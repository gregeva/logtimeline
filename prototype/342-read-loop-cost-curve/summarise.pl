#!/usr/bin/env perl
# #342 item 8: summarise the interleaved rounds run-curve.sh recorded.
#
# For each file and candidate: median and range of timing_total over the rounds,
# the delta of the median against the base median on the same file, and the
# per-round delta's median and range (each round's candidate against that
# round's base, which removes the drift the rounds share). For the gate, str
# and hash series: a least-squares slope of the median over N in {0,10,20,40}
# (N = 0 is the base), in seconds per test and in percent of the base per test.
#
#   usage: summarise.pl <runs tsv> [<runs tsv>...]
use strict;
use warnings;
use List::Util qw(sum min max);

my %t;   # file -> candidate -> round -> timing
my %m;   # file -> candidate -> round -> rss
for my $tsv (@ARGV) {
    open my $fh, '<', $tsv or die "$tsv: $!";
    my $hdr = <$fh>;
    while (<$fh>) {
        chomp;
        my ($round, $cand, $file, $timing, $rss) = split /\t/;
        next unless defined $timing && $timing ne '';
        $t{$file}{$cand}{$round} = $timing;
        $m{$file}{$cand}{$round} = $rss;
    }
    close $fh;
}
sub median { my @v = sort { $a <=> $b } @_; return undef unless @v; my $n = @v; return $n % 2 ? $v[($n-1)/2] : ($v[$n/2-1] + $v[$n/2]) / 2 }
sub fmt { defined $_[0] ? sprintf('%.3f', $_[0]) : '-' }
sub pct { my ($v, $b) = @_; return '-' unless defined $v && $b; sprintf('%+.2f%%', 100 * ($v - $b) / $b) }

my @order = qw(base gate-10 gate-20 gate-40 str-10 str-20 str-40 hash-10 hash-20 hash-40 hoist);
for my $file (sort keys %t) {
    my $base = $t{$file}{base} or next;
    my $bmed = median(values %$base);
    print "## $file (base median ", fmt($bmed), " s, n=", scalar(keys %$base), ")\n\n";
    print "| candidate | n | median s | range s | vs base median | per-round delta median (range) | rss median MB |\n|---|---|---|---|---|---|---|\n";
    for my $c (grep { exists $t{$file}{$_} } @order) {
        my $r = $t{$file}{$c};
        my @v = values %$r;
        my @d = map { exists $base->{$_} ? $r->{$_} - $base->{$_} : () } sort { $a <=> $b } keys %$r;
        my $rssmed = median(values %{ $m{$file}{$c} });
        printf "| %s | %d | %s | %s to %s | %s | %s (%s to %s) | %.1f |\n", $c, scalar @v, fmt(median(@v)), fmt(min @v), fmt(max @v),
            pct(median(@v), $bmed), fmt(median(@d)), fmt(min @d), fmt(max @d), $rssmed / 1048576;
    }
    print "\n";
    for my $series (qw(gate str hash)) {
        my @pts = ([0, $bmed], map { [$_, median(values %{ $t{$file}{"$series-$_"} })] } grep { exists $t{$file}{"$series-$_"} } (10, 20, 40));
        next unless @pts >= 3;
        my $n = @pts;
        my $sx = sum(map { $_->[0] } @pts); my $sy = sum(map { $_->[1] } @pts);
        my $sxx = sum(map { $_->[0] ** 2 } @pts); my $sxy = sum(map { $_->[0] * $_->[1] } @pts);
        my $slope = ($n * $sxy - $sx * $sy) / ($n * $sxx - $sx ** 2);
        my $intercept = ($sy - $slope * $sx) / $n;
        my @resid = map { $_->[1] - ($intercept + $slope * $_->[0]) } @pts;
        printf "slope %s: %.5f s per test (%.3f%% of base per test); intercept %.3f s; residuals %s\n",
            $series, $slope, 100 * $slope / $bmed, $intercept, join(', ', map { sprintf('%+.3f', $_) } @resid);
    }
    print "\n";
}
