#!/usr/bin/env perl
#
# 426-revalidate-v5-tables.pl — condense the V5 captures
# (prototype/426-results/revalidate-v5-summary.tsv and the per-comparison
# revalidate-v5-key-bpdNN.tsv files) into the tables the report quotes.
# Every number printed here is a re-aggregation of those files.
#
#   perl prototype/426-revalidate-v5-tables.pl [prototype/426-results/revalidate-v5]
#
use strict;
use warnings;
use List::Util qw(sum max);

my $prefix = $ARGV[0] // 'prototype/426-results/revalidate-v5';
my @Q = qw(P1 P50 P75 P90 P95 P99 P999);

# --- summary.tsv -> {bpd}{scope}{arm}{conv}{q} = {n,p50,p95,p99,max,within,bias,bound}
my %S; my @bpds;
open(my $fh, '<', "$prefix-summary.tsv") or die "no $prefix-summary.tsv: $!";
my $hdr = <$fh>;
while (<$fh>) {
    chomp; my @f = split /\t/;
    my ($file, $bpd, $bound, $scope, $arm, $conv, $q, $n, $p50, $p95, $p99, $max, $within, $bias) = @f;
    push @bpds, $bpd unless grep { $_ == $bpd } @bpds;
    $S{$bpd}{$scope}{$arm}{$conv}{$q} = { n => $n, p50 => $p50, p95 => $p95, p99 => $p99, max => $max, within => $within, bias => $bias, bound => $bound };
}
close $fh;
@bpds = sort { $a <=> $b } @bpds;
my $pc = sub { sprintf('%.2f%%', 100 * $_[0]) };
my $pc4 = sub { sprintf('%.4f%%', 100 * $_[0]) };

print "## A. [key] N>=100 — #189 V5 table shape, per arm (binning = oracle rank forced; raw = native ceil)\n\n";
print "| bpd | bound | arm | binning_max (range over 7 q) | binning_p50 (range) | raw_max (range) | max raw−binning gap at any q | pass |\n|---|---|---|---|---|---|---|---|\n";
for my $bpd (@bpds) {
    for my $arm (qw(T G)) {
        my $k = $S{$bpd}{key}{$arm} or next;
        my @bm = map { $k->{binning}{$_}{max} } @Q;
        my @bp = map { $k->{binning}{$_}{p50} } @Q;
        my @rm = map { $k->{raw}{$_}{max} } @Q;
        my $gap = max(map { $k->{raw}{$_}{max} - $k->{binning}{$_}{max} } @Q);
        my $bound = $k->{binning}{P50}{bound};
        my $pass = (grep { $_ > $bound + 1e-12 } @bm) ? 'FAIL' : 'PASS';
        printf "| %d | %s | %s | %s–%s | %s–%s | %s–%s | %s | %s |\n", $bpd, $pc->($bound), $arm,
            $pc->(min(@bm)), $pc->(max(@bm)), $pc->(min(@bp)), $pc->(max(@bp)), $pc->(min(@rm)), $pc->(max(@rm)),
            ($gap > 1e-6 ? '+' . $pc->($gap) : 'none'), $pass;
    }
}

print "\n## B. [key] N>=100 — per quantile, binning_max / raw_max, T vs G (rank-convention crossover)\n\n";
for my $bpd (@bpds) {
    my $bound = $S{$bpd}{key}{T}{binning}{P50}{bound};
    printf "### bpd=%d (bound %s)\n\n| Q | T binning_p50 | T binning_max | T raw_max | G binning_p50 | G binning_max | G raw_max | G bias (mean signed) | T bias |\n|---|---|---|---|---|---|---|---|---|\n", $bpd, $pc->($bound);
    for my $q (@Q) {
        my ($t, $g) = ($S{$bpd}{key}{T}, $S{$bpd}{key}{G});
        printf "| %s | %s | %s | %s | %s | %s | %s | %+.2f%% | %+.2f%% |\n", $q,
            $pc->($t->{binning}{$q}{p50}), $pc->($t->{binning}{$q}{max}), $pc->($t->{raw}{$q}{max}),
            $pc->($g->{binning}{$q}{p50}), $pc->($g->{binning}{$q}{max}), $pc->($g->{raw}{$q}{max}),
            100 * $g->{binning}{$q}{bias}, 100 * $t->{binning}{$q}{bias};
    }
    print "\n";
}

print "## C. [small] all keys N>=2 — binning convention: median / p95 / max, within one bin; raw within one bin\n\n";
for my $bpd (@bpds) {
    printf "### bpd=%d (bound %s, n=%d keys)\n\n| Q | T p50 / p95 / max | T within | G p50 / p95 / max | G within | T raw within | G raw within |\n|---|---|---|---|---|---|---|\n", $bpd, $pc->($S{$bpd}{small}{T}{binning}{P50}{bound}), $S{$bpd}{small}{T}{binning}{P50}{n};
    for my $q (@Q) {
        my ($t, $g) = ($S{$bpd}{small}{T}, $S{$bpd}{small}{G});
        printf "| %s | %s / %s / %s | %s | %s / %s / %s | %s | %s | %s |\n", $q,
            (map { $pc->($t->{binning}{$q}{$_}) } qw(p50 p95 max)), $pc->($t->{binning}{$q}{within}),
            (map { $pc->($g->{binning}{$q}{$_}) } qw(p50 p95 max)), $pc->($g->{binning}{$q}{within}),
            $pc->($t->{raw}{$q}{within}), $pc->($g->{raw}{$q}{within});
    }
    print "\n";
}

