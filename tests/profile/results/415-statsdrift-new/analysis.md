# #415 stats-phase drift — profile analysis (constructs c1, 100k sample)

## Hypothesis
`calculate_all_statistics` and its helpers show identical call counts between v0.16.0 and 0.17.0 (matching byte-identical `-V statistics-demand` / `-V percentile-algorithm` sections) but higher per-call cost under 0.17.0 — the drift is per-operation, not extra work.

## Method
- Construct: humungous-log-uniqueness `-so p99`, `--data-model=raw`, harness-shaped (`-bs 60`, `--terminal-width=200`), 100k-line sample.
- Arms: 0.17.0 tree (`415-statsdrift-new`) vs v0.16.0 detached worktree (`415-statsdrift-old`), same Perl 5.42.2, same machine, run back-to-back.
- Bin-counter involvement excluded beforehand: with `-dm raw` pinned on all four stores (verified via `-V runtime-config`), the end-to-end drift persists (median 0.462 s → 0.554 s, +19.9%, median-of-3, non-overlapping ranges); negative control (single-day access log `-hg`) flat.

## What NYTProf showed (100k)
| sub | old incl/excl | new incl/excl |
|---|---|---|
| calculate_all_statistics | 0.1372 / 0.0853 | 0.1581 / 0.0889 (+15% incl) |
| measure_memory_structures | 0.1125 | 0.1254 (+11%) |
| named_structure_sizes | 0.0836 | 0.0940 (+12%) |
| read_and_process_logs (excl) | 1.2736 | 1.1064 (faster) |
| compile_format_scan_sub | n/a | 28 calls, 0.0968 s (startup precompile, #413) |
| format_registry_promote | n/a | 13 calls, 0.0410 s |

Line-level (Devel::NYTProf::Data API, sub line range): the hot statements are the per-key loop over `%log_messages{$category}` (entry fetch + `$n` gate) and the `@by_occ` occurrences-sort comparator. Source is byte-identical between versions; per-statement counts match exactly (99,487 loop iterations = `COUNTS log_messages_entries` both arms; ~102.3k comparator entries both arms); per-statement TIME is +14–35% in 0.17.0.

## Cross-validation
NYTProf loop count 99,487 == `-V` `COUNTS log_messages_entries` 99,487 (both arms). Clean.

## Diagnosis
Not a statistics-code change (none exists; code and counts identical). Not bin-counter related (raw-pinned drift persists). The slowdown is concentrated in subs that traverse the large `%log_messages` hash (stats loop +15%, memory measurement walkers +11–12%) while the sequential read loop is unaffected — consistent with degraded memory locality of large-hash traversal in the 0.17.0 process, whose heap carries ~+20 MB of eagerly compiled scan-order subs allocated before the hash is built (#413; RSS 89 → 111 MB at this sample). Mechanism is inferred from the profile shape; not yet directly proven.

## Surprises
- `format_registry_promote` costs 3.15 ms/call mid-run (13 calls here) — compile-on-promotion cost visible in parse phase.
- run-profile.sh treats every bare token in ltl args as an input file to truncate — options must use `=`-joined forms.

## Next step (pending architect)
Discriminating probe for the locality hypothesis (requires a scratch-copy code edit, not yet approved): disable the eager precompile loop in `build_format_registry()` on a throwaway copy, re-run construct 1 median-of-3. Collapse of the drift attributes #415 to #413; persistence sends the investigation to allocator/heap layout beyond the precompile.

## Addendum: -so p99 vs default occurrences sort (0.17.0 only, architect-directed)

Timing (full 97 MB file, `-dm raw`, median-of-3):

| arm | finalize/calculate_statistics | delta |
|---|---|---|
| default (occurrences sort) | 0.315 s (0.309–0.316) | — |
| `-so p99` | 0.554 s (0.532–0.555) | +76% |

`-V statistics-demand` under `-so p99` on this log: `sort_selection: statistic=p99 defined=0 fill=286659 demoted=0`, all `group_calc … computed=0` — **zero keys reach the n≥4 percentile-eligibility floor, zero percentiles are computed**. The entire +0.24 s is (a) the population-wide per-key eligibility walk over `%log_messages` and (b) the 286,659-key fill-block occurrences sort (comparator does two hash lookups per comparison).

Profile agreement (100k sample, `calculate_all_statistics`): 0.083 s incl / 0.017 s excl (default) vs 0.158 s incl / 0.089 s excl (`-so p99`) — the difference sits on the loop/comparator statements, not percentile math.

Implication for the sort-on-statistic cost model: on singleton-dominated logs, the population-stats obligation of `-so <statistic>` degenerates into pure walk-and-sort overhead with zero statistical yield — the population price is paid even when no key can rank. This is also where the cross-version drift concentrates (same statements), which is why sort-on-statistic scenarios drift hardest between v0.16.0 and 0.17.0.

## Tooling fix landed under this ticket

`run-profile.sh` classified any non-dash token as an input file, truncating option values (`-V` section lists, `-so` operands, long-option values) into empty samples → zero-line profiled runs. Both arg walkers now apply one on-disk test (`-e` / glob expansion) before treating a token as a sample source. Commit eefda5a on branch 415-calculate-statistics-drift.

## Re-measure with the #417 sub-stage instrument (2026-08-24, post-merge of release/0.17.0)

Same construct (humungous `-so p99`, `-dm raw`, `-mem`, harness-shaped), median-of-3
ABAB, v0.16.0 worktree binary vs this branch (now carrying #417), same machine,
back-to-back. Runtime-config byte-identical to the earlier arms.

| row | old (v0.16.0) | new (0.17.0 + #417) | delta |
|---|---|---|---|
| calculate_statistics (parent) | 0.465 s (0.461–0.501) | 0.560 s (0.533–0.563) | **+20.4%** |
| ├ population_walk | — | 0.264 s (0.259–0.269) | 47% of phase |
| ├ sort_selection | — | 0.282 s (0.261–0.283) | 50% of phase |
| ├ bucket_stats / group_calc / threadpool_stats | — | 0.000 s each | 0% |
| └ untimed | — | 0.013 s | 2% |
| total | 2.934 s | 3.155 s | +7.5% |

- Drift reproduces at the same magnitude as the earlier raw-pinned measurement
  (+19.9% then, +20.4% now) — stable, not session noise.
- The instrument attributes 97% of the phase to exactly the two blocks the
  NYTProf statement-level analysis identified: the per-key eligibility walk over
  `%log_messages` (population_walk) and the 286,659-key fill-block occurrences
  sort (sort_selection). Denominators: `COUNTS log_messages_population 286659`,
  `sort_selection: statistic=p99 defined=0 fill=286659` — zero statistical yield,
  as before. Every sub-stage that does per-key *computation* (group_calc,
  bucket_stats) is 0.000: the drift lives entirely in hash traversal + sort.
- `-mem` in the same runs: rss_peak 212.5 MB (old) → 232.6 MB (new), unattributed
  76 → 95 MiB — the ~+20 MB pre-hash heap the locality hypothesis (#413 eager
  precompile) predicts is present in these exact runs.
- Cross-version conclusion now rests on comparable TIMING rows (the pause
  condition): identical work counts, identical sub-stage shape expected, cost
  concentrated where large-hash traversal locality would put it. The
  discriminating probe (scratch-copy disable of the eager precompile loop in
  `build_format_registry()`, re-run this construct) remains the one unproven
  link and still awaits approval — alternatively, #413's fix landing in this
  release provides the same discrimination for free at the next re-measure.

## Re-measure after #413 (2026-08-24, branch at release/0.17.0 head `30371a4`)

Same construct (humungous `-so p99`, `-dm raw`, `-mem`, harness-shaped), median-of-3
ABAB, v0.16.0 worktree binary vs release/0.17.0 head (carrying #413 and #417), same
machine, back-to-back. `COUNTS format_scan_subs_compiled 1` confirms the lazy
compile is in effect; work counts identical across arms
(`log_messages_population 286659`); no runtime warnings either arm.

| row | old (v0.16.0) | new (0.17.0 + #413) | delta |
|---|---|---|---|
| calculate_statistics (parent) | 0.473 s (0.471–0.476) | 0.555 s (0.537–0.558) | **+17.3%** |
| ├ population_walk | — | 0.274 s (0.258–0.282) | 49% of phase |
| ├ sort_selection | — | 0.267 s (0.263–0.269) | 48% of phase |
| ├ bucket_stats / group_calc / threadpool_stats | — | 0.000 s each | 0% |
| parse/read_files | 2.404 s (2.403–2.407) | 2.493 s (2.481–2.513) | +3.7% |
| total | 2.878 s | 3.056 s | +6.2% |
| rss_peak | 206.0 MB | 207.0 MB (205.8–207.7) | +1 MB (was +20 MB) |

- **Locality-via-eager-precompile hypothesis refuted.** #413 removed the +20 MB
  pre-hash heap (rss gap 20 MB → 1 MB) and the drift stepped down only
  +20.4% → +17.3%, still non-overlapping. The heap was at most a minor
  contributor; the dominant cause is elsewhere.
- Shape unchanged: 97% of the phase in the two `%log_messages` traversal
  blocks, zero per-key computation cost.
- `parse/read_files` is also +3.7% in the same runs with identical line
  counts — the read-phase symptom #414 tracks. Whether the two phases share a
  per-operation cause is the open question; #414's staged NYTProf attribution
  runs first (see the cross-link comments on both issues, 2026-08-24).

## Status

Paused 2026-08-24 (architect decision) pending #414's attribution. Resumption:
if #414 finds a whole-process per-operation slowdown, attribute #415 to it;
if #414's cause is scan-path-specific, profile `population_walk` /
`sort_selection` across both arms at 100k with the #413 heap out of the
picture.
