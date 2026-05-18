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

This section enumerates what each consumer needs the primitives to provide. It is the binding input to the implementation of this feature. The catalogue of `ltl` call sites that ground these requirements lives in **Audit findings** below.

### From #34 (heatmap and histogram bin-counter mode)

Heatmap and histogram are #189's first two production consumers. They consume R1 (partition), R2 (bin-assignment), R3 (counter-update) — but **not** R4 (percentile interpolation) directly. Empirical percentile derivation in both today (`%heatmap_percentiles` markers; `histogram_stats{p*}` values) is internal to those features and may continue to use raw-array sorting in raw-value mode; under histogram bin-counter mode the raw arrays are not allocated, so those derivations are either reformulated against R4 (heatmap percentile-marker open question — see **Audit findings** § "Open question — heatmap percentile markers under bin-counter mode") or dropped.

| # | Need | Concrete shape |
|---|---|---|
| 1 | Partition computation parameterized by `(min, max, num_buckets)` per consumer | Heatmap: one partition per run (single metric per run; `num_buckets = $heatmap_width`, default 52, `-hmw`-tunable). Histogram: one partition per metric (`num_buckets` from `calculate_histogram_bucket_count` driven by `-hgbpd`/`-hgb`). Partition computed at **start of pass** when histogram bin-counter mode is eligible, from pre-seeded bounds (#34 R3). |
| 2 | Bin assignment for per-line accumulation in the parsing hot path | Called inside the existing per-line loop in `read_and_process_logs`, **once per active metric per line**. Must be efficient enough that the per-line cost is no worse than today's `push` onto `%heatmap_raw` / `%histogram_values`. Today's two implementations (linear search `find_heatmap_bucket` at `ltl:4783`; binary search `find_histogram_bucket_index` at `ltl:4890`) confirm either algorithmic strategy is acceptable; #189 picks one. |
| 3 | Counter update with two distinct key shapes | Heatmap: `key = time_bucket`. Histogram: `key = ()` (no key beyond the implicit metric scope). Both must coexist in the same run because R10 makes them co-eligible. |
| 4 | Out-of-range tally per key, low and high | New behavior. Today's `find_heatmap_bucket` (`ltl:4783`) silently clamps to last in-range bin; `find_histogram_bucket_index` (`ltl:4890`) similarly returns an in-range index. #189 R2 introduces explicit sentinels; this is **not a refactor of existing logic** — it is new contract surface that #34 R5 / R6 (out-of-range counters + single end-of-run warning) and #179's drift detection both depend on. |
| 5 | Counter-store enumeration | For each consumer's rendering driver (heatmap: `print_heatmap_row` `ltl:6378`, `get_heatmap_column_header` `ltl:6265`, `print_heatmap_footer_scale` `ltl:6434`; histogram: `print_histograms` `ltl:6890` and its helpers `ltl:7071–7559`) and for the `-V` Layer 2 / 3 reporting (#34 R9). Must support iteration over `(key, bin_index, count)` triples plus the per-key overflow tallies. |
| 6 | Lifecycle | Partition persists for the run. Counter stores per key (heatmap: per time bucket; histogram: single store per metric) are independently freeable once rendering for that key completes — required for #187 Phase 3's per-time-bucket percentile counters, harmless for #34's own consumers. |

### From #187 (dual-mode percentiles)

#187 is the load-bearing consumer of R4 (percentile interpolation). It progressively migrates four percentile-computing paths catalogued in #187's `## Percentile-path harmonization audit`. Each phase adds a consumer to the primitive without changing the primitive contract — that is the test of whether R3's keying parameterization and R4's accuracy contract are sufficient.

| # | Need | Concrete shape |
|---|---|---|
| 1 | All of #34's needs (1–6 above) | Approximate mode reads counters #34 has already populated (#187 R8 / R13). The shared substrate means #187 cannot ship without #34's primitives in place — though R4 itself ships only after #187's algorithm choice (D3) lands. |
| 2 | Percentile interpolation per quantile, parameterized by the chosen accuracy contract | Algorithm and accuracy bound are chosen in #187 D1–D3 (algorithm research deliverable). This audit identifies the consumer call sites but does **not** specify the algorithm. Each call site below identifies a `(partition, counter_map, target_quantile) → value` invocation. |
| 3 | Accuracy-estimate descriptor returned alongside each interpolated value | Form (theoretical bound, empirical bound, or both) decided in #187 D3 and surfaced in #187's `-V` `accuracy_estimate` block (#187 R7). |
| 4 | Counter-store keying flexibility for all phases | Phase 2 (summary-table per-message latency, `ltl:5374–5379` consumer): `key = ()`. Phase 3 (per-time-bucket duration percentiles, `ltl:5220–5273` consumer): `key = time_bucket`. Phase 4 (highlight-subset percentiles, future / #51): `key = (time_bucket, highlight_subset)` or analogous compound. R3's parameterization must accept all three shapes without primitive-level change. |
| 5 | Migration target identification | Phase 2 target: `log_messages{$category}{$log_key}{durations}` raw array (allocated `ltl:4591`). Phase 3 target: `log_analysis{$bucket}{durations}` raw array (allocated `ltl:4634`, guarded `unless $heatmap_enabled`). Phase 4 target: highlight subset raw collections (today partially shaped by `histogram_values_hl`, `heatmap_raw_hl`; final shape determined when Phase 4 lands). Note that the Phase 3 raw array is **not allocated when heatmap is active** — heatmap takes ownership of duration values for its own raw-value mode — which is a pre-existing entanglement R8 ("Coupling to histogram bin counters" in #187) already anticipates. |
| 6 | Histogram-mode global percentile reformulation (incidental Phase 2 consumer) | `calculate_histogram_buckets` (`ltl:4908`) today derives `histogram_stats{p*}` from raw arrays (`ltl:4926–4940`, `ltl:4995–5004` for highlight) in addition to populating bin counters. Once R4 lands, these percentile values may be derived from the bin counters directly — eliminating the raw-value sort at this site too. This is a side benefit of R4, not a separate phase; it lands whenever it is convenient inside the Phase 2 migration. |

## Audit findings (from #34 R12 / #187 R12)

This section is the receiving end of the audits performed in `features/34-histogram-bin-counter-mode.md` § Harmonization audit and `features/187-histogram-bin-counter-percentiles.md` § Percentile-path harmonization audit. The catalogue below is the single source of truth; the sibling feature files cross-reference here.

All `ltl:line` references are against `release/0.14.5` HEAD at the time the audit landed. Subsequent refactors may shift line numbers; the subroutine names and global-variable identifiers are the stable anchors.

### Existing helpers to be unified or replaced

#### Heatmap consumer

| Site | `ltl` location | What it does | Primitive | Reads / writes | Key shape |
|---|---|---|---|---|---|
| `find_heatmap_bucket` | `ltl:4783–4789` | Linear search over `@heatmap_boundaries` to return bin index in `[0, num_buckets-1]`. Silently clamps out-of-range values to last bin. | R2 (bin-assignment) | Reads `@heatmap_boundaries`. | — |
| `calculate_heatmap_buckets` | `ltl:4791–4865` | End-of-pass: computes `@heatmap_boundaries` via logarithmic formula from `$heatmap_min` / `$heatmap_max`; sorts each `%heatmap_raw{$bucket}` to derive percentile markers; iterates each raw value and increments `%heatmap_data`; frees `%heatmap_raw`. | R1 (partition) + R2 (bin-assignment, via `find_heatmap_bucket`) + R3 (counter-update) + empirical-percentile derivation | Reads `$heatmap_min`, `$heatmap_max`, `$heatmap_width`, `%heatmap_raw`, `%heatmap_raw_hl`. Writes `@heatmap_boundaries`, `%heatmap_data`, `%heatmap_data_hl`, `%heatmap_percentiles`, `$heatmap_max_density`. Frees `%heatmap_raw` / `%heatmap_raw_hl` after binning (`ltl:4855–4856`). | `time_bucket` |
| Live observation in parse loop | `ltl:4689–4690` | Per-line update of `$heatmap_min` / `$heatmap_max` from each parsed value. Continues to run under #34 R7 (drift detection). | Min/max capture — outside R1–R4, but feeds R1 in raw-value mode. | Writes `$heatmap_min`, `$heatmap_max`. | — |
| Pre-seed load | `ltl:710–729` (`preseed_heatmap_bounds`) | When index pre-seed available, set `$heatmap_min` / `$heatmap_max` from `$index_aggregated{${metric}_min/max}` before parsing starts. Feeds R1 in histogram bin-counter mode. | Min/max sourcing for R1. | Writes `$heatmap_min`, `$heatmap_max` (from #179 globals). | — |
| Counter increment | `ltl:4839, 4850` (inside `calculate_heatmap_buckets`) | `$heatmap_data{$bucket}{$range_index}++`. Highlighted analog: `$heatmap_data_hl{$bucket}{$range_index}++`. | R3 (counter-update). | Writes `%heatmap_data`, `%heatmap_data_hl`, `$heatmap_max_density`. | `time_bucket` |
| `print_heatmap_row` | `ltl:6378–6432` | Per-time-bucket rendering: iterates bin indices, reads `%heatmap_data{$bucket}{$i}`, applies logarithmic color scale against `$heatmap_max_density`, overlays percentile markers from `%heatmap_percentiles`. | Rendering driver (consumes R3 output + percentile markers). | Reads `%heatmap_data`, `%heatmap_data_hl`, `%heatmap_percentiles`, `$heatmap_max_density`, `$heatmap_width`. | — |
| `get_heatmap_column_header` | `ltl:6265–6370` | Column header labels at 0% / 25% / 50% / 75% / 100% positions using `@heatmap_boundaries`. | Rendering driver (consumes R1 output). | Reads `@heatmap_boundaries`, `$heatmap_width`, `$heatmap_min`, `$heatmap_max`, `$heatmap_metric`. | — |
| `print_heatmap_footer_scale` | `ltl:6434–6540` | Bottom scale line with boundary values at percentage positions. | Rendering driver (consumes R1 output). | Reads `@heatmap_boundaries`, `$heatmap_width`, `$heatmap_max`, `$heatmap_metric`. | — |
| `format_heatmap_value` | `ltl:6242–6263` | Boundary-value formatter (time / bytes / number) for header and footer rendering. | Rendering helper. | Reads `$heatmap_metric`, UDM config. | — |

Heatmap data structures declared at `ltl:247–260`: `$heatmap_metric`, `$heatmap_width`, `%heatmap_data`, `%heatmap_data_hl`, `%heatmap_raw`, `%heatmap_raw_hl`, `@heatmap_boundaries`, `$heatmap_min`, `$heatmap_max`, `$heatmap_max_density`, `%heatmap_percentiles`.

**Constraints discovered (heatmap):**

- **Partition is global, not per-metric.** `@heatmap_boundaries` is a single array because heatmap renders one metric per run (selected by `-hm <metric>`). The R1 primitive must support a partition that is owned by the consumer; #189 does not impose a per-metric registry.
- **Bucket count is CLI-driven.** `$heatmap_width` (default 52, `-hmw`-tunable). Source is consumer-owned (R7).
- **Counter key is `time_bucket`.** Per-time-bucket counter freeing is in scope for #187 Phase 3.
- **Out-of-range handling today is silent clamp.** `find_heatmap_bucket` (`ltl:4783`) returns no out-of-range index; values above the max boundary fall through the loop and the caller's fallback applies last bin. The R2 contract introduces explicit sentinels — new behavior, not a refactor.
- **Partition-computation timing must move from end-of-pass to start-of-pass when histogram bin-counter mode is eligible.** Today `calculate_heatmap_buckets` runs at `ltl:8283` after the read pass. Under bin-counter mode, partition must exist before line-by-line accumulation begins so `find_heatmap_bucket` (or its R2 equivalent) can be called per line.
- **Empirical percentile markers depend on the raw-value array.** `%heatmap_percentiles{$bucket}` (populated `ltl:4829–4834`) is derived by sorting `%heatmap_raw{$bucket}` and indexing P50/P95/P99/P99.9 — then mapped through `find_heatmap_bucket` to bin indices for rendering. Under bin-counter mode, the raw array is not allocated; the markers must come from somewhere else. See **Open question — heatmap percentile markers under bin-counter mode** below.

#### Histogram consumer

| Site | `ltl` location | What it does | Primitive | Reads / writes | Key shape |
|---|---|---|---|---|---|
| `handle_histogram_option` | `ltl:3487–3529` | Parses `-hg[:metrics]`; sets `$histogram_enabled` and `%histogram_metrics`. | Configuration. | Writes `$histogram_enabled`, `%histogram_metrics`. | — |
| Raw value collection (parse loop) | `ltl:4700–4727` | Per-line, per-metric: `push @{$histogram_values{$metric}}, $value` (and `_hl` variant if highlighted). Gated by `$histogram_enabled` and `%histogram_metrics`. | Counter-update site **in raw-value mode** (will replace with R3 in bin-counter mode). | Reads `$duration`, `$bytes`, `$count`, `%udm_values`, `$category_bucket`. Writes `%histogram_values`, `%histogram_values_hl`. | — (per-metric only) |
| `calculate_histogram_bucket_count` | `ltl:4869–4887` | Determines `num_buckets` from observed `(min, max)` via `decades * histogram_buckets_per_decade`, clamped to ≥5. `-hgb` override bypasses. | R1 input (bucket-count derivation). | Reads `$histogram_bucket_override`, `$histogram_buckets_per_decade`. Returns `($bucket_count, $decades)`. | — |
| `find_histogram_bucket_index` | `ltl:4890–4905` | Binary search over per-metric boundary array; returns bin index. No out-of-range sentinel (always in-range result). | R2 (bin-assignment). | Reads `@$boundaries_ref`. | — |
| `calculate_histogram_buckets` | `ltl:4908–5043` | End-of-pass orchestrator: per metric, sort raw values, compute percentiles into `histogram_stats{$metric}`, derive `(min, max, num_buckets)`, populate `@{$histogram_boundaries{$metric}}` via logarithmic formula (`ltl:4962–4966`), iterate values and increment `@{$histogram_buckets{$metric}}[bucket_idx]` (`ltl:4973–4974`), free `%histogram_values{$metric}` (`ltl:4978`). Repeats analogously for highlight subset (`ltl:4984–5015`) reusing the same boundaries. | R1 (partition) + R2 (bin-assignment, via `find_histogram_bucket_index`) + R3 (counter-update) + empirical-percentile derivation | Reads `%histogram_values`, `%histogram_values_hl`. Writes `%histogram_boundaries`, `%histogram_buckets`, `%histogram_buckets_hl`, `%histogram_stats`, `%histogram_stats_hl`. Frees `%histogram_values{$metric}` and `%histogram_values_hl{$metric}` after binning. | — (per-metric only) |
| `calculate_histogram_layout` | `ltl:5048–5176` | Side-by-side layout dimensions for active metrics (those with non-zero count); width / height / centering. | Rendering driver (layout). | Reads `%histogram_stats`, terminal dimensions, `-hgw`/`-hgh`. | — |
| `print_histograms` | `ltl:6890–7068` | Top-level rendering driver. Calls layout, display-bucket scaling, y-tick / x-label calculation, percentile selection, per-row rendering, axis / legend rendering. | Rendering driver (consumes R1 + R3 output). | Reads `%histogram_buckets`, `%histogram_stats`, `%histogram_boundaries`, highlight variants. | — |
| `calculate_histogram_display_buckets` | `ltl:7071–7102` | Scales `@{$histogram_buckets{$metric}}` to display column count (expand or compress). | Rendering driver (display scaling). | — | — |
| `calculate_histogram_y_ticks` | `ltl:7105–7152` | Height-dependent Y-axis tick positions. | Rendering driver (ticks). | — | — |
| `calculate_histogram_x_labels` | `ltl:7155–7217` | Logarithmic X-axis label positions, formatted via `format_heatmap_value`. | Rendering driver (labels). | Reads `$boundaries_ref` for the metric. | — |
| `render_histogram_row` | `ltl:7220–7358` | Per-row bar rendering with partial-block glyphs, highlight stacking, gridlines. | Rendering driver (glyphs). | — | — |
| `select_histogram_percentiles` | `ltl:7375–7425` | Width-aware selection of which percentile values from `histogram_stats{$metric}` to show in the legend and axis. **Not a percentile computation; consumes already-computed values.** | Rendering driver (selection). | Reads `%histogram_stats`. | — |
| `calculate_histogram_percentile_ticks` | `ltl:7430–7451` | Maps selected percentile values to logarithmic X-axis column positions. | Rendering driver (positioning). | — | — |
| `render_histogram_x_axis`, `render_histogram_x_labels`, `render_histogram_legend` | `ltl:7454–7559` | Axis frame, axis labels, percentile legend (with optional highlight legend). | Rendering driver (composition). | — | — |

Histogram data structures declared at `ltl:286–328`: `$histogram_buckets_per_decade` (default 8), `$histogram_bucket_override`, `%histogram_values`, `%histogram_values_hl`, `%histogram_boundaries`, `%histogram_buckets`, `%histogram_buckets_hl`, `%histogram_stats`, `%histogram_stats_hl`. Option globals declared during parse: `$histogram_enabled`, `%histogram_metrics`, `$histogram_width_percent`, `$histogram_width_explicit`, `$histogram_height`, `$histogram_height_explicit`.

**Constraints discovered (histogram):**

- **Partition is per-metric, not global.** `%histogram_boundaries{$metric}` — one partition per active metric. R1 is invoked once per `(consumer, metric)` pair, even when consumers happen to share metric names.
- **Bucket count is data-driven, not CLI-fixed.** Today's `calculate_histogram_bucket_count` derives `num_buckets` from observed `(min, max)`. Under bin-counter mode, the same formula runs against **pre-seeded** `(min, max)` from #179 — same logic, different timing.
- **Counter key is `()`.** Histogram aggregates globally per metric; no per-time-bucket dimension. Distinct from heatmap.
- **Out-of-range handling today is silent (in-range only).** `find_histogram_bucket_index` (`ltl:4890`) returns an index always within `[0, num_buckets-1]` by binary-search construction; values outside `(min, max)` would have been adjusted to the inside before the call. Under bin-counter mode the partition is fixed up front, so values **can** fall outside; the R2 sentinel contract is required.
- **Highlight subset shares the base partition.** `%histogram_buckets_hl{$metric}` uses the same `%histogram_boundaries{$metric}` array (`ltl:5009`). Under bin-counter mode this remains correct: the highlight is a tally over the same value space, partitioned identically.
- **Empirical percentiles in `histogram_stats` depend on the raw-value array.** Stats `p1..p9999` (`ltl:4930–4939`) are sort-and-index over the raw value array. Under bin-counter mode the raw array is not allocated; either the percentiles in `histogram_stats` migrate to R4-derived (Phase 2 / R12 work in #187), or they are deferred until #187 lands. **#34 itself does not need to resolve this** — histogram percentile *values* are not part of the rendered bin counts and are not regressed by removing the raw array, as long as the consumer of `histogram_stats{p*}` (the legend, via `select_histogram_percentiles` at `ltl:7375`) is also updated. This is a real consumer-side requirement on #189 R4, recorded as a constraint on the rollout sequence, not a blocker.

#### Summary-table per-message latency percentile consumer (#187 Phase 2 target)

| Site | `ltl` location | What it does | Primitive | Reads / writes | Key shape |
|---|---|---|---|---|---|
| Raw collection | `ltl:4591` | `push @{$log_messages{$category}{$log_key}{durations}}, $duration` during parse loop. | Counter-update site **in exact mode** (will become R3 in approximate mode). | Writes `log_messages{}{}{durations}`. | `()` per `(category, message_key)` |
| `calculate_all_statistics` | `ltl:5178–5471` | Per-message aggregator; collects durations across buckets per `log_key`. | Orchestrator. | Reads `log_messages{}{}{durations}`. Writes per-message percentile scalars. | — |
| `calculate_statistics` | `ltl:5488–5527` | Core percentile engine: `sort { $a <=> $b }` + integer index lookup (`int($n * fraction)`). | Exact percentile (sort-and-index). | Reads array. Returns `(min, mean, max, p1, p50, p75, p90, p95, p99, p999, std_dev, cv)`. | — |
| Output | `ltl:5374–5379` | `$log_messages{$category}{$log_key}{p50}`, `{p99}`, `{p999}`. | Storage. | Writes `log_messages{}{}{p*}`. | — |
| Rendering | `ltl:7900–7916` | Summary table reads `log_messages{$grouping}{$key}{p50}`, `{p99}`, `{p999}`; formats and prints. | Rendering driver. | Reads `log_messages{}{}{p*}`. | — |

**Constraints discovered (summary-table per-message):**

- **`log_messages{...}{durations}` is the raw-array migration target for #187 Phase 2.** Under approximate mode it becomes a histogram bin-counter store keyed by `(category, log_key)` and indexed by bin.
- **Key shape is `()` per message** in #189 R3 terms — each `(category, log_key)` pair has its own counter store.
- **`calculate_statistics` (`ltl:5488`) is the algorithm boundary.** Exact mode keeps it; approximate mode replaces its sort-and-index core with R4 invocations against the per-message counter store.
- **Percentiles emitted: P1, P50, P75, P90, P95, P99, P99.9.** R4 must support all seven (or however many #187 R3 finalizes).
- **#34 R15 confirmed:** `log_messages{...}{durations}` is structurally separate from `%heatmap_raw` and `%histogram_values`. The three families have distinct keys, distinct lifetimes, and distinct allocation sites. #34's data structures do not entangle with this consumer.

#### Per-time-bucket duration percentile consumer (#187 Phase 3 target)

| Site | `ltl` location | What it does | Primitive | Reads / writes | Key shape |
|---|---|---|---|---|---|
| Raw collection | `ltl:4634` | `push @{$log_analysis{$bucket}{durations}}, $duration unless $heatmap_enabled`. | Counter-update site **in exact mode**. | Writes `log_analysis{$bucket}{durations}`. | `time_bucket` |
| Aggregation in `calculate_all_statistics` | `ltl:5206` | `push @{$aggregated_data->{durations}}, @{$log_analysis{$bucket}{durations}}` for each bucket. | Aggregator. | Reads `log_analysis{$bucket}{durations}`. Frees same (`ltl:5213–5214`). | `time_bucket` |
| `calculate_statistics` (per bucket) | `ltl:5488` | Same engine as per-message path — sort-and-index. | Exact percentile. | — | — |
| Output | `ltl:5220, 5236–5242, 5273` | `log_stats{$bucket}{p1}`, `{p50}`, `{p75}`, `{p90}`, `{p95}`, `{p99}`, `{p999}`. | Storage. | Writes `log_stats{$bucket}{p*}`. | `time_bucket` |
| Rendering | `ltl:6843–6846` | Time-bucket bar row: `$log_stats{$bucket}{p50}`, `{p95}`, `{p99}`, `{p999}` formatted inline. | Rendering driver. | Reads `log_stats{}{p*}`. | — |

**Constraints discovered (per-time-bucket):**

- **Raw array is gated `unless $heatmap_enabled`** (`ltl:4634`). When heatmap is active, the per-time-bucket duration percentile is suppressed because the heatmap's per-time-bucket distribution carries equivalent visual information. This entanglement is a pre-existing condition that #187 R8 ("Coupling to histogram bin counters") anticipates: under bin-counter mode, the heatmap counter store **is** the natural source for per-time-bucket percentile derivation via R4, and the `log_analysis{$bucket}{durations}` array becomes unnecessary. The gate may need re-evaluation when #187 Phase 3 lands.
- **Key shape is `time_bucket`** — identical to heatmap. #187 Phase 3 can reuse the heatmap counter store (per #189 R6 independence allows the partition to differ if bucket counts differ, but R3 allows the same counter store to be addressed by both consumers if their partitions agree).
- **Same percentile set as per-message (P1, P50, P75, P90, P95, P99, P99.9)** — R4 contract is uniform.

#### Histogram-mode global percentile consumer (incidental Phase 2 target)

| Site | `ltl` location | What it does | Primitive | Reads / writes | Key shape |
|---|---|---|---|---|---|
| Inside `calculate_histogram_buckets` | `ltl:4926–4940` | Computes `histogram_stats{$metric}{p1..p9999}` from sorted raw values **alongside** the bin-counter population in the same routine. | Exact percentile (sort-and-index), interleaved with R1+R2+R3 in raw-value mode. | Reads `%histogram_values`. Writes `%histogram_stats`. | — |
| Highlight variant | `ltl:4995–5004` | Same, against `%histogram_values_hl`. | — | — | — |
| Consumer | `ltl:7375–7425` (`select_histogram_percentiles`) | Renders selected percentile values on the legend. | Rendering driver. | Reads `%histogram_stats`. | — |

**Constraints discovered (histogram-mode global percentile):**

- **Today this path is entangled with the bin-counter population** — both happen in the same routine, against the same raw arrays, in two different sort-and-index passes (one for percentiles at `ltl:4926`, one for binning at `ltl:4972`).
- **Under bin-counter mode the raw arrays don't exist**, so this path must either disappear (drop legend percentile values) or migrate to R4 (interpolate from the bin counters that are present). Migration to R4 is the natural answer, and it lands when #187's algorithm choice is in place — i.e., as a side benefit of Phase 2.
- **Percentile set: P1, P10, P25, P50, P75, P90, P95, P99, P99.9, P99.99** — wider than the summary-table set; R4 must support all ten.

#### Heatmap percentile-marker consumer (open question for #34)

| Site | `ltl` location | What it does | Primitive | Reads / writes | Key shape |
|---|---|---|---|---|---|
| Inside `calculate_heatmap_buckets` | `ltl:4818, 4823–4834` | Sorts `%heatmap_raw{$bucket}`, derives P50/P95/P99/P99.9 values via index lookup, maps each value to a bin index via `find_heatmap_bucket`, stores in `%heatmap_percentiles{$bucket}` as bin indices. | Exact percentile derivation + bin lookup. Markers stored as bin indices, not values. | Reads `%heatmap_raw`. Writes `%heatmap_percentiles`. | `time_bucket` |
| Consumer | `ltl:6378–6432` (`print_heatmap_row`) | Overlays `|` markers at the recorded bin indices for each rendered row. | Rendering driver. | Reads `%heatmap_percentiles`. | — |

**Constraints discovered (heatmap percentile-marker) — see open question below.**

### Open question — heatmap percentile markers under bin-counter mode

**Status: unresolved at audit close; recorded as an open design question for #34's implementation step (delivery sequence step 4).**

Under raw-value mode, heatmap percentile markers are derived from `%heatmap_raw{$bucket}` (the per-bucket raw-value array) before that array is freed. Under histogram bin-counter mode (#34 R4), `%heatmap_raw` is **never allocated** — per-line values increment counters directly. So the marker derivation has no source.

Three resolutions are conceivable:

1. **Markers move to R4 (bin-derived interpolation).** Heatmap becomes a future consumer of `#189 R4`. This contradicts the current note in #189 R4 ("This primitive is not consumed by #34") but is the cleanest fit: the markers are positions on a logarithmic axis already partitioned identically to the data. The only friction is delivery sequencing: #34 ships before #187's algorithm choice (D3) lands, so R4 would need to ship with a default algorithm and accuracy bound that #34's implementation accepts.
2. **Markers are dropped in bin-counter mode.** The rendered heatmap row loses its P50/P95/P99/P99.9 markers. Behavior is no longer byte-identical under #34 R8 (render equivalence) — this resolution is incompatible with R8 and is recorded as non-viable unless R8 is amended.
3. **A second light-weight percentile tracker runs alongside the bin counter.** A streaming approximate percentile (e.g., t-digest) is maintained in addition to the bin counter, just for the markers. This adds a new primitive contract and is in tension with the audit's goal of harmonization; recorded as a non-preferred fallback.

The audit does not resolve this. The resolution is gated on either #187 D3 landing early enough for option 1, or on a documented amendment to #34 R8 for option 2. **#34's implementation step must surface this before coding begins.**

### Cross-cutting compatibility constraints discovered during audit

These constraints apply across all consumers and are the hard inputs to #189's primitive design.

- **Independent partitions per consumer** (#34 R11). Heatmap has one partition (single metric per run); histogram has one partition per metric; summary-table per-message percentiles (Phase 2) need one partition per `(category, log_key)`; per-time-bucket percentiles (Phase 3) can share the heatmap partition when bucket counts agree. R1's primitive return value is owned by the caller — no global registry.
- **Parameterizable counter keying** (#189 R3). Five distinct key shapes catalogued today / anticipated: `time_bucket` (heatmap, Phase 3), `()` (histogram, Phase 2, histogram-mode global percentile), `(category, log_key)` (Phase 2 per-message), `(time_bucket, highlight_subset)` (Phase 4). R3 must accept all without primitive-level change.
- **Partition-computation timing flexibility.** Today every partition is computed at end-of-pass after min/max observation. Under bin-counter mode every partition is computed at start-of-pass from pre-seeded bounds. R1 is pure and timing-agnostic; the timing decision lives in the consumer's eligibility gate (#34 R2 for heatmap/histogram; #187 R2 for percentiles).
- **Min/max source flexibility.** Today min/max are observed live during parse (`ltl:4689–4690` for heatmap; aggregated implicitly during sort in histogram). Under bin-counter mode they come from #179's pre-seed. Both must remain available during a run because #34 R7 mandates live capture continues even under bin-counter mode (for drift detection).
- **Out-of-range sentinels are new contract.** Today's bin-assignment functions (`find_heatmap_bucket` `ltl:4783`, `find_histogram_bucket_index` `ltl:4890`) silently produce in-range indices. R2's sentinel contract is required by #34 R5/R6 and by #179 drift detection. This is **not** a refactor of existing logic — it is new behavior the primitive introduces.
- **Two bin-assignment algorithms in use today (linear vs. binary search).** `find_heatmap_bucket` is linear (`ltl:4785–4789`); `find_histogram_bucket_index` is binary (`ltl:4895–4903`). R2 picks one (or supports both). Recorded as a #189 implementation decision, not resolved by the audit. Either choice satisfies R2's correctness contract.
- **Memory lifecycle: counter stores must be per-key freeable** (#189 R8). Heatmap counters per `time_bucket` can be freed after rendering. Phase 3 percentile counters similarly. Histogram counters persist for the run (no per-key freeing needed). Phase 2 per-message counters persist until the summary table is rendered. R8 must accommodate all three lifecycles.
- **The `histogram_stats` percentile values (`ltl:4926–4940`) are sort-derived from raw arrays and live alongside the bin counters in the same routine.** Under bin-counter mode the raw arrays are absent. This means a single implementation choice — keep the sort, drop the sort, or replace with R4 — affects both `histogram_stats{p*}` legend output and the `histogram_buckets` mechanism. The audit identifies this as the strongest argument for #34 and #187 Phase 2 to ship together (or for histogram to defer bin-counter mode until R4 ships).
- **Pre-existing entanglement between heatmap and per-time-bucket duration percentiles.** `log_analysis{$bucket}{durations}` is gated `unless $heatmap_enabled` (`ltl:4634`). Heatmap takes ownership of duration values when active; per-time-bucket percentiles are suppressed. Under bin-counter mode, heatmap's counters become the natural source for per-time-bucket percentiles via R4. The audit confirms the entanglement is in scope for #187 Phase 3 to resolve, not for #34 to patch.

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
