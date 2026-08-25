#!/usr/bin/env perl
#
# 426-n7-audit-cap.pl — exercise the out_of_range_bounded aggregation on a
# store that actually HAS overflow/underflow. Real ltl can never produce one
# (counter_update always extends; the comment at ltl:'only reachable when a
# future growth cap is added — none today'), so the aggregation logic is
# unexercised by any ltl run. The lib's max_rebins hook (#189 V3/V4) forces
# the state, and the same verbatim aggregation runs on arms T and S.

use strict; use warnings;
use FindBin;
require "$FindBin::Bin/426-revalidate-lib.pm";

my ($file, $cap, $top_n, $bpd) = @ARGV;
$file  //= '/tmp/ltl-426-fixtures/bin-dpm-10k.log';
$cap   //= 0;
$top_n //= 10;
$bpd   //= 53;

my @LADDER = ([p1=>0.01],[p5=>0.05],[p10=>0.10],[p25=>0.25],[p50=>0.50],
              [p75=>0.75],[p90=>0.90],[p95=>0.95],[p99=>0.99],[p999=>0.999],
              [p9999=>0.9999],[p99999=>0.99999]);

sub run_arm {
    my ($arm) = @_;
    Revalidate426::configure(bpd => $bpd, max_rebins => $cap);
    my $st = Revalidate426::store_new($arm, bpd => $bpd);
    my %occ;
    Revalidate426::iterate_durations($file, sub {
        my ($c,$k,$d)=@_; my $key="$c\x1f$k"; $occ{$key}++; $st->add($key,$d);
    });
    my %by_cat;
    for my $k (CORE::keys %occ) { my ($c)=split /\x1f/,$k,2; push @{$by_cat{$c}},$k }
    my @display;
    for my $c (sort CORE::keys %by_cat) {
        my @s = sort { ($occ{$b} <=> $occ{$a}) || ($a cmp $b) } @{$by_cat{$c}};
        my $last = $#s < $top_n-1 ? $#s : $top_n-1;
        push @display, @s[0..$last];
    }
    my %audit; my $calls=0;
    for my $k (@display) {
        next unless $st->has($k);
        $calls++;
        my %a;
        for my $p (@LADDER) { my (undef,$code)=$st->percentile($k,$p->[1]); $a{$p->[0]}=$code }
        for my $q (CORE::keys %a) {
            my $new=$a{$q}; my $cur=$audit{$q};
            if    ($new eq 'high')                            { $audit{$q}='high' }
            elsif ($new eq 'low' && (!$cur || $cur eq 'none')) { $audit{$q}='low'  }
            elsif (!defined $cur)                             { $audit{$q}='none' }
        }
    }
    my $t = $st->telemetry;
    return { st=>$st, t=>$t, audit=>\%audit, calls=>$calls, display=>scalar(@display) };
}

print "file: $file  max_rebins cap: $cap  top_n: $top_n  bpd: $bpd\n\n";
my %r;
for my $arm (qw(T S)) {
    my $r = run_arm($arm); $r{$arm}=$r;
    my $t=$r->{t};
    print "arm $arm\n";
    print "  partition_count:                 $t->{partition_count}\n";
    print "  total_rebin_events:              $t->{total_rebin_events}\n";
    print "  max_partition_bins:              $t->{max_partition_bins}\n";
    print "  partitions_with_overflow_count:  $t->{partitions_with_overflow_count}\n";
    print "  partitions_with_underflow_count: $t->{partitions_with_underflow_count}\n";
    print "  overflow_total:                  $t->{overflow_total}\n";
    print "  underflow_total:                 $t->{underflow_total}\n";
    printf "  rebins_per_partition: p50=%d p95=%d p99=%d max=%d\n",
        $t->{rebins_p50},$t->{rebins_p95},$t->{rebins_p99},$t->{rebins_max};
    print "  audit scope: $r->{calls} of $r->{display} display keys\n";
    print "  out_of_range_bounded: " . join(' ', map { "$_->[0]=".($r->{audit}{$_->[0]}//'none') } @LADDER) . "\n";
    print "  digest: " . $r->{st}->digest . "\n\n";
}
my $same_digest = $r{T}{st}->digest eq $r{S}{st}->digest ? 'IDENTICAL' : 'DIFFER';
my $same_audit  = join(',', map { $r{T}{audit}{$_->[0]}//'none' } @LADDER)
               eq join(',', map { $r{S}{audit}{$_->[0]}//'none' } @LADDER) ? 'IDENTICAL' : 'DIFFER';
print "T vs S store digest: $same_digest\n";
print "T vs S out_of_range_bounded: $same_audit\n";
