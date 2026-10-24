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
LTL="${LTL:-$REPO_DIR/ltl}"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"
# shellcheck source=lib/notices.sh
source "$SCRIPT_DIR/lib/notices.sh"

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

# Self-documenting assertion: no line matching `pattern` is present. The
# absence is read only against a run that wrote what it is read in: a line
# matching `evidence` must be present first, in `outfile` or in the file named
# by `in` (HARNESS-DESIGN.md Trap 13, shape 3).
assert_no_line() {
    local outfile="$1"
    shift
    local pattern evidence in asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            pattern)     pattern="$2";     shift 2 ;;
            evidence)    evidence="$2";    shift 2 ;;
            in)          in="$2";          shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_no_line: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${evidence:?assert_no_line requires evidence}"
    in="${in:-$outfile}"

    if ! grep -qaE "$evidence" "$in"; then
        echo "  FAIL  $current_scenario"
        echo "        pattern:     !$pattern (nothing to read the absence against)"
        echo "        evidence:    $evidence (not found in $in)"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
        failures+=("$current_scenario :: !$pattern (no evidence)")
    elif grep -qE "$pattern" "$outfile"; then
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

# Self-documenting equality assertion on exit code. Any failure exits non-zero
# and a run that printed nothing exits 0, so the exit code holds only beside a
# line the run writes: `evidence`, a pattern found in the file named by `in`
# (its message, or a line every run of its shape prints; HARNESS-DESIGN.md
# shapes 6 and 14).
assert_exit() {
    local actual="$1"
    local expected="$2"
    shift 2
    local evidence in asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            evidence)    evidence="$2";    shift 2 ;;
            in)          in="$2";          shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_exit: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${evidence:?assert_exit requires evidence}"
    : "${in:?assert_exit requires in}"

    if [[ "$actual" == "$expected" ]] && grep -qaE -- "$evidence" "$in"; then
        echo "  PASS  $current_scenario :: exit=$actual"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        expected:    exit=$expected, and a line matching $evidence in $in"
        echo "        actual:      exit=$actual$(grep -qaE -- "$evidence" "$in" || echo ", no such line")"
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
        pattern     '^bucket_size: 60$' \
        asserts     'A flag supplied on the CLI with a valid value appears in the command-line sub-section with the resolved value and no annotation.' \
        produced_by 'emit_runtime_config_verbose() in ltl (command-line sub-section body)' \
        contract    'features/225-test-harness-coverage-gaps.md section #231 - value with no annotation means user-supplied, valid, unchanged'

    assert_line "$RUN_STDOUT" \
        pattern     '^data_model_precision: 7$' \
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
        pattern     '^bucket_size: 30$' \
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
        pattern     '^bucket_size: 60$' \
        asserts     'When the same flag appears in both env and CLI, the command-line sub-section row carries the resolved (CLI-supplied) value with no annotation.' \
        produced_by 'emit_runtime_config_verbose() in ltl (command-line sub-section)' \
        contract    'features/225-test-harness-coverage-gaps.md section #231 - CLI wins; env-side carries override annotation'

    assert_line "$TMP_DIR/rc-over.stdout" \
        pattern     '^bucket_size: 60; overridden$' \
        asserts     'When the same flag appears in both env and CLI, the environment-variable sub-section row carries `; overridden` annotation. (The displayed value is the resolved CLI value; reconstructing the original env value is out of scope.)' \
        produced_by 'emit_runtime_config_verbose() in ltl (environment-variable sub-section)' \
        contract    'features/225-test-harness-coverage-gaps.md section #231 - annotation grammar uses semicolon-separated `; overridden`'
}

# Issue #614 phase 2 (D1's shape: one optional-operand helper). A value that
# is not in an optional-operand option's vocabulary goes back as a file
# argument, silently, and the option takes its bare default; a value that is
# then no file is named at file resolution with the option it followed.
# `-bs 1440 -oe`: stderr, exit status and the runtime-config defaults only;
# the twelve-line access fixture.
CONTRACT_PUSHBACK='features/614-operand-settlement.md § 2 D1 (two-place shape; silent pushback locked 2026-10-12) and § Acceptance criteria, phase 2'
PRODUCED_BY_PUSHBACK='settle_optional_operand() in ltl, called from adapt_to_command_line_options() for -hm, -hg, -V, -g and -mem'

