# Issue #137: Final Pass Redesign — Design Document

**GitHub Issue:** #137
**Branch:** `137-final-pass-log-messages`
**Status:** Design phase

## Problem

The final pass in `group_similar_messages()` (ltl lines 1524-1659) is fundamentally broken. It:

1. Only operates on keys remaining in `%consolidation_unmatched` — misses all keys that left the working set
2. Further filters to ceiling-excluded keys only — ignores everything else
3. Runs its own inline pairwise discovery — bypasses the S1→S2→S3→S4 pipeline entirely
4. Does not reuse `run_consolidation_checkpoint()` or `match_consolidation_patterns()`

This means:
- **Evicted keys (S6)** from #135 sit in `%log_messages` with no path back to consolidation
- **All remaining `%log_messages` keys** are never re-tested against the full set of discovered patterns
- The final pass is a separate mini-pipeline, not the same architecture we've been building and tuning

## Solution

Replace the current final pass with a loop over all `%log_messages` keys that feeds them through the **same** consolidation pipeline used during streaming. The only difference is the data source: instead of parsing log lines from files, the final pass iterates sorted `%log_messages` keys.

## Design Changes

### 1. Extract `consolidation_process_key()` subroutine

The consolidation pipeline logic currently embedded inline in the parsing loop (ltl lines 3882-3942) is extracted into a reusable subroutine. Both the streaming path and the final pass call this subroutine.

**Current inline code (lines 3882-3942):**
```
if ($is_new_key) {
    keys_seen++
    S1: match_consolidation_patterns() → if hit, accumulate stats into cluster
    S1 miss: store in consolidation_key_message, consolidation_unmatched
    Check trigger → fire run_consolidation_checkpoint() if threshold met
}
```

**New subroutine interface:**
```perl
sub consolidation_process_key {
    my ($log_key, $category, $cat_gk, $capped_msg, $stats_source) = @_;
    # Returns: 1 if S1 matched, 0 if not
}
```

**`$stats_source` parameter:** A hashref containing stats to merge into the cluster on S1 match. This is how the two callers differ:
- **Streaming caller:** constructs `{ occurrences => 1, total_duration => $duration, durations => [$duration], total_bytes => $bytes, ... }` from parsed line values
- **Final pass caller:** passes `$log_messages{$category}{$log_key}` directly — already has aggregated stats (occurrences, durations array, min/max, etc.)

On S1 match, the subroutine calls `merge_consolidation_stats($cluster, $stats_source)`. This replaces the per-field accumulation currently inline at lines 3892-3915. `merge_consolidation_stats()` already handles all fields correctly for both single-line and aggregated data.

**Pipeline steps inside the subroutine:**
1. Increment `keys_seen` counter (phase-appropriate counter set)
2. S1: call `match_consolidation_patterns()` — if match, call `merge_consolidation_stats()`, increment S1 counter, return 1
3. S1 miss: store in `consolidation_key_message`, `consolidation_unmatched`, set generation and checkpoint count
4. Increment category unmatched count, check trigger, fire `run_consolidation_checkpoint()` if threshold met
5. Return 0

### 2. Replace final pass in `group_similar_messages()`

Delete the current final pass code (lines 1524-1659). Replace with:

```perl
if ($consolidation_final_pass) {
    # 1. Reset transient working state
    # 2. Swap threshold/ceiling for final pass parameters
    # 3. Set phase flag

    for my $category (sort keys %log_messages) {
        for my $log_key (sort keys %{$log_messages{$category}}) {
            # Extract grouping key from log_key: [LEVEL] or [STATUS_CODE]
            # Build cat_gk, capped_msg
            # Call consolidation_process_key()
            # If S1 matched, delete from %log_messages
        }
    }

    # EOF checkpoints for final pass remainder
    for my $cat_gk (sort keys %consolidation_unmatched) {
        if (scalar(keys %{$consolidation_unmatched{$cat_gk}}) >= 2) {
            my ($cat, $gk) = split(/\|/, $cat_gk, 2);
            run_consolidation_checkpoint($cat, $gk);
        }
    }

    # Restore threshold/ceiling, reset phase
}
```

**Sorting keys:** `sort keys %{$log_messages{$category}}` naturally groups similar messages together. When a pattern is discovered mid-checkpoint, the immediately following keys are more likely to match via S3 — better checkpoint yield.

**Hash iteration safety:** `sort keys` materializes the key list into an array before iteration. Deleting keys during the loop (via S1 match or checkpoint absorption) is safe.

### 3. Data Merging

Both callers use `merge_consolidation_stats($cluster, $stats_source)` on S1 match — single code path.

`run_consolidation_pass()` already merges from `$log_messages{$category}{$key}` at S3 (line 2265) and S4 (lines 2336, 2384). During the final pass, those entries have aggregated stats; during streaming, they have single-line stats. The merge function handles both correctly — it sums occurrences, concatenates duration arrays, takes min of mins, max of maxes.

No changes needed to `merge_consolidation_stats()`.

### 4. Eviction: DISABLED During Final Pass

