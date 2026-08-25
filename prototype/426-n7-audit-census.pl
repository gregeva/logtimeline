#!/usr/bin/env perl
#
# 426-n7-audit-census.pl — N7: reproduce ltl's -V histogram-bin-counters
# summary_table aggregation (Decision 8 fields + out_of_range_bounded) for
# arms T and S, and report the arm-native replacement telemetry for arm G.
#
# The aggregation scope is NOT the whole store. ltl aggregates:
#   * the Decision 8 partition-shape fields over EVERY key in the counter
#     store (snapshot_counter_telemetry walks values %$store), and
#   * out_of_range_bounded over only the keys calculate_statistics_bin was
#     CALLED for — the display-slot set (@top_keys, top N by the sort metric)
#     plus, on a calculated-statistic sort, the population-walk keys.
# Both are reproduced here.

use strict;
use warnings;
use FindBin;
require "$FindBin::Bin/426-revalidate-lib.pm";

my ($file, $arm, $top_n, $bpd) = @ARGV;
$file  //= '/tmp/ltl-426-fixtures/bin-dpm-10k.log';
$arm   //= 'T';
$top_n //= 10;
$bpd   //= 53;

Revalidate426::configure(bpd => $bpd);
my $st = Revalidate426::store_new($arm, bpd => $bpd);

# Per-key sidecars ltl keeps on %log_messages: occurrences (the default sort
# metric) and duration_count (the n>0 gate).
my %occurrences;      # "cat\x1fkey" -> occurrences
my %duration_count;

# ltl counts occurrences for EVERY matched line, whether or not it carries a
# duration; the counter store only sees positive durations. iterate_durations
# invokes the callback only for dur>0, so occurrences here is the positive-
# duration occurrence count. That is the scope this probe asserts over: it is
# reported alongside, and the display set is compared against ltl's own.
my $counters = Revalidate426::iterate_durations($file, sub {
    my ($cat, $key, $dur) = @_;
    my $k = "$cat\x1f$key";
    $occurrences{$k}++;
    $duration_count{$k}++;
    $st->add($k, $dur);
});

# --- Decision 8 partition-shape fields: whole store ------------------------
my $t = $st->telemetry;

# --- out_of_range_bounded: display-slot scope ------------------------------
# ltl's default sort is occurrences, descending, with the string key as
# tiebreaker (ltl:12303 @sorted_log_keys), then top N. Categories are walked
# independently (foreach my $category (sort keys %log_messages)); top N is
# per category.
my %by_cat;
for my $k (CORE::keys %occurrences) {
    my ($cat, $key) = split /\x1f/, $k, 2;
    push @{ $by_cat{$cat} }, $k;
}

# The quantile ladder calculate_statistics_bin derives under summary_table
# demand with csv_body=0, extended=0 (no -o, no extended-percentile consumer):
# terminal_core only.  With extended demanded it is the full 12.  Both are
# computed; which one ltl used is read off its `percentiles_emitted:` line.
my @LADDER_CORE     = ([p50=>0.50],[p95=>0.95],[p99=>0.99],[p999=>0.999]);
my @LADDER_CSVBODY  = (@LADDER_CORE, [p1=>0.01],[p90=>0.90],[p75=>0.75]);
my @LADDER_EXTENDED = (@LADDER_CSVBODY, [p5=>0.05],[p10=>0.10],[p25=>0.25],
                       [p9999=>0.9999],[p99999=>0.99999]);

sub audit_over {
    my ($keys, $ladder) = @_;
    my %audit;
    my $calls = 0;
    for my $k (@$keys) {
        next unless ($duration_count{$k} // 0) > 0;
        next unless $st->has($k);
        $calls++;
        my %a;
        for my $pair (@$ladder) {
            my ($name, $q) = @$pair;
            my (undef, $code) = $st->percentile($k, $q);
            $a{$name} = $code;
        }
        # Verbatim ltl:12896-12901 aggregation: high > low > none.
        for my $q (CORE::keys %a) {
            my $new = $a{$q};
            my $cur = $audit{$q};
            if    ($new eq 'high')                              { $audit{$q} = 'high' }
            elsif ($new eq 'low' && (!$cur || $cur eq 'none'))  { $audit{$q} = 'low'  }
            elsif (!defined $cur)                               { $audit{$q} = 'none' }
        }
    }
    return (\%audit, $calls);
}

my @display_keys;
for my $cat (sort CORE::keys %by_cat) {
    my @sorted = sort {
        ($occurrences{$b} <=> $occurrences{$a}) || ($a cmp $b)
    } @{ $by_cat{$cat} };
    my $last = $#sorted < $top_n - 1 ? $#sorted : $top_n - 1;
    push @display_keys, @sorted[0 .. $last];
}

my ($audit_core, $calls_core)   = audit_over(\@display_keys, \@LADDER_CORE);
my ($audit_ext,  $calls_ext)    = audit_over(\@display_keys, \@LADDER_EXTENDED);
# Whole-store scope, for the contrast the audit turns on.
my ($audit_all,  $calls_all)    = audit_over([sort $st->keys], \@LADDER_EXTENDED);

sub fmt_audit {
    my ($a, $ladder) = @_;
    return join(' ', map { "$_->[0]=" . ($a->{$_->[0]} // 'none') } @$ladder);
}

binmode STDOUT, ':encoding(UTF-8)';
print "arm: $arm\n";
print "file: $file\n";
print "bpd: $bpd  top_n: $top_n\n";
print "parse: lines=$counters->{lines} matched=$counters->{matched} positive=$counters->{positive} zero=$counters->{zero} no_duration=$counters->{no_duration} unparsed=$counters->{unparsed} format=$counters->{format}\n";
print "categories: " . scalar(CORE::keys %by_cat) . "\n";
print "display_keys: " . scalar(@display_keys) . "\n";
print "\n";
print "# Decision 8 partition-shape fields (scope: whole counter store)\n";
if ($arm eq 'G') {
    for my $f (qw(partition_count span_p50 span_p95 span_p99 span_max index_min index_max counter_memory_bytes)) {
        printf "  %-32s %s\n", "$f:", (defined $t->{$f} ? $t->{$f} : 'undef');
    }
} else {
    print "  partition_count:                 $t->{partition_count}\n";
    print "  total_rebin_events:              $t->{total_rebin_events}\n";
    print "  max_partition_bins:              $t->{max_partition_bins}\n";
    print "  partitions_with_overflow_count:  $t->{partitions_with_overflow_count}\n";
    print "  partitions_with_underflow_count: $t->{partitions_with_underflow_count}\n";
    print "  counter_memory_bytes:            $t->{counter_memory_bytes}\n";
    printf "  rebins_per_partition: p50=%d p95=%d p99=%d max=%d\n",
        $t->{rebins_p50}, $t->{rebins_p95}, $t->{rebins_p99}, $t->{rebins_max};
}
print "\n";
print "# out_of_range_bounded (scope: display-slot keys walked by the stats pass)\n";
print "  ladder=terminal_core   calls=$calls_core\n";
print "  out_of_range_bounded: " . fmt_audit($audit_core, \@LADDER_CORE) . "\n";
print "  ladder=extended(12)    calls=$calls_ext\n";
print "  out_of_range_bounded: " . fmt_audit($audit_ext, \@LADDER_EXTENDED) . "\n";
print "\n";
print "# out_of_range_bounded (contrast scope: EVERY key in the store)\n";
print "  ladder=extended(12)    calls=$calls_all\n";
print "  out_of_range_bounded: " . fmt_audit($audit_all, \@LADDER_EXTENDED) . "\n";
print "\n";
print "digest: " . $st->digest . "\n";
