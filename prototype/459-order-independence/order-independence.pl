#!/usr/bin/env perl
# Issue #459 order-independence probe.
#
# The production subs are extracted verbatim from `ltl` by extract-subs.sh --
# never re-typed here -- so this measures the shipped combination path and not
# a convenience re-implementation of it (features/58 F9).
#
# What it asserts: given the same set of member histograms, combining them in
# any order produces byte-identical stored counts and identical percentiles.
use strict;
use warnings;
use POSIX ();

use constant {
    COUNTER_BYTES_PER_PARTITION => 48,
    COUNTER_BYTES_PER_BIN_SLOT  => 8,
};
our $percentile_seed_decades = 5;   # the shipped seed span (ltl $percentile_seed_decades)
our $message_stats_member_bytes = 0;

do '/tmp/459-subs.pl';
die "cannot load extracted subs: $@" if $@;
die "extracted subs missing" unless defined &merge_bin_counter_entries;

# Deterministic pseudo-random sample generator -- no Math::Random dependency
# and no reliance on rand()'s seeding across perl builds.
my $seed = 20260827;
sub nextval {
    $seed = ($seed * 1103515245 + 12345) % 2147483648;
    return $seed / 2147483648;
}

sub build_members {
    my ($count, $samples_each, $bpd) = @_;
    my @members;
    for my $m (1 .. $count) {
        # Each member observes a different decade band, so no two members are
        # congruent -- the shape that made the old combination lossy.
        my $centre = 10 ** (nextval() * 4 - 1);
        my $entry;
        for (1 .. $samples_each) {
            my $v = $centre * (10 ** (nextval() * 1.5 - 0.75));
            $entry //= counter_entry_new($v, $bpd);
                    counter_entry_observe($entry, $v);
        }
        push @members, $entry;
    }
    return \@members;
}

sub clone_entry {
    my ($e) = @_;
    return {
        partition => { %{ $e->{partition} } },
        bins      => [ @{ $e->{bins} } ],
        overflow  => $e->{overflow},
        underflow => $e->{underflow},
        rebin_growth => $e->{rebin_growth},
        rebin_merge  => $e->{rebin_merge},
        members      => $e->{members},
    };
}

sub combine_in_order {
    my ($members, $order, $bpd) = @_;
    my $target = { partition => undef, bins => [], overflow => 0, underflow => 0 };
    for my $i (@$order) {
        merge_bin_counter_entries($target, clone_entry($members->[$i]));
    }
    my $projections = collapse_bin_counter_entry($target);
    return ($target, $projections);
}

sub signature {
    my ($e) = @_;
    my $p = $e->{partition};
    return sprintf("%.17g|%.17g|%d|%s", $p->{min}, $p->{max}, $p->{bin_count},
                   join(",", map { $_ // 0 } @{ $e->{bins} }));
}

my @quantiles = (0.01, 0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 0.99);

for my $count (2, 5, 15, 40) {
    my $bpd = 53;
    my $members = build_members($count, 200, $bpd);

    my @orders;
    push @orders, [ 0 .. $count - 1 ];                       # arrival
    push @orders, [ reverse 0 .. $count - 1 ];               # reversed
    for my $trial (1 .. 8) {                                 # shuffled
        my @o = (0 .. $count - 1);
        for (my $i = $#o; $i > 0; $i--) {
            my $j = int(nextval() * ($i + 1));
            @o[$i, $j] = @o[$j, $i];
        }
        push @orders, \@o;
    }

    my ($ref, $ref_proj) = combine_in_order($members, $orders[0], $bpd);
    my $ref_sig = signature($ref);
    my @ref_q = map { (percentile($ref, $_))[0] } @quantiles;

    my ($sig_mismatch, $q_mismatch, $proj_mismatch) = (0, 0, 0);
    for my $order (@orders[1 .. $#orders]) {
        my ($got, $proj) = combine_in_order($members, $order, $bpd);
        $sig_mismatch++  if signature($got) ne $ref_sig;
        $proj_mismatch++ if $proj != $ref_proj;
        my @gq = map { (percentile($got, $_))[0] } @quantiles;
        for my $k (0 .. $#gq) {
            $q_mismatch++ if abs($gq[$k] - $ref_q[$k]) > 0;
        }
    }
    printf("members=%-3d orders=%-3d projections=%-3d stored-count mismatches=%d  percentile mismatches=%d  projection-count mismatches=%d\n",
           $count, scalar @orders, $ref_proj, $sig_mismatch, $q_mismatch, $proj_mismatch);
}
