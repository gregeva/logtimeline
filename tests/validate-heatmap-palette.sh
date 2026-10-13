#!/usr/bin/env bash
# validate-heatmap-palette.sh — Validate the heatmap-palette `-V` section
# emits the resolved palette state under each light/dark selection path
# and each heatmap metric (Issue #250), and that a user-defined heatmap
# takes the colour of its spec position, with or without a timeline column
# (Issues #678, #713).
# Usage: ./tests/validate-heatmap-palette.sh
#
# Follows the self-documenting assertion design from tests/HARNESS-DESIGN.md.
# Every assertion records:
#   - asserts:     the application invariant being tested
#   - produced_by: where in ltl the invariant is produced (function name)
#   - contract:    the stability contract that makes it stable
# All three are surfaced on failure so the reader can act without
# opening external docs.
#
# Why this harness exists: the heatmap-palette section is the contract
# point that lets a harness validate the light/dark selection branch
# without grepping rendered ANSI from the bar graph (which HARNESS-DESIGN.md
# explicitly forbids). The section reports the gradient array that
# print_heatmap_row() will use, plus the provenance of the light_bg flag,
# so this harness can guard the -lbg / -dbg / auto-detect / default
# branches and the -dbg-wins-over-lbg precedence rule.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib/logs-dir.sh
source "$SCRIPT_DIR/lib/logs-dir.sh"
LTL="$REPO_DIR/ltl"
# Invocation shape (tests/HARNESS-DESIGN.md section Invocation coherence):
# the palette scenarios read the -V heatmap-palette section - the resolved
# metric, palette and background source, all option-derived - never a
# heatmap cell; the user-defined scenarios below carry their own shape. The 5k ScriptLog slice (durationMS, bytes and count on
# every line, so each -hm metric resolves) at `-bs 1440 -oe -n 1 -osum`
# produces the identical section.
SCRIPT_LOG="$LOGS_DIR/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean-5k.log"
SHAPE="-bs 1440 -oe -n 1 -osum"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"
# shellcheck source=lib/rendered-output.sh
source "$SCRIPT_DIR/lib/rendered-output.sh"

# Ambient FORCE_COLOR/NO_COLOR must not decide what this harness asserts
# against (tests/HARNESS-DESIGN.md section Colour rendering is controlled,
# never inherited; issue #438).
neutralize_colour_env


if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"
    exit 1
fi
if [[ ! -f "$SCRIPT_LOG" ]]; then
    echo "ERROR: SCRIPT_LOG not found: $SCRIPT_LOG"
    exit 1
fi

# Expected gradient arrays — sourced from the canonical definitions in ltl:
#   yellow (duration): @column_colors entry (ltl GLOBALS)
#   green  (bytes):    @column_colors entry (ltl GLOBALS)
#   cyan   (count):    @column_colors entry (ltl GLOBALS)
# The harness asserts the section emits these literal arrays; a code-side
# change to any gradient is a breaking change that requires updating both
# the array and this expected-value table in the same commit.
YELLOW_DARK='58,94,136,142,178,184,220,226'
YELLOW_LIGHT='230,229,228,227,220,214,208,202'
GREEN_DARK='22,28,34,40,46,82,118,154'
GREEN_LIGHT='194,157,120,84,48,42,36,35'
CYAN_DARK='23,30,37,44,51,80,86,123'
CYAN_LIGHT='195,159,123,87,51,44,37,30'

pass=0
fail=0
failures=()
current_scenario=""

# Run ltl with -V heatmap-palette and the standard suppression flag.
# Captures combined output to a temp file, echoes the path.
# Args after the function name are forwarded verbatim before the input file.
run_section() {
    local outfile
    outfile=$(mktemp)
    # shellcheck disable=SC2086
    "$LTL" --disable-progress -ni $SHAPE -V heatmap-palette "$@" "$SCRIPT_LOG" > "$outfile" 2>"$outfile.stderr" || true
    if [[ ! -s "$outfile" ]]; then
        echo "FAIL: captured output is empty for: $LTL --disable-progress -ni $SHAPE -V heatmap-palette $* $SCRIPT_LOG" >&2
        exit 1
    fi
    echo "$outfile"
}

# Runtime-warning cleanliness for a run_section capture (its stderr lives
# beside the captured stdout as <capture>.stderr). Runs in the main shell so
# the fail counters persist - a command-substitution subshell could not
# update them. HARNESS-DESIGN.md section Runtime-warning cleanliness.
check_capture_warnings() {
    local capture="$1"
    if ! assert_no_runtime_warnings "$capture.stderr" "$current_scenario"; then
        fail=$((fail + 1))
        failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
    fi
}

