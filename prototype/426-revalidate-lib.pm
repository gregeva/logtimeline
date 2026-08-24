package Revalidate426;
#
# 426-revalidate-lib.pm — shared library for the #426 revalidation of the #189
# bin-counter primitives against the proposed representation (brief:
# scratchpad/brief.md). Three arms behind one store interface, the parsers
# that reproduce ltl's keys, the exact-percentile oracle, digests, timing and
# memory helpers.
#
# =============================================================================
# API REFERENCE (this header is the contract for the aspect prototypes)
# =============================================================================
#
# Loading (from a script in prototype/):
#     use FindBin; require "$FindBin::Bin/426-revalidate-lib.pm";
#
# --- configuration -----------------------------------------------------------
#   Revalidate426::configure(bpd => 53, seed_decades => 5, max_rebins => undef)
#       Sets the package globals the verbatim primitives read:
#         $Revalidate426::percentile_buckets_per_decade  (default 53)
#         $Revalidate426::percentile_seed_decades        (default 5)
#         $Revalidate426::max_rebins                     (default undef = no cap)
#       max_rebins is the #189-prototype `--max-rebins` hook: when defined and a
#       T/S partition has already rebinned max_rebins times, an out-of-range
#       value increments overflow/underflow instead of extending (V3/V4 of #189
#       used cap 0 to force the audit). When undef the verbatim counter_update
#       path runs untouched — the cap lives in counter_update_capped(), a
#       separate sub the T store selects only when the cap is set.
#   Revalidate426::tier_to_bpd($level)   1..9 -> 4,8,16,32,53,80,115,256,616
#   %Revalidate426::TIER_BPD             the same map as a hash
#
# --- Arm T primitives (verbatim from ltl lines 1088-1380 and ltl:7682) -------
#   bin_boundary($p, $i)                         -> boundary value
#   partition_new($v0, $bpd, $seed_decades)      -> partition hashref
#   partition_extend($p, $value, \@old_bins)     -> \@new_bins (mutates $p)
#   partition_rebin($p, \@src, $min, $max, $bc)  -> ($new_p, \@new_bins)
#   snapshot_counter_telemetry(\%store)          -> telemetry hashref (Devel::Size)
#   bin_assign($p, $v)                           -> ('IN',$i)|('UNDERFLOW',undef)|('OVERFLOW',undef)
#   counter_update(\%store, $key, $value, $bpd_override)
#   percentile($entry, $q)                       -> ($value, $audit)   [ceil(q*N)]
#   merge_bin_counter_entries($target, $source)  (mutates $target; adopts source's
#                                                 partition/bins BY REFERENCE when
#                                                 target is empty — verbatim)
#   The only non-verbatim additions on the T side:
#   counter_update_capped(\%store,$key,$value,$bpd_override)  — verbatim body plus
#       the cap check (see max_rebins above).
#   percentile_rank($entry, $q, $conv)           -> ($value, $audit); $conv 'ceil'
#       delegates to the verbatim percentile(); 'int' runs the identical walk
#       with target_rank = int(q*N)+1 (see RANK CONVENTIONS).
#
# --- Arm S (span-only columnar, verbatim geometry; P8+P9) --------------------
#   Port of 426-bin-store-mini.pl K4 (extend_cols / bump_offset_dense /
#   percentile_cols with offset_dense=1). Columns by row: pmin pmax pbc plr prb
#   pdec over under bins; bins[row] = [base_index, c0, c1, ...] over the
#   occupied span; key->row in {row}, row->key in {key}. Widening runs the
#   verbatim partition_extend through a dense view; merge runs the verbatim
#   merge_bin_counter_entries through dense views of both rows and writes the
#   result back as columns (so S never aliases, unlike T's adopt path).
#   `pdec` (partition decades) is one column more than K4 had: partition_rebin
#   (reached through merge) sets decades to the union span, and a later
#   partition_extend reads it for the doubling factor — without the column S
#   would diverge from T after merge-then-add.
#
# --- Arm G (shared log-spaced grid, span-only; P10) --------------------------
#   grid_index($v, $bpd)          -> POSIX::floor($bpd * log($v) / log(10))
#                                    (exactly 426-grid-fidelity.pl's grid_index)
#   grid_index_checked($v, $bpd)  -> ($i, $corrected) : closed-form index checked
#       against the real boundaries: if $v < 10**($i/$bpd) then $i-1; elsif
#       $v >= 10**(($i+1)/$bpd) then $i+1; $corrected = 1 when a step was taken.
#       One step only (float error is sub-ULP; the self-test verifies the bound
#       holds after the step). For the V1 cross-check. Known case: v=1000 —
#       closed form gives 158 at bpd 53 (1847 at 616), the boundary test says
#       159 (1848): exact powers of ten sit on a grid boundary and the float
#       log lands one ULP low. The G store adds with the UNCORRECTED closed
#       form (as 426-grid-fidelity.pl does); the cross-check is separate.
#   grid_lower($i,$bpd) = 10**($i/$bpd);  grid_upper($i,$bpd) = 10**(($i+1)/$bpd)
#   Store: bins[row] = [base_index, counts...]; no partition state, no
#   overflow/underflow; span grows on either side on demand; merge = index-wise
#   add; percentile = the #187 Decision 1 walk (ceil(q*N), rank_in_bin,
#   lower*(upper/lower)^fraction) — 426-grid-fidelity.pl's grid_percentile over
#   the span array. audit is always 'none'.
#
# --- store interface (all arms) ---------------------------------------------
#   my $st = Revalidate426::store_new($arm, %opt)   $arm in T|S|G
#       %opt: bpd => N (default: the configured global). The store captures its
#       bpd at creation; T passes it to counter_update as $bpd_override.
#       seed_decades and max_rebins are read from the globals at call time.
#   $st->add($key, $value)          $value must be > 0 (caller guards, as ltl does)
#   $st->percentile($key, $q, $conv)  -> ($value, $audit); $conv 'ceil' (default,
#       native Decision 1) | 'int' (oracle's rank; see RANK CONVENTIONS).
#       (undef,'none') for an unknown/empty key.
#   $st->merge($target_key, $source_key, drop_source => 0|1)
#       T: verbatim merge_bin_counter_entries (union geometry + remap); a missing
#          target adopts the source by reference (verbatim) — use drop_source=>1
#          or never add() to either key afterwards, else T aliases and S/G do not.
#       S: same arithmetic through dense views; result written back as a span.
#       G: index-wise add, span grown to cover both.
#       drop_source deletes the source key (T: hash delete; S/G: row tombstone).
#   $st->keys                        list of live keys (unordered)
#   $st->n($key)                     total N (bins + overflow + underflow)
#   $st->has($key)
#   $st->geometry($key)              T/S: {min,max,bin_count,log_ratio,decades,
#                                    rebins,overflow,underflow}; G: {base,span,
#                                    lo_index,hi_index}
#   $st->canonical($key)             the per-key digest line (see DIGESTS)
#   $st->bins_pairs($key)            list of "index:count" over nonzero bins
#                                    (T/S: partition-relative index; G: grid index)
#   $st->entry($key)                 T: the live ltl-shape entry; S: a fresh
#                                    ltl-shape dense view {partition,bins,overflow,
#                                    underflow} (mutating it does not touch S);
#                                    G: {bins=>{index=>count}} hash view
#   $st->digest                      MD5 hex over sorted keys of "key\tcanonical"
#   $st->telemetry                   T: snapshot_counter_telemetry verbatim;
#                                    S: the same 12 fields computed from the
#                                    columns (counter_memory_bytes = total_size of
#                                    the column set); G: {partition_count,
#                                    span_p50,span_p95,span_p99,span_max,
#                                    index_min,index_max,counter_memory_bytes}
#   $st->memory_bytes                Devel::Size::total_size of the containers
#                                    (T: the entry hash; S/G: row hash + key
#                                    column + all columns)
#   $st->arm, $st->bpd
#
# --- RANK CONVENTIONS -------------------------------------------------------
#   'ceil' : target_rank = POSIX::ceil($q * $N), clamped to [1, N]  (#187 D1)
#   'int'  : target_rank = int($q * $N) + 1, clamped to [1, N]. The oracle
#            indexes $sorted[int($n * $q)] (0-based) — that sample is 1-based rank
#            int(n*q)+1, so the walk lands in the bin holding the oracle's own
#            sample and the difference is binning error alone (#189 V5
#            `binning_*`; identical to 189-bin-counter-primitives.pl's
#            oracle_indexing => 1). Clamping matters only at q = 1.
#
# --- DIGESTS ----------------------------------------------------------------
#   canonical($key):
#     T/S: sprintf('%.17g/%.17g/%d/%d', min, max, bin_count, rebins)
#          . "|o<overflow>|u<underflow>|" . join(',', "<index>:<count>" ...)
#          over nonzero bins in index order (partition-relative index; the
#          geometry prefix makes it grid-independent). T and S produce the same
#          string when their arithmetic is identical (%.17g = full double).
#     G:   "grid/<bpd>|o0|u0|" . join(',', "<grid_index>:<count>" ...)
#   digest: MD5 hex of join("\n", map { "$key\t" . canonical } sort keys).
#
# --- parsers ----------------------------------------------------------------
#   parse_access_line($line) -> ($category, $log_key, $duration) or ()
#       VERBATIM copy of prototype/189-bin-counter-primitives.pl parse_line
#       (lines 113-165), including its corrupt-duration guard and its ThingWorx
#       fallback branch. iterate_durations never reaches that fallback for a
#       ThingWorx file (it selects parse_twx_line), so the 189-shape twx key
#       (350 chars, no masks) is not used anywhere.
#       $duration may be undef (no clean numeric); category = "Nxx".
#   parse_twx_line($line) -> ($category, $log_key, $duration) or ()
#       VERBATIM from 426-grid-fidelity.pl's read loop: returns () when the line
#       does not match or carries no ` durationM[sS]=N`; category = the [L: ...]
#       level (the key's first bracket); key masked and cut to 200 as ltl does
#       at the default width.
#   iterate_durations($file, $cb, %opt) -> \%counts
#       Detects the format from the first line that matches either parser
#       (twx first — the access regex is loose enough to match some ScriptLog
#       lines — then access; a twx line with no duration counts as unparsed) and calls $cb->($category, $log_key, $duration)
#       for every duration > 0. %opt: max_lines => N; count_keys => 1 adds
#       keys_any / keys_positive (distinct keys with a defined duration / with a
#       positive one). \%counts: {format, lines, matched, positive, zero,
#       negative, no_duration, unparsed, keys_any?, keys_positive?}. Also stored
#       in $Revalidate426::last_iterate.
#
# --- oracle -----------------------------------------------------------------
#   oracle_percentiles(\@values, \@quantiles) -> list of values (same order)
#       ltl calculate_statistics (ltl:12685 ff.): @sorted = sort {$a<=>$b};
#       $pX = $sorted[int($duration_count * $q)]  — nearest-rank, 0-based
#       floor index, no interpolation. Confirmed at ltl:12716-12718
#       (`$p1 = $sorted[int($duration_count * 0.01)]`, p50, p75 ...). The only
#       addition here: the index is clamped to $#sorted so q = 1 is defined
#       (ltl never asks for q = 1). Empty list -> all undef.
#
# --- timing / memory (re-exported from prototype/58-measure.pm) --------------
#   time_runs($runs, $code) -> list of seconds (one untimed warmup first)
#   median_min_max(@list)   -> (median, min, max)
#   rss_kb()                -> current process RSS in kB
#
# =============================================================================

