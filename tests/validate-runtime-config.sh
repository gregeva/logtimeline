#!/usr/bin/env bash
# validate-runtime-config.sh — Validate ltl's runtime-config -V section
# and the silent-override warnings + hard-error paths exercised by
# adapt_to_command_line_options(). Three concerns covered:
#   1. The runtime-config -V section emits command-line and
#      environment-variable sub-sections per the locked contract.
#   2. Silent-override warnings fire on the documented sites
#      (-g non-numeric, -hm non-built-in without UDM).
#   3. Hard-error paths (-du / -ru / -so unknown enums; nonexistent
#      input file) exit non-zero with the documented diagnostic.
# Usage: ./tests/validate-runtime-config.sh
#
# Implements the self-documenting-assertion design from
# tests/HARNESS-DESIGN.md. Reference: tests/validate-histogram-bin-counters.sh.
#
# Per HARNESS-DESIGN.md § "Naming rules": harness file names track the
# section they validate. This harness validates the runtime-config
# section; the issue that produced it is #231 (sub-task of #225).

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
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"

# Ambient FORCE_COLOR/NO_COLOR must not decide what this harness asserts
# against (tests/HARNESS-DESIGN.md section Colour rendering is controlled,
# never inherited; issue #438).
neutralize_colour_env

# Invocation shape (tests/HARNESS-DESIGN.md section Invocation coherence): the
# -V runtime-config section echoes the resolved options, so -bs/-dmp/-mdm on
# each run ARE the subject; the 741-line, 4-hour fixture is already minimal.
TEST_LOG="$LOGS_DIR/Codebeamber/codebeamer_access_log.2025-10-29.txt"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"
    exit 1
fi
if [[ ! -f "$TEST_LOG" ]]; then
    echo "ERROR: test log not found: $TEST_LOG"
    exit 1
fi

pass=0
fail=0
failures=()
current_scenario=""

# Self-documenting assertion: a line matching `pattern` must be present.
# Required fields: pattern, asserts, produced_by, contract.
assert_line() {
    local outfile="$1"
    shift
    local pattern asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            pattern)     pattern="$2";     shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_line: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${pattern:?assert_line requires pattern}"
    : "${asserts:?assert_line requires asserts}"
    : "${produced_by:?assert_line requires produced_by}"
    : "${contract:?assert_line requires contract}"

    if grep -qE "$pattern" "$outfile"; then
        echo "  PASS  $current_scenario :: $pattern"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        pattern:     $pattern"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        echo "        (not found in $outfile)"
        fail=$((fail + 1))
        failures+=("$current_scenario :: $pattern")
    fi
}

# Self-documenting assertion: no line matching `pattern` is present.
assert_no_line() {
    local outfile="$1"
    shift
    local pattern asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            pattern)     pattern="$2";     shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_no_line: unknown field '$1'"; exit 2 ;;
        esac
    done

    if grep -qE "$pattern" "$outfile"; then
        echo "  FAIL  $current_scenario"
        echo "        pattern:     !$pattern (unexpectedly present)"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
        failures+=("$current_scenario :: !$pattern")
    else
        echo "  PASS  $current_scenario :: !$pattern"
        pass=$((pass + 1))
    fi
}

# Self-documenting equality assertion on exit code.
assert_exit() {
    local actual="$1"
    local expected="$2"
    shift 2
    local asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_exit: unknown field '$1'"; exit 2 ;;
        esac
    done

    if [[ "$actual" == "$expected" ]]; then
        echo "  PASS  $current_scenario :: exit=$actual"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        expected:    exit=$expected"
        echo "        actual:      exit=$actual"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
        failures+=("$current_scenario :: exit (expected=$expected actual=$actual)")
    fi
}

# Helper: run ltl, capture stdout + stderr to separate temp files,
# return their paths via globals $RUN_STDOUT, $RUN_STDERR, $RUN_EXIT.
RUN_STDOUT=""
RUN_STDERR=""
RUN_EXIT=0
run_ltl() {
    local label="$1"
    shift
    RUN_STDOUT="$TMP_DIR/${label}.stdout"
    RUN_STDERR="$TMP_DIR/${label}.stderr"
    set +e
    "$LTL" --disable-progress -ni "$@" > "$RUN_STDOUT" 2> "$RUN_STDERR"
    RUN_EXIT=$?
    set -e
    check_stderr_warnings "$RUN_STDERR"
}

