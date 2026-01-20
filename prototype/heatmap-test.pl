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

# Generate multiple highlight datasets for different filter scenarios
sub generate_highlight_data {
    my ($main_data_ref) = @_;
    my @highlight_data;

    for my $row (@$main_data_ref) {
        my @hl_row;
        for my $i (0 .. $#$row) {
            my $val = $row->[$i];
            # Highlight pattern: every other bucket with significant density
            # This creates a diverse pattern across ALL density levels
            # Simulates: -highlight "POST" (which appears across fast and slow requests)
            if ($i % 2 == 0 && $val > 0.01) {
                push @hl_row, $val * (0.6 + rand() * 0.4);  # 60-100% of requests match
            } else {
                push @hl_row, 0;
            }
        }
        push @highlight_data, \@hl_row;
    }

    return @highlight_data;
}

# Generate highlight for fast requests only (left side, high density)
sub generate_highlight_fast {
    my ($main_data_ref) = @_;
    my @highlight_data;

    for my $row (@$main_data_ref) {
        my @hl_row;
        for my $i (0 .. $#$row) {
            my $val = $row->[$i];
            # Highlight fast requests (buckets 0-12, the bright yellow area)
            if ($i <= 12 && $val > 0.02) {
                push @hl_row, $val * (0.5 + rand() * 0.5);
            } else {
                push @hl_row, 0;
            }
        }
        push @highlight_data, \@hl_row;
    }

    return @highlight_data;
}

# Generate highlight for slow requests only
sub generate_highlight_slow {
    my ($main_data_ref) = @_;
    my @highlight_data;

    for my $row (@$main_data_ref) {
        my @hl_row;
        for my $i (0 .. $#$row) {
            my $val = $row->[$i];
            # Highlight slow requests (buckets 15+)
            if ($i >= 15 && $val > 0.005) {
                push @hl_row, $val * (0.7 + rand() * 0.3);
            } else {
                push @hl_row, 0;
            }
        }
        push @highlight_data, \@hl_row;
    }

    return @highlight_data;
}

