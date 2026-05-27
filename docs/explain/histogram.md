# LogTimeLine Histogram Reference

This page is the canonical reference for ltl's histogram visualization (`-hg`). It mirrors the content of `ltl --explain histogram`.

For a long-form explanation directly from the terminal, run `ltl --explain histogram`. For the index of available `--explain` topics, run `ltl --explain`.

---

## What it is

The histogram (`-hg`) renders a single distribution chart showing how often each value range occurs across the entire log — not split per time bucket like the heatmap. Where the heatmap surfaces *temporal* shape, the histogram surfaces *aggregate* shape: the full distribution's body, modes, tails, and percentile structure visible at once.

Bars rise from the X-axis to indicate frequency at each value range. The percentile tick marks along the bottom show exactly where p50, p95, p99, and p99.9 fall on the distribution.

---

## How to read it

The histogram has a **dual Y-axis**:

- **Left axis** (`Count`): absolute count of observations falling in each bucket.
- **Right axis** (`%`): the same expressed as a percentage of total observations.

Both axes track each other — count and percent describe the same bar — but the percentage axis gives a scale-free way to read the shape regardless of total volume.

**X-axis**: logarithmic across the full observed value range, same convention as the heatmap.

**Bar heights**: 8-level sub-character resolution (full block down through 7/8, 6/8, …, 1/8 block) so bars at intermediate heights render distinct intensities.

**Baseline tick marks** (along the bottom border):

- `┬` (down-pointing) at each labeled bucket boundary — pointing down to the X-axis value label below.
- `┴` (up-pointing) at each percentile position — pointing up into the chart. These mark where P50, P95, P99, and P99.9 actually fall on the distribution. They are the visual anchor for the legend values shown beneath the chart, letting you cross-reference the legend's numeric values to the corresponding column of the histogram at a glance.

### Example

```text
     Count                                                                  %
      1247├──────────────────▄▄▄▄█████▄▄────────────────────────────────────────┤ 100%
          │               ▄▄█████████████▄▄                              │     
       935├─────────────▄▄████████████████▄▄───────────────────────────────────┤  75%
          │           ▄▄████████████████████▄▄                          │     
       624├─────────▄▄█████████████████████████▄▄───────────────────────────────┤  50%
          │       ▄▄█████████████████████████████▄▄   ▄▄▄                │     
       312├─────▄▄█████████████████████████████████▄▄▄███▄▄▄───▄▄─────────┤  25%
          │▄▄▄▄▄███████████████████████████████████████████▄▄▄██▄▄▄▄▄▄▄▄▄▄│     
          └┬─────────┬─────────┬───┴─────┬──────┴──┬───┴─────┬┴────┬───┘
           1ms       5ms       50ms      500ms     5s        50s   500s

                  P50: 47ms   P95: 320ms   P99: 1.2s   P99.9: 4.5s
```

The shape shows a right-skewed distribution with peak around 50ms, the body decaying through 100ms, a small secondary cluster around 5s (tail-runaway signature), and percentile ticks anchored to specific X-axis positions: P50 is on the descending side of the peak (50ms), P95 well into the body tail (~320ms), P99 at the secondary cluster, and P99.9 at the far right.

---

## What to look for

The histogram is the chart for answering "what does the distribution actually look like?" Read it as you would any frequency chart, but two ltl-specific patterns deserve special attention.

1. **Log-scale tail interpretation.** A small bar at the far right represents a small number of *very large* values — those bars are diagnostically valuable even when short, because the X-axis is exponential.

2. **Percentile-tick alignment.**
   - P50 should fall on or near the tallest bar (the mode). When P50 is far from the peak, the distribution is highly skewed and the mean is unreliable.
   - When P95 and P99 are far apart on the X-axis (multiple decades), the tail is fat — common signature of GC pauses, lock contention, or retry storms.
   - When P99 and P99.9 are visually adjacent, the worst-case is dominated by a small cluster of consistent outliers; when far apart, the worst-case is dominated by one or two extreme events.

---

## Common flag combinations

```text
ltl -hg duration access.log                   # duration histogram (single metric)
ltl -hg bytes access.log                      # bytes histogram (response sizes)
ltl -hg count access.log                      # count histogram (per-bucket entry counts)
ltl -hg duration,bytes access.log             # multiple histograms in one invocation
ltl -hg duration -hgw 50 access.log           # narrow histogram (50% of terminal)
ltl -hg duration -hgh 16 access.log           # taller histogram (16 rows vs default 8)
ltl -hg duration -h "/api/v2/" access.log     # overlay highlight of matching entries
ltl -hg duration -dmp 7 access.log            # tighter precision (slower)
```

---

## Notes

- The X-axis log scale means that visual distance between bars represents an exponential, not linear, gap in actual value. Two bars that look the same width apart on the screen could represent a 10× difference at one part of the chart and a 100× difference at another.
- When `-hg` is invoked alongside the bar graph (default), the histogram renders as an additional panel below the timeline. When `-hg` is invoked with multiple metrics (`-hg duration,bytes`), each metric gets its own histogram panel stacked vertically.
- **Highlight overlays** (`-h pattern`) draw colored sub-bars within each main bar showing the proportion of matched entries. The highlight percentile legend appears below the main legend in highlight color.
- **Color rendering depends on terminal support.** Modern Unix terminals and Windows Terminal display the gradient correctly. Legacy Windows CMD with `more` shows monochrome bars; the layout and percentile ticks remain readable.

---

## How ltl renders this

The histogram uses log-spaced bins with HDR-histogram-style precision. Bin-counter resolution is controlled by `--data-model-precision` (tier 1..9, default 5); higher tiers give finer resolution. The histogram width (default 95% of terminal) and height (default 8 rows) are tunable via `-hgw` and `-hgh`. Highlight overlays (`-h regex`) render colored sub-bars within each main bar, showing the proportion of highlighted entries at each value range. The percentile tick marks on the baseline are computed from the same observations as the summary-table p99/p999 values, so the visual ticks and the numeric statistics agree by construction.

---

## See also

- `ltl --explain heatmap` — temporal distribution per time bucket
- `ltl --explain percentiles` — what p50, p95, p99, p999, p9999, p99999 mean and how to read them
- `ltl --explain iqr` — the body-spread statistic that pairs with p25/p75
- `ltl --explain skewness`, `ltl --explain kurtosis`, `ltl --explain bimodality_coef` — distribution-shape statistics that quantify what the histogram shows
- Flags: `-hg`, `-hgw`, `-hgh`, `-dmp`
