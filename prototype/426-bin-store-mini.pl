#!/usr/bin/env perl
#
# 426-bin-store-mini.pl — the -mdm bin per-message stores (#426): the message
# record with its Welford-Pébay sidecars plus the #189 bin-counter store, per
# representation. Companion of 426-store-mini.pl (raw mode); same protocol.
#
# Arms:
#   K1  today: record = one hash per message with the sidecars as fields;
#       counters = %log_messages_counters keyed "$category\x1f$log_key", one
#       { partition{7 fields}, bins[], overflow, underflow } entry per
#       message. counter_update / partition_new / bin_assign /
#       partition_extend / bin_boundary / percentile are the production
#       subs verbatim.
#   K2  columnar record (message->row hash + one array per field, sidecars
#       included); the counter entries are today's hashes, held in an array
#       by row — no composite key, same call shape as K1.
#   K3  columnar record + counter columns: partition min / max / bin_count /
#       log_ratio / rebins, overflow, underflow as arrays by row; bins[row]
#       an arrayref dense from index 0 as today; bin assignment inlined.
#   K4  K3 with offset-dense bins: bins[row] = [base_index, c0, c1, ...]
#       holding only the occupied span.
#
# Usage:
#   perl prototype/426-bin-store-mini.pl --arm K1|K2|K3|K4 [--runs N]
#        [--top-n N] [--width W] [--churn F] [--no-header] <fixture>
#
# Fixtures are ThingWorx application logs whose messages carry
# ` durationMs=N` (and optionally ` bytes=N`), i.e. the thingworx_standard
# format with its message-metric probes; every line takes the metric-bearing
# (access-log) write branch. TSV on stdout; PARITY digests on stderr.

use strict;
use warnings;
use FindBin;
use POSIX ();
use List::Util qw(min max sum0);
use Devel::Size qw(total_size);
use Digest::MD5;
use Time::HiRes qw(gettimeofday tv_interval);
require "$FindBin::Bin/58-measure.pm";

my ($runs, $arm, $top_n_messages, $width, $churn_frac, $no_header) = (5, 'K1', 10, 200, 0.9, 0);
while (@ARGV && $ARGV[0] =~ /^--/) {
    my $o = shift @ARGV;
    if    ($o eq '--runs')      { $runs = shift @ARGV }
    elsif ($o eq '--arm')       { $arm = shift @ARGV }
    elsif ($o eq '--top-n')     { $top_n_messages = shift @ARGV }
    elsif ($o eq '--width')     { $width = shift @ARGV }
    elsif ($o eq '--churn')     { $churn_frac = shift @ARGV }
    elsif ($o eq '--no-header') { $no_header = 1 }
    else { die "unknown option $o\n" }
}
die "usage: $0 --arm K1|K2|K3|K4 [--runs N] <fixture>\n" unless @ARGV == 1 && $arm =~ /^K[1-4]$/;
my $file = shift @ARGV;
(my $fixture = $file) =~ s{.*/}{};

## ---------------------------------------------------------------------------
## Production globals (values of the -mdm bin -so p99 construct).
## ---------------------------------------------------------------------------
our $impact_time_exponent            = 7;
our $omit_durations                  = 0;
our $omit_count                      = 0;
our $message_duration_stats_demand   = 1;
our $message_stats_capture_mode      = 'bin';
our $message_stats_demand_shape      = 0;
our $percentile_buckets_per_decade   = 53;
our $percentile_seed_decades         = 5;
our $max_log_message_length          = $width;
our $write_messages_to_csv           = 0;
our $group_similar_sensitivity       = 'none';
our $sort_ascending                  = 0;
our $n_floor                         = 1;
my @QUANTILES = ( [p50 => 0.50], [p95 => 0.95], [p99 => 0.99], [p999 => 0.999] );   # terminal_core demand

my $re_twx = qr/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})[\+\-]\d{4} \[L: ([^\]]*)\] \[O: ([^\]]*)] \[I: ([^\]]*)] \[U: ([^\]]*)] \[S: ([^\]]*)] \[P: ([^\]]*)] \[T: ((?:\](?! )|[^\]])*)] (.*)/;

