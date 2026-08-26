#!/usr/bin/env perl
#
# 426-grid-fidelity.pl — percentile fidelity of two bin-counter geometries
# against the exact raw percentiles, per message key and after merging
# pairs of keys (the -g grouping operation).
#
#   today   per-key partition seeded ±2.5 decades around the key's first
#           sample, HdrHistogram doubling when a sample falls outside it,
#           geometric-midpoint remap of existing counts on every widening;
#           merge = union geometry + remap of both sides. Production subs
#           verbatim (partition_new / bin_assign / partition_extend /
#           partition_rebin / bin_boundary / counter_update / percentile /
#           merge_bin_counter_entries).
#   shared  one log-spaced grid for the whole store: bin index =
#           floor(bpd * log10(value)); a key stores only its occupied
#           indices; merge = index-wise add. Same bins-per-decade, same
#           Prometheus-style within-bin exponential interpolation.
#
# Exact reference: calculate_statistics' nearest-rank percentile
# ($sorted[int($n * $q)]) over the same positive samples both geometries
# see (zero durations never enter a counter — that divergence is shared by
# both and is not what this probe measures).
#
# Usage: perl prototype/426-grid-fidelity.pl [--bpd N] <fixture>
# Prints a markdown summary; TSV rows (scheme, scope, quantile, statistic,
# value) on stderr when --tsv is given.

use strict;
use warnings;
use POSIX ();
use List::Util qw(min max sum);

my ($bpd, $seed_decades, $tsv) = (53, 5, 0);
while (@ARGV && $ARGV[0] =~ /^--/) {
    my $o = shift @ARGV;
    if    ($o eq '--bpd') { $bpd = shift @ARGV }
    elsif ($o eq '--tsv') { $tsv = 1 }
    else { die "unknown option $o\n" }
}
my $file = shift @ARGV or die "usage: $0 [--bpd N] <fixture>\n";
my @Q = ( [p50 => 0.50], [p95 => 0.95], [p99 => 0.99], [p999 => 0.999] );

