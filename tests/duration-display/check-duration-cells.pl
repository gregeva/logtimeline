#!/usr/bin/env perl
# check-duration-cells.pl — render-invariant checker for duration-statistic
# cells in ltl's terminal output (Issue #292).
#
# Extracts every duration cell from the two rendered surfaces:
#   - timeline rows:  the P50:/P95:/P99:/P999: tokens in the latency column
#   - summary table:  the Min / P50 / P99.9 columns of each TOP MESSAGES row
# and asserts the render invariants. The rendered surface IS the system under
# test here (see tests/HARNESS-DESIGN.md § Render-invariant harnesses); this
# script is invoked by tests/validate-duration-display.sh via assert_command.
#
# Usage:
#   check-duration-cells.pl --render <ansi-stripped-file> \
#                           --expected-decimals <N> \
#                           --resolved-unit <us|ms|s|...> \
#                           --check <unit|zero|precision>
#
# Input must already have ANSI escapes stripped. Exits 0 if the requested
# check passes for every cell on both surfaces; non-zero with a per-cell
# diagnostic on the first violation.

use strict;
use warnings;

my %arg;
while (@ARGV) {
    my $k = shift @ARGV;
    $k =~ s/^--//;
    $arg{$k} = shift @ARGV;
}
for my $required (qw(render expected-decimals resolved-unit check)) {
    die "missing --$required\n" unless defined $arg{$required};
}

my $render_file = $arg{render};
my $expected_decimals = $arg{'expected-decimals'};
my $resolved_unit = $arg{'resolved-unit'};
my $check = $arg{check};

open my $fh, '<', $render_file or die "cannot open render file '$render_file': $!\n";
my @lines = <$fh>;
close $fh;

# A duration cell renders as <number><unit>, where unit is one of the
# format_time short-form tokens. Captured groups: (1) the numeric part,
# (2) the unit token. A bare number (no unit) does NOT match this and is
# the Bug-2 failure condition.
my $UNIT = qr/(?:us|ms|s|m|h|d)/;
my $CELL = qr/^([0-9]+(?:\.[0-9]+)?)($UNIT)$/;

# Each extracted cell: { surface, label, raw, row }
my @cells;

# --- Surface 1: timeline rows ---------------------------------------------
# Tokens look like  P50:7ms  P95:326ms  P99:1s  P999:1s  — the value is the
# whitespace-delimited token immediately after the Pxx: prefix.
for my $line (@lines) {
    next unless $line =~ /P(?:50|95|99|999):/;
    while ($line =~ /\b(P(?:50|95|99|999)):(\S+)/g) {
        push @cells, { surface => 'timeline', label => $1, raw => $2, row => $line };
    }
}

# --- Surface 2: summary table (TOP ... MESSAGES) --------------------------
# A data row begins with a bracketed category, e.g.  [200] POST /...  and
# its columns are: <message...> <occurrences-int> <Min> <P50> <P99.9>
# <CV-decimal> <Duration...>. The three duration cells (Min, P50, P99.9) are
# the three fields immediately after the occurrences count.
#
# Anchor on the occurrences integer: the first pure-integer field followed by
# three stat-shaped (number, optionally with a unit, or empty) fields and then
# a bare-decimal CV field. The CV anchor is what disambiguates the triple from
# the trailing Duration column (which carries a space: "2.4 hr"). The triple
# guard deliberately does NOT require a unit on the stat cells — that is the
# very invariant under test; requiring it here would make a bare-number bug
# cell invisible to the extractor instead of caught (HARNESS-DESIGN.md § "A
# grep that matches nothing is a failure").
my $stat_or_empty = qr/^(?:[0-9]+(?:\.[0-9]+)?(?:$UNIT)?)?$/;  # number +/- unit, or empty
my $cv_shaped     = qr/^[0-9]+\.[0-9]+$/;                       # bare decimal, no unit
for my $line (@lines) {
    next unless $line =~ /^\s*\[[^\]]+\]\s/;   # bracketed-category data row
    my @f = split ' ', $line;
    my $occ_idx;
    for my $i (0 .. $#f - 4) {
        next unless $f[$i]   =~ /^[0-9]+$/;        # pure integer (occurrences)
        next unless $f[$i+1] =~ /$stat_or_empty/
                 && $f[$i+2] =~ /$stat_or_empty/
                 && $f[$i+3] =~ /$stat_or_empty/;  # Min / P50 / P99.9
        next unless $f[$i+4] =~ /$cv_shaped/;      # CV anchor immediately after triple
        $occ_idx = $i;
        last;
    }
    next unless defined $occ_idx;
    my @triple = @f[ $occ_idx+1 .. $occ_idx+3 ];
    my @labels = ('Min', 'P50', 'P99.9');
    for my $j (0..2) {
        push @cells, { surface => 'summary', label => $labels[$j], raw => $triple[$j], row => $line };
    }
}

if (!@cells) {
    print STDERR "FAIL: no duration cells extracted from $render_file — anchors did not match (renamed columns? layout shift?)\n";
    exit 1;
}

my $violations = 0;
my $report = sub {
    my ($cell, $msg) = @_;
    $violations++;
    my $row = $cell->{row};
    $row =~ s/\s+$//;
    print STDERR "FAIL: [$cell->{surface}/$cell->{label}] cell '$cell->{raw}': $msg\n";
    print STDERR "      row: $row\n";
};

for my $cell (@cells) {
    my $raw = $cell->{raw};

    if ($check eq 'unit') {
        # Invariant 1: every populated duration cell carries a unit suffix.
        # An empty cell is acceptable (no data); a bare number is not.
        next if $raw eq '';
        $report->($cell, "bare number with no unit suffix (expected <number><unit>)")
            unless $raw =~ /$CELL/;
    }
    elsif ($check eq 'zero') {
        # Invariant 2: a zero duration renders as 0<resolved-unit>, never bare
        # 0 and never auto-scaled (e.g. 0us on a ms source).
        next unless $raw =~ /^0(?:\.0+)?(?:$UNIT)?$/;   # candidate zero cell
        $report->($cell, "zero rendered as '$raw'; expected '0$resolved_unit'")
            unless $raw eq "0$resolved_unit";
    }
    elsif ($check eq 'precision') {
        # Invariant 3: rendered fractional precision must not exceed the
        # resolved-unit precision read from -V. format_time auto-scales the
        # unit (ms -> s -> hr) as magnitude grows; a value displayed in a
        # COARSER unit than the source carries no synthesized precision, so we
        # only constrain cells still displayed in the resolved (source) unit.
        next if $raw eq '';
        next unless $raw =~ /$CELL/;
        my ($num, $unit) = ($1, $2);
        next unless $unit eq $resolved_unit;            # only the source-unit cells
        my $frac = ($num =~ /\.([0-9]+)$/) ? length($1) : 0;
        $report->($cell, "shows $frac fractional digit(s) in '$resolved_unit'; resolved precision is $expected_decimals")
            if $frac > $expected_decimals;
    }
    else {
        die "unknown --check '$check' (expected unit|zero|precision)\n";
    }
}

if ($violations) {
    print STDERR "FAIL: $violations duration-cell violation(s) for check '$check'\n";
    exit 1;
}

printf "ok: %d cells passed check '%s' (surfaces: timeline + summary)\n", scalar(@cells), $check;
exit 0;
