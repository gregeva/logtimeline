#!/usr/bin/env bash
# validate-log-level-vocabulary.sh — every log level a supported format can emit
# is recognised and analysed (Issue #447).
#
# A line whose captured level is not in ltl's vocabulary is discarded by the
# per-line category gate in read_and_process_logs(). The line is read, matched
# against its format, and then silently dropped: it appears in LINES READ, not
# in LINES INCLUDED, and nothing tells the user. A level missing from the
# vocabulary is therefore invisible data loss, which is what this harness exists
# to prevent.
#
# Five scenarios cover the vocabulary. One reads the levels the Windchill Method
# Server format emits, including FATAL, which the format uses for server
# shutdown ("MethodServer stopped") — among the most consequential lines in the
# file. One reads the severity names the syslog and java.util.logging
# vocabularies emit and the ThingWorx Edge C SDK's AUDIT, and also asserts which
# of them the default classification rule calls a failure, since a level that
# reaches the category table has not thereby reached the failure count.
#
# The remaining three read what happens when a level is outside the vocabulary
# after all, which no vocabulary edit can rule out because the producers are
# open and the acceptor is closed. One asserts the end-of-run report over the
# committed fixture whose middle line carries such a token, and that the counts
# do not move: the report makes the loss audible without giving the lines back.
# One reads the ThingWorx Edge C SDK tokens, the real-data case the report
# exists for, where two of the three control tokens are dropped and reported and
# the third is a vocabulary member and is not. And one reads the format listing,
# where a format that writes categories of its own states them and one that
# writes the usual severity names states nothing.
#
# This is a RENDER-INVARIANT harness (tests/HARNESS-DESIGN.md § Render-invariant
# harnesses): the assertion reads the rendered category table, which is where a
# recognised level appears and a dropped one does not.
#
# Each assertion records, per HARNESS-DESIGN.md § Self-documenting assertions:
#   - asserts:     the invariant being tested
#   - produced_by: where in ltl it is produced (function name, never a line)
#   - contract:    the source that makes the invariant stable
# All three are surfaced on failure.
#
# Usage: ./tests/validate-log-level-vocabulary.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

LTL="$REPO_DIR/ltl"
PERL="${PERL:-/opt/homebrew/bin/perl}"
command -v "$PERL" >/dev/null 2>&1 || PERL=perl

# Invocation shape (HARNESS-DESIGN.md § Invocation coherence): the assertions
# read the category table and the summary counts. Neither depends on the time
# axis, so the run uses the coarsest bucket with empty buckets suppressed over a
# six-line fixture spanning seconds. -ni keeps the developer's ltl-index.csv out
# of the run.
FIXTURE="$REPO_DIR/tests/fixtures/log-level-vocabulary.txt"
# The second fixture carries the severity names a supported format can emit that
# the six-line one does not: the syslog severities, java.util.logging's
# spellings, and the ThingWorx Edge C SDK's AUDIT, plus one INFO line so a run
# over it has both classified and unclassified lines. Same invocation shape as
# above: the assertions read the category table and the summary counts.
FIXTURE_EXTENDED="$REPO_DIR/tests/fixtures/log-level-vocabulary-extended.txt"
# The three-line fixture whose middle line carries a token deliberately outside
# the vocabulary and outside any name a later vocabulary edit would absorb: the
# one committed example of a line the category gate drops, and the input the
# end-of-run report is read from.
FIXTURE_OUTSIDE="$REPO_DIR/tests/fixtures/log-level-outside-vocabulary.txt"
# Four lines in the ThingWorx Edge C SDK line shape carrying the three tokens
# that producer writes in the level slot which are not severities, plus one
# INFO control line. Two of the three are outside the vocabulary and reported;
# START is inside it and is not.
FIXTURE_EDGE="$REPO_DIR/tests/fixtures/edge-c-sdk-unregistered-levels.txt"
WIDTH=140

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"

neutralize_colour_env

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"; exit 1
fi
if [[ ! -f "$FIXTURE" ]]; then
    echo "ERROR: fixture not found: $FIXTURE"; exit 1
fi
if [[ ! -f "$FIXTURE_EXTENDED" ]]; then
    echo "ERROR: fixture not found: $FIXTURE_EXTENDED"; exit 1
fi
if [[ ! -f "$FIXTURE_OUTSIDE" ]]; then
    echo "ERROR: fixture not found: $FIXTURE_OUTSIDE"; exit 1
fi
if [[ ! -f "$FIXTURE_EDGE" ]]; then
    echo "ERROR: fixture not found: $FIXTURE_EDGE"; exit 1
fi

TMP_DIR=$(mktemp -d); trap 'rm -rf "$TMP_DIR"' EXIT

pass=0
fail=0
failures=()
current_scenario=""

strip_ansi() { sed -E 's/\x1b\[[0-9;]*m//g'; }

assert_command() {
    local command label asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            command)     command="$2";     shift 2 ;;
            label)       label="$2";       shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_command: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${command:?assert_command requires command}"
    : "${label:?assert_command requires label}"
    : "${asserts:?assert_command requires asserts}"
    : "${produced_by:?assert_command requires produced_by}"
    : "${contract:?assert_command requires contract}"

    local cmd_out cmd_rc
    set +e
    cmd_out=$(eval "$command" 2>&1); cmd_rc=$?
    set -e
    if [[ "$cmd_rc" -eq 0 ]]; then
        echo "  PASS  $current_scenario :: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario :: $label"
        echo "        command:     $command"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        echo "$cmd_out" | sed 's/^/        | /'
        fail=$((fail + 1))
        failures+=("$current_scenario :: $label")
    fi
}

