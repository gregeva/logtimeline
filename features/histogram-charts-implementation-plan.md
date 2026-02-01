# Histogram Charts - Implementation Plan

## Overview

This document outlines the implementation plan for adding histogram charts to ltl, as specified in `features/histogram-charts.md`.

## Prerequisites

- Feature document reviewed and approved: `features/histogram-charts.md`
- GitHub Issue: #25

## Architecture Summary

### Data Flow

```
Log Parsing → Collect Raw Values → Calculate Buckets → Render Histograms
     ↓              ↓                    ↓                   ↓
 (existing)   %histogram_values    %histogram_buckets    print_histograms()
              %histogram_boundaries
```

### Key Design Decisions

1. **Separate data collection**: Histogram collects ALL values across entire log (not per time-bucket like heatmap)
2. **Hash-based data model**: `%histogram_values`, `%histogram_buckets`, `%histogram_boundaries` for dynamic metric support
3. **Memory approach**: Simple array storage (memory optimization deferred to #34)
4. **Reuse existing infrastructure**: Color gradients, metric mapping, logarithmic boundary calculation

## Implementation Phases

### Phase 1: Command Line Options and Global Variables

**Location**: GLOBALS section (around lines 74-232)

**New global variables:**

```perl
# Histogram feature flags and settings
my $histogram_enabled = 0;                    # Flag: histogram mode active
my %histogram_metrics = ();                   # Metrics to display: {duration => 1, bytes => 1, count => 1}
my $histogram_width_percent = 95;             # Width as percentage of terminal
my $histogram_height = 10;                    # Height in rows (default 10)
my $histogram_gap = 4;                        # Horizontal padding between histograms
my $histogram_legend_spacing = 1;             # Vertical gap between histogram and legend

# Histogram data structures (hash-based for dynamic metrics)
my %histogram_values = (
    duration => [],
    bytes    => [],
    count    => [],
);

my %histogram_buckets = (
    duration => [],
    bytes    => [],
    count    => [],
);

my %histogram_boundaries = (
    duration => [],
    bytes    => [],
    count    => [],
);

my %histogram_stats = (
    duration => {},  # Will contain: min, max, p50, p90, p99, p999
    bytes    => {},
    count    => {},
);
```

**New command line options** (in GetOptions block, around line 780):

```perl
'histogram|hg:s'        => \&handle_histogram_option,   # Optional argument
'histogram-width|hgw=i' => \$histogram_width_percent,
'histogram-height|hgh=i' => \$histogram_height,
'hgbpd=i'               => \$histogram_buckets_per_decade,  # Buckets per decade (precision)
'hgb=i'                 => \$histogram_bucket_override,     # Override: explicit bucket count
```

**Bucket calculation configuration:**

```perl
my $histogram_buckets_per_decade = 8;   # Default: ~5% precision (4=10%, 8=5%, 16=2.5%, 32=1%)
my $histogram_bucket_override = 0;      # If > 0, use this exact bucket count instead of calculating
```

**Handler function for -hg option:**

```perl
sub handle_histogram_option {
    my ($opt_name, $opt_value) = @_;
    $histogram_enabled = 1;

    if (defined $opt_value && $opt_value ne '') {
        # Parse comma-separated metrics, additive behavior
        for my $metric (split /,/, $opt_value) {
            $metric = lc(trim($metric));
            if ($metric =~ /^(duration|bytes|count)$/) {
                $histogram_metrics{$metric} = 1;
            } else {
                warn "Unknown histogram metric: $metric (valid: duration, bytes, count)\n";
            }
        }
    }
    # If no specific metrics given, will default to all available after parsing
}
```

### Phase 2: Data Collection During Parsing

**Location**: `read_and_process_logs()` (around lines 1078-1549)

**Integration point**: After existing value extraction, before time-bucket storage (around line 1520)

```perl
# Collect values for histogram (entire population, not per-bucket)
if ($histogram_enabled) {
    if (defined $duration && $duration >= 0 && !$omit_durations) {
        push @{$histogram_values{duration}}, $duration;
    }
    if (defined $bytes && $bytes > 0 && !$omit_bytes) {
        push @{$histogram_values{bytes}}, $bytes;
    }
    if (defined $count && $count >= 0 && !$omit_count) {
        push @{$histogram_values{count}}, $count;
    }
}
```

**Note**: This is independent of heatmap collection - both can be enabled simultaneously.

### Phase 3: Bucket Calculation (HdrHistogram Approach)

**Location**: New subroutine `calculate_histogram_buckets()` (after `calculate_heatmap_buckets()`, around line 1654)

**Key Change from Original Design**: Bucket count is now determined by data range (decades) and precision setting, NOT display width. This follows the HdrHistogram industry standard approach.

**Algorithm:**

1. For each metric with data:
   - Find min/max values
   - Calculate dynamic range in decades: `log₁₀(max) - log₁₀(min)`
   - Calculate bucket count: `decades × buckets_per_decade` (or use override if set)
   - Calculate logarithmic bucket boundaries
   - Assign values to buckets using binary search
   - Calculate population percentiles (P50, P90, P99, P99.9)
   - Free raw values array to reclaim memory

```perl
# Calculate bucket count based on data range (HdrHistogram approach)
sub calculate_histogram_bucket_count {
    my ($min, $max) = @_;

    # Use explicit override if set
    return $histogram_bucket_override if $histogram_bucket_override > 0;

    # Ensure valid range for log calculation
    $min = 0.1 if $min <= 0;
    $max = $min * 10 if $max <= $min;

    # Calculate number of decades (orders of magnitude)
    my $decades = (log($max) - log($min)) / log(10);

    # Calculate bucket count
    my $bucket_count = int($decades * $histogram_buckets_per_decade + 0.5);
    $bucket_count = 5 if $bucket_count < 5;  # Minimum 5 buckets

    return $bucket_count;
}

sub calculate_histogram_buckets {
    my @metrics = keys %histogram_values;

    for my $metric (@metrics) {
        my $values_ref = $histogram_values{$metric};
        next unless @$values_ref > 0;

        # Sort values for percentile calculation
        my @sorted = sort { $a <=> $b } @$values_ref;
        my $n = scalar @sorted;

        # Calculate percentiles
        $histogram_stats{$metric} = {
            min    => $sorted[0],
            max    => $sorted[-1],
            p1     => $sorted[int($n * 0.01)],
            p10    => $sorted[int($n * 0.10)],
            p25    => $sorted[int($n * 0.25)],
            p50    => $sorted[int($n * 0.50)],
            p75    => $sorted[int($n * 0.75)],
            p90    => $sorted[int($n * 0.90)],
            p95    => $sorted[int($n * 0.95)],
            p99    => $sorted[int($n * 0.99)],
            p999   => $sorted[int($n * 0.999)] // $sorted[-1],
            p9999  => $sorted[int($n * 0.9999)] // $sorted[-1],
            count  => $n,
        };

        my $min = $sorted[0];
        my $max = $sorted[-1];

        # Handle edge case: all values identical
        if ($min == $max) {
            $min = $min * 0.9 if $min > 0;
            $max = $max * 1.1 if $max > 0;
            $min = 0.1 if $min <= 0;
            $max = 1 if $min == $max;
        }

        # Ensure min > 0 for logarithmic scale
        $min = 0.1 if $min <= 0;

        # Calculate bucket count using HdrHistogram approach
        my $bucket_count = calculate_histogram_bucket_count($min, $max);
        $histogram_stats{$metric}{bucket_count} = $bucket_count;
        $histogram_stats{$metric}{decades} = (log($max) - log($min)) / log(10);

        # Calculate logarithmic boundaries
        @{$histogram_boundaries{$metric}} = ();
        for my $i (0 .. $bucket_count) {
            my $boundary = $min * (($max / $min) ** ($i / $bucket_count));
            push @{$histogram_boundaries{$metric}}, $boundary;
        }

        # Initialize bucket counts
        @{$histogram_buckets{$metric}} = (0) x $bucket_count;

        # Assign values to buckets (binary search)
        for my $value (@sorted) {
            my $bucket_idx = find_bucket_index($value, $histogram_boundaries{$metric});
            $histogram_buckets{$metric}[$bucket_idx]++;
        }

        # Free memory
        @{$histogram_values{$metric}} = ();
    }
}

sub find_bucket_index {
    my ($value, $boundaries_ref) = @_;
    my $n = scalar(@$boundaries_ref) - 1;  # Number of buckets

    # Binary search
    my ($lo, $hi) = (0, $n - 1);
    while ($lo < $hi) {
        my $mid = int(($lo + $hi) / 2);
        if ($value < $boundaries_ref->[$mid + 1]) {
            $hi = $mid;
        } else {
            $lo = $mid + 1;
        }
    }
    return $lo;
}
```

### Phase 4: Layout Calculation

**Location**: New subroutine `calculate_histogram_layout()` (called from `normalize_data_for_output()` or separately)

**Returns**: Layout hash with dimensions for each histogram

```perl
sub calculate_histogram_layout {
    # Step 1: Get terminal width
    my $display_width = int($terminal_width * $histogram_width_percent / 100);

    # Step 2: Determine which metrics have data
    my @active_metrics = ();
    for my $metric (qw(duration bytes count)) {
        if ((!%histogram_metrics || $histogram_metrics{$metric}) &&
            exists $histogram_stats{$metric} &&
            $histogram_stats{$metric}{count} > 0) {
            push @active_metrics, $metric;
        }
    }

    return {} unless @active_metrics;

    my $n = scalar @active_metrics;

    # Step 3: Calculate spacing
    my $total_gap = ($n - 1) * $histogram_gap;

    # Step 4: Calculate available width for histograms
    my $available_width = $display_width - $total_gap;
    my $single_histogram_width = int($available_width / $n);

    # Step 5: Calculate internal layout for each histogram
    # Left Y-axis: count label (6 chars) + tick (2 chars) = 8
    # Right Y-axis: tick (2 chars) + percentage (5 chars) = 7
    # Total overhead per histogram: 15 chars
    my $y_axis_overhead = 15;
    my $bar_area_width = $single_histogram_width - $y_axis_overhead;
    $bar_area_width = 10 if $bar_area_width < 10;  # Minimum

    # Step 6: Calculate centering offset
    my $total_width = ($n * $single_histogram_width) + $total_gap;
    my $centering_offset = int(($terminal_width - $total_width) / 2);
    $centering_offset = 0 if $centering_offset < 0;

    return {
        active_metrics       => \@active_metrics,
        histogram_count      => $n,
        single_width         => $single_histogram_width,
        bar_area_width       => $bar_area_width,
        total_width          => $total_width,
        centering_offset     => $centering_offset,
        height               => $histogram_height,
    };
}
```

### Phase 5: Rendering

**Location**: New subroutine `print_histograms()` (after `print_bar_graph()`, around line 2800)

**Structure:**

1. Print title row for each histogram
2. Print Y-axis labels and bars row by row (top to bottom)
3. Print X-axis with tick marks
4. Print X-axis labels
5. Print legend (percentiles)

```perl
sub print_histograms {
    return unless $histogram_enabled;

    my $layout = calculate_histogram_layout();
    return unless $layout->{histogram_count};

    my @metrics = @{$layout->{active_metrics}};
    my $height = $layout->{height};
    my $bar_width = $layout->{bar_area_width};
    my $offset = $layout->{centering_offset};

    # Note: Buckets are calculated once based on data range (HdrHistogram approach)
    # Display scaling happens during rendering, not by recalculating buckets

    # Find max bucket count for scaling
    my %max_count;
    for my $metric (@metrics) {
        $max_count{$metric} = max(@{$histogram_buckets{$metric}}) || 1;
    }

    print "\n";  # Separator from bar graph

    # Title row
    print_histogram_titles($layout);

    # Column headers (Count / %)
    print_histogram_headers($layout);

    # Bar rows (top to bottom)
    for my $row (reverse 0 .. $height - 1) {
        print_histogram_row($layout, $row, \%max_count);
    }

    # X-axis
    print_histogram_x_axis($layout);

    # X-axis labels
    print_histogram_x_labels($layout);

    # Legend (percentiles)
    print_histogram_legend($layout);
}
```

**Bar character selection:**

```perl
my @bar_chars = (' ', '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█');

sub get_bar_char {
    my ($fill_level) = @_;  # 0.0 to 1.0
    my $index = int($fill_level * 8 + 0.5);
    $index = 8 if $index > 8;
    $index = 0 if $index < 0;
    return $bar_chars[$index];
}
```

**Display scaling (decoupled from bucket count):**

Since bucket count is determined by data range (not display width), rendering must scale buckets to display columns:

```perl
# Calculate display scaling
my $bucket_count = scalar(@{$histogram_buckets{$metric}});
my $cols_per_bucket = $bar_width / $bucket_count;

# Create display buckets (scaled to bar_width)
my @display_buckets;
if ($cols_per_bucket >= 1) {
    # Expand: each bucket maps to one or more display columns
    for my $i (0 .. $bar_width - 1) {
        my $bucket_idx = int($i / $cols_per_bucket);
        $bucket_idx = $bucket_count - 1 if $bucket_idx >= $bucket_count;
        push @display_buckets, $histogram_buckets{$metric}[$bucket_idx];
    }
} else {
    # Compress: multiple buckets aggregate to each display column
    my $buckets_per_col = $bucket_count / $bar_width;
    for my $i (0 .. $bar_width - 1) {
        my $start_bucket = int($i * $buckets_per_col);
        my $end_bucket = int(($i + 1) * $buckets_per_col) - 1;
        $end_bucket = $bucket_count - 1 if $end_bucket >= $bucket_count;
        my $sum = 0;
        for my $j ($start_bucket .. $end_bucket) {
            $sum += $histogram_buckets{$metric}[$j];
        }
        push @display_buckets, $sum;
    }
}
```

**Row rendering logic:**

For each row (0 = bottom, height-1 = top):
- Calculate the threshold: `row_threshold = (row + 1) / height`
- For each display column (not bucket):
  - Calculate bucket fill: `bucket_fill = display_buckets[$col] / max_count`
  - If `bucket_fill >= row_threshold`: print full block `█`
  - Else if `bucket_fill > (row / height)`: print partial block based on remainder
  - Else: print space (or gridline if enabled and at tick row)

### Phase 6: Box Drawing Characters

**Location**: New constant hash (in GLOBALS section)

**Note from prototyping**: Heavy box drawing characters render better on most terminals (no gaps between vertical lines). The implementation should support both heavy and light sets with a configuration variable.

```perl
# Box drawing character sets - configurable for terminal/OS compatibility
my $box_drawing_weight = 'heavy';  # 'heavy' or 'light'

my %box_char_sets = (
    light => {
        h_line    => '─',  # U+2500
        v_line    => '│',  # U+2502
        corner_tl => '┌',  # U+250C
        corner_tr => '┐',  # U+2510
        corner_bl => '└',  # U+2514
        corner_br => '┘',  # U+2518
        t_right   => '├',  # U+251C
        t_left    => '┤',  # U+2524
        t_down    => '┬',  # U+252C
        t_up      => '┴',  # U+2534
        cross     => '┼',  # U+253C
    },
    heavy => {
        h_line    => '━',  # U+2501
        v_line    => '┃',  # U+2503
        corner_tl => '┏',  # U+250F
        corner_tr => '┓',  # U+2513
        corner_bl => '┗',  # U+2517
        corner_br => '┛',  # U+251B
        t_right   => '┣',  # U+2523
        t_left    => '┫',  # U+252B
        t_down    => '┳',  # U+2533
        t_up      => '┻',  # U+253B
        cross     => '╋',  # U+254B
    },
);

my %box_chars = %{$box_char_sets{$box_drawing_weight}};

my @block_chars = (' ', '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█');
```

### Phase 7: Integration into Main Flow

**Location**: Main execution flow (around lines 3440-3480)

**Add call to histogram functions:**

```perl
# After line 3448 (calculate_heatmap_buckets)
calculate_histogram_buckets() if $histogram_enabled;

# After line 3465 (print_bar_graph)
print_histograms() if $histogram_enabled;
```

### Phase 8: Color Support

**Base colors** (match bar graph column plain_bg colors from ltl):

```perl
my %histogram_base_colors = (
    duration => 184,  # Yellow - matches bar graph column 2 plain_bg
    bytes    => 34,   # Green - matches bar graph column 3 plain_bg
    count    => 30,   # Cyan - matches bar graph column 4 plain_bg
);
```

**Color gradients** (for optional intensity variation):

```perl
my %histogram_color_gradients = (
    duration => [58, 94, 136, 142, 178, 184, 220, 226],   # Yellow gradient
    bytes    => [22, 28, 34, 40, 46, 82, 118, 154],       # Green gradient
    count    => [23, 30, 37, 44, 51, 80, 86, 123],        # Cyan gradient
);

my $color_gradient_enabled = 0;  # Toggle between flat base color and gradients
```

**Color application** (from prototyping - critical for eliminating whitespace gaps):

```perl
sub ansi_color_fg {
    my ($color_code) = @_;
    return "\e[38;5;${color_code}m";
}

sub ansi_color_fg_bg {
    my ($color_code) = @_;
    # Apply same color to both fg AND bg - eliminates whitespace gaps in full blocks
    return "\e[38;5;${color_code};48;5;${color_code}m";
}

# For full blocks (█): use ansi_color_fg_bg() to fill gaps
# For partial blocks (▁▂▃▄▅▆▇): use ansi_color_fg() only
```

### Phase 9: Dynamic Axis Scaling

**From prototyping**: Both X and Y axes need dynamic tick scaling based on available space.

**X-axis tick scaling:**

```perl
# Target: approximately one tick every 12 characters
my $target_spacing = 12;
my $num_ticks = int($bar_width / $target_spacing) + 1;
$num_ticks = 5 if $num_ticks < 5;  # Minimum 5 ticks (no maximum)
```

**Y-axis tick scaling:**

```perl
# Use "nice" tick counts that produce clean percentage intervals
my @nice_tick_counts = (2, 3, 5, 6, 9, 11, 21);
# 2 ticks = 50% intervals, 5 ticks = 25% intervals, 11 ticks = 10% intervals

my $y_target_spacing = 3;  # Target ~3 rows between ticks
my $ideal_ticks = int($height / $y_target_spacing) + 1;

# Select largest nice count that fits
my $num_y_ticks = 2;
for my $nice (@nice_tick_counts) {
    $num_y_ticks = $nice if $nice <= $ideal_ticks;
}
```

**Critical: 0% baseline on X-axis**

The X-axis line IS the 0% baseline. All height rows (0 to height-1) represent data > 0%. The X-axis shows "0" count on left and "0%" on right. Bars sit ON TOP of the X-axis floor.

### Phase 10: Optional Gridlines

**Horizontal gridlines at Y-axis tick positions:**

```perl
my $gridlines_enabled = 1;  # Toggle gridlines
my $gridline_color = 8;     # Dark grey (bright black / ANSI 8)

# Gridlines use light horizontal line (─) regardless of box drawing weight
# Only drawn in columns where there's no data (empty space)
# Only on rows with Y-axis tick marks
```

## Implementation Order

| Step | Description | Dependencies | Complexity | Notes from Prototype |
|------|-------------|--------------|------------|---------------------|
| 1 | Add global variables and CLI options | None | Low | Include `-hgbpd` and `-hgb` options |
| 2 | Add data collection in parsing loop | Step 1 | Low | |
| 3 | Implement `calculate_histogram_bucket_count()` | Step 2 | Low | HdrHistogram approach: decades × buckets_per_decade |
| 4 | Implement `calculate_histogram_buckets()` | Step 3 | Medium | Include expanded percentile set (P1-P99.99) |
| 5 | Implement `calculate_histogram_layout()` | Step 1 | Medium | Y-axis overhead = 16 chars (validated in prototype) |
| 6 | Implement box/block character constants | None | Low | Include both heavy and light sets |
| 7 | Implement `print_histograms()` skeleton | Steps 4-6 | Medium | |
| 8 | Implement display scaling (expand/compress) | Step 7 | Medium | Decouple bucket count from display width |
| 9 | Implement row rendering with bar chars | Step 8 | High | Use fg+bg color for full blocks |
| 10 | Implement dynamic Y-axis tick scaling | Step 9 | Medium | Use "nice" tick counts |
| 11 | Implement X-axis with dynamic ticks | Step 7 | Medium | Target 12-char spacing |
| 12 | Implement X-axis labels with collision avoidance | Step 11 | Medium | Same log formula as bucket boundaries |
| 13 | Implement legend with priority-based percentile selection | Step 4 | Medium | See priority order in feature doc |
| 14 | Implement optional gridlines | Steps 9-10 | Low | Light h-line in dark grey |
| 15 | Add color support (base + gradients) | Step 9 | Low | Match bar graph plain_bg colors |
| 16 | Add ANSI reset before right Y-axis | Step 9 | Low | Prevents color bleeding on wide displays |
| 17 | Integrate into main flow | Steps 1-16 | Low | |
| 18 | Add verbose output for bucket calculation | Step 4 | Low | Output when `-V` flag enabled |
| 19 | Testing and visual verification | All | Medium | Use prototype as reference |

## Testing Strategy

### Unit Tests (Manual)

1. **Bucket boundary calculation**: Verify logarithmic boundaries with known min/max
2. **Value-to-bucket assignment**: Test edge cases (min value, max value, middle)
3. **Bar character selection**: Verify correct character for fill levels 0%, 12.5%, 25%, ..., 100%
4. **Layout calculation**: Test with 1, 2, 3 active metrics at various terminal widths

### Integration Tests

```bash
# Duration + bytes (access logs)
./ltl -hg logs/AccessLogs/localhost_access_log.2025-03-21.txt

# All metrics (custom ThingWorx logs)
./ltl -hg logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log

# Single metric
./ltl -hg duration logs/AccessLogs/localhost_access_log.2025-03-21.txt

# Logs with count metric field
./ltl -hg count logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log

# Combined with heatmap (both should work)
./ltl -hm duration -hg logs/AccessLogs/localhost_access_log.2025-03-21.txt

# Custom height
./ltl -hg -hgh 15 logs/AccessLogs/localhost_access_log.2025-03-21.txt
```

### Visual Verification Checklist

- [ ] Bars are continuous pillars (no whitespace gaps) - use fg+bg color for full blocks
- [ ] Left Y-axis labels align with tick marks
- [ ] Right Y-axis percentage labels align with tick marks
- [ ] Y-axis tick marks scale dynamically with histogram height
- [ ] Percentage intervals are "nice" values (10%, 20%, 25%, 50%)
- [ ] 0% baseline is on X-axis line (not a data row)
- [ ] X-axis has `┗` and `┛` corners (heavy) or `└` and `┘` (light)
- [ ] X-axis tick marks scale dynamically with histogram width
- [ ] X-axis labels are readable and properly spaced (no overlap)
- [ ] X-axis labels correctly aligned with logarithmic bucket boundaries
- [ ] Multiple histograms are evenly spaced and centered
- [ ] Legend percentiles use priority-based selection
- [ ] Legend displays percentiles in ascending order
- [ ] Colors match bar graph column plain_bg values (184, 34, 30)
- [ ] Color gradient toggle works correctly
- [ ] Gridlines appear only at Y-axis tick rows and only in empty columns
- [ ] Gridlines use light horizontal line in dark grey
- [ ] Heavy/light box drawing weight is configurable
- [ ] Light background mode works correctly
- [ ] No color bleeding after right Y-axis (ANSI reset applied)
- [ ] Display scaling works correctly when display width > bucket count (expand)
- [ ] Display scaling works correctly when display width < bucket count (compress)
- [ ] Verbose output shows bucket calculation details when `-V` flag enabled

## Design Decisions (Resolved)

1. **Bucket count**: ~~Use 1:1 mapping (1 character = 1 bucket)~~ **SUPERSEDED** - Use HdrHistogram-style buckets-per-decade approach. Bucket count is determined by data range (decades) × buckets_per_decade, not display width. This follows industry standards for latency histograms and provides statistically meaningful bucketing. Display width determines how buckets are rendered (expanded across multiple columns or compressed via aggregation).

2. **Label collision avoidance**: Automatically reduce the number of X-axis labels based on available space. Approach:
   - Define a set of preferred tick mark positions (e.g., at 0%, 25%, 50%, 75%, 100% of range)
   - Calculate label width for each position
   - Disable labels that would overlap, starting from inner positions
   - Always try to keep min and max labels visible
   - This is complex due to variable label lengths (e.g., "1ms" vs "100ms" vs "10.5s")

3. **Narrow terminal handling**: Rather than a minimum width, automatically reduce the number of histograms displayed based on available space:
   - Calculate minimum usable width per histogram (e.g., 20 chars)
   - If all requested metrics don't fit, reduce count to what fits
   - Priority order: duration, bytes, count (matches bar graph column order)
   - User can explicitly select a specific metric with `-hg bytes` to override

## Files to Modify

| File | Changes |
|------|---------|
| `ltl` | All implementation (single file) |
| `features/histogram-charts.md` | Update progress tracking |

## Related Issues

- #25: Feature request (parent)
- #34: Memory optimization enhancement (deferred)

## Prototype Reference

The prototype at `prototype/histogram-prototype.pl` validates all rendering logic and should be used as the reference implementation for:

- **HdrHistogram-style bucket calculation** (buckets-per-decade model)
- **Display scaling** (expand/compress buckets to fit display width)
- Box drawing character configuration (heavy/light sets)
- Dynamic X-axis tick calculation
- Dynamic Y-axis tick calculation with "nice" intervals
- X-axis label alignment with logarithmic bucket boundaries
- 0% baseline handling (X-axis is the floor)
- Priority-based percentile legend selection
- fg+bg color application for full blocks
- Gridline rendering
- Color gradient toggle
- ANSI color reset before right Y-axis (prevents color bleeding on wide displays)

Key configuration variables validated in prototype:
- `$buckets_per_decade` = 8 (default, ~5% precision)
- `$box_drawing_weight` = 'heavy' (recommended)
- `$gridlines_enabled` = 1
- `$color_gradient_enabled` = 0 (for testing), 1 (for production)
- `$histogram_height` = 10 (default)
- `$histogram_width_percent` = 95
- `$histogram_gap` = 4
- `$histogram_legend_spacing` = 1

**Verbose output** (when `-V` flag enabled):
```
Histogram bucket calculation:
  Duration:  min=1ms      max=97.2s    decades=4.99 buckets_per_decade=8 total_buckets=40
  Bytes:     min=128B     max=12.4MB   decades=4.99 buckets_per_decade=8 total_buckets=40
  Count:     min=1        max=847      decades=2.93 buckets_per_decade=8 total_buckets=24
```
