#!/usr/bin/env perl
#
# 426-revalidate-v2.pl — aspect V2 of the #426 revalidation (mirror of #189 V2,
# extended to the store shape): per-key fan-out at scale, per-line cost, merge
# cost, and the -g fold shape, for one arm (T | S | G) at one bpd per process.
#
# Phases (all in one process; the file is parsed ONCE into (key, duration)
# arrays so every timed section measures the store, not the regex):
#   0  parse        iterate_durations -> @K/@D; parse wall-clock reported once
#   1  parity fill  one untimed warmup fill; RSS delta around it; fill_digest
#                   (--parity-only stops here — the driver asserts T == S
#                   before any timing)
#   2  fill timing  --runs timed fills (fresh store each), ns/sample
#   3  memory       Devel::Size of the store, RSS delta, bytes/key, projection
#                   to 1e5 keys; arm telemetry
#   4  spans        occupied span (hi-lo+1 over nonzero bins) p50/p95/p99/max;
#                   T/S also bin_count and (T) dense array length
#   5  percentiles  all keys x 7 quantiles ('ceil'), --runs timed; pct_digest
#   6  merge pairs  consecutive keys in sorted order, both N>=2, non-overlapping
#                   (426-grid-fidelity.pl V8); fresh store per run, merges timed;
#                   remap counts (T/S) ; merge_digest
#   7  fold         merge ALL keys into ONE accumulator in sorted order (the -g
#                   fold shape); fresh store per run, timed; final geometry;
#                   fold_digest (MD5 of the accumulator's canonical)
#
# Every metric line is `name=value`; timing lines are also emitted as
#   TSV<TAB>arm<TAB>bpd<TAB>metric<TAB>median<TAB>min<TAB>max
# for the driver to collect.
#
# Usage: perl prototype/426-revalidate-v2.pl --arm T|S|G [--bpd 53] [--file F]
#        [--runs 3] [--fold-runs N] [--parity-only] [--skip-fold] [--help]

use strict;
use warnings;
use FindBin;
use POSIX ();
use Time::HiRes qw(gettimeofday tv_interval);
use Digest::MD5 ();
use List::Util ();
require "$FindBin::Bin/426-revalidate-lib.pm";

