#!/usr/bin/env perl
# check-profile-labels.pl — render-invariant checker for the --profile folded
# timeline labels and the summary first/last-seen positions (Issue #256).
#
# The rendered terminal surface IS the system under test here (see
# tests/HARNESS-DESIGN.md § Render-invariant harnesses): these are properties
# of what a human reads off the timestamp column, with no internal-state
# equivalent. Invoked by tests/validate-profile-render.sh via assert_command.
#
# Input must already have ANSI escapes stripped. The timestamp column is the
# leading field of each bar-graph row, between the "timestamp legend ..."
# header separator and the run of rows. Under --profile it renders as a folded
# label: "HH:MM" (day/workday) or "Wkd HH:MM" (week/workweek, weekday shown
# once per day boundary then blanked).
#
# Usage:
#   check-profile-labels.pl --render <file> --check <check> [--mode <mode>]
#
# Checks (each exits 0 on pass, non-zero with a diagnostic on first violation):
#   time-only       every timeline label is HH:MM with NO weekday token
#                    (day / workday modes)
#   weekday-once     every included weekday appears exactly once across the
#                    timeline, at a day boundary; rows within a day are
#                    time-only (week / workweek modes). Requires --mode.
#   first-weekday    the first (leftmost/topmost) weekday label equals the
#                    mode's week-start weekday. Requires --mode.
#   no-excluded      no excluded-day weekday token appears (work modes).
#                    Requires --mode.
#   summary-folded   the summary first/last-seen heading shows folded positions
#                    in the mode's label form, not calendar dates.
#                    Requires --mode.

use strict;
use warnings;

my %arg;
while (@ARGV) {
    my $k = shift @ARGV;
    $k =~ s/^--//;
    $arg{$k} = shift @ARGV;
}
for my $required (qw(render check)) {
    die "missing --$required\n" unless defined $arg{$required};
}
my ($render_file, $check, $mode) = @arg{qw(render check mode)};

open my $fh, '<', $render_file or die "cannot open render file '$render_file': $!\n";
my @lines = <$fh>;
close $fh;
chomp @lines;

my @WD = qw(Mon Tue Wed Thu Fri Sat Sun);
my %IS_WD = map { $_ => 1 } @WD;

# Per-mode expectations (mirror features/256-time-axis-folding.md and the fold
# mode table in ltl). included = the weekday set the mode keeps, in axis order;
# excluded = the complementary set; first = the leftmost weekday label.
my %MODE = (
    'day'          => { week => 0 },
    'workday'      => { week => 0, excluded => [qw(Sat Sun)] },
    'workday-alt'  => { week => 0, excluded => [qw(Fri Sat)] },
    'week'         => { week => 1, included => [qw(Mon Tue Wed Thu Fri Sat Sun)], first => 'Mon', excluded => [] },
    'week-alt'     => { week => 1, included => [qw(Sun Mon Tue Wed Thu Fri Sat)], first => 'Sun', excluded => [] },
    'workweek'     => { week => 1, included => [qw(Mon Tue Wed Thu Fri)], first => 'Mon', excluded => [qw(Sat Sun)] },
    'workweek-alt' => { week => 1, included => [qw(Sun Mon Tue Wed Thu)], first => 'Sun', excluded => [qw(Fri Sat)] },
);

# Isolate the bar-graph timeline rows. They sit between the column header
# (the line containing "timestamp" and "legend") and the first blank-ish
# separator that follows the run. We collect every line whose leading field
# parses as a folded label; a non-label line after the run ends collection.
sub timeline_label_rows {
    my @rows;
    my $in = 0;
    for my $line (@lines) {
        if (!$in) {
            # The column header line. The leftmost label can be truncated by
            # column width ("timestamp" -> "times" in narrow day-fold), so
            # anchor on the wider, stable headers instead: "legend" plus the
            # "occurrence" stem (which may render as occurrences/occurrence).
            $in = 1 if $line =~ /\blegend\b/ && $line =~ /\boccurrence/;
            next;
        }
        # Within the timeline: a row's leading field is either
        #   "WKD HH:MM"  (weekday + time; the weekday renders upper-cased for
        #                 emphasis on day-boundary rows), or
        #   "HH:MM"      (time only / blanked weekday), possibly indented.
        # The matched weekday is normalized to mixed case (MON -> Mon) so the
        # rest of the checks compare against the canonical weekday names.
        if ($line =~ /^\s*([A-Za-z]{3})\s+(\d{2}:\d{2})\b/) {
            push @rows, { weekday => ucfirst(lc $1), time => $2, raw => $line };
        } elsif ($line =~ /^\s*(\d{2}:\d{2})\b/) {
            push @rows, { weekday => undef, time => $1, raw => $line };
        }
        # Lines that are neither (header separators, blank lines inside the
        # graph) are skipped, not treated as end-of-run, because empty buckets
        # still carry a time label and keep the run contiguous.
    }
    return @rows;
}

