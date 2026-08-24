#!/usr/bin/env perl
#
# 426-revalidate-v5.pl — aspect V5 of the #426 revalidation: calculation
# accuracy of the bin-counter arms against ltl's calculate_statistics oracle,
# per key and after merges. Mirrors #189 V5 (prototype/189-bin-counter-
# primitives.pl run_v5) and extends it with the merge scope of #426 V8.
#
# Arms (prototype/426-revalidate-lib.pm): T = production primitives verbatim,
# S = span-only columnar with verbatim geometry (digest-checked against T only),
# G = shared log-spaced grid, span-only.
#
# Scopes, per bpd:
#   [parity]  T vs S whole-store digest at --parity-bpd (default 53); the
#             script exits 2 on divergence. S inherits T's accuracy numbers by
#             construction, so S is not tabulated separately.
#   [key]     keys with N >= --min-N (default 100), quantiles P1 P50 P75 P90
#             P95 P99 P999, T and G vs the oracle, dual reporting:
#               binning_* : arm walk forced to the oracle's rank (int(q*N)+1,
#                           1-based) — binning error alone
#               raw_*     : arm's native ceil(q*N) (#187 D1) — binning +
#                           rank-convention error
#             Pass criterion (as #189 V5): binning_max <= 10^(1/bpd) - 1.
#   [small]   every key with N >= 2 (informational): median / p95 / max abs
#             error and % within one bin, T vs G, both conventions.
#   [pair]    consecutive keys in sorted order (both N >= 2), disjoint pairs
#             (k0,k1),(k2,k3),... merged: T via merge_bin_counter_entries
#             (fresh entries per pair), G via index-wise add; vs the oracle on
#             the union of samples.
#   [fold]    groups of 8 consecutive keys (N >= 2) folded sequentially into
#             the first (7 merges — the -g grouping shape); error vs the
#             oracle on the cumulative union recorded after every step.
#
# Output: a text report on stdout (capture it) and TSV files under
# --tsv-prefix: <prefix>-key-bpdNN.tsv, <prefix>-small-bpdNN.tsv,
# <prefix>-pair-bpdNN.tsv, <prefix>-fold-bpdNN.tsv (one row per comparison)
# plus <prefix>-summary.tsv (one row per bpd/scope/arm/convention/quantile;
# appended across runs).
#
# Usage:
#   perl prototype/426-revalidate-v5.pl --file F [--bpd 53,115,256,616]
#        [--arm T,G] [--parity-bpd 53] [--min-N 100] [--max-lines N]
#        [--tsv-prefix prototype/426-results/revalidate-v5]
#
use strict;
use warnings;
use FindBin;
use POSIX ();
use Time::HiRes qw(gettimeofday tv_interval);
use List::Util qw(sum min max);
require "$FindBin::Bin/426-revalidate-lib.pm";

