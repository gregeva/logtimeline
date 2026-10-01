#!/usr/bin/env perl
# ============================================================================
# Discovery-phase profile for #96: where ltl's grouping spends its time.
#
# Runs ltl's own grouping, compiled from ltl's source by
# prototype/96-ltl-engine.pl, with a timer wrapped around each of ltl's
# consolidation subs. It reports calls, inclusive time and exclusive time
# (inclusive less the wrapped subs it called). The interleaved re-scan runs
# inline in run_consolidation_pass() and process_final_pass_window(), so it is
# part of their exclusive time. The wrappers add a few microseconds a call, so
# the subs called most (dice_coefficient, match_consolidation_patterns) read
# high; --light leaves those two unwrapped. The findings this measures are
# features/fuzzy-message-consolidation.md PF-14 (performance profile) and PF-16
# (the discovery-phase breakdown).
#
# Usage: prototype/96-phase4-profile.pl --file <log> [--file <log> ...]
#            [--sensitivity N] [--light] [--ltl <path>]
# ============================================================================
use strict;
use warnings;
use Getopt::Long;
use File::Basename qw(dirname);
use File::Spec;
use Time::HiRes qw(time);
require File::Spec->catfile(dirname(File::Spec->rel2abs($0)), '96-ltl-engine.pl');

my @files;
my $sensitivity;                 # unset: ltl's own default
my $light = 0;
my $ltl_path = default_ltl_path();
GetOptions(
    'file=s@'       => \@files,
    'sensitivity=i' => \$sensitivity,
    'light'         => \$light,
    'ltl=s'         => \$ltl_path,
) or die "Usage: $0 --file <log> [--file <log> ...] [--sensitivity N] [--light] [--ltl <path>]\n";
die "Error: --file is required\n" unless @files;
-f $_ or die "Error: file '$_' not found\n" for @files;

load_ltl_engine($ltl_path);

my @wrapped = qw(
    consolidation_process_key run_consolidation_checkpoint run_consolidation_pass
    build_consolidation_ngram_index find_consolidation_candidates compute_mask coalesce_mask
    derive_canonical derive_regex try_consolidation_merge_into_existing
    merge_consolidation_overlapping_patterns merge_log_message_entry_into_cluster
    merge_consolidation_stats group_similar_messages process_final_pass_window
);
push @wrapped, qw(dice_coefficient match_consolidation_patterns) unless $light;

my (%calls, %incl, %excl);
my @stack;    # child time accumulated per open frame
for my $name (@wrapped) {
    no strict 'refs';
    no warnings 'redefine';
    my $orig = \&{"main::$name"};
    die "ltl has no sub $name\n" unless defined &$orig;
    *{"main::$name"} = sub {
        push @stack, 0;
        my $t0 = time();
        my @r = wantarray ? $orig->(@_) : (scalar $orig->(@_));
        my $dt = time() - $t0;
        my $children = pop @stack;
        $stack[-1] += $dt if @stack;
        $calls{$name}++;
        $incl{$name} += $dt;
        $excl{$name} += $dt - $children;
        return wantarray ? @r : $r[0];
    };
}

proto_configure(defined $sensitivity ? (sensitivity => $sensitivity) : ());
my $t0 = time();
proto_read_file($_) for @files;
my $t_read = time();
proto_finish();
my $t_end = time();
my %sum = proto_summary();

printf "Read and streaming grouping: %.3f s; end-of-file checkpoints and final pass: %.3f s\n", $t_read - $t0, $t_end - $t_read;
printf "Keys seen: %d, rows after grouping: %d, groups: %d, candidate searches: %d\n\n", @sum{qw(keys_seen rows groups searches)};
my $total = $t_end - $t0;
printf "%-42s %10s %12s %12s %8s\n", 'ltl sub', 'calls', 'inclusive s', 'exclusive s', 'excl %';
for my $name (sort { $excl{$b} <=> $excl{$a} } grep { $calls{$_} } @wrapped) {
    printf "%-42s %10d %12.3f %12.3f %7.1f%%\n", $name, $calls{$name}, $incl{$name}, $excl{$name}, $total ? 100 * $excl{$name} / $total : 0;
}
