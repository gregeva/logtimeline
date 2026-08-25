#!/usr/bin/env perl
#
# 426-n5-merge-shapes.pl — aspect N5 of the #426 revalidation: merge shapes
# beyond consecutive pairs. Sections, all for ONE arm at ONE bpd per process
# (so only the arm under test lives in the process):
#
#   R  ROLLUP        many keys -> ONE accumulating target (the time-bucket ->
#                    global rollup shape). Timed; percentiles of the rolled-up
#                    target checked against the oracle over the UNION of all
#                    contributing values.
#   D  DISJOINT      pairs chosen so the two keys' value ranges do not overlap
#                    (widest union geometry, most remapping). Accuracy of the
#                    merged percentiles vs the oracle over the union, in BINS
#                    of error (bins = |log10(est/exact)| * bpd).
#   P  DEPTH         accuracy after 1, 3, 7, 15 successive merges into one
#                    target, measured at each depth against the running oracle.
#   O  ORDER         the same key set merged in several orders; digest of the
#                    resulting accumulator compared across orders, plus the
#                    per-quantile spread in bins.
#
# Error metric everywhere: bins_err = |log10(est/exact)| * bpd, i.e. the error
# expressed in bin widths of THIS arm's bpd, so 1.0 = one bin.
#
# Usage: perl prototype/426-n5-merge-shapes.pl --arm T|S|G --bpd N --file F
#        [--sections RDPO] [--runs 3] [--rollup-keys N] [--disjoint-pairs N]
#        [--depth-groups N] [--order-keys N] [--order-perms N] [--seed N]
#
# Every metric line is `name=value`; timings additionally as
#   TSV<TAB>arm<TAB>bpd<TAB>fixture<TAB>metric<TAB>median<TAB>min<TAB>max

use strict;
use warnings;
use FindBin;
use POSIX ();
use Time::HiRes qw(gettimeofday tv_interval);
use Digest::MD5 ();
use List::Util ();
require "$FindBin::Bin/426-revalidate-lib.pm";

my ($arm, $bpd, $file, $sections, $runs) = (undef, 53, undef, 'RDPO', 3);
my ($rollup_keys, $disjoint_pairs, $depth_groups, $order_keys, $order_perms, $seed, $min_n)
    = (2000, 200, 200, 200, 4, 20260826, 2);
while (@ARGV) {
    my $o = shift @ARGV;
    if    ($o eq '--arm')            { $arm = shift @ARGV }
    elsif ($o eq '--bpd')            { $bpd = shift @ARGV }
    elsif ($o eq '--file')           { $file = shift @ARGV }
    elsif ($o eq '--sections')       { $sections = shift @ARGV }
    elsif ($o eq '--runs')           { $runs = shift @ARGV }
    elsif ($o eq '--rollup-keys')    { $rollup_keys = shift @ARGV }
    elsif ($o eq '--disjoint-pairs') { $disjoint_pairs = shift @ARGV }
    elsif ($o eq '--depth-groups')   { $depth_groups = shift @ARGV }
    elsif ($o eq '--order-keys')     { $order_keys = shift @ARGV }
    elsif ($o eq '--order-perms')    { $order_perms = shift @ARGV }
    elsif ($o eq '--seed')           { $seed = shift @ARGV }
    elsif ($o eq '--min-n')          { $min_n = shift @ARGV }
    else { die "unknown option $o\n" }
}
die "--arm T|S|G required\n" unless defined $arm && $arm =~ /^[TSG]$/;
die "--file required\n" unless defined $file && -f $file;
Revalidate426::configure(bpd => $bpd, seed_decades => 5, max_rebins => undef);