scenario_pushback_silent() {
    current_scenario="pushback-silent"
    echo "[$current_scenario]"
    local option
    for option in -hm -hg -g -mem; do
        run_ltl "pushback$option" -bs 1440 -oe -V runtime-config,format-detection "$option" "$METRIC_FIXTURE"
        assert_exit "$RUN_EXIT" 0 \
            evidence    '^=== runtime-config ===$' in "$RUN_STDOUT" \
            asserts     "ltl $option <file> reads the file: a value outside $option's vocabulary is a file argument." \
            produced_by "$PRODUCED_BY_PUSHBACK" \
            contract    "$CONTRACT_PUSHBACK"
        assert_line "$RUN_STDOUT" \
            pattern     "^file: .*tomcat-access-single-sample-keys\\.txt\$" \
            asserts     "The value $option took back is selected as the run's file." \
            produced_by "$PRODUCED_BY_PUSHBACK; the file-argument expansion loop in adapt_to_command_line_options()" \
            contract    "$CONTRACT_PUSHBACK"
        assert_command \
            command     "grep -q '^=== runtime-config ===\$' '$RUN_STDOUT' && [ ! -s '$RUN_STDERR' ] && ! grep -q 'Continue with these options' '$RUN_STDOUT'" \
            label       "ltl $option <file> raises no notice and says nothing on stderr" \
            asserts     'The pushback is silent for every optional-operand option: a file after the option is the normal invocation.' \
            produced_by "$PRODUCED_BY_PUSHBACK" \
            contract    "$CONTRACT_PUSHBACK"
    done
    assert_line "$TMP_DIR/pushback-hm.stdout" pattern '^heatmap: duration$' \
        asserts 'A pushed-back -hm value leaves -hm on its default metric, duration.' \
        produced_by "$PRODUCED_BY_PUSHBACK" contract "$CONTRACT_PUSHBACK"
    assert_line "$TMP_DIR/pushback-g.stdout" pattern '^group_similar: 85$' \
        asserts 'A pushed-back -g value leaves -g on its default threshold, 85.' \
        produced_by "$PRODUCED_BY_PUSHBACK" contract "$CONTRACT_PUSHBACK"
    assert_line "$TMP_DIR/pushback-mem.stdout" pattern '^memory_usage: 1$' \
        asserts 'A pushed-back -mem value leaves the memory report on, without its debug detail.' \
        produced_by "$PRODUCED_BY_PUSHBACK" contract "$CONTRACT_PUSHBACK"

    run_ltl "pushback-V" -bs 1440 -oe -V "$METRIC_FIXTURE"
    assert_exit "$RUN_EXIT" 0 \
        evidence    '^=== runtime-config ===$' in "$RUN_STDOUT" \
        asserts     'ltl -V <file> reads the file with every section.' \
        produced_by "$PRODUCED_BY_PUSHBACK" contract "$CONTRACT_PUSHBACK"
    assert_line "$RUN_STDOUT" pattern '^=== statistics-demand ===$' \
        asserts 'A pushed-back -V value leaves -V bare: every section is emitted.' \
        produced_by "$PRODUCED_BY_PUSHBACK" contract "$CONTRACT_PUSHBACK"
    assert_command \
        command     "grep -q '^=== runtime-config ===\$' '$RUN_STDOUT' && [ ! -s '$RUN_STDERR' ] && ! grep -q 'Continue with these options' '$RUN_STDOUT'" \
        label       'ltl -V <file> raises no notice and says nothing on stderr' \
        asserts     'The -V pushback is silent, as every option'"'"'s is.' \
        produced_by "$PRODUCED_BY_PUSHBACK" contract "$CONTRACT_PUSHBACK"
}

scenario_pushback_not_a_file() {
    current_scenario="pushback-not-a-file"
    echo "[$current_scenario]"
    local -a cases=(
        "-V|foo|Error: 'foo' matches no file (it followed -V/--verbose and is not a verbose section; 'ltl -V list' lists them)"
        "-g|85%|Error: '85%' matches no file (it followed -g/--group-similar and is not a similarity threshold, a whole number from 50 to 99)"
        "-mem|foo|Error: 'foo' matches no file (it followed -mem/--memory-usage and is not debug)"
        "-hm|foo|Error: 'foo' matches no file (it followed -hm/--heatmap and is not a metric; the metrics are duration, bytes, count)"
        "-hg|foo|Error: 'foo' matches no file (it followed -hg/--histogram and is not a metric; the metrics are duration, bytes, count)"
    )
    local entry option value message
    for entry in "${cases[@]}"; do
        IFS='|' read -r option value message <<< "$entry"
        run_ltl "not-a-file$option" -bs 1440 -oe "$option" "$value" "$METRIC_FIXTURE"
        assert_exit "$RUN_EXIT" 2 \
            evidence    "^Error: '.*' matches no file" in "$RUN_STDERR" \
            asserts     "ltl $option $value <file>: the value is given back as a file argument and selects no file, so the run stops at file resolution." \
            produced_by "$PRODUCED_BY_PUSHBACK; file_argument_problem() in ltl" \
            contract    "$CONTRACT_PUSHBACK"
        assert_command \
            command     "grep -aqxF -- \"$message\" '$RUN_STDERR'" \
            label       "the error names $value, the option it followed and what $option takes" \
            asserts     'The file-resolution error says which option the value followed and that it is not in that option'"'"'s vocabulary.' \
            produced_by "file_argument_problem() in ltl (%pushed_back_operand)" \
            contract    "$CONTRACT_PUSHBACK"
    done
}

scenario_list_member_unknown() {
    current_scenario="list-member-unknown"
    echo "[$current_scenario]"
    run_ltl "list-V" -bs 1440 -oe -V format-detection,foo "$METRIC_FIXTURE"
    assert_exit "$RUN_EXIT" 1 \
        evidence    "^Error: 'foo' given to -V/--verbose" in "$RUN_STDERR" \
        asserts     'A -V comma list with a known section is the option'"'"'s; its unknown member stops the run.' \
        produced_by "$PRODUCED_BY_PUSHBACK" contract "$CONTRACT_PUSHBACK"
    assert_command \
        command     "grep -aqxF -- \"Error: 'foo' given to -V/--verbose is not a verbose section; 'ltl -V list' lists them\" '$RUN_STDERR'" \
        label       'the -V list rejection names the unknown member and points to -V list' \
        asserts     'The rejection names the member that is not a section and says where the sections are listed.' \
        produced_by "$PRODUCED_BY_PUSHBACK" contract "$CONTRACT_PUSHBACK"

    run_ltl "list-V-known" -bs 1440 -oe -V format-detection,csv-output "$METRIC_FIXTURE"
    assert_exit "$RUN_EXIT" 0 \
        evidence    '^=== format-detection ===$' in "$RUN_STDOUT" \
        asserts     'A -V comma list of known sections is taken whole.' \
        produced_by "$PRODUCED_BY_PUSHBACK" contract "$CONTRACT_PUSHBACK"
}

