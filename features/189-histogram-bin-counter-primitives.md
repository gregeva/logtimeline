# Feature: Unified histogram bin-counter primitives for heatmap, histogram, and percentile consumers

## Overview

This feature implements the **unified primitive contract** locked in #187 (`features/187-histogram-bin-counter-percentiles.md`). The primitives are the helpers and data structures that every percentile-and-histogram consumer in ltl uses to build bin partitions, assign values to bins, increment counters, and interpolate percentile values. #187 produced the architectural research and locked the contract; #189 is the implementation ticket that turns the contract into runnable Perl code.

The primitives serve every consumer catalogued in #187 R12:

| `-V` consumer name | Purpose | Locked in #187 Decision 8 |
|---|---|---|
| `summary_table` | Per-message latency percentiles for the summary table | ✓ |
| `csv_output` | Same percentiles via `-o` CSV writer | ✓ |
| `time_bucket_stats` | Per-time-bucket duration percentile statistics row | ✓ |
| `heatmap_markers` | P50/P95/P99/P99.9 column-position markers on heatmap rows | ✓ |
| `heatmap_cells` | Heatmap cell colors themselves | ✓ |
| `histogram_view` | Histogram-mode global percentile indicators | ✓ |
| `histogram_bins` | Histogram-mode bin counts (bar heights) | ✓ |
| Future highlight-subset consumer | Per-`(time_bucket, highlight_subset)` percentiles | Phase 4 |
| Any future percentile-or-histogram consumer | Inherits the contract by construction | Phase 5 |

The primitives support **independent partitions per consumer** (heatmap, histogram, per-message, per-time-bucket all hold their own partitions) while sharing partition-computation, bin-assignment, counter-update, and percentile-interpolation logic. The contract is what's the same; the keying and rendering are what consumers choose.

Consumer-side statistics demand: which statistic groups the message-stats and bucket-stats consumers actually compute and store — including whether the Welford-Pébay moment sidecars are maintained at all — is governed by the statistics-group demand registry; see `features/305-shape-moment-extended-percentile-demand.md`.

## GitHub Issue

