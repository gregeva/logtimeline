# Duration statistics

The duration-statistics capability: the per-entry statistics ladder ltl
computes over observed durations, the stores it is computed for, the
consumer-demand model that decides which parts of the ladder are computed
and stored, and the observability contract (`-V statistics-demand`) that
makes all of it measurable. This document is the owning feature doc for
that capability; issue-scoped docs (investigations, harnesses, data-model
migrations) reference it rather than restating it.

## The statistics ladder and its groups

ltl computes up to 22 duration statistics per entry. They are partitioned
into four statistic groups (`%STAT_GROUP_FIELDS` in `ltl`); the group is
the unit of demand, compute, and storage:

| Group | Fields | Notes |
|---|---|---|
| `terminal_core` | min, p50, p95, p99, p999, cv | Every field any terminal surface reads (timeline latency column; messages-table statistics variant). Demanded whenever the store is. |
| `csv_body` | mean, max, p1, p75, p90, std_dev | Body statistics consumed only by the STATS/MESSAGES CSVs (and `-so` sort keys). |
| `extended_percentiles` | p5, p10, p25, p9999, p99999, iqr | |
| `shape_moments` | skewness, kurtosis, bimodality_coef | Introduced by #222. Require n ≥ 4 (the kurtosis and bimodality formulas divide by (n−2)(n−3)). |

## Stores and primitives

Statistics are computed for two stores, each by one call per entry to a
statistics primitive:

- **bucket** store — one entry per time bucket (`%log_stats`).
- **message** store — one entry per message key (`%log_messages`).

The primitive is selected by the store's effective data model:
`calculate_statistics()` under raw (sorts the entry's durations array and
derives the ladder from it), `calculate_statistics_bin()` under bin
(derives from HDR bin counters and Welford-Pébay sidecars; see
features/287-message-stats-bin-counter-data-model.md and
features/289-bucket-stats-bin-counter-data-model.md). Both take the same
per-call demand descriptor and return only the demanded groups' fields.

## Demand model

