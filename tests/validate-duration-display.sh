#!/usr/bin/env bash
# validate-duration-display.sh — render-invariant harness for duration-statistic
# display in ltl's terminal output (Issue #292).
#
# This is a RENDER-INVARIANT harness (tests/HARNESS-DESIGN.md § Render-invariant
# harnesses): the system under test is the rendered terminal surface itself, not
# internal state. It runs ltl at a pinned --terminal-width, strips ANSI, and
# asserts that every duration cell on both display surfaces — the timeline rows
# (P50/P95/P99/P999) and the summary table (Min/P50/P99.9) — obeys the invariants
# the rendered surface must hold to. -V supplies the EXPECTED precision/unit; the
# stripped render supplies the ACTUAL; the assertion compares them.
#
# Each assertion records, per HARNESS-DESIGN.md § Self-documenting assertions:
#   - asserts:     the render invariant being tested
#   - produced_by: where in ltl the rendered value is produced (function name)
#   - contract:    the source that makes the invariant stable
# All three are surfaced on failure alongside the failing command.
#
# Usage: ./tests/validate-duration-display.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"
CHECKER="$SCRIPT_DIR/duration-display/check-duration-cells.pl"
ACCESS_LOG="$REPO_DIR/logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt"
PERL="${PERL:-/opt/homebrew/bin/perl}"
command -v "$PERL" >/dev/null 2>&1 || PERL=perl

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"; exit 1
fi
if [[ ! -f "$CHECKER" ]]; then
    echo "ERROR: checker not found at $CHECKER"; exit 1
fi
if [[ ! -f "$ACCESS_LOG" ]]; then
    echo "ERROR: ACCESS_LOG not found: $ACCESS_LOG"; exit 1
fi

# All transient artifacts (rendered captures, the CSV files -o emits while we
# read the resolved-precision -V line) live in a temp dir cleaned on exit
# (HARNESS-DESIGN.md Trap 9/10).
TMP_DIR=$(mktemp -d); trap 'rm -rf "$TMP_DIR"' EXIT

pass=0
fail=0
failures=()
current_scenario=""

strip_ansi() { sed -E 's/\x1b\[[0-9;]*m//g'; }

# Capture ltl's ANSI-stripped rendered output for a scenario into a file.
# Args after the function name are forwarded verbatim before the input file.
capture_render() {
    local outfile="$1"; shift
    local stderrfile="$TMP_DIR/render.stderr"
    set +e
    "$LTL" --disable-progress "$@" "$ACCESS_LOG" 2>"$stderrfile" | strip_ansi > "$outfile"
    local st=("${PIPESTATUS[@]}")
    set -e
    if [[ "${st[0]}" -ne 0 ]]; then
        echo "  FAIL  $current_scenario :: ltl exited ${st[0]} while rendering" >&2
        sed 's/^/        /' "$stderrfile" >&2
        fail=$((fail + 1)); failures+=("$current_scenario :: ltl render failed"); return 1
    fi
    if [[ ! -s "$outfile" ]]; then
        echo "  FAIL  $current_scenario :: rendered output is empty" >&2
        fail=$((fail + 1)); failures+=("$current_scenario :: empty render"); return 1
    fi
}

# Read the resolved duration unit and the duration-family decimal count from the
# csv-output -V section. -o is required: the precision block is gated on
# csv_active. The emitted CSVs are transient and cleaned with TMP_DIR.
# Echoes "<unit> <decimals>".
read_resolved_precision() {
    local model="$1"
    local vfile="$TMP_DIR/csv-output.v"
    ( cd "$TMP_DIR" && "$LTL" --disable-progress -V csv-output -dm "$model" -o "$ACCESS_LOG" ) > "$vfile" 2>&1 || true

    local unit decimals
    unit=$(grep -aE '^duration_unit_resolved:' "$vfile" | awk '{print $2}')
    decimals=$(grep -aE '^decimals_duration:' "$vfile" | awk '{print $2}')
    if [[ -z "$unit" ]]; then
        echo "  FAIL  $current_scenario :: missing 'duration_unit_resolved' anchor in -V csv-output" >&2
        fail=$((fail + 1)); failures+=("$current_scenario :: missing duration_unit_resolved"); return 1
    fi
    if [[ -z "$decimals" ]]; then
        echo "  FAIL  $current_scenario :: missing 'decimals_duration' anchor in -V csv-output" >&2
        fail=$((fail + 1)); failures+=("$current_scenario :: missing decimals_duration"); return 1
    fi
    echo "$unit $decimals"
}