print "## D. [pair] merged pairs — binning convention\n\n";
for my $bpd (@bpds) {
    printf "### bpd=%d (bound %s, n=%d pairs)\n\n| Q | T p50 / p95 / max | T within | T max in bins | G p50 / p95 / max | G within | G max in bins |\n|---|---|---|---|---|---|---|\n", $bpd, $pc->($S{$bpd}{pair}{T}{binning}{P50}{bound}), $S{$bpd}{pair}{T}{binning}{P50}{n};
    for my $q (@Q) {
        my ($t, $g) = ($S{$bpd}{pair}{T}, $S{$bpd}{pair}{G});
        my $bound = $t->{binning}{$q}{bound};
        printf "| %s | %s / %s / %s | %s | %.2f | %s / %s / %s | %s | %.2f |\n", $q,
            (map { $pc->($t->{binning}{$q}{$_}) } qw(p50 p95 max)), $pc->($t->{binning}{$q}{within}), log(1 + $t->{binning}{$q}{max}) / log(1 + $bound),
            (map { $pc->($g->{binning}{$q}{$_}) } qw(p50 p95 max)), $pc->($g->{binning}{$q}{within}), log(1 + $g->{binning}{$q}{max}) / log(1 + $bound);
    }
    print "\n";
}

print "## E. [fold] groups of 8 — after 7 merges (step 7), binning convention; within-one-bin trajectory over steps 1..7\n\n";
for my $bpd (@bpds) {
    printf "### bpd=%d (bound %s, n=%d groups)\n\n| Q | T step7 p50 / p95 / max | T within step1→7 | G step7 p50 / p95 / max | G within step1→7 |\n|---|---|---|---|---|\n", $bpd, $pc->($S{$bpd}{fold7}{T}{binning}{P50}{bound}), $S{$bpd}{fold7}{T}{binning}{P50}{n};
    for my $q (@Q) {
        my ($t, $g) = ($S{$bpd}{fold7}{T}, $S{$bpd}{fold7}{G});
        my $tw = join(' ', map { sprintf('%.1f', 100 * $S{$bpd}{"fold$_"}{T}{binning}{$q}{within}) } 1 .. 7);
        my $gw = join(' ', map { sprintf('%.1f', 100 * $S{$bpd}{"fold$_"}{G}{binning}{$q}{within}) } 1 .. 7);
        printf "| %s | %s / %s / %s | %s | %s / %s / %s | %s |\n", $q,
            (map { $pc->($t->{binning}{$q}{$_}) } qw(p50 p95 max)), $tw,
            (map { $pc->($g->{binning}{$q}{$_}) } qw(p50 p95 max)), $gw;
    }
    print "\n";
}

# --- key TSVs: G's error split by whether the oracle value is an exact power of ten
print "## F. [key] N>=100 — binning error split by oracle value on a grid boundary (exact power of ten: 1, 10, 100, 1000 ms)\n\n";
print "| bpd | Q | keys with oracle = 10^k | G p50 err (10^k keys) | G p50 err (other keys) | T p50 err (10^k keys) | T p50 err (other keys) | G: 10^k keys within 0.1% of full bin |\n|---|---|---|---|---|---|---|---|\n";
for my $bpd (@bpds) {
    open(my $kh, '<', "$prefix-key-bpd$bpd.tsv") or next;
    my $h = <$kh>; chomp $h; my @cols = split /\t/, $h;
    my %ci; @ci{@cols} = 0 .. $#cols;
    my %E;
    while (<$kh>) {
        chomp; my @f = split /\t/;
        my $q = $f[$ci{quantile}]; my $orc = $f[$ci{oracle}];
        my $pow = ($orc =~ /^1(0*)$/ || $orc =~ /^1(0*)\.0*$/) ? 'pow' : 'other';
        push @{ $E{$q}{$pow}{G} }, abs($f[$ci{G_int_err}]);
        push @{ $E{$q}{$pow}{T} }, abs($f[$ci{T_int_err}]);
    }
    close $kh;
    my $bound = 10 ** (1 / $bpd) - 1;
    for my $q (@Q) {
        my $med = sub { my @s = sort { $a <=> $b } @{ $_[0] // [] }; @s ? $s[int(@s / 2)] : undef };
        my $gp = $med->($E{$q}{pow}{G}); my $go = $med->($E{$q}{other}{G});
        my $tp = $med->($E{$q}{pow}{T}); my $to = $med->($E{$q}{other}{T});
        my $np = scalar @{ $E{$q}{pow}{G} // [] };
        my $near = $np ? scalar(grep { $_ >= $bound - 0.001 } @{ $E{$q}{pow}{G} }) : 0;
        printf "| %d | %s | %d of %d | %s | %s | %s | %s | %d |\n", $bpd, $q, $np, $np + scalar(@{ $E{$q}{other}{G} // [] }),
            (defined $gp ? $pc->($gp) : '-'), (defined $go ? $pc->($go) : '-'), (defined $tp ? $pc->($tp) : '-'), (defined $to ? $pc->($to) : '-'), $near;
    }
}

sub min { my $m = shift; for (@_) { $m = $_ if $_ < $m } $m }
