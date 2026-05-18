# Feature: Bin-counter-based percentile calculation with dual-mode accuracy

## Overview

ltl's summary table reports per-message latency percentiles (P1, P5, P25, P50, P75, P90, P95, P99, P99.9). Today these are computed by retaining every individual metric value in an in-memory array, sorting it, and indexing. The algorithm requires `O(n)` memory in the number of values.

This feature introduces a dual-mode percentile path:

- **Exact mode** — today's array-based, exact percentile values. Unchanged.
- **Approximate mode** — quantile estimation via a sketch or bin-derived interpolation, with `O(state)` memory bounded by the chosen algorithm's parameters and not growing with input size.

Mode is decided at start of run by criteria modelled after #34's eligibility gate. The exact algorithm, the accuracy bound the algorithm must meet, and the precise gating criteria are research outcomes; this spec commits to the dual-mode foundation, the observability contract, and the research that must be completed before production implementation.

## GitHub Issue

[#187](https://github.com/gregeva/logtimeline/issues/187)

## Motivation

For multi-GB runs the per-message percentile arrays are typically the largest single memory consumer in the summary path — comparable in scale to the heatmap/histogram raw arrays that #34 addresses. With #179 reading bounds at start-up and #34 introducing the bin-counter accumulation pattern, the percentile arrays become the remaining target.

Unlike heatmap and histogram (where counts per bin are sufficient for rendering), percentile values require *estimating a position* in the value distribution. Multiple credible algorithms exist (t-digest, KLL sketch, Greenwald-Khanna, q-digest, bin-derived interpolation) with different accuracy / memory / CPU profiles. The right choice for ltl is not obvious from prior art alone — it depends on the value distributions actually observed in ltl's log datasets, which are heavy-tailed in ways that affect tail-quantile accuracy substantially. This feature therefore prioritizes research before locking in algorithm and accuracy.

## Requirements

### R1 — Two percentile-computation modes

The system supports two percentile-computation paths for the summary-table latency percentiles:

- **Exact mode** — the existing array-based computation, producing exact percentile values for the matched data. Behavior unchanged from today.
- **Approximate mode** — quantile estimation from a bounded-state estimator, producing the required percentile values within a documented accuracy bound (R4).

The selected mode is decided at run start.

### R2 — Mode-selection gate

The selection between exact and approximate mode must be governed by criteria evaluated at run start. The criteria must include at minimum:

1. Index pre-seed active (`index_used: yes` per #179).
2. Tier matches filter context (filtered → Tier-1 required; unfiltered → Tier-2 acceptable). Gaps are owed to #179 and recorded for follow-up there, not patched here.
3. Input criteria suitable for approximate mode. The specific input criteria (file size, selection line count, presence of bounds, etc.) are research outputs (R8/R9); the requirement is that at least one such input criterion is evaluated and reported.

When any criterion fails, exact mode runs.

### R3 — Required percentile values

Approximate mode must produce all of: P1, P5, P25, P50, P75, P90, P95, P99, P99.9.

### R4 — Documented accuracy bound

Approximate mode must operate within a documented accuracy bound. The bound is a research output (R9), expressed per quantile, and may differ across quantiles (P99.9 typically has wider bounds than P50). The bound must:

- Be derivable either from the chosen algorithm's theoretical guarantees, or from an empirical calibration against representative ltl datasets, or both.
- Be reported in `-V` (see R7).

The acceptance criterion is that for any input in the representative-dataset set (R8), every required quantile from approximate mode falls within the documented bound around the exact-mode value.

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

- **Layer 1**: `percentile_mode` (`exact` or `approximate`) and `percentile_mode_reason` (see R10).
- **Layer 2 (approximate mode)**: `algorithm` (the chosen estimator), `algorithm_version` where applicable, `state_budget_bytes`, and a per-quantile `accuracy_estimate` block reporting the bound applied to each required quantile.
- **Layer 3 (exact mode)**: `n` (the value count consumed) and a `sorted: yes` line for confirmation.

Section name and all labels are part of the feature contract.

### R8 — Representative-dataset set

The accuracy bound (R4) is verified against a curated set of datasets representative of ltl's actual usage. The set must include at minimum:

- A heavy-tailed access log (Tomcat / Apache style).
- A ThingWorx mixed-traffic log.
- A high-cardinality DEBUG-heavy log.
- A small-N case (a few hundred values).
- A degenerate case (all-same values).
- A pathological case relevant to ltl users (selection determined during research; e.g., a log with extreme outliers).

These datasets are referenced from `logs/` where existing files apply and curated into the test suite where new files are needed.

### R9 — Research outputs that bind production behavior

Before production implementation, the following research outputs must be produced and recorded (see **Research deliverables** below for the structure):

- **Algorithm choice** — which estimator(s) ltl ships.
- **Accuracy bound** — the per-quantile error bound that satisfies R4 for the R8 dataset set.
- **Input criteria for R2** — the specific input thresholds that govern when approximate mode activates.
- **State-budget configuration** — the parameter (e.g., t-digest compression, KLL `k`) the implementation uses.

Production implementation must report these outputs as fixed values in `-V` (R7) and must not deviate from them without re-running the relevant research.

### R10 — Reason codes

When exact mode runs, `-V` must report why. The vocabulary is at minimum:

- `approximate_eligible` — approximate mode active.
- `exact_default` — no eligibility (catch-all when no specific gate failed).
- `no_index` — R2.1 failed.
- `tier_mismatch` — R2.2 failed.
- `input_criteria_failed` — R2.3 failed (one or more input criteria below the threshold determined by R9).
- `feature_not_active` — no values were matched.

Additional reason codes may be added by implementation provided each maps to a single, testable cause.

### R11 — No regression in exact mode

When exact mode runs for any reason, percentile output is byte-identical to the pre-feature implementation. The existing regression suite must pass byte-identically.

### R12 — Heatmap and histogram unaffected

Heatmap and histogram bin counters (#34) are a separate data structure with separate eligibility. This feature must not alter their behavior. A run may have `percentile_mode: approximate` and `heatmap_mode: raw_value`, or any other combination, depending on each feature's independent gate.

### R13 — Boundaries with other features

- Heatmap and histogram bin counters — owned by #34.
- Highlight-data accumulation (including per-highlight percentile arrays if introduced) — owned by #51.
- Index read-back, tier correctness, and drift refresh — owned by #179.
- Within-run bound-discovery passes — not a topic of either this feature or #34.

When an eligibility gap traces to one of those features, it is filed against the owning issue, not patched here.

## Considerations for implementation

The spec is intentionally agnostic about the mechanisms below. Each must be addressed during prototype and implementation; the choice of mechanism is the implementer's, informed by research outcomes.

- **Algorithm choice as a research output (R9).** The candidate set named in **Research deliverables** is the prior art the implementer evaluates; the spec does not pre-select. The implementer may surface additional candidates if their literature review identifies more relevant work.
- **Detection methodology for mode selection.** R2 names the categories of criteria; the precise thresholds and how they are evaluated are determined in research and implementation. Consider: clarity of the decision, ordering for reason-code stability, cost of the checks relative to the run.
- **Memory behavior across modes.** The approximate-mode estimator state replaces the exact-mode value array. Consider how peak memory composes in mixed scenarios (e.g., approximate mode for the primary metric, exact mode for a highlight subset), and whether estimator state is freed at the same lifecycle point as the array is today.
- **`-V` accuracy unit.** R4 requires the bound to be reported per quantile. The unit (percentage-of-value error, absolute value error, percentile-rank distance) is decided in research and locked at R9-time. Consider which unit is most actionable for the user.
- **Surfacing of accuracy to the user.** The bound is in `-V` (R7). Whether the rendered summary table itself should annotate that approximate values are in use (e.g., a footnote, a marker on the percentile row) is implementation-defined. Consider the user's need to know vs. visual clutter.
- **Highlight subsets.** When a run uses a highlight pattern, percentiles are typically computed twice — once over all matched messages, once over highlighted. Whether both subsets can use approximate mode, whether they share estimator state, and how their accuracy bounds compose are decisions that must be reached during implementation, coordinated with #51 if highlight optimization is in flight at the same time.
- **Mode-selection criteria not yet identified.** R2 lists the minimum; additional criteria may be needed (e.g., behavior under memory pressure, behavior when bounds drift mid-run). If introduced, they must be reported under a new reason code (R10).
- **State lifecycle and reset.** When a run completes and percentile values are materialized, the estimator state is no longer needed. Consider when it is freed and whether the lifecycle composes cleanly with #23 Phase 2's named-stage memory model.

## Edge cases

| Case | Required behavior |
|---|---|
| No matched messages | Percentiles emit `-`; no estimator runs; `-V` reports `feature_not_active`. |
| All matched values are identical | Every percentile equals that value (exact and approximate modes agree). |
| Single matched value | Every percentile equals that value. |
| Very small N below R9's threshold | Gate (R2.3) steers to exact mode; `reason: input_criteria_failed`. |
| Stale or missing index | R2.1 fails; exact mode runs; `reason: no_index`. |
| Filtered run with only Tier-2 pre-seed | R2.2 fails; exact mode runs; `reason: tier_mismatch`; gap recorded against #179. |
| Highlight pattern present | Both subsets evaluated by R2 independently; each may be in exact or approximate mode; `-V` reports both. |
| Bounds drift mid-run | Exact-mode output unchanged. Approximate-mode behavior under drift is determined by R9; the accuracy bound (R4) must still hold or the gate must have excluded the run. |
| Concurrent ltl processes | Inherited from #179; out of this feature's concern. |

## Acceptance criteria

- [ ] R1–R13 hold across the representative-dataset set (R8).
- [ ] Research deliverables are complete: algorithm choice, accuracy bound, input criteria, state-budget configuration are recorded and referenced from this spec (R9).
- [ ] For every input in the R8 set, each required quantile from approximate mode falls within the R9 accuracy bound around the exact value.
- [ ] When approximate mode runs, R3, R4, R5, R6, and R7 hold; `state_budget_bytes` reported in `-V` matches the actual memory occupied by the estimator state.
- [ ] When exact mode runs for any reason (R10), output satisfies R11 (byte-identical to pre-feature).
- [ ] `-V` emits the section described in R7, with reason codes per R10 distinguishing every failure mode of R2.
- [ ] Heatmap and histogram behavior is unchanged (R12).
- [ ] All test scenarios in **Validation** pass.
- [ ] Any eligibility gap traced to #179 is filed against #179 (R13).

## Validation

Three layers, modelled after #34 and #179.

### Existing regression suite

`tests/validate-regression.sh` must pass byte-identically. Validates R11.

### New scenario suite

Mirrors #34's pattern: orchestrate `ltl-index.csv` state, run ltl with `-V`, assert against the `=== PERCENTILE MODE ===` section.

| Scenario | Setup | Action | Assertions |
|---|---|---|---|
| `cold-no-index-exact` | No `ltl-index.csv`. | `ltl <F> -V`. | `percentile_mode: exact`, `reason: no_index`. |
| `warm-eligible-approximate` | Fresh index pre-seed; input meets all R9 criteria. | `ltl <F> -V`. | `percentile_mode: approximate`, `reason: approximate_eligible`, `algorithm` populated, `accuracy_estimate` per quantile populated. |
| `warm-input-criteria-failed` | Fresh index pre-seed; input below the R9 threshold. | `ltl <F> -V`. | `percentile_mode: exact`, `reason: input_criteria_failed`. |
| `warm-tier-mismatch` | Filtered run, only Tier-2 pre-seed. | `ltl -dmin=50 <F> -V`. | `percentile_mode: exact`, `reason: tier_mismatch`. |
| `approximate-zero-values` | Eligible run; all messages filtered out. | `ltl -i nonexistent <F> -V`. | Percentiles emit `-`; `reason: feature_not_active`; no crash. |
| `approximate-all-same` | Eligible run; all matched values identical. | Crafted log file. | All percentiles equal that value. |
| `approximate-single-value` | Eligible run; single matched value. | Crafted log file. | All percentiles equal that value. |
| `accuracy-within-bound` | Eligible run; representative dataset. | Run twice — once forcing exact via gate-failure, once approximate. | Per-quantile absolute and relative errors fall within R9's bound. |
| `state-budget-reported` | Eligible run. | `ltl <F> -V`. | `state_budget_bytes` non-zero; matches the estimator's configured parameter (R9). |

### Accuracy-comparison test harness

A dedicated harness compares approximate-mode output against exact-mode output across the R8 dataset set. For each dataset:

1. Run ltl twice (once forced exact, once approximate).
2. Compute per-quantile absolute and relative error.
3. Assert each error within R9's bound.

The harness is part of this feature's deliverable.

## Research deliverables

Production implementation does not commence until the following deliverables are complete and recorded. The deliverables are requirements on the *work*, not prescriptions of the *mechanism*.

### D1 — Comparative algorithm study

Evaluate the following candidate algorithms against the R8 dataset set:

- **t-digest** — Dunning's structure; recognized for tail-quantile accuracy in heavy-tailed data.
- **KLL sketch** — deterministic-error succinct quantile sketch.
- **Greenwald-Khanna (GK)** — classic deterministic quantile sketch.
- **q-digest** — tree-based deterministic quantile sketch.
- **Bin-derived interpolation** — compute percentiles by interpolating within the bins produced by #34's bin-counter mode (reuses heatmap/histogram bins; no separate estimator state).

For each algorithm and each dataset:

- Per-quantile absolute error (raw-value units).
- Per-quantile relative error (percent of exact value).
- 95% confidence intervals over multiple sub-samples.
- Estimator state size.
- Per-update CPU cost.
- Per-finalize CPU cost.
- Determinism characteristic.

The implementer may add candidates if literature review surfaces relevant alternatives.

### D2 — Accuracy report

A written report summarizing D1 results across the R8 dataset set:

- Table of per-algorithm, per-quantile, per-dataset error metrics.
- Memory and CPU comparison.
- Qualitative discussion of which algorithm performs best for which dataset shape.
- Identification of any algorithm that is strictly dominated.

### D3 — Recommendation memo

A written recommendation:

- The algorithm (or algorithms, if multiple) ltl ships.
- The accuracy bound (R4) the implementation commits to.
- The input criteria for R2 (the thresholds that gate approximate-mode activation).
- The state-budget configuration (R9).
- Rationale connecting the recommendation to D2.

### D4 — Prototype

A working prototype in `prototype/187-percentile-sketch.pl` (or similar). The prototype:

- Implements the recommended algorithm(s).
- Runs against the R8 datasets and produces D2-style output reproducibly.
- Is runnable independently of ltl proper so algorithm changes can be validated without touching production code.

### D5 — Production gate

Production implementation references D1–D4 as prerequisites and treats their outputs as the binding values for R4, R9, and the R7 `accuracy_estimate` block.

## Related issues

- **#34** — bin-counter accumulation for heatmap and histogram (sibling; same gating pattern).
- **#179** — index read-back (R2.1 / R2.2 dependency).
- **#51** — highlight-data optimization (R13).
- **#41** — unified binning (D1 evaluates bin-derived interpolation, which composes with #41 if recommended).
- **#23 Phase 2 (#59)** — adopts this feature's memory model.
- **#180** — named pipeline stages.
- **#46** — index file (closed; foundation that #179 reads back).

## Spec stability

The behavior contract (R1–R13, edge cases, `-V` format) is intended to be stable across implementation. The research deliverables (D1–D5) are expected to grow as research lands; their outputs become the bound values for R4, R9, and the `accuracy_estimate` block. When that happens, a **Locked decisions from research** subsection records the values.
