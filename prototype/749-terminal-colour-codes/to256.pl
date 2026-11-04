#!/usr/bin/env perl
# to256.pl: rewrites ltl's captured output as it would read if every colour
# were a fixed 256-colour code. Each colour of the sixteen (written as a basic
# code 30-37/90-97, 40-47/100-107, or as palette index 0-15 through 38;5/48;5)
# becomes the index 16-255 nearest to xterm's default for that colour, the
# colour a terminal shows when no scheme repaints it. The non-standard 109 is
# dropped. Attributes (bold, faint, underline, reverse) are kept as written.
#
#   perl to256.pl < ltl-output.ans > ltl-output-256.ans
#   perl to256.pl --table          # prints the mapping
use strict;
use warnings;

# xterm's defaults for the sixteen, as ltl's @notice_xterm16.
my @xterm16 = (
    [0, 0, 0], [205, 0, 0], [0, 205, 0], [205, 205, 0], [0, 0, 238], [205, 0, 205], [0, 205, 205], [229, 229, 229],
    [127, 127, 127], [255, 0, 0], [0, 255, 0], [255, 255, 0], [92, 92, 255], [255, 0, 255], [0, 255, 255], [255, 255, 255],
);
sub rgb_of_index {
    my ($n) = @_;
    if ($n >= 232) { my $g = 8 + 10 * ($n - 232); return [$g, $g, $g] }
    $n -= 16;
    my @lv = (0, 95, 135, 175, 215, 255);
    return [ $lv[ int($n / 36) ], $lv[ int($n / 6) % 6 ], $lv[ $n % 6 ] ];
}
my @fixed;
for my $i (0 .. 15) {
    my ($best, $bd);
    for my $n (16 .. 255) {
        my $c = rgb_of_index($n);
        my $d = 0;
        $d += ($c->[$_] - $xterm16[$i][$_])**2 for 0 .. 2;
        ($best, $bd) = ($n, $d) if !defined $bd || $d < $bd;
    }
    $fixed[$i] = $best;
}
if (@ARGV && $ARGV[0] eq '--table') {
    printf "%2d  xterm %-13s -> 38;5;%-3d %s\n", $_, join(',', @{ $xterm16[$_] }), $fixed[$_], join(',', @{ rgb_of_index($fixed[$_]) }) for 0 .. 15;
    exit 0;
}

sub rewrite {
    my @p = split /;/, $_[0], -1;
    @p = (0) unless @p;
    my @out;
    while (@p) {
        my $v = shift @p;
        $v = 0 if $v eq '';
        if    ($v >= 30 && $v <= 37)   { push @out, "38;5;$fixed[$v - 30]" }
        elsif ($v >= 90 && $v <= 97)   { push @out, "38;5;$fixed[$v - 90 + 8]" }
        elsif ($v >= 40 && $v <= 47)   { push @out, "48;5;$fixed[$v - 40]" }
        elsif ($v >= 100 && $v <= 107) { push @out, "48;5;$fixed[$v - 100 + 8]" }
        elsif (($v == 38 || $v == 48) && @p >= 2 && $p[0] == 5) {
            my (undef, $n) = splice @p, 0, 2;
            push @out, "$v;5;" . ($n < 16 ? $fixed[$n] : $n);
        }
        elsif (($v == 38 || $v == 48) && @p >= 4 && $p[0] == 2) { push @out, join ';', $v, splice @p, 0, 4 }
        elsif ($v == 109) { }
        else { push @out, $v }
    }
    return join ';', @out;
}
while (my $line = <STDIN>) {
    # a sequence left with nothing (109 alone) is removed: written empty it
    # would be a reset
    $line =~ s/\e\[([0-9;]*)m/my $r = rewrite($1); length $r ? "\e[${r}m" : ''/ge;
    print $line;
}