# Self-documenting assertion (assert_command shape, HARNESS-DESIGN.md § 382):
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

# One scenario = one data model, one terminal width. Drives ltl, reads the
# resolved precision from -V, then runs the three render invariants.
run_scenario() {
    local model="$1" width="$2"
    current_scenario="dm-$model-w$width"
    echo "[$current_scenario]"

    local prec unit decimals
    prec=$(read_resolved_precision "$model") || return 0
    unit=${prec%% *}; decimals=${prec##* }

    local render="$TMP_DIR/render-$model-$width.txt"
    capture_render "$render" -dm "$model" --terminal-width "$width" || return 0

    assert_command \
        command     "$PERL '$CHECKER' --render '$render' --expected-decimals '$decimals' --resolved-unit '$unit' --check unit" \
        label       "every duration cell carries a unit ($unit) on both surfaces" \
        asserts     'Every populated duration cell in the summary table (Min/P50/P99.9) and the timeline (P50/P95/P99/P999) renders as <number><unit>; no value prints bare. This is the invariant Bug 2 violated, where small magnitudes (e.g. 58, 166, 1) printed with no unit.' \
        produced_by 'format_duration() in ltl — the single helper both surfaces route through; always passes through format_time so a unit is always present (no length>=4 bare-number bypass).' \
        contract    'Issue #292 + tests/HARNESS-DESIGN.md § Render-invariant harnesses. format_duration() is the locked rendering entry point for duration cells.'

    assert_command \
        command     "$PERL '$CHECKER' --render '$render' --expected-decimals '$decimals' --resolved-unit '$unit' --check zero" \
        label       "zero renders as 0$unit (resolved unit), never bare or auto-scaled" \
        asserts     'A zero duration renders in the resolved source unit (0ms for a ms source), never bare 0 and never auto-scaled down to 0us. format_time would scale 0 to the smallest unit; format_duration special-cases zero to the resolved unit.' \
        produced_by 'format_duration() in ltl — the `return "0$unit" if $value == 0` zero special-case.' \
        contract    'Issue #292 + tests/HARNESS-DESIGN.md § Render-invariant harnesses.'

    assert_command \
        command     "$PERL '$CHECKER' --render '$render' --expected-decimals '$decimals' --resolved-unit '$unit' --check precision" \
        label       "no cell shows finer precision than the resolved unit ($decimals decimals in $unit)" \
        asserts     'No duration cell still displayed in the resolved source unit shows more fractional digits than that unit can resolve (a ms source shows 0 decimals: 58ms not 58.2ms). The expected precision is read from -V csv-output decimals_duration; the actual is read from the render. This is the invariant Bug 1 violated via bin-counter interpolation synthesizing sub-grid values.' \
        produced_by 'format_duration() in ltl — rounds to %duration_display_decimals{resolved-unit} before format_time auto-scales.' \
        contract    'Issue #292 + tests/HARNESS-DESIGN.md § Render-invariant harnesses (-V supplies the expected precision; the render supplies the actual).'
}

echo "Validating duration-statistic display invariants (Issue #292)"
echo "Surfaces: timeline rows (P50/P95/P99/P999) + summary table (Min/P50/P99.9)"
echo ""

# -dm bin and -dm raw drive BOTH the per-message-key (summary table) and the
# per-time-bucket (timeline) surfaces together via the omnibus fan-out in
# resolve_data_model(); exercising both confirms the invariants hold on every
# percentile path and that the fan-out reaches both surfaces.
for model in bin raw; do
    for width in 200 120; do
        run_scenario "$model" "$width"
        echo ""
    done
done

echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do echo "  - $f"; done
    exit 1
fi
echo "ALL DURATION-DISPLAY TESTS PASSED"