# A level appears as its own row in the category table, and that row carries a
# count. Absence means the category gate discarded every line carrying the
# level (HARNESS-DESIGN.md § Harnesses must fail on missing anchors: a
# zero-match lookup is a hard failure).
#
# The row's value is the count followed by that count's share of the lines
# included, "1 (16.7%)", right-aligned to the 41-character row boundary. The
# count is what this harness reconciles against LINES INCLUDED, so it is read
# out of the row rather than merely matched; the share is optional in the
# pattern, because a row too tight to carry it drops the share and keeps the
# count. Only the row itself is examined — the file-details pane is printed
# on the same physical line, past the row's boundary.
check_level_present() {
    "$PERL" -e '
        my ($render, $level) = @ARGV;
        my $row_width = 41;
        open my $fh, "<", $render or die "cannot open $render: $!\n";
        my $count;
        while (my $line = <$fh>) {
            next if length($line) < 2 + $row_width;
            next unless substr($line, 0, 2) eq "  ";
            my $row = substr($line, 2, $row_width);
            $count = $1
                if $row =~ /^\Q$level\E\s+(\d+)(?: \(\d+(?:\.\d+)?%\))?$/;
        }
        close $fh;
        unless (defined $count) {
            print "level $level has no row in the category table: every line carrying it was discarded\n";
            exit 1;
        }
        unless ($count > 0) {
            print "level $level has a row but its count is $count\n";
            exit 1;
        }
        print "$level present in the category table with a count of $count\n";
        exit 0;
    ' "$1" "$2"
}

# Every line the fixture carries is analysed, not merely read. LINES READ equal
# to LINES INCLUDED proves nothing was dropped by the category gate.
check_all_lines_included() {
    "$PERL" -e '
        my ($render, $expected) = @ARGV;
        open my $fh, "<", $render or die "cannot open $render: $!\n";
        my ($read, $incl);
        while (my $line = <$fh>) {
            $read = $1 if $line =~ /LINES READ\s+(\d+)/;
            $incl = $1 if $line =~ /LINES INCLUDED\s+(\d+)/;
        }
        close $fh;
        unless (defined $read && defined $incl) {
            print "anchor not found: LINES READ / LINES INCLUDED absent from the render\n";
            exit 1;
        }
        if ($read != $expected || $incl != $expected) {
            printf "expected %d read and %d included, got %d read and %d included: %d line(s) discarded by the category gate\n",
                $expected, $expected, $read, $incl, $read - $incl;
            exit 1;
        }
        print "$read read, $incl included\n";
        exit 0;
    ' "$1" "$2"
}

# FAILURE CLASSIFIED, read from the run summary rather than the category table.
# A level's presence in the category table proves only that the per-line
# category gate let it through; reaching the failure count proves the default
# failure rule names it. The two measure different things, so they are asserted
# separately.
check_failure_classified() {
    "$PERL" -e '
        my ($render, $expected) = @ARGV;
        open my $fh, "<", $render or die "cannot open $render: $!\n";
        my $failures;
        while (my $line = <$fh>) {
            $failures = $1 if $line =~ /FAILURE CLASSIFIED\s+(\d+)/;
        }
        close $fh;
        unless (defined $failures) {
            print "anchor not found: FAILURE CLASSIFIED absent from the render\n";
            exit 1;
        }
        unless ($failures == $expected) {
            print "expected FAILURE CLASSIFIED $expected, got $failures\n";
            exit 1;
        }
        print "FAILURE CLASSIFIED $failures\n";
        exit 0;
    ' "$1" "$2"
}

# The added failure severities raise the failure count. Runs the fixture twice —
# once as-is, and once with every SEVERE, ALERT and EMERGENCY line removed — and
# requires the first to report a strictly higher FAILURE CLASSIFIED than the
# second. Comparing two runs keeps the assertion independent of how many other
# levels in the fixture are failures.
check_failure_count_rises_with_added_severities() {
    local fixture="$1"
    local removed="$TMP_DIR/added-severities-removed.txt"
    grep -vE ' (SEVERE|ALERT|EMERGENCY) ' "$fixture" > "$removed"

    local render_with="$TMP_DIR/failures-with.txt"
    local render_without="$TMP_DIR/failures-without.txt"
    ( cd "$TMP_DIR" && "$LTL" --disable-progress -ni -bs 1440 -oe -n 1 \
        --terminal-width "$WIDTH" "$fixture" ) 2>/dev/null | strip_ansi > "$render_with"
    ( cd "$TMP_DIR" && "$LTL" --disable-progress -ni -bs 1440 -oe -n 1 \
        --terminal-width "$WIDTH" "$removed" ) 2>/dev/null | strip_ansi > "$render_without"

    "$PERL" -e '
        my ($a, $b) = @ARGV;
        sub failures {
            my ($render) = @_;
            open my $fh, "<", $render or return undef;
            my $n;
            while (my $line = <$fh>) {
                $n = $1 if $line =~ /FAILURE CLASSIFIED\s+(\d+)/;
            }
            close $fh;
            return $n;
        }
        my $with    = failures($a);
        my $without = failures($b);
        unless (defined $with && defined $without) {
            print "anchor not found: FAILURE CLASSIFIED absent from one of the renders\n";
            exit 1;
        }
        unless ($with > $without) {
            printf "failure count did not rise with SEVERE, ALERT and EMERGENCY present: with %d, without %d — they are not named by the default failure rule\n",
                $with, $without;
            exit 1;
        }
        printf "FAILURE CLASSIFIED %d with SEVERE/ALERT/EMERGENCY vs %d without\n", $with, $without;
        exit 0;
    ' "$render_with" "$render_without"
}

