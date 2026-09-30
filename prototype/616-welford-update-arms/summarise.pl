#!/usr/bin/env perl
# #616 D12: summarise the interleaved rounds run-arms.sh recorded.
#
# For each selection and candidate: median and range of timing_total over the
# rounds, the median against the base median, and the per-round delta's median
# and range (each round's candidate against that round's base, which removes
# the drift the rounds share). The base's own spread is the noise band.
#
#   usage: summarise.pl <runs tsv> [<runs tsv>...]
use strict;
use warnings;
use List::Util qw(min max);

my @order = split ' ', ($ENV{CANDIDATES} // 'base b c hoist b-hoist c-hoist');
my (%t, %m);
for my $tsv (@ARGV) {
    open my $fh, '<', $tsv or die "$tsv: $!";
    <$fh>;
    while (<$fh>) {
        chomp;
        my ($round, $cand, $sel, $timing, $rss) = split /\t/;
        next unless defined $timing && $timing ne '';
        $t{$sel}{$cand}{$round} = $timing;
        $m{$sel}{$cand}{$round} = $rss;
    }
    close $fh;
}
sub median { my @v = sort { $a <=> $b } @_; return undef unless @v; my $n = @v; $n % 2 ? $v[($n-1)/2] : ($v[$n/2-1] + $v[$n/2]) / 2 }
sub fmt { defined $_[0] ? sprintf('%.3f', $_[0]) : '-' }
sub pct { my ($v, $b) = @_; return '-' unless defined $v && $b; sprintf('%+.2f%%', 100 * ($v - $b) / $b) }

for my $sel (sort keys %t) {
    my $base = $t{$sel}{base} or next;
    my $bmed = median(values %$base);
    printf "## %s (base median %s s, range %s to %s, n=%d)\n\n", $sel, fmt($bmed), fmt(min values %$base), fmt(max values %$base), scalar keys %$base;
    print "| candidate | n | median s | range s | vs base median | per-round delta median (range) s | per-round delta median % | rss median MB |\n|---|---|---|---|---|---|---|---|\n";
    for my $c (grep { exists $t{$sel}{$_} } @order) {
        my $r = $t{$sel}{$c};
        my @v = values %$r;
        my @d = map { exists $base->{$_} ? $r->{$_} - $base->{$_} : () } sort { $a <=> $b } keys %$r;
        printf "| %s | %d | %s | %s to %s | %s | %s (%s to %s) | %s | %.1f |\n", $c, scalar @v, fmt(median(@v)), fmt(min @v), fmt(max @v),
            pct(median(@v), $bmed), fmt(median(@d)), fmt(min @d), fmt(max @d), pct($bmed + median(@d), $bmed),
            median(values %{ $m{$sel}{$c} }) / 1048576;
    }
    print "\n";
}
