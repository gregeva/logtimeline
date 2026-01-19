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

my $hl_bg = 226;  # bright yellow background for duration metric

print "   Normal:      ";
for my $i (0..$#combined) {
    my $val = $combined[$i];
    my $idx = int($val * $#yellow);
    print $val < 0.02 ? ' ' : fg($yellow[$idx]) . $blocks{'full'} . $RESET;
}
print "\n";

print "   Highlighted: ";
for my $i (0..$#combined) {
    my $val = $combined[$i];
    my $idx = int($val * $#yellow);
    # Highlight the slow requests (middle-right area = DB/API calls)
    my $is_hl = ($i >= 5 && $i <= 10);
    if ($val < 0.02) {
        print ' ';
    } elsif ($is_hl && $val > 0.05) {
        # Bright background with foreground density color
        print bg($hl_bg) . fg($yellow[$idx]) . $blocks{'full'} . $RESET;
    } else {
        print fg($yellow[$idx]) . $blocks{'full'} . $RESET;
    }
}
print "\n";

print "\n   Legend: " . bg($hl_bg) . fg(0) . "█" . $RESET . " = Highlighted (bright bg, keeps density color)\n";

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