sub fail { my ($msg) = @_; print "VIOLATION: $msg\n"; exit 1; }

if ($check eq 'time-only') {
    my @rows = timeline_label_rows();
    fail("no timeline rows found (zero-match anchor)") unless @rows;
    for my $r (@rows) {
        if (defined $r->{weekday} && $IS_WD{$r->{weekday}}) {
            fail("day/workday timeline must be time-only, but a row carries weekday '$r->{weekday}': '$r->{raw}'");
        }
    }
    print "OK time-only: ", scalar(@rows), " timeline rows, all HH:MM, no weekday token\n";
    exit 0;
}

# Remaining checks need a mode.
die "check '$check' requires --mode\n" unless defined $mode;
my $cfg = $MODE{$mode} or die "unknown mode '$mode'\n";

if ($check eq 'weekday-once') {
    my @rows = timeline_label_rows();
    fail("no timeline rows found (zero-match anchor)") unless @rows;
    my %seen;
    for my $r (@rows) {
        next unless defined $r->{weekday};
        $seen{$r->{weekday}}++;
    }
    fail("no weekday labels found in a week-fold timeline (zero-match anchor)") unless %seen;
    for my $wd (sort keys %seen) {
        fail("weekday '$wd' appears $seen{$wd} times; each included weekday must appear exactly once (at its day boundary)")
            if $seen{$wd} != 1;
    }
    # The set of weekdays seen must equal the mode's included set.
    my %want = map { $_ => 1 } @{ $cfg->{included} };
    for my $wd (keys %seen) {
        fail("weekday '$wd' rendered but is not in the included set for $mode") unless $want{$wd};
    }
    for my $wd (keys %want) {
        fail("included weekday '$wd' for $mode never rendered") unless $seen{$wd};
    }
    print "OK weekday-once: each of (", join(',', @{$cfg->{included}}), ") appears exactly once\n";
    exit 0;
}

if ($check eq 'first-weekday') {
    my @rows = timeline_label_rows();
    fail("no timeline rows found (zero-match anchor)") unless @rows;
    my ($first) = grep { defined $_->{weekday} } @rows;
    fail("no weekday label found in the timeline (zero-match anchor)") unless $first;
    fail("first weekday label is '$first->{weekday}', expected '$cfg->{first}' for $mode")
        if $first->{weekday} ne $cfg->{first};
    print "OK first-weekday: leftmost label is $cfg->{first}\n";
    exit 0;
}

if ($check eq 'no-excluded') {
    my @rows = timeline_label_rows();
    fail("no timeline rows found (zero-match anchor)") unless @rows;
    my %excluded = map { $_ => 1 } @{ $cfg->{excluded} };
    fail("mode '$mode' has no excluded days to check") unless %excluded;
    for my $r (@rows) {
        next unless defined $r->{weekday};
        fail("excluded weekday '$r->{weekday}' rendered for $mode: '$r->{raw}'") if $excluded{$r->{weekday}};
    }
    print "OK no-excluded: none of (", join(',', @{$cfg->{excluded}}), ") rendered\n";
    exit 0;
}

if ($check eq 'summary-folded') {
    # The summary heading reads "... spanning <first> to <last>" under profile.
    my ($heading) = grep { /\bspanning\b.*\bto\b/ } @lines;
    fail("summary folding heading ('spanning ... to ...') not found (zero-match anchor)") unless defined $heading;
    my ($first, $last) = $heading =~ /spanning\s+(.+?)\s+to\s+(.+?)\s*$/;
    fail("could not parse first/last from heading: '$heading'") unless defined $first && defined $last;
    # A calendar date (YYYY-MM-DD) here would mean folding did not reach the
    # summary positions — the failure this check guards against.
    for my $pos ($first, $last) {
        fail("summary position '$pos' looks like a calendar date, not a folded position") if $pos =~ /\d{4}-\d{2}-\d{2}/;
    }
    if ($cfg->{week}) {
        for my $pos ($first, $last) {
            fail("week-fold summary position '$pos' lacks a weekday token") unless $pos =~ /^[A-Z][a-z][a-z]\s+\d{2}:\d{2}/;
        }
    } else {
        for my $pos ($first, $last) {
            fail("day-fold summary position '$pos' should be time-only (HH:MM), got '$pos'") unless $pos =~ /^\d{2}:\d{2}/;
        }
    }
    print "OK summary-folded: first='$first' last='$last'\n";
    exit 0;
}

die "unknown check '$check'\n";
