# Projection-Comparison Report (issue #201)

## Purpose

Empirical findings from the prototype validation done for #201. Documents the full V6/V7/V8 work — initial measurements that proved misleading, the correction via V8 column-by-column comparison, the bpd sweep across all locked Decision 2 tier values, the geometric-vs-proportional algorithm comparison, and the resolved recommendation.

This report is a **deliverable**. Do not overwrite for re-testing — copy to a temp label or rename first.

## Sources

- `prototype/189-bin-counter-primitives.pl` § `run_v6`, `run_v7`, `run_v8`, `_rebin_geometric`, `_rebin_proportional`, `_cdf_resample`.
- `features/201-display-geometry-bound-consumers.md` — investigation home doc.
- `features/187-histogram-bin-counter-percentiles.md` § Decision 2 — locked tier table (4, 8, 16, 32, 53, 80, 115, 256, 616).

## Datasets

Two real Tomcat access log datasets used throughout:

| Label | Path | Total lines | Parseable durations | Decades |
|---|---|---|---|---|
| **Your file** | `logs/AccessLogs/really-big/localhost_access_log-twx01-twx-thingworx-0.2025-12-30.txt` | 195,399 | 193,433 | 5.08 |
| **148MB file** | `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt` | 761,698 | 575,800 | 4.52 |

The "your file" reference matches the 41-bucket histogram shown in the actual ltl `-V` output during investigation (`samples=193433`, `total_buckets=41`).

## Reproducibility (locked commands)

```
# V8 sweep — bpd × algorithm matrix
/opt/homebrew/bin/perl prototype/189-bin-counter-primitives.pl \
    --aspect v8 \
    --file logs/AccessLogs/really-big/localhost_access_log-twx01-twx-thingworx-0.2025-12-30.txt \
    --display-width 71 --candidate sweep

# V8 detail table — per-column comparison at a specific bpd
/opt/homebrew/bin/perl prototype/189-bin-counter-primitives.pl \
    --aspect v8 \
    --file logs/AccessLogs/really-big/localhost_access_log-twx01-twx-thingworx-0.2025-12-30.txt \
    --display-width 71 --bpd 500
```

`--display-width 71` matches the per-histogram bar area when `terminal_width=186` and `n=2` (duration + bytes histograms). Derivation: `display_width=int(186×0.95)=176`, `total_gap=6`, `single_histogram_width=85`, `bar_area_width=85-14=71`.

---

## V6 — Heatmap projection fidelity (initial attempt)

**What V6 measured:** mass retention, peak retention, peak X-axis offset when re-binning a streaming auto-resize partition (bpd=53 default) into a display-bound partition with `bin_count = $heatmap_width`. Compared against a synthetic "baseline" built directly from raw values at display geometry.

**Result on canonical 148MB dataset (display_width=52):**

| Candidate | Mass retention | Peak retention | Peak X-offset |
|---|---|---|---|
| (e) two-stage | 100.0000% | 100.0000% | 0 columns |
| (c) CDF-resample | 100.0000% | 100.0000% | 0 columns |

**What V6 missed:** the measurement was per-partition aggregate, not per-column. A 100% mass / 100% peak metric is satisfied by many distributions — including one with the peak's count split across an adjacent empty column and one neighbor (mass conserved, peak count preserved, position preserved, but spike-trough structure destroyed). V6 did not measure per-column counts and therefore could not detect this failure mode.

V6 was **insufficient** as a validation. It contributed to the original (and later-rejected) recommendation locking option (e) at bpd=53 with `bin_count = $heatmap_width`.

---

## V7 — Histogram projection fidelity (initial attempt)

**What V7 measured:** same aggregate metrics as V6, applied to histogram (single-partition global per metric).

**Result on canonical 148MB dataset (display_width=100):**

| Metric | (d) shipped | (e) two-stage | (c) CDF-resample |
|---|---|---|---|
| Display sum | 1,647,292 | 575,800 | 575,800 |
| True mass | 575,800 raw values | 575,800 | 575,800 |
| Peak count | 289,806 at col 0 | 289,806 at col 0 | 289,806.0 at col 0 |
| Peak retention | 100% (ref) | 100.0000% | 100.0000% |

