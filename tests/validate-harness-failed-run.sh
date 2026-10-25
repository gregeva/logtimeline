#!/usr/bin/env bash
# validate-harness-failed-run.sh — every harness that runs ltl holds when the
# run it reads did not happen (tests/HARNESS-DESIGN.md § The failed-run
# checker, issue #747).
#
# One scenario per harness, named as the harness is without validate- and .sh.
# Each one checks the harness two ways:
#
#   1. Its source, read through bash's own parser by
#      process/check-harness-source.pl, for the three faults certain there: a
#      counting helper run inside $( ), a summary inside a scenario's block, a
#      grep or ls lookup assigned with no fallback.
#   2. A run of every scenario it registers against an ltl that prints nothing
#      and exits 1, one that prints nothing and exits 0, and one that prints
#      an unrelated line and exits 0, read by
#      process/check-harness-capture.pl: the summary is reached, the exit
#      status is not 0, the PASS lines number as many as the passed count, and
#      every PASS line is marked run-free.
#
# A harness that runs no ltl (it never names LTL) is not checked, nor is this
# one. The stubs are made in a temporary directory and named by their absolute
# paths. A harness change passes its scenario here before it is committed.
#
# Usage: ./tests/validate-harness-failed-run.sh [--scenario <harness>]... [--list]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PERL="${PERL:-perl}"
SOURCE_CHECKER="$REPO_DIR/process/check-harness-source.pl"
CAPTURE_CHECKER="$REPO_DIR/process/check-harness-capture.pl"

# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"

neutralize_colour_env

for f in "$SOURCE_CHECKER" "$CAPTURE_CHECKER"; do
    [[ -f "$f" ]] || { echo "ERROR: required file missing: $f" >&2; exit 1; }
done

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

pass=0
fail=0
failures=()
current_scenario=""

CONTRACT='tests/HARNESS-DESIGN.md section The failed-run checker - a check made against a run that did not happen is skipped, its cause counted once, and the harness reaches its summary (Traps 12 and 13)'

pass_with() { echo "  PASS  $current_scenario :: $1 [run-free: $2]"; pass=$((pass + 1)); }
fail_with() {   # label, asserts, produced_by, detail
    echo "  FAIL  $current_scenario :: $1"
    echo "        asserts:     $2"
    echo "        produced_by: $3"
    echo "        contract:    $CONTRACT"
    [[ -n "${4:-}" ]] && echo "$4" | sed 's/^/        | /'
    fail=$((fail + 1)); failures+=("$current_scenario :: $1")
    return 0
}

# The three stubs: two-line Perl scripts, each in a directory of its own.
for stub in failing:1 silent:0; do
    mkdir -p "$TMP_DIR/${stub%%:*}"
    printf '#!/usr/bin/env perl\nexit %s;\n' "${stub#*:}" > "$TMP_DIR/${stub%%:*}/ltl"
    chmod +x "$TMP_DIR/${stub%%:*}/ltl"
done
mkdir -p "$TMP_DIR/noise"
printf '#!/usr/bin/env perl\nprint "an unrelated line\\n";\n' > "$TMP_DIR/noise/ltl"
chmod +x "$TMP_DIR/noise/ltl"

# The harnesses checked: every tests/validate-*.sh that names LTL, this one
# excepted.
harnesses=()
for h in "$SCRIPT_DIR"/validate-*.sh; do
    name="$(basename "$h" .sh)"
    name="${name#validate-}"
    [[ "$name" == harness-failed-run ]] && continue
    grep -qw 'LTL' "$h" || continue
    harnesses+=("$name")
done

SCENARIO_USAGE_NOTE="  (one per harness that runs ltl)"
scenario_register "${harnesses[@]}"
scenario_parse_args "$@"

echo "Validating every harness against a run that did not happen (issue #747)"
echo ""

# The faults the source holds: one check per rule.
check_source() {
    local harness="$1" report="$TMP_DIR/$current_scenario.source"
    "$PERL" "$SOURCE_CHECKER" "$harness" > "$report" 2>&1 || true
    if grep -q ': unreadable: ' "$report"; then
        fail_with 'the source reads as bash' \
            'bash parses the harness, so its source can be read for the three faults' \
            'process/check-harness-source.pl' "$(cat "$report")"
        return 0
    fi
    local rule label
    for rule in counted-in-subshell summary-in-scenario lookup-no-fallback; do
        case "$rule" in
            counted-in-subshell) label='no helper that counts a check runs inside $( ), <( ) or backticks' ;;
            summary-in-scenario) label="the summary prints outside every scenario's block" ;;
            lookup-no-fallback)  label='every grep or ls lookup assigned to a variable has a fallback' ;;
        esac
        if grep -q ": $rule: " "$report"; then
            fail_with "$label" "$label (tests/HARNESS-DESIGN.md section The failed-run checker, rule $rule)" \
                'process/check-harness-source.pl' "$(grep ": $rule: " "$report" | sed 's/^[^:]*: //')"
        else
            pass_with "$label" "the harness source"
        fi
    done
}

