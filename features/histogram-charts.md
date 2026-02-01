# Feature: Histogram Charts for Key Metrics

## Overview

Add ASCII terminal histogram charts that visualize the value distribution of key metrics (duration, bytes, count) across all processed log entries. Unlike the time-series heatmap which shows how values change over time, histograms show the overall shape of the data distribution.  Data points are sorted and counted in buckets or bins of a specific size where the amount of data points counted in a bucket represents the height of the bar which will be draw.  The Y-axis then represents the number of data points (in absolute or relative terms), and the X-axis represents the range of values.

## Goals

1. Provide at-a-glance distribution visualization for duration, bytes, and count metrics
2. Help users quickly identify common value ranges, outliers, and distribution patterns (normal, bimodal, long-tail)
3. Complement existing percentile statistics with visual representation
4. Maintain consistent command-line interface patterns with existing features (especially heatmap)

## Requirements

### Command Line Interface

| Option | Description |
|--------|-------------|
| `-hg` or `--histogram` | Enable histogram output (no argument = all available metrics) |
| `-hg duration` | Show only duration histogram |
| `-hg bytes` | Show only bytes histogram |
| `-hg count` | Show only count histogram |
| `-hg duration,bytes` | Show specific metrics (comma-separated) |
| `-hgw <N>` or `--histogram-width <N>` | Set histogram display width as percentage of terminal (default: 95) |
| `-hgh <N>` or `--histogram-height <N>` | Set histogram height in rows/lines (default: 10) |
| `-hgbpd <N>` | Buckets per decade for precision control (default: 8) |
| `-hgb <N>` | Override: use exactly N buckets total |

Multiple uses of command line options for -hg should be additive in case the overall environment states displaying -hg duration, and the user adds -hg bytes then both duration and bytes should be included.

### Verbose Output (-V flag)

When the `-V` (verbose) flag is used with histograms enabled, output bucket calculation details for each metric:

```
Histogram bucket calculation:
  Duration: samples=48,293, min=1ms, max=97.2s, range=4.99 decades, buckets_per_decade=8, total_buckets=40
  Bytes:    samples=48,293, min=128B, max=12.4MB, range=4.99 decades, buckets_per_decade=8, total_buckets=40
  Count:    samples=12,847, min=1, max=847, range=2.93 decades, buckets_per_decade=8, total_buckets=24
```

This helps users understand the data population and how bucket counts were derived, and supports tuning via `-hgbpd` if needed.

### Output Placement

- Histograms appear **after** the time-based bar graph
- Histograms appear **before** the options output section
- Multiple histograms display **side by side**, centered in terminal
- Metrics with no data are omitted (remaining histograms expand to fill space)

### Layout Order and Colors

Histograms follow the same layout order and color scheme as the bar graph columns:

| Position | Metric | Color | Notes |
|----------|--------|-------|-------|
| 1 (left) | Duration | Yellow | Matches bar graph duration column |
| 2 (center) | Bytes | Green | Matches bar graph bytes column |
| 3 (right) | Count | Cyan | Matches bar graph count column |

If a metric has no data, it is omitted and remaining histograms shift to fill the space while maintaining their relative order (e.g., if only bytes and count have data, bytes appears left, count appears right).

### Visual Design

```
                     Duration Distribution                                         Bytes Distribution
 Count                                                %                 Count                                         %
 1247 ─┤          ██                              ├─ 100%               523 ─┤     ██                             ├─ 100%
       │         ████                             │                          │    ████                            │
       │        ██████                            │                          │   ██████  ██                       │
  623 ─┼       ████████ ▄▄                        ├─  50%               261 ─┼  ████████████                      ├─  50%
       │      ██████████████                      │                          │ ██████████████                     │
       │ ▂▂  ████████████████ ▂▂                  │                          │██████████████████ ▂▂               │
    0 ─┤▁▁▁▁██████████████████████▁▁              ├─   0%                 0 ─┤████████████████████████▁           ├─   0%
       └─┬────┬────┬────┬────┬────┬─┘                                        └─┬────┬────┬────┬────┬────┬─┘
        1ms 10ms 100ms 1s  10s 100s                                           1KB 10KB 100KB 1MB 10MB 100MB
       P50: 127ms   P90: 892ms                                               P50: 45KB    P90: 234KB
       P99: 4.2s    P99.9: 12.3s                                             P99: 1.2MB   P99.9: 8.7MB
```

