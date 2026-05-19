#!/usr/bin/env perl
# Prototype for issue #189 — unified histogram bin-counter primitives.
# Validates the architectural contract locked in issue #187 against real D2 data
# before #189 production implementation begins (per #187 Decision 10).
#
# Five validation aspects:
#   V1 — In-bin Prometheus formula behavior on real data + edge cases
#   V2 — Auto-resize lifecycle on per-key fan-out at scale + R2 algorithm benchmark
#   V3 — Initial seeding heuristic + overflow/underflow audit
#   V4 — End-to-end -V output sample per Decision 8 format
#   V5 — Calculation accuracy vs ltl's existing calculate_statistics oracle
#
# This is a prototype: standalone, not part of ltl proper. Findings inform #189.

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case bundling);
use POSIX qw(ceil floor);
use List::Util qw(sum min max);
use Time::HiRes qw(gettimeofday tv_interval);

# Devel::Size is optional (gated by --mem); load lazily so the prototype runs
# without it for V1/V3/V4/V5.
my $have_devel_size = 0;
eval { require Devel::Size; Devel::Size->import('total_size'); $have_devel_size = 1; };

# ============================================================================
# CLI
# ============================================================================

my %opt = (
    aspect              => undef,
    file                => [],
    bpd                 => 53,           # Decision 2 default
    seed_decades        => 5,            # Decision 5 default
    quantiles           => '0.01,0.5,0.75,0.9,0.95,0.99,0.999',
    'r2-impl'           => 'closed',     # closed|binary|linear
    'r2-cross-check'    => 0,            # V1: all 3 algos must agree
    'r2-bench'          => 0,            # V2: run all 3 sequentially, report per-algo time + memory
    'max-rebins'        => undef,        # V3: cap rebins to force overflow
    'min-N'             => 100,          # V5: only compare keys with >= N durations
    mem                 => 0,
    'exact-percentiles' => 0,            # V4 opt-out simulation
    'percentile-precision' => undef,
    pbpd                => undef,
    'max-keys'          => undef,        # V2 safety cap
    'max-lines'         => undef,
);

GetOptions(\%opt,
    'aspect=s', 'file=s@', 'bpd=i', 'seed_decades|seed-decades=i',
    'quantiles=s', 'r2-impl=s', 'r2-cross-check!', 'r2-bench!',
    'max-rebins=i', 'min-N=i', 'mem!', 'exact-percentiles!',
    'percentile-precision=i', 'pbpd=i', 'max-keys=i', 'max-lines=i',
    'help|h',
) or die_usage("bad options");

die_usage() if !defined $opt{aspect};

sub die_usage {
    my $msg = shift;
    print STDERR "ERROR: $msg\n\n" if defined $msg;
    print STDERR <<'EOF';
Usage: prototype/189-bin-counter-primitives.pl --aspect v1|v2|v3|v4|v5|all
                                                --file PATH [--file PATH ...]
                                                [--bpd N] [--seed-decades N]
                                                [--quantiles q1,q2,...]
                                                [--r2-impl closed|binary|linear]
                                                [--r2-cross-check] [--r2-bench]
                                                [--max-rebins N] [--min-N N]
                                                [--mem] [--exact-percentiles]
                                                [--percentile-precision N]
                                                [--pbpd N]
                                                [--max-keys N] [--max-lines N]
EOF
    exit 2;
}

# Resolve precision per Decision 2 (-pbpd wins over --percentile-precision).
my $precision_source = 'default';
if (defined $opt{pbpd}) {
    $opt{bpd} = $opt{pbpd};
    $precision_source = defined $opt{'percentile-precision'}
        ? "-pbpd $opt{pbpd}; --percentile-precision $opt{'percentile-precision'} overridden"
        : "-pbpd $opt{pbpd}";
} elsif (defined $opt{'percentile-precision'}) {
    my %level_to_bpd = (1=>4, 2=>8, 3=>16, 4=>32, 5=>53, 6=>80, 7=>115, 8=>256, 9=>616);
    my $lvl = $opt{'percentile-precision'};
    die_usage("--percentile-precision must be 1..9") unless exists $level_to_bpd{$lvl};
    $opt{bpd} = $level_to_bpd{$lvl};
    $precision_source = "--percentile-precision $lvl";
}

my @quantiles = sort { $a <=> $b } map { $_ + 0 } split /,/, $opt{quantiles};

# ============================================================================
# Parsing (from prototype/96-fuzzy-consolidation.pl:228, :268)
# ============================================================================

# Tomcat access log regex — verbatim from prototype/96-fuzzy-consolidation.pl:228
my $access_log_regex = qr/^(.+? ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)[ ]?([0-9.]+)?[ ]?(\S+)?[ ]?(\S+)?/;

# ThingWorx ApplicationLog regex — verbatim from prototype/96:225 (kept for future use; durations come from access logs in V5/V2)
my $twx_regex = qr/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})[\+\-]\d{4} \[L: ([^\]]*)\] \[O: ([^\]]*)] \[I: ([^\]]*)] \[U: ([^\]]*)] \[S: ([^\]]*)] \[P: ([^\]]*)] \[T: ((?:\](?! )|[^\]])*)] (.*)/;

# parse_line($line) -> ($category, $log_key, $duration) or () if unmatched
# Mirrors prototype/96:268-291 key construction for Tomcat access logs.
sub parse_line {
    my ($line) = @_;
    chomp $line;

    if (my (undef, undef, $msg, $status_code, undef, $duration_val, $thr, undef) = $line =~ $access_log_regex) {
        $msg =~ s/ HTTP\/\d\.\d$//;
        $msg =~ s/\?.+$//;
        my $category = $status_code;
        $category =~ s/(\d)\d{2}/$1xx/;

        my $threadname;
        if (defined $thr && $thr ne "") {
            my ($threadpool) = $thr =~ /(.*)-\d+$/;
            $threadname = defined $threadpool ? $threadpool : $thr;
        }

        my $log_key;
        if (defined $threadname) {
            my $truncated_thread = substr($threadname, 0, 20);
            $log_key = substr("[$status_code] [$truncated_thread] $msg", 0, 350);
        } else {
            $log_key = substr("[$status_code] $msg", 0, 350);
        }

        # Duration must be a clean numeric (digits with optional decimal).
        # Corrupted access log lines occasionally concatenate two records;
        # the regex's loose ([0-9.]+)? then catches an IP-address fragment.
        # Drop anything that isn't a clean numeric literal.
        my $duration;
        if (defined $duration_val && $duration_val =~ /\A\d+(?:\.\d+)?\z/) {
            $duration = $duration_val + 0;
        }
        return ($category, $log_key, $duration);
    }

    # ThingWorx fallback (durations come from `durationMs=N` in the message body)
    if (my ($ts, $cat, $object, undef, undef, undef, undef, $thread, $message) = $line =~ $twx_regex) {
        my $truncated_thread = substr($thread, 0, 20);
        my $max_object_length = 25;
        my $truncated_object = substr($object, length($object) > $max_object_length ? length($object) - $max_object_length : 0, $max_object_length);
        my $log_key = substr("[$cat] [$truncated_thread] [$truncated_object] $message", 0, 350);
        my ($duration) = $message =~ / durationM[sS]\s*=\s*(\d+)/;
        $duration = (defined $duration) ? $duration + 0 : undef;
        return ($cat, $log_key, $duration);
    }

    return ();
}

