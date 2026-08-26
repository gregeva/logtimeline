#!/usr/bin/perl
#
# 426-revalidate-v8-rebless.pl — N4: what a shared grid would do to the
# committed statistics-drift baselines.
#
# tests/validate-statistics.sh compares ltl's CSV output against committed
# baselines under tests/statistics-drift/baselines/<scenario>/{messages,stats}.csv
# at FULL precision (-cp full), and compare-statistics-drift.pl classifies any
# per-cell deviation above 1% as T3 — which BLOCKS the release. Five of the
# eighteen scenarios run the bin data model:
#
#   apache-bin-data-model  tomcat-bin-data-model  thingworx-bin-data-model
#   codebeamer-bin-data-model  tomcat-heatmap-bin
#
# Those five are the re-bless surface for any change to the bin-counter
# representation. This prototype enumerates the shift WITHOUT modifying ltl:
# for each scenario's logfile it reproduces the per-key percentile computation
# under arms T (today) and G (shared grid) at the message-stats bpd the
# scenario resolves to, and reports the per-quantile deviation distribution
# against T — i.e. exactly the quantity compare-statistics-drift.pl would
# classify.
#
# It reports, per scenario and per quantile:
#   - the fraction of (key, quantile) cells that would classify T1 (identical),
#     T2 (<= 1%, advisory) and T3 (> 1%, BLOCKING)
#   - the worst deviation and which key carries it
#
# The oracle is included as a third column so the reader can see whether a
# cell that moves is moving TOWARD or AWAY from the exact answer — a shift
# that lands closer to the true value is a different disposition from one
# that lands further away, and the T1/T2/T3 classification alone cannot
# distinguish them.
#
# Usage: perl prototype/426-revalidate-v8-rebless.pl [--bpd 53] [--out <dir>]
#                                                    [--max-keys N]
use strict;
use warnings;
use POSIX ();
use FindBin;
require "$FindBin::Bin/426-revalidate-lib.pm";

my %opt = (bpd => 53, out => undef, 'max-keys' => undef);
while (@ARGV) {
    my $a = shift @ARGV;
    if ($a =~ /^--(\w[\w-]*)$/ && exists $opt{$1}) { $opt{$1} = shift @ARGV }
    elsif ($a =~ /^--(\w[\w-]*)=(.*)$/ && exists $opt{$1}) { $opt{$1} = $2 }
    else { die "unknown argument: $a\n" }
}
my $BPD = $opt{bpd} + 0;
Revalidate426::configure(bpd => $BPD);

# The five bin-model scenarios from tests/statistics-drift/scenarios.tsv, with
# the logfile each one reads. Read from the TSV itself so this cannot drift
# from the harness.
my $TSV = "$FindBin::Bin/../tests/statistics-drift/scenarios.tsv";
open(my $tf, '<', $TSV) or die "cannot read $TSV: $!\n";
my @scenarios;
while (my $l = <$tf>) {
    next if $l =~ /^\s*#/ || $l !~ /\S/;
    chomp $l;
    my ($name, $logfile, $options) = split /\t/, $l;
    next unless defined $options && $options =~ /-mdm\s+bin/;
    push @scenarios, { name => $name, logfile => $logfile, options => $options };
}
close $tf;
die "no bin-model scenarios found in $TSV\n" unless @scenarios;

printf "bin-model scenarios in %s: %d\n", $TSV, scalar @scenarios;
printf "  %s\n", $_->{name} for @scenarios;
printf "message-stats bpd under test: %d\n\n", $BPD;

# ltl's percentile set, as calculate_statistics emits it.
my @QUANTS = (['p1',0.01],['p5',0.05],['p10',0.10],['p25',0.25],['p50',0.50],
              ['p75',0.75],['p90',0.90],['p95',0.95],['p99',0.99],
              ['p999',0.999],['p9999',0.9999]);

# VERBATIM semantics of calculate_statistics_bin's clamp: the interpolated
# value is clamped to the observed [min,max] carried on the sidecar.
sub clamp { my ($v,$min,$max)=@_; return unless defined $v;
            $v = $min if $v < $min; $v = $max if $v > $max; return $v }

# compare-statistics-drift.pl's classification, verbatim in behaviour:
#   T1 identical; T2 <= 1%; T3 > 1% (blocking).
sub classify {
    my ($base, $new) = @_;
    return ('T1', 0.0) if !defined $base && !defined $new;
    return ('T3', 'inf') if !defined $base || !defined $new;
    return ('T1', 0.0) if $base == $new;
    if ($base == 0) { return ('T1', 0.0) if $new == 0; return ('T3', 'inf') }
    my $dev = abs($new - $base) / abs($base) * 100;
    return ('T1', $dev) if $dev == 0.0;
    return ('T2', $dev) if $dev <= 1.0;
    return ('T3', $dev);
}

