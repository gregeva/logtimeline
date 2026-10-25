#!/usr/bin/env perl
# Reads the captured output of a harness run and reports what the run counted,
# so a run against an ltl that fails, or one that prints nothing, can be held
# to tests/HARNESS-DESIGN.md § Reading a harness for a run that did not happen:
# the harness reached its summary, and every check it passed is one that reads
# no output of ltl. It reads a capture and never runs a harness;
# tests/run-suite.sh reads each harness's capture with it.
#
# Usage: check-harness-capture.pl [--brief] CAPTURE [CAPTURE ...]
#   CAPTURE is a harness's standard output and standard error, captured
#   together. Its exit status is read from CAPTURE.rc when that file exists.
#
#   For each capture it prints whether the summary was reached (the last line
#   in one of the summary forms the harnesses print, and how many lines follow
#   it), the exit status, the passed and failed counts the summary gives, the
#   number of PASS lines against the passed count (a mismatch is a counter
#   advanced without a check, or a check that printed no PASS line: Trap 6),
#   and every PASS line, with those not marked run-free (a PASS line ending in
#   `[run-free: <what it read>]`, tests/HARNESS-DESIGN.md § The failed-run
#   checker) listed apart. --brief prints one tab-separated line per capture
#   instead: capture, summary (yes|no), exit, passed, failed, pass_lines,
#   unmarked (the PASS lines not marked run-free).
#
# Exit status: 0 when every capture reached its summary, 1 otherwise, 2 on a
# usage error.
use strict;
use warnings;

my $brief = 0;
my @captures;
for my $arg (@ARGV) {
    if    ( $arg eq '--brief' ) { $brief = 1 }
    elsif ( $arg =~ /^-/ )      { usage("unknown option $arg") }
    else                        { push @captures, $arg }
}
usage('no capture named') unless @captures;

# The summary forms, each giving the passed and the failed count.
my @summary_forms = (
    [ qr/^\s*Results: (\d+) passed, (\d+) failed/,                                1, 2 ],
    [ qr/^\s*PASS: (\d+)\s+FAIL: (\d+)\s*$/,                                       1, 2 ],
    [ qr/^=== [\w -]+: \d+ scenarios, (\d+) pass, (\d+) fail ===$/,                1, 2 ],
    [ qr/^=== validate-[\w-]+: (\d+) passed, (\d+) failed ===$/,                   1, 2 ],
    [ qr/^Total: \d+ \| Passed: (\d+) \| Failed: (\d+)$/,                          1, 2 ],
);

my $all_reached = 1;
for my $capture (@captures) {
    open my $fh, '<', $capture or die "cannot read $capture: $!\n";
    my @lines = map { s/\e\[[0-9;]*m//gr } <$fh>;
    close $fh;
    chomp @lines;

    my ( $summary_at, $passed, $failed );
    for my $i ( 0 .. $#lines ) {
        for my $form (@summary_forms) {
            my ( $re, $p, $f ) = @$form;
            next unless my @m = $lines[$i] =~ $re;
            ( $summary_at, $passed, $failed ) = ( $i, $m[ $p - 1 ], $m[ $f - 1 ] );
            last;
        }
    }
    my @pass_lines = grep { /^\s*PASS\b/ && !/^\s*PASS: \d+\s+FAIL: \d+\s*$/ } @lines;
    my @unmarked   = grep { !/\[run-free: [^]]+\]\s*$/ } @pass_lines;

    my $exit = 'unknown';
    if ( open my $rc, '<', "$capture.rc" ) {
        chomp( $exit = <$rc> // 'unknown' );
        close $rc;
    }

    my $reached = defined $summary_at;
    $all_reached &&= $reached;
    if ($brief) {
        print join( "\t", $capture, $reached ? 'yes' : 'no', $exit, $passed // '-', $failed // '-', scalar @pass_lines, scalar @unmarked ), "\n";
        next;
    }
    print "capture:     $capture\n";
    if ($reached) {
        print "summary:     reached: $lines[$summary_at]\n";
        print 'lines_after: ', $#lines - $summary_at, "\n";
    }
    else {
        print "summary:     NOT REACHED; last line: ", ( @lines ? $lines[-1] : '(empty capture)' ), "\n";
    }
    print "exit:        $exit\n";
    print 'passed:      ', $passed // '-', "\n";
    print 'failed:      ', $failed // '-', "\n";
    my $mismatch = defined $passed && $passed != @pass_lines ? "  MISMATCH: the summary counts $passed" : '';
    print 'pass_lines:  ', scalar @pass_lines, "$mismatch\n";
    print "  $_\n" for map { s/^\s+//r } @pass_lines;
    print 'unmarked:    ', scalar @unmarked, " PASS line(s) not marked run-free\n";
    print "  $_\n" for map { s/^\s+//r } @unmarked;
    print "\n";
}
exit( $all_reached ? 0 : 1 );

sub usage {
    print STDERR "check-harness-capture.pl: $_[0]\n" if @_;
    print STDERR "usage: check-harness-capture.pl [--brief] CAPTURE [CAPTURE ...]\n";
    exit 2;
}