Per-store, per-group demand is resolved by
`resolve_statistics_group_demand()` in `ltl` from `@STAT_CONSUMERS`: each
consumer surface (timeline latency column, messages table, STATS/MESSAGES
CSVs, `-so` sort keys) declares the store it reads and the groups it
consumes. Demand gates capture (read-loop accumulators), compute (the
derivation blocks in the primitives), and storage (undemanded statistic
fields are never written onto store entries — the memory lever at high key
cardinality). The demand-registry design, its measurements, and the
decision record live in
features/305-shape-moment-extended-percentile-demand.md (#305).

## -V statistics-demand section contract

Registered section `statistics-demand` (registry + `@verbose_section_order`,
after `percentile-algorithm`), emitted by `emit_statistics_demand_verbose()`
after finalize so counters are final. Harness:
`tests/validate-statistics-demand.sh` (self-documenting assertions per
tests/HARNESS-DESIGN.md). Locked line shapes:

```
=== statistics-demand ===
store: <bucket|message>
  store_demand: <0|1>
  group <name>: demanded=<0|1> consumers=<comma-joined|->
  moment_source: <second_pass|sidecar|none>
  stats_calls: <N>
  group_calc <name>: computed=<N> skipped_demand=<N> ineligible=<N>
  sort_selection: statistic=<field> defined=<N> fill=<N> demoted=<N>
  sort_calc: population=<N> topn=<N>
=== END statistics-demand ===
```

- Group order fixed: terminal_core, csv_body, extended_percentiles,
  shape_moments (both for the `group` demand lines and the `group_calc`
  counter lines). Store order fixed: bucket, message.
- `moment_source` — how the store's shape moments are produced when
  demanded: `second_pass` (raw path O(n) pass — measured cheaper than
  read-loop fusion; see features/305-shape-moment-extended-percentile-demand.md
  § #306 investigation), `sidecar` (bin path Welford-Pébay derivation),
  `none` (shape undemanded or store inactive). Derived from resolved
  configuration in the emitter.
- `stats_calls` — invocations of the store's statistics primitive
  (`calculate_statistics` under raw, `calculate_statistics_bin` under bin),
  counting every call including ones that early-return without deriving
  anything (no occurrences / no durations observed). This is the per-key
  population-cost denominator #303's calculated-statistic sort work
  measures against: a statistic sort drives it to the full key population,
  a pool-path sort to roughly the displayed pool.
- `group_calc <name>` — per-group derivation outcome of those invocations:
  - `computed` — the group's fields were derived (and stored, subject to the
    storage gate). Counts both the raw and bin mechanisms; `moment_source`
    discloses which one a store's shape moments used.
  - `skipped_demand` — the call could have derived the group but its demand
    was not raised: the work demand gating avoided.
  - `ineligible` — the group cannot be derived for that call regardless of
    demand (shape moments require n ≥ 4). Kept separate from
    `skipped_demand` so demand savings are never conflated with
    mathematical ineligibility.
  - `terminal_core` is derived on every non-early-returned call
    (`skipped_demand`/`ineligible` are structurally 0); `stats_calls` minus
    its `computed` is the early-returned no-duration call count. The
    per-group split exists so future per-group compute optionality (e.g.
    #303's two-pass sort computing only the sort statistic's group for the
    population pass) is observable the day it lands.
- `sort_selection` / `sort_calc` — calculated-statistic sort path
  observability (#303). Emitted only for the store where the two-pass sort
  selection ran: the message store, when `-so` names a duration-statistic
  field. Absent on every other run (available-value sorts, bucket store) —
  the absence is contractual and harness-assertable.
  - `statistic` — the resolved sort field (e.g. `p99`, `skewness`).
  - `defined` — keys ranked by the computed sort value (the defined block),
    summed across message categories (highlight + plain).
  - `fill` — keys with no defined value for the sort statistic: below the
    statistic's eligibility floor (percentiles/min/max/mean n ≥ 1,
    std_dev/cv n ≥ 2, shape n ≥ 4), no observed durations, or demoted (see
    below). They keep their place in the reference set and fill remaining
    display slots ranked by occurrences.
  - `demoted` — the subset of `fill` that met the eligibility floor but
    whose sort value computed to undef (degenerate data, e.g. zero-mean
    `cv`, zero-variance shape moments). `demoted` ≤ `fill`; `defined +
    fill` = the store's total key population.
  - `sort_calc population` — pass-1 primitive invocations (defined-block
    candidates, minimal per-call demand: only the sort statistic's group).
    `topn` is derived at emit time as `stats_calls − population`: every
    store call not made by the population pass came from the top-N pass
    (full demanded statistics for displayed keys only).
  `$stats_demand_telemetry_active` gate set in
  `resolve_statistics_group_demand()`): per-key increments in the
  statistics primitives would otherwise tax every run at high key
  cardinality. Whenever the section is emitted the counters were active,
  so emitted values are always complete. Benchmarking implication: when
  timing statistics-phase work with `-V benchmark-data`, do not also
  request `statistics-demand` in the same run.
- Additions are non-breaking; renames/removals are breaking per
  HARNESS-DESIGN.md's stability contract.

## Deferred follow-up: calculated-statistic sort contingency pool (#303)

Not scheduled — recorded here so future statistics work finds it. The #303
two-pass sort computes the sort statistic's group for every
eligibility-passing key (the population pass). A further optimization was
designed but deliberately **not built**: a candidate-pool prefilter using a
cheap safe bound before the population pass — `max` is a safe upper bound
for any percentile (pNN ≤ max, tight for tail percentiles), `min` mirrors
it for ascending sorts; bin mode already maintains exact per-key min/max,
raw mode would scan at sort time only.

Deferral rationale (2026-07-13 measurement, architect-confirmed): after the
two-pass change the marginal cost of the heaviest case (`-so p99`
descending, fully-eligible population) is ≈4.7 µs/key — ≈2.8s extrapolated
to the 600K-key production shape inside a read-dominated multi-minute turn
(~1–2%). Reconsider only if a real-world statistic-sort turn is reported
unacceptable at high key cardinality. The full preserved design analysis
(proxy tightness per metric, pool sizing anchored at the display cut,
safety verification/expansion policy) lives in
features/303-calculated-statistic-sort-path.md § Design sequencing
(contingency scope) and its measurement sections.

Any work resuming this must also consult the flagged open nuance in that
same doc (§ Eligibility: defined vs. meaningful): a minimum-sample
meaningfulness gate would shrink the pool population drastically and
interacts with both the defined/fill contract and pool sizing.

## Related issue docs

- features/305-shape-moment-extended-percentile-demand.md — #305 demand
  registry investigation and decision record (including the #306
  fused-moment rejection).
- features/254-validate-distribution-shape.md — #254 numerical-correctness
  harness for the shape moments.
- features/224-validate-statistics-test-harness.md — #224 tiered-tolerance
  statistics value harness.
- #222 — introduced the shape moments and extended percentiles (predates
  this doc; no dedicated feature doc).
- #303 — calculated-statistic sort path benchmark + optimization; consumer
  of the `stats_calls`/`group_calc` counters above.
