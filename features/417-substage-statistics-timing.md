# #417 — Boundary-level sub-stage timing for the statistics phase

Owning doc for the `finalize/calculate_statistics/*` sub-stage `TIMING` rows
and their alignment with the statistics-demand telemetry. Origin: the #415
stats-drift investigation, which needed NYTProf against a v0.16.0 worktree
because the statistics phase is a single opaque `TIMING` number
(`tests/profile/results/415-statsdrift-new/analysis.md`).

## Goal

Version-to-version attribution of statistics-phase cost from the benchmark
TSVs directly: which internal block moved, normalized per element, with no
profiler session and no reliance on remembering what was worked on.

## Hard constraint (from the issue, non-negotiable)

Boundary instrumentation ONLY. Timers are start/stop pairs around whole
blocks — a handful of `Time::HiRes` calls per run. Nothing is added inside
any per-key or per-element loop: no timer calls, no per-iteration counter
increments, no callbacks. A block that cannot be timed at a boundary stays
untimed rather than instrumented inside its loop.

## Locked decisions (planning walkthrough, 2026-08-24)

- **D1 — Block set.** Five timed sub-stages, fixed from the audited
  structure of `calculate_all_statistics`:
  | Sub-stage | Covers |
  |---|---|
  | `bucket_stats` | per-time-bucket loop: aggregation + per-bucket statistics (raw or bin) + per-bucket UDM |
  | `population_walk` | the calculated-statistic sort path's eligibility/sort-value walk over `%log_messages` (that branch only) |
  | `sort_selection` | the sorts that select the top keys — both branches: the occurrences/metric sort, and the `by_stat`/`defined`/`fill` sorts after the walk |
  | `group_calc` | top-keys loop: full per-key statistics + per-message UDM |
  | `threadpool_stats` | threadpool activity statistics |
  The `population_walk` split is deliberate (architect): the walk is the
  block the #415 drift and the `-so p99` degenerate cost (#418) both
  concentrate on. Timers for `population_walk`/`sort_selection`/`group_calc`
  sit inside the per-category loop (two iterations, accumulated) but outside
  every per-key loop.
- **D2 — Always emit, unconditional timers.** All sub-stage rows are emitted
  on every `-V benchmark-data` run, zeros included (`population_walk` is
  0.000 when the calculated-statistic branch never ran) — a row that
  appears/disappears between runs breaks comparison pairing. The timers
  themselves run unconditionally like the existing `elapsed_*` variables:
  gating them on `-V` would make observed runs execute a different code path
  than normal runs.
- **D3 — Derived `untimed` remainder row.** One additional row,
  `finalize/calculate_statistics/untimed`, computed at emission time as
  `max(0, parent − sum_of_substages)` — never measured. Every run's rows are
  self-coherent: sub-stages + untimed = parent exactly at printed precision;
  the clamp guarantees sub-stages never exceed the parent (requirement 4).
- **D4 — Full counter alignment; no gaps.** Every timed sub-stage has a
  documented element-count denominator (alignment table below). The two
  missing denominators are added as block-level counts (one `scalar keys`
  each, taken at the block boundary — zero in-loop cost).
- **D4a — One source, two surfaces (architect, 2026-08-24).** Per
  `tests/HARNESS-DESIGN.md` § "Counters serving benchmark attribution":
  each new count is computed ONCE at its block boundary, exposed in the
  owning functional `-V` section (`statistics-demand` — the statistics
  phase's calculation-telemetry home; the threadpool population lands there
  too, as no threadpool section exists) as the development-time assertion
  surface, and re-emitted by `benchmark-data` as a `COUNTS` row reading the
  same variable. `benchmark-data` computes no duplicate. The existing
  `COUNTS log_messages_entries` (final structure state at emission time) is
  a different quantity from the walk-time population and stays untouched;
  the walk-time message population is exposed under the new pattern.
- **D5 — Nomenclature.** Row labels extend the #180 `stage/step` scheme to
  `stage/step/sub_step` (`finalize/calculate_statistics/<sub_stage>`).
  Recorded in `features/180-named-pipeline-stages.md`, which owns the TIMING
  nomenclature.
- **D6 — No comparison-script changes here.** The new rows arrive under
  #416's "new in this version" handling; rollup treatment of sub-stage rows
  is #416's scope (cross-referenced on that issue, 2026-08-24).

## Alignment table (sub-stage row ↔ element-count denominator)

| Sub-stage row | Denominator (computed once at the block boundary) | Functional surface (`-V statistics-demand`) | Attribution surface (`-V benchmark-data`) |
|---|---|---|---|
| `bucket_stats` | buckets iterated | `store: bucket` → `population: <n>` (new) | `COUNTS log_analysis_entries` (new, same variable) |
| `population_walk` | keys walked (walk-time) | `store: message` → `population: <n>` (new); outcome split in `sort_selection: defined=/fill=` (existing) | `COUNTS log_messages_population` (new, same variable) |
| `sort_selection` | elements sorted | `sort_selection: defined= + fill=` (calculated-statistic branch); `store: message` `population:` (occurrences branch) | same rows as `population_walk` |
| `group_calc` | keys computed | per-group `computed` counts, store=message (existing) | — (existing functional counters; no benchmark duplicate) |
| `threadpool_stats` | threadpool keys (both categories) | `threadpool_population: <n>` (new; no threadpool section exists — statistics-phase telemetry home) | `COUNTS threadpool_entries` (new, same variable) |
| `untimed` | n/a | — | derived remainder (D3) |

