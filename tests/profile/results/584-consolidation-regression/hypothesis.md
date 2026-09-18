# Profiling Hypothesis: 584-consolidation-regression

Written before profiling, 2026-09-19.

## The behaviour being profiled

`-g` consolidation on a month of access logs from a single server (1.5 GB, 28 files)
takes 2655.6 s in `finalize/group_similar` against 55.2 s on v0.18.1, and peak memory
rises from 964 MB to 2393 MB. Surviving message rows (`COUNTS log_messages_entries`)
rise from 1,313 to 1,136,511.

Reproduced at 1/28 of that scale on one day of the same corpus: 467 rows and 0.71 s
become 36,791 rows and 6.88 s.

## What is already established by bisection

Three commits on `release/0.18.2` touch consolidation. Measured on one day of the
affected corpus, `-bs 1440 -n 25 -g`:

| commit | rows | group_similar |
|---|---|---|
| `e153589` (before #571) | 467 | 0.72 s |
| `3defdcb` (#571, final pass at the -g sensitivity) | 467 | 0.70 s |
| `0c7c950` (#569, UUIDs compared as written) | 36,790 | 23.05 s |
| `22a7e8f` (#569, the new candidate search) | 36,791 | 6.83 s |

`0c7c950` is the step that changes the outcome. The new search recovers time but not
grouping. #571 is flat on this invocation, which runs at the default 85.

The first-order cause is not in question: two access-log keys differing only in a
UUID score Dice 63 as written against 90 with the UUID normalised, so they no longer
reach the default 85 and each distinct UUID stays its own row. The day file holds
36,541 distinct UUIDs against 36,791 surviving rows.

## What profiling is for

Why the cost is super-linear. Per retained row, `group_similar` costs about 190 us at
1 to 4 days (6.9 s / 36,791 rows; 30.2 s / 147,866 rows) but about 2,336 us at 28 days
(2655.6 s / 1,136,511 rows) — roughly 12x the per-row cost. A first-order scoring
change alone would hold the per-row cost flat.

## Hypothesis

The dominant term is `match_consolidation_patterns()`, called once per surviving key in
final-pass Pass 1 and again in Pass 2, each call a linear scan of the whole pattern list
for that `cat_gk`. Every non-grouping UUID key is a guaranteed miss, so it pays the full
list every time. Both factors grow with input: surviving keys grow linearly with the log
(each distinct UUID is a row), and the pattern list grows as the final pass discovers
patterns (102 at 1 day, 232+ at 4 days).

Measured in isolation, one miss costs 18.5 us against 100 patterns, 46.7 us against 250
and 93.0 us against 500. At 1,136,511 keys over two passes that is 42 s, 106 s and 211 s
respectively — real and super-linear, but well short of 2,655 s, so it is expected to be
a major term rather than the whole of it.

Two contributors are expected alongside it:

- **Streaming absorbs nothing, so the final pass carries everything.** `-V` reports
  `S1 Inline match: 100` and `S6 Evicted: 150057` at 4 days, with `EMA=0.0%,
  max_survivals=0`. The adaptive eviction guard (#135) sees a zero absorption rate and
  evicts every key from streaming, deferring the entire population to the final pass.
  This is the guard behaving as designed on an absorption rate the UUID change drove
  to zero.
- **`find_consolidation_candidates()` in the final-pass windows.** Bounded per window
  (window capacity 1000, `$max_search` 500), so it should scale with window count
  rather than super-linearly, and is expected to be a secondary term.

Ranked expectation for exclusive time at the largest sample:
1. `match_consolidation_patterns` — largest single term
2. `find_consolidation_candidates` and `dice_coefficient`
3. `build_consolidation_ngram_index`

## What would falsify it

`match_consolidation_patterns` holding a low share of exclusive time while total time
still grows super-linearly. In that case the term is elsewhere — the candidates are the
per-window index rebuild, the Pass 2 sweep's own iteration, or cluster merging.

## Cross-validation

`tests/profile/checks/consolidation.tsv`. Pattern-match calls should reconcile against
the `-V` `fp_p1_s3` / `fp_p2_s3` counters plus misses; `fc_calls` against
`fp_p1_fc_calls`.
