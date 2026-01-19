# Feature Requirements: Console Heatmap Visualization

## Branch
`feature/heatmap`

## Overview
Add a heatmap visualization mode to LogTimeLine that replaces the latency statistics column with a visual heat distribution showing request density across latency ranges. This feature is inspired by SRE best practices for analyzing load profiles and latency distributions, providing at-a-glance visibility into request population distribution patterns that percentile numbers alone cannot convey.

## Background / Problem Statement

### The Limitation of Percentile Statistics
While percentile statistics (P50, P95, P99, P99.9) provide valuable insights into latency distribution, they reduce complex multi-modal distributions to a handful of numbers. Users investigating performance issues need to understand:

- **Distribution shape**: Is latency bi-modal (cache hit/miss)? Multi-modal (different code paths)?
- **Outlier clustering**: Are slow requests evenly distributed or clustered at specific times?
- **Population density**: Where do most requests fall within the latency range?
- **Temporal patterns**: How does the distribution shift over time?

A heatmap visualization addresses these limitations by showing the entire distribution visually, allowing patterns that would be invisible in percentile statistics to become immediately apparent.

### Industry Research: SRE Heatmap Best Practices

Based on research from industry leaders in observability and SRE:

**Brendan Gregg's Latency Heatmaps** ([brendangregg.com](https://www.brendangregg.com/HeatMaps/latency.html)):
- "Each frame of the histogram animation becomes a column in a latency heat map, with the histogram bar height represented as a color"
- Heatmaps transform temporal latency data into visual representations where X-axis is time, Y-axis is latency ranges, and color intensity represents frequency/density
- Bi-modal distributions become immediately visible, suggesting "fast path" and "slow path" behaviors
- Outliers appear as distinct colored regions separate from primary clusters
- "The modes move over time" - heatmaps reveal how latency distribution shifts across the monitoring period