# Issue #614 phase 2 criterion 7 and phase 3 criterion 6: the decision has one
# home. Read from the source, where the requirement lives: every unshift onto
# @ARGV sits in settle_optional_operand() or the environment-argument merge in
# adapt_to_command_line_options(); -V keeps no path test of its own; the -hg
# handler records its value and resolves nothing.
scenario_optional_operand_source() {
    current_scenario="optional-operand-source"
    echo "[$current_scenario]"
    local unshift_subs
    unshift_subs=$(awk '/^sub [A-Za-z_]+/ { sub_name = $2 } /unshift @ARGV/ { print sub_name }' "$LTL" | sort | tr '\n' ' ')
    assert_command \
        command     "[ '$unshift_subs' = 'adapt_to_command_line_options settle_optional_operand ' ] && [ \"\$(grep -c 'unshift @ARGV' '$LTL')\" = 2 ]" \
        label       'unshift @ARGV occurs only in settle_optional_operand() and the environment-argument merge' \
        asserts     'One sub gives a value back as a file argument for every optional-operand option; the only other unshift is the merge of LTL_* environment arguments (found: '"$unshift_subs"').' \
        produced_by 'settle_optional_operand() in ltl' \
        contract    "$CONTRACT_PUSHBACK; docs/architecture-patterns.md § Optional-operand options and the filename pushback"
    assert_command \
        command     "grep -qE '^sub adapt_to_command_line_options\\b' '$LTL' && ! grep -qF 'm{[/.]} || -e \$name' '$LTL'" \
        label       '-V keeps no path test of its own' \
        asserts     'The -V settlement no longer guesses whether a value looks like a path; the helper decides by the section vocabulary alone.' \
        produced_by 'adapt_to_command_line_options() in ltl (the -V settlement)' \
        contract    "$CONTRACT_PUSHBACK"
    assert_command \
        command     "awk '/^sub handle_histogram_option/ { f = 1 } f && /^}/ { exit } f' '$LTL' > '$TMP_DIR/hg-handler.pl' && grep -q 'push @histogram_operands' '$TMP_DIR/hg-handler.pl' && ! grep -qE 'builtin_metric_name|resolve_metric_operand|warn ' '$TMP_DIR/hg-handler.pl'" \
        label       'the -hg handler records its value and resolves nothing' \
        asserts     'handle_histogram_option() only records each -hg value; resolution happens at settlement, after the -udm metrics are parsed.' \
        produced_by 'handle_histogram_option() in ltl' \
        contract    'features/614-operand-settlement.md § 2 D2 (a handler only records the operand) and phase 3 criteria'
}

# Issue #613 criterion 1 (D5: one built-in metric table): each unknown-metric
# message interpolates the table's list, and none names time, which is not a
# metric name. -udm comes first on the -hg run: without one, -hg pushes an
# operand it does not recognise back as a file name. `-bs 1440 -oe`: stderr
# diagnostics only, no bucket read; the twelve-line access fixture.
METRIC_FIXTURE="$REPO_DIR/tests/fixtures/tomcat-access-single-sample-keys.txt"
CONTRACT_METRIC_LIST='features/613-one-name-vocabulary.md D5 (every unknown-metric message derives its list from the built-in metric table) and D1 (time is not a metric name); criterion 1'

scenario_error_unknown_metric_lists() {
    current_scenario="error-unknown-metric-lists"
    echo "[$current_scenario]"
    local contract="$CONTRACT_METRIC_LIST; features/614-operand-settlement.md § 2 D2 (one metric list for every consumer) and phase 3 criteria"

    run_ltl "metric-list-hg" -bs 1440 -oe -udm x::max -hg duration,foo "$METRIC_FIXTURE"
    assert_exit "$RUN_EXIT" 1 \
        evidence    "^Error: 'foo' given to -hg/--histogram is not a metric" in "$RUN_STDERR" \
        asserts     'An -hg comma list naming a metric and a word that is none is a rejection, exit 1, before any file is read.' \
        produced_by 'settle_optional_operand() in ltl (the -hg settlement), reported via print_usage()' \
        contract    "$contract"
    assert_line "$RUN_STDERR" \
        pattern     "^Error: 'foo' given to -hg/--histogram is not a metric; the metrics are duration, bytes, count, x$" \
        asserts     'The -hg rejection names the unknown member and lists the built-in metrics from the table, then the -udm names.' \
        produced_by 'settle_optional_operand() and metric_operand_expects() in ltl, via available_metric_names()' \
        contract    "$contract"
    assert_command \
        command     "grep -a '^Error:' '$RUN_STDERR' | grep -q . && ! grep -a '^Error:' '$RUN_STDERR' | grep -qE '(^|[^a-z])time([^a-z]|\\$)'" \
        label       'the -hg rejection does not name time among the metrics' \
        asserts     'The -hg rejection does not name time among the metrics (the usage synopsis above it carries <time> for -st and -et, so only the Error line is read).' \
        produced_by 'available_metric_names() in ltl' \
        contract    "$contract"

    run_ltl "metric-list-hg-no-udm" -bs 1440 -oe -hg duration,foo "$METRIC_FIXTURE"
    assert_exit "$RUN_EXIT" 1 \
        evidence    "^Error: 'foo' given to -hg/--histogram is not a metric" in "$RUN_STDERR" \
        asserts     'Without -udm the same comma list is the same rejection: whether -udm was given changes nothing about the rule.' \
        produced_by 'settle_optional_operand() in ltl (the -hg settlement)' \
        contract    "$contract"
    assert_line "$RUN_STDERR" \
        pattern     "^Error: 'foo' given to -hg/--histogram is not a metric; the metrics are duration, bytes, count$" \
        asserts     'Without -udm the list is the built-in metrics alone, from the same source.' \
        produced_by 'metric_operand_expects() in ltl, via available_metric_names()' \
        contract    "$contract"

    run_ltl "metric-list-hm-pushback" -bs 1440 -oe -udm x::max -hm foo "$METRIC_FIXTURE"
    assert_line "$RUN_STDERR" \
        pattern     "^Error: 'foo' matches no file \\(it followed -hm/--heatmap and is not a metric; the metrics are duration, bytes, count, x\\)$" \
        asserts     'An -hm value that names no metric is given back as a file argument; selecting no file, it is named with the metrics from the one list, built-in then -udm.' \
        produced_by 'settle_optional_operand(), metric_operand_expects() and file_argument_problem() in ltl' \
        contract    "$contract"
}

