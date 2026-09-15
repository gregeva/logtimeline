#!/usr/bin/env perl
# Recall of the implemented candidate search against direct Dice (acceptance criterion 3
# of the #569 design). Slices get_consolidation_trigrams(), dice_coefficient(),
# build_consolidation_ngram_index() and find_consolidation_candidates() out of `ltl`
# verbatim, indexes one first-checkpoint batch the way a checkpoint does, and for each of
# the first <sources> keys compares the search's return with the best raw Dice against
# every other key in the batch.
#   usage: probe-implemented.pl <ltl> <label> <batch file> [sources=500]
# Batch file: one message key per line, as dumped from a group's first streaming checkpoint.
# Output (TSV on stdout): label, T, sources, partners (best Dice >= T), missed (a partner
# exists and the search returned nothing), false (a returned candidate scores below T or
# is not the best score found), ms_per_search.
use strict;
use warnings;
no strict 'vars';
use List::Util qw(min max);
use Time::HiRes qw(time);

my ($ltl, $label, $batch, $n_src) = @ARGV;
die "usage: $0 <ltl> <label> <batch file> [sources]\n" unless defined $batch;
$n_src //= 500;

my $ltl_text = do { local $/; open my $fh, '<', $ltl or die "$ltl: $!"; <$fh> };
# The message cap decides the trigram sets, so it is sliced from ltl too, not restated.
$ltl_text =~ /^(my \$consolidation_message_length_cap\s*=[^\n]*)$/m
    or die "\$consolidation_message_length_cap not found in $ltl\n";
my $cap = $1 =~ s/^my /our /r;
my @subs = map {
    $ltl_text =~ /^(sub \Q$_\E \{.*?^\})/ms or die "sub $_ not found in $ltl\n";
    $1;
} qw(get_consolidation_trigrams dice_coefficient build_consolidation_ngram_index find_consolidation_candidates);
our (%consolidation_key_message, %consolidation_key_trigrams, %consolidation_id_index);
our $consolidation_message_length_cap;
eval join("\n\n", $cap, @subs) . "\n1;" or die $@;
die "sliced cap did not take effect\n" unless $consolidation_message_length_cap;

open my $fh, '<', $batch or die "$batch: $!";
my @keys = grep { length } map { chomp; $_ } <$fh>;
close $fh;
%consolidation_key_message = map { $_ => $_ } @keys;
main::build_consolidation_ngram_index('probe', \@keys);

my %seen;
my @uniq = grep { !$seen{$_}++ } @keys;
my @sources = @uniq[0 .. min($n_src, scalar @uniq) - 1];
my %best;
for my $s (@sources) {
    my $ts = $consolidation_key_trigrams{$s};
    my $b = -1;
    for my $c (@uniq) {
        next if $c eq $s;
        my $d = main::dice_coefficient($ts, $consolidation_key_trigrams{$c});
        $b = $d if $d > $b;
    }
    $best{$s} = $b;
}

print join("\t", qw(label T sources partners missed false ms_per_search)), "\n";
for my $t (50, 60, 70, 75, 80, 85, 90, 95) {
    my ($partners, $missed, $false) = (0, 0, 0);
    my $start = time;
    my %found;
    $found{$_} = [main::find_consolidation_candidates('probe', $_, $t, undef)] for @sources;
    my $ms = (time - $start) * 1000 / @sources;
    for my $s (@sources) {
        my @r = @{$found{$s}};
        $false++ if grep { $_->{score} < $t || $_->{score} > $best{$s} } @r;
        next unless $best{$s} >= $t;
        $partners++;
        $missed++ unless @r;
    }
    printf "%s\t%d\t%d\t%d\t%d\t%d\t%.3f\n", $label, $t, scalar @sources, $partners, $missed, $false, $ms;
}
