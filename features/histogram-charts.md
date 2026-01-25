# Feature: Histogram Charts for Key Metrics

## Overview

Add ASCII terminal histogram charts that visualize the value distribution of key metrics (duration, bytes, count) across all processed log entries. Unlike the time-series heatmap which shows how values change over time, histograms show the overall shape of the data distribution.

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
                     Duration Distribution                                    Bytes Distribution
 Count  %                                                              Count  %
 1247 ─┤          ██                              ├─ 100%               523 ─┤     ██                              ├─ 100%
       │         ████                             │                          │    ████
       │        ██████                            │                          │   ██████  ██
  623 ─┼       ████████ ▄▄                        ├─  50%               261 ─┼  ████████████                       ├─  50%
       │      ██████████████                      │                          │ ██████████████
       │ ▂▂  ████████████████ ▂▂                  │                          │██████████████████ ▂▂
    0 ─┤▁▁▁▁██████████████████████▁▁              ├─   0%                 0 ─┤████████████████████████▁            ├─   0%
       └─┬────┬────┬────┬────┬────┬─                                         └─┬────┬────┬────┬────┬────┬─
        1ms 10ms 100ms 1s  10s 100s                                           1KB 10KB 100KB 1MB 10MB 100MB
                                              P50:  127ms                                                       P50:  45KB
                                              P90:  892ms                                                       P90: 234KB
                                              P99: 4.2s                                                         P99: 1.2MB
                                            P99.9: 12.3s                                                      P99.9: 8.7MB
```

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

#### Optional: Color Gradient Bars

Use existing 8-level heatmap color gradients to color the bars based on count density:
- Duration: Yellow gradient (58, 94, 136, 142, 178, 184, 220, 226)
- Bytes: Green gradient (22, 28, 34, 40, 46, 82, 118, 154)
- Count: Cyan gradient (23, 30, 37, 44, 51, 80, 86, 123)

Each bar column's color intensity reflects the count in that bucket relative to the maximum bucket count. This is an optional enhancement to be tested for visual appeal.

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

- Corner character (`└`) at origin
- Downward-facing tick markers (`┬`) aligned with bucket boundaries
- Labels showing bucket boundary values using smart formatting:
  - Duration: 1ms, 10ms, 100ms, 1s, 10s, 100s
  - Bytes: 1KB, 10KB, 100KB, 1MB, 10MB
  - Count: 1, 10, 100, 1K, 10K, 100K
- Logarithmic scale (no linear option)

#### Legend (Right side, below histogram)

Display population-wide percentiles below each histogram:
```
P50:  127ms
P90:  892ms
P99: 4.2s
P99.9: 12.3s
```

These represent percentiles for the **entire population** of values, distinct from the time-bucket or message-based percentiles shown elsewhere.

### Data Collection

New data structures to capture values during log parsing:

```perl
# Raw value arrays (populated during parsing)
my @histogram_duration_values;   # All duration values
my @histogram_bytes_values;      # All bytes values
my @histogram_count_values;      # All count values

# Computed histogram buckets (populated before output)
my @histogram_duration_buckets;  # Count per bucket
my @histogram_bytes_buckets;
my @histogram_count_buckets;

# Bucket boundaries (logarithmic scale)
my @histogram_duration_boundaries;
my @histogram_bytes_boundaries;
my @histogram_count_boundaries;
```

### Bucket Calculation

1. **Determine range**: Find global min/max across all values
2. **Calculate logarithmic boundaries**: Similar to heatmap approach
   - `boundary[i] = min * (max/min)^(i/num_buckets)`
3. **Default bucket count**: Based on available display width
4. **Assign values to buckets**: Binary search for efficiency with large datasets

### Layout Calculation

1. Get terminal width
2. Calculate display width: `terminal_width * (histogram_width_percent / 100)`
3. Determine which metrics have data (in order: duration, bytes, count)
4. Divide display width equally among active histograms (with spacing between them)
5. Center the histogram group in terminal

### Color Scheme

Match bar graph column colors for consistency:
- Duration: Yellow (column 2 color)
- Bytes: Green (column 3 color)
- Count: Cyan (column 4 color)

## Non-Requirements (Out of Scope)

- Highlight filter support (future enhancement)
- User-defined bucket boundaries (future enhancement)
- Configurable histogram height (future enhancement - design for it)
- CSV output of histogram data (future enhancement)
- Light background color support (follow heatmap pattern when implemented)
- Linear scale option (removed - logarithmic only)

## Acceptance Criteria

1. [ ] `-hg` flag enables histogram output with all available metrics
2. [ ] `-hg <metric>` enables histogram for specific metric(s)
3. [ ] Histograms display after bar graph, before options output
4. [ ] Multiple histograms display side by side, centered
5. [ ] Histogram order follows bar graph column order: duration, bytes, count
6. [ ] Histogram colors match bar graph column colors
7. [ ] Metrics with no data are omitted from display
8. [ ] Vertical bars use 8-level Unicode block characters
9. [ ] Left Y-axis shows count with min/mid/max labels and tick marks
10. [ ] Right Y-axis shows percentage (0%/50%/100%) with tick marks
11. [ ] X-axis has tick markers aligned with bucket boundary labels
12. [ ] Logarithmic bucket scaling works correctly
13. [ ] Legend shows P50, P90, P99, P99.9 for entire population
14. [ ] Works with all log formats that provide duration/bytes/count

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
3. Run with count-only logs: `./ltl -hg logs/ThingworxLogs/ApplicationLog.log`
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

### Unicode Block Elements

The Unicode Block Elements range (U+2580-U+259F) provides the characters needed:
- Lower blocks: `▁▂▃▄▅▆▇█` (U+2581-U+2588)
- These are widely supported in modern terminal emulators

### Box Drawing Characters

For axes and tick marks:
- `─` (U+2500) Horizontal line
- `│` (U+2502) Vertical line
- `┬` (U+252C) Down-facing T (X-axis ticks)
- `├` (U+251C) Right-facing T (right Y-axis ticks)
- `┤` (U+2524) Left-facing T (left Y-axis ticks)
- `┼` (U+253C) Cross (midpoint ticks)
- `└` (U+2514) Bottom-left corner

### Similar Tools

- `spark` - Sparkline generator using block characters
- `gnuplot` - Can output ASCII histograms
- `termgraph` - Python terminal graphing library

## Future Enhancements

1. **Highlight support**: Show filtered subset distribution overlaid on full distribution
2. **Custom bucket boundaries**: Allow users to specify bucket ranges via command line
3. **Configurable height**: `-hgh <N>` to set histogram height in rows
4. **Cumulative distribution**: Show CDF alongside histogram
5. **CSV export**: Include histogram bucket data in CSV output
6. **Percentile markers on chart**: Visual indicators (e.g., vertical lines or markers) showing P50/P90/P99/P99.9 positions directly on the histogram bars

## Progress Tracking

| Task | Status | Notes |
|------|--------|-------|
| Feature document created | Done | |
| GitHub issue created | Done | [#25](https://github.com/gregeva/logtimeline/issues/25) |
| Implementation plan | Not started | |
| Prototype | Not started | |
| Implementation | Not started | |
| Testing | Not started | |
| Documentation | Not started | |

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