Per-element cost for a block = its `TIMING` row / its denominator; a
release comparison diffs that ratio across versions to localize drift.

## -V benchmark-data section contract (additions owned by this doc)

`-V benchmark-data` has no single owning contract doc today; this doc owns
the rows this change adds. Additions are non-breaking per
`tests/HARNESS-DESIGN.md` § Stability contract.

New `TIMING` rows, emitted immediately after `TIMING	finalize/calculate_statistics`,
same `TIMING\t<label>\t%.3f` shape, fixed order:

```
TIMING	finalize/calculate_statistics/bucket_stats	<s.mmm>
TIMING	finalize/calculate_statistics/population_walk	<s.mmm>
TIMING	finalize/calculate_statistics/sort_selection	<s.mmm>
TIMING	finalize/calculate_statistics/group_calc	<s.mmm>
TIMING	finalize/calculate_statistics/threadpool_stats	<s.mmm>
TIMING	finalize/calculate_statistics/untimed	<s.mmm>
```

Semantics: each measured row is wall-clock accumulated across that block's
boundary start/stop pairs (per-category blocks accumulate over the two
categories); `untimed` is the derived clamp-at-zero remainder (D3). All six
rows always present (D2). Sub-stage rows are NOT included in `TIMING total`
(their time is already inside `finalize/calculate_statistics`).

New `COUNTS` rows, in the existing "Hash entry counts" block alongside
`log_messages_entries` — each re-emits (never recomputes) the boundary
population variable per D4a:

```
COUNTS	log_analysis_entries	<n>       # time buckets iterated by bucket_stats
COUNTS	log_messages_population	<n>     # message keys at walk time (differs from log_messages_entries: final structure state)
COUNTS	threadpool_entries	<n>        # threadpool keys iterated by threadpool_stats (both categories)
```

## -V statistics-demand additions (contract owner: features/duration-statistics.md)

New lines (additions, non-breaking), semantics to be recorded in
`features/duration-statistics.md` § -V statistics-demand section contract in
the same change as the code:

```
store: bucket
  population: <n>          # time buckets iterated by the bucket_stats block
store: message
  population: <n>          # message keys at population-walk/sort time
threadpool_population: <n> # threadpool keys (both categories); phase-level line
```

## Validation plan / merge gate

1. **Zero in-loop cost** — primary proof is diff review (every added
   statement outside loop bodies, visible from the patch); plus median-of-3
   before/after on the #415 short construct showing the parent row unmoved
   within noise.
2. **Coherence** — on real runs (default sort, `-so p99`, threadpool-bearing
   log): sub-stages + untimed = parent at printed precision, untimed ≥ 0.
3. **Alignment behavior** — `population_walk` 0.000 on default-sort runs,
   nonzero under `-so <statistic>`; rows and their denominators move together.
4. **Harnesses** — `tests/validate-regression.sh` and
   `tests/validate-statistics-demand.sh` (consumers of the touched
   surfaces) pass; full suite reserved for the release gate.
5. **Records** — this doc, the D5 note in
   `features/180-named-pipeline-stages.md`, and the new population lines in
   `features/duration-statistics.md` § statistics-demand section contract
   (D4a) — all in the same change as the code. The one-source-two-surfaces
   rule itself is already recorded in `tests/HARNESS-DESIGN.md`.
6. Release-notes bullet at merge time: yes (user-observable `-V` output).

## Composition

- #416 (comparison rollups): consumes the new rows; rollup is its scope (D6).
- #415 (stats-drift, on hold, blocked_by this): resumes as a TSV diff once
  this lands; branch merges back into `415-calculate-statistics-drift`.
- #418 (degenerate-case sort cost): `population_walk`/`sort_selection` rows
  quantify the case it describes.

## Implementation record (2026-08-24)

Implemented per plan; every added statement sits outside loop bodies (16
timer calls per run, accumulated across the two categories). Validation:

- **Zero in-loop cost**: median-of-3 ABAB on the high-cardinality construct
  (~288k lines, ~287k unique keys), pre-change vs post-change binaries:
  `finalize/calculate_statistics` 0.304s (0.300–0.323) → 0.299s
  (0.295–0.306); `total` 2.864s → 2.865s. Within noise, both directions.
- **Coherence**: default sort 0.307 (sort_selection) + 0.012 (untimed) =
  0.319 = parent; `-so p99` 0.261 (population_walk) + 0.252 (sort_selection)
  + 0.012 = 0.525 vs parent 0.524 — sub-1ms independent-rounding skew is the
  expected tolerance at %.3f; raw values cohere by construction (D3).
- **Alignment behavior**: `population_walk` 0.000 under the default sort,
  0.261s under `-so p99` on the same input; populations correct on both a
  duration-bearing fixture (bucket population 1) and the no-durations
  construct (bucket population 0 — `%log_analysis` holds duration-bearing
  buckets only; the denominator honestly counts what the block iterates).
- **Harnesses**: `validate-statistics-demand.sh` 48/48,
  `validate-regression.sh` 46/46, both exit 0. Zero runtime warnings on all
  probe runs.
- The instrument already reproduces the #415/#418 findings without a
  profiler: the `-so p99` cost lands 0.261 walk / 0.252 fill-sort on a
  population with zero eligible contenders.