**What V7 surfaced (unexpected):** ltl's shipped histogram is NOT mass-conserving when projecting onto the display. `calculate_histogram_display_buckets` in the `cols_per_bucket >= 1` branch maps `display[i] = partition[int(i / cols_per_bucket)]` — which **duplicates** each internal partition bucket's count across multiple display columns to render visually-wide bars. The shipped display sum (1,647,292) is ~2.86× the true raw count (575,800).

V7 surfaced this asymmetry but **incorrectly interpreted it** as evidence that (e) and (c) "preserve true mass exactly while shipped does not." That framing missed the more important question: **does the bar-width-stretching convention preserve visible histogram structure that the migration would otherwise destroy?**

V7's conclusions about "(e) preserves data fidelity exactly" turned out to be wrong at the per-column scale; V7 was unable to see this because it did not print per-column counts.

---

## V8 — Per-column comparison (the corrective measurement)

After the user flagged that V6/V7's aggregate metrics could not reveal smoothing artifacts, V8 was added to print every display column's count side-by-side: column index, legacy count (after `calculate_histogram_display_buckets`), (e) count, delta.

### V8 detail table at bpd=53 (default) — failure of the original (e) recommendation

Running V8 against "your file" at `--display-width 71 --bpd 53` produced a side-by-side table for all 71 columns. The spike region (cols 11-25 in the 6-50ms range):

```
col  val_lower    legacy  (e_W)   (e_coarse)  legacy_vs_e_coarse
11   6.13         19125   9406    19125       +0.0%
12   7.23         19125   7914    19125       +0.0%
13   8.53         14941   13215   14941       +0.0%
14   10.06        19889   5317    19889       +0.0% (at bpd=616 — at bpd=53 the e_coarse column had -20% displacement)
18   19.46        21241   11265   21241       +0.0% (the visible 21k peak from image 1)
19   22.95        21241   13990   21241       +0.0%
20   27.06        14711   5767    14711       +0.0%
```

**Two findings emerged from this detail table:**

1. **(e_W) — re-bin directly to display width — smooths the data.** The peak at col 18 (legacy 21241) shows as 11265 under (e_W) — roughly half height. This is the same failure mode as the reverted Phase 3 attempts (multi-modal spike-trough structure flattened).

2. **(e_coarse) — re-bin into legacy partition shape, then apply legacy's `calculate_histogram_display_buckets` projection — preserves the legacy exactly** in the spike region.

The (e_W) variant was the original locked recommendation from V6/V7. V8 rejected it empirically. The (e_coarse) variant became the new candidate.

### V8 sweep at bpd=53 with (e_coarse): bucket-level displacement

The (e_coarse) result above looked perfect in the spike region (+0.0% delta) but had displacement in mid-density buckets at bpd=53:

```
col  val_lower    legacy  (e_coarse)   delta
22   9.88         7594    5549         -26.9%
23   10.97        6063    8108         +33.7%
```

Adjacent buckets gain what their neighbors lose. The displacement happens because the streaming partition's bin boundaries don't align with the legacy partition's bin boundaries. When a streaming bin straddles a legacy bucket boundary, the geometric-midpoint re-bin commits the entire streaming bin's count to one side or the other — and ~25-35% of the legacy bucket's mass can be misallocated.

This led to the bpd sweep.

---

## V8 sweep — bpd × algorithm matrix

Sweep across all 9 locked tier values from #187 Decision 2 (bpd ∈ {4, 8, 16, 32, 53, 80, 115, 256, 616}), testing both geometric-midpoint and proportional-overlap re-bin algorithms, both datasets.

### Your file (5.08 decades, 41 legacy buckets)

