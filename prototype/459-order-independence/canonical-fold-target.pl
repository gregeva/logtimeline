#!/usr/bin/env perl
# Issue #459 design probe: a combined-row histogram on a canonical grid with a
# fixed bucket budget, coarsened by exact folding as its range grows.
#
# Bucket j covers [10^(j/B), 10^((j+1)/B)). Because the grid is defined by B
# alone and not by any observed value:
#   - widening the range only addresses more grid indices, so growth costs
#     nothing and moves nothing;
#   - halving B maps grid index j to floor(j/2), so every pair of buckets
#     becomes one and no count leaves the range it was already in.
# Both operations are exact, so the only lossy step left is the single
# projection of each member's own (non-canonical) buckets onto the grid.
#
# The question: does that make the combined answer independent of the order
# members arrive in, and of where the batch boundaries fall, while holding
# memory to the budget?
use strict;
use warnings;
use POSIX ();

use constant { COUNTER_BYTES_PER_PARTITION => 48, COUNTER_BYTES_PER_BIN_SLOT => 8 };
our $percentile_seed_decades = 5;
do '/tmp/459-subs.pl'; die "load: $@" if $@;

my $seed = 20260827;
sub nextval { $seed = ($seed * 1103515245 + 12345) % 2147483648; return $seed / 2147483648; }

sub target_new { my ($B) = @_; return { B => $B, counts => {} } }

sub target_fold {
    my ($t) = @_;
    my %new;
    while (my ($j, $c) = each %{ $t->{counts} }) {
        my $nj = POSIX::floor($j / 2);
        $new{$nj} += $c;
    }
    $t->{B} /= 2;
    $t->{counts} = \%new;
}

sub target_fit {
    my ($t, $budget) = @_;
    while (1) {
        my @j = keys %{ $t->{counts} };
        last unless @j;
        my ($lo, $hi) = ($j[0], $j[0]);
        for (@j) { $lo = $_ if $_ < $lo; $hi = $_ if $_ > $hi }
        last if ($hi - $lo + 1) <= $budget || $t->{B} <= 1;
        target_fold($t);
    }
}

sub target_absorb {
    my ($t, $entry, $budget) = @_;
    my $p = $entry->{partition};
    for my $i (0 .. $p->{bin_count} - 1) {
        my $c = $entry->{bins}[$i];
        next unless $c;
        my $mid = sqrt(bin_boundary($p, $i) * bin_boundary($p, $i + 1));
        $t->{counts}{ POSIX::floor(log($mid) / log(10) * $t->{B}) } += $c;
    }
    target_fit($t, $budget);
}

sub target_entry {
    # Present the target as a #189-shape entry so percentile() reads it.
    my ($t) = @_;
    my @j = sort { $a <=> $b } keys %{ $t->{counts} };
    my ($lo, $hi) = ($j[0], $j[-1]);
    my $min = 10 ** ($lo / $t->{B});
    my $max = 10 ** (($hi + 1) / $t->{B});
    my $bc  = $hi - $lo + 1;
    my @bins = map { $t->{counts}{ $lo + $_ } // 0 } 0 .. $bc - 1;
    return { partition => { min => $min, max => $max, bpd => $t->{B},
                            decades => log($max / $min) / log(10),
                            bin_count => $bc, log_ratio => log($max / $min) },
             bins => \@bins, overflow => 0, underflow => 0 };
}

my @quantiles = (0.01, 0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 0.99);
my $member_bpd = 53;
my $bw = 10 ** (1 / $member_bpd) - 1;

printf("members at %d buckets/decade; combined target starts at 616 with a fixed bucket budget\n\n", $member_bpd);
printf("%-9s %-8s %-9s %-8s %-13s %-26s %s\n",
       "members", "budget", "orders", "batch", "final b/dec", "order/batch mismatches", "worst error vs raw (member buckets)");

for my $count (16, 64, 256) {
  for my $budget (512, 2048) {
    $seed = 20260827;
    my (@members, @raw);
    for my $m (1 .. $count) {
        my $centre = 10 ** (nextval() * 4 - 1);
        my $entry;
        for (1 .. 60) {
            my $v = $centre * (10 ** (nextval() * 1.5 - 0.75));
            push @raw, $v;
            $entry ? counter_entry_observe($entry, $v) : ($entry = counter_entry_new($v, $member_bpd));
        }
        push @members, $entry;
    }
    my @sorted = sort { $a <=> $b } @raw;

    my ($ref_sig, $ref_bpd, $mismatch) = (undef, 0, 0);
    my @worst;
    for my $trial (0 .. 11) {
        my @order = 0 .. $#members;
        if ($trial == 1) { @order = reverse @order }
        elsif ($trial > 1) {
            for (my $i = $#order; $i > 0; $i--) {
                my $j = int(nextval() * ($i + 1));
                @order[$i, $j] = @order[$j, $i];
            }
        }
        # Batch size varies per trial too, so batch boundaries move as well.
        my $batch = (8, 32, 1e9)[$trial % 3];
        my $t = target_new(616);
        my @pending;
        for my $idx (@order) {
            push @pending, $members[$idx];
            if (@pending >= $batch) {
                target_absorb($t, $_, $budget) for @pending;
                @pending = ();
            }
        }
        target_absorb($t, $_, $budget) for @pending;

        my $e = target_entry($t);
        my $sig = join(",", $t->{B}, map { "$_=$t->{counts}{$_}" } sort { $a <=> $b } keys %{ $t->{counts} });
        if (!defined $ref_sig) { $ref_sig = $sig; $ref_bpd = $t->{B} }
        elsif ($sig ne $ref_sig) { $mismatch++ }
        my $w = 0;
        for my $q (@quantiles) {
            my $exact = $sorted[ POSIX::ceil($q * scalar @sorted) - 1 ];
            my $d = abs((percentile($e, $q))[0] - $exact) / $exact / $bw;
            $w = $d if $d > $w;
        }
        push @worst, $w;
    }
    my @s = sort { $a <=> $b } @worst;
    printf("%-9d %-8d %-9d %-8s %-13.1f %-26d %.3f\n",
           $count, $budget, 12, "8/32/all", $ref_bpd, $mismatch, $s[-1]);
  }
}
