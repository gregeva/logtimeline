#!/usr/bin/env perl
# Histogram Charts Prototype
# Validates: bucket calculation, bar rendering, axis layout, label placement
#
# Usage: ./prototype/histogram-prototype.pl
#
# This prototype uses synthetic data to test histogram rendering independently
# of the main ltl log parsing infrastructure.

use strict;
use warnings;
use utf8;
binmode(STDOUT, ':utf8');

# ============================================================================
# CONFIGURATION
# ============================================================================

my $terminal_width = 120;          # Simulated terminal width
my $histogram_height = 10;         # Number of rows for bars
my $histogram_width_percent = 95;  # Percentage of terminal to use
my $histogram_gap = 4;             # Gap between histograms
my $histogram_legend_spacing = 1;  # Gap between histogram and legend

# Tick mark configuration (independent options)
my $tick_inside = 1;               # 1 = draw ticks pointing INTO the chart
my $tick_outside = 0;              # 1 = draw ticks pointing AWAY from the chart

# Gridline configuration
my $gridlines_enabled = 1;         # 1 = draw horizontal gridlines at Y-axis tick positions

# Color configuration
my $color_gradient_enabled = 0;    # 1 = use intensity gradients, 0 = single color (for testing)

# ============================================================================
# CHARACTER CONSTANTS
# ============================================================================

# Box drawing character sets - configurable for terminal/OS compatibility
# Set to 'heavy' or 'light' based on terminal rendering capabilities
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

# Active character set - code references this hash directly
my %box_chars = %{$box_char_sets{$box_drawing_weight}};

# 8-level block characters for sub-character resolution
my @block_chars = (' ', '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█');

# Base colors - match bar graph column plain_bg colors from ltl
# Duration (column 2): 184, Bytes (column 3): 34, Count (column 4): 30
my %base_colors = (
    duration => 184,  # Yellow - matches bar graph column 2 plain_bg
    bytes    => 34,   # Green - matches bar graph column 3 plain_bg
    count    => 30,   # Cyan - matches bar graph column 4 plain_bg
);

# Color gradients (256-color ANSI) - dark background
# Used when $color_gradient_enabled is true
my %color_gradients = (
    duration => [58, 94, 136, 142, 178, 184, 220, 226],   # Yellow gradient
    bytes    => [22, 28, 34, 40, 46, 82, 118, 154],       # Green gradient
    count    => [23, 30, 37, 44, 51, 80, 86, 123],        # Cyan gradient
);

# Gridline color - dark grey (bright black / ANSI 8)
my $gridline_color = 8;

# ============================================================================
# SYNTHETIC TEST DATA
# ============================================================================

sub generate_test_data {
    my ($metric) = @_;
    my @values;

    if ($metric eq 'duration') {
        # Simulated latency distribution: mostly fast, long tail
        # Values in milliseconds: 1ms to 100,000ms
        for (1..500) { push @values, 1 + rand(10); }        # Fast: 1-11ms
        for (1..300) { push @values, 10 + rand(90); }       # Medium: 10-100ms
        for (1..150) { push @values, 100 + rand(900); }     # Slow: 100ms-1s
        for (1..40)  { push @values, 1000 + rand(9000); }   # Very slow: 1-10s
        for (1..10)  { push @values, 10000 + rand(90000); } # Outliers: 10-100s
    }
    elsif ($metric eq 'bytes') {
        # Simulated response size distribution
        # Values in bytes: 100 to 10,000,000
        for (1..400) { push @values, 100 + rand(900); }           # Small: 100B-1KB
        for (1..350) { push @values, 1000 + rand(9000); }         # Medium: 1-10KB
        for (1..200) { push @values, 10000 + rand(90000); }       # Large: 10-100KB
        for (1..40)  { push @values, 100000 + rand(900000); }     # Very large: 100KB-1MB
        for (1..10)  { push @values, 1000000 + rand(9000000); }   # Huge: 1-10MB
    }
    elsif ($metric eq 'count') {
        # Simulated count distribution
        for (1..600) { push @values, 1 + int(rand(10)); }
        for (1..300) { push @values, 10 + int(rand(90)); }
        for (1..80)  { push @values, 100 + int(rand(900)); }
        for (1..20)  { push @values, 1000 + int(rand(9000)); }
    }

    return \@values;
}

