#!/usr/bin/env perl
#
# 426-native-span-merge.pl — #426 N2: parity and timing for the native span
# merge (arm S2) against the dense-view arm S and the verbatim arm T.
#
#   --mode parity   hand-built edge cases + consecutive-pair merges + -g fold
#                   digest comparison across T / S / S2
#   --mode timing   merge-pair and -g fold timing for T, S, S2 on one fixture
#
use strict;
use warnings;
use FindBin;
use Getopt::Long;
require "$FindBin::Bin/426-revalidate-lib.pm";

my ($mode, $bpd, $file, $runs, $pairs, $limit) = ('parity', 53, undef, 3, 725, 0);
GetOptions('mode=s' => \$mode, 'bpd=i' => \$bpd, 'file=s' => \$file,
           'runs=i' => \$runs, 'pairs=i' => \$pairs, 'limit=i' => \$limit) or die;

Revalidate426::configure(bpd => $bpd);
my @ARMS = qw(T S S2);
printf "# perl %vd  bpd=%d  mode=%s\n", $^V, $bpd, $mode;

# ---------------------------------------------------------------------------
sub load_pairs {
    my ($f, $lim) = @_;
    my (@k, @d);
    my %o = $lim ? (max_lines => $lim) : ();
    my $c = Revalidate426::iterate_durations($f, sub {
        my (undef, $key, $dur) = @_; push @k, $key; push @d, $dur;
    }, %o);
    printf "# parsed %s: lines=%d matched=%d positive=%d samples=%d\n",
        $f, $c->{lines}, $c->{matched}, $c->{positive}, scalar @k;
    return (\@k, \@d);
}
sub fill { my ($arm,$k,$d) = @_;
    my $st = Revalidate426::store_new($arm, bpd => $bpd);
    $st->add($k->[$_], $d->[$_]) for 0 .. $#$k;
    return $st;
}