# Runtime-warning cleanliness at the point of capture (HARNESS-DESIGN.md
# section Runtime-warning cleanliness). The intentional diagnostics this
# harness asserts (print_usage error blocks, silent-override warnings)
# never carry the ` at <file> line <N>` suffix, so the check and the
# stderr assertions coexist on the same capture. Runs in the main shell
# so the fail counters persist.
check_stderr_warnings() {
    local stderr_file="$1"
    if ! assert_no_runtime_warnings "$stderr_file" "$current_scenario"; then
        fail=$((fail + 1))
        failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
    fi
}

# ---------- Scenarios -----------------------------------------------------

scenario_runtime_config_command_line() {
    current_scenario="runtime-config-command-line"
    echo "[$current_scenario]"

    run_ltl "rc-cli" -V runtime-config -bs 60 -dmp 7 "$TEST_LOG"

    assert_line "$RUN_STDOUT" \
        pattern     '^=== runtime-config ===$' \
        asserts     'The runtime-config -V section header is emitted whenever -V runtime-config (or bare -V) is requested.' \
        produced_by 'emit_runtime_config_verbose() in ltl' \
        contract    'tests/HARNESS-DESIGN.md section Reserved section names - runtime-config is stability-contracted'

    assert_line "$RUN_STDOUT" \
        pattern     '^=== runtime-config / command-line ===$' \
        asserts     'The command-line sub-section is always present per the locked contract; empty body means no flags supplied on the CLI.' \
        produced_by 'emit_runtime_config_verbose() in ltl (Issue #231 section)' \
        contract    'features/225-test-harness-coverage-gaps.md section #231 - command-line sub-section always emits'

    assert_line "$RUN_STDOUT" \
        pattern     '^bucket-size: 60$' \
        asserts     'A flag supplied on the CLI with a valid value appears in the command-line sub-section with the resolved value and no annotation.' \
        produced_by 'emit_runtime_config_verbose() in ltl (command-line sub-section body)' \
        contract    'features/225-test-harness-coverage-gaps.md section #231 - value with no annotation means user-supplied, valid, unchanged'

    assert_line "$RUN_STDOUT" \
        pattern     '^data-model-precision: 7$' \
        asserts     'Multi-flag invocation surfaces each supplied flag as its own row in command-line sub-section.' \
        produced_by 'emit_runtime_config_verbose() in ltl' \
        contract    'features/225-test-harness-coverage-gaps.md section #231'

    assert_line "$RUN_STDOUT" \
        pattern     '^=== END runtime-config / command-line ===$' \
        asserts     'command-line sub-section closes with its END delimiter per HARNESS-DESIGN.md section Delimiter contract.' \
        produced_by 'emit_runtime_config_verbose() in ltl' \
        contract    'tests/HARNESS-DESIGN.md section Delimiter contract'
}

scenario_runtime_config_env_only() {
    current_scenario="runtime-config-env-only"
    echo "[$current_scenario]"

    LTL_CONFIG='-bs 30' "$LTL" --disable-progress -ni -V runtime-config "$TEST_LOG" > "$TMP_DIR/rc-env.stdout" 2> "$TMP_DIR/rc-env.stderr" || true
    check_stderr_warnings "$TMP_DIR/rc-env.stderr"

    assert_line "$TMP_DIR/rc-env.stdout" \
        pattern     '^=== runtime-config / environment-variable ===$' \
        asserts     'The environment-variable sub-section is always present per the locked contract.' \
        produced_by 'emit_runtime_config_verbose() in ltl' \
        contract    'features/225-test-harness-coverage-gaps.md section #231 - env-var sub-section always emits'

    assert_line "$TMP_DIR/rc-env.stdout" \
        pattern     '^bucket-size: 30$' \
        asserts     'A flag supplied via LTL_CONFIG with no CLI override appears in the environment-variable sub-section with no annotation.' \
        produced_by 'emit_runtime_config_verbose() in ltl (environment-variable sub-section body)' \
        contract    'features/225-test-harness-coverage-gaps.md section #231'
}