# ============================================================================
# BUCKET CALCULATION
# ============================================================================

sub calculate_buckets {
    my ($values_ref, $bucket_count) = @_;

    return ([], [], {}) unless @$values_ref > 0;

    # Sort for percentile calculation
    my @sorted = sort { $a <=> $b } @$values_ref;
    my $n = scalar @sorted;

    # Calculate percentiles - comprehensive set for dynamic legend display
    # Priority order for selection (most important first for SRE/performance analysis):
    #   P50 (median), P99 (SLO critical), P95 (common SLO), P90, P99.9 (high-volume),
    #   P75, P99.99 (very high-volume), P25, P10, P1
    # Display order is always ascending (P1, P10, P25, ... P99.99)
    my %stats = (
        min    => $sorted[0],
        max    => $sorted[-1],
        count  => $n,
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
    );

    my $min = $sorted[0];
    my $max = $sorted[-1];

    # Handle edge case: all values identical
    if ($min == $max) {
        $min = $min * 0.9 if $min > 0;
        $max = $max * 1.1 if $max > 0;
        $min = 0.1 if $min == $max;
        $max = 1 if $min == $max;
    }

    # Ensure min > 0 for logarithmic scale
    $min = 0.1 if $min <= 0;

    # Calculate logarithmic boundaries
    my @boundaries;
    for my $i (0 .. $bucket_count) {
        my $boundary = $min * (($max / $min) ** ($i / $bucket_count));
        push @boundaries, $boundary;
    }

    # Initialize bucket counts
    my @buckets = (0) x $bucket_count;

    # Assign values to buckets
    for my $value (@sorted) {
        my $idx = find_bucket_index($value, \@boundaries);
        $buckets[$idx]++;
    }

    return (\@boundaries, \@buckets, \%stats);
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

# ============================================================================
# VALUE FORMATTING
# ============================================================================

sub format_duration {
    my ($ms) = @_;
    if ($ms < 1000) {
        return sprintf("%.0fms", $ms);
    } elsif ($ms < 60000) {
        my $s = $ms / 1000;
        return ($s == int($s)) ? sprintf("%.0fs", $s) : sprintf("%.1fs", $s);
    } elsif ($ms < 3600000) {
        my $m = $ms / 60000;
        return ($m == int($m)) ? sprintf("%.0fm", $m) : sprintf("%.1fm", $m);
    } else {
        my $h = $ms / 3600000;
        return ($h == int($h)) ? sprintf("%.0fh", $h) : sprintf("%.1fh", $h);
    }
}

sub format_bytes {
    my ($bytes) = @_;
    if ($bytes < 1024) {
        return sprintf("%.0fB", $bytes);
    } elsif ($bytes < 1024 * 1024) {
        my $kb = $bytes / 1024;
        return ($kb == int($kb)) ? sprintf("%.0fKB", $kb) : sprintf("%.1fKB", $kb);
    } elsif ($bytes < 1024 * 1024 * 1024) {
        my $mb = $bytes / (1024 * 1024);
        return ($mb == int($mb)) ? sprintf("%.0fMB", $mb) : sprintf("%.1fMB", $mb);
    } else {
        my $gb = $bytes / (1024 * 1024 * 1024);
        return ($gb == int($gb)) ? sprintf("%.0fGB", $gb) : sprintf("%.1fGB", $gb);
    }
}

sub format_count {
    my ($count) = @_;
    if ($count < 1000) {
        return sprintf("%.0f", $count);
    } elsif ($count < 1000000) {
        my $k = $count / 1000;
        return ($k == int($k)) ? sprintf("%.0fK", $k) : sprintf("%.1fK", $k);
    } else {
        my $m = $count / 1000000;
        return ($m == int($m)) ? sprintf("%.0fM", $m) : sprintf("%.1fM", $m);
    }
}

sub format_value {
    my ($value, $metric) = @_;
    if ($metric eq 'duration') {
        return format_duration($value);
    } elsif ($metric eq 'bytes') {
        return format_bytes($value);
    } else {
        return format_count($value);
    }
}

# ============================================================================
# LAYOUT CALCULATION
# ============================================================================

sub calculate_layout {
    my ($metrics_ref) = @_;

    my $display_width = int($terminal_width * $histogram_width_percent / 100);
    my $n = scalar @$metrics_ref;

    return {} unless $n > 0;

    # Calculate spacing
    my $total_gap = ($n - 1) * $histogram_gap;

    # Calculate available width
    my $available_width = $display_width - $total_gap;
    my $single_width = int($available_width / $n);

    # Internal layout per histogram
    # Left Y-axis: label (7 chars) + tick (2 chars) = 9
    # Right Y-axis: tick (2 chars) + label (5 chars) = 7
    my $y_axis_overhead = 16;
    my $bar_area_width = $single_width - $y_axis_overhead;
    $bar_area_width = 10 if $bar_area_width < 10;

    # Centering offset
    my $total_width = ($n * $single_width) + $total_gap;
    my $centering_offset = int(($terminal_width - $total_width) / 2);
    $centering_offset = 0 if $centering_offset < 0;

    return {
        metrics          => $metrics_ref,
        count            => $n,
        single_width     => $single_width,
        bar_area_width   => $bar_area_width,
        total_width      => $total_width,
        centering_offset => $centering_offset,
        y_axis_overhead  => $y_axis_overhead,
    };
}

# ============================================================================
# RENDERING
# ============================================================================

sub ansi_color_fg {
    my ($color_code) = @_;
    return "\e[38;5;${color_code}m";
}

sub ansi_color_fg_bg {
    my ($color_code) = @_;
    return "\e[38;5;${color_code};48;5;${color_code}m";
}

sub ansi_reset {
    return "\e[0m";
}

sub get_bar_char {
    my ($fill_fraction) = @_;
    # fill_fraction is 0.0 to 1.0 within a single character cell
    my $index = int($fill_fraction * 8 + 0.5);
    $index = 8 if $index > 8;
    $index = 0 if $index < 0;
    return $block_chars[$index];
}

# Get tick characters based on configuration
# Returns (left_tick, right_tick) - single characters only
# Based on combination of $tick_inside and $tick_outside settings
sub get_y_tick_chars {
    my ($position) = @_;  # 'top', 'mid', 'bottom', 'none'

    if ($position eq 'none') {
        return ($box_chars{v_line}, $box_chars{v_line});
    }

    # Determine tick character based on inside/outside configuration
    # For LEFT Y-axis:
    #   inside tick = ├ (stem points right, into chart)
    #   outside tick = ┤ (stem points left, away from chart)
    #   both = ┼ (cross)
    #   neither = │ (vertical line)
    # For RIGHT Y-axis:
    #   inside tick = ┤ (stem points left, into chart)
    #   outside tick = ├ (stem points right, away from chart)
    #   both = ┼ (cross)
    #   neither = │ (vertical line)

    my ($left_char, $right_char);

    if ($tick_inside && $tick_outside) {
        # Both: cross on both sides
        $left_char = $box_chars{cross};
        $right_char = $box_chars{cross};
    } elsif ($tick_inside) {
        # Inside only: ticks point into chart
        $left_char = $box_chars{t_right};   # ├
        $right_char = $box_chars{t_left};   # ┤
    } elsif ($tick_outside) {
        # Outside only: ticks point away from chart
        $left_char = $box_chars{t_left};    # ┤
        $right_char = $box_chars{t_right};  # ├
    } else {
        # Neither: just vertical lines
        $left_char = $box_chars{v_line};
        $right_char = $box_chars{v_line};
    }

    return ($left_char, $right_char);
}

# Calculate X-axis label positions with dynamic tick count based on width
sub calculate_x_labels {
    my ($boundaries_ref, $bar_width, $metric) = @_;

    my $min_val = $boundaries_ref->[0];
    my $max_val = $boundaries_ref->[-1];

    # Dynamically calculate number of ticks based on bar width
    # Target: approximately one tick every 12 characters for good readability
    my $target_spacing = 12;
    my $num_ticks = int($bar_width / $target_spacing) + 1;
    $num_ticks = 5 if $num_ticks < 5;  # Minimum 5 ticks (no maximum - scales with width)

    # Generate evenly spaced positions from 0 to 1
    my @positions;
    for my $i (0 .. $num_ticks - 1) {
        push @positions, $i / ($num_ticks - 1);
    }

    # Calculate values at each position (logarithmic scale)
    my @label_info;
    for my $pos (@positions) {
        my $value = $min_val * (($max_val / $min_val) ** $pos);
        my $label = format_value($value, $metric);
        my $col = int($pos * ($bar_width - 1));
        push @label_info, { pos => $pos, col => $col, value => $value, label => $label };
    }

    # Filter out labels that would overlap, keeping min/max as priority
    my @filtered;
    my $min_gap = 2;  # Minimum characters between labels

    for my $info (@label_info) {
        my $label_len = length($info->{label});
        my $start_col = $info->{col};

        # Center the label on the tick mark (except for edges)
        if ($info->{pos} > 0 && $info->{pos} < 1) {
            $start_col = $info->{col} - int($label_len / 2);
        } elsif ($info->{pos} == 1) {
            $start_col = $info->{col} - $label_len + 1;
        }

        $start_col = 0 if $start_col < 0;
        my $end_col = $start_col + $label_len - 1;

        # Check for overlap with existing labels
        my $overlaps = 0;
        for my $existing (@filtered) {
            if ($start_col <= $existing->{end_col} + $min_gap &&
                $end_col >= $existing->{start_col} - $min_gap) {
                $overlaps = 1;
                last;
            }
        }

        unless ($overlaps) {
            $info->{start_col} = $start_col;
            $info->{end_col} = $end_col;
            push @filtered, $info;
        }
    }

    return \@filtered;
}

sub render_histogram {
    my ($metric, $boundaries_ref, $buckets_ref, $stats_ref, $layout) = @_;

    my $bar_width = $layout->{bar_area_width};
    my $height = $histogram_height;
    my @buckets = @$buckets_ref;
    my $single_width = $layout->{single_width};

    # Find max bucket count for scaling
    my $max_bucket = 0;
    for my $b (@buckets) {
        $max_bucket = $b if $b > $max_bucket;
    }
    $max_bucket = 1 if $max_bucket == 0;

    my $color_gradient = $color_gradients{$metric};
    my $base_color = $base_colors{$metric};

    # Title - centered
    my $title = ucfirst($metric) . " Distribution";
    my $title_padding = int(($single_width - length($title)) / 2);
    print " " x $title_padding . $title . "\n";

    # Column headers (Y-axis names)
    # Bar row layout: "%6d " (7 chars) + tick (1 char) = 8 chars before bars
    # After bars: tick (1) + " %3d%%" (5 chars) = 6 chars total
    my $left_margin = 6;  # Width for count label value
    # Header row layout - both labels centered over their respective axes:
    # - "Count" (5 chars) centered in 8 chars = 1 space + Count + 2 spaces (before bar area)
    # - bar_width chars for bar area
    # - "%" (1 char) centered in 6 chars (tick + 5) = 3 spaces + % + 2 spaces
    printf " Count  %*s   %%\n", $bar_width, "";

    # Calculate dynamic Y-axis tick positions based on height
    # The 0% tick is on the X-axis line (separate from data rows)
    # Data rows (0 to height-1) represent values > 0% up to 100%
    # So we need ticks for the data area only (excluding 0% which is on X-axis)

    # Target: approximately one tick every 3-4 rows for good readability
    # Use tick counts that produce clean percentage intervals
    # Valid counts: 2 (100% only), 3 (50%, 100%), 5 (25%, 50%, 75%, 100%), etc.
    # Note: these counts are for data area ticks, 0% is always on X-axis
    my @nice_tick_counts = (2, 3, 5, 6, 9, 11, 21);

    my $y_target_spacing = 3;
    my $ideal_ticks = int($height / $y_target_spacing) + 1;

    # Find the closest nice tick count that doesn't exceed what fits
    my $num_y_ticks = 2;  # Default minimum (just 100% on data, 0% on X-axis)
    for my $nice (@nice_tick_counts) {
        if ($nice <= $ideal_ticks) {
            $num_y_ticks = $nice;
        }
    }

    # Calculate consistent percentage intervals for data area ticks
    # 0% is on X-axis, so data ticks are from first interval to 100%
    my $pct_interval = 100 / ($num_y_ticks - 1);

    # Build lookup: row -> percentage value (only for tick rows in data area)
    # Row 0 = lowest data (first interval %), Row height-1 = 100%
    my %y_tick_info = ();
    for my $i (1 .. $num_y_ticks - 1) {  # Skip i=0 (0% is on X-axis)
        my $pct = $i * $pct_interval;
        # Map percentage to row: 0% would be row -1 (X-axis), 100% is row height-1
        # So row = (pct / 100) * height - 1, but we want pct > 0 to map to rows 0+
        # Simpler: row = (pct / 100) * (height) - 1
        my $row = int($pct / 100 * $height - 0.5);
        $row = 0 if $row < 0;
        $row = $height - 1 if $row > $height - 1;
        $y_tick_info{$row} = {
            pct => int($pct + 0.5),
            count_fraction => $pct / 100,
        };
    }

    # Render rows from top to bottom
    for my $row (reverse 0 .. $height - 1) {
        my $row_threshold = ($row + 1) / $height;
        my $row_bottom = $row / $height;

        # Determine if this row has a tick mark
        my $has_tick = exists $y_tick_info{$row};

        my ($left_tick, $right_tick) = get_y_tick_chars($has_tick ? 'tick' : 'none');

        # Left Y-axis label - always same width for alignment
        # Format: 6 chars for number + 1 space = 7 chars, then tick
        my $y_label;
        my $y_pct;
        if ($has_tick) {
            # Use pre-calculated consistent percentage values
            my $pct_val = $y_tick_info{$row}{pct};
            my $count_val = int($max_bucket * $y_tick_info{$row}{count_fraction} + 0.5);
            $y_label = sprintf("%6d ", $count_val);
            $y_pct = sprintf(" %3d%%", $pct_val);
        } else {
            $y_label = sprintf("%6s ", "");
            $y_pct = sprintf(" %4s", "");
        }

        print $y_label . $left_tick;

        # Render bar characters for this row
        # Gridlines use light horizontal line (always), regardless of box drawing weight
        my $gridline_char = '─';  # U+2500 Light horizontal line

        for my $col (0 .. $bar_width - 1) {
            my $bucket_idx = $col;  # 1:1 mapping
            last if $bucket_idx >= scalar(@buckets);

            my $bucket_fill = $buckets[$bucket_idx] / $max_bucket;

            my $char;
            if ($bucket_fill >= $row_threshold) {
                # Full block
                $char = $block_chars[8];
            } elsif ($bucket_fill > $row_bottom) {
                # Partial block
                my $partial = ($bucket_fill - $row_bottom) / (1 / $height);
                $char = get_bar_char($partial);
            } else {
                # Empty - check if we should draw a gridline
                if ($gridlines_enabled && $has_tick) {
                    # Draw gridline in dark grey (bright black)
                    print ansi_color_fg($gridline_color) . $gridline_char . ansi_reset();
                    next;
                }
                $char = ' ';
            }

            # Determine color: gradient based on density, or flat base color
            my $color;
            if ($color_gradient_enabled) {
                # Color intensity based on bucket density
                my $intensity = int(($buckets[$bucket_idx] / $max_bucket) * 7);
                $intensity = 7 if $intensity > 7;
                $color = $color_gradient->[$intensity];
            } else {
                # Flat color: use base color matching bar graph columns
                $color = $base_color;
            }

            if ($char eq $block_chars[8]) {
                # Full block: use matching fg+bg color to fill any whitespace gaps
                print ansi_color_fg_bg($color) . $char . ansi_reset();
            } elsif ($char ne ' ') {
                # Partial block: fg color only
                print ansi_color_fg($color) . $char . ansi_reset();
            } else {
                print $char;
            }
        }

        # Right Y-axis
        print $right_tick . $y_pct . "\n";
    }

    # X-axis line with tick marks
    # This is the 0% baseline - includes 0 count on left and 0% on right
    my $x_labels = calculate_x_labels($boundaries_ref, $bar_width, $metric);
    my %tick_positions = map { $_->{col} => 1 } @$x_labels;

    # Left side: "     0 " (0 count, 6 chars right-justified + space = 7 chars)
    printf "%6d ", 0;
    print $box_chars{corner_bl};         # Corner at axis intersection

    for my $col (0 .. $bar_width - 1) {
        if (exists $tick_positions{$col}) {
            print $box_chars{t_down};
        } else {
            print $box_chars{h_line};
        }
    }
    # Right side: corner + " 0%" (space + 3 chars + %)
    print $box_chars{corner_br} . sprintf(" %3d%%", 0) . "\n";

    # X-axis labels
    # The corner is at position 7 (after 7 chars margin)
    # Bar col 0 is at position 8, so labels for col 0 should also be at position 8
    my @label_line = (' ') x ($bar_width + 20);
    my $x_offset = $left_margin + 2;  # margin(7) + corner(1) = 8, so offset is left_margin + 2

    for my $info (@$x_labels) {
        my $start = $x_offset + $info->{start_col};
        for my $i (0 .. length($info->{label}) - 1) {
            $label_line[$start + $i] = substr($info->{label}, $i, 1) if $start + $i < scalar(@label_line);
        }
    }
    print join('', @label_line) . "\n";

    # Legend (percentiles) - dynamically selected based on available width
    # Priority order: most important percentiles for SRE/performance analysis first
    # Display order: always ascending (sorted by percentile value)
    # Priority order rationale:
    # - P50: Always first - the baseline median experience
    # - P99: Second - critical SLO metric, shows tail behavior
    # - P99.9: Third - important for high-volume systems
    # - P95: Fourth - common SLO target, fills gap between P50 and P99
    # - P90: Fifth - only after P95/P99 are present for finer granularity
    # - P75: Sixth - upper quartile, distribution shape
    # - P99.99: Seventh - extreme tail for very high-volume systems
    # - P25: Eighth - lower quartile
    # - P10: Ninth - best-case typical
    # - P1: Tenth - floor performance
    my @percentile_priority = (
        { key => 'p50',   label => 'P50',    sort_order => 50 },
        { key => 'p99',   label => 'P99',    sort_order => 99 },
        { key => 'p999',  label => 'P99.9',  sort_order => 99.9 },
        { key => 'p95',   label => 'P95',    sort_order => 95 },
        { key => 'p90',   label => 'P90',    sort_order => 90 },
        { key => 'p75',   label => 'P75',    sort_order => 75 },
        { key => 'p9999', label => 'P99.99', sort_order => 99.99 },
        { key => 'p25',   label => 'P25',    sort_order => 25 },
        { key => 'p10',   label => 'P10',    sort_order => 10 },
        { key => 'p1',    label => 'P1',     sort_order => 1 },
    );

    my $separator = "   ";  # 3 spaces between percentiles
    # Legend width constrained to bar area (between Y-axes)
    my $available_width = $bar_width;

    # First pass: calculate all entry strings
    my @all_entries;
    for my $pct (@percentile_priority) {
        my $value_str = format_value($stats_ref->{$pct->{key}}, $metric);
        my $entry_str = $pct->{label} . ": " . $value_str;
        push @all_entries, {
            sort_order => $pct->{sort_order},
            str        => $entry_str,
            len        => length($entry_str),
        };
    }

    # Second pass: find maximum number of entries that fit (in priority order)
    # This ensures lower-priority items only appear if all higher-priority ones fit
    my $max_entries = 0;
    my $total_len = 0;
    for my $i (0 .. $#all_entries) {
        my $needed = $all_entries[$i]{len};
        $needed += length($separator) if $i > 0;
        if ($total_len + $needed <= $available_width) {
            $total_len += $needed;
            $max_entries = $i + 1;
        } else {
            last;  # Stop at first entry that doesn't fit
        }
    }

    # Take the first max_entries items (by priority) and sort for display
    my @selected = @all_entries[0 .. $max_entries - 1];
    @selected = sort { $a->{sort_order} <=> $b->{sort_order} } @selected;

    my $legend_line = join($separator, map { $_->{str} } @selected);
    # Center within bar_width, offset by left margin (8 chars: 6 digits + space + tick)
    my $left_margin_chars = 8;
    my $legend_padding = $left_margin_chars + int(($bar_width - length($legend_line)) / 2);
    $legend_padding = 0 if $legend_padding < 0;

    print "\n" x $histogram_legend_spacing;
    print " " x $legend_padding . $legend_line . "\n";
}

# ============================================================================
# MAIN
# ============================================================================

print "=" x $terminal_width . "\n";
print "HISTOGRAM PROTOTYPE - Testing rendering with synthetic data\n";
print "=" x $terminal_width . "\n\n";

# Test with different metric combinations
my @test_metrics = ('duration', 'bytes', 'count');

for my $metric (@test_metrics) {
    print "-" x 60 . "\n";
    print "Testing: $metric\n";
    print "-" x 60 . "\n\n";

    my $values = generate_test_data($metric);
    my $layout = calculate_layout([$metric]);
    my $bar_width = $layout->{bar_area_width};

    my ($boundaries, $buckets, $stats) = calculate_buckets($values, $bar_width);

    print "Data points: " . $stats->{count} . "\n";
    print "Range: " . format_value($stats->{min}, $metric) . " - " . format_value($stats->{max}, $metric) . "\n";
    print "Buckets: " . scalar(@$buckets) . "\n\n";

    render_histogram($metric, $boundaries, $buckets, $stats, $layout);
    print "\n\n";
}

# Test side-by-side rendering
print "=" x $terminal_width . "\n";
print "SIDE-BY-SIDE TEST (duration + bytes)\n";
print "=" x $terminal_width . "\n\n";

my $layout_dual = calculate_layout(['duration', 'bytes']);
print "Layout: single_width=" . $layout_dual->{single_width} .
      ", bar_width=" . $layout_dual->{bar_area_width} .
      ", centering=" . $layout_dual->{centering_offset} . "\n\n";

print "(Side-by-side rendering to be implemented in main integration)\n\n";

# Test different terminal widths for X-axis label adjustment
print "=" x $terminal_width . "\n";
print "TERMINAL WIDTH TESTS (X-axis label adjustment)\n";
print "=" x $terminal_width . "\n\n";

for my $test_width (50, 60, 70, 80, 100, 120, 150, 200, 250, 400) {
    print "-" x 40 . "\n";
    print "Terminal width: $test_width\n";
    print "-" x 40 . "\n\n";

    # Temporarily change terminal width
    my $saved_width = $terminal_width;
    $terminal_width = $test_width;

    my $values = generate_test_data('duration');
    my $layout = calculate_layout(['duration']);
    my $bar_width = $layout->{bar_area_width};

    my ($boundaries, $buckets, $stats) = calculate_buckets($values, $bar_width);

    print "Bar width: $bar_width buckets\n\n";

    render_histogram('duration', $boundaries, $buckets, $stats, $layout);
    print "\n\n";

    $terminal_width = $saved_width;
}

# Test different histogram heights for Y-axis label adjustment
print "=" x $terminal_width . "\n";
print "HISTOGRAM HEIGHT TESTS (Y-axis label adjustment)\n";
print "=" x $terminal_width . "\n\n";

for my $test_height (5, 10, 15, 20, 25, 30) {
    print "-" x 40 . "\n";
    print "Histogram height: $test_height rows\n";
    print "-" x 40 . "\n\n";

    # Temporarily change histogram height
    my $saved_height = $histogram_height;
    $histogram_height = $test_height;

    my $values = generate_test_data('duration');
    my $layout = calculate_layout(['duration']);
    my $bar_width = $layout->{bar_area_width};

    my ($boundaries, $buckets, $stats) = calculate_buckets($values, $bar_width);

    render_histogram('duration', $boundaries, $buckets, $stats, $layout);
    print "\n\n";

    $histogram_height = $saved_height;
}

print "Prototype complete.\n";
