# Calculated-statistic sort path: benchmark + optimization (#303)

## Overview

Sorting the messages table by a computed statistic (`-so p99`, `-so skewness`,
any ladder field) cannot use the #302/#304 candidate-pool selection, because
the sort value does not exist until statistics are computed. The current path
(the `else` branch of the `$sort_key` ladder-field regex in
`calculate_all_statistics`, `## STATS FOR TOP LOG MESSAGES ##`) computes and
stores statistics for **every** message key, then sorts the full population —
versus the available-value path, which computes stats only for the displayed
pool.

Both CSV writers slice to top-N, so the population-wide compute exists only
to feed the sort; nothing else consumes it. This population-wide compute and
storage is also why #303 blocks #323 (memory-model research).

## GitHub Issue

https://github.com/gregeva/logtimeline/issues/303

## Design record (2026-07-13 design interview)

Established conversationally with the architect. This record supersedes the
earlier questionnaire-derived decision list in full.

### Target workload and priority

- The path this must be fast for is the **turn-by-turn terminal analyst**:
  single production log target (one busy day can be millions of lines; small
  systems reach that volume over a week), repeated re-execution as options
  are adjusted, output consumed only through the top-N table.
- The **CSV/export flow is explicitly allowed to stay slower** — it is the
  less frequent, broad-brush use (export for follow-up tooling or
  period-to-period comparison persistence).
- **The default `occurrences` sort is sacred**: it must not regress at all.
  A statistic sort is opt-in — the analyst knows what they asked for — so a
  visible, bounded overhead from multi-pass computation is acceptable.
  Parity with the occurrences sort is desirable but not required.
- The statistic-sort feature itself is new and as yet unused in anger; shape
  statistics (`skewness`, `kurtosis`, `bimodality_coef`) are anticipated to
  be at least as valuable to analysts as tail percentiles.

### Production population shape (grounding, from the #323 measurement)

One ThingWorx access-log node, ~8M lines: 600,345 distinct message keys;
**96.7% occur exactly once**, 99.1% occur ≤5 times; ~193 hot keys carry 77%
of all samples. Consequences for this path:

- The population pass is Edge-A dominated: per-key sub-call overhead and
  per-key stored fields across ~600k mostly-singleton keys — not per-sample
  statistics arithmetic (a singleton `%log_messages` entry measures ~2.3 KB,
  of which the durations array is ~3%).
- For statistics with an eligibility floor (std_dev/cv at n≥2, shape at n≥4
  plus non-degenerate m2), the eligible population is a small fraction of
  the key population (n≥2 keeps ~3%; n≥4 far less).
- For percentiles/min/max/mean on access logs, every line carries a
  duration, so the mathematically-defined population is the full 600k —
  `-so p99` descending at high cardinality is the one heavy case.

### The sort contract (behavior change, replaces undef-sorts-as-zero)

Statistics are derived from durations; a key with no data for the sort
statistic must not be *ranked by* it — generating a rank from nothing is
misleading. The comparator's current `// 0` treatment (undef competes as
zero; under `-sa` duration-less keys flood the top) is replaced by:

1. **Defined block first**: keys with a defined value for the sort statistic,
   ordered by that value in the requested direction (`-sa` applies here —
   ascending means "smallest defined value first", never "undefined first").
2. **Fill block second**: keys without a defined value stay in the reference
   set (the analyst did not ask to filter them out). Remaining top-N slots
   are filled from them ranked by **occurrences**, reusing the existing
   occurrences-sort conventions unchanged.
3. **Tiebreaker is the message key, everywhere, unchanged.** The secondary
   sort field is #302-tuned (significant performance work went into sorting
   this hash); do not introduce a different tiebreak rule.
4. **No notice/warning output** when the fill block appears — the blank
   statistic column on fill rows is the signal.
5. Follow the principles already present in the sorting code wherever this
   contract is silent; do not invent new ordering rules that create
   incoherence with the existing implementation.

**Correctness bar**: output identity to *this documented contract* (the
previous byte-identity-to-current-behavior bar is overturned by the contract
change). Existing `-so` expectations/baselines are re-blessed against it.
Enforcement: `-so` scenarios in `tests/validate-statistics-demand.sh` with a
prove-can-fail sabotage record, plus direct diffs against a reference
ordering during development.

### Eligibility: defined vs. meaningful — and a flagged open nuance

For this issue, "defined" is the code's mathematical contract: percentiles /
min / max / mean from n≥1 (a single sample *is* its own p99), std_dev/cv
from n≥2, shape moments from n≥4 with non-degenerate m2. Eligibility is
determinable from already-stored observation counts **before** any statistic
is computed — the defined/fill split is free.