| bpd | tier | geometric vis_max% | proportional vis_max% |
|---|---|---|---|
| 4 | L1 floor | 118.3% | 82.5% |
| 8 | L2 (current ltl default) | 110.8% | 76.3% |
| 16 | L3 | 100.0% | 89.9% |
| 32 | L4 | 27.6% | 15.9% |
| 53 | L5 (Decision 2 default) | 28.4% | 16.1% |
| 80 | L6 | 25.7% | 18.6% |
| 115 | L7 | 7.7% | 7.6% |
| 256 | L8 | 7.7% | 6.97% |
| **616** | **L9 / HdrHistogram 3-sig-digit** | **1.10%** | 3.49% |

### 148MB file (4.52 decades, 36 legacy buckets)

| bpd | tier | geometric vis_max% | proportional vis_max% |
|---|---|---|---|
| 4 | L1 floor | 5671.2% | 2703.2% |
| 8 | L2 | 55.1% | 1155.8% |
| 16 | L3 | 68.4% | 69.3% |
| 32 | L4 | 73.4% | 37.3% |
| 53 | L5 | 36.3% | 20.3% |
| 80 | L6 | 30.1% | 21.6% |
| 115 | L7 | 35.2% | 17.4% |
| 256 | L8 | 2.5% | 4.2% |
| **616** | **L9 / HdrHistogram 3-sig-digit** | **5.78%** | 2.99% |

### Findings from the sweep

1. **Re-bin error is much larger than per-bin midpoint error.** At Level 9 (bpd=616), the research-documented midpoint error is ~0.08%. Empirical re-bin error is 1.10% to 5.78% — roughly 14× to 72× larger. The Decision 2 tier table was calibrated for the **percentile interpolation** use case (Decision 1), not for **partition→partition re-binning**.

2. **Non-monotonic behavior is real.** Higher bpd is not always better. Streaming bin boundaries can align with target bucket boundaries at certain bpd values (resonance — exact match) and straddle at others. Examples on your file: bpd=500 shows 0.25%, bpd=750 shows 0.86%, bpd=1000 shows 2.22%, bpd=1500 shows 0.00%. The alignment depends on the streaming partition's `v_0` seed, which is data-dependent and unpredictable a priori.

3. **Proportional-overlap re-bin (mass splitting between target buckets) does not solve the problem.** It helps at some bpd values, hurts at others. At bpd=8 on the 148MB file it regresses catastrophically (1155% displacement) because too few streaming bins distribute mass too widely. The fundamental issue is that the streaming partition's `[min, max]` range is anchored around `v_0` (HdrHistogram seed) while the legacy partition is anchored to `[d_min, d_max]` — the ranges don't match by design.

4. **No value in the locked range 4-616 achieves sub-1% on both datasets.** Bpd=616 reaches 1.10% on your file but 5.78% on the 148MB file.

### Visibility-threshold reasoning

