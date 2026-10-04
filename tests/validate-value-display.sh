#!/usr/bin/env bash
# validate-value-display.sh - render-invariant harness for how ltl renders a
# number on every display surface: one dispatch per metric kind, a width or a
# named budget per surface, trailing zeros stripped, and never a unit below the
# value's floor (features/617-width-to-format-rule.md).
#
# This is a RENDER-INVARIANT harness (tests/HARNESS-DESIGN.md section
# Render-invariant harnesses): the system under test is the rendered terminal
# surface. Each scenario runs ltl at a pinned --terminal-width on the smallest
# fixture that carries its signal, strips ANSI, and asserts a property of the
# rendered values. -V supplies an expected value where one is needed (the
# resolved duration unit); the stripped render supplies the actual. Timeline
# cells are read through the layout engine's own offsets (--debug-layout and
# timeline_cell_report).
#
# Each assertion records asserts / produced_by / contract and surfaces all
# three on failure (tests/HARNESS-DESIGN.md section Self-documenting
# assertions).
#
# Usage: ./tests/validate-value-display.sh [--scenario NAME] [--list]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"
FIXTURES="$REPO_DIR/tests/fixtures"
CHECKER="$SCRIPT_DIR/value-display/check-values.pl"
PERL="${PERL:-/opt/homebrew/bin/perl}"
command -v "$PERL" >/dev/null 2>&1 || PERL=perl

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"
# shellcheck source=lib/rendered-output.sh
source "$SCRIPT_DIR/lib/rendered-output.sh"

neutralize_colour_env

CONTRACT='features/617-width-to-format-rule.md'

COUNT_1500="$FIXTURES/value-display-count-1500.txt"
ZERO_DURATION="$FIXTURES/value-display-zero-duration.txt"
CV_HALF="$FIXTURES/value-display-cv-half.txt"
SECONDS_UDM="$FIXTURES/value-display-seconds-udm.txt"
DURATION_SPREAD="$FIXTURES/tomcat-access-duration-spread.txt"
NUMERIC_BOUNDARY="$FIXTURES/numeric-highlight-boundary.txt"
FIT="$FIXTURES/value-display-fit.txt"
COUNT_1140="$FIXTURES/value-display-count-1140.txt"
CARRY="$FIXTURES/value-display-carry.txt"
COUNT_CARRY="$FIXTURES/value-display-count-carry.txt"
MESSAGES_TOTAL="$FIXTURES/value-display-messages-total.txt"

for f in "$LTL" "$CHECKER" "$COUNT_1500" "$ZERO_DURATION" "$CV_HALF" "$SECONDS_UDM" "$DURATION_SPREAD" "$NUMERIC_BOUNDARY" "$FIT" "$COUNT_1140" "$CARRY" "$COUNT_CARRY" "$MESSAGES_TOTAL"; do
    [[ -e "$f" ]] || { echo "ERROR: not found: $f"; exit 1; }
done

# Every ltl run happens in this directory, so the CSVs -o writes are the
# harness's own and leave with it (tests/HARNESS-DESIGN.md section A harness
# owns the directory it runs ltl in).
TMP_DIR=$(mktemp -d); trap 'rm -rf "$TMP_DIR"' EXIT

pass=0
fail=0
failures=()
current_scenario=""

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
    : "${command:?}" "${label:?}" "${asserts:?}" "${produced_by:?}" "${contract:?}"
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

# Run ltl in TMP_DIR and keep its output: <name>.raw with ANSI (for the layout
# reader), <name>.txt stripped. Fails the scenario on a non-zero exit, an empty
# render or a Perl runtime warning.
# Usage: render <name> <fixture> <ltl-args...>
render() {
    local name="$1" fixture="$2"; shift 2
    local raw="$TMP_DIR/$name.raw" err="$TMP_DIR/$name.stderr"
    set +e
    ( cd "$TMP_DIR" && "$LTL" --disable-progress -ni "$@" "$fixture" ) > "$raw" 2> "$err"
    local rc=$?
    set -e
    if [[ "$rc" -ne 0 || ! -s "$raw" ]]; then
        echo "  FAIL  $current_scenario :: ltl exited $rc or rendered nothing ($name)"
        sed 's/^/        | /' "$err"
        fail=$((fail + 1)); failures+=("$current_scenario :: render $name"); return 1
    fi
    if ! assert_no_runtime_warnings "$err" "$current_scenario ($name)"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: runtime warnings ($name)"); return 1
    fi
    # The debug-layout table prints on stderr; the timeline cell reader takes
    # it from the capture, so the delimited block (and only it) is appended.
    sed -n '/^--- Layout Engine Debug/,/^---$/p' "$err" >> "$raw"
    sed -E 's/\x1b\[[0-9;]*m//g' "$raw" > "$TMP_DIR/$name.txt"
}