scenario_runtime_config_env_overridden() {
    current_scenario="runtime-config-env-overridden"
    echo "[$current_scenario]"

    LTL_CONFIG='-bs 30' "$LTL" --disable-progress -ni -V runtime-config -bs 60 "$TEST_LOG" > "$TMP_DIR/rc-over.stdout" 2> "$TMP_DIR/rc-over.stderr" || true
    check_stderr_warnings "$TMP_DIR/rc-over.stderr"

    assert_line "$TMP_DIR/rc-over.stdout" \
        pattern     '^bucket-size: 60$' \
        asserts     'When the same flag appears in both env and CLI, the command-line sub-section row carries the resolved (CLI-supplied) value with no annotation.' \
        produced_by 'emit_runtime_config_verbose() in ltl (command-line sub-section)' \
        contract    'features/225-test-harness-coverage-gaps.md section #231 - CLI wins; env-side carries override annotation'

    assert_line "$TMP_DIR/rc-over.stdout" \
        pattern     '^bucket-size: 60; overridden$' \
        asserts     'When the same flag appears in both env and CLI, the environment-variable sub-section row carries `; overridden` annotation. (The displayed value is the resolved CLI value; reconstructing the original env value is out of scope.)' \
        produced_by 'emit_runtime_config_verbose() in ltl (environment-variable sub-section)' \
        contract    'features/225-test-harness-coverage-gaps.md section #231 - annotation grammar uses semicolon-separated `; overridden`'
}

scenario_warning_g_non_numeric() {
    current_scenario="warning-g-non-numeric"
    echo "[$current_scenario]"

    run_ltl "warn-g" -g bogus_value "$TEST_LOG"

    assert_line "$RUN_STDERR" \
        pattern     "^-g value 'bogus_value' is not numeric; treating as positional argument and using default threshold 85\\.$" \
        asserts     'When -g is given a non-numeric value, ltl now warns to stderr that the value was treated as a positional argument and the default threshold 85 was used. Was previously silent.' \
        produced_by 'adapt_to_command_line_options() in ltl (group-similar non-numeric branch)' \
        contract    'features/225-test-harness-coverage-gaps.md section #231 - silent-override gap closure'
}

scenario_warning_hm_non_builtin() {
    current_scenario="warning-hm-non-builtin"
    echo "[$current_scenario]"

    run_ltl "warn-hm" -hm bogus_metric "$TEST_LOG"

    assert_line "$RUN_STDERR" \
        pattern     "^-hm value 'bogus_metric' is not a built-in metric \\(duration\\|bytes\\|count\\) and no -udm configs are defined; treating as positional argument and using default metric 'duration'\\.$" \
        asserts     'When -hm is given a value that is neither a built-in metric nor matchable to a -udm config (because no -udm was given), ltl now warns that the value was treated as a positional argument and the default metric was used. Was previously silent.' \
        produced_by 'adapt_to_command_line_options() in ltl (heatmap non-builtin pushback branch)' \
        contract    'features/225-test-harness-coverage-gaps.md section #231 - silent-override gap closure'
}

scenario_error_unknown_exact_percentiles() {
    current_scenario="error-unknown-exact-percentiles"
    echo "[$current_scenario]"

    run_ltl "err-ep" --exact-percentiles "$TEST_LOG"

    assert_exit "$RUN_EXIT" 1 \
        asserts     '--exact-percentiles is not a known flag; ltl rejects it as an unknown option and exits non-zero. The flag is no longer part of the CLI surface; opt-out is via the per-surface data-model selector (-dm raw / -hgdm raw / -hmdm raw / -mdm raw / -bdm raw) per Issue #266.' \
        produced_by 'GetOptions parse failure classified by classify_option_error() in adapt_to_command_line_options()' \
        contract    'Issue #266 + Issue #287 - --exact-percentiles was the legacy F2/F3 opt-out; the data-model selectors are the locked replacement.'

    assert_line "$RUN_STDERR" \
        pattern     "unknown option '--exact-percentiles'" \
        asserts     'The user-visible error names the unknown option, using the specific unknown-option message (not the generic "required options not provided"), so the user knows which flag was rejected.' \
        produced_by 'classify_option_error() in ltl, rendered via print_usage() to stderr' \
        contract    'Issue #309 - option-error classification names each error case; Issue #308 co-locates the error block on stderr.'
}