# Issue #614 phase 2 criterion 5, phase 3 criterion 3: user-defined metrics are
# parsed before the optional operands are settled, so -udm's position on the
# line does not matter. Stdout of the two orders is compared whole.
scenario_udm_position() {
    current_scenario="udm-position"
    echo "[$current_scenario]"
    local contract='features/614-operand-settlement.md § Acceptance criteria, phase 2 (user-defined names are in the vocabulary wherever -udm stands) and phase 3'
    run_ltl "udm-after" -bs 1440 -oe -hg duration,sz -udm 'sz::max:/" 200 ([0-9]+) /' "$METRIC_FIXTURE"
    local after="$RUN_STDOUT" after_exit="$RUN_EXIT"
    run_ltl "udm-before" -bs 1440 -oe -udm 'sz::max:/" 200 ([0-9]+) /' -hg duration,sz "$METRIC_FIXTURE"
    assert_exit "$after_exit" 0 \
        evidence    'sz Distribution' in "$after" \
        asserts     '-hg naming a user-defined metric before its -udm is accepted.' \
        produced_by 'parse_udm_configs() ahead of settle_optional_operand() in adapt_to_command_line_options()' \
        contract    "$contract"
    assert_command \
        command     "grep -aq 'sz Distribution' '$after' && diff <(grep -aE 'Distribution|P[0-9]+:' '$after') <(grep -aE 'Distribution|P[0-9]+:' '$RUN_STDOUT')" \
        label       '-hg duration,sz renders the same panels whichever side of -udm it stands' \
        asserts     'The user-defined metric is in -hg'"'"'s vocabulary wherever -udm stands; both orders render the sz panel (the fixture'"'"'s 200 responses carry its values) with identical titles and percentiles; the banner echoing the command line and the run timing differ by nature.' \
        produced_by 'parse_udm_configs() ahead of settle_optional_operand() in adapt_to_command_line_options()' \
        contract    "$contract"
}

# Issue #613 criteria 2 and 3 (D1, D8, D17): time and size still name the
# duration and bytes metrics on the options their table entry lists, for one
# release, and say so in one deprecation line per spelling however many
# options it was given to. Each spelling's run is compared with the run under
# the canonical name; only the surface the option drives is rendered, so the
# comparison reads that surface and nothing timing-dependent. `-bs 1440 -oe`:
# no assertion reads a bucket.
CONTRACT_DEPRECATED='features/613-one-name-vocabulary.md D1 (time is not a metric name; -hm, -hg and -so print a deprecation notice for a release), D8 (size deprecated on -so), D17 (one deprecation-notice helper); criteria 2 and 3'
# The deprecation notice is a record of -V notices (notice_lines: kind | focus
# | statement | evidence | remedy); the rendered output is compared with the
# notice boxes set aside (without_notice_boxes).
TIME_NOTICE='^deprecated-spelling \| time \| is deprecated as a metric name \(given to [^)]*\) \| - \| use duration$'

# Run ltl rendering only the named section, stdout to <label>.stdout.
run_section_only() {
    local label="$1" section="$2"; shift 2
    local hide
    hide=$(printf '%s\n' title timeline histogram options messages summary | grep -vx "$section" | paste -sd, -)
    run_ltl "$label" -bs 1440 -oe --terminal-width 200 --hide "$hide" "$@"
}

assert_one_line() {
    local file="$1" pattern="$2" label="$3" produced_by="$4"
    local count
    count=$(grep -cE "$pattern" "$file" || true)
    if [[ "$count" == "1" ]]; then
        echo "  PASS  $current_scenario :: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario :: $label"
        echo "        expected:    exactly one line matching $pattern"
        echo "        actual:      $count"
        echo "        asserts:     $label"
        echo "        produced_by: $produced_by"
        echo "        contract:    $CONTRACT_DEPRECATED"
        fail=$((fail + 1))
        failures+=("$current_scenario :: $label")
    fi
}

# Self-documenting assertion for checks that are not one line in one file
# (HARNESS-DESIGN.md § When the assertion isn't a simple line grep): runs
# `command`; PASS on exit 0, FAIL otherwise, surfacing the command and the
# asserts/produced_by/contract fields.
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

assert_same_file() {
    local one="$1" two="$2" label="$3" produced_by="$4" contract="$5"
    if [[ -s "$one" ]] && diff -q "$one" "$two" >/dev/null; then
        echo "  PASS  $current_scenario :: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario :: $label"
        echo "        asserts:     $label"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        if [[ -s "$one" ]]; then diff "$one" "$two" | head -10 | sed 's/^/        | /' || true; else echo "        (empty capture $one)"; fi
        fail=$((fail + 1))
        failures+=("$current_scenario :: $label")
    fi
}

