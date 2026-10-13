#!/usr/bin/env perl
# #621: tally the run-constant tests per included line from a loop-line-counts
# dump and sites.tsv. Every site snippet must match at least one loop line;
# the lines each matched are printed so the classification can be checked.
#
#   usage: tally.pl <sites.tsv> <loop-lines.tsv> <included lines>
use strict;
use warnings;
my ($sites, $lines, $included) = @ARGV;
die "usage: tally.pl <sites.tsv> <loop-lines.tsv> <included lines>\n" unless $included;
open my $lf, '<', $lines or die "$lines: $!";
my @rows = map { chomp; [ split /\t/, $_, 4 ] } <$lf>;
open my $sf, '<', $sites or die "$sites: $!";
my (%by_class, %by_form, @detail);
while (<$sf>) {
    next if /^#/ || /^\s*$/;
    chomp;
    my ($class, $form, $tests, $snip) = split /\t/, $_, 4;
    my @hit = grep { index($_->[3], $snip) >= 0 } @rows;
    die "site matches no loop line: $snip\n" unless @hit;
    for my $h (@hit) {
        my $per_line = $h->[1] * $tests / $included;
        $by_class{$class} += $per_line;
        $by_form{"$class/$form"} += $per_line;
        push @detail, sprintf "%s\t%s\t%d\t%.3f\t%s", $class, $form, $h->[0], $per_line, $snip if $h->[1];
    }
}
print "$_\n" for @detail;
print "--\n";
printf "class %s\t%.2f tests per included line\n", $_, $by_class{$_} for sort keys %by_class;
printf "form %s\t%.2f\n", $_, $by_form{$_} for sort keys %by_form;
