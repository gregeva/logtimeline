#!/usr/bin/env perl
# Issue #459 accuracy probe: what the deferred combination bought, measured
# against the reference model the statistics oracle uses.
#
# Three arms, all running production code extracted verbatim:
#   REF  one partition over the cluster's pooled samples -- the model
#        tests/statistics-drift/oracle/calculate-reference.py evaluates, and
#        the answer an unconsolidated key of the same samples would give.
#   OLD  the eager per-combination projection, taken from release/0.18.0.
#   NEW  the deferred single collapse (#459 / D1).
#
# Deviation is reported in BIN WIDTHS, because that is the unit the accuracy
# contract is written in (features/187 R4): one bin width at bins-per-decade
# 53 is 4.44%.
use strict;
use warnings;
use POSIX ();

use constant {
    COUNTER_BYTES_PER_PARTITION => 48,
    COUNTER_BYTES_PER_BIN_SLOT  => 8,
};
our $percentile_seed_decades = 4;
our $message_stats_member_bytes = 0;

do '/tmp/459-subs.pl';      die "load: $@" if $@;
do '/tmp/459-old-merge.pl'; die "load old: $@" if $@;
die "missing subs" unless defined &collapse_bin_counter_entry
                       && defined &merge_bin_counter_entries_old;

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
my $bin_width_pct = (10 ** (1 / $bpd) - 1) * 100;

printf("one bin width at bpd %d = %.2f%%\n\n", $bpd, $bin_width_pct);
printf("%-8s  %-28s  %-28s\n", "members", "OLD eager per-combination", "NEW deferred single collapse");
printf("%-8s  %-28s  %-28s\n", "", "median / p95 / max (bin widths)", "median / p95 / max (bin widths)");

for my $count (2, 5, 15, 40) {
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

    # REF: the pooled-sample partition.
    my $ref;
    for my $v (@pooled) {
        $ref //= counter_entry_new($v, $bpd); counter_entry_observe($ref, $v);
    }

    my $old = { partition => undef, bins => [], overflow => 0, underflow => 0 };
    merge_bin_counter_entries_old($old, clone_entry($_)) for @members;

    my $new = { partition => undef, bins => [], overflow => 0, underflow => 0 };
    merge_bin_counter_entries($new, clone_entry($_)) for @members;
    collapse_bin_counter_entry($new);

    my (@dev_old, @dev_new);
    for my $q (@quantiles) {
        my $rv = (percentile($ref, $q))[0];
        next unless $rv && $rv > 0;
        push @dev_old, abs((percentile($old, $q))[0] - $rv) / $rv * 100 / $bin_width_pct;
        push @dev_new, abs((percentile($new, $q))[0] - $rv) / $rv * 100 / $bin_width_pct;
    }
    my @so = sort { $a <=> $b } @dev_old;
    my @sn = sort { $a <=> $b } @dev_new;
    printf("%-8d  %6.3f / %6.3f / %6.3f      %6.3f / %6.3f / %6.3f\n", $count,
           $so[int(@so * 0.50)], $so[int(@so * 0.95)], $so[-1],
           $sn[int(@sn * 0.50)], $sn[int(@sn * 0.95)], $sn[-1]);
}
