# Calculated-statistic sort path: benchmark + optimization (#303)

## Overview

Sorting the messages table by a computed statistic (`-so p99`, `-so skewness`,
any ladder field) cannot use the #302/#304 candidate-pool selection, because
the sort value does not exist until statistics are computed. The current path
(`## STATS FOR TOP LOG MESSAGES ##` in `ltl`, the `else` branch of the
`$sort_key` ladder-field regex) therefore computes and stores statistics for
**every** message key, then sorts the full population — versus the
available-value path, which computes stats only for the displayed pool.

Both CSV writers slice to top-N, so the population-wide compute exists only
to feed the sort; nothing else consumes it. This population-wide compute and
storage is also why #303 blocks #323 (memory-model research): it directly
shapes per-key memory on statistic-sort runs.

## GitHub Issue

https://github.com/gregeva/logtimeline/issues/303

## Decision record (2026-07-13 design interview)

The following were resolved with the architect before design/implementation:

1. **Benchmark coverage (issue step 1) — bundled suite + targeted.** Two new
   scenarios are added to `SCENARIOS` in `tests/baseline/run-benchmark.sh`:
   one `-so p99` (tail percentile — the proxy-poolable path) and one
   `-so skewness` (shape statistic — exercises the O(n) shape pass and the
   no-cheap-proxy fallback path). Cross-product grows 7×7=49 → 7×9=63.
   Prior baselines (v0.16.0 and earlier) lack these scenarios; their first
   release-to-release comparison happens at the next release gate.
2. **Issue-level before/after measurement is targeted only.** The bundled
   suite is a release-gate instrument and is not run during issue work. The
   optimization's before/after uses targeted single-file, single-scenario
   runs, median of 3 minimum.
3. **Design shape: proxy pool with two-pass fallback.**
   - *Proxy pool*: cheap safe-bound scan over all keys → candidate pool →
     full (demanded-group) statistics on the pool only → sort the pool.
   - *Two-pass fallback* (for metrics with no safe cheap proxy): pass 1
     computes only the sort statistic's group for all keys via a minimal
     per-call demand descriptor; pass 2 computes full demand for the top-N.
     The #305 demand descriptor is per-call precisely to permit this without
     reworking the registry.
4. **Proxy-safety mechanism: prototype both, decide on measurement.** Build
   the static per-metric proxy table first (max-proxy where safe AND tight:
   tail percentiles and `max` itself; everything else → fallback), then probe
   whether the adaptive verify-and-expand loop (build pool → verify no
   excluded key's safe bound beats the value at the display cut → expand
   until proven) ever pays on realistic distributions before adopting it.
5. **Ascending sorts are in scope, symmetrically.** `-sa` with a statistic
   sort uses the mirrored proxy: `min` is the safe bound for ascending
   percentile sorts (pNN ≥ min always). Bin mode already tracks per-key
   min/max incrementally (free proxy); raw mode's min scan costs the same as
   the max scan.
6. **Pass-1 / population memory disposition: defer to measurement.**
   Candidate designs: (a) transient — proxy/pass-1 values live in a temporary
   sort structure and are discarded, `%log_messages` stores statistics only
   for the displayed pool (the outcome #323 wants); (b) store the sort
   statistic's field population-wide. Measure `-mem` per-structure HWMs both
   ways before locking the design.
7. **Observability: extend the `-V statistics-demand` section.** Sort-path
   lines (proxy used, pool size vs population, verify/expansion events,
   per-pass call attribution) join the existing per-store `stats_calls` /
   `group_calc` counters. Per the test-harness contract, the section contract
   in `features/duration-statistics.md`, `tests/validate-statistics-demand.sh`,
   and the code change land in the same commit.
8. **Correctness bar: byte-identity, harness-enforced.** Displayed top-N and
   CSV rows under any `-so <statistic>` must be byte-identical to the
   current all-keys path, including tie resolution at the display cut
   (anchoring lesson from #302). Enforced by `-so` scenarios added to
   `validate-statistics-demand.sh` (with prove-can-fail sabotage recorded)
   plus direct pre/post diffs during development.
9. **Measurement fixture: TBD following analysis.** The issue's measurements
   used an uncommitted constructed fixture (~21.7K duration-bearing keys via
   `-iqs`); it does not exist and is not restorable. The targeted-measurement
   fixture (committed log at natural cardinality, reconstructed
   high-cardinality case, or both) is chosen once the analysis phase
   establishes what cardinality the question needs.

## Premise re-validation (mandatory before implementing)

All quantitative claims in the issue body predate #305 and must be
re-measured on the current code before the optimization is designed against
them:

- The ≈2× `calculate_statistics` cost (0.82s vs 0.41s at 21.7K keys) was
  measured when every invocation computed the full ladder. Post-#305, a
  terminal-only `-so p99` run computes only `terminal_core` population-wide
  (p99 is in `terminal_core`; csv_body/extended/shape are skipped), so the
  gap has likely narrowed. A `-so skewness` run additionally computes the
  shape group population-wide and likely retains more of the gap.
- The ~38× max-scan-vs-full-stats microbench likewise assumed full-ladder
  compute per key.

Probe protocol: dev-scale targeted runs on the current branch, using the
`-V statistics-demand` per-store `stats_calls` and `group_calc` counters
(landed on this branch) as the demanded-work denominator, per the #306
lesson (features/305-shape-moment-extended-percentile-demand.md § #306
investigation).

## Design notes preserved from the issue

- `max` is a safe upper bound for any percentile; safe AND tight for tail
  percentiles, safe but loose for central ones (p25/p50/p75) — `mean`
  predicts central percentiles better but is not a safe bound.
- `mean` is derivable for free from already-accumulated
  `total_duration`/`occurrences`; `std_dev`/`cv`/`iqr`/shape moments have no
  cheap safe bound → fallback path.
- Maintaining min/max incrementally at parse time was prototyped in #302 and
  rejected: ~2% on `read_files` paid by every run. An at-sort-time scan only
  when the sort needs it avoids the universal cost (consistent with the #306
  standing guidance: per-sample read-loop work is the most expensive place
  to add anything).
- Pool sizing must anchor at the display cut including ties (the #302
  lesson).

## Relationship to other issues

- **#302/#304** — candidate-pool selection for available-value sorts; this
  issue extends the pool idea to values that must be computed.
- **#305** — the statistics-group demand registry; supplies the per-call
  demand descriptor the two-pass fallback uses, and the `-V
  statistics-demand` instrument this issue extends and measures with.
- **#306** — fused moment accumulation, measured and rejected; its standing
  guidance (prefer deferred pool-limited compute over read-loop work)
  constrains this design.
- **#323** — blocked by this issue; the pass-1 memory disposition (decision
  6) is the coupling point.

## Status

- Landed on branch `303-calculated-statistic-sort-path`: per-store
  `stats_calls` + per-group `group_calc computed/skipped_demand/ineligible`
  counters in `-V statistics-demand` (the before/after instrument).
- Next: premise re-validation probe → benchmark scenarios → proxy-table
  prototype vs adaptive probe → implementation.