**CRITICAL REQUIREMENT**: Vertical bars must be continuous pillars from bottom to top with no whitespace gaps. The mockup above is illustrative only - actual bar rendering fills solidly upward. Final visual design requires architect approval before implementation.

#### Bar Characters (8 levels per character height)

Use Unicode block elements for sub-character resolution:

| Character | Unicode | Fill Level |
|-----------|---------|------------|
| ` ` (space) | U+0020 | 0/8 (empty) |
| `▁` | U+2581 | 1/8 |
| `▂` | U+2582 | 2/8 |
| `▃` | U+2583 | 3/8 |
| `▄` | U+2584 | 4/8 (half) |
| `▅` | U+2585 | 5/8 |
| `▆` | U+2586 | 6/8 |
| `▇` | U+2587 | 7/8 |
| `█` | U+2588 | 8/8 (full) |

This provides 8 levels of resolution per character row, enabling smooth gradients and accurate representation even with limited vertical height.

#### Chart Axes Characters

Characters for use in drawing the axes should be all contained in an in-memory data structure ready to be used to draw the axis differently depending on line and tick mark configuration.

Configurations should be available to easily change the internal and external tick marks and length.  The section below specifying the Y-axis should be used as the example of what might be configurable, as the proposed axis drawing has inconsistent application of the tick marks (inside/outside) for both of the Y-axis and at the different levels.  Configuration should hence existing for Y-axis left, Y-axis right, and X-axis.

Corner characters connecting the X and Y axis should also be included and configurable through a sub-local variable.

### Other Metric Support

The *count* metric included here is an example of a custom metric not typical to standard log analysis but which has been added to logs for specific usage and load pattern detailed analysis.  As this tool evolves, as well as its adoption and broader use, other custom metrics will be added - especially a feature request to specify a custom metric name at runtime and have that calculated and treated as the in-built ones.

Given this situation, the histogram data model, layout design, command line options, and all other requirements should plan for the fact that in the future it is a CERTAINTY that other metrics will exist and require their own treatment (color, placement, units, etc.).

#### Color Gradient Bars

Use existing 8-level heatmap color gradients to color the bars based on count density:
- Duration: Yellow gradient (58, 94, 136, 142, 178, 184, 220, 226)
- Bytes: Green gradient (22, 28, 34, 40, 46, 82, 118, 154)
- Count: Cyan gradient (23, 30, 37, 44, 51, 80, 86, 123)

Each bar column's color intensity reflects the count in that bucket relative to the maximum bucket count. This is an optional enhancement to be tested for visual appeal.  Other custom metrics would leverage the other defined color gradients.

Color gradients should support light background detection used in the heatmap.  If that heatmap pattern is not made common/global to the whole application, then it should become generalized so that this feature only needs to reference the detected color gradient variables and not bother itself with doing the detection.

#### Y-Axes (Dual)

**Left Y-axis (Count):**
- Maximum value at top with tick mark pointing left (`─┤`)
- Midpoint value with tick mark pointing left (`─┼`)
- Zero at bottom with tick mark pointing left (`─┤`)

**Right Y-axis (Percentage):**
- 100% at top with tick mark pointing right (`├─`)
- 50% at midpoint with tick mark pointing right (`├─`)
- 0% at bottom with tick mark pointing right (`├─`)

#### X-Axis

- Corner character (`└`) at origin (bottom-left)
- Corner character (`┘`) at bottom-right to enclose the frame
- Downward-facing tick markers (`┬`) aligned with bucket boundaries
- Labels showing bucket boundary values using smart formatting:
  - Duration: 1ms, 10ms, 100ms, 1s, 10s, 100s
  - Bytes: 1KB, 10KB, 100KB, 1MB, 10MB
  - Count: 1, 10, 100, 1K, 10K, 100K
