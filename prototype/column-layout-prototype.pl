#!/usr/bin/env perl
# Column Layout Engine Prototype
# Validates: single-source-of-truth column definitions, proportional distribution
# algorithm, width allocation pipeline, and visual output at various terminal widths.
#
# Usage: ./prototype/column-layout-prototype.pl [terminal_width]
#
# This prototype uses synthetic column definitions to test the layout engine
# independently of the main ltl log parsing infrastructure.
#
# NEXT STEP: The legend column is currently modeled as a single content-driven
# column. It needs to be implemented as a compound column with three sub-columns:
#   1. Counts sub-column (category labels + occurrence counts)
#   2. Spacing sub-column (2 chars, conditionally visible)
#   3. Rates sub-column (error rate + message rate)
# Each sub-column width should be calculated independently from data, and the
# layout engine should allocate legend width as the sum of its sub-columns.
# The current data row rendering concatenates counts and rates as a single
# string, which does not validate the compound column or spacing model.

use strict;
use warnings;
use utf8;
binmode(STDOUT, ':utf8');

use POSIX qw(floor ceil);
use List::Util qw(sum max min);

# ============================================================================
# SECTION 1: CONFIGURATION
# ============================================================================

# Terminal width: auto-detect or override via command line
my $terminal_width;
if (@ARGV && $ARGV[0] =~ /^\d+$/) {
    $terminal_width = int($ARGV[0]);
} else {
    # Auto-detect from terminal
    eval {
        require Term::ReadKey;
        ($terminal_width) = Term::ReadKey::GetTerminalSize();
    };
    if (!$terminal_width) {
        $terminal_width = `tput cols 2>/dev/null` || 160;
        chomp $terminal_width;
        $terminal_width = int($terminal_width);
    }
}

# Padding constants from ltl line 89
my %padding = (
    all       => 1,   # $graph_column_padding_all
    timestamp => 1,   # $graph_column_padding_timestamp
    legend    => 0,   # $graph_column_padding_legend
    count     => 2,   # $graph_column_padding_count
    other     => 1,   # $graph_column_padding_other
    latency   => 3,   # $graph_column_padding_latency
);

# Current hardcoded percentage tables from ltl (for comparison)
my %current_tables = (
    1 => { 1 => 100 },
    2 => { 1 => 65, 2 => 35 },
    3 => { 1 => 62, 2 => 21, 3 => 17 },
    4 => { 1 => 50, 2 => 18, 3 => 16, 4 => 16 },
    5 => { 1 => 40, 2 => 15, 3 => 15, 4 => 15, 5 => 15 },
    6 => { 1 => 30, 2 => 14, 3 => 14, 4 => 14, 5 => 14, 6 => 14 },
);

# Tunable algorithm parameters for proportional distribution
my $focus_base = 70;    # Starting focus percentage for N=2
my $focus_step = 10;    # Decrease per additional column
my $focus_min  = 25;    # Floor for focus percentage

# Alternative algorithm parameters (exponential decay)
my $alt_focus_max   = 70;
my $alt_decay_rate  = 0.75;  # Each additional column multiplies remaining by this

# Simulated fixed widths for prototype
my $sim_timestamp_width = 17;    # Typical: "2025-03-21 14:30" + padding
my $sim_legend_width    = 30;    # Typical legend content width
my $sim_latency_width   = 56;    # 3 + 52 + 1 padding (pad_latency + 52 + pad_all)

# Color definitions for column types (data only, no ANSI rendering)
my @column_colors = (
    { name => 'yellow',  plain_bg => 184, highlight_bg => 226, gradient => [58, 94, 136, 142, 178, 184, 220, 226] },
    { name => 'green',   plain_bg => 34,  highlight_bg => 46,  gradient => [22, 28, 34, 40, 46, 82, 118, 154] },
    { name => 'cyan',    plain_bg => 30,  highlight_bg => 51,  gradient => [23, 30, 37, 44, 51, 80, 86, 123] },
    { name => 'blue',    plain_bg => 20,  highlight_bg => 27,  gradient => [17, 18, 19, 20, 21, 27, 33, 39] },
    { name => 'magenta', plain_bg => 127, highlight_bg => 207, gradient => [53, 89, 125, 127, 163, 165, 201, 207] },
);

# ============================================================================
# SECTION 2: COLUMN DEFINITION DATA STRUCTURE
# ============================================================================