# Self-documenting assertion: a line matching `pattern` must be present.
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

# Common: the section header must be present (HARNESS-DESIGN.md "must fail
# on missing anchors" — guards against a silent rename).
assert_header_present() {
    local outfile="$1"
    assert_line "$outfile" \
        pattern     '^=== heatmap-palette ===$' \
        asserts     'The heatmap-palette section is emitted whenever -V heatmap-palette is requested, regardless of whether heatmap mode is active' \
        produced_by 'emit_heatmap_palette_verbose() in ltl' \
        contract    'Issue #250 + tests/HARNESS-DESIGN.md section Reserved section names - section name is stability-contracted; renames are breaking'
    assert_line "$outfile" \
        pattern     '^=== END heatmap-palette ===$' \
        asserts     'The heatmap-palette section closes with an explicit END marker so harnesses can use sed-range extraction unambiguously' \
        produced_by 'emit_heatmap_palette_verbose() in ltl' \
        contract    'tests/HARNESS-DESIGN.md section Delimiter contract - END markers are required'
}

# ---------------------------------------------------------------------------
# Scenario: no heatmap mode (sanity — section emits with - for every absent field)
# ---------------------------------------------------------------------------
scenario_no_heatmap() {
    scenario_wanted no-heatmap || return 0
    current_scenario="no-heatmap"
    echo "[$current_scenario]"
    local out
    out=$(run_section)
    check_capture_warnings "$out"

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^heatmap_active: no$' \
        asserts     'When -hm is not on the command line, heatmap_active reports `no` and the metric/color/gradient fields are placeholders' \
        produced_by 'emit_heatmap_palette_verbose() in ltl (inactive branch)' \
        contract    'Issue #250 - section reports inactive state without crashing when heatmap is off'

    assert_line "$out" \
        pattern     '^metric: -$' \
        asserts     'metric reports `-` when no heatmap metric is selected' \
        produced_by 'emit_heatmap_palette_verbose() in ltl (inactive branch)' \
        contract    'Issue #250 - locked placeholder for absent metric'

    assert_line "$out" \
        pattern     '^gradient_active: -$' \
        asserts     'gradient_active reports `-` when no heatmap is rendering - neither dark nor light branch is selected' \
        produced_by 'emit_heatmap_palette_verbose() in ltl (inactive branch)' \
        contract    'Issue #250 - locked placeholder for absent gradient selection'
}

# ---------------------------------------------------------------------------
# Per-palette scenarios — each forces dark or light and asserts metric,
# color name, the matching gradient array literal, gradient_active, and
# light_bg_source.
# ---------------------------------------------------------------------------

