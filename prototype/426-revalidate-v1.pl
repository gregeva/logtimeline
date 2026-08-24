#!/usr/bin/env perl
#
# 426-revalidate-v1.pl — aspect V1 of the #426 revalidation (mirror of #189 V1,
# extended): in-bin edge cases, the R2 cross-check at scale, determinism.
#
#   Part A — hand-computable edge cases for arms T and G (S asserted digest-
#            identical to T on every scenario): the eight #189 V1 scenarios
#            re-read for the grid, powers of ten, 10**(i/bpd) boundary values,
#            tiny/huge values, value 0 and negatives under a guard, identical
#            repeated values.
#   Part B — R2 cross-check on a whole file: G closed-form index vs boundary-
#            checked index at bpd 53/115/256/616 over every observed positive
#            duration (distinct values checked once each); T vs S full-file
#            digest parity at bpd 53 and 616.
#   Part C — determinism (#189 R5): 200 keys with N>=20 fed in file order,
#            reversed, seeded shuffle — per-key canonical + 7 percentiles
#            compared across orderings for T and G; merge(a,b) vs merge(b,a)
#            for 200 consecutive-key pairs, T and G.
#
# Usage:
#   perl prototype/426-revalidate-v1.pl --part A [--bpd 53,616]
#   perl prototype/426-revalidate-v1.pl --part BC --file F [--bpd 53,616]
#       [--check-bpd 53,115,256,616] [--keys 200] [--min-n 20] [--seed 426]
#       [--arm T,S,G] [--out-dir prototype/426-results]
#   --part all runs A then BC. Exit non-zero on any FAIL.
#
# Every arm uses prototype/426-revalidate-lib.pm (production primitives
# verbatim for T; S/G as the library defines them).

use strict;
use warnings;
use FindBin;
use POSIX ();
use List::Util ();
require "$FindBin::Bin/426-revalidate-lib.pm";

my %opt = (part => 'all', file => undef, bpd => '53,616', check_bpd => '53,115,256,616',
           keys => 200, min_n => 20, seed => 426, arm => 'T,S,G', out_dir => "$FindBin::Bin/426-results");
sub usage {
    print <<"EOU";
usage: $0 --part A|BC|all [--file F] [--bpd 53,616] [--check-bpd 53,115,256,616]
          [--keys 200] [--min-n 20] [--seed 426] [--arm T,S,G] [--out-dir DIR]
  --part      A: edge cases (no file needed); BC: cross-check + determinism (needs --file); all
  --file      access log for parts B/C
  --bpd       bpd list for the stores (parity digests, edge cases)
  --check-bpd bpd list for the G index cross-check (part B)
  --keys      number of keys (part C) and pairs (keys+1 keys needed)
  --min-n     minimum N per key for part C
  --seed      srand seed for the shuffled ordering
  --arm       arms to build in parts B/C (T,S,G); part A always runs all three
  --out-dir   where the TSV side files go
EOU
    exit 0;
}
while (@ARGV && $ARGV[0] =~ /^--/) {
    my $o = shift @ARGV;
    if    ($o eq '--help')      { usage() }
    elsif ($o eq '--part')      { $opt{part} = shift @ARGV }
    elsif ($o eq '--file')      { $opt{file} = shift @ARGV }
    elsif ($o eq '--bpd')       { $opt{bpd} = shift @ARGV }
    elsif ($o eq '--check-bpd') { $opt{check_bpd} = shift @ARGV }
    elsif ($o eq '--keys')      { $opt{keys} = shift @ARGV }
    elsif ($o eq '--min-n')     { $opt{min_n} = shift @ARGV }
    elsif ($o eq '--seed')      { $opt{seed} = shift @ARGV }
    elsif ($o eq '--arm')       { $opt{arm} = shift @ARGV }
    elsif ($o eq '--out-dir')   { $opt{out_dir} = shift @ARGV }
    else { die "unknown option $o (try --help)\n" }
}
my @BPDS  = split /,/, $opt{bpd};
my @CBPDS = split /,/, $opt{check_bpd};
my %ARM   = map { $_ => 1 } split /,/, $opt{arm};
my @Q     = (0.01, 0.5, 0.75, 0.9, 0.95, 0.99, 0.999);
my $fail  = 0;
sub ok   { my ($c, $l) = @_; printf "%s %s\n", ($c ? 'PASS' : 'FAIL'), $l; $fail++ unless $c; return $c }
sub note { print "NOTE $_[0]\n" }
sub width { 10 ** (1 / $_[0]) - 1 }
sub fmt  { defined $_[0] ? sprintf('%.10g', $_[0]) : 'undef' }
sub rel  { my ($a, $b) = @_; return (defined $a && defined $b && $b != 0) ? abs($a - $b) / abs($b) : undef }
sub in_bins { my ($r, $bpd) = @_; return defined $r ? $r / width($bpd) : undef }   # relative error in bin widths
sub reset_cfg { my $bpd = shift; Revalidate426::configure(bpd => $bpd, seed_decades => 5, max_rebins => undef) }
sub new_stores { my $bpd = shift; return map { $_ => Revalidate426::store_new($_, bpd => $bpd) } qw(T S G) }
sub add_all { my ($st, $key, @v) = @_; for my $v (@v) { $st->{$_}->add($key, $v) for qw(T S G) } }
sub parity { my ($st, $label) = @_; return ok($st->{T}->digest eq $st->{S}->digest, "$label: T and S digests identical") }
# guarded call: alarm-bounded; returns (outcome, message) where outcome in ok|died|alarm
sub guarded {
    my ($secs, $code) = @_;
    my $r = eval { local $SIG{ALRM} = sub { die "ALARM\n" }; alarm $secs; $code->(); alarm 0; 1 };
    alarm 0;
    return ('ok', '') if $r;
    my $e = $@; chomp $e;
    return ($e eq 'ALARM' ? 'alarm' : 'died', $e);
}

