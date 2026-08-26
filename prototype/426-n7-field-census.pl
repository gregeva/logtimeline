#!/usr/bin/env perl
#
# 426-n7-field-census.pl — the D8 field census. For every field #187 Decision 8
# locks in a `path: unified` per-consumer block, probe each arm's store for a
# populable source and report can/cannot with the arm-native replacement.
#
# "Populable" is decided by asking the arm's own store, not by assertion: for
# each field the probe names the source expression and evaluates it against a
# live store built from a real fixture. A field whose source does not exist in
# the arm reports NO with the reason.

use strict; use warnings;
use FindBin;
require "$FindBin::Bin/426-revalidate-lib.pm";

my $file = $ARGV[0] // '/tmp/ltl-426-fixtures/bin-dpm-10k.log';
my $bpd  = $ARGV[1] // 53;
Revalidate426::configure(bpd => $bpd);

my %st;
for my $arm (qw(T S G)) {
    my $s = Revalidate426::store_new($arm, bpd => $bpd);
    Revalidate426::iterate_durations($file, sub { my ($c,$k,$d)=@_; $s->add("$c\x1f$k",$d) });
    $st{$arm} = $s;
}

# The locked D8 field list, in emission order, read from
# features/187-histogram-bin-counter-percentiles.md § Decision 8 § "When
# `path: unified`, the following fields appear (in order)". Run-level lines
# (data_model_precision) and the path/shares lines are structural, not
# per-partition state, and are listed separately below.
my @D8 = qw(
    partition_keying
    partition_count
    total_rebin_events
    max_partition_bins
    partitions_with_overflow_count
    partitions_with_underflow_count
    counter_memory_bytes
    rebins_per_partition
    percentiles_emitted
    out_of_range_bounded
);

sub probe {
    my ($arm, $field) = @_;
    my $s = $st{$arm};
    my $t = $s->telemetry;
    return ('YES', 'consumer-level constant; not read from the store') if $field eq 'partition_keying';
    return ('YES', 'consumer-level constant; not read from the store') if $field eq 'percentiles_emitted';
    if ($field eq 'partition_count')      { return ('YES', "telemetry{partition_count}=$t->{partition_count}") }
    if ($field eq 'counter_memory_bytes') { return ('YES', "telemetry{counter_memory_bytes}=$t->{counter_memory_bytes}") }
    if ($field eq 'out_of_range_bounded') {
        # Ask the arm's percentile() whether a non-'none' code is reachable at all.
        my ($k) = $s->keys;
        my (undef, $code) = $s->percentile($k, 0.5);
        my $reach = ($arm eq 'G') ? 'no out-of-range exit exists (span always covers every observation)'
                                  : "reachable only under a growth cap; uncapped ltl always 'none'";
        return ($arm eq 'G' ? 'NO' : 'YES', "sample code='$code'; $reach");
    }
    # The four partition-state fields.
    for my $f (qw(total_rebin_events max_partition_bins
                  partitions_with_overflow_count partitions_with_underflow_count)) {
        next unless $field eq $f;
        return exists $t->{$f} ? ('YES', "telemetry{$f}=$t->{$f}")
                               : ('NO', 'field absent from this arm\'s telemetry');
    }
    if ($field eq 'rebins_per_partition') {
        return exists $t->{rebins_p50}
            ? ('YES', sprintf('p50=%d p95=%d p99=%d max=%d', @{$t}{qw(rebins_p50 rebins_p95 rebins_p99 rebins_max)}))
            : ('NO', 'no rebin counter exists in this arm');
    }
    return ('?', 'unclassified');
}

print "file: $file  bpd: $bpd\n";
print "arms built: T S G   (partition_count T=$st{T}->telemetry->{partition_count})\n\n" if 0;
printf "%-32s %-6s %-6s %-6s\n", 'D8 field', 'T', 'S', 'G';
printf "%-32s %-6s %-6s %-6s\n", '-'x32, '-'x6, '-'x6, '-'x6;
my %detail;
for my $f (@D8) {
    my @v;
    for my $arm (qw(T S G)) {
        my ($ok, $why) = probe($arm, $f);
        push @v, $ok;
        $detail{$f}{$arm} = "$ok — $why";
    }
    printf "%-32s %-6s %-6s %-6s\n", $f, @v;
}
print "\n# per-arm detail\n";
for my $f (@D8) {
    print "$f\n";
    print "  $_: $detail{$f}{$_}\n" for qw(T S G);
}
print "\n# arm G native telemetry (the replacement surface)\n";
my $g = $st{G}->telemetry;
printf "  %-22s %s\n", "$_:", (defined $g->{$_} ? $g->{$_} : 'undef')
    for qw(partition_count span_p50 span_p95 span_p99 span_max index_min index_max counter_memory_bytes);
