#!/usr/bin/env perl
# Gradient comparison prototype for heatmap color improvements
# Run: perl prototype/gradient-comparison.pl

use strict;
use warnings;
use utf8;
binmode(STDOUT, ':utf8');

sub fg { return "\e[38;5;$_[0]m"; }
sub rst { return "\e[0m"; }

my $block = "█";

# Proposed 10-level gradients - no grays, all in-family colors (DARK BG)
my %proposed_10 = (
    'yellow'  => [58, 94, 100, 136, 142, 178, 184, 214, 220, 226],
    'green'   => [22, 28, 34, 40, 46, 82, 83, 118, 119, 154],
    'cyan'    => [23, 29, 30, 36, 37, 43, 44, 50, 51, 87],
    'blue'    => [17, 18, 19, 20, 21, 26, 27, 32, 33, 39],
    'magenta' => [53, 89, 125, 126, 161, 162, 163, 198, 199, 200],
    'red'     => [52, 88, 124, 160, 161, 196, 197, 203, 204, 209],
    'white'   => [236, 238, 240, 242, 244, 246, 248, 250, 252, 255],
);

# Proposed 8-level gradients - DARK BG
my %proposed_8_dark = (
    'yellow'  => [58, 94, 136, 142, 178, 184, 220, 226],
    'green'   => [22, 28, 34, 40, 46, 82, 118, 154],
    'cyan'    => [23, 30, 37, 44, 51, 80, 86, 123],
    'blue'    => [17, 18, 19, 20, 21, 27, 33, 39],
    'magenta' => [53, 89, 125, 161, 162, 163, 199, 200],
    'red'     => [52, 88, 124, 160, 196, 197, 203, 209],
    'white'   => [238, 240, 242, 244, 246, 248, 252, 255],
);

# Proposed 8-level gradients - LIGHT BG (pale to saturated)
my %proposed_8_light = (
    'yellow'  => [230, 229, 228, 227, 220, 214, 208, 202],
    'green'   => [194, 157, 120, 84, 48, 42, 36, 35],
    'cyan'    => [195, 159, 123, 87, 51, 44, 37, 30],
    'blue'    => [189, 153, 117, 81, 45, 39, 33, 27],
    'magenta' => [225, 219, 213, 207, 201, 165, 129, 93],
    'red'     => [224, 218, 212, 206, 200, 196, 160, 124],
    'white'   => [255, 254, 253, 250, 247, 244, 241, 238],
);

# Proposed 10-level gradients - LIGHT BG (pale to saturated)
my %proposed_10_light = (
    'yellow'  => [230, 229, 228, 227, 226, 220, 214, 208, 202, 196],
    'green'   => [194, 157, 156, 120, 84, 48, 47, 42, 36, 35],
    'cyan'    => [195, 159, 158, 123, 87, 51, 50, 44, 37, 30],
    'blue'    => [189, 153, 152, 117, 81, 45, 44, 39, 33, 27],
    'magenta' => [225, 219, 218, 213, 207, 201, 200, 165, 129, 93],
    'red'     => [224, 218, 217, 212, 206, 200, 199, 196, 160, 124],
    'white'   => [255, 254, 253, 252, 250, 247, 244, 241, 238, 235],
);

print "=" x 100, "\n";
print "HEATMAP GRADIENT COMPARISON: 10-level vs 8-level\n";
print "=" x 100, "\n\n";

print "PROPOSED 10-LEVEL DARK BG:                           PROPOSED 10-LEVEL LIGHT BG:\n";
print "─" x 100, "\n\n";

foreach my $color (qw(yellow green cyan blue magenta red white)) {
    printf "%-9s", uc($color);
    foreach my $c (@{$proposed_10{$color}}) {
        print fg($c), $block x 2, rst();
    }
    print "      ";
    printf "%-9s", uc($color);
    foreach my $c (@{$proposed_10_light{$color}}) {
        print fg($c), $block x 2, rst();
    }
    print "\n";
}
print "\n";

print "PROPOSED 8-LEVEL DARK BG:                         PROPOSED 8-LEVEL LIGHT BG:\n";
print "─" x 100, "\n\n";

foreach my $color (qw(yellow green cyan blue magenta red white)) {
    printf "%-9s", uc($color);
    foreach my $c (@{$proposed_8_dark{$color}}) {
        print fg($c), $block x 2, rst();
    }
    print "          ";
    printf "%-9s", uc($color);
    foreach my $c (@{$proposed_8_light{$color}}) {
        print fg($c), $block x 2, rst();
    }
    print "\n";
}
print "\n";
