# Statistics-group demand registry (#305)

## Overview

The duration-statistics ladder (min through bimodality_coef) is computed by
`calculate_statistics` (raw data model) / `calculate_statistics_bin` (bin data
model) for two statistics stores: per-time-bucket (`%log_analysis` →
`%log_stats`) and per-message-key (`%log_messages`). Before #305, every
invocation computed and stored the full ladder regardless of whether any
output surface consumed the values. Two costs followed:

- **Compute**: the shape-moment derivation (m2/m3/m4 → skewness, kurtosis,
  bimodality_coef) is an O(n) pass over the sorted samples per key/bucket —
  the dominant per-key cost of `calculate_statistics` and the residual
  +15–27% `calculate_statistics` regression vs v0.14.5 identified in #305.
- **Memory**: every computed statistic is stored as a field on the per-key /
  per-bucket entry. At high key cardinality (hundreds of thousands of
  distinct messages) each unconsumed field is dead weight multiplied by the
  population — measured in the #323 investigation at ~2.3 KB/entry across
  600k+ keys.

#305 introduces a **declarative statistics-group demand registry** that gates
capture, compute, and storage on actual consumer demand. Memory and compute
are equal goals.

## GitHub Issue

https://github.com/gregeva/logtimeline/issues/305

## The demand contract

**A statistic is captured, computed, and stored only when a producer is
active AND at least one output surface consumes it.**

This extends the store-level demand contract introduced by #349 (commit
`eb86f84`), which this document also records since #349 has no feature doc:

### Store-level demand (#349, pre-existing)

One boolean per statistics store, resolved once in
`adapt_to_command_line_options()` after all options (including the `-os`
deprecation fold) are settled:

- `$bucket_duration_stats_demand` — per-time-bucket statistics. Raised by:
  the timeline latency-statistics column (`!$hide_stats && !$heatmap_enabled`
  — the heatmap replaces the column) OR the STATS CSV (`-o`).
- `$message_duration_stats_demand` — per-message-key statistics. Raised by:
  the messages-table statistics variant (`$top_n_messages > 0`) OR the
  MESSAGES CSV (`-o`).

Both require the producer (`!$omit_durations`). Demand is the consumer half
of a conjunction: compute additionally requires observation
(`$durations_observed` / per-sample observation). `-hst/--hide-stats` is
display-only and does NOT suppress capture; `-od/--omit-durations`
suppresses production. Heatmap/histogram consume durations through their own
stores and create no demand here. `-V` sections report resolved state
truthfully whether or not statistics ran, so **-V creates no demand** —
locked decision, inherited by the group level below.

### Statistics-group demand (#305)

The ladder is partitioned into four groups (`%STAT_GROUP_FIELDS` in `ltl`):

| group | fields | rationale |
|---|---|---|
| `terminal_core` | min p50 p95 p99 p999 cv | every ladder field any terminal surface reads: timeline latency column (p50/p95/p99/p999/cv), messages table (min/p50/p999/cv). Demanded whenever the store is, by construction. |
| `csv_body` | mean max p1 p75 p90 std_dev | body statistics consumed only by the CSVs and `-so` sort keys |
| `extended_percentiles` | p5 p10 p25 p9999 p99999 iqr | the #222 extended set; CSV/`-so` only |
| `shape_moments` | skewness kurtosis bimodality_coef | the #222 shape set; CSV/`-so` only; owns the O(n) pass |

Consumer surfaces declare the groups they read (`@STAT_CONSUMERS` in `ltl`):

| consumer | store | active when | groups |
|---|---|---|---|
| timeline-latency-column | bucket | `!$hide_stats && !$heatmap_enabled` | terminal_core |
| stats-csv | bucket | `$write_messages_to_csv` | all four |
| messages-table | message | `$top_n_messages > 0` | terminal_core |
| messages-csv | message | `$write_messages_to_csv` | all four |
| sort-on | message | `$sort_key` is a ladder field | the group containing `$sort_key` |

`resolve_statistics_group_demand()` derives per-store per-group demand from
the declarations (a consumer contributes only when it is active AND its
store's #349 boolean is true), records provenance (`consumers=` in the -V
section; the sort consumer as `sort-on:<field>`), and caches six hot-path
booleans (`$bucket_stats_demand_{csv_body,extended,shape}` and the message
equivalents). `-so` thereby becomes an **explicit demand contributor**:
sorting on a statistic guarantees that statistic's group is computed and
stored for every sorted key.

## The three gate classes

Demand gates three distinct cost sites; all three matter:

1. **Capture (read loop)** — accumulators are only maintained when a
   demanding group needs them. Raw-path capture was already fully
   store-gated by #349 (sum_of_squares feeds cv = terminal_core; the
   durations array feeds every percentile). The bin path's Welford-Pébay
   moment accumulators (`m2_sum`/`m3_sum`/`m4_sum`: the lazy-init literal
   fields, the per-sample update, and the `merge_bin_state` moment-merge
   arithmetic) run only under shape-group demand. `duration_count` and
   `_running_mean` stay unconditional — core derivation and the parallel
   merge consume them.
2. **Compute (finalize)** — `calculate_statistics` /
   `calculate_statistics_bin` take a demand descriptor
   `{ csv_body => 0|1, extended => 0|1, shape => 0|1 }` (terminal_core is
   always computed). The raw O(n) shape pass, the extended percentile index
   reads / `percentile()` calls, and the shape derivation are skipped when
   ungated. Cheap scalars other demanded statistics derive from (mean,
   std_dev, p75 for iqr) are computed regardless of their own group's
   demand — intermediates are free; the gates target the O(n) pass and the
   stored fields.