Adaptive eviction (#135) must be disabled during the final pass:

1. **No subsequent pass.** The final pass is the last opportunity to consolidate. Evicted keys remain unconsolidated forever. During streaming, eviction is acceptable because the final pass is the safety net. Eviction *in* the safety net defeats its purpose.

2. **Bounded set.** Eviction prevents unbounded growth during streaming (new keys keep arriving). The final pass iterates a fixed, known set — no new keys arrive. The working set is naturally bounded by `%log_messages` size.

**Implementation:** The `$consolidation_phase` flag tells `run_consolidation_checkpoint()` to skip:
- Fast-path eviction (lines 2472-2500)
- Survivor culling (lines 2539-2575)

When `$consolidation_phase eq 'final_pass'`, all keys survive checkpoints indefinitely.

### 5. Ceiling During Final Pass

The streaming ceiling (`$consolidation_occurrence_ceiling = 3`) excludes high-occurrence keys from S4 pairwise discovery. In the final pass:

- **S1 matching:** Ceiling doesn't affect S1. All keys are tested against compiled patterns regardless of occurrence count.
- **S4 discovery:** Use `$consolidation_final_ceiling` (default 1,000,000) instead of streaming ceiling. This allows high-occurrence keys to participate in pairwise discovery.

**Implementation:** Swap `$consolidation_occurrence_ceiling` with `$consolidation_final_ceiling` before the loop, restore after.

### 6. Threshold During Final Pass

Swap `$consolidation_threshold` with `$consolidation_final_threshold` before the loop. Both currently default to 85%, but the separate CLI option (`--final-threshold`) gives users control. Restore after.

### 7. Checkpoint Trigger Size

The streaming trigger (5000 unmatched keys per category) works for the final pass. The remaining `%log_messages` key count is bounded (typically hundreds to low thousands after streaming consolidation), so the trigger may fire 0-2 times. Same cadence is appropriate.

### 8. Extracting Grouping Key from log_key

During streaming, `$grouping_key = $log_level` comes from parsing. In the final pass, extract from the `$log_key`:
```perl
my ($grouping_key) = $log_key =~ /^\[([^\]]+)\]/;
$grouping_key //= "";
```
Format: `[$level] ...` for app logs, `[$status_code] ...` for access logs.

### 9. Resetting Transient State Before Final Pass

**Reset** (final pass builds its own working set):
- `%consolidation_unmatched`
- `%consolidation_key_message`, `%consolidation_key_message_cat_gk`
- `%consolidation_key_generation`, `%consolidation_key_checkpoint_count`
- `%consolidation_ngram_index`, `%consolidation_key_trigrams`, `%consolidation_key_trigrams_norm`, `%consolidation_posting_size`
- `%consolidation_category_unmatched_count`
- `%consolidation_absorption_ema` (fresh EMA — though eviction is disabled, useful for observability)

**Preserve** (carry over from streaming):
- `%consolidation_patterns` — final pass matches against existing patterns and may discover new ones
- `%consolidation_clusters` — final pass merges into existing clusters
- `%consolidation_pattern_generation` — carries over for S3 skip optimization
- `%consolidation_cat_stats` — streaming counters stay; final pass writes to `fp_*` counters

### 10. Separate Observability Counters

`%consolidation_cat_stats` gets parallel counter sets:
- Streaming: `s1_inline`, `s3_checkpoint`, `s4_pairwise`, `keys_seen`, `checkpoints`, etc. (existing, unchanged)
- Final pass: `fp_s1_inline`, `fp_s3_checkpoint`, `fp_s4_pairwise`, `fp_keys_seen`, `fp_checkpoints`, etc.

A phase flag (`$consolidation_phase = 'streaming' | 'final_pass'`) tells `consolidation_process_key()` and `run_consolidation_checkpoint()` which counter set to increment.

Verbose output (`-V`) shows both sets separately — streaming contribution vs final pass contribution.

### 11. Streaming Path Refactor

The inline stats accumulation (lines 3892-3915) is replaced with `consolidation_process_key()`. The streaming caller constructs `$stats_source`:

```perl
my $stats_source = { occurrences => 1 };
if ($is_access_log) {
    $stats_source->{total_bytes} = $bytes if defined $bytes;
    if (defined $duration && !$omit_durations) {
        $stats_source->{total_duration} = $duration;
        $stats_source->{total_duration_num} = $duration;
        $stats_source->{sum_of_squares} = $duration ** 2;
        $stats_source->{durations} = [$duration];
    }
    if (defined $count) {
        $stats_source->{count_sum} = $count;
        $stats_source->{count_occurrences} = 1;
        $stats_source->{count_min} = $count;
        $stats_source->{count_max} = $count;
    }
    foreach my $config (@udm_configs) {
        my $name = $config->{name};
        next unless defined $udm_values{$name};
        $stats_source->{"udm_${name}_sum"} = $udm_values{$name};
        $stats_source->{"udm_${name}_occurrences"} = 1;
        $stats_source->{"udm_${name}_min"} = $udm_values{$name};
        $stats_source->{"udm_${name}_max"} = $udm_values{$name};
    }
}

my $matched = consolidation_process_key($log_key, $category, $cat_gk, $capped_msg, $stats_source);
$consolidation_s1_matched = $matched;
```

The downstream code (`if (!$consolidation_s1_matched)` at line 3947) continues to control whether stats go to `%log_messages`.

## Files to Modify

- **`ltl`** — extract `consolidation_process_key()`, refactor streaming path, replace final pass in `group_similar_messages()`, disable eviction during final pass, update verbose output for dual-phase reporting
- **`features/fuzzy-message-consolidation.md`** — update Outstanding Decision 6, update final pass documentation, add lesson learned

## Verification Plan

1. **Tracking invariant**: `S1 + S2 + S3 + S4 + S5 + S6 = keys_seen` must hold for both streaming and final pass phases independently
2. **Streaming regression**: Run against standard access log with `-g 85 -V --disable-progress` — streaming counters must be unchanged from before the refactor
3. **Final pass absorption**: Verify final pass `fp_s1_inline` is non-zero on files where eviction occurred during streaming (evicted keys should match patterns)
4. **XL benchmark**: Time and memory comparison — final pass should add minimal overhead
5. **Verbose output**: Both streaming and final-pass sections appear separately in `-V` output
6. **`--no-final-pass`**: Still works (skips the final pass loop entirely)