# Args: scenario_name, ltl_args, expected_metric, expected_color,
#       expected_light_bg ("no"|"yes"), expected_source, expected_active ("dark"|"light"),
#       expected_gradient_dark, expected_gradient_light
scenario_palette() {
    scenario_wanted "$1" || return 0
    local name="$1"; shift
    local ltl_args="$1"; shift
    local exp_metric="$1"; shift
    local exp_color="$1"; shift
    local exp_lbg="$1"; shift
    local exp_source="$1"; shift
    local exp_active="$1"; shift
    local exp_dark="$1"; shift
    local exp_light="$1"; shift

    current_scenario="$name"
    echo "[$current_scenario]"
    local out
    # shellcheck disable=SC2086
    out=$(run_section $ltl_args)
    check_capture_warnings "$out"

    assert_header_present "$out"

    assert_line "$out" \
        pattern     "^heatmap_active: yes\$" \
        asserts     "When -hm is on the command line, heatmap_active reports \`yes\`" \
        produced_by 'emit_heatmap_palette_verbose() in ltl (active branch)' \
        contract    'Issue #250 - locked field value when heatmap mode is enabled'

    assert_line "$out" \
        pattern     "^metric: ${exp_metric}\$" \
        asserts     "metric reports the heatmap metric selected via -hm (${exp_metric})" \
        produced_by 'emit_heatmap_palette_verbose() in ltl (resolves $heatmap_metric)' \
        contract    'Issue #250 - metric field tracks $heatmap_metric verbatim'

    assert_line "$out" \
        pattern     "^color_name: ${exp_color}\$" \
        asserts     "color_name reports the column color (${exp_color}) bound to the heatmap metric via %heatmap_metric_map and resolved through %column_color_lookup" \
        produced_by 'emit_heatmap_palette_verbose() in ltl (resolves $heatmap_metric_map{$heatmap_metric}{color})' \
        contract    'Issue #250 - metric-to-color binding is the same resolution print_heatmap_row() performs at ltl:7830-7831'

    assert_line "$out" \
        pattern     "^light_bg: ${exp_lbg}\$" \
        asserts     "light_bg reports the resolved value of \$heatmap_light_bg (${exp_lbg}) that print_heatmap_row() will branch on" \
        produced_by 'emit_heatmap_palette_verbose() in ltl' \
        contract    'Issue #250 - light_bg field equals the runtime value read by print_heatmap_row()'

    assert_line "$out" \
        pattern     "^light_bg_source: ${exp_source}\$" \
        asserts     "light_bg_source reports the provenance of the light_bg decision (${exp_source}); precedence: -dbg > -lbg > auto-detect > default" \
        produced_by 'adapt_to_command_line_options() in ltl - set by -lbg callback, -dbg reconciliation block, and auto-detect block' \
        contract    'Issue #250 - \$heatmap_light_bg_source is the canonical provenance signal; the four enumerated values are the only valid emissions'

    assert_line "$out" \
        pattern     "^gradient_dark: ${exp_dark}\$" \
        asserts     "gradient_dark reports the dark-palette 256-color array for the active metric's color (${exp_color}); this is the literal array @column_colors carries in ltl GLOBALS" \
        produced_by 'emit_heatmap_palette_verbose() in ltl (joins @{$entry->{gradient}} with commas)' \
        contract    'Issue #250 - gradient arrays in @column_colors are part of the heatmap-palette contract surface; changes require updating this harness in the same commit'

    assert_line "$out" \
        pattern     "^gradient_light: ${exp_light}\$" \
        asserts     "gradient_light reports the light-palette 256-color array for the active metric's color (${exp_color}); this is the literal array @column_colors carries in ltl GLOBALS" \
        produced_by 'emit_heatmap_palette_verbose() in ltl (joins @{$entry->{gradient_light}} with commas)' \
        contract    'Issue #250 - gradient arrays in @column_colors are part of the heatmap-palette contract surface; changes require updating this harness in the same commit'

    assert_line "$out" \
        pattern     "^gradient_active: ${exp_active}\$" \
        asserts     "gradient_active reports which branch (${exp_active}) print_heatmap_row() will pick when rendering; load-bearing line for visual palette coverage" \
        produced_by 'emit_heatmap_palette_verbose() in ltl (\$heatmap_light_bg ? "light" : "dark")' \
        contract    'Issue #250 - gradient_active is the contract for which palette renders'
}

# ---------------------------------------------------------------------------
# User-defined heatmap colour scenarios (features/678-heatmap-udm-without-column.md
# acceptance criteria AC1 to AC5). A user-defined metric's colour is fixed by
# its position among the -udm specs, for its timeline column and its heatmap
# alike (D1), and a heatmap of a metric that captured nothing renders empty in
# that colour (D3).
#
# Invocation shape: `-bs 1440 -oe -n 1 -osum` gives the one timeline row the
# column and heatmap cells are read from and switches off the message table and
# the summary, which nothing here reads; `--terminal-width 120 --debug-layout`
# pins the layout and prints the engine's column offsets, through which a
# column's cells are cut (tests/HARNESS-DESIGN.md section Asserting rendered
# output). The two fixtures are the smallest carrying each signal: two
# application-log lines with `elapsed=0` and non-zero `a` and `b`, and the
# twelve-line access log, which carries no `x`.
# ---------------------------------------------------------------------------
UDM_FIXTURE="$REPO_DIR/tests/fixtures/udm-heatmap-colour.txt"
NO_VALUE_FIXTURE="$REPO_DIR/tests/fixtures/tomcat-access-single-sample-keys.txt"
UDM_SHAPE="-bs 1440 -oe -n 1 -osum --terminal-width 120 --debug-layout"
UDM_ROW='^ *20[0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]'

# The fill (plain background) of each colour a dynamic column can take, from
# the @column_colors entries in ltl GLOBALS (plain_bg_num). A code-side change
# to these is a breaking change for this table, as for the gradient arrays.
declare -A PLAIN_BG_NUM=(
    [yellow]=184 [green]=34 [cyan]=30 [blue]=20 [magenta]=127
    [red]=124 [orange]=166 [pink]=169 [teal]=29 [purple]=55
)

