#!/usr/bin/env perl
#
# 426-revalidate-v3.pl — #426 revalidation, aspect V3 (mirror of #189 V3):
# seeding heuristic, span growth, overflow/underflow audit, against the three
# arms of prototype/426-revalidate-lib.pm:
#   T  today's per-key partitions (verbatim primitives)
#   S  span-only columnar, verbatim geometry (P8+P9) — must equal T
#   G  shared log-spaced grid, span-only (P10) — no seed / rebin / over- /
#      underflow: the aspect becomes the span-growth and out-of-range story.
#
# Parts:
#   A  real data (--file, default the #189 V3 277 MB Tomcat file): T rebin
#      telemetry (reproduces #189 partitions 4153 / rebins 7 / p99 0 / max 1)
#      beside G's per-key span distribution and global index range; per key
#      G span slots vs T bin_count; sum of spans vs sum of bin_counts; memory
#      (Devel::Size + RSS delta) and build time per arm (one arm per process
#      when --arm names one arm; --arm all builds every arm in one process and
#      does the per-key comparison + the T/S parity digest).
#   B  pathological scenarios from #189 V3 (extreme high / extreme low / mixed)
#      under T cap 0 (overflow/underflow path), T no cap (auto-resize), S both
#      (parity asserted), G; a 12-decade key; the 1..1e9 worst case.
#   C  non-positive value behaviour of every arm (log(0) / negative).
#
# Usage:
#   perl prototype/426-revalidate-v3.pl --part A --arm all --bpd 53,616 [--file F] [--runs N] [--per-key TSV]
#   perl prototype/426-revalidate-v3.pl --part A --arm T --bpd 53 --runs 3
#   perl prototype/426-revalidate-v3.pl --part B --bpd 53,616
#   perl prototype/426-revalidate-v3.pl --part C
# Exit status: non-zero on any T/S divergence or failed expectation.

use strict;
use warnings;
use FindBin;
use POSIX ();
use Devel::Size ();
use Time::HiRes qw(gettimeofday tv_interval);
use Getopt::Long qw(GetOptions);
require "$FindBin::Bin/426-revalidate-lib.pm";
$| = 1;

