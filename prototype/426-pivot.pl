#!/usr/bin/env perl
#
# 426-pivot.pl — pivot 426-run-matrix.sh results.tsv into per-fixture
# markdown tables (one row per metric, one column per arm; median with
# min–max range; ratio vs arm A where the metric is a time).
#
# Usage: perl prototype/426-pivot.pl <results.tsv> [metric-regex]

use strict;
use warnings;

my ($file, $filter) = @ARGV;
die "usage: $0 <results.tsv> [metric-regex]\n" unless $file;
open my $fh, '<', $file or die "open $file: $!";
my $hdr = <$fh>;
my (%v, %arms, @fix_order, %seen_fix, @met_order, %seen_met);
while (<$fh>) {
    chomp;
    my ($cand, $fixture, $lines, $metric, $med, $min, $max) = split /\t/;
    next if defined $filter && $metric !~ /$filter/;
    $v{$fixture}{$metric}{$cand} = [$med, $min, $max, $lines];
    $arms{$cand} = 1;
    push @fix_order, $fixture unless $seen_fix{$fixture}++;
    push @met_order, $metric unless $seen_met{$metric}++;
}
my @arms = sort keys %arms;

sub fmt {
    my ($metric, $r) = @_;
    return '—' unless $r;
    my ($med, $min, $max) = @$r;
    if ($metric =~ /_s$/)          { return sprintf('%.4f (%.4f–%.4f)', $med, $min, $max) }
    if ($metric =~ /ns_per_line/)  { return sprintf('%.0f (%.0f–%.0f)', $med, $min, $max) }
    if ($metric =~ /bytes|_kb$/)   { return sprintf('%s', commify(int($med))) }
    return sprintf('%s', commify(int($med)));
}
sub commify { my $n = reverse shift; $n =~ s/(\d{3})(?=\d)/$1,/g; return scalar reverse $n }

for my $fixture (@fix_order) {
    my ($lines) = map { $_->[3] } grep { $_ } map { $v{$fixture}{$_}{$arms[0]} } @met_order;
    print "### $fixture (", commify($lines // 0), " lines)\n\n";
    print "| metric | ", join(" | ", @arms), " | ratio vs A |\n";
    print "|---|", "---|" x @arms, "---|\n";
    for my $metric (@met_order) {
        my $row = $v{$fixture}{$metric} or next;
        my @cells = map { fmt($metric, $row->{$_}) } @arms;
        my $ratio = '';
        if ($metric =~ /_s$|ns_per_line|bytes|_kb$/ && $row->{'arm-A'} && $row->{'arm-A'}[0] > 0) {
            $ratio = join(' / ', map { $row->{$_} ? sprintf('%.2f', $row->{$_}[0] / $row->{'arm-A'}[0]) : '—' } grep { $_ ne 'arm-A' } @arms);
        }
        print "| $metric | ", join(" | ", @cells), " | $ratio |\n";
    }
    print "\n";
}
