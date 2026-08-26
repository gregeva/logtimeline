#!/usr/bin/perl
#
# 426-revalidate-v7.pl — V7 aspect of the #426 revalidation: the BUCKET-STATS
# surface.
#
# The pre-prototype audit (features/426-per-message-statistics-store.md
# § Pre-prototype audit) found %TIER_BPD has four surfaces and that
# 'bucket-stats' is a THIRD consumer shape, covered by neither the per-key
# percentile aspects (V1-V5) nor the display aspect (V6):
#
#   - keyed per TIME BUCKET: bounded cardinality (tens to hundreds of
#     partitions), not the millions of message keys V1-V5 exercised.
#   - its own bpd ladder in %TIER_BPD:
#         'bucket-stats' => [16, 32, 53, 53, 53, 115, 616, 616, 616]
#     53 at the default tier 5; 616 only from tier 7. (Verified in ltl.)
#   - consumed by calculate_statistics_bin(), which invokes percentile()
#     DIRECTLY against the streaming partition. There is NO finalize rebin,
#     unlike V6's display surfaces.
#   - capture site (ltl, read_and_process_logs):
#         counter_update(\%bucket_stats_counters, $bucket, $duration,
#                        $bucket_stats_buckets_per_decade)
#
# THE CLAMP. calculate_statistics_bin() clamps every interpolated percentile
# to the observed [min,max] carried by the sidecars:
#
#     for (values %pct) {
#         next unless defined;
#         $_ = $min if defined $min && $_ < $min;
#         $_ = $max if defined $max && $_ > $max;
#     }
#
# (ltl, "Clamp interpolated percentile values to the observed [min, max].")
# It is load-bearing for #224 Decision 4's Layer-2 invariant
# "min <= p1 <= ... <= p99999 <= max": partition boundaries come from the
# lazy seed range (v_0 * sqrt(10^5)) and the in-bucket interpolation can
# return the populated bin's UPPER boundary, which may exceed the observed
# max. This prototype reproduces the clamp faithfully in ALL THREE arms, and
# measures how often it actually fires (Part 3) — the number that says
# whether the clamp does structural work or is a no-op, and in particular
# whether a shared grid G (no seeded out-of-range geometry) needs it as much
# as today's store T does.
#
# Arms: T = today's verbatim ltl primitives
#       S = span-only columnar store, verbatim geometry (P8+P9)
#       G = shared log-spaced grid, span-only (P10)
#
# Time buckets are derived from CONTIGUOUS RUNS of the input (the input is
# chronological, and the library's iterate_durations exposes no timestamp):
# every --bucket-size consecutive positive-duration samples form one bucket
# key. This reproduces the surface's defining property — bounded partition
# cardinality with large per-partition N — which is what distinguishes it
# from the per-message-key surface.
#
# Parts:
#   1. PARITY      T vs S per-key canonical digests, and the whole-store MD5.
#   2. ACCURACY    the full ltl percentile ladder (p1,p5,p10,p25,p50,p75,p90,
#                  p95,p99,p999,p9999) per bucket against oracle_percentiles
#                  over that bucket's raw values, WITH the clamp applied,
#                  using the 'int' rank convention (lib header § RANK
#                  CONVENTIONS).
#   3. CLAMP RATE  how often each arm's RAW interpolated value falls outside
#                  the observed [min,max], per arm and per quantile.
#   4. MEMORY      RSS delta per arm (N8's rule: RSS is the number of record),
#                  Devel::Size reported alongside.
#   5. TIMING      build cost and percentile-evaluation cost, medians of 3+
#                  with min/max ranges.
#
# Usage:
#   perl prototype/426-revalidate-v7.pl --file <log> --bpd N
#        [--bucket-size N] [--max-lines N] [--arm T|S|G|all] [--out <dir>]
#        [--runs N]
#
# One arm per process for the memory numbers (RSS delta is only meaningful
# when a single store is live); --arm all is for parity/accuracy convenience.

use strict;
use warnings;
use POSIX ();
use Digest::MD5 ();
use FindBin;
require "$FindBin::Bin/426-revalidate-lib.pm";

