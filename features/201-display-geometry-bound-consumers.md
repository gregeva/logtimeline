# Feature: Investigation — display-geometry-bound consumers and the #189 primitive contract

## Overview

This document is the **investigation home** for issue #201. It catalogues the architectural mismatch between the bin-counter primitives locked in #187 / implemented in #189 (`ltl:565–748` on `release/0.14.5`) and the **display-geometry-bound consumers** (heatmap, histogram) those primitives must serve once #34 Phase 3 lands.

The investigation produces decisions and doc amendments. It does **not** change `ltl` code. Any primitive variant code that the recommendation requires lands in a follow-on #189-amendment ticket per the issue's scope statement.

## GitHub Issue

[#201](https://github.com/gregeva/logtimeline/issues/201)

## Sources

- `features/187-histogram-bin-counter-percentiles.md` — locked contract, Decision 5 (partition lifecycle) is the focus of clarification.
- `features/189-histogram-bin-counter-primitives.md` — primitive spec, R1–R6.
- `features/189-bin-counter-primitives-implementation-readiness-audit.md` — #195's audit; new Bucket D added by this investigation.
- `features/34-histogram-bin-counter-mode.md` — #34 implementation ticket; R5/R8 update by this investigation.
- `prototype/189-bin-counter-primitives.pl` — V1–V5 validation harness, extended by V6/V7 for this investigation.
- `prototype/189-bin-counter-primitives-validation-report.md` — V1–V5 empirical findings, companion to the V6/V7 report this investigation produces.
- `ltl` at `release/0.14.5` HEAD — code anchor for current consumer behavior.

Line numbers refer to `release/0.14.5` HEAD; symbols and global identifiers are the stable anchors.

## What this investigation is not

- **Not a code change.** Read-only against `ltl`. Deliverables are `features/*.md` amendments and a prototype extension. No `ltl` lines modified by #201.
- **Not a primitive implementation.** Any primitive variant that the recommendation requires lands in a follow-on ticket.
- **Not a consumer migration.** #34 owns the heatmap/histogram migrations; this investigation unblocks it.

---

## § Problem reframing

The issue body centers on a "fixed-bin-count primitive variant," framing the mismatch as one-dimensional (bin count). The four projection strategies attempted during #34 Phase 3 (since reverted, never committed) varied bin count via `bpd` and varied projection math (midpoint vs. distributive), but all four failed — which tells us bin count is **not** the root cause. It is at most one of three coupled mismatches between the partition primitive and the display.

### Three dimensions of mismatch

**Dimension A — Bin-count mismatch.**
- Partition `bin_count = int(bpd × decades)`. At locked defaults (`bpd=53`, `decades=5`), that is ~265 bins per partition.
- Heatmap display column count: `$heatmap_width`, default 52 (CLI `-hmw`).
- Histogram display column count: `$bar_area_width`, variable (computed from terminal width and active-metric count).
- Bin count and display column count are not equal under any locked default; they would need to be reconciled in some way.

**Dimension B — Range-anchor mismatch.**
- Partition `[min, max]` is seeded at `[v_0 / sqrt(10^5), v_0 × sqrt(10^5)]` (`ltl:571–573`), then extended outward by `partition_extend` (`ltl:586–631`) doubling the affected end by factor `10^(decades/2)` until subsequent values fit.
- Display geometry is anchored at `[d_min, d_max]` (the observed data extents), known only at end-of-parse.
- The partition range and display range drift apart in a **data-dependent** way. Even with auto-resize extending the partition outward, the final partition `[min, max]` is determined by the value sequence and doubling factor, not by `[d_min, d_max]`.
- Consequence: bin boundaries straddle display boundaries. Spike *positions* shift, not just amplitudes. This is the failure mode the Phase 3 `bpd=8 + distributive remap` attempt couldn't fix despite 97% Y-axis retention.

**Dimension C — Knowability-time mismatch.**
- Heatmap `$heatmap_width` is known at CLI-parse time (before the first line is read). ✓
- Histogram `$bar_area_width` depends on:
  - `$terminal_width` (known at startup; `ltl:236`).
  - `n` = count of metrics with non-zero observations during parse (known only at end-of-parse; `ltl:5304–5310`).
  - `$histogram_width_percent` (CLI-controlled, auto-adapts by metric count; `ltl:5472–5473`).
- Auto-resize requires partition construction on the **first observation** for that key — a moment when neither extents nor `n` are known.

### Why "bin-count variant" alone is insufficient

The issue title and the four candidate primitive options the issue lists all address Dimension A only. If the bin count is the only thing pinned, Dimension B (range-anchor drift) is still free to introduce spike-position offsets even at matched bin counts. The Phase 3 evidence (`bpd=8 + distributive remap`: 97% Y-axis retention, heatmap still gap-toothed) is the empirical signal that pinning bin count without addressing range-anchoring does not solve the user-visible problem.

### Three-family consumer taxonomy

The issue body proposes a two-family thesis: per-key fan-out vs. display-bound. The consumer reality is **three families** with materially different problem shapes:

| Family | Examples | Partition keying | Current binning model (`release/0.14.5`) | Auto-resize fit |
|---|---|---|---|---|
| **F1 — Per-key fan-out, precision-bound** | `summary_table`, `csv_output`, `time_bucket_stats` | Per-`(category, log_key)` or per-`time_bucket` | Pre-migration: `calculate_statistics` (`ltl:5879–5919`) from retained `@durations` arrays. Bins do not exist; percentiles from sorted raw values. Post-migration target: #189 primitives as-built. | ✓ Auto-resize is correct. Bins are internal precision, never rendered. |
| **F2 — Per-key fan-out, display-direct** | `heatmap_cells`, `heatmap_markers` (per-`time_bucket`) | Per-`time_bucket` | `calculate_heatmap_buckets` (`ltl:5182–5256`): `bucket_count = $heatmap_width` (default 52); log boundaries over `[d_min, d_max]`. **There is no projection step in shipped code — partition geometry IS display geometry, 1:1.** | ✗ Auto-resize *introduces* a projection step that did not exist before. The partition geometry no longer matches display geometry. |
| **F3 — Single-partition, linear-index projection** | `histogram_view`, `histogram_bins` (per-metric global) | Per-metric global (one partition per metric) | `calculate_histogram_buckets` (`ltl:5298–5410`): `bucket_count = int(decades × histogram_buckets_per_decade)`, default `histogram_buckets_per_decade = 8`. Log boundaries over `[d_min, d_max]`. Display projection: `calculate_histogram_display_buckets` (`ltl:7462–7493`) — linear over bucket indices, NOT log-space-aware. | ✗ Auto-resize *replaces* an existing working projection with a (Phase 3) broken one. Dimension C also applies. |

The two-family thesis collapses Family 2 and Family 3 into "display-bound consumers" — which is the framing that produced the Phase 3 category error (see § Phase 3 evidence catalogue). Treating them as one family forces a single projection strategy across two consumers with different starting models, and any uniform strategy will fight one of them.

### Scope clarification on #187 Decision 5

Per maintainer clarification (recorded by issue thread): Decision 5's "lifecycle is not revisitable" lock was written narrowly about **per-message bin counters for percentile calculation**. It was never meant as a universal lifecycle rule across every consumer. Different consumers with different needs were always on the table; the per-consumer differentiation was understood but never written down.

The Decision 5 amendment this investigation proposes therefore **clarifies scope that was always intended**. It is not reopening a freshly-locked decision; it is writing down a distinction that was part of the design intent from the start. Line 1247 of Decision 5 currently reads "every consumer of the unified primitive contract" — the amendment scopes that phrase to F1 explicitly and writes the F2/F3 lifecycle conventions that were always implied by the per-consumer keying enumeration immediately after (line 1247 already lists per-time_bucket and per-metric keying, which presupposed per-consumer lifecycle differences without spelling them out).

---

## § Per-consumer projection model today (release/0.14.5)

A faithful catalogue of what each shipped consumer does **today**, before any #34 Phase 3 work. Any unified contract amendment must explicitly account for both starting points — applying a single "display projection" strategy across consumers with different starting models is what produced Phase 3's failure mode.

### F1 — `summary_table` / `csv_output` (precision-bound, no projection)
- Today: `calculate_statistics` (`ltl:5879–5919`) sorts retained `@durations` arrays and indexes by `int(N × q)` to derive percentiles.
- No binning, no projection. Bins are not part of the data model.
- Post-migration target (#187 R9 Phase 2): replaces `calculate_statistics` calls with `percentile()` (`ltl:692`) invocations against #189 primitive partitions. **The post-migration target is well-fitted by #189 as-built.** Auto-resize lifecycle is appropriate.

### F2 — `heatmap_cells` / `heatmap_markers` (display-direct, no projection step)
- Today (`ltl:5182–5256`):
  - `heatmap_bucket_count = $heatmap_width` (1:1 with display columns).
  - Boundaries: `boundary[i] = effective_min × (effective_max / effective_min)^(i / heatmap_bucket_count)` — log-spaced over `[d_min, d_max]`.
  - Both `$heatmap_min` and `$heatmap_max` are discovered during the parse and finalized at end-of-parse (`ltl:5080–5081` area).
  - `find_heatmap_bucket(value, bucket_count)` (`ltl:5174–5180`) is a linear search over `@heatmap_boundaries`; out-of-range values silently clamp to the last bin.
  - Each value maps directly to a display column index. **No projection step exists** because the partition has exactly as many bins as the display has columns, sharing identical log-spaced boundaries.
- Memory cost today: `%heatmap_raw{$bucket}` retains all raw values until end-of-parse — this is the memory motivation for migration, NOT a need for a projection step.
- Display column count: known at CLI-parse (`-hmw`, default 52). ✓ Dimension C is not a blocker.

### F3 — `histogram_view` / `histogram_bins` (linear-index projection at render time)
- Today (`ltl:5260–5278`, `5298–5410`):
  - `calculate_histogram_bucket_count(min, max)` returns `int(decades × histogram_buckets_per_decade + 0.5)`, minimum 5. Default `histogram_buckets_per_decade = 8`.
  - Boundaries: log-spaced over `[d_min, d_max]` per metric.
  - `find_histogram_bucket_index(value, boundaries_ref)` (`ltl:5281–5296`) is a binary search over per-metric `@{$histogram_boundaries{$metric}}`.
- Display projection (`ltl:7462–7493`, `calculate_histogram_display_buckets`):
  - `cols_per_bucket = $bar_width / $bucket_count`.
  - If `>= 1` (display wider than partition): each display column picks its bucket via `bucket_idx = int(i / cols_per_bucket)` — partition bin index → display column index mapping is **linear over indices**, not log-space-aware.
  - If `< 1` (display narrower than partition): aggregates `int(i × buckets_per_col) .. int((i+1) × buckets_per_col) - 1` adjacent partition bins per display column.
- This is the closest existing precedent for a partition→display projection step. It works at narrow widths because partition `[min, max]` matches display `[d_min, d_max]` exactly (both derived from data extents at end-of-parse); only bin counts differ.
- Display column count: depends on `n` = count of metrics with non-zero observations, **not known until end-of-parse** (`ltl:5304–5310`). ✓ Dimension C applies.

### Category-error analysis

The Phase 3 attempt treated "heatmap and histogram" as a single consumer family with a single projection problem, and tried four projection strategies uniformly across both consumers. But:

- For **heatmap (F2)**: Phase 3 *introduced* a projection step where none existed in shipped code. Even if the projection were mathematically perfect, the partition `[min, max]` would not match display `[d_min, d_max]` (Dimension B), so spike positions would shift.
- For **histogram (F3)**: Phase 3 *replaced* an existing working projection (linear-index, partition range matches display range by construction) with a projection that no longer had matching ranges (because auto-resize partition `[min, max]` was seeded around `v_0`, not `[d_min, d_max]`).

In both cases, the failure trace through Dimension B is identical, but the *fix* differs. F2's fix is to never need a projection step at all (preserve the 1:1 partition=display model). F3's fix is to preserve the partition-range = display-range invariant somehow (defer partition allocation, or two-stage stream→finalize). A single primitive variant applied to both cannot satisfy both fixes.

This is the category-error finding that justifies the three-family taxonomy.

---

## § Phase 3 evidence catalogue

This section reconstructs what the four #34 Phase 3 attempts did and why each failed, **separately per consumer**. The Phase 3 work was never committed; the evidence below is from the diagnosis recorded in #201's issue body, cross-referenced against the shipped code state on `release/0.14.5`.

**Methodology.** For each strategy, we record:
- What the strategy was (algorithm).
- Which Dimensions (A/B/C) it addressed.
- The empirical failure observed.
- What it would have looked like applied to each consumer family (F2 / F3) — because the four attempts were applied uniformly across both, and that uniformity is itself a finding.

### Strategy 1 — Midpoint-only assignment

**Algorithm.** Each partition bin gets assigned to one display column via its geometric midpoint: `display_col = floor(display_width × log(midpoint / d_min) / log(d_max / d_min))`. Each partition bin contributes 100% of its count to one display column.

**Dimensions addressed.** Partial Dimension A only — gives a deterministic bin→column map, but doesn't reconcile the count mismatch. Dimension B (range-anchor) untouched. Dimension C (knowability) untouched.

**Empirical failure.** Heatmap shows gap-toothed cells. With Phase 3's `bpd=8` (32 partition bins per heatmap row at 4 decades) vs. `$heatmap_width=52` (display columns), 52 − 32 = 20 display columns receive no count → empty cells.

**Per-consumer trace.**
- **F2 (heatmap):** Catastrophic visual failure. Today's heatmap has no projection; partition `bin_count = display_width` exactly. Strategy 1 introduces a projection where the partition has *fewer* bins than the display, mathematically guaranteeing empty display columns. This is a structural failure, not a tuning failure.
- **F3 (histogram):** Less visible but still wrong. Today's `calculate_histogram_display_buckets` at `ltl:7468` handles the `cols_per_bucket >= 1` case by *spanning* each bucket across multiple display columns (`bucket_idx = int(i / cols_per_bucket)` — multiple display indices `i` map to the same bucket). Strategy 1's midpoint-only assignment collapses each partition bin to one display column → other display columns receive zero, even when they should display a smeared bar. The histogram bar profile becomes "spiky" where today's is "smooth-and-stepped."

### Strategy 2 — Distributive remap (log-overlap)

**Algorithm.** Each partition bin's count is split across overlapping display bins proportional to log-space overlap. A partition bin `[L_p, U_p]` overlapping display bins `[L_d_i, U_d_i]` for `i ∈ {a, b, c}` contributes its count weighted by `log(min(U_p, U_d_i) / max(L_p, L_d_i)) / log(U_p / L_p)` to each.

**Dimensions addressed.** Dimension A (resolves bin-count mismatch via fractional contribution). Dimension B (partial — splits across boundaries, but doesn't anchor partition range to display range). Dimension C untouched.

**Empirical failure.** Histogram spikes flatten from 21k → 19k (~10% peak attenuation; counts mathematically preserved but smeared into neighbor bars). Counts add up correctly; visual peak shape destroyed.

**Per-consumer trace.**
- **F2 (heatmap):** Heatmap cells fill in (no gap-toothed problem), but cell *intensity* is smeared. A cluster of values that should hit a single bright cell instead lights up two or three adjacent dimmer cells. The visual signal of "tight latency clustering" is lost. Marker positions (P50/P95/P99/P999) drift because the smeared distribution shifts the rank-locating bin.
- **F3 (histogram):** The 21k → 19k peak attenuation matches today's `calculate_histogram_display_buckets` behavior in the `cols_per_bucket < 1` branch (where it sums adjacent buckets) — but with smearing across display boundaries on top. The cumulative effect is worse than today's projection because the partition boundaries no longer align with display boundaries.

### Strategy 3 — `bpd = 53` (locked default) + distributive remap

**Algorithm.** Partition uses locked default `bpd = 53` (per #187 Decision 2 default; ~265 bins at 5 decades), then distributive remap onto display width. The hope: more partition bins → finer-grained source data → better remap fidelity.

**Dimensions addressed.** Tried to fix A by going in the wrong direction (more partition bins → more overlap per display bin → worse smearing). B and C untouched.

**Empirical failure.** Worse smearing than Strategy 2. With 265 partition bins remapped onto 52 display columns, each display column averages ~5 partition bins → each display bar reflects an aggregate of 5 partition bins' worth of count → smoothing aggressively pronounced.

**Per-consumer trace.**
- **F2 (heatmap):** Heatmap cells uniformly lit with smoothed intensity. The signal that distinguishes one time bucket's latency profile from another's collapses toward a uniform gray.
- **F3 (histogram):** Histogram bars look like a kernel-density-smoothed version of the true distribution. Useful for general shape, useless for peak detection. The "spike at 100ms" that today's histogram shows clearly becomes a hump from 80–150ms.

**Diagnosis.** This is the strategy that proves bin-count tuning alone cannot solve the problem. Higher `bpd` (more partition bins) made fidelity *worse*, not better — because the failure mode is range-anchor mismatch (Dimension B), not bin-count mismatch (Dimension A). Distributing 265 misaligned bins onto 52 display columns is more lossy than distributing 32 misaligned bins, even though 32 misaligned bins also produces visible smearing.

### Strategy 4 — `bpd = 8` + distributive remap

**Algorithm.** Drop `bpd` from 53 to 8 (matching ltl's existing `histogram_buckets_per_decade = 8` default), then distributive remap. The hope: with fewer partition bins, fewer overlap conflicts.

**Dimensions addressed.** Tried to fix A by minimizing partition bin count (the opposite direction from Strategy 3). B untouched. C untouched.

**Empirical failure.** Y-axis retention improves to 97% (281k peak vs. true 290k) but the heatmap *still* has empty cells and the bar shape is *still* smoothed.

**Per-consumer trace.**
- **F2 (heatmap):** With `bpd=8 × 5 decades = 40` partition bins distributing onto 52 display columns, 12 display columns must be empty (by pigeonhole, since fewer source bins than destination bins and the projection is value-positive). Gap-toothed visual returns.
- **F3 (histogram):** 97% Y-axis retention is mathematically excellent, but the spike position has *shifted* by some number of display columns. The spike is at the wrong x-axis location, not just attenuated. A user reading the histogram for "where do my latencies cluster" would see the cluster at the wrong location.

**Diagnosis.** This is the strategy that proves the failure mode is **range-anchor mismatch (Dimension B)**, not bin-count (Dimension A). Y-axis retention says counts are preserved; spike position drift says boundaries are misaligned. The partition was seeded around `v_0` (first observed value), so the partition's `[min, max]` differs from the display's `[d_min, d_max]` by a `v_0`-dependent offset. Re-binning preserves counts but shifts where those counts land in the display.

### Category-error finding

The four strategies were applied uniformly to both consumers. They share an unstated assumption: **F2 and F3 are the same kind of consumer, with the same kind of projection problem.** The taxonomy in § Problem reframing shows they are not. Specifically:

- **F2 (heatmap) today has no projection step.** Any Phase 3 strategy that introduces a projection step is fighting an architectural mismatch the heatmap never had.
- **F3 (histogram) today has a working projection step** (`calculate_histogram_display_buckets`). It works because partition boundaries and display boundaries are *both* derived from `[d_min, d_max]` — the partition range equals the display range by construction. Any Phase 3 strategy that breaks this range-alignment (because auto-resize seeds around `v_0` instead of extents) will produce a worse projection than what shipped.

The four strategies all break the F2 invariant ("no projection step") and the F3 invariant ("partition range = display range"). They cannot satisfy both consumers simultaneously because the invariants are different.

**Implication for option analysis.** The remedy is not a uniform "better projection algorithm." It is **per-consumer architectural fit**: F2 needs a partition that preserves its 1:1 bin=column invariant (or stays on `%heatmap_raw` pre-migration); F3 needs a partition whose range matches `[d_min, d_max]` (which means deferring partition construction until extents are known, or running a two-stage stream→finalize). These are different solutions, not variants of one solution.

---

## § Option space

Each option analyzed per family. Cell shape: **What changes** / **What stays** / **Predicted fidelity** / **Risk**. Predicted fidelity placeholders refer forward to § Algebraic fidelity bounds (which formalize the predictions) and § Prototype extension (which validates them).

Options under consideration:
- **(a)** New primitive variant: explicit `bin_count` + deferred `[min, max]`.
- **(b)** `fixed_bin_count` partition flag affecting `partition_extend`.
- **(c)** Keep primitives, add smarter re-projection algorithm at consumer call site.
- **(d)** Defer partition allocation to end-of-parse (re-introduces raw-value retention).
- **(e)** Two-stage: precision-bound stream partition → end-of-parse re-bin into display-bound partition.
- **(f)** Decompose F2 from F3 — recognize they have different problem shapes (composes with other options).
- **(g)** Amend #34 R5/R8 (loosen "display geometry unchanged" promise) instead of #189 (loosen primitive contract).
- **(h)** Amend Decision 5 to formalize per-family lifecycles (clarified scope per maintainer correction; composes with other options).

Options (f) and (h) are **architectural framings**, not standalone solutions — they compose with (a)–(e) and (g) by defining the per-family lifecycle the chosen primitive/algorithm operates under. The matrix below treats them as composition modifiers, marked **applies-to** rather than per-family.

### (a) — New primitive variant: explicit `bin_count` + deferred `[min, max]`

**Shape.** A new `partition_new_fixed($bin_count)` returns a partition object with `bin_count` pinned and `[min, max]` deferred. Subsequent observations either: (i) wait for finalize before binning (requires raw-value retention — collapses into option (d) or (e)); or (ii) bin against a placeholder range that gets re-bin'd at finalize. `partition_extend` is replaced by a `partition_finalize($v_min, $v_max)` that locks the range and bins retained values.

| Family | What changes | What stays | Predicted fidelity | Risk |
|---|---|---|---|---|
| **F2 (heatmap)** | Partition has `bin_count = $heatmap_width` from CLI-parse time. Boundaries set at end-of-parse from `[$heatmap_min, $heatmap_max]`. Values retained during parse, bin'd at finalize. Effectively today's `calculate_heatmap_buckets` wrapped in primitive vocabulary. | Heatmap visual output is byte-identical to today's. `$heatmap_width` semantics. `find_heatmap_bucket` deleted (replaced by `bin_assign` on the finalized partition). | **Perfect** — display geometry is constructed from same `[d_min, d_max]` as today, with same `bucket_count`. | Streams memory cost is unchanged (raw-value retention persists in some form). Defeats one of #187's stated motivations. |
| **F3 (histogram)** | Partition has `bin_count` pinned... but to *what*? `$bar_area_width` not known until end-of-parse. Variant requires `bin_count` at construction. Forced to either (i) defer construction (collapses into (d)) or (ii) construct at a worst-case value and re-bin at render. | Today's `calculate_histogram_buckets` could be adapted. | **Conditional** — if forced into (d) or two-stage, fidelity matches that option. Standalone, this variant is awkward for F3. | Dimension C makes this awkward; the explicit-`bin_count` knob doesn't fit when display width is unknown at construction. |

**Verdict.** Useful for F2, awkward for F3. The "explicit `bin_count`" idea is sound for F2 but not the full answer; it doesn't address range-anchoring (still needs deferred `[min, max]`) and it doesn't help F3 directly.

### (b) — `fixed_bin_count` partition flag affecting `partition_extend`

**Shape.** `partition_new(...)` accepts an optional `fixed_bin_count` flag. When set, `partition_extend` preserves `bin_count` across rebin events (line 608's `int($p->{bpd} × $new_decades)` becomes `$p->{bin_count}`). Caller is expected to provide explicit `bin_count` and tune `bpd` accordingly.

| Family | What changes | What stays | Predicted fidelity | Risk |
|---|---|---|---|---|
| **F2 (heatmap)** | `partition_new(v_0, ?, ?, fixed_bin_count => $heatmap_width)` — pins bin count to display width. Auto-resize still seeds around `v_0` (not extents), so range-anchor drift remains. Phase 3 evidence: this is essentially Strategy 4 (bpd=8), which still showed gap-toothed cells. | Auto-resize lifecycle. | **Poor** — fixes Dimension A but Dimension B drift produces position offsets. Same failure mode as Strategy 4. | Looks like a fix; doesn't actually fix the visible problem. |
| **F3 (histogram)** | Same issue: pinning `bin_count` doesn't fix range-anchoring. With auto-resize partition seeded around first metric value and display anchored to extents, bars shift positions. | Same. | **Poor** — same as F2. | Same. |

**Verdict.** Surface-level fix only. Addresses the named problem (bin count) without addressing the actual cause (range anchor). Rejected on first principles; the Phase 3 evidence already validates the rejection empirically for F2.

### (c) — Smarter re-projection algorithm at consumer call site

**Shape.** Keep primitives unchanged. Add a re-projection step at the consumer that uses log-space-aware splitting or CDF-resampling (treating each partition's bins as a discretized CDF, then resampling onto the display grid).

| Family | What changes | What stays | Predicted fidelity | Risk |
|---|---|---|---|---|
| **F2 (heatmap)** | New `project_partition_to_heatmap_row($partition, $bins, $display_width, $d_min, $d_max)` runs per `time_bucket` at render. Input: per-bucket partition `[v_0/sqrt(10^5), ...]` after rebin. Output: array of length 52 with counts. Algorithm: CDF-resample. | Primitives unchanged. Partition seeding around `v_0` unchanged. | **Bounded** — depends on how aggressively the range mismatch shifts boundaries. CDF resampling preserves total mass but blurs spike position by up to `δ × display_width / log(range_ratio)` columns where `δ` is the log-space offset between partition and display ranges. | The same mathematical problem Phase 3 fought. Better algorithm helps only at the margin. |
| **F3 (histogram)** | Replace `calculate_histogram_display_buckets` (`ltl:7462`) with a CDF-resample variant. | Primitives unchanged. | **Bounded similarly** — partition range drift produces position offsets. | Same as F2. |

**Verdict.** Tries to do at render time what auto-resize fundamentally cannot do streaming. The mathematical ceiling on fidelity is bounded by how badly partition `[min, max]` diverges from display `[d_min, d_max]` — and auto-resize cannot guarantee convergence within a useful tolerance. Worth analyzing the bound (see § Algebraic fidelity bounds) but unlikely to satisfy F2's display-direct invariant.

### (d) — Defer partition allocation to end-of-parse (re-introduces raw-value retention)

**Shape.** Heatmap and histogram retain `%heatmap_raw{$bucket}` and `%histogram_values{$metric}` as today. At end-of-parse, construct partition with `bin_count = display_width`, boundaries from `[d_min, d_max]`, bin all retained values. This is essentially "don't migrate — leave shipped code in place."

| Family | What changes | What stays | Predicted fidelity | Risk |
|---|---|---|---|---|
| **F2 (heatmap)** | Nothing — `calculate_heatmap_buckets` (`ltl:5182`) stays. | Everything. Heatmap output byte-identical. | **Perfect** — no change. | None for fidelity; but #187's memory motivation for migration is defeated. |
| **F3 (histogram)** | Nothing — `calculate_histogram_buckets` + `calculate_histogram_display_buckets` stay. | Everything. Histogram output byte-identical. | **Perfect** — no change. | Same. |

**Verdict.** Equivalent to "don't migrate F2/F3 ever." Establishes the worst-case-memory baseline for cost-benefit analysis. Documented as a legitimate option because the alternative (suboptimal migration) may be worse than no migration. Note: the `%heatmap_raw` / `%histogram_values` memory cost in practice is bounded — heatmap is `time_bucket_count × $heatmap_width` (at most ~52 × bucket_count integers), not unbounded. The dominant memory consumers in #187's analysis were `%log_messages` and `%log_analysis`, not the display-bound consumers. **This is the option most worth pressure-testing against (e) on actual memory cost, not just on principle.**

### (e) — Two-stage: precision-bound stream partition → finalize re-bin into display-bound partition

**Shape.** Stream into a precision-bound partition (auto-resize, ~265 bins) for memory safety. At end-of-parse, re-bin into a display-bound partition (`bin_count = display_width`, boundaries from now-known `[d_min, d_max]`). Display reads from the display-bound partition.

| Family | What changes | What stays | Predicted fidelity | Risk |
|---|---|---|---|---|
| **F2 (heatmap)** | New `partition_rebin($source_partition, $source_bins, $new_min, $new_max, $new_bin_count)` runs at end-of-parse per `time_bucket`. Source: auto-resize partition with ~265 bins. Target: 52-bin partition matching display. Re-bin via geometric-midpoint (same loop as `partition_extend` at `ltl:613–622`). | Display reads 52-bin partition (matches today's invariant). `find_heatmap_bucket` deleted. | **Near-perfect at finalize** — re-bin operates on bounded source data with known target geometry. Y-axis: 99%+ retention (one source bin's count goes entirely to one target bin via midpoint). X-axis: bounded by source bin width × `display_width / source_bin_count` — at locked defaults, sub-column accuracy. | One re-projection happens at finalize (not per-render-frame), so cost is one-shot. Fidelity loss bounded but non-zero. |
| **F3 (histogram)** | Same pattern at end-of-parse per metric. Source: global auto-resize partition (~265 bins). Target: `$bar_area_width`-bin partition. Re-bin step identical to F2. | Display reads finalized partition. Replaces `calculate_histogram_display_buckets`. | **Near-perfect** — same bounds as F2. Today's `calculate_histogram_display_buckets` is itself a coarser version of this (linear-index, not log-space-aware), so two-stage strictly improves over today. | Same. |

**Verdict.** Architecturally clean: streams stay memory-bounded, finalize is one-shot, display geometry reconstructed at the moment all needed inputs are known. Fidelity bounded by a known function of source and target bin counts. **Likely best candidate for both families** subject to algebraic fidelity bound derivation and prototype validation.

### (f) — Decompose F2 from F3 (composition modifier)

**Shape.** Treat F2 and F3 as separate consumer families with independent lifecycle decisions. Doesn't pick a primitive; instead it forces the doc structure to enumerate per-family decisions rather than presenting a unified one.

**Applies to all options.** If (e) is chosen, (f) says "(e) is the F2 answer AND (e) is the F3 answer — but those are independent decisions, not one decision applied twice." If F2 lands on (d) and F3 lands on (e), (f) is what allows that.

**Verdict.** Necessary regardless of primitive choice. The Phase 3 evidence (§ Phase 3 evidence catalogue) shows that treating F2 and F3 as one consumer family produces the category error. **Accept (f) as a framing.**

### (g) — Amend #34 R5/R8 to loosen "display geometry unchanged"

**Shape.** Allow display geometry to adjust to match partition geometry, instead of requiring partition geometry to project onto fixed display geometry. The display widths become outputs of the partition lifecycle, not inputs.

| Family | What changes | What stays | Predicted fidelity | Risk |
|---|---|---|---|---|
| **F2 (heatmap)** | `$heatmap_width` becomes a target, not a hard constraint. Display shows partition's actual `bin_count` (~40–265 depending on `bpd` and observed range). Heatmap row width varies between runs. | Partition logic unchanged. | **Perfect at the partition level** — no projection needed. **Visually disruptive** — heatmap width changes per run, breaks `-hmw` user expectation. | UX regression. Breaks the "display geometry unchanged" promise that motivated #34 R8. Users would file bugs. |
| **F3 (histogram)** | `$bar_area_width` becomes a target. Bars compete for space; auto-allocate at end-of-parse. | Same. | **Perfect at partition level**; UX regression similar to F2. | Same. |

**Verdict.** Solves the fidelity problem by removing the constraint that was producing it. **Architecturally honest but UX-cost is large.** Document as a fallback if (e) fails prototype validation, but don't expect to choose it.

### (h) — Amend Decision 5 to formalize per-family lifecycles (composition modifier)

**Shape.** Per maintainer clarification, Decision 5 was always about per-message bin counters for percentile calculation (F1). The per-consumer differentiation was understood but never written down. (h) writes it down. It composes with (a)–(e) and (g) by defining the lifecycle each family runs.

**Applies to all options.** Mandatory artifact of the investigation regardless of which primitive/algorithm choice lands. The Decision 5 amendment in `features/187-*.md` will be the codification of (h).

**Verdict.** Mandatory. (h) is not a standalone option; it's the contract amendment that captures whichever option(s) the investigation lands on.

### Option-space summary table

| Option | F2 fit | F3 fit | Standalone? | Verdict |
|---|---|---|---|---|
| (a) Explicit `bin_count` + deferred range | Useful but incomplete | Awkward (Dimension C) | No — collapses into (d) or (e) | Component of (e), not standalone |
| (b) `fixed_bin_count` flag | Poor — Dim. B drift | Poor — Dim. B drift | Yes | **Rejected** by Phase 3 evidence (Strategy 4) |
| (c) Smarter projection algorithm | Bounded — Dim. B ceiling | Bounded — Dim. B ceiling | Yes | Worth bounding but unlikely to pass for F2 |
| (d) Don't migrate (keep raw retention) | Perfect | Perfect | Yes | Baseline for cost-benefit; legitimate fallback |
| (e) Two-stage stream→finalize | Near-perfect | Near-perfect | Yes | **Primary candidate** for both families |
| (f) Decompose F2 from F3 | n/a | n/a | No — modifier | **Mandatory framing** |
| (g) Loosen #34 R5/R8 | Perfect math, UX-cost | Perfect math, UX-cost | Yes | Fallback only |
| (h) Amend Decision 5 | n/a | n/a | No — modifier | **Mandatory codification** |

**Candidates advancing to algebraic fidelity bounds.** Primary: (e). Comparison: (c) and (d). Modifiers (f) and (h) compose with whichever wins.

---

## § Algebraic fidelity bounds

> *To be filled in by Task #11. For each surviving candidate, derive worst-case Y-axis error envelope and X-axis offset envelope as functions of (bin_count, display_width, range_offset). Predict-then-validate posture; no candidate advances to prototyping without quantitative prediction.*

---

## § Prototype extension

> *To be filled in by Task #12. V6 (heatmap projection fidelity) + V7 (histogram projection fidelity) extension of `prototype/189-bin-counter-primitives.pl`. Findings captured in `prototype/201-projection-comparison-report.md`.*

---

## § Recommendation

> *To be filled in by Task #13 after prototype validation. Per family (F2, F3). Explicit predicted fidelity numbers + surviving prototype evidence. Convergence between families justified if applicable; divergence justified if not.*

---

## § Open question for histogram migration ticket

> *Documented at recommendation time. Histogram Dimension C (n-metrics-knowability) may not fully resolve in #201; candidate directions documented for the future histogram migration ticket per the issue's stated scope-boundary.*

---

## Amendments produced by this investigation

After the recommendation locks, surgical edits to:
- `features/187-histogram-bin-counter-percentiles.md` — Decision 5 per-family scope clarification.
- `features/189-histogram-bin-counter-primitives.md` — New R-section (if needed) for additional primitive surface; or an explicit "current primitives suffice with caller-side composition" finding.
- `features/189-bin-counter-primitives-implementation-readiness-audit.md` — New **Bucket D**: per-consumer-binning-need category not surfaced by the original audit.
- `features/34-histogram-bin-counter-mode.md` — R5/R8 update with concrete unblocked Phase 3 path.

---

## Delivery sequence (where this investigation sits)

```
┌─────────────────────────────────────────────────────────────┐
│ #187 (locked) — unified contract                            │  done
│   Decision 5 lifecycle, Decision 8 -V format, etc.          │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ #189 (production complete) — primitives in ltl              │  done
│   R1-R6 helpers, =BIN-COUNTER MODE= -V block, CLI flags     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ #195 (audit complete) — implementation-readiness audit      │  done
│   Buckets A-C catalogue spec/code/decision surfaces         │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ #201 (this investigation) — display-geometry-bound          │  ◄ here
│   consumer family analysis + amendments                     │
│   adds Bucket D to #195 audit                               │
│   doc + prototype only                                      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ #34 Phase 3 — heatmap/histogram consumer migrations         │  unblocked
│   executes against this investigation's locked recommendation│
└─────────────────────────────────────────────────────────────┘
```
