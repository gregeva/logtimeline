#!/usr/bin/env bash
# validate-message-grouping-notices.sh — harness for the user-facing notices
# ltl emits about message grouping (-g) and what it costs the statistics the
# grouped rows carry.
#
# The system under test is the stderr messaging surface: when message grouping
# runs against the bin message-stats data model, every absorbed key's histogram
# is combined onto a shared bucket geometry, so the consolidated row's
# percentiles are answered from counts that were remapped once. The tool says
# so, and points at the data model that answers exactly. The notice exists so
# an accuracy-for-memory trade is never made on the user's behalf in silence.
#
# Each assertion records, per HARNESS-DESIGN.md § Self-documenting assertions:
#   - asserts:     the messaging invariant being tested
#   - produced_by: where in ltl the message is produced (function name)
#   - contract:    the source that makes the invariant stable
# All three are surfaced on failure alongside the failing command.
#
# Usage: ./tests/validate-message-grouping-notices.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib/logs-dir.sh
source "$SCRIPT_DIR/lib/logs-dir.sh"
LTL="$REPO_DIR/ltl"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"

# Ambient FORCE_COLOR/NO_COLOR must not decide what this harness asserts
# against (tests/HARNESS-DESIGN.md section Colour rendering is controlled,
# never inherited).
neutralize_colour_env

# Access log carrying repeated request paths that differ only in their
# parameters — the shape fuzzy grouping consolidates.
FIXTURE="$REPO_DIR/tests/fixtures/tomcat-access-duration-spread.txt"

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

# Run ltl and capture stderr for notice assertions. Fails hard if ltl itself
# fails (HARNESS-DESIGN.md Trap 1: never let a crashed run read as "no notice").
# Usage: capture_stderr <stderr-outfile> <ltl-args-and-fixture...>
capture_stderr() {
    local errfile="$1"; shift
    local stdoutfile="$TMP_DIR/run.stdout"
    set +e
    # Run inside TMP_DIR so cwd artifacts (ltl-index.csv) never land in the
    # repo (HARNESS-DESIGN.md Trap 9: temp artifacts stay out of deliverables).
    ( cd "$TMP_DIR" && "$LTL" --disable-progress -ni "$@" ) > "$stdoutfile" 2>"$errfile"
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
    # Runtime-warning cleanliness at the point of capture (HARNESS-DESIGN.md
    # section Runtime-warning cleanliness). The intentional notices this
    # harness asserts never carry the ` at <file> line <N>` suffix, so the
    # check and the notice assertions coexist on the same capture.
    if ! assert_no_runtime_warnings "$errfile" "$current_scenario"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
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

# Invocation shape (tests/HARNESS-DESIGN.md section Invocation coherence):
# every assertion reads a stderr notice; the rendered timeline and table are
# never consulted, so the run uses one wide bucket and a single reported row.
SHAPE="-bs 1440 -oe -n 1"

NOTICE_CONTRACT='docs/usage.md § Options — Stderr warnings: message grouping under the bin message-stats data model answers consolidated rows from histograms combined onto a shared bucket geometry, so their percentiles are approximate and the run says so, pointing at -mdm raw'

# --- Scenario: grouping on the bin data model announces the trade ---
current_scenario="grouped-bin-model-notice"
echo "[$current_scenario]"
errfile="$TMP_DIR/grouped-bin.stderr"
if capture_stderr "$errfile" $SHAPE -g 85 -mdm bin "$FIXTURE"; then
    assert_command \
        command     "grep -aq 'Note: consolidation combined [0-9,]* message histograms onto shared bucket geometries, so their percentiles are approximate - use -mdm raw for exact percentiles' '$errfile'" \
        label       'notice names the combination and the exact alternative' \
        asserts     'When message grouping runs under the bin message-stats data model and histograms were actually combined, the run reports how many were combined, states that the resulting percentiles are approximate, and names the data model that answers exactly' \
        produced_by 'bin_consolidation_notice() in ltl, called from pipeline_finalize() after group_similar_messages()' \
        contract    "$NOTICE_CONTRACT"
    assert_command \
        command     "[ \"\$(grep -ac 'percentiles are approximate' '$errfile')\" -eq 1 ]" \
        label       'emitted exactly once per run' \
        asserts     'The notice is a run-level statement about the analysis, not a per-cluster or per-file one, so a run that consolidates many keys still reports it once' \
        produced_by 'bin_consolidation_notice() in ltl, called from pipeline_finalize() after group_similar_messages()' \
        contract    "$NOTICE_CONTRACT"
fi

# --- Scenario: the exact data model is silent ---
current_scenario="grouped-raw-model-silent"
echo "[$current_scenario]"
errfile="$TMP_DIR/grouped-raw.stderr"
if capture_stderr "$errfile" $SHAPE -g 85 -mdm raw "$FIXTURE"; then
    assert_command \
        command     "! grep -aq 'percentiles are approximate' '$errfile'" \
        label       'no notice when the run already answers exactly' \
        asserts     'The raw message-stats data model holds every observed value, so grouping costs it no percentile accuracy and there is nothing to disclose' \
        produced_by 'bin_consolidation_notice() in ltl (capture-mode guard)' \
        contract    "$NOTICE_CONTRACT"
fi

# --- Scenario: the bin model without grouping is silent ---
current_scenario="ungrouped-bin-model-silent"
echo "[$current_scenario]"
errfile="$TMP_DIR/ungrouped-bin.stderr"
if capture_stderr "$errfile" $SHAPE -mdm bin "$FIXTURE"; then
    assert_command \
        command     "! grep -aq 'percentiles are approximate' '$errfile'" \
        label       'no notice when no row is consolidated' \
        asserts     'The notice is tied to grouping, not to the data model: an ungrouped bin run combines no histograms, so no percentile it reports carries a combination' \
        produced_by 'bin_consolidation_notice() in ltl (grouping guard)' \
        contract    "$NOTICE_CONTRACT"
fi

echo
echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    printf '  failed: %s\n' "${failures[@]}"
    exit 1
fi
exit 0
