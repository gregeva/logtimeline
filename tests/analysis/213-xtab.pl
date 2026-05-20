#!/usr/bin/env perl
use strict;
use warnings;

# Cross-tabulate XL consolidate scenarios from baseline TSVs.
# Usage: xtab.pl <v0.14.4.tsv> <v0.14.5.tsv>

my ($f4, $f5) = @ARGV;

my @scenarios = qw(
    month-single-server-access-logs-top25-consolidate
    month-single-server-access-logs-heatmap-histogram-consolidate
    month-many-servers-access-logs-top25-consolidate
    month-many-servers-access-logs-heatmap-histogram-consolidate
);
my %sset = map { $_ => 1 } @scenarios;

sub load {
    my $f = shift;
    my %d;
    open my $fh, '<', $f or die $!;
    while (<$fh>) {
        chomp;
        my @c = split /\t/, $_, -1;
        next unless @c >= 4;
        my ($test, $opts, $type) = @c[0,1,2];
        next unless $sset{$test};
        if    ($type eq 'TIMING')       { $d{$test}{timing}{$c[3]}     = $c[4]; }
        elsif ($type eq 'MEMORY')       { $d{$test}{memory}{$c[3]}     = $c[4]; }
        elsif ($type eq 'MEMORY_FINAL') { $d{$test}{memory_final}{$c[3]} = $c[4]; }
        elsif ($type eq 'COUNTS')       { $d{$test}{counts}{$c[3]}     = $c[4]; }
        elsif ($type eq 'lines_read')   { $d{$test}{lines_read}        = $c[3]; }
    }
    close $fh;
    return \%d;
}

my $d4 = load($f4);
my $d5 = load($f5);

sub fmt {
    my $v = shift;
    return '-' unless defined $v;
    return $v;
}

sub is_num { defined $_[0] && $_[0] =~ /^[-+]?\d+\.?\d*$/ }

sub fmt_pct {
    my ($a, $b) = @_;
    return '-' unless is_num($a) && is_num($b);
    return '-' if $a + 0 == 0;
    my $p = ($b - $a) / $a * 100;
    return sprintf('%+.1f%%', $p);
}

sub fmt_x {
    my ($a, $b) = @_;
    return '-' unless is_num($a) && is_num($b);
    return '-' if $a + 0 == 0;
    return sprintf('%.2fx', $b / $a);
}

sub fmt_mb {
    my $v = shift;
    return '-' unless defined $v;
    return sprintf('%.1f', $v / 1_048_576);
}

for my $s (@scenarios) {
    print "\n## $s\n";
    print "lines_read: v0.14.4=", fmt($d4->{$s}{lines_read}), "  v0.14.5=", fmt($d5->{$s}{lines_read}), "\n";

    # TIMING
    print "\n### TIMING (seconds)\n";
    printf "%-25s %10s %10s %10s %10s\n", 'phase', 'v0.14.4', 'v0.14.5', 'delta', 'ratio';
    for my $k (qw(read_files initialize_buckets group_similar calculate_statistics heatmap_statistics histogram_statistics normalize_data total)) {
        my $a = $d4->{$s}{timing}{$k};
        my $b = $d5->{$s}{timing}{$k};
        printf "%-25s %10s %10s %10s %10s\n", $k, fmt($a), fmt($b), fmt_pct($a, $b), fmt_x($a, $b);
    }

    # MEMORY (live peak)
    print "\n### MEMORY (MiB, rss_peak + structures)\n";
    printf "%-40s %12s %12s %10s %10s\n", 'structure', 'v0.14.4 MiB', 'v0.14.5 MiB', 'delta', 'ratio';
    my %all_mem_keys = map { $_ => 1 } (keys %{$d4->{$s}{memory} || {}}, keys %{$d5->{$s}{memory} || {}});
    # Sort: rss_peak first, then consolidation_*, then alpha
    my @keys = sort {
        ($a eq 'rss_peak') <=> ($b eq 'rss_peak')      and return ($a eq 'rss_peak') <=> ($b eq 'rss_peak');
        ($a =~ /^consolidation_/) <=> ($b =~ /^consolidation_/) and return ($b =~ /^consolidation_/) <=> ($a =~ /^consolidation_/);
        $a cmp $b
    } keys %all_mem_keys;
    # Simpler: rss_peak top, then consolidation_*, then others
    my @ordered;
    push @ordered, 'rss_peak' if $all_mem_keys{rss_peak};
    push @ordered, sort grep { /^consolidation_/ } keys %all_mem_keys;
    push @ordered, sort grep { !/^consolidation_/ && $_ ne 'rss_peak' } keys %all_mem_keys;
    for my $k (@ordered) {
        my $a = $d4->{$s}{memory}{$k};
        my $b = $d5->{$s}{memory}{$k};
        printf "%-40s %12s %12s %10s %10s\n", $k, fmt_mb($a), fmt_mb($b), fmt_pct($a, $b), fmt_x($a, $b);
    }

    # COUNTS
    print "\n### COUNTS (workload sanity check)\n";
    printf "%-35s %15s %15s %10s\n", 'count', 'v0.14.4', 'v0.14.5', 'delta';
    my %cnt = map { $_ => 1 } (keys %{$d4->{$s}{counts} || {}}, keys %{$d5->{$s}{counts} || {}});
    for my $k (sort keys %cnt) {
        my $a = $d4->{$s}{counts}{$k};
        my $b = $d5->{$s}{counts}{$k};
        printf "%-35s %15s %15s %10s\n", $k, fmt($a), fmt($b), fmt_pct($a, $b);
    }
    print "\n", '-' x 80, "\n";
}