## ---------------------------------------------------------------------------
## Production bin-counter primitives, verbatim (K1 and K2 call these; K3/K4
## call partition_new / partition_extend through a column view — extension
## is rare and its geometry must stay byte-identical).
## ---------------------------------------------------------------------------
sub partition_new {
    my ($v0, $bpd, $seed_decades) = @_;
    my $half_span = sqrt(10 ** $seed_decades);
    my $min       = $v0 / $half_span;
    my $max       = $v0 * $half_span;
    my $bin_count = int($bpd * $seed_decades);
    return {
        min       => $min,
        max       => $max,
        bpd       => $bpd,
        decades   => $seed_decades,
        bin_count => $bin_count,
        log_ratio => log($max / $min),
        rebins    => 0,
    };
}
sub partition_extend {
    my ($p, $value, $old_bins_ref) = @_;
    my $double_factor = 10 ** ($p->{decades} / 2);
    my ($new_min, $new_max) = ($p->{min}, $p->{max});
    while ($value > $new_max || $value < $new_min) {
        if ($value > $new_max) {
            $new_max *= $double_factor;
        } else {
            $new_min /= $double_factor;
        }
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

    $p->{min}       = $new_min;
    $p->{max}       = $new_max;
    $p->{bin_count} = $new_bin_count;
    $p->{log_ratio} = $new_log_ratio;
    $p->{rebins}++;

    return \@new_bins;
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
sub bin_boundary {
    my ($p, $i) = @_;
    return $p->{min} * exp($p->{log_ratio} * $i / $p->{bin_count});
}
sub counter_update {
    my ($store, $key, $value, $bpd_override) = @_;
    my $bpd = $bpd_override // $percentile_buckets_per_decade;
    my $entry = $store->{$key};
    if (!$entry) {
        $entry = $store->{$key} = {
            partition => partition_new($value, $bpd, $percentile_seed_decades),
            bins      => [],
            overflow  => 0,
            underflow => 0,
        };
    }

    my ($where, $idx) = bin_assign($entry->{partition}, $value);
    if ($where eq 'IN') {
        $entry->{bins}->[$idx] = ($entry->{bins}->[$idx] // 0) + 1;
        return;
    }

    my $new_bins = partition_extend($entry->{partition}, $value, $entry->{bins});
    $entry->{bins} = $new_bins;
    my ($w2, $i2) = bin_assign($entry->{partition}, $value);
    if ($w2 eq 'IN') {
        $entry->{bins}->[$i2] = ($entry->{bins}->[$i2] // 0) + 1;
    } elsif ($w2 eq 'OVERFLOW') {
        $entry->{overflow}++;
    } else {
        $entry->{underflow}++;
    }
}
sub percentile {
    my ($entry, $q) = @_;
    my $p    = $entry->{partition};
    my $bins = $entry->{bins};
    my $under = $entry->{underflow} // 0;
    my $over  = $entry->{overflow}  // 0;

    my $in_total = 0;
    $in_total += ($_ // 0) for @$bins;
    my $total_N = $under + $in_total + $over;
    return (undef, 'none') if $total_N == 0;

    my $target_rank = POSIX::ceil($q * $total_N);
    $target_rank = 1       if $target_rank < 1;
    $target_rank = $total_N if $target_rank > $total_N;

    my $cum = 0;
    if ($under > 0) {
        $cum += $under;
        return (bin_boundary($p, 0), 'low') if $target_rank <= $cum;
    }
    for my $i (0 .. $p->{bin_count} - 1) {
        my $c = $bins->[$i] // 0;
        next if $c == 0;
        $cum += $c;
        if ($target_rank <= $cum) {
            my $lower       = bin_boundary($p, $i);
            my $upper       = bin_boundary($p, $i + 1);
            my $rank_in_bin = $target_rank - ($cum - $c);
            my $fraction    = $rank_in_bin / $c;
            my $value       = $lower * (($upper / $lower) ** $fraction);
            return ($value, 'none');
        }
    }
    return (bin_boundary($p, $p->{bin_count}), 'high');
}

## K2: counter_update with the entry held in an array slot by row.
sub counter_update_row {
    my ($ctr, $i, $value) = @_;
    my $entry = $ctr->[$i];
    if (!$entry) {
        $entry = $ctr->[$i] = {
            partition => partition_new($value, $percentile_buckets_per_decade, $percentile_seed_decades),
            bins      => [],
            overflow  => 0,
            underflow => 0,
        };
    }
    my ($where, $idx) = bin_assign($entry->{partition}, $value);
    if ($where eq 'IN') {
        $entry->{bins}->[$idx] = ($entry->{bins}->[$idx] // 0) + 1;
        return;
    }
    my $new_bins = partition_extend($entry->{partition}, $value, $entry->{bins});
    $entry->{bins} = $new_bins;
    my ($w2, $i2) = bin_assign($entry->{partition}, $value);
    if ($w2 eq 'IN') {
        $entry->{bins}->[$i2] = ($entry->{bins}->[$i2] // 0) + 1;
    } elsif ($w2 eq 'OVERFLOW') {
        $entry->{overflow}++;
    } else {
        $entry->{underflow}++;
    }
}

## K3/K4: out-of-range sample — extend through the verbatim primitive via a
## column view (rare path), then re-assign.
my $SEED_HALF = sqrt(10 ** $percentile_seed_decades);
my $SEED_BC   = int($percentile_buckets_per_decade * $percentile_seed_decades);
sub extend_cols {
    my ($st, $i, $value, $offset_dense) = @_;
    my ($pmin, $pmax, $pbc, $plr, $prb, $bins, $over, $under) = @$st{qw(pmin pmax pbc plr prb bins over under)};
    my %p = ( min => $pmin->[$i], max => $pmax->[$i], bpd => $percentile_buckets_per_decade,
              decades => $percentile_seed_decades, bin_count => $pbc->[$i], log_ratio => $plr->[$i], rebins => $prb->[$i] );
    my $dense = $bins->[$i] // [];
    if ($offset_dense && @$dense) {
        my ($base, @c) = @$dense;
        my @d; $d[$base + $_] = $c[$_] for 0 .. $#c;
        $dense = \@d;
    }
    my $new_bins = partition_extend(\%p, $value, $dense);
    @{$pmin}[$i] = $p{min}; $pmax->[$i] = $p{max}; $pbc->[$i] = $p{bin_count}; $plr->[$i] = $p{log_ratio}; $prb->[$i] = $p{rebins};
    if ($offset_dense) {
        my ($first) = grep { defined $new_bins->[$_] } 0 .. $#$new_bins;
        $bins->[$i] = defined $first ? [ $first, map { $new_bins->[$_] // 0 } $first .. $#$new_bins ] : [];
    } else {
        $bins->[$i] = $new_bins;
    }
    # re-assign
    if ($value < $pmin->[$i])    { $under->[$i]++; return }
    if ($value > $pmax->[$i])    { $over->[$i]++;  return }
    my $idx = int($pbc->[$i] * log($value / $pmin->[$i]) / $plr->[$i]);
    $idx = $pbc->[$i] - 1 if $idx >= $pbc->[$i];
    $idx = 0 if $idx < 0;
    if ($offset_dense) { bump_offset_dense($bins, $i, $idx) } else { $bins->[$i][$idx]++ }
}
sub bump_offset_dense {
    my ($bins, $i, $idx) = @_;
    my $b = $bins->[$i];
    if (!$b || !@$b) { $bins->[$i] = [ $idx, 1 ]; return }
    my $base = $b->[0];
    if ($idx >= $base) { $b->[$idx - $base + 1]++; return }
    my $shift = $base - $idx;
    splice @$b, 1, 0, (0) x $shift;
    $b->[0] = $idx;
    $b->[1]++;
}

## K3/K4 percentile over columns.
sub percentile_cols {
    my ($st, $i, $q, $offset_dense) = @_;
    my ($pmin, $pbc, $plr, $bins, $over, $under) = @$st{qw(pmin pbc plr bins over under)};
    my $b = $bins->[$i] // [];
    my ($base, $first) = (0, 0);
    if ($offset_dense) { $base = $b->[0] // 0; $first = 1 }
    my $u = $under->[$i] // 0;
    my $o = $over->[$i]  // 0;
    my $in_total = 0;
    $in_total += ($_ // 0) for @{$b}[$first .. $#$b];
    my $total_N = $u + $in_total + $o;
    return (undef, 'none') if $total_N == 0;
    my $target_rank = POSIX::ceil($q * $total_N);
    $target_rank = 1        if $target_rank < 1;
    $target_rank = $total_N if $target_rank > $total_N;
    my ($mn, $lr, $bc) = ($pmin->[$i], $plr->[$i], $pbc->[$i]);
    my $cum = 0;
    if ($u > 0) {
        $cum += $u;
        return ($mn * exp($lr * 0 / $bc), 'low') if $target_rank <= $cum;
    }
    my ($lo, $hi) = $offset_dense ? ($base, $base + $#$b - 1) : (0, $bc - 1);
    for my $bi ($lo .. $hi) {
        my $c = $b->[$bi - $base + $first] // 0;
        next if $c == 0;
        $cum += $c;
        if ($target_rank <= $cum) {
            my $lower       = $mn * exp($lr * $bi / $bc);
            my $upper       = $mn * exp($lr * ($bi + 1) / $bc);
            my $rank_in_bin = $target_rank - ($cum - $c);
            my $fraction    = $rank_in_bin / $c;
            my $value       = $lower * (($upper / $lower) ** $fraction);
            return ($value, 'none');
        }
    }
    return ($mn * exp($lr * $bc / $bc), 'high');
}

## ---------------------------------------------------------------------------
## Build subs: shared parse + key derivation, per-arm store write.
## ---------------------------------------------------------------------------
my $PARSE = <<'PERL';
        my ($timestamp_str, $category_bucket, $object, $instance, $user, $session, $platform, $thread, $message) = $_ =~ $re_twx;
        next unless defined $timestamp_str;
        my ($bytes, $duration, $count, $threadname, $threadpool);
        if (index($message, '=') >= 0) {
            ($bytes)    = $message =~ / bytes\s*=\s*(\d+)/         if index($message, ' bytes') >= 0;
            ($duration) = $message =~ / durationM[sS]\s*=\s*(\d+)/ if index($message, ' durationM') >= 0;
            $message =~ s/ ((bytes|durationM[sS])\s*=\s*)(\d+)/ $1?/g if defined $bytes || defined $duration;
        }
        if( !$omit_count && defined $message ) {
            ( $count ) = $message =~ / count\s*=\s*(\d+)/;
            if( defined $count ) {
                $message =~ s/ count\s*=\s*\d+/ count=?/g;
            }
        }
        if( defined $thread && $thread ne "" ) {
            ( $threadpool ) = $thread =~ /(.*)-\d+$/;
            $threadname = defined $threadpool ? $threadpool : $thread;
        }
        my $status_code = 0;
        $log_occurrences{substr($timestamp_str, 0, 16)}{$category_bucket}{occurrences}++;
        my $category = 'plain';
PERL
my $KEY = <<'PERL';
        my $log_key = "";
        my $max_object_length = 25;
        my $log_level = $status_code > 0 ? $status_code : $category_bucket;
        $log_level =~ s/-HL$//;
        my $truncated_thread = defined($threadname) ? substr($threadname, 0, 20) : undef;
        my $truncated_object = defined($object) ? substr($object, length($object) > $max_object_length ? length($object)-$max_object_length : 0, $max_object_length) : undef;
        if( defined( $threadname ) && defined( $object ) ) {
            $log_key = substr("[$log_level] [$truncated_thread] [$truncated_object] $message", 0, ( ($write_messages_to_csv == 1 || $group_similar_sensitivity ne "none") ? 350 : $max_log_message_length ) );
        } elsif( defined( $object ) ) {
            $log_key = substr("[$log_level] [$truncated_object] $message", 0, ( ($write_messages_to_csv == 1 || $group_similar_sensitivity ne "none") ? 350 : $max_log_message_length ) );
        } elsif( defined( $threadname ) ) {
            $log_key = substr("[$log_level] [$truncated_thread] $message", 0, ( ($write_messages_to_csv == 1 || $group_similar_sensitivity ne "none") ? 350 : $max_log_message_length ) );
        } else {
            $log_key = substr("[$log_level] $message", 0, ( ($write_messages_to_csv == 1 || $group_similar_sensitivity ne "none") ? 350 : $max_log_message_length ) );
        }
PERL

# K1: production bin-mode write block (raw-array and UDM/count branches
# omitted: the fixtures carry no count and no UDM).
my $WRITE_K1 = <<'PERL';
        $log_messages{$category}{$log_key} //= {
            occurrences    => 0,
            total_bytes    => 0,
            total_duration => 0,
            sum_of_squares => 0,
            duration_count => 0,
            min            => undef,
            max            => undef,
            _running_mean  => 0,
            ($message_stats_demand_shape ? (m2_sum => 0, m3_sum => 0, m4_sum => 0) : ()),
        };

        $log_messages{$category}{$log_key}{occurrences}++;
        $log_messages{$category}{$log_key}{total_bytes} += $bytes if defined $bytes;

        if( defined $count ) {
            $log_messages{$category}{$log_key}{count_sum} += $count if defined $count;
            $log_messages{$category}{$log_key}{count_occurrences}++;
            $log_messages{$category}{$log_key}{count_min} = $count if !defined $log_messages{$category}{$log_key}{count_min} || $count < $log_messages{$category}{$log_key}{count_min};
            $log_messages{$category}{$log_key}{count_max} = $count if !defined $log_messages{$category}{$log_key}{count_max} || $count > $log_messages{$category}{$log_key}{count_max};
        }

        if( defined $duration && !$omit_durations ) {
            $log_messages{$category}{$log_key}{total_duration} += $duration;
            $log_messages{$category}{$log_key}{total_duration_num} += $duration;

            if( $message_duration_stats_demand ) {
                $log_messages{$category}{$log_key}{sum_of_squares} += $duration ** 2;
                if ($message_stats_capture_mode eq 'bin') {
                    my $entry = $log_messages{$category}{$log_key};
                    if ($duration > 0) {
                        counter_update(\%log_messages_counters,
                                       "$category\x1f$log_key",
                                       $duration);
                    }
                    $entry->{min} = $duration
                        if !defined $entry->{min} || $duration < $entry->{min};
                    $entry->{max} = $duration
                        if !defined $entry->{max} || $duration > $entry->{max};
                    my $n_old = $entry->{duration_count};
                    my $n     = $n_old + 1;
                    if ($n_old == 0) {
                        $entry->{_running_mean} = $duration;
                    } else {
                        my $mean     = $entry->{_running_mean};
                        my $delta    = $duration - $mean;
                        my $delta_n  = $delta / $n;
                        $entry->{_running_mean} = $mean + $delta_n;
                        if ($message_stats_demand_shape) {
                            my $delta_n2 = $delta_n * $delta_n;
                            my $term1    = $delta * $delta_n * $n_old;
                            $entry->{m4_sum} +=
                                  $term1 * $delta_n2 * ($n*$n - 3*$n + 3)
                                + 6 * $delta_n2 * $entry->{m2_sum}
                                - 4 * $delta_n  * $entry->{m3_sum};
                            $entry->{m3_sum} +=
                                  $term1 * $delta_n * ($n - 2)
                                - 3 * $delta_n * $entry->{m2_sum};
                            $entry->{m2_sum} += $term1;
                        }
                    }
                    $entry->{duration_count} = $n;
                }
            }

            if( $duration > 0 ) {
                my $mean = $log_messages{$category}{$log_key}{total_duration} / $log_messages{$category}{$log_key}{occurrences};
                $log_messages{$category}{$log_key}{impact} = log( $mean ** $impact_time_exponent * $log_messages{$category}{$log_key}{occurrences} );
            }
        }
PERL

# K2/K3/K4: columnar record; the counter part is arm-specific.
my $WRITE_COLS_HEAD = <<'PERL';
        if ($category ne $cur_cat) {
            $st->{n} = $n if $st;
            $st = $store{$category};
            ($ord, $occ, $tb, $td, $tdn, $ss, $imp, $dc, $rm, $mn, $mx, $m2, $m3, $m4, $csum, $ccnt, $cmin, $cmax) =
                @$st{qw(ord occ tb td tdn ss imp dc rm mn mx m2 m3 m4 csum ccnt cmin cmax)};
            ($ctr, $pmin, $pmax, $pbc, $plr, $prb, $bins, $over, $under) =
                @$st{qw(ctr pmin pmax pbc plr prb bins over under)};
            $n = $st->{n};
            $cur_cat = $category;
        }
        my $i = ($ord->{$log_key} //= $n);
        if ($i == $n) {
            $n++;
            $occ->[$i] = 0;
            $tb->[$i]  = 0;
            $td->[$i]  = 0;
            $ss->[$i]  = 0;
            $dc->[$i]  = 0;
            $rm->[$i]  = 0;
        }

        $occ->[$i]++;
        $tb->[$i] += $bytes if defined $bytes;

        if( defined $count ) {
            $csum->[$i] += $count if defined $count;
            $ccnt->[$i]++;
            $cmin->[$i] = $count if !defined $cmin->[$i] || $count < $cmin->[$i];
            $cmax->[$i] = $count if !defined $cmax->[$i] || $count > $cmax->[$i];
        }

        if( defined $duration && !$omit_durations ) {
            $td->[$i]  += $duration;
            $tdn->[$i] += $duration;

            if( $message_duration_stats_demand ) {
                $ss->[$i] += $duration ** 2;
                if ($duration > 0) {
PERL
my %COUNTER = (
    K2 => <<'PERL',
                    counter_update_row($ctr, $i, $duration);
PERL
    K3 => <<'PERL',
                    if (!defined $pmin->[$i]) {
                        $pmin->[$i] = $duration / $SEED_HALF;
                        $pmax->[$i] = $duration * $SEED_HALF;
                        $pbc->[$i]  = $SEED_BC;
                        $plr->[$i]  = log($pmax->[$i] / $pmin->[$i]);
                        $prb->[$i]  = 0;
                        $bins->[$i] = [];
                        $over->[$i] = 0;
                        $under->[$i] = 0;
                    }
                    if ($duration < $pmin->[$i] || $duration > $pmax->[$i]) {
                        extend_cols($st, $i, $duration, 0);
                    } else {
                        my $idx = int($pbc->[$i] * log($duration / $pmin->[$i]) / $plr->[$i]);
                        $idx = $pbc->[$i] - 1 if $idx >= $pbc->[$i];
                        $idx = 0 if $idx < 0;
                        $bins->[$i][$idx]++;
                    }
PERL
    K4 => <<'PERL',
                    if (!defined $pmin->[$i]) {
                        $pmin->[$i] = $duration / $SEED_HALF;
                        $pmax->[$i] = $duration * $SEED_HALF;
                        $pbc->[$i]  = $SEED_BC;
                        $plr->[$i]  = log($pmax->[$i] / $pmin->[$i]);
                        $prb->[$i]  = 0;
                        $over->[$i] = 0;
                        $under->[$i] = 0;
                    }
                    if ($duration < $pmin->[$i] || $duration > $pmax->[$i]) {
                        extend_cols($st, $i, $duration, 1);
                    } else {
                        my $idx = int($pbc->[$i] * log($duration / $pmin->[$i]) / $plr->[$i]);
                        $idx = $pbc->[$i] - 1 if $idx >= $pbc->[$i];
                        $idx = 0 if $idx < 0;
                        my $b = $bins->[$i];
                        if (!$b) {
                            $bins->[$i] = [ $idx, 1 ];
                        } elsif ($idx >= $b->[0]) {
                            $b->[$idx - $b->[0] + 1]++;
                        } else {
                            bump_offset_dense($bins, $i, $idx);
                        }
                    }
PERL
);
my $WRITE_COLS_TAIL = <<'PERL';
                }
                $mn->[$i] = $duration if !defined $mn->[$i] || $duration < $mn->[$i];
                $mx->[$i] = $duration if !defined $mx->[$i] || $duration > $mx->[$i];
                my $n_old = $dc->[$i];
                my $nn    = $n_old + 1;
                if ($n_old == 0) {
                    $rm->[$i] = $duration;
                } else {
                    my $mean     = $rm->[$i];
                    my $delta    = $duration - $mean;
                    my $delta_n  = $delta / $nn;
                    $rm->[$i] = $mean + $delta_n;
                    if ($message_stats_demand_shape) {
                        my $delta_n2 = $delta_n * $delta_n;
                        my $term1    = $delta * $delta_n * $n_old;
                        $m4->[$i] +=
                              $term1 * $delta_n2 * ($nn*$nn - 3*$nn + 3)
                            + 6 * $delta_n2 * $m2->[$i]
                            - 4 * $delta_n  * $m3->[$i];
                        $m3->[$i] +=
                              $term1 * $delta_n * ($nn - 2)
                            - 3 * $delta_n * $m2->[$i];
                        $m2->[$i] += $term1;
                    }
                }
                $dc->[$i] = $nn;
            }

            if( $duration > 0 ) {
                my $mean = $td->[$i] / $occ->[$i];
                $imp->[$i] = log( $mean ** $impact_time_exponent * $occ->[$i] );
            }
        }
PERL

my $is_columnar = $arm ne 'K1';
my @REC_COLS = qw(occ tb td tdn ss imp dc rm mn mx m2 m3 m4 csum ccnt cmin cmax);
my @CTR_COLS = $arm eq 'K2' ? qw(ctr) : $arm =~ /^K[34]$/ ? qw(pmin pmax pbc plr prb bins over under) : ();
sub new_store {
    return { map { $_ => { ord => {}, n => 0, dead => 0, key => [], map { $_ => [] } (@REC_COLS, @CTR_COLS) } } qw(plain highlight) };
}

my $build_src = "sub {\n    my (\$file) = \@_;\n"
    . ($is_columnar
        ? "    my (%log_occurrences);\n    my %store = %{ new_store() };\n"
          . "    my (\$cur_cat, \$st, \$ord, \$occ, \$tb, \$td, \$tdn, \$ss, \$imp, \$dc, \$rm, \$mn, \$mx, \$m2, \$m3, \$m4, \$csum, \$ccnt, \$cmin, \$cmax, \$n) = ('');\n"
          . "    my (\$ctr, \$pmin, \$pmax, \$pbc, \$plr, \$prb, \$bins, \$over, \$under);\n"
        : "    my (%log_messages, %log_messages_counters, %log_occurrences);\n")
    . "    my \$lines = 0;\n    open my \$fh, '<', \$file or die \"open \$file: \$!\";\n    while (<\$fh>) {\n        \$lines++;\n"
    . $PARSE . $KEY
    . ($is_columnar ? $WRITE_COLS_HEAD . $COUNTER{$arm} . $WRITE_COLS_TAIL : $WRITE_K1)
    . "    }\n    close \$fh;\n"
    . ($is_columnar
        ? "    \$st->{n} = \$n if \$st && defined \$n;\n    return { store => \\%store, side => \\%log_occurrences, lines => \$lines };\n"
        : "    return { lm => \\%log_messages, ctr => \\%log_messages_counters, side => \\%log_occurrences, lines => \$lines };\n")
    . "}\n";
if ($ENV{LTL426_DUMP}) { print STDERR $build_src; exit 0 }
my $build = eval $build_src or die "build sub failed to compile for $arm: $@\n$build_src";

## ---------------------------------------------------------------------------
## Consumers: the -so p99 population pass = eligibility + the
## calculate_statistics_bin derivation (terminal_core demand) for every
## eligible key.
## ---------------------------------------------------------------------------
sub stats_hash {                       # ($entry, $counter_entry) -> list
    my ($e, $c) = @_;
    my $n = $e->{duration_count} // 0;
    return () unless $n > 0;
    my $mean = $e->{total_duration} / $n;
    my ($std_dev, $cv);
    if ($n >= 2) {
        my $sum_sq_dev = $e->{sum_of_squares} - $n * ($mean ** 2);
        $sum_sq_dev = 0 if $sum_sq_dev < 0;
        $std_dev = sqrt($sum_sq_dev / ($n - 1));
        $cv = $mean != 0 ? $std_dev / $mean : undef;
    }
    my @pct;
    if ($c) { push @pct, (percentile($c, $_->[1]))[0] for @QUANTILES }
    else    { @pct = (0) x @QUANTILES }
    return ($e->{min}, $e->{max}, $mean, $std_dev, $cv, @pct);
}
sub stats_cols {                       # ($st, $i) -> list
    my ($st, $i) = @_;
    my $n = $st->{dc}[$i] // 0;
    return () unless $n > 0;
    my $mean = $st->{td}[$i] / $n;
    my ($std_dev, $cv);
    if ($n >= 2) {
        my $sum_sq_dev = $st->{ss}[$i] - $n * ($mean ** 2);
        $sum_sq_dev = 0 if $sum_sq_dev < 0;
        $std_dev = sqrt($sum_sq_dev / ($n - 1));
        $cv = $mean != 0 ? $std_dev / $mean : undef;
    }
    my @pct;
    if ($arm eq 'K2') {
        my $c = $st->{ctr}[$i];
        if ($c) { push @pct, (percentile($c, $_->[1]))[0] for @QUANTILES } else { @pct = (0) x @QUANTILES }
    } else {
        if (defined $st->{pmin}[$i]) { push @pct, (percentile_cols($st, $i, $_->[1], $arm eq 'K4'))[0] for @QUANTILES }
        else                         { @pct = (0) x @QUANTILES }
    }
    return ($st->{mn}[$i], $st->{mx}[$i], $mean, $std_dev, $cv, @pct);
}

sub population_hash {                  # walk + stats for every eligible key; returns {key => p99}
    my ($lm, $ctr, $category) = @_;
    my (%p99, @fill_block);
    foreach my $log_key (keys %{$lm->{$category}}) {
        my $entry = $lm->{$category}{$log_key};
        my $n = $entry->{duration_count} // 0;
        if (!$message_duration_stats_demand || $n < $n_floor || !defined $entry->{occurrences}) {
            push @fill_block, $log_key;
            next;
        }
        my @s = stats_hash($entry, $ctr->{"$category\x1f$log_key"});
        $p99{$log_key} = $s[7];
    }
    return (\%p99, \@fill_block);
}
sub population_cols {
    my ($st) = @_;
    my ($occ, $dc) = @$st{qw(occ dc)};
    my (%p99, @fill_block);
    for my $i (0 .. $#$occ) {
        next unless defined $occ->[$i];
        my $n = $dc->[$i] // 0;
        if (!$message_duration_stats_demand || $n < $n_floor) { push @fill_block, $i; next }
        my @s = stats_cols($st, $i);
        $p99{$i} = $s[7];
    }
    return (\%p99, \@fill_block);
}
sub walk_only_hash {
    my ($lm, $category) = @_;
    my ($e, $f) = (0, 0);
    foreach my $log_key (keys %{$lm->{$category}}) {
        my $entry = $lm->{$category}{$log_key};
        my $n = $entry->{duration_count} // 0;
        if (!$message_duration_stats_demand || $n < $n_floor || !defined $entry->{occurrences}) { $f++; next }
        $e++;
    }
    return ($e, $f);
}
sub walk_only_cols {
    my ($st) = @_;
    my ($occ, $dc) = @$st{qw(occ dc)};
    my ($e, $f) = (0, 0);
    for my $i (0 .. $#$occ) {
        next unless defined $occ->[$i];
        my $n = $dc->[$i] // 0;
        if (!$message_duration_stats_demand || $n < $n_floor) { $f++; next }
        $e++;
    }
    return ($e, $f);
}

sub keymap {
    my ($st) = @_;
    my ($ord, $key) = @$st{qw(ord key)};
    @$key = ();
    while (my ($k, $i) = each %$ord) { $key->[$i] = $k }
}

## Deletion churn: the -g final pass merges each key into a cluster (attach
## the counter entry, read, detach) and deletes both stores' entries.
sub churn_hash {
    my ($lm, $ctr, $category, $sorted_keys, $frac) = @_;
    my $n_del = int($frac * @$sorted_keys);
    my $sum = 0;
    for my $k (@$sorted_keys[0 .. $n_del - 1]) {
        my $source = $lm->{$category}{$k};
        my $key = "$category\x1f$k";
        $source->{bin_entry} = $ctr->{$key};
        $sum += $source->{occurrences} + ($source->{bin_entry} ? $source->{bin_entry}{overflow} : 0);
        delete $ctr->{$key};
        delete $source->{bin_entry};
        delete $lm->{$category}{$k};
    }
    my $n_inj = int(0.01 * @$sorted_keys) || 1;
    for my $j (1 .. $n_inj) {
        my $k = "[ERROR] [cluster-thread] [c.t.cluster] canonical pattern $j absorbed ##### keys";
        $lm->{$category}{$k} = { occurrences => 100 + $j, is_consolidated => 1, duration_count => 1, _running_mean => $j, min => $j, max => $j, total_duration => $j, sum_of_squares => $j * $j };
        counter_update($ctr, "$category\x1f$k", $j);
    }
    return $sum;
}
sub churn_cols {
    my ($st, $sorted_keys, $frac) = @_;
    my ($ord, $occ) = @$st{qw(ord occ)};
    my @cols = map { $st->{$_} } (@REC_COLS, @CTR_COLS, 'key');
    my $n_del = int($frac * @$sorted_keys);
    my $sum = 0;
    for my $k (@$sorted_keys[0 .. $n_del - 1]) {
        my $i = delete $ord->{$k};
        $sum += $occ->[$i] + ($arm eq 'K2' ? ($st->{ctr}[$i] ? $st->{ctr}[$i]{overflow} : 0) : ($st->{over}[$i] // 0));
        $_->[$i] = undef for @cols;
        $st->{dead}++;
    }
    my $n_inj = int(0.01 * @$sorted_keys) || 1;
    for my $j (1 .. $n_inj) {
        my $k = "[ERROR] [cluster-thread] [c.t.cluster] canonical pattern $j absorbed ##### keys";
        my $i = $ord->{$k} = $st->{n}++;
        $st->{occ}[$i] = 100 + $j; $st->{dc}[$i] = 1; $st->{rm}[$i] = $j; $st->{mn}[$i] = $j; $st->{mx}[$i] = $j;
        $st->{td}[$i] = $j; $st->{ss}[$i] = $j * $j; $st->{key}[$i] = $k;
        if ($arm eq 'K2') { counter_update_row($st->{ctr}, $i, $j) }
        else {
            $st->{pmin}[$i] = $j / $SEED_HALF; $st->{pmax}[$i] = $j * $SEED_HALF; $st->{pbc}[$i] = $SEED_BC;
            $st->{plr}[$i] = log($st->{pmax}[$i] / $st->{pmin}[$i]); $st->{prb}[$i] = 0; $st->{over}[$i] = 0; $st->{under}[$i] = 0;
            my $idx = int($SEED_BC * log($j / $st->{pmin}[$i]) / $st->{plr}[$i]);
            $st->{bins}[$i] = $arm eq 'K4' ? [ $idx, 1 ] : do { my @b; $b[$idx] = 1; \@b };
        }
    }
    return $sum;
}
sub compact_cols {
    my ($st) = @_;
    my $occ = $st->{occ};
    my @live = grep { defined $occ->[$_] } 0 .. $#$occ;
    my @map; $map[$live[$_]] = $_ for 0 .. $#live;
    for my $c (@REC_COLS, @CTR_COLS, 'key') {
        my $a = $st->{$c};
        @$a = @{$a}[@live];
    }
    my $ord = $st->{ord};
    while (my ($k, $i) = each %$ord) { $ord->{$k} = $map[$i] }
    $st->{n} = scalar @live;
    $st->{dead} = 0;
}

## ---------------------------------------------------------------------------
## Parity: per-key rows (record fields, canonical bins as index:count pairs,
## the derived statistics) — identical across arms.
## ---------------------------------------------------------------------------
sub canon_bins_hash {
    my ($c) = @_;
    return '' unless $c;
    my $b = $c->{bins};
    return join(',', (map { defined $b->[$_] && $b->[$_] ? "$_:$b->[$_]" : () } 0 .. $#$b), "o$c->{overflow}", "u$c->{underflow}",
                sprintf('%.12g/%.12g/%d/%d', $c->{partition}{min}, $c->{partition}{max}, $c->{partition}{bin_count}, $c->{partition}{rebins}));
}
sub canon_bins_cols {
    my ($st, $i) = @_;
    return canon_bins_hash($st->{ctr}[$i]) if $arm eq 'K2';
    return '' unless defined $st->{pmin}[$i];
    my $b = $st->{bins}[$i] // [];
    my @pairs;
    if ($arm eq 'K4') { my ($base, @c) = @$b; push @pairs, map { $c[$_] ? ($base + $_) . ":$c[$_]" : () } 0 .. $#c }
    else              { push @pairs, map { defined $b->[$_] && $b->[$_] ? "$_:$b->[$_]" : () } 0 .. $#$b }
    return join(',', @pairs, "o" . ($st->{over}[$i] // 0), "u" . ($st->{under}[$i] // 0),
                sprintf('%.12g/%.12g/%d/%d', $st->{pmin}[$i], $st->{pmax}[$i], $st->{pbc}[$i], $st->{prb}[$i]));
}
sub fmt { join("\t", map { defined $_ ? $_ : '' } @_) }
sub digest_hash {
    my ($lm, $ctr) = @_;
    my $d = Digest::MD5->new; my $n = 0;
    for my $cat (sort keys %$lm) {
        for my $k (sort keys %{$lm->{$cat}}) {
            my $e = $lm->{$cat}{$k};
            $d->add(fmt($cat, $k, @$e{qw(occurrences total_bytes total_duration sum_of_squares duration_count _running_mean min max impact count_sum count_occurrences count_min count_max)},
                        canon_bins_hash($ctr->{"$cat\x1f$k"}), stats_hash($e, $ctr->{"$cat\x1f$k"})), "\n");
            $n++;
        }
    }
    return ($d->hexdigest, $n);
}
sub digest_cols {
    my ($store) = @_;
    my $d = Digest::MD5->new; my $n = 0;
    for my $cat (sort keys %$store) {
        my $st = $store->{$cat};
        for my $k (sort keys %{$st->{ord}}) {
            my $i = $st->{ord}{$k};
            $d->add(fmt($cat, $k, (map { $st->{$_}[$i] } qw(occ tb td ss dc rm mn mx imp csum ccnt cmin cmax)), canon_bins_cols($st, $i), stats_cols($st, $i)), "\n");
            $n++;
        }
    }
    return ($d->hexdigest, $n);
}
sub top10_by_p99 {                      # {key => p99} -> digest of top-10 keys (desc p99, key tiebreak)
    my ($p99, $key) = @_;
    my @ks = sort { ($p99->{$b} <=> $p99->{$a}) || (($key ? $key->[$a] : $a) cmp ($key ? $key->[$b] : $b)) } keys %$p99;
    @ks = map { $key->[$_] } @ks if $key;
    return Digest::MD5::md5_hex(join("\n", @ks[0 .. min($#ks, $top_n_messages - 1)]));
}

## ---------------------------------------------------------------------------
## Run.
## ---------------------------------------------------------------------------
Measure58::tsv_header(\*STDOUT) unless $no_header;
my $cand = "arm-$arm";
my $emit = sub {
    my ($metric, @secs) = @_;
    my ($med, $min, $max) = Measure58::median_min_max(@secs);
    Measure58::emit_tsv(\*STDOUT, $cand, $fixture, $LINES::n // 0, $metric, $med, $min, $max);
};

my $rss0 = Measure58::rss_kb();
my @build_secs;
my $t0 = [gettimeofday];
my $S = $build->($file);
push @build_secs, tv_interval($t0);
$LINES::n = $S->{lines};
my $rss_after_build = Measure58::rss_kb();
for (2 .. $runs) {
    my $t = [gettimeofday];
    my $tmp = $build->($file);
    push @build_secs, tv_interval($t);
    undef $tmp;
}
$emit->('build_ns_per_line', map { $_ / $S->{lines} * 1e9 } @build_secs);
$emit->('rss_delta_after_build_kb', ($rss_after_build - $rss0) x 3);

my $category = 'plain';
my ($lm, $ctr, $st) = ($S->{lm}, $S->{ctr}, $S->{store} ? $S->{store}{$category} : undef);
my $distinct = $is_columnar ? scalar keys %{$st->{ord}} : scalar keys %{$lm->{$category}};
$emit->('distinct_keys', ($distinct) x 3);
my $extensions = 0;
if ($is_columnar) {
    if ($arm eq 'K2') { $extensions += $_->{partition}{rebins} for grep { $_ } @{$st->{ctr}} }
    else              { $extensions += $_ // 0 for @{$st->{prb}} }
} else {
    $extensions += $_->{partition}{rebins} for values %$ctr;
}
$emit->('partition_extensions', ($extensions) x 3);

if ($is_columnar) {
    $emit->('keymap_s', Measure58::time_runs($runs, sub { keymap($st) }));
    my $counter_bytes = $arm eq 'K2' ? total_size($st->{ctr}) : sum0(map { total_size($st->{$_}) } @CTR_COLS);
    $emit->('devel_size_record_bytes', (total_size($S->{store}) - $counter_bytes - total_size($st->{key})) x 3);
    $emit->('devel_size_counter_bytes', ($counter_bytes) x 3);
} else {
    $emit->('devel_size_record_bytes', (total_size($lm)) x 3);
    $emit->('devel_size_counter_bytes', (total_size($ctr)) x 3);
}

my ($p99, $fill_block);
my $walk = $is_columnar ? sub { walk_only_cols($st) } : sub { walk_only_hash($lm, $category) };
my $pop  = $is_columnar ? sub { ($p99, $fill_block) = population_cols($st) } : sub { ($p99, $fill_block) = population_hash($lm, $ctr, $category) };
$emit->('walk_s', Measure58::time_runs($runs, $walk));
$emit->('population_stats_s', Measure58::time_runs($runs, $pop));
$pop->();
$emit->('eligible_keys', (scalar keys %$p99) x 3);

my ($store_digest, $rows) = $is_columnar ? digest_cols($S->{store}) : digest_hash($lm, $ctr);
printf STDERR "PARITY\t%s\t%s\tstore=%s rows=%d avail=%s fill=%s\n",
    $fixture, $cand, $store_digest, $rows, top10_by_p99($p99, $is_columnar ? $st->{key} : undef), Digest::MD5::md5_hex(scalar @$fill_block);

my @sorted_keys = $is_columnar ? sort keys %{$st->{ord}} : sort keys %{$lm->{$category}};
my $t_churn = [gettimeofday];
my $absorbed = $is_columnar ? churn_cols($st, \@sorted_keys, $churn_frac) : churn_hash($lm, $ctr, $category, \@sorted_keys, $churn_frac);
$emit->('churn_s', (tv_interval($t_churn)) x 3);
$emit->('churn_population_stats_s', Measure58::time_runs($runs, $pop));
$pop->();
my $churn_digest = $is_columnar ? (digest_cols($S->{store}))[0] : (digest_hash($lm, $ctr))[0];
printf STDERR "PARITY\t%s\t%s\tchurn=%s absorbed=%d churn_fill=%s\n", $fixture, $cand, $churn_digest, $absorbed, top10_by_p99($p99, $is_columnar ? $st->{key} : undef);
if ($is_columnar) {
    my $t_c = [gettimeofday];
    compact_cols($st);
    $emit->('compact_s', (tv_interval($t_c)) x 3);
    $emit->('compact_population_stats_s', Measure58::time_runs($runs, $pop));
    $pop->();
    printf STDERR "PARITY\t%s\t%s\tcompact=%s\n", $fixture, $cand, (digest_cols($S->{store}))[0];
}