# =============================================================================
# Part A
# =============================================================================
sub part_a {
    print "=== Part A: hand-computable edge cases (arms T, S, G) ===\n";
    for my $bpd (@BPDS) {
        reset_cfg($bpd);
        my $w = width($bpd);
        printf "\n--- bpd=%d (one bin = %.4f%%)\n", $bpd, 100 * $w;

        # A1: bin_count=1 (one observation in one bin) -> T returns upper of that bin; G returns grid upper.
        {
            my %st = new_stores($bpd);
            add_all(\%st, 'k', 100);
            my $e = $st{T}->entry('k');
            my ($where, $i) = Revalidate426::bin_assign($e->{partition}, 100);
            my $upper = Revalidate426::bin_boundary($e->{partition}, $i + 1);
            my $gi = Revalidate426::grid_index(100, $bpd);
            my $gu = Revalidate426::grid_upper($gi, $bpd);
            for my $q (0.5, 0.99) {
                my ($vt, $at) = $st{T}->percentile('k', $q);
                my ($vg, $ag) = $st{G}->percentile('k', $q);
                ok(abs($vt - $upper) <= 1e-9 * $upper && $at eq 'none',
                   sprintf("A1 bpd=%d bin_count=1 q=%s T returns upper of bin %d (%s) audit=%s", $bpd, $q, $i, fmt($vt), $at));
                ok(abs($vg - $gu) <= 1e-9 * $gu && $ag eq 'none',
                   sprintf("A1 bpd=%d bin_count=1 q=%s G returns grid upper of index %d (%s) audit=%s", $bpd, $q, $gi, fmt($vg), $ag));
            }
            my $g = $st{G}->geometry('k');
            ok($g->{span} == 1 && $g->{lo_index} == $gi, "A1 bpd=$bpd G single occupied index: span=$g->{span} lo=$g->{lo_index} (closed form $gi)");
            parity(\%st, "A1 bpd=$bpd");
        }

        # A2: lower=upper. T: synthetic partition (min=max) as #189 V1 did; unreachable through
        # partition_new (min = v0/sqrt(10^5) < max = v0*sqrt(10^5) for any v0 > 0). G: cannot occur —
        # lower = 10**(i/bpd) < upper = 10**((i+1)/bpd) for every integer i and finite bpd.
        {
            my $synth = { min => 1, max => 1, bpd => $bpd, decades => 0, bin_count => 1, log_ratio => 1e-300, rebins => 0 };
            my $entry = { partition => $synth, bins => [3], overflow => 0, underflow => 0 };
            for my $q (0.1, 0.5, 0.9, 0.99) {
                my ($v, $a) = Revalidate426::percentile($entry, $q);
                ok(abs($v - 1) <= 1e-9 && $a eq 'none', "A2 bpd=$bpd lower=upper synthetic T q=$q returns 1 (" . fmt($v) . ")");
            }
            my $p = Revalidate426::partition_new(1, $bpd, 5);
            ok($p->{min} < $p->{max}, sprintf("A2 bpd=%d T lower=upper unreachable via partition_new: min=%s < max=%s", $bpd, fmt($p->{min}), fmt($p->{max})));
            my $mono = 1;
            for my $i (-2000 .. 2000) { $mono = 0 unless Revalidate426::grid_lower($i, $bpd) < Revalidate426::grid_upper($i, $bpd) }
            ok($mono, "A2 bpd=$bpd G lower=upper cannot occur: 10**(i/bpd) < 10**((i+1)/bpd) for i in [-2000,2000] (vacuous on the grid)");
        }

        # A3: single observation via add: T -> upper of the bin holding 42; G -> grid upper.
        {
            my %st = new_stores($bpd);
            add_all(\%st, 'single', 42);
            my $e = $st{T}->entry('single');
            my (undef, $i) = Revalidate426::bin_assign($e->{partition}, 42);
            my $upper = Revalidate426::bin_boundary($e->{partition}, $i + 1);
            my ($vt) = $st{T}->percentile('single', 0.5);
            my $gi = Revalidate426::grid_index(42, $bpd);
            my ($vg) = $st{G}->percentile('single', 0.5);
            ok(abs($vt - $upper) <= 1e-9 * $upper, sprintf("A3 bpd=%d single observation T q=0.5 -> upper of bin %d = %s (v=42, rel %.4f%%)", $bpd, $i, fmt($vt), 100 * rel($vt, 42)));
            ok(abs($vg - Revalidate426::grid_upper($gi, $bpd)) <= 1e-9 * $vg, sprintf("A3 bpd=%d single observation G q=0.5 -> grid upper of %d = %s (rel %.4f%%)", $bpd, $gi, fmt($vg), 100 * rel($vg, 42)));
            parity(\%st, "A3 bpd=$bpd");
        }

        # A4: fraction=0 unreachable — property of the walk (target_rank <= cum), identical in T and G.
        note "A4 bpd=$bpd fraction=0 unreachable in both walks (target_rank <= cum => rank_in_bin in [1,c]); G's walk is the same code shape";

        # A5: zero-count. T: entry with empty bins -> (undef,'none'); store-level unknown key -> (undef,'none') in all arms.
        {
            my $entry = { partition => Revalidate426::partition_new(1, $bpd, 5), bins => [], overflow => 0, underflow => 0 };
            my ($v, $a) = Revalidate426::percentile($entry, 0.5);
            ok(!defined $v && $a eq 'none', "A5 bpd=$bpd zero-count T entry -> (undef,'none')");
            my %st = new_stores($bpd);
            my $all = 1;
            for my $arm (qw(T S G)) { my ($vv, $aa) = $st{$arm}->percentile('nokey', 0.5); $all = 0 if defined $vv || $aa ne 'none' }
            ok($all, "A5 bpd=$bpd zero-count store key -> (undef,'none') in T, S, G");
            # G: a row whose span was emptied is not constructible through add(); the only empty-span
            # row is one created by merge from an empty source — not reachable either (source must exist).
            note "A5 bpd=$bpd G has no partition state to be zero-count; a key exists only after its first add";
        }

        # A6/A7: all-overflow / all-underflow. T (a) direct entry as #189 V1; (b) via the store under
        # max_rebins=0: seed at 1, then 5 values far above -> overflow=5 of N=6. G with the same inputs.
        for my $side (qw(over under)) {
            my $entry = { partition => Revalidate426::partition_new(1, $bpd, 5), bins => [], overflow => 0, underflow => 0 };
            my $p = $entry->{partition};
            if ($side eq 'over') { $entry->{overflow} = 5 } else { $entry->{underflow} = 4 }
            my $q = $side eq 'over' ? 0.9 : 0.1;
            my ($v, $a) = Revalidate426::percentile($entry, $q);
            my $bnd = Revalidate426::bin_boundary($p, $side eq 'over' ? $p->{bin_count} : 0);
            ok(abs($v - $bnd) <= 1e-9 * $bnd && $a eq ($side eq 'over' ? 'high' : 'low'),
               sprintf("A6/7 bpd=%d all-%sflow direct T entry q=%s -> boundary %s audit=%s", $bpd, $side, $q, fmt($v), $a));

            Revalidate426::configure(max_rebins => 0);
            my %st = new_stores($bpd);
            my @vals = $side eq 'over' ? (1, (1e6) x 5) : (1, (1e-6) x 5);
            add_all(\%st, 'k', @vals);
            my $g = $st{T}->geometry('k');
            my ($vt, $at) = $st{T}->percentile('k', $q);
            my ($vg, $ag) = $st{G}->percentile('k', $q);
            my $expect_bnd = Revalidate426::bin_boundary($st{T}->entry('k')->{partition}, $side eq 'over' ? $g->{bin_count} : 0);
            ok($g->{$side . 'flow'} == 5 && $g->{rebins} == 0 && abs($vt - $expect_bnd) <= 1e-9 * $expect_bnd && $at eq ($side eq 'over' ? 'high' : 'low'),
               sprintf("A6/7 bpd=%d store cap=0 seed 1 + 5x%s: T %sflow=%d rebins=%d q=%s -> %s audit=%s", $bpd, $vals[1], $side, $g->{$side . 'flow'}, $g->{rebins}, $q, fmt($vt), $at));
            my $gg = $st{G}->geometry('k');
            my $target = $vals[1];
            my $gi = Revalidate426::grid_index($target, $bpd);
            ok($ag eq 'none' && abs($vg - $target) <= $w * $target + 1e-9,
               sprintf("A6/7 bpd=%d same inputs G: span=%d [%d..%d] q=%s -> %s audit=%s (within one bin of %s; index %d)", $bpd, $gg->{span}, $gg->{lo_index}, $gg->{hi_index}, $q, fmt($vg), $ag, $target, $gi));
            parity(\%st, "A6/7 bpd=$bpd $side cap=0");
            # T's answer vs the true value: error in bin widths
            printf "INFO A6/7 bpd=%d %sflow: T returns %s for a true q=%s value of %s (rel err %.3g = %.1f bins); G rel err %.3g\n",
                $bpd, $side, fmt($vt), $q, $target, rel($vt, $target), in_bins(rel($vt, $target), $bpd), rel($vg, $target);
            reset_cfg($bpd);
        }

        # A8: powers of ten — closed-form index, boundary-checked index, and where the percentile lands.
        print "\nA8 bpd=$bpd powers of ten: value | closed i | checked i | lower(closed) upper(closed) | v in [lower,upper)? | G q=0.5 (single add) | T bin (single add) T q=0.5\n";
        my $pow_mismatch = 0;
        for my $v (1, 10, 100, 1000, 1e4, 1e5, 1e6, 1e9) {
            my $ci = Revalidate426::grid_index($v, $bpd);
            my ($ki, $corr) = Revalidate426::grid_index_checked($v, $bpd);
            my ($lo, $up) = (Revalidate426::grid_lower($ci, $bpd), Revalidate426::grid_upper($ci, $bpd));
            my $inside = ($lo <= $v && $v < $up) ? 'yes' : 'NO';
            my %st = new_stores($bpd);
            add_all(\%st, 'p', $v);
            my ($vg) = $st{G}->percentile('p', 0.5);
            my $e = $st{T}->entry('p');
            my (undef, $ti) = Revalidate426::bin_assign($e->{partition}, $v);
            my ($vt) = $st{T}->percentile('p', 0.5);
            $pow_mismatch++ if $corr;
            printf "A8 bpd=%d %-6g | %5d | %5d%s | %.10g %.10g | %s | %.10g (rel %+.4f%%) | bin %d %.10g (rel %+.4f%%)\n",
                $bpd, $v, $ci, $ki, ($corr ? '*' : ' '), $lo, $up, $inside, $vg, 100 * ($vg - $v) / $v, $ti, $vt, 100 * ($vt - $v) / $v;
        }
        print "INFO A8 bpd=$bpd powers of ten with closed-form != boundary-checked: $pow_mismatch of 8\n";

        # A9: values exactly at 10**(i/bpd) boundaries.
        my @is = $bpd == 53 ? (1, 7, 53, 100, 106, 159, 200, 265) : $bpd == 616 ? (1, 7, 616, 1000, 1232, 1848, 3000, 3080) : (1, 7, $bpd, 2 * $bpd, 3 * $bpd);
        print "\nA9 bpd=$bpd boundary values v=10**(i/bpd): i | v | closed i | checked i | G q=0.5 rel err | T bin | T q=0.5 rel err\n";
        my ($b_ok, $b_bad) = (0, 0);
        for my $i (@is) {
            my $v = 10 ** ($i / $bpd);
            my $ci = Revalidate426::grid_index($v, $bpd);
            my ($ki, $corr) = Revalidate426::grid_index_checked($v, $bpd);
            my %st = new_stores($bpd);
            add_all(\%st, 'b', $v);
            my ($vg) = $st{G}->percentile('b', 0.5);
            my $e = $st{T}->entry('b');
            my (undef, $ti) = Revalidate426::bin_assign($e->{partition}, $v);
            my ($vt) = $st{T}->percentile('b', 0.5);
            if ($ci == $i) { $b_ok++ } else { $b_bad++ }
            printf "A9 bpd=%d i=%-4d | %.12g | %5d | %5d%s | %+.4f%% | %d | %+.4f%%\n", $bpd, $i, $v, $ci, $ki, ($corr ? '*' : ' '), 100 * ($vg - $v) / $v, $ti, 100 * ($vt - $v) / $v;
        }
        print "INFO A9 bpd=$bpd boundary values: closed form == i for $b_ok, != i for $b_bad of " . scalar(@is) . "\n";
        ok(1, "A9 bpd=$bpd boundary values recorded (informational; the G store uses the closed form, both neighbours are within one bin)");

        # A10: tiny / huge values — separately and in one key.
        {
            print "\nA10 bpd=$bpd tiny/huge single-key adds: value | G index | T seed min..max bin_count | T q=0.5 | G q=0.5\n";
            for my $v (1e-3, 1e-6, 1e12) {
                my %st = new_stores($bpd);
                add_all(\%st, 'x', $v);
                my $g = $st{T}->geometry('x');
                my ($vt) = $st{T}->percentile('x', 0.5);
                my ($vg) = $st{G}->percentile('x', 0.5);
                printf "A10 bpd=%d %-6g | %6d | %.6g..%.6g %d | %.6g | %.6g\n", $bpd, $v, Revalidate426::grid_index($v, $bpd), $g->{min}, $g->{max}, $g->{bin_count}, $vt, $vg;
                parity(\%st, "A10 bpd=$bpd v=$v");
            }
            my %st = new_stores($bpd);
            add_all(\%st, 'wide', 1e-6, 1e-3, 1, 1e12);
            my $g = $st{T}->geometry('wide');
            my $gg = $st{G}->geometry('wide');
            printf "A10 bpd=%d one key {1e-6,1e-3,1,1e12}: T min=%.6g max=%.6g bin_count=%d rebins=%d over=%d under=%d; G span=%d [%d..%d] slots; memory T=%d S=%d G=%d\n",
                $bpd, @$g{qw(min max bin_count rebins overflow underflow)}, $gg->{span}, $gg->{lo_index}, $gg->{hi_index}, map { $st{$_}->memory_bytes } qw(T S G);
            my @orc = Revalidate426::oracle_percentiles([1e-6, 1e-3, 1, 1e12], \@Q);
            my ($worst_t, $worst_g) = (0, 0);
            for my $j (0 .. $#Q) {
                my ($vt) = $st{T}->percentile('wide', $Q[$j], 'int');
                my ($vg) = $st{G}->percentile('wide', $Q[$j], 'int');
                my ($rt, $rg) = (rel($vt, $orc[$j]), rel($vg, $orc[$j]));
                $worst_t = List::Util::max($worst_t, $rt); $worst_g = List::Util::max($worst_g, $rg);
                printf "A10 bpd=%d q=%-5s oracle=%-6g T=%.6g (%.2f bins) G=%.6g (%.2f bins)\n", $bpd, $Q[$j], $orc[$j], $vt, in_bins($rt, $bpd), $vg, in_bins($rg, $bpd);
            }
            ok($worst_g <= $w + 1e-12, sprintf("A10 bpd=%d wide-range key: G every quantile within one bin (max %.2f bins); T max %.2f bins after %d rebins (recorded, not asserted)", $bpd, in_bins($worst_g, $bpd), in_bins($worst_t, $bpd), $g->{rebins}));
            parity(\%st, "A10 bpd=$bpd wide");
        }

        # A11: value 0 and negative, guarded. (a) as the first sample (partition_new / grid_index);
        # (b) on an existing partition (partition_extend's doubling loop) and existing G row.
        {
            print "\nA11 bpd=$bpd value 0 and negative under a 5 s alarm guard\n";
            for my $v (0, -5) {
                for my $arm (qw(T S G)) {
                    my $st = Revalidate426::store_new($arm, bpd => $bpd);
                    my ($o1, $m1) = guarded(5, sub { $st->add('z', $v) });
                    my $st2 = Revalidate426::store_new($arm, bpd => $bpd);
                    $st2->add('z', 100);
                    my ($o2, $m2) = guarded(5, sub { $st2->add('z', $v) });
                    my $g2 = $st2->has('z') ? $st2->geometry('z') : {};
                    printf "A11 bpd=%d %s v=%-3g first-sample: %-5s %s | on existing partition(100): %-5s %s%s\n", $bpd, $arm, $v, $o1, ($m1 || '-'), $o2, ($m2 || '-'),
                        ($arm ne 'G' && $o2 eq 'ok' ? sprintf(' [min=%.3g max=%.3g rebins=%d under=%d]', @$g2{qw(min max rebins underflow)}) : '');
                    ok($o1 ne 'ok' && $o2 ne 'ok', "A11 bpd=$bpd $arm v=$v: never accepted silently (first-sample $o1, existing $o2)" . ($o1 eq 'alarm' || $o2 eq 'alarm' ? " -- UNBOUNDED LOOP, alarm fired" : ""));
                }
            }
            # Loop replica (NOT the verbatim sub): how many doubling steps partition_extend's while
            # loop takes before new_min underflows to 0 for value 0 / negative, starting from the seed of 100.
            my $p = Revalidate426::partition_new(100, $bpd, 5);
            my ($m, $n) = ($p->{min}, 0);
            my $factor = 10 ** ($p->{decades} / 2);
            while (0 < $m && $n < 100000) { $m /= $factor; $n++ }
            printf "INFO A11 bpd=%d loop replica: from seed min=%.4g the doubling loop reaches new_min=0 after %d steps (then log(new_max/0) dies); negative values take the same path\n", $bpd, $p->{min}, $n;
        }

        # A12: identical repeated value, N=1,2,1000 — every quantile within one bin (both conventions).
        {
            for my $N (1, 2, 1000) {
                my %st = new_stores($bpd);
                add_all(\%st, 'rep', (250) x $N);
                my ($worst_t, $worst_g) = (0, 0);
                for my $conv (qw(ceil int)) {
                    for my $q (@Q) {
                        my ($vt) = $st{T}->percentile('rep', $q, $conv);
                        my ($vg) = $st{G}->percentile('rep', $q, $conv);
                        $worst_t = List::Util::max($worst_t, rel($vt, 250));
                        $worst_g = List::Util::max($worst_g, rel($vg, 250));
                    }
                }
                my $gt = $st{T}->geometry('rep'); my $gg = $st{G}->geometry('rep');
                ok($worst_t <= $w + 1e-12 && $worst_g <= $w + 1e-12,
                   sprintf("A12 bpd=%d %d x 250: T max rel err %.4f%% (%.2f bins, %d occupied bin), G max rel err %.4f%% (%.2f bins, span %d)", $bpd, $N,
                           100 * $worst_t, in_bins($worst_t, $bpd), scalar($st{T}->bins_pairs('rep')), 100 * $worst_g, in_bins($worst_g, $bpd), $gg->{span}));
                parity(\%st, "A12 bpd=$bpd N=$N");
            }
        }
    }
    reset_cfg($BPDS[0]);
}