# ===========================================================================
if ($mode eq 'parity') {
    my $fail = 0;
    my $report = sub {
        my ($label, %dig) = @_;
        my $ok = ($dig{T} eq $dig{S}) && ($dig{S} eq $dig{S2});
        $fail++ unless $ok;
        printf "%-58s T=%s S=%s S2=%s  %s\n", $label,
            substr($dig{T},0,12), substr($dig{S},0,12), substr($dig{S2},0,12),
            $ok ? 'IDENTICAL' : '*** DIVERGENT ***';
        if (!$ok) {
            printf "    full T  : %s\n    full S  : %s\n    full S2 : %s\n", $dig{T}, $dig{S}, $dig{S2};
        }
        return $ok;
    };

    # --- A. hand-built edge cases -------------------------------------------
    print "\n## A. Hand-built edge cases (merge target<-source, digest of whole store)\n";
    # each case: name => [ [tk-values], [sk-values], drop_source ]
    my @cases = (
        ['A1 empty target (source only)',      [],                       [10,20,30],            0],
        ['A2 empty source (target only)',      [10,20,30],               [],                    0],
        ['A3 both empty',                      [],                       [],                    0],
        ['A4 identical geometry, same values', [10,20,30],               [10,20,30],            0],
        ['A5 disjoint spans (far apart)',      [1,2,3],                  [1e5,2e5,3e5],         0],
        ['A6 source entirely inside target',   [0.01,1,100,10000],       [40,50,60],            0],
        ['A7 target entirely inside source',   [40,50,60],               [0.01,1,100,10000],    0],
        ['A8 union forces rebin (wide src)',   [100,101,102],            [1e-4,1e9],            0],
        ['A9 union forces rebin (wide tgt)',   [1e-4,1e9],               [100,101,102],         0],
        ['A10 single sample each',             [7],                      [7],                   0],
        ['A11 single sample, far apart',       [1e-3],                   [1e6],                 0],
        ['A12 many identical values',          [(5) x 500],              [(5) x 500],           0],
        ['A13 drop_source',                    [10,20,30],               [15,25,35],            1],
        ['A14 12-decade target',               [1e-6,1e-3,1,1e3,1e6],    [500],                 0],
        ['A15 exact powers of ten',            [1,10,100,1000],          [10000,100000],        0],
        ['A16 tiny spread (all one bin)',      [1.0,1.0001,1.0002],      [1.00005],             0],
        ['A17 source after target extend',     [1,2,3,1e8],              [1e-8,5],              0],
        ['A18 both after extends',             [1,1e8,1e-8],             [2,1e7,1e-7],          0],
    );
    for my $c (@cases) {
        my ($name, $tv, $sv, $drop) = @$c;
        my %dig;
        for my $arm (@ARMS) {
            my $st = Revalidate426::store_new($arm, bpd => $bpd);
            $st->add('TGT', $_) for @$tv;
            $st->add('SRC', $_) for @$sv;
            $st->merge('TGT', 'SRC', drop_source => $drop);
            $dig{$arm} = $st->digest;
        }
        $report->($name, %dig);
    }

    # --- A19/A20: merge-then-add, and chained merges -------------------------
    print "\n## A19-A21. Post-merge behaviour (adds and chains after a merge)\n";
    {
        my %dig;
        for my $arm (@ARMS) {
            my $st = Revalidate426::store_new($arm, bpd => $bpd);
            $st->add('TGT', $_) for (10,20,30);
            $st->add('SRC', $_) for (1e-3, 1e5);
            $st->merge('TGT','SRC', drop_source => 1);
            $st->add('TGT', $_) for (15, 1e7, 1e-7, 22);   # forces extend on the merged geometry
            $dig{$arm} = $st->digest;
        }
        $report->('A19 merge, drop source, then add (extend after rebin)', %dig);
    }
    {
        my %dig;
        for my $arm (@ARMS) {
            my $st = Revalidate426::store_new($arm, bpd => $bpd);
            $st->add("K$_", $_ * 3.7 + 1) for 1 .. 20;
            $st->add("K$_", $_ * 91.3)    for 1 .. 20;
            $st->merge('K1', "K$_", drop_source => 1) for 2 .. 20;
            $dig{$arm} = $st->digest;
        }
        $report->('A20 chained fold of 20 keys into one', %dig);
    }
    {
        # empty-target ALIASING probe: adopt then add to BOTH keys.
        my %dig; my %pct;
        for my $arm (@ARMS) {
            my $st = Revalidate426::store_new($arm, bpd => $bpd);
            $st->add('SRC', $_) for (10,20,30);
            $st->merge('TGT','SRC');          # target absent -> adopt path
            $st->add('SRC', 40);              # mutate the SOURCE after the adopt
            $st->add('TGT', 50);
            $dig{$arm} = $st->digest;
            $pct{$arm} = join('/', map { my ($v) = $st->percentile('TGT', $_, 'ceil'); defined $v ? sprintf('%.6g',$v) : 'undef' } (0.5, 0.99));
        }
        my $ok = $report->('A21 ALIASING PROBE: adopt, then add to both keys', %dig);
        printf "    TGT p50/p99 : T=%s  S=%s  S2=%s\n", $pct{T}, $pct{S}, $pct{S2};
        printf "    NOTE: T aliases here (verbatim adopt-by-reference); S and S2 copy.\n" unless $ok;
    }

    # --- B/C. real-fixture pair merges and the -g fold ----------------------
    if ($file) {
        my ($k, $d) = load_pairs($file, $limit);
        print "\n## B. Consecutive-pair merges on the fixture\n";
        my (%dig, %n);
        for my $arm (@ARMS) {
            my $st = fill($arm, $k, $d);
            my @keys = sort { $a cmp $b } $st->keys;
            my $done = 0;
            for (my $i = 0; $i + 1 <= $#keys && $done < $pairs; $i += 2) {
                next unless $st->n($keys[$i]) >= 1 && $st->n($keys[$i+1]) >= 1;
                $st->merge($keys[$i], $keys[$i+1], drop_source => 1);
                $done++;
            }
            $dig{$arm} = $st->digest;
            my $t = 0; $t += $st->n($_) for $st->keys;
            $n{$arm} = $t;
            printf "#   %-3s merges=%d  keys_after=%d  N=%d\n", $arm, $done, scalar($st->keys), $t;
        }
        $report->(sprintf('B pair merges (%d requested)', $pairs), %dig);
        printf "#   N conserved across arms: %s\n",
            ($n{T} == $n{S} && $n{S} == $n{S2}) ? "yes ($n{T})" : "NO ($n{T}/$n{S}/$n{S2})";

        print "\n## C. Full -g fold (every key into the first)\n";
        my (%fdig, %fpct, %fgeo);
        for my $arm (@ARMS) {
            my $st = fill($arm, $k, $d);
            my @keys = sort { $a cmp $b } $st->keys;
            my $acc = shift @keys;
            $st->merge($acc, $_, drop_source => 1) for @keys;
            $fdig{$arm} = $st->digest;
            $fpct{$arm} = join(' ', map { my ($v) = $st->percentile($acc, $_, 'ceil'); sprintf('%.10g', $v) } (0.01,0.5,0.75,0.9,0.95,0.99,0.999));
            my $g = $st->geometry($acc);
            $fgeo{$arm} = sprintf('min=%.17g max=%.17g bins=%d N=%d', $g->{min}, $g->{max}, $g->{bin_count}, $st->n($acc));
            printf "#   %-3s merges=%d  %s\n", $arm, scalar(@keys), $fgeo{$arm};
        }
        $report->('C -g fold digest', %fdig);
        my $pok = ($fpct{T} eq $fpct{S}) && ($fpct{S} eq $fpct{S2});
        $fail++ unless $pok;
        printf "%-58s %s\n", 'C fold percentiles (7 quantiles)', $pok ? 'IDENTICAL' : '*** DIVERGENT ***';
        printf "    T : %s\n    S : %s\n    S2: %s\n", $fpct{T}, $fpct{S}, $fpct{S2} unless $pok;
    }

    print "\n## PARITY RESULT: ", ($fail ? "FAIL ($fail divergence(s))" : "PASS (all cases identical)"), "\n";
    exit($fail ? 2 : 0);
}

