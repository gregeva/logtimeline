#!/usr/bin/env perl
# ============================================================================
# Re-scan benchmark for #96: matching keys against compiled patterns.
#
# Compares ways of finding, for each of N message keys, the first of M compiled
# patterns that matches it. ltl's arm is ltl's own match_consolidation_patterns()
# (a Perl loop over the group's patterns, with its hot-sort), compiled from
# ltl's source by prototype/96-ltl-engine.pl. The patterns are the ones ltl's
# grouping discovers on the log, and the keys are the log's unique keys, read
# and built as ltl builds them. The alternatives are a single alternation regex
# and a C loop over Perl's regex engine (Inline::C); neither is ltl's code. The
# finding this measures is features/fuzzy-message-consolidation.md PF-16 (the
# re-scan optimisation research).
#
# Usage: prototype/96-rescan-bench.pl --file <log> [--file <log> ...]
#            [--sensitivity N] [--iterations N] [--ltl <path>]
# ============================================================================
use strict;
use warnings;
use Getopt::Long;
use File::Basename qw(dirname);
use File::Spec;
use Time::HiRes qw(time);
require File::Spec->catfile(dirname(File::Spec->rel2abs($0)), '96-ltl-engine.pl');

use Inline C => <<'END_C';

#include <string.h>

/* Match a string against an array of compiled qr// patterns.
 * Returns the index of the first matching pattern, or -1 if none match.
 * Uses Perl's native regex engine — no external libraries needed.
 */
int match_first_pattern_c(SV* string_sv, AV* patterns_av) {
    dTHX;
    STRLEN retlen;
    char* input = SvPV(string_sv, retlen);
    int pattern_count = av_len(patterns_av) + 1;

    for (int i = 0; i < pattern_count; i++) {
        SV** pattern_svp = av_fetch(patterns_av, i, 0);
        if (!pattern_svp || !SvROK(*pattern_svp)) continue;

        REGEXP* rx = (REGEXP*)SvRV(*pattern_svp);
        if (SvTYPE((SV*)rx) != SVt_REGEXP) continue;

        if (pregexec(rx, input, input + retlen, input, 0, string_sv, 0)) {
            return i;
        }
    }

    return -1;
}

/* Batch match: test all strings against all patterns.
 * Returns an AV* of integers: matched pattern index or -1.
 * This is the key optimization — the entire double loop runs in C,
 * eliminating per-iteration Perl interpreter overhead.
 */
SV* batch_match_c(AV* strings_av, AV* patterns_av) {
    dTHX;
    int string_count = av_len(strings_av) + 1;
    int pattern_count = av_len(patterns_av) + 1;

    AV* results = newAV();
    av_extend(results, string_count - 1);

    /* Pre-extract pattern REGEXP* pointers for the inner loop */
    REGEXP** rxs = (REGEXP**)malloc(pattern_count * sizeof(REGEXP*));
    for (int j = 0; j < pattern_count; j++) {
        SV** p = av_fetch(patterns_av, j, 0);
        if (p && SvROK(*p) && SvTYPE(SvRV(*p)) == SVt_REGEXP) {
            rxs[j] = (REGEXP*)SvRV(*p);
        } else {
            rxs[j] = NULL;
        }
    }

    for (int i = 0; i < string_count; i++) {
        SV** s = av_fetch(strings_av, i, 0);
        if (!s) {
            av_push(results, newSViv(-1));
            continue;
        }

        STRLEN retlen;
        char* input = SvPV(*s, retlen);
        int matched = -1;

        for (int j = 0; j < pattern_count; j++) {
            if (!rxs[j]) continue;
            if (pregexec(rxs[j], input, input + retlen, input, 0, *s, 0)) {
                matched = j;
                break;
            }
        }

        av_push(results, newSViv(matched));
    }

    free(rxs);
    return newRV_noinc((SV*)results);
}

END_C

my @files;
my $sensitivity;                 # unset: ltl's own default
my $iterations = 3;
my $ltl_path = default_ltl_path();
GetOptions(
    'file=s@'       => \@files,
    'sensitivity=i' => \$sensitivity,
    'iterations=i'  => \$iterations,
    'ltl=s'         => \$ltl_path,
) or die "Usage: $0 --file <log> [--file <log> ...] [--sensitivity N] [--iterations N] [--ltl <path>]\n";
die "Error: --file is required\n" unless @files;
-f $_ or die "Error: file '$_' not found\n" for @files;

