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
| 2 | **Research** — literature-grounded comparative study against the audited use cases; decision-support memo presenting options and trade-offs; prototype only if specific open questions warrant measurement | **#187 D1–D5 (D4 conditional)** | Algorithm choice (sketch vs. bin-derived interpolation, or a hybrid) determines what #189's percentile-interpolation primitive must do. Performed after audit but before #189 implementation so #189 isn't built blind. | **This file's research deliverables; corresponds to R9 Phase 1** |
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
- **Phase 1 — Research (D1–D5; D4 conditional).** Literature-grounded comparative study of candidate algorithms against the use-case demands the R12 audit identified; cross-reference of existing log files to use-case regimes; decision-support memo presenting options and trade-offs for the user to decide from; prototype only if D3 surfaces open questions that literature alone cannot resolve. Production implementation gated on the decision conversation that follows D3.
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

The spec is intentionally agnostic about the mechanisms below. Each must be addressed during research, the decision conversation, and implementation; the choice of mechanism is decided through Phase 1's decision-support process (D3), informed by D1's literature-grounded analysis and D4 only when triggered.

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
- [ ] Phase 1 research deliverables (D1, D2, D3, and D4 if triggered) complete, and the decision conversation that follows D3 has produced the binding values for algorithm choice, accuracy bound, and gating thresholds, before Phase 2 implementation.
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

### D1 — Comparative algorithm study (literature-grounded)

D1 is a literature-grounded comparative study, not an empirical bake-off. Its purpose is to characterize each candidate algorithm against the use-case demands the R12 audit identified (Paths A, B, C1, C2), so the trade-offs are visible and a decision can be made. No measurement is performed at this stage; measurement is conditional on D4 (see below).

**Candidate algorithms** — the following list is a starting point; literature review may surface additional candidates and those are included if relevant:

- **t-digest** — Dunning's structure; recognized for tail-quantile accuracy in heavy-tailed data.
- **KLL sketch** — deterministic-error succinct quantile sketch.
- **Greenwald-Khanna (GK)** — classic deterministic quantile sketch.
- **q-digest** — tree-based deterministic quantile sketch.
- **Bin-derived interpolation over histogram bin counters** — compute percentiles by interpolating within the histogram bin counters produced by #34 via the primitives from #189.

The study presents *options and trade-offs*, not a preferred answer. The decision is made by the user against D3's synthesis, not by D1 implicitly.

**For each candidate, the study characterizes:**

