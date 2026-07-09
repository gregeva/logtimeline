#!/usr/bin/env bash
# validate-numeric-criteria-notices.sh — harness for the user-facing notices
# ltl emits about its numeric criteria (the -dmin/-dmax/-bmin/-bmax/-cmin/-cmax
# filters and the -hdmin/-hdmax/-hbmin/-hbmax/-hcmin/-hcmax highlight ranges).
#
# The system under test is the stderr messaging surface: when a numeric filter
# excludes lines because they carry no value for the filtered metric, ltl must
# say so (and how many); when nothing was excluded that way, it must stay
# silent. These notices exist so a numeric filter can never silently shrink
# the analyzed population beyond what the threshold explains.
#
# Each assertion records, per HARNESS-DESIGN.md § Self-documenting assertions:
#   - asserts:     the messaging invariant being tested
#   - produced_by: where in ltl the message is produced (function name)
#   - contract:    the source that makes the invariant stable
# All three are surfaced on failure alongside the failing command.
#
# Usage: ./tests/validate-numeric-criteria-notices.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"
# Boundary fixture: exactly one line lacks a duration value (BD-dur-missing),
# one lacks bytes (BD-bytes-missing), one lacks count (BD-count-missing);
# every other line carries all three metrics.
BOUNDARY_FIXTURE="$REPO_DIR/tests/fixtures/numeric-highlight-boundary.txt"
# Access log on which every line carries a duration value.
ACCESS_LOG="$REPO_DIR/logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt"

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"; exit 1
fi
if [[ ! -f "$BOUNDARY_FIXTURE" ]]; then
    echo "ERROR: fixture not found: $BOUNDARY_FIXTURE"; exit 1
fi
if [[ ! -f "$ACCESS_LOG" ]]; then
    echo "ERROR: access log not found: $ACCESS_LOG"; exit 1
fi

TMP_DIR=$(mktemp -d); trap 'rm -rf "$TMP_DIR"' EXIT

pass=0
fail=0
failures=()
current_scenario=""

# Run ltl and capture stderr for notice assertions. Fails hard if ltl itself
# fails (HARNESS-DESIGN.md Trap 1: never let a crashed run read as "no notice").
# Usage: capture_stderr <stderr-outfile> <ltl-args-and-fixture...>
capture_stderr() {
    local errfile="$1"; shift
    local stdoutfile="$TMP_DIR/run.stdout"
    set +e
    # Run inside TMP_DIR so cwd artifacts (ltl-index.csv) never land in the
    # repo (HARNESS-DESIGN.md Trap 9: temp artifacts stay out of deliverables).
    ( cd "$TMP_DIR" && "$LTL" --disable-progress "$@" ) > "$stdoutfile" 2>"$errfile"
    local rc=$?
    set -e
    if [[ "$rc" -ne 0 ]]; then
        echo "  FAIL  $current_scenario :: ltl exited $rc" >&2
        sed 's/^/        /' "$errfile" >&2
        fail=$((fail + 1)); failures+=("$current_scenario :: ltl run failed"); return 1
    fi
    if [[ ! -s "$stdoutfile" ]]; then
        echo "  FAIL  $current_scenario :: ltl produced no output" >&2
        fail=$((fail + 1)); failures+=("$current_scenario :: empty ltl output"); return 1
    fi
}

# Self-documenting assertion (assert_command shape, HARNESS-DESIGN.md):
# runs `command`; PASS on exit 0, FAIL otherwise. On failure surfaces the
# command plus asserts/produced_by/contract.
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

MISSING_METRIC_CONTRACT='docs/usage.md § Filtering & Highlighting — numeric filters only keep entries that carry the filtered metric; the count of entries excluded this way is reported (Issue #321)'

# --- Scenario: one missing-metric note per filtered metric, with exact count ---
current_scenario="missing-metric-notes"
echo "[$current_scenario]"
errfile="$TMP_DIR/missing-metric.stderr"
if capture_stderr "$errfile" -bs 240 -n 25 -dmin 1 -bmin 1 -cmin 1 "$BOUNDARY_FIXTURE"; then
    for metric in duration bytes count; do
        assert_command \
            command     "grep -aq 'Note: 1 lines carried no $metric value and were excluded by the $metric filter' '$errfile'" \
            label       "exactly-one-line note for the $metric filter" \
            asserts     "When a numeric $metric filter is active and a line carries no $metric value, the line is excluded and the post-processing note reports the exact number of lines excluded that way (the fixture contains exactly one such line per metric)" \
            produced_by 'read_and_process_logs() in ltl (numeric threshold guards + end-of-processing note emission)' \
            contract    "$MISSING_METRIC_CONTRACT"
    done
    assert_command \
        command     "[ \"\$(grep -ac '^Note:' '$errfile')\" -eq 3 ]" \
        label       'exactly three notes emitted (one per filtered metric)' \
        asserts     'The missing-metric note is emitted once per metric whose filter excluded at least one metric-less line — never duplicated, never merged' \
        produced_by 'read_and_process_logs() in ltl (end-of-processing note emission)' \
        contract    "$MISSING_METRIC_CONTRACT"
fi

# --- Scenario: silent when every line carries the filtered metric ---
current_scenario="silent-when-metric-present"
echo "[$current_scenario]"
errfile="$TMP_DIR/all-carry.stderr"
if capture_stderr "$errfile" -bs 240 -n 25 -dmin 1 "$ACCESS_LOG"; then
    assert_command \
        command     "! grep -aq 'carried no .* value and were excluded' '$errfile'" \
        label       'no missing-metric note when every line carries the metric' \
        asserts     'The missing-metric note only appears when at least one line was excluded for lacking the filtered metric; a filter that excluded nothing that way stays silent' \
        produced_by 'read_and_process_logs() in ltl (end-of-processing note emission)' \
        contract    "$MISSING_METRIC_CONTRACT"
fi

# --- Scenario: silent when no numeric filter is active ---
current_scenario="silent-without-numeric-filters"
echo "[$current_scenario]"
errfile="$TMP_DIR/no-filters.stderr"
if capture_stderr "$errfile" -bs 240 -n 25 "$BOUNDARY_FIXTURE"; then
    assert_command \
        command     "! grep -aq 'carried no .* value and were excluded' '$errfile'" \
        label       'no missing-metric note without numeric filters' \
        asserts     'Metric-less lines are kept (and produce no note) when no numeric filter is active; the note is tied to the filters, not to the data shape' \
        produced_by 'read_and_process_logs() in ltl (numeric threshold guards)' \
        contract    "$MISSING_METRIC_CONTRACT"
fi

echo
echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    printf '  failed: %s\n' "${failures[@]}"
    exit 1
fi
exit 0