# The category table prints in the order of the vocabulary, so the rows the
# fixture produces must appear in the expected sequence. Reads the rows in the
# order they are rendered and compares against the expected list.
check_category_order() {
    "$PERL" -e '
        my ($render, @expected) = @ARGV;
        my $row_width = 41;
        open my $fh, "<", $render or die "cannot open $render: $!\n";
        my @seen;
        while (my $line = <$fh>) {
            next if length($line) < 2 + $row_width;
            next unless substr($line, 0, 2) eq "  ";
            my $row = substr($line, 2, $row_width);
            push @seen, $1
                if $row =~ /^(\S+(?: \S+)*?)\s+\d+(?: \(\d+(?:\.\d+)?%\))?$/
                   && grep { $_ eq $1 } @expected;
        }
        close $fh;
        unless (@seen) {
            print "anchor not found: no category rows in the render\n";
            exit 1;
        }
        my $got = join ", ", @seen;
        my $want = join ", ", @expected;
        unless ($got eq $want) {
            print "category table order is [$got], expected [$want]\n";
            exit 1;
        }
        print "category rows in order: $got\n";
        exit 0;
    ' "$@"
}

# The error rate counts FATAL. Runs the fixture twice — once as-is (one FATAL,
# one ERROR) and once with the FATAL line downgraded to INFO (one ERROR) — and
# requires the first to report a strictly higher error rate than the second.
# Comparing two runs keeps this independent of the rate unit. This is the one
# assertion whose bucket size matters: at -bs 1440 two failures spread over a
# day round to 0/min on both arms, so it runs at -bs 1 where the rate is
# observable (HARNESS-DESIGN.md section Invocation coherence).
check_error_rate_counts_fatal() {
    local fixture="$1"
    local with_fatal="$TMP_DIR/rate-with-fatal.txt"
    local without_fatal="$TMP_DIR/rate-without-fatal.txt"
    cp "$fixture" "$with_fatal"
    sed 's/ FATAL / INFO  /' "$fixture" > "$without_fatal"

    # The error rate is read from the stats CSV, whose err-rate column is the
    # computed value rather than a rendered approximation.
    local dir_a="$TMP_DIR/rate-a" dir_b="$TMP_DIR/rate-b"
    rm -rf "$dir_a" "$dir_b"; mkdir -p "$dir_a" "$dir_b"
    ( cd "$dir_a" && "$LTL" --disable-progress -ni -bs 1 -oe -n 1 --terminal-width "$WIDTH" -o "$with_fatal" ) >/dev/null 2>&1
    ( cd "$dir_b" && "$LTL" --disable-progress -ni -bs 1 -oe -n 1 --terminal-width "$WIDTH" -o "$without_fatal" ) >/dev/null 2>&1

    "$PERL" -e '
        my ($da, $db) = @ARGV;
        sub rate {
            my ($dir) = @_;
            my ($csv) = glob("$dir/*STATS*.csv");
            return undef unless defined $csv && -f $csv;
            open my $fh, "<", $csv or return undef;
            my $hdr = <$fh>; my $row = <$fh>; close $fh;
            return undef unless defined $hdr && defined $row;
            chomp($hdr, $row);
            my @h = split /,/, $hdr; my @r = split /,/, $row;
            for my $i (0 .. $#h) { return $r[$i] if $h[$i] =~ /^err-rate/ }
            return undef;
        }
        my $with    = rate($da);
        my $without = rate($db);
        unless (defined $with && defined $without) {
            print "anchor not found: err-rate column absent from one of the stats CSVs\n";
            exit 1;
        }
        unless ($with > $without) {
            printf "error rate did not rise when FATAL was present: with FATAL %s, without %s — FATAL is not counted as a failure\n",
                $with, $without;
            exit 1;
        }
        printf "err-rate %s with FATAL vs %s without\n", $with, $without;
        exit 0;
    ' "$dir_a" "$dir_b"
}

# The end-of-run report names the format, the token exactly as the producer
# wrote it, and the number of lines that carried it. Read from stderr, where the
# report is raised beside the numeric-filter and unreadable-directory notices.
# A capture that carries no report line at all is a failure naming that, so an
# absent report is never mistaken for a report naming something else.
check_report_names() {
    "$PERL" -e '
        my ($stderr, $format, $token, $count) = @ARGV;
        open my $fh, "<", $stderr or die "cannot open $stderr: $!\n";
        my @report = grep { /ltl does not recognise/ } <$fh>;
        close $fh;
        unless (@report) {
            print "anchor not found: no unregistered-level report on stderr\n";
            exit 1;
        }
        my ($line) = grep { /\b\Q$format\E\b/ } @report;
        unless (defined $line) {
            print "no report line names the format $format; saw: @report";
            exit 1;
        }
        unless ($line =~ /\Q$token\E \((\d+) lines?\)/) {
            print "the $format report line does not name the token $token with a line count: $line";
            exit 1;
        }
        unless ($1 == $count) {
            print "the $format report names $token with $1 line(s), expected $count\n";
            exit 1;
        }
        print "report: $line";
        exit 0;
    ' "$1" "$2" "$3" "$4"
}

# A report line reached stderr at all. Separate from check_report_names so the
# "it prints under --disable-progress" assertion measures presence rather than
# content, and can fail on its own.
check_report_present() {
    "$PERL" -e '
        my ($stderr) = @ARGV;
        open my $fh, "<", $stderr or die "cannot open $stderr: $!\n";
        my @report = grep { /ltl does not recognise/ } <$fh>;
        close $fh;
        unless (@report) {
            print "no unregistered-level report on stderr under --disable-progress\n";
            exit 1;
        }
        print "report present under --disable-progress: @report";
        exit 0;
    ' "$1"
}

# A token the report must NOT name. Contracted absence: the token is a member of
# the vocabulary, so the line carrying it was counted, and a report naming it
# would be reporting a loss that did not happen. A capture carrying no report at
# all fails rather than passes, so the absence is read against a real report.
check_report_omits() {
    "$PERL" -e '
        my ($stderr, $token) = @ARGV;
        open my $fh, "<", $stderr or die "cannot open $stderr: $!\n";
        my @report = grep { /ltl does not recognise/ } <$fh>;
        close $fh;
        unless (@report) {
            print "anchor not found: no unregistered-level report on stderr to read the absence against\n";
            exit 1;
        }
        if (grep { /\b\Q$token\E\b/ } @report) {
            print "the report names $token, which is a member of the vocabulary and was counted: @report";
            exit 1;
        }
        print "$token absent from the report, as a counted level must be\n";
        exit 0;
    ' "$1" "$2"
}

# LINES READ and LINES INCLUDED read from the run summary, asserted at the two
# values the input produces. Distinct from check_all_lines_included, which
# requires the two to be equal; here the gap is the point.
check_lines_read_included() {
    "$PERL" -e '
        my ($render, $want_read, $want_incl) = @ARGV;
        open my $fh, "<", $render or die "cannot open $render: $!\n";
        my ($read, $incl);
        while (my $line = <$fh>) {
            $read = $1 if $line =~ /LINES READ\s+(\d+)/;
            $incl = $1 if $line =~ /LINES INCLUDED\s+(\d+)/;
        }
        close $fh;
        unless (defined $read && defined $incl) {
            print "anchor not found: LINES READ / LINES INCLUDED absent from the render\n";
            exit 1;
        }
        unless ($read == $want_read && $incl == $want_incl) {
            printf "expected %d read and %d included, got %d read and %d included\n",
                $want_read, $want_incl, $read, $incl;
            exit 1;
        }
        print "$read read, $incl included\n";
        exit 0;
    ' "$1" "$2" "$3"
}

# A token must have no row in the category table. Contracted absence: naming a
# token in the report is not admitting it to the vocabulary. The check requires
# the category table to be present first, so an empty render never passes.
check_no_category_row() {
    "$PERL" -e '
        my ($render, $level) = @ARGV;
        my $row_width = 41;
        open my $fh, "<", $render or die "cannot open $render: $!\n";
        my ($rows, $found) = (0, 0);
        while (my $line = <$fh>) {
            next if length($line) < 2 + $row_width;
            next unless substr($line, 0, 2) eq "  ";
            my $row = substr($line, 2, $row_width);
            next unless $row =~ /^(\S+(?: \S+)*?)\s+\d+(?: \(\d+(?:\.\d+)?%\))?$/;
            $rows++;
            $found = 1 if $1 eq $level;
        }
        close $fh;
        unless ($rows) {
            print "anchor not found: no category rows in the render to read the absence against\n";
            exit 1;
        }
        if ($found) {
            print "$level has a row in the category table: the report promoted an unrecognised token to a category\n";
            exit 1;
        }
        print "$level has no category row, over $rows rows read\n";
        exit 0;
    ' "$1" "$2"
}

# The format listing states a named format's declared levels. The listing wraps,
# so the row and its continuation lines are joined before the list is matched.
check_help_states_levels() {
    "$PERL" -e '
        my ($help, $format, $levels) = @ARGV;
        open my $fh, "<", $help or die "cannot open $help: $!\n";
        my @lines = <$fh>;
        close $fh;
        my ($i) = grep { $lines[$_] =~ /^\s+\Q$format\E\s{2,}\S/ } 0 .. $#lines;
        unless (defined $i) {
            print "anchor not found: no listing row for $format\n";
            exit 1;
        }
        my $row = $lines[$i];
        $row .= $lines[$_] for grep { $_ <= $#lines && $lines[$_] =~ /^\s{20,}\S/ } $i + 1 .. $i + 6;
        $row =~ s/\s+/ /g;
        unless (index($row, "Writes the categories $levels.") >= 0) {
            print "the $format row does not state the levels [$levels]: $row\n";
            exit 1;
        }
        print "$format states: $levels\n";
        exit 0;
    ' "$1" "$2" "$3"
}

# A family states the levels its members share once in the whole listing. Two
# occurrences would mean the statement had been repeated per member rather than
# hoisted to the family heading; zero means it is not stated at all.
check_help_family_states_levels_once() {
    "$PERL" -e '
        my ($help, $levels) = @ARGV;
        open my $fh, "<", $help or die "cannot open $help: $!\n";
        my $text = do { local $/; <$fh> };
        close $fh;
        $text =~ s/\s+/ /g;
        my $n = () = $text =~ /Writes the categories \Q$levels\E\./g;
        unless ($n == 1) {
            print "the level list [$levels] appears $n time(s) in the listing, expected exactly 1 (stated once under the family heading)\n";
            exit 1;
        }
        print "the level list [$levels] is stated once\n";
        exit 0;
    ' "$1" "$2"
}

# A format that declares no levels carries no level statement in its row.
# Contracted absence: nothing is inferred from a format that declares nothing,
# so the listing must not claim a set it never named. The row itself must be
# present, or the absence would pass against a missing format.
check_help_states_no_levels() {
    "$PERL" -e '
        my ($help, $format) = @ARGV;
        open my $fh, "<", $help or die "cannot open $help: $!\n";
        my @lines = <$fh>;
        close $fh;
        my ($i) = grep { $lines[$_] =~ /^\s+\Q$format\E\s{2,}\S/ } 0 .. $#lines;
        unless (defined $i) {
            print "anchor not found: no listing row for $format\n";
            exit 1;
        }
        my $row = $lines[$i];
        $row .= $lines[$_] for grep { $_ <= $#lines && $lines[$_] =~ /^\s{20,}\S/ } $i + 1 .. $i + 6;
        $row =~ s/\s+/ /g;
        if (index($row, "Writes the categories") >= 0) {
            print "the $format row states levels although the format declares none: $row\n";
            exit 1;
        }
        print "$format states no levels, as a format declaring none must\n";
        exit 0;
    ' "$1" "$2"
}

# ---------------------------------------------------------------------------
# Scenario: one line per level the Windchill Method Server format emits.
# ---------------------------------------------------------------------------

# Scenario selector (tests/HARNESS-DESIGN.md section The scenario selector).
scenario_register method-server-levels \
                  extended-severity-vocabulary \
                  unregistered-level-report \
                  edge-c-sdk-unregistered-levels \
                  declared-levels-in-help
scenario_parse_args "$@"

if scenario_wanted method-server-levels; then
current_scenario="method-server-levels"
echo "[$current_scenario]"

RENDER="$TMP_DIR/render.txt"
STDERR="$TMP_DIR/render.stderr"

set +e
( cd "$TMP_DIR" && "$LTL" --disable-progress -ni -bs 1440 -oe -n 10 \
    --terminal-width "$WIDTH" "$FIXTURE" ) 2>"$STDERR" | strip_ansi > "$RENDER"
render_status=("${PIPESTATUS[@]}")
set -e

if [[ "${render_status[0]}" -ne 0 ]]; then
    echo "  FAIL  $current_scenario :: ltl exited ${render_status[0]} while rendering" >&2
    sed 's/^/        /' "$STDERR" >&2
    exit 1
fi
if [[ ! -s "$RENDER" ]]; then
    echo "  FAIL  $current_scenario :: rendered output is empty" >&2
    exit 1
fi

if ! assert_no_runtime_warnings "$STDERR" "$current_scenario"; then
    fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
fi

for level in FATAL ERROR WARN INFO DEBUG TRACE; do
    assert_command \
        command     "check_level_present '$RENDER' '$level'" \
        label       "$level is recognised and reaches the category table" \
        asserts     "A line whose captured level is outside ltl's vocabulary is discarded by the per-line category gate — read, format-matched, then silently dropped, so it counts in LINES READ but not LINES INCLUDED and nothing tells the user. Every level a supported format emits must therefore be in the vocabulary. FATAL was absent until #447, which discarded Windchill Method Server shutdown events." \
        produced_by '@log_levels / %log_level_set in ltl, gated per line in read_and_process_logs(); rendered by print_summary_table() in ltl' \
        contract    'features/447-message-control-character-normalisation.md § D6 — every level a supported format emits is in the vocabulary'
done

assert_command \
    command     "check_all_lines_included '$RENDER' 6" \
    label       'every fixture line is analysed, none discarded by the category gate' \
    asserts     'The fixture carries six lines, one per level the Windchill Method Server format emits, and all six match the format. LINES READ and LINES INCLUDED must both be 6; a shortfall is the count of lines the category gate discarded.' \
    produced_by '@log_levels / %log_level_set in ltl, gated per line in read_and_process_logs()' \
    contract    'features/447-message-control-character-normalisation.md § D6 — every level a supported format emits is in the vocabulary'

# FATAL is a failure level and must be counted toward the error rate, like ERROR
# and the 4xx/5xx status classes. The fixture carries exactly one FATAL and one
# ERROR, so removing FATAL from the error-rate accumulation halves the rate.
assert_command \
    command     "check_error_rate_counts_fatal '$FIXTURE'" \
    label       'FATAL is counted toward the error rate' \
    asserts     'FATAL denotes a failure and must contribute to the error rate alongside ERROR and the 4xx/5xx status classes. Measured by comparing a FATAL-and-ERROR run against an ERROR-only run: the two-failure run must report a strictly higher error rate than the one-failure run.' \
    produced_by 'normalize_data_for_output() in ltl — the error-rate accumulation' \
    contract    'features/447-message-control-character-normalisation.md § D6 — FATAL counts toward the error rate'

# ---------------------------------------------------------------------------
# Scenario: the severity names the syslog and java.util.logging vocabularies
# emit, plus the ThingWorx Edge C SDK's AUDIT.
# ---------------------------------------------------------------------------

fi

if scenario_wanted extended-severity-vocabulary; then
current_scenario="extended-severity-vocabulary"
echo "[$current_scenario]"

RENDER_EXT="$TMP_DIR/render-extended.txt"
STDERR_EXT="$TMP_DIR/render-extended.stderr"

set +e
( cd "$TMP_DIR" && "$LTL" --disable-progress -ni -bs 1440 -oe -n 10 \
    --terminal-width "$WIDTH" "$FIXTURE_EXTENDED" ) 2>"$STDERR_EXT" | strip_ansi > "$RENDER_EXT"
render_ext_status=("${PIPESTATUS[@]}")
set -e

if [[ "${render_ext_status[0]}" -ne 0 ]]; then
    echo "  FAIL  $current_scenario :: ltl exited ${render_ext_status[0]} while rendering" >&2
    sed 's/^/        /' "$STDERR_EXT" >&2
    exit 1
fi
if [[ ! -s "$RENDER_EXT" ]]; then
    echo "  FAIL  $current_scenario :: rendered output is empty" >&2
    exit 1
fi

if ! assert_no_runtime_warnings "$STDERR_EXT" "$current_scenario"; then
    fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
fi

for level in CRITICAL SEVERE WARNING NOTICE ALERT EMERGENCY AUDIT; do
    assert_command \
        command     "check_level_present '$RENDER_EXT' '$level'" \
        label       "$level is recognised and reaches the category table" \
        asserts     "A line whose captured level is outside ltl's vocabulary is discarded by the per-line category gate — read, format-matched, then silently dropped, so it counts in LINES READ but not LINES INCLUDED and nothing tells the user. CRITICAL, SEVERE, WARNING, NOTICE, ALERT, EMERGENCY and AUDIT are severity names a supported format can emit and must therefore be in the vocabulary." \
        produced_by '@log_levels / %log_level_set in ltl, gated per line in read_and_process_logs(); rendered by print_summary_table() in ltl' \
        contract    'features/475-log-level-vocabulary-completion.md § D1 (the vocabulary is a static list and names are added by hand) — the seven names admitted are CRITICAL, SEVERE, WARNING, NOTICE, ALERT, EMERGENCY and AUDIT'
done

assert_command \
    command     "check_all_lines_included '$RENDER_EXT' 8" \
    label       'every fixture line is analysed, none discarded by the category gate' \
    asserts     'The fixture carries eight lines — one per added level plus one INFO control — and all eight match the Windchill Method Server format. LINES READ and LINES INCLUDED must both be 8; a shortfall is the count of lines the category gate discarded.' \
    produced_by '@log_levels / %log_level_set in ltl, gated per line in read_and_process_logs()' \
    contract    'features/475-log-level-vocabulary-completion.md § R1 (a line carrying one of the seven names is counted in LINES INCLUDED and appears as its own row in the category table)'

assert_command \
    command     "check_category_order '$RENDER_EXT' EMERGENCY ALERT CRITICAL SEVERE WARNING NOTICE INFO AUDIT" \
    label       'the added levels print in severity order, AUDIT after INFO' \
    asserts     'The vocabulary order is the print order of the category table, the legend, the aggregate export and the STATS CSV header. The syslog severities lead most-serious-first, SEVERE sits in the FATAL band and WARNING in the WARN band, NOTICE sits between WARN and INFO, and AUDIT — which records an action rather than an outcome — follows the whole severity run.' \
    produced_by '@log_levels in ltl, read in order by print_summary_table()' \
    contract    'features/475-log-level-vocabulary-completion.md § D4 (colours reuse existing exact colour strings; AUDIT takes cyan) — position in @log_levels is by severity, with AUDIT after INFO and before DEBUG'

assert_command \
    command     "check_failure_classified '$RENDER_EXT' 4" \
    label       'CRITICAL is counted under FAILURE CLASSIFIED' \
    asserts     'The shipped default failure rule names CRITICAL, so a CRITICAL line must reach the failure count and not merely appear as a category row. The fixture carries four lines the rule names — EMERGENCY, ALERT, CRITICAL and SEVERE — so FAILURE CLASSIFIED must read 4; being in the category table only proves the gate let the line through.' \
    produced_by '%classification_default in ltl, compiled into each entry through format_classification_src(); counted in read_and_process_logs() and rendered by print_summary_table()' \
    contract    'features/475-log-level-vocabulary-completion.md § D2 (CRITICAL is admitted with the others and gets its own criterion)'

assert_command \
    command     "check_failure_count_rises_with_added_severities '$FIXTURE_EXTENDED'" \
    label       'SEVERE, ALERT and EMERGENCY are counted as failures' \
    asserts     "SEVERE is java.util.logging's highest severity and ALERT and EMERGENCY sit above CRITICAL in syslog, so the default failure rule names all three. Measured by comparing a run carrying them against a run with those lines removed: the first must report a strictly higher FAILURE CLASSIFIED than the second." \
    produced_by '%classification_default in ltl, compiled into each entry through format_classification_src(); counted in read_and_process_logs()' \
    contract    'features/475-log-level-vocabulary-completion.md § D3 (the default failure rule gains SEVERE, ALERT and EMERGENCY)'

WARNLESS="$TMP_DIR/non-failure-levels-only.txt"
grep -vE ' (SEVERE|ALERT|EMERGENCY|CRITICAL) ' "$FIXTURE_EXTENDED" > "$WARNLESS"
RENDER_WARNLESS="$TMP_DIR/render-non-failure-levels-only.txt"
STDERR_WARNLESS="$TMP_DIR/render-non-failure-levels-only.stderr"

set +e
( cd "$TMP_DIR" && "$LTL" --disable-progress -ni -bs 1440 -oe -n 1 \
    --terminal-width "$WIDTH" "$WARNLESS" ) 2>"$STDERR_WARNLESS" | strip_ansi > "$RENDER_WARNLESS"
set -e

if ! assert_no_runtime_warnings "$STDERR_WARNLESS" "$current_scenario"; then
    fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr-non-failure-arm")
fi

assert_command \
    command     "check_failure_classified '$RENDER_WARNLESS' 0" \
    label       'WARNING, NOTICE and AUDIT are recognised levels that are not failures' \
    asserts     "WARNING is java.util.logging's spelling of WARN and WARN is not a failure; NOTICE sits below informational in syslog; AUDIT records an action rather than an outcome. A run whose only non-INFO lines carry those three must report FAILURE CLASSIFIED 0, so admitting them to the vocabulary does not silently widen what the tool calls a failure." \
    produced_by '%classification_default in ltl, compiled into each entry through format_classification_src(); counted in read_and_process_logs() and rendered by print_summary_table()' \
    contract    'features/475-log-level-vocabulary-completion.md § D3 (the default failure rule gains SEVERE, ALERT and EMERGENCY) — WARNING, NOTICE and AUDIT stay outside the rule'

# ---------------------------------------------------------------------------
# Scenario: a level the vocabulary does not carry is reported at the end of the
# run, and nothing about the counts changes.
# ---------------------------------------------------------------------------

fi

if scenario_wanted unregistered-level-report; then
current_scenario="unregistered-level-report"
echo "[$current_scenario]"

RENDER_OUT="$TMP_DIR/render-outside.txt"
STDERR_OUT="$TMP_DIR/render-outside.stderr"

set +e
( cd "$TMP_DIR" && "$LTL" --disable-progress -ni -bs 1440 -oe -n 10 \
    --terminal-width "$WIDTH" "$FIXTURE_OUTSIDE" ) 2>"$STDERR_OUT" | strip_ansi > "$RENDER_OUT"
render_outside_status=("${PIPESTATUS[@]}")
set -e

if [[ "${render_outside_status[0]}" -ne 0 ]]; then
    echo "  FAIL  $current_scenario :: ltl exited ${render_outside_status[0]} while rendering" >&2
    sed 's/^/        /' "$STDERR_OUT" >&2
    exit 1
fi

if ! assert_no_runtime_warnings "$STDERR_OUT" "$current_scenario"; then
    fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
fi

assert_command \
    command     "check_report_names '$STDERR_OUT' 'windchill_method_server' 'NOTAREALLEVEL' 1" \
    label       'the report names the format, the token and the line count' \
    asserts     "A line whose captured level is outside the vocabulary is matched against its format and then dropped by the per-line category gate, so it counts in LINES READ and not in LINES INCLUDED with nothing to attribute the gap to. The end of the run must name the format that produced the token, the token exactly as the producer wrote it, and how many lines carried it — the count is what separates a rounding error from a loss that matters." \
    produced_by 'read_and_process_logs() in ltl — the unregistered-level collection on the reject branch of the category gate, reported at the tail of the same sub beside the numeric-filter and unreadable-directory notices' \
    contract    'features/476-per-format-log-level-declarations.md § D6 (one report line per format, each token with its line count, always printed)'

assert_command \
    command     "check_report_present '$STDERR_OUT'" \
    label       'the report prints under --disable-progress' \
    asserts     'The report is a behavioural notice, not a progress indicator: --disable-progress suppresses progress indicators only. This run passes --disable-progress, as every harness invocation does, and the report must still reach stderr.' \
    produced_by 'read_and_process_logs() in ltl — the notice block at the tail, which prints to stderr unconditionally' \
    contract    'features/476-per-format-log-level-declarations.md § D6 (it always prints; --disable-progress suppresses progress indicators only)'

assert_command \
    command     "check_lines_read_included '$RENDER_OUT' 3 2" \
    label       'the dropped line is still dropped: LINES READ 3, LINES INCLUDED 2' \
    asserts     'The report makes the loss audible; it does not give the lines back. The three-line fixture carries one line whose level is outside the vocabulary, so LINES READ stays 3 and LINES INCLUDED stays 2 exactly as before the report existed. Retaining the line would move LINES INCLUDED, the category table, the percentiles and every committed reference render.' \
    produced_by '%log_level_set in ltl, gated per line in read_and_process_logs(); rendered by print_summary_table()' \
    contract    'features/476-per-format-log-level-declarations.md § D1 (an unregistered level is still rejected; this drop captures and reports it, and retains nothing)'

assert_command \
    command     "check_no_category_row '$RENDER_OUT' 'NOTAREALLEVEL'" \
    label       'the reported token does not become a category' \
    asserts     'Naming a token in the report is not admitting it to the vocabulary. The token must not appear as a row of the category table, or the report would have promoted an unrecognised token to a category the tool counts.' \
    produced_by '%log_level_set in ltl, gated per line in read_and_process_logs(); the category table rendered by print_summary_table()' \
    contract    'features/476-per-format-log-level-declarations.md § D1 (the gate keeps today behaviour exactly; the token, the format and the count are kept and reported, and nothing is retained)'

# ---------------------------------------------------------------------------
# Scenario: the Edge C SDK tokens, the real-data case the report exists for.
# ---------------------------------------------------------------------------

fi

if scenario_wanted edge-c-sdk-unregistered-levels; then
current_scenario="edge-c-sdk-unregistered-levels"
echo "[$current_scenario]"

RENDER_EDGE="$TMP_DIR/render-edge.txt"
STDERR_EDGE="$TMP_DIR/render-edge.stderr"

set +e
( cd "$TMP_DIR" && "$LTL" --disable-progress -ni -bs 1440 -oe -n 10 \
    --terminal-width "$WIDTH" "$FIXTURE_EDGE" ) 2>"$STDERR_EDGE" | strip_ansi > "$RENDER_EDGE"
render_edge_status=("${PIPESTATUS[@]}")
set -e

if [[ "${render_edge_status[0]}" -ne 0 ]]; then
    echo "  FAIL  $current_scenario :: ltl exited ${render_edge_status[0]} while rendering" >&2
    sed 's/^/        /' "$STDERR_EDGE" >&2
    exit 1
fi

if ! assert_no_runtime_warnings "$STDERR_EDGE" "$current_scenario"; then
    fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
fi

for token in AUTH TRAFFIC_CONTROL; do
    assert_command \
        command     "check_report_names '$STDERR_EDGE' 'tw_edge_c_sdk' '$token' 1" \
        label       "$token is reported with its line count" \
        asserts     "The Edge C SDK writes AUTH and TRAFFIC_CONTROL in the level slot. They are startup and control messages rather than severities, so they are not admitted to the vocabulary and the lines carrying them are dropped. The report is the mechanism that names such a token without promoting it to a category, and it must name this one with the number of lines that carried it." \
        produced_by 'read_and_process_logs() in ltl — the unregistered-level collection on the reject branch of the category gate, reported at the tail of the same sub' \
        contract    'features/476-per-format-log-level-declarations.md § D9 (the Edge C SDK tokens are the first real-data case the report surfaces; the entry declares TRACE, DEBUG, INFO, WARN, ERROR, FORCE and AUDIT and declares none of the three control tokens)'
done

assert_command \
    command     "check_report_omits '$STDERR_EDGE' 'START'" \
    label       'START is not reported, because the vocabulary already carries it' \
    asserts     'START is a member of the global vocabulary, put there by the Workgroup Manager letter map, so a START line from the Edge C SDK passes the gate and is counted as a category of a format that does not declare it. The report names what was dropped, and START was not dropped, so it must not appear — the declaration makes that condition legible rather than closing it, which would cost a per-format check on the accept path of every matched line.' \
    produced_by 'read_and_process_logs() in ltl — the collection runs on the reject branch only, and a token in %log_level_set never reaches it' \
    contract    'features/476-per-format-log-level-declarations.md § D9 (one of the three is not dropped, and the declaration is what makes that visible)'

assert_command \
    command     "check_lines_read_included '$RENDER_EDGE' 4 2" \
    label       'two of the four lines are dropped and two are counted' \
    asserts     'The four-line fixture carries START, AUTH, TRAFFIC_CONTROL and INFO. AUTH and TRAFFIC_CONTROL are outside the vocabulary and dropped; START and INFO are inside it and counted. LINES READ must be 4 and LINES INCLUDED 2, which is the measurement behind the report.' \
    produced_by '%log_level_set in ltl, gated per line in read_and_process_logs(); rendered by print_summary_table()' \
    contract    'features/476-per-format-log-level-declarations.md § D1 (an unregistered level is still rejected) and § D9 (START passes the gate, AUTH and TRAFFIC_CONTROL do not)'

# ---------------------------------------------------------------------------
# Scenario: the levels a format declares are stated by the format listing.
# ---------------------------------------------------------------------------

fi

if scenario_wanted declared-levels-in-help; then
current_scenario="declared-levels-in-help"
echo "[$current_scenario]"

HELP_FORMATS="$TMP_DIR/help-formats.txt"
HELP_FORMATS_ERR="$TMP_DIR/help-formats.stderr"

set +e
( cd "$TMP_DIR" && "$LTL" --help formats ) 2>"$HELP_FORMATS_ERR" | strip_ansi > "$HELP_FORMATS"
help_status=("${PIPESTATUS[@]}")
set -e

if [[ "${help_status[0]}" -ne 0 ]]; then
    echo "  FAIL  $current_scenario :: ltl --help formats exited ${help_status[0]}" >&2
    sed 's/^/        /' "$HELP_FORMATS_ERR" >&2
    exit 1
fi

if ! assert_no_runtime_warnings "$HELP_FORMATS_ERR" "$current_scenario"; then
    fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
fi

assert_command \
    command     "check_help_states_levels '$HELP_FORMATS' 'tw_edge_c_sdk' 'TRACE, DEBUG, INFO, WARN, ERROR, FORCE, AUDIT'" \
    label       'the Edge C SDK entry states the levels it declares' \
    asserts     "A format that writes categories of its own states them in the listing, so a reader can see what the tool expects that producer to write before running it against a file. The Edge C SDK writes FORCE and AUDIT beside the standard severities, so it declares rather than staying silent, and the listing must carry that list." \
    produced_by 'print_help_formats() in ltl, reading the declared levels from the compiled registry specs' \
    contract    'features/476-per-format-log-level-declarations.md § D8 (ltl --help formats states the levels each format declares)'

assert_command \
    command     "check_help_states_levels '$HELP_FORMATS' 'java_gc_g1' 'Pause Young, Pause Full, Pause Remark, Pause Cleanup, To-space exhausted, Using G1'" \
    label       'the G1 garbage-collection entry states its pause kinds' \
    asserts     'The G1 entry categorises by pause kind rather than by severity, and its declaration is exactly the closed alternation its own pattern captures. The listing must state those six names, because a reader who expects severity names from this format would otherwise have no way to learn what it actually writes.' \
    produced_by 'print_help_formats() in ltl, reading the declared levels from the compiled registry specs' \
    contract    'features/476-per-format-log-level-declarations.md § D4 table as amended (the list of what each declaring entry adds, read as additions)'

assert_command \
    command     "check_help_family_states_levels_once '$HELP_FORMATS' '1xx, 2xx, 3xx, 4xx, 5xx'" \
    label       'the access family states its five status families once, not seven times' \
    asserts     'The seven access entries share one status-family set, and the listing states a property a family shares once under the family heading rather than repeating it on every member. The five families must appear exactly once in the whole listing, which is what proves the family shape is used rather than seven identical rows.' \
    produced_by 'print_help_formats() in ltl — the family heading, which states what the members share once' \
    contract    'features/476-per-format-log-level-declarations.md § D8 (a family is listed under one heading with the property its members share stated once)'

assert_command \
    command     "check_help_states_no_levels '$HELP_FORMATS' 'windchill_method_server'" \
    label       'a format that declares nothing shows no level line' \
    asserts     'Nothing is inferred from a format that declares no levels: there is no standard set it can be said to inherit, so the listing says nothing about levels for it rather than claiming a set it never named. The Windchill Method Server entry declares none and its row must carry no level statement.' \
    produced_by 'print_help_formats() in ltl — the level statement is emitted only for an entry carrying a declaration' \
    contract    'features/476-per-format-log-level-declarations.md § Amendment of 2026-09-13 (--help formats states the declared levels for an entry that declares any and says nothing about levels for one that does not)'

echo
echo "─────────────────────────────────────────"
echo "  PASS: $pass    FAIL: $fail"
if [[ "$fail" -gt 0 ]]; then
    echo
    echo "  Failed assertions:"
    printf '    - %s\n' "${failures[@]}"
    exit 1
fi
echo "─────────────────────────────────────────"
exit 0
fi

