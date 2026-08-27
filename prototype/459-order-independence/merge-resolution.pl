#!/usr/bin/env perl
# Issue #459 design probe: does projecting the COMBINED result at a finer
# resolution than its inputs stop the error compounding across repeated
# collapses?
#
# The question this answers: a member's own quantisation cannot be undone --
# its counts already sit at its own bucket midpoints. But the projection that
# places those midpoints onto the combined scale need not add any more error
# of its own. If the combined scale is much finer than the members', each
# midpoint lands almost exactly where it belongs, so a collapse adds close to
# nothing -- and a result that is carried through several collapses stops
# decaying.
#
# Arms, all against a reference partition built by streaming the pooled raw
# samples into one partition at the members' own resolution:
#   A  one collapse at the members' resolution              (what ships today)
#   B  one collapse at a finer resolution
#   C  batched collapses at the members' resolution         (a retention limit)
#   D  batched collapses at a finer resolution
use strict;
use warnings;
use POSIX ();

use constant { COUNTER_BYTES_PER_PARTITION => 48, COUNTER_BYTES_PER_BIN_SLOT => 8 };
our $percentile_seed_decades = 4;
our $message_stats_member_bytes = 0;

do '/tmp/459-subs.pl'; die "load: $@" if $@;

my $seed = 20260827;
sub nextval { $seed = ($seed * 1103515245 + 12345) % 2147483648; return $seed / 2147483648; }

# Collapse a list of entries into one, at a caller-chosen resolution.
# Same arithmetic as collapse_bin_counter_entry, with the union bin count
# derived from $target_bpd instead of inherited from the first side.
sub collapse_at {
    my ($sides, $target_bpd) = @_;
    my ($umin, $umax) = ($sides->[0]{partition}{min}, $sides->[0]{partition}{max});
    for my $s (@$sides) {
        $umin = $s->{partition}{min} if $s->{partition}{min} < $umin;
        $umax = $s->{partition}{max} if $s->{partition}{max} > $umax;
    }
    my $bc = int($target_bpd * (log($umax / $umin) / log(10)));
    $bc = 1 if $bc < 1;
    my @bins;
    my $up;
    for my $s (@$sides) {
        my $p = $s->{partition};
        my ($np, $aligned);
        if ($p->{min} == $umin && $p->{max} == $umax && $p->{bin_count} == $bc) {
            $aligned = $s->{bins}; $np = $p;
        } else {
            ($np, $aligned) = partition_rebin($p, $s->{bins}, $umin, $umax, $bc);
        }
        $up //= $np;
        for my $i (0 .. $bc - 1) { $bins[$i] = ($bins[$i] // 0) + ($aligned->[$i] // 0); }
    }
    $up = { %$up, bpd => $target_bpd };
    return { partition => $up, bins => \@bins, overflow => 0, underflow => 0 };
}

sub batched {
    my ($members, $limit, $bpd) = @_;
    my $carried;
    my @batch;
    for my $m (@$members) {
        push @batch, $m;
        if (@batch >= $limit) {
            $carried = collapse_at([ $carried ? ($carried, @batch) : @batch ], $bpd);
            @batch = ();
        }
    }
    $carried = collapse_at([ $carried ? ($carried, @batch) : @batch ], $bpd) if @batch;
    return $carried;
}

my @quantiles = (0.01, 0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 0.99);
my $member_bpd = 53;
my $fine_bpd   = 616;
my $bw = (10 ** (1 / $member_bpd) - 1) * 100;   # one member bucket, in percent

printf("members at %d buckets/decade (one bucket = %.2f%%), fine scale %d\n", $member_bpd, $bw, $fine_bpd);
printf("deviation from a single partition over the pooled samples, in member bucket widths\n\n");
printf("%-9s %-11s  %-18s %-18s %-18s %-18s\n", "members", "limit", "A one/coarse", "B one/fine", "C batched/coarse", "D batched/fine");

for my $count (16, 64, 256) {
    for my $limit (8, 32) {
        $seed = 20260827;
        my (@members, @pooled);
        for my $m (1 .. $count) {
            my $centre = 10 ** (nextval() * 4 - 1);
            my $entry;
            for (1 .. 60) {
                my $v = $centre * (10 ** (nextval() * 1.5 - 0.75));
                push @pooled, $v;
                $entry //= counter_entry_new($v, $member_bpd); counter_entry_observe($entry, $v);
            }
            push @members, $entry;
        }
        my $ref;
        for my $v (@pooled) { $ref //= counter_entry_new($v, $member_bpd); counter_entry_observe($ref, $v); }

        my %arm = (
            A => collapse_at([@members], $member_bpd),
            B => collapse_at([@members], $fine_bpd),
            C => batched(\@members, $limit, $member_bpd),
            D => batched(\@members, $limit, $fine_bpd),
        );
        my @cell;
        for my $k (qw(A B C D)) {
            my @dev;
            for my $q (@quantiles) {
                my $rv = (percentile($ref, $q))[0];
                next unless $rv && $rv > 0;
                push @dev, abs((percentile($arm{$k}, $q))[0] - $rv) / $rv * 100 / $bw;
            }
            my @s = sort { $a <=> $b } @dev;
            push @cell, sprintf("%.3f / %.3f", $s[int(@s * 0.50)], $s[-1]);
        }
        printf("%-9d %-11d  %-18s %-18s %-18s %-18s\n", $count, $limit, @cell);
    }
}
print "\n(each cell: median / worst)\n";