use strict;
use warnings;
use POSIX ();
use Digest::MD5 ();
use File::Basename ();
use List::Util ();
use Devel::Size ();

BEGIN {
    require File::Spec;
    my $dir = File::Basename::dirname(File::Spec->rel2abs(__FILE__));
    require "$dir/58-measure.pm";
}
{ no warnings 'once';
  *time_runs      = \&Measure58::time_runs;
  *median_min_max = \&Measure58::median_min_max;
  *rss_kb         = \&Measure58::rss_kb; }

our $percentile_buckets_per_decade = 53;
our $percentile_seed_decades       = 5;
our $max_rebins                    = undef;
our $last_iterate;

our %TIER_BPD = (1 => 4, 2 => 8, 3 => 16, 4 => 32, 5 => 53, 6 => 80, 7 => 115, 8 => 256, 9 => 616);
sub tier_to_bpd {
    my ($level) = @_;
    die "tier must be 1..9\n" unless defined $level && exists $TIER_BPD{$level};
    return $TIER_BPD{$level};
}

sub configure {
    my (%o) = @_;
    $percentile_buckets_per_decade = $o{bpd}          if exists $o{bpd};
    $percentile_seed_decades       = $o{seed_decades} if exists $o{seed_decades};
    $max_rebins                    = $o{max_rebins}   if exists $o{max_rebins};
    return;
}

