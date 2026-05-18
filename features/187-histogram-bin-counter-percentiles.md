# Feature: Bin-counter-based percentile calculation with dual-mode accuracy (multi-phase rollout)

## Overview

ltl's summary table reports per-message latency percentiles (P1, P5, P25, P50, P75, P90, P95, P99, P99.9). Today these are computed by retaining every individual metric value in an in-memory array (`log_messages{$category}{$log_key}{durations}` at `ltl:4591`), sorting it, and indexing. The algorithm requires `O(n)` memory in the number of values.

This feature replaces those raw-value arrays with the **HdrHistogram-style log-spaced bin-counter primitive that ltl already ships** in the heatmap (`-hm`) and histogram (`-hg`) paths. The substrate is not new: it is the same `min·(max/min)^(i/N)` partition, the same binary-search bin-find, the same `buckets_per_decade` precision knob that has been in production since v0.8. What this feature adds is the **percentile-derivation step** on top of that substrate — `#189` R4, the interpolation primitive — and the **dual-mode gate** that selects between exact (sorted-array) percentiles and bin-counter-derived percentiles based on input scale.

This feature is **architecturally consequential beyond the summary table**. It defines the path by which the existing bin-counter primitives (heatmap, histogram) are extended to the four percentile-computing paths catalogued in R12. The multi-phase rollout in R9 is the staging plan.

## GitHub Issue