scenario_deprecated_metric_spellings() {
    current_scenario="deprecated-metric-spellings"
    echo "[$current_scenario]"

    local spelling
    for spelling in time TIME; do
        run_ltl "dep-hm-$spelling" -bs 1440 -oe -V runtime-config,notices -hm "$spelling" "$METRIC_FIXTURE"
        notice_lines "$RUN_STDOUT" > "$RUN_STDOUT.notices"
        assert_line "$RUN_STDOUT" \
            pattern     '^heatmap: duration$' \
            asserts     "-hm $spelling draws the duration heatmap: time is a deprecated spelling of duration on -hm, in any case." \
            produced_by 'builtin_metric_name() in ltl (the deprecated spellings of @builtin_metrics)' \
            contract    "$CONTRACT_DEPRECATED"
        assert_one_line "$RUN_STDOUT.notices" "$TIME_NOTICE" "-hm $spelling raises exactly one deprecation notice naming time and duration" \
            'record_deprecation() and print_deprecation_notices() in ltl'
    done

    run_section_only "dep-hg-duration" histogram -V notices -hg duration "$METRIC_FIXTURE"
    local hg_duration="$RUN_STDOUT"
    without_notice_boxes "$hg_duration" > "$hg_duration.rendered"
    run_section_only "dep-hg-time" histogram -V notices -hg time "$METRIC_FIXTURE"
    without_notice_boxes "$RUN_STDOUT" > "$RUN_STDOUT.rendered"
    notice_lines "$RUN_STDOUT" > "$RUN_STDOUT.notices"
    assert_same_file "$hg_duration.rendered" "$RUN_STDOUT.rendered" '-hg time renders the histogram -hg duration renders' \
        'handle_histogram_option() in ltl, through builtin_metric_name()' "$CONTRACT_DEPRECATED"
    assert_one_line "$RUN_STDOUT.notices" "$TIME_NOTICE" '-hg time raises exactly one deprecation notice, though -hg is read inside the option parser' \
        'handle_histogram_option() records it; print_deprecation_notices() prints it at option settlement'

    run_section_only "dep-so-duration" messages -V notices -so duration "$METRIC_FIXTURE"
    local so_duration="$RUN_STDOUT"
    without_notice_boxes "$so_duration" > "$so_duration.rendered"
    run_section_only "dep-so-time" messages -V notices -so time "$METRIC_FIXTURE"
    without_notice_boxes "$RUN_STDOUT" > "$RUN_STDOUT.rendered"
    notice_lines "$RUN_STDOUT" > "$RUN_STDOUT.notices"
    assert_same_file "$so_duration.rendered" "$RUN_STDOUT.rendered" '-so time ranks the messages as -so duration does' \
        'adapt_to_command_line_options() in ltl (the -so bare metric word, through builtin_metric_name())' "$CONTRACT_DEPRECATED"
    assert_one_line "$RUN_STDOUT.notices" "$TIME_NOTICE" '-so time raises exactly one deprecation notice' \
        'record_deprecation() and print_deprecation_notices() in ltl'

    run_ltl "dep-all-three" -bs 1440 -oe -V notices -hm time -hg time -so time "$METRIC_FIXTURE"
    notice_lines "$RUN_STDOUT" > "$RUN_STDOUT.notices"
    assert_one_line "$RUN_STDOUT.notices" "$TIME_NOTICE" 'time given to -hm, -hg and -so in one run raises one notice, not three' \
        'record_deprecation() in ltl (one notice per spelling, naming every option it was given to)'
    assert_line "$RUN_STDOUT.notices" \
        pattern     '^deprecated-spelling \| time \| is deprecated as a metric name \(given to -hm/--heatmap, -hg/--histogram, -so/--sort-on\) \| - \| use duration$' \
        asserts     'The one notice names each option the deprecated spelling was given to, in the order the options are settled (-hm, -hg, -so).' \
        produced_by 'print_deprecation_notices() in ltl' \
        contract    "$CONTRACT_DEPRECATED"

    # -so size against -so bytes: the MESSAGES CSV, written into a directory
    # this harness owns, carries the whole ranking.
    local size_dir="$TMP_DIR/dep-so-size" bytes_dir="$TMP_DIR/dep-so-bytes"
    mkdir -p "$size_dir" "$bytes_dir"
    ( cd "$bytes_dir" && "$LTL" --disable-progress -ni -bs 1440 -oe -n 100 -o -V notices -so bytes "$METRIC_FIXTURE" > run.out 2> run.err ) || true
    ( cd "$size_dir"  && "$LTL" --disable-progress -ni -bs 1440 -oe -n 100 -o -V notices -so size  "$METRIC_FIXTURE" > run.out 2> run.err ) || true
    notice_lines "$bytes_dir/run.out" > "$bytes_dir/run.notices"
    notice_lines "$size_dir/run.out" > "$size_dir/run.notices"
    check_stderr_warnings "$bytes_dir/run.err"
    check_stderr_warnings "$size_dir/run.err"
    local bytes_csv size_csv
    bytes_csv=$(find "$bytes_dir" -name '*-LTL-MESSAGES-*.csv' -print -quit)
    size_csv=$(find "$size_dir" -name '*-LTL-MESSAGES-*.csv' -print -quit)
    assert_same_file "$bytes_csv" "$size_csv" '-so size writes the MESSAGES CSV -so bytes writes' \
        'adapt_to_command_line_options() in ltl (the -so bare metric word, through builtin_metric_name())' "$CONTRACT_DEPRECATED"
    assert_one_line "$size_dir/run.notices" '^deprecated-spelling \| size \| is deprecated as a metric name \(given to -so/--sort-on\) \| - \| use bytes$' \
        '-so size raises exactly one deprecation notice naming size and bytes' 'record_deprecation() and print_deprecation_notices() in ltl'
    assert_no_line "$bytes_dir/run.notices" \
        pattern     'deprecated|MISSING-SECTION' \
        evidence    '^=== notices ===$' in "$bytes_dir/run.out" \
        asserts     'The canonical name prints no deprecation line.' \
        produced_by 'builtin_metric_name() in ltl' \
        contract    "$CONTRACT_DEPRECATED"
}