UDM_TMP=$(mktemp -d); trap 'rm -rf "$UDM_TMP"' EXIT

for f in "$UDM_FIXTURE" "$NO_VALUE_FIXTURE"; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: fixture not found: $f"
        exit 1
    fi
done

# run_udm NAME INPUT ARGS... : one ltl run; NAME.out (stdout), NAME.stderr,
# NAME.exit (status) and NAME.all (stderr then stdout: the debug-layout table
# prints to stderr, the rows to stdout) under $UDM_TMP. The status is recorded,
# never swallowed: a run that ends with an error is what AC1 and AC2 assert
# against.
run_udm() {
    local name="$1" input="$2"; shift 2
    local base="$UDM_TMP/$name"
    set +e
    # shellcheck disable=SC2086
    "$LTL" --disable-progress $UDM_SHAPE -V heatmap-palette "$@" "$input" > "$base.out" 2> "$base.stderr"
    echo "$?" > "$base.exit"
    set -e
    cat "$base.stderr" "$base.out" > "$base.all"
    if [[ ! -s "$base.out" ]]; then
        echo "FAIL: captured output is empty for: $LTL --disable-progress $UDM_SHAPE -V heatmap-palette $* $input" >&2
        exit 1
    fi
    check_capture_warnings "$base"
}

# Self-documenting assertion over a command (eval'd; PASS on exit 0).
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

    local diag
    if diag=$(eval "$command" 2>&1); then
        echo "  PASS  $current_scenario :: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario :: $label"
        echo "        command:     $command"
        [[ -n "$diag" ]] && printf '        output:      %s\n' "$diag"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
        failures+=("$current_scenario :: $label")
    fi
}

# The color_name a capture's heatmap-palette section reports; fails on none.
palette_colour() {
    local c
    c=$(sed -n 's/^color_name: //p' "$UDM_TMP/$1.out")
    [[ -n "$c" ]] || { echo "no color_name line in $UDM_TMP/$1.out"; return 1; }
    echo "$c"
}

# The fill colour of a column on the timeline row, read through the layout
# engine's offsets; fails when the row or the column is missing.
column_fill() {
    local report
    report=$(timeline_cell_report "$UDM_TMP/$1.all" "$UDM_ROW" "$2") || return 1
    sed -E 's/.* fill=([^ ]+).*/\1/' <<< "$report"
}

# AC1: every captured value is zero.
scenario_udm_all_zero() {
    scenario_wanted udm-all-zero || return 0
    current_scenario="udm-all-zero"
    echo "[$current_scenario]"
    sed 's/elapsed=0/elapsed=5/' "$UDM_FIXTURE" > "$UDM_TMP/elapsed-five.txt"
    run_udm zero    "$UDM_FIXTURE"              -udm 'elapsed:s:max' -hm elapsed
    run_udm control "$UDM_TMP/elapsed-five.txt" -udm 'elapsed:s:max' -hm elapsed

    assert_command \
        command     "[[ \$(cat '$UDM_TMP/zero.exit') == 0 ]] || { echo \"exit \$(cat '$UDM_TMP/zero.exit')\"; tail -3 '$UDM_TMP/zero.stderr'; false; }" \
        label       'a heatmap of an all-zero user-defined metric exits 0' \
        asserts     'A run whose -hm metric is a user-defined metric whose every captured value is zero completes; it no longer dies drawing the heatmap' \
        produced_by 'print_heatmap_row() in ltl (the gradient lookup through $heatmap_metric_map{...}{color})' \
        contract    'features/678-heatmap-udm-without-column.md AC1 (issue #678)'

    assert_command \
        command     "z=\$(palette_colour zero) && c=\$(palette_colour control) && [[ \$z != '-' && \$z == \$c ]] || { echo \"all-zero: \$z  control: \$c\"; false; }" \
        label       'the all-zero heatmap names the colour the same spec takes when it captures non-zero values' \
        asserts     'An all-zero user-defined heatmap has the colour of its spec position, the colour the same spec takes on the same lines carrying elapsed=5' \
        produced_by 'normalize_data_for_output() in ltl (user-defined colours resolved by spec position into %heatmap_metric_map)' \
        contract    'features/678-heatmap-udm-without-column.md D1 and AC1'
}