# Issue #287: assert that the per-surface data-model selectors surface in
# -V runtime-config / command-line when supplied by the user. The selectors
# themselves were wired by #266; this scenario locks the -V row format so
# the runtime-config -V contract reflects the post-#287 surface state.
scenario_runtime_config_data_model_selectors() {
    current_scenario="runtime-config-data-model-selectors"
    echo "[$current_scenario]"

    run_ltl "rc-dm" -V runtime-config -mdm bin -bdm bin -dm bin "$TEST_LOG"

    assert_line "$RUN_STDOUT" \
        pattern     '^message-stats-data-model: bin$' \
        asserts     'A user-supplied -mdm bin appears in the runtime-config / command-line sub-section with its resolved value and no annotation, per #266 + #231.' \
        produced_by 'emit_runtime_config_verbose() in ltl - %resolved_values lookup for message-stats-data-model' \
        contract    'features/266-data-model-selectors.md section -V runtime-config surfacing + features/287-message-stats-bin-counter-data-model.md section R8.3 - selector row format is locked.'

    assert_line "$RUN_STDOUT" \
        pattern     '^bucket-stats-data-model: bin$' \
        asserts     'A user-supplied -bdm bin appears in the runtime-config / command-line sub-section with its resolved value and no annotation, per #266 + #231 (Issue #289 honors -bdm bin end-to-end).' \
        produced_by 'emit_runtime_config_verbose() in ltl - %resolved_values lookup for bucket-stats-data-model' \
        contract    'features/266-data-model-selectors.md section -V runtime-config surfacing + features/289-bucket-stats-bin-counter-data-model.md - selector row format is locked.'

    assert_line "$RUN_STDOUT" \
        pattern     '^data-model: bin$' \
        asserts     'A user-supplied omnibus -dm bin appears as the data-model row in the command-line sub-section, alongside any per-surface override.' \
        produced_by 'emit_runtime_config_verbose() in ltl' \
        contract    'features/266-data-model-selectors.md section -V runtime-config surfacing.'
}

scenario_runtime_config_numeric_highlight() {
    current_scenario="runtime-config-numeric-highlight"
    echo "[$current_scenario]"

    run_ltl "rc-hl" -V runtime-config -hdmin 100 -hbmax 5000 -hcmin 2 "$TEST_LOG"

    assert_line "$RUN_STDOUT" \
        pattern     '^highlight-duration-min: 100$' \
        asserts     'A user-supplied -hdmin appears in the runtime-config / command-line sub-section with its resolved value and no annotation.' \
        produced_by 'emit_runtime_config_verbose() in ltl - %resolved_values lookup for highlight-duration-min' \
        contract    'features/312-numeric-criteria-highlight-selection.md section -V runtime-config - the six highlight criteria join the resolved-values registry'

    assert_line "$RUN_STDOUT" \
        pattern     '^highlight-bytes-max: 5000$' \
        asserts     'A user-supplied -hbmax appears in the runtime-config / command-line sub-section with its resolved value and no annotation.' \
        produced_by 'emit_runtime_config_verbose() in ltl - %resolved_values lookup for highlight-bytes-max' \
        contract    'features/312-numeric-criteria-highlight-selection.md section -V runtime-config'

    assert_line "$RUN_STDOUT" \
        pattern     '^highlight-count-min: 2$' \
        asserts     'A user-supplied -hcmin appears in the runtime-config / command-line sub-section with its resolved value and no annotation.' \
        produced_by 'emit_runtime_config_verbose() in ltl - %resolved_values lookup for highlight-count-min' \
        contract    'features/312-numeric-criteria-highlight-selection.md section -V runtime-config'

    assert_line "$RUN_STDOUT" \
        pattern     '^highlight \(merged\): \(not set\)$' \
        asserts     'The merged highlight regex line reports (not set) when only numeric highlight criteria are given - numeric criteria do not synthesize a regex.' \
        produced_by 'emit_runtime_config_verbose() in ltl (merged-regex display line)' \
        contract    'features/312-numeric-criteria-highlight-selection.md section The defined-highlight_regex gate sweep - the runtime-config merged line stays regex-only'
}

# Issue #566 criterion 12: the resolved expose names, in command-line order,
# surface as one runtime-config row beside the per-flag rows of the aliases.
scenario_runtime_config_expose() {
    current_scenario="runtime-config-expose"
    echo "[$current_scenario]"

    run_ltl "rc-expose" -V runtime-config -xqs -x fileName -xu "$TEST_LOG"

    assert_line "$RUN_STDOUT" \
        pattern     '^expose: query-string,fileName,user$' \
        asserts     'The expose row reports the names -x and its aliases resolved to, comma-separated, in the order they were given on the command line: -xqs -x fileName -xu resolves to query-string, fileName, user. The order is the contract - it is the order the values are appended to the message key in.' \
        produced_by 'emit_runtime_config_verbose() in ltl - %resolved_values lookup for expose, filled by adapt_to_command_line_options() from the ordered expose list' \
        contract    'features/566-preserve-named-values-in-message.md section D2 (command-line order) and section D3 (one option names anything to expose; the existing options are its aliases)'

    assert_line "$RUN_STDOUT" \
        pattern     '^expose-query-string: 1$' \
        asserts     'The alias still reports its own state: -xqs sets expose-query-string, whose row is unchanged by the new expose row.' \
        produced_by 'emit_runtime_config_verbose() in ltl' \
        contract    'features/566-preserve-named-values-in-message.md section D3 - the existing options are kept as aliases'

    assert_line "$RUN_STDOUT" \
        pattern     '^expose-user: 1$' \
        asserts     'The alias still reports its own state: -xu sets expose-user, whose row is unchanged by the new expose row.' \
        produced_by 'emit_runtime_config_verbose() in ltl' \
        contract    'features/566-preserve-named-values-in-message.md section D3 - the existing options are kept as aliases'
}