# Issue #613 criterion 23 (D15): a built-in metric name matches in any case on
# every option that takes one.
scenario_metric_name_case() {
    current_scenario="metric-name-case"
    echo "[$current_scenario]"
    local contract='features/613-one-name-vocabulary.md D15 (every built-in name matches in any case on every option); criterion 23'

    run_ltl "case-hm" -bs 1440 -oe -V runtime-config -hm Bytes "$METRIC_FIXTURE"
    assert_line "$RUN_STDOUT" \
        pattern     '^heatmap: bytes$' \
        asserts     '-hm Bytes draws the bytes heatmap.' \
        produced_by 'builtin_metric_name() in ltl' \
        contract    "$contract"

    run_section_only "case-hg-lower" histogram -hg bytes "$METRIC_FIXTURE"
    local hg_lower="$RUN_STDOUT"
    run_section_only "case-hg-upper" histogram -hg BYTES "$METRIC_FIXTURE"
    assert_same_file "$hg_lower" "$RUN_STDOUT" '-hg BYTES renders the histogram -hg bytes renders' 'builtin_metric_name() in ltl' "$contract"

    run_section_only "case-so-lower" messages -so bytes "$METRIC_FIXTURE"
    local so_lower="$RUN_STDOUT"
    run_section_only "case-so-upper" messages -so Bytes "$METRIC_FIXTURE"
    assert_same_file "$so_lower" "$RUN_STDOUT" '-so Bytes ranks the messages as -so bytes does' 'builtin_metric_name() in ltl' "$contract"

    run_section_only "case-hide-lower" timeline --hide bytes "$METRIC_FIXTURE"
    local hide_lower="$RUN_STDOUT"
    run_section_only "case-hide-upper" timeline --hide Bytes "$METRIC_FIXTURE"
    assert_same_file "$hide_lower" "$RUN_STDOUT" '--hide Bytes hides the column --hide bytes hides' 'resolve_visibility_name() in ltl' "$contract"
}

# Issue #613 criterion 15 (D3): durationMs is a key spelling, not a metric
# name, so -hm takes it down the unknown-name path of any other word.
scenario_metric_key_spelling_unknown() {
    current_scenario="metric-key-spelling-unknown"
    echo "[$current_scenario]"
    local contract='features/613-one-name-vocabulary.md D3 (durationMs and durationMS are key spellings, not metric names: an unknown name on -hm and -hg); criterion 15; features/614-operand-settlement.md phase 2'

    run_ltl "key-hm-pushback" -bs 1440 -oe -hm durationMs "$METRIC_FIXTURE"
    assert_line "$RUN_STDERR" \
        pattern     "^Error: 'durationMs' matches no file \\(it followed -hm/--heatmap and is not a metric; the metrics are duration, bytes, count\\)$" \
        asserts     '-hm durationMs is given back as any unknown word is, and named as no metric when it selects no file.' \
        produced_by 'settle_optional_operand() and file_argument_problem() in ltl' \
        contract    "$contract"

    run_ltl "key-hg-list" -bs 1440 -oe -udm x::max -hg duration,durationMs "$METRIC_FIXTURE"
    assert_line "$RUN_STDERR" \
        pattern     "^Error: 'durationMs' given to -hg/--histogram is not a metric; the metrics are duration, bytes, count, x$" \
        asserts     'Inside an -hg list, durationMs is the rejection any unknown member gets.' \
        produced_by 'settle_optional_operand() in ltl (the -hg settlement)' \
        contract    "$contract"
}

# Issue #613 criterion 16 (D4): a user-defined metric is named by its name,
# so the key it reads is not a metric name on -hm.
scenario_udm_key_not_a_name() {
    current_scenario="udm-key-not-a-name"
    echo "[$current_scenario]"
    run_ltl "udm-key-hm" -bs 1440 -oe -udm 'lat::max:elapsed' -hm elapsed "$METRIC_FIXTURE"
    assert_line "$RUN_STDERR" \
        pattern     "^Error: 'elapsed' matches no file \\(it followed -hm/--heatmap and is not a metric; the metrics are duration, bytes, count, lat\\)$" \
        asserts     '-hm elapsed is not a metric when the metric reading elapsed is named lat: it is given back, and named with the vocabulary when it selects no file.' \
        produced_by 'resolve_metric_operand() and udm_config_by_name() in ltl' \
        contract    'features/613-one-name-vocabulary.md D4 (a user-defined metric is named by its name on every option); criterion 16'
}

scenario_error_unknown_exact_percentiles() {
    current_scenario="error-unknown-exact-percentiles"
    echo "[$current_scenario]"

    run_ltl "err-ep" --exact-percentiles "$TEST_LOG"

    assert_exit "$RUN_EXIT" 1 \
        evidence    "unknown option '--exact-percentiles'" in "$RUN_STDERR" \
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
        pattern     '^message_stats_data_model: bin$' \
        asserts     'A user-supplied -mdm bin appears in the runtime-config / command-line sub-section with its resolved value and no annotation, per #266 + #231.' \
        produced_by 'emit_runtime_config_verbose() in ltl - %resolved_values lookup for message-stats-data-model' \
        contract    'features/266-data-model-selectors.md section -V runtime-config surfacing + features/287-message-stats-bin-counter-data-model.md section R8.3 - selector row format is locked.'

    assert_line "$RUN_STDOUT" \
        pattern     '^bucket_stats_data_model: bin$' \
        asserts     'A user-supplied -bdm bin appears in the runtime-config / command-line sub-section with its resolved value and no annotation, per #266 + #231 (Issue #289 honors -bdm bin end-to-end).' \
        produced_by 'emit_runtime_config_verbose() in ltl - %resolved_values lookup for bucket-stats-data-model' \
        contract    'features/266-data-model-selectors.md section -V runtime-config surfacing + features/289-bucket-stats-bin-counter-data-model.md - selector row format is locked.'

    assert_line "$RUN_STDOUT" \
        pattern     '^data_model: bin$' \
        asserts     'A user-supplied omnibus -dm bin appears as the data-model row in the command-line sub-section, alongside any per-surface override.' \
        produced_by 'emit_runtime_config_verbose() in ltl' \
        contract    'features/266-data-model-selectors.md section -V runtime-config surfacing.'
}