- **Accuracy guarantee** — quantitative where the literature supplies it (e.g., published worst-case quantile-rank error bounds, asymptotic behavior at tail quantiles); qualitative where it does not (e.g., known behavior on heavy-tailed data, sensitivity to ordering).
- **Memory profile** — quantitative where the literature supplies it (asymptotic state size as a function of compression parameter and N); qualitative for behavior at the small-N regime relevant to Path B and Path A's single-occurrence log keys.
- **CPU profile** — quantitative where the literature supplies it (asymptotic per-update and per-finalize cost); qualitative for Perl-implementation implications where relevant.
- **Determinism** — does the algorithm produce identical output for identical input; if randomized, what seeding discipline is required.
- **Fit against each audited use case** — for each of Paths A, B, C1, C2:
  - Does the algorithm meet the use case's percentile-set demand (7-value set for A/B, 10-value set for C1, 4-marker set for C2)?
  - Does its N-regime behavior match the use case (per-`log_key` N for A, per-`time_bucket` N for B, full-dataset N for C1, per-`time_bucket` N for C2)?
  - Does its output form match the use case (numeric value for A/B/C1, bin-index for C2 via #189 R2 round-trip)?
  - Where is the algorithm a poor fit, and why?
- **Harmonization implication** — if this algorithm were chosen for all four paths, what does ltl gain or lose architecturally? If it were chosen for only some paths, which combinations make sense and what is the cost of running two algorithms?
- **Open questions** — what about this candidate cannot be answered from literature alone, and would require measurement (D4) to resolve?

#### D1 study — use-case demand profile

Drawn from the R12 audit (above). The demands a percentile primitive must satisfy across the four paths:

| Demand | Path A (summary-table per-message) | Path B (per-time-bucket) | Path C1 (histogram-mode global) | Path C2 (heatmap markers) |
|---|---|---|---|---|
| Percentile set | 7-value: P1, P50, P75, P90, P95, P99, P99.9 | 7-value: P1, P50, P75, P90, P95, P99, P99.9 | **10-value**: P1, P10, P25, P50, P75, P90, P95, P99, P99.9, **P99.99** | 4-marker: P50, P95, P99, P99.9 |
| Output form | Numeric value (rendered as duration) | Numeric value (rendered inline on bar row) | Numeric value (legend + x-axis ticks) | **Bin index** (column position on heatmap row) |
| Partition shape | Per-`(category, log_key)` — many independent partitions, one per distinct log key | Per-`time_bucket` — one partition per visible row | Single global partition per metric | Per-`time_bucket` — one partition per heatmap row (same partition as #34's bin counters) |
| N regime | Highly variable: many keys with N=1–10; some keys with N=10⁴–10⁶ on heavy-traffic endpoints | Variable: typically 10²–10⁴ per bucket at default bucket size; can drop to <10 at narrow `-b` or low-traffic windows | Single large N: typically 10⁵–10⁷ for the full dataset | Same as Path B (per-time-bucket) |
| Update pattern | Streaming during parse loop; finalize per-key after parse | Streaming during parse loop; finalize per-bucket after parse | Streaming during parse loop; finalize once | Streaming during parse loop; finalize per-bucket after parse |
| Tail-quantile importance | High (P99.9 is operationally critical for SRE latency) | High (P99 / P99.9 markers shown alongside time-bucket bar) | Very high (P99.99 included — extreme tail) | High (P99.9 marker shown on every heatmap row) |
| Memory pressure sensitivity | **Highest** — many keys × value array is the dominant summary-path memory consumer on multi-GB runs | Moderate — bucket count ~hundreds; per-bucket array can be large | Moderate — single partition but full-dataset N | Already addressed by #34's bin counters; percentile derivation must not reintroduce raw arrays |
| Determinism requirement | Byte-identical across runs (R6) | Byte-identical across runs (R6) | Byte-identical across runs (R6) | Bin-index stability across runs (R6, plus R11 byte-identical when exact mode runs) |

**Cross-cutting demands** (not path-specific):

- **Per-quantile accuracy bound (R4)**: the bound is reported in `-V` per quantile and may differ across quantiles. P99.9 may have a wider bound than P50.
- **Degenerate inputs (R5)**: zero, one, or all-same values must produce correct output without crashing.
- **Wide percentile set support**: any chosen primitive must handle all percentiles required by any consumer; the 10-value set from Path C1 is the worst case.
- **Out-of-range tallies (#34 R5/R6)**: under bin-counter mode, values below the partition's low edge or above its high edge are counted but not placed in interior bins. The percentile primitive must either consume these tallies or the consumer must fold them into edge bins. This is a primitive-design question, not an algorithm-choice question — recorded as input to #189 R4, not to D3.
- **State independence**: if the chosen algorithm carries estimator state separate from the counter store (sketches do; bin-derived interpolation does not), that state must be freeable per key independently of the counter store.

#### D1 study — candidate characterizations

The five spec-listed candidates plus four adjacent candidates that the literature review surfaces as relevant: DDSketch (relative-error sketch), HdrHistogram (industry-standard latency histogram), P-square (single-pass online quantile estimator), and reservoir sampling (uniform random sample then exact).

Where the literature supplies quantitative characteristics they are stated; where it does not, the entry says so explicitly. Behavior on heavy-tailed data — the dominant regime for ltl's primary use case — is called out where the literature characterizes it.

##### Candidate 1 — t-digest (Dunning & Ertl)

**Source**: Dunning, *"The t-digest: Efficient estimates of distributions"* (2019, Software Impacts). Open-source reference implementations in Java, C++, Go, Python.

- **Accuracy guarantee**: No worst-case theoretical bound on rank or relative error. Strong *empirical* tail-quantile accuracy: relative error at P99 and P99.9 is typically <1% and improves at the tails (centroid clustering is denser near 0 and 1). At median (P50) the relative error is the *worst* of any quantile in a t-digest — opposite of most sketches.
- **Memory profile**: O(δ) state where δ is the compression parameter. Default δ=100 → ~5–20 KB serialized state. State is the centroid array, size bounded by δ but loosely (centroids merge dynamically). Asymptotically independent of N. At very small N (<100 typical for Path B narrow buckets or Path A single-occurrence keys), state is bounded by N rather than δ — degenerates gracefully.
- **CPU profile**: Per-update O(log δ) amortized (binary search to find the host centroid, occasional merge). Per-finalize O(δ) to interpolate at requested quantiles. In Perl, the binary-search and merge overhead is the practical bottleneck — no published Perl benchmark exists, but t-digest in interpreted languages typically runs 5–20× slower per update than in JIT-compiled languages.
- **Determinism**: Deterministic for fixed-order input. **Sensitive to input order** — different ingestion orders of the same multiset produce different (but similar-accuracy) digests because centroid merge decisions depend on arrival order. ltl's parse order is deterministic per file, so this does not break R6, but it does mean t-digest from a re-sorted input would not be byte-identical.
- **Fit against Path A**: Good. 7-quantile demand met; numeric output; per-`(category, log_key)` partition works (one digest per key). Memory at small N degenerates gracefully. Heavy-traffic keys (N=10⁶) get the benefit of bounded state.
- **Fit against Path B**: Acceptable. Bounded state per bucket is a memory win at scale. Small-N buckets (<100) revert to near-exact behavior. Tail accuracy is the strong suit, which matches the operational importance of P99/P99.9 on time-bucket rows.
- **Fit against Path C1**: Acceptable. 10-quantile demand including P99.99 — t-digest's tail bias actually *helps* here, and large single-partition N is the regime t-digest is most optimized for.
- **Fit against Path C2**: Acceptable. Numeric output mapped to bin index via #189 R2 is a clean round-trip. Bin-index stability depends on the relationship between the t-digest's internal centroids and the heatmap partition's bin boundaries — open question.
- **Harmonization implication**: One algorithm for all four paths is feasible. Single primitive in #189 R4. Trade-off: t-digest does *not* share data structure with #34's bin counters — the digest is independent estimator state. So bin counters and t-digest coexist rather than unify. This is a missed harmonization opportunity relative to bin-derived interpolation but does not preclude its use.
- **Open questions**:
  - No worst-case theoretical bound means R4 must be set empirically against ltl's distributions, not derived from theory. D3 must decide whether to lock R4 on published empirical numbers (Dunning's paper reports specific datasets) or to mandate D4 measurement.
  - Perl-implementation cost on streaming updates is not characterized in the literature. If Phase 2 lands and t-digest updates dominate parse-loop CPU, that's a regression.
  - Bin-index stability for Path C2 across runs with the same input is open: t-digest is order-deterministic for fixed input, so the stability should hold, but no published characterization exists.

##### Candidate 2 — KLL sketch (Karnin, Lang, Liberty)

**Source**: Karnin, Lang, Liberty, *"Optimal Quantile Approximation in Streams"* (FOCS 2016). Reference implementations in Apache DataSketches (Java) and various ports.

- **Accuracy guarantee**: **Theoretical worst-case bound**: rank error ≤ ε with probability ≥ 1−δ for randomized variant; deterministic variant exists with weaker constant. Error is in *rank space* (quantile rank), not value space. ε=0.01 means the returned value's true rank is within 1% of the requested rank. Critically, KLL's rank error is *uniform* across quantiles — same bound at P50 and P99.9, unlike t-digest's tail bias.
- **Memory profile**: O((1/ε) · log log (1/δ)) bytes (randomized) or O((1/ε) · log(εN)) (deterministic). At ε=0.01, randomized variant is ~3 KB; deterministic variant grows logarithmically with N. Asymptotically optimal — published results prove KLL is within a constant factor of the information-theoretic lower bound.
- **CPU profile**: Per-update O(log log (1/δ)) amortized (randomized). Per-finalize O((1/ε) log(1/ε)). Update cost is essentially constant in practice.
- **Determinism**: **Randomized variant requires a seed.** With a fixed seed, deterministic for fixed input. Deterministic variant has no randomness but pays more memory. For R6, the randomized variant must seed reproducibly (e.g., from file hash or input checksum) — this is a non-trivial implementation discipline question.
- **Fit against Path A**: Good. 7-quantile demand met with uniform accuracy. Memory at small N (<100): KLL of size O(1/ε) is still ~3 KB even for N=10, which is overhead relative to storing the array. Below some N threshold, exact mode is cheaper.
- **Fit against Path B**: Good for moderate-N buckets. Same small-N overhead concern as Path A. Uniform rank error matches Path B's tail-importance well — P99.9 accuracy is no worse than P50.
- **Fit against Path C1**: Very good. Uniform rank error and asymptotic optimality at large N. 10-quantile demand met without tail-specific concerns.
- **Fit against Path C2**: Good. Numeric output mapped to bin index via #189 R2. Rank-error semantics mean bin-index stability is a function of how rank error translates to value error in heavy-tailed distributions — open question.
- **Harmonization implication**: One algorithm for all four paths feasible. KLL state coexists with #34's bin counters rather than unifying with them. Same trade-off as t-digest: clean primitive but no structural unification with the bin-counter substrate.
- **Open questions**:
  - Whether the rank-error bound is useful to ltl users as reported in `-V`. Rank error is mathematically rigorous but operationally awkward: "P99 returned a value at true rank 0.985–0.995" is harder to reason about than "P99 returned a value within ±5% of the true P99 value." D3 must decide which reporting form R4 commits to and whether KLL's rank guarantee can be translated to value error for ltl's distributions.
  - Seeding discipline for the randomized variant under R6.
  - Small-N threshold below which exact mode is cheaper than KLL state.

##### Candidate 3 — Greenwald-Khanna (GK)

**Source**: Greenwald & Khanna, *"Space-efficient online computation of quantile summaries"* (SIGMOD 2001). Foundational sketch; many implementations exist.

- **Accuracy guarantee**: **Theoretical worst-case rank-error bound** of ε. Deterministic — no randomness. Uniform across quantiles like KLL.
- **Memory profile**: O((1/ε) · log(εN)) tuples. At ε=0.01 and N=10⁶, that's ~1400 tuples (each tuple is 3 numbers) ≈ 30–60 KB. Grows with N (logarithmically), unlike KLL or t-digest. This is GK's main weakness.
- **CPU profile**: Per-update O(log(1/ε) + log log(εN)) amortized. Per-finalize O(1/ε).
- **Determinism**: Fully deterministic. R6 satisfied trivially.
- **Fit against Path A**: Acceptable. Worse memory than KLL at the same accuracy because of the log(εN) factor. For heavy-traffic keys with N=10⁶, GK is ~10× larger than KLL.
- **Fit against Path B**: Acceptable. Same trade-off — moderate-N buckets carry an O(log) memory tax that KLL avoids.
- **Fit against Path C1**: Acceptable. Full-dataset N (10⁵–10⁷) is exactly where GK's log(εN) factor bites hardest.
- **Fit against Path C2**: Acceptable. Same numeric-to-bin-index round-trip as the others.
- **Harmonization implication**: Same as KLL — independent estimator state, coexists with bin counters rather than unifying. GK is the *least* memory-efficient of the sketch options at large N, which matters because Phase 2 is the primary memory-pressure motivation for this entire feature.
- **Open questions**:
  - Whether GK's deterministic guarantee (no seed discipline needed) is worth the extra memory relative to KLL. Some implementations argue yes for systems where reproducibility-by-default is operationally important.
  - GK is older and well-understood; few open questions in the literature.

##### Candidate 4 — q-digest

**Source**: Shrivastava et al., *"Medians and beyond: new aggregation techniques for sensor networks"* (SenSys 2004). Tree-based deterministic quantile sketch.

- **Accuracy guarantee**: Theoretical worst-case bound on rank error ε, with state proportional to 1/ε. Designed for sensor-network aggregation (mergeable across nodes), not specifically for heavy-tailed streams.
- **Memory profile**: O((1/ε) log U) where U is the universe size (the range of possible values). For ltl, U is the range of duration values — milliseconds from 0 to some hours-scale upper bound, so log U ≈ 20–25. State size grows with the *value range*, not with N.
- **CPU profile**: Per-update O(log U) for tree traversal. Per-finalize O(state size).
- **Determinism**: Fully deterministic.
- **Fit against Path A**: Marginal. The log U factor means q-digest is heavier per partition than KLL or t-digest at comparable accuracy. Many partitions (per `log_key`) compound this cost.
- **Fit against Path B**: Marginal. Same per-partition cost as Path A applied per bucket.
- **Fit against Path C1**: Acceptable. Single partition amortizes the log U cost.
- **Fit against Path C2**: Acceptable.
- **Harmonization implication**: Independent estimator state like KLL/GK/t-digest. q-digest's mergeability is a feature ltl does not currently exploit (no distributed aggregation) — so the main advantage of the algorithm is unused.
- **Open questions**:
  - Whether q-digest's mergeability matters for any future Phase (5+) consumer (e.g., aggregating multiple `ltl` runs). If not, q-digest is dominated by KLL on every dimension.

##### Candidate 5 — Bin-derived interpolation over histogram bin counters

**Source**: No single canonical paper — the approach is classical (histogram-based quantile estimation) but appears in the literature primarily as a *component* of other algorithms (e.g., HdrHistogram, DDSketch) rather than as a named technique in its own right. The form proposed here is: given a partition with bin counters (the structure #34 produces and #189 R1–R3 manages), find the bin containing rank ⌈q·N⌉ and interpolate linearly within the bin.

- **Accuracy guarantee**: **No probabilistic bound** — accuracy is fully determined by partition shape. Two bounds apply:
  1. **Worst-case per-quantile value error**: ≤ width of the bin containing the target rank. For a logarithmic partition with base b and num_buckets B, the bin width at the high end of the range is `(max/min)^(1/B) · v` for a value v near the high end — i.e., **relative error bounded by (b−1)** where b is the log base.
  2. **Best-case (uniform within bin)**: interpolation is exact if values within a bin are uniformly distributed; degrades to bin-width error in the worst case.
  Heavy-tailed data within a log-spaced bin is approximately log-uniform within the bin if the partition matches the distribution's scale, so the practical error is closer to the best-case than the worst-case for ltl's regime.
- **Memory profile**: **Zero estimator state beyond the bin counters themselves.** The bin counters are already required by #34 for heatmap/histogram rendering — percentile derivation reuses them at no additional cost. This is the dominant architectural advantage.
- **CPU profile**: Per-update is whatever #189 R2 (bin assignment) costs — typically O(log B) binary search or O(1) closed-form for log-spaced partitions. **No additional per-update cost beyond bin counter increment.** Per-finalize: O(B) linear scan to find the bin containing rank ⌈q·N⌉, plus O(1) interpolation. Per ten quantiles (Path C1's demand), O(B · 10) — but B is typically 30–60 for ltl's heatmap partitions, so this is trivial.
- **Determinism**: Fully deterministic. Output is a function of bin counters only.
- **Fit against Path A**: **Question of partition shape.** Path A needs per-`(category, log_key)` percentiles. If each log_key carries its own bin counter store, the per-key memory is B integers (~B × 8 bytes ≈ 500 bytes per key for B=60). For 10⁵ distinct keys, this is ~50 MB of counter storage — comparable to or worse than the current raw arrays for low-N keys, but **bounded** rather than growing with values per key. For high-traffic keys (N=10⁶), this is a massive memory win. Accuracy depends on whether the partition's bin boundaries are appropriate for the per-key value range — open question whether one global partition serves all keys or each key needs an adaptive partition.
- **Fit against Path B**: **Natural fit.** Path B is per-`time_bucket`; #34's heatmap already produces a counter store keyed by `time_bucket`. The audit explicitly identifies this as the natural source. Accuracy is governed by the heatmap's partition shape — same partition for heatmap rendering and percentile derivation means rendering and percentile values are mutually consistent by construction.
- **Fit against Path C1**: **Natural fit.** Histogram's bin counters are the partition; percentile derivation reads them directly. 10-quantile demand (including P99.99) hits the partition's high-end resolution — the highest bin may not have enough sub-bin resolution for P99.99 if N is small or the partition tops out. Open question whether out-of-range overflow tallies (#34 R5/R6) need special handling at the extreme tail.
- **Fit against Path C2**: **Natural fit, and uniquely so.** Path C2 stores bin indices, not values. Bin-derived interpolation returns a value that is then mapped *back* to a bin index — but the algorithm already knows the bin during its scan, so a variant of the primitive (#189 R4-bis) returns the bin index directly without value round-trip. This is the only candidate that natively produces Path C2's output form.
- **Harmonization implication**: **Maximum.** All four paths read the same primitive against the same counter substrate. No independent estimator state. #189 R4 is one function call, not four. The bin-counter store is already required for #34's heatmap/histogram rendering, so percentile derivation is a side benefit at zero memory overhead.
- **Open questions**:
  - **Per-key partition shape for Path A.** The single biggest unresolved question. If Path A uses one global partition, accuracy on per-key value ranges that fall in a narrow sub-range of the global partition degrades sharply (all values land in 2–3 bins). If Path A uses per-key partitions, the partition itself must be determined adaptively from per-key data — circular dependency at parse time. D3 must address this; if no clean answer exists from literature, it is a D4 trigger candidate.
  - **Tail accuracy at P99.9 / P99.99 for heavy-tailed distributions.** Bin-derived interpolation's worst-case error scales with bin width at the tail bin. Log-spaced partitions have wider bins at the high end (by design — that's where the resolution savings come from). For very heavy tails, the highest bin may span 2–10× in value, meaning P99.9 has potentially that level of relative error. Whether this is acceptable for SRE latency reporting is a D3 decision that depends on R4's tolerance.
  - **Small-N behavior.** When a partition has more bins than values (Path B narrow buckets, Path A single-occurrence keys), interpolation between sparsely-populated bins produces step-function outputs. The audit already notes this as a Path A/B concern; bin-derived interpolation must either fall back to exact-mode behavior at small N or accept the step-function output.
  - **Out-of-range tallies.** #34 R5/R6 produce overflow counts at the low and high ends. The percentile primitive must either consume these (and treat them as values at the partition edge) or the consumer must fold them into edge bins. This is a primitive-design question for #189 R4, not an algorithm-choice question for D3.

##### Adjacent candidate A — DDSketch (Datadog)

**Source**: Masson, Rim, Lee, *"DDSketch: A Fast and Fully-Mergeable Quantile Sketch with Relative-Error Guarantees"* (VLDB 2019). Surfaced because: it is the modern relative-error-guaranteed sketch, designed for the latency-distribution use case ltl primarily serves.

- **Accuracy guarantee**: **Theoretical worst-case bound** of α relative error in *value space* (not rank space) — uniform across quantiles. For α=0.01, every quantile returned is within 1% of the true value. This is the strongest guarantee form for ltl's use case, where users reason in milliseconds, not ranks.
- **Memory profile**: O((1/α) log(max/min)) bins. For α=0.01 and a duration range from 1ms to 1 hour (max/min = 3.6×10⁶), state is ~1500 bins ≈ 10–20 KB. State grows with the *log of value range*, not with N.
- **CPU profile**: Per-update O(1) (constant-time bin assignment via a closed-form log-spaced index). Per-finalize O(state size).
- **Determinism**: Fully deterministic.
- **Fit against Path A**: Good — relative-error guarantee is exactly what SRE latency reporting wants. Per-key partitions where each key only sees a narrow value range are inefficient (state proportional to value range, not data range), but bounded.
- **Fit against Path B**: Good. Mergeability is a feature (different time buckets' sketches could be combined for derived aggregations).
- **Fit against Path C1**: Good. Relative-error guarantee at all 10 quantiles.
- **Fit against Path C2**: Good. Numeric output to bin index.
- **Harmonization implication**: **Structurally similar to bin-derived interpolation** — DDSketch *is* essentially a partitioned counter store with a published relative-error guarantee. The partition shape is fixed (log-spaced with rate 1+α) rather than free, but the data structure is the same family as #34's bin counters. This raises a follow-up question for D3: could #34's bin counters be *configured* as DDSketch-compatible partitions, giving the relative-error guarantee without an independent estimator? If yes, this merges with the "Bin-derived interpolation" candidate above with a published bound. If no (e.g., because heatmap rendering needs a different bin count than DDSketch's α implies), they remain distinct.
- **Open questions**:
  - Whether #34's partition shape is compatible with DDSketch's α-parameterized partition.
  - Whether ltl's value range (min/max) is bounded enough to keep state small — DDSketch can blow up if max/min is extreme.

##### Adjacent candidate B — HdrHistogram

**Source**: Tene, *HdrHistogram: A High Dynamic Range Histogram* (open-source, ~2010s). Industry standard in JVM-language latency reporting. Surfaced because: it is the de facto latency-histogram structure in the JVM ecosystem and is specifically designed for the SRE-latency use case.

- **Accuracy guarantee**: Configurable precision; typically 3 significant digits → ~0.1% relative error in value space. Like DDSketch, value-space relative error rather than rank error.
- **Memory profile**: Fixed-size by configuration: ~tens of KB for a 3-significant-digit histogram covering nanoseconds to hours. Does not grow with N.
- **CPU profile**: O(1) update (closed-form bin assignment).
- **Determinism**: Fully deterministic.
- **Fit against all paths**: Structurally identical to bin-derived interpolation with a fixed, opinionated partition shape (log-spaced subdivided into linear sub-bins). Tail accuracy is excellent — designed for it. Harmonization opportunity same as DDSketch: if #34's bin counters can be configured HdrHistogram-style, the published bound transfers.
- **Open questions**:
  - HdrHistogram has no canonical Perl implementation. Reference implementations are JVM and C. Whether porting cost is acceptable, or whether the partition logic alone can be embedded in #189, is open.
  - Whether HdrHistogram's fixed partition strategy is too rigid for ltl's variable bucket-count consumers (heatmap `-hmw`, histogram `calculate_histogram_bucket_count`).

##### Adjacent candidate C — P-square (Jain & Chlamtac)

**Source**: Jain & Chlamtac, *"The P² algorithm for dynamic calculation of quantiles and histograms without storing observations"* (CACM 1985). Surfaced because: classical single-pass online estimator with O(1) state, occasionally cited as a baseline.

- **Accuracy guarantee**: No worst-case bound. Empirically accurate at moderate quantiles, **poor at extreme tails** (P99.9, P99.99) — known limitation in the literature.
- **Memory profile**: O(1) — five marker positions. State is negligible.
- **CPU profile**: O(1) per update.
- **Determinism**: Deterministic for fixed input order.
- **Fit against all paths**: **Poor for ltl's use case.** Tail-quantile accuracy is the dominant requirement; P-square's known weakness is exactly there. Listed for completeness but not seriously competitive against any of the above.
- **Open questions**: None worth pursuing — the literature already establishes P-square as inappropriate for tail-quantile-critical workloads.

##### Adjacent candidate D — Reservoir sampling + exact

**Source**: Vitter, *"Random sampling with a reservoir"* (TOMS 1985). Surfaced because: it offers a simple form of bounded state — store a uniform random sample of size K, compute exact percentiles on the sample.

- **Accuracy guarantee**: Statistical, not worst-case. Standard error scales as O(1/√K). For K=1000, ~3% standard error at any quantile. Tail quantiles (P99.9) require larger K to have meaningful resolution — at K=1000, only ~1 sample lands above the true P99.9, so the estimate is extremely noisy.
- **Memory profile**: O(K) — fixed.
- **CPU profile**: O(1) per update (with the standard skip-step optimization).
- **Determinism**: **Randomized.** Requires reproducible seeding; for R6 the seed must be derived from input deterministically.
- **Fit against all paths**: **Acceptable for low-tail-importance use cases only.** Path C2's P99.9 marker would be too noisy to render reliably; Path A's P99.9 would not meet SRE latency-reporting standards. Listed for completeness; not competitive at tail quantiles.
- **Open questions**: None — the statistical-noise floor at low K is well-characterized, and at high K the memory advantage disappears.

#### D1 study — synthesis across candidates

The candidates fall into three architectural families, and D3's options reduce to choosing among the families:

**Family 1 — Independent sketches with published bounds.** KLL, GK, q-digest, DDSketch. Estimator state separate from #34's bin counters. Trade-off: published accuracy bounds (a benefit for R4's reporting requirement) at the cost of running two data structures (counters for #34's rendering, sketch for percentiles). KLL and DDSketch are the strongest members — KLL for rank-space rigor with smallest memory, DDSketch for value-space relative-error guarantee.

**Family 2 — Independent sketches without published bounds.** t-digest, P-square. t-digest has strong empirical tail accuracy on heavy-tailed data but no theoretical bound; P-square is dominated. The trade-off is identical to Family 1 except R4 must commit to empirical (not theoretical) accuracy.

**Family 3 — Bin-derived interpolation.** Reuses #34's bin counters as the sole data structure. Trade-offs: zero additional state, maximum architectural harmonization, **and** if the partition shape is chosen to be DDSketch-compatible or HdrHistogram-compatible, transfers their published bounds. The risk concentrates in two places: (a) Path A's per-key partition shape question (the single largest open question of Phase 1), and (b) tail-quantile accuracy at very heavy tails when the highest bin is wide.

**Cross-family observations:**

- **The bin-derived family is the only one with native fit for Path C2** (bin-index output form). Other families require numeric-to-bin-index round-trip via #189 R2; bin-derived can short-circuit it (#189 R4-bis).
- **The bin-derived family is the only one that eliminates an independent state structure.** All other families coexist with #34's counters rather than unify with them.
- **The bin-derived family inherits its accuracy from the partition shape.** If the partition is "free" (data-driven, chosen for rendering aesthetics), the accuracy guarantee is empirical and partition-dependent. If the partition is "constrained" (e.g., DDSketch's log-spaced with parameter α), a published bound transfers but the partition is no longer free.
- **For Paths A and B at small N**, all candidates degrade. The natural fallback in all families is exact mode (R2.3 gate) — which means the small-N concern is a *gating-criteria* question (D3's R2.3 design) rather than an algorithm-choice question per se.
- **Determinism (R6)**: KLL randomized variant and reservoir sampling require seed discipline. All other candidates (including KLL deterministic variant) are deterministic for fixed input. Bin-derived interpolation is the simplest determinism story.

#### D1 study — open questions surfaced for D3 / D4

Questions the literature cannot resolve on its own, ordered by how directly they affect the algorithm-choice decision:

1. **Path A partition shape for bin-derived interpolation.** Does ltl use one global partition, per-key adaptive partitions, or some hybrid? This question may have a satisfying literature-grounded answer (e.g., "DDSketch-style log-spaced fixed partition is good enough"), or may require D4 measurement on ltl's heavy-traffic-key value ranges.
2. **Whether #34's bin-counter partition can be made DDSketch/HdrHistogram-compatible.** If yes, Family 3 inherits a published bound and the architectural-harmonization advantage. If no, Family 3's accuracy bound for R4 must be derived from ltl's data empirically (D4 trigger).
3. **Tail accuracy threshold for SRE latency reporting.** What relative-error bound at P99.9 is acceptable for the use case? This is a *user/product* question that D3 must surface for the decision conversation — it bounds which candidates qualify.
4. **R4 reporting unit.** Rank error (KLL/GK), value-relative error (DDSketch/HdrHistogram/t-digest empirical), or value-absolute error (bin-derived raw). The reporting form affects which family's guarantee is most useful in `-V`.
5. **Perl-implementation cost.** No published benchmarks for any of these algorithms in Perl. If the chosen algorithm's update cost dominates parse-loop throughput, Phase 2 ships a regression. D4 trigger if a candidate is otherwise preferred but its Perl cost is uncharacterized.
6. **Small-N gating threshold.** Below what N should the run/key/bucket revert to exact mode? This is an R2.3 design question. Each candidate has a different cross-over point.
7. **Bin-index stability for Path C2 across runs.** Bin-derived interpolation is trivially stable (deterministic function of counters). Other families' stability depends on the numeric-to-bin-index round-trip's sensitivity to small numeric perturbations in the percentile estimate. May be a non-issue (all families are deterministic) but warrants confirmation.

These open questions are the input to D3's decision-support memo and to any D4 prototype that D3 triggers.

### D2 — Representative-dataset cross-reference

The representative data already exists in the `logs/` tree (see `docs/test-logs.md`). D2 is a cross-reference, not a curation effort — its job is to identify which existing log files exercise which use-case regime, so D1's analysis and any later D4 measurement have a known correspondence between dataset and use case.

D2 records, for each of the following regimes, the existing log file(s) that exercise it:

- Heavy-tailed access log (Tomcat / Apache style).
- ThingWorx mixed-traffic log.
- High-cardinality DEBUG-heavy log.
- Small-N case (a few hundred values per `log_key` or per `time_bucket`).
- Degenerate cases (all-same values, single value, zero matched values) — may be reproduced from existing logs via filters, no new files needed.
- Any pathological case relevant to ltl users (extreme outliers, etc.), drawn from existing logs.
- Per-time-bucket sub-samples for Phase 3 readiness — identifying which existing logs naturally produce small N per time bucket.

If a regime is not covered by an existing log file, D2 records the gap explicitly rather than fabricating data; the gap becomes a research input that D1 and D3 weigh.

#### D2 cross-reference

Populated against the inventory in `docs/test-logs.md` at `release/0.14.5` HEAD. Sizes shown for orientation only; relevance is determined by the regime, not the size.

| Regime | Why it matters to this research | Existing log file(s) | Notes |
|---|---|---|---|
| Heavy-tailed access log (Tomcat / Apache) | The dominant Phase 2 use case (Path A) and a Phase 3 driver (Path B). Tomcat/Apache access logs have right-skewed duration distributions — most responses fast, a long tail of slow ones. Tail-quantile (P99, P99.9) accuracy under this shape is the primary stress test for any candidate algorithm. | `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt` (277 MB Tomcat 9, ms latency); `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-06.txt` (220 MB); `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt` (148 MB); `logs/AccessLogs/localhost_access_log.2025-03-21.txt` (2.6 MB, fast iteration); `logs/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log` (658 KB, Apache HTTP2 with microsecond latency — distinct unit regime) | The four Tomcat files form a graduated size series for the same workload — useful for any analysis that wants to vary N without changing distribution shape. |
| ThingWorx mixed-traffic log | Path A and Path B coverage on a structurally different log family. ThingWorx CustomThingworxLogs carry `durationMS=` fields, enabling per-message latency percentiles on a non-access-log distribution shape (service-call latencies rather than HTTP response latencies). | `logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log` (29 MB, canonical heatmap file per CLAUDE.md); `logs/ThingworxLogs/CustomThingworxLogs/ScriptLog.2025-04-09.1.log` through `.4.log` (72–98 MB each, same workload graduated); `logs/ThingworxLogs/CustomThingworxLogs/ScriptLog.2025-04-10.0.log` (98 MB); `logs/ThingworxLogs/CustomThingworxLogs/ScriptLog.log` (54 MB) | The clean variant has duration, bytes, and count metrics simultaneously — useful for cross-metric percentile coherence checks. |
| High-cardinality DEBUG/ERROR-heavy log | Path A under the regime where the per-`log_key` distribution flattens (many distinct log keys, few values each). Stresses the small-per-key-N behavior of any algorithm chosen for Path A. Also relevant to Path C1 if histogram mode is engaged on the same file. | `logs/ThingworxLogs/HundredsOfThousandsOfUniqueErrors.log` (101.7 MB; 288K lines, ~286K unique keys — per consolidation memory); `logs/ThingworxLogs/ApplicationLog.2025-05-05.0.log` (85 MB, broader L:DEBUG/INFO/WARN/ERROR mix); `logs/ThingworxLogs/ApplicationLog.2025-05-06.0.log` (6.5 MB); `logs/ThingworxLogs/ApplicationLog.2025-12-12.282-Windows.log` (10 MB, Windows variant) | These files do not carry per-message duration values (no `durationMS=`). They are relevant to Path C1 (histogram-mode global, when `-hg` is run) and to count-based percentile regimes; per-message duration percentiles (Path A) do not apply to these files unless paired with a metric source. Documented as a constraint, not a gap. |
| Small-N case (a few hundred values per `log_key` or per `time_bucket`) | Path B at typical bucket sizes routinely produces small N per bucket. Path A at one-off log messages produces single-occurrence keys. Any candidate algorithm must be characterized at this regime; sketches with fixed compression parameters may exceed their state size at small N, while bin-derived interpolation degenerates to bin-index accuracy. | `logs/Codebeamber/codebeamer_access_log.2025-10-29.txt` (83 KB, naturally small); `logs/ThingworxLogs/CustomThingworxLogs/ScriptLog.GetComplexPlotByIndex.log` (739 KB, single-service slice); `logs/ThingworxLogs/AuthLog.2025-05-06.0.log` (257 KB); `logs/ThingworxLogs/DatabaseLog.2025-05-05.0.log` (700 KB); `logs/ThingworxLogs/DatabaseLog.log` (29 KB, very small) | Small-N per *time bucket* can also be induced on any larger file by narrowing the bucket size (`-b 0.1` for 6-second buckets, `-ms` for millisecond precision). The cross-reference notes that this is reachable from existing files via CLI flags rather than requiring a dedicated file. |
| Degenerate — all-same values | Edge case R5; trivially handled by exact mode; approximate mode must agree. | Reproducible by filtering any existing file to a single repeated message (`-if <pattern>` selecting one log_key) where every value is the same — common for health-check endpoints. Health-check filter pattern files exist (`patterns/probes`, `patterns/metrics`). | No dedicated file. |
| Degenerate — single value | Edge case R5. | Reproducible by filtering any existing file to a one-occurrence message. | No dedicated file. |
| Degenerate — zero matched values | Edge case R5. | Reproducible on any file with `-if nonexistent-pattern`. | No dedicated file. |
| Pathological — extreme outliers in heavy-tailed data | Captures the regime where a few values are orders of magnitude above the bulk. Stresses tail-quantile (P99.9) accuracy specifically; the question is whether the algorithm represents the outlier as a distinct rank or absorbs it into a neighboring bin/centroid. | The Tomcat access logs listed under "Heavy-tailed" already exhibit this naturally — occasional multi-second requests in millisecond-dominated traffic. `logs/AccessLogs/really-big/*` (8.5 GB Tomcat 10, 4 servers × 28 days) is the production-scale variant if outlier density at scale is part of D1's analysis. | The `really-big/*` set is large enough to stress production-scale considerations but is not required for D1's literature work. |
| Per-time-bucket sub-samples (Phase 3 readiness) | Phase 3 (Path B) reads percentiles per `time_bucket`. The N per bucket varies with file size, traffic density, and bucket width. D1 must consider candidate algorithms' behavior across the resulting N regime (tens to thousands of values per bucket on typical files; extremes possible). | Achievable from any heavy-tailed access log by varying `-b` (e.g., `-b 0.1` on the 2.6 MB file produces narrow buckets with low per-bucket N; `-b 60` on the 277 MB file produces wide buckets with high per-bucket N). The extreme small cases are `logs/ThingworxLogs/ApplicationLog-improperlyRead.log` (468 B) and `logs/ThingworxLogs/CommunicationLog.2025-05-06.0.log` (190 B) where the entire file is a few lines. | No dedicated per-bucket sub-sample file; the regime is reached by CLI flag variation on the heavy-tailed files. |

#### Gaps recorded

- **No log with externally-labeled ground-truth percentile values.** All ground truth for accuracy comparison is derived by running ltl in exact mode on the same file. This is acceptable for D1 (literature analysis does not need empirical ground truth) and for D4 if triggered (exact-mode output is the reference). Recorded so the gap is explicit if D3 later argues for an empirical confirmation step.
- **No synthetic log with controlled distribution parameters** (e.g., Pareto with specified α, log-normal with specified σ). The heavy-tailed access logs are heavy-tailed *in fact* but the tail parameters are not labeled. D1's literature analysis can reference theoretical results for parameterized distributions independently; D3 weighs whether the absence of synthetic controls is a material gap.
- **No log isolating a single percentile-extreme regime.** Real-world logs mix regimes; isolating "small-N only" or "outlier-dominated only" requires CLI filtering of an existing file rather than a dedicated dataset. Recorded as a constraint on how D1 frames its examples (regime descriptions reference CLI invocations on listed files, not standalone synthetic inputs).
- **UDM CSV inputs** (`logs/UDM/*`) are outside the Phase 2/3 scope (those features carry user-defined metrics, not per-message latency for the summary table or per-time-bucket duration for the heatmap). Listed here only to record that they were considered and excluded.

### D3 — Decision-support memo

D3 is the central deliverable of Phase 1. It synthesizes D1 (and the D2 cross-reference) into a written memo whose purpose is to put the user in a position to decide which algorithm (or combination of algorithms) ltl ships. The memo presents *options with trade-offs*, not a pre-committed recommendation.

For each viable option (single-algorithm and hybrid combinations that survive D1's analysis), D3 documents:

- **What this option does** — the algorithm(s) involved, and how each one maps to Paths A, B, C1, C2.
- **What it gains** — the accuracy guarantees, memory profile, harmonization benefits, and operational simplifications relative to status quo.
- **What it costs** — the accuracy compromises, memory or CPU costs, implementation complexity, and any use cases that are served sub-optimally.
- **Open questions** — what remains unresolved from literature alone; what would need D4 measurement to confirm or refute.
- **Implication for the gating criteria (R2.3)** — what input criteria the option requires the run-start gate to evaluate, and qualitative thresholds where the literature supports them.
- **Implication for the accuracy bound (R4)** — what per-quantile bound this option could commit to, and the source of that bound (theoretical guarantee, expected empirical confirmation, etc.).
- **Implication for state budget** — what the option's state size would be, parameterized appropriately.

The memo concludes with a structured comparison (e.g., a matrix across options vs. evaluation criteria) and an explicit list of the *decisions the user must make* to move from Phase 1 to Phase 2 — the algorithm choice, the accuracy bound, the gating thresholds, whether a user-facing precision preference is introduced, and whether any open questions warrant D4 (see below) before deciding.

D3 does **not** lock the implementation. The decision conversation between user and Claude is what locks it; D3 is the input to that conversation.

### D4 — Prototype (conditional)

D4 is **conditional**. It is produced only if D3's analysis identifies open questions that cannot be answered from literature alone and that materially affect the decision. The scope of D4 is bounded by those specific open questions — it is not a flat "implement and measure all candidates" exercise.

When D4 is triggered, it produces a working prototype in `prototype/187-percentile-sketch.pl` (or similar) that:

- Implements only the algorithm(s) the open questions concern.
- Runs against the D2 cross-referenced log files relevant to the open questions.
- Produces measurement output (per-quantile error, state size, CPU cost, etc.) appropriate to the question being answered.
- Is runnable independently of ltl proper so the algorithm can be exercised without touching production code.
- For bin-derived interpolation, includes a mock of the #189 primitive contract so the algorithm can be exercised standalone.

D4's output feeds back into D3, which is updated to reflect the resolved questions. The user-and-Claude decision conversation then proceeds against the updated D3.

If D3's analysis resolves all material questions from literature alone, D4 is not produced and Phase 1 concludes at D3.

### D5 — Production gate

Production implementation references D1, D2, D3, and (when produced) D4 as prerequisites, and treats the decision-conversation outcome that follows D3 as the binding values for R4, R7's `accuracy_estimate`, and the R2.3 / R10 gating criteria. D4 is a prerequisite only when it has been triggered per its conditional clause.

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
