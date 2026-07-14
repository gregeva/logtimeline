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

Moved to the capability-owning feature doc: see
features/duration-statistics.md § -V statistics-demand section contract for
the locked line shapes and the semantics of every emitted key and counter.
This doc retains only the #305-specific decision record (the demand
registry, the gate classes, and the #306 investigation below).

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

## #306 investigation — fused moment accumulation: measured and rejected

#306 proposed fusing the raw path's m2/m3/m4 accumulation into the read loop
(Welford-Pébay sidecars, as the bin path does) to eliminate the second O(n)
traversal in `calculate_statistics`. The fusion was **fully implemented and
proven numerically correct** (drift confined to exactly
skewness/kurtosis/bimodality_coef at ≤1.6e-13 relative — running-mean vs
final-mean centering; L3 NumPy/SciPy oracle green on all 18 scenarios;
terminal output byte-identical), then **rejected on measured performance**
and reverted. The full record is on the #306 issue; the durable findings any
future change to this code path must be weighed against:

**Measured result** (median of 3, ranges non-overlapping; single-day Tomcat
log, 761,698 lines; base = post-#305 two-pass, head = fused):

| configuration | read_files | calculate_statistics | total | log_messages |
|---|---|---|---|---|
| `-o` (both stores demand shape) | +9.0% (+1.60s) | −46.6% (−0.149s) | **+8.0%** | **+12.5%** |
| `-so skewness` (message store only) | +5.1% (+0.91s) | −28.5% (−0.111s) | **+4.4%** | +12% |

**Attribution** (the two configurations isolate the mechanism — they differ
only in how many stores run the per-line update): one Welford update costs
**~1.0–1.2 µs per sample** (+0.91s/762k lines at one store; +1.60s at two);
the second-pass loop it replaced costs **~0.15 µs per element** (the
measured `calculate_statistics` savings over the same populations). **The
fused update is ~7–8× more expensive per element.**

**Mechanism**: the second pass is 3 lexical-scalar multiply-adds over a
contiguous, already-sorted array — the sort is paid for percentiles
regardless — i.e. near-optimal Perl. The Welford update performs 5–6
hash-field reads/writes per sample (string-keyed lookups) plus an FP
division; in Perl, hash traffic dominates arithmetic. Memory: the sidecars
add 5 numeric fields to **every** observed key (capture is population-wide),
while statistics are computed only for the top-N pool on non-statistic sorts
— +12% on `log_messages`, the dominant structure.

**Ceiling analysis**: collapsing the 5 hash fields into one arrayref field
would roughly halve the update (~0.5–0.6 µs) — still ~4× the pass. Both
sides scale linearly with sample count, so the constants decide at every
scale; no optimization within the fused design beats the two-pass.

**Why the premise failed**: #306 was written pre-#305, when the pass ran
unconditionally for every key on every run, and assumed extending the
`sum_of_squares` pattern (one field `+=`) to three moments was the same
cost class. Post-#305: undemanded runs skip the pass entirely (measured
`calculate_statistics` beats the v0.14.5 baseline by 13–16% on all seven
month-single-server scenarios), and demanded runs are at v0.14.5 parity by
construction (v0.14.5 also computed everything). **The +15–27% regression
that motivated #302/#305/#306 is fully accounted for by #304 (sort
comparator) + #305 (demand gating); no residual remains for #306.**

**Standing guidance for this code path**:
- The raw path keeps the demand-gated two-pass; do not fuse moment
  accumulation into the read loop without new evidence that beats the
  per-element arithmetic above.
- The bin path keeps its Welford sidecars — there they are the only option
  (no raw samples) and they buy the elimination of the durations arrays.
- Per-sample work in `read_and_process_logs` is the most expensive place to
  add anything: at ~1 µs per hash-heavy update per line, one added update
  costs ~+5–9% total wall-clock on access-log workloads. Prefer deferred,
  pool-limited computation at the `calculate_statistics` site.
- The `-V statistics-demand` section (retained) is the instrument that made
  this measurable: the per-store `stats_calls` and
  `group_calc <name>: computed/skipped_demand/ineligible` counters give the
  demanded-work denominator and `moment_source` names the mechanism per
  store — use them for any future attribution in this territory.

## Relationship to other issues

- **#349** — the store-level demand contract this extends (recorded above).
- **#222** — introduced the shape moments and extended percentiles; #305
  gates their cost on demand without regressing the feature.
- **#302/#304** — the two-stage candidate-pool selection (fewer keys); #305
  is less work per key.
- **#303** — population-wide compute on statistic sorts; enabled by the
  per-call demand descriptor, not solved here.
- **#306** — proposed replacing the raw path's O(n) shape pass with
  incremental Welford-Pébay sidecars. **Implemented, measured, and
  rejected**: the fusion is a net loss on both time and memory in the
  post-#305 world — see § #306 investigation below for the attributed,
  validated findings that any future change to this code path must be
  weighed against. The bin path's sidecar/merge machinery (which rightly
  keeps Welford — it has no raw samples) is in
  features/189-histogram-bin-counter-primitives.md.
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