# Issue #580 criterion 11: the resolved mask names, in command-line order, a
# comma-separated list split and a repeated name kept once, and the mask-uuid
# row reporting whether UUIDs are masked by either spelling.
scenario_runtime_config_mask() {
    current_scenario="runtime-config-mask"
    echo "[$current_scenario]"

    run_ltl "rc-mask-list" -V runtime-config -m uuid,ipv4 -m uuid "$TEST_LOG"
    assert_line "$RUN_STDOUT" \
        pattern     '^mask: uuid,ipv4$' \
        asserts     'The mask row reports the names -m resolved to, comma-separated, in the order they were given: a comma-separated list is split, and a name given twice keeps its first position. -m uuid,ipv4 -m uuid resolves to uuid, ipv4.' \
        produced_by 'emit_runtime_config_verbose() in ltl - %resolved_values lookup for mask, filled by resolve_mask_names() from the ordered mask list' \
        contract    'features/580-mask-uuid-and-ip-address.md section D5 - a new mask key lists the resolved names in command-line order'
    assert_line "$RUN_STDOUT" \
        pattern     '^mask-uuid: 1$' \
        asserts     'mask-uuid reports 1 when UUIDs are masked through -m uuid, not only through the deprecated -uuid spelling.' \
        produced_by 'emit_runtime_config_verbose() in ltl - the mask-uuid row, given command-line provenance whenever -m was supplied' \
        contract    'features/580-mask-uuid-and-ip-address.md section D5 - mask-uuid reports 1 when UUIDs are masked by either spelling'

    run_ltl "rc-mask-uuid" -V runtime-config -uuid "$TEST_LOG"
    assert_line "$RUN_STDOUT" \
        pattern     '^mask: uuid$' \
        asserts     'The deprecated -uuid spelling resolves to the mask name uuid and reports it on the mask row, so the two spellings read as one configuration.' \
        produced_by 'emit_runtime_config_verbose() in ltl - the mask row, given command-line provenance whenever -uuid was supplied' \
        contract    'features/580-mask-uuid-and-ip-address.md section D5 - -V runtime-config reports the effective configuration'
    assert_line "$RUN_STDOUT" \
        pattern     '^mask-uuid: 1$' \
        asserts     '-uuid still reports mask-uuid: 1, as it did before -m existed.' \
        produced_by 'emit_runtime_config_verbose() in ltl - the mask-uuid row' \
        contract    'features/580-mask-uuid-and-ip-address.md section D5 - mask-uuid stays'

    run_ltl "rc-mask-ip" -V runtime-config -m ip "$TEST_LOG"
    assert_line "$RUN_STDOUT" \
        pattern     '^mask: ip$' \
        asserts     'ip is reported as the name given, not expanded to ipv4,ipv6: the row is the configuration as the user stated it.' \
        produced_by 'emit_runtime_config_verbose() in ltl - the mask row' \
        contract    'features/580-mask-uuid-and-ip-address.md section D5 and section Acceptance criteria 11'
    assert_line "$RUN_STDOUT" \
        pattern     '^mask-uuid: 0$' \
        asserts     'A mask that does not name uuid reports mask-uuid: 0 rather than omitting the row, so a reader of the section sees that UUIDs are not masked.' \
        produced_by 'emit_runtime_config_verbose() in ltl - the mask-uuid row, given command-line provenance whenever -m was supplied' \
        contract    'features/580-mask-uuid-and-ip-address.md section Acceptance criteria 11 - -m ip reports mask: ip, mask-uuid: 0'
}