# =============================================================================
# Arm T — production primitives, VERBATIM from ltl lines 1088-1380
# =============================================================================

sub bin_boundary {
    # Compute boundary[i] = min * (max/min)^(i/B) for partition $p.
    # Cheaper than 2 multiplies + 1 exp on modern hardware; called by R4
    # (twice per percentile invocation) and by partition_extend's count
    # remap. Not called per-observation — R2 uses log()/log_ratio directly.
    my ($p, $i) = @_;
    return $p->{min} * exp($p->{log_ratio} * $i / $p->{bin_count});
}

sub partition_new {
    # R1: lazily construct a partition seeded around $v0.
    # Seed: min = v0 / sqrt(10^seed_decades), max = v0 * sqrt(10^seed_decades).
    # bin_count = bpd * seed_decades, integer-truncated. Locked at:
    #   features/187-histogram-bin-counter-percentiles.md § Decision 5
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
        log_ratio => log($max / $min),  # cached for closed-form bin_assign
        rebins    => 0,
    };
}

sub partition_extend {
    # R1: HdrHistogram doubling-rebin so $value falls inside [min, max].
    # When $value > max, multiply max by 10^(decades/2) until it contains
    # $value; symmetric for $value < min. After extension, remap existing
    # bin counts via geometric-midpoint projection into the new geometry
    # (index-monotonic in the extension direction — counts cluster on a
    # contiguous range of new indices, no scatter). Locked at:
    #   features/187-histogram-bin-counter-percentiles.md § Decision 5
    #
    # Returns the new bins arrayref; the caller is expected to swap it in.
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
    # Re-derive bin_count from the new span so per-decade resolution is preserved.
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
        my $midpoint = sqrt($lower * $upper);  # geometric midpoint
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

sub partition_rebin {
    # R12 (#201): re-bin a source partition's counts into a target partition
    # with caller-specified [new_min, new_max] and new_bin_count.
    # Geometric-midpoint projection per the fidelity invariant — each source
    # bin's count goes entirely to one target bin (the one containing the
    # source bin's geometric midpoint). No cross-bin mass splitting.
    # Reuses the same remap algorithm as partition_extend (ltl:613-622),
    # the only difference is the caller chooses target geometry instead of
    # HdrHistogram doubling deriving it. Locked at:
    #   features/189-histogram-bin-counter-primitives.md § R12
    #   features/201-display-geometry-bound-consumers.md § Recommendation
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
    # Zero-fill so the bins arrayref has exactly $new_bin_count elements.
    for my $i (0 .. $new_bin_count - 1) {
        $new_bins[$i] //= 0;
    }
    my $new_partition = {
        min       => $new_min,
        max       => $new_max,
        bpd       => $p->{bpd},
        decades   => log($new_max / $new_min) / log(10),
        bin_count => $new_bin_count,
        log_ratio => $new_log_ratio,
        rebins    => 0,
    };
    return ($new_partition, \@new_bins);
}

sub snapshot_counter_telemetry {
    # Capture per-consumer telemetry from a streaming counter store before
    # the store is discarded at finalize. Populates the locked #187 Decision 8
    # -V fields read later by emit_bin_counter_mode_verbose().
    my ($store) = @_;
    my $n = scalar keys %$store;
    my ($total_rebins, $max_bins, $with_over, $with_under, $over_sum, $under_sum) = (0, 0, 0, 0, 0, 0);
    my @rebins;
    for my $entry (values %$store) {
        my $p = $entry->{partition};
        $total_rebins += $p->{rebins};
        push @rebins, $p->{rebins};
        $max_bins = $p->{bin_count} if $p->{bin_count} > $max_bins;
        my $o = $entry->{overflow}  // 0;
        my $u = $entry->{underflow} // 0;
        $with_over++  if $o > 0;
        $with_under++ if $u > 0;
        $over_sum    += $o;
        $under_sum   += $u;
    }
    my @sorted = sort { $a <=> $b } @rebins;
    my $p50 = @sorted ? $sorted[int(@sorted * 0.50)] : 0;
    my $p95 = @sorted ? $sorted[int(@sorted * 0.95)] : 0;
    my $p99 = @sorted ? $sorted[int(@sorted * 0.99)] : 0;
    my $rmax = @sorted ? $sorted[-1] : 0;
    require Devel::Size;
    my $bytes = Devel::Size::total_size($store);
    return {
        partition_count                 => $n,
        total_rebin_events              => $total_rebins,
        max_partition_bins              => $max_bins,
        partitions_with_overflow_count  => $with_over,
        partitions_with_underflow_count => $with_under,
        overflow_total                  => $over_sum,
        underflow_total                 => $under_sum,
        counter_memory_bytes            => $bytes,
        rebins_p50                      => $p50,
        rebins_p95                      => $p95,
        rebins_p99                      => $p99,
        rebins_max                      => $rmax,
    };
}

sub bin_assign {
    # R2: closed-form bin index. Returns:
    #   ('IN',        $i)     value in [min, max]
    #   ('UNDERFLOW', undef)  value < min
    #   ('OVERFLOW',  undef)  value > max
    # The caller decides whether to extend the partition or increment an
    # over/underflow counter. counter_update() composes those choices per
    # the auto-resize lifecycle.
    my ($p, $v) = @_;
    return ('UNDERFLOW', undef) if $v < $p->{min};
    return ('OVERFLOW',  undef) if $v > $p->{max};
    my $i = int($p->{bin_count} * log($v / $p->{min}) / $p->{log_ratio});
    $i = $p->{bin_count} - 1 if $i >= $p->{bin_count};
    $i = 0                   if $i < 0;
    return ('IN', $i);
}

sub counter_update {
    # R3 + R6: increment the counter for ($store, $key, $value).
    # $store is a hashref; $key is a caller-formed string (the caller composes
    # the key from whatever shape its consumer needs — (category, log_key),
    # time_bucket, '', etc. — joined with "\x1f" by convention). Lazy partition
    # construction on first observation per the auto-resize lifecycle locked at:
    #   features/187-histogram-bin-counter-percentiles.md § Decision 5
    # Out-of-range triggers extend; if the extended partition still can't
    # contain the value (only reachable when a future growth cap is added —
    # none today), the over/underflow counter increments per:
    #   features/187-histogram-bin-counter-percentiles.md § Decision 4
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

    # Out of range: extend the partition, remap existing counts, re-assign.
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
    # R4: Prometheus HistogramQuantile in-bucket interpolation. Formula and
    # rank convention locked verbatim against promql/quantile.go at:
    #   features/187-histogram-bin-counter-percentiles.md § Decision 1
    #
    # 1. total_N = sum(bins) + underflow + overflow
    # 2. target_rank = ceil(q * total_N)
    # 3. Walk: underflow -> in-range bins low-to-high -> overflow
    # 4. If target_rank lands in underflow: return boundary[0],          audit='low'
    #    If target_rank lands in overflow:  return boundary[bin_count],  audit='high'
    #    Otherwise: rank_in_bin = target_rank - (cum - c);
    #               fraction    = rank_in_bin / c;
    #               value       = lower * (upper/lower)^fraction;        audit='none'
    #
    # Per-quantile audit semantics: a partition with overflow > 0 may still
    # report audit='none' for some quantiles — the audit is decided by where
    # the target rank lands, not by partition state. Locked at:
    #   features/189-bin-counter-primitives-implementation-readiness-audit.md § Bucket A § A3
    #
    # Returns (undef, 'none') for empty counter maps. Caller should not invoke
    # in that state, but the contract is defined.
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
    # Must be in overflow.
    return (bin_boundary($p, $p->{bin_count}), 'high');
}

# VERBATIM from ltl:7682
sub merge_bin_counter_entries {
    my ($target, $source) = @_;
    if (!$target->{partition}) {
        # Target empty — adopt source wholesale.
        $target->{partition} = $source->{partition};
        $target->{bins}      = $source->{bins} // [];
        $target->{overflow}  = $source->{overflow}  // 0;
        $target->{underflow} = $source->{underflow} // 0;
        return;
    }
    return unless $source->{partition};

    my $tp = $target->{partition};
    my $sp = $source->{partition};

    # Compute the union geometry. partition_extend's doubling history can
    # leave the two partitions with non-congruent (min, max) even when their
    # observation streams overlapped, so we cannot just per-bin add directly
    # — we rebin both into a shared union geometry first.
    my $union_min = $tp->{min} < $sp->{min} ? $tp->{min} : $sp->{min};
    my $union_max = $tp->{max} > $sp->{max} ? $tp->{max} : $sp->{max};
    my $bpd       = $tp->{bpd};
    my $union_decades   = log($union_max / $union_min) / log(10);
    my $union_bin_count = int($bpd * $union_decades);
    $union_bin_count = 1 if $union_bin_count < 1;

    if ($tp->{min} != $union_min || $tp->{max} != $union_max || $tp->{bin_count} != $union_bin_count) {
        my ($new_p, $new_bins) = partition_rebin($tp, $target->{bins}, $union_min, $union_max, $union_bin_count);
        $target->{partition} = $new_p;
        $target->{bins}      = $new_bins;
    }

    my $source_bins_aligned;
    if ($sp->{min} != $union_min || $sp->{max} != $union_max || $sp->{bin_count} != $union_bin_count) {
        my (undef, $new_bins) = partition_rebin($sp, $source->{bins}, $union_min, $union_max, $union_bin_count);
        $source_bins_aligned = $new_bins;
    } else {
        $source_bins_aligned = $source->{bins};
    }

    for my $i (0 .. $union_bin_count - 1) {
        my $sc = $source_bins_aligned->[$i] // 0;
        next if $sc == 0;
        $target->{bins}->[$i] = ($target->{bins}->[$i] // 0) + $sc;
    }
    $target->{overflow}  += ($source->{overflow}  // 0);
    $target->{underflow} += ($source->{underflow} // 0);
}

# --- non-verbatim T-side additions --------------------------------------------

# counter_update with the #189-prototype growth cap ($max_rebins). Body is the
# verbatim counter_update with one inserted check before partition_extend.
sub counter_update_capped {
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

    # --- cap hook (189-bin-counter-primitives.pl --max-rebins semantics) ---
    if (defined $max_rebins && $entry->{partition}{rebins} >= $max_rebins) {
        if ($where eq 'OVERFLOW') { $entry->{overflow}++ } else { $entry->{underflow}++ }
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

sub _target_rank {
    my ($q, $total_N, $conv) = @_;
    my $r = ($conv // 'ceil') eq 'int' ? int($q * $total_N) + 1 : POSIX::ceil($q * $total_N);
    $r = 1        if $r < 1;
    $r = $total_N if $r > $total_N;
    return $r;
}

# percentile() with a selectable rank convention; 'ceil' is the verbatim sub.
sub percentile_rank {
    my ($entry, $q, $conv) = @_;
    return percentile($entry, $q) if !defined $conv || $conv eq 'ceil';
    my $p    = $entry->{partition};
    my $bins = $entry->{bins};
    my $under = $entry->{underflow} // 0;
    my $over  = $entry->{overflow}  // 0;
    my $in_total = 0;
    $in_total += ($_ // 0) for @$bins;
    my $total_N = $under + $in_total + $over;
    return (undef, 'none') if $total_N == 0;
    my $target_rank = _target_rank($q, $total_N, $conv);
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

# =============================================================================
# Arm G — shared grid helpers (426-grid-fidelity.pl grid_index, verbatim form)
# =============================================================================
my $LN10 = log(10);
sub grid_index { my ($v, $bpd) = @_; return POSIX::floor($bpd * log($v) / $LN10) }
sub grid_lower { my ($i, $bpd) = @_; return 10 ** ($i / $bpd) }
sub grid_upper { my ($i, $bpd) = @_; return 10 ** (($i + 1) / $bpd) }
sub grid_index_checked {
    my ($v, $bpd) = @_;
    my $i = POSIX::floor($bpd * log($v) / $LN10);
    if    ($v <  10 ** ($i / $bpd))       { return ($i - 1, 1) }
    elsif ($v >= 10 ** (($i + 1) / $bpd)) { return ($i + 1, 1) }
    return ($i, 0);
}

# =============================================================================
# Oracle — calculate_statistics nearest-rank (ltl:12716 `$sorted[int($n*$q)]`)
# =============================================================================
sub oracle_percentiles {
    my ($values, $quantiles) = @_;
    my @sorted = sort { $a <=> $b } @$values;
    my $n = scalar @sorted;
    return map { undef } @$quantiles if $n == 0;
    return map { my $i = int($n * $_); $i = $#sorted if $i > $#sorted; $sorted[$i] } @$quantiles;
}

# =============================================================================
# Parsers
# =============================================================================

# Tomcat access log regex — verbatim from prototype/96-fuzzy-consolidation.pl:228
my $access_log_regex = qr/^(.+? ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)[ ]?([0-9.]+)?[ ]?(\S+)?[ ]?(\S+)?/;

# ThingWorx ApplicationLog regex — verbatim from prototype/96:225 (kept for future use; durations come from access logs in V5/V2)
my $twx_regex = qr/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})[\+\-]\d{4} \[L: ([^\]]*)\] \[O: ([^\]]*)] \[I: ([^\]]*)] \[U: ([^\]]*)] \[S: ([^\]]*)] \[P: ([^\]]*)] \[T: ((?:\](?! )|[^\]])*)] (.*)/;