scenario_runtime_config_numeric_highlight() {
    current_scenario="runtime-config-numeric-highlight"
    echo "[$current_scenario]"

    run_ltl "rc-hl" -V runtime-config -hdmin 100 -hbmax 5000 -hcmin 2 "$TEST_LOG"

    assert_line "$RUN_STDOUT" \
        pattern     '^highlight_duration_min: 100$' \
        asserts     'A user-supplied -hdmin appears in the runtime-config / command-line sub-section with its resolved value and no annotation.' \
        produced_by 'emit_runtime_config_verbose() in ltl - %resolved_values lookup for highlight-duration-min' \
        contract    'features/312-numeric-criteria-highlight-selection.md section -V runtime-config - the six highlight criteria join the resolved-values registry'

    assert_line "$RUN_STDOUT" \
        pattern     '^highlight_bytes_max: 5000$' \
        asserts     'A user-supplied -hbmax appears in the runtime-config / command-line sub-section with its resolved value and no annotation.' \
        produced_by 'emit_runtime_config_verbose() in ltl - %resolved_values lookup for highlight-bytes-max' \
        contract    'features/312-numeric-criteria-highlight-selection.md section -V runtime-config'

    assert_line "$RUN_STDOUT" \
        pattern     '^highlight_count_min: 2$' \
        asserts     'A user-supplied -hcmin appears in the runtime-config / command-line sub-section with its resolved value and no annotation.' \
        produced_by 'emit_runtime_config_verbose() in ltl - %resolved_values lookup for highlight-count-min' \
        contract    'features/312-numeric-criteria-highlight-selection.md section -V runtime-config'

    assert_line "$RUN_STDOUT" \
        pattern     '^highlight_merged: -$' \
        asserts     'The merged highlight regex line reports - (nothing set) when only numeric highlight criteria are given - numeric criteria do not synthesize a regex.' \
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
        pattern     '^expose_query_string: yes$' \
        asserts     'The alias still reports its own state: -xqs sets expose-query-string, whose row is unchanged by the new expose row.' \
        produced_by 'emit_runtime_config_verbose() in ltl' \
        contract    'features/566-preserve-named-values-in-message.md section D3 - the existing options are kept as aliases'

    assert_line "$RUN_STDOUT" \
        pattern     '^expose_user: yes$' \
        asserts     'The alias still reports its own state: -xu sets expose-user, whose row is unchanged by the new expose row.' \
        produced_by 'emit_runtime_config_verbose() in ltl' \
        contract    'features/566-preserve-named-values-in-message.md section D3 - the existing options are kept as aliases'
}

# Issue #580 criterion 11: the resolved mask names, in command-line order, a
# comma-separated list split and a repeated name kept once, and the mask_uuid
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
        pattern     '^mask_uuid: yes$' \
        asserts     'mask_uuid reports yes when UUIDs are masked through -m uuid, not only through the deprecated -uuid spelling.' \
        produced_by 'emit_runtime_config_verbose() in ltl - the mask_uuid row, given command-line provenance whenever -m was supplied' \
        contract    'features/580-mask-uuid-and-ip-address.md section D5 - mask_uuid reports yes when UUIDs are masked by either spelling'

    run_ltl "rc-mask-uuid" -V runtime-config -uuid "$TEST_LOG"
    assert_line "$RUN_STDOUT" \
        pattern     '^mask: uuid$' \
        asserts     'The deprecated -uuid spelling resolves to the mask name uuid and reports it on the mask row, so the two spellings read as one configuration.' \
        produced_by 'emit_runtime_config_verbose() in ltl - the mask row, given command-line provenance whenever -uuid was supplied' \
        contract    'features/580-mask-uuid-and-ip-address.md section D5 - -V runtime-config reports the effective configuration'
    assert_line "$RUN_STDOUT" \
        pattern     '^mask_uuid: yes$' \
        asserts     '-uuid still reports mask_uuid: yes, as it did before -m existed.' \
        produced_by 'emit_runtime_config_verbose() in ltl - the mask-uuid row' \
        contract    'features/580-mask-uuid-and-ip-address.md section D5 - mask-uuid stays'

    run_ltl "rc-mask-ip" -V runtime-config -m ip "$TEST_LOG"
    assert_line "$RUN_STDOUT" \
        pattern     '^mask: ip$' \
        asserts     'ip is reported as the name given, not expanded to ipv4,ipv6: the row is the configuration as the user stated it.' \
        produced_by 'emit_runtime_config_verbose() in ltl - the mask row' \
        contract    'features/580-mask-uuid-and-ip-address.md section D5 and section Acceptance criteria 11'
    assert_line "$RUN_STDOUT" \
        pattern     '^mask_uuid: no$' \
        asserts     'A mask that does not name uuid reports mask_uuid: no rather than omitting the row, so a reader of the section sees that UUIDs are not masked.' \
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
        pattern     '^omit_durations:' \
        evidence    '^=== runtime-config / command-line ===$' \
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
        pattern     '^omit_durations: yes$' \
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
        evidence    'invalid sort type' in "$RUN_STDERR" \
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

