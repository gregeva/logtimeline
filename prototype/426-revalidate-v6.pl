#!/usr/bin/perl
#
# 426-revalidate-v6.pl — V6 aspect of the #426 revalidation: the
# display-geometry-bound consumers (F2 heatmap, F3 histogram) under the
# proposed representations.
#
# The #189 validation aspects V1-V5 covered the per-key percentile surface.
# They did not cover the two surfaces whose counters finalize into DISPLAY
# GEOMETRY: #187 Decision 5's F2/F3 stream -> finalize contract, executed in
# ltl by finalize_heatmap_unified() and finalize_histogram_unified() through
# #189 R12's partition_rebin(). This aspect covers them.
#
# What is measured, per arm (T = today verbatim, S = span-only columns with
# verbatim geometry, G = shared log-spaced grid):
#
#   Part A  Finalize parity  — T vs S finalized display bins must be
#           IDENTICAL (S is a re-containering of T's arithmetic; any
#           difference is a defect in S, not a fidelity trade).
#   Part B  Fidelity of each arm's finalized display against the EXACT
#           distribution, using #201's own measures:
#             - mass retention        (no observation lost or double-counted)
#             - peak retention        (peak cell height vs exact)
#             - peak X-offset         (#201's spike-position drift, in cells)
#             - empty-cell count      (#201's gap-toothed failure)
#             - per-cell total abs deviation from exact
#   Part C  Where the divergence comes from: the overflow/underflow fold.
#           T and S fold streamed out-of-range mass into the edge display
#           cells (finalize_heatmap_unified, "Fold streaming over/underflow
#           into the edge bins"); G has no out-of-range state, so it places
#           that mass by value. Reported separately so the two mechanisms
#           are not conflated.
#
# Both display geometries are exercised with ltl's own target shapes:
#   heatmap   bin_count = $heatmap_width (default 52), range [min,max] observed
#   histogram bin_count = calculate_histogram_bucket_count(min,max)
#             = int(decades * 8 + 0.5), min 5   (verbatim from ltl)
#
# Usage:
#   perl prototype/426-revalidate-v6.pl --file <log> [--bpd 616] [--width 52]
#                                       [--max-lines N] [--out <dir>]
use strict;
use warnings;
use POSIX ();
use FindBin;
require "$FindBin::Bin/426-revalidate-lib.pm";

my %opt = (bpd => 616, width => 52, out => undef, 'max-lines' => undef, file => undef,
           hgbpd => 8, keyed => 0, 'bucket-lines' => 5000);
while (@ARGV) {
    my $a = shift @ARGV;
    if ($a =~ /^--(\w[\w-]*)$/ && exists $opt{$1}) { $opt{$1} = shift @ARGV }
    elsif ($a =~ /^--(\w[\w-]*)=(.*)$/ && exists $opt{$1}) { $opt{$1} = $2 }
    else { die "unknown argument: $a\n" }
}
die "--file is required\n" unless defined $opt{file};
die "file not readable: $opt{file}\n" unless -r $opt{file};

my $BPD = $opt{bpd} + 0;
my $W   = $opt{width} + 0;
Revalidate426::configure(bpd => $BPD);

# =============================================================================
# ltl's target-geometry helpers, verbatim
# =============================================================================

# VERBATIM from ltl calculate_histogram_bucket_count() (no override path: the
# prototype never sets $histogram_bucket_override).
sub histogram_bucket_count {
    my ($min, $max) = @_;
    $min = 0.1 if $min <= 0;
    $max = $min * 10 if $max <= $min;
    my $decades = (log($max) - log($min)) / log(10);
    my $bucket_count = int($decades * $opt{hgbpd} + 0.5);
    $bucket_count = 5 if $bucket_count < 5;
    return ($bucket_count, $decades);
}

