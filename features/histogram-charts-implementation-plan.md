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

### Phase 3: Bucket Calculation

**Location**: New subroutine `calculate_histogram_buckets()` (after `calculate_heatmap_buckets()`, around line 1654)

**Algorithm:**

1. For each metric with data:
   - Find min/max values
   - Calculate logarithmic bucket boundaries (reuse heatmap formula)
   - Assign values to buckets using binary search
   - Calculate population percentiles (P50, P90, P99, P99.9)
   - Free raw values array to reclaim memory

```perl
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
            min   => $sorted[0],
            max   => $sorted[-1],
            p50   => $sorted[int($n * 0.50)],
            p90   => $sorted[int($n * 0.90)],
            p99   => $sorted[int($n * 0.99)],
            p999  => $sorted[int($n * 0.999)] // $sorted[-1],
            count => $n,
        };

        my $min = $sorted[0];
        my $max = $sorted[-1];

        # Handle edge case: all values identical
        if ($min == $max) {
            $min = $min * 0.9 if $min > 0;
            $max = $max * 1.1 if $max > 0;
            $min = 0 if $min == $max;  # fallback
            $max = 1 if $min == $max;
        }

        # Bucket count determined by available width (calculated later in layout)
        # For now, use a default that will be adjusted
        my $bucket_count = 50;  # Placeholder, adjusted during layout

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

    # Recalculate buckets with correct width
    recalculate_histogram_buckets($bar_width);

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

**Row rendering logic:**

For each row (0 = bottom, height-1 = top):
- Calculate the threshold: `row_threshold = (row + 1) / height`
- For each bucket:
  - Calculate bucket fill: `bucket_fill = bucket_count / max_count`
  - If `bucket_fill >= row_threshold`: print full block `█`
  - Else if `bucket_fill > (row / height)`: print partial block based on remainder
  - Else: print space

### Phase 6: Box Drawing Characters

**Location**: New constant hash (in GLOBALS section)

```perl
my %box_chars = (
    h_line      => '─',  # U+2500
    v_line      => '│',  # U+2502
    corner_tl   => '┌',  # U+250C
    corner_tr   => '┐',  # U+2510
    corner_bl   => '└',  # U+2514
    corner_br   => '┘',  # U+2518
    t_right     => '├',  # U+251C
    t_left      => '┤',  # U+2524
    t_down      => '┬',  # U+252C
    t_up        => '┴',  # U+2534
    cross       => '┼',  # U+253C
);

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

### Phase 8: Color Gradient Support

**Reuse existing heatmap color infrastructure:**

```perl
sub get_histogram_color {
    my ($metric, $intensity) = @_;  # intensity: 0-7

    my $color_name = $heatmap_metric_map{$metric}{color};
    my $colors = $light_background ? \%heatmap_colors_light : \%heatmap_colors;

    return $colors->{$color_name}[$intensity];
}
```

## Implementation Order

| Step | Description | Dependencies | Estimated Complexity |
|------|-------------|--------------|---------------------|
| 1 | Add global variables and CLI options | None | Low |
| 2 | Add data collection in parsing loop | Step 1 | Low |
| 3 | Implement `calculate_histogram_buckets()` | Step 2 | Medium |
| 4 | Implement `calculate_histogram_layout()` | Step 1 | Medium |
| 5 | Implement box/block character constants | None | Low |
| 6 | Implement `print_histograms()` skeleton | Steps 3-5 | Medium |
| 7 | Implement row rendering with bar chars | Step 6 | High |
| 8 | Implement X-axis with labels | Step 6 | Medium |
| 9 | Implement legend output | Step 3 | Low |
| 10 | Integrate into main flow | Steps 1-9 | Low |
| 11 | Add color gradient support | Step 7 | Low |
| 12 | Testing and visual verification | All | Medium |

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

- [ ] Bars are continuous pillars (no whitespace gaps)
- [ ] Left Y-axis labels align with tick marks
- [ ] Right Y-axis percentage labels align with tick marks
- [ ] X-axis has `└` and `┘` corners (enclosed frame)
- [ ] X-axis tick marks (`┬`) align with bucket boundaries
- [ ] X-axis labels are readable and properly spaced
- [ ] Multiple histograms are evenly spaced and centered
- [ ] Legend percentiles are below each histogram
- [ ] Colors match bar graph columns (yellow/green/cyan)
- [ ] Light background mode works correctly

## Design Decisions (Resolved)

1. **Bucket count**: Use 1:1 mapping (1 character = 1 bucket) for finest granularity. This may use more memory and could be revisited after real-world usage experience.

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