[#189](https://github.com/gregeva/logtimeline/issues/189)

## Motivation

Without unified primitives, every consumer ships divergent implementations of the same conceptual operations. Issues #34 (heatmap/histogram bin counters), #187 (percentile calculation), and future consumers each would either fork the partition/assignment/counter code (accumulating drift) or reimplement it (accumulating bugs). #189 prevents both by being the single home for the helper functions.

#187 produced the architectural research and locked the contract. #189 implements it. The two issues are bound together: #189 has no design discretion that is not already settled by #187's locked decisions; #189's role is to translate the contract into correct, efficient Perl code, validated empirically.

## Delivery sequence

This feature is one of three co-developed issues (#34, #187, #189), now joined by the per-consumer migration tickets that consume #189's primitives.

| Step | Work | Owner | Why this position |
|---|---|---|---|
| 1 | **Audit + Research** — catalogue every consumer (#187 R12), produce literature-grounded research, lock the unified primitive contract via the decision conversation | **#187** | Output is the unified contract in `features/187-histogram-bin-counter-percentiles.md` (D1, D2, D3 decision-support memo, all locked decisions). |
| 2 | **Prototype validation** (the five mandatory aspects from #187 Decision 10) | **#189 — this issue's first step** | Hard prerequisite for production code. Validates the locked architecture against real D2 data before committing to production implementation. See *Prototype validation* below. |
| 3 | **Implement unified primitives** per the locked contract | **#189 — this issue's production step** | Build R1 (partition with auto-resize), R2 (assignment), R3 (counter update with parameterized keying), R4 (percentile interpolation using the locked Prometheus formula), R5/R6 (overflow/underflow counters). |
| 4 | **Consumer migrations begin** — heatmap/histogram (owned by #34's implementation ticket); summary-table + CSV output (per-message migration ticket); etc. | **Each consumer's own implementation ticket** | Consumers replace their pre-migration code with #189-primitive calls per the locked contract. Each migration is the responsibility of the owning ticket; #189 does not ship migrations. |

### Parallelism

Steps 1 and 2 are sequential (the contract must be locked before the prototype is built). Step 3 (production implementation) is sequential after step 2 (Decision 10's hard-prerequisite rule). Step 4 (consumer migrations) gates on step 3 completing.

### Integration

All work lands on feature branches per CLAUDE.md's release process. Specific release-branch integration is the implementation ticket's call, not the contract's.

## Terminology

This feature uses the terminology locked in #187:

- **Unified primitive contract** — the set of locked decisions in `features/187-histogram-bin-counter-percentiles.md` (F1, D1, D1A, D2, D3, D4, D5, D7, D8, D10). #189 implements this contract.
- **Histogram bin counters** — the underlying data structure (log-spaced bin geometry, counter per bin, no retention of raw values).
- **Consumer** — a code path that needs percentile values or histogram bin counts. See R12 catalogue above.
- **Partition** — one instance of the bin counter structure with its own `[min, max]` boundaries, owned by one consumer for one keying dimension.
- **Auto-resize** — the partition lifecycle locked in #187 Decision 5.

#189 introduces no new terminology beyond what #187 locked.

## Prototype validation (mandatory prerequisite per #187 Decision 10)

Before #189 begins production implementation of the primitives, **the locked architecture must be validated empirically through prototyping**. Per #187 Decision 10, the five mandatory validation aspects are:

1. **In-bin interpolation formula behavior on real data.** Exercise the locked Prometheus formula (`returned_value = exp(log(lower) + (log(upper) − log(lower)) · fraction)`) against representative D2 log files. Validate that the Perl implementation matches the math and that the accuracy contract holds on real distributions. Cover edge cases (single-bin partitions, `bin_count = 1`, `lower = upper`).

2. **Auto-resize partition lifecycle on per-key fan-out at scale.** Exercise the HdrHistogram-style auto-resize behavior with realistic per-`(category, log_key)` fan-out (tens to hundreds of thousands of partitions). Measure rebin event counts per partition, per-key memory consumption, total counter-store memory, and confirm that actual memory matches the projected ~212 MB at 10⁵ keys at locked default 53 bpd. Validate that the amortized O(N) rebin cost claim holds on real per-key value-range distributions. Closes #187 grounding-doc gap 8 (per-key fan-out unaddressed in literature).

3. **Initial partition seeding heuristic and overflow/underflow handling on edge-case data.** Validate the locked seed (partition opens at 5 decades centered on the first value seen) produces p99 rebin counts in the expected 0–2 range on real latency data. Construct pathological D2 inputs (extreme outliers, very narrow distributions, mixed scale regimes) and confirm the locked `out_of_range_bounded: high|low|none` audit field fires correctly per quantile and that R4 returns the correct boundary value.

4. **End-to-end `-V` output sample for downstream comparison.** Produce a real `=== BIN-COUNTER MODE ===` verbose output block (per #187 Decision 8's locked format) from the prototype running against real log files. Exercise enough scenarios (default precision, `--percentile-precision` override, `-pbpd` override, flag conflict, overflow audit firing, opt-out active) to cover the locked format surface.

5. **Calculation accuracy compared to the array-of-values approach currently in use.** Direct comparison between the prototype's unified-contract output and ltl's existing `calculate_statistics` retained-array sort-and-index approach (`ltl:5488`). For every required percentile per consumer (per #187 R3) across D2 datasets, confirm the unified output sits within the bin-resolution bound (per #187 R4) of today's exact output.

**Hard prerequisite contract** (locked in #187 Decision 10):
- #189 production implementation does not begin until all five aspects have been validated, results documented, and lessons identified.
- If prototype validation surfaces a result that contradicts a locked #187 decision (e.g., real-world rebin rates are pathologically high under the locked seed heuristic), a follow-up issue is filed against #187 to record the contract revision and re-lock the affected decision. #189 does not silently diverge from the contract.

**#189 owns**: where the prototype lives (e.g., `prototype/189-*.pl`), how it's structured (single script with `--scenario` subcommands, per-aspect scripts, etc.), how the results are documented, and whether the prototype code becomes the basis for production code or is discarded after lessons are extracted.

The `prototype/96-fuzzy-consolidation.pl` work is the precedent for this pattern. Issue #96 used a standalone prototype to validate algorithmic choices against real D2 data before its production consolidation code was written; lessons from the prototype shaped the production implementation directly. #189 follows the same pattern for #187's contract.

## Requirements

The requirements below define the **contract surface** that #189's primitive implementations must satisfy. Each requirement either restates a #187-locked decision (referenced explicitly) or specifies #189-internal contract surface for the primitives.

### R1 — Bin-partition primitive (lazy lifecycle per #187 Decision 5)

The bin-partition primitive constructs and manages a partition object. Per #187 Decision 5, the partition lifecycle is **HdrHistogram-style auto-resize**:

- Partition is constructed **lazily on first observation** for a given consumer-key pair. Construction is not invoked at start-of-run.
- Initial sizing: when the first value `v_0` for a partition is observed, the partition opens with `min` and `max` set to a default span centered geometrically on `v_0`. Per #187 Decision 5 implementation guidance: `min = v_0 / sqrt(10^decades_default)`, `max = v_0 · sqrt(10^decades_default)`, where `decades_default = 5` (matches ltl's existing heatmap/histogram convention).
- Bin count per partition: per #187 Decision 2, the resolved `buckets_per_decade` (default 53; tunable via `--percentile-precision 1..9` or `-pbpd N`) multiplied by the partition's decades. At locked default, a partition has ~265 bins.
- Boundary geometry: log-spaced, `boundary[i] = min · (max/min)^(i/B)` where B is the bin count. Same formula as the existing heatmap/histogram code (`ltl:4961-4966`).
- Rebin growth: when a subsequently-observed value falls outside `[min, max]`, the partition extends via **HdrHistogram-convention doubling**. Per #187 Decision 5 implementation guidance: if a value exceeds `max`, extend so the new `max` is at least `current_max · 10^(decades_default / 2)`; symmetric for values below `min`. Existing counts retain their indices (the boundary geometry is index-monotonic in the extension direction).

The primitive must:

- Accept the resolved `buckets_per_decade` value (locked per #187 Decision 2's source-annotated value: default, `-pbpd N`, or `--percentile-precision N`).
- Maintain the partition's `min`, `max`, and bin-count as observable state for the consumer.
- Track rebin events on the partition for the `-V` telemetry per #187 Decision 5 (see R9 below).
- Be deterministic: same observation sequence produces the same partition state.

### R2 — Bin-assignment primitive

The bin-assignment primitive, given `(partition, value)`, returns either:

- A bin index in `[0, num_buckets - 1]` for in-range values.
- An out-of-range sentinel (low or high) for values outside the partition's current `[min, max]`.

Out-of-range values trigger the rebin behavior (R1) — the partition extends so the value can be placed in an in-range bin. Out-of-range sentinels are only returned when the partition's current `[min, max]` is the result of an explicit decision not to extend further (an implementation-defined cap on partition growth, if any) — in that case, the value contributes to the overflow or underflow counter per #187 Decision 4 (see R6 below).

The primitive must:

- Produce the same bin index that the locked log-spaced boundary computation produces for any value inside `[min, max]`.
- Be efficient enough to invoke per-line in the parsing hot path. The exact algorithm (binary search, direct logarithmic computation) is implementation-defined.
- Be pure given a fixed partition state.

**Implementation guidance (non-binding) — closed-form is the recommended R2 algorithm.** Prototype evidence (PR #194; `prototype/189-bin-counter-primitives-validation-report.md` § V2 Part B) measured three R2 candidates against a 67 MB Tomcat file at 51,469 partitions: closed-form (`floor(B · log(v/min) / log(max/min))`), binary search over a stored boundary array, and linear search over the same array. Closed-form was 3.31× faster than linear, 2.46× faster than binary, with 4.75× lower memory (no boundary array stored per partition). V1 cross-checked all three against 857,480 real observations with zero disagreement on bin index. The recommended R2 implementation for #189 production is closed-form; binary and linear search remain conforming alternatives and the contract makes no exclusion.

**Implementation guidance (non-binding) — boundary materialization is on-demand, not stored.** The closed-form R2 implementation does not require a stored boundary array; `boundary[i] = min · (max/min)^(i/B)` can be computed on demand whenever R4 or rendering code needs a specific boundary value. The prototype measured that storing the array per partition adds ~4.75× memory at locked default bpd=53 (51,469 partitions: 117 MB closed-form vs. 555 MB with boundary arrays). For consumers running at Path A scale (10⁵+ partitions), the recommended implementation materializes boundaries inline at the call site rather than persistently per partition. Decision 2's memory projection (~212 MB at 10⁵ partitions) assumes the closed-form path; choosing a boundary-array-requiring R2 implementation invalidates that projection.

### R3 — Counter-update primitive (parameterized keying)

The counter-update primitive, given `(counter_store, key, bin_index_or_overflow_sentinel)`, increments the appropriate counter. The `key` shape is **parameterized per consumer**, supporting all keying shapes catalogued in #187 R12:

| Consumer (#187 Decision 8 locked name) | Key shape |
|---|---|
| `summary_table` | `(category, log_key)` |
| `csv_output` | shares with `summary_table` |
| `time_bucket_stats` | `time_bucket` |
| `heatmap_markers` | `time_bucket` |
| `heatmap_cells` | `time_bucket` |
| `histogram_view` | `()` (single global partition per metric) |
| `histogram_bins` | `()` (single global partition per metric) |
| Future highlight-subset | `(time_bucket, highlight_subset)` or analogous |

The primitive must:

- Not assume any specific key shape. Consumers define their key when they invoke R3.
- Maintain separate counters per key for in-range bin indices, plus the overflow and underflow counters per #187 Decision 4 (see R6).
- Allow the counter store for a key to be looked up, enumerated, and freed independently of other keys' stores (R8 lifecycle requirement).
- Lazily construct the partition for a new key on its first observation (R1 lifecycle).

The counter-store shape (hash of hashes, dense array, etc.) is implementation-defined. The contract is the operation, not the data structure.

### R4 — Percentile-interpolation primitive (locked formula per #187 Decision 1)

The percentile-interpolation primitive, given `(partition, counter_map_for_a_single_key, target_quantile)`, returns a value for that quantile using the **Prometheus native-exponential `HistogramQuantile` in-bucket interpolation formula** locked in #187 Decision 1.

The algorithm (locked verbatim in #187 Decision 1 against `promql/quantile.go` lines 331–353):

1. Compute `total_N = sum of counter map` (including the overflow and underflow counters per #187 Decision 4).
2. Compute `target_rank = ceil(target_quantile · total_N)`.
3. Walk the counter map (low to high: underflow, then in-range bins by index, then overflow) to locate the position containing `target_rank`.
4. If `target_rank` lies in the underflow counter, return `partition.boundary[0]` (per #187 Decision 4). If it lies in the overflow counter, return `partition.boundary[B]` (per #187 Decision 4). The audit-field value for this quantile is `low` or `high` respectively.
5. Otherwise compute `rank_in_bin = target_rank − (cumulative count up to but not including the located bin)` and `fraction = rank_in_bin / counter_map[located_bin]`.
6. Return `exp(log(lower) + (log(upper) − log(lower)) · fraction)` where `lower = partition.boundary[located_bin]` and `upper = partition.boundary[located_bin + 1]`. The audit-field value for this quantile is `none`.

The primitive must:

- Be deterministic.
- Compute correctly for any positive `bin_count` (including `bin_count = 1`, which yields `fraction = 1.0` and returns `upper` — matches HdrHistogram's per-bin convention).
- Support any quantile in `(0, 1)`. Consumers select which percentiles they emit per #187 R3 (e.g., `summary_table` emits P1, P50, P75, P90, P95, P99, P999; `histogram_view` emits the wider ten-value set).
- Report per-quantile `out_of_range_bounded: high | low | none` to the consumer alongside the returned value (so the consumer can populate the locked `-V` audit field per #187 Decision 8).

**Special cases from Prometheus source that do not apply to ltl** (recorded for completeness):
- ltl's substrate is positive-only duration data; no negative-bucket mirroring is needed.
- ltl's substrate is purely log-spaced; the custom-bucket / zero-spanning-bucket linear-interpolation fallback in `promql/quantile.go` does not apply.

### R5 — Determinism

All primitives are deterministic. For a given observation sequence and partition state, the partition object (R1), bin assignments (R2), counter updates (R3), and percentile values (R4) are identical across runs. No randomization is used in any primitive.

### R6 — Overflow and underflow counters (per #187 Decision 4)

Per #187 Decision 4, each partition maintains two extra counter slots beyond the in-range bins:

- **Underflow counter**: tallies values where `0 < value < partition.min` (positive values below the partition's current low boundary, where the partition's growth cap — if any — has not extended further).
- **Overflow counter**: tallies values where `value > partition.max` (values above the partition's current high boundary, where the partition's growth cap — if any — has not extended further).

Under #187 Decision 5's auto-resize lifecycle, overflow and underflow are expected to be rare in practice — the partition extends to contain observed values. The counters function as a safety net for extreme cases (e.g., a single outlier value beyond what the doubling-rebin extends to in a reasonable number of rebins).

The primitive must:

- Maintain the underflow and overflow counters per `(partition, key)` distinct from the in-range bin counters.
- Include both in `total_N` for R4's rank computation.
- Expose them to consumers for the per-consumer audit aggregates (`partitions_with_overflow_count`, `partitions_with_underflow_count` per #187 Decision 8).

**Audit semantics — per-quantile, not per-partition.** The `out_of_range_bounded` audit code is determined per-quantile by R4 at the moment of invocation, based on whether the target rank for that specific quantile lands in the underflow counter, an in-range bin, or the overflow counter. A partition with `partitions_with_overflow_count > 0` may still report `audit = none` for some quantiles (those whose target rank lands in an in-range bin). Per #187 Decision 4, the overflow/underflow counter's share of total N determines which quantiles fire: a quantile q lands in overflow only when `ceil(q · total_N) > (total_N − overflow_count)`; symmetric for underflow. The prototype's V3 (`prototype/189-bin-counter-primitives-validation-report.md` § V3) validated this empirically — a partition with overflow=3 in 1003 total observations reported `audit = none` at q=0.01 because the target rank landed in the in-range region. Consumer tests must not assert `audit = high` for every quantile of any partition where `overflow > 0`.

### R7 — Independence of partitions across consumers (and across keys within a consumer)

The primitives are designed so that each `(consumer, key)` pair holds its own partition object. Two consumers sharing the same metric but different keying shapes (e.g., `summary_table` keyed by `(category, log_key)` and `histogram_view` keyed by `()`) hold separate partitions even on the same underlying data. Within a consumer, two keys (e.g., two distinct `time_bucket` values for `heatmap_cells`) hold separate partitions.

This is a hard requirement, not an option:

- Heatmap and histogram have independently configured display widths (`-hmw`, `-hgw`) and therefore historically had different bin counts. Under the unified contract, both consumers run at the same locked `buckets_per_decade` (per #187 Decision 2), so their partition geometry is consistent — but they remain separate partitions because they have different keying.
- Per-key partitions in `summary_table` adapt independently to each log_key's value range.
- Per-time-bucket partitions in `heatmap_cells` adapt independently to each time bucket's value range.

The primitives impose no global registry of partitions.

### R8 — Memory lifecycle

The primitives expose a lifecycle that supports the consumer migration tickets' memory-management needs:

- A partition object persists for the consumer's lifetime (typically the run).
- Counter stores per key are independently freeable. The implementation tickets may free per-key counter stores after the data has been used (e.g., after a time bucket's row has been rendered).
- The R4 primitive does not retain state between invocations; it derives its result from inputs only.
- Composability with #23 Phase 2's named-stage memory model: counter stores can be freed at the `finalize` stage's per-bucket lifecycle point if/when that work lands.

Auto-resize (R1) reallocates the counter storage when the partition extends. The implementation may choose in-place reallocation or copy-on-resize; per #187 Decision 5 implementation guidance, in-place avoids per-rebin allocation churn.

### R9 — Telemetry surface for `-V` output (per #187 Decision 8)

The primitives expose telemetry signals that consumers populate into the locked `=== BIN-COUNTER MODE ===` `-V` section per #187 Decision 8. The primitives themselves do not produce `-V` output; they make the data available.

The primitives must expose:

- Per-partition `min`, `max`, `bin_count`, and counter-store memory footprint — for the `bin_count` and `state_budget_bytes` fields in `-V` per consumer block.
- Aggregate rebin event count per consumer (sum of rebin events across all partitions for that consumer) — for `total_rebin_events` field.
- Per-partition rebin-event-count distribution across the partition population — for `rebins_per_partition: p50=N p95=N p99=N max=N` field. Per #187 Decision 5, this distribution is the empirical-tuning surface for the seed heuristic.
- Per-partition high-water-mark bin count — for `max_partition_bins` field.
- Per-partition overflow and underflow counter values — for `partitions_with_overflow_count` and `partitions_with_underflow_count` aggregates.
- Per-quantile R4 return state (whether the value came from interpolation or from an overflow/underflow boundary) — for `out_of_range_bounded: high|low|none` per quantile.

#189 picks the exact data structures and API names that surface this telemetry; #187 Decision 8 locks the consumer-visible field names that consumers emit using this data.

### R10 — Pre-migration code path coexistence (per #187 R11 / R11a)

#189's primitives coexist with the pre-migration code paths during the phased rollout of consumer migrations. Specifically:

- A consumer that has not yet migrated continues to use its pre-migration code path (e.g., `calculate_statistics` at `ltl:5488` for `summary_table`); it does not invoke #189 primitives.
- A consumer that has migrated uses #189 primitives unconditionally for the unified path.
- A migrated consumer with `--exact-percentiles` opt-out (per #187 Decision 7) reverts to its pre-migration code path for that run.

This is per the consumer's discretion (not the primitive's): #189 does not implement a mode-switch within the primitives. The primitives run unconditionally when invoked by a migrated consumer on the unified path.

### R11 — Boundaries with other features

This feature owns the **primitive implementations** that satisfy #187's unified contract.

This feature does NOT own:

- The unified contract itself (locked decisions, R12 audit, consumer-name strings, `-V` format) — owned by **#187**. #189 implements; #187 specifies.
- Consumer migrations onto the primitives — each consumer's migration is owned by its **own implementation ticket** (e.g., the per-message migration for `summary_table` and `csv_output`; #34's implementation ticket for heatmap/histogram).
- Index read-back (#179, closed) — no longer load-bearing for partition sizing under the auto-resize lifecycle; see #187's Downstream implications for related issues for the relationship.
- Highlight subsets (#51) — Phase 4 consumer, owned by its own implementation ticket.
- Activation policy, default-on vs. default-off, release cadence, deprecation timing — implementation-ticket concerns per #187 Decision 9's dissolution.

The contract authoritative reference is `features/187-histogram-bin-counter-percentiles.md` § *Locked decisions from research*.

### R12 — Finalize re-bin wrapper for display-geometry-bound consumers (added 2026-05-20 via #201)

Added by investigation #201 to support F2 (heatmap) and F3 (histogram) consumer families per the per-family Decision 5 scope clarification.

#### Contract

`partition_rebin($src_partition, $src_bins, $new_min, $new_max, $new_bin_count)` — re-bin a source partition's counts into a target partition with explicit `[$new_min, $new_max]` and `$new_bin_count`. Returns the target partition object and its bins array (count vector of length `$new_bin_count`).

Algorithm: geometric-midpoint projection — for each source bin with positive count, compute its geometric midpoint via `sqrt(lower × upper)`, locate the target bin containing that midpoint via the standard closed-form bin assignment (`int(new_bin_count × log(mid / new_min) / log(new_max / new_min))`), and assign the source bin's count to that target bin in full. Source bins whose midpoint falls outside `[$new_min, $new_max]` are assigned to the nearest target end (or, if the consumer requires it, accumulated into separate overflow/underflow counters per #187 Decision 4).

#### Why a new wrapper instead of new primitive surface

`partition_extend` (R1 implementation, `ltl:586–631`) already implements geometric-midpoint projection in its remap loop at `ltl:613–622`. `partition_rebin` is the same loop extracted into a caller-driven wrapper that:

- Accepts arbitrary `[$new_min, $new_max]` and `$new_bin_count` (instead of computing them from doubling).
- Returns a freshly constructed target partition (instead of mutating the source).

The algorithm is identical; the difference is in *who* chooses the target geometry. `partition_extend` uses HdrHistogram-convention doubling; `partition_rebin` uses caller-supplied display geometry. **No new mathematical primitive surface.**

#### Composition pattern for F2/F3

```
# During parse: streaming auto-resize partition per consumer key.
# F2/F3 streaming bpd is locked at 616 (Level 9 per #187 Decision 2 tier
# table; HdrHistogram 3-significant-digit reference) — ONLY for F2 (heatmap)
# and F3 (histogram) because their partition counts are bounded (~70 total).
# F1 consumers (summary_table, csv_output, time_bucket_stats) MUST continue
# using Decision 2 default (bpd=53) — F1 has unbounded partition counts
# (one per (category, log_key)) and bpd=616 would multiply memory by ~12x
# per partition (gigabytes of overhead on typical workloads).
counter_update(\%store, $key, $value);   # R1 + R2 + R3

# At end-of-parse: finalize re-bin into target partition.
my $entry = $store{$key};
my ($finalized_p, $finalized_bins) = partition_rebin(
    $entry->{partition},
    $entry->{bins},
    $d_min, $d_max,
    $target_bin_count,   # F2: $heatmap_width
                         # F3: int(decades * histogram_buckets_per_decade)
);
# $finalized_p has bin_count = $target_bin_count, boundaries log-spaced over
# [d_min, d_max]. $finalized_bins is the count vector. Underflow and overflow
# from the streaming partition can be folded into $finalized_bins[0] and
# [$target_bin_count - 1] respectively, or kept separate per consumer choice.

# Display rendering:
#   F2: read $finalized_bins directly (partition geometry IS display geometry).
#   F3: apply calculate_histogram_display_buckets($finalized_bins, $bar_area_width)
#       unchanged. The shipped stretched-bar projection at ltl:7462 handles
#       the partition->display step.
```

#### Invariants preserved

- **Mass conservation.** Sum of counts in `$finalized_bins` equals sum of counts in `$src_bins` plus optional source-side overflow/underflow folded in. Empirically validated on canonical Tomcat datasets via V6/V7/V8 in `prototype/189-bin-counter-primitives.pl`.
- **Peak preservation.** A spike entirely contained within one source bin lands entirely in one target bin (the one containing the source bin's midpoint). Empirically validated at 100% peak retention.
- **Per-bucket displacement bounded below visibility threshold at streaming bpd=616.** V8 sweep results on canonical datasets show worst-case visible-bucket displacement of 1.10% (your file) and 5.78% (148MB file) — both well below the ~11% per-character-row threshold of a 9-character-tall ASCII histogram. See `prototype/201-projection-comparison-report.md` for the full sweep across all 9 locked tier values and both geometric-midpoint and proportional-overlap algorithms.
- **Determinism.** Geometric-midpoint projection is deterministic in the source partition and target geometry.

#### Source basis

- The remap loop at `ltl:613–622` and its lineage to HdrHistogram's `AbstractHistogram.java` resize path.
- Empirical fidelity validation at `prototype/201-projection-comparison-report.md` (V6/V7 initial aggregate measurements, V8 per-column comparison and bpd sweep).
- Architectural rationale at `features/201-display-geometry-bound-consumers.md` § Recommendation.

#### Implementation note

`partition_rebin` can be a thin function or inlined at F2/F3 consumer call sites. Whether to expose it as a callable subroutine or as a documented pattern is an implementation choice for the production ticket. The behavior described above is the contract; the API shape is open.

#### Boundary with R1's auto-resize

R1's auto-resize lifecycle is **unchanged** by R12. F1 consumers (`summary_table`, `csv_output`, `time_bucket_stats`) continue to use the auto-resize lifecycle without a finalize re-bin step — bins are internal precision, never rendered as display columns, so display geometry is irrelevant for F1.

R12 applies only to F2 and F3 consumers per the Decision 5 per-family scope clarification.

## Consumer-side requirements (per #187 R12)

This section enumerates what each consumer of #189's primitives needs. The consumer-name strings (`summary_table`, `csv_output`, `time_bucket_stats`, `heatmap_markers`, `heatmap_cells`, `histogram_view`, `histogram_bins`) and the consumer catalogue are locked in #187 R12 and #187 Decision 8. The mapping between consumer names and ltl call sites lives in the **Audit findings** section below.

All consumers consume **R1–R4 of #189 plus R6 (overflow/underflow counters)** uniformly per the unified contract. Differences between consumers are in keying (R3) and percentile-set selection (R4), not in algorithmic behavior.

### Universal needs across all consumers

- **R1 (partition with auto-resize)**: partitions are lazily constructed on first observation and adapt via doubling-rebin. Initial seed: 5 decades centered on the first observed value (per #187 Decision 5).
- **R2 (bin assignment)**: efficient enough for per-line invocation in the parsing hot path. Linear search (`find_heatmap_bucket` at `ltl:4783`) and binary search (`find_histogram_bucket_index` at `ltl:4890`) both demonstrate adequate performance; #189 picks one.
- **R3 (counter update with consumer-specific keying)**: see per-consumer keying table below.
- **R4 (percentile interpolation per the locked Prometheus formula)**: returns numeric value plus the `out_of_range_bounded: high|low|none` audit value per quantile.
- **R6 (overflow/underflow counters)**: separate counters per partition; both contribute to `total_N`; when target rank lands in either, R4 returns the corresponding boundary.

### Per-consumer keying and percentile sets

| Consumer (#187 Decision 8 name) | R3 keying | R4 percentiles emitted | Notes |
|---|---|---|---|
| `summary_table` | `(category, log_key)` | P1, P50, P75, P90, P95, P99, P999 | Path A in #187 R12; per-key partition fan-out scenario (gap 8 in industry literature). |
| `csv_output` | shares `summary_table`'s partitions | same as `summary_table` | Path A' in #187 R12; downstream renderer of the same `%log_stats` values. R3's `shares_partitions_with: summary_table` mechanism. |
| `time_bucket_stats` | `time_bucket` | P1, P50, P75, P90, P95, P99, P999 | Path B in #187 R12; per-bucket partition (one per time bucket). |
| `heatmap_markers` | `time_bucket` | P50, P95, P99, P999 | Path C2 in #187 R12; R4 returns numeric value, consumer maps to display column via R2 for storage in `%heatmap_percentiles`. May share `time_bucket_stats` partitions per R7. |
| `heatmap_cells` | `time_bucket` | (no percentiles; bin counts only via R3 enumeration) | Path C2-cells in #187 R12; per-bucket partition, re-projected onto display columns at render time. |
| `histogram_view` | `()` (single global partition per metric) | P1, P10, P25, P50, P75, P90, P95, P99, P999, P9999 (widest set) | Path C1 in #187 R12; ten-value percentile set is the widest #189 R4 must support. |
| `histogram_bins` | `()` (single global partition per metric) | (no percentiles; bin counts only via R3 enumeration) | Path C1-bins in #187 R12; same partition as `histogram_view` (consumer-shared). |

### Migration targets (informational; owned by per-consumer migration tickets)

The pre-migration code paths each consumer migrates from are catalogued for context only. The migrations themselves are owned by the per-consumer implementation tickets, not by #189.

- `summary_table` and `csv_output`: replace `log_messages{$category}{$log_key}{durations}` raw arrays (`ltl:4591`) and `calculate_statistics` sort-and-index (`ltl:5488`) with #189-primitive calls.
- `time_bucket_stats`: replace `log_analysis{$bucket}{durations}` raw arrays (`ltl:4634`, gated `unless $heatmap_enabled`) with #189-primitive calls.
- `heatmap_markers` and `heatmap_cells`: replace `%heatmap_raw` accumulation and end-of-parse binning in `calculate_heatmap_buckets` (`ltl:4791-4865`) with #189-primitive calls.
- `histogram_view` and `histogram_bins`: replace `histogram_values{$metric}` raw arrays and end-of-parse binning in `calculate_histogram_buckets` (`ltl:4908`) with #189-primitive calls.

## Audit findings — technical inventory of `ltl` call sites

This section is the line-precise technical inventory underlying #187's R12 consumer audit. Where #187 R12 catalogues the *consumers* and their migration targets, this section catalogues the *specific helper functions, data structures, and call sites* in `ltl` that each consumer's migration must replace or interact with.

All `ltl:line` references are against `release/0.14.5` HEAD at the time the audit landed. Subsequent refactors may shift line numbers; the subroutine names and global-variable identifiers are the stable anchors.

The audit catalogue below uses the original Path-A/B/C terminology from earlier work (e.g., "Heatmap consumer", "Histogram consumer", "Summary-table per-message latency percentile consumer"). The mapping to #187 Decision 8's locked `-V` consumer-name strings is:

| Audit-section heading | `-V` consumer-name string (locked in #187 Decision 8) |
|---|---|
| Heatmap consumer (cells) | `heatmap_cells` |
| Heatmap consumer (percentile markers) | `heatmap_markers` |
| Histogram consumer (bin counts) | `histogram_bins` |
| Histogram consumer (global percentile indicators) | `histogram_view` |
| Summary-table per-message latency percentile consumer | `summary_table` |
| Summary-table per-message latency percentile consumer (CSV output) | `csv_output` (shares partitions with `summary_table`) |
| Per-time-bucket duration percentile consumer | `time_bucket_stats` |

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

Heatmap data structures declared at `ltl:246–260`: `$heatmap_metric`, `$heatmap_width`, `%heatmap_data`, `%heatmap_data_hl`, `%heatmap_raw`, `%heatmap_raw_hl`, `@heatmap_boundaries`, `$heatmap_min`, `$heatmap_max`, `$heatmap_max_density`, `%heatmap_percentiles`.

**Constraints discovered (heatmap):**

- **Partition is global, not per-metric.** `@heatmap_boundaries` is a single array because heatmap renders one metric per run (selected by `-hm <metric>`). The R1 primitive must support a partition that is owned by the consumer; #189 does not impose a per-metric registry.
- **Bucket count is CLI-driven.** `$heatmap_width` (default 52, `-hmw`-tunable). Source is consumer-owned (R7).
- **Counter key is `time_bucket`.** Per-time-bucket counter freeing is in scope for #187 Phase 3.
- **Out-of-range handling today is silent clamp.** `find_heatmap_bucket` (`ltl:4783`) returns no out-of-range index; values above the max boundary fall through the loop and the caller's fallback applies last bin. The R2 contract introduces explicit sentinels — new behavior, not a refactor.
- **Partition-computation timing must move from end-of-pass to start-of-pass when histogram bin-counter mode is eligible.** Today `calculate_heatmap_buckets` runs at `ltl:8283` after the read pass. Under bin-counter mode, partition must exist before line-by-line accumulation begins so `find_heatmap_bucket` (or its R2 equivalent) can be called per line.
- **Empirical percentile markers depend on the raw-value array.** `%heatmap_percentiles{$bucket}` (populated `ltl:4829–4834`) is derived by sorting `%heatmap_raw{$bucket}` and indexing P50/P95/P99/P99.9 — then mapped through `find_heatmap_bucket` to bin indices for rendering. Under bin-counter mode, the raw array is not allocated; markers are derived from #189 R4 against the bin counters, with the numeric return value mapped back to a bin index via R2 for storage. See **Resolution — percentile markers and indicators under bin-counter mode** below.

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

Histogram data structures declared at `ltl:285–331`: `$histogram_buckets_per_decade` (default 8), `$histogram_bucket_override`, `%histogram_values`, `%histogram_values_hl`, `%histogram_boundaries`, `%histogram_buckets`, `%histogram_buckets_hl`, `%histogram_stats`, `%histogram_stats_hl`. Option globals declared during parse: `$histogram_enabled`, `%histogram_metrics`, `$histogram_width_percent`, `$histogram_width_explicit`, `$histogram_height`, `$histogram_height_explicit`.

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

#### Heatmap percentile-marker consumer

| Site | `ltl` location | What it does today (raw-value mode) | Under bin-counter mode | Reads / writes | Key shape |
|---|---|---|---|---|---|
| Inside `calculate_heatmap_buckets` | `ltl:4818, 4823–4834` | Sorts `%heatmap_raw{$bucket}`, derives P50/P95/P99/P99.9 values via index lookup, maps each value to a bin index via `find_heatmap_bucket`, stores in `%heatmap_percentiles{$bucket}` as bin indices. | At end of pass, per time bucket: invoke #189 R4 against `%heatmap_data{$bucket}` for each quantile. Map R4's numeric return value to a bin index via R2 (or equivalent). Store in `%heatmap_percentiles{$bucket}` as bin indices (unchanged shape). | Reads `%heatmap_data` (bin-counter mode) or `%heatmap_raw` (raw-value mode). Writes `%heatmap_percentiles`. | `time_bucket` |
| Consumer | `ltl:6378–6432` (`print_heatmap_row`) | Overlays `|` markers at the recorded bin indices for each rendered row. Unchanged. | Unchanged. | Reads `%heatmap_percentiles`. | — |

**Resolution — percentile markers and indicators under bin-counter mode**

The R12 audit originally recorded this as an open question with three conceivable resolutions (markers move to R4; markers are dropped; a separate streaming sketch). Further investigation surfaced a symmetric concern for the histogram consumer (legend values, x-axis tick positioning — both depend on `%histogram_stats{$metric}{p*}`, which is sort-derived from `%histogram_values{$metric}` under raw-value mode and has no source under bin-counter mode).

**Decision (recorded in #34 R4-bis and #34 § Resolution):** Both consumers — heatmap percentile markers and histogram percentile indicators — derive from #189 R4 at end of pass under bin-counter mode.

- **Heatmap markers**: R4 returns a numeric value; consumer maps to bin index via R2 for storage in `%heatmap_percentiles`. (A cumulative-count walk over the bin counters would also satisfy heatmap's needs alone, but the symmetric histogram case requires R4's numeric value, so unifying both consumers on R4 was preferred to a split implementation.)
- **Histogram indicators**: R4 returns a numeric value; stored directly in `%histogram_stats{$metric}{p*}` for downstream legend rendering (`select_histogram_percentiles`, `ltl:7375`) and x-axis tick positioning (`calculate_histogram_percentile_ticks`, `ltl:7430`).

Alternatives rejected:

- Drop markers/indicators under bin-counter mode → breaks #34 R8 (render equivalence).
- Keep `%histogram_values` allocated under bin-counter mode purely for the histogram legend → defeats most of the memory win.
- Maintain a separate streaming sketch (e.g., t-digest) alongside the bin counters → adds a new primitive contract; in tension with #189's harmonization goal.

Delivery consequence: **#34 step 4 (implementation) now gates on #189 R1–R4**, not R1–R3. The original "ship R1–R3 first, ship R4 later" two-phase split is dropped in favor of a single converged delivery. See updated Delivery sequence table and Parallelism section above; see #34 R8 amendment (within-accuracy-bound render equivalence) for the matching consumer-side update.

This resolution is reflected in:
- R4 (Percentile-interpolation primitive) consumer table above — #34's heatmap markers and histogram indicators are first-class R4 consumers.
- Consumer-side requirements § From #34 (Need #7) above.
- Cross-cutting compatibility constraints below (no separate "open question" entry; the resolution is folded into the primitive contract).

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
| First value for a new `(consumer, key)` is observed | R1 lazily constructs the partition; partition opens with `min = v_0 / sqrt(10^5)` and `max = v_0 · sqrt(10^5)` per #187 Decision 5 implementation guidance. |
| A subsequent value falls outside the current `[min, max]` | R1 extends the partition via HdrHistogram-convention doubling. Counts in existing bins retain their indices. Counted as a rebin event in R9 telemetry. |
| A value falls outside the partition after doubling-rebin cap (if implementation imposes one) | R2 returns the appropriate overflow or underflow sentinel; R3 increments the corresponding R6 counter. R4 returns the partition boundary per #187 Decision 4 when target rank lands in this counter. |
| Bin assignment for a value exactly equal to a boundary | R2 returns a deterministic bin index using the locked log-spaced boundary computation. The choice (lower or upper bin) is documented and consistent. |
| Counter update for a key never seen before | R3 lazily initializes the counter store for that key, invoking R1 to construct the partition from the first value. |
| Counter store free for a key while another key is still active | Independent per R8; freeing one does not affect another. |
| R4 invoked on a counter map with zero total count | R4 returns a defined "no values" indicator that the consumer maps to `-`. (Per #187 R5; should not be reached in practice because consumers check for empty data before invoking R4.) |
| R4 invoked on a counter map with a single non-zero bin | The cumulative walk locates the single bin; `fraction = 1.0` (rank-in-bin = bin_count); the formula returns `upper`. Same result regardless of quantile. |
| R4 invoked with `bin_count = 1` at the target rank | Standard formula: `fraction = 1.0`, returns `upper`. Matches HdrHistogram's per-bin convention (locked Decision 1). |
| Concurrent partition state queries from rendering driver | R9 telemetry is consistent: rendering drivers see the partition state as of the moment they query it. No locking needed (single-threaded). |

## Acceptance criteria

### Prototype phase (#187 Decision 10 hard prerequisite)

- [ ] All five mandatory validation aspects from #187 Decision 10 are exercised against representative D2 datasets.
- [ ] Results documented per #187 Decision 10's implementation guidance.
- [ ] Lessons identified for #189's production implementation.
- [ ] If any locked #187 decision is contradicted by prototype results, a follow-up issue is filed against #187 before #189 production work begins.

### Production implementation phase

- [ ] R1–R11 hold.
- [ ] All primitive behavior matches the locked #187 contract: Decision 1's formula in R4; Decision 5's auto-resize lifecycle in R1; Decision 4's overflow/underflow handling in R6; Decision 2's resolved `buckets_per_decade` value drives R1's bin count.
- [ ] The R9 telemetry surface provides every data point that #187 Decision 8 requires consumers to surface in `=== BIN-COUNTER MODE ===` output.
- [ ] Primitive-level unit tests cover R1–R6 (see Validation below).
- [ ] Cross-consumer composition tests demonstrate that R7 (partition independence) and R8 (lifecycle independence) hold when multiple consumers exercise the primitives simultaneously.
- [ ] Per-consumer migration tickets can consume the primitives without forking, duplicating, or extending them beyond their locked contract.

## Validation

### Prototype validation

Per the *Prototype validation* section above (#187 Decision 10's hard prerequisite). The prototype validates the locked architecture against real D2 data; its output informs production implementation design.

### Primitive-level unit tests

Each primitive has unit tests covering:

- **R1**: partitions construct correctly on first observation; subsequent values extend via doubling-rebin; existing counts preserved through rebin; rebin events tallied in R9 telemetry.
- **R2**: bin assignments match the locked log-spaced boundary computation; boundary-equal values are assigned consistently; out-of-range sentinels are returned when the partition's growth cap is reached.
- **R3**: counter stores are correctly keyed across all #187 R12 keying shapes (per-`(category, log_key)`, per-`time_bucket`, `()` global, future compound shapes); per-key independence is verified.
- **R4**: interpolated values match the locked Prometheus formula (Decision 1) for canonical inputs; the `out_of_range_bounded: high|low|none` audit value is correctly reported per quantile; `bin_count = 1` and single-bin edge cases produce the expected `upper` result.
- **R5**: identical observation sequences produce identical primitive state across runs.
- **R6**: overflow and underflow counters are correctly maintained and contribute to `total_N`; R4 returns the correct boundary when target rank lands in either.

### Consumer-level integration tests

The primitives are exercised through the per-consumer migration tickets' test suites. Passing those suites is the primary verification that the primitives behave correctly in production-shaped usage. R10 (pre-migration code path coexistence) is verified at this layer.

### Cross-consumer composition tests

Tests that exercise multiple consumers sharing primitives in the same run (e.g., `summary_table` keyed by `(category, log_key)` alongside `heatmap_cells` keyed by `time_bucket`) verify that consumer independence (R7) and lifecycle independence (R8) hold under composition.

## Related issues

- **#187** — owns the locked unified contract. Authoritative reference for all primitive behavior. #189 implements; #187 specifies.
- **#34** — implementation ticket for heatmap and histogram consumer migrations (`heatmap_cells`, `heatmap_markers`, `histogram_view`, `histogram_bins`); consumes #189's primitives.
- **#51** — future Phase 4 highlight-subset consumer.
- **#41** — heatmap-histogram alignment; relationship to #189 captured in #187's Downstream implications section.
- **#179** — index read-back (closed); no longer load-bearing for partition sizing under Decision 5's auto-resize lifecycle.
- **#23 Phase 2 (#59)** — may adopt this feature's memory lifecycle model.
- **#180** — named pipeline stages.
- **#46** — index file (closed).

## Spec stability

The primitive contract (R1–R11) tracks the locked #187 unified contract. Changes to the locked contract in #187 cascade to #189's requirements; #189 does not lock decisions independently of #187. If prototype validation surfaces a need to revise a locked #187 decision, the revision is recorded in #187 first, then propagated to #189.

The **Audit findings** section is the technical inventory of ltl call sites at the time of writing. Line numbers may shift with subsequent refactors; subroutine names and global-variable identifiers are the stable anchors. Adding a consumer to R12 (in #187) is not a contract change for #189; the parameterization in R3 already accommodates new keying shapes.

## Investigation — dynamic bins-per-decade by message occurrence count (#323)

**Question investigated**: should the per-message bin-counter partition (`summary_table` consumer, `%log_messages_counters`) use a smaller bins-per-decade (BPD) for messages with few observations and the full BPD only for messages with many, on the premise that sparse messages waste memory on empty bins?

**Recommendation: do not implement.** The skew premise is confirmed and extreme, but the memory motivation does not hold — sparse partitions are already cheap under the shipped sparse-array representation, so dynamic BPD saves little while adding a per-occurrence-count tiering surface and (for post-collection tiering) a rebin pass. The fidelity intuition is correct but yields no observable benefit at sparse N.

### Grounding

All measurements from `-mdm bin -V` (and a BPD tier sweep via `--data-model-precision`) on a 112 MB high-cardinality Tomcat access log with the default (no fuzzy consolidation) grouping. The `summary_table` partition store held 21,103 partitions.

**Occurrence-count distribution (the skew):**

| occurrences | # messages | % of messages | % of all samples |
|---|---|---|---|
| 1 | 48,826 | 95.2% | 9.4% |
| 2–5 | 1,051 | 2.0% | 0.6% |
| 6–20 | 788 | 1.5% | 1.7% |
| 21–100 | 381 | 0.7% | 3.4% |
| 101–1000 | 151 | 0.3% | 6.7% |
| 1001+ | 102 | 0.2% | 78.3% |

95.2% of messages occur exactly once; 97.2% occur ≤5 times yet carry ~10% of samples; the top 0.2% carry 78.3%. Median occurrence count = 1. The skew is a power law and is stronger than the issue hypothesized.

**Counter-store memory vs. BPD (tier sweep, same 21,103 partitions):**

| precision tier | BPD | `counter_memory_bytes` | total max memory |
|---|---|---|---|
| 1 | 4 | 28.4 MB | 142 MB |
| 5 (default) | 53 | 52.8 MB | 175 MB |
| 9 | 616 | 324.6 MB | 471 MB |

Least-squares fit over the sweep: `counter_memory ≈ 26.9 MB + 483 KB × bpd`, i.e. a fixed **~1,274 bytes/partition** (BPD-independent) plus ~22.9 bytes/partition per unit BPD.

### Why dynamic BPD does not pay off

The per-partition memory cost is driven by **populated bins, not `bin_count`.** A single-occurrence partition stores exactly one populated bin in a sparse Perl array; its footprint is essentially the same at BPD 4 or BPD 53 (only the `bin_count` scalar differs). The BPD-driven growth in the sweep comes almost entirely from the dense 0.2% of partitions that legitimately populate hundreds of bins — precisely the partitions #323 would *keep* at full BPD.

Consequently, the fixed ~1.3 KB/partition term dominates the sparse tail's cost, and that term is BPD-independent. Lowering the sparse 95% from BPD 53 to BPD 4 removes only their small share of the ~22.9 bytes/partition/BPD marginal term, not the dominant fixed overhead. The achievable saving is far below a naïve "95% × 52.8 MB" estimate.

### Answers to the issue's investigation questions

1. **Thresholds** — moot given the recommendation; the distribution would support tiers (e.g. 1, 2–20, 21+) if pursued, but see the memory finding.
2. **Timing of the decision** — BPD is baked into the partition at `partition_new` on the **first observation**, before occurrence count is known. Choosing BPD by occurrence count is therefore inherently an end-of-parse decision.
3. **Rebinning cost** — `partition_rebin` already re-projects a populated partition into a caller-chosen geometry, so a post-collection down-tier is mechanically available. But rebinning a sparse partition *down* saves negligible memory (one populated bin either way) while costing CPU per partition across the 95% tail — net-negative.
4. **Memory impact** — quantified above: the sparse tail is already cheap; the BPD lever does not target the fixed per-partition overhead that dominates it.
5. **Output fidelity** — a message with ≤5 samples populates ≤5 bins regardless of BPD; percentiles over so few points have low inherent precision and are unaffected by reduced BPD. Reduced BPD on sparse messages is safe — and, per (4), nearly free of benefit.
6. **Implementation shape** — would require either per-partition BPD chosen at first observation (impossible: count unknown) or an end-of-parse rebin tier pass over `%log_messages_counters`. The existing structures accommodate the latter, but (3)/(4) make it not worthwhile.

### Surfaced adjacent findings

- **Filed as #346** — `-mem` omits `%log_messages_counters` from its measurement map, undercounting reported memory by the full counter-store size (~53 MB here) under `-mdm bin`. Discovered while grounding this investigation.
- **The real sparse-tail lever is the fixed ~1.3 KB/partition overhead** (partition hash, metadata, `"\x1f"`-joined string keys × 21,103 partitions ≈ 27 MB), not BPD. A leaner per-partition representation would beat dynamic BPD on the sparse tail. Recorded here as a candidate direction, not a committed one.
- **`log_messages` raw sidecar (~30 MB) is the larger memory ceiling** and is BPD-independent — separate territory from the bin-counter store.

## Investigation (second direction) — raw-first, promote-to-histogram under memory pressure (#323)

**Status: IN PROGRESS — production-scale measurement done; several earlier hypotheses OVERTURNED.** A real large-log run (below) replaced the synthetic projections. The headline correction: the earlier "~90–95% raw-first win" was built on a raw-cost model that the measured data shows was **~13× too optimistic**, and a true like-for-like (`-mdm bin` vs `-mdm raw`) shows the shipped **bin model uses *more* message-stats memory than raw** at production scale, not less. The real lever is narrower and better-targeted than first thought: promotion only helps the tiny high-occurrence head; the singleton body needs raw representation, not partitions. Measured evidence and the corrected conclusions are below.

### Question investigated

Instead of allocating a histogram bin-counter partition on a message's *first* observation, start each message as a **raw array of observed values** (exact, lossless) and convert to a partition only under memory pressure. Does this beat the shipped all-partition model on memory, and at what fidelity cost?

### What is established (measured, stands)

Per-representation costs measured with `Devel::Size::total_size` on Homebrew Perl 5.42, entry shapes faithful to `ltl`'s streaming `counter_update` write path (sparse `bins` array extended only to the highest assigned index; `partition_new` seeded 5 decades, BPD 53):

| representation | N=1 | N=20 | N≈88 | marginal / extra value |
|---|---|---|---|---|
| partition entry `{partition,bins,overflow,underflow}` | 2,524 B | 3,452 B | ~2,884 B (clustered) | — |
| raw bare arrayref `[v, …]` | 96 B | 704 B | ~2,624 B | **32 B** |

- **Single-occurrence partition floor ≈ 2,524 B**, of which 1,152 B is a `bins` array pre-extended to ~133 slots (a lone value lands at the geometric centre, bin ~132 of 265). This cross-checks the first direction's anchor three ways (52.8 MB ÷ 21,103 = 2,502 B; measured 2,524 B; LSQ `1,274 + 22.9×53` = 2,488 B). The "~1.3 KB" first-direction headline is the BPD-*independent* intercept; the real floor at BPD 53 is ~2.5 KB.
- **Memory crossover ≈ N=88** (with realistically clustered per-message latencies): below it a raw array is *both smaller and exact*; above it the partition is the cheaper container.
- **Fidelity ordering is unconditional**: for every percentile ltl reports, nearest-rank over the raw values is exact and a partition only ever approximates. A histogram is *never* more faithful than the raw data — its only justification is memory. (Separately, ltl's own sample-size rule notes high-nines are statistically meaningless below ~10/(1−q) samples regardless of representation; that is neutral to the raw-vs-partition choice, not an argument for promoting.)
- **Promotion replay is cheap** (~4–27 µs per promoted message; it *defers* bin-assign work rather than adding it) and a code inventory found **five consumers** that would need entry-kind branching if the store became heterogeneous (percentile path, `-V` telemetry snapshot, three fuzzy-consolidation merge subs), plus two uniform pass-throughs. These are structural facts about the code, independent of the memory question.

### Production-scale measurement (the real test)

Instrument: `ltl -mdm bin|raw -mem -V -o -n 2000000 --disable-progress`, one ThingWorx access-log node (30 files, ~8M lines, ~1.6 GB), same input for both models, `caffeinate`-wrapped. Enabled by #346 (which put `%log_messages_counters` in the `-mem` map). Both runs deterministic (identical `counter_memory_bytes`, `partition_count` across repeats).

**Occurrence-count distribution (measured, ltl's own grouping — 600,345 distinct messages, 7.35M samples):**

| occurrences | # msgs | % msgs | % samples |
|---|---|---|---|
| **1** | **580,237** | **96.7%** | 7.9% |
| 2–5 | 8,387 | 1.4% | 0.3% |
| 6–20 | 6,298 | 1.0% | 0.9% |
| 21–100 | 3,902 | 0.6% | 2.3% |
| 101–1000 | 1,106 | 0.2% | 4.0% |
| 1001–10000 | 222 | 0.0% | 7.3% |
| 10001–100000 | 182 | 0.0% | 55.1% |
| 100001+ | 11 | 0.0% | 22.1% |

96.7% of messages occur exactly once; 99.1% ≤5 times. Just **193 messages** (>10k occurrences) carry **77% of all samples**; the hottest single message has **197,293** occurrences.

**Like-for-like memory, `-mdm bin` vs `-mdm raw` (measured, same node, `-n 2000000`):**

| structure | `-mdm bin` | `-mdm raw` |
|---|---|---|
| `log_messages` | 4.22 GB | 4.63 GB |
| `log_messages_counters` | 2.96 GB | 0 |
| **message-stats total** | **7.17 GB** | **4.63 GB** |
| peak RSS | 8.64 GB | 5.45 GB |

### What the measurement overturned

1. **The "~90–95% raw-first win" was wrong — the raw-cost model was ~13× too optimistic.** The synthetic model assumed a raw entry ≈ a bare arrayref of doubles (`64 + 32·N`). The real `%log_messages` entry is a per-message **stats hash** (name string, ~15 stat fields, Welford-Pébay `m2_sum`/`m3_sum`/`m4_sum`, Perl hash overhead) — measured **2,327 B for a singleton**, of which the durations array is only **75 B (3%)**. So the raw store is dominated by fixed per-message hash overhead, not by value arrays. Calibrating the model to the measured 4.63 GB raw store required a 13.6× scale factor — i.e. the bare-array model under-predicted reality by that much.

2. **`-mdm bin` uses *more* message-stats memory than `-mdm raw`, not less: 7.17 GB vs 4.63 GB (~55% heavier).** Bin correctly skips the durations push under `-mdm bin` (`read_and_process_logs`: `push @{...{durations}}, $duration unless $message_stats_capture_mode eq 'bin'`), but for the 96.7% singleton body that saves only ~75 B/message (~44 MB total) while the counter store *adds* 2.96 GB. Bin keeps the full per-message sidecar hash in `log_messages` **and** a partition store on top. **Filed as #354.**

3. **Storage redundancy confirmed at the code level.** Under `-mdm bin` each `%log_messages` entry carries Welford `m2_sum`/`m3_sum`/`m4_sum` **and** a full bin-counter partition exists for the same key — both computing overlapping distribution statistics (the code comments already acknowledge "the bin-counter store and Welford-Pébay sidecars carry the same data"). **Noted on #306** (which owns the compute-cost side of the same sidecars).

### What still stands (measured, unchanged)

- **The distribution is extreme and power-law** (96.7% singletons; 193 hot keys carry 77% of samples) — confirming both edges are real:
  - **Edge A (high cardinality):** the singleton body. Promotion is **structurally powerless** here (a 1-value raw entry is already smaller than any partition; converting it *increases* memory). The lever is **cardinality reduction** — coarser fuzzy grouping (auto `-g`), applied to the invisible tail and gated by user intent (`-dmin`/`-dmax`, occurrence/sort, include/exclude — exact gating is follow-up research), with a warning. This is where the real memory (per-message hashes × 600k) lives, and neither data model touches it.
  - **Edge B (high duration occurrences):** the ~193 hot keys. As raw value arrays these are enormous (the 197k-occurrence key ≈ 6.3 MB); as partitions they are ~2.3 KB (a ~2,700× per-key win). **This is the only place a histogram partition earns its memory** — and there are vanishingly few of them, so promoting only these is cheap.
- **Per-entry `Devel::Size` costs** (partition floor ~2,524 B; raw arrayref +32 B/value; crossover ~N=88) and the **unconditional fidelity ordering** (raw exact, partition approximate) stand as measured earlier.

### Reframed conclusion

Raw-first's *premise* is validated but its *shape* is corrected. The win is **not** "raw instead of bin everywhere" (raw already beats bin at 4.63 vs 7.17 GB) and **not** a 90% reduction. The real design is:

- **Body (singletons/low-N):** store raw — it is smaller and exact. Do **not** allocate a partition.
- **Head (the ~193 hot keys):** promote to a partition — the only case where it saves memory and the durations array would otherwise be huge.
- The dominant remaining cost — the per-message stats hash × 600k messages — is **an Edge-A cardinality problem** that promotion cannot touch; grouping (#96) is the lever there.

### Also surfaced — untracked `-mem` memory

Even after #346, summing every `-mem`-reported structure leaves **~0.81 GB (9% of the 8.64 GB peak RSS) untracked** in the bin run (0.19 GB / 4% in the raw run). A `Devel::Size` sweep of the 75 unmapped file-scope structures found **no single large holder** (only `message_key_order` ≈ 4 MB above 100 KB) — so the gap is diffuse/transient allocation (Perl arena fragmentation, the `-n 2000000` per-message percentile scratch), not one missing hash to add to the map. **Filed as #356.**

### Sequencing (architect decision, 2026-07-13)

**#2 (memory ceiling + graceful degradation) is the umbrella for this memory line.** Its available-memory measurement and target ceiling drive the raw→bin promotion-threshold policy. All storage-policy work below is designed inside that framework, not standalone:

1. **#2 design first** — available-memory detection, the target ceiling, and the degradation contract under which every downstream policy (promotion thresholds, budget awareness) is decided.
2. **#354 (BUG: `-mdm bin` heavier than raw) is blocked behind that design.** Its fix — head/body split: raw for N below the ~N=88 crossover, partition only above — is a storage policy owned by the #2 umbrella. The #306 rejection settles the entry shapes: head keeps sidecar + partition (sidecar authoritative for moments), body keeps neither (moments via the post-sort pass).
3. **Edge A via grouping** (#96 / auto-`-g`, intent-gated) — the per-message-hash cost is the largest lever; a separate track from the data-model policy, orthogonal to the umbrella.
4. **Re-measure** any implemented head/body split on the same node with `-mem` to confirm it beats *both* pure models (the two measured endpoints — bin 7.17 GB, raw 4.63 GB — bracket the target). Peak-RSS anchors must be re-taken post-#362: the runs above used `-n 2000000` before the unclamped output-phase slice burst (~0.16–0.19 GB transient RSS ratchet) was fixed; per-structure `Devel::Size` figures are unaffected.

### Dependencies / cross-links

- **#2** — the umbrella (see Sequencing above); #354 is blocked on it.
- **#346** — resolved (PR #350); made this measurement possible.
- **#354 (BUG: `-mdm bin` memory regression vs raw)** — the actionable defect this investigation surfaced; blocked behind the #2 design, which owns its head/body-split fix.
- **#306** — closed (implemented, measured, rejected): the raw path keeps its two-pass moment computation; raw entries carry no Welford sidecars. Constants and rationale in features/305-shape-moment-extended-percentile-demand.md § #306 investigation.
- **#96 / `-g`** — the Edge-A cardinality lever (the dominant remaining cost).
- **#347 (bin-counter eviction)** — closed as not planned: prevention (never allocate sparse partitions, per the #354 fix direction) supersedes evicting them. Residual eviction scope (raw-side synthesized residue) belongs to #2's contract if ever needed.
- **#362** — resolved; reframes the peak-RSS figures above (see Sequencing item 4).
- **#356 (`-mem` untracked residual)** — resolved (merged into `release/0.16.0`); the memory account closes, so `-mem`-based re-measurements in this line are trustworthy.
- The **single-sample inline producer** (`read_and_process_logs`, `%tmp` `_single` path) is a second place entry-kind is minted; any head/body implementation must route it through the same policy as the main write path.
