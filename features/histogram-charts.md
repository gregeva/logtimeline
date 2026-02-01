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

Multiple uses of command line options for -hg should be additive in case the overall environment states displaying -hg duration, and the user adds -hg bytes then both duration and bytes should be included.

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
       └─┬────┬────┬────┬────┬────┬─                                         └─┬────┬────┬────┬────┬────┬─
        1ms 10ms 100ms 1s  10s 100s                                           1KB 10KB 100KB 1MB 10MB 100MB
                                              P50:    127ms                                                       P50:  45KB
                                              P90:    892ms                                                       P90: 234KB
                                              P99:    4.2s                                                        P99: 1.2MB
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

CLAUDE: Please clarify why you have only put a corner character joining X and Y axis on the far left, and not on the right?

- Corner character (`└`) at origin (far left)
- Downward-facing tick markers (`┬`) aligned with bucket boundaries
- Labels showing bucket boundary values using smart formatting:
  - Duration: 1ms, 10ms, 100ms, 1s, 10s, 100s
  - Bytes: 1KB, 10KB, 100KB, 1MB, 10MB
  - Count: 1, 10, 100, 1K, 10K, 100K
- Logarithmic scale (no linear option)

#### Legend (Right side, below histogram)

CLAUDE: make sure that there are configurable variables for spacing between the Histogram and legend, and between the histograms, and that legend text and values are correctly aligned (left, right).  Update this section accordingly and remove this comment.

Display population-wide percentiles below each histogram:
```
P50:    127ms
P90:    892ms
P99:     4.2s
P99.9:  12.3s
```

The percentile labels should be left aligned, and the values right aligned meeting standard text and number table formatting rules.  A maximum of one decimal place should be used in the value output, with no decimal place if the digit after the decimal is a zero.  There should be a space between the value and the unit (which is provided by the helper function).

These represent percentiles for the **entire population** of values, distinct from the time-bucket or message-based percentiles shown elsewhere.

### Data Collection

CLAUDE: This is wrong, the data structure should be Hash, containing arrays.  The same pattern elsewhere so that new metrics can be added programatically.  What you have proposed here is static and repetitive where the base code, data model should be the same.  Update this section accordingly to be aligned with the section "Other Metric Support", ensuring a more flexible, dynamic data model; and then remove this comment once resolved.

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
3. **Default bucket count**: Based on available display width for the histogram (will depend on terminal width and number of histograms being calculated)
4. **Assign values to buckets**: Binary search for efficiency with large datasets

### Layout Calculation

CLAUDE: I have updated this section with a few added steps as your layout planning was quite insufficient given the feature requirements and challenges to layout such a complex grid of trends with legends and spacing.  Please ensure that the order fits your algorithmic plan, and determine if there are any other missing layout calculation stages which are missing.  Once the section is updated, you can remove this comment as resolved.

1. Get terminal width (this comes from the global variable)
2. Calculate display width: `terminal_width * (histogram_width_percent / 100)`
3. Determine which metrics have data (in order: duration, bytes, count)
4. Divide display width equally among active histograms (with spacing between them)
5. Apply a configurable amount of padding between each histogram
6. Allow for space for the printed legend
7. Each histogram size is then known
6. Center the histogram group in terminal

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
13. [ ] Legend shows P50, P90, P99, P99.9 for entire population with left aigned labels and right aligned values
14. [ ] Works with all log formats that provide duration/bytes/count
15. [ ] Light background support has been added for automatically switching color gradients on light terminals

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

CLAUDE: It is unclear why you have left out bottom-right corner character.  The defined and used characters should be complete surrounding all drawing of parts of such lines, tick marks, and corners.  Resolve, and remove this comment once done.

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
| Color gradient bars should be configurable, but required | Reuse heatmap gradients, test for visual appeal | 2026-02-01 |