# eval with a wall-clock guard: returns (1) on success, (0, "DIES: msg") on die,
# (0, "HANGS: no return within Ns") when the call does not return (Part C).
sub guarded {
    my ($secs, $code) = @_;
    my $r = eval { local $SIG{ALRM} = sub { die "ALARM\n" }; alarm $secs; $code->(); alarm 0; 1 };
    alarm 0;
    return 1 if $r;
    return (0, $@ eq "ALARM\n" ? "HANGS: no return within ${secs}s (infinite loop)" : "DIES: " . ($@ =~ s/\s+$//r));
}

my %opt = (
    file    => "$FindBin::Bin/../logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt",
    bpd     => '53',
    arm     => 'all',
    part    => 'all',
    runs    => 1,
    'per-key' => undef,
    'max-lines' => undef,
    help    => 0,
);
GetOptions(\%opt, 'file=s', 'bpd=s', 'arm=s', 'part=s', 'runs=i', 'per-key=s', 'max-lines=i', 'help')
    or die_usage();
die_usage() if $opt{help};
sub die_usage {
    print <<"USAGE";
usage: $0 [--part A|B|C|all] [--arm T|S|G|all] [--bpd 53,616] [--file F]
          [--runs N] [--per-key out.tsv] [--max-lines N]
  --part     A = real-data seeding/span telemetry; B = pathological scenarios;
             C = non-positive value behaviour; all = A,B,C (default all)
  --arm      which arm(s) Part A builds; 'all' also runs the T/S digest
             assertion and the per-key T-vs-G span comparison (default all)
  --bpd      comma list of buckets-per-decade (default 53)
  --file     input log (Tomcat access or ThingWorx application log)
  --runs     timed build runs per arm after one untimed warmup (Part A)
  --per-key  Part A --arm all: write per-key TSV (n, T bin_count, T rebins,
             T bins array length, G span, G lo/hi index, G occupied bins)
USAGE
    exit 1;
}

my @BPDS = split /,/, $opt{bpd};
my @ARMS = $opt{arm} eq 'all' ? qw(T S G) : (split /,/, $opt{arm});
die "arm must be T|S|G|all\n" if grep { !/^[TSG]$/ } @ARMS;
my $fail = 0;
sub ok { my ($cond, $line) = @_; printf "%s %s\n", ($cond ? 'PASS' : 'FAIL'), $line; $fail++ unless $cond; return $cond }
sub fmt_bytes { my $b = shift; return sprintf('%d (%.2f MB)', $b, $b / 1048576) }
sub percentile_of { my ($q, @v) = @_; my @s = sort { $a <=> $b } @v; return 0 unless @s; my $i = int(@s * $q); $i = $#s if $i > $#s; return $s[$i] }
sub key_label { my $k = shift; $k =~ s/\x1f/ | /g; return $k }

# =============================================================================
# Part A — real data
# =============================================================================
sub part_a {
    print "=== Part A: seeding / span growth on real data ===\n";
    printf "file: %s\n", $opt{file};
    printf "arms: %s   bpd: %s   runs: %d\n\n", join(',', @ARMS), join(',', @BPDS), $opt{runs};

    for my $bpd (@BPDS) {
        Revalidate426::configure(bpd => $bpd, seed_decades => 5, max_rebins => undef);
        printf "--- bpd=%d (one bin = %.4f%%)\n", $bpd, 100 * (10 ** (1 / $bpd) - 1);
        my %st;
        my %build_secs;
        my $counts;
        for my $arm (@ARMS) {
            # Warmup build (untimed): also the build we keep and measure memory on.
            my $rss0 = Revalidate426::rss_kb();
            my $t0 = [gettimeofday];
            my $s = Revalidate426::store_new($arm, bpd => $bpd);
            $counts = Revalidate426::iterate_durations($opt{file}, sub { $s->add("$_[0]\x1f$_[1]", $_[2]) },
                                                       count_keys => 1, max_lines => $opt{'max-lines'});
            my $warm = tv_interval($t0);
            my $rss1 = Revalidate426::rss_kb();
            $st{$arm} = $s;
            my @secs;
            for (1 .. $opt{runs}) {
                my $t1 = [gettimeofday];
                my $s2 = Revalidate426::store_new($arm, bpd => $bpd);
                Revalidate426::iterate_durations($opt{file}, sub { $s2->add("$_[0]\x1f$_[1]", $_[2]) }, max_lines => $opt{'max-lines'});
                push @secs, tv_interval($t1);
                undef $s2;
            }
            if (@secs) {
                my ($med, $mn, $mx) = Revalidate426::median_min_max(@secs);
                printf "arm %s build: warmup %.3fs; timed runs=%d median %.3fs (min %.3f max %.3f) — parse+add, one arm per store\n",
                    $arm, $warm, scalar @secs, $med, $mn, $mx;
            } else {
                printf "arm %s build: single untimed build %.3fs (no timed runs requested)\n", $arm, $warm;
            }
            printf "arm %s memory: Devel::Size=%s  RSS delta=%d kB (%.2f MB) [rss %d -> %d kB]\n",
                $arm, fmt_bytes($s->memory_bytes), $rss1 - $rss0, ($rss1 - $rss0) / 1024, $rss0, $rss1;
        }
        printf "file counts: format=%s lines=%d matched=%d unparsed=%d no_duration=%d positive=%d zero=%d negative=%d keys_any=%d keys_positive=%d\n",
            $counts->{format}, @$counts{qw(lines matched unparsed no_duration positive zero negative keys_any keys_positive)};

        for my $arm (grep { /[TS]/ } @ARMS) {
            my $t = $st{$arm}->telemetry;
            printf "%s telemetry: partitions_total=%d total_rebin_events=%d max_partition_bins=%d partitions_with_overflow=%d partitions_with_underflow=%d overflow_total=%d underflow_total=%d rebins_per_partition: p50=%d p95=%d p99=%d max=%d counter_memory_bytes=%d\n",
                $arm, @$t{qw(partition_count total_rebin_events max_partition_bins partitions_with_overflow_count partitions_with_underflow_count overflow_total underflow_total rebins_p50 rebins_p95 rebins_p99 rebins_max counter_memory_bytes)};
            my $with = grep { $st{$arm}->geometry($_)->{rebins} > 0 } $st{$arm}->keys;
            printf "%s partitions_with_rebins=%d (%.4f%%)  Decision 5 healthy-seed signal (p99 <= 2): %s\n",
                $arm, $with, 100 * $with / ($t->{partition_count} || 1), ($t->{rebins_p99} <= 2 ? 'PASS' : 'FAIL');
        }
        if ($st{G}) {
            my $g = $st{G}->telemetry;
            printf "G telemetry: partitions_total=%d span_slots: p50=%d p95=%d p99=%d max=%d index_range=[%d,%d] (%.2f decades) counter_memory_bytes=%d\n",
                @$g{qw(partition_count span_p50 span_p95 span_p99 span_max index_min index_max)},
                ($g->{index_max} - $g->{index_min} + 1) / $bpd, $g->{counter_memory_bytes};
        }
        if ($st{T} && $st{S}) {
            my ($dT, $dS) = ($st{T}->digest, $st{S}->digest);
            ok($dT eq $dS, "bpd=$bpd T and S digests identical ($dT)");
            my $tt = $st{T}->telemetry; my $ts = $st{S}->telemetry;
            my $same = join(',', map { $tt->{$_} } grep { $_ ne 'counter_memory_bytes' } sort keys %$tt)
                    eq join(',', map { $ts->{$_} } grep { $_ ne 'counter_memory_bytes' } sort keys %$ts);
            ok($same, "bpd=$bpd T and S telemetry identical (rebins/overflow/underflow/bins fields)");
        }
        if ($st{T} && $st{G}) {
            my ($n_keys, $g_larger, $g_equal, $sum_bc, $sum_len, $sum_span, $sum_occ, $g_larger_len) = (0) x 8;
            my (@ratio, @rows);
            my ($seed_bc) = int($bpd * 5);
            my ($n_seed, $n_grown) = (0, 0);
            my %span_over_seed;
            for my $k ($st{T}->keys) {
                my $tg = $st{T}->geometry($k);
                my $gg = $st{G}->geometry($k);
                my $len = scalar @{ $st{T}->entry($k)->{bins} };
                my $occ = scalar($st{G}->bins_pairs($k));
                $n_keys++;
                $g_larger++ if $gg->{span} > $tg->{bin_count};
                $g_larger_len++ if $gg->{span} > $len;
                $g_equal++  if $gg->{span} == $tg->{bin_count};
                $sum_bc  += $tg->{bin_count};
                $sum_len += $len;
                $sum_span += $gg->{span};
                $sum_occ  += $occ;
                push @ratio, $gg->{span} / $tg->{bin_count};
                $tg->{bin_count} == $seed_bc ? $n_seed++ : $n_grown++;
                $span_over_seed{$k} = 1 if $gg->{span} > $seed_bc;
                push @rows, [ $k, $st{T}->n($k), $tg->{bin_count}, $tg->{rebins}, $len, $gg->{span}, $gg->{lo_index}, $gg->{hi_index}, $occ ];
            }
            printf "per-key T vs G (bpd=%d): keys=%d; T bin_count==seed(%d)=%d, grown=%d; G span > T bin_count: %d keys; G span == T bin_count: %d; G span > T bins array length: %d\n",
                $bpd, $n_keys, $seed_bc, $n_seed, $n_grown, $g_larger, $g_equal, $g_larger_len;
            printf "per-key T vs G (bpd=%d): G span > seed bin_count (%d): %d keys\n", $bpd, $seed_bc, scalar keys %span_over_seed;
            printf "totals (bpd=%d): sum T bin_count=%d; sum T bins array length=%d; sum G span slots=%d; sum G occupied bins=%d; G/T slot ratio=%.4f (span/bin_count), %.4f (span/array length)\n",
                $bpd, $sum_bc, $sum_len, $sum_span, $sum_occ, $sum_span / $sum_bc, $sum_span / $sum_len;
            printf "span/bin_count ratio per key: p50=%.4f p95=%.4f p99=%.4f max=%.4f\n",
                map { percentile_of($_, @ratio) } 0.5, 0.95, 0.99, 1;
            my @top = (sort { $b->[5] <=> $a->[5] || $a->[0] cmp $b->[0] } @rows)[0 .. 4];
            print "5 widest G spans (n, T bin_count, T rebins, T bins len, G span, G lo..hi, occupied): \n";
            printf "  %s | n=%d T bc=%d rb=%d len=%d | G span=%d lo=%d hi=%d occ=%d\n", key_label(substr($_->[0], 0, 90)), @$_[1 .. 8] for @top;
            my @rebinned = grep { $_->[3] > 0 } @rows;
            print "keys T rebinned (n, T bin_count, T rebins, T bins len, G span, G lo..hi, occupied):\n";
            printf "  %s | n=%d T bc=%d rb=%d len=%d | G span=%d lo=%d hi=%d occ=%d\n", key_label(substr($_->[0], 0, 90)), @$_[1 .. 8]
                for sort { $a->[0] cmp $b->[0] } @rebinned;
            if ($opt{'per-key'}) {
                (my $f = $opt{'per-key'}) =~ s/\.tsv$//;
                $f .= "-bpd$bpd.tsv";
                open(my $fh, '>', $f) or die "cannot write $f: $!";
                print {$fh} join("\t", qw(key n t_bin_count t_rebins t_bins_len g_span g_lo g_hi g_occupied)) . "\n";
                print {$fh} join("\t", key_label($_->[0]), @$_[1 .. 8]) . "\n" for sort { $a->[0] cmp $b->[0] } @rows;
                close $fh;
                print "per-key TSV: $f\n";
            }
        }
        print "\n";
    }
}

# =============================================================================
# Part B — pathological scenarios
# =============================================================================
my @Q_AUDIT = (0.001, 0.5, 0.999);

sub build_scenario {          # -> { T_cap, T_nocap, S_cap, S_nocap, G } stores + samples
    my ($bpd, $values) = @_;
    my %st;
    for my $spec ([ 'T_cap', 'T', 0 ], [ 'S_cap', 'S', 0 ], [ 'T_nocap', 'T', undef ], [ 'S_nocap', 'S', undef ], [ 'G', 'G', undef ]) {
        my ($name, $arm, $cap) = @$spec;
        Revalidate426::configure(bpd => $bpd, seed_decades => 5, max_rebins => $cap);
        my $s = Revalidate426::store_new($arm, bpd => $bpd);
        $s->add('k', $_) for @$values;
        $st{$name} = $s;
    }
    Revalidate426::configure(max_rebins => undef);
    return \%st;
}

sub entry_bytes {
    my ($s) = @_;
    return $s->arm eq 'T' ? Devel::Size::total_size($s->entry('k')) : $s->memory_bytes;
}

sub report_scenario {
    my ($name, $bpd, $values, $qs, $expect) = @_;
    printf "Scenario: %s (bpd=%d, N=%d)\n", $name, $bpd, scalar @$values;
    my $st = build_scenario($bpd, $values);
    my @orc = Revalidate426::oracle_percentiles($values, $qs);
    printf "  oracle exact (nearest-rank): %s\n", join('  ', map { sprintf('q%g=%.6g', $qs->[$_], $orc[$_]) } 0 .. $#$qs);
    # parity S == T in both cap states
    for my $c (qw(cap nocap)) {
        my ($ct, $cs) = ($st->{"T_$c"}->canonical('k'), $st->{"S_$c"}->canonical('k'));
        ok($ct eq $cs, "  [$name bpd=$bpd $c] S canonical == T canonical");
    }
    my %audit_seen;
    for my $arm (qw(T_cap T_nocap G)) {
        my $s = $st->{$arm};
        my $g = $s->geometry('k');
        my $bins = $s->arm eq 'G' ? $s->{bins}[ $s->{row}{k} ] : $s->entry('k')->{bins};
        my $slots = $s->arm eq 'G' ? $g->{span} : scalar @$bins;
        my $bytes = entry_bytes($s);
        if ($s->arm eq 'G') {
            printf "  %-8s span_slots=%d grid_index=[%d,%d] occupied=%d bytes=%d (no partition state; no overflow/underflow counters)\n",
                $arm, $g->{span}, $g->{lo_index}, $g->{hi_index}, scalar($s->bins_pairs('k')), $bytes;
        } else {
            printf "  %-8s partition min=%.6g max=%.6g bin_count=%d rebins=%d bins_array_len=%d overflow=%d underflow=%d bytes=%d\n",
                $arm, @$g{qw(min max bin_count rebins)}, $slots, @$g{qw(overflow underflow)}, $bytes;
        }
        my @cells;
        for my $j (0 .. $#$qs) {
            my ($v, $a) = $s->percentile('k', $qs->[$j], 'ceil');
            my $err = defined $v && $orc[$j] ? 100 * ($v - $orc[$j]) / $orc[$j] : 0;
            push @cells, sprintf('q%g=%.6g[%s,%+.2f%%]', $qs->[$j], $v, $a, $err);
            $audit_seen{$arm}{$a}++;
        }
        printf "  %-8s R4 ceil-rank (value[audit,err vs exact]): %s\n", $arm, join('  ', @cells);
    }
    if ($expect) {
        my $a = $audit_seen{T_cap};
        ok(($expect->{high} ? ($a->{high} // 0) > 0 : ($a->{high} // 0) == 0) && ($expect->{low} ? ($a->{low} // 0) > 0 : ($a->{low} // 0) == 0),
           sprintf("  [$name bpd=$bpd] T cap 0 audit across q=%s: {%s} expected high=%d low=%d (#189 V3)",
                   join('/', @$qs), join(',', map { "$_=$a->{$_}" } sort keys %$a), $expect->{high}, $expect->{low}));
        ok(!grep({ $_ ne 'none' } keys %{ $audit_seen{T_nocap} }), "  [$name bpd=$bpd] T no cap: every audit 'none' (auto-resize contained every value)");
    }
    ok(!grep({ $_ ne 'none' } keys %{ $audit_seen{G} }), "  [$name bpd=$bpd] G: every audit 'none' (structural)");
    print "\n";
    return $st;
}

sub warmup_values {           # deterministic replacement for #189 V3's rand(): v0*(0.5 .. 1.5)
    my ($v0) = @_;
    return map { $v0 * (0.5 + $_ / 1000) } 0 .. 999;
}

sub part_b {
    print "=== Part B: pathological scenarios (#189 V3 Part B under T cap 0 / T no cap / S parity / G) ===\n";
    print "warmup: 1000 deterministic values v0*(0.5 + j/1000), j=0..999 (#189 used rand); outliers appended after warmup.\n\n";
    for my $bpd (@BPDS) {
        printf "--- bpd=%d (one bin = %.4f%%)\n\n", $bpd, 100 * (10 ** (1 / $bpd) - 1);
        report_scenario('extreme high outlier (v0=100; 1e6,1e7,1e8)', $bpd,
                        [ warmup_values(100), 1e6, 1e7, 1e8 ], \@Q_AUDIT, { high => 1, low => 0 });
        report_scenario('extreme low outlier (v0=10000; 0.5,0.1,0.01)', $bpd,
                        [ warmup_values(10000), 0.5, 0.1, 0.01 ], \@Q_AUDIT, { high => 0, low => 1 });
        report_scenario('mixed scale (v0=1000; 50 x 1e-3, 50 x 1e8)', $bpd,
                        [ warmup_values(1000), (1e-3) x 50, (1e8) x 50 ], \@Q_AUDIT, { high => 1, low => 1 });
        # 12-decade key: 1000 near 100 then one sample per decade 1e-3..1e9
        my @dec = map { 10 ** $_ } -3 .. 9;
        report_scenario('12-decade key (1000 near 100 first, then 1e-3..1e9 ascending)', $bpd,
                        [ warmup_values(100), @dec ], [ 0.001, 0.5, 0.999 ]);
        report_scenario('12-decade key (1e-3..1e9 ascending first, then 1000 near 100)', $bpd,
                        [ @dec, warmup_values(100) ], [ 0.001, 0.5, 0.999 ]);
        report_scenario('12-decade key (1e9 first, then 1e8..1e-3 descending, then 1000 near 100)', $bpd,
                        [ reverse(@dec), warmup_values(100) ], [ 0.001, 0.5, 0.999 ]);
        print "\n";
    }
    # Worst case arithmetic: integer ms durations 1..1e9 at the top tier.
    print "--- worst case: integer ms durations spanning 1..1e9 ---\n";
    for my $bpd (@BPDS) {
        my $lo = Revalidate426::grid_index(1, $bpd);
        my $hi = Revalidate426::grid_index(1e9, $bpd);
        printf "bpd=%d closed form: grid_index(1)=%d grid_index(1e9)=%d -> max G span slots = %d (= 9 decades x %d + 1)\n",
            $bpd, $lo, $hi, $hi - $lo + 1, $bpd;
        # Fill every grid slot: one value per bin at its geometric midpoint, plus the endpoints.
        my @fill = (1, 1e9, map { 10 ** (($_ + 0.5) / $bpd) } $lo .. $hi);
        for my $first (1, 1000, 1e9) {
            my @vals = ($first, grep { $_ != $first } @fill);
            my %st;
            for my $arm (qw(T S G)) {
                Revalidate426::configure(bpd => $bpd, seed_decades => 5, max_rebins => undef);
                my $s = Revalidate426::store_new($arm, bpd => $bpd);
                $s->add('k', $_) for @vals;
                $st{$arm} = $s;
            }
            ok($st{T}->canonical('k') eq $st{S}->canonical('k'), "  [worst bpd=$bpd first=$first] S canonical == T canonical");
            my $tg = $st{T}->geometry('k'); my $gg = $st{G}->geometry('k');
            my $tlen = scalar @{ $st{T}->entry('k')->{bins} };
            printf "  first=%-5g N=%d | T: min=%.6g max=%.6g decades=%.2f bin_count=%d rebins=%d bins_array_len=%d occupied=%d bytes(entry)=%d bytes(S columns)=%d | G: span_slots=%d occupied=%d bytes=%d | G/T slots=%.3f bytes=%.3f\n",
                $first, scalar @vals, @$tg{qw(min max)}, log($tg->{max} / $tg->{min}) / log(10), @$tg{qw(bin_count rebins)}, $tlen,
                scalar($st{T}->bins_pairs('k')), entry_bytes($st{T}), $st{S}->memory_bytes,
                $gg->{span}, scalar($st{G}->bins_pairs('k')), entry_bytes($st{G}),
                $gg->{span} / $tg->{bin_count}, entry_bytes($st{G}) / entry_bytes($st{T});
        }
        # Sparse variant: only the two endpoints (span grows to full width, slots between are zero/undef).
        my %st;
        for my $arm (qw(T G)) {
            Revalidate426::configure(bpd => $bpd, seed_decades => 5, max_rebins => undef);
            my $s = Revalidate426::store_new($arm, bpd => $bpd);
            $s->add('k', $_) for (1, 1e9);
            $st{$arm} = $s;
        }
        my $tg = $st{T}->geometry('k'); my $gg = $st{G}->geometry('k');
        printf "  endpoints only (1 then 1e9): T bin_count=%d rebins=%d bins_array_len=%d bytes=%d | G span_slots=%d occupied=2 bytes=%d\n",
            @$tg{qw(bin_count rebins)}, scalar @{ $st{T}->entry('k')->{bins} }, entry_bytes($st{T}), $gg->{span}, entry_bytes($st{G});
        %st = ();
        for my $arm (qw(T G)) {
            Revalidate426::configure(bpd => $bpd, seed_decades => 5, max_rebins => undef);
            my $s = Revalidate426::store_new($arm, bpd => $bpd);
            $s->add('k', $_) for (1e9, 1);
            $st{$arm} = $s;
        }
        $tg = $st{T}->geometry('k'); $gg = $st{G}->geometry('k');
        printf "  endpoints only (1e9 then 1): T bin_count=%d rebins=%d bins_array_len=%d bytes=%d | G span_slots=%d occupied=2 bytes=%d (downward growth splices real zeros)\n",
            @$tg{qw(bin_count rebins)}, scalar @{ $st{T}->entry('k')->{bins} }, entry_bytes($st{T}), $gg->{span}, entry_bytes($st{G});
    }
    print "\n";
}

# =============================================================================
# Part C — non-positive values
# =============================================================================
sub part_c {
    print "=== Part C: non-positive values in every arm (caller guard today: ltl skips duration <= 0 before counter_update) ===\n";
    my $bpd = $BPDS[0];
    for my $v (0, -1, 1e-320, 1e308) {
        printf "value=%g\n", $v;
        my $gi = eval { Revalidate426::grid_index($v, $bpd) };
        printf "  grid_index(%g,%d): %s\n", $v, $bpd, defined $gi ? "index=$gi" : "DIES: " . ($@ =~ s/\s+$//r);
        for my $arm (qw(T S G)) {
            Revalidate426::configure(bpd => $bpd, seed_decades => 5, max_rebins => undef);
            my $s = Revalidate426::store_new($arm, bpd => $bpd);
            my ($r, $why) = guarded(5, sub { $s->add('k', $v) });
            my $msg = $r ? 'accepted' : $why;
            my $extra = '';
            if ($r) {
                my $g = $s->geometry('k');
                $extra = $arm eq 'G' ? " geometry lo=$g->{lo_index} hi=$g->{hi_index} span=$g->{span}"
                                     : sprintf(" geometry min=%g max=%g bin_count=%d over=%d under=%d", @$g{qw(min max bin_count overflow underflow)});
                my ($pv, $pa);
                my ($pr, $pwhy) = guarded(5, sub { ($pv, $pa) = $s->percentile('k', 0.5) });
                $extra .= !$pr ? " p50=$pwhy" : defined $pv ? sprintf(" p50=%g[%s]", $pv, $pa) : ' p50=undef';
                # then a normal value on the same key
                my ($r2, $why2) = guarded(5, sub { $s->add('k', 100) });
                $extra .= $r2 ? ' then add(100): accepted' : " then add(100): $why2";
            }
            printf "  %s add: %s%s\n", $arm, $msg, $extra;
        }
        # value after a healthy key
        for my $arm (qw(T S G)) {
            Revalidate426::configure(bpd => $bpd, seed_decades => 5, max_rebins => undef);
            my $s = Revalidate426::store_new($arm, bpd => $bpd);
            $s->add('k', 100);
            my ($r, $why) = guarded(5, sub { $s->add('k', $v) });
            my $g = $s->geometry('k');
            printf "  %s add after add(100): %s; n=%d %s\n", $arm, ($r ? 'accepted' : $why), $s->n('k'),
                $arm eq 'G' ? "lo=$g->{lo_index} hi=$g->{hi_index} span=$g->{span}"
                            : sprintf("min=%g max=%g bin_count=%d rebins=%d over=%d under=%d", @$g{qw(min max bin_count rebins overflow underflow)});
        }
    }
    print "\n";
}

my $part = uc $opt{part};
part_a() if $part eq 'ALL' || $part eq 'A';
part_b() if $part eq 'ALL' || $part eq 'B';
part_c() if $part eq 'ALL' || $part eq 'C';
print $fail ? "FAILURES: $fail\n" : "ALL PASS\n";
exit($fail ? 1 : 0);