- Logarithmic scale (no linear option)

#### Legend (Below Histogram)

Display population-wide percentiles below each histogram on a single centered line, dynamically selecting which percentiles to show based on available width.

**Configurable spacing variables:**
- `$histogram_legend_spacing` - vertical gap between histogram bottom and legend
- `$histogram_gap` - horizontal padding between adjacent histograms

**Percentile Selection:**

Percentiles are selected based on a priority order reflecting SRE and performance analysis best practices. The selection algorithm takes percentiles from this priority list until the available width is exhausted, then displays them in ascending order.

| Priority | Percentile | Rationale |
|----------|------------|-----------|
| 1 | P50 (median) | The typical user experience; always the most important baseline |
| 2 | P99 | Critical for SLO/SLA monitoring; catches "1 in 100" degraded experiences |
| 3 | P99.9 | Important for high-volume systems (1 in 1,000 requests); tail behavior |
| 4 | P95 | Common SLO target; fills the gap between P50 and P99 |
| 5 | P90 | Shows where "good" experiences end; only after P95/P99 for finer granularity |
| 6 | P75 | Upper quartile; helps understand distribution shape |
| 7 | P99.99 | For very high-volume systems (1 in 10,000 requests) |
| 8 | P25 | Lower quartile; shows "fast path" performance |
| 9 | P10 | Best-case typical performance |
| 10 | P1 | The fastest requests; understanding the floor |

**Selection Algorithm:**
1. Start with empty selection
2. For each percentile in priority order, check if adding it (with separator) fits in available width
3. If it fits, add to selection
4. After all percentiles checked, sort selection by ascending percentile value
5. Display as single centered line with 3-space separators

**Example outputs at various widths:**
```
# Narrow (50 chars): 4 percentiles
P50: 11ms   P90: 697ms   P95: 2.1s   P99: 10.3s

# Medium (120 chars): 6 percentiles
P50: 11ms   P90: 697ms   P95: 2.1s   P99: 10.3s   P99.9: 45.2s   P99.99: 1.2m

# Wide (250 chars): 8+ percentiles
P10: 2ms   P25: 5ms   P50: 11ms   P75: 89ms   P90: 697ms   P95: 2.1s   P99: 10.3s   P99.9: 45.2s
```

**Legend layout:**
- Single line, centered under histogram
- Percentiles displayed in ascending order (e.g., `P50: 127ms   P90: 892ms   P99: 4.2s`)
- 3-space separator between percentile entries
- Maximum one decimal place (omit if zero, e.g., "4s" not "4.0s")

These represent percentiles for the **entire population** of values, distinct from the time-bucket or message-based percentiles shown elsewhere.

### Data Collection

New data structures use hashes containing arrays to support dynamic metric addition:

```perl
# Raw value arrays (populated during parsing)
# Keys: 'duration', 'bytes', 'count', and future metric names
my %histogram_values = (
    duration => [],
    bytes    => [],
    count    => [],
);

# Computed histogram buckets (populated before output)
# Each array contains count per bucket
my %histogram_buckets = (
    duration => [],
    bytes    => [],
    count    => [],
);

# Bucket boundaries (logarithmic scale)
# Each array has bucket_count+1 elements (boundaries[0]=min, boundaries[N]=max)
my %histogram_boundaries = (
    duration => [],
    bytes    => [],
    count    => [],
);
```

This hash-based structure allows new metrics to be added programmatically without code changes to the core histogram logic.

### Bucket Calculation

1. **Determine range**: Find global min/max across all values
2. **Calculate dynamic range**: Number of decades (orders of magnitude) the data spans
3. **Calculate bucket count**: `decades × buckets_per_decade`
4. **Calculate logarithmic boundaries**:
   - `boundary[i] = min * (max/min)^(i/num_buckets)`
