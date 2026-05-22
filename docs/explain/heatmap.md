# LogTimeLine Heatmap Reference

This page is the canonical reference for ltl's heatmap visualization (`-hm`). It mirrors the content of `ltl --explain heatmap`.

For a long-form explanation directly from the terminal, run `ltl --explain heatmap`. For the index of available `--explain` topics, run `ltl --explain`.

---

## What it is

The heatmap (`-hm`) replaces the per-bucket latency statistics column with a color-intensity visualization showing how values are distributed *within* each time bucket. Where percentile statistics collapse a distribution to a handful of numbers, the heatmap reveals its full shape — bimodal distributions, shifting modes over time, outlier clustering, long tails, and rare-but-extreme events all become visually apparent at a glance.

Each row of the heatmap is one time bucket. Each cell in the row represents a logarithmic value range. Cell color intensity is proportional to the number of entries in that range.

---

## How to read it

Reading the heatmap left-to-right:

- **X-axis**: logarithmic across the metric's full observed range. The smallest values are on the left, the largest on the right. The footer scale labels show the actual numeric value at 0%, 25%, 50%, 75%, and 100% of the X-axis width.
- **Rows**: each row corresponds to one time bucket from the timeline. The rows align with the rows of the bar graph on the left of the screen.
- **Per-row percentile markers** (P50, P95, P99): rendered as inline `|` characters in gray at the column position where that percentile falls for THAT bucket. Markers shift left or right as latency profiles change over time.
- **Color gradient**: metric-specific.
  - `-hm duration` — yellow gradient
  - `-hm bytes` — green gradient
  - `-hm count` — cyan gradient
- **Cell color saturation**: darker / more saturated cells indicate more entries in that value range; lighter cells indicate fewer. Empty cells (no observations) render as blank.

### Example

```text
    08:00  █████████████|███████|███ |
    08:05   █████████████████|████████████|████ |
    08:10    █████████████████████████|████████████████|██████ |
    08:15         ████████████████████████|████████████████████████|████ |
    08:20       █████████████████████████████|██████████████████ █████████████|████ |
    08:25   ████████████████████|██████████        ███████████████|████ |
          1ms───────────────10ms────────────────100ms───────────────1s─────────────────10s
```

In the example, rows show how latency distribution evolves over half an hour: a tight low-latency cluster at 08:00 broadens by 08:10, becomes **bimodal** at 08:15 (two distinct clusters — possibly cache-hit vs. cache-miss), then develops a **tail runaway** at 08:20 where outliers reach into the seconds.

---

## What to look for

The heatmap surfaces patterns that summary statistics cannot.

1. **Bimodal distributions** — Two distinct vertical color bands in a row indicate two value populations (cache hit / cache miss, queued / unqueued, authenticated / unauthenticated).
2. **Mode drift over time** — The brightest band in each row sliding left or right as you scan top-to-bottom signals latency degradation or improvement.
3. **Tail growth** — Entries appearing in the rightmost columns where they weren't before signal new outliers (lock contention, GC pauses, retry storms).
4. **Hot-spot clusters** — A concentrated bright region across many rows in the same column range indicates a recurring value cluster.
5. **Sparse vs dense rows** — Some time buckets may show only a thin horizontal slice while others span a wide range; that's variance shifting over time.

---

## Common flag combinations

```text
ltl -hm duration access.log                   # duration heatmap (yellow gradient)
ltl -hm bytes access.log                      # bytes heatmap (green gradient)
ltl -hm count access.log                      # count heatmap (cyan gradient)
ltl -hm duration -hmw 80 access.log           # wider heatmap (80 cells vs default 52)
ltl -hm duration -bs 5 access.log             # 5-minute time buckets for finer-grained view
ltl -hm duration -lbg access.log              # palette tuned for light terminal backgrounds
ltl -hm duration -dbg access.log              # force dark palette regardless of auto-detect
```

---

## Notes

- The X-axis is **logarithmic**, so equal visual spacing represents an exponential range of values. A cell at the right of the chart represents values 10× to 100× larger than a cell at the same visual position one decade left.
- **Color rendering depends on terminal support.** Modern Unix terminals and Windows Terminal display the 256-color gradient correctly. Legacy Windows CMD with `more` shows monochrome cells; the layout and gridline structure remain readable.
- When the heatmap and histogram are both active (`-hm` and `-hg` together), the heatmap renders inline in the bar-graph rows and the histogram renders as a separate panel below.

---

## How ltl renders this

Cell positions span the full observed value range on a logarithmic scale: each row uses the same column-to-value mapping, so a cell at a given horizontal position represents the same value across every time bucket. Per-bucket counts determine each cell's color intensity, mapped to an 8-step gradient in the metric's color (yellow for duration, green for bytes, cyan for count). The per-row percentile markers and the summary-table p99/p999 values are computed from the same observations, so the markers and the printed percentile statistics agree by construction. The heatmap width is controlled by `-hmw` (default 52 cells); narrower widths trade horizontal resolution for screen real estate.

---

## See also

- `ltl --explain histogram` — aggregate distribution chart with percentile tick marks
- `ltl --explain percentiles` — what p50, p95, p99, p999 mean and how to read them
- `ltl --explain skewness`, `ltl --explain kurtosis`, `ltl --explain bimodality_coef` — distribution-shape statistics for cross-reference
- Flags: `-hm`, `-hmw`, `-bs`, `-lbg`, `-dbg`
