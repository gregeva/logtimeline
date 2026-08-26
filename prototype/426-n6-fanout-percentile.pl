#!/usr/bin/env perl
#
# 426-n6-fanout-percentile.pl — #426 N6: the per-key percentile evaluation cost
# and the per-key memory cost of each arm at fan-out scale, measured directly
# rather than projected from a smaller key count.
#
# One arm per process (RSS delta is only meaningful when one store exists in the
# address space). The store is built once from --file, then:
#
#   memory   RSS delta across the build (the number of record) beside
#            Devel::Size::total_size of the containers (the arm's own view of
#            itself), and the difference between them — the bytes the container
#            holds that Devel::Size cannot walk.
#   percentile  --runs timed sweeps (one untimed warmup) of $st->percentile over
#            every live key at each quantile in --quantiles; reported as
#            microseconds per evaluation, median of the runs with min/max.
#
# Usage:
#   perl prototype/426-n6-fanout-percentile.pl --file F --arm T|S|G [--bpd 53]
#        [--runs 3] [--quantiles 0.5,0.95,0.99] [--conv ceil]
use strict;
use warnings;
use FindBin;
use Getopt::Long qw(GetOptions);
use Time::HiRes qw(gettimeofday tv_interval);
require "$FindBin::Bin/426-revalidate-lib.pm";

my %opt = (bpd => 53, runs => 3, quantiles => '0.5,0.95,0.99', conv => 'ceil', arm => 'T');
GetOptions(\%opt, 'file=s', 'arm=s', 'bpd=i', 'runs=i', 'quantiles=s', 'conv=s', 'help')
    or die "bad options\n";
if ($opt{help} || !defined $opt{file}) {
    print "usage: $0 --file F --arm T|S|G [--bpd 53] [--runs 3] [--quantiles 0.5,0.95,0.99] [--conv ceil|int]\n";
    exit($opt{help} ? 0 : 2);
}
my @Q = split /,/, $opt{quantiles};
Revalidate426::configure(bpd => $opt{bpd}, seed_decades => 5, max_rebins => undef);

printf "=== N6 fan-out: arm %s bpd %d ===\nfile: %s\n", $opt{arm}, $opt{bpd}, $opt{file};

my $rss0 = Revalidate426::rss_kb();
my $t0 = [gettimeofday];
my $st = Revalidate426::store_new($opt{arm}, bpd => $opt{bpd});
my $counts = Revalidate426::iterate_durations($opt{file},
    sub { $st->add("$_[0]\x1f$_[1]", $_[2]) }, count_keys => 1);
my $build_s = tv_interval($t0);
my $rss1 = Revalidate426::rss_kb();

my @keys = $st->keys;
my $nkeys = scalar @keys;
my $obs = 0; $obs += $st->n($_) for @keys;

my $rss_bytes = ($rss1 - $rss0) * 1024;
my $ds_bytes  = $st->memory_bytes;
printf "counts: lines=%d positive=%d keys_positive=%d live_keys=%d observations=%d build_s=%.3f\n",
    @$counts{qw(lines positive keys_positive)}, $nkeys, $obs, $build_s;
printf "memory: RSS_delta_bytes=%d (%.2f MB, %.1f B/key)  DevelSize_bytes=%d (%.2f MB, %.1f B/key)  RSS-DevelSize=%d bytes (%.1f%% of RSS)\n",
    $rss_bytes, $rss_bytes / 2**20, $rss_bytes / ($nkeys || 1),
    $ds_bytes, $ds_bytes / 2**20, $ds_bytes / ($nkeys || 1),
    $rss_bytes - $ds_bytes, 100 * ($rss_bytes - $ds_bytes) / ($rss_bytes || 1);

# --- percentile sweep -------------------------------------------------------
my $evals = $nkeys * scalar @Q;
my $sweep = sub {
    my $sink = 0;
    for my $k (@keys) { for my $q (@Q) { my ($v) = $st->percentile($k, $q, $opt{conv}); $sink++ if defined $v } }
    return $sink;
};
my @secs = Revalidate426::time_runs($opt{runs}, $sweep);
my ($med, $mn, $mx) = Revalidate426::median_min_max(@secs);
printf "percentile: quantiles=%s conv=%s evals_per_sweep=%d runs=%d sweep_s median=%.4f (min %.4f max %.4f)\n",
    join(',', @Q), $opt{conv}, $evals, scalar @secs, $med, $mn, $mx;
printf "percentile: us_per_eval median=%.4f (min %.4f max %.4f)\n",
    1e6 * $med / $evals, 1e6 * $mn / $evals, 1e6 * $mx / $evals;
printf "build: s_per_key median_n/a single_build=%.6f ms/key=%.6f\n", $build_s, 1000 * $build_s / ($nkeys || 1);
print "OK\n";
