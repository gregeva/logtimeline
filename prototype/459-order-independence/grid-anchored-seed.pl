#!/usr/bin/env perl
# Issue #459 design probe: what happens if partitions are seeded on a GLOBAL
# log grid instead of around their own first observed value.
#
# Today partition_new centres [min, max] on v0, so no two keys' bin edges line
# up and combining them can only be done by projecting counts across
# non-congruent edges -- which displaces them. If min is instead snapped down
# to the nearest 10^(k/bpd) boundary, every partition in the run shares one
# set of edges, projection becomes an exact index shift, and the combined
# answer equals the answer the same samples would have given in one partition.
#
# This probe replaces ONLY partition_new's seed line; every other sub is the
# production code extracted verbatim. It reports, for each arm, the deviation
# from the pooled-sample reference in bin widths.
use strict;
use warnings;
use POSIX ();

use constant { COUNTER_BYTES_PER_PARTITION => 48, COUNTER_BYTES_PER_BIN_SLOT => 8 };
our $percentile_seed_decades = 5;   # the shipped seed span (ltl $percentile_seed_decades)
our $message_stats_member_bytes = 0;

do '/tmp/459-subs.pl'; die "load: $@" if $@;

my $GRID = 0;   # flipped per arm
{
    no warnings 'redefine';
    my $stock = \&partition_new;
    *partition_new = sub {
        my ($v0, $bpd, $seed_decades) = @_;
        return $stock->(@_) unless $GRID;
        my $half_span = sqrt(10 ** $seed_decades);
        # Snap the seed floor down to the nearest global grid boundary.
        my $min = 10 ** (POSIX::floor(log($v0 / $half_span) / log(10) * $bpd) / $bpd);
        my $max = $min * (10 ** $seed_decades);
        return { min => $min, max => $max, bpd => $bpd, decades => $seed_decades,
                 bin_count => int($bpd * $seed_decades), log_ratio => log($max / $min) };
    };
}

my $seed = 20260827;
sub nextval { $seed = ($seed * 1103515245 + 12345) % 2147483648; return $seed / 2147483648; }
sub clone_entry {
    my ($e) = @_;
    return { partition => { %{ $e->{partition} } }, bins => [ @{ $e->{bins} } ],
             overflow => $e->{overflow}, underflow => $e->{underflow},
             rebin_growth => $e->{rebin_growth}, rebin_merge => $e->{rebin_merge},
             members => $e->{members} };
}

my @quantiles = (0.01, 0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 0.99);
my $bpd = 53;

printf("%-8s  %-34s  %-34s\n", "members", "seeded on first value (today)", "seeded on a global grid");
printf("%-8s  %-34s  %-34s\n", "", "median / max (bin widths)", "median / max (bin widths)");

for my $count (2, 5, 15, 40) {
    my @row;
    for my $arm (0, 1) {
        $GRID = $arm;
        $seed = 20260827;    # identical sample stream in both arms
        my (@members, @pooled);
        for my $m (1 .. $count) {
            my $centre = 10 ** (nextval() * 4 - 1);
            my $entry;
            for (1 .. 200) {
                my $v = $centre * (10 ** (nextval() * 1.5 - 0.75));
                push @pooled, $v;
                $entry //= counter_entry_new($v, $bpd); counter_entry_observe($entry, $v);
            }
            push @members, $entry;
        }
        my $ref;
        for my $v (@pooled) {
            $ref //= counter_entry_new($v, $bpd); counter_entry_observe($ref, $v);
        }
        my $new = { partition => undef, bins => [], overflow => 0, underflow => 0 };
        merge_bin_counter_entries($new, clone_entry($_)) for @members;
        collapse_bin_counter_entry($new);

        my $bw = (10 ** (1 / $bpd) - 1) * 100;
        my @dev;
        for my $q (@quantiles) {
            my $rv = (percentile($ref, $q))[0];
            next unless $rv && $rv > 0;
            push @dev, abs((percentile($new, $q))[0] - $rv) / $rv * 100 / $bw;
        }
        my @s = sort { $a <=> $b } @dev;
        push @row, sprintf("%8.4f / %8.4f", $s[int(@s * 0.50)], $s[-1]);
    }
    printf("%-8d  %-34s  %-34s\n", $count, $row[0], $row[1]);
}

# ---------------------------------------------------------------------------
# Why the grid arm above does not read zero: the union bin count is derived as
# int(bpd * log10(max/min)). On grid-aligned extents that product is an exact
# integer in exact arithmetic, but in floating point it lands a hair under and
# int() truncates it to one less -- which shifts every edge and reintroduces
# the displacement the grid was there to remove. This second pass repeats the
# candidate with the bin count ROUNDED instead of truncated, to separate the
# idea from that arithmetic detail.
print "\nGrid-anchored seed, union bin count rounded instead of truncated:\n";
printf("%-8s  %-34s\n", "members", "median / max (bin widths)");

sub collapse_rounded {
    my ($sides, $bpd) = @_;
    my ($umin, $umax) = ($sides->[0]{partition}{min}, $sides->[0]{partition}{max});
    for my $s (@$sides) {
        $umin = $s->{partition}{min} if $s->{partition}{min} < $umin;
        $umax = $s->{partition}{max} if $s->{partition}{max} > $umax;
    }
    my $bc = int($bpd * (log($umax / $umin) / log(10)) + 0.5);
    $bc = 1 if $bc < 1;
    my @bins;
    for my $s (@$sides) {
        my $p = $s->{partition};
        my $aligned = ($p->{min} == $umin && $p->{max} == $umax && $p->{bin_count} == $bc)
            ? $s->{bins}
            : (partition_rebin($p, $s->{bins}, $umin, $umax, $bc))[1];
        for my $i (0 .. $bc - 1) { $bins[$i] = ($bins[$i] // 0) + ($aligned->[$i] // 0); }
    }
    my ($p) = partition_rebin($sides->[0]{partition}, [], $umin, $umax, $bc);
    return { partition => $p, bins => \@bins, overflow => 0, underflow => 0 };
}

$GRID = 1;
for my $count (2, 5, 15, 40) {
    $seed = 20260827;
    my (@members, @pooled);
    for my $m (1 .. $count) {
        my $centre = 10 ** (nextval() * 4 - 1);
        my $entry;
        for (1 .. 200) {
            my $v = $centre * (10 ** (nextval() * 1.5 - 0.75));
            push @pooled, $v;
            $entry //= counter_entry_new($v, $bpd); counter_entry_observe($entry, $v);
        }
        push @members, $entry;
    }
    my $ref;
    for my $v (@pooled) { $ref //= counter_entry_new($v, $bpd); counter_entry_observe($ref, $v); }
    my $got = collapse_rounded(\@members, $bpd);
    my $bw = (10 ** (1 / $bpd) - 1) * 100;
    my @dev;
    for my $q (@quantiles) {
        my $rv = (percentile($ref, $q))[0];
        next unless $rv && $rv > 0;
        push @dev, abs((percentile($got, $q))[0] - $rv) / $rv * 100 / $bw;
    }
    my @s = sort { $a <=> $b } @dev;
    printf("%-8d  %8.4f / %8.4f\n", $count, $s[int(@s * 0.50)], $s[-1]);
}
