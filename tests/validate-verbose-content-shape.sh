#!/usr/bin/env bash
# validate-verbose-content-shape.sh — every -V section follows one content
# shape (tests/HARNESS-DESIGN.md § Content shape): snake_case keys, "-" for an
# absent value, a key with nothing after its colon only as the heading of the
# facts indented beneath it, and bulk records tab-separated.
#
# The runs below request every registered section (the registry is read from
# `ltl -V list`, so a section added later is covered without editing this
# file); the checker, tests/lib/verbose-content-shape.pl, reads every line of
# every section and fails on a departure, and fails on a registered section no
# run emitted.
#
# Each assertion records, per tests/HARNESS-DESIGN.md § Self-documenting
# assertions: asserts, produced_by (function name), contract.
#
# Usage: ./tests/validate-verbose-content-shape.sh [--list | --scenario NAME]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"
CHECKER="$SCRIPT_DIR/lib/verbose-content-shape.pl"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"

neutralize_colour_env

# An access log with durations, sizes, users and a two-day span: every
# section has something to report on it.
FIXTURE="$REPO_DIR/tests/fixtures/tomcat-access-duration-spread.txt"
CONTRACT='tests/HARNESS-DESIGN.md section Content shape; features/605-input-units.md section 4 D25 to D29'

pass=0
fail=0
failures=()
current_scenario=""

pass_with() { echo "  PASS  $current_scenario :: $1"; pass=$((pass + 1)); }
fail_with() {
    local label="$1" asserts="$2" produced_by="$3"
    shift 3
    echo "  FAIL  $current_scenario :: $label"
    echo "        asserts:     $asserts"
    echo "        produced_by: $produced_by"
    echo "        contract:    $CONTRACT"
    local d
    for d in "$@"; do echo "        $d"; done
    fail=$((fail + 1))
    failures+=("$current_scenario :: $label")
}

# run_capture <tag> <args...>: one ltl run in its own directory (-o writes
# there); stdout to $TMP_DIR/<tag>.out. A failed run or a Perl runtime warning
# is a failure.
run_capture() {
    local tag="$1"; shift
    local dir="$TMP_DIR/$tag"; mkdir -p "$dir"
    local rc=0
    ( cd "$dir" && "$LTL" --disable-progress "$@" ) > "$TMP_DIR/$tag.out" 2> "$TMP_DIR/$tag.err" || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        fail_with "run $tag" 'Every capture run completes' 'ltl' "exit: $rc" "stderr: $(tr '\n' '|' < "$TMP_DIR/$tag.err")"
        return 1
    fi
    if ! assert_no_runtime_warnings "$TMP_DIR/$tag.err" "$current_scenario/$tag"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: $tag perl-runtime-warnings-on-stderr")
    fi
}

# ---------------------------------------------------------------------------
# Every registered section, on two runs: the first carries a heatmap, a
# histogram on the bin data model, grouping, user-defined metrics (a byte
# maximum and a distinct count), the exports, a duration bound and a
# highlight; the second the raw data model's histogram and a profile fold.
# ---------------------------------------------------------------------------
scenario_every_section() {
    current_scenario="every-section"
    echo "[$current_scenario]"
    local registered
    "$LTL" --disable-progress -V list > "$TMP_DIR/list.out" 2> "$TMP_DIR/list.err" || true
    if ! assert_no_runtime_warnings "$TMP_DIR/list.err" "$current_scenario/list"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: list perl-runtime-warnings-on-stderr")
    fi
    registered=$(sed -n 's/^  \([a-z][a-z-]*\)  .*/\1/p' "$TMP_DIR/list.out" | paste -sd, -)
    if [[ -z "$registered" ]]; then
        fail_with "registered sections read" 'The section registry lists its sections under -V list' 'adapt_to_command_line_options() in ltl (-V list)' 'no section name read'
        return
    fi
    run_capture grouped -V -bs 1440 -hm duration -hg duration -g -o -cp 3 -dmin 1 -hdmin 50 -tp s \
        -udm 'size:B:max:/ (\d+) \d+$/' -udm 'agent::distinct:/"(\w+) /' "$FIXTURE" || return
    run_capture folded -ni -V -bs 60 -pr week -dm raw -hg bytes "$FIXTURE" || return
    local report="$TMP_DIR/shape.txt" rc=0
    perl "$CHECKER" --registered "$registered" "$TMP_DIR/grouped.out" "$TMP_DIR/folded.out" > "$report" || rc=$?
    local sections lines
    sections=$(sed -n 's/^SECTIONS\t//p' "$report"); lines=$(sed -n 's/^LINES\t//p' "$report")
    if [[ "$rc" -eq 0 ]]; then
        pass_with "every line of $sections sections ($lines lines) follows the content shape"
    else
        fail_with "content shape" \
            'Every line of every -V section is a key: value line with a snake_case key (or a heading, a blank line or a tab-separated record), absent values are -, and every registered section is emitted by one of the runs' \
            'the -V emitters in ltl (each section'"'"'s emit_*_verbose)' \
            "$(grep -v '^SECTIONS\|^LINES' "$report" | head -20 | tr '\n' '|')"
    fi
}

scenario_register every-section
scenario_parse_args "$@"

if [[ ! -x "$LTL" ]]; then echo "ERROR: ltl not found or not executable at $LTL"; exit 1; fi
if [[ ! -f "$FIXTURE" ]]; then echo "ERROR: fixture not found: $FIXTURE"; exit 1; fi

TMP_DIR=$(mktemp -d); trap 'rm -rf "$TMP_DIR"' EXIT

while read -r _scenario; do
    case "$_scenario" in
        every-section ) scenario_every_section ;;
    esac
done < <(scenario_selected)

echo
echo "Results: $pass passed, $fail failed"
if [[ "$pass" -eq 0 && "$fail" -eq 0 ]]; then echo "FAIL: no assertion ran"; exit 1; fi
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    printf '  %s\n' "${failures[@]}"
    exit 1
fi
exit 0
