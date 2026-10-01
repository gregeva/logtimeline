#!/usr/bin/env perl
# ============================================================================
# Prototype for #96 — Fuzzy Message Consolidation
#
# Message grouping outside ltl's full pipeline, for experimenting with it.
# The engine is ltl's own, compiled from ltl's source at start-up by
# prototype/96-ltl-engine.pl, so this groups exactly as ltl -g does and follows
# features/fuzzy-message-consolidation.md (the master specification) by
# construction. The formats it reads are listed in 96-ltl-engine.pl.
#
# Usage:
#   prototype/96-fuzzy-consolidation.pl --file <log> [--file <log> ...]
#       [--sensitivity N] [--group-ceiling N] [--no-final-pass]
#       [--top N] [--membership] [--ltl <path to ltl>]
# ============================================================================
use strict;
use warnings;
use Getopt::Long;
use File::Basename qw(dirname);
use File::Spec;
require File::Spec->catfile(dirname(File::Spec->rel2abs($0)), '96-ltl-engine.pl');

my @files;
my $sensitivity;                 # unset: ltl's own default ($consolidation_threshold)
my $group_ceiling;               # unset: ltl's own default ($consolidation_final_ceiling)
my $final_pass    = 1;
my $top_n         = 20;
my $membership    = 0;
my $ltl_path      = default_ltl_path();

GetOptions(
    'file=s@'         => \@files,
    'sensitivity=i'   => \$sensitivity,
    'group-ceiling=i' => \$group_ceiling,
    'final-pass!'     => \$final_pass,
    'top=i'           => \$top_n,
    'membership'      => \$membership,
    'ltl=s'           => \$ltl_path,
) or die "Usage: $0 --file <log> [--file <log> ...] [--sensitivity N] [--group-ceiling N] [--no-final-pass] [--top N] [--membership] [--ltl <path>]\n";

@files = map { my @m = glob($_); @m ? @m : die "Error: no files match '$_'\n" } @files;
die "Error: --file is required\n" unless @files;
-f $_ or die "Error: file '$_' not found\n" for @files;

load_ltl_engine($ltl_path);
proto_configure(sensitivity => $sensitivity, group_ceiling => $group_ceiling, final_pass => $final_pass);
proto_read_file($_) for @files;
proto_finish();
proto_report(top => $top_n, membership => $membership);