> **OPEN DESIGN NUANCE — minimum-sample statistical meaningfulness
> (follow-up, deliberately not resolved here).** A pNN value computed from
> one sample is mathematically defined but is not a tail estimate: it is the
> duration of one request wearing a percentile's name. Sorting `-so p99`
> descending on an access log therefore ranks one-off slow requests above an
> API called 200,000 times with a genuinely bad tail — which may be signal
> or chaff depending on the hunt. Any future gate must make statistical
> sense **per statistic, scaled to its number of nines**: a p99 says little
> below ~100 samples, p999 below ~1000, p9999 below ~10000; min/max/mean are
> honest from n=1; std_dev/cv from n≥2; shape from n≥4. Candidate shapes for
> future work: fixed per-statistic floors (extending the existing shape-gate
> idiom), an analyst-controlled threshold, or leaving ranking permissive and
> treating filtering as a separately expressed concern. Interacts with the
> defined/fill contract above (a gate moves keys from the defined block to
> the fill block) and with pool sizing (any floor shrinks the heavy
> `-so p99` population drastically). Future statistic-sort and
> statistic-display enhancements must consult this paragraph.

### Design sequencing: two-pass first, proxy pool as contingency

**Committed scope** — implement and measure before any further machinery:

1. **Eligibility split** from stored observation counts: partition keys into
   defined/fill blocks with no statistics computed.
2. **Population pass (defined block only)**: compute only the sort
   statistic's group via a minimal per-call #305 demand descriptor. The
   descriptor is per-call precisely to permit this without reworking the
   registry. At production shape this alone collapses shape/std_dev/cv sorts
   from 600k keys to the eligible few thousand.
3. **Top-N pass**: full demanded statistics for the displayed keys only
   (defined-block winners plus fill-block rows).
4. Measure at production scale (targeted runs, median of 3): the residual
   heavy case is `-so p99` descending over a fully-eligible high-cardinality
   population.

**Contingency scope** — only if the measured `-so p99` turn remains
unacceptable: a candidate-pool prefilter using a cheap safe bound before the
population pass. Preserved analysis for that eventuality:

- `max` is a safe upper bound for any percentile (pNN ≤ max), tight for tail
  percentiles, loose for central ones (p25/p50/p75; `mean` predicts those
  better but is not a safe bound). Ascending sorts mirror to `min`
  (pNN ≥ min).
