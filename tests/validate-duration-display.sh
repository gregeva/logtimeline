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
# Apache HTTP2 access log: the %D trailing field is request duration in genuine
# microseconds, so -du us resolves to a microsecond source (6 decimals). Used to
# cover a non-ms resolved unit.
APACHE_LOG="$REPO_DIR/logs/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log"
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
if [[ ! -f "$APACHE_LOG" ]]; then
    echo "ERROR: APACHE_LOG not found: $APACHE_LOG"; exit 1
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
# Usage: capture_render <outfile> <fixture> <ltl-args...>
capture_render() {
    local outfile="$1"; shift
    local fixture="$1"; shift
    local stderrfile="$TMP_DIR/render.stderr"
    set +e
    "$LTL" --disable-progress "$@" "$fixture" 2>"$stderrfile" | strip_ansi > "$outfile"
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

# Read the resolved duration unit from the csv-output -V section. -o is
# required: the precision block is gated on csv_active. The emitted CSVs are
# transient and cleaned with TMP_DIR. The display precision rule is a function
# of displayed-unit vs this resolved unit, so only the unit is needed.
# Usage: read_resolved_unit <fixture> <ltl-args...>  — echoes "<unit>".
read_resolved_unit() {
    local fixture="$1"; shift
    local vfile="$TMP_DIR/csv-output.v"
    ( cd "$TMP_DIR" && "$LTL" --disable-progress -V csv-output "$@" -o "$fixture" ) > "$vfile" 2>&1 || true

    local unit
    unit=$(grep -aE '^duration_unit_resolved:' "$vfile" | awk '{print $2}')
    if [[ -z "$unit" ]]; then
        echo "  FAIL  $current_scenario :: missing 'duration_unit_resolved' anchor in -V csv-output" >&2
        fail=$((fail + 1)); failures+=("$current_scenario :: missing duration_unit_resolved"); return 1
    fi
    echo "$unit"
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

# One scenario = one fixture, one width, one set of model/unit args. Drives ltl,
# reads the resolved precision from -V (using the same model/unit args), then
# runs the three render invariants.
# Usage: run_scenario <tag> <fixture> <width> <model-and-unit-args...>
run_scenario() {
    local tag="$1"; shift
    local fixture="$1"; shift
    local width="$1"; shift
    local -a model_args=("$@")
    current_scenario="$tag"
    echo "[$current_scenario]"

    local unit
    unit=$(read_resolved_unit "$fixture" "${model_args[@]}") || return 0

    local render="$TMP_DIR/render-$tag.txt"
    capture_render "$render" "$fixture" "${model_args[@]}" --terminal-width "$width" || return 0

    assert_command \
        command     "$PERL '$CHECKER' --render '$render' --resolved-unit '$unit' --check unit" \
        label       "every duration cell carries a unit ($unit source) on both surfaces" \
        asserts     'Every populated duration cell in the summary table (Min/P50/P99.9) and the timeline (P50/P95/P99/P999) renders as <number><unit>; no value prints bare. This is the invariant Bug 2 violated, where small magnitudes (e.g. 58, 166, 1) printed with no unit.' \
        produced_by 'format_duration() in ltl — the single helper both surfaces route through; always passes through format_time so a unit is always present (no length>=4 bare-number bypass).' \
        contract    'Issue #292 + tests/HARNESS-DESIGN.md § Render-invariant harnesses. format_duration() is the locked rendering entry point for duration cells.'

    assert_command \
        command     "$PERL '$CHECKER' --render '$render' --resolved-unit '$unit' --check zero" \
        label       "zero renders as 0$unit (resolved unit), never bare or auto-scaled" \
        asserts     'A zero duration renders in the resolved source unit (0ms for a ms source), never bare 0 and never auto-scaled down to 0us. format_time would scale 0 to the smallest unit; format_duration special-cases zero to the resolved unit.' \
        produced_by 'format_duration() in ltl — the `return "0$unit" if $value == 0` zero special-case.' \
        contract    'Issue #292 + tests/HARNESS-DESIGN.md § Render-invariant harnesses.'

    assert_command \
        command     "$PERL '$CHECKER' --render '$render' --resolved-unit '$unit' --check precision" \
        label       "<=1 decimal everywhere; 0 decimals when displayed in the source unit ($unit)" \
        asserts     'Duration cells follow the display precision rule: (a) at most one fractional digit on any cell (ltls one-decimal display convention); (b) zero fractional digits when a cell is displayed in the source resolution unit, since one decimal there fabricates sub-unit precision the input never had (a ms source shows 58ms not 58.2ms — Bug 1). A value that auto-scales to a coarser unit (ms source -> 1.2s; us source -> 47.2ms) legitimately keeps its single decimal. Applies to duration cells only; CV and other columns have their own formatting regime and are not extracted.' \
        produced_by 'format_duration() in ltl — rounds the ms-valued statistic to %duration_display_decimals{resolved-unit} before format_time auto-scales and applies its single-decimal render.' \
        contract    'Issue #292 + tests/HARNESS-DESIGN.md § Render-invariant harnesses. The precision rule is a function of displayed-unit vs resolved-unit (read from -V duration_unit_resolved).'
}

echo "Validating duration-statistic display invariants (Issue #292)"
echo "Surfaces: timeline rows (P50/P95/P99/P999) + summary table (Min/P50/P99.9)"
echo ""

# -dm bin and -dm raw drive BOTH the per-message-key (summary table) and the
# per-time-bucket (timeline) surfaces together via the omnibus fan-out in
# resolve_data_model(); exercising both confirms the invariants hold on every
# percentile path and that the fan-out reaches both surfaces. The ms-resolved
# source (default unit) is the case Bug 1/Bug 2 surfaced on.
for model in bin raw; do
    for width in 200 120; do
        run_scenario "dm-$model-w$width" "$ACCESS_LOG" "$width" -dm "$model"
        echo ""
    done
done

# Microsecond-resolved source: the Apache HTTP2 %D field is genuine microseconds,
# so -du us resolves the duration unit to us (6 decimals). This covers a non-ms
# resolved unit and exercises the precision invariant's other side — values that
# auto-scale to a coarser display unit (ms) carry no synthesized precision and
# must NOT be flagged, even though the source unit permits 6 decimals.
run_scenario "du-us-bin-w200" "$APACHE_LOG" 200 -dm bin -du us
echo ""

echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do echo "  - $f"; done
    exit 1
fi
echo "ALL DURATION-DISPLAY TESTS PASSED"