# Issue #567 criterion 15 (567 D18): the discard row, and the omit rows that
# report only what the user gave.
scenario_runtime_config_discard() {
    current_scenario="runtime-config-discard"
    echo "[$current_scenario]"

    run_ltl "rc-discard" -V runtime-config -xqs -x thread -d sign,thread -d duration "$TEST_LOG"
    assert_line "$RUN_STDOUT" \
        pattern     '^discard: sign,thread,duration$' \
        asserts     'The discard row reports the names -d resolved to, comma-separated, in the order they were given: a comma-separated list is split, and the names keep their command-line order across repeated options.' \
        produced_by 'emit_runtime_config_verbose() in ltl - %resolved_values lookup for discard, filled by resolve_discard_names() from the ordered discard list' \
        contract    'features/567-discard-named-values-from-message.md section Decisions D18 - a new discard key lists the resolved names in command-line order'
    assert_line "$RUN_STDOUT" \
        pattern     '^expose: query-string$' \
        asserts     'The expose row lists only the names still exposed: a name given to both options is discarded and drops out of the expose row, so the two rows cannot both claim the same value.' \
        produced_by 'apply_discard_precedence() in ltl - the exposed names a discard removes' \
        contract    'features/567-discard-named-values-from-message.md section Decisions D13 and D18'
    assert_no_line "$RUN_STDOUT" \
        pattern     '^omit-durations:' \
        asserts     'runtime-config reports the configuration the user provided: -d duration is reported by the discard row, and the omit row is not printed for an option the user did not give.' \
        produced_by 'emit_runtime_config_verbose() in ltl - the rows are emitted from %option_provenance, which records what was supplied' \
        contract    'features/567-discard-named-values-from-message.md section Decisions D18, revised 2026-09-19'

    run_ltl "rc-discard-repeat" -V runtime-config -d sign -d sign "$TEST_LOG"
    assert_line "$RUN_STDOUT" \
        pattern     '^discard: sign$' \
        asserts     'A name given twice is listed once, at its first position.' \
        produced_by 'emit_runtime_config_verbose() in ltl - %resolved_values lookup for discard' \
        contract    'features/567-discard-named-values-from-message.md section Decisions D18'

    run_ltl "rc-discard-omit" -V runtime-config -od -d duration "$TEST_LOG"
    assert_line "$RUN_STDOUT" \
        pattern     '^omit-durations: 1$' \
        asserts     'An omit option the user did give is reported on its own row, whether or not --discard names the same metric: each option surfaces itself.' \
        produced_by 'emit_runtime_config_verbose() in ltl - the omit-durations row, given command-line provenance because -od was supplied' \
        contract    'features/567-discard-named-values-from-message.md section Decisions D18, revised 2026-09-19'
    assert_line "$RUN_STDOUT" \
        pattern     '^discard: duration$' \
        asserts     'The discard row is unaffected by the omit option being given as well.' \
        produced_by 'emit_runtime_config_verbose() in ltl - %resolved_values lookup for discard' \
        contract    'features/567-discard-named-values-from-message.md section Decisions D18'
}

scenario_error_unknown_so() {
    current_scenario="error-unknown-so"
    echo "[$current_scenario]"

    run_ltl "err-so" -so invalidfield "$TEST_LOG"
    assert_exit "$RUN_EXIT" 1 \
        asserts     '-so with an unknown enum value is a hard error and exits with code 1.' \
        produced_by 'adapt_to_command_line_options() in ltl (sort-on enum validation), via print_usage() exit 1' \
        contract    'features/225-test-harness-coverage-gaps.md section #231 - hard-error paths pin current exit code; exit-code policy normalization is deferred to a separate ticket per scoping decision'

    # ltl emits the error block (including "Error: invalid sort type used") on
    # stderr via print_usage(); print_usage exits directly, so there is no
    # "Died at ..." Perl trace. The harness asserts against the user-visible
    # diagnostic, hence stderr.
    assert_line "$RUN_STDERR" \
        pattern     'invalid sort type' \
        asserts     'The user-visible diagnostic (emitted via print_usage to stderr) identifies the failed validation (sort type).' \
        produced_by 'print_usage("invalid sort type used") in adapt_to_command_line_options()' \
        contract    'features/225-test-harness-coverage-gaps.md section #231 - pinning current diagnostic surface; Issue #308 routes the error block to stderr'
}

