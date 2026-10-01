#!/usr/bin/env perl
# ============================================================================
# N-gram size benchmark for #96: ltl's grouping with the gram size and step
# under test.
#
# Each configuration runs ltl's own grouping, compiled from ltl's source by
# prototype/96-ltl-engine.pl, in a child process of its own. The only change is
# the variable under test: get_consolidation_trigrams() is replaced by one that
# takes grams of the given size at the given step, over the same cut of the key.
# Size 3, step 1 is ltl as it is. Everything else (the candidate search, Dice,
# alignment, merging, checkpoints and the final pass) is ltl's code. The finding
# this measures is features/fuzzy-message-consolidation.md PF-02 (n-gram index
# performance characteristics).
#
# Usage: prototype/96-ngram-tuning.pl --file <log> [--file <log> ...]
#            [--sizes 2,3,4,5] [--steps 1,2] [--sensitivity N] [--ltl <path>]
# ============================================================================
use strict;
use warnings;
use Getopt::Long;
use File::Basename qw(dirname);
use File::Spec;
use Time::HiRes qw(time);
require File::Spec->catfile(dirname(File::Spec->rel2abs($0)), '96-ltl-engine.pl');

my @files;
my $sizes = '2,3,4,5';
my $steps = '1';
my $sensitivity;                 # unset: ltl's own default
my $ltl_path = default_ltl_path();
GetOptions(
    'file=s@'       => \@files,
    'sizes=s'       => \$sizes,
    'steps=s'       => \$steps,
    'sensitivity=i' => \$sensitivity,
    'ltl=s'         => \$ltl_path,
) or die "Usage: $0 --file <log> [--file <log> ...] [--sizes 2,3,4,5] [--steps 1,2] [--sensitivity N] [--ltl <path>]\n";
die "Error: --file is required\n" unless @files;
-f $_ or die "Error: file '$_' not found\n" for @files;

printf "%-5s %-5s %10s %10s %10s %10s %10s\n", 'size', 'step', 'time (s)', 'keys', 'rows', 'groups', 'searches';
for my $size (split /,/, $sizes) {
    for my $step (split /,/, $steps) {
        pipe(my $r, my $w) or die "pipe: $!";
        my $pid = fork() // die "fork: $!";
        if ($pid == 0) {
            close $r;
            load_ltl_engine($ltl_path);
            unless ($size == 3 && $step == 1) {
                no warnings qw(redefine once);
                # The variable under test, in place of ltl's trigram function: grams
                # of $size characters every $step characters, over the key cut at
                # the per-run cut (MESSAGE_KEY_CAP under -g), as ltl's function cuts it.
                *main::get_consolidation_trigrams = sub {
                    my ($str) = @_;
                    my $capped = substr($str, 0, main::MESSAGE_KEY_CAP());
                    my %grams;
                    for (my $i = 0; $i <= length($capped) - $size; $i += $step) { $grams{ substr($capped, $i, $size) } = 1 }
                    return \%grams;
                };
            }
            proto_configure(defined $sensitivity ? (sensitivity => $sensitivity) : ());
            my $t0 = time();
            proto_read_file($_) for @files;
            proto_finish();
            my %sum = proto_summary();
            printf $w "%.3f %d %d %d %d\n", time() - $t0, @sum{qw(keys_seen rows groups searches)};
            close $w;
            exit 0;
        }
        close $w;
        my $line = <$r>;
        close $r;
        waitpid($pid, 0);
        die "configuration size $size, step $step failed\n" unless defined $line && $? == 0;
        my @v = split ' ', $line;
        printf "%-5s %-5s %10.3f %10d %10d %10d %10d%s\n", $size, $step, @v, ($size == 3 && $step == 1 ? '   (ltl)' : '');
    }
}
