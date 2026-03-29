# Issue #150: Final Pass Scalability Redesign

**GitHub Issue:** #150
**Status:** Design phase
**Related:** #137 (current final pass implementation), #144 (2M auto-disable workaround), #135 (eviction mechanics), #96 (consolidation engine)

## Problem

The current final pass simulates streaming processing on a static dataset — it feeds all remaining `%log_messages` keys through `consolidation_process_key()` one by one, triggering checkpoints at the same 5000-key cadence as streaming. This causes:

1. **Unbounded working set accumulation** — without eviction, `%consolidation_unmatched` grows linearly with each checkpoint. S3 testing cost, bucket partitioning, and trigram memory all grow without bound.
2. **Data duplication** — every key is copied into `%consolidation_key_message`, `%consolidation_unmatched`, and related tracking structures, duplicating data already in `%log_messages`.
3. **Inefficient S4 discovery** — the large accumulated working set means S4 builds trigram indices over thousands of keys that will never match, wasting memory and CPU.

A 2M-line auto-disable workaround (#144) currently prevents the final pass from running on large files, meaning large-file users get no final pass benefit at all.

## Investigation Findings (v0.14.3 → v0.14.4)

### Upstream bugs resolved

The catastrophic regression reported in v0.14.3 was primarily caused by upstream consolidation engine bugs, not the final pass architecture:

- **#158** — Log key truncated to terminal width (120 chars), cutting UUIDs and breaking UUID-normalized Dice scoring. Fixed to use 350-char cap when `-g` active. This was the primary cause: UUID-heavy keys couldn't consolidate during streaming, flooding the final pass with an enormous unconsolidatable key set.
- **#157** — `--terminal-width` CLI option not propagated to `$max_log_message_length`.
- **#164** — Cross-cluster pattern merge tested subsumption in wrong direction.

**Benchmark impact of upstream fixes (v0.14.3 → v0.14.4):**

| Test | v0.14.3 | v0.14.4 | Change |
|------|---------|---------|--------|
| 7.7M lines consolidate | 67.4 min | 2.3 min | -96.6% |
| 38.7M lines consolidate | 477.7 min | 10.3 min | -97.9% |
| 38.7M hm+hg+consolidate | crashed (OOM) | 13.6 min | now completes |

### Remaining architectural concerns

Despite the upstream fixes resolving the catastrophic regression, the final pass architecture still has structural problems:

1. **Sort order** — sorts by full `$log_key` which groups by `[$status_code]` prefix, separating messages that are consolidation candidates across different status codes
2. **Data duplication** — copies keys into consolidation working structures instead of operating on `%log_messages` directly
3. **Unbounded accumulation** — no eviction means working set still grows without bound (just less severe now that streaming consolidation works better)
4. **Trigram lifecycle** — per-key trigrams accumulate across checkpoints without cleanup for definitively unmatched keys

## Design — Redesigned Final Pass

### Key Principle

The final pass uses the **same functions** as streaming (S3 pattern matching, S4 pairwise discovery, `find_consolidation_candidates`, `compute_mask`, `derive_regex`, etc.) but a **different execution mechanism** suited to operating on a static dataset rather than a stream of incoming keys.

### Architecture

**Pass 1 — Sorted iteration with sliding window:**

```
Sort remaining %log_messages keys by message body (strip [$grouping_key] prefix)

Initialize sliding window (capacity: 1000 keys)
new_patterns_created = 0

For each key in sorted %log_messages:
    capped_msg = substr($log_key, 0, $consolidation_message_length_cap)

    # S3: test against all compiled patterns
    if match_consolidation_patterns($category, $grouping_key, $capped_msg):
        merge stats into matched cluster
        delete key from %log_messages
        → absorbed (S3)
        continue to next key

    # S2: ceiling filter (user-configurable)
    if key occurrences >= $consolidation_final_ceiling:
        → skip S4 for this key (leave in %log_messages)
        continue to next key

    # S3 miss, below ceiling → add to sliding window
    add key to sliding window

    # Window full? → run S4 pairwise discovery
    if window.size >= 1000:
        build trigram index for window contents
        run pairwise discovery (find_candidates → compute_mask → derive_regex)
        for each new pattern discovered:
            new_patterns_created++
            pattern immediately available for S3 on subsequent keys
        absorb matched keys → delete from %log_messages
        free trigrams and index
        clear window

# End of iteration — process remaining window if >= 2 keys
if window.size >= 2:
    run S4 on remaining window contents
    free trigrams and index
```

**Pass 2 — Conditional cleanup sweep (only if Pass 1 created new patterns):**

```
if new_patterns_created > 0:
    For each key still in %log_messages:
        # S3 only — test against newly created patterns from Pass 1
        if match against new patterns:
            merge stats into cluster
            delete key from %log_messages
```

No S4 in Pass 2. No trigrams. Just regex matching against the new patterns. This catches keys that appeared *before* their matching pattern was discovered in Pass 1's sorted order.

### Sort Order

Sort by message body, stripping the `[$grouping_key]` prefix:

```perl
my @sorted_keys = sort {
    my ($msg_a) = $a =~ /^\[[^\]]+\]\s*(.*)/;
    my ($msg_b) = $b =~ /^\[[^\]]+\]\s*(.*)/;
    ($msg_a // $a) cmp ($msg_b // $b)
} keys %{$log_messages{$category}};
```

This clusters similar API paths together regardless of status code, maximizing S4 yield within each sliding window.

### No Data Duplication

The current implementation copies keys into `%consolidation_key_message`, `%consolidation_unmatched`, `%consolidation_key_generation`, `%consolidation_key_checkpoint_count`. The new design operates directly on `%log_messages`:

- `$capped_msg` is computed on the fly from the `$log_key` (which is the hash key in `%log_messages`)
- The sliding window holds only references/keys, not copies of message data
- Trigrams are built for window contents and freed after each window
- No `%consolidation_unmatched` — keys that aren't absorbed simply stay in `%log_messages`

### Bounded Resource Usage

| Resource | Current (unbounded) | New design (bounded) |
|----------|-------------------|---------------------|
| Working set | Grows by ~4500 keys per checkpoint | Fixed at 1000 keys (window size) |
| Trigrams | Accumulate for all unmatched keys | Built and freed per window |
| Ngram index | Rebuilt but over growing key set | Built over window contents only |
| Key message copies | All keys duplicated | No duplication |

### Ceiling as User Control

The streaming ceiling (`$consolidation_occurrence_ceiling = 3`) is a performance optimization — it excludes high-occurrence keys from S4 discovery during streaming to keep discovery focused on the long tail.

The final pass ceiling (`$consolidation_final_ceiling`) serves a different purpose: it is a **user-facing control** that allows users to scope consolidation. A user might set `--final-ceiling 50` to say "only consolidate messages with fewer than 50 occurrences — high-occurrence entries are already meaningful as individual entries." The default should be high (effectively unlimited) so consolidation works fully by default.

This distinction should be documented in the help text and user documentation.

### Observability

The `-V` verbose output for the final pass should report:

- **Pass 1:** keys iterated, S3 absorbed, S2 ceiling skipped, windows processed, S4 pairwise discovered, S4 re-scan absorbed, new patterns created, keys remaining
- **Pass 2:** keys tested, S3 absorbed (new patterns only), keys remaining
- Total reduction: keys entering final pass → keys remaining after both passes

### Removal of 2M Auto-Disable (#144)

The 2M-line auto-disable workaround should be removed as part of this implementation. The new bounded architecture makes the final pass safe to run on any file size. The auto-disable must be removed during development to enable testing of the final pass on large files.

## Resolved Questions (from investigation phase)

1. ~~UUID consolidation failure~~ — Resolved by #158. Log key truncation was cutting UUIDs.
2. ~~Bounding mechanism~~ — Sliding window of 1000 keys with per-window trigram lifecycle.
3. ~~Sort order~~ — Sort by message body, stripping grouping key prefix.
4. ~~Should survivors get a second chance?~~ — Pass 2 provides this. Keys that appeared before their pattern was discovered get a second S3 pass.
5. ~~Interaction with #156~~ — Resolved. Upstream fixes dramatically reduced keys entering final pass.

## Implementation Plan

1. Remove 2M auto-disable (#144)
2. Replace `group_similar_messages()` final pass section with new Pass 1 + Pass 2 architecture
3. Reuse existing functions: `match_consolidation_patterns()`, `build_consolidation_ngram_index()`, `find_consolidation_candidates()`, `compute_mask()`, `derive_regex()`, `derive_canonical()`, `merge_consolidation_stats()`
4. Update `-V` verbose output with new final pass metrics
5. Update `--final-ceiling` help text to describe user-facing scoping purpose
6. Validate with benchmarks: 10K, 100K, and XL access logs + application logs

## References

- #137 — Current final pass implementation (superseded by this design)
- #144 — 2M auto-disable workaround (to be removed)
- #135 — Eviction mechanics (streaming only, not applicable to new final pass)
- #157, #158, #164 — Upstream fixes that resolved the catastrophic regression
- #156, #162 — Investigation findings that informed this design
- `features/137-final-pass-redesign.md` — Design document for current implementation
- `features/fuzzy-message-consolidation.md` — Full consolidation engine documentation (includes process flow diagram)
