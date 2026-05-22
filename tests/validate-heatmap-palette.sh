#!/usr/bin/env bash
# validate-heatmap-palette.sh — Validate the heatmap-palette `-V` section
# emits the resolved palette state under each light/dark selection path
# and each heatmap metric (Issue #250).
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
LTL="$REPO_DIR/ltl"
SCRIPT_LOG="$REPO_DIR/logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log"

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
    "$LTL" --disable-progress -V heatmap-palette "$@" "$SCRIPT_LOG" > "$outfile" 2>&1 || true
    if [[ ! -s "$outfile" ]]; then
        echo "FAIL: captured output is empty for: $LTL --disable-progress -V heatmap-palette $* $SCRIPT_LOG" >&2
        exit 1
    fi
    echo "$outfile"
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
        contract    'Issue #250 + tests/HARNESS-DESIGN.md § Reserved section names — section name is stability-contracted; renames are breaking'
    assert_line "$outfile" \
        pattern     '^=== END heatmap-palette ===$' \
        asserts     'The heatmap-palette section closes with an explicit END marker so harnesses can use sed-range extraction unambiguously' \
        produced_by 'emit_heatmap_palette_verbose() in ltl' \
        contract    'tests/HARNESS-DESIGN.md § Delimiter contract — END markers are required'
}

# ---------------------------------------------------------------------------
# Scenario: no heatmap mode (sanity — section emits with n/a fields)
# ---------------------------------------------------------------------------
scenario_no_heatmap() {
    current_scenario="no-heatmap"
    echo "[$current_scenario]"
    local out
    out=$(run_section)

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^heatmap_active: no$' \
        asserts     'When -hm is not on the command line, heatmap_active reports `no` and the metric/color/gradient fields are placeholders' \
        produced_by 'emit_heatmap_palette_verbose() in ltl (inactive branch)' \
        contract    'Issue #250 — section reports inactive state without crashing when heatmap is off'

    assert_line "$out" \
        pattern     '^metric: n/a$' \
        asserts     'metric reports `n/a` when no heatmap metric is selected' \
        produced_by 'emit_heatmap_palette_verbose() in ltl (inactive branch)' \
        contract    'Issue #250 — locked placeholder for absent metric'

    assert_line "$out" \
        pattern     '^gradient_active: n/a$' \
        asserts     'gradient_active reports `n/a` when no heatmap is rendering — neither dark nor light branch is selected' \
        produced_by 'emit_heatmap_palette_verbose() in ltl (inactive branch)' \
        contract    'Issue #250 — locked placeholder for absent gradient selection'
}

# ---------------------------------------------------------------------------
# Per-palette scenarios — each forces dark or light and asserts metric,
# color name, the matching gradient array literal, gradient_active, and
# light_bg_source.
# ---------------------------------------------------------------------------

