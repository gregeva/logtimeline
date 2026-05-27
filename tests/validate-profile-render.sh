#!/usr/bin/env bash
# validate-profile-render.sh — Render-invariant harness for the --profile
# folded timeline labels and summary first/last-seen (Issue #256).
#
# This is a RENDER-INVARIANT harness (tests/HARNESS-DESIGN.md § Render-invariant
# harnesses): the system under test is the rendered terminal surface itself —
# the folded labels in the timestamp column and the summary heading — not
# internal state. It runs ltl at a pinned --terminal-width, strips ANSI, and
# asserts the label INVARIANTS the surface must hold to, regardless of the data:
#   - day/workday: every timeline label is HH:MM, no weekday token
#   - week/workweek: each included weekday appears exactly once (at its day
#     boundary); the leftmost weekday matches the mode's week start
#   - work modes: no excluded-day weekday is rendered
#   - summary first/last-seen render as folded positions, not calendar dates
# These are properties, not frozen output, so the harness does not duplicate the
# snapshot regression harness (validate-regression.sh).
#
# The sibling state-observability harness (validate-profile.sh) asserts the
# computed fold counts via -V profile; this one asserts the rendered surface.
#
# The fixture is the synthetic month-long log from
# tests/profile/generate-profile-log.py. The label extraction and invariant
# checks live in tests/profile/check-profile-labels.pl, invoked per assertion.
#
# Each assertion records, per HARNESS-DESIGN.md § Self-documenting assertions:
#   - asserts:     the render invariant being tested
#   - produced_by: where in ltl the rendered label is produced (function name)
#   - contract:    the source that makes the invariant stable
# All three are surfaced on failure alongside the failing command.
#
# Usage: ./tests/validate-profile-render.sh
#
# Requires python3 (the generator; standard library only) and perl (the checker).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"
GENERATOR="$SCRIPT_DIR/profile/generate-profile-log.py"
CHECKER="$SCRIPT_DIR/profile/check-profile-labels.pl"
PERL="${PERL:-/opt/homebrew/bin/perl}"
command -v "$PERL" >/dev/null 2>&1 || PERL=perl

WIDTH=120

PRODUCED_BY='print_bar_graph() in ltl renders the timestamp column from $output_timestamp_format (set in adapt_to_command_line_options() to %H:%M or %a %H:%M under --profile) and blanks a repeated weekday at the day boundary; the summary heading is built in print_summary_table(). Bucket keys are folded by fold_epoch() in read_and_process_logs().'
CONTRACT='Issue #256 + tests/HARNESS-DESIGN.md § Render-invariant harnesses. The folded-label forms (time-only for day/workday, weekday-once for week/workweek, week-start Mon default / Sun for -alt, excluded-day suppression) are the locked rendered surface for --profile.'

for f in "$LTL" "$GENERATOR" "$CHECKER"; do
    if [[ ! -e "$f" ]]; then echo "ERROR: required file missing: $f" >&2; exit 1; fi
done
[[ -x "$LTL" ]] || { echo "ERROR: ltl not executable: $LTL" >&2; exit 1; }
if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: this harness requires python3 (not found on PATH)." >&2
    exit 1
fi

TMP_ROOT=$(mktemp -d); trap 'rm -rf "$TMP_ROOT"' EXIT
LOGFILE="$TMP_ROOT/profile.log"

pass=0
fail=0
failures=()
current_scenario=""

strip_ansi() { sed -E 's/\x1b\[[0-9;]*m//g'; }

# Generate the fixture ONCE (capture-once). This harness asserts on the render,
# not the counts, so the manifest is not needed — discard the generator's stdout
# manifest dump. Hard-fail on any breakdown.
if ! python3 "$GENERATOR" "$LOGFILE" >/dev/null 2>"$TMP_ROOT/gen.err"; then
    echo "ERROR: fixture generation failed:" >&2
    sed 's/^/    /' "$TMP_ROOT/gen.err" >&2
    exit 1
fi
[[ -s "$LOGFILE" ]] || { echo "ERROR: generated log is empty" >&2; exit 1; }

# Render one mode at the pinned width, ANSI-stripped, into a file. -oe omits
# empty buckets so a multi-day fixture at fine bucket sizes does not backfill a
# huge empty range; the folded LABELS (the invariant under test) are unaffected.
# Usage: render_mode <mode> <outfile>
render_mode() {
    local mode="$1" outfile="$2" stderrfile="$TMP_ROOT/$mode.err"
    set +e
    "$LTL" --disable-progress -pr "$mode" -bs 60 -oe --terminal-width "$WIDTH" "$LOGFILE" \
        2>"$stderrfile" | strip_ansi > "$outfile"
    local st=("${PIPESTATUS[@]}")
    set -e
    if [[ "${st[0]}" -ne 0 ]]; then
        echo "  FAIL  $current_scenario :: ltl exited ${st[0]} while rendering" >&2
        sed 's/^/        /' "$stderrfile" >&2
        fail=$((fail + 1)); failures+=("$current_scenario :: ltl render failed"); return 1
    fi
    [[ -s "$outfile" ]] || { echo "  FAIL  $current_scenario :: rendered output empty" >&2; fail=$((fail+1)); failures+=("$current_scenario :: empty render"); return 1; }
}