my @report_rows;
for my $sc (@scenarios) {
    my $file = "$FindBin::Bin/../$sc->{logfile}";
    unless (-r $file) { printf "SKIP %-28s (unreadable: %s)\n", $sc->{name}, $sc->{logfile}; next }

    # Per-key raw values, keyed as ltl keys the message store.
    my %vals;
    my $counts = Revalidate426::iterate_durations($file, sub {
        my ($cat, $key, $dur) = @_;
        push @{ $vals{"$cat\x1f$key"} }, $dur;
    });
    my $nkeys = scalar keys %vals;
    unless ($nkeys) {
        # Not a finding about ltl: this prototype's parsers are the two verbatim
        # ones the revalidation library carries (#189's access-log parser and
        # 426-grid-fidelity's ThingWorx parser). The codebeamer access log records
        # its duration as a bracketed "[293ms] [0.293s]" pair, which neither parser
        # reads. ltl itself parses the file through its own format registry entry.
        # The scenario is therefore NOT COVERED by this enumeration, and is
        # reported as such rather than silently omitted.
        printf "NOT COVERED %-22s (this prototype's verbatim parsers do not read this\n", $sc->{name};
        printf "                              format's bracketed duration; ltl reads it via the\n";
        printf "                              format registry. Not an ltl finding.)\n";
        next;
    }

    my @keys = sort keys %vals;
    if (defined $opt{'max-keys'} && @keys > $opt{'max-keys'}) {
        @keys = @keys[0 .. $opt{'max-keys'} - 1];
    }

    # Build both arms over the same keys.
    my $T = Revalidate426::store_new('T', bpd => $BPD);
    my $G = Revalidate426::store_new('G', bpd => $BPD);
    for my $k (@keys) { for my $v (@{ $vals{$k} }) { $T->add($k,$v); $G->add($k,$v) } }

    my %tier_count; my %per_q;
    my ($worst_dev, $worst_key, $worst_q) = (0, undef, undef);
    my ($closer, $further, $tie) = (0,0,0);
    my $cells = 0;

    for my $k (@keys) {
        my @raw = @{ $vals{$k} };
        my ($omin, $omax) = ($raw[0], $raw[0]);
        for (@raw) { $omin = $_ if $_ < $omin; $omax = $_ if $_ > $omax }
        my @oracle = Revalidate426::oracle_percentiles(\@raw, [ map { $_->[1] } @QUANTS ]);

        for my $qi (0 .. $#QUANTS) {
            my ($qname, $q) = @{ $QUANTS[$qi] };
            my ($tv) = $T->percentile($k, $q, 'int');
            my ($gv) = $G->percentile($k, $q, 'int');
            $tv = clamp($tv, $omin, $omax);
            $gv = clamp($gv, $omin, $omax);
            my ($tier, $dev) = classify($tv, $gv);
            $cells++;
            $tier_count{$tier}++;
            $per_q{$qname}{$tier}++;
            if ($dev ne 'inf' && $dev > $worst_dev) {
                ($worst_dev, $worst_key, $worst_q) = ($dev, $k, $qname);
            }
            # Does G land closer to the oracle than T does?
            my $ov = $oracle[$qi];
            if (defined $ov && defined $tv && defined $gv && $ov != 0) {
                my $et = abs($tv - $ov) / abs($ov);
                my $eg = abs($gv - $ov) / abs($ov);
                if    ($eg < $et) { $closer++ }
                elsif ($eg > $et) { $further++ }
                else              { $tie++ }
            }
        }
    }

    printf "=== %s ===\n", $sc->{name};
    printf "  file            %s\n", $sc->{logfile};
    printf "  format          %s   keys %d (compared %d)   observations %d\n",
        $counts->{format} // '?', $nkeys, scalar @keys, $counts->{positive};
    printf "  cells compared  %d  (%d keys x %d quantiles)\n", $cells, scalar @keys, scalar @QUANTS;
    printf "  classification against today's values (compare-statistics-drift.pl tiers):\n";
    for my $t (qw(T1 T2 T3)) {
        printf "    %-3s %8d  %6.2f%%%s\n", $t, ($tier_count{$t}//0),
            100 * ($tier_count{$t}//0) / ($cells || 1),
            ($t eq 'T3' ? '   <-- BLOCKING in validate-statistics.sh' : '');
    }
    printf "  worst deviation %.4f%% at quantile %s\n", $worst_dev, ($worst_q // '-');
    printf "  vs the exact oracle: G closer %d (%.2f%%)  further %d (%.2f%%)  tie %d\n",
        $closer, 100*$closer/($cells||1), $further, 100*$further/($cells||1), $tie;
    printf "  per-quantile T3 rate:\n";
    for my $qq (@QUANTS) {
        my $qn = $qq->[0];
        my $t3 = $per_q{$qn}{T3} // 0;
        my $tot = 0; $tot += ($per_q{$qn}{$_} // 0) for qw(T1 T2 T3);
        printf "    %-7s %6.2f%%  (%d of %d)\n", $qn, 100*$t3/($tot||1), $t3, $tot;
    }
    print "\n";

    push @report_rows, {
        scenario => $sc->{name}, logfile => $sc->{logfile}, bpd => $BPD,
        keys => scalar @keys, cells => $cells,
        T1 => $tier_count{T1}//0, T2 => $tier_count{T2}//0, T3 => $tier_count{T3}//0,
        worst_dev => $worst_dev, worst_q => $worst_q // '',
        closer => $closer, further => $further, tie => $tie,
    };
}

if (defined $opt{out}) {
    mkdir $opt{out} unless -d $opt{out};
    my $tsv = "$opt{out}/rebless-bpd$BPD.tsv";
    open(my $fh, '>', $tsv) or die "cannot write $tsv: $!\n";
    my @cols = qw(scenario logfile bpd keys cells T1 T2 T3 worst_dev worst_q closer further tie);
    print $fh join("\t", @cols), "\n";
    for my $r (@report_rows) { print $fh join("\t", map { defined $r->{$_} ? $r->{$_} : '' } @cols), "\n" }
    close $fh;
    print "TSV: $tsv\n";
}