[#187](https://github.com/gregeva/logtimeline/issues/187)

## Motivation

For multi-GB runs the per-message percentile arrays are typically the largest single memory consumer in the summary path — comparable in scale to the heatmap/histogram raw arrays that #34 addresses. With #179 reading bounds at start-up and #34 reframing heatmap/histogram around bin counters, the per-message percentile arrays are the next array-shaped consumer to migrate to the same primitive.

The algorithm question for this feature is **not** "which quantile estimator do we pick" — that question was already answered when ltl shipped the heatmap and histogram features. The substrate is HdrHistogram-style log-spaced bin counters, with `buckets_per_decade` as the tunable precision knob:

| Decision | Where it's already locked in code |
|---|---|
| Log-spaced bin geometry `min·(max/min)^(i/N)` | `ltl:4961-4966`, heatmap path |
| Buckets-per-decade precision knob | `ltl:286`, `-hgbpd`, default 8 (~5%) |
| Precision table (4=10%, 8=5%, 16=2.5%, 32=1%) | `histogram-charts.md` lines 258-262 |
| Binary-search bin-find | `ltl:4889-4905` |
| Naming/lineage as "HdrHistogram approach" | `ltl:285`, `ltl:4867`, `ltl:4956` |
| Same primitive for heatmap markers + histogram indicators | `features/34-histogram-bin-counter-mode.md` R4-bis |
| `#189` R4 owns the percentile-interpolation function | `features/189-histogram-bin-counter-primitives.md` R4 |

What this feature contributes — that the heatmap and histogram features did not have to address, because they retain raw values during the same pass that they compute their bin counters — is the **percentile-derivation step on top of the bin counters when the raw values are not retained**. That is `#189` R4. This feature's research is scoped to the open questions about R4's behavior (Phase 1, D1–D3), and its implementation is the dual-mode gate + R4 application to Path A (Phase 2) and progressively to Paths B/C1/C2 (Phases 3+).

A second motivation is architectural: this feature is not a one-shot replacement. It establishes the foundation for a **progressive multi-phase migration** of percentile calculation across ltl, with user-driven precision selection (exact vs. approximate) and automatic determination based on input criteria. Every percentile consumer in ltl is on the path to adopting this same dual-mode foundation. R9 makes that plan explicit.

## Delivery sequence

This feature is one of three co-developed issues (#34, #187, #189). The work is performed in parallel against the `release/0.14.5` branch, with each issue's feature branches merging back periodically. The ordering below is the *delivery* sequence — when each step's output is required to be complete — not a strict serial work order. The multi-phase rollout for this feature itself is detailed in **R9**; the table below positions those phases within the broader cross-issue sequence.

| Step | Work | Owner | Why this position | Status of this file |
|---|---|---|---|---|
| 1 | **Audit** — catalogue existing helpers (heatmap, histogram, summary-table percentile paths); produce consumer-side primitive requirements | **#34 R12** + **#187 R12**; outputs land in **#189** *Audit findings* and *Consumer-side requirements* sections | Both #189's primitive design and this feature's algorithm research need to know what shapes the primitives must support. Without this first, primitives risk being designed for two consumers and reworked later. | **This file owns part of this step (R12); corresponds to R9 Phase 0** |
| 2 | **Research** — literature-grounded extension study of the existing bin-counter substrate against the audited use cases; decision-support memo presenting options and trade-offs for the open questions the substrate's existing implementations do not answer; prototype only if specific open questions warrant measurement | **#187 D1–D5 (D4 conditional)** | The R4 in-bin interpolation strategy, `buckets_per_decade` default, and partition-lifecycle decisions all feed `#189`'s R4 implementation. Performed after audit but before `#189` implementation so `#189` isn't built blind. | **This file's research deliverables; corresponds to R9 Phase 1** |
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
- **Approximate mode** — bin-counter-derived percentile values from the histogram bin-counter substrate (per R8), producing the required percentile values within a documented accuracy bound (R4).

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
- **Layer 2 (approximate mode)**: `buckets_per_decade` (the partition precision parameter), `bin_count` (B per partition), `state_budget_bytes` (the counter store footprint), `in_bin_interpolation` (the strategy chosen at D3), and a per-quantile `accuracy_estimate` block reporting the bound applied to each required quantile. The `accuracy_estimate` block also reports `tail_sample_count_warning: yes|no` per quantile, distinguishing bin-resolution error (bounded) from sample-count starvation (the partition cannot manufacture rank precision the data does not contain).
- **Layer 3 (exact mode)**: `n` (the value count consumed) and a `sorted: yes` line for confirmation.
- **Layer 4 (always)**: `gating_criteria` — the input criteria the gate (R2.3) evaluated this run, each reporting `value`, `threshold`, and `passed: yes|no`. Lets tests assert each criterion independently.

Section name and all labels are part of the feature contract.

### R8 — Coupling to histogram bin counters

Approximate mode operates on **histogram bin counters** — the same HdrHistogram-style log-spaced bin-counter substrate that heatmap (`-hm`) and histogram (`-hg`) already use today, with the partition/assignment/counter primitives defined by #189 (R1, R2, R3) and the percentile-derivation primitive defined by #189 R4. This feature does not maintain a parallel data structure and does not introduce an independent estimator.

This is what makes the multi-phase rollout (R9) coherent: the per-message latency percentile path consumes the same primitive that heatmap and histogram already consume, with #189 R4 providing the percentile-derivation step.

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
- **Migration target (Phase 2)**: replace the raw `durations` array with a histogram bin-counter store keyed by `(category, log_key)` per #189 R3. Replace the sort-and-index core of `calculate_statistics` with #189 R4 invocations against the per-message counter store. R4's in-bin interpolation strategy and `buckets_per_decade` default for this path are decided by D3.
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
- **Memory lifecycle**: counter structures freeable per key independently of the partition. R4 carries no state of its own — it derives from the counter map at invocation time.

This list is the consumer-side input to #189's primitive design.

### Cross-reference

- Full per-site `ltl:line` catalogue with primitive mappings: `features/189-histogram-bin-counter-primitives.md` § Audit findings.
- Per-feature consumer-side requirements (combined #34 + #187): `features/189-histogram-bin-counter-primitives.md` § Consumer-side requirements.
- Cross-cutting constraints discovered during audit: `features/189-histogram-bin-counter-primitives.md` § Cross-cutting compatibility constraints discovered during audit.
- Boundary with #34's heatmap and histogram consumers: `features/34-histogram-bin-counter-mode.md` § Harmonization audit (this feature ships the percentile-interpolation algorithm and progressive consumer migration; #34 ships the heatmap/histogram bin-counter substrate the percentile work consumes).

## Considerations for implementation

The algorithm substrate is fixed (HdrHistogram-style log-spaced bin counters, per Motivation). The items below are the remaining mechanism questions that the research deliverables address.

- **R4 percentile-derivation formula.** Given a partition and a counter map for one key, what does `(target_quantile) → value` compute? This decomposes into a cumulative-count walk (mechanical) plus an in-bin interpolation choice (research question, D3). See **Research deliverables** for the in-bin interpolation alternatives.
- **`buckets_per_decade` for the per-message path.** Existing consumers default to 8 (~5% bin width). For SRE tail-percentile reporting, the per-message percentile path may want a higher value (16 or 32) for tighter accuracy. This is a D3 decision, not an algorithm choice.
- **Tail-bin behavior.** Bin-counter accuracy is bounded by bin width *uniformly* across quantiles (the same ~5% at P50 as at P99.9 for `buckets_per_decade=8`). The historically separate concern — "sample-count starvation at the tail" (P99.9 of 50 samples is meaningless) — is a property of *any* percentile estimator including the current sorted-array code; this feature does not introduce it but does make it visible via `-V`. See R4.
- **Accuracy-reporting unit.** Value-relative error (bounded by `1 - 10^(-1/buckets_per_decade)`). This is a property of the log-spaced partition, not a research question.
- **Memory behavior across modes.** The approximate-mode bin-counter store replaces the exact-mode value array. Mixed-mode behavior is well-defined per R13; lifecycle composes with #23 Phase 2's named-stage memory model.
- **Highlight subsets.** Phase 4 coordination with #51.
- **State lifecycle and reset.** Counter store freed when no longer needed; lifecycle composes with #23 Phase 2.

## Edge cases

| Case | Required behavior |
|---|---|
| No matched messages | Percentiles emit `-`; no estimator runs; `-V` reports `feature_not_active`. |
| All matched values are identical | Every percentile equals that value (exact and approximate modes agree). |
| Single matched value | Every percentile equals that value. |
| Very small N below D3's threshold | Gate (R2.3) steers to exact mode; `reason: input_criteria_failed`. |
| Stale or missing index | R2.1 fails; exact mode runs; `reason: no_index`. |
| Filtered run with only Tier-2 pre-seed | R2.2 fails; exact mode runs; `reason: tier_mismatch`; gap recorded against #179. |
| Approximate mode chosen but histogram bin counters unavailable (#34 ineligible) | Gate (R2.3) treats absence of histogram bin counters as a failed gating criterion. `reason: input_criteria_failed` with the specific criterion identified in `gating_criteria`. |
| Bounds drift mid-run | Exact-mode output unchanged. Approximate-mode behavior under drift is determined by D3; the accuracy bound (R4) must still hold or the gate must have excluded the run. |
| User-forced exact mode | If D3 introduces a user-facing precision preference and the user selects exact, gate fails by design; `reason: user_forced_exact`. |
| Highlight pattern present (pre-Phase 4) | Highlight-subset percentiles run in exact mode regardless of main-set mode; recorded as a Phase 4 dependency. |
| Concurrent ltl processes | Inherited from #179; out of this feature's concern. |

## Acceptance criteria

- [ ] R1–R13 hold across the representative-dataset set (D2).
- [ ] Phase 0 deliverables complete: this feature file, the audit (R12), the consumer-side primitive requirements landed in `features/189-histogram-bin-counter-primitives.md`.
- [ ] Phase 1 research deliverables (D1, D2, D3, and D4 if triggered) complete, and the decision conversation that follows D3 has produced the binding values for algorithm choice, accuracy bound, and gating thresholds, before Phase 2 implementation.
- [ ] For every input in the D2 set, each required quantile from approximate mode falls within the D3 accuracy bound around the exact value.
- [ ] When approximate mode runs, R3–R8 hold; `state_budget_bytes` in `-V` matches actual counter-store memory; `buckets_per_decade`, `bin_count`, and `in_bin_interpolation` are reported per R7.
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
| `warm-eligible-approximate` | Fresh index pre-seed; input meets D3 gating criteria. | `ltl <F> -V`. | `percentile_mode: approximate`, `reason: approximate_eligible`, `buckets_per_decade` and `bin_count` populated, `in_bin_interpolation` populated, `accuracy_estimate` per quantile populated. |
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

### D1 — Extension study (literature-grounded)

D1 characterizes the **HdrHistogram-style log-spaced bin-counter substrate** (the substrate already shipped in `-hm` and `-hg`) against the four percentile-computing use cases catalogued in R12, identifies what the existing implementations already answer, and isolates the questions that extending the substrate to those use cases leaves open. It is literature-grounded; measurement is conditional on D4 (see below).

D1 does **not** open a multi-algorithm comparison. The substrate choice is settled by prior art in this codebase:

- `ltl:285-287, 4867-4905, 4956-4975` — log-spaced bin geometry, `buckets_per_decade` precision knob (default 8 → ~5% bin width), binary-search bin-find.
- `features/heatmap.md` and `features/histogram-charts.md` — design decisions, color/render integration, and the `-hgbpd` CLI knob.
- `features/34-histogram-bin-counter-mode.md` R4-bis — heatmap markers and histogram indicators both derive from `#189` R4 under bin-counter mode.
- `features/189-histogram-bin-counter-primitives.md` R1–R4 — partition, assignment, counter-update, and percentile-interpolation primitives.

The study presents the substrate's known properties for each use case and lists the open questions that the decision conversation must close before Phase 2 implementation. The decision is made by the user against D3's synthesis.

**The study covers:**

- The substrate's properties as already shipped (bin geometry, precision knob, bin-find).
- How those properties map to each of Paths A, B, C1, C2 (the existing implementations already cover C1 and C2 with raw-array sort for percentile derivation; A and B are the migration targets).
- What changes when raw values are *not* retained (the per-message migration target): how percentiles are derived directly from bin counters via #189 R4.
- The accuracy story decomposed into its two genuinely separate sources: bin-resolution error (bounded by `buckets_per_decade`) and sample-count starvation at the tail (a property of every percentile estimator including the current sorted-array code).
- Open questions for D3 that the existing features do not answer.

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

- **Per-quantile accuracy bound (R4)**: reported in `-V` per quantile. With log-spaced bins the bound is uniform across quantiles for the *bin-resolution* component; the *sample-count starvation* component is reported separately per R7's `tail_sample_count_warning`.
- **Degenerate inputs (R5)**: zero, one, or all-same values must produce correct output without crashing.
- **Wide percentile set support**: `#189` R4 must handle all percentiles required by any consumer; the 10-value set from Path C1 is the worst case.
- **Out-of-range tallies (#34 R5/R6)**: under bin-counter mode, values below the partition's low edge or above its high edge are counted but not placed in interior bins. Handling is a `#189` R4 design question — D3 Decision 4 picks fold-into-edge-bins vs. separate-population.

#### D1 study — the substrate as already shipped

The HdrHistogram-style log-spaced bin-counter substrate is implemented and in production. The characterization below summarizes its properties as they apply to all four percentile-computing paths.

##### Bin geometry

**Partition**: `boundary[i] = min · (max/min)^(i/B)` where B is the bin count. Number of bins is `decades · buckets_per_decade` rounded to integer, with a minimum of 5 (`calculate_histogram_bucket_count` at `ltl:4867-4887`). Per-bin width ratio is `10^(1/buckets_per_decade)` — independent of position in the partition, by construction.

**Precision knob**: `buckets_per_decade`. The values shipped in `histogram-charts.md` correspond to:

| `buckets_per_decade` | Per-bin width ratio | Max relative error (bin midpoint) |
|---|---|---|
| 4 | 1.78× | ~28% |
| 8 (default) | 1.33× | ~14% |
| 16 | 1.155× | ~7% |
| 32 | 1.075× | ~3.6% |

These error bounds apply *uniformly* across quantiles — P50 and P99.9 inherit the same bound from the partition. The headline numbers in `histogram-charts.md` (10%, 5%, 2.5%, 1%) report the per-bin width fraction; the worst-case midpoint error is roughly half the bin width.

**Bin-find**: binary search over the boundary array (`find_histogram_bucket_index` at `ltl:4889-4905`). Closed-form `floor(B · log(v/min) / log(max/min))` is an alternative the consumer can choose at `#189` R2 implementation time.

##### Memory profile per partition

`B + 1` integer counters per partition. For B = 40 (default 5 decades × 8 buckets/decade), that is ~320 bytes per partition at 8 bytes per counter. Asymptotically independent of N.

For Path A (per-`(category, log_key)` partitions) at 10⁵ keys × ~320 bytes = ~30 MB total counter storage. Compares against today's `durations` arrays which scale with `sum_over_keys(occurrences_per_key) · 8 bytes` — typically hundreds of MB to GB on multi-GB runs.

For Path B (per-`time_bucket` partitions) when heatmap is active, the existing heatmap counter store is the source — zero additional state. When heatmap is not active, Phase 3 introduces a per-bucket counter store with the same shape.

##### CPU profile per partition

Per-update: O(log B) for binary-search bin-find, or O(1) for closed-form. No additional cost beyond counter increment.

Per-finalize: O(B) cumulative-count walk to locate the target bin, plus O(1) interpolation. For ten quantiles (Path C1's demand), O(10·B). B is typically 30–60, so per-finalize is trivial.

##### Determinism

Fully deterministic. Output is a function of bin counters only. R6 satisfied trivially.

##### Fit against each percentile-computing path

**Path A — summary-table per-message percentiles (Phase 2 target).** Per-`(category, log_key)` partition. Each `log_messages` entry already tracks its own `min` and `max` online (`ltl:5369-5371`) — the partition can be sized from those. Bin counter store replaces the raw `durations` array at `ltl:4591`. Percentile derivation (`calculate_statistics` at `ltl:5488`) replaces sort-and-index with `#189` R4 against the counter store. Counter footprint per key is small (B integers, ~320 bytes at B=40); the win at heavy-traffic keys (N=10⁴–10⁶) is large; the loss at single-occurrence keys is bounded.

**Path B — per-time-bucket duration percentiles (Phase 3 target).** Per-`time_bucket` partition. When heatmap is active, the heatmap counter store *is* the partition — Path B reads it via `#189` R4. When heatmap is not active, Phase 3 introduces an equivalent per-bucket counter store. The raw `durations` array at `ltl:4634` is removed.

**Path C1 — histogram-mode global percentiles (incidental Phase 2 consumer).** Single partition per metric. Histogram already builds the bin counters (`ltl:4961-4975`); today's code redundantly sorts the raw values for percentile derivation (`ltl:4926-4940`). The migration removes the redundant sort: percentiles derive from the bin counters via `#189` R4.

**Path C2 — heatmap percentile markers.** Per-`time_bucket` partition. Today's code sorts raw values to find bin indices (`ltl:4823-4834`). Under `#34` bin-counter mode, markers derive from `#189` R4 against the counter store, with the numeric return mapped back to a bin index via `#189` R2. Already documented as the migration target in `features/34-…md` R4-bis.

##### Accuracy story — two genuinely separate sources of error

This is the analytical heart of D1. Tail-quantile accuracy concerns (P99.9, P99.99) decompose into two independent sources, and they need to be reasoned about separately because only one of them is introduced by the bin-counter approach.

**Source 1 — Bin-resolution error.** Bounded uniformly by partition geometry. For `buckets_per_decade = N`, each bin spans a factor of `10^(1/N)` in value, and a percentile that falls inside a bin can be returned anywhere in that range. The bound applies *equally* at P50 and at P99.9 — there is no tail-amplification of bin-resolution error in a log-spaced partition.

| `buckets_per_decade` | Bound (bin midpoint return) | Bound (linear-in-log interpolation in bin) |
|---|---|---|
| 4 | ~28% | ~14% |
| 8 (default) | ~14% | ~7% |
| 16 | ~7% | ~3.5% |
| 32 | ~3.6% | ~1.8% |

**Source 2 — Sample-count starvation at the tail.** Not introduced by this feature. P99.9 of 1,000 samples = the single highest value; P99.9 of 50 samples is meaningless. Today's sorted-array code (`ltl:5519-5525`) silently returns `sorted[int(N · 0.999)]` regardless of whether N supports that rank — a 50-occurrence message will report `sorted[0]` (the minimum) as its "P99.9". This is not accuracy; it is silence about being inaccurate.

The bin-counter approach inherits this limitation (no estimator can manufacture rank precision the data does not contain) but can **make it visible**: once the cumulative-count walk reaches the target rank, the consumer knows exactly how many samples support it. `-V` Layer 2 reports `tail_sample_count_warning: yes|no` per quantile, surfacing what the array code hides.

**SRE implication.** For high-volume messages and time buckets — the regime where P99.9 is operationally meaningful — bin-resolution error at `buckets_per_decade = 16` or `32` is well within SRE tolerances. For low-volume messages and time buckets, neither approach gives a trustworthy P99.9, and the bin-counter approach honestly reports that. This is a feature, not a regression.

#### D1 study — open questions for D3

These are the questions the existing heatmap, histogram, `#34`, and `#189` documents do not answer, and that the decision conversation that follows D3 must close before Phase 2 implementation:

1. **In-bin interpolation strategy for `#189` R4.** Once the cumulative-count walk locates the target bin, what value does R4 return? Candidates:
   - **(a) Bin lower boundary** — coarsest; no interpolation math; max relative error is the full bin width (~14% at `buckets_per_decade=8`).
   - **(b) Bin midpoint** — half the bin width error; trivial math.
   - **(c) Linear-in-value within the bin** — `lower + (rank_within_bin / bin_count) · (upper − lower)`. Halves the average error against (b) when values inside the bin are roughly uniform on a linear scale.
   - **(d) Linear-in-log within the bin** — `lower · (upper/lower)^(rank_within_bin / bin_count)`. Halves the average error against (b) when values inside the bin are roughly uniform on a log scale (the natural assumption for a log-spaced partition fed heavy-tailed data).
2. **`buckets_per_decade` default for the per-message percentile path (Path A).** Existing consumers default to 8 (~14% midpoint error). For Path A's SRE latency-reporting use case, the default may want to be 16 (~7%) or 32 (~3.6%). Memory grows linearly with `buckets_per_decade` per partition, so this is a trade-off worth setting explicitly. The CLI already exposes `-hgbpd` for the histogram path; Path A may want its own knob or may inherit `-hgbpd`.
3. **Tail-bin behavior when `buckets_per_decade` is high.** At `buckets_per_decade = 32`, the highest bins may contain very few samples even at high N. Does R4 fall back to a coarser interpolation (return the bin midpoint) when the sample count in the target bin drops below some threshold? Related to the sample-count-starvation visibility in `-V`.
4. **R2.3 trigger threshold — when does exact mode fire.** This feature's gate (R2) decides between exact and approximate mode. The threshold needs to be chosen: a small-N cutoff (below which sorting the array is cheaper), an index/bounds-availability check (R2.1/R2.2), or a user-facing override (`--exact-percentiles`). The decision conversation produces the specific values.
5. **Out-of-range tally handling.** `#34` R5/R6 tracks values outside the partition's `[min, max]` range. Under bin-counter mode, does R4 fold those into edge bins (treating them as if they landed at the boundary) or count them as separate populations? `#189` R4 must specify which.
6. **Path A partition lifecycle when the per-`(category, log_key)` `min`/`max` is only known partway through the parse.** Heatmap and histogram do a final-pass after global `min`/`max` are known (`calculate_histogram_buckets` at `ltl:4908` is end-of-pass). For per-message percentile counters built online, the partition would have to be sized from per-key `min`/`max` discovered during the parse — which means re-binning if a new value extends the range. Acceptable strategies: (a) two-pass (parse once for per-key bounds, once for counter accumulation), (b) widen-and-rescale (rebuild the partition when a new value falls outside), (c) accept a fixed default range. Each has known trade-offs; D3 picks.

These six questions are the input to D3's memo. None of them require empirical measurement to *enumerate*; one or more may benefit from a prototype to *decide* (D4-trigger candidates).

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
| Small-N case (a few hundred values per `log_key` or per `time_bucket`) | Path B at typical bucket sizes routinely produces small N per bucket. Path A at one-off log messages produces single-occurrence keys. The substrate's behavior here is the focus of D3 Decision 3 (tail-bin fall-through) and Decision 6 (small-N gating into exact mode). | `logs/Codebeamber/codebeamer_access_log.2025-10-29.txt` (83 KB, naturally small); `logs/ThingworxLogs/CustomThingworxLogs/ScriptLog.GetComplexPlotByIndex.log` (739 KB, single-service slice); `logs/ThingworxLogs/AuthLog.2025-05-06.0.log` (257 KB); `logs/ThingworxLogs/DatabaseLog.2025-05-05.0.log` (700 KB); `logs/ThingworxLogs/DatabaseLog.log` (29 KB, very small) | Small-N per *time bucket* can also be induced on any larger file by narrowing the bucket size (`-b 0.1` for 6-second buckets, `-ms` for millisecond precision). The cross-reference notes that this is reachable from existing files via CLI flags rather than requiring a dedicated file. |
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

D3 is the central deliverable of Phase 1. It synthesizes D1's analysis into a memo whose purpose is to put the user in a position to **make the six decisions** D1 surfaced as open. The memo presents options for each decision with trade-offs, not a pre-committed recommendation.

D3 does **not** lock the implementation. The decision conversation between user and Claude is what locks it; D3 is the input to that conversation.

#### D3 memo — the six decisions

For each open question from D1, D3 presents the candidate answers with their consequences, the dependencies between decisions, and the D4-trigger condition that fires if literature is insufficient to choose.

##### Decision 1 — In-bin interpolation strategy for `#189` R4

Once R4's cumulative-count walk locates the bin containing rank `q · N`, what value does R4 return?

| Strategy | What it returns | Max relative error (`buckets_per_decade=8`) | Trade-off |
|---|---|---|---|
| (a) Bin lower boundary | `boundary[i]` | Bin width (~33%) | Simplest; coarse. |
| (b) Bin midpoint | `(boundary[i] + boundary[i+1]) / 2` | Half bin width (~17%) | Trivial math; no use of in-bin rank. |
| (c) Linear-in-value | `lower + (rank_in_bin / bin_count) · (upper − lower)` | Distribution-dependent | Better on roughly-uniform-in-value data. |
| (d) Linear-in-log | `lower · (upper/lower)^(rank_in_bin / bin_count)` | Distribution-dependent | Better on roughly-uniform-in-log data (the natural assumption for log-spaced bins fed heavy-tailed data). |

**Recommendation framing**: (d) matches the partition's geometry and ltl's primary use case (heavy-tailed latency). (b) is the fall-through when in-bin rank is unavailable or when the bin contains very few samples. (a) and (c) are listed for completeness; neither has a strong case in ltl's regime.

**D4-trigger**: if the decision conversation cannot decide between (b), (c), (d) from D1's analysis alone, prototype on a heavy-tailed access log (D2 cross-reference identifies candidates) and compare per-quantile error against exact-mode output. Bounded scope.

##### Decision 2 — `buckets_per_decade` default for the per-message percentile path

The existing histogram default is 8 (~14% midpoint error). For Path A's SRE-grade tail-percentile reporting, the natural choice is higher.

| `buckets_per_decade` | Bins per partition at 5 decades | Bytes per partition (8 B/counter) | Bound (interpolated) |
|---|---|---|---|
| 8 (existing default) | 40 | 320 B | ~7% |
| 16 | 80 | 640 B | ~3.5% |
| 32 | 160 | 1280 B | ~1.8% |

At 10⁵ keys, the total counter store is ~32 MB / 64 MB / 128 MB respectively — all small compared to today's array storage on multi-GB runs. Memory is not the binding constraint; the choice is between "tight enough for SRE work" and "tighter than needed."

**Recommendation framing**: 16 is the natural starting point. The decision conversation may choose to inherit `-hgbpd` (consumer-controlled), or to introduce a separate `--percentile-buckets-per-decade` knob for Path A.

**D4-trigger**: none. This is a defaulting decision with bounded memory implications at all options.

##### Decision 3 — Tail-bin fall-through behavior

At high `buckets_per_decade`, the highest bins may contain very few samples even at high N. When R4's cumulative walk lands in a target bin where the in-bin count is below some threshold (e.g., < 3), interpolation strategies (c)/(d) become noise.

| Approach | Behavior |
|---|---|
| Always interpolate | Use chosen strategy regardless of in-bin count. Simplest. |
| Threshold fall-through | If in-bin count < T (e.g., T=3), fall through to bin midpoint. Tunable. |
| Per-quantile signaling | Always interpolate, but also report `tail_sample_count_warning` in `-V` Layer 2 (per R7) when the in-bin count is low. |

**Recommendation framing**: the third approach (always interpolate + signal) is the most honest and avoids hidden mode-switches. Aligns with R7's `tail_sample_count_warning` already specified. Threshold fall-through can be added later if signaling-only proves operationally noisy.

**D4-trigger**: none. The signaling approach has no measurement cost; threshold tuning if added is a Phase 2-time decision.

##### Decision 4 — Out-of-range tally handling

`#34` R5/R6 produces overflow counts at the low and high ends of the partition (values outside `[min, max]` when the partition was sized before those values were seen — possible under widening strategies for Path A). `#189` R4 must specify what to do with them.

| Approach | Behavior |
|---|---|
| Fold into edge bins | Treat low-overflow as if it landed at `boundary[0]`; high-overflow as if at `boundary[B]`. R4 inflates the edge-bin counts before its walk. |
| Separate populations | R4 reports out-of-range counts separately in `-V` and excludes them from quantile derivation. |

**Recommendation framing**: fold into edge bins is the SRE-honest default — out-of-range values *did* happen; treating them as edge-bin values preserves the percentile semantics. The "separate populations" approach is only useful if the partition is wrong (a Phase 2 implementation bug to detect, not a user-facing concern).

**D4-trigger**: none.

##### Decision 5 — Path A partition lifecycle when per-key `min`/`max` is discovered online

Heatmap and histogram finalize their partitions *after* the parse (`calculate_histogram_buckets` at `ltl:4908`), using global `min`/`max`. For Path A's per-`(category, log_key)` partitions, the partition must be sized from per-key `min`/`max` — which are tracked online (`ltl:5369-5371`) but only complete at end of parse.

| Approach | Behavior | Memory cost | CPU cost |
|---|---|---|---|
| (a) Two-pass | First pass discovers per-key `min`/`max`; second pass accumulates counters. | Same as existing per-key min/max — already tracked. | 2× parse cost. Heavy. |
| (b) Widen-and-rescale | First value seen for a key seeds a default-width partition; values outside trigger a partition rebuild (re-bin existing counts). | Slightly elevated transient memory during rebuild. | Amortized small if rebuilds are rare. |
| (c) Fixed global partition | All keys share one log-spaced partition over the global value range (e.g., 1ms – 1h). | Lowest. | Lowest. |
| (d) Defer until end-of-pass + cache durations | Same as today's `durations` array — defeats the feature. | Same as today. | Same as today. |

**Recommendation framing**: (c) is by far the simplest, and is what the existing heatmap/histogram code already does (one partition per metric, sized from global `min`/`max`). The trade-off is that Path A's per-key value ranges are subsets of the global range; for a key whose values all sit in a narrow sub-range, most of its bins will be empty (wasted memory) but the populated bins still produce accurate percentiles. Memory waste is bounded — B integers per key, ~640 B at `buckets_per_decade=16`. (b) is the next-simplest if (c) proves wasteful in practice. (a) is the fallback if neither suffices. (d) is rejected.

**D4-trigger**: if the decision conversation chooses between (b) and (c) based on suspected memory waste, prototype on a high-cardinality log (D2 identifies `HundredsOfThousandsOfUniqueErrors.log` as the stress case, but it lacks duration values — substitute the Tomcat access logs with the existing 286K-unique-key consolidation prototype as the value source). Bounded scope.

##### Decision 6 — R2.3 gating-criteria thresholds (when does approximate mode fire)

The dual-mode gate (R2) needs concrete thresholds. The criteria are:

- **Small-N opt-out per key.** Below some N, sorting the array is cheaper than building+walking counters. Where is the cross-over? At B=80 (`buckets_per_decade=16`), counter store ≈ raw array at N=80. Below N=80, exact mode is cheaper.
- **Index pre-seed (R2.1).** Inherited from #179 — fail if no index.
- **Tier match (R2.2).** Inherited from #179.
- **User override.** A CLI flag (e.g., `--exact-percentiles`) for users who want to force exact regardless of input scale.
- **Total memory headroom.** Optional — if available memory is tight, fall back to exact (which the existing code already manages incrementally).

**Recommendation framing**: ship Phase 2 with small-N opt-out (cross-over at N ≈ B), index pre-seed, tier match. Defer memory-headroom gating unless user feedback indicates need. CLI override is part of the decision (decision item 7 below).

**D4-trigger**: none. Cross-over is calculable from B and counter element size; the other gates are pre-existing.

#### D3 memo — additional decisions surfaced for the conversation

Beyond the six analytical decisions above, the decision conversation must resolve four practical questions before Phase 2 implementation begins:

7. **Whether to introduce a user-facing precision preference.** A `--exact-percentiles` flag (and possibly `--approximate-percentiles` as the opposite) for users who want to override the automatic gate. Default-on or default-auto.
8. **`-V` reporting verbosity.** Layer 2's `accuracy_estimate` block per quantile is specified in R7. The decision conversation confirms format details (numeric vs. symbolic bound, per-quantile vs. global).
9. **Phase 2 default activation policy.** R9 Phase 2 says "ships with default gating (no automatic activation without explicit user opt-in until validated)." The decision conversation confirms whether Phase 2 ships as opt-in only, or with auto-activation once D2-equivalent harness validates the accuracy bound.
10. **Whether any decision triggers D4.** From decisions 1, 2, 5 above. The conversation explicitly picks zero or more.

#### D3 memo — what D3 does *not* do

This memo is decision-support, not decision. It does not:

- Lock the in-bin interpolation strategy.
- Lock `buckets_per_decade` for Path A.
- Lock the gating thresholds.
- Commit to D4 work.

All of those are decided in the conversation that consumes this memo. The memo's job is to make that conversation possible without the participants having to re-derive D1's analysis.

### D4 — Prototype (conditional)

D4 is **conditional**. It is produced only if a D3 decision (Decision 1, 2, or 5 per the memo) cannot be resolved from D1's analysis alone and the decision conversation flags it as needing measurement. The scope of D4 is bounded by the specific decision being measured — it is not a flat "exercise the substrate" prototype.

When D4 is triggered, it produces a working prototype in `prototype/187-percentile-binderived.pl` (or similar) that:

- Implements the bin-counter primitive plus the in-bin interpolation strategies under question.
- Runs against the D2 cross-referenced log files relevant to the open decision.
- Produces measurement output (per-quantile error against exact-mode reference, state size, CPU cost) appropriate to the decision being resolved.
- Is runnable independently of ltl proper so the primitive can be exercised without touching production code.
- Mocks `#189` R1–R4 sufficiently to exercise the decision under question.

D4's output feeds back into D3, which is updated to reflect the resolved decision. The user-and-Claude decision conversation then proceeds against the updated D3.

If D3's analysis resolves all decisions from literature alone, D4 is not produced and Phase 1 concludes at D3.

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
