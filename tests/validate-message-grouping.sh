#!/usr/bin/env bash
# validate-message-grouping.sh — harness for the message-grouping -V section.
#
# The system under test is the threshold message grouping (-g) applies in its
# final pass. The final pass scores at the sensitivity the run resolved from
# -g (or its default), unless --final-threshold is given explicitly, and the
# section header reports the threshold the final pass used.
#
# The fixture's four request paths are each requested three times, so every
# key reaches the occurrence ceiling, streaming discovery skips it, and only
# the final pass can group them. They form two pairs at Dice 77 and Dice 89,
# so the number of patterns the final pass creates says which threshold it
# scored at.
#
# Each assertion records, per HARNESS-DESIGN.md § Self-documenting assertions:
#   - asserts:     the invariant being tested
#   - produced_by: where in ltl it is produced (function name)
#   - contract:    the source that makes the invariant stable
# All three are surfaced on failure alongside the failing command.
#
# Usage: ./tests/validate-message-grouping.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"

# Ambient FORCE_COLOR/NO_COLOR must not decide what this harness asserts
# against (tests/HARNESS-DESIGN.md section Colour rendering is controlled,
# never inherited).
neutralize_colour_env

FIXTURE="$REPO_DIR/tests/fixtures/grouping-final-pass-threshold.txt"

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

CONTRACT='features/fuzzy-message-consolidation.md § Final pass follows the sensitivity (#571) — acceptance criteria and the -V message-grouping keys asserted'
HEADER_PRODUCER='pipeline_finalize() in ltl (message-grouping header line)'
FINAL_PASS_PRODUCER='group_similar_messages() in ltl (final-pass threshold), counted per group by process_final_pass_window()'

# Run ltl, capture the message-grouping section, fail hard on a failed run, an
# empty capture, a missing section, or a runtime warning (HARNESS-DESIGN.md
# Trap 1, Trap 3 and Runtime-warning cleanliness).
# Usage: capture_section <outfile> <ltl-args...>
capture_section() {
    local outfile="$1"; shift
    local errfile="$outfile.stderr"
    set +e
    # Run inside TMP_DIR so cwd artifacts never land in the repo (Trap 9).
    ( cd "$TMP_DIR" && "$LTL" --disable-progress -ni "$@" ) > "$outfile" 2>"$errfile"
    local rc=$?
    set -e
    if [[ "$rc" -ne 0 ]]; then
        echo "  FAIL  $current_scenario :: ltl exited $rc" >&2
        sed 's/^/        /' "$errfile" >&2
        fail=$((fail + 1)); failures+=("$current_scenario :: ltl run failed"); return 1
    fi
    if ! grep -q '^=== message-grouping ===$' "$outfile" || ! grep -q '^=== END message-grouping ===$' "$outfile"; then
        echo "  FAIL  $current_scenario :: message-grouping section missing from $outfile" >&2
        fail=$((fail + 1)); failures+=("$current_scenario :: section missing"); return 1
    fi
    if ! assert_no_runtime_warnings "$errfile" "$current_scenario"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr"); return 1
    fi
}

# Self-documenting assertion (assert_command shape, HARNESS-DESIGN.md).
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

# Prints one counter from a group's phase block; exits non-zero when the block
# or the counter is absent (HARNESS-DESIGN.md Trap 4: a missing anchor is never
# an empty value).
# Usage: block_counter <file> <group> <Streaming Phase|Final Pass> <counter label>
block_counter() {
    awk -v grp="--- $2: $3" -v key="$4:" '
        index($0, "  --- ") == 1 { inblock = (index($0, grp) > 0) }
        inblock && index($0, key) { sub(/^.*: */, ""); split($0, v, " "); print v[1]; found = 1; exit }
        END { if (!found) exit 1 }
    ' "$1"
}

# Asserts the header thresholds, that all fixture keys reach the final pass,
# and the final pass's pattern count for one scenario.
# Usage: check_scenario <capture> <streaming T> <final-pass T> <expected patterns> <why>
check_scenario() {
    local out="$1" t="$2" f="$3" patterns="$4" why="$5"
    assert_command \
        command     "grep -Eq '^  Threshold: ${t}%  .*Final pass: on \\(threshold=${f}%,' '$out'" \
        label       "header reports sensitivity ${t}% and final pass at ${f}%" \
        asserts     "The message-grouping header reports the resolved -g sensitivity and the threshold the final pass scored at ($why)" \
        produced_by "$HEADER_PRODUCER" \
        contract    "$CONTRACT"
    assert_command \
        command     "[ \"\$(block_counter '$out' 'plain|200' 'Final Pass' 'Keys seen')\" = 4 ]" \
        label       'the final pass receives all 4 keys' \
        asserts     'Every fixture key reaches the occurrence ceiling, so streaming groups none of them and all 4 reach the final pass; any pattern counted in the final-pass block was formed there, at its own threshold' \
        produced_by 'group_similar_messages() in ltl (fp_keys_seen), after run_consolidation_pass() skips ceiling keys' \
        contract    "$CONTRACT"
    assert_command \
        command     "[ \"\$(block_counter '$out' 'plain|200' 'Final Pass' 'New patterns created')\" = $patterns ]" \
        label       "final pass creates $patterns pattern(s)" \
        asserts     "With pairs at Dice 77 and 89, a final pass scoring at ${f}% groups exactly $patterns pair(s) ($why)" \
        produced_by "$FINAL_PASS_PRODUCER" \
        contract    "$CONTRACT"
}

# Invocation shape (tests/HARNESS-DESIGN.md section Invocation coherence):
# every assertion reads the message-grouping section; one wide bucket, no empty
# buckets and a single reported row keep the rest of the run trivial.
SHAPE="-bs 1440 -oe -n 1 -V message-grouping"

current_scenario="sensitivity-70"
echo "[$current_scenario]"
out="$TMP_DIR/g70.out"
if capture_section "$out" $SHAPE -g 70 "$FIXTURE"; then
    check_scenario "$out" 70 70 2 'the final pass follows -g 70, so both the Dice 77 and Dice 89 pairs group'
fi

current_scenario="sensitivity-95"
echo "[$current_scenario]"
out="$TMP_DIR/g95.out"
if capture_section "$out" $SHAPE -g 95 "$FIXTURE"; then
    check_scenario "$out" 95 95 0 'the final pass follows -g 95, so neither pair groups'
fi

current_scenario="default-sensitivity"
echo "[$current_scenario]"
out="$TMP_DIR/gdefault.out"
# -g without a value takes the default sensitivity; -V follows so the option
# parser does not read the fixture path as the -g value.
if capture_section "$out" -bs 1440 -oe -n 1 -g -V message-grouping "$FIXTURE"; then
    check_scenario "$out" 85 85 1 'the final pass follows the default 85, so only the Dice 89 pair groups'
fi

current_scenario="explicit-final-threshold"
echo "[$current_scenario]"
out="$TMP_DIR/g95-final70.out"
if capture_section "$out" $SHAPE -g 95 --final-threshold 70 "$FIXTURE"; then
    check_scenario "$out" 95 70 2 'an explicit --final-threshold 70 overrides -g 95 for the final pass only'
fi

echo
echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    printf '  failed: %s\n' "${failures[@]}"
    exit 1
fi
exit 0