# AC2 and AC3: the metric captured nothing.
scenario_udm_no_value() {
    scenario_wanted udm-no-value || return 0
    current_scenario="udm-no-value"
    echo "[$current_scenario]"
    run_udm none "$NO_VALUE_FIXTURE" -udm x::max -hm x

    assert_command \
        command     "[[ \$(cat '$UDM_TMP/none.exit') == 0 ]] || { echo \"exit \$(cat '$UDM_TMP/none.exit')\"; tail -3 '$UDM_TMP/none.stderr'; false; }" \
        label       'a heatmap of a user-defined metric that captured nothing exits 0' \
        asserts     'A run whose -hm metric is a user-defined metric that captured no value completes; it no longer dies drawing the heatmap' \
        produced_by 'print_heatmap_row() in ltl (the gradient lookup through $heatmap_metric_map{...}{color})' \
        contract    'features/678-heatmap-udm-without-column.md AC2 (issue #713)'

    assert_line "$UDM_TMP/none.out" \
        pattern     '^color_name: [a-z]+$' \
        asserts     'A heatmap of a metric that captured nothing still names a colour: its spec position decides it, not the presence of a timeline column' \
        produced_by 'normalize_data_for_output() in ltl (user-defined colours resolved by spec position into %heatmap_metric_map)' \
        contract    'features/678-heatmap-udm-without-column.md D1 and AC2'

    assert_command \
        command     "n=\$(grep -c \"^Note: -udm 'x::max': no metrics produced from matching lines\$\" '$UDM_TMP/none.stderr'); [[ \$n == 1 ]] || { echo \"notice lines: \$n\"; false; }" \
        label       'the zero-match notice prints once for the one spec' \
        asserts     'The existing zero-match notice is printed exactly as defined, once per spec that produced nothing: here once' \
        produced_by 'emit_udm_zero_match_notices() in ltl' \
        contract    'features/user-defined-metrics.md D8 and D9; features/678-heatmap-udm-without-column.md AC2'

    assert_command \
        command     "sed -E 's/\\x1b\\[[0-9;]*m//g' '$UDM_TMP/none.out' | grep -qE '(^|[^0-9])0 +heatmap \\[x\\] +0 *\$' || { sed -E 's/\\x1b\\[[0-9;]*m//g' '$UDM_TMP/none.out' | grep 'heatmap \\['; false; }" \
        label       'the heatmap header reads 0 at both ends' \
        asserts     'A heatmap of a metric that captured nothing shows its header at 0 at both ends, as the built-in duration does with no durations' \
        produced_by 'get_heatmap_column_header() in ltl' \
        contract    'features/678-heatmap-udm-without-column.md D3 and AC3'

    assert_command \
        command     "f=\$(sed -E 's/\\x1b\\[[0-9;]*m//g' '$UDM_TMP/none.out' | grep '┴' | sed 's/.*┴//') && [[ -n \$f && \$f =~ 0 && \$f =~ ^[─0]+\$ ]] || { echo \"footer: \$f\"; false; }" \
        label       'every heatmap footer tick reads 0' \
        asserts     'A heatmap of a metric that captured nothing shows every footer tick at 0' \
        produced_by 'print_heatmap_footer_scale() in ltl' \
        contract    'features/678-heatmap-udm-without-column.md D3 and AC3'

    assert_command \
        command     "r=\$(timeline_cell_report '$UDM_TMP/none.all' '$UDM_ROW' heatmap) && [[ \$r =~ ^text=\\'\\ +\\' && \$r == *' extent=0 fill=none '* ]] || { echo \"\$r\"; false; }" \
        label       'every heatmap cell on the row is empty' \
        asserts     'A heatmap of a metric that captured nothing draws no cell: its part of the row is blank, nothing filled, as the built-in duration renders with no durations' \
        produced_by 'print_heatmap_row() in ltl' \
        contract    'features/678-heatmap-udm-without-column.md D3 and AC3'
}

# AC4: a column's colour does not depend on another metric's data.
scenario_udm_colour_by_position() {
    scenario_wanted udm-colour-by-position || return 0
    current_scenario="udm-colour-by-position"
    echo "[$current_scenario]"
    run_udm first-empty "$UDM_FIXTURE" -udm x::max -udm b::max -hm b
    run_udm both        "$UDM_FIXTURE" -udm a::max -udm b::max -hm b

    assert_command \
        command     "e=\$(column_fill first-empty udm_b) && c=\$(column_fill both udm_b) && [[ \$e != none && \$e == \$c ]] || { echo \"first spec empty: \$e  both capture: \$c\"; false; }" \
        label       "the second spec's column keeps its colour when the first spec captures nothing" \
        asserts     "A user-defined metric's timeline column takes the colour of its spec position: the second spec's column fill is the same whether or not the first spec captured data" \
        produced_by 'normalize_data_for_output() in ltl (add_dynamic_column for each -udm spec, colour by spec position)' \
        contract    'features/678-heatmap-udm-without-column.md D1, D2 and AC4'
}

