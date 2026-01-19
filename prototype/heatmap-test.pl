#!/usr/bin/perl
#
# Heatmap Rendering Prototype
# ===========================
# This script explores different approaches for rendering latency distribution
# heatmaps in the terminal using ANSI 256-color escape codes and Unicode
# block characters.
#
# HEATMAP MODEL:
#   - X-axis (horizontal position): Latency value range (min → max)
#     - Left = fast requests, Right = slow requests
#   - Y-axis (rows): Time buckets
#   - Color intensity: Number of requests (density) at that latency
#     - Bright = many requests, Dark = few requests
#
# Run: perl prototype/heatmap-test.pl
#
# Tests four rendering approaches:
# 1. Shade + Color: Uses shade characters (░▒▓█) with color gradient
# 2. Color-Only: Uses full block (█) with color intensity only
# 3. Hybrid: Combines 2-3 shade levels with color gradient
# 4. Background Color: Uses space with background color intensity
#
# Also tests highlight overlay approaches.

use strict;
use warnings;
use utf8;
binmode(STDOUT, ":utf8");

# ============================================================================
# CONFIGURATION
# ============================================================================

my $heatmap_width = 51;      # Number of latency buckets (columns)
my $num_time_buckets = 15;   # Number of time rows to demonstrate

# Latency range for the heatmap (in milliseconds)
my $latency_min = 0;
my $latency_max = 5000;      # 5 seconds max

# Unicode block characters
my %blocks = (
    'empty'    => ' ',
    'light'    => '░',   # U+2591 - ~25% fill
    'medium'   => '▒',   # U+2592 - ~50% fill
    'dark'     => '▓',   # U+2593 - ~75% fill
    'full'     => '█',   # U+2588 - 100% fill
);

# ANSI escape codes
my $ESC = "\033";
my $RESET = "${ESC}[0m";
my $BOLD = "${ESC}[1m";

# ============================================================================
# COLOR DEFINITIONS
# ============================================================================

# 256-color gradients for DENSITY (request count), not latency value
# These go from dark (few requests) to bright (many requests)

my %color_gradients = (
    # Duration heatmap - Yellow theme (dark to bright)
    'duration' => [
        233, 234, 235,     # very dark grays (0-2 requests)
        58,  94,  136,     # dark olive/brown (few requests)
        142, 178, 184,     # yellow (moderate requests)
        220, 226, 227,     # bright yellow (many requests)
    ],

    # Bytes heatmap - Green theme (dark to bright)
    'bytes' => [
        233, 234, 235,     # very dark grays
        22,  28,  34,      # dark greens
        40,  46,  82,      # medium greens
        118, 154, 155,     # bright greens
    ],

    # Count heatmap - Cyan theme (dark to bright)
    'count' => [
        233, 234, 235,     # very dark grays
        23,  29,  30,      # dark cyans
        36,  37,  43,      # medium cyans
        44,  50,  51,      # bright cyans
    ],
);

# Highlight background colors (makes foreground pop while retaining metric color)
my %highlight_bg_colors = (
    'duration' => 226,  # bright yellow background
    'bytes'    => 46,   # bright green background
    'count'    => 51,   # bright cyan background
);

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

sub fg_color {
    my ($color_index) = @_;
    return "${ESC}[38;5;${color_index}m";
}

sub bg_color {
    my ($color_index) = @_;
    return "${ESC}[48;5;${color_index}m";
}

