# Profiling Analysis: #135 Redundant Processing in Consolidation

## Hypothesis
Time regression on XL access logs (+58% with `-g 85`) is caused by:
1. O(all_keys) cleanup loops at every checkpoint
2. S3 re-testing keys against patterns they already failed against in S1
3. `find_consolidation_candidates` searching diverse keys with poor Dice scores

## What NYTProf Showed

### 10k sample (71 unique keys, 2 checkpoints, 3 patterns)
| Function | Calls | Excl(s) | Notes |
|----------|-------|---------|-------|
| `read_and_process_logs` | 1 | 0.208 | 77.2% of CPU — dominates |
| `find_consolidation_candidates` | 31 | 0.004 | 0.21 ms/call |
| `dice_coefficient` | 282 | 0.002 | 9.1 Dice calls per fc_call |
| `build_consolidation_ngram_index` | 2 | 0.001 | Once per checkpoint |

### 100k sample (82 unique keys, 2 checkpoints, 1 pattern)
| Function | Calls | Excl(s) | Notes |
|----------|-------|---------|-------|
| `read_and_process_logs` | 1 | 2.092 | 95.0% of CPU |
| `find_consolidation_candidates` | 41 | 0.007 | 0.28 ms/call |
| `dice_coefficient` | 558 | 0.004 | 13.6 Dice calls per fc_call |
| `merge_consolidation_stats` | 55 | 0.004 | |
| `build_consolidation_ngram_index` | 3 | 0.002 | |

## Cross-Validation Results

All primary checks pass:
- `match_consolidation_patterns`: NYTProf=91, expected=92 (keys_seen+s3_calls), diff=-1.1% **[OK]**
- `find_consolidation_candidates`: NYTProf=41, expected=41, diff=0.0% **[OK]**
- `read_and_process_logs`: NYTProf=1, expected=1 **[OK]**

### Instrumentation bugs found and fixed before profiling
- checks file used prototype function names (`find_candidates`, `match_against_patterns`) instead of ltl names (`find_consolidation_candidates`, `match_consolidation_patterns`)
- S1 regex case mismatch: `S1 inline` vs actual `S1 Inline`
- `find_candidates calls:` regex tried to match across multi-line Grand Totals header
- `fc_calls` counter only printed for multi-category — never matched for single-category runs
- Grand Totals labels matched same regex as per-category, causing double-counting with `+` accumulator
- Original check `s1_inline + s3_checkpoint` was wrong — these are successful matches, not total calls. Correct is `keys_seen + s3_calls`.
- Final pass `find_consolidation_candidates` calls not counted in `fc_calls` — added counter.

## Surprises

1. **Standard access log has very low diversity** — only 82 unique keys across 100K lines. The XL problem requires 80% unique ratio data (707K keys across 762K lines). Profiling with standard access log doesn't reproduce the XL pathology. However, the counter data still confirms the hypothesized waste patterns.

2. **S1 Inline match: 0** everywhere at these scales. Checkpoint trigger (5000) exceeds unique key count per category, so all keys enter unmatched before any checkpoint fires. S1 only matters on large files with multiple checkpoints.

3. **`read_and_process_logs` dominates** at 95% of CPU — but this is the parsing loop which is always the dominant cost. The consolidation overhead (0.026s for `group_similar_messages`, 0.012s for `find_consolidation_candidates`) is tiny at this scale.

## Diagnosis

The new counters confirm all three hypotheses:

### 1. O(all_keys) cleanup: confirmed wasteful
- `plain|404`: 79 keys scanned to clean up a category with 2 unique keys and 0 absorbed
- `plain|200` at 10k: 669 keys scanned for 570 unique keys and ~350 absorbed
- At XL scale (707K keys × 100+ checkpoints): ~70M key iterations in cleanup loops alone

### 2. S3 match rate: confirmed 0.0%
- 10k: 303 S3 attempts, 0 matches
- 100k: 10 S3 attempts, 0 matches
- S3 tests keys against patterns that didn't exist when those keys entered unmatched

### 3. Diverse data Dice cost: not measurable at this scale
- Need XL data with 80% unique ratio to see the 14s/checkpoint cost from prior investigation
- At 82 unique keys, `find_consolidation_candidates` takes 0.28ms/call — negligible

## Action

Implemented three fixes to eliminate redundant processing:
1. **Fix 1: Tracked cleanup** — `run_consolidation_pass` returns `%consumed`; cleanup loops iterate O(consumed) instead of O(all_keys)
2. **Fix 2: Smart S3 skip** — track `$consolidation_pattern_generation`; S3 skips keys whose generation >= current
3. **Fix 3: Return entry from merge** — `try_consolidation_merge_into_existing` returns `($merged_regex, $entry, $existing)`; callers use returned references directly instead of O(patterns) linear scan

**Not pursued:** Stall detection / saturation flag approach was rejected — it simply stops all consolidation for the affected category, defeating the feature's purpose. The correct approach to bound the unmatched working set is per-key eviction (tracked as a separate effort under #135).

## Benchmark Results (XL access log samples)

Baseline: main branch. Fixed: branch with Fixes 1-3.

| Sample | Baseline time | Fixed time | Baseline memory | Fixed memory |
|--------|-------------|-----------|----------------|-------------|
| 100K lines | 117.9s | 113.5s (-3.8%) | 157.7 MiB | 199.7 MiB (+26.6%) |
| 500K lines | 118.9s | 118.8s (-0.1%) | 429.4 MiB | 478.1 MiB (+11.3%) |

**Interpretation:** Time improvement is modest because `read_and_process_logs` dominates at 95% CPU on this diverse data. The redundancy was confirmed and eliminated, but it wasn't the bottleneck. The dominant cost is the accumulating unmatched key set (22K+ diverse keys at 100K lines, 132K+ at 500K lines) which grows unboundedly — this is the per-key eviction problem.

Memory increased slightly — may be from generation tracking structures or the threshold difference (baseline used final pass threshold=80%, fixes use 85%).

## Learnings

1. **Cross-validation checks file must use actual ltl function names**, not prototype names. When code is ported from prototype to ltl with renames, update the checks file.
2. **Grand Totals labels must differ from per-category labels** to prevent double-counting with `+` accumulation in regexes. Used `Total` prefix for Grand Totals.
3. **The `(informational)` tolerance in extract-profile.pl is parsed as 5%** due to the regex `$tol =~ /^([\d.]+)%$/` falling through to default. Consider fixing this to skip comparison for informational rows.
4. **Counter expressions like `s1_inline + s3_checkpoint` must reflect total calls, not just successful matches.** Corrected to `keys_seen + s3_calls`.
5. **Per-category counters must be printed even for single-category runs** — otherwise cross-validation regex has nothing to match.