5. **Assign values to buckets**: Binary search for efficiency with large datasets
6. **Display scaling**: Render each bucket across multiple characters if display width exceeds bucket count

### Bucket Count Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-hgbpd <N>` | 8 | Buckets per decade (order of magnitude) |
| `-hgb <N>` | (auto) | Override: use exactly N buckets total |

**Bucket count is derived from data range:**
- Calculate decades: `log10(max) - log10(min)`
- Total buckets: `decades × buckets_per_decade`
- Example: latency from 1ms to 100s = 5 decades × 8 = 40 buckets

**Precision levels:**
| Buckets/Decade | Precision | Use Case |
|----------------|-----------|----------|
| 4 | ~10% | Quick overview, narrow displays |
| 8 | ~5% | Default, good balance |
| 16 | ~2.5% | Detailed analysis, wide displays |

**Display width vs bucket count**: These are decoupled. A 200-character wide histogram with 40 buckets renders each bucket as 5 characters wide. This provides visual prominence while maintaining statistical validity.

### Layout Calculation

1. Get terminal width from global variable
2. Calculate total display width: `terminal_width * (histogram_width_percent / 100)`
3. Determine which metrics have data (in order: duration, bytes, count)
4. Count active histograms (N)
5. Calculate inter-histogram spacing: `$histogram_gap` (configurable padding between histograms)
6. Calculate total spacing needed: `(N - 1) * $histogram_gap`
7. Calculate legend height: `$histogram_legend_spacing` + number of legend rows needed
8. Calculate available width for histograms: `display_width - total_spacing`
9. Calculate individual histogram width: `available_width / N`
10. For each histogram, calculate internal layout:
    - Left Y-axis label width (count values)
    - Left Y-axis tick/line width
    - Bar area width (determines bucket count)
    - Right Y-axis tick/line width
    - Right Y-axis label width (percentage)
11. Calculate legend row count (minimize rows while fitting P50, P90, P99, P99.9 with labels/values)
12. Calculate total histogram group width: `(N * histogram_width) + ((N - 1) * $histogram_gap)`
13. Calculate centering offset: `(terminal_width - total_group_width) / 2`

### Color Scheme

Match bar graph column colors for consistency:
- Duration: Yellow (column 2 color)
- Bytes: Green (column 3 color)
- Count: Cyan (column 4 color)

## Non-Requirements (Out of Scope)

- Highlight filter support (future enhancement)
- User-defined bucket boundaries (future enhancement)
- CSV output of histogram data (future enhancement)
- Linear scale option (removed - logarithmic only)

## Acceptance Criteria

1. [x] `-hg` flag enables histogram output with all available metrics
2. [x] `-hg <metric>` enables histogram for specific metric(s)
3. [x] Histograms display after bar graph, before options output
4. [x] Multiple histograms display side by side, centered
5. [x] Histogram order follows bar graph column order: duration, bytes, count
6. [x] Histogram colors match bar graph column colors
7. [x] Metrics with no data are omitted from display
8. [x] Vertical bars use 8-level Unicode block characters
9. [x] Left Y-axis shows count with dynamic tick marks
10. [x] Right Y-axis shows percentage with dynamic tick marks
11. [x] X-axis has tick markers aligned with bucket boundary labels
12. [x] Logarithmic bucket scaling works correctly
13. [x] Legend shows percentiles for entire population with priority-based selection
14. [x] Works with all log formats that provide duration/bytes/count
15. [x] Color gradients are used for displaying the bars, but can be disabled and switched to solid color
16. [x] Light background support has been added for automatically switching color gradients on light terminals
17. [x] Histogram section display height is configurable from a command line option
18. [x] Dynamic height scaling based on terminal height (4-15 rows)
19. [x] Progress messages and timing displayed for histogram statistics

## Test Plan

### Unit Tests

1. Bucket boundary calculation with various min/max ranges
2. Value-to-bucket assignment accuracy
3. Bar character selection for various fill levels
4. Layout calculation for 1, 2, and 3 histograms
5. Percentile calculation for population-wide statistics

### Integration Tests