# Self-documenting assertion: runs the checker command; PASS on exit 0, FAIL
# otherwise, surfacing asserts/produced_by/contract and the checker output.
assert_command() {
    local command label asserts
    while [[ $# -gt 0 ]]; do
        case "$1" in
            command) command="$2"; shift 2 ;;
            label)   label="$2";   shift 2 ;;
            asserts) asserts="$2"; shift 2 ;;
            *) echo "assert_command: unknown field '$1'" >&2; exit 2 ;;
        esac
    done
    : "${command:?}"; : "${label:?}"; : "${asserts:?}"
    local out rc
    set +e
    out=$(eval "$command" 2>&1); rc=$?
    set -e
    if [[ "$rc" -eq 0 ]]; then
        echo "  PASS  $current_scenario :: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario :: $label"
        echo "        command:     $command"
        echo "        asserts:     $asserts"
        echo "        produced_by: $PRODUCED_BY"
        echo "        contract:    $CONTRACT"
        echo "$out" | sed 's/^/        | /'
        fail=$((fail + 1)); failures+=("$current_scenario :: $label")
    fi
}

check() { echo "$PERL '$CHECKER' --render '$1' --check '$2'${3:+ --mode '$3'}"; }

echo "Validating --profile rendered-label invariants (Issue #256)"
echo "Surfaces: timeline timestamp column + summary first/last-seen; width $WIDTH"
echo ""

# --- day-period modes: time-only labels, no weekday token --------------------
for mode in day workday workday-alt; do
    current_scenario="$mode"
    echo "[$current_scenario]"
    render="$TMP_ROOT/$mode.txt"
    render_mode "$mode" "$render" || { echo ""; continue; }

    assert_command \
        command "$(check "$render" time-only)" \
        label   "every timeline label is HH:MM with no weekday token" \
        asserts 'day/workday fold onto a 24h axis, so the timestamp column shows time-of-day only; no weekday token (Mon, Sun, ...) may appear on any row.'

    assert_command \
        command "$(check "$render" summary-folded "$mode")" \
        label   "summary first/last-seen render as folded time-of-day positions" \
        asserts 'Under a day-period fold the summary heading shows folded positions (HH:MM), never a calendar date.'

    if [[ "$mode" != "day" ]]; then
        assert_command \
            command "$(check "$render" no-excluded "$mode")" \
            label   "no excluded-day weekday token rendered" \
            asserts 'workday drops the weekend (Sat/Sun); workday-alt drops Fri/Sat. Even though labels are time-only, no excluded-day data should reach the timeline (the fold drops those rows).'
    fi
    echo ""
done

# --- week-period modes: weekday once, correct start, excluded suppressed -----
for mode in week week-alt workweek workweek-alt; do
    current_scenario="$mode"
    echo "[$current_scenario]"
    render="$TMP_ROOT/$mode.txt"
    render_mode "$mode" "$render" || { echo ""; continue; }

    assert_command \
        command "$(check "$render" weekday-once "$mode")" \
        label   "each included weekday appears exactly once (at its day boundary)" \
        asserts 'week/workweek prefix the weekday on the first bucket of each day and blank it on later rows; each included weekday must therefore appear exactly once, and the set must equal the mode included set.'

    assert_command \
        command "$(check "$render" first-weekday "$mode")" \
        label   "leftmost weekday label matches the week start" \
        asserts 'Default modes start the week on Monday (ISO); -alt modes start on Sunday. The first weekday label rendered must be that start day.'

    if [[ "$mode" == workweek* ]]; then
        assert_command \
            command "$(check "$render" no-excluded "$mode")" \
            label   "no excluded-day weekday token rendered" \
            asserts 'workweek renders only Mon-Fri (no Sat/Sun); workweek-alt renders only Sun-Thu (no Fri/Sat).'
    fi

    assert_command \
        command "$(check "$render" summary-folded "$mode")" \
        label   "summary first/last-seen render as folded weekday positions" \
        asserts 'Under a week-period fold the summary heading shows folded positions with a weekday token (Wkd HH:MM), never a calendar date.'
    echo ""
done

echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do echo "  - $f"; done
    exit 1
fi
echo "ALL PROFILE RENDER TESTS PASSED"