my @Q  = (0.5, 0.9, 0.99);
my @QD = (0.01, 0.5, 0.9, 0.99, 0.999);   # for depth/disjoint accuracy
sub say_kv { my ($k, $v) = @_; print "$k=$v\n" }
(my $fx = $file) =~ s{.*/}{};
sub tsv {
    my ($metric, @secs) = @_;
    my ($med, $min, $max) = Revalidate426::median_min_max(@secs);
    printf "TSV\t%s\t%d\t%s\t%s\t%.6f\t%.6f\t%.6f\n", $arm, $bpd, $fx, $metric, $med, $min, $max;
    return ($med, $min, $max);
}
sub pct_of { my ($aref, $f) = @_; my @s = sort { $a <=> $b } @$aref; return @s ? $s[List::Util::min($#s, int(@s * $f))] : undef }
# bins of error between an estimate and the exact (oracle) value
sub bins_err {
    my ($est, $exact) = @_;
    return undef unless defined $est && defined $exact && $est > 0 && $exact > 0;
    return abs(log($est / $exact) / log(10)) * $bpd;
}
sub stats_line {
    my ($name, $aref) = @_;
    my @v = grep { defined } @{ $aref || [] };
    if (!@v) { say_kv($name . '_n', 0); return }
    my @s = sort { $a <=> $b } @v;
    say_kv($name . '_n',    scalar @s);
    say_kv($name . '_p50',  sprintf('%.4f', $s[int(@s * 0.5)]));
    say_kv($name . '_p95',  sprintf('%.4f', $s[List::Util::min($#s, int(@s * 0.95))]));
    say_kv($name . '_max',  sprintf('%.4f', $s[-1]));
    say_kv($name . '_maxraw', sprintf('%.12g', $s[-1]));
    say_kv($name . '_mean', sprintf('%.4f', List::Util::sum(@s) / @s));
    say_kv($name . '_gt1',  scalar grep { $_ > 1.0 } @s);
    say_kv($name . '_gt2',  scalar grep { $_ > 2.0 } @s);
    say_kv($name . '_gt1eps', scalar grep { $_ > 1.0 + 1e-9 } @s);
}
# deterministic PRNG so every arm sees the same choices
my $rs = $seed;
sub rnd { $rs = ($rs * 1103515245 + 12345) % 2147483648; return $rs / 2147483648 }
sub shuffled { my @a = @{$_[0]}; for (my $i = $#a; $i > 0; $i--) { my $j = int(rnd() * ($i + 1)); @a[$i,$j] = @a[$j,$i] } return @a }

say_kv(arm => $arm); say_kv(bpd => $bpd); say_kv(fixture => $fx);
say_kv(sections => $sections); say_kv(runs => $runs); say_kv(seed => $seed);
say_kv(perl => "$^V");

# --- parse once ---------------------------------------------------------------
my (@K, @D);
my $t0 = [gettimeofday];
my $counts = Revalidate426::iterate_durations($file, sub { push @K, "$_[0]\x1f$_[1]"; push @D, $_[2] }, count_keys => 1);
say_kv(parse_s => sprintf('%.3f', tv_interval($t0)));
say_kv("parse_$_" => $counts->{$_}) for qw(format lines matched positive keys_positive);
say_kv(n_samples => scalar @D);

# per-key value lists (the oracle's raw material)
my %VALS;
push @{ $VALS{ $K[$_] } }, $D[$_] for 0 .. $#K;
my @all_keys = sort { $a cmp $b } CORE::keys %VALS;
say_kv(keys_total => scalar @all_keys);
my @keys_ge2 = grep { @{ $VALS{$_} } >= $min_n } @all_keys;
say_kv(min_n => $min_n);
say_kv(keys_ge2 => scalar @keys_ge2);
say_kv(keys_n_ge_2 => scalar grep { @{ $VALS{$_} } >= 2 } @all_keys);

# per-key value range (min/max), for the disjoint selection
my %RANGE;
for my $k (@all_keys) {
    my @s = sort { $a <=> $b } @{ $VALS{$k} };
    $RANGE{$k} = [ $s[0], $s[-1] ];
}

sub fill_keys {   # a store containing exactly the listed keys
    my ($keys) = @_;
    my $st = Revalidate426::store_new($arm, bpd => $bpd);
    for my $k (@$keys) { $st->add($k, $_) for @{ $VALS{$k} } }
    return $st;
}
sub timed_runs {
    my ($n, $setup, $body) = @_;
    my @secs;
    for my $r (0 .. $n) {
        my $ctx = $setup->();
        my $t = [gettimeofday];
        $body->($ctx);
        push @secs, tv_interval($t) if $r > 0;
    }
    return @secs;
}

# =============================================================================
# R — ROLLUP: many keys into ONE accumulating target
# =============================================================================
if ($sections =~ /R/) {
    print "SECTION=rollup\n";
    my @rk = @all_keys;
    @rk = @rk[0 .. $rollup_keys - 1] if @rk > $rollup_keys;
    say_kv(rollup_source_keys => scalar @rk);
    my $target = "\x00ROLLUP";
    my $nvals = 0; $nvals += scalar @{ $VALS{$_} } for @rk;
    say_kv(rollup_values => $nvals);

    my $store;
    my @secs = timed_runs($runs,
        sub { undef $store; $store = fill_keys(\@rk); return $store },
        sub { my $s = $_[0]; $s->merge($target, $_, drop_source => 1) for @rk });
    my ($med) = tsv('rollup_s', @secs);
    say_kv(rollup_merges => scalar @rk);
    say_kv(rollup_us_per_merge => sprintf('%.2f', $med / @rk * 1e6));
    say_kv(rollup_n_after => $store->n($target));    # must equal rollup_values
    say_kv(rollup_keys_after => scalar $store->keys);
    say_kv(rollup_digest => Digest::MD5::md5_hex($store->canonical($target)));
    if ($arm ne 'G') {
        my $g = $store->geometry($target);
        say_kv(rollup_bin_count => $g->{bin_count});
        say_kv(rollup_rebins => $g->{rebins});
        say_kv(rollup_min => sprintf('%.6g', $g->{min}));
        say_kv(rollup_max => sprintf('%.6g', $g->{max}));
        say_kv(rollup_overflow => $g->{overflow});
        say_kv(rollup_underflow => $g->{underflow});
    } else {
        my $g = $store->geometry($target);
        say_kv(rollup_span => $g->{span});
        say_kv(rollup_lo_index => $g->{lo_index});
        say_kv(rollup_hi_index => $g->{hi_index});
    }
    # accuracy against the oracle over the union of all contributing values
    my @union = map { @{ $VALS{$_} } } @rk;
    my @exact = Revalidate426::oracle_percentiles(\@union, \@QD);
    my @errs;
    for my $qi (0 .. $#QD) {
        my ($v) = $store->percentile($target, $QD[$qi], 'int');
        my $e = bins_err($v, $exact[$qi]);
        push @errs, $e;
        say_kv(sprintf('rollup_q%s_est', $QD[$qi]),   defined $v ? sprintf('%.6g', $v) : 'undef');
        say_kv(sprintf('rollup_q%s_exact', $QD[$qi]), defined $exact[$qi] ? sprintf('%.6g', $exact[$qi]) : 'undef');
        say_kv(sprintf('rollup_q%s_bins_err', $QD[$qi]), defined $e ? sprintf('%.4f', $e) : 'undef');
    }
    stats_line('rollup_bins_err', \@errs);
    undef $store;
}

# =============================================================================
# D — DISJOINT SPANS: pairs whose value ranges do not overlap
# =============================================================================
if ($sections =~ /D/) {
    print "SECTION=disjoint\n";
    # Greedy disjoint pairing: walk keys in increasing max; for each unpaired
    # key take the unpaired partner with the LARGEST min that still clears it
    # (min_hi > max_lo => strictly disjoint value ranges). This maximises the
    # gap, which is the geometry-stressing case the section exists to measure.
    my @by_max = sort { $RANGE{$a}[1] <=> $RANGE{$b}[1] || $a cmp $b } @keys_ge2;
    my @by_min = sort { $RANGE{$b}[0] <=> $RANGE{$a}[0] || $a cmp $b } @keys_ge2;
    my (@pairs, %used);
    for my $lo (@by_max) {
        last if @pairs >= $disjoint_pairs;
        next if $used{$lo};
        for my $hi (@by_min) {
            next if $used{$hi} || $hi eq $lo;
            next unless $RANGE{$hi}[0] > $RANGE{$lo}[1];
            $used{$lo} = $used{$hi} = 1;
            push @pairs, [ $lo, $hi ];
            last;
        }
    }
    say_kv(disjoint_pairs => scalar @pairs);
    if (@pairs) {
        my @decsep = map { log($RANGE{$_->[1]}[0] / $RANGE{$_->[0]}[1]) / log(10) } @pairs;
        say_kv(disjoint_gap_decades_p50 => sprintf('%.3f', pct_of(\@decsep, 0.5)));
        say_kv(disjoint_gap_decades_max => sprintf('%.3f', pct_of(\@decsep, 1)));
        my @unionspan = map { log($RANGE{$_->[1]}[1] / $RANGE{$_->[0]}[0]) / log(10) } @pairs;
        say_kv(disjoint_union_decades_p50 => sprintf('%.3f', pct_of(\@unionspan, 0.5)));
        say_kv(disjoint_union_decades_max => sprintf('%.3f', pct_of(\@unionspan, 1)));

        my @flat = map { @$_ } @pairs;
        my $store;
        my @secs = timed_runs($runs,
            sub { undef $store; $store = fill_keys(\@flat); return $store },
            sub { my $s = $_[0]; $s->merge($_->[0], $_->[1], drop_source => 1) for @pairs });
        my ($med) = tsv('disjoint_merge_s', @secs);
        say_kv(disjoint_us_per_merge => sprintf('%.2f', $med / @pairs * 1e6));
        say_kv(disjoint_digest => $store->digest);

        # accuracy per pair, per quantile
        my (@errs, %per_q, @nfail);
        my ($ntot_ok) = (0);
        for my $p (@pairs) {
            my @union = (@{ $VALS{$p->[0]} }, @{ $VALS{$p->[1]} });
            $ntot_ok++ if $store->n($p->[0]) == scalar @union;
            my @exact = Revalidate426::oracle_percentiles(\@union, \@QD);
            for my $qi (0 .. $#QD) {
                my ($v) = $store->percentile($p->[0], $QD[$qi], 'int');
                my $e = bins_err($v, $exact[$qi]);
                push @errs, $e;
                push @{ $per_q{ $QD[$qi] } }, $e;
            }
        }
        say_kv(disjoint_n_conserved_pairs => $ntot_ok);
        stats_line('disjoint_bins_err', \@errs);
        stats_line("disjoint_q$_" . '_bins_err', $per_q{$_}) for @QD;
        if ($arm ne 'G') {
            my (@bc, @rb);
            for my $p (@pairs) { my $g = $store->geometry($p->[0]); push @bc, $g->{bin_count}; push @rb, $g->{rebins} }
            say_kv(disjoint_bin_count_p50 => pct_of(\@bc, 0.5));
            say_kv(disjoint_bin_count_max => pct_of(\@bc, 1));
            say_kv(disjoint_rebins_max => pct_of(\@rb, 1));
        } else {
            my @sp; for my $p (@pairs) { push @sp, $store->geometry($p->[0])->{span} }
            say_kv(disjoint_span_p50 => pct_of(\@sp, 0.5));
            say_kv(disjoint_span_max => pct_of(\@sp, 1));
        }
        undef $store;
    }
}

# =============================================================================
# P — MERGE DEPTH: accuracy after 1, 3, 7, 15 successive merges
# =============================================================================
if ($sections =~ /P/) {
    print "SECTION=depth\n";
    my @DEPTHS = (1, 3, 7, 15);
    my $need = $DEPTHS[-1] + 1;             # 16 keys per group
    my @pool = @keys_ge2;
    my $ngroups = List::Util::min($depth_groups, int(@pool / $need));
    say_kv(depth_groups => $ngroups);
    say_kv(depth_keys_per_group => $need);
    if ($ngroups > 0) {
        my @groups;
        for my $g (0 .. $ngroups - 1) { push @groups, [ @pool[ $g * $need .. $g * $need + $need - 1 ] ] }
        my @flat = map { @$_ } @groups;
        my $store = fill_keys(\@flat);
        my %err_at;      # depth -> [errors]
        my %errq_at;     # "depth|q" -> [errors]
        for my $grp (@groups) {
            my $tgt = $grp->[0];
            my @acc = @{ $VALS{$tgt} };
            my $done = 0;
            for my $step (1 .. $#$grp) {
                my $src = $grp->[$step];
                $store->merge($tgt, $src, drop_source => 1);
                push @acc, @{ $VALS{$src} };
                $done = $step;
                next unless grep { $_ == $done } @DEPTHS;
                my @exact = Revalidate426::oracle_percentiles(\@acc, \@QD);
                for my $qi (0 .. $#QD) {
                    my ($v) = $store->percentile($tgt, $QD[$qi], 'int');
                    my $e = bins_err($v, $exact[$qi]);
                    push @{ $err_at{$done} }, $e;
                    push @{ $errq_at{"$done|$QD[$qi]"} }, $e;
                }
            }
        }
        for my $d (@DEPTHS) {
            stats_line("depth${d}_bins_err", $err_at{$d});
            stats_line("depth${d}_q$_" . '_bins_err', $errq_at{"$d|$_"}) for @QD;
        }
        # geometry drift with depth (on the final depth only)
        if ($arm ne 'G') {
            my (@bc, @rb);
            for my $grp (@groups) { my $g = $store->geometry($grp->[0]); push @bc, $g->{bin_count}; push @rb, $g->{rebins} }
            say_kv(depth15_bin_count_p50 => pct_of(\@bc, 0.5));
            say_kv(depth15_bin_count_max => pct_of(\@bc, 1));
            say_kv(depth15_rebins_p50 => pct_of(\@rb, 0.5));
            say_kv(depth15_rebins_max => pct_of(\@rb, 1));
        } else {
            my @sp; for my $grp (@groups) { push @sp, $store->geometry($grp->[0])->{span} }
            say_kv(depth15_span_p50 => pct_of(\@sp, 0.5));
            say_kv(depth15_span_max => pct_of(\@sp, 1));
        }
        undef $store;
    }
}

# =============================================================================
# O — ORDER DEPENDENCE: same set, different merge orders
# =============================================================================
if ($sections =~ /O/) {
    print "SECTION=order\n";
    # groups of 8 keys; merge each group into one target in --order-perms
    # different orders; compare the resulting canonical strings and percentiles.
    my $GSZ = 8;
    my @pool = @keys_ge2;
    my $ngroups = List::Util::min(int($order_keys / $GSZ), int(@pool / $GSZ));
    say_kv(order_groups => $ngroups);
    say_kv(order_group_size => $GSZ);
    say_kv(order_perms => $order_perms);
    if ($ngroups > 0) {
        my @groups;
        for my $g (0 .. $ngroups - 1) { push @groups, [ @pool[ $g * $GSZ .. $g * $GSZ + $GSZ - 1 ] ] }
        # build the per-group orders ONCE (same for every arm: deterministic PRNG)
        my @orders;   # [group][perm] = arrayref of keys in merge order
        for my $gi (0 .. $#groups) {
            my @o;
            push @o, [ @{ $groups[$gi] } ];                        # perm 0: as-is
            push @o, [ reverse @{ $groups[$gi] } ];                # perm 1: reversed
            push @o, [ shuffled($groups[$gi]) ] for 3 .. $order_perms;  # the rest: shuffled
            $#o = $order_perms - 1;
            $orders[$gi] = \@o;
        }
        my ($diff_groups, $total_groups) = (0, 0);
        my (@spread_bins, %spread_q);
        my ($digest_all, @per_group_digest);
        for my $gi (0 .. $#groups) {
            my (%canon_seen, @canon, @pctsets);
            for my $pi (0 .. $order_perms - 1) {
                my $ord = $orders[$gi][$pi];
                # a fresh store per permutation holding just this group's keys,
                # accumulating into a NEUTRAL target so the target key itself is
                # not part of the ordering (a true set-merge).
                my $st = fill_keys($groups[$gi]);
                my $tgt = "\x00ORD";
                $st->merge($tgt, $_, drop_source => 1) for @$ord;
                my $c = $st->canonical($tgt);
                push @canon, $c; $canon_seen{$c}++;
                push @pctsets, [ map { my ($v) = $st->percentile($tgt, $_, 'int'); $v } @QD ];
                undef $st;
            }
            $total_groups++;
            my $ndistinct = scalar CORE::keys %canon_seen;
            $diff_groups++ if $ndistinct > 1;
            push @per_group_digest, Digest::MD5::md5_hex(join("\n", @canon));
            # per-quantile spread across permutations, in bins
            for my $qi (0 .. $#QD) {
                my @v = grep { defined && $_ > 0 } map { $_->[$qi] } @pctsets;
                next unless @v >= 2;
                my ($mn, $mx) = (List::Util::min(@v), List::Util::max(@v));
                my $sp = abs(log($mx / $mn) / log(10)) * $bpd;
                push @spread_bins, $sp;
                push @{ $spread_q{ $QD[$qi] } }, $sp;
            }
        }
        say_kv(order_groups_tested => $total_groups);
        say_kv(order_groups_differing => $diff_groups);
        say_kv(order_groups_differing_pct => sprintf('%.1f', $total_groups ? 100 * $diff_groups / $total_groups : 0));
        stats_line('order_spread_bins', \@spread_bins);
        stats_line("order_q$_" . '_spread_bins', $spread_q{$_}) for @QD;
    }
}
print "DONE\n";