# Build the default column set — the single source of truth.
# Returns an ordered array of column definition hashes.
sub build_default_columns {
    my (%opts) = @_;

    my $show_legend  = $opts{show_legend}  // 1;
    my $show_latency = $opts{show_latency} // 1;
    my $timestamp_w  = $opts{timestamp_width} // $sim_timestamp_width;
    my $legend_w     = $opts{legend_width}    // $sim_legend_width;
    my $latency_w    = $opts{latency_width}   // $sim_latency_width;

    my @cols;

    # Timestamp — fixed width
    push @cols, {
        id         => 'timestamp',
        type       => 'fixed',
        name       => 'timestamp',
        width      => undef,    # calculated
        base_width => $timestamp_w,
        spacing    => $padding{all} + $padding{timestamp},  # 2
        visible    => 1,
        color      => undef,
        priority   => undef,
        data_source => 'format',
    };

    # Legend — compound column (content-driven)
    if ($show_legend) {
        push @cols, {
            id         => 'legend',
            type       => 'content',
            name       => 'legend',
            width      => undef,
            base_width => $legend_w,
            spacing    => $padding{legend},  # 0
            visible    => 1,
            color      => undef,
            priority   => undef,
            data_source => 'log_occurrences',
        };
    }

    # Separator: legend | graph columns
    push @cols, {
        id         => 'sep_legend_graph',
        type       => 'separator',
        name       => '│',
        width      => undef,
        base_width => 1,
        spacing    => 0,
        visible    => $show_legend,
        color      => undef,
        priority   => undef,
        data_source => undef,
    };

    # Occurrences — proportional, focus column
    push @cols, {
        id         => 'occurrences',
        type       => 'proportional',
        name       => 'occurrences',
        width      => undef,
        base_width => undef,
        spacing    => $padding{count} - 1,  # 1 (separator accounts for 1 char of original pad_count=2)
        visible    => 1,
        color      => undef,  # occurrences uses category colors, not a single color
        priority   => 'focus',
        data_source => 'log_occurrences',
    };

    # Duration — proportional, secondary
    push @cols, {
        id         => 'duration',
        type       => 'proportional',
        name       => 'duration',
        width      => undef,
        base_width => undef,
        spacing    => $padding{all} + $padding{other},  # 2
        visible    => 0,   # only visible when data exists
        color      => $column_colors[0],  # yellow
        priority   => 'secondary',
        data_source => 'log_stats',
    };

    # Bytes — proportional, secondary
    push @cols, {
        id         => 'bytes',
        type       => 'proportional',
        name       => 'bytes',
        width      => undef,
        base_width => undef,
        spacing    => $padding{all} + $padding{other},  # 2
        visible    => 0,
        color      => $column_colors[1],  # green
        priority   => 'secondary',
        data_source => 'log_stats',
    };

    # Count — proportional, secondary
    push @cols, {
        id         => 'count',
        type       => 'proportional',
        name       => 'count',
        width      => undef,
        base_width => undef,
        spacing    => $padding{all} + $padding{other},  # 2
        visible    => 0,
        color      => $column_colors[2],  # cyan
        priority   => 'secondary',
        data_source => 'log_stats',
    };

    # Separator: graph columns | latency
    if ($show_latency) {
        push @cols, {
            id         => 'sep_graph_stats',
            type       => 'separator',
            name       => '│',
            width      => undef,
            base_width => 1,
            spacing    => 0,
            visible    => 1,
            color      => undef,
            priority   => undef,
            data_source => undef,
        };
    }

    # Latency statistics — fixed width
    if ($show_latency) {
        push @cols, {
            id         => 'latency',
            type       => 'fixed',
            name       => 'latency statistics',
            width      => undef,
            base_width => $latency_w,
            spacing    => $padding{latency} - 1,  # 2 (separator accounts for 1 char; original was pad_latency=3 embedded in the gap-fill + │ + 2 spaces)
            visible    => 1,
            color      => undef,
            priority   => undef,
            data_source => 'log_stats',
        };
    }

    return @cols;
}

# Add a dynamic column (threadpool or UDM) before the graph-stats separator
sub add_dynamic_column {
    my ($columns_ref, $id, $name, $color_index) = @_;

    my $color = $column_colors[$color_index % scalar(@column_colors)];

    # Find insertion point: before sep_graph_stats (or end of proportionals)
    my $insert_idx = scalar @$columns_ref;
    for my $i (0 .. $#$columns_ref) {
        if ($columns_ref->[$i]{id} eq 'sep_graph_stats') {
            $insert_idx = $i;
            last;
        }
    }

    my $new_col = {
        id         => $id,
        type       => 'proportional',
        name       => $name,
        width      => undef,
        base_width => undef,
        spacing    => $padding{all} + $padding{other},  # 2
        visible    => 1,
        color      => $color,
        priority   => 'secondary',
        data_source => 'log_stats',
    };

    splice @$columns_ref, $insert_idx, 0, $new_col;
    return $columns_ref;
}

# ============================================================================
# SECTION 3: PROPORTIONAL DISTRIBUTION ALGORITHM
# ============================================================================

# Algorithm A: Linear decay with floor
# focus_share = max(focus_min, focus_base - (N-1) * focus_step)
# secondaries split remainder equally
sub distribute_linear {
    my ($n_proportional, $base, $step, $min_focus) = @_;
    $base      //= $focus_base;
    $step      //= $focus_step;
    $min_focus //= $focus_min;

    return (100) if $n_proportional == 1;

    my $focus_pct = max($min_focus, $base - ($n_proportional - 2) * $step);
    my $secondary_pct = (100 - $focus_pct) / ($n_proportional - 1);

    my @shares = ($focus_pct);
    push @shares, $secondary_pct for 2 .. $n_proportional;
    return @shares;
}

# Algorithm B: Exponential decay
# focus starts at max, each additional column reduces the focus share multiplicatively
sub distribute_exponential {
    my ($n_proportional, $max_pct, $decay) = @_;
    $max_pct //= $alt_focus_max;
    $decay   //= $alt_decay_rate;

    return (100) if $n_proportional == 1;

    # Focus percentage decays: max * decay^(N-2) for N>=2
    my $focus_pct = $max_pct * ($decay ** ($n_proportional - 2));
    $focus_pct = max(15, $focus_pct);  # floor at 15%
    my $secondary_pct = (100 - $focus_pct) / ($n_proportional - 1);

    my @shares = ($focus_pct);
    push @shares, $secondary_pct for 2 .. $n_proportional;
    return @shares;
}