scenario_error_unknown_du() {
    current_scenario="error-unknown-du"
    echo "[$current_scenario]"

    run_ltl "err-du" -du x "$TEST_LOG"
    assert_exit "$RUN_EXIT" 1 \
        asserts     '-du with an unknown enum value is a hard error (exit 1 via print_usage).' \
        produced_by 'adapt_to_command_line_options() in ltl (duration-unit enum validation)' \
        contract    'features/225-test-harness-coverage-gaps.md section #231'

    assert_line "$RUN_STDERR" \
        pattern     "Invalid duration unit" \
        asserts     'The user-visible diagnostic (stderr) identifies the failed validation (duration unit).' \
        produced_by 'print_usage("Invalid duration unit ...") in adapt_to_command_line_options()' \
        contract    'features/225-test-harness-coverage-gaps.md section #231; Issue #308 routes the error block to stderr'
}

scenario_error_unknown_ru() {
    current_scenario="error-unknown-ru"
    echo "[$current_scenario]"

    run_ltl "err-ru" -ru x "$TEST_LOG"
    assert_exit "$RUN_EXIT" 1 \
        asserts     '-ru with an unknown enum value is a hard error (exit 1 via print_usage).' \
        produced_by 'adapt_to_command_line_options() in ltl (rate-unit enum validation)' \
        contract    'features/225-test-harness-coverage-gaps.md section #231'

    assert_line "$RUN_STDERR" \
        pattern     "Invalid rate unit" \
        asserts     'The user-visible diagnostic (stderr) identifies the failed validation (rate unit).' \
        produced_by 'print_usage("Invalid rate unit ...") in adapt_to_command_line_options()' \
        contract    'features/225-test-harness-coverage-gaps.md section #231; Issue #308 routes the error block to stderr'
}

scenario_error_no_files() {
    current_scenario="error-no-files"
    echo "[$current_scenario]"

    run_ltl "err-nofiles" /tmp/definitely-not-here-$$.nonexistent
    # The no-files case uses a different die path (not print_usage) and ends up
    # with exit code 2 rather than 1. Pinning current behavior; harmonizing
    # exit codes across error paths is out of scope per the deferred exit-code
    # policy decision in features/231-cli-validation-coverage.md § 8.
    assert_exit "$RUN_EXIT" 2 \
        asserts     'A non-existent file path is a hard error after glob expansion produces no matches (exit 2, distinct from the print_usage exit-1 paths).' \
        produced_by 'adapt_to_command_line_options() in ltl (post-glob @in_files empty check)' \
        contract    'features/225-test-harness-coverage-gaps.md section #231 - exit-code disparity (1 vs 2) intentionally pinned; harmonization deferred to a separate ticket'

    assert_line "$RUN_STDERR" \
        pattern     'unable to open any files' \
        asserts     'The user-visible diagnostic (stderr) surfaces the empty-@in_files condition.' \
        produced_by 'print_usage("unable to open any files") in adapt_to_command_line_options()' \
        contract    'features/225-test-harness-coverage-gaps.md section #231; Issue #308 routes the error block to stderr'
}

scenario_no_warning_on_clean_run() {
    current_scenario="no-warning-on-clean-run"
    echo "[$current_scenario]"

    run_ltl "clean" -bs 60 "$TEST_LOG"
    assert_exit "$RUN_EXIT" 0 \
        asserts     'A run with valid flags and a valid file exits 0.' \
        produced_by 'normal ltl execution' \
        contract    'baseline'

    # None of the silent-override warnings should fire on a clean run.
    assert_no_line "$RUN_STDERR" \
        pattern     "is not numeric|is not a built-in metric" \
        asserts     'A clean run produces none of the silent-override warnings. This guards against the warnings firing on inputs they were not designed for.' \
        produced_by 'adapt_to_command_line_options() in ltl' \
        contract    'features/225-test-harness-coverage-gaps.md section #231 - warnings are gated on specific input shapes'
}

scenario_info_version_wins_over_parse_error() {
    current_scenario="info-version-wins-over-parse-error"
    echo "[$current_scenario]"

    run_ltl "info-ver" --version -b 5 "$TEST_LOG"
    assert_exit "$RUN_EXIT" 0 \
        asserts     'An informational option (--version) short-circuits before GetOptions runs, so an otherwise-fatal malformed companion option (-b, unknown post no_auto_abbrev) never triggers a parse error; the version prints and the process exits 0.' \
        produced_by 'dispatch_informational_options() in adapt_to_command_line_options() in ltl (pre-parse @ARGV scan)' \
        contract    'Issue #309 - informational options take precedence over option parsing and validation.'

    assert_line "$RUN_STDOUT" \
        pattern     '^Version: ' \
        asserts     'The version line is printed despite the malformed companion option.' \
        produced_by 'print_version() dispatched from dispatch_informational_options()' \
        contract    'Issue #309 - informational-option precedence.'
}