## --- production primitives, verbatim -----------------------------------------
sub partition_new {
    my ($v0, $bpd, $seed_decades) = @_;
    my $half_span = sqrt(10 ** $seed_decades);
    my $min       = $v0 / $half_span;
    my $max       = $v0 * $half_span;
    my $bin_count = int($bpd * $seed_decades);
    return { min => $min, max => $max, bpd => $bpd, decades => $seed_decades,
             bin_count => $bin_count, log_ratio => log($max / $min), rebins => 0 };
}
sub partition_extend {
    my ($p, $value, $old_bins_ref) = @_;
    my $double_factor = 10 ** ($p->{decades} / 2);
    my ($new_min, $new_max) = ($p->{min}, $p->{max});
    while ($value > $new_max || $value < $new_min) {
        if ($value > $new_max) { $new_max *= $double_factor } else { $new_min /= $double_factor }
    }
    my $new_decades   = log($new_max / $new_min) / log(10);
    my $new_bin_count = int($p->{bpd} * $new_decades);
    $new_bin_count = $p->{bin_count} if $new_bin_count < $p->{bin_count};
    my $new_log_ratio = log($new_max / $new_min);
    my @new_bins;
    for my $old_i (0 .. $p->{bin_count} - 1) {
        my $count = $old_bins_ref->[$old_i];
        next unless defined $count && $count > 0;
        my $lower    = bin_boundary($p, $old_i);
        my $upper    = bin_boundary($p, $old_i + 1);
        my $midpoint = sqrt($lower * $upper);
        my $new_i    = int($new_bin_count * log($midpoint / $new_min) / $new_log_ratio);
        $new_i = 0                  if $new_i < 0;
        $new_i = $new_bin_count - 1 if $new_i >= $new_bin_count;
        $new_bins[$new_i] = ($new_bins[$new_i] // 0) + $count;
    }
    $p->{min} = $new_min; $p->{max} = $new_max; $p->{bin_count} = $new_bin_count;
    $p->{log_ratio} = $new_log_ratio; $p->{rebins}++;
    return \@new_bins;
}
sub partition_rebin {
    my ($p, $src_bins, $new_min, $new_max, $new_bin_count) = @_;
    my $new_log_ratio = log($new_max / $new_min);
    my @new_bins;
    for my $old_i (0 .. $p->{bin_count} - 1) {
        my $count = $src_bins->[$old_i];
        next unless defined $count && $count > 0;
        my $lower    = bin_boundary($p, $old_i);
        my $upper    = bin_boundary($p, $old_i + 1);
        my $midpoint = sqrt($lower * $upper);
        my $new_i    = int($new_bin_count * log($midpoint / $new_min) / $new_log_ratio);
        $new_i = 0                  if $new_i < 0;
        $new_i = $new_bin_count - 1 if $new_i >= $new_bin_count;
        $new_bins[$new_i] = ($new_bins[$new_i] // 0) + $count;
    }
    for my $i (0 .. $new_bin_count - 1) { $new_bins[$i] //= 0 }
    my $new_partition = { min => $new_min, max => $new_max, bpd => $p->{bpd},
                          decades => log($new_max / $new_min) / log(10), bin_count => $new_bin_count,
                          log_ratio => $new_log_ratio, rebins => 0 };
    return ($new_partition, \@new_bins);
}
sub bin_assign {
    my ($p, $v) = @_;
    return ('UNDERFLOW', undef) if $v < $p->{min};
    return ('OVERFLOW',  undef) if $v > $p->{max};
    my $i = int($p->{bin_count} * log($v / $p->{min}) / $p->{log_ratio});
    $i = $p->{bin_count} - 1 if $i >= $p->{bin_count};
    $i = 0                   if $i < 0;
    return ('IN', $i);
}
sub bin_boundary { my ($p, $i) = @_; return $p->{min} * exp($p->{log_ratio} * $i / $p->{bin_count}) }
sub counter_update {
    my ($store, $key, $value) = @_;
    my $entry = $store->{$key};
    if (!$entry) {
        $entry = $store->{$key} = { partition => partition_new($value, $bpd, $seed_decades), bins => [], overflow => 0, underflow => 0 };
    }
    my ($where, $idx) = bin_assign($entry->{partition}, $value);
    if ($where eq 'IN') { $entry->{bins}->[$idx] = ($entry->{bins}->[$idx] // 0) + 1; return }
    my $new_bins = partition_extend($entry->{partition}, $value, $entry->{bins});
    $entry->{bins} = $new_bins;
    my ($w2, $i2) = bin_assign($entry->{partition}, $value);
    if    ($w2 eq 'IN')       { $entry->{bins}->[$i2] = ($entry->{bins}->[$i2] // 0) + 1 }
    elsif ($w2 eq 'OVERFLOW') { $entry->{overflow}++ }
    else                      { $entry->{underflow}++ }
}
sub percentile {
    my ($entry, $q) = @_;
    my $p = $entry->{partition}; my $bins = $entry->{bins};
    my $under = $entry->{underflow} // 0; my $over = $entry->{overflow} // 0;
    my $in_total = 0; $in_total += ($_ // 0) for @$bins;
    my $total_N = $under + $in_total + $over;
    return (undef, 'none') if $total_N == 0;
    my $target_rank = POSIX::ceil($q * $total_N);
    $target_rank = 1 if $target_rank < 1; $target_rank = $total_N if $target_rank > $total_N;
    my $cum = 0;
    if ($under > 0) { $cum += $under; return (bin_boundary($p, 0), 'low') if $target_rank <= $cum }
    for my $i (0 .. $p->{bin_count} - 1) {
        my $c = $bins->[$i] // 0; next if $c == 0; $cum += $c;
        if ($target_rank <= $cum) {
            my $lower = bin_boundary($p, $i); my $upper = bin_boundary($p, $i + 1);
            my $rank_in_bin = $target_rank - ($cum - $c); my $fraction = $rank_in_bin / $c;
            return ($lower * (($upper / $lower) ** $fraction), 'none');
        }
    }
    return (bin_boundary($p, $p->{bin_count}), 'high');
}
sub merge_bin_counter_entries {
    my ($target, $source) = @_;
    if (!$target->{partition}) {
        $target->{partition} = $source->{partition}; $target->{bins} = $source->{bins} // [];
        $target->{overflow} = $source->{overflow} // 0; $target->{underflow} = $source->{underflow} // 0; return;
    }
    return unless $source->{partition};
    my $tp = $target->{partition}; my $sp = $source->{partition};
    my $union_min = $tp->{min} < $sp->{min} ? $tp->{min} : $sp->{min};
    my $union_max = $tp->{max} > $sp->{max} ? $tp->{max} : $sp->{max};
    my $b = $tp->{bpd};
    my $union_decades   = log($union_max / $union_min) / log(10);
    my $union_bin_count = int($b * $union_decades);
    $union_bin_count = 1 if $union_bin_count < 1;
    if ($tp->{min} != $union_min || $tp->{max} != $union_max || $tp->{bin_count} != $union_bin_count) {
        my ($new_p, $new_bins) = partition_rebin($tp, $target->{bins}, $union_min, $union_max, $union_bin_count);
        $target->{partition} = $new_p; $target->{bins} = $new_bins;
    }
    my $source_bins_aligned;
    if ($sp->{min} != $union_min || $sp->{max} != $union_max || $sp->{bin_count} != $union_bin_count) {
        my (undef, $new_bins) = partition_rebin($sp, $source->{bins}, $union_min, $union_max, $union_bin_count);
        $source_bins_aligned = $new_bins;
    } else { $source_bins_aligned = $source->{bins} }
    for my $i (0 .. $union_bin_count - 1) {
        my $sc = $source_bins_aligned->[$i] // 0; next if $sc == 0;
        $target->{bins}->[$i] = ($target->{bins}->[$i] // 0) + $sc;
    }
    $target->{overflow} += ($source->{overflow} // 0); $target->{underflow} += ($source->{underflow} // 0);
}

## --- shared grid ----------------------------------------------------------------
my $LN10 = log(10);
sub grid_index { my ($v) = @_; return POSIX::floor($bpd * log($v) / $LN10) }
sub grid_add   { my ($h, $v) = @_; $h->{ grid_index($v) }++ }
sub grid_merge { my ($t, $s) = @_; $t->{$_} += $s->{$_} for keys %$s; return $t }
sub grid_percentile {
    my ($h, $q) = @_;
    my $total_N = sum(values %$h) // 0;
    return undef if $total_N == 0;
    my $target_rank = POSIX::ceil($q * $total_N);
    $target_rank = 1 if $target_rank < 1; $target_rank = $total_N if $target_rank > $total_N;
    my $cum = 0;
    for my $i (sort { $a <=> $b } keys %$h) {
        my $c = $h->{$i}; $cum += $c;
        if ($target_rank <= $cum) {
            my $lower = 10 ** ($i / $bpd); my $upper = 10 ** (($i + 1) / $bpd);
            my $rank_in_bin = $target_rank - ($cum - $c); my $fraction = $rank_in_bin / $c;
            return $lower * (($upper / $lower) ** $fraction);
        }
    }
    die "unreachable";
}

## --- read the fixture ------------------------------------------------------------
my $re_twx = qr/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})[\+\-]\d{4} \[L: ([^\]]*)\] \[O: ([^\]]*)] \[I: ([^\]]*)] \[U: ([^\]]*)] \[S: ([^\]]*)] \[P: ([^\]]*)] \[T: ((?:\](?! )|[^\]])*)] (.*)/;
my (%dur, $zeros, $lines);
open my $fh, '<', $file or die "open $file: $!";
while (<$fh>) {
    $lines++;
    my ($timestamp_str, $category_bucket, $object, undef, undef, undef, undef, $thread, $message) = $_ =~ $re_twx;
    next unless defined $timestamp_str;
    next unless index($message, ' durationM') >= 0;
    my ($duration) = $message =~ / durationM[sS]\s*=\s*(\d+)/;
    next unless defined $duration;
    $message =~ s/ ((bytes|durationM[sS])\s*=\s*)(\d+)/ $1?/g;
    $message =~ s/ count\s*=\s*\d+/ count=?/g;
    my $threadname = $thread;
    if (defined $thread && $thread ne "") { my ($pool) = $thread =~ /(.*)-\d+$/; $threadname = $pool if defined $pool }
    my $truncated_thread = defined($threadname) ? substr($threadname, 0, 20) : undef;
    my $truncated_object = defined($object) ? substr($object, length($object) > 25 ? length($object) - 25 : 0, 25) : undef;
    my $log_key = substr("[$category_bucket] [$truncated_thread] [$truncated_object] $message", 0, 200);
    if ($duration > 0) { push @{ $dur{$log_key} }, $duration } else { $zeros++ }
}
close $fh;