# VERBATIM: prototype/189-bin-counter-primitives.pl parse_line (lines 113-165),
# renamed parse_access_line.
# parse_line($line) -> ($category, $log_key, $duration) or () if unmatched
# Mirrors prototype/96:268-291 key construction for Tomcat access logs.
sub parse_access_line {
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

# VERBATIM body of 426-grid-fidelity.pl's read loop (lines 204-219), wrapped as
# a function; `next` became `return ()`; the duration is returned rather than
# pushed. Category = the [L: ...] level ($category_bucket).
my $re_twx = $twx_regex;
sub parse_twx_line {
    local $_ = $_[0];
    my ($timestamp_str, $category_bucket, $object, undef, undef, undef, undef, $thread, $message) = $_ =~ $re_twx;
    return () unless defined $timestamp_str;
    return () unless index($message, ' durationM') >= 0;
    my ($duration) = $message =~ / durationM[sS]\s*=\s*(\d+)/;
    return () unless defined $duration;
    $message =~ s/ ((bytes|durationM[sS])\s*=\s*)(\d+)/ $1?/g;
    $message =~ s/ count\s*=\s*\d+/ count=?/g;
    my $threadname = $thread;
    if (defined $thread && $thread ne "") { my ($pool) = $thread =~ /(.*)-\d+$/; $threadname = $pool if defined $pool }
    my $truncated_thread = defined($threadname) ? substr($threadname, 0, 20) : undef;
    my $truncated_object = defined($object) ? substr($object, length($object) > 25 ? length($object) - 25 : 0, 25) : undef;
    my $log_key = substr("[$category_bucket] [$truncated_thread] [$truncated_object] $message", 0, 200);
    return ($category_bucket, $log_key, $duration + 0);
}

sub iterate_durations {
    my ($file, $cb, %opt) = @_;
    open(my $fh, '<', $file) or die "Cannot open $file: $!\n";
    my %c = (format => undef, lines => 0, matched => 0, positive => 0, zero => 0,
             negative => 0, no_duration => 0, unparsed => 0);
    my (%keys_any, %keys_pos);
    my $count_keys = $opt{count_keys};
    my $parser;
    while (my $line = <$fh>) {
        $c{lines}++;
        last if defined $opt{max_lines} && $c{lines} > $opt{max_lines};
        my @r;
        if (!$parser) {
            # twx FIRST: the loose access regex also matches ScriptLog lines whose
            # message carries a quoted string followed by a 3-digit number.
            @r = parse_twx_line($line);
            if (@r) { $parser = \&parse_twx_line; $c{format} = 'twx' }
            else {
                @r = parse_access_line($line);
                if (@r) { $parser = \&parse_access_line; $c{format} = 'access' }
            }
        } else {
            @r = $parser->($line);
        }
        if (!@r) { $c{unparsed}++; next }
        $c{matched}++;
        my ($cat, $key, $dur) = @r;
        if (!defined $dur) { $c{no_duration}++; next }
        $keys_any{"$cat\x1f$key"} = 1 if $count_keys;
        if ($dur > 0) {
            $c{positive}++;
            $keys_pos{"$cat\x1f$key"} = 1 if $count_keys;
            $cb->($cat, $key, $dur);
        } elsif ($dur == 0) { $c{zero}++ }
        else { $c{negative}++ }
    }
    close $fh;
    if ($count_keys) { $c{keys_any} = scalar keys %keys_any; $c{keys_positive} = scalar keys %keys_pos }
    $last_iterate = \%c;
    return \%c;
}

# =============================================================================
# Store factory
# =============================================================================
sub store_new {
    my ($arm, %opt) = @_;
    die "arm must be T|S|G\n" unless defined $arm && $arm =~ /^[TSG]$/;
    my $class = "Revalidate426::Store::$arm";
    return $class->new(%opt);
}

sub _canon_TS {
    my ($min, $max, $bc, $rebins, $over, $under, $pairs) = @_;
    return sprintf('%.17g/%.17g/%d/%d', $min, $max, $bc, $rebins) . "|o$over|u$under|" . join(',', @$pairs);
}

# =============================================================================
package Revalidate426::Store;
use strict; use warnings;
use Digest::MD5 ();
use Devel::Size ();

sub arm { $_[0]{arm} }
sub bpd { $_[0]{bpd} }
sub has { defined $_[0]->_row($_[1]) }

sub digest {
    my ($self) = @_;
    my $d = Digest::MD5->new;
    for my $k (sort { $a cmp $b } $self->keys) {
        $d->add("$k\t" . $self->canonical($k) . "\n");
    }
    return $d->hexdigest;
}

# =============================================================================
package Revalidate426::Store::T;
use strict; use warnings;
use POSIX ();
use Devel::Size ();
our @ISA = ('Revalidate426::Store');

sub new {
    my ($class, %opt) = @_;
    return bless { arm => 'T', bpd => $opt{bpd} // $Revalidate426::percentile_buckets_per_decade, store => {} }, $class;
}
sub _row { $_[0]{store}{$_[1]} }
sub add {
    my ($self, $key, $value) = @_;
    if (defined $Revalidate426::max_rebins) {
        Revalidate426::counter_update_capped($self->{store}, $key, $value, $self->{bpd});
    } else {
        Revalidate426::counter_update($self->{store}, $key, $value, $self->{bpd});
    }
}
sub percentile {
    my ($self, $key, $q, $conv) = @_;
    my $e = $self->{store}{$key} or return (undef, 'none');
    return Revalidate426::percentile_rank($e, $q, $conv);
}
sub merge {
    my ($self, $tk, $sk, %o) = @_;
    my $src = $self->{store}{$sk} or return;
    my $tgt = $self->{store}{$tk} //= {};
    Revalidate426::merge_bin_counter_entries($tgt, $src);
    delete $self->{store}{$sk} if $o{drop_source};
    return;
}
sub keys { return CORE::keys %{ $_[0]{store} } }
sub n {
    my ($self, $key) = @_;
    my $e = $self->{store}{$key} or return 0;
    my $t = ($e->{overflow} // 0) + ($e->{underflow} // 0);
    $t += ($_ // 0) for @{ $e->{bins} };
    return $t;
}
sub entry { $_[0]{store}{$_[1]} }
sub geometry {
    my ($self, $key) = @_;
    my $e = $self->{store}{$key} or return undef;
    my $p = $e->{partition};
    return { min => $p->{min}, max => $p->{max}, bin_count => $p->{bin_count}, log_ratio => $p->{log_ratio},
             decades => $p->{decades}, rebins => $p->{rebins}, overflow => $e->{overflow} // 0, underflow => $e->{underflow} // 0 };
}
sub bins_pairs {
    my ($self, $key) = @_;
    my $e = $self->{store}{$key} or return ();
    my $b = $e->{bins};
    return map { defined $b->[$_] && $b->[$_] ? "$_:$b->[$_]" : () } 0 .. $#$b;
}
sub canonical {
    my ($self, $key) = @_;
    my $e = $self->{store}{$key} or return '';
    my $p = $e->{partition};
    return Revalidate426::_canon_TS($p->{min}, $p->{max}, $p->{bin_count}, $p->{rebins},
                                    $e->{overflow} // 0, $e->{underflow} // 0, [ $self->bins_pairs($key) ]);
}
sub telemetry { Revalidate426::snapshot_counter_telemetry($_[0]{store}) }
sub memory_bytes { Devel::Size::total_size($_[0]{store}) }

# =============================================================================
package Revalidate426::Store::S;
use strict; use warnings;
use POSIX ();
use Devel::Size ();
our @ISA = ('Revalidate426::Store');

sub new {
    my ($class, %opt) = @_;
    my $bpd = $opt{bpd} // $Revalidate426::percentile_buckets_per_decade;
    return bless {
        arm => 'S', bpd => $bpd,
        row => {}, key => [],
        pmin => [], pmax => [], pbc => [], plr => [], prb => [], pdec => [], over => [], under => [], bins => [],
    }, $class;
}
sub _row { $_[0]{row}{$_[1]} }
sub _row_new {
    my ($self, $key) = @_;
    my $i = scalar @{ $self->{key} };
    push @{ $self->{key} }, $key;
    $self->{row}{$key} = $i;
    return $i;
}

# K4 write path (426-bin-store-mini.pl %COUNTER{K4}), seed constants computed
# per call from the globals so configure() takes effect.
sub add {
    my ($self, $key, $duration) = @_;
    my $i = $self->{row}{$key};
    my ($pmin, $pmax, $pbc, $plr, $bins) = @$self{qw(pmin pmax pbc plr bins)};
    if (!defined $i) {
        $i = $self->_row_new($key);
        my $seed_half = sqrt(10 ** $Revalidate426::percentile_seed_decades);
        $pmin->[$i] = $duration / $seed_half;
        $pmax->[$i] = $duration * $seed_half;
        $pbc->[$i]  = int($self->{bpd} * $Revalidate426::percentile_seed_decades);
        $plr->[$i]  = log($pmax->[$i] / $pmin->[$i]);
        $self->{prb}[$i]   = 0;
        $self->{pdec}[$i]  = $Revalidate426::percentile_seed_decades;
        $self->{over}[$i]  = 0;
        $self->{under}[$i] = 0;
    }
    if ($duration < $pmin->[$i] || $duration > $pmax->[$i]) {
        $self->_extend($i, $duration);
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
            _bump_offset_dense($bins, $i, $idx);
        }
    }
}
sub _bump_offset_dense {
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
sub _dense_view {            # row -> dense bins arrayref (index 0-based)
    my ($self, $i) = @_;
    my $b = $self->{bins}[$i] // [];
    return [] unless @$b;
    my ($base, @c) = @$b;
    my @d; $d[$base + $_] = $c[$_] for 0 .. $#c;
    return \@d;
}
sub _span_from_dense {       # dense arrayref -> [base, counts...] trimmed to nonzero
    my ($dense) = @_;
    my ($first, $last);
    for my $j (0 .. $#$dense) {
        next unless defined $dense->[$j] && $dense->[$j];
        $first //= $j; $last = $j;
    }
    return [] unless defined $first;
    return [ $first, map { $dense->[$_] // 0 } $first .. $last ];
}
sub _partition_view {
    my ($self, $i) = @_;
    return { min => $self->{pmin}[$i], max => $self->{pmax}[$i], bpd => $self->{bpd},
             decades => $self->{pdec}[$i], bin_count => $self->{pbc}[$i], log_ratio => $self->{plr}[$i],
             rebins => $self->{prb}[$i] };
}
sub _write_partition {
    my ($self, $i, $p) = @_;
    $self->{pmin}[$i] = $p->{min}; $self->{pmax}[$i] = $p->{max}; $self->{pbc}[$i] = $p->{bin_count};
    $self->{plr}[$i] = $p->{log_ratio}; $self->{prb}[$i] = $p->{rebins}; $self->{pdec}[$i] = $p->{decades};
}
# Port of extend_cols(offset_dense=1) plus the cap hook.
sub _extend {
    my ($self, $i, $value) = @_;
    my ($pmin, $pmax, $pbc, $plr, $bins, $over, $under) = @$self{qw(pmin pmax pbc plr bins over under)};
    if (defined $Revalidate426::max_rebins && $self->{prb}[$i] >= $Revalidate426::max_rebins) {
        if ($value > $pmax->[$i]) { $over->[$i]++ } else { $under->[$i]++ }
        return;
    }
    my $p = $self->_partition_view($i);
    my $new_bins = Revalidate426::partition_extend($p, $value, $self->_dense_view($i));
    $self->_write_partition($i, $p);
    $bins->[$i] = _span_from_dense($new_bins);
    # re-assign
    if ($value < $pmin->[$i]) { $under->[$i]++; return }
    if ($value > $pmax->[$i]) { $over->[$i]++;  return }
    my $idx = int($pbc->[$i] * log($value / $pmin->[$i]) / $plr->[$i]);
    $idx = $pbc->[$i] - 1 if $idx >= $pbc->[$i];
    $idx = 0 if $idx < 0;
    _bump_offset_dense($bins, $i, $idx);
}
# Port of percentile_cols(offset_dense=1) with the rank convention parameter.
sub percentile {
    my ($self, $key, $q, $conv) = @_;
    my $i = $self->{row}{$key};
    return (undef, 'none') unless defined $i;
    my ($pmin, $pbc, $plr, $bins, $over, $under) = @$self{qw(pmin pbc plr bins over under)};
    my $b = $bins->[$i] // [];
    my $base = $b->[0] // 0;
    my $u = $under->[$i] // 0;
    my $o = $over->[$i]  // 0;
    my $in_total = 0;
    $in_total += ($_ // 0) for @{$b}[1 .. $#$b];
    my $total_N = $u + $in_total + $o;
    return (undef, 'none') if $total_N == 0;
    my $target_rank = Revalidate426::_target_rank($q, $total_N, $conv);
    my ($mn, $lr, $bc) = ($pmin->[$i], $plr->[$i], $pbc->[$i]);
    my $cum = 0;
    if ($u > 0) {
        $cum += $u;
        return ($mn * exp($lr * 0 / $bc), 'low') if $target_rank <= $cum;
    }
    for my $bi ($base .. $base + $#$b - 1) {
        my $c = $b->[$bi - $base + 1] // 0;
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
sub entry {
    my ($self, $key) = @_;
    my $i = $self->{row}{$key};
    return undef unless defined $i;
    return { partition => $self->_partition_view($i), bins => $self->_dense_view($i),
             overflow => $self->{over}[$i] // 0, underflow => $self->{under}[$i] // 0 };
}
sub _tombstone {
    my ($self, $i) = @_;
    delete $self->{row}{ $self->{key}[$i] };
    $self->{key}[$i] = undef;
    $self->{$_}[$i] = undef for qw(pmin pmax pbc plr prb pdec over under bins);
}
sub merge {
    my ($self, $tk, $sk, %o) = @_;
    my $si = $self->{row}{$sk};
    return unless defined $si;
    my $ti = $self->{row}{$tk};
    my $src = $self->entry($sk);
    my $tgt = defined $ti ? $self->entry($tk) : {};
    Revalidate426::merge_bin_counter_entries($tgt, $src);
    $ti = $self->_row_new($tk) unless defined $ti;
    $self->_write_partition($ti, $tgt->{partition});
    $self->{bins}[$ti]  = _span_from_dense($tgt->{bins});
    $self->{over}[$ti]  = $tgt->{overflow};
    $self->{under}[$ti] = $tgt->{underflow};
    $self->_tombstone($si) if $o{drop_source};
    return;
}
sub keys { return CORE::keys %{ $_[0]{row} } }
sub n {
    my ($self, $key) = @_;
    my $i = $self->{row}{$key};
    return 0 unless defined $i;
    my $b = $self->{bins}[$i] // [];
    my $t = ($self->{over}[$i] // 0) + ($self->{under}[$i] // 0);
    $t += ($_ // 0) for @{$b}[1 .. $#$b];
    return $t;
}
sub geometry {
    my ($self, $key) = @_;
    my $i = $self->{row}{$key};
    return undef unless defined $i;
    return { min => $self->{pmin}[$i], max => $self->{pmax}[$i], bin_count => $self->{pbc}[$i], log_ratio => $self->{plr}[$i],
             decades => $self->{pdec}[$i], rebins => $self->{prb}[$i], overflow => $self->{over}[$i] // 0, underflow => $self->{under}[$i] // 0 };
}
sub bins_pairs {
    my ($self, $key) = @_;
    my $i = $self->{row}{$key};
    return () unless defined $i;
    my $b = $self->{bins}[$i] // [];
    return () unless @$b;
    my ($base, @c) = @$b;
    return map { $c[$_] ? ($base + $_) . ":$c[$_]" : () } 0 .. $#c;
}
sub canonical {
    my ($self, $key) = @_;
    my $i = $self->{row}{$key};
    return '' unless defined $i;
    return Revalidate426::_canon_TS($self->{pmin}[$i], $self->{pmax}[$i], $self->{pbc}[$i], $self->{prb}[$i],
                                    $self->{over}[$i] // 0, $self->{under}[$i] // 0, [ $self->bins_pairs($key) ]);
}
sub _columns { my ($self) = @_; return { map { $_ => $self->{$_} } qw(row key pmin pmax pbc plr prb pdec over under bins) } }
sub memory_bytes { Devel::Size::total_size($_[0]->_columns) }
sub telemetry {
    my ($self) = @_;
    my @rows = values %{ $self->{row} };
    my $n = scalar @rows;
    my ($total_rebins, $max_bins, $with_over, $with_under, $over_sum, $under_sum) = (0, 0, 0, 0, 0, 0);
    my @rebins;
    for my $i (@rows) {
        $total_rebins += $self->{prb}[$i];
        push @rebins, $self->{prb}[$i];
        $max_bins = $self->{pbc}[$i] if $self->{pbc}[$i] > $max_bins;
        my $o = $self->{over}[$i]  // 0;
        my $u = $self->{under}[$i] // 0;
        $with_over++  if $o > 0;
        $with_under++ if $u > 0;
        $over_sum  += $o;
        $under_sum += $u;
    }
    my @sorted = sort { $a <=> $b } @rebins;
    return {
        partition_count                 => $n,
        total_rebin_events              => $total_rebins,
        max_partition_bins              => $max_bins,
        partitions_with_overflow_count  => $with_over,
        partitions_with_underflow_count => $with_under,
        overflow_total                  => $over_sum,
        underflow_total                 => $under_sum,
        counter_memory_bytes            => $self->memory_bytes,
        rebins_p50                      => (@sorted ? $sorted[int(@sorted * 0.50)] : 0),
        rebins_p95                      => (@sorted ? $sorted[int(@sorted * 0.95)] : 0),
        rebins_p99                      => (@sorted ? $sorted[int(@sorted * 0.99)] : 0),
        rebins_max                      => (@sorted ? $sorted[-1] : 0),
    };
}

# =============================================================================
package Revalidate426::Store::G;
use strict; use warnings;
use POSIX ();
use Devel::Size ();
our @ISA = ('Revalidate426::Store');

sub new {
    my ($class, %opt) = @_;
    my $bpd = $opt{bpd} // $Revalidate426::percentile_buckets_per_decade;
    return bless { arm => 'G', bpd => $bpd, row => {}, key => [], bins => [] }, $class;
}
sub _row { $_[0]{row}{$_[1]} }
sub _row_new {
    my ($self, $key) = @_;
    my $i = scalar @{ $self->{key} };
    push @{ $self->{key} }, $key;
    $self->{row}{$key} = $i;
    return $i;
}
sub add {
    my ($self, $key, $value) = @_;
    my $idx = POSIX::floor($self->{bpd} * log($value) / $LN10);
    my $i = $self->{row}{$key};
    if (!defined $i) {
        $i = $self->_row_new($key);
        $self->{bins}[$i] = [ $idx, 1 ];
        return;
    }
    my $b = $self->{bins}[$i];
    if (!@$b) { @$b = ($idx, 1); return }
    my $base = $b->[0];
    if ($idx >= $base) { $b->[$idx - $base + 1]++; return }
    splice @$b, 1, 0, (0) x ($base - $idx);
    $b->[0] = $idx;
    $b->[1]++;
}
sub percentile {
    my ($self, $key, $q, $conv) = @_;
    my $i = $self->{row}{$key};
    return (undef, 'none') unless defined $i;
    my $b = $self->{bins}[$i] // [];
    return (undef, 'none') unless @$b;
    my $base = $b->[0];
    my $total_N = 0;
    $total_N += ($_ // 0) for @{$b}[1 .. $#$b];
    return (undef, 'none') if $total_N == 0;
    my $target_rank = Revalidate426::_target_rank($q, $total_N, $conv);
    my $bpd = $self->{bpd};
    my $cum = 0;
    for my $j (1 .. $#$b) {
        my $c = $b->[$j] // 0;
        next if $c == 0;
        $cum += $c;
        if ($target_rank <= $cum) {
            my $gi = $base + $j - 1;
            my $lower = 10 ** ($gi / $bpd); my $upper = 10 ** (($gi + 1) / $bpd);
            my $rank_in_bin = $target_rank - ($cum - $c); my $fraction = $rank_in_bin / $c;
            return ($lower * (($upper / $lower) ** $fraction), 'none');
        }
    }
    die "unreachable";
}
sub merge {
    my ($self, $tk, $sk, %o) = @_;
    my $si = $self->{row}{$sk};
    return unless defined $si;
    my $sb = $self->{bins}[$si] // [];
    my $ti = $self->{row}{$tk};
    if (!defined $ti) {
        $ti = $self->_row_new($tk);
        $self->{bins}[$ti] = [ @$sb ];
    } elsif (@$sb) {
        my $tb = $self->{bins}[$ti];
        if (!@$tb) { @$tb = @$sb }
        else {
            my ($sbase, $tbase) = ($sb->[0], $tb->[0]);
            if ($sbase < $tbase) { splice @$tb, 1, 0, (0) x ($tbase - $sbase); $tb->[0] = $tbase = $sbase }
            for my $j (1 .. $#$sb) {
                my $c = $sb->[$j] // 0; next unless $c;
                $tb->[$sbase - $tbase + $j] += $c;
            }
        }
    }
    if ($o{drop_source}) {
        delete $self->{row}{$sk};
        $self->{key}[$si] = undef;
        $self->{bins}[$si] = undef;
    }
    return;
}
sub keys { return CORE::keys %{ $_[0]{row} } }
sub n {
    my ($self, $key) = @_;
    my $i = $self->{row}{$key};
    return 0 unless defined $i;
    my $b = $self->{bins}[$i] // [];
    my $t = 0; $t += ($_ // 0) for @{$b}[1 .. $#$b];
    return $t;
}
sub geometry {
    my ($self, $key) = @_;
    my $i = $self->{row}{$key};
    return undef unless defined $i;
    my $b = $self->{bins}[$i] // [];
    return { base => $b->[0], span => $#$b, lo_index => $b->[0], hi_index => (@$b ? $b->[0] + $#$b - 1 : undef) };
}
sub bins_pairs {
    my ($self, $key) = @_;
    my $i = $self->{row}{$key};
    return () unless defined $i;
    my $b = $self->{bins}[$i] // [];
    return () unless @$b;
    my ($base, @c) = @$b;
    return map { $c[$_] ? ($base + $_) . ":$c[$_]" : () } 0 .. $#c;
}
sub canonical {
    my ($self, $key) = @_;
    return '' unless defined $self->{row}{$key};
    return "grid/$self->{bpd}|o0|u0|" . join(',', $self->bins_pairs($key));
}
sub entry {
    my ($self, $key) = @_;
    my $i = $self->{row}{$key};
    return undef unless defined $i;
    my %h; for ($self->bins_pairs($key)) { my ($ix, $c) = split /:/; $h{$ix} = $c }
    return { bins => \%h };
}
sub _columns { my ($self) = @_; return { map { $_ => $self->{$_} } qw(row key bins) } }
sub memory_bytes { Devel::Size::total_size($_[0]->_columns) }
sub telemetry {
    my ($self) = @_;
    my @rows = values %{ $self->{row} };
    my (@spans, $imin, $imax);
    for my $i (@rows) {
        my $b = $self->{bins}[$i] // [];
        push @spans, $#$b;
        next unless @$b;
        my ($lo, $hi) = ($b->[0], $b->[0] + $#$b - 1);
        $imin = $lo if !defined $imin || $lo < $imin;
        $imax = $hi if !defined $imax || $hi > $imax;
    }
    my @s = sort { $a <=> $b } @spans;
    return {
        partition_count      => scalar @rows,
        span_p50             => (@s ? $s[int(@s * 0.50)] : 0),
        span_p95             => (@s ? $s[int(@s * 0.95)] : 0),
        span_p99             => (@s ? $s[int(@s * 0.99)] : 0),
        span_max             => (@s ? $s[-1] : 0),
        index_min            => $imin,
        index_max            => $imax,
        counter_memory_bytes => $self->memory_bytes,
    };
}

1;
