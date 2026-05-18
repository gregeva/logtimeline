# Feature: Bin-counter-based percentile calculation with dual-mode accuracy (multi-phase rollout)

## Overview

ltl's summary table reports per-message latency percentiles (P1, P5, P25, P50, P75, P90, P95, P99, P99.9). Today these are computed by retaining every individual metric value in an in-memory array, sorting it, and indexing. The algorithm requires `O(n)` memory in the number of values.

This feature introduces a **dual-mode percentile foundation**:

- **Exact mode** — today's array-based, exact percentile values. Unchanged.
- **Approximate mode** — quantile estimation via a sketch or via interpolation over **histogram bin counters** (the data structure introduced by #34, defined by primitives in #189), with `O(state)` memory bounded by the chosen algorithm's parameters and not growing with input size.

Mode is decided at start of run by criteria modelled after #34's eligibility gate. The exact algorithm, the accuracy bound it must meet, and the precise gating criteria are research outcomes (D1–D5).

This feature is **architecturally consequential beyond the summary table**. It defines the data-model and helper-function direction for percentile calculation across all of ltl, progressively. The roadmap consequence is captured in the multi-phase plan (R9) and the harmonization audit dependency on #189.

## GitHub Issue

[#187](https://github.com/gregeva/logtimeline/issues/187)

## Motivation

For multi-GB runs the per-message percentile arrays are typically the largest single memory consumer in the summary path — comparable in scale to the heatmap/histogram raw arrays that #34 addresses. With #179 reading bounds at start-up and #34 introducing histogram bin counters, the per-message percentile arrays become the next consumer of the same primitive.

Unlike heatmap and histogram (where counts per bin are sufficient for rendering), percentile values require *estimating a position* in the value distribution. Multiple credible algorithms exist (t-digest, KLL sketch, Greenwald-Khanna, q-digest, and **bin-derived interpolation over histogram bin counters**) with different accuracy / memory / CPU profiles. The right choice for ltl is not obvious from prior art alone — it depends on the value distributions actually observed in ltl's log datasets, which are heavy-tailed in ways that affect tail-quantile accuracy substantially. This feature therefore prioritizes research before locking in algorithm and accuracy.

A second motivation is architectural: this feature is not a one-shot replacement. It establishes the foundation for a **progressive multi-phase migration** of percentile calculation across ltl, with user-driven precision selection (exact vs. approximate) and automatic determination based on input criteria (memory, file size, line count, etc.). Every percentile consumer in ltl is on the path to adopting this same dual-mode foundation. R9 makes that plan explicit.

## Delivery sequence

This feature is one of three co-developed issues (#34, #187, #189). The work is performed in parallel against the `release/0.14.5` branch, with each issue's feature branches merging back periodically. The ordering below is the *delivery* sequence — when each step's output is required to be complete — not a strict serial work order. The multi-phase rollout for this feature itself is detailed in **R9**; the table below positions those phases within the broader cross-issue sequence.

| Step | Work | Owner | Why this position | Status of this file |
|---|---|---|---|---|
| 1 | **Audit** — catalogue existing helpers (heatmap, histogram, summary-table percentile paths); produce consumer-side primitive requirements | **#34 R12** + **#187 R12**; outputs land in **#189** *Audit findings* and *Consumer-side requirements* sections | Both #189's primitive design and this feature's algorithm research need to know what shapes the primitives must support. Without this first, primitives risk being designed for two consumers and reworked later. | **This file owns part of this step (R12); corresponds to R9 Phase 0** |
| 2 | **Research + prototype** — algorithm comparative study, accuracy report, recommendation memo, prototype | **#187 D1–D5** | Algorithm choice (sketch vs. bin-derived interpolation) determines what #189's percentile-interpolation primitive must do. Performed after audit but before #189 implementation so #189 isn't built blind. | **This file's research deliverables; corresponds to R9 Phase 1** |
| 3 | **Deliver #189** — implement unified primitives | **#189** | Now informed by both the audit (step 1) and the algorithm choice (step 2). | Consumed by this file at step 5 |
| 4 | **Deliver #34 implementation** — heatmap and histogram consume #189's primitives, **including R4** | **#34** | First production consumer of #189. Consumes **R1–R4**: per the #34 R12 audit resolution, heatmap percentile markers and histogram percentile indicators both derive from R4 under bin-counter mode. This means #34 step 4 also gates on **this feature's D3** (algorithm choice), since D3 fixes what R4 does. | **D3 (algorithm choice) is now consumed at step 4, not just step 5** |
| 5 | **Deliver #187 Phase 2** — summary-table per-message percentiles consume #189's primitives | **#187 Phase 2** | Second R4 consumer. Verifies R4's keying flexibility for a different consumer shape (per-`(category, log_key)`). | **This file's primary implementation step; corresponds to R9 Phase 2** |
| 6+ | **#187 Phases 3–5** — progressively land more consumers (per-time-bucket, highlight-data, future) | **#187 Phases 3–5** | Each phase verifies #189's primitives don't need to change to accept the new consumer. | **This file's later phases; correspond to R9 Phases 3–5** |

### Parallelism

Steps 1 and 2 may proceed in parallel once the audit has produced enough consumer-side requirements for the research to evaluate bin-derived interpolation against. Step 3 (#189 implementation) cannot complete until step 2 lands the algorithm choice. **Both step 4 (#34 implementation) and step 5 (this feature's Phase 2 implementation) gate on #189 R1–R4 being complete**, so D3 (the algorithm choice) is on the critical path for both consumers. The earlier plan that allowed #34 to ship against R1–R3 ahead of R4 is superseded by the #34 R12 audit resolution: #34's heatmap percentile markers and histogram percentile indicators both consume R4 under bin-counter mode. The three issues now converge to ship together rather than in the originally planned staggered sequence.

### Integration

All work lands on feature branches merged into `release/0.14.5` periodically. The release branch is the integration point until the three co-developed issues are individually complete, at which point `release/0.14.5` ships per the standard release process (CLAUDE.md).

## Terminology

Throughout this document, the consistent term for the underlying data structure is **histogram bin counters** (the structure defined in #34 and built from primitives in #189). When approximate mode uses bin-derived interpolation, it interpolates over those same histogram bin counters — not over a separate parallel structure. This is the architectural foundation: one set of primitives, multiple consumers.

## Requirements

### R1 — Two percentile-computation modes for the summary-table per-message latency percentiles

The system supports two percentile-computation paths for the summary-table latency percentiles:

- **Exact mode** — the existing array-based computation, producing exact percentile values for the matched data. Behavior unchanged from today.
- **Approximate mode** — quantile estimation from a bounded-state estimator (sketch- or bin-derived), producing the required percentile values within a documented accuracy bound (R4).

The selected mode is decided at run start.

### R2 — Mode-selection gate

The selection between exact and approximate mode is governed by criteria evaluated at run start. The criteria include at minimum:

1. Index pre-seed active (`index_used: yes` per #179).
2. Tier matches filter context (filtered → Tier-1 required; unfiltered → Tier-2 acceptable). Tier-correctness gaps are filed against #179, not patched here.
3. Input criteria suitable for approximate mode. The specific input criteria (file size, selection line count, available memory, user-provided precision preference, etc.) are research outputs (D3) and become the binding values for production. The requirement is that the gate evaluates *some* set of input criteria, reports them in `-V`, and that the criteria are designed alongside the algorithm choice — not deferred to ad-hoc implementation.

When any criterion fails, exact mode runs.

### R3 — Required percentile values

Approximate mode must produce all of: P1, P5, P25, P50, P75, P90, P95, P99, P99.9.

### R4 — Documented accuracy bound

Approximate mode must operate within a documented accuracy bound. The bound is a research output (D3), expressed per quantile, and may differ across quantiles (P99.9 typically has wider bounds than P50). The bound must:

- Be derivable either from the chosen algorithm's theoretical guarantees, or from an empirical calibration against representative ltl datasets (D2), or both.
- Be reported in `-V` (see R7).

The acceptance criterion is that for any input in the representative-dataset set (D2), every required quantile from approximate mode falls within the documented bound around the exact-mode value.

### R5 — Degenerate-input behavior

Approximate mode must handle the following inputs without crashing and without producing nonsensical values:

- Zero matched values — percentiles emit `-` (today's behavior).
- All-same value — every percentile equals that value.
- Single value — every percentile equals that value.
- Small N (single-digit to low-hundreds) — output remains correct under R4; if the chosen algorithm degrades, the gate (R2) must steer small-N runs to exact mode and that decision must be reported in `-V`.

### R6 — Determinism

Approximate mode must be deterministic for a given input: the same input file, filters, and gate decision produce the same percentile values across runs. If the chosen algorithm is randomized, it must be seeded reproducibly such that this requirement holds.

### R7 — `-V` observability

A dedicated `=== PERCENTILE MODE ===` section reports:

- **Layer 1**: `percentile_mode` (`exact` | `approximate`) and `percentile_mode_reason` (see R10).
- **Layer 2 (approximate mode)**: `algorithm` (the chosen estimator), `algorithm_version` where applicable, `state_budget_bytes`, `data_source` (`sketch` | `histogram_bin_counters` per #34/#189), and a per-quantile `accuracy_estimate` block reporting the bound applied to each required quantile.
- **Layer 3 (exact mode)**: `n` (the value count consumed) and a `sorted: yes` line for confirmation.
- **Layer 4 (always)**: `gating_criteria` — the input criteria the gate (R2.3) evaluated this run, each reporting `value`, `threshold`, and `passed: yes|no`. Lets tests assert each criterion independently.

Section name and all labels are part of the feature contract.

### R8 — Coupling to histogram bin counters

When the chosen approximate algorithm is bin-derived interpolation, the data source is the **histogram bin counters from #34**, accessed via the unified primitives from #189. This feature does not maintain a parallel partition.

This requirement is what makes the multi-phase rollout (R9) coherent: the per-message latency percentile path consumes the same primitive that heatmap and histogram already consume, with #189 providing the interpolation routine.

When the chosen approximate algorithm is sketch-based (t-digest / KLL / GK / q-digest), the estimator state is independent of histogram bin counters. The `data_source` in `-V` Layer 2 distinguishes the two.

### R9 — Multi-phase rollout plan

Approximate mode is introduced **progressively** across ltl's percentile consumers, not in a single shot. Each phase has a defined consumer, a defined acceptance condition, and a recorded outcome before the next phase begins.

The phases are:

- **Phase 0 — Foundation (this feature's spec work).** Audit existing percentile-computing paths (R12). Establish the dual-mode contract, the gating pattern, the `-V` observability contract, the multi-phase plan itself. Lock in the consumer-side requirements that #189's primitives must satisfy. **Output**: this feature file + the audit deliverable; the consumer-side primitive requirements landing in `features/189-histogram-bin-counter-primitives.md`. **No code changes yet.**
- **Phase 1 — Research and prototype (D1–D5).** Comparative algorithm study, accuracy report, recommendation memo, prototype. Production implementation gated on these.
- **Phase 2 — Summary-table per-message latency percentiles (the target this feature addresses directly).** Implement dual-mode for the summary-table percentiles per R1–R8. Validate against D2 datasets. Ship with default gating (no automatic activation without explicit user opt-in until validated; activation policy defined by D3).
- **Phase 3 — Time-bucketed duration percentiles** (the per-time-bucket percentile statistics that heatmap rendering uses implicitly today): migrate to bin-derived interpolation over the histogram bin counters already accumulated for heatmap. Validate that R4 holds at the per-time-bucket granularity (smaller N per bucket → potentially wider accuracy bound; revalidate in D2-equivalent harness scoped per-bucket).
- **Phase 4 — Highlight-data percentiles** (if and when #51 lands): apply dual-mode to highlight-subset percentiles. Coordinate with #51.
- **Phase 5 — Future percentile consumers.** Any new percentile-reporting feature adopts dual-mode by default; new consumers do not introduce array-based exact-only implementations.

Each phase is a separate implementation milestone with its own validation. The plan is not a single PR.

### R10 — Reason codes

When exact mode runs, `-V` must report why. The vocabulary is at minimum:

- `approximate_eligible` — approximate mode active.
- `exact_default` — no eligibility (catch-all when no specific gate failed).
- `no_index` — R2.1 failed.
- `tier_mismatch` — R2.2 failed.
- `input_criteria_failed` — R2.3 failed (one or more gating criteria did not pass the threshold determined by D3).
- `user_forced_exact` — when D3 determines a user-facing precision preference exists and the user selected exact.
- `feature_not_active` — no values were matched.

Additional reason codes may be added by implementation provided each maps to a single, testable cause.

### R11 — No regression in exact mode

When exact mode runs for any reason, percentile output is byte-identical to the pre-feature implementation. The existing regression suite must pass byte-identically.

### R12 — Percentile-path harmonization audit

Phase 0 includes an audit of every percentile-computing path in ltl today:

- Summary-table per-message latency percentiles (primary target).
- Per-time-bucket duration percentile statistics (implicit in heatmap rendering today; the percentile-derived statistics surfaced alongside the time-bucket bar graph).
- Any other percentile-reporting code path discovered during the audit.

For each path, the audit records:

- Today's data structure (array shape, key dimensions).
- Today's computation method (sort-and-index, or other).
- The migration target (which phase of R9 absorbs this path; what histogram bin-counter shape the path needs from #189).
- Compatibility constraints — what must not change in #189's primitive design to enable this consumer.

The audit lives in this feature file (see **Percentile-path harmonization audit** below) and feeds the consumer-side requirements in `features/189-histogram-bin-counter-primitives.md`.

The audit is required output of Phase 0 — without it, the primitives in #189 risk being designed for #34's two consumers only, forcing rework when later phases of R9 land.

### R13 — Heatmap and histogram bin-counter behavior unaffected by this feature

The histogram bin counters introduced by #34 are not modified by this feature in Phase 0–2. From Phase 3 onward, this feature *reads* the per-time-bucket histogram bin counters via the unified primitives but does not change how they are populated.

A run may have `percentile_mode: approximate` and `mode: raw_value` (#34's histogram bin-counter mode) or vice versa — they are governed by separate gates because the consumers are different, even though both gates share the index-pre-seed dependency. The exception is that approximate mode using bin-derived interpolation (R8) requires histogram bin counters to be present, which means #34's gate must have succeeded for that algorithm option to be available; that interaction is captured as a gating criterion in R2.3.

### R14 — Boundaries with other features

This feature does not own:

- Heatmap and histogram bin counters (the data structure and accumulation) — owned by #34.
- The unified primitives (helper functions, data structure contract) — owned by #189.
- Highlight-data accumulation — owned by #51.
- Index read-back, tier correctness, drift refresh — owned by #179.
- Within-run pre-pass / sampling-based bound discovery — not a topic of either this feature or #34.

When an eligibility gap traces to one of those features, it is filed against the owning issue rather than patched here.

## Percentile-path harmonization audit

The audit is part of Phase 0's deliverables (R12). It identifies the percentile-computing paths in `ltl` today, their migration targets, and the compatibility constraints those migrations place on #189's primitive design.

**Status: complete.** The audit was performed jointly with #34 R12 against `release/0.14.5` HEAD. The full per-site catalogue (line-precise, with primitive mappings and data-structure references) lives in `features/189-histogram-bin-counter-primitives.md` § **Audit findings** § "Summary-table per-message latency percentile consumer", § "Per-time-bucket duration percentile consumer", and § "Histogram-mode global percentile consumer". This section summarizes the percentile-specific findings and the migration targets per phase.

### Path A — Summary-table per-message latency percentiles (Phase 2 target)

- **Today's data structure**: `log_messages{$category}{$log_key}{durations}` — a per-message duration array, pushed during the parse loop at `ltl:4591`.
- **Today's computation**: `calculate_all_statistics` (`ltl:5178`) aggregates per `log_key`, delegating to `calculate_statistics` (`ltl:5488`) which sorts and indexes by integer rank (`int($n * fraction)`).
- **Percentiles emitted**: P1, P50, P75, P90, P95, P99, P99.9 (`ltl:5374–5379`); rendered in the summary table at `ltl:7900–7916`.
- **Migration target (Phase 2)**: replace the raw `durations` array with a histogram bin-counter store keyed by `(category, log_key)` per #189 R3. Replace the sort-and-index core of `calculate_statistics` with #189 R4 invocations against the per-message counter store. Algorithm (sketch vs. bin-derived interpolation) is decided by D3.
- **Compatibility constraints on #189**:
  - R3 must accept `key = (category, log_key)` (or `key = ()` per active aggregator if the aggregation happens before counter update — implementer's choice).
  - R4 must support the seven percentiles listed above with an accuracy contract sufficient for SRE latency reporting; specifics in D3.
  - R4 must handle the "single-message" degenerate case gracefully (very small count per `log_key` is common for one-off log messages).
- **#34 R15 verified**: this raw array is structurally separate from `%heatmap_raw` and `%histogram_values` (distinct keys, distinct lifetimes, distinct allocation sites). The #34 implementation does not entangle with this consumer.

### Path B — Per-time-bucket duration percentile statistics (Phase 3 target)

- **Today's data structure**: `log_analysis{$bucket}{durations}` — a per-time-bucket duration array, pushed during the parse loop at `ltl:4634` **gated by `unless $heatmap_enabled`**. Freed inside `calculate_all_statistics` at `ltl:5213–5214` after aggregation.
- **Today's computation**: same `calculate_statistics` engine (`ltl:5488`) as Path A, applied per time bucket. Outputs `log_stats{$bucket}{p1..p999}` at `ltl:5220, 5236–5242, 5273`.
- **Percentiles emitted**: P1, P50, P75, P90, P95, P99, P99.9; rendered inline on the time-bucket bar row at `ltl:6843–6846`.
- **Migration target (Phase 3)**: read #34's heatmap bin-counter store (keyed by `time_bucket`) directly via #189 R4 — no separate counter store needed when heatmap is active. When heatmap is **not** active, Phase 3 must populate its own per-`time_bucket` counter store (R3 with `key = time_bucket`) since no parallel structure exists.
- **Compatibility constraints on #189**:
  - R6 (independence of partitions across consumers) must allow Phase 3 to share the heatmap partition when bucket counts agree, or to compute its own partition when they differ.
  - R4 must produce acceptable accuracy at small per-bucket N (many log files have time buckets with <100 entries); D3 must evaluate this regime explicitly.
  - R3's per-key lifecycle (#189 R8) must support per-time-bucket counter freeing — Phase 3 can free a bucket's counter store once its row is rendered.
- **Pre-existing entanglement noted**: the `unless $heatmap_enabled` gate at `ltl:4634` is a load-bearing condition today (heatmap takes ownership of duration values when active). Under bin-counter mode this gate becomes natural rather than incidental — the heatmap counter store **is** the natural source. The gate may be removable when Phase 3 lands. This is recorded for resolution at Phase 3 implementation time, not at audit.

### Path C — Other percentile-reporting code paths

Two additional paths were catalogued during the audit:

#### C1 — Histogram-mode global percentiles (incidental Phase 2 consumer)

- **Today's data structure**: `histogram_stats{$metric}{p1..p9999}` — computed inside `calculate_histogram_buckets` at `ltl:4926–4940` (base) and `ltl:4995–5004` (highlight) from sorted `histogram_values{$metric}` arrays in the same routine that builds the bin counters.
- **Today's computation**: sort-and-index, identical pattern to Paths A/B but interleaved with R1+R2+R3 in raw-value mode.
- **Percentiles emitted**: P1, P10, P25, P50, P75, P90, P95, P99, P99.9, P99.99 (ten values — wider set than Paths A/B). Rendered in the histogram legend via `select_histogram_percentiles` (`ltl:7375`) and `calculate_histogram_percentile_ticks` (`ltl:7430`).
- **Migration target**: incidental Phase 2. When R4 lands, these can be derived from the bin counters #34 already populates — eliminating the raw-array sort at this site.
- **Compatibility constraints on #189**: R4 must support all ten percentile values; otherwise the rendered legend regresses. The legend consumer (`select_histogram_percentiles`) needs no API change — it reads `histogram_stats{$metric}{p*}` regardless of how those values were derived.
- **Coupling to #34**: because the raw-array sort and the bin-counter population happen in the same routine, #34's bin-counter mode and #187's Path C migration are best landed together (or #34 must keep the sort in bin-counter mode purely for `histogram_stats{p*}`, which defeats the memory win). The audit recommends Phase 2 absorb C1 as a side benefit.

#### C2 — Heatmap percentile markers (resolved as R4 consumer under bin-counter mode)

- **Today's data structure**: `%heatmap_percentiles{$bucket} = { p50, p95, p99, p999 }` — stored as **bin indices, not values**. Derived at `ltl:4823–4834` by sorting `%heatmap_raw{$bucket}`, indexing P50/P95/P99/P99.9, then mapping each value to a bin via `find_heatmap_bucket`.
- **Today's computation**: sort-and-index, then bin lookup. Output is a column position on the heatmap row, not a numeric percentile value.
- **Migration target**: under #34's bin-counter mode, derived from #189 R4 invoked per time bucket against `%heatmap_data{$bucket}`. The numeric return value is mapped back to a bin index via #189 R2 for storage in `%heatmap_percentiles{$bucket}`; downstream rendering is unchanged. Full resolution recorded in `features/34-histogram-bin-counter-mode.md` § Resolution and § R4-bis, and in `features/189-histogram-bin-counter-primitives.md` § Audit findings § Resolution.
- **Symmetric resolution for the histogram consumer**: histogram percentile indicators (`%histogram_stats{$metric}{p*}`, used by legend and x-axis ticks) likewise derive from #189 R4 under bin-counter mode; numeric value stored directly (no bin-index round-trip).
- **Delivery consequence**: #34 step 4 now gates on #189 R4 — and therefore on this feature's D3 (algorithm choice). #34 and #187 Phase 2 converge to ship together rather than in the originally planned staggered sequence.

### Currently no bin-derived percentile interpolation in `ltl`

A finding worth recording: **none** of the four percentile paths today (A, B, C1, C2) uses bin-derived interpolation. All four use sort-and-index over raw arrays. This means #189 R4 is a **new abstraction**, not a refactor of an existing helper. The algorithm choice (D3) and the accuracy contract (R4 in this feature) are inputs to a primitive that has no precedent in the codebase.

### Forward-compatibility statement (consumer-side requirements for #189)

For Phases 2–5 to consume the unified primitives without primitive-level redesign:

- **R1 (partition)** accepts arbitrary `num_buckets` per consumer. Bucket-count sources today vary across consumers: CLI-fixed (heatmap, `-hmw`), data-driven (histogram, `calculate_histogram_bucket_count`), Phase-2-implementer-chosen (per-message percentile partition shape, decided by D3). R1 must support all.
- **R3 (counter keying)** is parameterizable across all distinct shapes catalogued: `()` (Path A in some implementer choices, Path C1), `(category, log_key)` (Path A in other implementer choices), `time_bucket` (Path B, heatmap), `(time_bucket, highlight_subset)` (Path C in future / #51), and any compound key Phase 4 or Phase 5 introduces.
- **R4 (percentile interpolation)** accepts a target quantile and a counter map, returns the interpolated value, exposes its accuracy guarantee in a form that #187 R4 / R7 can report. Must handle:
  - Wide percentile sets: at minimum the ten-value set from Path C1 (P1, P10, P25, P50, P75, P90, P95, P99, P99.9, P99.99).
  - Small-N degenerate inputs: Path B at narrow time buckets, Path A at single-occurrence log keys, Path C2 at sparse heatmap rows.
  - Reporting alongside #34 R5 / R6 out-of-range tallies — overflow counts must be accessible to the interpolation primitive (or the consumer adjusts the partition to fold overflow into edge bins; R4 must specify which).
- **Accuracy guarantee per quantile is parameterizable by partition shape.** Per-time-bucket and global partitions have different N regimes; D3 must produce a bound that applies to both.
- **Memory lifecycle**: counter structures freeable per key independently of the partition; estimator state (if R4 uses any) freeable independently of the counter store.

This list is the consumer-side input to #189's primitive design.

### Cross-reference

- Full per-site `ltl:line` catalogue with primitive mappings: `features/189-histogram-bin-counter-primitives.md` § Audit findings.
- Per-feature consumer-side requirements (combined #34 + #187): `features/189-histogram-bin-counter-primitives.md` § Consumer-side requirements.
- Cross-cutting constraints discovered during audit: `features/189-histogram-bin-counter-primitives.md` § Cross-cutting compatibility constraints discovered during audit.
- Boundary with #34's heatmap and histogram consumers: `features/34-histogram-bin-counter-mode.md` § Harmonization audit (this feature ships the percentile-interpolation algorithm and progressive consumer migration; #34 ships the heatmap/histogram bin-counter substrate the percentile work consumes).

## Considerations for implementation

The spec is intentionally agnostic about the mechanisms below. Each must be addressed during prototype and implementation; the choice of mechanism is the implementer's, informed by research outcomes (D1–D5).

- **Algorithm choice** is a research output (D3). Candidate algorithms are enumerated in **Research deliverables**; the implementer may extend the candidate set if literature review surfaces relevant alternatives. The choice must be one of: a sketch (t-digest / KLL / GK / q-digest), bin-derived interpolation over histogram bin counters, or a hybrid.
- **Memory behavior across modes.** The approximate-mode estimator state (sketch or counter-derived) replaces the exact-mode value array. Mixed-mode behavior is well-defined per R13; lifecycle composes with #23 Phase 2's named-stage memory model.
- **Accuracy reporting unit.** R4 requires per-quantile reporting. The unit (percentage-of-value error, absolute value error, percentile-rank distance) is decided in research and locked at D3-time.
- **Highlight subsets.** Phase 4 coordination with #51.
- **State lifecycle and reset.** Estimator state freed when no longer needed; lifecycle composes with #23 Phase 2.

## Edge cases

| Case | Required behavior |
|---|---|
| No matched messages | Percentiles emit `-`; no estimator runs; `-V` reports `feature_not_active`. |
| All matched values are identical | Every percentile equals that value (exact and approximate modes agree). |
| Single matched value | Every percentile equals that value. |
| Very small N below D3's threshold | Gate (R2.3) steers to exact mode; `reason: input_criteria_failed`. |
| Stale or missing index | R2.1 fails; exact mode runs; `reason: no_index`. |
| Filtered run with only Tier-2 pre-seed | R2.2 fails; exact mode runs; `reason: tier_mismatch`; gap recorded against #179. |
| Approximate mode chosen but histogram bin counters unavailable (#34 ineligible) and chosen algorithm requires them | Gate (R2.3) treats absence of histogram bin counters as a failed gating criterion when bin-derived interpolation is the chosen algorithm. `reason: input_criteria_failed` with the specific criterion identified in `gating_criteria`. Sketch-based algorithms are unaffected. |
| Bounds drift mid-run | Exact-mode output unchanged. Approximate-mode behavior under drift is determined by D3; the accuracy bound (R4) must still hold or the gate must have excluded the run. |
| User-forced exact mode | If D3 introduces a user-facing precision preference and the user selects exact, gate fails by design; `reason: user_forced_exact`. |
| Highlight pattern present (pre-Phase 4) | Highlight-subset percentiles run in exact mode regardless of main-set mode; recorded as a Phase 4 dependency. |
| Concurrent ltl processes | Inherited from #179; out of this feature's concern. |

## Acceptance criteria

- [ ] R1–R13 hold across the representative-dataset set (D2).
- [ ] Phase 0 deliverables complete: this feature file, the audit (R12), the consumer-side primitive requirements landed in `features/189-histogram-bin-counter-primitives.md`.
- [ ] Phase 1 research deliverables (D1–D5) complete before Phase 2 implementation.
- [ ] For every input in the D2 set, each required quantile from approximate mode falls within the D3 accuracy bound around the exact value.
- [ ] When approximate mode runs, R3–R8 hold; `state_budget_bytes` in `-V` matches actual estimator memory; `data_source` correctly identifies sketch vs. histogram bin counters.
- [ ] When exact mode runs for any reason (R10), output satisfies R11 (byte-identical to pre-feature).
- [ ] `-V` emits the section described in R7, with reason codes per R10 distinguishing every failure mode of R2, and the `gating_criteria` block in Layer 4 lets tests assert each criterion independently.
- [ ] Heatmap and histogram bin-counter behavior is unchanged in Phase 2 (R13).
- [ ] Multi-phase plan (R9) is documented; subsequent phases reference this feature file as their predecessor.
- [ ] All test scenarios in **Validation** pass.
- [ ] Any eligibility gap traced to #179 is filed against #179 (R14).

## Validation

Three layers, modelled after #34 and #179.

### Existing regression suite

`tests/validate-regression.sh` must pass byte-identically. Validates R11.

### New scenario suite

Mirrors #34's pattern: orchestrate `ltl-index.csv` state, run ltl with `-V`, assert against the `=== PERCENTILE MODE ===` section.

| Scenario | Setup | Action | Assertions |
|---|---|---|---|
| `cold-no-index-exact` | No `ltl-index.csv`. | `ltl <F> -V`. | `percentile_mode: exact`, `reason: no_index`. |
| `warm-eligible-approximate-sketch` | Fresh index pre-seed; input meets D3 criteria; chosen algorithm is sketch-based. | `ltl <F> -V`. | `percentile_mode: approximate`, `reason: approximate_eligible`, `algorithm` populated, `data_source: sketch`, `accuracy_estimate` per quantile populated. |
| `warm-eligible-approximate-bin-derived` | Same as above; chosen algorithm is bin-derived interpolation; #34 also eligible. | `ltl -hg <F> -V`. | Same as above plus `data_source: histogram_bin_counters`. |
| `warm-input-criteria-failed` | Fresh pre-seed; input below D3 thresholds. | `ltl <F> -V`. | `percentile_mode: exact`, `reason: input_criteria_failed`. `gating_criteria` Layer 4 identifies the failing criterion. |
| `warm-tier-mismatch` | Filtered run, only Tier-2 pre-seed. | `ltl -dmin=50 <F> -V`. | `percentile_mode: exact`, `reason: tier_mismatch`. |
| `bin-derived-needs-histogram-counters` | Fresh pre-seed; chosen algorithm is bin-derived; #34 ineligible (raw-value mode). | `ltl <F> -V`. | `percentile_mode: exact`, `reason: input_criteria_failed`. `gating_criteria` identifies `histogram_bin_counters_available: passed: no`. |
| `approximate-zero-values` | Eligible run; all messages filtered out. | `ltl -i nonexistent <F> -V`. | Percentiles emit `-`; `reason: feature_not_active`; no crash. |
| `approximate-all-same` | Eligible run; all matched values identical. | Crafted log file. | All percentiles equal that value. |
| `approximate-single-value` | Eligible run; single matched value. | Crafted log file. | All percentiles equal that value. |
| `accuracy-within-bound` | Eligible run; representative dataset. | Run twice — once forcing exact via gate-failure, once approximate. | Per-quantile absolute and relative errors fall within D3's bound. |
| `state-budget-reported` | Eligible run. | `ltl <F> -V`. | `state_budget_bytes` non-zero; matches the estimator's configured parameter (D3). |
| `user-forced-exact` (if D3 introduces this) | Fresh pre-seed; input meets all auto criteria; user selects exact. | `ltl <F> -V` (with whatever D3 mechanism opts out). | `percentile_mode: exact`, `reason: user_forced_exact`. |

### Accuracy-comparison test harness

A dedicated harness compares approximate-mode output against exact-mode output across the D2 dataset set. For each dataset:

1. Run ltl twice (once forced exact, once approximate).
2. Compute per-quantile absolute and relative error.
3. Assert each error within D3's bound.

The harness is part of this feature's deliverable.

## Research deliverables

Production implementation does not commence until the following deliverables are complete and recorded. The deliverables are requirements on the *work*, not prescriptions of the *mechanism*.

### D1 — Comparative algorithm study

Evaluate the following candidate algorithms against the D2 dataset set:

- **t-digest** — Dunning's structure; recognized for tail-quantile accuracy in heavy-tailed data.
- **KLL sketch** — deterministic-error succinct quantile sketch.
- **Greenwald-Khanna (GK)** — classic deterministic quantile sketch.
- **q-digest** — tree-based deterministic quantile sketch.
- **Bin-derived interpolation over histogram bin counters** — compute percentiles by interpolating within the histogram bin counters produced by #34 via the primitives from #189. Strongly preferred for architectural harmonization; the comparative study determines whether its accuracy is sufficient.

For each algorithm and each dataset:

- Per-quantile absolute error (raw-value units).
- Per-quantile relative error (percent of exact value).
- 95% confidence intervals over multiple sub-samples.
- Estimator state size.
- Per-update CPU cost.
- Per-finalize CPU cost.
- Determinism characteristic.

### D2 — Representative-dataset set

Curate a representative dataset set for accuracy evaluation. Must include:

- A heavy-tailed access log (Tomcat / Apache style).
- A ThingWorx mixed-traffic log.
- A high-cardinality DEBUG-heavy log.
- A small-N case (a few hundred values).
- A degenerate case (all-same values).
- A pathological case relevant to ltl users (selection determined during research; e.g., a log with extreme outliers).
- Per-time-bucket sub-samples (for Phase 3 readiness — bin-derived interpolation must be validated at the smaller N typical per time bucket).

### D3 — Recommendation memo

A written recommendation:

- The algorithm (or algorithms, if a hybrid is recommended) ltl ships.
- The accuracy bound (R4) the implementation commits to, per quantile.
- The input criteria for R2.3 (the gating thresholds), with explicit values.
- Whether and how a user-facing precision preference is introduced (the mechanism, the default).
- The state-budget configuration.
- Rationale connecting the recommendation to D1 + D2.

### D4 — Prototype

A working prototype in `prototype/187-percentile-sketch.pl` (or similar). The prototype:

- Implements the recommended algorithm(s).
- Runs against the D2 datasets and produces D1-style output reproducibly.
- Is runnable independently of ltl proper so algorithm changes can be validated without touching production code.
- For bin-derived interpolation, the prototype must include a mock of the #189 primitive contract so the algorithm can be exercised standalone.

### D5 — Production gate

Production implementation references D1–D4 as prerequisites and treats their outputs as the binding values for R4, R7's `accuracy_estimate`, and the R2.3 / R10 gating criteria.

## Related issues

- **#34** — histogram bin-counter accumulation (sibling; provides the counter data structure for bin-derived interpolation; consumer of #189).
- **#179** — index read-back (R2.1 / R2.2 dependency).
- **#189** — unified histogram bin-counter primitives (provides the helper-function contract; R8 and R12 depend on it).
- **#51** — highlight-data accumulation (Phase 4 coordination).
- **#41** — unified binning (D1 evaluates bin-derived interpolation, which composes with #41 if it lands).
- **#23 Phase 2 (#59)** — adopts this feature's memory model.
- **#180** — named pipeline stages.
- **#46** — index file (closed; foundation that #179 reads back).

## Spec stability

The behavior contract (R1–R14, R9 multi-phase plan, edge cases, `-V` format) is intended to be stable across implementation. The research deliverables (D1–D5) are expected to grow as research lands; their outputs become the bound values for R4, R7, R10. When that happens, a **Locked decisions from research** subsection records the values.

Phase boundaries in R9 are part of the spec contract. Crossing a phase boundary requires explicit revalidation against the accuracy bound for the new consumer.