# Every scenario the harness registers, as --scenario arguments, in
# $scenario_args; empty when --list names none. The names are the one-word
# lines after "Scenarios:"; a note the harness prints under them is not one.
scenario_args=()
read_scenarios() {
    local harness="$1" name
    scenario_args=()
    while read -r name; do
        scenario_args+=(--scenario "$name")
    done < <("$harness" --list 2>/dev/null | awk '/^Scenarios:/ { s = 1; next } s && /^  [^[:space:]]+$/ { print $1; next } s { exit }')
}

# What a stub does, as a failure message names it.
stub_behaviour() {
    case "$1" in
        failing) echo 'exits 1 having printed nothing' ;;
        silent)  echo 'exits 0 having printed nothing' ;;
        noise)   echo 'exits 0 having printed an unrelated line' ;;
    esac
}

# One run of the harness against a stub, read by the capture checker.
check_stub_run() {
    local harness="$1" stub="$2"
    local capture="$TMP_DIR/$current_scenario.$stub.out" rc=0
    ( cd "$REPO_DIR" && LTL="$TMP_DIR/$stub/ltl" "$harness" "${scenario_args[@]}" ) > "$capture" 2>&1 || rc=$?
    echo "$rc" > "$capture.rc"
    local summary exit_status passed failed pass_lines unmarked
    IFS=$'\t' read -r _ summary exit_status passed failed pass_lines unmarked \
        < <("$PERL" "$CAPTURE_CHECKER" --brief "$capture" || true)
    local runs="against the $stub stub"
    if [[ "$summary" == yes ]]; then
        pass_with "$runs: the summary is reached" "a run of the harness against the $stub stub"
    else
        fail_with "$runs: the summary is reached" \
            "The harness reaches its summary when ltl $(stub_behaviour "$stub"): no step ends it early (shape 13, Trap 12)" \
            'the harness' "$(tail -5 "$capture")"
        return 0
    fi
    if [[ "$exit_status" != 0 ]]; then
        pass_with "$runs: the harness exits $exit_status, not 0" "a run of the harness against the $stub stub"
    else
        fail_with "$runs: the harness exits non-zero" \
            'A harness whose ltl did not run fails: every run it makes is a counted failure' \
            'the harness' "$(tail -3 "$capture")"
    fi
    if [[ -n "$passed" && "$passed" == "$pass_lines" ]]; then
        pass_with "$runs: $pass_lines PASS lines, as many as the passed count" "a run of the harness against the $stub stub"
    else
        fail_with "$runs: as many PASS lines as the passed count" \
            'Each counted pass prints its PASS line: a counter advanced without a check, or a check that printed no line, is a mismatch (Trap 6, shape 12)' \
            'the harness' "summary counts ${passed:-?} passed; $pass_lines PASS lines"
    fi
    if [[ "$unmarked" == 0 ]]; then
        pass_with "$runs: every PASS line is marked run-free" "a run of the harness against the $stub stub"
    else
        fail_with "$runs: every PASS line is marked run-free" \
            'A check that passes when ltl did not run reads nothing a run produced, and its PASS line says what it read; any other is a check that holds on a run that did not happen (Trap 13)' \
            'the harness' "$("$PERL" "$CAPTURE_CHECKER" "$capture" | sed -n '/^unmarked:/,$p' | sed -n '2,6p')"
    fi
}

while read -r _scenario; do
    current_scenario="$_scenario"
    echo "[$current_scenario]"
    harness="$SCRIPT_DIR/validate-$_scenario.sh"
    check_source "$harness"
    read_scenarios "$harness"
    if [[ ${#scenario_args[@]} -eq 0 ]]; then
        fail_with 'its --list names its scenarios' \
            'The harness registers its scenarios, so every one of them is run against the stubs' \
            'tests/lib/scenario-select.sh' "$("$harness" --list 2>&1 | head -5)"
    else
        check_stub_run "$harness" failing
        check_stub_run "$harness" silent
        check_stub_run "$harness" noise
    fi
    echo ""
done < <(scenario_selected)

echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do echo "  - $f"; done
    exit 1
fi
echo "EVERY HARNESS HOLDS ON A RUN THAT DID NOT HAPPEN, OR PRINTED SOMETHING UNRELATED"
