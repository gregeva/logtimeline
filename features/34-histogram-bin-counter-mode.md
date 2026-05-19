# Feature: Heatmap and histogram consumer migrations onto the unified primitive contract

## Overview

This feature is the **implementation ticket for the heatmap and histogram consumer migrations** onto the unified primitive contract locked in #187 (`features/187-histogram-bin-counter-percentiles.md`). The migrations transition four consumers from today's end-of-parse-from-retained-arrays pattern (in `calculate_heatmap_buckets` at `ltl:4791-4865` and `calculate_histogram_buckets` at `ltl:4908`) onto the unified contract, which uses #189's primitives:

| `-V` consumer name (locked in #187 Decision 8) | What it covers | Current implementation |
|---|---|---|
| `heatmap_cells` | Heatmap cell colors | `%heatmap_raw` accumulation, end-of-parse partition derivation, end-of-parse binning |
| `heatmap_markers` | P50/P95/P99/P999 column-position markers on heatmap rows | `%heatmap_percentiles` derived from `%heatmap_raw` sort |
| `histogram_view` | Histogram-mode global percentile indicators (legend values, x-axis ticks) | `%histogram_stats{$metric}{p*}` derived from `%histogram_values` sort |
| `histogram_bins` | Histogram-mode bin counts (bar heights) | `%histogram_buckets{$metric}` derived from end-of-parse binning |

Under the unified contract, each of these consumers uses #189's primitives directly: partition with HdrHistogram-style auto-resize (per #187 Decision 5), bin assignment via log-spaced boundary computation, counter update with the consumer's keying, percentile interpolation via the locked Prometheus formula (per #187 Decision 1). The dual-mode "raw-value mode vs. bin-counter mode" framing that pre-dated #187's locked contract is **dissolved** — there is no runtime gate (per #187 Decision 6's dissolution). The consumer either runs the unified path (post-migration) or its pre-migration code path (pre-migration or under `--exact-percentiles` opt-out per #187 Decision 7).

## GitHub Issue

[#34](https://github.com/gregeva/logtimeline/issues/34)

## Motivation

For multi-GB log analysis runs (chained daily files, long-window investigations), the raw-value arrays (`%heatmap_raw`, `%histogram_values`) dominate peak memory. The unified contract replaces them with bounded counter stores (~265 bins per partition at locked default 53 bpd × 5 decades), with per-key memory bounded by the per-key value range.

Under #187's locked Decision 5 (auto-resize), the partition lifecycle is online — no precedent run or index pre-seed is required. A fresh `ltl` invocation on months of historical data gets the heatmap, histogram, and the rest in a single pass, in memory-safe form. This is the realistic operational pattern for ltl's user base.

Display geometry is unchanged by the migration: the heatmap column count, color scheme, and percentile-marker positions all stay the same; the histogram column count, bar layout, and legend stay the same. Internal precision improves because Decision 2's locked default (53 bpd) is higher than today's shipped 8 bpd default for the heatmap and histogram features — percentile markers and bin counts become *more* accurate. Per-time-bucket re-projection of per-partition counts onto the display column grid is the render-time step that preserves display stability.

## Delivery sequence

This feature is the implementation ticket for the heatmap/histogram consumer migrations. It depends on #187's locked contract and #189's primitives.

| Step | Work | Owner | Why this position |
|---|---|---|---|
| 1 | **Unified contract locked** — F1, D1, D1A, D2, D3, D4, D5, D7, D8, D10 | **#187** | Authoritative contract reference: `features/187-histogram-bin-counter-percentiles.md`. |
| 2 | **Prototype validation** — five mandatory aspects per #187 Decision 10 | **#189 (prerequisite to its production work)** | Validates the locked architecture against real D2 data before any consumer migration begins. |
| 3 | **Unified primitives implemented** — R1-R11 per `features/189-histogram-bin-counter-primitives.md` | **#189** | Provides the primitive helpers each consumer migration uses. |
| 4 | **Heatmap and histogram consumer migrations** — `heatmap_cells`, `heatmap_markers`, `histogram_view`, `histogram_bins` migrate onto #189's primitives | **#34 — this issue's production step** | The four consumers migrate together (per R9 grouping recommendation in #187 — they share code structure in `calculate_heatmap_buckets` and `calculate_histogram_buckets`). |

### Parallelism

Steps 1, 2, and 3 are sequential prerequisites. Step 4 (this feature's work) cannot begin until #189 has completed step 3.

### Integration

Work lands on feature branches per CLAUDE.md's release process. Specific release-branch integration is this implementation ticket's choice.

## Terminology

This feature uses the terminology locked in #187:

- **Unified primitive contract** — the locked decisions in `features/187-histogram-bin-counter-percentiles.md`. Authoritative for all behavior.
- **Histogram bin counters** — the underlying data structure used by every consumer (#189 implements).
- **Consumer** — a code path that needs percentile values or histogram bin counts. The four consumers in scope here are `heatmap_cells`, `heatmap_markers`, `histogram_view`, `histogram_bins`.
- **Partition** — one instance of the bin counter structure with its own `[min, max]` boundaries, owned by one consumer for one keying dimension.
- **Auto-resize** — the partition lifecycle locked in #187 Decision 5 (lazy construction, full-default-span seed centered on first value, HdrHistogram-convention doubling on rebin).
- **Pre-migration path** — the consumer's current end-of-parse-from-retained-arrays code (in `calculate_heatmap_buckets`, `calculate_histogram_buckets`). Survives post-migration as the `--exact-percentiles` opt-out path per #187 Decision 7.
- **Unified path** — the consumer's post-migration code, using #189's primitives.

No new terminology introduced by #34.

## Requirements

The requirements below define the **contract surface** that the heatmap and histogram consumer migrations must satisfy. Each requirement either restates a #187-locked decision or specifies migration-specific scope. The locked decisions in `features/187-histogram-bin-counter-percentiles.md` are authoritative.

### R1 — Four consumer migrations onto the unified contract

This feature migrates the following four consumers from their pre-migration code paths onto the unified primitive contract:

1. **`heatmap_cells`** — heatmap cell colors. Pre-migration path: `%heatmap_raw{$bucket}` accumulation during the parse, `calculate_heatmap_buckets` at `ltl:4791-4865` at end of parse. Migration: per-`time_bucket` auto-resize partition via #189 R1, per-line bin assignment via #189 R2, per-line counter update via #189 R3, render-time re-projection of per-bucket partition counts onto the W-column display grid (`-hmw`, default 52).
2. **`heatmap_markers`** — P50/P95/P99/P999 column-position markers on each heatmap row. Pre-migration path: sort `%heatmap_raw{$bucket}`, index by integer rank, map to bin index via `find_heatmap_bucket`, store in `%heatmap_percentiles`. Migration: per-`time_bucket` partition shared with `heatmap_cells` (or independent, per #189 R7); R4 invoked per time bucket for the four quantiles per #187 R3; R4's numeric return mapped to a display column position for storage in `%heatmap_percentiles`.
3. **`histogram_view`** — histogram-mode global percentile indicators (legend values, x-axis tick positions). Pre-migration path: sort `%histogram_values{$metric}`, index by integer rank, store in `%histogram_stats{$metric}{p*}`. Migration: global per-metric auto-resize partition via #189 R1; R4 invoked per metric for the ten-value percentile set per #187 R3 (P1, P10, P25, P50, P75, P90, P95, P99, P999, P9999); numeric values stored directly in `%histogram_stats{$metric}{p*}`.
4. **`histogram_bins`** — histogram-mode bin counts (bar heights). Pre-migration path: end-of-parse binning in `calculate_histogram_buckets` at `ltl:4908`. Migration: same global per-metric partition as `histogram_view` (consumer-shared per #189 R7); per-line bin assignment and counter update during the parse; render-time re-projection of partition counts onto display column grid.

The four consumers migrate together per #187 R9's Phase 3 grouping recommendation (they share code structure in `calculate_heatmap_buckets` and `calculate_histogram_buckets`; splitting them across releases would leave the codebase in an inconsistent partial-migration state).

### R2 — No runtime mode-selection gate

Per #187 Decision 6's dissolution, there is **no runtime gate** between an "approximate path" and an "exact path" within a consumer. Post-migration, each of the four consumers runs the unified-contract path unconditionally on every run.

The pre-migration code path survives per-consumer:
- During the migration's validation phase, as the regression-validation reference per #187 R11.
- Post-validation, as the path engaged when the user opts out via `--exact-percentiles` (per #187 Decision 7).

R10 reports per-consumer which path is active for any given run.

### R3 — Auto-resize partition lifecycle per #187 Decision 5

Each consumer's partitions follow the locked auto-resize lifecycle:

- Constructed lazily on first observation for the consumer's key (`time_bucket` for `heatmap_cells`/`heatmap_markers`; `()` global per metric for `histogram_view`/`histogram_bins`).
- Seeded at 5 decades centered on the first observed value per #187 Decision 5 implementation guidance.
- Extended via HdrHistogram-convention doubling when subsequent values fall outside `[min, max]`.

Partition computation does *not* happen at start-of-run from external bounds. The unified contract is end-of-pass-from-retained-arrays-free *and* index-pre-seed-free.

### R4 — Per-line accumulation during parse

During the existing single read pass, each parsed value for an active metric (`-hm` or `-hg` requested) is assigned to a bin index against the consumer's auto-resize partition via #189 R2, and the corresponding counter is incremented via #189 R3. No per-line value array is allocated for the metrics that drive heatmap or histogram rendering — the pre-migration `%heatmap_raw` and `%histogram_values` data structures are eliminated under the unified path.

When a value falls outside the partition's current `[min, max]`, R3 triggers rebin (auto-resize per R3 of this feature, which delegates to #189's R1 lifecycle).

### R5 — Render-time re-projection onto the display grid

The display geometry of the heatmap and histogram is unchanged by the migration: the heatmap has W display columns (`-hmw`, default 52); the histogram has its display column count from existing CLI flags (`-hgw`, etc.).

The internal partition has more bins than the display has columns (typically ~265 bins at locked default 53 bpd × 5 decades). The migrated rendering driver computes the W-column display boundaries from the partition's `[min, max]` and re-projects the partition's bin counts onto the W display columns at render time via an O(bin count) traversal per row. Cell colors and bar heights derive from the re-projected counts.

The same render-time re-projection is used by `heatmap_markers` and `histogram_view`: R4 returns a numeric value; the rendering driver re-projects that value onto a display column position (for `heatmap_markers`) or formats it directly (for `histogram_view`).

### R6 — Overflow and underflow per #187 Decision 4

Per #187 Decision 4, each partition maintains separate overflow and underflow counters distinct from the in-range bins. Under #187 Decision 5's auto-resize lifecycle, overflow and underflow are expected to be rare in practice — the partition extends to contain observed values. Decision 4's mechanisms function primarily as a safety net.

The migrated consumers do not require any feature-specific overflow handling beyond what #189 implements per #187 Decision 4.

### R7 — Telemetry surface for `-V` output per #187 Decision 8

Each migrated consumer produces a per-consumer block in the locked `=== BIN-COUNTER MODE ===` `-V` section per #187 Decision 8, with the locked consumer-name strings: `heatmap_cells`, `heatmap_markers`, `histogram_view`, `histogram_bins`.

Each per-consumer block reports the contract-surface fields locked in #187 Decision 8: `path`, `partition_keying`, `partition_count`, `total_rebin_events`, `max_partition_bins`, `partitions_with_overflow_count`, `partitions_with_underflow_count`, `counter_memory_bytes`, `rebins_per_partition`, `percentiles_emitted`, `out_of_range_bounded`, `shares_partitions_with` (where applicable).

The exact field formats are locked in #187 Decision 8. This feature implements the consumer-specific population of those fields; it does not define new fields.

### R8 — Display geometry preservation

Display geometry (column counts, color scheme, bar layout, percentile-marker positions, legend layout, x-axis tick positions) is unchanged by the migration. Internal precision improves because Decision 2's locked default (53 bpd) is higher than today's shipped 8 bpd default — bin counts and percentile values become *more* accurate.

Implementation tickets must validate against the existing baseline-regression harness (`tests/baseline/`, per CLAUDE.md) to confirm display stability.

### R9 — Heatmap and histogram have independent partitions per #189 R7

Although both consumers operate on the same metric, they hold independent partitions:

- `heatmap_cells` and `heatmap_markers` may share partitions (same keying, same metric) — #189 R7 allows consumer sharing.
- `histogram_view` and `histogram_bins` share their partition (same keying `()` global, same metric) per #189 R7.
- The heatmap pair and the histogram pair hold separate partitions because they have different keying (`time_bucket` vs. `()` global).

The partitions are independent in `[min, max]` as each per-time-bucket partition adapts to its own bucket's values.

### R10 — Per-consumer `-V` path reporting

Each consumer's `path:` line in its `=== BIN-COUNTER MODE ===` block per #187 Decision 8 reports the active path for that consumer:

- `unified` — consumer is on the migrated path.
- `pre_migration` — consumer has not yet migrated, or this is a pre-migration validation run.
- `user_opt_out` — `--exact-percentiles` is active per #187 Decision 7.
- `feature_not_active` — the consumer's feature is not engaged in this run (`-hm` not requested for heatmap consumers; `-hg` not requested for histogram consumers; or no values matched).

### R11 — Pre-migration code path preserved through phase validation per #187 R11

The pre-migration code paths (`calculate_heatmap_buckets`, `%heatmap_raw`, `find_heatmap_bucket`, `calculate_histogram_buckets`, `%histogram_values`, `find_histogram_bucket_index`, related globals) are preserved through this feature's validation phase per #187 R11.

During validation, the implementation ticket runs both paths against the D2 datasets and confirms:
- Under `--exact-percentiles`, byte-identical pre-feature output per #187 R11a.
- Under the unified path, per-quantile error within the bin-resolution bound per #187 R4 for every required quantile.

After phase validation passes, the pre-migration code is retained as the `--exact-percentiles` opt-out surface per #187 Decision 7. The decision of whether and when to retire the pre-migration code post-validation is the implementation ticket's call (per #187 Decision 9's dissolution).

### R12 — Boundaries with other features

This feature owns the **migration implementations** for `heatmap_cells`, `heatmap_markers`, `histogram_view`, `histogram_bins`.

This feature does NOT own:

- The unified contract itself (locked decisions, R12 audit, consumer-name strings, `-V` format) — owned by **#187**.
- The primitive implementations (R1-R11 of `features/189-histogram-bin-counter-primitives.md`) — owned by **#189**.
- Other consumer migrations (`summary_table`, `csv_output`, `time_bucket_stats`, future highlight subsets) — owned by their own implementation tickets.
- Index read-back and any drift-correction concerns — owned by #179 (closed; no longer load-bearing for partition sizing under the auto-resize lifecycle).
- Activation policy, default-on vs. default-off, release cadence — implementation-ticket concerns per #187 Decision 9's dissolution.

The contract authoritative reference is `features/187-histogram-bin-counter-percentiles.md` § *Locked decisions from research*.

## Code sites affected by the migration

The pre-migration code paths that this feature's implementation replaces. Line references are against `release/0.14.5` HEAD; subroutine names and global-variable identifiers are the stable anchors. Full per-site catalogue with primitive mappings lives in `features/189-histogram-bin-counter-primitives.md` § *Audit findings*.

### Heatmap code sites

- **Bin-partition computation** — `calculate_heatmap_buckets` at `ltl:4791-4865`. Pre-migration: end-of-parse, from `$heatmap_min`/`$heatmap_max` aggregated during parse; writes `@heatmap_boundaries`. Migration: replaced by per-`time_bucket` auto-resize partition via #189 R1 invoked during the parse.
- **Per-value bin-index assignment** — `find_heatmap_bucket` at `ltl:4783-4789`. Pre-migration: linear search over `@heatmap_boundaries`, silently clamps out-of-range to last bin. Migration: replaced by #189 R2 with explicit overflow/underflow sentinels per #187 Decision 4.
- **Counter increment** — `ltl:4839`, `ltl:4850` inside `calculate_heatmap_buckets`. Pre-migration: writes `%heatmap_data{$bucket}{$range_index}++`. Migration: replaced by #189 R3 invoked during the parse, with `key = time_bucket`.
- **Raw-value collection** — `%heatmap_raw{$bucket}` accumulated during parse (`ltl:255` declaration). Migration: eliminated entirely under the unified path; the parse loop calls #189 R3 directly instead of pushing values to the raw array.
- **Percentile-marker derivation** — `ltl:4823-4834` inside `calculate_heatmap_buckets`. Pre-migration: sort `%heatmap_raw{$bucket}`, index by integer rank for P50/P95/P99/P999, map to bin via `find_heatmap_bucket`, store in `%heatmap_percentiles{$bucket}`. Migration: #189 R4 invoked per time bucket against the per-bucket partition; numeric return mapped to display column position; storage unchanged.
- **Rendering drivers** — `print_heatmap_row` at `ltl:6378-6432`, `get_heatmap_column_header` at `ltl:6265-6370`, `print_heatmap_footer_scale` at `ltl:6434-6540`, `format_heatmap_value` at `ltl:6242-6263`. Migration: largely unchanged. The render-time re-projection of partition counts onto the W-column display grid (R5 of this feature) is a new step performed before or inside these existing drivers.
- **Heatmap data structures** declared at `ltl:247-260`: `$heatmap_metric`, `$heatmap_width`, `%heatmap_data`, `%heatmap_data_hl`, `%heatmap_raw`, `%heatmap_raw_hl`, `@heatmap_boundaries`, `$heatmap_min`, `$heatmap_max`, `$heatmap_max_density`, `%heatmap_percentiles`. Migration touches all of these.

### Histogram code sites

- **Bucket-count determination** — `calculate_histogram_bucket_count` at `ltl:4869-4887`. Pre-migration: derives `num_buckets` from observed `(min, max)` via `decades * histogram_buckets_per_decade` (default 8). Migration: per #187 Decision 2, `buckets_per_decade` becomes the user-tunable lever (default locked at 53); this function's role shifts to consuming the resolved bpd value.
- **Bin-partition computation** — `calculate_histogram_buckets` at `ltl:4908-5043`. Pre-migration: end-of-parse, sort `%histogram_values{$metric}`, derive `(min, max, num_buckets)`, populate `@{$histogram_boundaries{$metric}}`. Migration: replaced by global per-metric auto-resize partition via #189 R1 invoked during the parse.
- **Per-value bin-index assignment** — `find_histogram_bucket_index` at `ltl:4890-4905`. Pre-migration: binary search over per-metric boundary array. Migration: replaced by #189 R2 with explicit overflow/underflow sentinels.
- **Counter increment** — `ltl:4973-4974` inside `calculate_histogram_buckets`. Pre-migration: `@{$histogram_buckets{$metric}}[bucket_idx]++`. Migration: #189 R3 invoked during the parse with `key = ()` per metric.
- **Raw-value collection** — `%histogram_values{$metric}` accumulated during parse at `ltl:4700-4727` (`ltl:286-328` declarations). Migration: eliminated under the unified path; parse loop calls #189 R3 directly.
- **Percentile-indicator derivation** — `ltl:4926-4940` inside `calculate_histogram_buckets`. Pre-migration: sort `%histogram_values{$metric}`, index by integer rank for the ten-value set, store in `%histogram_stats{$metric}{p*}`. Migration: #189 R4 invoked per metric for the ten-value set; numeric values stored directly.
- **Rendering drivers** — `print_histograms` at `ltl:6890-7068` and helpers at `ltl:7071-7559` (display scaling, y-tick / x-label calculation, percentile selection, per-row rendering, axis / legend rendering). Migration: largely unchanged. The render-time re-projection of partition counts onto display columns is a new step performed before or inside these existing drivers.

## Edge cases

| Case | Required behavior |
|---|---|
| Neither `-hm` nor `-hg` requested | All four consumers report `path: feature_not_active` in `-V`. No partitions constructed. |
| First value for a new time bucket (heatmap) is observed | Per #189 R1 (Decision 5 lifecycle), partition is lazily constructed centered on the first value with 5-decade span. No upfront sizing required. |
| First value for a new metric (histogram) is observed | Same lazy construction at first observation. |
| Subsequent value falls outside the current partition `[min, max]` | Per #189 R1 / Decision 5, partition extends via HdrHistogram-convention doubling. Existing counts preserved. Rebin event tallied per Decision 5 telemetry. |
| Value falls outside the partition after doubling cap (if any) | Increments overflow or underflow counter per #187 Decision 4. Per-quantile `out_of_range_bounded` audit field reflects this. |
| All-same metric values | Single bin populated; partition operates correctly. Per #187 R5. |
| Single observed value | Partition constructed with single observation; subsequent percentile queries return that value per #187 R5. |
| Multi-file run | Each file's values feed the same per-`time_bucket` (heatmap) and per-metric (histogram) partitions. Auto-resize accommodates the combined range. No special multi-file handling required at this feature's layer. |
| User specifies `-hmw <W1>` (heatmap display width) | Display has W1 columns. The internal partition has more bins than W1; render-time re-projection (R5) projects partition counts onto W1 columns. |
| User specifies different `-hmw` and `-hgw` | Heatmap displays at W1 columns; histogram at W2 columns. Independent per #189 R7. Internal partitions are independent. |
| `--exact-percentiles` is set | All four consumers report `path: user_opt_out` and run the pre-migration code paths per #187 Decision 7 and R11 of this feature. |
| Concurrent ltl processes | Out of this feature's concern. |

## Acceptance criteria

### Migration completeness

- [ ] R1 holds: all four consumers (`heatmap_cells`, `heatmap_markers`, `histogram_view`, `histogram_bins`) have unified-path implementations.
- [ ] R2 holds: no runtime mode-selection gate; each consumer runs either `unified`, `pre_migration`, `user_opt_out`, or `feature_not_active`.
- [ ] R3 holds: partitions use #189 R1's auto-resize lifecycle.
- [ ] R4 holds: per-line accumulation during parse via #189 R2 / R3; no raw-value arrays under the unified path.
- [ ] R5 holds: display geometry preserved via render-time re-projection.
- [ ] R6 holds: overflow/underflow per #187 Decision 4 implemented by #189; this feature consumes that mechanism.
- [ ] R7 holds: `=== BIN-COUNTER MODE ===` section reports each consumer's block per #187 Decision 8.
- [ ] R8 holds: display geometry unchanged; precision improvements documented in release notes.
- [ ] R9 holds: heatmap and histogram have independent partitions per #189 R7.
- [ ] R10 holds: per-consumer `path:` line reports correctly under all four states.
- [ ] R11 holds: pre-migration code paths preserved as `--exact-percentiles` opt-out surface.
- [ ] R12 holds: boundary responsibilities respected.

### Validation phase

- [ ] Under `--exact-percentiles`, all four consumers' output is byte-identical to the pre-feature implementation per #187 R11a.
- [ ] Under the unified path, all four consumers' percentile values fall within the bin-resolution bound per #187 R4 around the pre-migration values, across the D2 dataset set.
- [ ] `tests/baseline/` regression harness passes for the heatmap and histogram outputs.
- [ ] `-V` `=== BIN-COUNTER MODE ===` output matches the locked format per #187 Decision 8 (consumer-name strings, field names, format).

## Validation

This section defines the **validation scenarios** for the heatmap and histogram migrations. The validation harness lives in `tests/baseline/` per CLAUDE.md.

### Contract-level scenarios from #187

The contract-level validation scenarios specified in #187 § Validation apply to this feature's consumers. They cover the locked `=== BIN-COUNTER MODE ===` format, per-consumer `path:` reporting, opt-out behavior, out-of-range bounded reporting, and accuracy comparison against the pre-migration output. The implementation ticket runs these scenarios against the four consumers in this feature's scope.

### Heatmap-specific validation

- **Display geometry stability**: visual diff between pre-migration heatmap output and unified-path output. The unified path has higher internal precision but the same W-column display grid. Cell colors and percentile-marker positions should match within the bin-resolution bound; large deviations indicate a bug in render-time re-projection.
- **Per-time-bucket partition independence**: a workload where adjacent time buckets have wildly different value ranges should produce per-bucket partitions that adapt independently. Verifiable via `-V` per-consumer telemetry (`rebins_per_partition: max` should not unduly inflate).
- **Heatmap-markers vs. heatmap-cells consistency**: P50/P95/P99/P999 markers should fall in display columns whose bin index is consistent with the cell-color distribution. Visual verification against representative D2 datasets.

### Histogram-specific validation

- **Display geometry stability**: bin counts in the rendered histogram should match the pre-migration counts within the bin-resolution bound. Display column count is unchanged.
- **Percentile indicator placement**: P1, P10, P25, P50, P75, P90, P95, P99, P999, P9999 indicators in the legend and on x-axis ticks should fall within the bin-resolution bound of the pre-migration values.
- **Wide percentile set support**: confirm that `histogram_view` requests the ten-value set per R3 of this feature, and that #189 R4 handles all ten correctly.

### Cross-consumer scenarios

- **Both heatmap and histogram active simultaneously**: per #189 R7 (consumer independence), the two pairs of consumers (`heatmap_cells` + `heatmap_markers`; `histogram_view` + `histogram_bins`) hold independent partitions. Verifiable via `-V` per-consumer telemetry.
- **Per-consumer opt-out**: confirm that `--exact-percentiles` applies to all four consumers uniformly per #187 Decision 7 (global scope).

## Related issues

- **#187** — owns the locked unified contract. Authoritative reference for all behavior. Spec at `features/187-histogram-bin-counter-percentiles.md`; industry grounding at `features/187-histogram-industry-grounding.md`.
- **#189** — implements the unified primitives that this feature consumes. Spec at `features/189-histogram-bin-counter-primitives.md`.
- **#51** — Phase 4 highlight-subset consumer migration. Coordinates with this feature insofar as `_hl` variant data structures (`%heatmap_raw_hl`, `%histogram_values_hl`) are touched.
- **#41** — heatmap-histogram alignment. Largely satisfied by #187+#189; both consumers run the same primitive contract at the same precision.
- **#179** — index read-back (closed); no longer load-bearing for partition sizing under the auto-resize lifecycle.
- **#23 Phase 2 (#59)** — core engine rewrite; this feature's migration composes with whatever pipeline architecture #23 produces.
- **#180** — named pipeline stages.
- **#46** — index file (closed).

## Spec stability

The contract surface (R1-R12) tracks #187's locked unified contract. Changes to the locked contract in #187 cascade to this feature's requirements; this feature does not lock decisions independently of #187.

The **Code sites affected by the migration** section is the technical inventory at the time of writing. Line numbers may shift; subroutine names and global-variable identifiers are the stable anchors.