## --- per-key --------------------------------------------------------------------
my %err;      # {scheme}{scope}{quantile} => [signed relative errors]
my ($n_keys, $n_ext, $n_pairs, $n_remaps) = (0, 0, 0, 0);
my %today_entries;
for my $k (sort keys %dur) {
    my @s = sort { $a <=> $b } @{ $dur{$k} };
    my $n = @s;
    $n_keys++;
    my %store; counter_update(\%store, $k, $_) for @s;
    my $te = $store{$k}; $n_ext += $te->{partition}{rebins};
    $today_entries{$k} = $te;
    my %g; grid_add(\%g, $_) for @s;
    for my $pair (@Q) {
        my ($name, $q) = @$pair;
        my $exact = $s[int($n * $q)];
        my ($t) = percentile($te, $q);
        my $gv = grid_percentile(\%g, $q);
        push @{ $err{today}{key}{$name}  }, ($t  - $exact) / $exact;
        push @{ $err{shared}{key}{$name} }, ($gv - $exact) / $exact;
    }
}

## --- merged pairs (consecutive keys in sorted order, both with >= 2 samples) ----
my @mk = grep { @{ $dur{$_} } >= 2 } sort keys %dur;
for (my $j = 0; $j + 1 < @mk; $j += 2) {
    my ($ka, $kb) = @mk[$j, $j + 1];
    my @s = sort { $a <=> $b } (@{ $dur{$ka} }, @{ $dur{$kb} });
    my $n = @s;
    $n_pairs++;
    # today: rebuild both entries fresh (merge mutates the target), then merge verbatim
    my (%sa, %sb); counter_update(\%sa, 'a', $_) for @{ $dur{$ka} }; counter_update(\%sb, 'b', $_) for @{ $dur{$kb} };
    my $before = $sa{a}{partition}{min} . '/' . $sa{a}{partition}{max};
    merge_bin_counter_entries($sa{a}, $sb{b});
    $n_remaps++ if $before ne $sa{a}{partition}{min} . '/' . $sa{a}{partition}{max};
    my (%ga, %gb); grid_add(\%ga, $_) for @{ $dur{$ka} }; grid_add(\%gb, $_) for @{ $dur{$kb} };
    my $g = grid_merge(\%ga, \%gb);
    for my $pair (@Q) {
        my ($name, $q) = @$pair;
        my $exact = $s[int($n * $q)];
        my ($t) = percentile($sa{a}, $q);
        my $gv = grid_percentile($g, $q);
        push @{ $err{today}{merged}{$name}  }, ($t  - $exact) / $exact;
        push @{ $err{shared}{merged}{$name} }, ($gv - $exact) / $exact;
    }
}