**Datadog Heatmap Engineering** ([datadoghq.com](https://www.datadoghq.com/blog/engineering/how-we-built-the-datadog-heatmap-to-visualize-distributions-over-time-at-arbitrary-scale/)):
- Distributing histogram boundaries approximately exponentially (by factors of roughly 3) is effective for visualizing request distributions
- A metric can contain multiple systems that behave differently, showing up visually as distinct "modes"
- Logarithmic scale support is important for latency data which often spans orders of magnitude

**Google SRE Monitoring** ([sre.google](https://sre.google/sre-book/monitoring-distributed-systems/)):
- The Four Golden Signals (latency, traffic, errors, saturation) are foundational to SRE monitoring
- Latency distributions reveal more than averages - percentiles capture tail behavior that averages mask

**ACM Queue: Visualizing System Latency** ([queue.acm.org](https://queue.acm.org/detail.cfm?id=1809426)):
- Response time is crucial to understand in detail, but common presentations hide important details and patterns
- Latency heat maps effectively reveal distribution modes, outliers, and temporal patterns

### Key Insights for Implementation
1. **Pixel/Bucket Resolution**: Time and latency ranges should allow multiple operations to fall within them for meaningful density representation
2. **Scale**: Logarithmic or exponential bucket boundaries work better for latency data than linear
3. **Color Intensity**: Darker/more intense colors for higher density, lighter for lower
4. **Fixed Range**: Use global min/max across all time buckets so each row has the same reference scale
5. **Multi-Modal Visibility**: The visualization should make bi-modal and multi-modal distributions apparent

## Goals
- Replace latency statistics column with a heatmap visualization when `-hm` or `--heatmap` flag is used
- Support three metrics: `duration` (default), `bytes`, and `count`
- Provide SRE-grade visualization of request distribution across latency/metric ranges
- Maintain support for the existing highlight feature to differentiate filtered requests
- Use ANSI 256-color and Unicode block characters for terminal-native rendering
- Keep the same column width as the current latency statistics section (~56 characters)

## Requirements

### Functional Requirements

1. **Command Line Interface**
   - Add `-hm` or `--heatmap` option that accepts optional metric type
   - Default metric: `duration` (request latency)
   - Alternative metrics: `bytes` (response size), `count` (request count)
   - Examples:
     - `./ltl --heatmap logs/access.log` (duration heatmap)
     - `./ltl -hm bytes logs/access.log` (bytes heatmap)
     - `./ltl --heatmap count logs/access.log` (count heatmap)

2. **Heatmap Rendering**
   - Replace the "latency statistics" column with heatmap visualization
   - Column heading changes to reflect the metric being displayed
   - Each row (time bucket) shows distribution of values across the range
   - Fixed range from global minimum to global maximum across all time buckets
   - ~51 character width for the heatmap cells (matching current column width minus borders)

3. **Heatmap Axes and Color Model**
   - **X-axis (horizontal position)**: Metric value range
     - Left edge = minimum value (fast requests / small responses / low count)
     - Right edge = maximum value (slow requests / large responses / high count)
     - Each column represents a bucket/bin in the value range
   - **Y-axis (rows)**: Time buckets (same as existing bar graph rows)
   - **Color intensity**: Request COUNT/density at that value
     - Bright/intense color = MANY requests fell into this bucket
     - Dark/dim color = FEW requests fell into this bucket
     - Empty/space = NO requests at this level

   **Key Insight**: The position tells you "at what latency", the color tells you "how many requests".

4. **Density Representation**
   - Highest density (many requests): Bright color + full block (█)
   - Medium density: Medium color + partial blocks (▒ or ▓)
   - Low density (few requests): Dark color + light block (░)
   - Zero density: Empty space
   - Use Unicode block elements for additional fill indication: ░ ▒ ▓ █
   - OR rely purely on color intensity with full blocks (█)

5. **Color Scheme** (indicates density/COUNT, not the metric value)
   - Gradient from dark (few requests) to bright (many requests)
   - Different base color per metric type for visual differentiation:
     - `duration`: Yellow gradient (dark gray → brown → bright yellow)
     - `bytes`: Green gradient (dark gray → dark green → bright green)
     - `count`: Cyan gradient (dark gray → dark cyan → bright cyan)
   - Base on 256-color ANSI palette for wide terminal compatibility

6. **Highlight Support**
   - When `-highlight` is used alongside `-hm`, track separate heatmap data for highlighted requests
   - Differentiate highlighted requests visually using **bright background color**
   - Approach (consistent with existing ltl highlight behavior):
     - Highlighted cells use bright background color to make the character pop
     - Foreground color remains the same (density color is preserved)
     - This allows users to see both: which requests matched the filter AND their density
   - Background colors per metric:
     - `duration`: Bright yellow background (256-color index 226)
     - `bytes`: Bright green background (256-color index 46)
     - `count`: Bright cyan background (256-color index 51)
   - Note: This approach works for Shade+Color, Color-Only, and Hybrid modes
     - Does NOT apply to Background Color mode (Approach 4) since it already uses background

7. **Data Processing**
   - During log processing, bucket values into latency/metric ranges
   - Store histogram data per time bucket: `%log_heatmap{$bucket}{$range_index} = count`
   - For highlights: `%log_heatmap_hl{$bucket}{$range_index} = count`
   - Calculate global min/max across all buckets before rendering

8. **Bucket Distribution**
   - Use logarithmic or exponential bucket boundaries for latency (duration)
   - Consider linear boundaries for bytes and count
   - Number of buckets matches display width (~51 cells)

### Non-Functional Requirements

1. **Terminal Compatibility**
   - Must work on terminals supporting 256 colors
   - Graceful fallback for 16-color terminals (use shade characters instead of color gradient)
   - UTF-8 support required for Unicode block characters

2. **Performance**
   - Histogram binning adds minimal overhead to log processing
   - No impact on memory usage beyond the histogram data structure

3. **Display Consistency**
   - Heatmap must not cause line wrapping
   - Scale indicator/legend should be shown (possibly in header or footer)
   - All rows must use the same scale for visual consistency

## User Stories

- As an SRE investigating a latency spike, I want to see the request distribution heatmap so I can identify if the spike affects all requests or a specific subset
- As a Performance Engineer analyzing load patterns, I want to see bi-modal distributions that indicate cache hit/miss behavior
- As a Developer debugging slow requests, I want to use the highlight filter with heatmap to see where my filtered requests fall in the overall distribution
- As a Capacity Planner reviewing historical data, I want to see response size distributions over time to understand traffic patterns

## Acceptance Criteria

- [ ] `-hm` and `--heatmap` command line options are recognized
- [ ] Default metric is `duration` when no metric specified
- [ ] `bytes` and `count` metrics work when specified
- [ ] Heatmap replaces latency statistics column (not shown together)
- [ ] Column heading changes to "duration heatmap", "bytes heatmap", or "count heatmap"
- [ ] Heatmap cells show density with block characters
- [ ] Color gradient reflects density (dark=low, bright=high)
- [ ] Different color schemes for different metrics
- [ ] Global scale used (min-max consistent across all rows)
- [ ] Highlight filter works with heatmap mode
- [ ] No line wrapping occurs on standard terminal widths
- [ ] CSV output includes histogram bucket counts when `-o` flag used

## Technical Considerations

### Console Rendering Research

**Unicode Block Characters** ([Wikipedia: Block Elements](https://en.wikipedia.org/wiki/Block_Elements)):

Shade characters (fill density):
- U+0020 ` ` (space) - 0% fill
- U+2591 `░` - Light shade (~25%)
- U+2592 `▒` - Medium shade (~50%)
- U+2593 `▓` - Dark shade (~75%)
- U+2588 `█` - Full block (100%)

Lower block elements (vertical fill):
- U+2581 `▁` - Lower 1/8 block
- U+2582 `▂` - Lower 1/4 block
- U+2583 `▃` - Lower 3/8 block
- U+2584 `▄` - Lower 1/2 block
- U+2585 `▅` - Lower 5/8 block
- U+2586 `▆` - Lower 3/4 block
- U+2587 `▇` - Lower 7/8 block
- U+2588 `█` - Full block

**Rendering Approach Options** (evaluated in prototype `prototype/heatmap-test.pl`):

All approaches use the same model:
- **Position (X-axis)**: Latency value (left = fast, right = slow)
- **Color intensity**: Request COUNT/density (dark = few, bright = many)

1. **Shade + Color**: Use shade characters (░▒▓█) with 256-color gradient
   - Characters: ` ` (empty) → `░` (few) → `▒` (some) → `▓` (many) → `█` (most)
   - Color: Dark gray → brown → yellow → bright yellow (reinforces density)
   - Pros: Maximum information density (both fill level AND color convey request count)
   - Cons: Can look busy; some terminals render shades with dithering patterns
   - Best for: Users who want maximum detail and pattern visibility

2. **Color-Only Full Blocks**: Use full block (█) with color intensity only
   - Characters: ` ` (empty) or `█` (full block only)
   - Color: Full gradient from dark (few requests) to bright (many requests)
   - Pros: Clean, modern appearance; no dithering issues; works well on all terminals
   - Cons: Relies entirely on color gradient; may be harder to distinguish adjacent density levels
   - Best for: Clean visual aesthetic; terminals with good color rendering

3. **Hybrid (3 Shades + Color)**: Combine 3 shade levels with color gradient
   - Characters: ` ` (empty) → `░` (low count) → `▓` (medium count) → `█` (high count)
   - Color: Full gradient from dark to bright
   - Pros: Good balance of clarity and information; 3 distinct visual "bands"
   - Cons: Slightly more complex than color-only
   - Best for: Balance between detail and visual cleanliness

4. **Background Color**: Use space character with background color
   - Characters: ` ` (space only, color in background)
   - Color: Background color intensity varies based on request count
   - Pros: Smoothest appearance; works with any font; no character rendering issues
   - Cons: May not stand out as much; some terminals have background color quirks
   - Best for: Minimal visual noise; integration with existing UI elements

**Prototype Comparison** (run `perl prototype/heatmap-mini.pl` to see):
```
  Latency:  0ms        500ms       1s         2s        5s
            │──────────│───────────│──────────│─────────│

1. Shade+Color:   █▓▒░░░░░░░░░░░   (bright=many fast requests, dim=few slow)
2. Color Only:    █████████░░░░░   (color intensity shows density)
3. Hybrid:        █▓▓░░░░░░░░░░░   (3 shade levels + color)
4. Background:    ████████░░░░░░   (background color intensity)
```

**Interpretation**: Bright yellow on the LEFT means many fast requests. Dim/dark on the RIGHT means few slow requests. This is a healthy latency profile - most traffic is fast.

**Recommendation**: Start with **Approach 2 (Color-Only)** as the default due to its clean appearance and universal terminal compatibility. Consider offering Approach 1 or 3 as a command-line option (`--heatmap-style shade`) for users who prefer more visual detail.

**256-Color ANSI Codes**:
- Foreground: `ESC[38;5;⟨n⟩m`
- Background: `ESC[48;5;⟨n⟩m`
- Color cube (216 colors): indices 16-231, formula: 16 + 36×r + 6×g + b (0 ≤ r,g,b ≤ 5)
- Grayscale: indices 232-255 (24 shades)

**Perl Support** ([Term::ANSIColor](https://metacpan.org/pod/Term::ANSIColor)):
- Already used in ltl for existing color output
- Supports 256-color mode via `ansiN` where N is 0-255
- RGB colors via `rgbRGB` format (e.g., `rgb530` for orange)
- Grayscale via `grey0` through `grey23`

### Existing ANSI::Heatmap Perl Module

The [ANSI::Heatmap](https://github.com/richardjharris/ANSI-Heatmap) module provides reference for terminal heatmap rendering in Perl:
- Uses 256 ANSI colors and Unicode characters
- Supports half-height mode for improved aspect ratio
- Includes predefined color swatches (blue-red thermography, grayscale)
- Methods: `set(X, Y, Z)`, `get(X, Y)`, `inc(X, Y)`, `to_string()`

We may adapt patterns from this module or use it as a dependency.

### Data Structures

New data structures needed:

```perl
# Heatmap histogram data per time bucket
my %log_heatmap;           # {bucket}{range_index} = count
my %log_heatmap_hl;        # {bucket}{range_index} = count (highlighted)

# Global range tracking
my ($heatmap_min, $heatmap_max);  # Global min/max for the selected metric
my @heatmap_bucket_boundaries;    # Array of boundary values for histogram buckets

# Configuration
my $heatmap_width = 51;           # Number of histogram buckets/columns
my $heatmap_metric = 'duration';  # 'duration', 'bytes', or 'count'
my $heatmap_enabled = 0;          # Flag set by command line option
```

### Integration Points

1. **Command Line Parsing** (~line 463): Add `--heatmap|-hm` option
2. **Log Processing** (~line 950-1100): Add histogram binning during value extraction
3. **Statistics Calculation** (~line 1114): Calculate global min/max, bucket boundaries
4. **Output Normalization** (~line 1535): Calculate `$durations_graph_width` based on mode
5. **Bar Graph Printing** (~line 2029-2049): Render heatmap instead of percentile stats

### Width Calculation

Current latency statistics width: 56 characters
- `│ + 2 spaces` (3) + P50(11) + P95(11) + P99(11) + P999(11) + CV(7) + padding(2) = 56

Heatmap target width: 56 characters
- `│ + 2 spaces` (3) + heatmap cells (51) + padding(2) = 56

### Histogram Bucket Boundaries (Duration)

For latency data spanning potentially 1ms to 100,000ms:
- Use logarithmic boundaries to handle wide range
- Example 51-bucket logarithmic scale:
  - Bucket 0: 0-1ms
  - Bucket 25: ~100ms
  - Bucket 50: ~100,000ms
- Formula: `boundary[i] = min * (max/min)^(i/num_buckets)`

### Color Gradient Examples

**Duration (Yellow)** - using 256-color indices:
- Low density: 58 (dark olive/brown)
- Medium-low: 100 (dark yellow)
- Medium: 142 (yellow)
- Medium-high: 184 (bright yellow)
- High: 226 (intense yellow)

**Bytes (Green)**:
- Low density: 22 (dark green)
- Medium-low: 28 (forest green)
- Medium: 34 (green)
- Medium-high: 40 (bright green)
- High: 46 (intense green)

**Count (Cyan)**:
- Low density: 23 (dark cyan)
- Medium-low: 30 (teal)
- Medium: 37 (cyan)
- Medium-high: 44 (bright cyan)
- High: 51 (intense cyan)

## Prototype Plan

### Phase 1: Standalone Prototype
Build a standalone Perl script to explore rendering options before integrating into ltl.

**Prototype Goals**:
1. Render a sample heatmap with synthetic data
2. Test all four rendering approaches (shade+color, color-only, half-height, hybrid)
3. Evaluate visual clarity across different terminal emulators
4. Test highlight overlay approaches
5. Determine optimal color gradients for each metric type

**Prototype Deliverables**:
- `prototype/heatmap-test.pl` - Standalone test script ✓ CREATED
- Screenshots/recordings of different rendering approaches
- Decision document on chosen rendering approach

**Prototype Status**: Initial version created. Run with:
```bash
perl prototype/heatmap-test.pl
```

The prototype demonstrates:
- Four rendering approaches (shade+color, color-only, hybrid, background)
- Bi-modal distribution visualization with temporal drift
- Highlight overlay with contrasting colors
- Color scheme comparison (duration/bytes/count)

### Phase 2: Integration
Integrate chosen approach into ltl main script.

### Phase 3: Testing & Documentation
Full testing across platforms and documentation updates.

## Out of Scope
- Interactive heatmap (cursor navigation, zoom)
- True color (24-bit) rendering (stick to 256-color for compatibility)
- Heatmap in CSV output (will include histogram data instead)
- Combining heatmap with percentile statistics display
- Vertical (time on Y-axis) heatmap orientation

## Testing Requirements

### Prototype Testing
```bash
cd prototype && perl heatmap-test.pl
```
Test on:
- macOS Terminal
- iTerm2
- VS Code integrated terminal
- Windows Terminal (via WSL)
- Linux GNOME Terminal

### Integration Testing
```bash
# Basic heatmap (duration)
./ltl --heatmap logs/accessLogs/localhost_access_log*.log

# Bytes heatmap
./ltl -hm bytes logs/accessLogs/localhost_access_log*.log

# Count heatmap
./ltl --heatmap count logs/accessLogs/localhost_access_log*.log

# With highlight
./ltl --heatmap -highlight "GET /api/users" logs/accessLogs/localhost_access_log*.log

# Narrow terminal
COLUMNS=120 ./ltl --heatmap logs/accessLogs/localhost_access_log*.log
```

## Documentation Requirements

- Update README.md with new `-hm`/`--heatmap` option
- Add example output screenshots
- Document color scheme and interpretation
- Add section on heatmap visualization for SRE analysis

## Progress Tracking

### Research Phase
- [x] Research SRE latency heatmap best practices
- [x] Research console/terminal heatmap rendering techniques
- [x] Research Unicode block characters and ANSI 256-color
- [x] Document findings in feature file

### Prototype Phase
- [x] Create prototype directory and test script
- [x] Implement shade+color rendering approach
- [x] Implement color-only rendering approach
- [x] Implement hybrid rendering approach
- [x] Implement background color approach
- [x] Prototype highlight overlay
- [ ] Test on multiple terminals
- [ ] Select optimal rendering approach
- [ ] Document prototype findings

### Implementation Phase
- [ ] Add command line options
- [ ] Implement histogram data collection during log processing
- [ ] Implement bucket boundary calculation
- [ ] Implement heatmap rendering function
- [ ] Implement highlight differentiation
- [ ] Integrate with existing output flow

### Testing Phase
- [ ] Test all three metric types
- [ ] Test with highlight filter
- [ ] Test on macOS, Linux, Windows
- [ ] Test narrow terminal widths
- [ ] Test with large log files
- [ ] Performance benchmarking

### Documentation Phase
- [ ] Update README.md
- [ ] Update CLAUDE.md if needed
- [ ] Create example screenshots

## External References

### SRE & Observability
- [Brendan Gregg: Latency Heat Maps](https://www.brendangregg.com/HeatMaps/latency.html)
- [Datadog: How We Built the Heatmap](https://www.datadoghq.com/blog/engineering/how-we-built-the-datadog-heatmap-to-visualize-distributions-over-time-at-arbitrary-scale/)
- [Google SRE Book: Monitoring Distributed Systems](https://sre.google/sre-book/monitoring-distributed-systems/)
- [ACM Queue: Visualizing System Latency](https://queue.acm.org/detail.cfm?id=1809426)

### Terminal Rendering
- [ANSI Escape Codes Reference](https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797)
- [256 Colors Cheat Sheet](https://www.ditig.com/256-colors-cheat-sheet)
- [Unicode Block Elements](https://en.wikipedia.org/wiki/Block_Elements)
- [Term::ANSIColor Perl Module](https://metacpan.org/pod/Term::ANSIColor)
- [ANSI::Heatmap Perl Module](https://github.com/richardjharris/ANSI-Heatmap)

### Percentile Analysis
- [P50 vs P95 vs P99 Latency Percentiles](https://oneuptime.com/blog/post/2025-09-15-p50-vs-p95-vs-p99-latency-percentiles/view)
- [What Is P99 Latency?](https://aerospike.com/blog/what-is-p99-latency/)

## Notes

### Design Decisions to Make During Prototyping
1. Which block character approach provides best visual clarity?
2. Should we use logarithmic or linear bucket boundaries?
3. What is the optimal number of color gradient steps?
4. How should highlights be visually differentiated?
5. Should we show a legend/scale indicator?

### Potential Future Enhancements
- Configurable bucket count via command line
- Custom color schemes
- Percentile markers overlaid on heatmap
- Comparative mode (two heatmaps side by side)