# =============================================================================
# Parts B and C — one read of the file
# =============================================================================
sub part_bc {
    die "--part BC needs --file\n" unless defined $opt{file} && -f $opt{file};
    (my $fx = $opt{file}) =~ s{.*/}{};
    print "\n=== Part B/C on $fx ===\n";
    my (%samples, %distinct);
    my $t0 = time;
    my $counts = Revalidate426::iterate_durations($opt{file}, sub {
        my ($cat, $key, $d) = @_;
        push @{ $samples{"$cat\x1f$key"} }, $d;
        $distinct{$d}++;
    }, count_keys => 1);
    printf "file: %s format=%s lines=%d matched=%d unparsed=%d no_duration=%d positive=%d zero=%d negative=%d keys_any=%d keys_positive=%d distinct_values=%d read_s=%d\n",
        $fx, $counts->{format}, @$counts{qw(lines matched unparsed no_duration positive zero negative keys_any keys_positive)}, scalar(keys %distinct), time - $t0;

    # ---- Part B1: G closed-form vs boundary-checked on every distinct value, weighted by occurrences
    print "\n--- Part B1: G closed-form index vs boundary-checked index\n";
    open(my $tsv, '>', "$opt{out_dir}/revalidate-v1-r2-offenders.tsv") or die $!;
    print {$tsv} join("\t", qw(bpd value occurrences closed_i checked_i lower_closed upper_closed reason)), "\n";
    for my $bpd (@CBPDS) {
        my ($n_vals, $n_obs, $bad_vals, $bad_obs, $bound_fail) = (0, 0, 0, 0, 0);
        my (@offenders, %reason);
        for my $v (sort { $a <=> $b } keys %distinct) {
            my $ci = Revalidate426::grid_index($v, $bpd);
            my ($ki, $corr) = Revalidate426::grid_index_checked($v, $bpd);
            $n_vals++; $n_obs += $distinct{$v};
            $bound_fail++ unless Revalidate426::grid_lower($ki, $bpd) <= $v && $v < Revalidate426::grid_upper($ki, $bpd);
            next unless $corr;
            $bad_vals++; $bad_obs += $distinct{$v};
            my $reason = ($v == 10 ** int(log($v) / log(10) + 0.5) && abs(log($v) / log(10) - int(log($v) / log(10) + 0.5)) < 1e-12) ? 'exact power of ten' : 'float near-boundary';
            $reason{$reason}++;
            push @offenders, sprintf("%g(x%d, closed %d -> checked %d, %s)", $v, $distinct{$v}, $ci, $ki, $reason);
            print {$tsv} join("\t", $bpd, $v, $distinct{$v}, $ci, $ki, Revalidate426::grid_lower($ci, $bpd), Revalidate426::grid_upper($ci, $bpd), $reason), "\n";
        }
        printf "B1 bpd=%d distinct values=%d observations=%d disagreements: %d distinct values / %d observations (%s); bound holds after check on all: %s\n",
            $bpd, $n_vals, $n_obs, $bad_vals, $bad_obs, join(', ', map { "$_=$reason{$_}" } sort keys %reason) || 'none', ($bound_fail == 0 ? 'yes' : "NO ($bound_fail)");
        print "B1 bpd=$bpd offenders: " . (join('; ', @offenders) || 'none') . "\n";
        ok($bound_fail == 0, "B1 bpd=$bpd boundary-checked index satisfies 10**(i/bpd) <= v < 10**((i+1)/bpd) on every distinct value");
    }
    close $tsv;

    # ---- Part B2: T vs S full-file digest parity at each --bpd (and G digest for the record)
    print "\n--- Part B2: full-file digests\n";
    my @keys_sorted = sort keys %samples;
    for my $bpd (@BPDS) {
        reset_cfg($bpd);
        my %st = map { $_ => Revalidate426::store_new($_, bpd => $bpd) } grep { $ARM{$_} } qw(T S G);
        my $rss0 = Revalidate426::rss_kb();
        for my $k (@keys_sorted) { for my $v (@{ $samples{$k} }) { $_->add($k, $v) for values %st } }
        my $rss1 = Revalidate426::rss_kb();
        printf "B2 bpd=%d digests %s keys %s rss_delta_kb=%d memory_bytes %s\n", $bpd,
            join(' ', map { "$_=" . $st{$_}->digest } sort keys %st), join(' ', map { "$_=" . scalar($st{$_}->keys) } sort keys %st), $rss1 - $rss0,
            join(' ', map { "$_=" . $st{$_}->memory_bytes } sort keys %st);
        if ($st{T} && $st{S}) {
            ok($st{T}->digest eq $st{S}->digest, "B2 bpd=$bpd T and S full-file digests identical");
            my $tel = $st{T}->telemetry;
            printf "B2 bpd=%d T telemetry: partitions=%d rebin_events=%d max_bins=%d over=%d under=%d rebins p50=%d p95=%d p99=%d max=%d\n", $bpd,
                @$tel{qw(partition_count total_rebin_events max_partition_bins overflow_total underflow_total rebins_p50 rebins_p95 rebins_p99 rebins_max)};
        }
        if ($st{G}) {
            my $tg = $st{G}->telemetry;
            printf "B2 bpd=%d G telemetry: partitions=%d span p50=%d p95=%d p99=%d max=%d index_range=[%d,%d]\n", $bpd, @$tg{qw(partition_count span_p50 span_p95 span_p99 span_max index_min index_max)};
        }
    }

    # ---- Part C: determinism
    print "\n--- Part C: determinism (#189 R5)\n";
    my @elig = grep { @{ $samples{$_} } >= $opt{min_n} } @keys_sorted;
    my $nk = $opt{keys};
    die "only " . scalar(@elig) . " keys with N>=$opt{min_n}; need " . ($nk + 1) . "\n" if @elig < $nk + 1;
    my @ck = @elig[0 .. $nk];   # nk+1 keys: nk for orderings, nk consecutive pairs
    printf "C keys: %d eligible with N>=%d; using first %d (sorted key order) for orderings, %d consecutive pairs; N range %d..%d; seed %d\n",
        scalar(@elig), $opt{min_n}, $nk, $nk, List::Util::min(map { scalar @{ $samples{$_} } } @ck), List::Util::max(map { scalar @{ $samples{$_} } } @ck), $opt{seed};
    open(my $ctsv, '>', "$opt{out_dir}/revalidate-v1-determinism.tsv") or die $!;
    print {$ctsv} join("\t", qw(bpd arm test key_or_pair N canonical_same max_rel_diff max_bins)), "\n";
    for my $bpd (@BPDS) {
        reset_cfg($bpd);
        for my $arm (grep { $ARM{$_} } qw(T G)) {
            # C1: orderings
            my ($dep_canon, $dep_pct, $max_rel, $n_cmp) = (0, 0, 0, 0);
            my ($geom_dep, $rebin_keys) = (0, 0);
            for my $j (0 .. $nk - 1) {
                my $k = $ck[$j];
                my @s = @{ $samples{$k} };
                srand($opt{seed});
                my @sh = List::Util::shuffle(@s);
                my (%canon, %pct, %geo);
                for my $ord (['file', \@s], ['reversed', [reverse @s]], ['shuffled', \@sh]) {
                    my $st = Revalidate426::store_new($arm, bpd => $bpd);
                    $st->add($k, $_) for @{ $ord->[1] };
                    $canon{ $ord->[0] } = $st->canonical($k);
                    $pct{ $ord->[0] }   = [ map { ($st->percentile($k, $_))[0] } @Q ];
                    $geo{ $ord->[0] }   = $st->geometry($k);
                }
                my $same = ($canon{file} eq $canon{reversed} && $canon{file} eq $canon{shuffled}) ? 1 : 0;
                $dep_canon++ unless $same;
                my $kmax = 0;
                for my $o (qw(reversed shuffled)) {
                    for my $i (0 .. $#Q) { my $r = rel($pct{$o}[$i], $pct{file}[$i]) // 0; $kmax = $r if $r > $kmax; $n_cmp++ }
                }
                $dep_pct++ if $kmax > 1e-12;
                $max_rel = $kmax if $kmax > $max_rel;
                if ($arm eq 'T') {
                    my $gsame = join(',', map { sprintf('%.17g/%.17g/%d', @{ $geo{$_} }{qw(min max bin_count)}) } qw(file reversed shuffled));
                    my @gg = split /,/, $gsame;
                    $geom_dep++ unless $gg[0] eq $gg[1] && $gg[0] eq $gg[2];
                    $rebin_keys++ if List::Util::max(map { $geo{$_}{rebins} } qw(file reversed shuffled)) > 0;
                }
                print {$ctsv} join("\t", $bpd, $arm, 'ordering', $j, scalar(@s), $same, sprintf('%.6g', $kmax), sprintf('%.3f', in_bins($kmax, $bpd))), "\n";
            }
            printf "C1 bpd=%d %s orderings: %d keys; canonical order-dependent: %d; percentiles order-dependent (>1e-12): %d; max rel diff %.4g%% = %.3f bins%s\n",
                $bpd, $arm, $nk, $dep_canon, $dep_pct, 100 * $max_rel, in_bins($max_rel, $bpd),
                ($arm eq 'T' ? sprintf("; geometry (min/max/bin_count) order-dependent: %d; keys that rebinned in some ordering: %d", $geom_dep, $rebin_keys) : '');
            ok($arm eq 'G' ? ($dep_canon == 0 && $dep_pct == 0) : 1,
               $arm eq 'G' ? "C1 bpd=$bpd G is order-independent (0 canonical, 0 percentile differences)"
                           : sprintf("C1 bpd=%d T order dependence recorded: %d/%d keys canonical-different, max percentile diff %.3f bins (R5 holds for a fixed sequence; the geometry is seeded by the first sample)", $bpd, $dep_canon, $nk, in_bins($max_rel, $bpd)));
            ok($max_rel <= width($bpd) + 1e-12, sprintf("C1 bpd=%d %s ordering percentile differences bounded by one bin width (max %.3f bins)", $bpd, $arm, in_bins($max_rel, $bpd)));

            # C2: merge commutativity on consecutive pairs
            my ($pdep_canon, $pdep_bins, $pdep_pct, $pmax) = (0, 0, 0, 0);
            for my $j (0 .. $nk - 1) {
                my ($a, $b) = @ck[$j, $j + 1];
                my (%canon, %pct, %bins);
                for my $dir (['ab', $a, $b], ['ba', $b, $a]) {
                    my $st = Revalidate426::store_new($arm, bpd => $bpd);
                    for my $k ($a, $b) { $st->add($k, $_) for @{ $samples{$k} } }
                    $st->merge($dir->[1], $dir->[2], drop_source => 1);
                    my $t = $dir->[1];
                    $canon{ $dir->[0] } = $st->canonical($t);
                    $pct{ $dir->[0] }   = [ map { ($st->percentile($t, $_))[0] } @Q ];
                    # geometry-independent comparison for T: bins as absolute boundary pairs
                    if ($arm eq 'T') {
                        my $e = $st->entry($t); my $p = $e->{partition};
                        $bins{ $dir->[0] } = join(',', map { sprintf('%.12g:%d', Revalidate426::bin_boundary($p, $_), $e->{bins}[$_]) } grep { $e->{bins}[$_] } 0 .. $#{ $e->{bins} })
                                           . sprintf('|%.12g/%.12g/%d|o%d|u%d', $p->{min}, $p->{max}, $p->{bin_count}, $e->{overflow}, $e->{underflow});
                    } else { $bins{ $dir->[0] } = join(',', $st->bins_pairs($t)) }
                }
                my $same = $canon{ab} eq $canon{ba} ? 1 : 0;
                $pdep_canon++ unless $same;
                $pdep_bins++ unless $bins{ab} eq $bins{ba};
                my $kmax = 0;
                for my $i (0 .. $#Q) { my $r = rel($pct{ab}[$i], $pct{ba}[$i]) // 0; $kmax = $r if $r > $kmax }
                $pdep_pct++ if $kmax > 1e-12;
                $pmax = $kmax if $kmax > $pmax;
                print {$ctsv} join("\t", $bpd, $arm, 'merge', "$j,$j+1", scalar(@{ $samples{$a} }) + scalar(@{ $samples{$b} }), $same, sprintf('%.6g', $kmax), sprintf('%.3f', in_bins($kmax, $bpd))), "\n";
            }
            printf "C2 bpd=%d %s merge(a,b) vs merge(b,a): %d pairs; canonical differs: %d; bins+geometry differ: %d; percentiles differ (>1e-12): %d; max rel diff %.4g%% = %.3f bins\n",
                $bpd, $arm, $nk, $pdep_canon, $pdep_bins, $pdep_pct, 100 * $pmax, in_bins($pmax, $bpd);
            ok($pdep_bins == 0 && $pdep_pct == 0, "C2 bpd=$bpd $arm merge is commutative on bins and percentiles ($pdep_canon canonical-string differences)");
        }
    }
    close $ctsv;
    reset_cfg($BPDS[0]);
}

part_a()  if $opt{part} =~ /^(A|all)$/i;
part_bc() if $opt{part} =~ /^(BC|all)$/i;
print "\n", ($fail ? "FAILURES: $fail" : "ALL PASS"), "\n";
exit($fail ? 1 : 0);
