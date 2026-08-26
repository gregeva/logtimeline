#!/usr/bin/env perl
#
# 426-n6-locality-probe.pl — #426 N6: why arm T's percentile cost per evaluation
# rises with the number of live keys even though the per-evaluation work (one
# pass to total the bins, one walk over bin_count slots) is fixed by bpd alone.
#
# Holds bpd and the per-key shape constant (N=1, the fan-out shape) and varies
# only the key count, so the only thing changing is how far the per-key bin
# arrays are spread through the heap. Reports microseconds per percentile
# evaluation at each key count, median of --runs with min/max.
#
# Usage: perl prototype/426-n6-locality-probe.pl [--bpd 53] [--runs 3]
#        [--keys 5000,20000,80000,200000] [--arm T]
use strict;
use warnings;
use FindBin;
use Getopt::Long qw(GetOptions);
require "$FindBin::Bin/426-revalidate-lib.pm";

my %opt = (bpd => 53, runs => 3, keys => '5000,20000,80000,200000', arm => 'T');
GetOptions(\%opt, 'bpd=i', 'runs=i', 'keys=s', 'arm=s') or die "bad options\n";
Revalidate426::configure(bpd => $opt{bpd}, seed_decades => 5, max_rebins => undef);

printf "=== N6 locality probe: arm %s bpd %d (N=1 per key, one quantile per key) ===\n",
    $opt{arm}, $opt{bpd};
printf "%10s %12s %14s %14s %12s\n", 'keys', 'RSS_MB', 'us/eval_med', 'us/eval_min', 'us/eval_max';
for my $nk (split /,/, $opt{keys}) {
    my $r0 = Revalidate426::rss_kb();
    my $st = Revalidate426::store_new($opt{arm}, bpd => $opt{bpd});
    $st->add("key$_", 100 + ($_ % 900)) for 1 .. $nk;
    my @k = $st->keys;
    my $rss = (Revalidate426::rss_kb() - $r0) / 1024;
    my @secs = Revalidate426::time_runs($opt{runs}, sub {
        my $sink = 0;
        for my $key (@k) { my ($v) = $st->percentile($key, 0.5, 'ceil'); $sink++ if defined $v }
        return $sink;
    });
    my ($med, $mn, $mx) = Revalidate426::median_min_max(@secs);
    printf "%10d %12.1f %14.3f %14.3f %12.3f\n",
        $nk, $rss, 1e6 * $med / @k, 1e6 * $mn / @k, 1e6 * $mx / @k;
    undef $st;
}
print "OK\n";