1. Run with access logs (duration + bytes): `./ltl -hg logs/AccessLogs/localhost_access_log.2025-03-21.txt`
2. Run with ThingWorx ScriptLogs (all metrics): `./ltl -hg logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log`
3. Run with logs containing count metric: `./ltl -hg count logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log`
4. Verify single histogram centers properly
5. Verify two histograms display side by side
6. Verify three histograms display correctly
7. Verify layout order matches bar graph column order

### Visual Verification

1. Y-axis labels (min/mid/max on left, 0%/50%/100% on right) align with tick marks
2. X-axis bucket labels align with tick marks
3. Legend percentiles display correctly below each histogram
4. Colors match bar graph column colors (yellow, green, cyan)
5. Bar heights accurately represent data distribution
6. Optional color gradients enhance readability (if implemented)

## Research & References

### Logarithmic Histogram Bucket Selection

#### Why Traditional Bin Selection Rules Don't Apply

Traditional histogram bin selection methods (Sturges, Rice, Scott, Freedman-Diaconis) are designed for **linear histograms** with equal-width bins. They calculate an optimal fixed bin width based on data characteristics like sample size, standard deviation, or interquartile range.

These methods are **not applicable** to logarithmic histograms because:
- They assume equal-width bins in the value space
- Logarithmic bins have exponentially increasing widths
- The "bin width" concept doesn't translate to log scale

For latency and performance data that spans multiple orders of magnitude, **logarithmic binning is the correct approach** - but it requires a different method for determining bucket count.

#### Industry Standard: HdrHistogram Approach