scenario_info_help_beats_version() {
    current_scenario="info-help-beats-version"
    echo "[$current_scenario]"

    run_ltl "info-help-ver" --help --version "$TEST_LOG"
    assert_exit "$RUN_EXIT" 0 \
        asserts     'When multiple informational options are given, the fixed priority is help > explain > version regardless of command-line position; --help --version prints help and exits 0.' \
        produced_by 'dispatch_informational_options() in ltl (fixed help>explain>version priority)' \
        contract    'Issue #309 - informational-option precedence order.'

    assert_line "$RUN_STDOUT" \
        pattern     'USAGE' \
        asserts     'The help body (which contains the USAGE heading) is printed, proving help won over version.' \
        produced_by 'print_help() dispatched from dispatch_informational_options()' \
        contract    'Issue #309 - informational-option precedence order.'
}

scenario_error_unknown_short_b() {
    current_scenario="error-unknown-short-b"
    echo "[$current_scenario]"

    run_ltl "err-b" -b 5 "$TEST_LOG"
    assert_exit "$RUN_EXIT" 1 \
        asserts     'With no_auto_abbrev, -b is no longer a unique-prefix abbreviation of any long option; it is a clean unknown option (not "ambiguous", not silently accepted) and exits 1.' \
        produced_by 'GetOptions parse failure classified by classify_option_error() in ltl' \
        contract    'Issue #309 - no_auto_abbrev + option-error classification.'

    assert_line "$RUN_STDERR" \
        pattern     "unknown option '-b'" \
        asserts     'The user-visible error names the specific unknown option (-b), not the generic "required options not provided".' \
        produced_by 'classify_option_error() in ltl, rendered via print_usage() to stderr' \
        contract    'Issue #309 - option-error classification; Issue #308 co-locates the error block on stderr.'
}

# ---------- Run -----------------------------------------------------------

echo "Validating runtime-config -V section + CLI validation paths (issue #231)"
echo "  ltl:       $LTL"
echo ""

scenario_register runtime-config-command-line \
                  runtime-config-env-only \
                  runtime-config-env-overridden \
                  warning-g-non-numeric \
                  warning-hm-non-builtin \
                  error-unknown-exact-percentiles \
                  runtime-config-data-model-selectors \
                  runtime-config-numeric-highlight \
                  runtime-config-expose \
                  runtime-config-mask \
                  runtime-config-discard \
                  error-unknown-so \
                  error-unknown-du \
                  error-unknown-ru \
                  error-no-files \
                  info-version-wins-over-parse-error \
                  info-help-beats-version \
                  error-unknown-short-b \
                  no-warning-on-clean-run
scenario_parse_args "$@"

while read -r _scenario; do
    case "$_scenario" in
        runtime-config-command-line        ) scenario_runtime_config_command_line ;;
        runtime-config-env-only            ) scenario_runtime_config_env_only ;;
        runtime-config-env-overridden      ) scenario_runtime_config_env_overridden ;;
        warning-g-non-numeric              ) scenario_warning_g_non_numeric ;;
        warning-hm-non-builtin             ) scenario_warning_hm_non_builtin ;;
        error-unknown-exact-percentiles    ) scenario_error_unknown_exact_percentiles ;;
        runtime-config-data-model-selectors) scenario_runtime_config_data_model_selectors ;;
        runtime-config-numeric-highlight   ) scenario_runtime_config_numeric_highlight ;;
        runtime-config-expose              ) scenario_runtime_config_expose ;;
        runtime-config-mask                ) scenario_runtime_config_mask ;;
        runtime-config-discard             ) scenario_runtime_config_discard ;;
        error-unknown-so                   ) scenario_error_unknown_so ;;
        error-unknown-du                   ) scenario_error_unknown_du ;;
        error-unknown-ru                   ) scenario_error_unknown_ru ;;
        error-no-files                     ) scenario_error_no_files ;;
        info-version-wins-over-parse-error ) scenario_info_version_wins_over_parse_error ;;
        info-help-beats-version            ) scenario_info_help_beats_version ;;
        error-unknown-short-b              ) scenario_error_unknown_short_b ;;
        no-warning-on-clean-run            ) scenario_no_warning_on_clean_run ;;
    esac
    echo ""
done < <(scenario_selected)

echo ""
echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
echo "ALL RUNTIME-CONFIG TESTS PASSED"
exit 0