- Bin mode (`-mdm bin`) already maintains exact per-key min/max
  incrementally — the proxy is free there. Raw mode needs an at-sort-time
  O(n) scan per key (~38× cheaper than full stats pre-#305; re-measure).
- Maintaining min/max at parse time was prototyped in #302 and rejected
  (~2% on `read_files` paid by every run) — consistent with the #306
  standing guidance that the read loop is the most expensive place to add
  anything; scan at sort time only when the sort needs it.
- Pool sizing must anchor at the display cut including ties (the #302
  lesson). Safety verification (no excluded key's bound beats the value at
  the cut) and expansion policy are designed only if this contingency is
  ever built.

### Premise re-validation (mandatory before implementing)

All quantitative claims in the issue body predate #305 and are re-measured
on the current branch before implementation: the ≈2× `calculate_statistics`
cost (0.82s vs 0.41s at 21.7K keys) was measured when every invocation
computed the full ladder — post-#305 a terminal-only `-so p99` run computes
only `terminal_core` population-wide, so the gap has likely narrowed; the
~38× max-scan microbench likewise assumed full-ladder compute. Probe
protocol: dev-scale targeted runs using the per-store `stats_calls` /
`group_calc computed/skipped_demand/ineligible` counters (landed on this
branch) as the demanded-work denominator, per the #306 lesson.

#### Probe results (2026-07-13, this branch)

Workload: `-iqs` on `localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt`
(148 MB, 22,244 message-store keys — reproduces the issue's ~21.7K-key
fixture scale). Terminal-only, `--terminal-width 200`, median of 3,
`-V benchmark-data` timing runs kept separate from `-V statistics-demand`
counter runs. Message-store demand attribution:

| sort              | stats_calls | terminal_core | shape computed / ineligible | calc_stats median (range) | total median |
|-------------------|------------:|--------------:|----------------------------:|--------------------------:|-------------:|
| `-so occurrences` |          10 |            10 |                       0 / 0 |     0.187s (0.185–0.195) |       17.75s |
| `-so p99`         |      22,244 |        22,244 |                       0 / 0 |     0.458s (0.455–0.458) |       18.17s |
| `-so skewness`    |      22,244 |        22,244 |              1,770 / 20,474 |     0.592s (0.591–0.593) |       18.37s |

Findings:

- **The phase-relative gap persists post-#305**: 2.4× for `-so p99`, 3.2×
  for `-so skewness` vs the occurrences pool path. In absolute turn terms
  it is small at this cardinality (~0.27–0.41s of an ~18s read-dominated
  turn, ≈2%); the concern scales with key cardinality (production shape:
  600k keys).
- **Population-pass arithmetic confirms the eligibility-split win**: the
  p99→skewness delta (0.134s for 1,770 shape second-pass computations +
  20,474 eligibility checks) and the occurrences→p99 delta (0.27s for
  22,234 extra terminal_core calls ≈ 12µs/key) attribute cleanly to
  demanded work.
- **Sharpened expectation for the committed scope**: for a terminal-only
  `-so p99`, today's path already computes only `terminal_core`
  population-wide — exactly what the two-pass population pass would compute
  — so the two-pass design yields ~no compute win there (its win is memory
  transience, the #323 coupling). The compute win concentrates on
  shape/std_dev/cv sorts (eligibility collapse: 22,244 → 1,770 here) and on
  CSV-demand runs (population pass computes one group instead of all
  demanded groups). `-so p99` compute remains irreducible without the
  contingency proxy pool — consistent with the design record's "residual
  heavy case" framing.
- Stderr clean across all runs (no runtime warnings).

### Benchmark coverage (issue step 1)

- Two scenarios join `SCENARIOS` in `tests/baseline/run-benchmark.sh`:
  `-so p99` (the heavy fully-eligible percentile path) and `-so skewness`
  (the eligibility-split / shape-pass path). Cross-product 7×7=49 → 7×9=63.
  Both are terminal-only (no `-o`), matching the tuning target.
- Prior baselines lack these scenarios; their first release-to-release
  comparison happens at the next release gate.
- The issue's own before/after measurement uses **targeted** single-file,
  single-scenario runs (median of 3 minimum) — the bundled suite remains a
  release-gate instrument and is not run during issue work.
- Measurement fixture: chosen during the analysis phase once the probe
  establishes what cardinality the question needs (the issue's ~21.7K-key
  constructed fixture was never committed and is not restorable).

### Memory disposition of the population pass

Deferred to measurement, with the direction sharpened by #323: candidate
designs are (a) transient — population-pass values live in a temporary sort
structure, `%log_messages` stores statistics only for displayed keys (the
same storage shape as non-statistic sorts, and the outcome #323 needs); or
(b) storing the sort statistic's field population-wide. Decide on `-mem`
per-structure HWMs measured both ways at production scale.

### Observability

Sort-path lines join the existing `-V statistics-demand` section (defined vs
fill block sizes, per-pass call attribution, contingency-pool counters if
that scope is ever built). Per the test-harness contract, the section
contract in `features/duration-statistics.md`,
`tests/validate-statistics-demand.sh`, and the code change land in the same
commit.

## Relationship to other issues

- **#302/#304** — candidate-pool selection for available-value sorts; the
  tuned two-stage sort and message-key tiebreak are load-bearing and
  unchanged by this design.
- **#305** — the statistics-group demand registry; supplies the per-call
  demand descriptor the population pass uses, and the `-V statistics-demand`
  instrument this issue extends and measures with.
- **#306** — fused moment accumulation, measured and rejected; its standing
  guidance (prefer deferred pool-limited compute over read-loop work)
  constrains this design and rules out parse-time proxy maintenance.
- **#323** — blocked by this issue; supplied the production population shape
  above, and the population-pass memory disposition is the coupling point.

## Status

- Landed on branch `303-calculated-statistic-sort-path`:
  - per-store `stats_calls` + per-group `group_calc` counters in
    `-V statistics-demand` (the before/after instrument);
  - premise re-validation probe (results above);
  - `sort-p99` / `sort-skewness` benchmark scenarios (suite 7×9=63) with
    `compare-results.sh` table columns;
  - the sort contract + eligibility split + two-pass implementation
    (memory disposition (a): population-pass values are transient; the
    `print_message_summary` fallback sort is removed — both sort branches
    record `%message_key_order`);
  - `sort_selection` / `sort_calc` observability lines with feature-doc
    contract and harness assertions (sabotage-proven).
- Implementation notes: the fill block honors `-sa` (the occurrences
  ranking reuses the occurrences-sort conventions including direction);
  the two-stage display-cut comparators are intentionally inlined per
  block, matching the #302 idiom, rather than routed through a shared
  coderef-based helper — coderef comparators measurably tax
  population-scale sorts.
- Next: production-scale measurement (before/after, `-mem` HWMs both
  dispositions) → findings analysis → contingency decision.