# VERBATIM from ltl partition_rebin() — the R12 finalize step. Arms T and S
# both reach the display through this sub; it is copied rather than called
# through the store so the finalize path is identical for both.
sub bin_boundary_p { my ($p,$i)=@_; return $p->{min} * exp($p->{log_ratio} * $i / $p->{bin_count}) }
sub partition_rebin_verbatim {
    my ($p, $src_bins, $new_min, $new_max, $new_bin_count) = @_;
    my $new_log_ratio = log($new_max / $new_min);
    my @new_bins;
    for my $old_i (0 .. $p->{bin_count} - 1) {
        my $count = $src_bins->[$old_i];
        next unless defined $count && $count > 0;
        my $lower    = bin_boundary_p($p, $old_i);
        my $upper    = bin_boundary_p($p, $old_i + 1);
        my $midpoint = sqrt($lower * $upper);
        my $new_i    = int($new_bin_count * log($midpoint / $new_min) / $new_log_ratio);
        $new_i = 0                  if $new_i < 0;
        $new_i = $new_bin_count - 1 if $new_i >= $new_bin_count;
        $new_bins[$new_i] = ($new_bins[$new_i] // 0) + $count;
    }
    for my $i (0 .. $new_bin_count - 1) { $new_bins[$i] //= 0 }
    return \@new_bins;
}

# The G equivalent of R12: project a grid span into display geometry using the
# SAME geometric-midpoint rule. A grid bin i spans [10**(i/bpd), 10**((i+1)/bpd)),
# whose geometric midpoint is exactly 10**((i+0.5)/bpd) — so the projection is
# the identical formula with the grid's own boundaries. There is no
# over/underflow to fold: the grid has no bounded range.
sub grid_rebin {
    my ($span, $bpd, $new_min, $new_max, $new_bin_count) = @_;
    my $new_log_ratio = log($new_max / $new_min);
    my @new_bins;
    my $base = $span->[0];
    for my $j (1 .. $#$span) {
        my $count = $span->[$j];
        next unless defined $count && $count > 0;
        my $gi       = $base + $j - 1;
        my $midpoint = 10 ** (($gi + 0.5) / $bpd);
        my $new_i    = int($new_bin_count * log($midpoint / $new_min) / $new_log_ratio);
        $new_i = 0                  if $new_i < 0;
        $new_i = $new_bin_count - 1 if $new_i >= $new_bin_count;
        $new_bins[$new_i] = ($new_bins[$new_i] // 0) + $count;
    }
    for my $i (0 .. $new_bin_count - 1) { $new_bins[$i] //= 0 }
    return \@new_bins;
}

# The exact reference: every observation placed into the display cell that
# holds its own value. This is what the display WOULD show with no binning
# substrate at all — the fidelity target both #201 and this aspect measure
# against.
sub exact_display {
    my ($values, $new_min, $new_max, $new_bin_count) = @_;
    my $lr = log($new_max / $new_min);
    my @bins = (0) x $new_bin_count;
    for my $v (@$values) {
        my $i = int($new_bin_count * log($v / $new_min) / $lr);
        $i = 0                  if $i < 0;
        $i = $new_bin_count - 1 if $i >= $new_bin_count;
        $bins[$i]++;
    }
    return \@bins;
}

# =============================================================================
# Fidelity measures — #201's own, plus mass conservation
# =============================================================================
sub measures {
    my ($got, $exact) = @_;
    my $n = scalar @$exact;
    my ($gsum, $esum) = (0, 0);
    $gsum += $_ for @$got;
    $esum += $_ for @$exact;
    my ($gpeak, $gpi, $epeak, $epi) = (-1, -1, -1, -1);
    for my $i (0 .. $n - 1) {
        if ($got->[$i]   > $gpeak) { $gpeak = $got->[$i];   $gpi = $i }
        if ($exact->[$i] > $epeak) { $epeak = $exact->[$i]; $epi = $i }
    }
    my ($absdiff, $cells_differ, $maxcell) = (0, 0, 0);
    for my $i (0 .. $n - 1) {
        my $d = abs($got->[$i] - $exact->[$i]);
        $absdiff += $d;
        $cells_differ++ if $d;
        $maxcell = $d if $d > $maxcell;
    }
    return {
        mass            => $gsum,
        mass_exact      => $esum,
        mass_retention  => $esum ? $gsum / $esum : 1,
        peak            => $gpeak,
        peak_exact      => $epeak,
        peak_retention  => $epeak ? $gpeak / $epeak : 1,
        peak_col        => $gpi,
        peak_col_exact  => $epi,
        peak_x_offset   => abs($gpi - $epi),
        empty_cells     => scalar(grep { $_ == 0 } @$got),
        empty_exact     => scalar(grep { $_ == 0 } @$exact),
        cells_differ    => $cells_differ,
        abs_dev         => $absdiff,
        abs_dev_pct     => $esum ? 100 * $absdiff / $esum : 0,
        max_cell_dev    => $maxcell,
    };
}

# =============================================================================
# Build the three arms over one keyed surface, then finalize
# =============================================================================
# The display surfaces key by TIME BUCKET (heatmap) and by METRIC (histogram).
# This prototype exercises the geometry, not the keying: it builds ONE
# partition per arm over all observations (the histogram's global-per-metric
# keying) and, separately, the per-key case is covered by V1-V5. Keying is
# added in the driver by partitioning the value stream.

my @values;
my %by_bucket;      # heatmap-shaped keying: one partition per time bucket
my $obs_seq = 0;
my $BUCKET_LINES = $opt{'bucket-lines'} + 0;
my $counts = Revalidate426::iterate_durations(
    $opt{file},
    sub {
        my (undef, undef, $d) = @_;
        push @values, $d;
        # Time buckets are contiguous runs of the input, which is chronological:
        # this reproduces the heatmap's per-time-bucket partition keying and its
        # per-key value distribution (each bucket sees its own value range) without
        # depending on this prototype re-implementing ltl's timestamp parsing.
        push @{ $by_bucket{ int($obs_seq / $BUCKET_LINES) } }, $d;
        $obs_seq++;
    },
    (defined $opt{'max-lines'} ? (max_lines => $opt{'max-lines'} + 0) : ()),
);

die "no positive durations parsed from $opt{file}\n" unless @values;

printf "file            %s\n", $opt{file};
printf "format          %s\n", $counts->{format} // '?';
printf "lines           %d  matched %d  positive %d  unparsed %d\n",
    $counts->{lines}, $counts->{matched}, $counts->{positive}, $counts->{unparsed};
printf "observations    %d\n", scalar @values;
printf "bpd             %d   (streaming resolution, both T/S and G)\n", $BPD;

my ($vmin, $vmax) = ($values[0], $values[0]);
for my $v (@values) { $vmin = $v if $v < $vmin; $vmax = $v if $v > $vmax }
printf "observed range  [%.6g, %.6g]  (%.3f decades)\n",
    $vmin, $vmax, (log($vmax) - log($vmin)) / log(10);

# --- build each arm through the store interface (verbatim primitives) -------
my %store;
for my $arm (qw(T S G)) {
    my $st = Revalidate426::store_new($arm, bpd => $BPD);
    $st->add('_all', $_) for @values;
    $store{$arm} = $st;
}
printf "N per arm       T=%d S=%d G=%d\n",
    $store{T}->n('_all'), $store{S}->n('_all'), $store{G}->n('_all');

my $tgeo = $store{T}->geometry('_all');
printf "T geometry      min=%.6g max=%.6g bins=%d rebins=%d over=%d under=%d\n",
    $tgeo->{min}, $tgeo->{max}, $tgeo->{bin_count}, $tgeo->{rebins},
    $tgeo->{overflow}, $tgeo->{underflow};
my $ggeo = $store{G}->geometry('_all');
printf "G geometry      grid indices [%d, %d]  span=%d\n",
    $ggeo->{lo_index}, $ggeo->{hi_index}, $ggeo->{span};

# --- finalize each arm into both display geometries ------------------------
sub finalize_arm {
    my ($arm, $new_min, $new_max, $bin_count) = @_;
    if ($arm eq 'G') {
        my $i    = $store{G}{row}{'_all'};
        my $span = $store{G}{bins}[$i];
        return grid_rebin($span, $BPD, $new_min, $new_max, $bin_count);
    }
    # T and S both present an ltl-shape entry {partition,bins,overflow,underflow}
    my $e = $store{$arm}->entry('_all');
    my $fin = partition_rebin_verbatim($e->{partition}, $e->{bins},
                                       $new_min, $new_max, $bin_count);
    # Verbatim from finalize_heatmap_unified / finalize_histogram_unified.
    my $pre_fold = [ @$fin ];
    $fin->[0]              += $e->{underflow} // 0;
    $fin->[$bin_count - 1] += $e->{overflow}  // 0;
    return ($fin, $pre_fold, ($e->{overflow} // 0), ($e->{underflow} // 0));
}

my @geometries = (
    { name => 'heatmap',   min => ($vmin > 0 ? $vmin : 1), max => $vmax, bins => $W },
);
{
    my ($bc, $dec) = histogram_bucket_count($vmin, $vmax);
    push @geometries, { name => 'histogram', min => ($vmin <= 0 ? 0.1 : $vmin),
                        max => $vmax, bins => $bc, decades => $dec };
}

my @rows;
for my $geo (@geometries) {
    print "\n";
    printf "=== %s display geometry: bins=%d range [%.6g, %.6g] ===\n",
        $geo->{name}, $geo->{bins}, $geo->{min}, $geo->{max};

    my $exact = exact_display(\@values, $geo->{min}, $geo->{max}, $geo->{bins});

    my %fin; my %prefold; my %flow;
    for my $arm (qw(T S G)) {
        if ($arm eq 'G') {
            $fin{G} = finalize_arm('G', $geo->{min}, $geo->{max}, $geo->{bins});
            $prefold{G} = $fin{G};
            $flow{G} = [0, 0];
        } else {
            my ($f, $pf, $o, $u) = finalize_arm($arm, $geo->{min}, $geo->{max}, $geo->{bins});
            $fin{$arm} = $f; $prefold{$arm} = $pf; $flow{$arm} = [$o, $u];
        }
    }

    # Part A — T vs S finalize parity (must be identical)
    my $parity_ok = 1; my $first_bad;
    for my $i (0 .. $geo->{bins} - 1) {
        if ($fin{T}[$i] != $fin{S}[$i]) { $parity_ok = 0; $first_bad = $i; last }
    }
    printf "PART A  T vs S finalized display bins: %s%s\n",
        ($parity_ok ? "IDENTICAL (all $geo->{bins} cells)" : "DIFFER"),
        ($parity_ok ? "" : sprintf(" first at cell %d: T=%d S=%d",
                                   $first_bad, $fin{T}[$first_bad], $fin{S}[$first_bad]));

    # Part B — fidelity of each arm against exact
    printf "PART B  fidelity against the exact display (%d observations)\n", scalar @values;
    printf "  %-4s %10s %10s %8s %8s %8s %8s %10s %8s\n",
        'arm', 'mass', 'mass_ret', 'peak_ret', 'peak_dx', 'empty', 'exact_e', 'abs_dev%', 'maxcell';
    for my $arm (qw(T S G)) {
        my $m = measures($fin{$arm}, $exact);
        printf "  %-4s %10d %10.6f %8.4f %8d %8d %8d %10.4f %8d\n",
            $arm, $m->{mass}, $m->{mass_retention}, $m->{peak_retention},
            $m->{peak_x_offset}, $m->{empty_cells}, $m->{empty_exact},
            $m->{abs_dev_pct}, $m->{max_cell_dev};
        push @rows, { geometry => $geo->{name}, arm => $arm, bins => $geo->{bins},
                      %$m, overflow => $flow{$arm}[0], underflow => $flow{$arm}[1] };
    }

    # Part C — how much of T/S's divergence is the out-of-range fold
    for my $arm (qw(T S)) {
        my ($o, $u) = @{ $flow{$arm} };
        next unless $o || $u;
        my $m_pre  = measures($prefold{$arm}, $exact);
        my $m_post = measures($fin{$arm},     $exact);
        printf "PART C  %s out-of-range fold: overflow=%d underflow=%d (%.4f%% of mass)\n",
            $arm, $o, $u, 100 * ($o + $u) / scalar(@values);
        printf "        abs deviation from exact: %.4f%% before the fold -> %.4f%% after\n",
            $m_pre->{abs_dev_pct}, $m_post->{abs_dev_pct};
        printf "        the fold places that mass in cells 0 and %d regardless of value;\n",
            $geo->{bins} - 1;
        printf "        G has no out-of-range state and places it by value.\n";
    }
}

# =============================================================================
# Part D — the heatmap's real keying: one partition per time bucket, all
# finalized into ONE shared display geometry (finalize_heatmap_unified walks
# keys %heatmap_counters and re-bins each against the global [min,max] x W).
#
# This is where the two representations differ structurally: T/S seed each
# bucket's partition around that bucket's OWN first value, so every bucket
# carries a different range anchor (#201's Dimension B); G's grid is global by
# construction, so every bucket's bins already share one anchor.
# =============================================================================
{
    print "\n";
    my $nb = scalar keys %by_bucket;
    printf "=== PART D  per-time-bucket keying: %d buckets, %d lines each, one shared %d-cell display ===\n",
        $nb, $BUCKET_LINES, $W;

    my ($dmin, $dmax) = ($vmin > 0 ? $vmin : 1, $vmax);

    my %fin_total;      # arm -> summed display cells over all buckets
    my %per_bucket_dev; # arm -> list of per-bucket abs_dev_pct
    my %seed_ranges;    # T: distinct partition anchors observed
    for my $arm (qw(T S G)) { $fin_total{$arm} = [ (0) x $W ] }

    my $exact_total = exact_display(\@values, $dmin, $dmax, $W);

    my $parity_bad = 0;
    for my $b (sort { $a <=> $b } keys %by_bucket) {
        my $vals = $by_bucket{$b};
        my %bfin;
        for my $arm (qw(T S G)) {
            my $st = Revalidate426::store_new($arm, bpd => $BPD);
            $st->add('k', $_) for @$vals;
            if ($arm eq 'G') {
                my $i = $st->{row}{'k'};
                $bfin{G} = grid_rebin($st->{bins}[$i], $BPD, $dmin, $dmax, $W);
            } else {
                my $e = $st->entry('k');
                my $f = partition_rebin_verbatim($e->{partition}, $e->{bins}, $dmin, $dmax, $W);
                $f->[0]      += $e->{underflow} // 0;
                $f->[$W - 1] += $e->{overflow}  // 0;
                $bfin{$arm} = $f;
                if ($arm eq 'T') {
                    my $g = $st->geometry('k');
                    $seed_ranges{ sprintf('%.6g/%.6g/%d', $g->{min}, $g->{max}, $g->{bin_count}) }++;
                }
            }
        }
        for my $i (0 .. $W - 1) {
            $parity_bad++ if $bfin{T}[$i] != $bfin{S}[$i];
            $fin_total{$_}[$i] += $bfin{$_}[$i] for qw(T S G);
        }
        # per-bucket fidelity against that bucket's own exact display
        my $bexact = exact_display($vals, $dmin, $dmax, $W);
        for my $arm (qw(T S G)) {
            my $m = measures($bfin{$arm}, $bexact);
            push @{ $per_bucket_dev{$arm} }, $m->{abs_dev_pct};
        }
    }

    printf "PART D  T vs S per-bucket finalized cells: %s\n",
        ($parity_bad ? "$parity_bad cells DIFFER" : "IDENTICAL across every bucket");
    printf "PART D  distinct T/S partition anchors across the %d buckets: %d\n",
        $nb, scalar keys %seed_ranges;
    printf "        (G uses one global grid anchor by construction — #201 Dimension B)\n";

    printf "PART D  aggregate display (all buckets summed) vs exact:\n";
    printf "  %-4s %10s %10s %8s %8s %8s %10s %8s\n",
        'arm', 'mass', 'mass_ret', 'peak_ret', 'peak_dx', 'empty', 'abs_dev%', 'maxcell';
    for my $arm (qw(T S G)) {
        my $m = measures($fin_total{$arm}, $exact_total);
        printf "  %-4s %10d %10.6f %8.4f %8d %8d %10.4f %8d\n",
            $arm, $m->{mass}, $m->{mass_retention}, $m->{peak_retention},
            $m->{peak_x_offset}, $m->{empty_cells}, $m->{abs_dev_pct}, $m->{max_cell_dev};
        push @rows, { geometry => 'heatmap-keyed', arm => $arm, bins => $W,
                      %$m, overflow => '', underflow => '' };
    }

    printf "PART D  per-bucket deviation from that bucket's exact display (%% of its mass):\n";
    printf "  %-4s %9s %9s %9s %9s\n", 'arm', 'median', 'p95', 'max', 'mean';
    for my $arm (qw(T S G)) {
        my @d = sort { $a <=> $b } @{ $per_bucket_dev{$arm} };
        my $med = $d[int(@d * 0.5)];
        my $p95 = $d[int(@d * 0.95)];
        my $mean = 0; $mean += $_ for @d; $mean /= @d;
        printf "  %-4s %9.4f %9.4f %9.4f %9.4f\n", $arm, $med, $p95, $d[-1], $mean;
    }
}

# --- TSV for the report ----------------------------------------------------
if (defined $opt{out}) {
    my $dir = $opt{out};
    mkdir $dir unless -d $dir;
    my $tsv = "$dir/revalidate-v6.tsv";
    open(my $fh, '>', $tsv) or die "cannot write $tsv: $!\n";
    my @cols = qw(geometry arm bins mass mass_exact mass_retention peak peak_exact
                  peak_retention peak_col peak_col_exact peak_x_offset empty_cells
                  empty_exact cells_differ abs_dev abs_dev_pct max_cell_dev
                  overflow underflow);
    print $fh join("\t", 'file', 'bpd', @cols), "\n";
    for my $r (@rows) {
        print $fh join("\t", $opt{file}, $BPD, map { defined $r->{$_} ? $r->{$_} : '' } @cols), "\n";
    }
    close $fh;
    print "\nTSV: $tsv\n";
}