# Map density (0.0 to 1.0) to a color from the gradient
sub get_density_color {
    my ($gradient_name, $density) = @_;
    my @gradient = @{$color_gradients{$gradient_name}};
    my $index = int($density * $#gradient);
    $index = 0 if $index < 0;
    $index = $#gradient if $index > $#gradient;
    return $gradient[$index];
}

# Convert latency bucket index to milliseconds for display
sub bucket_to_latency {
    my ($bucket_index, $num_buckets) = @_;
    # Using logarithmic scale for better latency representation
    my $ratio = $bucket_index / ($num_buckets - 1);
    # Log scale: more resolution at lower latencies
    my $latency = $latency_min + ($latency_max - $latency_min) * ($ratio ** 2);
    return int($latency);
}

# ============================================================================
# REALISTIC TEST DATA GENERATION
# ============================================================================

# Generate realistic request distribution data
# This simulates what real log analysis would produce:
# - Most requests are fast (cluster at low latency)
# - Some requests are slow (tail latency)
# - Distribution shifts over time (simulating load changes)

sub generate_realistic_data {
    my ($num_time_buckets, $num_latency_buckets) = @_;
    my @data;

    # Max requests per cell for normalization
    my $max_requests = 0;

    for my $t (0 .. $num_time_buckets - 1) {
        my @row;

        # Simulate varying load over time
        my $load_factor = 0.7 + 0.3 * sin($t * 0.5);  # Varies 0.7-1.0
        my $base_requests = 1000 * $load_factor;

        for my $bucket (0 .. $num_latency_buckets - 1) {
            my $latency = bucket_to_latency($bucket, $num_latency_buckets);
            my $requests = 0;

            # Primary mode: Most requests are fast (0-200ms)
            # Exponential decay from left side
            if ($latency < 500) {
                $requests += $base_requests * exp(-$latency / 80);
            }

            # Secondary mode: Database queries (200-800ms)
            # Gaussian around 400ms
            my $db_center = 400 + $t * 10;  # Shifts over time
            $requests += ($base_requests * 0.15) * exp(-0.00005 * ($latency - $db_center) ** 2);

            # Tertiary mode: External API calls (1000-2000ms)
            # Smaller gaussian around 1500ms
            if ($t > 5) {  # Only appears after time bucket 5
                my $api_center = 1500;
                $requests += ($base_requests * 0.05) * exp(-0.000005 * ($latency - $api_center) ** 2);
            }

            # Tail latency outliers (random spikes at high latency)
            if ($latency > 2000 && rand() < 0.1) {
                $requests += rand() * $base_requests * 0.02;
            }

            # Add some noise
            $requests += rand() * $base_requests * 0.01;

            $requests = int($requests);
            $requests = 0 if $requests < 1;

            push @row, $requests;
            $max_requests = $requests if $requests > $max_requests;
        }
        push @data, \@row;
    }

    # Normalize to 0.0-1.0 range
    for my $row (@data) {
        for my $i (0 .. $#$row) {
            $row->[$i] = $max_requests > 0 ? $row->[$i] / $max_requests : 0;
        }
    }

    return (\@data, $max_requests);
}

# Generate highlight data (subset - e.g., requests matching a filter)
sub generate_highlight_data {
    my ($main_data_ref) = @_;
    my @highlight_data;

    for my $row (@$main_data_ref) {
        my @hl_row;
        for my $i (0 .. $#$row) {
            my $val = $row->[$i];
            # Highlight: requests in the "slow" range (middle-right of heatmap)
            # Simulates: -highlight "GET /api/slow-endpoint"
            if ($i > 20 && $i < 40 && $val > 0.05) {
                push @hl_row, $val * (0.3 + rand() * 0.4);  # Portion of requests
            } else {
                push @hl_row, 0;
            }
        }
        push @highlight_data, \@hl_row;
    }

    return @highlight_data;
}

# ============================================================================
# RENDERING APPROACHES
# ============================================================================

sub print_header {
    my ($title, $subtitle) = @_;
    print "\n${BOLD}=== $title ===${RESET}\n";
    print "$subtitle\n\n";
}

sub print_latency_scale {
    my ($width) = @_;
    # Print latency scale header
    print "             │ ";
    my $scale_points = 5;
    my $segment_width = int($width / $scale_points);

    for my $i (0 .. $scale_points) {
        my $bucket = int($i * $width / $scale_points);
        $bucket = $width - 1 if $bucket >= $width;
        my $latency = bucket_to_latency($bucket, $width);
        my $label;
        if ($latency >= 1000) {
            $label = sprintf("%.1fs", $latency / 1000);
        } else {
            $label = sprintf("%dms", $latency);
        }

        if ($i == 0) {
            print $label;
            print " " x ($segment_width - length($label));
        } elsif ($i == $scale_points) {
            print $label;
        } else {
            my $padding = $segment_width - length($label);
            my $left = int($padding / 2);
            print " " x $left . $label . " " x ($padding - $left);
        }
    }
    print "\n";
    print "  " . "─" x 9 . "┼" . "─" x ($width + 2) . "\n";
}

sub print_density_legend {
    my ($metric) = @_;
    print "\n  Density: ";
    my @gradient = @{$color_gradients{$metric}};
    print fg_color($gradient[0]) . "█" . $RESET . " few ";
    for my $i (1 .. $#gradient - 1) {
        print fg_color($gradient[$i]) . "█" . $RESET;
    }
    print " " . fg_color($gradient[$#gradient]) . "█" . $RESET . " many requests\n";
}

# Approach 1: Shade characters + Color gradient for density
sub render_shade_color {
    my ($data_ref, $metric, $title) = @_;

    print_header($title, "Shade characters (░▒▓█) show density, color intensity reinforces it");
    print "  X-axis: Latency (left=fast, right=slow)\n";
    print "  Color:  Request density (dark=few, bright=many)\n\n";

    print_latency_scale($heatmap_width);

    my $row_num = 0;
    for my $row (@$data_ref) {
        my $timestamp = sprintf("  %02d:00:00 │ ", 8 + $row_num);  # Start at 08:00
        print $timestamp;

        for my $density (@$row) {
            my $color = get_density_color($metric, $density);
            my $char;

            if ($density < 0.02) {
                $char = ' ';
            } elsif ($density < 0.15) {
                $char = $blocks{'light'};
            } elsif ($density < 0.35) {
                $char = $blocks{'medium'};
            } elsif ($density < 0.6) {
                $char = $blocks{'dark'};
            } else {
                $char = $blocks{'full'};
            }

            if ($char eq ' ') {
                print $char;
            } else {
                print fg_color($color) . $char . $RESET;
            }
        }
        print "\n";
        $row_num++;
    }

    print_density_legend($metric);
}

# Approach 2: Color-only with full blocks
sub render_color_only {
    my ($data_ref, $metric, $title) = @_;

    print_header($title, "Full blocks (█) with color intensity only");
    print "  X-axis: Latency (left=fast, right=slow)\n";
    print "  Color:  Request density (dark=few, bright=many)\n\n";

    print_latency_scale($heatmap_width);

    my $row_num = 0;
    for my $row (@$data_ref) {
        my $timestamp = sprintf("  %02d:00:00 │ ", 8 + $row_num);
        print $timestamp;

        for my $density (@$row) {
            if ($density < 0.02) {
                print " ";
            } else {
                my $color = get_density_color($metric, $density);
                print fg_color($color) . $blocks{'full'} . $RESET;
            }
        }
        print "\n";
        $row_num++;
    }

    print_density_legend($metric);
}

# Approach 3: Hybrid - 3 shade levels with color gradient
sub render_hybrid {
    my ($data_ref, $metric, $title) = @_;

    print_header($title, "3 shade levels (░▓█) combined with color gradient");
    print "  X-axis: Latency (left=fast, right=slow)\n";
    print "  Color:  Request density (dark=few, bright=many)\n\n";

    print_latency_scale($heatmap_width);

    my $row_num = 0;
    for my $row (@$data_ref) {
        my $timestamp = sprintf("  %02d:00:00 │ ", 8 + $row_num);
        print $timestamp;

        for my $density (@$row) {
            my $color = get_density_color($metric, $density);
            my $char;

            if ($density < 0.02) {
                $char = ' ';
            } elsif ($density < 0.25) {
                $char = $blocks{'light'};
            } elsif ($density < 0.55) {
                $char = $blocks{'dark'};
            } else {
                $char = $blocks{'full'};
            }

            if ($char eq ' ') {
                print $char;
            } else {
                print fg_color($color) . $char . $RESET;
            }
        }
        print "\n";
        $row_num++;
    }

    print_density_legend($metric);
}

# Approach 4: Background color
sub render_bg_color {
    my ($data_ref, $metric, $title) = @_;

    print_header($title, "Space character with background color intensity");
    print "  X-axis: Latency (left=fast, right=slow)\n";
    print "  Color:  Request density (dark=few, bright=many)\n\n";

    print_latency_scale($heatmap_width);

    my $row_num = 0;
    for my $row (@$data_ref) {
        my $timestamp = sprintf("  %02d:00:00 │ ", 8 + $row_num);
        print $timestamp;

        for my $density (@$row) {
            if ($density < 0.02) {
                print " ";
            } else {
                my $color = get_density_color($metric, $density);
                print bg_color($color) . " " . $RESET;
            }
        }
        print "\n";
        $row_num++;
    }

    print_density_legend($metric);
}

# Highlight overlay demonstration - uses bright background to make foreground pop
sub render_with_highlight {
    my ($data_ref, $highlight_ref, $metric, $title) = @_;

    print_header($title, "Highlighted requests use bright background (retains density color)");
    print "  Simulates: ./ltl --heatmap -highlight 'GET /api/slow'\n";
    print "  Bright background makes highlighted cells pop while keeping density color\n\n";

    print_latency_scale($heatmap_width);

    my $hl_bg = $highlight_bg_colors{$metric};

    my $row_num = 0;
    for my $i (0 .. $#$data_ref) {
        my $row = $data_ref->[$i];
        my $hl_row = $highlight_ref->[$i];

        my $timestamp = sprintf("  %02d:00:00 │ ", 8 + $row_num);
        print $timestamp;

        for my $j (0 .. $#$row) {
            my $density = $row->[$j];
            my $hl_density = $hl_row->[$j];

            if ($density < 0.02) {
                print " ";
            } elsif ($hl_density > 0.02) {
                # Highlighted request - bright background with foreground density color
                my $color = get_density_color($metric, $density);
                print bg_color($hl_bg) . fg_color($color) . $blocks{'full'} . $RESET;
            } else {
                # Normal request
                my $color = get_density_color($metric, $density);
                print fg_color($color) . $blocks{'full'} . $RESET;
            }
        }
        print "\n";
        $row_num++;
    }

    print "\n  Legend: ";
    print bg_color($hl_bg) . fg_color(0) . "█" . $RESET . " highlighted (bright bg)  ";
    my @gradient = @{$color_gradients{$metric}};
    for my $c (@gradient) { print fg_color($c) . "█" . $RESET; }
    print " normal\n";
}

# Demonstrate different metric color schemes
sub render_metric_comparison {
    my ($data_ref) = @_;

    print_header("Color Scheme Comparison", "Same data with different metric color themes");

    # Use middle row for comparison
    my $sample_row = $data_ref->[7];

    for my $metric (qw(duration bytes count)) {
        my $label = sprintf("  %-10s", "$metric:");
        print $label;

        for my $density (@$sample_row) {
            if ($density < 0.02) {
                print " ";
            } else {
                my $color = get_density_color($metric, $density);
                print fg_color($color) . $blocks{'full'} . $RESET;
            }
        }
        print "\n";
    }

    print "\n  All three show the same latency distribution,\n";
    print "  just with different color themes.\n";
}

# ============================================================================
# MAIN
# ============================================================================

print "\n";
print "═" x 72 . "\n";
print "  LATENCY HEATMAP RENDERING PROTOTYPE\n";
print "  Testing approaches for terminal heatmap visualization\n";
print "═" x 72 . "\n";

print "\n  ${BOLD}HEATMAP MODEL:${RESET}\n";
print "  • X-axis (position):  Latency value (left=fast, right=slow)\n";
print "  • Y-axis (rows):      Time buckets (like existing ltl output)\n";
print "  • Color intensity:    Request count (dark=few, bright=many)\n";
print "\n  This shows WHERE requests fall in the latency distribution\n";
print "  and HOW MANY requests are at each latency level.\n";

# Generate realistic test data
my ($data_ref, $max_requests) = generate_realistic_data($num_time_buckets, $heatmap_width);
my @highlight = generate_highlight_data($data_ref);

print "\n  Test data simulates:\n";
print "  • Primary mode: Fast requests (0-200ms) - most traffic\n";
print "  • Secondary mode: DB queries (~400ms) - shifts over time\n";
print "  • Tertiary mode: API calls (~1500ms) - appears mid-way\n";
print "  • Tail outliers: Random slow requests (>2000ms)\n";

# Test all rendering approaches
print "\n" . "─" x 72 . "\n";
render_shade_color($data_ref, 'duration', 'Approach 1: Shade + Color');

print "\n" . "─" x 72 . "\n";
render_color_only($data_ref, 'duration', 'Approach 2: Color Only (Full Blocks)');

print "\n" . "─" x 72 . "\n";
render_hybrid($data_ref, 'duration', 'Approach 3: Hybrid (3 Shades + Color)');

print "\n" . "─" x 72 . "\n";
render_bg_color($data_ref, 'duration', 'Approach 4: Background Color');

print "\n" . "─" x 72 . "\n";
render_with_highlight($data_ref, \@highlight, 'duration', 'Highlight Overlay Demo');

print "\n" . "─" x 72 . "\n";
render_metric_comparison($data_ref);

print "\n";
print "═" x 72 . "\n";
print "  INTERPRETATION GUIDE\n";
print "═" x 72 . "\n";
print <<'GUIDE';

  What to look for in these heatmaps:

  1. PRIMARY MODE (left side, bright): Most requests are fast
     - The bright yellow cluster on the left shows healthy fast responses

  2. SECONDARY MODE (middle): Database-bound requests
     - A dimmer cluster around 400ms that shifts right over time
     - This simulates increasing DB load during the day

  3. TERTIARY MODE (right-middle): External API calls
     - Appears in later time buckets around 1500ms
     - Shows when slow external dependencies kick in

  4. TAIL LATENCY (far right): Outliers
     - Sparse dots at high latency values
     - These are the P99/P99.9 contributors

  The heatmap reveals patterns that percentiles hide:
  - Bi-modal/multi-modal distributions are immediately visible
  - You can see HOW the distribution shifts over time
  - Outliers are visible in context of the whole distribution

GUIDE

print "\n";