## --- report ---------------------------------------------------------------------
my $bin_width = 10 ** (1 / $bpd) - 1;
sub pct { my ($aref, $f) = @_; my @s = sort { $a <=> $b } @$aref; return $s[ min($#s, int(@s * $f)) ] }
(my $fx = $file) =~ s{.*/}{};
printf "### %s — %d lines, %d keys with positive durations (%d zero-duration samples excluded), bpd=%d (one bin = %.2f%%)\n\n",
    $fx, $lines, $n_keys, $zeros // 0, $bpd, 100 * $bin_width;
printf "Today's geometry: %d partition widenings across keys; %d of %d merged pairs needed a union remap.\n\n", $n_ext, $n_remaps, $n_pairs;
print "| scope | quantile | scheme | median abs err | p95 abs err | max abs err | within one bin | mean signed err (bias) |\n";
print "|---|---|---|---|---|---|---|---|\n";
for my $scope (qw(key merged)) {
    for my $pair (@Q) {
        my ($name) = @$pair;
        for my $scheme (qw(today shared)) {
            my $e = $err{$scheme}{$scope}{$name} or next;
            my @abs = map { abs } @$e;
            my $within = (grep { $_ <= $bin_width + 1e-12 } @abs) / @abs;
            printf "| %s (n=%d) | %s | %s | %.3f%% | %.3f%% | %.3f%% | %.1f%% | %+.3f%% |\n",
                $scope eq 'key' ? 'per key' : 'merged pair', scalar @$e, $name, $scheme,
                100 * pct(\@abs, 0.5), 100 * pct(\@abs, 0.95), 100 * max(@abs), 100 * $within, 100 * sum(@$e) / @$e;
            if ($tsv) {
                printf STDERR "%s\t%s\t%s\t%s\t%.6g\n", $scheme, $scope, $name, $_->[0], $_->[1]
                    for [median_abs => pct(\@abs, 0.5)], [p95_abs => pct(\@abs, 0.95)], [max_abs => max(@abs)],
                        [within_bin => $within], [bias => sum(@$e) / @$e];
            }
        }
    }
}