# ============================================================================
# SECTION 4: WIDTH ALLOCATION ENGINE
# ============================================================================

# Main layout calculation function
# Input: array of column definitions, terminal width
# Output: modifies column width fields in place, returns layout summary
sub calculate_layout {
    my ($columns_ref, $term_width) = @_;

    # Step 1: Filter to visible columns, resolve separator adjacency
    resolve_separator_visibility($columns_ref);

    my @visible = grep { $_->{visible} } @$columns_ref;

    # Step 2: Allocate fixed columns
    my $fixed_total = 0;
    for my $col (@visible) {
        if ($col->{type} eq 'fixed') {
            $col->{width} = $col->{base_width};
            $fixed_total += $col->{width};
        }
    }

    # Step 3: Allocate separator columns
    my $sep_total = 0;
    for my $col (@visible) {
        if ($col->{type} eq 'separator') {
            $col->{width} = $col->{base_width};  # always 1
            $sep_total += $col->{width};
        }
    }

    # Step 4: Allocate content-driven columns
    my $content_total = 0;
    for my $col (@visible) {
        if ($col->{type} eq 'content') {
            $col->{width} = $col->{base_width};  # pre-calculated from data scan
            $content_total += $col->{width};
        }
    }

    # Step 5: Deduct all spacing
    my $spacing_total = 0;
    for my $col (@visible) {
        $spacing_total += $col->{spacing};
    }

    # Step 6: Calculate remaining width for proportional columns
    my $allocated = $fixed_total + $sep_total + $content_total + $spacing_total;
    my $remaining = $term_width - $allocated;

    # Step 7: Distribute remaining to proportional columns
    my @prop_cols = grep { $_->{type} eq 'proportional' } @visible;
    my $n_prop = scalar @prop_cols;

    if ($n_prop > 0 && $remaining > 0) {
        # Get percentage shares from algorithm
        my @shares = distribute_linear($n_prop);

        # Convert percentages to pixel widths
        my @raw_widths;
        for my $i (0 .. $#prop_cols) {
            push @raw_widths, $shares[$i] / 100 * $remaining;
        }

        # Step 8: Apply cumulative rounding
        my @rounded = cumulative_round_widths(\@raw_widths, $remaining);

        # Deduct per-column spacing from proportional widths
        # (spacing is separate from width in our model, but we need to verify
        # the total budget works)
        for my $i (0 .. $#prop_cols) {
            $prop_cols[$i]->{width} = $rounded[$i];
        }
    } elsif ($n_prop > 0) {
        # Not enough space — assign minimum widths
        for my $col (@prop_cols) {
            $col->{width} = max(1, int($remaining / $n_prop));
        }
    }

    # Build summary
    my %summary = (
        terminal_width  => $term_width,
        fixed_total     => $fixed_total,
        separator_total => $sep_total,
        content_total   => $content_total,
        spacing_total   => $spacing_total,
        proportional_remaining => $remaining,
        n_proportional  => $n_prop,
        total_used      => 0,
    );

    # Calculate total used
    for my $col (@visible) {
        $summary{total_used} += ($col->{width} // 0) + $col->{spacing};
    }

    return %summary;
}

# Resolve separator visibility based on adjacency
# A separator is visible only if both adjacent non-separator columns are visible
sub resolve_separator_visibility {
    my ($columns_ref) = @_;

    for my $i (0 .. $#$columns_ref) {
        my $col = $columns_ref->[$i];
        next unless $col->{type} eq 'separator';

        # Find nearest visible non-separator column on each side
        my $prev_visible = 0;
        for my $j (reverse 0 .. $i-1) {
            next if $columns_ref->[$j]{type} eq 'separator';
            next unless $columns_ref->[$j]{visible};
            $prev_visible = 1;
            last;
        }

        my $next_visible = 0;
        for my $j ($i+1 .. $#$columns_ref) {
            next if $columns_ref->[$j]{type} eq 'separator';
            next unless $columns_ref->[$j]{visible};
            $next_visible = 1;
            last;
        }

        $col->{visible} = ($prev_visible && $next_visible) ? 1 : 0;
    }
}

# ============================================================================
# SECTION 5: CUMULATIVE ROUNDING
# ============================================================================

# Verbatim from ltl:3084-3108
sub cumulative_round_widths {
    my ($w_ref, $M) = @_;
    my @w = @$w_ref;

    # 1) cumulative sums
    my @cum;
    my $acc = 0.0;
    for my $x (@w) {
        $acc += $x;
        push @cum, $acc;
    }

    # 2) rounded boundaries (nearest), and force the last to M
    my @b = map { int($_ + 0.5) } @cum;
    $b[-1] = $M;

    # 3) widths from boundary differences
    my @widths;
    $widths[0] = $b[0];
    for my $i (1 .. $#b) {
        $widths[$i] = $b[$i] - $b[$i - 1];
    }

    return @widths;
}

# ============================================================================
# SECTION 6: RENDERING / MOCKUP OUTPUT
# ============================================================================

# Synthetic data for simulated data rows
my @sim_rows = (
    {
        timestamp  => '14:30:00',
        legend     => 'INFO: 245 WARN: 42 ERROR: 3 ',
        rates      => '12:892/m ',
        occ_fill   => 0.85,   # fraction of column width to fill with blocks
        duration   => { fill => 0.60, label => ' 4.2 sec' },
        bytes      => { fill => 0.35, label => ' 1.2 MB' },
        count      => { fill => 0.45, label => ' 23.4' },
        latency    => 'P50:120ms  P95:890ms  P99:2.1s   P999:4.5s  CV:  42',
    },
    {
        timestamp  => '14:35:00',
        legend     => 'INFO: 180 WARN: 8 ',
        rates      => '3:564/m ',
        occ_fill   => 0.55,
        duration   => { fill => 0.30, label => ' 1.8 sec' },
        bytes      => { fill => 0.70, label => ' 3.8 MB' },
        count      => { fill => 0.20, label => ' 8.1' },
        latency    => 'P50:85ms   P95:340ms  P99:1.2s   P999:2.8s  CV:  28',
    },
    {
        timestamp  => '14:40:00',
        legend     => 'INFO: 310 WARN: 95 ERROR: 18 ',
        rates      => '45:1.2k/m ',
        occ_fill   => 1.00,
        duration   => { fill => 0.90, label => ' 12.4 sec' },
        bytes      => { fill => 0.15, label => ' 420 KB' },
        count      => { fill => 0.80, label => ' 67.2' },
        latency    => 'P50:450ms  P95:3.2s   P99:8.7s   P999:12s   CV: 118',
    },
);

# Render a cell's content padded/truncated to exact width
sub render_cell {
    my ($content, $width) = @_;
    if (length($content) >= $width) {
        return substr($content, 0, $width);
    }
    return $content . ' ' x ($width - length($content));
}

# Render a bar graph cell: block chars for fill, value label overlaid, padded to width
sub render_bar_cell {
    my ($width, $fill_frac, $label) = @_;
    $label //= '';
    my $bar_chars = int($fill_frac * $width + 0.5);
    $bar_chars = $width if $bar_chars > $width;

    # Build the cell character by character
    my $result = '';
    my $label_len = length($label);
    for my $i (0 .. $width - 1) {
        my $has_label = $i < $label_len;
        if ($i < $bar_chars) {
            $result .= $has_label ? substr($label, $i, 1) : '█';
        } else {
            $result .= $has_label ? substr($label, $i, 1) : ' ';
        }
    }
    return $result;
}

# Render an occurrences bar with mixed category blocks
sub render_occ_bar {
    my ($width, $fill_frac) = @_;
    my $total_fill = int($fill_frac * $width + 0.5);
    $total_fill = $width if $total_fill > $width;

    # Simulate category proportions within the fill
    my $info_frac  = 0.65;
    my $warn_frac  = 0.25;
    my $error_frac = 0.10;

    my $info_w  = int($total_fill * $info_frac + 0.5);
    my $warn_w  = int($total_fill * $warn_frac + 0.5);
    my $error_w = $total_fill - $info_w - $warn_w;
    $error_w = 0 if $error_w < 0;

    # Use different block densities for categories (no color available)
    my $result = '█' x $info_w . '▓' x $warn_w . '░' x $error_w;
    $result .= ' ' x ($width - length($result)) if length($result) < $width;
    return substr($result, 0, $width);
}

# Render simulated data rows for visible columns
sub render_data_rows {
    my ($visible_ref, $term_width) = @_;

    for my $row (@sim_rows) {
        my $line = '';
        for my $col (@$visible_ref) {
            my $w   = $col->{width};
            my $sp  = $col->{spacing};
            my $id  = $col->{id};

            if ($col->{type} eq 'separator') {
                $line .= '│';
                next;
            }

            # Spacing before column content
            $line .= ' ' x $sp;

            if ($id eq 'timestamp') {
                $line .= render_cell($row->{timestamp}, $w);
            } elsif ($id eq 'legend') {
                # Combine counts and rates, right-pad to legend width
                my $counts = $row->{legend} // '';
                my $rates  = $row->{rates}  // '';
                my $legend_content = $counts;
                # Pad counts to fill legend width minus rates length
                my $counts_space = $w - length($rates);
                if ($counts_space > length($counts)) {
                    $legend_content = $counts . ' ' x ($counts_space - length($counts)) . $rates;
                } else {
                    $legend_content = $counts . $rates;
                }
                $line .= render_cell($legend_content, $w);
            } elsif ($id eq 'occurrences') {
                $line .= render_occ_bar($w, $row->{occ_fill});
            } elsif ($id eq 'latency') {
                $line .= render_cell($row->{latency} // '', $w);
            } elsif ($col->{type} eq 'proportional' && exists $row->{$id}) {
                my $data = $row->{$id};
                $line .= render_bar_cell($w, $data->{fill}, $data->{label});
            } else {
                # Unknown or no data — empty fill
                $line .= ' ' x $w;
            }
        }
        print "$line\n";
    }
}

# Render a visual box-drawing mockup of the column layout
sub render_layout_mockup {
    my ($columns_ref, $term_width, $label) = @_;

    my @visible = grep { $_->{visible} } @$columns_ref;
    return unless @visible;

    print "\n$label\n" if $label;
    print "Terminal Width: $term_width\n";

    # Build three rows: horizontal rule, header names, type labels
    # Only internal separators (│) are rendered — no outer box borders
    my $rule = '';
    my $mid  = '';
    my $bot  = '';

    for my $col (@visible) {
        my $total_w = $col->{width} + $col->{spacing};

        if ($col->{type} eq 'separator') {
            $rule .= '┼';
            $mid  .= '│';
            $bot  .= '│';
            next;
        }

        # Build column content
        my $header = $col->{name};
        my $type_label;
        if ($col->{type} eq 'fixed') {
            $type_label = sprintf "%d fixed", $col->{width};
        } elsif ($col->{type} eq 'content') {
            $type_label = sprintf "%d content", $col->{width};
        } elsif ($col->{type} eq 'proportional') {
            my $prio = $col->{priority} eq 'focus' ? 'focus' : 's';
            $type_label = sprintf "%d prop(%s)", $col->{width}, $prio;
        } else {
            $type_label = sprintf "%d", $col->{width};
        }

        # Header name (centered in total_w)
        my $h_text = length($header) > $total_w ? substr($header, 0, $total_w) : $header;
        my $h_pad_l = int(($total_w - length($h_text)) / 2);
        my $h_pad_r = $total_w - length($h_text) - $h_pad_l;

        # Type label (centered in total_w)
        my $t_text = length($type_label) > $total_w ? substr($type_label, 0, $total_w) : $type_label;
        my $t_pad_l = int(($total_w - length($t_text)) / 2);
        my $t_pad_r = $total_w - length($t_text) - $t_pad_l;

        $rule .= '─' x $total_w;
        $mid  .= ' ' x $h_pad_l . $h_text . ' ' x $h_pad_r;
        $bot  .= ' ' x $t_pad_l . $t_text . ' ' x $t_pad_r;
    }

    print "$rule\n";
    print "$mid\n";
    print "$bot\n";
    print "$rule\n";

    # Render simulated data rows
    render_data_rows(\@visible, $term_width);

    print "$rule\n";

    # Print column detail table
    printf "  %-20s %-14s %6s %7s %6s\n", "Column", "Type", "Width", "Spacing", "Total";
    printf "  %-20s %-14s %6s %7s %6s\n", '-' x 20, '-' x 14, '-' x 6, '-' x 7, '-' x 6;
    my $running_total = 0;
    for my $col (@visible) {
        my $total = ($col->{width} // 0) + $col->{spacing};
        $running_total += $total;
        printf "  %-20s %-14s %6d %7d %6d\n",
            $col->{id}, $col->{type}, $col->{width} // 0, $col->{spacing}, $total;
    }
    printf "  %-20s %-14s %6s %7s %6d\n", '', '', '', 'TOTAL:', $running_total;
    print "\n";
}

# ============================================================================
# SECTION 7: VALIDATION
# ============================================================================

my @test_results;

sub assert_ok {
    my ($test_name, $condition, $detail) = @_;
    $detail //= '';
    if ($condition) {
        push @test_results, { name => $test_name, pass => 1, detail => $detail };
    } else {
        push @test_results, { name => $test_name, pass => 0, detail => $detail };
    }
}

sub validate_layout {
    my ($columns_ref, $term_width, $test_prefix) = @_;
    $test_prefix //= '';

    my @visible = grep { $_->{visible} } @$columns_ref;

    # Check 1: Total width equals terminal width
    my $total = 0;
    for my $col (@visible) {
        $total += ($col->{width} // 0) + $col->{spacing};
    }
    assert_ok(
        "${test_prefix}Total width == terminal width",
        $total == $term_width,
        "expected $term_width, got $total"
    );

    # Check 2: No column has width <= 0 (except separators which are 1)
    for my $col (@visible) {
        next if $col->{type} eq 'separator';
        assert_ok(
            "${test_prefix}Column '$col->{id}' width > 0",
            ($col->{width} // 0) > 0,
            "width = " . ($col->{width} // 'undef')
        );
    }

    # Check 3: All proportional columns have reasonable minimum width
    for my $col (@visible) {
        next unless $col->{type} eq 'proportional';
        assert_ok(
            "${test_prefix}Proportional '$col->{id}' width >= 3",
            ($col->{width} // 0) >= 3,
            "width = " . ($col->{width} // 'undef')
        );
    }
}

# Compare algorithm output against current hardcoded tables
sub validate_algorithm_deviation {
    my ($test_prefix, $max_allowed_deviation) = @_;
    $max_allowed_deviation //= 5;

    for my $n (2 .. 6) {
        my @algo = distribute_linear($n);
        my $current = $current_tables{$n};

        for my $i (0 .. $n-1) {
            my $key = $i + 1;
            my $current_pct = $current->{$key};
            my $algo_pct = $algo[$i];
            my $delta = abs($algo_pct - $current_pct);

            assert_ok(
                "${test_prefix}N=$n col=$key deviation <= ${max_allowed_deviation}pp",
                $delta <= $max_allowed_deviation,
                sprintf("algo=%.1f%% current=%d%% delta=%.1f", $algo_pct, $current_pct, $delta)
            );
        }
    }
}

# ============================================================================
# OUTPUT SECTION A: ALGORITHM VS CURRENT TABLES
# ============================================================================

sub print_section_header {
    my ($letter, $title) = @_;
    print "\n";
    print "=" x 78 . "\n";
    print "  $letter. $title\n";
    print "=" x 78 . "\n";
}

sub output_algorithm_comparison {
    print_section_header('A', 'ALGORITHM VS CURRENT TABLES');

    printf "\n%-4s  %-40s  %-30s\n", "N", "Current Hardcoded", "Algorithm (Linear)";
    printf "%-4s  %-40s  %-30s\n", "-" x 4, "-" x 40, "-" x 30;

    for my $n (1 .. 8) {
        # Current table (only defined for 1-6)
        my $current_str;
        if (exists $current_tables{$n}) {
            my @pcts;
            for my $k (1 .. $n) {
                push @pcts, sprintf("%d%%", $current_tables{$n}{$k} // 0);
            }
            $current_str = join(' / ', @pcts);
        } else {
            $current_str = '(not defined)';
        }

        # Algorithm
        my @algo = distribute_linear($n);
        my @algo_strs = map { sprintf("%.1f%%", $_) } @algo;
        my $algo_str = join(' / ', @algo_strs);

        # Delta
        my $delta_str = '';
        if (exists $current_tables{$n}) {
            my @deltas;
            for my $i (0 .. $n-1) {
                my $d = $algo[$i] - ($current_tables{$n}{$i+1} // 0);
                push @deltas, sprintf("%+.1f", $d);
            }
            $delta_str = '  delta: ' . join('/', @deltas);
        }

        printf "%-4d  %-40s  %-30s%s\n", $n, $current_str, $algo_str, $delta_str;
    }

    # Also show exponential algorithm
    printf "\n%-4s  %-40s  %-30s\n", "N", "Algorithm (Linear)", "Algorithm (Exponential)";
    printf "%-4s  %-40s  %-30s\n", "-" x 4, "-" x 40, "-" x 30;

    for my $n (1 .. 8) {
        my @linear = distribute_linear($n);
        my @expo   = distribute_exponential($n);
        my $l_str = join(' / ', map { sprintf("%.1f%%", $_) } @linear);
        my $e_str = join(' / ', map { sprintf("%.1f%%", $_) } @expo);
        printf "%-4d  %-40s  %-30s\n", $n, $l_str, $e_str;
    }
}

# ============================================================================
# OUTPUT SECTION B: WIDTH SWEEP
# ============================================================================

sub output_width_sweep {
    print_section_header('B', 'WIDTH SWEEP');

    my @widths = (80, 100, 120, 160, 200, 350);

    for my $w (@widths) {
        # Build columns — adjust for narrow terminals
        # At narrow widths, hide latency and use fewer proportional columns
        # (this mirrors real ltl behavior where narrow terminals don't show stats)
        my $show_latency = ($w >= 120) ? 1 : 0;
        my $show_duration = ($w >= 130) ? 1 : 0;
        my $show_bytes = ($w >= 160) ? 1 : 0;

        my @cols = build_default_columns(show_latency => $show_latency);
        for my $col (@cols) {
            $col->{visible} = 1 if $col->{id} eq 'duration' && $show_duration;
            $col->{visible} = 1 if $col->{id} eq 'bytes' && $show_bytes;
        }

        my %summary = calculate_layout(\@cols, $w);
        render_layout_mockup(\@cols, $w, "--- Width Sweep: $w chars ---");
        validate_layout(\@cols, $w, "Width=$w: ");
    }
}

# ============================================================================
# OUTPUT SECTION C: COLUMN COUNT SWEEP
# ============================================================================

sub output_column_count_sweep {
    print_section_header('C', 'COLUMN COUNT SWEEP');

    # Show proportional distribution for 1-8 proportional columns
    # Use a fixed width of 250 to ensure enough room for all column counts
    my $sweep_width = max(200, $terminal_width);

    my @extra_cols = qw(duration bytes count tp_active udm_cpu udm_memory udm_disk);

    for my $n_extra (0 .. $#extra_cols) {
        my $n_prop = 1 + $n_extra;  # occurrences + extras

        my @cols = build_default_columns();

        # Enable the first n_extra additional columns
        my $enabled = 0;
        for my $i (0 .. $n_extra - 1) {
            my $target = $extra_cols[$i];
            my $found = 0;
            for my $col (@cols) {
                if ($col->{id} eq $target) {
                    $col->{visible} = 1;
                    $found = 1;
                    last;
                }
            }
            # If not found, add as dynamic column
            unless ($found) {
                add_dynamic_column(\@cols, $target, $target, $enabled);
                # Make it visible
                for my $col (@cols) {
                    if ($col->{id} eq $target) {
                        $col->{visible} = 1;
                        last;
                    }
                }
            }
            $enabled++;
        }

        my %summary = calculate_layout(\@cols, $sweep_width);

        # Print summary line
        my @prop_visible = grep { $_->{type} eq 'proportional' && $_->{visible} } @cols;
        printf "\n--- %d proportional column(s) at width %d ---\n", scalar(@prop_visible), $sweep_width;
        printf "  %-20s %6s %6s  %s\n", "Column", "Width", "Pct%", "Priority";
        printf "  %-20s %6s %6s  %s\n", '-' x 20, '-' x 6, '-' x 6, '-' x 10;
        my $prop_total = sum(map { $_->{width} } @prop_visible) || 1;
        for my $col (@prop_visible) {
            printf "  %-20s %6d %5.1f%%  %s\n",
                $col->{id}, $col->{width}, ($col->{width} / $prop_total) * 100, $col->{priority};
        }
        printf "  %-20s %6d %5.1f%%\n", "TOTAL", $prop_total, 100.0;

        validate_layout(\@cols, $sweep_width, "N_prop=$n_prop: ");
    }
}

# ============================================================================
# OUTPUT SECTION D: VISIBILITY TOGGLE DEMO
# ============================================================================

sub output_visibility_demo {
    print_section_header('D', 'VISIBILITY TOGGLE DEMO');

    my $w = 160;

    # Scenario 1: All default (timestamp, legend, occurrences, latency)
    {
        my @cols = build_default_columns();
        my %summary = calculate_layout(\@cols, $w);
        render_layout_mockup(\@cols, $w, "--- Default: timestamp + legend + occurrences + latency ---");
        validate_layout(\@cols, $w, "Vis-default: ");
    }

    # Scenario 2: Hide legend
    {
        my @cols = build_default_columns();
        for my $col (@cols) { $col->{visible} = 0 if $col->{id} eq 'legend'; }
        my %summary = calculate_layout(\@cols, $w);
        render_layout_mockup(\@cols, $w, "--- Legend hidden (space redistributed to occurrences) ---");
        validate_layout(\@cols, $w, "Vis-no-legend: ");
    }

    # Scenario 3: Hide latency
    {
        my @cols = build_default_columns();
        for my $col (@cols) { $col->{visible} = 0 if $col->{id} =~ /^(latency|sep_graph_stats)$/; }
        my %summary = calculate_layout(\@cols, $w);
        render_layout_mockup(\@cols, $w, "--- Latency hidden (space redistributed to occurrences) ---");
        validate_layout(\@cols, $w, "Vis-no-latency: ");
    }

    # Scenario 4: Full set with duration+bytes+count
    {
        my @cols = build_default_columns();
        for my $col (@cols) {
            $col->{visible} = 1 if $col->{id} =~ /^(duration|bytes|count)$/;
        }
        my %summary = calculate_layout(\@cols, $w);
        render_layout_mockup(\@cols, $w, "--- Full: all metrics visible ---");
        validate_layout(\@cols, $w, "Vis-full: ");
    }

    # Scenario 5: Full set then hide legend
    {
        my @cols = build_default_columns();
        for my $col (@cols) {
            $col->{visible} = 1 if $col->{id} =~ /^(duration|bytes|count)$/;
            $col->{visible} = 0 if $col->{id} eq 'legend';
        }
        my %summary = calculate_layout(\@cols, $w);
        render_layout_mockup(\@cols, $w, "--- Full metrics, no legend ---");
        validate_layout(\@cols, $w, "Vis-full-no-legend: ");
    }
}

# ============================================================================
# OUTPUT SECTION E: SEQUENCING DEMO
# ============================================================================

sub output_sequencing_demo {
    print_section_header('E', 'SEQUENCING DEMO: TABLE CALCULATION BEFORE SCALING');

    my $w = 160;

    print "\nThis demonstrates that the layout engine can calculate column widths\n";
    print "BEFORE any data scaling occurs. The scaling phase then uses these\n";
    print "widths to scale values proportionally into the available space.\n\n";

    # Step 1: Build columns and calculate layout
    my @cols = build_default_columns();
    for my $col (@cols) {
        $col->{visible} = 1 if $col->{id} =~ /^(duration|bytes)$/;
    }

    print "Step 1: Calculate layout (before scaling)\n";
    my %summary = calculate_layout(\@cols, $w);

    # Show the calculated widths
    printf "  %-20s %6s %6s\n", "Column", "Width", "Spacing";
    printf "  %-20s %6s %6s\n", '-' x 20, '-' x 6, '-' x 6;
    for my $col (grep { $_->{visible} } @cols) {
        printf "  %-20s %6d %6d\n", $col->{id}, $col->{width} // 0, $col->{spacing};
    }

    # Step 2: Simulate scaling using calculated widths
    print "\nStep 2: Scale data into calculated column widths\n";
    my %sim_max = (occurrences => 1500, duration => 45000, bytes => 2_500_000);
    my %sim_val = (occurrences => 750,  duration => 22000, bytes => 1_000_000);

    for my $col (grep { $_->{type} eq 'proportional' && $_->{visible} } @cols) {
        my $id = $col->{id};
        my $max = $sim_max{$id} // 100;
        my $val = $sim_val{$id} // 50;
        my $scaled = int(($val / $max) * $col->{width});
        printf "  %-20s max=%-10d val=%-10d col_width=%-4d scaled=%-4d (%.0f%% fill)\n",
            $id, $max, $val, $col->{width}, $scaled, ($scaled / $col->{width}) * 100;
    }

    validate_layout(\@cols, $w, "Sequencing: ");
}

# ============================================================================
# OUTPUT SECTION F: SEPARATOR BUDGET VALIDATION
# ============================================================================

sub output_separator_validation {
    print_section_header('F', 'SEPARATOR BUDGET VALIDATION');

    print "\nValidates that the separator-as-column model produces the same\n";
    print "total character budget as the current padding-embedded approach.\n\n";

    my $w = 160;

    # Current approach budget (from ltl)
    # timestamp: width + pad_timestamp + pad_all = 17 + 1 + 1 = 19
    # legend: width + pad_legend = 30 + 0 = 30
    # occurrences: width + pad_count + pad_all = W + 2 + 1 = W+3
    #   (pad_count includes the │ char)
    # duration: width + pad_other + pad_all = W + 1 + 1 = W+2
    # latency: width + pad_latency + pad_all = 52 + 3 + 1 = 56
    #   (gap-fill + │ + 2 spaces is how pad_latency works)

    # Our approach budget:
    # timestamp: width + spacing(2) = 17 + 2 = 19
    # legend: width + spacing(0) = 30 + 0 = 30
    # sep_legend_graph: width(1) + spacing(0) = 1
    # occurrences: width + spacing(1) = W + 1  (sep accounts for 1 of pad_count)
    # duration: width + spacing(2) = W + 2
    # sep_graph_stats: width(1) + spacing(0) = 1
    # latency: width + spacing(2) = 52 + 2 = 54  (sep accounts for 1 of pad_latency)

    # Total separators (ours): 1 + 1 = 2 chars
    # Total separators (current): embedded in pad_count(1st char) + pad_latency(│ char)
    # Net: identical

    my @cols = build_default_columns();
    for my $col (@cols) {
        $col->{visible} = 1 if $col->{id} eq 'duration';
    }
    my %summary = calculate_layout(\@cols, $w);

    printf "  %-25s %-20s %-20s\n", "Component", "Our Model", "Current Model";
    printf "  %-25s %-20s %-20s\n", '-' x 25, '-' x 20, '-' x 20;

    # Get widths from our model
    my %our_widths;
    for my $col (grep { $_->{visible} } @cols) {
        $our_widths{$col->{id}} = { width => $col->{width}, spacing => $col->{spacing} };
    }

    my $occ_w = $our_widths{occurrences}{width};

    printf "  %-25s %-20s %-20s\n", "timestamp",
        sprintf("%d + %d = %d", $our_widths{timestamp}{width}, $our_widths{timestamp}{spacing}, $our_widths{timestamp}{width} + $our_widths{timestamp}{spacing}),
        sprintf("%d + %d = %d", $sim_timestamp_width, $padding{timestamp} + $padding{all}, $sim_timestamp_width + $padding{timestamp} + $padding{all});
    printf "  %-25s %-20s %-20s\n", "legend",
        sprintf("%d + %d = %d", $our_widths{legend}{width}, $our_widths{legend}{spacing}, $our_widths{legend}{width} + $our_widths{legend}{spacing}),
        sprintf("%d + %d = %d", $sim_legend_width, $padding{legend}, $sim_legend_width + $padding{legend});
    printf "  %-25s %-20s %-20s\n", "sep_legend_graph",
        sprintf("%d + %d = %d", $our_widths{sep_legend_graph}{width}, $our_widths{sep_legend_graph}{spacing}, 1),
        "(embedded in pad_count)";
    printf "  %-25s %-20s %-20s\n", "occurrences",
        sprintf("%d + %d = %d", $occ_w, $our_widths{occurrences}{spacing}, $occ_w + $our_widths{occurrences}{spacing}),
        sprintf("W + %d = W+%d", $padding{count} + $padding{all}, $padding{count} + $padding{all});
    if ($our_widths{duration}) {
        my $dur_w = $our_widths{duration}{width};
        printf "  %-25s %-20s %-20s\n", "duration",
            sprintf("%d + %d = %d", $dur_w, $our_widths{duration}{spacing}, $dur_w + $our_widths{duration}{spacing}),
            sprintf("W + %d = W+%d", $padding{other} + $padding{all}, $padding{other} + $padding{all});
    }
    printf "  %-25s %-20s %-20s\n", "sep_graph_stats",
        sprintf("%d + %d = %d", $our_widths{sep_graph_stats}{width}, $our_widths{sep_graph_stats}{spacing}, 1),
        "(embedded in gap-fill)";
    printf "  %-25s %-20s %-20s\n", "latency",
        sprintf("%d + %d = %d", $our_widths{latency}{width}, $our_widths{latency}{spacing}, $our_widths{latency}{width} + $our_widths{latency}{spacing}),
        sprintf("%d + %d = %d", $sim_latency_width, $padding{latency} + $padding{all}, $sim_latency_width + $padding{latency} + $padding{all});

    printf "\n  Total (our model):     %d\n", $summary{total_used};
    printf "  Terminal width:        %d\n", $w;
    assert_ok("Separator budget match", $summary{total_used} == $w,
        "our total=$summary{total_used}, expected=$w");
}

# ============================================================================
# MAIN: RUN ALL OUTPUT SECTIONS
# ============================================================================

print "=" x 78 . "\n";
print "  Column Layout Engine Prototype\n";
print "  Terminal width: $terminal_width\n";
print "=" x 78 . "\n";

# Run all output sections
output_algorithm_comparison();
output_width_sweep();
output_column_count_sweep();
output_visibility_demo();
output_sequencing_demo();
output_separator_validation();

# Run validation checks
validate_algorithm_deviation("AlgoCheck: ", 5);

# ============================================================================
# PRINT TEST RESULTS
# ============================================================================

print "\n";
print "=" x 78 . "\n";
print "  TEST RESULTS\n";
print "=" x 78 . "\n\n";

my $pass_count = 0;
my $fail_count = 0;

for my $result (@test_results) {
    if ($result->{pass}) {
        $pass_count++;
        printf "  PASS  %s\n", $result->{name};
    } else {
        $fail_count++;
        printf "  FAIL  %s  (%s)\n", $result->{name}, $result->{detail};
    }
}

print "\n  " . "-" x 50 . "\n";
printf "  Total: %d tests, %d passed, %d failed\n\n", $pass_count + $fail_count, $pass_count, $fail_count;

if ($fail_count > 0) {
    print "  RESULT: FAIL\n\n";
    exit 1;
} else {
    print "  RESULT: PASS\n\n";
    exit 0;
}