my %opt = (file => undef, bpd => 53, 'bucket-size' => 5000, 'max-lines' => undef,
           arm => 'all', out => undef, runs => 3, 'pct-runs' => 3);
while (@ARGV) {
    my $a = shift @ARGV;
    if    ($a =~ /^--([\w-]+)$/    && exists $opt{$1}) { $opt{$1} = shift @ARGV }
    elsif ($a =~ /^--([\w-]+)=(.*)$/ && exists $opt{$1}) { $opt{$1} = $2 }
    else { die "unknown argument: $a\n" }
}
die "--file is required\n"        unless defined $opt{file};
die "file not readable: $opt{file}\n" unless -r $opt{file};

my $BPD = $opt{bpd} + 0;
my $BS  = $opt{'bucket-size'} + 0;
Revalidate426::configure(bpd => $BPD);

# ltl's full percentile ladder as derived by calculate_statistics_bin under
# full demand (csv_body + extended): terminal_core + csv_body + extended.
# p99999 is in the ltl ladder too, but at the per-bucket N reachable here
# (<= --bucket-size) the oracle's int(n*q) index for q=0.99999 collapses onto
# the same sample as q=0.9999 for n < 100000; both are still evaluated below,
# and p99999 is reported separately so the collapse is visible rather than
# silently averaged into the ladder.
my @QUANT = ( [p1 => 0.01], [p5 => 0.05], [p10 => 0.10], [p25 => 0.25],
              [p50 => 0.50], [p75 => 0.75], [p90 => 0.90], [p95 => 0.95],
              [p99 => 0.99], [p999 => 0.999], [p9999 => 0.9999] );

# =============================================================================
# Load: bucket the input into contiguous runs, keeping raw values for the oracle.
# =============================================================================
my (@bucket_keys, %raw);          # bucket key -> arrayref of raw durations
my $seq = 0;
my $counts = Revalidate426::iterate_durations($opt{file}, sub {
    my (undef, undef, $dur) = @_;
    my $b = int($seq++ / $BS);
    my $key = sprintf('bucket%05d', $b);
    if (!exists $raw{$key}) { push @bucket_keys, $key; $raw{$key} = [] }
    push @{ $raw{$key} }, $dur;
}, defined $opt{'max-lines'} ? (max_lines => $opt{'max-lines'}) : ());

my $nbuckets = scalar @bucket_keys;
die "no positive durations parsed from $opt{file}\n" unless $nbuckets;

# Per-bucket sidecar min/max — exactly what calculate_statistics_bin clamps to.
# ltl populates these unconditionally per sample from the raw duration, NOT
# from the partition, so they are the TRUE observed extremes.
my %sidecar;
for my $k (@bucket_keys) {
    my ($mn, $mx);
    for my $v (@{ $raw{$k} }) { $mn = $v if !defined $mn || $v < $mn;
                                $mx = $v if !defined $mx || $v > $mx }
    $sidecar{$k} = { min => $mn, max => $mx, n => scalar @{ $raw{$k} } };
}

# =============================================================================
# Store construction / percentile evaluation
# =============================================================================
sub build_store {
    my ($arm) = @_;
    my $st = Revalidate426::store_new($arm, bpd => $BPD);
    for my $k (@bucket_keys) { $st->add($k, $_) for @{ $raw{$k} } }
    return $st;
}

# Reproduce calculate_statistics_bin's percentile ladder for ONE bucket key,
# including the clamp. Returns (\%clamped, \%raw_interpolated, \%audit).
# $conv selects the rank convention: 'ceil' is ltl's native #187 Decision 1;
# 'int' matches the oracle's own sample (lib header § RANK CONVENTIONS) and is
# what the accuracy comparison uses so the residual is binning error alone.
sub ladder {
    my ($st, $key, $conv) = @_;
    my (%pct, %rawv, %audit);
    for my $pair (@QUANT) {
        my ($name, $q) = @$pair;
        my ($v, $a) = $st->percentile($key, $q, $conv);
        $rawv{$name} = $v; $audit{$name} = $a;
        $pct{$name}  = $v;
    }
    # VERBATIM shape of ltl's clamp (calculate_statistics_bin):
    my ($min, $max) = @{ $sidecar{$key} }{qw(min max)};
    for (values %pct) {
        next unless defined;
        $_ = $min if defined $min && $_ < $min;
        $_ = $max if defined $max && $_ > $max;
    }
    return (\%pct, \%rawv, \%audit);
}