my %opt = (
    file         => undef,
    bpd          => '53,115,256,616',
    arm          => 'T,G',
    'parity-bpd' => 53,
    'min-N'      => 100,
    'max-lines'  => undef,
    'tsv-prefix' => "$FindBin::Bin/426-results/revalidate-v5",
    'fold-size'  => 8,
);
sub usage {
    print <<"USAGE";
usage: $0 --file F [--bpd 53,115,256,616] [--arm T,G] [--parity-bpd 53]
          [--min-N 100] [--max-lines N] [--fold-size 8]
          [--tsv-prefix prototype/426-results/revalidate-v5]
  --file        access log (Tomcat) or ThingWorx application log
  --bpd         comma list of bins-per-decade levels to run (one loop each, parsed once)
  --arm         arms to tabulate against the oracle: T and/or G (S is parity-only)
  --parity-bpd  bpd at which S is also built and T<->S digest parity asserted
                (exit 2 on divergence); 0 disables
  --min-N       key-scope threshold (#189 V5 used 100)
  --max-lines   stop reading after N lines (iteration)
  --fold-size   keys per fold group (default 8 -> 7 merges)
  --tsv-prefix  path prefix for the per-comparison TSV files
USAGE
    exit 0;
}
while (@ARGV) {
    my $o = shift @ARGV;
    if    ($o eq '--help' || $o eq '-h') { usage() }
    elsif ($o =~ /^--(file|bpd|arm|parity-bpd|min-N|max-lines|tsv-prefix|fold-size)$/) { $opt{$1} = shift @ARGV }
    else { die "unknown option $o (try --help)\n" }
}
die "--file is required (try --help)\n" unless defined $opt{file};
my @bpds = split /,/, $opt{bpd};
my %arm  = map { $_ => 1 } split /,/, $opt{arm};
die "--arm must be a subset of T,G\n" if grep { !/^[TG]$/ } keys %arm;
my @arms = grep { $arm{$_} } qw(T G);
my @Q = (0.01, 0.5, 0.75, 0.9, 0.95, 0.99, 0.999);
my %QL = (0.01 => 'P1', 0.5 => 'P50', 0.75 => 'P75', 0.9 => 'P90', 0.95 => 'P95', 0.99 => 'P99', 0.999 => 'P999');
my @CONV = qw(int ceil);
my %CONVLABEL = (int => 'binning', ceil => 'raw');

$| = 1;
(my $fx = $opt{file}) =~ s{.*/}{};
print "=== 426 V5: accuracy vs calculate_statistics oracle, per key and after merge ===\n";
printf "file: %s\narms: %s  parity-bpd: %s  min-N: %d  fold-size: %d\n", $opt{file}, join(',', @arms), $opt{'parity-bpd'}, $opt{'min-N'}, $opt{'fold-size'};

# --- parse once ---------------------------------------------------------------
my $rss0 = Revalidate426::rss_kb();
my $t0 = [gettimeofday];
my %samples;   # "$cat\x1f$key" => [durations > 0]
my $counts = Revalidate426::iterate_durations($opt{file}, sub {
    my ($cat, $key, $d) = @_;
    push @{ $samples{"$cat\x1f$key"} }, $d;
}, count_keys => 1, (defined $opt{'max-lines'} ? (max_lines => $opt{'max-lines'}) : ()));
my $parse_s = tv_interval($t0);
printf "parse: format=%s lines=%d matched=%d unparsed=%d no_duration=%d positive=%d zero=%d negative=%d keys_any=%d keys_positive=%d parse_s=%.2f rss_after_parse_kb=%d\n",
    $counts->{format}, @$counts{qw(lines matched unparsed no_duration positive zero negative keys_any keys_positive)}, $parse_s, Revalidate426::rss_kb();

my @keys_sorted = sort { $a cmp $b } keys %samples;
my @keys_big    = grep { @{ $samples{$_} } >= $opt{'min-N'} } @keys_sorted;
my @keys_ge2    = grep { @{ $samples{$_} } >= 2 } @keys_sorted;
printf "keys: total=%d N>=%d: %d  N>=2: %d  pairs=%d  fold groups of %d=%d\n",
    scalar @keys_sorted, $opt{'min-N'}, scalar @keys_big, scalar @keys_ge2, int(@keys_ge2 / 2), $opt{'fold-size'}, int(@keys_ge2 / $opt{'fold-size'});

# --- helpers ------------------------------------------------------------------
sub pick { my ($sorted, $f) = @_; my $i = int(@$sorted * $f); $i = $#$sorted if $i > $#$sorted; return $sorted->[$i] }
sub errstats {
    # abs relative errors -> (n, p50, p95, p99, max, within_bound_fraction, mean_signed)
    my ($abs, $signed, $bound) = @_;
    my @s = sort { $a <=> $b } @$abs;
    return (0) x 7 unless @s;
    my $within = grep { $_ <= $bound + 1e-12 } @s;
    my $bias = @$signed ? sum(@$signed) / @$signed : 0;
    return (scalar @s, pick(\@s, 0.5), pick(\@s, 0.95), pick(\@s, 0.99), $s[-1], $within / @s, $bias);
}
sub open_tsv {
    my ($path, @hdr) = @_;
    open(my $fh, '>', $path) or die "cannot write $path: $!\n";
    print $fh join("\t", @hdr), "\n";
    return $fh;
}
my $summary_path = "$opt{'tsv-prefix'}-summary.tsv";
my $summary_new  = !-e $summary_path;
open(my $SUM, '>>', $summary_path) or die "cannot append $summary_path: $!\n";
print $SUM join("\t", qw(file bpd bound scope arm conv quantile n p50 p95 p99 max within_bound mean_signed)), "\n" if $summary_new;
sub emit_summary {
    my ($bpd, $bound, $scope, $arm, $conv, $q, @st) = @_;
    printf $SUM "%s\t%d\t%.6f\t%s\t%s\t%s\t%s\t%d\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\n", $fx, $bpd, $bound, $scope, $arm, $conv, $QL{$q}, @st;
}

# A fresh per-arm store holding only the given keys (T merge mutates the
# target and adopts by reference; fresh stores keep the key-scope stores clean).
sub fresh_store {
    my ($arm, $bpd, @ks) = @_;
    my $st = Revalidate426::store_new($arm, bpd => $bpd);
    for my $k (@ks) { $st->add($k, $_) for @{ $samples{$k} } }
    return $st;
}
sub geom_sig { my ($g) = @_; return join('/', @$g{qw(min max bin_count)}) }

my $exit = 0;
for my $bpd (@bpds) {
    Revalidate426::configure(bpd => $bpd, seed_decades => 5, max_rebins => undef);
    my $bound = 10 ** (1 / $bpd) - 1;
    printf "\n############ bpd=%d  one bin = %.4f%% (worst-case structural bound)\n", $bpd, 100 * $bound;

    # --- build the key-scope stores ---------------------------------------------
    my @build = @arms;
    push @build, 'S' if $opt{'parity-bpd'} && $bpd == $opt{'parity-bpd'};
    my %st;
    for my $a (@build) {
        my $r0 = Revalidate426::rss_kb();
        my $t = [gettimeofday];
        my $s = Revalidate426::store_new($a, bpd => $bpd);
        for my $k (@keys_sorted) { $s->add($k, $_) for @{ $samples{$k} } }
        my $el = tv_interval($t);
        $st{$a} = $s;
        printf "build %s: keys=%d build_s=%.2f (single run, informational) memory_bytes=%d rss_delta_kb=%d\n",
            $a, scalar $s->keys, $el, $s->memory_bytes, Revalidate426::rss_kb() - $r0;
    }
    if ($st{T}) {
        my $tel = $st{T}->telemetry;
        printf "T telemetry: partition_count=%d total_rebin_events=%d max_partition_bins=%d partitions_with_overflow=%d partitions_with_underflow=%d overflow_total=%d underflow_total=%d rebins p50=%d p95=%d p99=%d max=%d\n",
            @$tel{qw(partition_count total_rebin_events max_partition_bins partitions_with_overflow_count partitions_with_underflow_count overflow_total underflow_total rebins_p50 rebins_p95 rebins_p99 rebins_max)};
    }
    if ($st{G}) {
        my $tel = $st{G}->telemetry;
        printf "G telemetry: partition_count=%d span p50=%d p95=%d p99=%d max=%d index_range=[%d,%d]\n",
            @$tel{qw(partition_count span_p50 span_p95 span_p99 span_max index_min index_max)};
    }
    # --- parity -----------------------------------------------------------------
    if ($st{S}) {
        my ($dT, $dS) = ($st{T}->digest, $st{S}->digest);
        my $ok = $dT eq $dS;
        printf "%s parity bpd=%d: T digest=%s S digest=%s keys T=%d S=%d\n", ($ok ? 'PASS' : 'FAIL'), $bpd, $dT, $dS, scalar $st{T}->keys, scalar $st{S}->keys;
        if (!$ok) { print "T<->S digest divergence — aborting\n"; exit 2 }
        delete $st{S};
    }

    # --- [key] scope: N >= min-N ------------------------------------------------
    {
        my $fh = open_tsv("$opt{'tsv-prefix'}-key-bpd$bpd.tsv", qw(key_ordinal n quantile oracle), map { my $a = $_; map { ("${a}_$_", "${a}_${_}_err") } @CONV } @arms);
        my %E;   # {arm}{conv}{q} => [abs errs], {arm}{conv}{q}{signed}
        my $ord = 0;
        for my $k (@keys_big) {
            $ord++;
            my $n = @{ $samples{$k} };
            my @orc = Revalidate426::oracle_percentiles($samples{$k}, \@Q);
            for my $j (0 .. $#Q) {
                my @row = ($ord, $n, $QL{$Q[$j]}, $orc[$j]);
                for my $a (@arms) {
                    for my $conv (@CONV) {
                        my ($v) = $st{$a}->percentile($k, $Q[$j], $conv);
                        my $se = ($v - $orc[$j]) / $orc[$j];
                        push @{ $E{$a}{$conv}{$Q[$j]}{abs} }, abs($se);
                        push @{ $E{$a}{$conv}{$Q[$j]}{sig} }, $se;
                        push @row, sprintf('%.6f', $v), sprintf('%.6f', $se);
                    }
                }
                print $fh join("\t", @row), "\n";
            }
        }
        close $fh;
        printf "\n[key] keys_compared (N >= %d): %d\n", $opt{'min-N'}, scalar @keys_big;
        for my $a (@arms) {
            printf "%-3s %-5s %12s %12s %12s %12s %12s %12s %12s %s\n", 'arm', 'Q', 'binning_p50', 'binning_p95', 'binning_p99', 'binning_max', 'raw_p50', 'raw_max', 'raw>bin_max', 'pass(binning_max<=bound)';
            my $all_pass = 1;
            for my $q (@Q) {
                my @b = errstats($E{$a}{int}{$q}{abs},  $E{$a}{int}{$q}{sig},  $bound);
                my @r = errstats($E{$a}{ceil}{$q}{abs}, $E{$a}{ceil}{$q}{sig}, $bound);
                my $pass = $b[4] <= $bound + 1e-12;
                $all_pass &&= $pass;
                printf "%-3s %-5s %11.4f%% %11.4f%% %11.4f%% %11.4f%% %11.4f%% %11.4f%% %12s %s\n", $a, $QL{$q},
                    100 * $b[1], 100 * $b[2], 100 * $b[3], 100 * $b[4], 100 * $r[1], 100 * $r[4],
                    ($r[4] > $b[4] + 1e-12 ? sprintf('+%.4f%%', 100 * ($r[4] - $b[4])) : 'no'), ($pass ? 'PASS' : 'FAIL');
                emit_summary($bpd, $bound, 'key', $a, 'binning', $q, @b);
                emit_summary($bpd, $bound, 'key', $a, 'raw', $q, @r);
            }
            printf "%s [key] bpd=%d arm=%s: binning_max <= %.4f%% at every quantile\n", ($all_pass ? 'PASS' : 'FAIL'), $bpd, $a, 100 * $bound;
            $exit = 1 unless $all_pass;
        }
    }

    # --- [small] scope: every key with N >= 2 ----------------------------------
    {
        my $fh = open_tsv("$opt{'tsv-prefix'}-small-bpd$bpd.tsv", qw(key_ordinal n quantile oracle), map { my $a = $_; map { ("${a}_${_}_err") } @CONV } @arms);
        my %E;
        my $ord = 0;
        for my $k (@keys_ge2) {
            $ord++;
            my $n = @{ $samples{$k} };
            my @orc = Revalidate426::oracle_percentiles($samples{$k}, \@Q);
            for my $j (0 .. $#Q) {
                my @row = ($ord, $n, $QL{$Q[$j]}, $orc[$j]);
                for my $a (@arms) {
                    for my $conv (@CONV) {
                        my ($v) = $st{$a}->percentile($k, $Q[$j], $conv);
                        my $se = ($v - $orc[$j]) / $orc[$j];
                        push @{ $E{$a}{$conv}{$Q[$j]}{abs} }, abs($se);
                        push @{ $E{$a}{$conv}{$Q[$j]}{sig} }, $se;
                        push @row, sprintf('%.6f', $se);
                    }
                }
                print $fh join("\t", @row), "\n";
            }
        }
        close $fh;
        printf "\n[small] keys_compared (N >= 2): %d\n", scalar @keys_ge2;
        printf "%-3s %-5s %-7s %12s %12s %12s %12s %10s\n", 'arm', 'Q', 'conv', 'p50', 'p95', 'p99', 'max', 'within1bin';
        for my $a (@arms) {
            for my $q (@Q) {
                for my $conv (@CONV) {
                    my @s = errstats($E{$a}{$conv}{$q}{abs}, $E{$a}{$conv}{$q}{sig}, $bound);
                    printf "%-3s %-5s %-7s %11.4f%% %11.4f%% %11.4f%% %11.4f%% %9.2f%%\n", $a, $QL{$q}, $CONVLABEL{$conv}, 100 * $s[1], 100 * $s[2], 100 * $s[3], 100 * $s[4], 100 * $s[5];
                    emit_summary($bpd, $bound, 'small', $a, $CONVLABEL{$conv}, $q, @s);
                }
            }
        }
    }

    # --- [pair] scope --------------------------------------------------------
    {
        my $fh = open_tsv("$opt{'tsv-prefix'}-pair-bpd$bpd.tsv", qw(pair n_a n_b n_union remap quantile oracle), map { my $a = $_; map { ("${a}_${_}_err") } @CONV } @arms);
        my %E; my ($n_pairs, $n_remaps) = (0, 0);
        my $t = [gettimeofday];
        for (my $j = 0; $j + 1 < @keys_ge2; $j += 2) {
            my ($ka, $kb) = @keys_ge2[$j, $j + 1];
            $n_pairs++;
            my @union = (@{ $samples{$ka} }, @{ $samples{$kb} });
            my @orc = Revalidate426::oracle_percentiles(\@union, \@Q);
            my %ps; my $remap = 0;
            for my $a (@arms) {
                my $s = fresh_store($a, $bpd, $ka, $kb);
                if ($a eq 'T') { $remap = geom_sig($s->geometry($ka)) ne geom_sig($s->geometry($kb)) ? 1 : 0 }
                $s->merge($ka, $kb, drop_source => 1);
                die "merge N mismatch arm=$a" unless $s->n($ka) == @union;
                $ps{$a} = $s;
            }
            $n_remaps += $remap;
            for my $i (0 .. $#Q) {
                my @row = ($n_pairs, scalar @{ $samples{$ka} }, scalar @{ $samples{$kb} }, scalar @union, $remap, $QL{$Q[$i]}, $orc[$i]);
                for my $a (@arms) {
                    for my $conv (@CONV) {
                        my ($v) = $ps{$a}->percentile($ka, $Q[$i], $conv);
                        my $se = ($v - $orc[$i]) / $orc[$i];
                        push @{ $E{$a}{$conv}{$Q[$i]}{abs} }, abs($se);
                        push @{ $E{$a}{$conv}{$Q[$i]}{sig} }, $se;
                        push @row, sprintf('%.6f', $se);
                    }
                }
                print $fh join("\t", @row), "\n";
            }
        }
        close $fh;
        printf "\n[pair] merged pairs=%d (consecutive keys, N>=2, disjoint) T union remaps=%d (%.1f%%) elapsed_s=%.1f\n", $n_pairs, $n_remaps, ($n_pairs ? 100 * $n_remaps / $n_pairs : 0), tv_interval($t);
        printf "%-3s %-5s %-7s %12s %12s %12s %12s %10s %s\n", 'arm', 'Q', 'conv', 'p50', 'p95', 'p99', 'max', 'within1bin', 'pass(binning_max<=bound)';
        for my $a (@arms) {
            for my $q (@Q) {
                for my $conv (@CONV) {
                    my @s = errstats($E{$a}{$conv}{$q}{abs}, $E{$a}{$conv}{$q}{sig}, $bound);
                    my $pass = $conv eq 'int' ? ($s[4] <= $bound + 1e-12 ? 'PASS' : 'FAIL') : '-';
                    printf "%-3s %-5s %-7s %11.4f%% %11.4f%% %11.4f%% %11.4f%% %9.2f%% %s\n", $a, $QL{$q}, $CONVLABEL{$conv}, 100 * $s[1], 100 * $s[2], 100 * $s[3], 100 * $s[4], 100 * $s[5], $pass;
                    emit_summary($bpd, $bound, 'pair', $a, $CONVLABEL{$conv}, $q, @s);
                }
            }
        }
    }

    # --- [fold] scope --------------------------------------------------------
    {
        my $fs = $opt{'fold-size'};
        my $fh = open_tsv("$opt{'tsv-prefix'}-fold-bpd$bpd.tsv", qw(group step n_union remaps_so_far quantile oracle), map { my $a = $_; map { ("${a}_${_}_err") } @CONV } @arms);
        my %E; my ($n_groups, $n_remaps_total) = (0, 0);
        my $t = [gettimeofday];
        for (my $j = 0; $j + $fs - 1 < @keys_ge2; $j += $fs) {
            my @g = @keys_ge2[$j .. $j + $fs - 1];
            $n_groups++;
            my %ps = map { $_ => fresh_store($_, $bpd, @g) } @arms;
            my @union = @{ $samples{ $g[0] } };
            my $remaps = 0;
            for my $step (1 .. $fs - 1) {
                my $ks = $g[$step];
                push @union, @{ $samples{$ks} };
                for my $a (@arms) {
                    if ($a eq 'T') { $remaps++ if geom_sig($ps{T}->geometry($g[0])) ne geom_sig($ps{T}->geometry($ks)) }
                    $ps{$a}->merge($g[0], $ks, drop_source => 1);
                    die "fold N mismatch arm=$a" unless $ps{$a}->n($g[0]) == @union;
                }
                my @orc = Revalidate426::oracle_percentiles(\@union, \@Q);
                for my $i (0 .. $#Q) {
                    my @row = ($n_groups, $step, scalar @union, $remaps, $QL{$Q[$i]}, $orc[$i]);
                    for my $a (@arms) {
                        for my $conv (@CONV) {
                            my ($v) = $ps{$a}->percentile($g[0], $Q[$i], $conv);
                            my $se = ($v - $orc[$i]) / $orc[$i];
                            push @{ $E{$step}{$a}{$conv}{$Q[$i]}{abs} }, abs($se);
                            push @{ $E{$step}{$a}{$conv}{$Q[$i]}{sig} }, $se;
                            push @row, sprintf('%.6f', $se);
                        }
                    }
                    print $fh join("\t", @row), "\n";
                }
            }
            $n_remaps_total += $remaps;
        }
        close $fh;
        printf "\n[fold] groups of %d=%d (%d merges each) T union remaps=%d of %d merges (%.1f%%) elapsed_s=%.1f\n",
            $fs, $n_groups, $fs - 1, $n_remaps_total, $n_groups * ($fs - 1), ($n_groups ? 100 * $n_remaps_total / ($n_groups * ($fs - 1)) : 0), tv_interval($t);
        printf "%-4s %-3s %-5s %-7s %12s %12s %12s %12s %10s %s\n", 'step', 'arm', 'Q', 'conv', 'p50', 'p95', 'p99', 'max', 'within1bin', 'pass(binning_max<=bound)';
        for my $step (1 .. $fs - 1) {
            for my $a (@arms) {
                for my $q (@Q) {
                    for my $conv (@CONV) {
                        my @s = errstats($E{$step}{$a}{$conv}{$q}{abs}, $E{$step}{$a}{$conv}{$q}{sig}, $bound);
                        my $pass = $conv eq 'int' ? ($s[4] <= $bound + 1e-12 ? 'PASS' : 'FAIL') : '-';
                        printf "%-4d %-3s %-5s %-7s %11.4f%% %11.4f%% %11.4f%% %11.4f%% %9.2f%% %s\n", $step, $a, $QL{$q}, $CONVLABEL{$conv}, 100 * $s[1], 100 * $s[2], 100 * $s[3], 100 * $s[4], 100 * $s[5], $pass;
                        emit_summary($bpd, $bound, "fold$step", $a, $CONVLABEL{$conv}, $q, @s);
                    }
                }
            }
        }
    }
    printf "\nrss_kb now=%d (start %d)\n", Revalidate426::rss_kb(), $rss0;
}
close $SUM;
print "\n", ($exit ? "KEY-SCOPE FAIL (see FAIL lines)" : "DONE"), "\n";
exit $exit;