# AC5: the heatmap reads its column's colour.
scenario_udm_heatmap_matches_column() {
    scenario_wanted udm-heatmap-matches-column || return 0
    current_scenario="udm-heatmap-matches-column"
    echo "[$current_scenario]"
    run_udm first-empty-hm "$UDM_FIXTURE" -udm x::max -udm b::max -hm b

    assert_command \
        command     "n=\$(palette_colour first-empty-hm) && f=\$(column_fill first-empty-hm udm_b) && [[ -n \${PLAIN_BG_NUM[\$n]:-} && \$f == \"256:\${PLAIN_BG_NUM[\$n]}\" ]] || { echo \"heatmap colour: \$n (fill 256:\${PLAIN_BG_NUM[\$n]:-?})  column fill: \$f\"; false; }" \
        label       'the heatmap names the colour its timeline column is filled with' \
        asserts     'A user-defined heatmap and its timeline column read one colour: the colour the heatmap-palette section names fills the column' \
        produced_by 'normalize_data_for_output() in ltl (the colour resolved once per spec, read by the column and %heatmap_metric_map)' \
        contract    'features/678-heatmap-udm-without-column.md D1 and AC5'
}

# ---------------------------------------------------------------------------
# Run scenarios
# ---------------------------------------------------------------------------

echo "Validating heatmap-palette -V section (Issue #250)"
echo ""

# Scenario selector (tests/HARNESS-DESIGN.md section The scenario selector).
# One scenario per palette case; the name is the first argument each
# scenario_palette call already carries.
SCENARIO_USAGE_NOTE="  (one scenario per heatmap palette case)"
scenario_register no-heatmap \
                  dbg-duration \
                  dbg-bytes \
                  dbg-count \
                  lbg-duration \
                  lbg-bytes \
                  lbg-count \
                  precedence-lbg-then-dbg \
                  precedence-dbg-then-lbg \
                  udm-all-zero \
                  udm-no-value \
                  udm-colour-by-position \
                  udm-heatmap-matches-column
scenario_parse_args "$@"

scenario_no_heatmap
echo ""

# --- -dbg path: each of three metrics ---
scenario_palette "dbg-duration" \
    "-hm duration -dbg" \
    "duration" "yellow" "no" "-dbg" "dark" \
    "$YELLOW_DARK" "$YELLOW_LIGHT"
echo ""

scenario_palette "dbg-bytes" \
    "-hm bytes -dbg" \
    "bytes" "green" "no" "-dbg" "dark" \
    "$GREEN_DARK" "$GREEN_LIGHT"
echo ""

scenario_palette "dbg-count" \
    "-hm count -dbg" \
    "count" "cyan" "no" "-dbg" "dark" \
    "$CYAN_DARK" "$CYAN_LIGHT"
echo ""

# --- -lbg path: each of three metrics ---
scenario_palette "lbg-duration" \
    "-hm duration -lbg" \
    "duration" "yellow" "yes" "-lbg" "light" \
    "$YELLOW_DARK" "$YELLOW_LIGHT"
echo ""

scenario_palette "lbg-bytes" \
    "-hm bytes -lbg" \
    "bytes" "green" "yes" "-lbg" "light" \
    "$GREEN_DARK" "$GREEN_LIGHT"
echo ""

scenario_palette "lbg-count" \
    "-hm count -lbg" \
    "count" "cyan" "yes" "-lbg" "light" \
    "$CYAN_DARK" "$CYAN_LIGHT"
echo ""

# --- Precedence: -dbg wins over -lbg regardless of CLI order ---
scenario_palette "precedence-lbg-then-dbg" \
    "-hm duration -lbg -dbg" \
    "duration" "yellow" "no" "-dbg" "dark" \
    "$YELLOW_DARK" "$YELLOW_LIGHT"
echo ""

scenario_palette "precedence-dbg-then-lbg" \
    "-hm duration -dbg -lbg" \
    "duration" "yellow" "no" "-dbg" "dark" \
    "$YELLOW_DARK" "$YELLOW_LIGHT"
echo ""

scenario_udm_all_zero
echo ""
scenario_udm_no_value
echo ""
scenario_udm_colour_by_position
echo ""
scenario_udm_heatmap_matches_column

echo ""
echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
echo "ALL HEATMAP-PALETTE TESTS PASSED"