# Generate highlight for middle/DB range
sub generate_highlight_db {
    my ($main_data_ref) = @_;
    my @highlight_data;

    for my $row (@$main_data_ref) {
        my @hl_row;
        for my $i (0 .. $#$row) {
            my $val = $row->[$i];
            # Highlight DB query range (buckets 5-20)
            if ($i >= 5 && $i <= 20 && $val > 0.01) {
                push @hl_row, $val * (0.5 + rand() * 0.5);
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

# Side-by-side highlight comparison - normal vs filtered for each row
sub render_highlight_sidebyside {
    my ($data_ref, $highlight_ref, $metric) = @_;

    print_header("Side-by-Side Highlight Comparison", "Each time bucket shown with and without highlight filter");
    print "  Compare 'normal' (all traffic) vs 'filter' (highlighted subset)\n";
    print "  Filter simulates: -highlight 'GET /api/slow' (slow requests in 400-1500ms range)\n\n";

    my $hl_bg = $highlight_bg_colors{$metric};

    # Show latency scale once at top
    print "                    │ ";
    print "0ms        500ms       1s         2s        5s\n";
    print "  " . "─" x 16 . "┼" . "─" x ($heatmap_width + 2) . "\n";

    for my $i (0 .. $#$data_ref) {
        my $row = $data_ref->[$i];
        my $hl_row = $highlight_ref->[$i];
        my $hour = 8 + $i;

        # Print normal row
        my $label_normal = sprintf("  %02d:00 normal │ ", $hour);
        print $label_normal;
        for my $j (0 .. $#$row) {
            my $density = $row->[$j];
            if ($density < 0.02) {
                print " ";
            } else {
                my $color = get_density_color($metric, $density);
                print fg_color($color) . $blocks{'full'} . $RESET;
            }
        }
        print "\n";

        # Print highlighted row
        my $label_filter = "        filter │ ";
        print $label_filter;
        for my $j (0 .. $#$row) {
            my $density = $row->[$j];
            my $hl_density = $hl_row->[$j];

            if ($density < 0.02) {
                print " ";
            } elsif ($hl_density > 0.02) {
                my $color = get_density_color($metric, $density);
                print bg_color($hl_bg) . fg_color($color) . $blocks{'full'} . $RESET;
            } else {
                my $color = get_density_color($metric, $density);
                print fg_color($color) . $blocks{'full'} . $RESET;
            }
        }
        print "\n";

        # Add spacing between time bucket pairs
        print "\n" if $i < $#$data_ref;
    }

    print "\n  Legend: ";
    print bg_color($hl_bg) . fg_color(0) . "█" . $RESET . " = highlighted requests  ";
    my @gradient = @{$color_gradients{$metric}};
    print fg_color($gradient[0]) . "█" . $RESET . "→";
    print fg_color($gradient[$#gradient]) . "█" . $RESET . " = density (few→many)\n";
}

# Different highlight filter scenarios on same data
sub render_highlight_scenarios {
    my ($data_ref, $metric) = @_;

    print_header("Highlight Filter Scenarios", "Different filters applied to the same time bucket");
    print "  Shows how different -highlight patterns isolate different request populations\n\n";

    my $sample_row = $data_ref->[7];  # Use middle row

    # Define filter scenarios
    my @scenarios = (
        {
            name => "No filter (baseline)",
            desc => "all traffic",
            filter => sub { return 0; },
            bg => undef
        },
        {
            name => "Fast requests (<100ms)",
            desc => "-highlight 'cache hit'",
            filter => sub { my ($idx, $w) = @_; return $idx < int($w * 0.15); },
            bg => 51   # cyan
        },
        {
            name => "Medium requests (100-500ms)",
            desc => "-highlight 'DB query'",
            filter => sub { my ($idx, $w) = @_; return $idx >= int($w * 0.15) && $idx < int($w * 0.4); },
            bg => 201  # magenta
        },
        {
            name => "Slow requests (500ms-2s)",
            desc => "-highlight 'API call'",
            filter => sub { my ($idx, $w) = @_; return $idx >= int($w * 0.4) && $idx < int($w * 0.7); },
            bg => 226  # yellow
        },
        {
            name => "Very slow requests (>2s)",
            desc => "-highlight 'timeout'",
            filter => sub { my ($idx, $w) = @_; return $idx >= int($w * 0.7); },
            bg => 231  # white
        },
    );

    # Print latency scale
    print "                              │ ";
    print "0ms        500ms       1s         2s        5s\n";
    print "  " . "─" x 28 . "┼" . "─" x ($heatmap_width + 2) . "\n\n";

    for my $scenario (@scenarios) {
        my $label = sprintf("  %-28s│ ", $scenario->{name});
        print $label;

        for my $j (0 .. $#$sample_row) {
            my $density = $sample_row->[$j];
            my $is_highlighted = $scenario->{filter}->($j, $heatmap_width);

            if ($density < 0.02) {
                print " ";
            } elsif ($is_highlighted && defined $scenario->{bg}) {
                my $color = get_density_color($metric, $density);
                print bg_color($scenario->{bg}) . fg_color($color) . $blocks{'full'} . $RESET;
            } else {
                my $color = get_density_color($metric, $density);
                print fg_color($color) . $blocks{'full'} . $RESET;
            }
        }
        print "  $scenario->{desc}\n";
    }

    print "\n  Legend:\n";
    print "    " . bg_color(51) . fg_color(0) . "█" . $RESET . " cyan bg    = fast/cache hits\n";
    print "    " . bg_color(201) . fg_color(0) . "█" . $RESET . " magenta bg = DB queries\n";
    print "    " . bg_color(226) . fg_color(0) . "█" . $RESET . " yellow bg  = API calls\n";
    print "    " . bg_color(231) . fg_color(0) . "█" . $RESET . " white bg   = timeouts\n";
}

# Compare different background colors for highlighting
sub render_highlight_bg_comparison {
    my ($data_ref, $highlight_ref, $metric) = @_;

    print_header("Highlight Background Color Options", "Same highlight with different background colors");
    print "  Helps choose the best background color for visibility on your terminal\n\n";

    my $sample_row = $data_ref->[10];  # Use a row with good highlight data
    my $hl_row = $highlight_ref->[10];

    my @bg_options = (
        { name => "Yellow (226)",   bg => 226 },
        { name => "White (231)",    bg => 231 },
        { name => "Cyan (51)",      bg => 51 },
        { name => "Magenta (201)",  bg => 201 },
        { name => "Orange (208)",   bg => 208 },
        { name => "Green (46)",     bg => 46 },
        { name => "Red (196)",      bg => 196 },
        { name => "Blue (21)",      bg => 21 },
    );

    for my $opt (@bg_options) {
        my $label = sprintf("  %-16s│ ", $opt->{name});
        print $label;

        for my $j (0 .. $#$sample_row) {
            my $density = $sample_row->[$j];
            my $hl_density = $hl_row->[$j];

            if ($density < 0.02) {
                print " ";
            } elsif ($hl_density > 0.02) {
                my $color = get_density_color($metric, $density);
                print bg_color($opt->{bg}) . fg_color($color) . $blocks{'full'} . $RESET;
            } else {
                my $color = get_density_color($metric, $density);
                print fg_color($color) . $blocks{'full'} . $RESET;
            }
        }
        print "\n";
    }

    print "\n  Recommendation: Yellow or White typically provide best contrast\n";
    print "  with the yellow/brown density gradient.\n";
}

# Side-by-side with multiple highlight types
sub render_highlight_sidebyside_multi {
    my ($data_ref, $hl_fast_ref, $hl_db_ref, $hl_slow_ref, $metric) = @_;

    print_header("Multi-Filter Side-by-Side Comparison", "Same time buckets with different highlight filters");
    print "  Shows how different filters highlight different density regions\n\n";

    my $hl_bg = $highlight_bg_colors{$metric};

    # Show a subset of rows for clarity
    my @rows_to_show = (2, 5, 8, 11);  # Peak traffic times

    print "                        │ ";
    print "0ms        500ms       1s         2s        5s\n";
    print "  " . "─" x 20 . "┼" . "─" x ($heatmap_width + 2) . "\n";

    for my $i (@rows_to_show) {
        my $row = $data_ref->[$i];
        my $hl_fast = $hl_fast_ref->[$i];
        my $hl_db = $hl_db_ref->[$i];
        my $hl_slow = $hl_slow_ref->[$i];
        my $hour = 8 + $i;

        # Normal (no highlight)
        print sprintf("  %02d:00 %-12s│ ", $hour, "normal");
        for my $j (0 .. $#$row) {
            my $density = $row->[$j];
            if ($density < 0.02) { print " "; }
            else {
                my $color = get_density_color($metric, $density);
                print fg_color($color) . $blocks{'full'} . $RESET;
            }
        }
        print "\n";

        # Fast requests highlighted (bright yellow bg on bright chars)
        print sprintf("        %-12s│ ", "fast filter");
        for my $j (0 .. $#$row) {
            my $density = $row->[$j];
            my $hl = $hl_fast->[$j];
            if ($density < 0.02) { print " "; }
            elsif ($hl > 0.02) {
                my $color = get_density_color($metric, $density);
                print bg_color($hl_bg) . fg_color($color) . $blocks{'full'} . $RESET;
            } else {
                my $color = get_density_color($metric, $density);
                print fg_color($color) . $blocks{'full'} . $RESET;
            }
        }
        print "  ← bright yellow on bright yellow\n";

        # DB range highlighted (medium density)
        print sprintf("        %-12s│ ", "DB filter");
        for my $j (0 .. $#$row) {
            my $density = $row->[$j];
            my $hl = $hl_db->[$j];
            if ($density < 0.02) { print " "; }
            elsif ($hl > 0.02) {
                my $color = get_density_color($metric, $density);
                print bg_color(201) . fg_color($color) . $blocks{'full'} . $RESET;  # magenta bg
            } else {
                my $color = get_density_color($metric, $density);
                print fg_color($color) . $blocks{'full'} . $RESET;
            }
        }
        print "  ← magenta on medium\n";

        # Slow requests highlighted
        print sprintf("        %-12s│ ", "slow filter");
        for my $j (0 .. $#$row) {
            my $density = $row->[$j];
            my $hl = $hl_slow->[$j];
            if ($density < 0.02) { print " "; }
            elsif ($hl > 0.005) {
                my $color = get_density_color($metric, $density);
                print bg_color(231) . fg_color($color) . $blocks{'full'} . $RESET;  # white bg
            } else {
                my $color = get_density_color($metric, $density);
                print fg_color($color) . $blocks{'full'} . $RESET;
            }
        }
        print "  ← white on dim\n";

        print "\n" if $i != $rows_to_show[-1];
    }

    print "\n  Key insight: Notice how highlights appear across ALL density levels,\n";
    print "  from bright yellow (many requests) to dark (few requests).\n";
}

# Background color comparison with diverse density coverage
sub render_highlight_bg_comparison_diverse {
    my ($data_ref, $hl_fast_ref, $hl_db_ref, $metric) = @_;

    print_header("Background Colors on Different Densities", "Comparing highlight visibility across density levels");
    print "  Top section: Fast requests (HIGH density, bright foreground)\n";
    print "  Bottom section: DB range (MEDIUM density, moderate foreground)\n\n";

    my $sample_row = $data_ref->[5];  # Good traffic row
    my $hl_fast = $hl_fast_ref->[5];
    my $hl_db = $hl_db_ref->[5];

    my @bg_options = (
        { name => "Yellow (226)",   bg => 226 },
        { name => "White (231)",    bg => 231 },
        { name => "Cyan (51)",      bg => 51 },
        { name => "Magenta (201)",  bg => 201 },
        { name => "Orange (208)",   bg => 208 },
        { name => "Green (46)",     bg => 46 },
    );

    print "  ${BOLD}Fast requests (bright yellow foreground):${RESET}\n";
    for my $opt (@bg_options) {
        my $label = sprintf("  %-16s│ ", $opt->{name});
        print $label;

        for my $j (0 .. $#$sample_row) {
            my $density = $sample_row->[$j];
            my $hl = $hl_fast->[$j];

            if ($density < 0.02) {
                print " ";
            } elsif ($hl > 0.02) {
                my $color = get_density_color($metric, $density);
                print bg_color($opt->{bg}) . fg_color($color) . $blocks{'full'} . $RESET;
            } else {
                my $color = get_density_color($metric, $density);
                print fg_color($color) . $blocks{'full'} . $RESET;
            }
        }
        print "\n";
    }

    print "\n  ${BOLD}DB range (medium brown/olive foreground):${RESET}\n";
    for my $opt (@bg_options) {
        my $label = sprintf("  %-16s│ ", $opt->{name});
        print $label;

        for my $j (0 .. $#$sample_row) {
            my $density = $sample_row->[$j];
            my $hl = $hl_db->[$j];

            if ($density < 0.02) {
                print " ";
            } elsif ($hl > 0.02) {
                my $color = get_density_color($metric, $density);
                print bg_color($opt->{bg}) . fg_color($color) . $blocks{'full'} . $RESET;
            } else {
                my $color = get_density_color($metric, $density);
                print fg_color($color) . $blocks{'full'} . $RESET;
            }
        }
        print "\n";
    }

    print "\n  Note: Observe how visibility changes based on foreground brightness.\n";
    print "  Cyan/Magenta work well for bright foreground; White works for dark.\n";
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

# Generate different highlight patterns for diverse comparisons
my @highlight_mixed = generate_highlight_data($data_ref);     # Mixed pattern across all densities
my @highlight_fast = generate_highlight_fast($data_ref);      # Fast/bright area
my @highlight_slow = generate_highlight_slow($data_ref);      # Slow/dim area
my @highlight_db = generate_highlight_db($data_ref);          # Middle DB range

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

# Highlight demos with FAST requests (bright yellow areas)
print "\n" . "─" x 72 . "\n";
render_with_highlight($data_ref, \@highlight_fast, 'duration', 'Highlight: Fast Requests (bright yellow areas)');

# Highlight demos with DB range (medium density)
print "\n" . "─" x 72 . "\n";
render_with_highlight($data_ref, \@highlight_db, 'duration', 'Highlight: DB Query Range (medium density)');

# Highlight demos with SLOW requests
print "\n" . "─" x 72 . "\n";
render_with_highlight($data_ref, \@highlight_slow, 'duration', 'Highlight: Slow Requests (dim areas)');

# Highlight demos with MIXED pattern (shows all density levels)
print "\n" . "─" x 72 . "\n";
render_with_highlight($data_ref, \@highlight_mixed, 'duration', 'Highlight: Mixed Pattern (all density levels)');

print "\n" . "─" x 72 . "\n";
render_highlight_sidebyside_multi($data_ref, \@highlight_fast, \@highlight_db, \@highlight_slow, 'duration');

print "\n" . "─" x 72 . "\n";
render_highlight_scenarios($data_ref, 'duration');

print "\n" . "─" x 72 . "\n";
render_highlight_bg_comparison_diverse($data_ref, \@highlight_fast, \@highlight_db, 'duration');

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