# The patterns ltl's grouping discovers, from a run of its own in a child process
pipe(my $r, my $w) or die "pipe: $!";
my $pid = fork() // die "fork: $!";
if ($pid == 0) {
    close $r;
    load_ltl_engine($ltl_path);
    proto_configure(defined $sensitivity ? (sensitivity => $sensitivity) : ());
    proto_read_file($_) for @files;
    proto_finish();
    print $w join("\t", @$_), "\n" for proto_patterns();
    close $w;
    exit 0;
}
close $w;
my @pattern_rows = map { chomp; [ split /\t/, $_, 3 ] } <$r>;
close $r;
waitpid($pid, 0);
die "the grouping run failed\n" if $?;

# The keys, read and built as ltl builds them, not grouped
load_ltl_engine($ltl_path);
proto_configure(group => 0);
proto_read_file($_) for @files;
my %group_keys;
for my $row (proto_store()) {
    my ($cat, $key) = @$row;
    my ($gk) = $key =~ /^\[([^\]]*)\]/;
    push @{ $group_keys{"$cat|" . ($gk // '')} }, $key;
}
my %group_patterns;
push @{ $group_patterns{ $_->[0] } }, $_ for @pattern_rows;

print "=== Re-scan approaches ===\n";
for my $cat_gk (sort keys %group_patterns) {
    my @rows = @{ $group_patterns{$cat_gk} };
    my @strings = @{ $group_keys{$cat_gk} // [] };
    next unless @rows >= 2 && @strings;
    my ($cat, $gk) = split /\|/, $cat_gk, 2;
    printf "\n--- %s: %d keys x %d patterns ---\n", $cat_gk, scalar @strings, scalar @rows;

    # ltl: match_consolidation_patterns(), on a fresh copy of the group's patterns each iteration
    my (@ltl_hit, $t_ltl);
    for my $iter (1 .. $iterations) {
        proto_set_patterns(@rows);
        my $t1 = time();
        @ltl_hit = map { defined(main::match_consolidation_patterns($cat, $gk, $_)) ? 1 : 0 } @strings;
        $t_ltl += time() - $t1;
    }
    $t_ltl /= $iterations;
    printf "  ltl match_consolidation_patterns: %.4f s  (%d matched)\n", $t_ltl, scalar grep { $_ } @ltl_hit;

    my @patterns = map { qr/$_->[2]/ } @rows;

    # Alternative: one alternation regex over every pattern
    my $alt_source = join '|', map { my $p = "$_"; $p =~ s/^\(\?\^[a-z]*://; $p =~ s/\)$//; "(?:$p)" } @patterns;
    my $alt = eval { qr/$alt_source/ };
    if ($alt) {
        my (@alt_hit, $t_alt);
        for my $iter (1 .. $iterations) {
            my $t1 = time();
            @alt_hit = map { $_ =~ $alt ? 1 : 0 } @strings;
            $t_alt += time() - $t1;
        }
        $t_alt /= $iterations;
        my $disagree = grep { $alt_hit[$_] != $ltl_hit[$_] } 0 .. $#strings;
        printf "  alternation regex:                %.4f s  %.1fx ltl, %d keys disagree with ltl\n", $t_alt, $t_ltl / ($t_alt || 1e-9), $disagree;
    } else {
        printf "  alternation regex:                failed to compile (%s)\n", $@ // 'unknown error';
    }

    # Alternative: a C loop over Perl's regex engine
    my (@c_hit, $t_c);
    for my $iter (1 .. $iterations) {
        my $t1 = time();
        @c_hit = map { $_ >= 0 ? 1 : 0 } @{ batch_match_c(\@strings, \@patterns) };
        $t_c += time() - $t1;
    }
    $t_c /= $iterations;
    my $disagree = grep { $c_hit[$_] != $ltl_hit[$_] } 0 .. $#strings;
    printf "  Inline::C batch:                  %.4f s  %.1fx ltl, %d keys disagree with ltl\n", $t_c, $t_ltl / ($t_c || 1e-9), $disagree;
}