# iterate_durations($file, $cb) — stream lines, drop non-positive durations.
# The contract defines underflow as 0 < value < min, so non-positive values are
# dropped before partitions see them (Decision 4 / R6).
sub iterate_durations {
    my ($file, $cb) = @_;
    open(my $fh, '<', $file) or die "Cannot open $file: $!\n";
    my $lines = 0;
    while (my $line = <$fh>) {
        $lines++;
        last if defined $opt{'max-lines'} && $lines > $opt{'max-lines'};
        my ($cat, $log_key, $dur) = parse_line($line);
        next unless defined $dur && $dur > 0;
        $cb->($cat, $log_key, $dur);
    }
    close $fh;
    return $lines;
}

# ============================================================================
# R1 — Partition (auto-resize lifecycle, Decision 5)
# ============================================================================
#
# Seed: min = v0 / sqrt(10^seed_decades), max = v0 * sqrt(10^seed_decades).
# Boundary geometry: boundary[i] = min * (max/min)^(i/B). Same formula as
# ltl:4961-4966.
# Rebin: HdrHistogram-convention doubling — new_max >= current_max *
# 10^(seed_decades/2) symmetric for low end. Copy-on-resize for clarity.
# Existing bin counts are remapped through R2 against the new partition (correct
# under any of the three R2 implementations because the boundary geometry is
# index-monotonic in the extension direction).

sub partition_new {
    my ($v0, $bpd, $seed_decades) = @_;
    my $half_span = sqrt(10 ** $seed_decades);
    my $min = $v0 / $half_span;
    my $max = $v0 * $half_span;
    my $bin_count = int($bpd * $seed_decades);
    my $p = {
        min        => $min,
        max        => $max,
        bpd        => $bpd,
        decades    => $seed_decades,
        bin_count  => $bin_count,
        log_ratio  => log($max / $min),     # cached for closed-form R2
        rebins     => 0,
        max_rebins => $opt{'max-rebins'},   # V3: artificial cap
    };
    # Boundary array is built lazily by _ensure_boundaries() when binary or
    # linear R2 needs it. Closed-form R2 needs only the scalars.
    return $p;
}

sub _ensure_boundaries {
    my ($p) = @_;
    return if exists $p->{boundaries};
    my @b;
    my $ratio = $p->{max} / $p->{min};
    for my $i (0 .. $p->{bin_count}) {
        push @b, $p->{min} * ($ratio ** ($i / $p->{bin_count}));
    }
    $p->{boundaries} = \@b;
}

sub _invalidate_boundaries {
    my ($p) = @_;
    delete $p->{boundaries};
    $p->{log_ratio} = log($p->{max} / $p->{min});
}

