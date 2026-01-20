#!/usr/bin/perl
#
# Mini Heatmap Demo - Compact output for quick viewing
#
# HEATMAP MODEL:
#   - X-axis (position): Latency value (left=fast, right=slow)
#   - Color intensity: Request count/density (dark=few, bright=many)
#

use strict;
use warnings;
use utf8;
binmode(STDOUT, ":utf8");

my $ESC = "\033";
my $RESET = "${ESC}[0m";
my $BOLD = "${ESC}[1m";

my %blocks = (
    'light'  => '░',
    'medium' => '▒',
    'dark'   => '▓',
    'full'   => '█',
);

# Color gradients: dark (few requests) → bright (many requests)
my @yellow = (233, 234, 58, 94, 136, 142, 178, 184, 220, 226);  # Duration
my @green  = (233, 234, 22, 28, 34, 40, 46, 82, 118, 154);      # Bytes
my @cyan   = (233, 234, 23, 29, 30, 36, 37, 43, 44, 51);        # Count

sub fg { my ($c) = @_; return "${ESC}[38;5;${c}m"; }
sub bg { my ($c) = @_; return "${ESC}[48;5;${c}m"; }

# Realistic latency distribution data (request COUNTS at each latency bucket)
# Left = fast (many requests), Right = slow (few requests)
# Values represent density/count of requests at that latency level
my @data = (
    # bucket: 0ms   50   100  150  200  300  400  500  700  1s   1.5s  2s   3s   4s   5s
    1.0, 0.95, 0.85, 0.7, 0.5, 0.35, 0.25, 0.18, 0.12, 0.08, 0.05, 0.03, 0.02, 0.01, 0.01,  # Fast cluster
    0.0, 0.0,  0.0,  0.0, 0.1, 0.2,  0.35, 0.3,  0.15, 0.05, 0.02, 0.0,  0.0,  0.0,  0.0,   # DB mode ~400ms
    0.0, 0.0,  0.0,  0.0, 0.0, 0.0,  0.0,  0.0,  0.0,  0.05, 0.12, 0.08, 0.03, 0.01, 0.0,   # API mode ~1.5s
);

# Combine into single row (simulating one time bucket)
my @combined;
for my $i (0..14) {
    my $val = $data[$i] + $data[$i+15] + $data[$i+30];
    $val = 1.0 if $val > 1.0;
    push @combined, $val;
}

print "\n";
print "═" x 65 . "\n";
print "${BOLD}  HEATMAP RENDERING APPROACHES${RESET}\n";
print "═" x 65 . "\n";
print "\n  ${BOLD}Model:${RESET} Position = latency (left=fast, right=slow)\n";
print "         Color = request density (dark=few, bright=many)\n\n";

print "  Latency:  0ms        500ms       1s         2s        5s\n";
print "            │──────────│───────────│──────────│─────────│\n";

