# Feature: Unified histogram bin-counter primitives for heatmap, histogram, and percentile consumers

## Overview

Histogram bin counters — the data structures and accumulation logic introduced by #34 — are the substrate for multiple ltl consumers: heatmap rendering, histogram rendering, and (progressively, per #187) per-message and per-time-bucket latency percentile calculation. Today the helper functions that compute bin partitions, assign values to bins, increment counters, and (for percentiles) interpolate quantiles are duplicated and inconsistent across the heatmap and histogram paths, and absent for percentiles.

This feature establishes a **unified set of histogram bin-counter primitives** that all current and future consumers share. The primitives are designed once, harmonized with the existing bin-count and bin-size determination logic (which is in place today and is not changing), and made available to:

- Heatmap rendering (per `(time_bucket, bin_index)`).
- Histogram rendering (per `(metric, bin_index)`).
- Summary-table per-message latency percentile calculation (per `(metric, bin_index)`, future consumer; today's array-based exact path migrates per #187's multi-phase rollout).
- Per-time-bucket duration percentile statistics (per `(time_bucket, bin_index)`, future consumer per #187 Phase 3).
- Highlight-subset percentiles (per `(time_bucket, bin_index, highlight_subset)` or analogous, future consumer per #187 Phase 4 / #51).

The primitives must support **independent partitions per consumer** (heatmap and histogram have different bucket counts and visual widths today — this is not changing) while sharing the underlying partition-computation, bin-assignment, counter-update, and percentile-interpolation logic.

## GitHub Issue

[#189](https://github.com/gregeva/logtimeline/issues/189)

## Motivation

Without harmonized primitives, the consumers will ship divergent implementations of the same conceptual operations. The cost compounds at every phase of the multi-phase percentile rollout (#187 R9). Each new consumer would either fork the partition/assignment/counter code from an existing consumer (accumulating drift) or reimplement it (accumulating bugs).

Designing the primitives once, with full knowledge of all current and future consumers, also forces an explicit decision about which dimensions of the counter keying are parameterizable versus fixed. That decision is hard to retrofit once consumers are shipped.

#34 lists the harmonization audit as a Phase 0 deliverable (R12). #187 lists the consumer-side primitive requirements as a Phase 0 deliverable (R12). This feature is the *receiving* end of both — the audit findings and consumer-side requirements land here as the binding primitive contract.

## Delivery sequence

This feature is one of three co-developed issues (#34, #187, #189). The work is performed in parallel against the `release/0.14.5` branch, with each issue's feature branches merging back periodically. The ordering below is the *delivery* sequence — when each step's output is required to be complete — not a strict serial work order.

| Step | Work | Owner | Why this position | Status of this file |
|---|---|---|---|---|
| 1 | **Audit** — catalogue existing helpers (heatmap, histogram, summary-table percentile paths); produce consumer-side primitive requirements | **#34 R12** + **#187 R12**; outputs land in **this file's** *Audit findings* and *Consumer-side requirements* sections | Both this feature's primitive design and #187's algorithm research need to know what shapes the primitives must support. Without this first, primitives risk being designed for two consumers and reworked later. | **This file is the receiving end of step 1; populates its own *Audit findings* and *Consumer-side requirements* sections from the audit outputs** |
| 2 | **Research + prototype** — algorithm comparative study, accuracy report, recommendation memo, prototype | **#187 D1–D5** | Algorithm choice (sketch vs. bin-derived interpolation) determines what this feature's percentile-interpolation primitive (R4) must do. Performed after audit but before this feature's implementation so it isn't built blind. | This file's R4 is informed by step 2's output |
| 3 | **Deliver #189** — implement unified primitives | **#189** | Now informed by both the audit (step 1) and the algorithm choice (step 2). | **This file's implementation step** |
| 4 | **Deliver #34 implementation** — heatmap and histogram consume this feature's primitives | **#34** | First production consumer of this feature. Simpler consumer (partition + assignment + counter only); verifies primitives work in production before more complex consumers build on top. | This feature's R10 (no regression) is verified at step 4 |
| 5 | **Deliver #187 Phase 2** — summary-table percentiles consume this feature's primitives | **#187 Phase 2** | Second consumer. First use of this feature's percentile-interpolation primitive (R4). | This feature's R4 is verified at step 5 |
| 6+ | **#187 Phases 3–5** — progressively land more consumers (per-time-bucket, highlight-data, future) | **#187 Phases 3–5** | Each phase verifies this feature's primitives don't need to change to accept the new consumer. | This feature's R6 (independence) and R8 (lifecycle) are verified incrementally at each later phase |

### Parallelism

Steps 1 and 2 may proceed in parallel once the audit has produced enough consumer-side requirements for the research to evaluate bin-derived interpolation against. Step 3 (this feature's implementation) cannot complete until step 2 lands the algorithm choice, but the partition / assignment / counter primitives (R1–R3) can be designed and implemented from the audit alone, in parallel with research. The percentile-interpolation primitive (R4) is gated on step 2 completing.

This means this feature's implementation is naturally two phases internally: the non-percentile primitives can ship first (unblocking step 4 for #34), and the percentile-interpolation primitive can land later (unblocking step 5 for #187 Phase 2).

### Integration

All work lands on feature branches merged into `release/0.14.5` periodically. The release branch is the integration point until the three co-developed issues are individually complete, at which point `release/0.14.5` ships per the standard release process (CLAUDE.md).

## Terminology

The data structures and helpers in this feature are uniformly named **histogram bin counters**, **bin partitions**, **bin assignment**, and **percentile interpolation**. The qualifier "histogram" denotes the kind of partition (logarithmic histogram-style bins) and distinguishes the substrate from other counter-style structures in ltl.

## Requirements

### R1 — Bin-partition primitive

A primitive that, given `(min, max, num_buckets)`, returns a stable bin-boundary array of length `num_buckets + 1`. The formula is the existing logarithmic `min * (max/min)^(i/num_buckets)` (unchanged from today; in place and not modified by this feature).

The primitive must:

- Accept arbitrary positive `num_buckets`. Heatmap and histogram pass their own (already-computed) bucket counts.
- Validate inputs and surface a recognized failure condition for degenerate cases (`min == max`, `min <= 0`).
- Return a partition object that downstream primitives consume; the object's shape (array, opaque handle, etc.) is implementation-defined provided the contract holds.
- Be pure: same inputs always produce the same partition.

### R2 — Bin-assignment primitive

A primitive that, given `(partition, value)`, returns either:

- A bin index in `[0, num_buckets - 1]` for in-range values.
- An out-of-range sentinel (low or high) for values outside `[min, max]`.

The primitive must:

- Produce the same bin index that today's post-hoc tally produces for the same partition (no off-by-one at boundary edges). This is the load-bearing correctness requirement that makes #34 R8 (render equivalence) achievable.
- Be efficient enough to invoke per-line in the parsing hot path. The exact algorithm (binary search, direct logarithmic computation, etc.) is implementation-defined.
- Be pure.

### R3 — Counter-update primitive (parameterized keying)

A primitive that, given `(counter_store, key, bin_index_or_overflow)`, increments the appropriate counter. The `key` shape is **parameterized per consumer**:

- Heatmap: `key = time_bucket`.
- Histogram: `key = ()` (no key beyond the implied metric).
- Per-message latency percentile (future, #187 Phase 2): `key = ()`.
- Per-time-bucket percentile (future, #187 Phase 3): `key = time_bucket`.
- Highlight-subset (future, #187 Phase 4 / #51): `key = (time_bucket, highlight_subset)` or analogous.

The primitive must:

- Not assume any specific key shape. Consumers define their key.
- Maintain separate counters for in-range bin indices and for low/high overflow per key.
- Allow the counter store for a key to be looked up, enumerated, and freed independently of other keys' stores (R8 lifecycle requirement).

The counter-store shape (hash of hashes, dense array, etc.) is implementation-defined. The contract is the operation, not the structure.

### R4 — Percentile-interpolation primitive

A primitive that, given `(partition, counter_map_for_a_single_key, target_quantile)`, returns an interpolated value for that quantile.

The primitive must:

- Accept any partition produced by R1 and any counter map produced by R3 invocations against the same partition.
- Return values that satisfy #187's accuracy bound (R4 in #187, locked by D3 in #187) for the partition shapes used by #187's consumers.
- Expose its accuracy guarantee in a form that #187's `-V` `accuracy_estimate` block can report. The form (theoretical bound, empirical bound, both) is decided in #187's D3.
- Handle degenerate inputs gracefully (zero counters → returns `-`; single non-zero counter → returns the bin's representative value; all counts in one bin → returns the bin's representative value).
- Be deterministic per R5.

This primitive is not consumed by #34 (heatmap and histogram render from raw counts, not percentile values). It is the load-bearing primitive for #187. Defining it here ensures #187 does not invent a parallel partition.

### R5 — Determinism

All primitives are deterministic. For randomized internal optimizations (if any), state is reproducibly seeded. The consumer's caller sees identical outputs for identical inputs across runs.

### R6 — Independence of partitions across consumers

The primitives are designed so that each consumer holds its own partition object (R1 return value). Two consumers sharing the same metric but different `num_buckets` (heatmap and histogram are exactly this case) hold two separate partitions. The primitives do not impose a single shared partition.

This is not a "future option"; it is a hard requirement. #34 R11 mandates that heatmap and histogram have independent partitions because their bucket counts and visual widths are independently configured. The primitives must accommodate that today.

### R7 — Compatibility with existing bin-count and bin-size determination

ltl today has working logic that determines the bucket count for heatmap (from `-hmw` and related) and for histogram (from `-hgw` and related), and that drives the visual representation. This feature must not change that logic. The primitive in R1 *consumes* a bucket count; it does not compute it.

When future consumers (per #187 Phases 2–5) need a bucket count, they either (a) consume an existing consumer's bucket count (e.g., Phase 3 per-time-bucket percentiles consume the heatmap bucket count by sharing the partition object) or (b) compute their own via consumer-specific logic outside this feature. This feature does not introduce a global default bucket count.

### R8 — Memory lifecycle

The primitives expose a lifecycle that allows:

- A partition object to persist across an entire run.
- Counter stores keyed by any value (per R3) to be freed when their key's processing completes — e.g., a heatmap counter store for `time_bucket=T` can be freed once that time bucket is rendered and no longer needed.
- The percentile-interpolation primitive (R4) does not retain state between invocations; it derives its result from inputs only.
- Composability with #23 Phase 2's named-stage memory model: counter stores can be freed at the `finalize` stage's per-bucket lifecycle point.

### R9 — `-V` observability surface

The primitives themselves do not produce `-V` output (consumers do). But the primitives expose enough state for consumers to populate their own `-V` sections accurately:

- Partition objects expose their `min`, `max`, `num_buckets`, and boundary array.
- Counter stores expose totals, per-key per-bin counts, and overflow counts.
- The percentile-interpolation primitive returns the interpolated value alongside an accuracy-estimate descriptor.

The exact API surface (method names, return shapes) is implementation-defined provided #34's `=== HISTOGRAM BIN COUNTER MODE ===` and #187's `=== PERCENTILE MODE ===` sections can be populated correctly.

### R10 — No regression in current consumers

When #34 and (future) #187 ship, the primitives must enable byte-identical output to today's implementation for the matching-bounds, exact-mode cases (#34 R14 and #187 R11). The primitives' correctness is verified through consumer-level regression rather than through standalone primitive tests alone — the contract is that consumers using the primitives produce the same output they would produce without them when configured to match today.

### R11 — Boundaries with other features

This feature does not own:

- The eligibility gate for histogram bin-counter mode (#34 R2) — owned by #34.
- The dual-mode percentile selection and accuracy contract (#187 R2 / R4) — owned by #187.
- The index read-back primitive that supplies pre-seeded bounds (#179) — closed; consumed indirectly via #34 / #187.
- Specific algorithm choice for percentile interpolation (#187 D3) — owned by #187 research.

This feature provides the *helpers and data structures*; #34 and #187 are the *consumers*.

## Consumer-side requirements (received from #34 R12 and #187 R12)

This section enumerates what each consumer needs the primitives to provide. It is the input to the implementation of this feature.

### From #34 (heatmap and histogram bin-counter mode)

- Partition computation parameterized by `(min, max, num_buckets)` per consumer.
- Bin assignment for per-line accumulation in the parsing hot path.
- Counter update keyed by `time_bucket` (heatmap) or by `()` (histogram).
- Out-of-range tallying per key (low and high).
- Counter store enumeration for rendering and for `-V` Layer 2/3 reporting.
- Lifecycle: partition persists for the run; counter stores per key are freeable.

### From #187 (dual-mode percentiles)

- All of the above (since approximate mode using bin-derived interpolation reads counters #34 already populates).
- Percentile interpolation per quantile, parameterized by the chosen accuracy contract.
- Accuracy-estimate descriptor returned alongside each interpolated value.
- Counter-store keying flexibility for Phase 2 (`()`), Phase 3 (`time_bucket`), Phase 4 (`(time_bucket, highlight_subset)` or analogous).

## Audit findings (from #34 R12 / #187 R12)

This section is the receiving end of the audits performed in #34 and #187. Initial scaffolding; populated during implementation.

### Existing helpers to be unified or replaced

Catalogue produced by the audit:

- Heatmap bin-partition computation site(s) — to be enumerated.
- Heatmap per-value bin-assignment site(s) — to be enumerated.
- Heatmap counter increment site(s) — to be enumerated.
- Histogram bin-partition computation site(s) — to be enumerated.
- Histogram per-value bin-assignment site(s) — to be enumerated.
- Histogram counter increment site(s) — to be enumerated.
- Summary-table latency percentile array allocation site(s) — to be enumerated (this is a non-histogram-bin-counter today; the audit captures it so the migration target is clear).
- Per-time-bucket duration percentile derivation site(s) — to be enumerated.

For each site, the audit records: what it does today, which primitive it maps to under this feature, and what code-level changes the consumer requires when adopting the primitive.

### Compatibility constraints discovered during audit

Constraints that the primitives must satisfy, identified by the audit:

- Heatmap and histogram have independent bucket counts (#34 R11).
- Heatmap counter store is keyed per time bucket; per-bucket counter freeing is in scope.
- Per-time-bucket percentile derivation (future) consumes the heatmap counter store via the same primitives, not via a parallel structure.

Additional constraints are added as the audit lands.

## Edge cases

| Case | Required behavior |
|---|---|
| Partition requested with `min == max` | R1 returns a recognized failure condition; consumer reports `missing_bound` per its own contract. |
| Partition requested with `min <= 0` | R1 returns a recognized failure condition (logarithmic boundaries undefined for non-positive `min`). |
| Bin assignment for a value exactly equal to a boundary | The primitive returns a consistent bin index for boundary-equal values; the choice (lower or upper bin) is documented and unchanged from today's tally. R10 (no regression) is the test. |
| Counter update for a key never seen before | R3 lazily initializes the counter store for that key. |
| Counter store free for a key while another key is still active | Independent per R8; freeing one does not affect another. |
| Percentile interpolation requested for a counter map with all zeros | R4 returns a defined "no values" indicator that the consumer maps to `-`. |
| Percentile interpolation requested for a counter map with a single non-zero bin | R4 returns the bin's representative value (e.g., geometric mean of bin boundaries); consumer behavior unaffected. |
| Concurrent partition creation for the same `(min, max, num_buckets)` | Determinism (R5) means the resulting partitions are identical; sharing is implementation-defined. |

## Acceptance criteria

- [ ] R1–R10 hold.
- [ ] Both #34 and #187 (Phase 2) consume the primitives without forking or duplicating.
- [ ] The audit (from #34 R12 / #187 R12) is complete and landed in **Audit findings** above.
- [ ] R7 holds: existing bin-count and bin-size determination logic is preserved unchanged.
- [ ] R10 holds: consumer-level regression produces byte-identical output for matching-bounds exact-mode cases.
- [ ] Each future consumer per #187 R9 Phases 2–5 can be added without primitive-level changes (verified incrementally as each phase lands).
- [ ] All test scenarios in **Validation** pass.

## Validation

### Primitive-level unit tests

Each primitive has unit tests covering:

- R1: partitions are correct for representative bound ranges; degenerate inputs are rejected with the documented failure condition.
- R2: bin assignments match today's post-hoc tally for representative inputs; boundary-equal values are assigned consistently; out-of-range sentinels are returned for under/over.
- R3: counter stores are correctly keyed; per-key independence is verified.
- R4: interpolated values match the chosen algorithm's expected output for canonical inputs (counter maps generated from known distributions); accuracy descriptors are returned.

### Consumer-level integration tests

The primitives are exercised through #34 and #187's test suites. Passing those suites is the primary verification that the primitives behave correctly in production-shaped usage. R10 (no regression) is verified at this layer.

### Cross-consumer composition tests

Tests that exercise multiple consumers sharing primitives in the same run (e.g., heatmap and histogram in #34, with #187 Phase 2 active over the same data) to verify that consumer independence (R6) and lifecycle independence (R8) hold under composition.

## Related issues

- **#34** — heatmap and histogram consumer (co-developed).
- **#187** — percentile consumer (co-developed; multi-phase consumer per R9 in #187).
- **#51** — future highlight-data consumer.
- **#41** — heatmap-histogram alignment (R6 confirms partition independence; #41 must be compatible).
- **#179** — index read-back (closed; indirectly supplies the bounds that R1 consumes).
- **#23 Phase 2 (#59)** — adopts this feature's memory lifecycle model.
- **#180** — named pipeline stages.
- **#46** — index file (closed).

## Spec stability

The primitive contract (R1–R11) is intended to be stable across the implementation cycle. The **Audit findings** and **Consumer-side requirements** sections grow as the audit completes and as future consumers (per #187 R9) land. New consumers may add new keying shapes to R3, but adding a keying shape is not a contract change — the parameterization in R3 is what enables them.