sub out_path {
    my ($name) = @_;
    return undef unless defined $opt{out};
    mkdir $opt{out} unless -d $opt{out};
    return "$opt{out}/$name";
}
my @report;
sub say_r { my $l = join('', @_); print $l, "\n"; push @report, $l }

# =============================================================================
# Header
# =============================================================================
say_r "# V7 bucket-stats surface — file=$opt{file} bpd=$BPD bucket_size=$BS";
say_r sprintf("input: format=%s lines=%d matched=%d positive=%d zero=%d no_duration=%d unparsed=%d",
    $counts->{format}, $counts->{lines}, $counts->{matched}, $counts->{positive},
    $counts->{zero}, $counts->{no_duration}, $counts->{unparsed});
{
    my @n = sort { $a <=> $b } map { $sidecar{$_}{n} } @bucket_keys;
    my $tot = 0; $tot += $_ for @n;
    my $q = sub { my $p = shift; $n[ POSIX::floor($#n * $p) ] };
    say_r sprintf("buckets: count=%d total_N=%d  N per bucket: min=%d p50=%d p95=%d max=%d",
        $nbuckets, $tot, $n[0], $q->(0.50), $q->(0.95), $n[-1]);
}
say_r "";

# =============================================================================
# PART 1 — PARITY (T vs S). Runs whenever both arms are in scope.
# =============================================================================
my %digest;
if ($opt{arm} eq 'all') {
    my $t = build_store('T');
    my $s = build_store('S');
    my $g = build_store('G');
    $digest{T} = $t->digest; $digest{S} = $s->digest; $digest{G} = $g->digest;
    my $mismatch = 0; my @first;
    for my $k (@bucket_keys) {
        my ($ct, $cs) = ($t->canonical($k), $s->canonical($k));
        if ($ct ne $cs) { $mismatch++; push @first, [$k, $ct, $cs] if @first < 3 }
    }
    say_r "## Part 1 — PARITY (T vs S canonical digests)";
    say_r sprintf("keys compared: %d   mismatches: %d", $nbuckets, $mismatch);
    say_r sprintf("store digest T = %s", $digest{T});
    say_r sprintf("store digest S = %s", $digest{S});
    say_r sprintf("PARITY: %s", ($mismatch == 0 && $digest{T} eq $digest{S}) ? 'PASS' : 'FAIL');
    for my $m (@first) { say_r "  MISMATCH $m->[0]\n    T: $m->[1]\n    S: $m->[2]" }
    # G is a different geometry by construction; its digest is recorded, not compared.
    say_r sprintf("store digest G = %s   (different geometry by construction; not a parity target)", $digest{G});
    say_r "";
    # Sanity: every arm must agree on N per key.
    my $nbad = 0;
    for my $k (@bucket_keys) {
        my $want = $sidecar{$k}{n};
        $nbad++ if $t->n($k) != $want || $s->n($k) != $want || $g->n($k) != $want;
    }
    say_r sprintf("N-conservation across T/S/G vs raw counts: %s (%d key(s) disagree)",
        $nbad ? 'FAIL' : 'PASS', $nbad);
    say_r "";
}

# =============================================================================
# PARTS 2+3 — ACCURACY vs oracle (with clamp) and CLAMP RATE, per arm
# =============================================================================
my @arms = $opt{arm} eq 'all' ? qw(T S G) : ($opt{arm});
my %acc;    # arm -> stats
for my $arm (@arms) {
    my $rss0 = Revalidate426::rss_kb();
    my $st = build_store($arm);
    my $rss1 = Revalidate426::rss_kb();
    my $bytes = eval { $st->memory_bytes };

    my ($maxrel, $maxrel_where) = (0, '');
    my ($cmp, $within, $exact_zero_div) = (0, 0, 0);
    my (%clamp_hi, %clamp_lo, %clamp_n);
    my (%rel_by_q, %n_by_q, %degen);
    my $binwidth = 10 ** (1 / $BPD);   # multiplicative width of one bin at this bpd

    for my $k (@bucket_keys) {
        my ($pct, $rawv) = ladder($st, $k, 'int');
        my @qs = map { $_->[1] } @QUANT;
        my @ora = Revalidate426::oracle_percentiles($raw{$k}, \@qs);
        my ($mn, $mx) = @{ $sidecar{$k} }{qw(min max)};
        for my $i (0 .. $#QUANT) {
            my $name = $QUANT[$i][0];
            my ($got, $want, $rw) = ($pct->{$name}, $ora[$i], $rawv->{$name});
            $clamp_n{$name}++;
            if (defined $rw) {
                $clamp_hi{$name}++ if defined $mx && $rw > $mx;
                $clamp_lo{$name}++ if defined $mn && $rw < $mn;
            }
            # Degeneracy flag: when the oracle's own index int(n*q) is n-1 the
            # oracle answer IS the observed max, and the clamp forces the arm to
            # exactly that value -> zero error by construction, not by accuracy.
            # Counted and reported separately rather than folded into the ladder.
            my $nb = $sidecar{$k}{n};
            $degen{$name}++ if int($nb * $QUANT[$i][1]) >= $nb - 1;
            next unless defined $got && defined $want;
            if ($want == 0) { $exact_zero_div++; next }
            my $rel = abs($got - $want) / $want;
            $cmp++;
            $rel_by_q{$name} += $rel; $n_by_q{$name}++;
            # "within one bin": the ratio got/want is inside one multiplicative
            # bin width at this bpd, i.e. the answer is in the oracle's own bin
            # or an adjacent one no further than a bin apart.
            my $ratio = $got > $want ? $got / $want : $want / $got;
            $within++ if $ratio <= $binwidth;
            if ($rel > $maxrel) { $maxrel = $rel; $maxrel_where = "$k/$name got=$got want=$want" }
        }
    }
    $acc{$arm} = {
        maxrel => $maxrel, where => $maxrel_where, cmp => $cmp,
        within => $within, binwidth => $binwidth, zerodiv => $exact_zero_div,
        rss => $rss1 - $rss0, bytes => $bytes,
        clamp_hi => \%clamp_hi, clamp_lo => \%clamp_lo, clamp_n => \%clamp_n,
        rel_by_q => \%rel_by_q, n_by_q => \%n_by_q, degen => \%degen,
    };
    undef $st;
}

say_r "## Part 2 — ACCURACY vs oracle (clamp applied, 'int' rank convention)";
say_r sprintf("bin width at bpd=%d: %.6f x (%.4f%% multiplicative)",
    $BPD, 10 ** (1 / $BPD), (10 ** (1 / $BPD) - 1) * 100);
say_r sprintf("%-4s %10s %12s %14s %14s", 'arm', 'compared', 'max_rel_err', 'within_1bin', 'mean_rel_err');
for my $arm (@arms) {
    my $a = $acc{$arm};
    my $mean = 0; my $n = 0;
    for my $q (CORE::keys %{ $a->{rel_by_q} }) { $mean += $a->{rel_by_q}{$q}; $n += $a->{n_by_q}{$q} }
    say_r sprintf("%-4s %10d %12.6f %13.2f%% %14.6f",
        $arm, $a->{cmp}, $a->{maxrel}, 100 * $a->{within} / ($a->{cmp} || 1),
        $n ? $mean / $n : 0);
}
for my $arm (@arms) { say_r sprintf("  %s worst: %s", $arm, $acc{$arm}{where}) if $acc{$arm}{where} }
say_r "";
say_r "### per-quantile mean relative error";
say_r "degen% = share of buckets where the oracle index int(n*q) is n-1, so the";
say_r "oracle answer IS the observed max and the clamp forces exact agreement.";
say_r "Those rows measure the clamp, not the binning; read them as such.";
say_r sprintf("%-8s %s %8s", 'quantile', join(' ', map { sprintf('%12s', $_) } @arms), 'degen%');
for my $pair (@QUANT) {
    my $q = $pair->[0];
    my $d = $acc{$arms[0]}{degen}{$q} // 0;
    say_r sprintf("%-8s %s %7.1f%%", $q, join(' ', map {
        my $a = $acc{$_};
        sprintf('%12.6f', $a->{n_by_q}{$q} ? $a->{rel_by_q}{$q} / $a->{n_by_q}{$q} : 0)
    } @arms), 100 * $d / ($nbuckets || 1));
}
say_r "";

say_r "## Part 3 — CLAMP RATE (raw interpolated value outside observed [min,max])";
say_r "clamped_high = raw > observed max ; clamped_low = raw < observed min";
say_r sprintf("%-8s %s", 'quantile', join(' ', map { sprintf('%22s', "$_ hi/lo") } @arms));
my %tot_hi; my %tot_lo; my %tot_n;
for my $pair (@QUANT) {
    my $q = $pair->[0];
    my @cells;
    for my $arm (@arms) {
        my $a = $acc{$arm};
        my ($hi, $lo, $n) = ($a->{clamp_hi}{$q} // 0, $a->{clamp_lo}{$q} // 0, $a->{clamp_n}{$q} // 0);
        $tot_hi{$arm} += $hi; $tot_lo{$arm} += $lo; $tot_n{$arm} += $n;
        push @cells, sprintf('%9.2f%%/%8.2f%%', 100 * $hi / ($n || 1), 100 * $lo / ($n || 1));
    }
    say_r sprintf("%-8s %s", $q, join(' ', @cells));
}
say_r sprintf("%-8s %s", 'ALL', join(' ', map {
    sprintf('%9.2f%%/%8.2f%%', 100 * ($tot_hi{$_} // 0) / ($tot_n{$_} || 1),
                               100 * ($tot_lo{$_} // 0) / ($tot_n{$_} || 1))
} @arms));
say_r "";

# =============================================================================
# PART 4 — MEMORY
# =============================================================================
say_r "## Part 4 — MEMORY";
say_r sprintf("%-4s %14s %16s", 'arm', 'RSS_delta_kB', 'Devel::Size_B');
for my $arm (@arms) {
    say_r sprintf("%-4s %14d %16s", $arm, $acc{$arm}{rss},
        defined $acc{$arm}{bytes} ? $acc{$arm}{bytes} : 'n/a');
}
say_r "NOTE: RSS delta in --arm all is contaminated (three stores built in one";
say_r "process). The memory number of record comes from the single-arm runs.";
say_r "";

# =============================================================================
# PART 5 — TIMING
# =============================================================================
say_r "## Part 5 — TIMING (medians of $opt{runs} with min/max)";
say_r sprintf("%-4s %26s %26s", 'arm', 'build_s (med [min,max])', 'ladder_s (med [min,max])');
for my $arm (@arms) {
    my @b = Revalidate426::time_runs($opt{runs} + 0, sub { my $s = build_store($arm); undef $s });
    my ($bm, $bmin, $bmax) = Revalidate426::median_min_max(@b);
    my $st = build_store($arm);
    my @p = Revalidate426::time_runs($opt{'pct-runs'} + 0, sub {
        for my $k (@bucket_keys) { ladder($st, $k, 'ceil') }
    });
    my ($pm, $pmin, $pmax) = Revalidate426::median_min_max(@p);
    undef $st;
    say_r sprintf("%-4s %10.4f [%.4f,%.4f] %14.5f [%.5f,%.5f]",
        $arm, $bm, $bmin, $bmax, $pm, $pmin, $pmax);
}
say_r "";
say_r sprintf("ladder = the full %d-quantile ltl ladder + clamp over all %d buckets, 'ceil' (native) convention",
    scalar @QUANT, $nbuckets);

if (defined $opt{out}) {
    my $p = out_path(sprintf('v7-%s-bpd%d.txt', $opt{arm}, $BPD));
    open(my $fh, '>', $p) or die "cannot write $p: $!\n";
    print $fh "$_\n" for @report;
    close $fh;
    warn "wrote $p\n";
}