# Issue #525 D9: -tp is reported by its canonical token whatever spelling
# was given; a run that does not supply it emits no row.
scenario_runtime_config_timestamp_precision() {
    current_scenario="runtime-config-timestamp-precision"
    echo "[$current_scenario]"

    # Application logs whose timestamps carry milliseconds and microseconds,
    # so a request at or above the log's precision is reported unclamped.
    local ms_log="$TMP_DIR/tp-millis.log" us_log="$TMP_DIR/tp-micros.log"
    printf '%s\n' \
        '2026-01-26 10:00:01,123 [main] INFO  com.example.Service - first line' \
        '2026-01-26 10:00:02,456 [main] INFO  com.example.Service - second line' > "$ms_log"
    printf '%s\n' \
        '2026-01-26 10:00:01,123456 [main] INFO  com.example.Service - first line' \
        '2026-01-26 10:00:02,456789 [main] INFO  com.example.Service - second line' > "$us_log"

    local row spelling log want
    for row in "Millisecond|$ms_log|ms" "MSEC|$ms_log|ms" "microseconds|$us_log|us" "second|$ms_log|s"; do
        IFS='|' read -r spelling log want <<< "$row"
        run_ltl "rc-tp-$spelling" -V runtime-config -tp "$spelling" "$log"
        assert_line "$RUN_STDOUT" \
            pattern     "^timestamp_precision: $want\$" \
            asserts     "-tp $spelling appears in the runtime-config / command-line sub-section as its canonical token $want, with no annotation when the log carries that precision." \
            produced_by 'emit_runtime_config_verbose() in ltl - %resolved_values lookup for timestamp-precision, resolved by adapt_to_command_line_options()' \
            contract    'features/525-timestamp-precision-option.md D9 (a -V runtime-config key naming the precision) and features/225-test-harness-coverage-gaps.md section #231'
    done

    # Clamped: the resolved precision, and the request in the annotation.
    for row in "nanosecond|$us_log|us; clamped from ns|the finest the parse keeps" \
               "ms|$TEST_LOG|s; clamped from ms|the whole seconds the access log carries" \
               "us|$ms_log|ms; clamped from us|the milliseconds the log carries"; do
        local why
        IFS='|' read -r spelling log want why <<< "$row"
        run_ltl "rc-tp-clamp-$spelling" -V runtime-config -tp "$spelling" "$log"
        assert_line "$RUN_STDOUT" \
            pattern     "^timestamp_precision: $want\$" \
            asserts     "-tp $spelling resolves to $why; the row names the resolved precision and the request in the clamp annotation." \
            produced_by 'emit_runtime_config_verbose() in ltl - %option_overrides clamped_from; the row is resolved by resolve_timestamp_precision() after the read' \
            contract    'features/525-timestamp-precision-option.md D4 and D9 (the requested and the resolved precision, machine-readable) and features/225-test-harness-coverage-gaps.md section #231 (the clamped-from annotation)'
    done

    run_ltl "rc-tp-absent" -V runtime-config "$TEST_LOG"
    assert_no_line "$RUN_STDOUT" \
        pattern     '^timestamp_precision:' \
        evidence    '^=== runtime-config / command-line ===$' \
        asserts     'A run that does not supply -tp emits no timestamp-precision row: defaults are documented, not duplicated in the section.' \
        produced_by 'emit_runtime_config_verbose() in ltl (provenance partitioning)' \
        contract    'features/225-test-harness-coverage-gaps.md section #231'
}

scenario_error_unknown_du() {
    current_scenario="error-unknown-du"
    echo "[$current_scenario]"

    run_ltl "err-du" -du x "$TEST_LOG"
    assert_exit "$RUN_EXIT" 1 \
        evidence    'Invalid duration unit' in "$RUN_STDERR" \
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
        evidence    'Invalid rate unit' in "$RUN_STDERR" \
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
        evidence    'unable to open any files' in "$RUN_STDERR" \
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
        evidence    'LINES READ' in "$RUN_STDOUT" \
        asserts     'A run with valid flags and a valid file exits 0.' \
        produced_by 'normal ltl execution' \
        contract    'baseline'

    # None of the silent-override warnings should fire on a clean run.
    assert_no_line "$RUN_STDERR" \
        pattern     "matches no file|is not a metric|given to" \
        evidence    'LINES READ' in "$RUN_STDOUT" \
        asserts     'A clean run produces none of the silent-override warnings. This guards against the warnings firing on inputs they were not designed for.' \
        produced_by 'adapt_to_command_line_options() in ltl' \
        contract    'features/225-test-harness-coverage-gaps.md section #231 - warnings are gated on specific input shapes'
}

scenario_info_version_wins_over_parse_error() {
    current_scenario="info-version-wins-over-parse-error"
    echo "[$current_scenario]"

    run_ltl "info-ver" --version -b 5 "$TEST_LOG"
    assert_exit "$RUN_EXIT" 0 \
        evidence    '^Version: ' in "$RUN_STDOUT" \
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
        evidence    'USAGE' in "$RUN_STDOUT" \
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
        evidence    "unknown option '-b'" in "$RUN_STDERR" \
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
                  pushback-silent \
                  pushback-not-a-file \
                  list-member-unknown \
                  udm-position \
                  optional-operand-source \
                  error-unknown-metric-lists \
                  deprecated-metric-spellings \
                  metric-name-case \
                  metric-key-spelling-unknown \
                  udm-key-not-a-name \
                  error-unknown-exact-percentiles \
                  runtime-config-data-model-selectors \
                  runtime-config-numeric-highlight \
                  runtime-config-timestamp-precision \
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
        pushback-silent                    ) scenario_pushback_silent ;;
        pushback-not-a-file                ) scenario_pushback_not_a_file ;;
        list-member-unknown                ) scenario_list_member_unknown ;;
        udm-position                       ) scenario_udm_position ;;
        optional-operand-source            ) scenario_optional_operand_source ;;
        error-unknown-metric-lists         ) scenario_error_unknown_metric_lists ;;
        deprecated-metric-spellings        ) scenario_deprecated_metric_spellings ;;
        metric-name-case                   ) scenario_metric_name_case ;;
        metric-key-spelling-unknown        ) scenario_metric_key_spelling_unknown ;;
        udm-key-not-a-name                 ) scenario_udm_key_not_a_name ;;
        error-unknown-exact-percentiles    ) scenario_error_unknown_exact_percentiles ;;
        runtime-config-data-model-selectors) scenario_runtime_config_data_model_selectors ;;
        runtime-config-numeric-highlight   ) scenario_runtime_config_numeric_highlight ;;
        runtime-config-timestamp-precision ) scenario_runtime_config_timestamp_precision ;;
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