# The trimmed text of one timeline cell, read through the layout engine's
# offsets; empty with a diagnostic when the row or column is missing.
cell_text() {
    local name="$1" row="$2" column="$3" report
    report=$(timeline_cell_report "$TMP_DIR/$name.raw" "$row" "$column") || return 1
    report=${report#text=\'}
    report=${report%%\' fg=*}
    echo "$report" | sed -E 's/^ +//; s/ +$//'
}

check() { "$PERL" "$CHECKER" "$@"; }

# ---------------------------------------------------------------------------
# count-spelling (AC1): one value of 1500 renders as 1.5 and a unit on the
# timeline count column, the heatmap header and the histogram; the two chart
# surfaces name the same budget and print the same string; no surface prints
# 1.50. -bs 1 -n 0: one bucket, no message table (not read).
# ---------------------------------------------------------------------------
scenario_count_spelling() {
    current_scenario="count-spelling"
    echo "[$current_scenario]"
    render cs-timeline "$COUNT_1500" -bs 1 -n 0 --terminal-width 220 --debug-layout || return 0
    render cs-heatmap "$COUNT_1500" -bs 1 -n 0 --terminal-width 220 -hm count || return 0
    render cs-histogram "$COUNT_1500" -bs 1 -n 0 --terminal-width 220 -hg count || return 0

    assert_command \
        command     "cell_text cs-timeline '^ 2026-01-26 10:00' count | grep -qE '^1\\.5 ?(k|thousand)\$'" \
        label       'the timeline count cell reads 1.5 and a count unit' \
        asserts     'A count of 1500 renders as 1.5 followed by the unit of the tier its column resolved, never 1.50 or a cut value' \
        produced_by 'print_bar_graph() in ltl, the count column, through format_number() (the count arm of value_text())' \
        contract    "$CONTRACT D1, D3, D12"
    assert_command \
        command     "check tokens --file '$TMP_DIR/cs-heatmap.txt' --line 'heatmap \\[count\\]' --each '1\\.5k' --min 2" \
        label       'the heatmap header reads 1.5k at both ends' \
        asserts     'The heatmap header renders its minimum and maximum through the chart label budget (medium, tight): 1.5k' \
        produced_by 'get_heatmap_column_header() in ltl, through value_text() and the chart label budget row' \
        contract    "$CONTRACT D2, D9"
    assert_command \
        command     "check tokens --file '$TMP_DIR/cs-histogram.txt' --line 'P50:' --after 'P\\d+(?:\\.\\d+)?' --each '1\\.5k' --min 2" \
        label       'the histogram percentile legend reads 1.5k' \
        asserts     'The histogram percentile legend names the chart label budget, as the heatmap header does, so one value prints one string on both' \
        produced_by 'render_histogram_legend() in ltl, through value_text() and the chart label budget row' \
        contract    "$CONTRACT D1, D2, D9"
    assert_command \
        command     "check absent --file '$TMP_DIR/cs-timeline.txt' --regex '1\\.50' && check absent --file '$TMP_DIR/cs-heatmap.txt' --regex '1\\.50' && check absent --file '$TMP_DIR/cs-histogram.txt' --regex '1\\.50'" \
        label       'no surface prints 1.50' \
        asserts     'A trailing fractional zero is stripped on every display surface' \
        produced_by 'strip_trailing_zeros() in ltl, called by every arm of value_text()' \
        contract    "$CONTRACT D3"
}

# ---------------------------------------------------------------------------
# fixed-budget-sweep (AC2): the latency cells and the messages-table Min, P50
# and P99.9 name a budget, so they read the same at every terminal width.
# Three lines of one path, durations 10, 20 and 30 ms, one bucket.
# ---------------------------------------------------------------------------
scenario_fixed_budget_sweep() {
    current_scenario="fixed-budget-sweep"
    echo "[$current_scenario]"
    local w
    for w in 120 140 160 180 200 220; do
        render "fb-$w" "$CV_HALF" -bs 1 -n 1 --terminal-width "$w" || return 0
    done
    assert_command \
        command     "n=0; for w in 120 140 160 180 200 220; do grep -q 'P50:' '$TMP_DIR'/fb-\$w.txt || continue; n=\$((n + 1)); grep -oE 'P(50|95|99|999):[^ ]+' '$TMP_DIR'/fb-\$w.txt | tr '\\n' ' '; echo; done > '$TMP_DIR/fb-cells'; [[ \$n -ge 3 ]] && sort -u '$TMP_DIR/fb-cells' | awk 'END { exit !(NR == 1 && \$0 ~ /P50:20ms P95:30ms P99:30ms P999:30ms/) }'" \
        label       'the timeline latency cells read P50:20ms P95:30ms P99:30ms P999:30ms at every width that shows them (at least three)' \
        asserts     'The latency cells name one budget (short tier, tight fit, their own width), so the same bucket renders the same strings whatever the terminal width' \
        produced_by 'print_bar_graph() in ltl, the latency column, through value_text() and the latency cell budget row' \
        contract    "$CONTRACT D9; Issue #292 latency contract"
    assert_command \
        command     "for w in 120 140 160 180 200 220; do grep -E '\\[200\\] GET /vd/cv' '$TMP_DIR'/fb-\$w.txt | awk '{ for (i = 1; i <= NF; i++) if (\$i == \"3\") { print \$(i+1), \$(i+2), \$(i+3); exit } }'; done | sort -u | awk 'END { exit !(NR == 1 && \$0 == \"10ms 20ms 30ms\") }'" \
        label       'the messages-table Min, P50 and P99.9 read 10ms 20ms 30ms at every width' \
        asserts     'The messages-table duration cells name the latency cell budget, so their strings do not change with the column width' \
        produced_by 'print_message_summary() in ltl, through value_text() and the latency cell budget row' \
        contract    "$CONTRACT D9"
}

# ---------------------------------------------------------------------------
# zero-duration (AC8): a real zero renders in the resolved source unit on the
# heatmap header, never the ladder's lowest step; a seconds-declared metric's
# zero renders in seconds on its timeline column.
# ---------------------------------------------------------------------------
scenario_zero_duration() {
    current_scenario="zero-duration"
    echo "[$current_scenario]"
    local unit
    ( cd "$TMP_DIR" && "$LTL" --disable-progress -ni -bs 1440 -oe -n 0 -V csv-output -o "$ZERO_DURATION" ) > "$TMP_DIR/zd-unit.v" 2> "$TMP_DIR/zd-unit.stderr" || true
    assert_no_runtime_warnings "$TMP_DIR/zd-unit.stderr" "$current_scenario (resolved-unit probe)" || { fail=$((fail + 1)); failures+=("$current_scenario :: runtime warnings (probe)"); }
    unit=$(grep -aE '^duration_unit_resolved:' "$TMP_DIR/zd-unit.v" | awk '{print $2}')
    if [[ -z "$unit" ]]; then
        echo "  FAIL  $current_scenario :: missing duration_unit_resolved in -V csv-output"
        fail=$((fail + 1)); failures+=("$current_scenario :: missing duration_unit_resolved"); return 0
    fi
    render zd-heatmap "$ZERO_DURATION" -bs 1 -n 0 --terminal-width 160 -hm duration || return 0
    render zd-udm "$SECONDS_UDM" -bs 1 -n 0 --terminal-width 160 --debug-layout -udm 'elapsed:s:max' || return 0

    assert_command \
        command     "check tokens --file '$TMP_DIR/zd-heatmap.txt' --line 'heatmap \\[duration\\]' --each '0$unit' --min 2" \
        label       "the heatmap header reads 0$unit at both ends (resolved unit $unit)" \
        asserts     'A real zero duration renders in the source resolved unit on the heatmap header, as on the latency cells' \
        produced_by 'get_heatmap_column_header() in ltl, through value_text(): format_time() climbs from the floor step' \
        contract    "$CONTRACT D4, D16; features/444-access-log-format-family-and-user-surface.md R17"
    assert_command \
        command     "check absent --file '$TMP_DIR/zd-heatmap.txt' --regex '(?<![\\d.])0ns\\b'" \
        label       '0ns appears nowhere' \
        asserts     'A zero never renders in the ladder lowest step' \
        produced_by 'format_time() in ltl, the floor of the climb' \
        contract    "$CONTRACT D4"
    assert_command \
        command     "cell_text zd-udm '^ 2026-01-26 10:00' udm_elapsed | grep -qE '^0 ?(s|sec|seconds)\$'" \
        label       "a seconds-declared metric's zero reads 0 seconds on its timeline column" \
        asserts     'A user-defined time metric renders zero in its own declared unit, never the built-in duration unit' \
        produced_by 'print_bar_graph() in ltl, the user-defined time column, format_time() with the metric unit as floor' \
        contract    "$CONTRACT D16"
}

# ---------------------------------------------------------------------------
# floor-unit (AC9): no value renders below its floor. A seconds-declared
# metric carrying 0, 0, 0.25 and 2 reads in seconds on its timeline column,
# its heatmap labels and its dimensions line; on a millisecond-source access
# log no duration on any surface reads in micro- or nanoseconds.
# ---------------------------------------------------------------------------
scenario_floor_unit() {
    current_scenario="floor-unit"
    echo "[$current_scenario]"
    render fu-timeline "$SECONDS_UDM" -bs 1 -n 0 --terminal-width 160 --debug-layout -udm 'elapsed:s:max' || return 0
    render fu-heatmap "$SECONDS_UDM" -bs 1 -n 0 --terminal-width 160 -udm 'elapsed:s:max' -hm elapsed || return 0
    render fu-dims "$SECONDS_UDM" -bs 1 -n 0 --terminal-width 160 -udm 'elapsed:s:max' -hg elapsed -V histogram-bin-counters || return 0
    render fu-ms "$DURATION_SPREAD" -bs 60 -n 5 --terminal-width 160 -hm duration -hg duration || return 0
    render fu-ms-zero "$ZERO_DURATION" -bs 1 -n 5 --terminal-width 160 -hm duration || return 0

    assert_command \
        command     "cell_text fu-timeline '^ 2026-01-26 10:01' udm_elapsed | grep -qE '^2 ?(s|sec|seconds)\$'" \
        label       'the timeline column reads 2 seconds' \
        asserts     'A seconds-declared metric renders in seconds on its timeline column' \
        produced_by 'print_bar_graph() in ltl, the user-defined time column' \
        contract    "$CONTRACT D16"
    assert_command \
        command     "check tokens --file '$TMP_DIR/fu-heatmap.txt' --line 'heatmap \\[elapsed\\]' --each '[0-9.]+s' --min 2" \
        label       'the heatmap labels read in seconds' \
        asserts     'A seconds-declared metric value below one second renders in seconds (0.2s), never in milliseconds (250ms)' \
        produced_by 'get_heatmap_column_header() in ltl, through value_text(): resolve_value_kind() gives the declared unit as the floor' \
        contract    "$CONTRACT D15, D16"
    assert_command \
        command     "grep -qE '^  Elapsed: .* min=[0-9.]+s +max=[0-9.]+s ' '$TMP_DIR/fu-dims.txt'" \
        label       'the dimensions line reads min and max in seconds' \
        asserts     'The histogram display-dimensions line renders a seconds-declared metric in seconds' \
        produced_by 'format_histogram_dimensions_line() in ltl, through value_text() and the dimensions line budget row' \
        contract    "$CONTRACT D16"
    assert_command \
        command     "check absent --file '$TMP_DIR/fu-ms.txt' --regex '(?<![\\w.])[0-9.]+ ?(us|ns|usec|nsec|microseconds?|nanoseconds?)\\b' && check absent --file '$TMP_DIR/fu-ms-zero.txt' --regex '(?<![\\w.])[0-9.]+ ?(us|ns|usec|nsec|microseconds?|nanoseconds?)\\b'" \
        label       'no duration on a millisecond source reads in us or ns' \
        asserts     'On a millisecond-source access log no surface (timeline, latency cells, heatmap header, histogram labels, messages table) renders a duration below the millisecond' \
        produced_by 'value_text() in ltl: resolve_value_kind() gives the built-in duration its resolved unit as floor' \
        contract    "$CONTRACT D16"
}

# ---------------------------------------------------------------------------
# cv-agreement (AC7): durations 10, 20 and 30 ms have a coefficient of
# variation of exactly one half; the timeline cell, the messages-table cell
# and the MESSAGES CSV all read 0.5.
# ---------------------------------------------------------------------------
scenario_cv_agreement() {
    current_scenario="cv-agreement"
    echo "[$current_scenario]"
    rm -f "$TMP_DIR"/*-LTL-MESSAGES-*.csv
    render cv "$CV_HALF" -bs 1 -n 1 -o --terminal-width 200 || return 0
    local csv
    csv=$(ls "$TMP_DIR"/*-LTL-MESSAGES-*.csv 2>/dev/null | head -1)
    assert_command \
        command     "grep -qE 'CV:0\\.5( |\$)' '$TMP_DIR/cv.txt'" \
        label       'the timeline CV cell reads CV:0.5' \
        asserts     'The CV cell renders through the CV cell budget with its trailing zero stripped' \
        produced_by 'print_bar_graph() in ltl, through value_text() and the CV cell budget row' \
        contract    "$CONTRACT D3, D9"
    assert_command \
        command     "grep -E '\\[200\\] GET /vd/cv' '$TMP_DIR/cv.txt' | grep -qE ' 30ms +0\\.5 '" \
        label       'the messages-table CV cell reads 0.5' \
        asserts     'The messages-table CV cell renders through the CV cell budget, trailing zero stripped' \
        produced_by 'print_message_summary() in ltl, through value_text() and the CV cell budget row' \
        contract    "$CONTRACT D3, D9"
    assert_command \
        command     "[[ -n '$csv' ]] && $PERL -MText::ParseWords -ne 'chomp; my @f = parse_line(\",\", 0, \$_); if (\$. == 1) { (\$i) = grep { \$f[\$_] eq \"duration_cv\" } 0..\$#f; die \"no duration_cv column\\n\" unless defined \$i; next } \$v = \$f[\$i]; END { die \"duration_cv is \" . (\$v // \"absent\") . \"\\n\" unless defined \$v && \$v eq \"0.5\" }' '$csv'" \
        label       'the MESSAGES CSV duration_cv cell reads 0.5' \
        asserts     'The CV cell and the CSV agree where the CSV value fits the cell budget' \
        produced_by 'print_message_summary() in ltl, format_csv_value() for duration_cv' \
        contract    "$CONTRACT D3, correction 12"
}

# ---------------------------------------------------------------------------
# user-defined-kind (AC15): a user-defined non-counting metric renders its
# heatmap labels in its own unit. A maximum of the millisecond key of the
# numeric-boundary application log.
# ---------------------------------------------------------------------------
scenario_user_defined_kind() {
    current_scenario="user-defined-kind"
    echo "[$current_scenario]"
    render udk "$NUMERIC_BOUNDARY" -bs 1 -n 0 --terminal-width 160 -udm 'x:ms:max:durationMS' -hm x || return 0
    assert_command \
        command     "check tokens --file '$TMP_DIR/udk.txt' --line 'heatmap \\[x\\]' --each '[0-9.]+(ms|s)' --min 2" \
        label       'the heatmap labels read in time units' \
        asserts     'A user-defined time metric heatmap renders its labels in time units through the one dispatch' \
        produced_by 'get_heatmap_column_header() in ltl, through value_text(); resolve_value_kind() resolves the user-defined metric' \
        contract    "$CONTRACT D15"
}

# ---------------------------------------------------------------------------
# rate-suffix (AC16, timeline half): a user-defined rate carries the rate
# suffix of -ru on its timeline column.
# ---------------------------------------------------------------------------
scenario_rate_suffix() {
    current_scenario="rate-suffix"
    echo "[$current_scenario]"
    render rs "$NUMERIC_BOUNDARY" -bs 1 -n 0 --terminal-width 200 --debug-layout -ru s -udm 'cnt::rate:count' || return 0
    assert_command \
        command     "cell_text rs '^ 2026-01-26 10:00' udm_cnt | grep -qE '^[0-9.]+ ?/s\$'" \
        label       'the user-defined rate cell carries /s' \
        asserts     'A user-defined rate renders as a count with the rate unit suffix of -ru' \
        produced_by 'print_bar_graph() in ltl, the user-defined rate column' \
        contract    "$CONTRACT D15, D21"
}

# ---------------------------------------------------------------------------
# no-trailing-zero (AC6): no rendered value ends in a fractional zero, over a
# battery of captures covering every surface, and over every regression
# golden. Timestamps and IP addresses are excluded by the token shape.
# ---------------------------------------------------------------------------
scenario_no_trailing_zero() {
    current_scenario="no-trailing-zero"
    echo "[$current_scenario]"
    render nz-1 "$COUNT_1500" -bs 1 -n 0 --terminal-width 160 -hm count || return 0
    render nz-2 "$COUNT_1500" -bs 1 -n 0 --terminal-width 160 -hg count || return 0
    render nz-3 "$CV_HALF" -bs 1 -n 1 --terminal-width 160 || return 0
    render nz-4 "$DURATION_SPREAD" -bs 60 -n 5 --terminal-width 200 -hm duration || return 0
    render nz-5 "$DURATION_SPREAD" -bs 60 -n 5 --terminal-width 200 -hg duration,bytes || return 0
    local pattern='(?<![\d.])\d+\.\d*0(?![\d.])'
    assert_command \
        command     "for f in '$TMP_DIR'/nz-*.txt; do check absent --file \"\$f\" --regex '$pattern' || exit 1; done" \
        label       'no value in the battery ends in a fractional zero' \
        asserts     'Trailing fractional zeros are stripped on every display surface after the decimals are chosen' \
        produced_by 'strip_trailing_zeros() in ltl, called by every arm of value_text()' \
        contract    "$CONTRACT D3"
    assert_command \
        command     "for f in '$REPO_DIR'/tests/reference-output/*.txt; do check absent --file \"\$f\" --regex '$pattern' || exit 1; done" \
        label       'no value in a regression golden ends in a fractional zero' \
        asserts     'The frozen surfaces carry no trailing fractional zero' \
        produced_by 'strip_trailing_zeros() in ltl, called by every arm of value_text()' \
        contract    "$CONTRACT D3"
}

# ---------------------------------------------------------------------------
# fit-sweep (AC3, AC4, AC11, AC12): at every --terminal-width from 100 to 220
# in steps of 10, every duration and bytes cell is one whole value (a number
# and a complete unit spelling, never cut), one tier and one fit run down each
# column, a long-tier word is never tight, a millisecond-source duration shown
# in milliseconds carries no decimal on any surface, and the bytes column
# resolves more than one tier across the widths. One access-log line per
# minute, totals from 7 ms to 12.2 min and from 512 B to 5 MB; -bs 1 -n 0,
# -osum: the summary's own timings state no source unit and have no floor.
# ---------------------------------------------------------------------------
visible_column() { grep -qE "^  $2 +proportional +[0-9]+ +[0-9]+ +[0-9]+ +1 " "$TMP_DIR/$1.raw"; }

scenario_fit_sweep() {
    current_scenario="fit-sweep"
    echo "[$current_scenario]"
    local w seen=0
    : > "$TMP_DIR/fs-bytes-tiers"
    for w in 100 110 120 130 140 150 160 170 180 190 200 210 220; do
        render "fs-$w" "$FIT" -bs 1 -n 0 -osum --terminal-width "$w" --debug-layout || return 0
        if visible_column "fs-$w" duration; then
            seen=$((seen + 1))
            assert_command \
                command     "check column --file '$TMP_DIR/fs-$w.raw' --column duration --kind duration --source-unit ms --lib '$_RENDERED_OUTPUT_LIB'" \
                label       "width $w: every duration cell is a whole value, one tier and fit down the column" \
                asserts     'A timeline value is never cut: a number and a complete unit spelling; the column resolves one tier and one fit against all its values; a long word keeps its space; a millisecond source shows no decimal in milliseconds' \
                produced_by 'print_bar_graph() in ltl: value_column() resolves the column (value_walk_row()), value_text() renders each cell' \
                contract    "$CONTRACT D1, D10, D11, D19, D23"
        fi
        if visible_column "fs-$w" bytes; then
            assert_command \
                command     "check column --file '$TMP_DIR/fs-$w.raw' --column bytes --kind bytes-si --lib '$_RENDERED_OUTPUT_LIB' >> '$TMP_DIR/fs-bytes-tiers'" \
                label       "width $w: every bytes cell is a whole SI value, one tier and fit down the column" \
                asserts     'A bytes value is never cut and spells one tier of the run notation down its column' \
                produced_by 'print_bar_graph() in ltl, through value_column() and format_bytes()' \
                contract    "$CONTRACT D10, D19"
        fi
    done
    assert_command \
        command     "[[ $seen -ge 5 ]] && sort -u '$TMP_DIR/fs-bytes-tiers' | grep -c . | awk '{ exit !(\$1 >= 2) }' && grep -q 'tiers=long' '$TMP_DIR/fs-bytes-tiers'" \
        label       'the duration column shows at five widths or more; the bytes column resolves more than one tier, the long word among them' \
        asserts     'Bytes are a tiered kind like every other: the walk reaches the long-tier word where the column is wide and the token below' \
        produced_by 'value_walk_row() in ltl; the word field of @byte_unit_ladder' \
        contract    "$CONTRACT D19 (bytes a tiered kind)"
    render fs-hg "$FIT" -bs 1 -n 0 -osum -hm duration -hg duration --terminal-width 160 || return 0
    assert_command \
        command     "for f in '$TMP_DIR'/fs-*.txt; do check absent --file \"\$f\" --regex '(?<![\\w.])\\d+\\.\\d+ ?(ms|msec|milliseconds?)\\b' || exit 1; done" \
        label       'no surface (timeline, latency cells, heatmap header, histogram labels) shows a decimal at the millisecond step on a millisecond source' \
        asserts     'A rendered digit is never finer than the source resolution (latency cells included)' \
        produced_by 'format_time() in ltl: the resolution ceiling' \
        contract    "$CONTRACT D19"
}

# ---------------------------------------------------------------------------
# common-maxima (AC5): a count of 1140 reads 1.14 thousand where its column
# resolves the long tier, 1.1 k where it resolves medium, and 1.1k on the
# heatmap header; no value carries more decimals than its tier allows.
# ---------------------------------------------------------------------------
scenario_common_maxima() {
    current_scenario="common-maxima"
    echo "[$current_scenario]"
    render cm-wide "$COUNT_1140" -bs 1 -n 0 --terminal-width 160 --debug-layout || return 0
    render cm-narrow "$COUNT_1140" -bs 1 -n 0 --terminal-width 100 --debug-layout || return 0
    render cm-heatmap "$COUNT_1140" -bs 1 -n 0 --terminal-width 160 -hm count || return 0
    assert_command \
        command     "cell_text cm-wide '^ 2026-01-26 10:00' count | grep -qx '1.14 thousand'" \
        label       'a long-tier column reads 1.14 thousand' \
        asserts     'The long tier carries up to two decimals, the same maximum for every kind' \
        produced_by 'value_text() in ltl, %tier_decimals' \
        contract    "$CONTRACT D12"
    assert_command \
        command     "cell_text cm-narrow '^ 2026-01-26 10:00' count | grep -qE '^1\\.1 ?k\$'" \
        label       'a medium-tier column reads 1.1 k' \
        asserts     'The medium tier carries up to one decimal' \
        produced_by 'value_text() in ltl, %tier_decimals' \
        contract    "$CONTRACT D12"
    assert_command \
        command     "check tokens --file '$TMP_DIR/cm-heatmap.txt' --line 'heatmap \\[count\\]' --each '1\\.1k' --min 1" \
        label       'the heatmap header reads 1.1k' \
        asserts     'The chart label budget (medium, tight) carries the medium maximum' \
        produced_by 'get_heatmap_column_header() in ltl, through value_text()' \
        contract    "$CONTRACT D12"
}

# ---------------------------------------------------------------------------
# boundary-carry (AC10): a value that rounds up to the next step's size
# renders at that step: 999,999 bytes under SI reads 1 MB, 59,960 ms reads
# 1 min, a count of 999,960 reads 1 million (timeline and heatmap header).
# ---------------------------------------------------------------------------
scenario_boundary_carry() {
    current_scenario="boundary-carry"
    echo "[$current_scenario]"
    render bc "$CARRY" -bs 1 -n 0 -bn si --terminal-width 160 --debug-layout || return 0
    render bc-count "$COUNT_CARRY" -bs 1 -n 0 --terminal-width 160 --debug-layout || return 0
    render bc-count-hm "$COUNT_CARRY" -bs 1 -n 0 --terminal-width 160 -hm count || return 0
    assert_command \
        command     "cell_text bc '^ 2025-05-07 00:00' bytes | grep -qE '^1 ?(MB|megabyte)\$'" \
        label       '999,999 bytes reads 1 MB' \
        asserts     'A value whose rounding reaches the next step size renders at that step, never 1000 kB' \
        produced_by 'format_bytes() in ltl, the carry' \
        contract    "$CONTRACT D19"
    assert_command \
        command     "cell_text bc '^ 2025-05-07 00:01' duration | grep -qE '^1 ?(m|min|minute)\$'" \
        label       '59,960 ms reads 1 min' \
        asserts     'The carry applies to every kind with a ladder: never 60 sec' \
        produced_by 'format_time() in ltl, the carry' \
        contract    "$CONTRACT D19"
    assert_command \
        command     "cell_text bc-count '^ 2026-01-26 10:00' count | grep -qE '^(1 ?(M|Mil|million)|999\\.96 thousand)\$' && check tokens --file '$TMP_DIR/bc-count-hm.txt' --line 'heatmap \\[count\\]' --each '1Mil' --min 2" \
        label       'a count of 999,960 never reads 1000 k: 1Mil on the heatmap header, the timeline column as its tier carries it' \
        asserts     'The carry applies to counts: at one decimal 999,960 rounds to the next step size and reads 1Mil; at the long tier two decimals keep it below (999.96 thousand); never 1000 of the smaller unit' \
        produced_by 'format_number() in ltl, the carry' \
        contract    "$CONTRACT D12, D19"
}

# ---------------------------------------------------------------------------
# messages-total (AC17): the messages-table total fits its column at every
# width, a whole value, one tier down the column; the MESSAGES CSV
# duration_nice reads the same string at every width. Four paths whose
# totals run from 5 ms to 2 min.
# ---------------------------------------------------------------------------
scenario_messages_total() {
    current_scenario="messages-total"
    echo "[$current_scenario]"
    local w
    for w in 100 120 140 160 180 200 220; do
        rm -f "$TMP_DIR"/*-LTL-MESSAGES-*.csv
        render "mt-$w" "$MESSAGES_TOTAL" -bs 60 -n 4 -o --terminal-width "$w" || return 0
        ls "$TMP_DIR"/*-LTL-MESSAGES-*.csv > /dev/null 2>&1 && \
            $PERL -MText::ParseWords -ne 'chomp; my @f = parse_line(",", 0, $_); if ($. == 1) { ($i) = grep { $f[$_] eq "duration_nice" } 0..$#f; next } print "$f[$i]\n"' "$TMP_DIR"/*-LTL-MESSAGES-*.csv | sort > "$TMP_DIR/mt-$w.nice"
    done
    assert_command \
        command     "for w in 100 120 140 160 180 200 220; do grep -E 'GET /vd/total' '$TMP_DIR'/mt-\$w.txt | $PERL -ne 'm{(\\d+(?:\\.\\d+)?)( ?)(ms|msec|milliseconds?|s|sec|seconds?|m|min|minutes?)\\s*\$} or die \"no whole total in: \$_\"; \$t{ length(\$3) > 4 ? \"long\" : \$3 =~ /^(ms|s|m)\$/ ? \"short\" : \"medium\" }++; \$f{\$2}++; END { die \"tiers \" . join(\",\", keys %t) . \" fits \" . join(\",\", keys %f) . \"\\n\" if keys %t > 1 || keys %f > 1 || !%t }' || exit 1; done" \
        label       'at every width each total is a whole value, one tier and fit down the column' \
        asserts     'The messages-table total is walked by its own column width, resolved once against every total the table shows, never cut' \
        produced_by 'print_message_summary() in ltl: value_column() with the messages total row, value_text()' \
        contract    "$CONTRACT D10, D18, D23"
    assert_command \
        command     "[[ -s '$TMP_DIR/mt-100.nice' ]] && for w in 120 140 160 180 200 220; do cmp -s '$TMP_DIR/mt-100.nice' '$TMP_DIR'/mt-\$w.nice || exit 1; done" \
        label       'the MESSAGES CSV duration_nice reads the same at every width' \
        asserts     'The CSV nice cell keeps a fixed budget whatever the terminal width' \
        produced_by 'print_message_summary() in ltl, value_text() with the nice cell row' \
        contract    "$CONTRACT D18"
}

# ---------------------------------------------------------------------------
# axis-tick (AC22): a duration histogram whose tallest bin holds 1,155
# samples labels that tick 1.2k, and no two y-axis ticks read alike.
# Generated: 1,155 lines at 10 ms and 300 at 2 s, one path.
# ---------------------------------------------------------------------------
scenario_axis_tick() {
    current_scenario="axis-tick"
    echo "[$current_scenario]"
    local gen="$TMP_DIR/axis-tick.txt" i
    : > "$gen"
    for ((i = 0; i < 1155; i++)); do printf '192.0.2.43 - - [07/May/2025:00:00:%02d +0000] "GET /vd/axis HTTP/1.1" 200 512 10\n' $((i % 60)) >> "$gen"; done
    for ((i = 0; i < 300; i++)); do printf '192.0.2.43 - - [07/May/2025:00:00:%02d +0000] "GET /vd/axis HTTP/1.1" 200 512 2000\n' $((i % 60)) >> "$gen"; done
    render at "$gen" -bs 1440 -oe -n 0 -hg duration --terminal-width 160 || return 0
    assert_command \
        command     "$PERL -ne 'print \"\$1\\n\" if /^\\s*(\\S+) [^\\x00-\\x7f]/ && \$1 !~ /^(?:0|timestamp)\$/' '$TMP_DIR/at.txt' > '$TMP_DIR/at-ticks' && grep -qx '1.2k' '$TMP_DIR/at-ticks' && [[ \$(sort '$TMP_DIR/at-ticks' | uniq -d | wc -l) -eq 0 ]]" \
        label       'the top tick reads 1.2k and no two ticks read alike' \
        asserts     'The y-axis tick names the axis tick budget (medium, tight, the six-character label field): 1,155 reads 1.2k, never 1k above 866' \
        produced_by 'render_histogram_row() in ltl, through value_text() and the axis tick row' \
        contract    "$CONTRACT D1, D8, D9; correction 6"
}

scenario_register count-spelling fixed-budget-sweep zero-duration floor-unit cv-agreement user-defined-kind rate-suffix fit-sweep common-maxima boundary-carry messages-total axis-tick no-trailing-zero
scenario_parse_args "$@"

scenario_wanted count-spelling     && { scenario_count_spelling; echo ""; }
scenario_wanted fixed-budget-sweep && { scenario_fixed_budget_sweep; echo ""; }
scenario_wanted zero-duration      && { scenario_zero_duration; echo ""; }
scenario_wanted floor-unit         && { scenario_floor_unit; echo ""; }
scenario_wanted cv-agreement       && { scenario_cv_agreement; echo ""; }
scenario_wanted user-defined-kind  && { scenario_user_defined_kind; echo ""; }
scenario_wanted rate-suffix        && { scenario_rate_suffix; echo ""; }
scenario_wanted fit-sweep          && { scenario_fit_sweep; echo ""; }
scenario_wanted common-maxima      && { scenario_common_maxima; echo ""; }
scenario_wanted boundary-carry     && { scenario_boundary_carry; echo ""; }
scenario_wanted messages-total     && { scenario_messages_total; echo ""; }
scenario_wanted axis-tick          && { scenario_axis_tick; echo ""; }
scenario_wanted no-trailing-zero   && { scenario_no_trailing_zero; echo ""; }

echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 || "$pass" -eq 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do echo "  - $f"; done
    exit 1
fi
echo "ALL VALUE-DISPLAY TESTS PASSED"
