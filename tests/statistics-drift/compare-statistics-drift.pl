#!/usr/bin/env perl
#
# compare-statistics-drift.pl — L1+L2+L3+L4 statistics comparison engine
# for the statistics-drift test harness (Issue #224).
#
# This is the Phase B stub. The real engine body is implemented in Phase C
# (L1 drift + L2 intra-row), Phase E (L4 cross-model pairing), and Phase F
# (L3 oracle integration). For now, this stub validates the invocation
# interface and lets the Phase B driver wire end-to-end without doing any
# real comparison work.
#
# Invocation interface (locked, downstream phases must preserve):
#
#   compare-statistics-drift.pl --scenario <name> --file-kind messages|stats \
#       --new <path> [--baseline <path>] [--show-all] [--oracle-json <path>]
#       [--paired-with <other-scenario-name> --paired-new <path>]
#
# Exit codes:
#   0   no T3/T4 failures across any layer
#   1   at least one T3/T4 failure
#   2   invocation error (missing args, missing files, etc.)
#
# Self-documenting failure output (locked — Decision 7):
#   FAIL [Ttier-Llayer] scenario=... file=... key="..." column=...
#       baseline=... new=... deviation=...%
#       asserts: <invariant in plain English>
#       produced_by: <function in ltl that emits the value>
#       contract: <feature file section reference>
#       rule: <the inequality that was breached>

use strict;
use warnings;
use Getopt::Long;

my %opt = (
    scenario     => undef,
    file_kind    => undef,
    baseline     => undef,
    new          => undef,
    show_all     => 0,
    oracle_json  => undef,
    paired_with  => undef,
    paired_new   => undef,
);

GetOptions(
    'scenario=s'     => \$opt{scenario},
    'file-kind=s'    => \$opt{file_kind},
    'baseline=s'     => \$opt{baseline},
    'new=s'          => \$opt{new},
    'show-all'       => \$opt{show_all},
    'oracle-json=s'  => \$opt{oracle_json},
    'paired-with=s'  => \$opt{paired_with},
    'paired-new=s'   => \$opt{paired_new},
) or die "usage error\n";

for my $required (qw(scenario file_kind new)) {
    unless (defined $opt{$required}) {
        print STDERR "compare-statistics-drift.pl: missing --$required\n";
        exit 2;
    }
}

unless ($opt{file_kind} eq 'messages' || $opt{file_kind} eq 'stats') {
    print STDERR "compare-statistics-drift.pl: --file-kind must be 'messages' or 'stats'\n";
    exit 2;
}

unless (-f $opt{new}) {
    print STDERR "compare-statistics-drift.pl: --new file missing: $opt{new}\n";
    exit 2;
}

if (defined $opt{baseline} && !-f $opt{baseline}) {
    print STDERR "compare-statistics-drift.pl: --baseline file missing: $opt{baseline}\n";
    exit 2;
}

# Phase B stub — print invocation, exit 0. Phase C replaces this block.
my $baseline_state = defined $opt{baseline}    ? 'present' : 'absent';
my $oracle_state   = defined $opt{oracle_json} ? 'present' : 'absent';
my $paired_state   = defined $opt{paired_with} ? "with=$opt{paired_with}" : 'none';

print "STUB scenario=$opt{scenario} file=$opt{file_kind} ",
      "baseline=$baseline_state oracle=$oracle_state paired=$paired_state\n";
exit 0;
