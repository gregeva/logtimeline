# Feature: Bin-counter accumulation for heatmap and histogram

## Overview

Heatmap and histogram today retain every per-line metric value in memory (`%heatmap_raw{$time_bucket}` and `%histogram_values{$metric}`) so that bin boundaries can be computed from the observed min/max **after** the file is fully read. This feature introduces an alternative accumulation path in which per-bin integer counters replace those per-line value structures when the bin boundaries can be known **before** the read pass begins.

The condition that makes that possible is index read-back (#179): when a prior run's bounds are pre-seeded into in-memory state at start-up, ltl can compute logarithmic bin boundaries up front and tally each parsed value directly into a bin counter. No per-line values are retained.

The feature is therefore a conditional gate: bin-counter mode activates per-feature (heatmap independently of histogram) when pre-seeded bounds are available for the metric in question; otherwise the current raw-value implementation runs unchanged.

## GitHub Issue

[#34](https://github.com/gregeva/logtimeline/issues/34)

## Motivation

For multi-GB log analysis runs (chained daily files, long-window investigations), the raw-value arrays dominate peak memory. The bounds those arrays exist to discover are stable properties of the file (or filter selection) — once captured by the index, they do not need to be re-discovered on subsequent runs. With #179 reading them back at start-up, the raw-value retention has no remaining purpose for those runs.

## Requirements

### R1 — Two accumulation modes per metric

For each metric tracked by heatmap and histogram (duration, bytes, count, and any user-defined metric), the system supports two accumulation paths:

- **Raw-value mode** — today's behavior, unchanged. Per-line values accumulate; bin boundaries are derived at end of pass; rendering uses the resulting bins.
- **Bin-counter mode** — bin boundaries are computed at start of run from pre-seeded bounds; per-line values increment a bin counter directly during the read pass; no per-line value array is allocated.

The selected mode is decided independently per feature (heatmap, histogram) and per metric.

### R2 — Mode-selection gate

A given (feature, metric) pair is eligible for bin-counter mode iff all of the following hold:

1. Index pre-seed is active for this run (`index_used: yes` per #179).
2. The pre-seed tier matches filter context: filtered runs require Tier-1 (`selection`) pre-seed; unfiltered runs accept Tier-2 (`file`) pre-seed or Tier-1 with `filters = -`. Tier correctness is owed by #179. If a filtered run reaches this gate with only Tier-2 pre-seed, the metric is treated as ineligible (`reason: tier_mismatch`) and the gap is recorded for follow-up against #179 rather than patched at this layer.
3. Both `min` and `max` pre-seed values are present (non-placeholder) for the metric.

When any criterion fails, raw-value mode runs for that metric.

### R3 — Bin boundary computation in bin-counter mode

When eligible, the boundary array is computed once at start of run using the existing logarithmic formula `min * (max/min)^(i/num_buckets)` for `i in 0..num_buckets`, with the same `num_buckets` value used today. The formula, bucket count, and resulting bin semantics are identical to today's post-hoc computation; only the timing of computation moves earlier.

### R4 — Per-line accumulation in bin-counter mode

During the existing single read pass, each parsed value for an eligible metric is assigned to a bin index against the pre-computed boundary array and the corresponding counter is incremented. No per-line value array is allocated or appended for that metric.

### R5 — Out-of-range handling

Values falling outside the pre-seeded bounds are tallied into out-of-range counters:

- Values below the pre-seeded `min` increment `out_of_range_low` (per metric for histogram; per metric per time bucket for heatmap).
- Values above the pre-seeded `max` increment `out_of_range_high` analogously.

Out-of-range tallies must:

- Be reported in `-V` (see R8).
- Propagate to #179's drift detection so the index entry is refreshed at end of run.
- Not retroactively widen the in-memory boundary array during the current run. The rendered axis for the current run remains the pre-seeded one.

### R6 — Live bound capture continues in bin-counter mode

The live `min` / `max` capture that #179 relies on for drift detection must continue running alongside bin-counter accumulation. Only the per-line value array allocation is eliminated.

### R7 — Render equivalence

When pre-seeded bounds match observed live values exactly, rendered heatmap and histogram output in bin-counter mode is identical to raw-value mode for the same input.

When raw-value mode runs (any ineligible scenario), rendered output is byte-identical to today's pre-feature implementation.

### R8 — `-V` observability of mode selection and out-of-range activity

A dedicated section in `-V` output, named `=== HISTOGRAM BIN COUNTER MODE ===`, reports:

- **Layer 1 — Run-level summary**: `heatmap_mode` and `histogram_mode`, each taking values `bin_counter`, `raw_value`, or `not_active` (when the feature itself was not requested).
- **Layer 2 — Per-feature, per-metric detail**: for each active feature, one block per metric reporting `mode`, `reason` (see R9), `boundary_min`, `boundary_max`, `num_buckets`.
- **Layer 3 — Out-of-range report**: emitted whenever any metric is in `bin_counter` mode. Reports `out_of_range_low` and `out_of_range_high` per metric (totals). For heatmap, additionally reports per-time-bucket breakdown for any time bucket where out-of-range counts are non-zero.
- **Layer 4 — Drift cross-reference**: a single line pointing to #179's drift section, since drift detail is owned there.

The section name and all labels are part of the feature contract and stable across implementations.

### R9 — Reason codes

When a metric runs in raw-value mode under the bin-counter feature, `-V` must report why. The reason values reported must be sufficient for an external test to distinguish each failure of R2. The vocabulary is at minimum:

- `index_pre_seed_ok` — bin-counter mode active.
- `no_index` — R2.1 failed.
- `tier_mismatch` — R2.2 failed.
- `missing_bound` — R2.3 failed (including degenerate `min == max` and non-positive values that make logarithmic boundaries undefined).
- `feature_not_active` — feature itself was not requested.

Additional reason codes may be added by implementation provided each maps to a single, testable cause.

### R10 — Per-feature and per-metric independence

The eligibility decision must be made per (feature, metric) pair. A run may have heatmap in bin-counter mode and histogram in raw-value mode, or have one histogram metric in bin-counter mode and another in raw-value mode, depending on which bounds were pre-seeded.

### R11 — Memory behavior under bin-counter mode

When R2 is satisfied for a metric, that metric's per-line memory footprint must not grow with line count:

- Heatmap per-metric memory must be bounded by `num_buckets × num_time_buckets`.
- Histogram per-metric memory must be bounded by `num_buckets`.

Constant per-bucket per-time-bucket overhead is acceptable; growth proportional to input size is not.

### R12 — No regression in raw-value mode

When any metric runs in raw-value mode for any reason, behavior is byte-identical to the pre-feature implementation. The existing regression suite (`tests/validate-regression.sh`) must pass byte-identically.

### R13 — Per-message percentile arrays unaffected

The per-message latency percentile arrays used by the summary table (P1..P99.9) are a separate data structure from `%heatmap_raw` and `%histogram_values`. This feature must not alter their behavior in either direction. The dual-mode percentile path is owned by sibling issue #187.

### R14 — Boundaries with other features (this feature does not own)

- Highlight-data optimization (`%heatmap_raw_hl` and equivalents) — owned by #51.
- Per-message latency percentile dual-mode — owned by #187.
- Shared boundary-array unification between heatmap and histogram — owned by #41.
- Index read-back, tier correctness, and drift refresh — owned by #179.

When an eligibility gap traces to one of those features, it is recorded and filed against the owning issue rather than patched here.

## Considerations for implementation

The spec is intentionally agnostic about the mechanisms below. Each must be addressed during prototype and implementation; the choice of mechanism is the implementer's, informed by what the gate actually needs in practice.

- **Detection methodology for ineligible runs.** R2 lists the eligibility criteria. How those criteria are checked at run start, how reason codes are derived, and how `-V` instrumentation is produced are implementation-defined. Consider: clarity of the gate (so future readers can audit the decision), order of checks (so reason reporting is unambiguous), and cost of the checks (should be negligible relative to the read pass).
- **Memory behavior across mixed-mode runs.** A run may have some metrics in bin-counter mode and others in raw-value mode (R10). The implementer should consider how peak memory composes in mixed cases, whether any structures are shared across metrics, and whether allocating one structure freezes the other into a less efficient layout.
- **Out-of-range rendering.** R5 requires out-of-range tallies to be reported in `-V`. Whether and how out-of-range counts surface on the rendered heatmap or histogram itself (a labeled marker at the axis edge, an inline annotation, or silent) is implementation-defined. Consider: visibility for the user, conformance with the existing visual style, and behavior when the count is non-zero but small.
- **Mode-selection criteria beyond the gate.** R2 defines the minimum eligibility criteria. Additional criteria — for example, whether very small selections benefit from bin-counter mode, or whether memory pressure on the host should influence the decision — may be needed in practice. If introduced, they must be reported in `-V` with a new reason code (R9). Whether to expose any of them to the user via a CLI surface is an implementation decision and is not constrained by this spec.
- **Boundary computation precision.** R3 mandates the existing logarithmic formula. Implementation must verify that bin assignment from pre-seeded boundaries produces identical bin indices to today's post-hoc computation, with no off-by-one at boundary edges, across all supported metrics.
- **Heatmap-vs-histogram structural symmetry.** Both features apply the same accumulation pattern over different keying (time-bucketed vs. global). Implementation should consider whether a shared helper is warranted now or whether shared structure is deferred to #41.
- **Live bound capture cost.** R6 requires live `min` / `max` capture to continue running in bin-counter mode. The cost is small but non-zero; implementation should confirm that retaining it does not erase the memory benefit of bin-counter mode in any realistic scenario.

## Edge cases

| Case | Required behavior |
|---|---|
| Feature not requested (`-hm` absent, `-hg` absent) | `-V` reports the relevant `*_mode: not_active`. No per-metric blocks emitted. |
| Pre-seeded `min == max` for a metric | Metric is ineligible (`reason: missing_bound`); raw-value mode runs and handles the degenerate case as today. |
| Pre-seeded `min` is zero or negative for a duration/bytes metric | Logarithmic boundaries undefined. Metric ineligible (`reason: missing_bound`). |
| Pre-seeded bounds match live exactly | No out-of-range counts, no drift, render identical to raw-value mode. |
| Pre-seeded bounds wider than live | Bins at extremes empty; legitimate; render uses the wider axis. |
| Pre-seeded bounds narrower than live | Out-of-range counts accumulate; render uses the pre-seeded axis; #179 refreshes the index; next run observes no out-of-range counts. |
| Heatmap eligible, histogram missing a bound | Heatmap in bin-counter mode; histogram in raw-value mode for the missing-bound metric. `-V` reflects both independently. |
| One histogram metric eligible, another not | Eligible metric uses bin counters; ineligible metric uses raw-value. Both render identically to today. |
| Multi-file run, mixed pre-seed (one file fresh, one not) | #179's multi-file rule already blocks pre-seed; this feature observes `no_index` and runs raw-value mode for both features. |
| Multi-file run, all fresh, same tier | Per-file bounds aggregated per #179 (min-of-mins, max-of-maxes); boundary array uses aggregated values. |
| Filter signature never seen before | No Tier-1 match; filtered run is ineligible (`reason: tier_mismatch`); next run with same filters will be eligible. |
| `-hm count` requested, pre-seed has only `duration` bounds | Heatmap active metric is `count`; ineligible (`reason: missing_bound`). |
| Stale or malformed `ltl-index.csv` | #179 produces no pre-seed; this feature observes `no_index`; raw-value mode. |
| Concurrent ltl processes | Inherited from #179; out of this feature's concern. |

## Acceptance criteria

- [ ] R1–R13 hold for all supported (feature, metric) combinations.
- [ ] When R2 is satisfied for a metric, that metric's memory growth respects R11.
- [ ] When R2 fails for any reason, behavior satisfies R12.
- [ ] `-V` emits the section described in R8, with reason codes per R9, sufficient to distinguish every failure mode of R2.
- [ ] Out-of-range counts (R5) propagate to #179's drift refresh; after refresh, the next run with the same input observes zero out-of-range counts.
- [ ] All test scenarios in **Validation** pass.
- [ ] `tests/validate-regression.sh` passes byte-identically against the pre-feature baseline.
- [ ] Any eligibility gap traced to #179 is filed against #179, not patched here (R14).

## Validation

Three layers, modelled after #179.

### Existing regression suite

`tests/validate-regression.sh` — all existing tests must pass byte-identically. Validates R12 and confirms that bin-counter mode does not alter rendered output when bounds are matched.

### New scenario suite

A new test runner orchestrates `ltl-index.csv` state directly (mirroring #179's pattern), runs ltl with `-V`, and asserts against the `=== HISTOGRAM BIN COUNTER MODE ===` section.

`<F>` denotes a test input file with known content. `<F1>`, `<F2>` denote two distinct files with known distinct values.

| Scenario | Setup | Action | Assertions |
|---|---|---|---|
| `cold-no-index-heatmap` | No `ltl-index.csv`. | `ltl -hm duration <F> -V`. | `heatmap_mode: raw_value`, `reason: no_index`. Render byte-identical to pre-feature. |
| `cold-no-index-histogram` | No `ltl-index.csv`. | `ltl -hg <F> -V`. | `histogram_mode: raw_value`, `reason: no_index` for each metric. |
| `warm-unfiltered-heatmap-eligible` | Fresh file row, bounds populated. | `ltl -hm duration <F> -V`. | `heatmap_mode: bin_counter`, `reason: index_pre_seed_ok`, `boundary_min` / `boundary_max` match the row. Render identical to `cold-no-index-heatmap`. |
| `warm-unfiltered-histogram-eligible` | Same file row, all metric bounds populated. | `ltl -hg <F> -V`. | `histogram_mode: bin_counter` for each metric. Render identical to cold. |
| `warm-filtered-tier1-eligible` | Fresh selection row for `(<F>, -dmin=50;)` with bounds covering live filtered range. | `ltl -hm duration -dmin=50 <F> -V`. | `heatmap_mode: bin_counter`, `reason: index_pre_seed_ok`. Pre-seed values match the selection row. |
| `warm-filtered-tier2-fallback` | Fresh file row only; no matching selection row. | `ltl -hm duration -dmin=50 <F> -V`. | `heatmap_mode: raw_value`, `reason: tier_mismatch`. Render byte-identical to pre-feature. |
| `missing-bound-column-heatmap` | File row with `duration_max=-`. | `ltl -hm duration <F> -V`. | `heatmap_mode: raw_value`, `reason: missing_bound`. |
| `missing-bound-column-histogram-partial` | File row, `duration` bounds populated, `bytes_max=-`. | `ltl -hg <F> -V`. | `metric: duration` → `bin_counter`; `metric: bytes` → `raw_value`, `reason: missing_bound`. |
| `out-of-range-low` | File row with `duration_min=100` (live values 10–500). | `ltl -hm duration <F> -V`. | `bin_counter`, `out_of_range_low > 0`, `out_of_range_high: 0`. Per-time-bucket breakdown present. #179's `drift_detected: yes` for `duration_min`. After re-run with refreshed index: `out_of_range_low: 0`. |
| `out-of-range-high` | File row with `duration_max=200` (live values up to 500). | `ltl -hm duration <F> -V`. | Symmetric: `out_of_range_high > 0`, `out_of_range_low: 0`. |
| `mixed-feature-eligibility` | File row, `duration` bounds populated, `bytes` bounds as `-`. | `ltl -hm duration -hg <F> -V`. | `heatmap_mode: bin_counter`. `histogram` block: `duration` → `bin_counter`, `bytes` → `raw_value` with `missing_bound`. |
| `multi-file-all-eligible` | Fresh file rows for `<F1>` and `<F2>`. | `ltl -hm duration <F1> <F2> -V`. | `heatmap_mode: bin_counter`. Pre-seed uses aggregated bounds. |
| `multi-file-mixed-eligibility` | `<F1>` fresh, `<F2>` stale mtime. | `ltl -hm duration <F1> <F2> -V`. | `heatmap_mode: raw_value`, `reason: no_index` (inherited from #179's multi-file blocking rule). |
| `boundary-exact-match` | File row with `min` / `max` matching live exactly. | `ltl -hm duration <F> -V`. | `bin_counter`, no out-of-range, no drift. Render byte-identical to a raw-value re-run. |
| `wider-than-live-bounds` | File row with bounds wider than live. | `ltl -hm duration <F> -V`. | `bin_counter`, no out-of-range. Render uses the wider axis. |
| `feature-not-active` | Fresh file row; no `-hm`, no `-hg`. | `ltl <F> -V`. | `heatmap_mode: not_active`, `histogram_mode: not_active`. No per-metric blocks. |
| `degenerate-min-equals-max` | File row with `duration_min = duration_max`. | `ltl -hm duration <F> -V`. | `raw_value`, `reason: missing_bound`. |

#### Assertion mechanics

Tests parse the `=== HISTOGRAM BIN COUNTER MODE ===` section from `-V` output and assert keys against expected values. They do not assert against rendered output (that is the existing regression suite's job); they assert against the bin-counter section and, for out-of-range scenarios, against #179's drift block.

### `-V` instrumentation as the validation surface

The labels and structure defined in R8 and R9 are the test contract. Without that level of detail in `-V`, scenarios like `mixed-feature-eligibility` and `out-of-range-low` (which must assert *which* metric was affected and *why*) are not assertable from rendered output alone.

## Related issues

- **#179** — index read-back (provides pre-seed primitive that R2 depends on).
- **#51** — highlight-data accumulation (R14).
- **#187** — bin-counter-based percentile calculation (sibling; R13).
- **#41** — unified binning for heatmap and histogram (R14).
- **#23 Phase 2 (#59)** — core engine rewrite; the memory model defined by R10–R11 is intended to be inherited unchanged.
- **#180** — named pipeline stages.
- **#46** — index file (closed; foundation that #179 reads back).

## Spec stability

This document is intended to be stable across the implementation cycle. Two categories of post-merge change are expected:

1. Clarifications when an unspecified case is encountered during implementation (move from "unspecified" to "specified" in **Edge cases**).
2. Updates when sibling features (#51, #187, #41) land — at that point this doc may add a brief subsection per consumer recording what each reads from or composes with this feature's mode contract.

The spec does not track implementation status, code locations, or commit history. Those live in commit messages and the issue itself.
