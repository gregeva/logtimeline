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
# FATAL was absent until #447. Windchill Method Server logs emit it for server
# shutdown ("MethodServer stopped"), so those events — among the most
# consequential lines in the file — were being dropped.
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
WIDTH=140

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"

neutralize_colour_env

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"; exit 1
fi
if [[ ! -f "$FIXTURE" ]]; then
    echo "ERROR: fixture not found: $FIXTURE"; exit 1
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

# A level appears as its own row in the category table. Absence means the
# category gate discarded every line carrying it (HARNESS-DESIGN.md § Harnesses
# must fail on missing anchors: a zero-match lookup is a hard failure).
check_level_present() {
    "$PERL" -e '
        my ($render, $level) = @ARGV;
        open my $fh, "<", $render or die "cannot open $render: $!\n";
        my $found = 0;
        while (my $line = <$fh>) {
            $found = 1 if $line =~ /^\s+\Q$level\E\s+\d+(?:\s|$)/;
        }
        close $fh;
        unless ($found) {
            print "level $level has no row in the category table: every line carrying it was discarded\n";
            exit 1;
        }
        print "$level present in the category table\n";
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

# ---------------------------------------------------------------------------
# Scenario: one line per level the Windchill Method Server format emits.
# ---------------------------------------------------------------------------

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