# ===========================================================================
if ($mode eq 'timing') {
    die "--file required for timing\n" unless $file;
    my ($k, $d) = load_pairs($file, $limit);
    printf "# runs=%d (median of %d, plus one untimed warmup)\n", $runs, $runs;

    print "\n## Merge pairs\n";
    print "arm\tbpd\tmerges\tmedian_s\tmin_s\tmax_s\tus_per_merge\tdigest\n";
    for my $arm (@ARMS) {
        my ($nm, $dg);
        my @t = Revalidate426::time_runs($runs, sub {
            my $st = fill($arm, $k, $d);
            my @keys = sort { $a cmp $b } $st->keys;
            my $done = 0;
            for (my $i = 0; $i + 1 <= $#keys && $done < $pairs; $i += 2) {
                next unless $st->n($keys[$i]) >= 1 && $st->n($keys[$i+1]) >= 1;
                $st->merge($keys[$i], $keys[$i+1], drop_source => 1);
                $done++;
            }
            $nm = $done; $dg ||= 1;
        });
        # NOTE: time_runs above includes the fill; subtract a fill-only baseline.
        my @f = Revalidate426::time_runs($runs, sub { fill($arm, $k, $d) });
        my ($fm) = Revalidate426::median_min_max(@f);
        my @net = map { $_ - $fm } @t;
        my ($m,$mn,$mx) = Revalidate426::median_min_max(@net);
        printf "%s\t%d\t%d\t%.4f\t%.4f\t%.4f\t%.2f\t%s\n", $arm, $bpd, $nm, $m, $mn, $mx, $m/$nm*1e6, "(see parity)";
    }

    print "\n## -g fold\n";
    print "arm\tbpd\tmerges\tmedian_s\tmin_s\tmax_s\tus_per_merge\tdigest\n";
    for my $arm (@ARMS) {
        my ($nm, $dg);
        my @t = Revalidate426::time_runs($runs, sub {
            my $st = fill($arm, $k, $d);
            my @keys = sort { $a cmp $b } $st->keys;
            my $acc = shift @keys;
            $st->merge($acc, $_, drop_source => 1) for @keys;
            $nm = scalar @keys; $dg ||= 1;
        });
        my @f = Revalidate426::time_runs($runs, sub { fill($arm, $k, $d) });
        my ($fm) = Revalidate426::median_min_max(@f);
        my @net = map { $_ - $fm } @t;
        my ($m,$mn,$mx) = Revalidate426::median_min_max(@net);
        printf "%s\t%d\t%d\t%.4f\t%.4f\t%.4f\t%.2f\t%s\n", $arm, $bpd, $nm, $m, $mn, $mx, $m/$nm*1e6, "(see parity)";
    }
    exit 0;
}
die "unknown mode $mode\n";