# Args: scenario_name, ltl_args, expected_metric, expected_color,
#       expected_light_bg ("0"|"1"), expected_source, expected_active ("dark"|"light"),
#       expected_gradient_dark, expected_gradient_light
scenario_palette() {
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

    assert_header_present "$out"

    assert_line "$out" \
        pattern     "^heatmap_active: yes\$" \
        asserts     "When -hm is on the command line, heatmap_active reports \`yes\`" \
        produced_by 'emit_heatmap_palette_verbose() in ltl (active branch)' \
        contract    'Issue #250 — locked field value when heatmap mode is enabled'

    assert_line "$out" \
        pattern     "^metric: ${exp_metric}\$" \
        asserts     "metric reports the heatmap metric selected via -hm (${exp_metric})" \
        produced_by 'emit_heatmap_palette_verbose() in ltl (resolves $heatmap_metric)' \
        contract    'Issue #250 — metric field tracks $heatmap_metric verbatim'

    assert_line "$out" \
        pattern     "^color_name: ${exp_color}\$" \
        asserts     "color_name reports the column color (${exp_color}) bound to the heatmap metric via %heatmap_metric_map and resolved through %column_color_lookup" \
        produced_by 'emit_heatmap_palette_verbose() in ltl (resolves $heatmap_metric_map{$heatmap_metric}{color})' \
        contract    'Issue #250 — metric-to-color binding is the same resolution print_heatmap_row() performs at ltl:7830-7831'

    assert_line "$out" \
        pattern     "^light_bg: ${exp_lbg}\$" \
        asserts     "light_bg reports the resolved value of \$heatmap_light_bg (${exp_lbg}) that print_heatmap_row() will branch on" \
        produced_by 'emit_heatmap_palette_verbose() in ltl' \
        contract    'Issue #250 — light_bg field equals the runtime value read by print_heatmap_row()'

    assert_line "$out" \
        pattern     "^light_bg_source: ${exp_source}\$" \
        asserts     "light_bg_source reports the provenance of the light_bg decision (${exp_source}); precedence: -dbg > -lbg > auto-detect > default" \
        produced_by 'adapt_to_command_line_options() in ltl — set by -lbg callback, -dbg reconciliation block, and auto-detect block' \
        contract    'Issue #250 — \$heatmap_light_bg_source is the canonical provenance signal; the four enumerated values are the only valid emissions'

    assert_line "$out" \
        pattern     "^gradient_dark: ${exp_dark}\$" \
        asserts     "gradient_dark reports the dark-palette 256-color array for the active metric's color (${exp_color}); this is the literal array @column_colors carries in ltl GLOBALS" \
        produced_by 'emit_heatmap_palette_verbose() in ltl (joins @{$entry->{gradient}} with commas)' \
        contract    'Issue #250 — gradient arrays in @column_colors are part of the heatmap-palette contract surface; changes require updating this harness in the same commit'

    assert_line "$out" \
        pattern     "^gradient_light: ${exp_light}\$" \
        asserts     "gradient_light reports the light-palette 256-color array for the active metric's color (${exp_color}); this is the literal array @column_colors carries in ltl GLOBALS" \
        produced_by 'emit_heatmap_palette_verbose() in ltl (joins @{$entry->{gradient_light}} with commas)' \
        contract    'Issue #250 — gradient arrays in @column_colors are part of the heatmap-palette contract surface; changes require updating this harness in the same commit'

    assert_line "$out" \
        pattern     "^gradient_active: ${exp_active}\$" \
        asserts     "gradient_active reports which branch (${exp_active}) print_heatmap_row() will pick when rendering; load-bearing line for visual palette coverage" \
        produced_by 'emit_heatmap_palette_verbose() in ltl (\$heatmap_light_bg ? "light" : "dark")' \
        contract    'Issue #250 — gradient_active is the contract for which palette renders'
}

# ---------------------------------------------------------------------------
# Run scenarios
# ---------------------------------------------------------------------------

echo "Validating heatmap-palette -V section (Issue #250)"
echo ""

scenario_no_heatmap
echo ""

# --- -dbg path: each of three metrics ---
scenario_palette "dbg-duration" \
    "-hm duration -dbg" \
    "duration" "yellow" "0" "-dbg" "dark" \
    "$YELLOW_DARK" "$YELLOW_LIGHT"
echo ""

scenario_palette "dbg-bytes" \
    "-hm bytes -dbg" \
    "bytes" "green" "0" "-dbg" "dark" \
    "$GREEN_DARK" "$GREEN_LIGHT"
echo ""

scenario_palette "dbg-count" \
    "-hm count -dbg" \
    "count" "cyan" "0" "-dbg" "dark" \
    "$CYAN_DARK" "$CYAN_LIGHT"
echo ""

# --- -lbg path: each of three metrics ---
scenario_palette "lbg-duration" \
    "-hm duration -lbg" \
    "duration" "yellow" "1" "-lbg" "light" \
    "$YELLOW_DARK" "$YELLOW_LIGHT"
echo ""

scenario_palette "lbg-bytes" \
    "-hm bytes -lbg" \
    "bytes" "green" "1" "-lbg" "light" \
    "$GREEN_DARK" "$GREEN_LIGHT"
echo ""

scenario_palette "lbg-count" \
    "-hm count -lbg" \
    "count" "cyan" "1" "-lbg" "light" \
    "$CYAN_DARK" "$CYAN_LIGHT"
echo ""

# --- Precedence: -dbg wins over -lbg regardless of CLI order ---
scenario_palette "precedence-lbg-then-dbg" \
    "-hm duration -lbg -dbg" \
    "duration" "yellow" "0" "-dbg" "dark" \
    "$YELLOW_DARK" "$YELLOW_LIGHT"
echo ""

scenario_palette "precedence-dbg-then-lbg" \
    "-hm duration -dbg -lbg" \
    "duration" "yellow" "0" "-dbg" "dark" \
    "$YELLOW_DARK" "$YELLOW_LIGHT"

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