3. **Storage (the memory lever)** — both primitives return a **hashref of
   only-computed fields** (the positional 22-tuple is gone). The store sites
   merge that hashref into the entry (`%$stats` in the `%log_stats{$bucket}`
   literal; a hash-slice write onto `%log_messages{...}`), so undemanded
   statistic fields are **never written**. Absent fields read as undef —
   identical downstream semantics to the old present-with-undef contract
   under `defined`/`//` guards.

## Output-compatibility invariants

- **Demand OFF (terminal-only runs)**: rendered output is byte-identical to
  pre-#305 — no terminal surface reads a gated field. Verified by direct
  diff and `validate-regression.sh`.
- **Demand ON (any `-o` run; `-so <statistic>`)**: CSV bytes are identical to
  pre-#305 — a CSV being active is precisely what raises full demand, so the
  columns always populate. The CSV column *set* never changes.
- Fields whose value is legitimately undefined under demand (std_dev at n<2,
  shape moments at n<4 or degenerate m2) remain present-with-undef.

## -V statistics-demand section contract

Registered section `statistics-demand` (registry + `@verbose_section_order`,
after `percentile-algorithm`), emitted by `emit_statistics_demand_verbose()`
after finalize so counters are final. Harness:
`tests/validate-statistics-demand.sh` (5 scenarios; self-documenting
assertions per HARNESS-DESIGN.md). Locked line shapes:

```
=== statistics-demand ===
store: <bucket|message>
  store_demand: <0|1>
  group <name>: demanded=<0|1> consumers=<comma-joined|->
  moment_source: <second_pass|sidecar|none>
shape_pass: executed=<N> skipped=<N>
=== END statistics-demand ===
```

- Group order fixed: terminal_core, csv_body, extended_percentiles,
  shape_moments. Store order fixed: bucket, message.
- `moment_source` — how the store's shape moments are produced when
  demanded: `second_pass` (raw path O(n) pass), `sidecar` (bin path
  Welford-Pébay derivation; the raw path also becomes `sidecar` when #306
  lands), `none` (shape undemanded or store inactive). Derived from resolved
  configuration in the emitter.
- `shape_pass` counters count **only the raw path's O(n) second pass**:
  `executed` = invocations that ran it; `skipped` = invocations with n≥4
  whose shape group was undemanded. The bin path's O(1) derivation is
  deliberately not counted — its story is `moment_source: sidecar`. These
  counters are the observable proof that demand gating skips work.
- Additions are non-breaking; renames/removals are breaking per
  HARNESS-DESIGN.md's stability contract.

## Sorting and the top-N landscape (context for demand's compute impact)

- **Non-statistic sorts** (default `occurrences`, etc.): the #302/#304
  two-stage candidate-pool selection already limits per-message statistics
  to the top-N pool — demand gating changes little for the message store on
  such runs (but fully gates the bucket store, which `-n` never limits).
- **Statistic sorts** (`-so p99`, `-so skewness`, …): `@top_keys` is every
  key — the full ladder is computed and stored for the entire population,
  then sorted. The demand registry bounds this to the demanded groups (the
  4-group split saves the csv_body/extended/shape fields per key when only
  the sort statistic's group is needed), but the population-wide compute
  remains **#303's territory**: a two-pass approach (pass 1 computes only
  the sort statistic's group for all keys, pass 2 full demand for the top
  N). The demand descriptor is per-call precisely so #303 can pass different
  descriptors per pass without reworking this registry.

## How future statistics-surface reduction plugs in

The registry is the single declaration of which surface consumes which
statistics. Reducing a surface's statistic set (e.g. dropping columns from a
CSV) becomes an edit to that surface's `groups` declaration (or a group's
field list) — capture, compute, and storage follow automatically. Note the
inverse implication: with gating in place, unconsumed statistics cost
nothing, so any future reduction decision is purely about user-facing
surface complexity, not performance.

## Relationship to other issues

- **#349** — the store-level demand contract this extends (recorded above).
- **#222** — introduced the shape moments and extended percentiles; #305
  gates their cost on demand without regressing the feature.
- **#302/#304** — the two-stage candidate-pool selection (fewer keys); #305
  is less work per key.
- **#303** — population-wide compute on statistic sorts; enabled by the
  per-call demand descriptor, not solved here.
- **#306** — replaces the raw path's O(n) shape pass with incremental
  Welford-Pébay sidecars when shape IS demanded; shape-group demand gates
  that capture (the #305/#306 interlock). See
  features/189-histogram-bin-counter-primitives.md for the sidecar/merge
  machinery.
- **#323/#354** — the memory investigations that established per-key field
  cost at scale; the storage gate is this design's contribution to that
  reduction line.

## Validation

- `tests/validate-statistics-demand.sh` — the section contract (5 scenarios:
  terminal-only, `-o` full demand, `-so skewness`, heatmap bucket-store
  suppression, runtime-config cross-check), with a prove-can-fail sabotage
  demonstration recorded in the #305 PR.
- Demand-OFF byte-identity: terminal output diff vs branch point +
  `validate-regression.sh`.
- Demand-ON byte-identity: `validate-csv-output.sh`,
  `validate-statistics.sh` (L1/L2/L3 — all scenarios use `-o`, so full
  demand: unchanged), `validate-distribution-shape.sh`.
- Memory: `-mem` per-structure HWMs before/after on a large node file
  (terminal-only and `-so p99` variants).
- Performance: `benchmark-data` TIMING `calculate_statistics` vs
  `tests/baseline/results/v0.14.5.tsv` via
  `tests/baseline/compare-results.sh` (±5% acceptance on
  month-many-servers-standard per the #305 verification criteria).
