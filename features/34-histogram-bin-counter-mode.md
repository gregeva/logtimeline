# Feature: Histogram bin-counter accumulation for heatmap and histogram

## Overview

Heatmap and histogram today retain every per-line metric value in memory (`%heatmap_raw{$time_bucket}` and `%histogram_values{$metric}`) so that bin boundaries can be computed from the observed min/max **after** the file is fully read. This feature introduces an alternative accumulation path in which per-bin integer counters — **histogram bin counters** — replace those per-line value structures when the bin boundaries can be known **before** the read pass begins.

The condition that makes that possible is index read-back (#179): when a prior run's bounds are pre-seeded into in-memory state at start-up, ltl can compute logarithmic bin partitions up front and tally each parsed value directly into a histogram bin counter. No per-line values are retained.

The feature is therefore a conditional gate: **histogram bin-counter mode** activates as a single all-or-nothing decision per run, evaluated against the filter context and index pre-seed availability. When eligible, both heatmap and histogram run in histogram bin-counter mode for the duration of that run. When ineligible, both run in raw-value mode unchanged.

This feature also establishes the foundation-laying work for a broader harmonization of histogram bin-counter primitives across all of ltl's percentile-computing paths. Histogram bin counters are intended to serve heatmap rendering, histogram rendering, and (progressively, per #187) the summary-table per-message latency percentile calculation. The unified primitives are owned by #189 and co-developed with this feature; this feature provides the audit and consumer-side requirements.

## GitHub Issue

[#34](https://github.com/gregeva/logtimeline/issues/34)

## Motivation

For multi-GB log analysis runs (chained daily files, long-window investigations), the raw-value arrays dominate peak memory. The bounds those arrays exist to discover are stable properties of the file (or filter selection) — once captured by the index, they do not need to be re-discovered on subsequent runs. With #179 reading them back at start-up, the raw-value retention has no remaining purpose for those runs.

A second motivation is architectural: the same histogram bin-counter primitives can serve multiple downstream consumers, including the per-message latency percentile calculation that #187 will progressively migrate. Designing the primitives once, with full understanding of all future consumers, avoids ad-hoc divergence and rework. That harmonization design lives in #189 and depends on the audit deliverable in this feature.

## Delivery sequence

This feature is one of three co-developed issues (#34, #187, #189). The work is performed in parallel against the `release/0.14.5` branch, with each issue's feature branches merging back periodically. The ordering below is the *delivery* sequence — when each step's output is required to be complete — not a strict serial work order.

| Step | Work | Owner | Why this position | Status of this file |
|---|---|---|---|---|
| 1 | **Audit** — catalogue existing helpers (heatmap, histogram, summary-table percentile paths); produce consumer-side primitive requirements | **#34 R12** + **#187 R12**; outputs land in **#189** *Audit findings* and *Consumer-side requirements* sections | Both #189's primitive design and #187's algorithm research need to know what shapes the primitives must support. Without this first, primitives risk being designed for two consumers and reworked later. | **This file owns part of this step (R12)** |
| 2 | **Research + prototype** — algorithm comparative study, accuracy report, recommendation memo, prototype | **#187 D1–D5** | Algorithm choice (sketch vs. bin-derived interpolation) determines what #189's percentile-interpolation primitive must do. Performed after audit but before #189 implementation so #189 isn't built blind. | No dependency from this file |
| 3 | **Deliver #189** — implement unified primitives | **#189** | Now informed by both the audit (step 1) and the algorithm choice (step 2). | Consumed by this file at step 4 |
| 4 | **Deliver #34 implementation** — heatmap and histogram consume #189's primitives, including R4 for percentile markers (heatmap) and indicators (histogram) | **#34** | First production consumer of #189. **Gates on full R1–R4** because heatmap percentile markers and histogram percentile indicators (legend values, x-axis ticks) both derive from R4 under bin-counter mode — see amendments to R3 / R4 / R8 and the R12 audit resolution. | **This file's implementation step** |
| 5 | **Deliver #187 Phase 2** — summary-table percentiles consume #189's primitives | **#187 Phase 2** | Second consumer. | No dependency from this file |
| 6+ | **#187 Phases 3–5** — progressively land more consumers (per-time-bucket, highlight-data, future) | **#187 Phases 3–5** | Each phase verifies #189's primitives don't need to change to accept the new consumer. | No dependency from this file |

### Parallelism

Steps 1 and 2 may proceed in parallel once the audit has produced enough consumer-side requirements for the research to evaluate bin-derived interpolation against. Step 3 (#189 implementation) cannot complete until step 2 lands the algorithm choice. Step 4 (this feature's implementation) cannot start until **#189 R1–R4 are all complete**, including the percentile-interpolation primitive (R4): the R12 audit established that heatmap percentile markers and histogram percentile indicators both derive from R4 under bin-counter mode. The earlier scaffolding plan that allowed R4 to land later (as a #187-only concern) is superseded by the R12 audit's resolution.

### Integration

All work lands on feature branches merged into `release/0.14.5` periodically. The release branch is the integration point until the three co-developed issues are individually complete, at which point `release/0.14.5` ships per the standard release process (CLAUDE.md).

## Terminology

Throughout this document, the consistent term for the data structures and the accumulation mode is **histogram bin counters** and **histogram bin-counter mode**. The bare phrase "bin counters" is not used; the qualifier "histogram" names the kind of bin partition (logarithmic histogram-style bins, as today) and distinguishes the approach from other counter-style structures elsewhere in ltl.

## Requirements

### R1 — Two accumulation modes for heatmap and histogram

The system supports two accumulation paths for heatmap and histogram:

- **Raw-value mode** — today's behavior, unchanged. Per-line values accumulate; bin partitions are derived at end of pass; rendering uses the resulting bins.
- **Histogram bin-counter mode** — bin partitions are computed at start of run from pre-seeded bounds; per-line values increment a histogram bin counter directly during the read pass; no per-line value array is allocated.

The selected mode applies uniformly to both heatmap and histogram for a given run (see R10).

### R2 — Mode-selection gate (single, run-level)

A single eligibility decision is made per run, evaluated before the read pass begins. The run is eligible for histogram bin-counter mode iff all of the following hold:

1. Index pre-seed is active for this run (`index_used: yes` per #179).
2. The pre-seed tier matches filter context:
   - Filtered run (any filter option is active that scopes the data set, e.g. `-dmin`, `-i`, `-e`, `-st`, `-et`) requires Tier-1 (`selection`) pre-seed for the active filter signature.
   - Unfiltered run accepts Tier-2 (`file`) pre-seed.
   Tier correctness is owed by #179. If a filtered run reaches this gate with only Tier-2 pre-seed, the run is ineligible (`reason: tier_mismatch`) and the gap is filed against #179 rather than patched at this layer.
3. The bounds required by the active features are populated (non-placeholder) in the pre-seed:
   - When `-hm <metric>` is active: `<metric>_min` and `<metric>_max` must be populated.
   - When `-hg` is active: for each metric the histogram will render, the corresponding `min` / `max` must be populated.
   - When both are active: the union of the above must be populated.

When any criterion fails, raw-value mode runs for the whole run (R10).

### R3 — Bin partition computation in histogram bin-counter mode

When eligible, each consumer's bin partition is computed once at start of run using the existing logarithmic formula `min * (max/min)^(i/num_buckets)` for `i in 0..num_buckets`. The formula, the per-consumer bucket-count determination, and the resulting bin semantics are unchanged from today (R11). Only the timing of computation moves earlier — from end-of-pass to start-of-pass.

The partition is then a stable input to the per-line accumulation in R4 (per-line) and to the end-of-pass percentile derivation in R4-bis below.

### R4 — Per-line accumulation in histogram bin-counter mode

During the existing single read pass, each parsed value for an active metric is assigned to a bin index against the pre-computed partition and the corresponding counter is incremented. No per-line value array is allocated for the metrics that drive heatmap or histogram rendering.

### R4-bis — Percentile-marker and percentile-indicator derivation under bin-counter mode

The raw value arrays (`%heatmap_raw`, `%histogram_values`) that today's code sorts to compute percentile markers (heatmap row overlays `%heatmap_percentiles`) and percentile indicators (histogram legend values `%histogram_stats{$metric}{p*}` and x-axis tick positions) are not allocated under bin-counter mode. The R12 audit identified this as the open question on this feature's implementation. **Resolution: under bin-counter mode, both consumers derive percentile values from #189 R4 (the percentile-interpolation primitive), at end of pass, against the bin counters R4 (per-line) populated.**

Specifically:

- **Heatmap row markers** (P50, P95, P99, P99.9): per time bucket, invoke #189 R4 against `%heatmap_data{$bucket}` for each target quantile. Map the returned numeric value to a bin index via #189 R2 (or the heatmap consumer's equivalent). Store the bin index in `%heatmap_percentiles{$bucket}` as today. Rendering is unchanged downstream.
- **Histogram legend values and x-axis tick positions** (P1, P10, P25, P50, P75, P90, P95, P99, P99.9, P99.99): per metric, invoke #189 R4 against `%histogram_buckets{$metric}` for each target quantile. Store the numeric value in `%histogram_stats{$metric}{p*}` as today. Rendering and tick positioning (via `calculate_histogram_percentile_ticks`) are unchanged downstream.

Accuracy implications:

- The accuracy of these percentile values is bounded by #189 R4's accuracy contract (set by #187 D3). R8 (render equivalence) is satisfied to within R4's accuracy bound for both consumers.
- The wider histogram percentile set (10 values, including P99.99) is supported by #189 R4. R4's percentile-set support requirement must cover both the heatmap set (4 values) and the histogram set (10 values).

Delivery implication:

- This feature's implementation step (delivery sequence step 4) gates on #189 R4 being available, in addition to R1–R3. Step 4 cannot begin until #187 D3 has fixed the algorithm choice and #189 has implemented R4 against it. The Delivery sequence table is updated accordingly.

### R5 — Out-of-range handling

Values falling outside the pre-seeded bounds are tallied into out-of-range counters:

- Values below the pre-seeded `min` increment `out_of_range_low` (per metric for histogram; per metric per time bucket for heatmap).
- Values above the pre-seeded `max` increment `out_of_range_high` analogously.

Out-of-range tallies must:

- Be reported in `-V` (see R8).
- Propagate to #179's drift detection so the index entry is refreshed at end of run.
- Not retroactively widen the bin partition during the current run. The rendered axis for the current run remains the pre-seeded one.
- Trigger **exactly one stderr warning per run** when any out-of-range value is encountered (see R6). One warning per run, not per bucket and not per metric in separate lines.

### R6 — Single end-of-run warning when bounds were insufficient

When out-of-range values exist for any metric in a run that ran in histogram bin-counter mode, ltl emits a single warning to stderr summarizing the condition. The warning:

- Is emitted exactly once per run (not per bucket, not per value).
- Names each metric and direction (low / high) that had any out-of-range values.
- States plainly that the pre-seeded bounds did not cover the live data and that bin determination was therefore suboptimal for that run.
- States that the index has been refreshed (per #179) and that re-running will produce correct bins.

The warning is a data-quality signal to the user, not a debug aid. Out-of-range counts (with per-time-bucket breakdown for heatmap) remain in `-V` as diagnostic detail.

### R7 — Live bound capture continues in histogram bin-counter mode

The live `min` / `max` capture that #179 relies on for drift detection must continue running alongside histogram bin-counter accumulation. Only the per-line value array allocation is eliminated.

### R8 — Render equivalence

When pre-seeded bounds match observed live values exactly, rendered heatmap and histogram output in histogram bin-counter mode is equivalent to raw-value mode for the same input. "Equivalent" means:

- **Bin counts and bar-graph rendering are byte-identical.** Same bin partition, same value-to-bin assignment, same counts per bin.
- **Heatmap percentile markers and histogram percentile indicators are equivalent within #189 R4's accuracy bound** (set by #187 D3). Bin-counter mode derives these via R4 against the bin counters (per R4-bis); raw-value mode derives them by sorting the raw arrays. The two derivation paths are not byte-identical at the value level, but the rendered output (marker bin index for heatmap; numeric value displayed in histogram legend; column position for x-axis tick) is within R4's documented accuracy contract.
- Any deviation between modes that exceeds R4's accuracy bound is a bug in R4 or its consumer, not an acceptable render difference.

When raw-value mode runs (any ineligible scenario), rendered output is byte-identical to today's pre-feature implementation.

The new scenario suite (see Validation) asserts the equivalence-within-accuracy-bound contract; the existing regression suite asserts the raw-value-mode byte-identity.

### R9 — `-V` observability of mode selection and out-of-range activity

A dedicated section in `-V` output, named `=== HISTOGRAM BIN COUNTER MODE ===`, reports:

- **Layer 1 — Run-level summary**: `mode` (`histogram_bin_counter` | `raw_value` | `not_active`) and `reason` (see R10 reason codes). `not_active` applies when neither `-hm` nor `-hg` is requested.
- **Layer 2 — Per-feature partition detail**: for each active feature, one block reporting `feature` (`heatmap` | `histogram`), the metric(s) being partitioned, `num_buckets`, `boundary_min`, `boundary_max`. When both features are active, both blocks appear with their independently computed partitions (R11).
- **Layer 3 — Out-of-range report**: emitted whenever `mode: histogram_bin_counter`. Reports `out_of_range_low` and `out_of_range_high` per metric (totals). For heatmap, additionally reports per-time-bucket breakdown for any time bucket where out-of-range counts are non-zero.
- **Layer 4 — Drift cross-reference**: a single line pointing to #179's drift section, since drift detail is owned there.

The section name and all labels are part of the feature contract and stable across implementations.

### R10 — All-or-nothing per run; co-eligibility of heatmap and histogram

The eligibility decision is **a single per-run decision**, not per-feature and not per-metric:

- If R2 succeeds, the run is in `mode: histogram_bin_counter`. Both heatmap and histogram (if requested) use histogram bin-counter accumulation.
- If R2 fails, the run is in `mode: raw_value`. Both heatmap and histogram (if requested) use today's raw-value accumulation.

There is no mixed-mode run. The rationale is that the source data and the filter context determine eligibility, not the individual feature: when the pre-seed is available and matches the filter context, all consumers of pre-seeded bounds benefit; when it is not, none can.

Reason codes reported in `-V` Layer 1:

- `histogram_bin_counter_eligible` — R2 succeeded; `mode: histogram_bin_counter`.
- `no_index` — R2.1 failed.
- `tier_mismatch` — R2.2 failed.
- `missing_bound` — R2.3 failed (including degenerate `min == max` and non-positive values that make logarithmic partitions undefined).
- `not_active` — neither `-hm` nor `-hg` requested.

Additional reason codes may be introduced if a future requirement adds a new gate criterion. Each reason code must map to a single, testable cause and be observable from `-V` alone.

### R11 — Heatmap and histogram have independent bin partitions

Although heatmap and histogram are co-eligible (R10) and use the same accumulation approach (R3), they compute their bin partitions **independently**:

- Heatmap and histogram each have their own bucket count (already determined today by their respective bucket-count determination logic). That logic is in place and is not changing in this feature.
- Heatmap and histogram each have their own visual width configuration (the existing width-control properties), driving display rendering independently.
- The bin partitions themselves are computed independently per consumer, even when both consume bounds for the same metric, because the bucket count drives different partition arrays.

The shared piece is the *approach* and the *underlying primitive operations* (R12), not the partition arrays.

### R12 — Harmonization audit and unified-primitives plan (foundation for #189)

This feature includes a foundation-laying deliverable for #189 (unified histogram bin-counter primitives):

- **Audit**: catalogue the existing helper functions touching bin-partition computation, per-value bin assignment, counter increment, and (where applicable) percentile derivation, across heatmap, histogram, and the summary-table per-message latency percentile path.
- **Consumer-side requirements**: document what heatmap and histogram need from the unified primitives this feature consumes (#189 defines them).
- **Forward-compatibility statement**: identify which aspects of the histogram bin-counter data structure must remain stable so the per-message latency percentile migration (per #187, multi-phase) can adopt the same primitives without primitive-level redesign.

The audit and consumer-side requirements are written into this feature file (see **Harmonization audit** below) and into `features/189-histogram-bin-counter-primitives.md` (which captures the helper-function contract as its own spec).

The harmonization is not optional and is not deferred to "implementation discretion." It is required because divergent ad-hoc implementations across heatmap, histogram, and the future per-message percentile path would accumulate technical debt at every phase of the multi-phase percentile rollout.

### R13 — Memory behavior in histogram bin-counter mode

When the run is in `mode: histogram_bin_counter`:

- Heatmap per-metric memory must be bounded by `num_buckets × num_time_buckets`.
- Histogram per-metric memory must be bounded by `num_buckets`.

Constant per-bucket per-time-bucket overhead is acceptable; growth proportional to input size is not.

### R14 — No regression in raw-value mode

When the run is in `mode: raw_value` for any reason, behavior is byte-identical to the pre-feature implementation. The existing regression suite (`tests/validate-regression.sh`) must pass byte-identically.

### R15 — Per-message latency percentile arrays unaffected by this feature

The per-message latency percentile arrays used by the summary table (P1..P99.9) are a separate data structure from `%heatmap_raw` and `%histogram_values`. This feature must not alter their behavior in either direction.

The eventual migration of those arrays to histogram bin counters is a multi-phase progressive rollout owned by #187, with #189 providing the shared primitives. This feature lays the foundation (R12) so that migration is possible without primitive-level redesign; it does not perform the migration.

### R16 — Boundaries with other features (this feature does not own)

- Highlight-data accumulation (`%heatmap_raw_hl` and equivalents) — owned by #51.
- Per-message latency percentile dual-mode — owned by #187.
- Unified histogram bin-counter primitives (helper functions, shared data structure contract) — owned by #189.
- Index read-back, tier correctness, drift refresh — owned by #179.
- Shared boundary-array unification between heatmap and histogram — owned by #41 (note: this feature's R11 confirms heatmap and histogram have *independent partition arrays*; whatever #41 unifies must be compatible with that independence).

When an eligibility gap traces to one of those features, it is recorded and filed against the owning issue rather than patched here.

## Harmonization audit

The audit is part of this feature's deliverables (R12). It captures, at the requirements level, what helpers exist today and what the unified primitives in #189 must satisfy.

**Status: complete.** The audit was performed jointly with #187 R12 against `release/0.14.5` HEAD. The full catalogue of `ltl` call sites, the per-consumer constraints, and the cross-cutting constraints live in `features/189-histogram-bin-counter-primitives.md` § **Audit findings** and § **Consumer-side requirements**. The percentile-path portion (sibling deliverable owed by #187 R12) lives in `features/187-histogram-bin-counter-percentiles.md` § **Percentile-path harmonization audit**.

This section summarizes only what is specific to this feature's consumers (heatmap + histogram). The R12 audit's original open question — how heatmap percentile markers are derived under bin-counter mode when `%heatmap_raw` is not allocated — is **resolved** below; the same investigation revealed a symmetric concern for histogram percentile indicators, which is also resolved below.

### Consumers catalogued for this feature

- **Heatmap path**: bin-partition computation (`calculate_heatmap_buckets` `ltl:4791`), per-value bin-index assignment (`find_heatmap_bucket` `ltl:4783`), counter increment per `(time_bucket, bin_index)` (`ltl:4839`, `ltl:4850`), rendering drivers (`print_heatmap_row` `ltl:6378`, `get_heatmap_column_header` `ltl:6265`, `print_heatmap_footer_scale` `ltl:6434`, `format_heatmap_value` `ltl:6242`).
- **Histogram path**: option handling (`handle_histogram_option` `ltl:3487`), bucket-count determination (`calculate_histogram_bucket_count` `ltl:4869`), bin-partition computation + bin-index assignment + counter increment (orchestrated in `calculate_histogram_buckets` `ltl:4908`, with bin-assignment in `find_histogram_bucket_index` `ltl:4890`), rendering drivers (`print_histograms` `ltl:6890` and its helpers `ltl:7071–7559`).

Full per-site catalogue with line-precise references in `features/189-histogram-bin-counter-primitives.md` § Audit findings.

### What heatmap and histogram need from #189's primitives

From this feature's perspective as a consumer (full contract in #189 R1–R11):

- **R1 partition computation**: `(min, max, num_buckets) → partition`. Heatmap passes `num_buckets = $heatmap_width` (default 52, `-hmw`-tunable). Histogram passes one call per active metric with `num_buckets` from the existing `calculate_histogram_bucket_count`. Partition must be computable at **start of pass** when bin-counter mode is eligible (R3 / R4 of this feature).
- **R2 bin assignment**: `(partition, value) → bin_index | overflow_sentinel`. Per-line call in the parse hot path. Algorithm choice (linear vs. binary search — both shapes present today) is #189's discretion; either satisfies R2's correctness contract.
- **R3 counter update** with two distinct key shapes: `time_bucket` (heatmap) and `()` (histogram). Both shapes coexist in the same run because R10 makes the two features co-eligible.
- **Out-of-range tally per key, low and high**. This is **new behavior** — today's bin-assignment helpers silently clamp to in-range indices. #34 R5 / R6 (per-key overflow + single end-of-run warning) and #179's drift detection both depend on it.
- **Counter-store enumeration** for the rendering drivers listed above and for `-V` Layer 2 / 3 reporting (R9).
- **Counter store lifecycle**: per-time-bucket counter stores (heatmap) are freeable once that bucket renders; histogram's single per-metric store persists for the run.
- **R4 percentile interpolation**: invoked at end of pass under bin-counter mode. Heatmap consumer invokes R4 per time bucket against `%heatmap_data{$bucket}` for P50/P95/P99/P99.9; maps the numeric return value back to a bin index via R2 for storage in `%heatmap_percentiles`. Histogram consumer invokes R4 per metric against `%histogram_buckets{$metric}` for the ten-value percentile set; stores the numeric return value directly in `%histogram_stats{$metric}{p*}`. See R4-bis and the Resolution section below.

### Forward-compatibility implications for this feature

The audit confirms:

- **#34 R15 holds.** The per-message latency percentile arrays (`log_messages{$category}{$log_key}{durations}` allocated `ltl:4591`) are structurally separate from `%heatmap_raw` (`ltl:255`) and `%histogram_values` (`ltl:290`). Three distinct key shapes, three distinct lifetimes, three distinct allocation sites. This feature's data structures do not entangle with the #187 Phase 2 migration target.
- **Heatmap percentile markers** today (`%heatmap_percentiles` populated at `ltl:4829–4834`) are stored as bin indices derived from a sort over `%heatmap_raw`. Under bin-counter mode they are derived from #189 R4 (see R4-bis above and the resolution below). They remain stored as bin indices for backward-compatible rendering.
- **Histogram percentile indicators** (`%histogram_stats{p*}` populated `ltl:4926–4940`; consumed by the legend at `ltl:7375` and by x-axis tick positioning at `ltl:7430`) are sort-derived from raw arrays under raw-value mode. Under bin-counter mode they are derived from #189 R4 (see R4-bis above and the resolution below). Storage and downstream rendering are unchanged; only the derivation path changes.

### Resolution — percentile markers and indicators under bin-counter mode

The R12 audit identified an open question about how heatmap percentile markers (`%heatmap_percentiles`) would be derived when `%heatmap_raw` is not allocated. Further investigation surfaced a symmetric question about histogram percentile indicators (`%histogram_stats{$metric}{p*}` — used in the legend and in x-axis tick positioning) when `%histogram_values{$metric}` is not allocated.

**Resolution (recorded here, captured in R4-bis above):**

Both consumers — heatmap percentile markers and histogram percentile indicators — derive from **#189 R4 (the percentile-interpolation primitive)** at end of pass under bin-counter mode. The heatmap consumer maps R4's numeric return value back to a bin index via #189 R2 for storage in `%heatmap_percentiles`. The histogram consumer stores R4's numeric return value directly in `%histogram_stats{$metric}{p*}`; downstream legend rendering and x-axis tick positioning are unchanged.

Why this resolution:

- **Heatmap markers** could in principle be derived from a simpler cumulative-count walk over the bin counters (no R4 needed). However, **histogram indicators** require a numeric value — the legend prints "P50:42ms"; a bin index alone is insufficient — and the cleanest path for that is R4. Adopting R4 for both consumers harmonizes the percentile-derivation story across the two features, matching the harmonization intent of #189.
- Alternatives considered and rejected:
  - Dropping markers/indicators in bin-counter mode → breaks R8.
  - Keeping `%histogram_values` allocated under bin-counter mode purely for the legend → defeats most of the memory win.
  - Maintaining a separate streaming sketch alongside the bin counters → adds a new primitive contract in tension with #189's harmonization goal.
  - For heatmap alone, the cumulative-count walk is viable. We accept the (small) cost of taking the R4 dependency for the heatmap as well, in exchange for a single uniform percentile-derivation story.

Delivery-sequence consequence:

- **Step 4 (this feature's implementation) gates on #189 R4** in addition to R1–R3. R4 in turn gates on #187 D3's algorithm choice. The Delivery sequence table is updated to reflect this. The earlier note in #189's Parallelism section that allowed R4 to land later than R1–R3 is superseded.
- The three issues (#34, #187 Phase 2, #189) now converge to ship together rather than in the originally planned staggered sequence.

R8 (Render equivalence) is amended to permit the within-R4-accuracy-bound deviation between raw-value mode and bin-counter mode (see R8 amendment above).

#189's R4 requirement and its Consumer-side requirements section are updated to add #34 as an R4 consumer (previously the spec noted "this primitive is not consumed by #34").

## Edge cases

| Case | Required behavior |
|---|---|
| Neither `-hm` nor `-hg` requested | `mode: not_active`. No partition computed. No `-V` Layer 2 / 3. |
| Pre-seeded `min == max` for any required metric | Eligibility fails (`reason: missing_bound`); raw-value mode runs and handles the degenerate case as today. |
| Pre-seeded `min` is zero or negative for a duration/bytes metric | Logarithmic partitions undefined. Eligibility fails (`reason: missing_bound`). |
| Pre-seeded bounds match live exactly | No out-of-range counts, no drift, no warning. Render identical to raw-value mode. |
| Pre-seeded bounds wider than live | Bins at extremes empty; legitimate; render uses the wider axis. No out-of-range, no warning. |
| Pre-seeded bounds narrower than live | Out-of-range counts accumulate; single stderr warning (R6); render uses pre-seeded axis; #179 refreshes; next run observes no out-of-range. |
| `-hm count` requested, pre-seed has only `duration` bounds | Eligibility fails (`reason: missing_bound`); raw-value mode. |
| Multi-file run, mixed pre-seed (one file fresh, one not) | #179's multi-file rule already blocks pre-seed; this feature observes `no_index`; raw-value mode. |
| Multi-file run, all fresh, same tier | Per-file bounds aggregated per #179 (min-of-mins, max-of-maxes); partition arrays use aggregated values. |
| Filter signature never seen before | No Tier-1 match; eligibility fails (`reason: tier_mismatch`); next run with same filters will be eligible. |
| Stale or malformed `ltl-index.csv` | #179 produces no pre-seed; this feature observes `no_index`; raw-value mode. |
| Out-of-range values in multiple metrics in one run | Single warning (R6) names all affected metrics and directions. |
| Concurrent ltl processes | Inherited from #179; out of this feature's concern. |

## Acceptance criteria

- [ ] R1–R15 hold across all supported configurations.
- [ ] R10 (all-or-nothing per run) holds: no test produces a mixed-mode run.
- [ ] R11 (independent partitions) holds: heatmap and histogram each have their own bucket count and width; partition arrays are independent.
- [ ] When R2 succeeds, memory growth respects R13.
- [ ] When R2 fails for any reason, behavior satisfies R14.
- [ ] `-V` emits the section described in R9, with reason codes per R10, sufficient to distinguish every failure mode of R2.
- [ ] Out-of-range counts (R5) propagate to #179's drift refresh; after refresh, the next run with the same input observes zero out-of-range counts.
- [ ] The single end-of-run warning (R6) is emitted exactly once when out-of-range values exist; not emitted when none exist.
- [ ] The harmonization audit (R12) is complete and committed; the consumer-side requirements appear in **Harmonization audit** above and in `features/189-histogram-bin-counter-primitives.md`.
- [ ] Per-message latency percentile arrays are unaffected (R15).
- [ ] All test scenarios in **Validation** pass.
- [ ] `tests/validate-regression.sh` passes byte-identically against the pre-feature baseline.
- [ ] Any eligibility gap traced to #179 is filed against #179, not patched here (R16).

## Validation

Three layers, modelled after #179.

### Existing regression suite

`tests/validate-regression.sh` — all existing tests must pass byte-identically. Validates R14 and confirms that histogram bin-counter mode does not alter rendered output when bounds are matched.

### New scenario suite

A new test runner orchestrates `ltl-index.csv` state directly (mirroring #179's pattern), runs ltl with `-V`, and asserts against the `=== HISTOGRAM BIN COUNTER MODE ===` section.

`<F>` denotes a test input file with known content. `<F1>`, `<F2>` denote two distinct files with known distinct values.

| Scenario | Setup | Action | Assertions |
|---|---|---|---|
| `cold-no-index-heatmap` | No `ltl-index.csv`. | `ltl -hm duration <F> -V`. | `mode: raw_value`, `reason: no_index`. Render byte-identical to pre-feature. |
| `cold-no-index-histogram` | No `ltl-index.csv`. | `ltl -hg <F> -V`. | `mode: raw_value`, `reason: no_index`. |
| `cold-no-index-both` | No `ltl-index.csv`. | `ltl -hm duration -hg <F> -V`. | `mode: raw_value`, `reason: no_index`. Both features render byte-identical to pre-feature. |
| `warm-unfiltered-eligible-heatmap` | Fresh file row, bounds populated. | `ltl -hm duration <F> -V`. | `mode: histogram_bin_counter`, `reason: histogram_bin_counter_eligible`. Heatmap partition block in Layer 2 with the row's `min` / `max`. Render identical to `cold-no-index-heatmap`. |
| `warm-unfiltered-eligible-histogram` | Same file row, all metric bounds populated. | `ltl -hg <F> -V`. | `mode: histogram_bin_counter`. Histogram partition block in Layer 2 with one entry per metric. Render identical to cold. |
| `warm-unfiltered-eligible-both` | Same file row. | `ltl -hm duration -hg <F> -V`. | `mode: histogram_bin_counter`. Both heatmap and histogram partition blocks present in Layer 2, with their respective `num_buckets` (independent per R11). |
| `warm-filtered-tier1-eligible` | Fresh selection row for `(<F>, -dmin=50;)` with bounds covering live filtered range. | `ltl -hm duration -dmin=50 <F> -V`. | `mode: histogram_bin_counter`. Pre-seed values match the selection row. |
| `warm-filtered-tier2-fallback` | Fresh file row only; no matching selection row. | `ltl -hm duration -dmin=50 <F> -V`. | `mode: raw_value`, `reason: tier_mismatch`. Render byte-identical to pre-feature. |
| `missing-bound-heatmap` | File row with `duration_max=-`. | `ltl -hm duration <F> -V`. | `mode: raw_value`, `reason: missing_bound`. |
| `missing-bound-histogram-one-metric` | File row, `duration` bounds populated, `bytes_max=-`. | `ltl -hg <F> -V`. | `mode: raw_value`, `reason: missing_bound` (R10 — all-or-nothing; histogram needs all its metrics' bounds). |
| `missing-bound-mixed-features` | File row, `duration` bounds populated, `bytes_max=-`. | `ltl -hm duration -hg <F> -V`. | `mode: raw_value`, `reason: missing_bound` (R10 — all-or-nothing; histogram metric bound missing fails the whole run). |
| `out-of-range-low` | File row with `duration_min=100` (live values 10–500). | `ltl -hm duration <F> -V`. | `mode: histogram_bin_counter`, `out_of_range_low > 0`, `out_of_range_high: 0`. Per-time-bucket breakdown present. Exactly one stderr warning naming `duration` and `low`. #179's `drift_detected: yes`. After re-run with refreshed index: `out_of_range_low: 0`, no warning. |
| `out-of-range-high` | File row with `duration_max=200`. | `ltl -hm duration <F> -V`. | Symmetric: `out_of_range_high > 0`, single warning naming `duration` and `high`. |
| `out-of-range-both-directions` | File row with `duration_min=100, duration_max=200`. | `ltl -hm duration <F> -V`. | Both `out_of_range_low > 0` and `out_of_range_high > 0`. Exactly one stderr warning naming `duration` with both `low` and `high`. |
| `out-of-range-multi-metric` | `-hg` requested; live exceeds bounds for two metrics. | `ltl -hg <F> -V`. | Exactly one stderr warning naming both affected metrics with their directions. |
| `multi-file-all-eligible` | Fresh file rows for `<F1>` and `<F2>`. | `ltl -hm duration <F1> <F2> -V`. | `mode: histogram_bin_counter`. Partition uses aggregated bounds per #179. |
| `multi-file-mixed-eligibility` | `<F1>` fresh, `<F2>` stale mtime. | `ltl -hm duration <F1> <F2> -V`. | `mode: raw_value`, `reason: no_index` (inherited from #179's multi-file blocking rule). |
| `boundary-exact-match` | File row with `min` / `max` matching live exactly. | `ltl -hm duration <F> -V`. | `mode: histogram_bin_counter`, no out-of-range, no drift, no warning. Render byte-identical to a raw-value re-run. |
| `wider-than-live-bounds` | File row with bounds wider than live. | `ltl -hm duration <F> -V`. | `mode: histogram_bin_counter`, no out-of-range, no warning. Render uses the wider axis. |
| `feature-not-active` | Fresh file row; no `-hm`, no `-hg`. | `ltl <F> -V`. | `mode: not_active`. No partition blocks. |
| `degenerate-min-equals-max` | File row with `duration_min = duration_max`. | `ltl -hm duration <F> -V`. | `mode: raw_value`, `reason: missing_bound`. |
| `independent-bucket-counts` | Fresh file row; `-hm` and `-hg` requested with different `num_buckets` settings. | `ltl -hm duration -hg -hmw <W1> -hgw <W2> <F> -V`. | `mode: histogram_bin_counter`. Layer 2 heatmap and histogram blocks report different `num_buckets` (R11). |

#### Assertion mechanics

Tests parse the `=== HISTOGRAM BIN COUNTER MODE ===` section from `-V` output and assert keys against expected values. They also assert stderr content for out-of-range scenarios (R6 single-warning rule). Rendered bar-graph output is not asserted in this suite (that is the existing regression suite's job); the section and stderr are.

### `-V` instrumentation as the validation surface

The labels and structure defined in R9 and R10 are the test contract. Without that level of detail in `-V`, scenarios like `out-of-range-multi-metric` (which must assert *which* metrics were affected and *what direction*) are not assertable from rendered output alone.

## Related issues

- **#179** — index read-back (provides pre-seed primitive; R2 depends on it).
- **#187** — histogram bin-counter-based percentile calculation (sibling; consumes the same primitives; R15 keeps this feature out of percentile arrays).
- **#189** — unified histogram bin-counter primitives (sibling; provides the helper-function contract; R12 deliverable feeds it).
- **#51** — highlight-data accumulation (future consumer of the unified primitives).
- **#41** — heatmap-histogram alignment (R11 confirms partition independence; #41 must be compatible).
- **#23 Phase 2 (#59)** — core engine rewrite; the memory model defined by R10–R13 is intended to be inherited unchanged.
- **#180** — named pipeline stages.
- **#46** — index file (closed; foundation that #179 reads back).

## Spec stability

This document is intended to be stable across the implementation cycle. Two categories of post-merge change are expected:

1. Clarifications when an unspecified case is encountered during implementation (move from "unspecified" to "specified" in **Edge cases**).
2. Updates when sibling features (#51, #187, #189, #41) land — at that point this doc may add a brief subsection per consumer recording what each reads from or composes with this feature's mode contract.

The spec does not track implementation status, code locations, or commit history. Those live in commit messages and the issue itself.