The 1% threshold I initially used was arbitrary. The actual perceptibility threshold in a ~9-character-tall ASCII histogram is roughly **11% of peak** (each character row = 100/9 ≈ 11.1% per row; smallest visible bar-height change is one row's worth).

Re-reading the sweep with that threshold:

| bpd | Your file (visible diff?) | 148MB file (visible diff?) |
|---|---|---|
| 53 (default) | YES — 28.4% (~3 rows) | YES — 36.3% (~3 rows) |
| 256 (Level 8) | NO — 7.7% (sub-1-row) | NO — 2.5% (sub-1-row) |
| **616 (Level 9)** | **NO — 1.10% (negligible)** | **NO — 5.78% (sub-1-row)** |

At histogram rendering height of 9 characters, **bpd=616 is below the visibility threshold on both datasets.** Higher rendering heights would tighten the threshold, but the default rendering and typical user-visible rendering are well within this margin.

---

## Locked recommendation

**Two-stage stream → finalize re-bin into legacy partition shape → apply legacy's display projection unchanged.**

**Scope: F2 (heatmap) and F3 (histogram) only.** F1 consumers (summary_table, csv_output, time_bucket_stats) are unaffected — they continue using Decision 2's default bpd=53. The bpd=616 streaming default below applies ONLY to display-geometry-bound consumers because their partition counts are bounded (~70 total). F1 partition counts are unbounded (one per `(category, log_key)`), and applying bpd=616 to F1 would multiply per-partition memory by ~12× — gigabytes of overhead on typical workloads.

- Streaming `bpd = 616` (Level 9, HdrHistogram 3-sig-digit reference, top of locked Decision 2 range) — **F2/F3 only**.
- Streaming `seed_decades = 5` (Decision 5 default).
- Finalize re-bin via `partition_rebin` (#189 R12) using geometric-midpoint projection (same algorithm as `partition_extend`'s existing remap loop at `ltl:613-622`).
- Finalize target partition shape:
  - **F2 (heatmap)**: `bin_count = $heatmap_width`, boundaries log-spaced over `[$heatmap_min, $heatmap_max]`.
  - **F3 (histogram)**: `bin_count = int(decades × histogram_buckets_per_decade)` (default 8 × decades), boundaries log-spaced over `[d_min, d_max]`. Same shape ltl computes today.
- Render: F2 reads finalized partition directly. F3 applies `calculate_histogram_display_buckets` (`ltl:7462`) unchanged for stretched-bar rendering.

### Memory cost at locked bpd=616 (F2/F3 only)

| Consumer | Partition count | Bytes/partition | Subtotal |
|---|---|---|---|
| Heatmap (F2) | ~60 time buckets | ~25KB | ~1.5 MB |
| Histogram (F3) | ~10 metrics | ~25KB | ~250 KB |
| **Total F2/F3** | ~70 partitions | | **~1.75 MB** |

Bounded by `bpd × decades`, not by sample count. Stays at ~1.75MB regardless of input file size.

**F1 consumers are NOT included in this table** — they continue using Decision 2 default (bpd=53), one partition per `(category, log_key)`. F1 memory is governed by Decision 2's existing analysis at ~2.5GB worst case for L9 (which is why L9 was always the analyst's opt-in lever for F1, never the default). The F2/F3 locked bpd=616 is decoupled from the F1 Decision 2 default; the two systems use the same primitives but different bpd settings tuned for their respective partition-count regimes.

### Validation against canonical datasets

V8 detail table at bpd=616 on "your file" (display_width=71): the entire spike region (cols 11-42, covering 6ms-1s where 95%+ of mass lives) showed **0.0% deviation** vs. legacy direct binning + legacy display projection. Three columns in the medium-density tail showed deviations of ±0.1-0.3% (within ±3 absolute counts on bars of ~2100). Spike-trough-spike multi-modal structure preserved exactly.

---

## What the prototyping journey taught us

1. **Aggregate metrics (mass, peak, X-offset) are not sufficient.** They can be satisfied while spike-trough structure is destroyed. Always print per-column / per-bucket counts when validating re-binning fidelity.

2. **The legacy histogram's "wide bars" are not mass-conserving by accident** — they're a deliberate rendering convention via count duplication in `calculate_histogram_display_buckets`. Any migration that puts each count into exactly one display column will render as "narrow spikes" instead of "wide bars." This is a real change, not a wash.

3. **Re-bin error compounds streaming bin width AND alignment with target boundaries.** The research's per-bin midpoint error (Decision 2 tier table) characterizes Decision 1 percentile interpolation accuracy, not partition→partition re-bin accuracy. The re-bin error is empirically 14-72× the midpoint error at the same bpd.

4. **Proportional-overlap re-bin is not a fix.** It can help when streaming bin count is in a sweet spot, but it makes things worse with very few or very many streaming bins, and it does not eliminate the alignment-resonance noise.

5. **The visibility threshold matters.** A 1% accuracy target is the right call for percentile interpolation but is overkill for ASCII histogram rendering. The right threshold is roughly "smaller than one character row of the rendered histogram" — at default 9-character height, that's ~11%, which makes bpd=256 viable and bpd=616 safely below visual perceptibility on all tested datasets.

6. **Streaming at the locked Level 9 (bpd=616) keeps the option of higher visual fidelity open** for follow-on UX work (see #204). Lowering the streaming bpd would close that option without a memory benefit that matters at the ~70-partition scale.