my $file = "$FindBin::Bin/../logs/AccessLogs/really-big/localhost_access_log-twx01-twx-thingworx-0.2026-01-14.txt";
my ($arm, $bpd, $runs, $fold_runs, $parity_only, $skip_fold) = (undef, 53, 3, undef, 0, 0);
sub usage {
    print <<"EOT";
usage: $0 --arm T|S|G [--bpd N] [--file F] [--runs N] [--fold-runs N] [--parity-only] [--skip-fold]
  --arm         T (today, verbatim primitives) | S (span-only columnar) | G (shared grid)
  --bpd         buckets per decade (default 53)
  --file        access log (default: the #189 V2 fan-out file)
  --runs        timed runs per phase after one untimed warmup (default 3)
  --fold-runs   timed runs for the fold phase (default: --runs)
  --parity-only parse + one fill + digest, then exit (no timing)
  --skip-fold   omit phase 7
EOT
    exit 0;
}
while (@ARGV) {
    my $o = shift @ARGV;
    if    ($o eq '--arm')         { $arm = shift @ARGV }
    elsif ($o eq '--bpd')         { $bpd = shift @ARGV }
    elsif ($o eq '--file')        { $file = shift @ARGV }
    elsif ($o eq '--runs')        { $runs = shift @ARGV }
    elsif ($o eq '--fold-runs')   { $fold_runs = shift @ARGV }
    elsif ($o eq '--parity-only') { $parity_only = 1 }
    elsif ($o eq '--skip-fold')   { $skip_fold = 1 }
    elsif ($o eq '--help')        { usage() }
    else { die "unknown option $o (try --help)\n" }
}
die "--arm T|S|G is required\n" unless defined $arm && $arm =~ /^[TSG]$/;
$fold_runs //= $runs;
Revalidate426::configure(bpd => $bpd, seed_decades => 5, max_rebins => undef);

my @Q = (0.01, 0.5, 0.75, 0.9, 0.95, 0.99, 0.999);
my $MB = 1024 * 1024;
sub say_kv { my ($k, $v) = @_; print "$k=$v\n" }
sub tsv {
    my ($metric, @secs) = @_;
    my ($med, $min, $max) = Revalidate426::median_min_max(@secs);
    printf "TSV\t%s\t%d\t%s\t%.6f\t%.6f\t%.6f\n", $arm, $bpd, $metric, $med, $min, $max;
    return ($med, $min, $max);
}
sub pct_of { my ($aref, $f) = @_; my @s = sort { $a <=> $b } @$aref; return @s ? $s[List::Util::min($#s, int(@s * $f))] : 0 }
sub timed_runs {                 # like time_runs, but a fresh setup per run (untimed) then the timed body
    my ($n, $setup, $body) = @_;
    my @secs;
    for my $r (0 .. $n) {        # r=0 is the warmup
        my $ctx = $setup->();
        my $t0 = [gettimeofday];
        $body->($ctx);
        push @secs, tv_interval($t0) if $r > 0;
    }
    return @secs;
}

(my $fx = $file) =~ s{.*/}{};
say_kv(arm => $arm); say_kv(bpd => $bpd); say_kv(file => $fx); say_kv(runs => $runs);
say_kv(bin_width_pct => sprintf('%.4f', 100 * (10 ** (1 / $bpd) - 1)));
say_kv(perl => $^V);

# --- phase 0: parse once ------------------------------------------------------
my (@K, @D);
my $rss_start = Revalidate426::rss_kb();
my $t0 = [gettimeofday];
my $counts = Revalidate426::iterate_durations($file, sub { push @K, "$_[0]\x1f$_[1]"; push @D, $_[2] }, count_keys => 1);
my $parse_s = tv_interval($t0);
my $n_samples = scalar @D;
say_kv(parse_s => sprintf('%.3f', $parse_s));
say_kv("parse_$_" => $counts->{$_}) for qw(format lines matched unparsed no_duration positive zero negative keys_any keys_positive);
say_kv(n_samples => $n_samples);
say_kv(rss_after_parse_kb => Revalidate426::rss_kb());

# --- phase 1: parity fill (warmup; RSS delta) ---------------------------------
sub fill { my $st = Revalidate426::store_new($arm, bpd => $bpd); $st->add($K[$_], $D[$_]) for 0 .. $#K; return $st }
my $rss_before_fill = Revalidate426::rss_kb();
my $st = fill();
my $rss_after_fill = Revalidate426::rss_kb();
my $n_keys = scalar $st->keys;
say_kv(keys => $n_keys);
say_kv(fill_digest => $st->digest);
say_kv(rss_before_fill_kb => $rss_before_fill);
say_kv(rss_after_fill_kb => $rss_after_fill);
my $rss_delta_b = ($rss_after_fill - $rss_before_fill) * 1024;
say_kv(fill_rss_delta_bytes => $rss_delta_b);
if ($parity_only) { print "PARITY_ONLY_DONE\n"; exit 0 }

# --- phase 2: fill timing -----------------------------------------------------
my @fill_secs;
for my $r (1 .. $runs) {
    undef $st;
    my $t = [gettimeofday];
    $st = fill();
    push @fill_secs, tv_interval($t);
}
my ($fill_med) = tsv('fill_s', @fill_secs);
say_kv(fill_ns_per_sample => sprintf('%.1f', $fill_med / $n_samples * 1e9));
say_kv(fill_ns_per_sample_range => sprintf('%.1f-%.1f', map { $_ / $n_samples * 1e9 } (sort { $a <=> $b } @fill_secs)[0, -1]));

# --- phase 3: memory ----------------------------------------------------------
my $mem = $st->memory_bytes;
say_kv(store_devel_size_bytes => $mem);
say_kv(store_devel_size_mb => sprintf('%.2f', $mem / $MB));
say_kv(bytes_per_key_devel_size => sprintf('%.0f', $mem / $n_keys));
say_kv(projected_1e5_keys_devel_size_mb => sprintf('%.1f', $mem / $n_keys * 1e5 / $MB));
say_kv(bytes_per_key_rss_delta => sprintf('%.0f', $rss_delta_b / $n_keys));
say_kv(projected_1e5_keys_rss_delta_mb => sprintf('%.1f', $rss_delta_b / $n_keys * 1e5 / $MB));
say_kv(projection_vs_d2_212mb_pct => sprintf('%+.1f', 100 * ($mem / $n_keys * 1e5 - 212e6) / 212e6)) if $bpd == 53;
my $tel = $st->telemetry;
say_kv("telemetry_$_" => $tel->{$_} // 'undef') for sort keys %$tel;

# --- phase 4: spans -----------------------------------------------------------
{
    my (@span, @bc, @dense_len);
    for my $k ($st->keys) {
        my @p = $st->bins_pairs($k);
        my ($lo) = $p[0]  =~ /^(-?\d+):/;
        my ($hi) = $p[-1] =~ /^(-?\d+):/;
        push @span, $hi - $lo + 1;
        if ($arm ne 'G') {
            push @bc, $st->geometry($k)->{bin_count};
            push @dense_len, scalar @{ $st->entry($k)->{bins} } if $arm eq 'T';
        }
    }
    say_kv("span_$_" => pct_of(\@span, $_ eq 'max' ? 1 : $_ / 100)) for qw(50 95 99 max);
    say_kv(span_mean => sprintf('%.2f', List::Util::sum(@span) / @span));
    if ($arm ne 'G') {
        say_kv("bin_count_$_" => pct_of(\@bc, $_ eq 'max' ? 1 : $_ / 100)) for qw(50 95 99 max);
    }
    if ($arm eq 'T') {
        say_kv("dense_len_$_" => pct_of(\@dense_len, $_ eq 'max' ? 1 : $_ / 100)) for qw(50 95 99 max);
        say_kv(dense_len_mean => sprintf('%.2f', List::Util::sum(@dense_len) / @dense_len));
    }
}

# --- phase 5: percentile pass -------------------------------------------------
my @sorted_keys = sort { $a cmp $b } $st->keys;
my $pct_digest;
my @pct_secs = Revalidate426::time_runs($runs, sub {
    my $d = Digest::MD5->new;
    for my $k (@sorted_keys) {
        for my $q (@Q) {
            my ($v, $a) = $st->percentile($k, $q, 'ceil');
            $d->add(sprintf('%.12g|%s;', $v, $a));
        }
    }
    $pct_digest = $d->hexdigest;
});
my ($pct_med) = tsv('percentile_pass_s', @pct_secs);
say_kv(percentile_evaluations => $n_keys * scalar @Q);
say_kv(percentile_us_per_eval => sprintf('%.2f', $pct_med / ($n_keys * @Q) * 1e6));
say_kv(pct_digest => $pct_digest);

# --- phase 6: merge consecutive pairs -----------------------------------------
my %N; $N{$_}++ for @K;
my @mk = grep { $N{$_} >= 2 } @sorted_keys;
my @pairs; for (my $j = 0; $j + 1 < @mk; $j += 2) { push @pairs, [ @mk[$j, $j + 1] ] }
say_kv(merge_pairs => scalar @pairs);
say_kv(merge_keys_with_n_ge_2 => scalar @mk);
{
    # remap accounting on the (untouched) filled store, before any merge
    my ($target_remap, $source_remap, $any_remap) = (0, 0, 0);
    if ($arm ne 'G') {
        for my $p (@pairs) {
            my ($gt, $gs) = map { $st->geometry($_) } @$p;
            my $umin = $gt->{min} < $gs->{min} ? $gt->{min} : $gs->{min};
            my $umax = $gt->{max} > $gs->{max} ? $gt->{max} : $gs->{max};
            my $ubc  = int($bpd * log($umax / $umin) / log(10)); $ubc = 1 if $ubc < 1;
            my $tr = ($gt->{min} != $umin || $gt->{max} != $umax || $gt->{bin_count} != $ubc) ? 1 : 0;
            my $sr = ($gs->{min} != $umin || $gs->{max} != $umax || $gs->{bin_count} != $ubc) ? 1 : 0;
            $target_remap += $tr; $source_remap += $sr; $any_remap++ if $tr || $sr;
        }
    }
    say_kv(merge_pairs_target_remap => $target_remap);
    say_kv(merge_pairs_source_remap => $source_remap);
    say_kv(merge_pairs_any_remap => $any_remap);
    say_kv(merge_remap_pct => sprintf('%.1f', @pairs ? 100 * $any_remap / @pairs : 0));
}
my $merged_store;
my @merge_secs = timed_runs($runs,
    sub { undef $merged_store; $merged_store = fill(); return $merged_store },
    sub { my $s = $_[0]; $s->merge($_->[0], $_->[1], drop_source => 1) for @pairs });
my ($merge_med) = tsv('merge_pairs_s', @merge_secs);
say_kv(merge_us_per_merge => sprintf('%.2f', @pairs ? $merge_med / @pairs * 1e6 : 0));
say_kv(merge_keys_after => scalar $merged_store->keys);
say_kv(merge_digest => $merged_store->digest);
{
    my $n_check = 0; $n_check += $merged_store->n($_) for $merged_store->keys;
    say_kv(merge_n_total_after => $n_check);      # must equal n_samples
    if ($arm ne 'G') {
        my $t2 = $merged_store->telemetry;
        say_kv(merge_max_partition_bins => $t2->{max_partition_bins});
    }
}
undef $merged_store;

# --- phase 7: the -g fold shape -----------------------------------------------
if (!$skip_fold) {
    my $acc = $sorted_keys[0];
    my @rest = @sorted_keys[1 .. $#sorted_keys];
    my $fold_store;
    my @fold_secs = timed_runs($fold_runs,
        sub { undef $fold_store; $fold_store = fill(); return $fold_store },
        sub { my $s = $_[0]; $s->merge($acc, $_, drop_source => 1) for @rest });
    my ($fold_med) = tsv('fold_all_s', @fold_secs);
    say_kv(fold_runs => $fold_runs);
    say_kv(fold_merges => scalar @rest);
    say_kv(fold_us_per_merge => sprintf('%.2f', $fold_med / @rest * 1e6));
    say_kv(fold_keys_after => scalar $fold_store->keys);
    say_kv(fold_n_total => $fold_store->n($acc));           # must equal n_samples
    my @p = $fold_store->bins_pairs($acc);
    my ($lo) = $p[0] =~ /^(-?\d+):/; my ($hi) = $p[-1] =~ /^(-?\d+):/;
    say_kv(fold_occupied_span => $hi - $lo + 1);
    say_kv(fold_nonzero_bins => scalar @p);
    my $g = $fold_store->geometry($acc);
    if ($arm eq 'G') {
        say_kv(fold_lo_index => $g->{lo_index}); say_kv(fold_hi_index => $g->{hi_index}); say_kv(fold_span => $g->{span});
    } else {
        say_kv(fold_bin_count => $g->{bin_count});
        say_kv(fold_min => sprintf('%.6g', $g->{min})); say_kv(fold_max => sprintf('%.6g', $g->{max}));
        say_kv(fold_decades => sprintf('%.3f', log($g->{max} / $g->{min}) / log(10)));
        say_kv(fold_rebins => $g->{rebins}); say_kv(fold_overflow => $g->{overflow}); say_kv(fold_underflow => $g->{underflow});
        say_kv(fold_dense_len => scalar @{ $fold_store->entry($acc)->{bins} });
    }
    say_kv(fold_digest => Digest::MD5::md5_hex($fold_store->canonical($acc)));
    my @fp = map { my ($v, $a) = $fold_store->percentile($acc, $_, 'ceil'); sprintf('%.6g', $v) } @Q;
    say_kv(fold_percentiles => join(',', @fp));
}
say_kv(rss_end_kb => Revalidate426::rss_kb());
print "DONE\n";