# partition_extend($p, $value, \@old_bins) — extend min or max to contain $value
# via HdrHistogram doubling. Returns new bins array (counts remapped). Returns
# undef (and does NOT extend) when --max-rebins cap reached, in which case the
# caller increments the overflow/underflow counter instead.
sub partition_extend {
    my ($p, $value, $old_bins_ref) = @_;
    return undef if defined $p->{max_rebins} && $p->{rebins} >= $p->{max_rebins};

    my $double_factor = 10 ** ($p->{decades} / 2);
    my ($new_min, $new_max) = ($p->{min}, $p->{max});

    while ($value > $new_max || $value < $new_min) {
        if ($value > $new_max) {
            $new_max *= $double_factor;
        } else {
            $new_min /= $double_factor;
        }
    }

    # Re-derive bin_count from the new span so per-decade resolution is preserved.
    my $new_decades = log10($new_max / $new_min);
    my $new_bin_count = int($p->{bpd} * $new_decades);
    $new_bin_count = $p->{bin_count} if $new_bin_count < $p->{bin_count};

    # Remap existing bin counts: each old bin's geometric midpoint maps to a new
    # bin via the new partition's R2. Index-monotonic in the extension direction
    # so counts cluster onto a contiguous range of new indices.
    _ensure_boundaries($p);
    my @new_bins;
    for my $old_i (0 .. $p->{bin_count} - 1) {
        my $count = $old_bins_ref->[$old_i];
        next unless defined $count && $count > 0;
        my $lower = $p->{boundaries}->[$old_i];
        my $upper = $p->{boundaries}->[$old_i + 1];
        my $midpoint = sqrt($lower * $upper);
        # Compute new bin index using the new geometry directly.
        my $new_log_ratio = log($new_max / $new_min);
        my $new_i = int($new_bin_count * log($midpoint / $new_min) / $new_log_ratio);
        $new_i = 0 if $new_i < 0;
        $new_i = $new_bin_count - 1 if $new_i >= $new_bin_count;
        $new_bins[$new_i] = ($new_bins[$new_i] // 0) + $count;
    }

    $p->{min}       = $new_min;
    $p->{max}       = $new_max;
    $p->{bin_count} = $new_bin_count;
    $p->{rebins}++;
    _invalidate_boundaries($p);

    return \@new_bins;
}

sub log10 { return log($_[0]) / log(10); }

# ============================================================================
# R2 — Bin assignment (three implementations behind --r2-impl)
# ============================================================================
#
# Returns:
#   ('IN',       $bin_index)     value is in [partition.min, partition.max]
#   ('OVERFLOW', undef)          value > partition.max
#   ('UNDERFLOW',undef)          0 < value < partition.min

sub r2_closed {
    my ($p, $v) = @_;
    return ('UNDERFLOW', undef) if $v < $p->{min};
    return ('OVERFLOW',  undef) if $v > $p->{max};
    my $i = int($p->{bin_count} * log($v / $p->{min}) / $p->{log_ratio});
    $i = $p->{bin_count} - 1 if $i >= $p->{bin_count};
    $i = 0 if $i < 0;
    return ('IN', $i);
}

sub r2_binary {
    my ($p, $v) = @_;
    return ('UNDERFLOW', undef) if $v < $p->{min};
    return ('OVERFLOW',  undef) if $v > $p->{max};
    _ensure_boundaries($p);
    my $b = $p->{boundaries};
    my $lo = 0;
    my $hi = $p->{bin_count} - 1;
    # Match ltl:4895-4903 semantics: find largest i with boundary[i] <= v.
    while ($lo < $hi) {
        my $mid = int(($lo + $hi + 1) / 2);
        if ($b->[$mid] <= $v) {
            $lo = $mid;
        } else {
            $hi = $mid - 1;
        }
    }
    return ('IN', $lo);
}

sub r2_linear {
    my ($p, $v) = @_;
    return ('UNDERFLOW', undef) if $v < $p->{min};
    return ('OVERFLOW',  undef) if $v > $p->{max};
    _ensure_boundaries($p);
    my $b = $p->{boundaries};
    # Match ltl:4785-4789 semantics: linear scan until b[i+1] > v.
    for my $i (0 .. $p->{bin_count} - 1) {
        return ('IN', $i) if $b->[$i + 1] > $v;
    }
    return ('IN', $p->{bin_count} - 1);
}

sub bin_assign {
    my ($p, $v, $impl) = @_;
    $impl //= $opt{'r2-impl'};
    return r2_closed($p, $v) if $impl eq 'closed';
    return r2_binary($p, $v) if $impl eq 'binary';
    return r2_linear($p, $v) if $impl eq 'linear';
    die "Unknown --r2-impl: $impl";
}

# ============================================================================
# R3 — Counter update (parameterized keying)
# ============================================================================
#
# $store is a hashref: { join("\x1f", @key) => { partition, bins, overflow,
# underflow, rebins } }. Lazy partition construction on first observation.
# Per-key counter store is independently freeable.

sub counter_update {
    my ($store, $key, $value, $impl) = @_;
    my $entry = $store->{$key};
    if (!$entry) {
        $entry = $store->{$key} = {
            partition => partition_new($value, $opt{bpd}, $opt{seed_decades}),
            bins      => [],
            overflow  => 0,
            underflow => 0,
        };
    }

    my ($where, $idx) = bin_assign($entry->{partition}, $value, $impl);
    if ($where eq 'IN') {
        $entry->{bins}->[$idx] = ($entry->{bins}->[$idx] // 0) + 1;
        return;
    }

    # Out of range: try to extend the partition (Decision 5 auto-resize).
    my $new_bins = partition_extend($entry->{partition}, $value, $entry->{bins});
    if (defined $new_bins) {
        $entry->{bins} = $new_bins;
        # Re-assign the value into the new partition.
        my ($w2, $i2) = bin_assign($entry->{partition}, $value, $impl);
        if ($w2 eq 'IN') {
            $entry->{bins}->[$i2] = ($entry->{bins}->[$i2] // 0) + 1;
        } elsif ($w2 eq 'OVERFLOW') {
            $entry->{overflow}++;
        } else {
            $entry->{underflow}++;
        }
        return;
    }

    # Growth cap reached (V3 with --max-rebins 0): increment over/underflow.
    if ($where eq 'OVERFLOW') {
        $entry->{overflow}++;
    } else {
        $entry->{underflow}++;
    }
}

# ============================================================================
# R4 — Percentile interpolation (Prometheus formula, Decision 1)
# ============================================================================
#
# Returns ($value, $audit) where $audit ∈ ('none', 'low', 'high').
# Decision 1 formula: lower * (upper/lower)^fraction
# Equivalent to 2^(log2(lower) + (log2(upper)-log2(lower))*fraction).
# Geometric form chosen for numerical stability.
#
# Decision 1A: use rank_in_bin (we have the information).
# Decision 4: overflow/underflow contribute to total_N; rank in those slots
# returns boundary[B] or boundary[0].

sub percentile {
    my ($entry, $q, %opts) = @_;
    my $use_oracle_indexing = $opts{oracle_indexing} // 0;  # V5 binning-only error mode

    my $p = $entry->{partition};
    my $bins = $entry->{bins};
    my $under = $entry->{underflow} // 0;
    my $over  = $entry->{overflow}  // 0;

    my $in_total = 0;
    $in_total += ($_ // 0) for @$bins;
    my $total_N = $under + $in_total + $over;
    return (undef, 'none') if $total_N == 0;

    # Decision 1: target_rank = ceil(q * total_N). V5 binning-only mode uses
    # int(q*N)+1 to match ltl's int($n*fraction) 0-based indexing for fair
    # comparison.
    my $target_rank = $use_oracle_indexing
        ? int($q * $total_N) + 1
        : ceil($q * $total_N);
    $target_rank = 1 if $target_rank < 1;
    $target_rank = $total_N if $target_rank > $total_N;

    # Walk: underflow -> in-range bins (low to high) -> overflow.
    my $cum = 0;
    if ($under > 0) {
        $cum += $under;
        if ($target_rank <= $cum) {
            _ensure_boundaries($p);
            return ($p->{boundaries}->[0], 'low');
        }
    }
    for my $i (0 .. $p->{bin_count} - 1) {
        my $c = $bins->[$i] // 0;
        next if $c == 0;
        $cum += $c;
        if ($target_rank <= $cum) {
            _ensure_boundaries($p);
            my $lower = $p->{boundaries}->[$i];
            my $upper = $p->{boundaries}->[$i + 1];
            my $rank_in_bin = $target_rank - ($cum - $c);
            my $fraction = $rank_in_bin / $c;
            # Decision 1 formula. Geometric form.
            my $value = $lower * (($upper / $lower) ** $fraction);
            return ($value, 'none');
        }
    }
    # Must be in overflow.
    _ensure_boundaries($p);
    return ($p->{boundaries}->[$p->{bin_count}], 'high');
}

# ============================================================================
# Oracle — copy of ltl:5488-5528 (V5 only)
# ============================================================================
# Faithful mirror including the int($n * fraction) 0-based-indexing quirk so V5
# compares apples to apples against today's user-facing percentiles.

sub calculate_statistics_oracle {
    my ($durations_ref) = @_;
    return unless @$durations_ref;
    my @sorted = sort { $a <=> $b } @$durations_ref;
    my $n = scalar @sorted;
    return {
        min  => $sorted[0],
        max  => $sorted[-1],
        p1   => $sorted[int($n * 0.01)],
        p50  => $sorted[int($n * 0.5)],
        p75  => $sorted[int($n * 0.75)],
        p90  => $sorted[int($n * 0.9)],
        p95  => $sorted[int($n * 0.95)],
        p99  => $sorted[int($n * 0.99)],
        p999 => $sorted[int($n * 0.999)],
        n    => $n,
    };
}

sub q_label {
    my $q = shift;
    # Match the labels the oracle returns: p1, p50, p75, p90, p95, p99, p999.
    # Convention: drop "0." prefix; for q with fractional part beyond .9, keep
    # the trailing digits (p999 = 0.999, p9999 = 0.9999). For round-ten q
    # (0.5, 0.75, 0.9, 0.95, 0.99) pad single-digit second decimal: 0.9 -> p90.
    my %fixed = (
        0.01   => 'p1',
        0.1    => 'p10',
        0.25   => 'p25',
        0.5    => 'p50',
        0.75   => 'p75',
        0.9    => 'p90',
        0.95   => 'p95',
        0.99   => 'p99',
        0.999  => 'p999',
        0.9999 => 'p9999',
    );
    return $fixed{$q} if exists $fixed{$q};
    # Fallback: strip "0." and trailing zeros for any other q.
    my $s = sprintf("%.6f", $q);
    $s =~ s/^0\.//;
    $s =~ s/0+$//;
    return "p$s";
}

# ============================================================================
# Telemetry (Decision 8 format)
# ============================================================================

sub partition_dist {
    my @vals = sort { $a <=> $b } @_;
    return (0, 0, 0, 0) unless @vals;
    my $pick = sub {
        my $q = shift;
        my $i = int(@vals * $q);
        $i = $#vals if $i > $#vals;
        return $vals[$i];
    };
    return ($pick->(0.5), $pick->(0.95), $pick->(0.99), $vals[-1]);
}

sub emit_telemetry {
    my ($store, %args) = @_;
    my $consumer = $args{consumer} // 'summary_table';
    my $keying   = $args{keying}   // '(category, log_key)';
    my $path     = $opt{'exact-percentiles'} ? 'user_opt_out' : 'unified';

    print "\n=== PERCENTILE MODE ===\n";
    print "opt_out_active: ", ($opt{'exact-percentiles'} ? 'yes' : 'no'), "\n";
    if ($opt{'exact-percentiles'}) {
        print "opt_out_notice: --exact-percentiles is set; all migrated consumers reverted to pre-#187 sort-based computation. This flag is deprecated and will be removed in a future release.\n";
    }
    # Per #187 Decision 8 (refined by #195 Bucket A5): render literal "n/a" when
    # -pbpd resolved to a non-tier value (no matching LEVEL in Decision 2's
    # locked tier table). The literal string "n/a" is part of Decision 8's
    # locked stability contract for this field.
    my $precision_label;
    if (defined $opt{'percentile-precision'}) {
        $precision_label = $opt{'percentile-precision'};
    } elsif ($precision_source eq 'default') {
        $precision_label = 5;
    } else {
        $precision_label = 'n/a';
    }
    my $not_in_effect = $opt{'exact-percentiles'} ? '; not in effect this run' : '';
    print "percentile_precision: $precision_label ($precision_source$not_in_effect)\n";
    print "buckets_per_decade: $opt{bpd} ($precision_source$not_in_effect)\n";

    if (!%$store) {
        print "consumers_active: none\n";
        return;
    }
    if ($opt{'exact-percentiles'}) {
        print "\nconsumer: $consumer\n";
        print "  path: user_opt_out\n";
        return;
    }

    my @rebin_counts;
    my $total_rebins = 0;
    my $max_bins = 0;
    my $overflow_partitions = 0;
    my $underflow_partitions = 0;
    my $mem_bytes = 0;
    for my $key (keys %$store) {
        my $e = $store->{$key};
        my $r = $e->{partition}->{rebins};
        push @rebin_counts, $r;
        $total_rebins += $r;
        $max_bins = $e->{partition}->{bin_count} if $e->{partition}->{bin_count} > $max_bins;
        $overflow_partitions++  if ($e->{overflow}  // 0) > 0;
        $underflow_partitions++ if ($e->{underflow} // 0) > 0;
    }
    if ($opt{mem} && $have_devel_size) {
        $mem_bytes = total_size($store);
    }
    my ($rp50, $rp95, $rp99, $rmax) = partition_dist(@rebin_counts);

    # Per-quantile out_of_range_bounded audit aggregate.
    my %audit_seen;
    for my $key (keys %$store) {
        my $e = $store->{$key};
        for my $q (@quantiles) {
            my (undef, $audit) = percentile($e, $q);
            $audit_seen{$q}->{$audit}++ if defined $audit;
        }
    }
    my @audit_line;
    for my $q (@quantiles) {
        my $worst = 'none';
        if    ($audit_seen{$q}->{high}) { $worst = 'high'; }
        elsif ($audit_seen{$q}->{low})  { $worst = 'low'; }
        push @audit_line, q_label($q) . "=$worst";
    }

    print "\nconsumer: $consumer\n";
    print "  path: $path\n";
    print "  partition_keying: $keying\n";
    printf "  partition_count: %d\n", scalar keys %$store;
    print "  total_rebin_events: $total_rebins\n";
    print "  max_partition_bins: $max_bins\n";
    print "  partitions_with_overflow_count: $overflow_partitions\n";
    print "  partitions_with_underflow_count: $underflow_partitions\n";
    if ($opt{mem} && $have_devel_size) {
        print "  counter_memory_bytes: $mem_bytes\n";
    }
    print "  rebins_per_partition: p50=$rp50 p95=$rp95 p99=$rp99 max=$rmax\n";
    print "  percentiles_emitted: ", join(' ', map { q_label($_) } @quantiles), "\n";
    print "  out_of_range_bounded: ", join(' ', @audit_line), "\n";
}

# ============================================================================
# Aspect dispatch
# ============================================================================

my $aspect = lc $opt{aspect};
if    ($aspect eq 'v5')  { run_v5(); }
elsif ($aspect eq 'v1')  { run_v1(); }
elsif ($aspect eq 'v3')  { run_v3(); }
elsif ($aspect eq 'v2')  { run_v2(); }
elsif ($aspect eq 'v4')  { run_v4(); }
elsif ($aspect eq 'all') { run_v5(); run_v1(); run_v3(); run_v2(); run_v4(); }
else { die_usage("unknown --aspect $opt{aspect}"); }

exit 0;

# --- aspect stubs (filled in by subsequent commits) ---
sub run_v1 {
    print "=== V1: In-bin formula edge cases + R2 cross-check ===\n\n";

    # -----------------------------------------------------------------------
    # Part A: hand-computable edge cases for the Decision 1 formula.
    # -----------------------------------------------------------------------
    print "--- Part A: Formula edge cases ---\n";
    my $passes = 0;
    my $fails  = 0;
    my $check  = sub {
        my ($name, $actual, $expected, $tol) = @_;
        $tol //= 1e-9;
        my $ok = (defined $expected && defined $actual && abs($actual - $expected) <= $tol * (abs($expected) + 1));
        printf "  [%s] %-60s actual=%-20s expected=%-20s\n",
            ($ok ? 'OK  ' : 'FAIL'),
            $name,
            (defined $actual   ? sprintf('%.10g', $actual)   : 'undef'),
            (defined $expected ? sprintf('%.10g', $expected) : 'undef');
        $ok ? $passes++ : $fails++;
    };

    # Edge 1: bin_count=1 in the located bin -> fraction = 1.0 -> returns upper.
    # Construct an entry whose only data is one observation in a single bin.
    {
        my $entry = {
            partition => partition_new(100, $opt{bpd}, $opt{seed_decades}),
            bins      => [],
            overflow  => 0,
            underflow => 0,
        };
        my ($where, $i) = bin_assign($entry->{partition}, 100, 'closed');
        $entry->{bins}->[$i] = 1;
        _ensure_boundaries($entry->{partition});
        my $upper = $entry->{partition}->{boundaries}->[$i + 1];
        for my $q (0.5, 0.99) {
            my ($v, $audit) = percentile($entry, $q);
            $check->("bin_count=1, q=$q -> returns upper", $v, $upper);
            $check->("bin_count=1, q=$q -> audit=none",
                ($audit eq 'none' ? 1 : 0), 1);
        }
    }

    # Edge 2: lower=upper (degenerate single-value partition). Force by
    # constructing a partition with v0=1, then collapse min=max=1 to simulate.
    # Geometric form lower*(upper/lower)^fraction = 1*(1)^fraction = 1.
    {
        my $synth = {
            min        => 1,
            max        => 1,
            bpd        => $opt{bpd},
            decades    => 0.0,
            bin_count  => 1,
            log_ratio  => 1e-300,    # avoid div-by-zero; not used in this path
            rebins     => 0,
            max_rebins => undef,
            boundaries => [1, 1],
        };
        my $entry = { partition => $synth, bins => [3], overflow => 0, underflow => 0 };
        for my $q (0.1, 0.5, 0.9, 0.99) {
            my ($v, $audit) = percentile($entry, $q);
            $check->("lower=upper, q=$q -> returns 1", $v, 1);
            $check->("lower=upper, q=$q -> audit=none",
                ($audit eq 'none' ? 1 : 0), 1);
        }
    }

    # Edge 3: single observation in a normal partition.
    # Cumulative walk lands target_rank=1 in the single populated bin;
    # fraction = 1/1 = 1.0 -> returns upper. Same logical case as Edge 1
    # but exercised through counter_update.
    {
        my %store;
        counter_update(\%store, 'single', 42);
        my $entry = $store{single};
        _ensure_boundaries($entry->{partition});
        my ($where, $i) = bin_assign($entry->{partition}, 42, 'closed');
        my $upper = $entry->{partition}->{boundaries}->[$i + 1];
        my ($v, $audit) = percentile($entry, 0.5);
        $check->("single observation, q=0.5 -> upper of bin containing v", $v, $upper);
    }

    # Edge 4: rank_in_bin = 0 -> fraction = 0 -> returns lower.
    # Walk: cumulative count *includes* the bin's count when target_rank lands
    # in it. To exercise fraction=0 we need target_rank to be the last element
    # of the previous bin -- which the walk treats as still in the previous
    # bin. So this is naturally hard to hit at fraction=0; Decision 1 uses
    # `target_rank <= cumulative` so fraction = rank_in_bin/count is always
    # in [1/count .. count/count]. fraction=0 is unreachable by construction.
    # Record this as a property of the locked walk, not a missing edge case.
    print "  [NOTE] Decision 1 walk uses target_rank<=cum so fraction in (0,1]; fraction=0 is unreachable.\n";

    # Edge 5: zero-count partition -> R4 returns (undef, 'none').
    {
        my $entry = {
            partition => partition_new(1, $opt{bpd}, $opt{seed_decades}),
            bins      => [],
            overflow  => 0,
            underflow => 0,
        };
        my ($v, $audit) = percentile($entry, 0.5);
        $check->("zero-count partition -> value=undef",
            (defined $v ? 0 : 1), 1);
    }

    # Edge 6: all-overflow -> R4 returns boundary[B] and audit=high.
    {
        my $entry = {
            partition => partition_new(1, $opt{bpd}, $opt{seed_decades}),
            bins      => [],
            overflow  => 5,
            underflow => 0,
        };
        $entry->{partition}->{max_rebins} = 0; # ensure overflow stays in counter
        _ensure_boundaries($entry->{partition});
        my $top = $entry->{partition}->{boundaries}->[$entry->{partition}->{bin_count}];
        my ($v, $audit) = percentile($entry, 0.9);
        $check->("all-overflow -> value=boundary[B]", $v, $top);
        $check->("all-overflow -> audit=high",
            ($audit eq 'high' ? 1 : 0), 1);
    }

    # Edge 7: all-underflow -> R4 returns boundary[0] and audit=low.
    {
        my $entry = {
            partition => partition_new(1, $opt{bpd}, $opt{seed_decades}),
            bins      => [],
            overflow  => 0,
            underflow => 4,
        };
        $entry->{partition}->{max_rebins} = 0;
        _ensure_boundaries($entry->{partition});
        my $bot = $entry->{partition}->{boundaries}->[0];
        my ($v, $audit) = percentile($entry, 0.1);
        $check->("all-underflow -> value=boundary[0]", $v, $bot);
        $check->("all-underflow -> audit=low",
            ($audit eq 'low' ? 1 : 0), 1);
    }

    print "\nPart A summary: $passes passed, $fails failed.\n";
    print "\n";

    # -----------------------------------------------------------------------
    # Part B: R2 cross-check on real data. Run all three R2 implementations on
    # every observed value; log disagreements with (value, partition_min,
    # partition_max, three indices).
    # -----------------------------------------------------------------------
    die_usage("--aspect v1 requires at least one --file") unless @{$opt{file}};

    print "--- Part B: R2 cross-check on real data ---\n";
    print "Comparing closed-form, binary search, linear search across all observed values.\n\n";

    # Counter store built using closed-form (the contract-default impl). We
    # then re-bin every observed value with all three R2 algorithms against
    # each partition's current state and check agreement.
    my %store;
    my $observations = 0;
    my $disagreements = 0;
    my $disagreement_examples = 0;
    my @sample_disagreements;

    for my $file (@{$opt{file}}) {
        iterate_durations($file, sub {
            my ($cat, $key, $dur) = @_;
            my $jk = "$cat\x1f$key";
            counter_update(\%store, $jk, $dur);   # uses --r2-impl (default closed)

            # Cross-check against the partition's CURRENT state (after any
            # rebin from this observation).
            my $p = $store{$jk}->{partition};
            return unless $dur >= $p->{min} && $dur <= $p->{max};
            $observations++;

            my ($wc, $ic) = r2_closed($p, $dur);
            my ($wb, $ib) = r2_binary($p, $dur);
            my ($wl, $il) = r2_linear($p, $dur);

            # All three must produce IN-range result and identical bin index.
            if ($wc ne 'IN' || $wb ne 'IN' || $wl ne 'IN' ||
                $ic != $ib || $ib != $il) {
                $disagreements++;
                if ($disagreement_examples < 10) {
                    push @sample_disagreements, sprintf(
                        "  value=%g  partition=[%g,%g] B=%d  closed=%s/%s  binary=%s/%s  linear=%s/%s\n",
                        $dur, $p->{min}, $p->{max}, $p->{bin_count},
                        $wc, (defined $ic ? $ic : '-'),
                        $wb, (defined $ib ? $ib : '-'),
                        $wl, (defined $il ? $il : '-')
                    );
                    $disagreement_examples++;
                }
            }
        });
    }

    printf "observations_compared: %d\n", $observations;
    printf "disagreements: %d (%.4f%%)\n", $disagreements,
        ($observations > 0 ? 100 * $disagreements / $observations : 0);
    if (@sample_disagreements) {
        print "\nSample disagreements (up to 10):\n";
        print for @sample_disagreements;
    } else {
        print "All three R2 implementations agreed on every observation.\n";
    }
}
sub run_v2 {
    die_usage("--aspect v2 requires at least one --file") unless @{$opt{file}};

    print "=== V2: Per-key fan-out at scale + R2 algorithm benchmark ===\n\n";
    if (!$have_devel_size && $opt{mem}) {
        print "WARNING: --mem requested but Devel::Size not available; memory measurements skipped.\n\n";
    }

    # -----------------------------------------------------------------------
    # Part A: per-key fan-out at scale -- contract behavior with the locked
    # default R2 algorithm (closed-form). Measure rebin distribution, per-key
    # memory, projected total at 10^5 keys.
    # -----------------------------------------------------------------------
    print "--- Part A: Per-key fan-out at scale (R2 algorithm: $opt{'r2-impl'}) ---\n";

    my %store;
    my $t0 = [gettimeofday];
    my $lines = 0;
    for my $file (@{$opt{file}}) {
        $lines += iterate_durations($file, sub {
            my ($cat, $key, $dur) = @_;
            counter_update(\%store, "$cat\x1f$key", $dur);
        });
    }
    my $elapsed = tv_interval($t0);

    my $partition_count = scalar keys %store;
    my @rebin_counts;
    my $max_bins = 0;
    my $overflow_partitions = 0;
    my $underflow_partitions = 0;
    for my $key (keys %store) {
        my $e = $store{$key};
        push @rebin_counts, $e->{partition}->{rebins};
        $max_bins = $e->{partition}->{bin_count} if $e->{partition}->{bin_count} > $max_bins;
        $overflow_partitions++  if ($e->{overflow}  // 0) > 0;
        $underflow_partitions++ if ($e->{underflow} // 0) > 0;
    }
    my ($p50r, $p95r, $p99r, $maxr) = partition_dist(@rebin_counts);

    printf "files: %s\n", join(", ", @{$opt{file}});
    printf "lines_read: %d\n", $lines;
    printf "elapsed_s: %.2f (parse + counter_update with R2=%s)\n", $elapsed, $opt{'r2-impl'};
    printf "partition_count: %d\n", $partition_count;
    printf "buckets_per_decade: %d\n", $opt{bpd};
    printf "max_partition_bins: %d\n", $max_bins;
    printf "total_rebin_events: %d\n", sum(@rebin_counts) // 0;
    printf "rebins_per_partition: p50=%d p95=%d p99=%d max=%d\n",
        $p50r, $p95r, $p99r, $maxr;
    printf "partitions_with_overflow_count: %d\n",  $overflow_partitions;
    printf "partitions_with_underflow_count: %d\n", $underflow_partitions;

    my $mem_total = undef;
    my $mem_per_key = undef;
    if ($opt{mem} && $have_devel_size) {
        $mem_total = total_size(\%store);
        $mem_per_key = $partition_count > 0 ? $mem_total / $partition_count : 0;
        printf "counter_memory_bytes: %d (%.2f MB)\n",
            $mem_total, $mem_total / 1024 / 1024;
        printf "per_partition_memory_bytes: %.0f\n", $mem_per_key;
        # Project to 10^5 partitions.
        my $projected_100k = $mem_per_key * 100000;
        printf "projected_memory_at_1e5_partitions: %.0f bytes (%.0f MB)\n",
            $projected_100k, $projected_100k / 1024 / 1024;
        # #187 Decision 2 implementation guidance projects ~212 MB at 10^5 keys
        # at default bpd=53. Compare.
        if ($opt{bpd} == 53) {
            my $delta_pct = 100 * ($projected_100k - 212e6) / 212e6;
            printf "projection_vs_decision_2_guidance (~212 MB at 10^5 keys): %+.1f%%\n",
                $delta_pct;
        }
    }
    print "\n";

    return unless $opt{'r2-bench'};

    # -----------------------------------------------------------------------
    # Part B: R2 algorithm benchmark. Run all three R2 implementations in
    # sequence against the same input. Report wall-clock time per
    # implementation and the memory delta attributable to the boundary array
    # (closed-form doesn't need it; binary/linear do).
    # -----------------------------------------------------------------------
    print "--- Part B: R2 algorithm benchmark ---\n";
    print "Each implementation processes the input from scratch with its own counter store.\n\n";

    my @results;
    for my $impl (qw(closed binary linear)) {
        # Reset and re-run with this implementation.
        my %bstore;
        my $bt0 = [gettimeofday];
        my $blines = 0;
        for my $file (@{$opt{file}}) {
            $blines += iterate_durations($file, sub {
                my ($cat, $key, $dur) = @_;
                counter_update(\%bstore, "$cat\x1f$key", $dur, $impl);
            });
        }
        my $belapsed = tv_interval($bt0);
        my $bmem = ($opt{mem} && $have_devel_size) ? total_size(\%bstore) : undef;

        # For binary/linear: explicitly materialize boundary arrays for every
        # partition (closed-form leaves them lazy). This makes the memory
        # comparison apples-to-apples: production binary/linear would need
        # them materialized for every observation.
        if ($impl ne 'closed') {
            for my $k (keys %bstore) {
                _ensure_boundaries($bstore{$k}->{partition});
            }
            $bmem = ($opt{mem} && $have_devel_size) ? total_size(\%bstore) : undef;
        }

        push @results, {
            impl    => $impl,
            elapsed => $belapsed,
            lines   => $blines,
            keys    => scalar keys %bstore,
            mem     => $bmem,
        };
    }

    printf "%-10s %-12s %-12s %-18s %s\n",
        'R2 algo', 'elapsed_s', 'lines/s', 'memory_MB', 'memory_per_key_B';
    print  "-" x 75, "\n";
    for my $r (@results) {
        printf "%-10s %-12.2f %-12.0f %-18s %s\n",
            $r->{impl},
            $r->{elapsed},
            $r->{lines} / ($r->{elapsed} || 1),
            defined $r->{mem} ? sprintf('%.2f', $r->{mem} / 1024 / 1024) : '(no --mem)',
            defined $r->{mem} ? sprintf('%.0f', $r->{mem} / ($r->{keys} || 1)) : '-';
    }
    print "\n";

    # Speedup factors relative to linear.
    my %by_impl = map { $_->{impl} => $_ } @results;
    if ($by_impl{linear} && $by_impl{linear}->{elapsed} > 0) {
        printf "Speedup vs linear: closed=%.2fx  binary=%.2fx\n",
            $by_impl{linear}->{elapsed} / $by_impl{closed}->{elapsed},
            $by_impl{linear}->{elapsed} / $by_impl{binary}->{elapsed};
    }
    if ($opt{mem} && $have_devel_size && $by_impl{closed} && $by_impl{closed}->{mem}) {
        printf "Memory overhead vs closed (boundary array cost):\n";
        printf "  binary: %+.2f MB  (%+.0f%%)\n",
            ($by_impl{binary}->{mem} - $by_impl{closed}->{mem}) / 1024 / 1024,
            100 * ($by_impl{binary}->{mem} - $by_impl{closed}->{mem}) / $by_impl{closed}->{mem};
        printf "  linear: %+.2f MB  (%+.0f%%)\n",
            ($by_impl{linear}->{mem} - $by_impl{closed}->{mem}) / 1024 / 1024,
            100 * ($by_impl{linear}->{mem} - $by_impl{closed}->{mem}) / $by_impl{closed}->{mem};
    }
}
sub run_v3 {
    print "=== V3: Seeding heuristic + overflow/underflow audit ===\n\n";

    # -----------------------------------------------------------------------
    # Part A: seeding heuristic on real data. Decision 5 implementation
    # guidance: with 5-decade seed centered on first value, p99 rebins should
    # be in [0, 2] on typical latency data. V5 already showed this; V3 owns
    # the measurement.
    # -----------------------------------------------------------------------
    die_usage("--aspect v3 requires at least one --file") unless @{$opt{file}};

    print "--- Part A: Seed heuristic on real data ---\n";
    print "Decision 5 guidance: p99 rebins should be in [0, 2] on typical latency data.\n\n";

    my %store;
    for my $file (@{$opt{file}}) {
        iterate_durations($file, sub {
            my ($cat, $key, $dur) = @_;
            counter_update(\%store, "$cat\x1f$key", $dur);
        });
    }

    my @rebin_counts;
    my $partitions_with_rebins = 0;
    for my $key (keys %store) {
        my $r = $store{$key}->{partition}->{rebins};
        push @rebin_counts, $r;
        $partitions_with_rebins++ if $r > 0;
    }
    my ($p50, $p95, $p99, $maxr) = partition_dist(@rebin_counts);
    my $total = sum(@rebin_counts) // 0;
    printf "partitions_total: %d\n", scalar @rebin_counts;
    printf "partitions_with_rebins: %d (%.4f%%)\n",
        $partitions_with_rebins,
        (@rebin_counts ? 100 * $partitions_with_rebins / scalar @rebin_counts : 0);
    printf "total_rebin_events: %d\n", $total;
    printf "rebins_per_partition: p50=%d p95=%d p99=%d max=%d\n",
        $p50, $p95, $p99, $maxr;
    my $heuristic_ok = ($p99 <= 2);
    printf "Decision 5 healthy-seed signal (p99 <= 2): %s\n",
        ($heuristic_ok ? 'PASS' : 'FAIL');
    print "\n";

    # -----------------------------------------------------------------------
    # Part B: overflow/underflow audit on pathological inputs constructed in
    # script. Each scenario uses --max-rebins to artificially cap growth so the
    # overflow/underflow counters fire and `out_of_range_bounded` becomes a
    # non-trivial enum value.
    # -----------------------------------------------------------------------
    print "--- Part B: Overflow/underflow audit on pathological inputs ---\n";
    print "Each scenario constructs a partition, caps rebins at 0, then feeds\n";
    print "values designed to fall outside the seeded partition.\n\n";

    my @scenarios = (
        {
            name        => 'extreme high outlier (after warmup at v0=100)',
            v0          => 100,                          # seeds [~0.32, ~31623]
            outliers    => [ 1e6, 1e7, 1e8 ],            # all > max
            expect_high => 1,
            expect_low  => 0,
            q           => 0.999,
        },
        {
            name        => 'extreme low outlier (after warmup at v0=10000)',
            v0          => 10000,                        # seeds [~31.6, ~3162277]
            outliers    => [ 0.5, 0.1, 0.01 ],           # all < min and > 0
            expect_high => 0,
            expect_low  => 1,
            q           => 0.01,
        },
        {
            name        => 'mixed scale (after warmup at v0=1000)',
            v0          => 1000,                                         # seeds [~3.16, ~316228]
            # 50 underflow + 50 overflow against 1000 in-range observations.
            # That's ~4.5% underflow share -- enough that q=0.01 lands in the
            # underflow counter and q=0.999 lands in the overflow counter.
            outliers    => [ (1e-3) x 50, (1e8) x 50 ],
            expect_high => 1,
            expect_low  => 1,
            q           => 0.5,
        },
    );

    my $pass = 0;
    my $fail = 0;
    for my $s (@scenarios) {
        print "Scenario: $s->{name}\n";

        # Seed partition at v0; cap rebins so subsequent out-of-range values
        # land in the overflow/underflow counters.
        my $p = partition_new($s->{v0}, $opt{bpd}, $opt{seed_decades});
        $p->{max_rebins} = 0;
        my $entry = {
            partition => $p, bins => [], overflow => 0, underflow => 0,
        };
        # Warmup: 1000 normal observations clustered around v0 (lognormal-ish
        # spread within the partition).
        for (1..1000) {
            my $j = $s->{v0} * (0.5 + rand);
            my ($w, $i) = bin_assign($p, $j, 'closed');
            $entry->{bins}->[$i] = ($entry->{bins}->[$i] // 0) + 1 if $w eq 'IN';
        }
        # Inject outliers; with max_rebins=0, partition_extend fails and the
        # over/underflow counter is incremented.
        for my $v (@{ $s->{outliers} }) {
            my ($w, undef) = bin_assign($p, $v, 'closed');
            my $new_bins = partition_extend($p, $v, $entry->{bins});
            if (!defined $new_bins) {
                if ($w eq 'OVERFLOW')  { $entry->{overflow}++;  }
                if ($w eq 'UNDERFLOW') { $entry->{underflow}++; }
            }
        }

        printf "  partition: min=%g max=%g B=%d\n",
            $p->{min}, $p->{max}, $p->{bin_count};
        printf "  in_range_observations: %d (sum of bins)\n",
            sum(map { $_ // 0 } @{ $entry->{bins} }) // 0;
        printf "  overflow_count: %d   underflow_count: %d\n",
            $entry->{overflow}, $entry->{underflow};

        # Verify R4 audit for the scenario's quantile.
        my ($v, $audit) = percentile($entry, $s->{q});
        printf "  R4 at q=%g: value=%g audit=%s\n",
            $s->{q}, (defined $v ? $v : 'undef'), $audit // '(none)';

        # Pass conditions: counters incremented as expected; aggregate audit
        # surfaces non-`none` on at least one quantile when overflow/underflow
        # non-zero.
        my $counter_ok = (
            ($s->{expect_high} ? $entry->{overflow}  > 0 : 1) &&
            ($s->{expect_low}  ? $entry->{underflow} > 0 : 1)
        );

        # Check audit aggregate by running R4 at the extreme quantiles to see
        # if `high`/`low` audit codes surface.
        my %seen_audit;
        for my $q (0.001, 0.5, 0.999) {
            my (undef, $a) = percentile($entry, $q);
            $seen_audit{$a // 'undef'}++;
        }
        my $audit_ok = (
            ($s->{expect_high} ? ($seen_audit{high} // 0) > 0 : 1) &&
            ($s->{expect_low}  ? ($seen_audit{low}  // 0) > 0 : 1)
        );

        if ($counter_ok && $audit_ok) {
            print "  [PASS]\n\n";
            $pass++;
        } else {
            printf "  [FAIL] counter_ok=%d audit_ok=%d  audit_seen={%s}\n\n",
                $counter_ok, $audit_ok,
                join(',', map { "$_=$seen_audit{$_}" } keys %seen_audit);
            $fail++;
        }
    }

    print "Part B summary: $pass passed, $fail failed.\n";
}
sub run_v4 {
    die_usage("--aspect v4 requires at least one --file") unless @{$opt{file}};

    # V4 captures the six locked Decision 8 scenarios. Rather than spawning
    # subprocesses (which complicates argument handling and timing), V4
    # explicitly re-runs the data-load + telemetry-emit loop with the
    # appropriate flag state mutated in $opt{...} per scenario. Each scenario
    # writes a labeled output block to stdout.
    #
    # The six scenarios from #187 Decision 10's V4 requirement:
    #   1. Default precision
    #   2. --percentile-precision N override
    #   3. -pbpd N override
    #   4. Both flags specified (-pbpd wins per Decision 2)
    #   5. Overflow audit firing (--max-rebins 0)
    #   6. --exact-percentiles opt-out
    print "=== V4: -V output samples per Decision 8 format ===\n\n";
    print "Six scenarios per #187 Decision 10 V4 requirement. Each block reproduces\n";
    print "what would appear under `=== PERCENTILE MODE ===` in `ltl -V` output for a\n";
    print "migrated `summary_table` consumer.\n\n";

    # Saved state for restoration between scenarios.
    my $saved_bpd                  = $opt{bpd};
    my $saved_precision            = $opt{'percentile-precision'};
    my $saved_pbpd                 = $opt{pbpd};
    my $saved_exact                = $opt{'exact-percentiles'};
    my $saved_max_rebins           = $opt{'max-rebins'};
    my $saved_precision_source     = $precision_source;

    my $banner = sub {
        my ($n, $title) = @_;
        print "\n", "#" x 78, "\n";
        printf "# Scenario %d: %s\n", $n, $title;
        print "#" x 78, "\n";
    };

    # Helper: load the file with the current $opt{...} state into a fresh store
    # and emit the telemetry block.
    my $run = sub {
        my $store = {};
        for my $file (@{$opt{file}}) {
            iterate_durations($file, sub {
                my ($cat, $key, $dur) = @_;
                counter_update($store, "$cat\x1f$key", $dur);
            });
        }
        emit_telemetry($store, consumer => 'summary_table',
            keying => '(category, log_key)');
    };

    # --- 1. Default precision ---
    $opt{bpd} = 53; $opt{'percentile-precision'} = undef; $opt{pbpd} = undef;
    $precision_source = 'default';
    $opt{'exact-percentiles'} = 0;
    $opt{'max-rebins'} = undef;
    $banner->(1, 'Default precision (no CLI overrides)');
    $run->();

    # --- 2. --percentile-precision N override ---
    $opt{'percentile-precision'} = 7;
    $opt{bpd} = 115;
    $opt{pbpd} = undef;
    $precision_source = '--percentile-precision 7';
    $banner->(2, '--percentile-precision 7 (maps to bpd=115)');
    $run->();

    # --- 3. -pbpd N override ---
    $opt{'percentile-precision'} = undef;
    $opt{pbpd} = 100;
    $opt{bpd} = 100;
    $precision_source = '-pbpd 100';
    $banner->(3, '-pbpd 100 (direct numeric override)');
    $run->();

    # --- 4. Both flags (conflict; -pbpd wins per Decision 2) ---
    $opt{'percentile-precision'} = 4;
    $opt{pbpd} = 100;
    $opt{bpd} = 100;
    $precision_source = '-pbpd 100; --percentile-precision 4 overridden';
    $banner->(4, 'Flag conflict: -pbpd 100 + --percentile-precision 4');
    $run->();

    # --- 5. Overflow audit firing (--max-rebins 0 + pathological injection) ---
    $opt{'percentile-precision'} = undef;
    $opt{pbpd} = undef;
    $opt{bpd} = 53;
    $precision_source = 'default';
    $opt{'max-rebins'} = 0;
    $banner->(5, 'Overflow audit firing (synthetic --max-rebins 0 + outlier)');
    {
        # Custom load that injects outliers; standard iterate_durations doesn't
        # produce overflow under Decision 5 auto-resize.
        my $store = {};
        my @injected_outliers;
        for my $file (@{$opt{file}}) {
            iterate_durations($file, sub {
                my ($cat, $key, $dur) = @_;
                counter_update($store, "$cat\x1f$key", $dur);
            });
        }
        # Inject overflow values into a sample key.
        my @sample_keys = keys %$store;
        my $target = $sample_keys[0];
        for (1..10) {
            # Force overflow: directly increment counter.
            $store->{$target}->{overflow}++;
        }
        emit_telemetry($store, consumer => 'summary_table',
            keying => '(category, log_key)');
    }
    $opt{'max-rebins'} = undef;

    # --- 6. --exact-percentiles opt-out ---
    $opt{'exact-percentiles'} = 1;
    $banner->(6, '--exact-percentiles opt-out (all migrated consumers revert)');
    $run->();
    $opt{'exact-percentiles'} = 0;

    # Restore.
    $opt{bpd}                   = $saved_bpd;
    $opt{'percentile-precision'} = $saved_precision;
    $opt{pbpd}                  = $saved_pbpd;
    $opt{'exact-percentiles'}   = $saved_exact;
    $opt{'max-rebins'}          = $saved_max_rebins;
    $precision_source           = $saved_precision_source;
}

# ============================================================================
# V5 — Accuracy vs calculate_statistics oracle
# ============================================================================

sub run_v5 {
    die_usage("--aspect v5 requires at least one --file") unless @{$opt{file}};

    # Per-key raw arrays (for the oracle) AND per-key counter stores (for R4).
    # The counter store is populated streaming; the raw array is kept only for
    # the oracle. Production code would never keep the array; this is the V5
    # comparison harness.
    my %raw;        # { "$cat\x1f$key" => [ durations ] }
    my %counter;    # the unified-contract counter store
    my %cat_key;    # for reverse lookup of (category, log_key) from joined key

    my $start = [gettimeofday];
    my $total_lines = 0;
    for my $file (@{$opt{file}}) {
        my $n = iterate_durations($file, sub {
            my ($cat, $key, $dur) = @_;
            my $jk = "$cat\x1f$key";
            $cat_key{$jk} //= [$cat, $key];
            push @{ $raw{$jk} }, $dur;
            counter_update(\%counter, $jk, $dur);
        });
        $total_lines += $n;
    }
    my $elapsed = tv_interval($start);

    print "=== V5: Accuracy vs calculate_statistics oracle ===\n";
    printf "files: %s\n", join(", ", @{$opt{file}});
    printf "total_lines_read: %d\n", $total_lines;
    printf "unique_keys: %d\n", scalar keys %raw;
    printf "elapsed_s: %.2f\n", $elapsed;
    printf "buckets_per_decade: %d ($precision_source)\n", $opt{bpd};
    printf "min_N_threshold: %d\n", $opt{'min-N'};
    print  "quantiles: ", join(',', map { q_label($_) } @quantiles), "\n";
    print  "\n";

    # Per-quantile error histograms. Two error series:
    #   raw_err  = (R4_with_ceil - oracle) / oracle    (rank-convention + binning)
    #   bin_err  = (R4_with_oracle_idx - oracle) / oracle   (binning only)
    my %raw_errs;    # { q => [ relative errors ] }
    my %bin_errs;    # { q => [ relative errors ] }
    my $compared_keys = 0;

    for my $jk (sort keys %raw) {
        my $durations = $raw{$jk};
        next if scalar @$durations < $opt{'min-N'};
        $compared_keys++;
        my $oracle = calculate_statistics_oracle($durations);
        my $entry  = $counter{$jk};
        for my $q (@quantiles) {
            my $label = q_label($q);
            my $orc = $oracle->{$label};
            next unless defined $orc && $orc > 0;

            my ($r4_raw, $audit_raw) = percentile($entry, $q);
            my ($r4_bin, $audit_bin) = percentile($entry, $q, oracle_indexing => 1);
            next unless defined $r4_raw && defined $r4_bin;

            push @{ $raw_errs{$q} }, abs($r4_raw - $orc) / $orc;
            push @{ $bin_errs{$q} }, abs($r4_bin - $orc) / $orc;
        }
    }

    printf "keys_compared (N >= %d): %d\n\n", $opt{'min-N'}, $compared_keys;

    # Three error scales relative to bin geometry at the current bpd:
    #   bin_width        = 10^(1/bpd) - 1                  (bound for worst-case
    #                                                      interpolation:
    #                                                      R4 returns upper but
    #                                                      truth is lower)
    #   bin_width_pct    = bin_width * 100                 (as percentage)
    #   bin_midpoint_pct = bin_width_pct / 2               (expected error for
    #                                                      uniformly-distributed
    #                                                      target rank inside a
    #                                                      bin)
    my $bin_width_pct    = (10 ** (1 / $opt{bpd}) - 1) * 100;
    my $bin_midpoint_pct = $bin_width_pct / 2;

    printf "%-6s %-15s %-15s %-15s %-15s %s\n",
        'Q', 'binning_p50', 'binning_p95', 'binning_p99', 'binning_max', 'raw_max';
    print  "-" x 90, "\n";
    for my $q (@quantiles) {
        my @rb = sort { $a <=> $b } @{ $bin_errs{$q} // [] };
        my @rr = sort { $a <=> $b } @{ $raw_errs{$q} // [] };
        if (!@rb) {
            printf "%-6s %-15s\n", q_label($q), '(no data)';
            next;
        }
        my $pick = sub {
            my $arr = shift;
            my $f = shift;
            my $i = int(@$arr * $f);
            $i = $#$arr if $i > $#$arr;
            return $arr->[$i];
        };
        printf "%-6s %14.4f%% %14.4f%% %14.4f%% %14.4f%% %14.4f%%\n",
            q_label($q),
            $pick->(\@rb, 0.5)  * 100,
            $pick->(\@rb, 0.95) * 100,
            $pick->(\@rb, 0.99) * 100,
            $rb[-1] * 100,
            $rr[-1] * 100;
    }
    print "\n";
    printf "bin_geometry at bpd=%d:\n", $opt{bpd};
    printf "  worst_case_bound (full bin width): ~%.2f%%\n", $bin_width_pct;
    printf "  expected_typical (uniform-in-bin):  ~%.2f%%\n", $bin_midpoint_pct;
    printf "Pass criterion: binning_max <= worst_case_bound; binning_p50 ~= expected_typical.\n";

    # Emit telemetry block (Decision 8 format).
    emit_telemetry(\%counter, consumer => 'summary_table', keying => '(category, log_key)');
}