[HdrHistogram](https://github.com/HdrHistogram/HdrHistogram), created by Gil Tene and widely adopted in performance analysis tools, uses a **log-linear** bucketing approach that is the industry standard for latency histograms.

**Key insight from HdrHistogram:**
> "Internally, data in HdrHistogram variants is maintained using a concept somewhat similar to that of floating point number representation: Using an exponent and a (non-normalized) mantissa to support a wide dynamic range at a high but varying (by exponent value) resolution."

This means:
- **Exponentially increasing bucket ranges** (like our logarithmic scale)
- **Linear sub-buckets within each exponential range** for precision
- Bucket count is determined by **dynamic range** and **precision level**

#### Buckets Per Decade Model

From the [wingolog HDR histogram analysis](https://www.wingolog.org/archives/2023/12/10/a-simple-hdr-histogram):

> "A log-linear bucket spacing has two parts: a logarithm of the value to cover a large dynamic range with a few bits... Linear, evenly spaced buckets between logarithms provide more precision. **4 buckets per log are enough for 10% precision; 32 buckets per log gives 1% precision.**"

This gives us a principled approach:
1. Calculate the **dynamic range** (number of decades/orders of magnitude)
2. Choose a **buckets per decade** value based on desired precision
3. Total buckets = decades × buckets_per_decade

**Example:**
- Latency range: 1ms to 100s
- Decades: log₁₀(100000) - log₁₀(1) = 5 decades
- At 8 buckets/decade: 5 × 8 = 40 buckets total

#### Precision Levels

| Buckets/Decade | Relative Precision | Use Case |
|----------------|-------------------|----------|
| 4 | ~10% | Quick overview, constrained displays |
| 8 | ~5% | **Default** - good balance of detail and clarity |
| 16 | ~2.5% | Detailed analysis, wide displays |
| 32 | ~1% | High-precision analysis |

The precision represents the minimum distinguishable difference between values within a decade. At 8 buckets/decade, values must differ by ~5% to land in different buckets.

#### Why This Works for SRE Analysis

1. **Adapts to data range** - narrow range (1ms-100ms) gets fewer buckets than wide range (1ms-100s)
2. **Consistent resolution across magnitudes** - same relative precision at 10ms as at 10s
3. **Natural fit for log-scale X-axis** - bucket boundaries align with logarithmic display
4. **Decoupled from display width** - statistical bucketing is independent of visual rendering

**Sources:**
- [HdrHistogram - GitHub](https://github.com/HdrHistogram/HdrHistogram)
- [A simple HDR histogram - wingolog](https://www.wingolog.org/archives/2023/12/10/a-simple-hdr-histogram)

### Unicode Block Elements

The Unicode Block Elements range (U+2580-U+259F) provides the characters needed:
- Lower blocks: `▁▂▃▄▅▆▇█` (U+2581-U+2588)
- These are widely supported in modern terminal emulators

### Box Drawing Characters

Complete set for axes, tick marks, and corners:

| Character | Unicode | Description |
|-----------|---------|-------------|
| `─` | U+2500 | Horizontal line |
| `│` | U+2502 | Vertical line |
| `┌` | U+250C | Top-left corner |
| `┐` | U+2510 | Top-right corner |
| `└` | U+2514 | Bottom-left corner |
| `┘` | U+2518 | Bottom-right corner |
| `├` | U+251C | Right-facing T (left side ticks) |
| `┤` | U+2524 | Left-facing T (right side ticks) |
| `┬` | U+252C | Down-facing T (top/X-axis ticks) |
| `┴` | U+2534 | Up-facing T (bottom ticks) |
| `┼` | U+253C | Cross (midpoint ticks) |

### Block Characters (8 levels per character height)

| Character | Unicode | Fill Level |
|-----------|---------|------------|
| ` ` | U+0020 | 0/8 (empty) |
| `▁` | U+2581 | 1/8 |
| `▂` | U+2582 | 2/8 |
| `▃` | U+2583 | 3/8 |
| `▄` | U+2584 | 4/8 (half) |
| `▅` | U+2585 | 5/8 |
| `▆` | U+2586 | 6/8 |
| `▇` | U+2587 | 7/8 |
| `█` | U+2588 | 8/8 (full) |

### Similar Tools

- `spark` - Sparkline generator using block characters
- `gnuplot` - Can output ASCII histograms
- `termgraph` - Python terminal graphing library

## Future Enhancements

1. **Highlight support**: Show filtered subset distribution overlaid on full distribution
2. **Custom bucket boundaries**: Allow users to specify bucket ranges via command line
3. **Cumulative distribution**: Show CDF alongside histogram
4. **CSV export**: Include histogram bucket data in CSV output
5. **Percentile markers on chart**: Visual indicators (e.g., vertical lines or markers) showing P50/P90/P99/P99.9 positions directly on the histogram bars

## Progress Tracking

| Task | Status | Notes |
|------|--------|-------|
| Feature document created | Done | |
| GitHub issue created | Done | [#25](https://github.com/gregeva/logtimeline/issues/25) |
| Implementation plan | Done | `features/histogram-charts-implementation-plan.md` |
| Prototype | Done | `prototype/histogram-prototype.pl` |
| HdrHistogram bucket calculation | Done | Buckets-per-decade model implemented in prototype |
| Display scaling | Done | Decoupled bucket count from display width |
| X-axis label alignment verified | Done | Labels correctly aligned with log-scale bucket boundaries |
| Implementation | Done | All phases complete |
| Testing | Done | Visual verification complete |
| Documentation | In Progress | Feature doc updated, help text and release notes pending |

## Decisions Log

| Decision | Rationale | Date |
|----------|-----------|------|
| Vertical bar orientation | Classic histogram look, allows dual Y-axes | 2026-01-25 |
| 8-level Unicode blocks | Maximum resolution per character row | 2026-01-25 |
| Logarithmic scale only | Better for latency/size data; linear removed from scope | 2026-01-25 |
| Side-by-side layout | Efficient use of terminal width, easy comparison | 2026-01-25 |
| Separate from heatmap | Different purpose: overall distribution vs time-series | 2026-01-25 |
| Highlight as future | Keep initial implementation focused | 2026-01-25 |
| Dual Y-axes with 3 tick marks | Count (left) and percentage (right) for context | 2026-01-25 |
| Population percentiles in legend | P50/P90/P99/P99.9 for entire dataset, not time-based | 2026-01-25 |
| Optional color gradient bars | Reuse heatmap gradients, test for visual appeal | 2026-01-25 |
| Layout order matches bar graph | Duration, bytes, count (left to right) for consistency | 2026-01-25 |
| Colors match bar graph columns | Yellow, green, cyan to maintain visual consistency | 2026-01-25 |
| Color gradient bars should be configurable, but required | Reuse heatmap gradients, test for visual appeal | 2026-02-01 |
| Configurable height is initial requirement | Default 10 rows, `-hgh <N>` option | 2026-02-01 |
| Legend placement below histogram | Better fit for narrow terminals, use minimum rows | 2026-02-01 |
| Hash-based data model | Dynamic metric support via `%histogram_values`, `%histogram_buckets`, `%histogram_boundaries` | 2026-02-01 |
| Enclosed X-axis frame | Both `└` (left) and `┘` (right) corners for complete frame | 2026-02-01 |
| 1:1 bucket-to-character mapping | ~~Finest granularity~~ **SUPERSEDED** - now decoupled; bucket count is statistical, display width scales rendering | 2026-02-01 |
| Automatic X-axis label reduction | Reduce labels based on space/length to avoid overlap | 2026-02-01 |
| Auto-reduce histogram count for narrow terminals | Prioritize duration > bytes > count; user can override with explicit `-hg <metric>` | 2026-02-01 |
| Heavy box drawing characters preferred | Heavy set (`┃━┣┫┳┻╋┏┓┗┛`) renders better than light set on most terminals; configurable via `$box_drawing_weight` | 2026-02-01 |
| Full block fg+bg color matching | Apply same ANSI color to both foreground and background for full blocks (`█`) to eliminate whitespace gaps between characters | 2026-02-01 |
| Dynamic X-axis tick scaling | Number of ticks scales with histogram width; target ~12 character spacing; minimum 5 ticks, no maximum | 2026-02-01 |
| Dynamic Y-axis tick scaling | Use "nice" tick counts (2, 3, 5, 6, 9, 11, 21) that produce clean percentage intervals (10%, 20%, 25%, 50%); target ~3 row spacing | 2026-02-01 |
| 0% baseline on X-axis | The X-axis line IS the 0% baseline; all data rows represent values > 0%; bars sit ON TOP of the axis floor | 2026-02-01 |
| Horizontal gridlines at Y-axis ticks | Optional gridlines using light horizontal line (`─`) in dark grey (ANSI 8); only in empty columns; configurable via `$gridlines_enabled` | 2026-02-01 |
| Base colors match bar graph plain_bg | Duration: 184 (yellow), Bytes: 34 (green), Count: 30 (cyan) - matching ltl bar graph column colors | 2026-02-01 |
| Color gradient toggle | `$color_gradient_enabled` controls intensity variation vs flat base color; default off for testing clarity | 2026-02-01 |
| Decouple bucket count from display width | Bucket count based on data range and precision, display width determines character-per-bucket rendering | 2026-02-01 |
| ~~Freedman-Diaconis for bucket count~~ | **SUPERSEDED** - Freedman-Diaconis assumes linear bins; not applicable to logarithmic histograms | 2026-02-01 |
| Buckets-per-decade model (HdrHistogram approach) | Industry standard for latency histograms; bucket count = decades × buckets_per_decade; default 8 buckets/decade (~5% precision) | 2026-02-01 |
| `-hgbpd` option for precision control | Configure buckets per decade (4=10%, 8=5%, 16=2.5%); `-hgb` overrides with explicit total | 2026-02-01 |
| X-axis label alignment with log buckets | Labels calculated using same logarithmic formula as bucket boundaries; verified alignment across all display widths | 2026-02-01 |
| Display bucket expansion/compression | When display > buckets: each bucket spans multiple columns; when display < buckets: multiple buckets aggregate per column | 2026-02-01 |
| ANSI color reset before Y-axis | Prevents color bleeding on wide displays; `ansi_reset()` called before right Y-axis rendering | 2026-02-01 |