# Approach 1: Shade + Color
print "\n${BOLD}1. Shade + Color${RESET} (░▒▓█ + color gradient)\n";
print "   ";
for my $val (@combined) {
    my $idx = int($val * $#yellow);
    my $char = $val < 0.05 ? ' ' : $val < 0.2 ? $blocks{'light'} : $val < 0.45 ? $blocks{'medium'} : $val < 0.7 ? $blocks{'dark'} : $blocks{'full'};
    print $val < 0.02 ? ' ' : fg($yellow[$idx]) . $char . $RESET;
}
print "\n";

# Approach 2: Color-only full blocks
print "\n${BOLD}2. Color Only${RESET} (█ with intensity)\n";
print "   ";
for my $val (@combined) {
    my $idx = int($val * $#yellow);
    print $val < 0.02 ? ' ' : fg($yellow[$idx]) . $blocks{'full'} . $RESET;
}
print "\n";

# Approach 3: Hybrid (3 shades)
print "\n${BOLD}3. Hybrid${RESET} (░▓█ + color)\n";
print "   ";
for my $val (@combined) {
    my $idx = int($val * $#yellow);
    my $char = $val < 0.02 ? ' ' : $val < 0.3 ? $blocks{'light'} : $val < 0.65 ? $blocks{'dark'} : $blocks{'full'};
    print $val < 0.02 ? ' ' : fg($yellow[$idx]) . $char . $RESET;
}
print "\n";

# Approach 4: Background color
print "\n${BOLD}4. Background Color${RESET} (space with bg)\n";
print "   ";
for my $val (@combined) {
    my $idx = int($val * $#yellow);
    print $val < 0.02 ? ' ' : bg($yellow[$idx]) . ' ' . $RESET;
}
print "\n";

# Density legend
print "\n  Density:  ";
print fg($yellow[0]) . "█" . $RESET . " few ";
for my $i (1..$#yellow-1) { print fg($yellow[$i]) . "█" . $RESET; }
print " " . fg($yellow[$#yellow]) . "█" . $RESET . " many requests\n";

# Color schemes
print "\n";
print "═" x 65 . "\n";
print "${BOLD}  COLOR SCHEMES BY METRIC${RESET}\n";
print "═" x 65 . "\n\n";

print "   Duration (yellow):  ";
for my $c (@yellow) { print fg($c) . $blocks{'full'} . $RESET; }
print "  few→many\n";

print "   Bytes (green):      ";
for my $c (@green) { print fg($c) . $blocks{'full'} . $RESET; }
print "  few→many\n";

print "   Count (cyan):       ";
for my $c (@cyan) { print fg($c) . $blocks{'full'} . $RESET; }
print "  few→many\n";

# Highlight demo - uses bright background to make foreground pop
print "\n";
print "═" x 65 . "\n";
print "${BOLD}  HIGHLIGHT OVERLAY DEMO${RESET}\n";
print "═" x 65 . "\n";
print "  Bright background makes highlighted cells pop (retains density color)\n\n";

my $hl_bg_yellow = 226;  # bright yellow background
my $hl_bg_cyan = 51;     # bright cyan background
my $hl_bg_magenta = 201; # bright magenta background
my $hl_bg_white = 231;   # white background

# Create multiple highlight scenarios for comparison
my @scenarios = (
    {
        name => "All traffic (no filter)",
        desc => "baseline",
        filter => sub { return 0; }  # no highlights
    },
    {
        name => "Slow requests (>300ms)",
        desc => "positions 5-14",
        filter => sub { my ($i, $v) = @_; return ($i >= 5 && $v > 0.03); },
        bg => $hl_bg_yellow
    },
    {
        name => "Fast requests (<100ms)",
        desc => "positions 0-3",
        filter => sub { my ($i, $v) = @_; return ($i <= 3 && $v > 0.03); },
        bg => $hl_bg_cyan
    },
    {
        name => "DB queries (~400ms)",
        desc => "positions 6-9",
        filter => sub { my ($i, $v) = @_; return ($i >= 6 && $i <= 9 && $v > 0.05); },
        bg => $hl_bg_magenta
    },
    {
        name => "API timeout zone (>1s)",
        desc => "positions 10-14",
        filter => sub { my ($i, $v) = @_; return ($i >= 10 && $v > 0.01); },
        bg => $hl_bg_white
    },
);

print "  Latency:  0ms        500ms       1s         2s        5s\n";
print "            │──────────│───────────│──────────│─────────│\n\n";

for my $scenario (@scenarios) {
    my $label = sprintf("  %-26s", $scenario->{name});
    print $label;

    for my $i (0..$#combined) {
        my $val = $combined[$i];
        my $idx = int($val * $#yellow);
        my $is_hl = $scenario->{filter}->($i, $val);

        if ($val < 0.02) {
            print ' ';
        } elsif ($is_hl && exists $scenario->{bg}) {
            print bg($scenario->{bg}) . fg($yellow[$idx]) . $blocks{'full'} . $RESET;
        } else {
            print fg($yellow[$idx]) . $blocks{'full'} . $RESET;
        }
    }
    print "  ($scenario->{desc})\n";
}

print "\n  Legend:\n";
print "    " . fg($yellow[9]) . "█" . $RESET . " = Normal (bright = many requests)\n";
print "    " . bg($hl_bg_yellow) . fg($yellow[5]) . "█" . $RESET . " = Highlighted (yellow bg) - slow requests\n";
print "    " . bg($hl_bg_cyan) . fg($yellow[9]) . "█" . $RESET . " = Highlighted (cyan bg) - fast requests\n";
print "    " . bg($hl_bg_magenta) . fg($yellow[6]) . "█" . $RESET . " = Highlighted (magenta bg) - DB queries\n";
print "    " . bg($hl_bg_white) . fg($yellow[3]) . "█" . $RESET . " = Highlighted (white bg) - API timeouts\n";

# Additional comparison: Multiple time rows with highlight
print "\n";
print "═" x 65 . "\n";
print "${BOLD}  MULTI-FILTER HIGHLIGHT COMPARISON${RESET}\n";
print "═" x 65 . "\n";
print "  Different filters highlight different density regions\n\n";

# Generate more varied data for multiple rows
my @row_data = (
    # Row 1: Heavy fast traffic, light slow traffic (normal healthy traffic)
    [1.0, 0.95, 0.85, 0.7, 0.5, 0.35, 0.25, 0.18, 0.12, 0.08, 0.05, 0.03, 0.02, 0.01, 0.01],
    # Row 2: Bimodal - fast and DB queries
    [0.9, 0.8, 0.6, 0.3, 0.15, 0.3, 0.5, 0.45, 0.25, 0.1, 0.03, 0.02, 0.01, 0.0, 0.0],
    # Row 3: More DB traffic, less fast traffic
    [0.6, 0.5, 0.4, 0.25, 0.2, 0.4, 0.6, 0.55, 0.35, 0.15, 0.05, 0.03, 0.02, 0.01, 0.0],
    # Row 4: Spike in API calls
    [0.7, 0.6, 0.45, 0.3, 0.2, 0.25, 0.35, 0.3, 0.25, 0.35, 0.45, 0.35, 0.2, 0.1, 0.05],
    # Row 5: Heavy slow traffic (incident)
    [0.5, 0.4, 0.35, 0.3, 0.3, 0.35, 0.45, 0.5, 0.55, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1],
    # Row 6: Recovery - back to normal
    [0.85, 0.8, 0.7, 0.55, 0.35, 0.3, 0.25, 0.2, 0.15, 0.1, 0.06, 0.03, 0.02, 0.01, 0.0],
);

my @time_labels = ("08:00", "08:15", "08:30", "08:45", "09:00", "09:15");

print "  Latency:       0ms        500ms       1s         2s        5s\n";
print "                 │──────────│───────────│──────────│─────────│\n\n";

# Show one row with multiple filter types
my @sample_row = @{$row_data[0]};  # Use the healthy traffic row

print "  ${BOLD}Healthy traffic (08:00) with different highlight filters:${RESET}\n\n";

# Normal (no filter)
print "  No filter:     ";
for my $i (0..$#sample_row) {
    my $val = $sample_row[$i];
    my $idx = int($val * $#yellow);
    print $val < 0.02 ? ' ' : fg($yellow[$idx]) . $blocks{'full'} . $RESET;
}
print "  (baseline)\n";

# Fast filter (positions 0-5, HIGH density bright yellow)
print "  Fast (<200ms): ";
for my $i (0..$#sample_row) {
    my $val = $sample_row[$i];
    my $idx = int($val * $#yellow);
    my $is_hl = ($i <= 5 && $val > 0.1);
    if ($val < 0.02) { print ' '; }
    elsif ($is_hl) { print bg($hl_bg_cyan) . fg($yellow[$idx]) . $blocks{'full'} . $RESET; }
    else { print fg($yellow[$idx]) . $blocks{'full'} . $RESET; }
}
print "  (cyan bg on BRIGHT)\n";

# DB filter (positions 4-9, MEDIUM density)
print "  DB (~400ms):   ";
for my $i (0..$#sample_row) {
    my $val = $sample_row[$i];
    my $idx = int($val * $#yellow);
    my $is_hl = ($i >= 4 && $i <= 9 && $val > 0.05);
    if ($val < 0.02) { print ' '; }
    elsif ($is_hl) { print bg($hl_bg_magenta) . fg($yellow[$idx]) . $blocks{'full'} . $RESET; }
    else { print fg($yellow[$idx]) . $blocks{'full'} . $RESET; }
}
print "  (magenta bg on MEDIUM)\n";

# Slow filter (positions 8+, LOW density)
print "  Slow (>700ms): ";
for my $i (0..$#sample_row) {
    my $val = $sample_row[$i];
    my $idx = int($val * $#yellow);
    my $is_hl = ($i >= 8 && $val > 0.01);
    if ($val < 0.02) { print ' '; }
    elsif ($is_hl) { print bg($hl_bg_white) . fg($yellow[$idx]) . $blocks{'full'} . $RESET; }
    else { print fg($yellow[$idx]) . $blocks{'full'} . $RESET; }
}
print "  (white bg on DIM)\n";

print "\n  Key: Highlights appear on bright yellow (many requests) AND dim (few).\n";

# Now show time progression with fast filter (highlight bright areas)
print "\n  ${BOLD}Time progression with 'fast requests' filter (highlight bright areas):${RESET}\n\n";

for my $r (0..$#row_data) {
    my @row = @{$row_data[$r]};

    # Print normal
    print "  $time_labels[$r]  normal: ";
    for my $i (0..$#row) {
        my $val = $row[$i];
        my $idx = int($val * $#yellow);
        print $val < 0.02 ? ' ' : fg($yellow[$idx]) . $blocks{'full'} . $RESET;
    }
    print "\n";

    # Print with FAST highlight (positions 0-6, bright yellow areas)
    print "          fast:  ";
    for my $i (0..$#row) {
        my $val = $row[$i];
        my $idx = int($val * $#yellow);
        my $is_hl = ($i <= 6 && $val > 0.1);

        if ($val < 0.02) { print ' '; }
        elsif ($is_hl) { print bg($hl_bg_cyan) . fg($yellow[$idx]) . $blocks{'full'} . $RESET; }
        else { print fg($yellow[$idx]) . $blocks{'full'} . $RESET; }
    }
    print "\n\n";
}

print "  Observations:\n";
print "  • 08:00 - Healthy: Most traffic is fast (heavily highlighted)\n";
print "  • 08:30 - Bimodal: Fast AND slow traffic present\n";
print "  • 09:00 - Incident: Fast traffic drops (less highlighting)\n";
print "  • 09:15 - Recovery: Fast traffic returns (highlighting resumes)\n";

# Side-by-side comparison of different highlight background colors
print "\n";
print "═" x 65 . "\n";
print "${BOLD}  HIGHLIGHT BACKGROUND COLOR OPTIONS${RESET}\n";
print "═" x 65 . "\n";
print "  Comparing background colors on BRIGHT foreground (fast requests)\n\n";

my @bg_options = (
    { name => "Yellow bg (226)", bg => 226 },
    { name => "White bg (231)",  bg => 231 },
    { name => "Cyan bg (51)",    bg => 51 },
    { name => "Magenta bg (201)", bg => 201 },
    { name => "Orange bg (208)", bg => 208 },
    { name => "Green bg (46)",   bg => 46 },
);

# Use healthy traffic row - shows bright yellows
my @healthy_row = @{$row_data[0]};

print "  ${BOLD}Fast requests (bright yellow foreground):${RESET}\n";
for my $opt (@bg_options) {
    my $label = sprintf("  %-18s", $opt->{name});
    print $label;

    for my $i (0..$#healthy_row) {
        my $val = $healthy_row[$i];
        my $idx = int($val * $#yellow);
        my $is_hl = ($i <= 6 && $val > 0.1);  # Fast requests

        if ($val < 0.02) {
            print ' ';
        } elsif ($is_hl) {
            print bg($opt->{bg}) . fg($yellow[$idx]) . $blocks{'full'} . $RESET;
        } else {
            print fg($yellow[$idx]) . $blocks{'full'} . $RESET;
        }
    }
    print "\n";
}

# Use incident row - shows medium/dim colors
my @incident_row = @{$row_data[4]};

print "\n  ${BOLD}Slow requests (dim brown/olive foreground):${RESET}\n";
for my $opt (@bg_options) {
    my $label = sprintf("  %-18s", $opt->{name});
    print $label;

    for my $i (0..$#incident_row) {
        my $val = $incident_row[$i];
        my $idx = int($val * $#yellow);
        my $is_hl = ($i >= 7 && $val > 0.1);  # Slow requests

        if ($val < 0.02) {
            print ' ';
        } elsif ($is_hl) {
            print bg($opt->{bg}) . fg($yellow[$idx]) . $blocks{'full'} . $RESET;
        } else {
            print fg($yellow[$idx]) . $blocks{'full'} . $RESET;
        }
    }
    print "\n";
}

print "\n  Note: Cyan/Magenta contrast well with bright; White works for dim.\n";

print "\n";
print "═" x 65 . "\n";
print "${BOLD}  INTERPRETATION${RESET}\n";
print "═" x 65 . "\n";
print <<'NOTES';

  What the heatmap shows:
  - LEFT (bright): Fast requests (0-200ms) - most traffic lives here
  - MIDDLE (dimmer): DB-bound requests (~400ms)
  - RIGHT (sparse): Slow API calls, timeouts (>1s)

  The color tells you HOW MANY requests, not how slow they are.
  The position tells you how slow they are.

NOTES

print "\n";
