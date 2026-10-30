#!/usr/bin/env bash
# validate-value-display.sh - render-invariant harness for how ltl renders a
# number on every display surface: one dispatch per metric kind, a width or a
# named budget per surface, trailing zeros stripped (features/617-width-to-format-rule.md),
# and never a unit finer than the precision the raw data carries
# (features/759-duration-precision-rendering.md).
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
# Usage: ./tests/validate-value-display.sh [--scenario NAME]... [--list]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="${LTL:-$REPO_DIR/ltl}"
FIXTURES="$REPO_DIR/tests/fixtures"
CHECKER="$SCRIPT_DIR/value-display/check-values.pl"
PERL="${PERL:-perl}"

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
DURATION_SPREAD_SECONDS="$FIXTURES/tomcat-access-duration-spread-seconds.txt"
NUMERIC_BOUNDARY="$FIXTURES/numeric-highlight-boundary.txt"
FIT="$FIXTURES/value-display-fit.txt"
COUNT_MAXIMA="$FIXTURES/value-display-count-maxima.txt"
CARRY="$FIXTURES/value-display-carry.txt"
COUNT_CARRY="$FIXTURES/value-display-count-carry.txt"
MESSAGES_TOTAL="$FIXTURES/value-display-messages-total.txt"

for f in "$LTL" "$CHECKER" "$COUNT_1500" "$ZERO_DURATION" "$CV_HALF" "$SECONDS_UDM" "$DURATION_SPREAD" "$DURATION_SPREAD_SECONDS" "$NUMERIC_BOUNDARY" "$FIT" "$COUNT_MAXIMA" "$CARRY" "$COUNT_CARRY" "$MESSAGES_TOTAL"; do
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

# A check whose input does not depend on $LTL names it in `run_free`, and its
# PASS line ends [run-free: <it>] (tests/HARNESS-DESIGN.md section The
# failed-run checker).
assert_command() {
    local command label asserts produced_by contract run_free=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            command)     command="$2";     shift 2 ;;
            label)       label="$2";       shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            run_free)    run_free="$2";    shift 2 ;;
            *) echo "assert_command: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${command:?}" "${label:?}" "${asserts:?}" "${produced_by:?}" "${contract:?}"
    local cmd_out cmd_rc
    set +e
    cmd_out=$(eval "$command" 2>&1); cmd_rc=$?
    set -e
    if [[ "$cmd_rc" -eq 0 ]]; then
        echo "  PASS  $current_scenario :: $label${run_free:+ [run-free: $run_free]}"
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
# reader), <name>.txt stripped. Fails the scenario on a non-zero exit, a render
# that drew no timeline row, or a Perl runtime warning: every surface a check
# scans (the timeline, the heatmap header, the histogram labels) is drawn with
# the timeline, so its rows are the evidence an absence is read against.
# Usage: render <name> <fixture> <ltl-args...>
render() {
    local name="$1" fixture="$2"; shift 2
    local raw="$TMP_DIR/$name.raw" err="$TMP_DIR/$name.stderr"
    set +e
    ( cd "$TMP_DIR" && "$LTL" --disable-progress -ni "$@" "$fixture" ) > "$raw" 2> "$err"
    local rc=$?
    set -e
    if [[ "$rc" -ne 0 ]] || ! sed -E 's/\x1b\[[0-9;]*m//g' "$raw" | grep -E '^ [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}' > /dev/null; then
        echo "  FAIL  $current_scenario :: ltl exited $rc or drew no timeline row ($name)"
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
        command     "cell_text cs-timeline '^ 2026-01-26 10:00' count | grep -qx '1500'" \
        label       'the timeline count cell reads 1500' \
        asserts     'A count of 1500 in a walking column renders unclimbed: exact, four digits, no wider than 1.5k (D25); never 1.50 or a cut value' \
        produced_by 'print_bar_graph() in ltl, the count column, through format_number() (the count arm of value_text())' \
        contract    "$CONTRACT D1, D3, D12, D25"
    assert_command \
        command     "grep -E 'heatmap \\[count\\]' '$TMP_DIR/cs-heatmap.txt' | $PERL -ne '@t = /(?<![\\w.])(\\d[\\d.]*)(?![\\w.])/g; exit !(@t >= 2 && !grep { \$_ ne \"1500\" } @t)'" \
        label       'the heatmap header reads 1500 at both ends' \
        asserts     'The heatmap header renders its minimum and maximum through the chart label budget: 1,500 unclimbed, exact and no wider than 1.5k (D26)' \
        produced_by 'get_heatmap_column_header() in ltl, through value_text() and the chart label budget row' \
        contract    "$CONTRACT D2, D9"
    assert_command \
        command     "grep -E 'P50:' '$TMP_DIR/cs-histogram.txt' | $PERL -ne '@t = /P\\d+(?:\\.\\d+)?: *(\\S+)/g; exit !(@t >= 2 && !grep { \$_ ne \"1500\" } @t)'" \
        label       'the histogram percentile legend reads 1500, as the timeline and the heatmap header do' \
        asserts     'One value prints one string on every surface: the timeline column, the heatmap header and the histogram legend all show 1,500 unclimbed (D25, D26)' \
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
# zero-duration (AC8): a real zero renders in the precision its raw data
# carries on the heatmap header (the fixture writes whole milliseconds, so the
# unit read in), never the ladder's lowest step; a seconds-declared metric's
# zero renders in its precision on its timeline column: the millisecond for
# values written with two decimals (0.25), the second for whole seconds.
# ---------------------------------------------------------------------------
scenario_zero_duration() {
    current_scenario="zero-duration"
    echo "[$current_scenario]"
    local unit
    ( cd "$TMP_DIR" && "$LTL" --disable-progress -ni -bs 1440 -oe -n 0 -V csv-output -o "$ZERO_DURATION" ) > "$TMP_DIR/zd-unit.v" 2> "$TMP_DIR/zd-unit.stderr" || true
    assert_no_runtime_warnings "$TMP_DIR/zd-unit.stderr" "$current_scenario (resolved-unit probe)" || { fail=$((fail + 1)); failures+=("$current_scenario :: runtime warnings (probe)"); }
    unit=$(grep -aE '^duration_unit_resolved:' "$TMP_DIR/zd-unit.v" | awk '{print $2}') || unit=""
    if [[ -z "$unit" ]]; then
        echo "  FAIL  $current_scenario :: missing duration_unit_resolved in -V csv-output"
        fail=$((fail + 1)); failures+=("$current_scenario :: missing duration_unit_resolved"); return 0
    fi
    render zd-heatmap "$ZERO_DURATION" -bs 1 -n 0 --terminal-width 160 -hm duration || return 0
    render zd-udm "$SECONDS_UDM" -bs 1 -n 0 --terminal-width 160 --debug-layout -udm 'elapsed:s:max' || return 0
    sed -E 's/elapsed=0\.25/elapsed=1/' "$SECONDS_UDM" > "$TMP_DIR/seconds-udm-whole.txt"
    render zd-udm-whole "$TMP_DIR/seconds-udm-whole.txt" -bs 1 -n 0 --terminal-width 160 --debug-layout -udm 'elapsed:s:max' || return 0

    assert_command \
        command     "check tokens --file '$TMP_DIR/zd-heatmap.txt' --line 'heatmap \\[duration\\]' --each '0$unit' --min 2" \
        label       "the heatmap header reads 0$unit at both ends (resolved unit $unit)" \
        asserts     'A real zero duration renders in the precision its raw data carries on the heatmap header, as on the latency cells; whole milliseconds carry the millisecond' \
        produced_by 'get_heatmap_column_header() in ltl, through value_text(): format_time() climbs from the floor step, the precision resolve_duration_precision() resolves' \
        contract    "$CONTRACT D4 as amended; features/759-duration-precision-rendering.md D2, AC2"
    assert_command \
        command     "check absent --file '$TMP_DIR/zd-heatmap.txt' --regex '(?<![\\d.])0ns\\b'" \
        label       '0ns appears nowhere' \
        asserts     'A zero never renders in the ladder lowest step' \
        produced_by 'format_time() in ltl, the floor of the climb' \
        contract    "$CONTRACT D4"
    assert_command \
        command     "cell_text zd-udm '^ 2026-01-26 10:00' udm_elapsed | grep -qE '^0 ?(ms|msec|milliseconds)\$' && cell_text zd-udm-whole '^ 2026-01-26 10:00' udm_elapsed | grep -qE '^0 ?(s|sec|seconds)\$'" \
        label       "a seconds-declared metric's zero reads 0 milliseconds over values written with two decimals, 0 seconds over whole seconds" \
        asserts     "A user-defined time metric renders zero in its declared unit combined with the precision its values carry, never the built-in duration's" \
        produced_by 'print_bar_graph() in ltl, the user-defined time column; udm_precision() gives format_time() its floor' \
        contract    "features/759-duration-precision-rendering.md D5, AC7"
}

# ---------------------------------------------------------------------------
# floor-unit (AC9): no value renders below its floor, the precision its raw
# data carries. A seconds-declared metric carrying 0, 0, 0.25 and 2 (two
# decimals, so the millisecond) reads 2 seconds on its timeline column and
# 250ms at the low end of its heatmap labels and its dimensions line; a
# kilobyte metric carrying 0.5 and 1.5 reads 500 B; on a millisecond-source
# access log no duration on any surface reads in micro- or nanoseconds.
# ---------------------------------------------------------------------------
scenario_floor_unit() {
    current_scenario="floor-unit"
    echo "[$current_scenario]"
    render fu-timeline "$SECONDS_UDM" -bs 1 -n 0 --terminal-width 160 --debug-layout -udm 'elapsed:s:max' || return 0
    render fu-heatmap "$SECONDS_UDM" -bs 1 -n 0 --terminal-width 160 -udm 'elapsed:s:max' -hm elapsed || return 0
    render fu-dims "$SECONDS_UDM" -bs 1 -n 0 --terminal-width 160 -udm 'elapsed:s:max' -hg elapsed -V histogram-bin-counters || return 0
    sed -E 's/elapsed=0\.25/size=0.5/; s/elapsed=2$/size=1.5/; s/elapsed=/size=/' "$SECONDS_UDM" > "$TMP_DIR/kilobyte-udm.txt"
    render fu-bytes "$TMP_DIR/kilobyte-udm.txt" -bs 1 -n 0 --terminal-width 160 -udm 'size:kB:max' -hm size || return 0
    render fu-ms "$DURATION_SPREAD" -bs 60 -n 5 --terminal-width 160 -hm duration -hg duration || return 0
    render fu-ms-zero "$ZERO_DURATION" -bs 1 -n 5 --terminal-width 160 -hm duration || return 0

    assert_command \
        command     "cell_text fu-timeline '^ 2026-01-26 10:01' udm_elapsed | grep -qE '^2 ?(s|sec|seconds)\$'" \
        label       'the timeline column reads 2 seconds' \
        asserts     'A seconds-declared metric value of two seconds renders in seconds: the unit its magnitude reaches' \
        produced_by 'print_bar_graph() in ltl, the user-defined time column' \
        contract    "features/759-duration-precision-rendering.md D5, AC7"
    assert_command \
        command     "grep -E 'heatmap \\[elapsed\\]' '$TMP_DIR/fu-heatmap.txt' | grep -qE '(^| )250ms .*heatmap \\[elapsed\\] +2s *\$'" \
        label       'the heatmap labels read 250ms and 2s' \
        asserts     'A seconds-declared metric whose values are written with two decimals carries the millisecond: 0.25 renders 250ms, never 0.2s or 0.3s' \
        produced_by 'get_heatmap_column_header() in ltl, through value_text(): resolve_value_kind() gives udm_precision() as the floor' \
        contract    "$CONTRACT D15; features/759-duration-precision-rendering.md D5, AC7"
    assert_command \
        command     "grep -qE '^  metric: elapsed .* min=250ms max=2s ' '$TMP_DIR/fu-dims.txt'" \
        label       'the dimensions line reads min=250ms max=2s' \
        asserts     'The histogram display-dimensions line renders a seconds-declared metric at the precision its values carry (zeros are not binned: the AC2 exception)' \
        produced_by 'format_histogram_dimensions_line() in ltl, through value_text() and the dimensions line budget row' \
        contract    "features/759-duration-precision-rendering.md D5, AC7"
    assert_command \
        command     "grep -E 'heatmap \\[size\\]' '$TMP_DIR/fu-bytes.txt' | grep -qE '(^| )500 ?B .*heatmap \\[size\\] +1\\.5 ?kB *\$'" \
        label       'a kilobyte metric carrying 0.5 and 1.5 reads 500 B and 1.5 kB on its heatmap labels' \
        asserts     'A byte metric takes the same count: kilobytes written with one decimal reach the byte, so 0.5 kB renders in bytes' \
        produced_by 'get_heatmap_column_header() in ltl, through value_text(): resolve_value_kind() gives udm_precision() as the floor of format_bytes()' \
        contract    "features/759-duration-precision-rendering.md D5, AC7"
    assert_command \
        command     "check absent --file '$TMP_DIR/fu-ms.txt' --regex '(?<![\\w.])[0-9.]+ ?(us|ns|usec|nsec|microseconds?|nanoseconds?)\\b' && check absent --file '$TMP_DIR/fu-ms-zero.txt' --regex '(?<![\\w.])[0-9.]+ ?(us|ns|usec|nsec|microseconds?|nanoseconds?)\\b'" \
        label       'no duration on a millisecond source reads in us or ns' \
        asserts     'On an access log of whole milliseconds no surface (timeline, latency cells, heatmap header, histogram labels, messages table) renders a duration below the millisecond: the precision its raw data carries' \
        produced_by 'value_text() in ltl: resolve_value_kind() gives the built-in duration the precision resolve_duration_precision() resolves as floor' \
        contract    "features/759-duration-precision-rendering.md § 2, AC3"
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
    csv=$(ls "$TMP_DIR"/*-LTL-MESSAGES-*.csv 2>/dev/null | head -1) || csv=""
    assert_command \
        command     "grep -qE 'CV:0\\.50( |\$)' '$TMP_DIR/cv.txt'" \
        label       'the timeline CV cell reads CV:0.50' \
        asserts     'The CV cell renders through the CV cell budget at the two decimals its producer fixes, trailing zero kept' \
        produced_by 'print_bar_graph() in ltl, through value_text() and the CV cell budget row' \
        contract    "$CONTRACT D9, D28"
    assert_command \
        command     "grep -E '\\[200\\] GET /vd/cv' '$TMP_DIR/cv.txt' | grep -qE ' 30ms +0\\.50 '" \
        label       'the messages-table CV cell reads 0.50' \
        asserts     'The messages-table CV cell renders through the CV cell budget at two decimals, trailing zero kept' \
        produced_by 'print_message_summary() in ltl, through value_text() and the CV cell budget row' \
        contract    "$CONTRACT D9, D28"
    assert_command \
        command     "[[ -n '$csv' ]] && $PERL -MText::ParseWords -ne 'chomp; my @f = parse_line(\",\", 0, \$_); if (\$. == 1) { (\$i) = grep { \$f[\$_] eq \"duration_cv\" } 0..\$#f; die \"no duration_cv column\\n\" unless defined \$i; next } \$v = \$f[\$i]; END { die \"duration_cv is \" . (\$v // \"absent\") . \"\\n\" unless defined \$v && \$v eq \"0.5\" }' '$csv'" \
        label       'the MESSAGES CSV duration_cv cell reads 0.5' \
        asserts     'The CSV keeps its own precision family and strips its trailing zero (0.5); the cell shows the same value at two decimals (0.50)' \
        produced_by 'print_message_summary() in ltl, format_csv_value() for duration_cv' \
        contract    "$CONTRACT D28, correction 12"
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
# golden. Timestamps and IP addresses are excluded by the token shape; the CV
# cells keep their zeros by design (D28) and are removed before the scan: the
# timeline's CV: tokens, and on a messages-table row the one bare decimal, the
# CV column.
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
    without_cv() { $PERL -pe 's/CV:\S+//g; s/(?<=\s)\d+\.\d+(?=\s)//g if /^\S*\s*\[/' "$1" > "$2"; }
    assert_command \
        command     "for f in '$TMP_DIR'/nz-*.txt; do without_cv \"\$f\" \"\$f.nocv\"; check absent --file \"\$f.nocv\" --regex '$pattern' || exit 1; done" \
        label       'no value in the battery ends in a fractional zero' \
        asserts     'Trailing fractional zeros are stripped on every display surface after the decimals are chosen' \
        produced_by 'strip_trailing_zeros() in ltl, called by every arm of value_text()' \
        contract    "$CONTRACT D3, D28 (the CV cells excepted)"
    assert_command \
        command     "for f in '$REPO_DIR'/tests/reference-output/*.txt; do without_cv \"\$f\" '$TMP_DIR/golden.nocv'; check absent --file '$TMP_DIR/golden.nocv' --regex '$pattern' || exit 1; done" \
        label       'no value in a regression golden ends in a fractional zero' \
        asserts     'The frozen surfaces carry no trailing fractional zero' \
        produced_by 'strip_trailing_zeros() in ltl, called by every arm of value_text()' \
        contract    "$CONTRACT D3" \
        run_free    'the regression goldens under tests/reference-output'
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
    assert_command \
        command     "n=0; for w in 100 110 120 130 140 150 160 170 180 190 200 210 220; do visible_column fs-\$w bytes || continue; c=\$(cell_text fs-\$w '^ 2025-05-07 00:02' bytes) || exit 1; case \"\$c\" in *kilobyte*) n=\$((n + 1)); [[ \"\$c\" == '16.8 kilobytes' ]] || { echo \"width \$w: \$c\"; exit 1; } ;; 16800*) echo \"width \$w: \$c shown unclimbed\"; exit 1 ;; *' '*) [[ \"\$c\" == '16.8 kB' || \"\$c\" == '17 kB' ]] || { echo \"width \$w: \$c\"; exit 1; } ;; esac; done; [[ \$n -ge 1 ]]" \
        label       'a tabular column never trades a digit for the unit name, and bytes always climb: 16,800 bytes reads 16.8 kilobytes or 16.8 kB, 17 kB only where 16.8 kB does not fit, never 16800 B' \
        asserts     'A tabular column gives up the unit name first, then decimals within its tolerance, then the space, then the decimals the width forces' \
        produced_by 'value_walk_row() in ltl, the tabular walk of %value_intent' \
        contract    "$CONTRACT D23 (the order of what gives way), D27 (bytes climb at their steps)"
    render fs-hg "$FIT" -bs 1 -n 0 -osum -hm duration -hg duration --terminal-width 160 || return 0
    assert_command \
        command     "for f in '$TMP_DIR'/fs-*.txt; do check absent --file \"\$f\" --regex '(?<![\\w.])\\d+\\.\\d+ ?(ms|msec|milliseconds?)\\b' || exit 1; done" \
        label       'no surface (timeline, latency cells, heatmap header, histogram labels) shows a decimal at the millisecond step on a millisecond source' \
        asserts     'A rendered digit is never finer than the source resolution (latency cells included)' \
        produced_by 'format_time() in ltl: the resolution ceiling' \
        contract    "$CONTRACT D19"
}

# ---------------------------------------------------------------------------
# common-maxima (AC5): a count of 1,140,000 (seven digits, so never shown
# unclimbed) reads 1.14 million where its column has room for the long tier's
# two decimals, 1.1 and a unit where it has less, and 1.1Mil on the heatmap
# header (medium, one decimal); no value carries more decimals than its tier
# allows.
# ---------------------------------------------------------------------------
scenario_common_maxima() {
    current_scenario="common-maxima"
    echo "[$current_scenario]"
    render cm-wide "$COUNT_MAXIMA" -bs 1 -n 0 --terminal-width 160 --debug-layout || return 0
    render cm-narrow "$COUNT_MAXIMA" -bs 1 -n 0 --terminal-width 100 --debug-layout || return 0
    render cm-heatmap "$COUNT_MAXIMA" -bs 1 -n 0 --terminal-width 160 -hm count || return 0
    assert_command \
        command     "cell_text cm-wide '^ 2026-01-26 10:00' count | grep -qx '1.14 million'" \
        label       'a long-tier column reads 1.14 million' \
        asserts     'The long tier carries up to two decimals, the same maximum for every kind' \
        produced_by 'value_text() in ltl, %tier_decimals' \
        contract    "$CONTRACT D12"
    assert_command \
        command     "cell_text cm-narrow '^ 2026-01-26 10:00' count | grep -qE '^1\\.1 ?(M|Mil|million)\$'" \
        label       'a narrower column reads 1.1 and a unit' \
        asserts     'Where the width does not afford the long tier two decimals, the value gives one up' \
        produced_by 'value_text() in ltl, %tier_decimals' \
        contract    "$CONTRACT D12"
    assert_command \
        command     "check tokens --file '$TMP_DIR/cm-heatmap.txt' --line 'heatmap \\[count\\]' --each '1\\.1Mil' --min 1" \
        label       'the heatmap header reads 1.1Mil' \
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
        command     "$PERL -ne 'print \"\$1\\n\" if /^\\s*(\\S+) [^\\x00-\\x7f]/ && \$1 !~ /^(?:0|timestamp)\$/' '$TMP_DIR/at.txt' > '$TMP_DIR/at-ticks' && grep -qx '1155' '$TMP_DIR/at-ticks' && [[ \$(sort '$TMP_DIR/at-ticks' | uniq -d | wc -l) -eq 0 ]]" \
        label       'the top tick reads 1155 and no two ticks read alike' \
        asserts     'The y-axis tick names the axis tick budget (the six-character label field): 1,155 reads 1155 unclimbed (D26), never 1k above 866' \
        produced_by 'render_histogram_row() in ltl, through value_text() and the axis tick row' \
        contract    "$CONTRACT D1, D8, D9, D26; correction 6"
}

# ---------------------------------------------------------------------------
# exact-counts (AC13): tables and the summary print exact occurrence counts;
# the legend shows a count unclimbed up to five digits and keeps its tier
# above, and under -pv (the precise intent) reads exact. Generated: 1,200 and
# 123,456 lines of the verification format whose duration satisfies neither
# outcome.
# ---------------------------------------------------------------------------
scenario_exact_counts() {
    current_scenario="exact-counts"
    echo "[$current_scenario]"
    local gen="$TMP_DIR/exact-1200.txt"
    "$PERL" -e 'for my $i (0..1199) { printf "VERIFY CLS 2025-06-01 10:%02d:%02d.000 level=INFO thread=worker-1 object=Store took=1500 cache warm\n", int($i/60) % 60, $i % 60 }' > "$gen"
    render ec "$gen" -lf classification_verification -bs 1440 -n 1 --terminal-width 160 || return 0
    local big="$TMP_DIR/exact-123456.txt"
    "$PERL" -e 'for my $i (0..123455) { printf "VERIFY CLS 2025-06-01 %02d:%02d:%02d.000 level=INFO thread=worker-1 object=Store took=1500 cache warm\n", int($i/3600) % 24, int($i/60) % 60, $i % 60 }' > "$big"
    render ec-big "$big" -lf classification_verification -bs 1440 -oe -n 1 --terminal-width 160 || return 0
    render ec-big-pv "$big" -lf classification_verification -bs 1440 -oe -n 1 -pv --terminal-width 160 || return 0
    assert_command \
        command     "grep -E 'cache warm' '$TMP_DIR/ec.txt' | grep -qE ' 1200 ' && grep -qE '^ +LINES READ +1200 ' '$TMP_DIR/ec.txt' && grep -qE '^ +INFO +1200 \\(100%\\)' '$TMP_DIR/ec.txt'" \
        label       'the messages table and the summary read 1200' \
        asserts     'Tables and the summary print exact occurrence counts' \
        produced_by 'print_message_summary() and print_summary_table() in ltl (the exact count row)' \
        contract    "$CONTRACT D5"
    assert_command \
        command     "grep -qE '^ 2025-06-01 00:00 INFO: 1200 ' '$TMP_DIR/ec.txt' && grep -qE '^ 2025-06-01 00:00 INFO: 123\\.5k ' '$TMP_DIR/ec-big.txt' && grep -qE '^ 2025-06-01 00:00 INFO: 123456 ' '$TMP_DIR/ec-big-pv.txt'" \
        label       'the legend reads 1200 and 123.5k, and 123456 under -pv' \
        asserts     'The legend shows a count of five digits or fewer unclimbed (D26); above, it keeps its tier, and -pv names the precise intent: the exact value' \
        produced_by 'legend_category_total() in ltl, through value_text() and the legend total row' \
        contract    "$CONTRACT D5, D17, D26"
}

# ---------------------------------------------------------------------------
# The precision the raw data carries (features/759-duration-precision-rendering.md):
# the unit the durations are read in descended by the decimals they are
# written with, counted in the detection sample. It is the floor and the
# rounding of every duration rendering; a value above it renders in the unit
# its magnitude reaches, whatever unit it was read in.
# ---------------------------------------------------------------------------
PRECISION_CONTRACT='features/759-duration-precision-rendering.md'

# One access-log line of the common-plus-duration shape: TIME (MM:SS within
# 00:xx), PATH, DURATION as written.
access_line() {
    printf '192.0.2.30 - - [07/May/2025:00:%s +0000] "GET %s HTTP/1.1" 200 512 %s\n' "$1" "$2" "$3"
}

# The messages-table Min, P50 and P99.9 of the row for PATH, space-separated.
msg_cells() {
    "$PERL" -ne 'BEGIN { $p = shift } if (/\Q$p\E\s+\d+\s+(\S+)\s+(\S+)\s+(\S+)/) { print "$1 $2 $3"; exit }' "$2" "$TMP_DIR/$1.txt"
}

# The text of a render that does not depend on how its input was named or
# read: the banner, the echoed options, the file pane and the tool's own
# timings are left out.
comparable() {
    grep -vE 'log timeline \[|command-line options|tomcat-access-duration-spread|TOTAL TIME|MAXIMUM MEMORY' "$TMP_DIR/$1.txt"
}

# ---------------------------------------------------------------------------
# precision-pair (AC1): the same durations read in milliseconds and in
# seconds with three decimals under -du s render the same text on every
# duration surface: the timeline, the messages table, the heatmap header and
# footer, the histogram axis and legend, the -V display-dimensions line, and
# the STATS and MESSAGES CSVs. -bs 60 -n 20: the timeline, a full messages
# table, both charts and the CSVs, at one width.
# ---------------------------------------------------------------------------
scenario_precision_pair() {
    current_scenario="precision-pair"
    echo "[$current_scenario]"
    local args=(-bs 60 -n 20 --terminal-width 200 -hm duration -hg duration -o -V histogram-bin-counters) side
    for side in ms s; do
        rm -f "$TMP_DIR"/*-LTL-*.csv
        if [[ $side == ms ]]; then
            render pair-ms "$DURATION_SPREAD" "${args[@]}" || return 0
        else
            render pair-s "$DURATION_SPREAD_SECONDS" -du s "${args[@]}" || return 0
        fi
        mkdir -p "$TMP_DIR/pair-$side-csv"
        mv "$TMP_DIR"/*-LTL-MESSAGES-*.csv "$TMP_DIR/pair-$side-csv/messages.csv"
        mv "$TMP_DIR"/*-LTL-STATS-*.csv "$TMP_DIR/pair-$side-csv/stats.csv"
    done
    assert_command \
        command     "diff <(comparable pair-ms) <(comparable pair-s)" \
        label       'every duration surface reads the same, read in milliseconds or in seconds with three decimals' \
        asserts     'A value carries its magnitude whatever unit it is read in: seconds written with three decimals carry the millisecond, so the timeline, messages table, heatmap, histogram and dimensions line render as the same values read in milliseconds' \
        produced_by 'resolve_duration_precision() in ltl, the floor resolve_value_kind() hands value_text()' \
        contract    "$PRECISION_CONTRACT § 2, D2; AC1"
    assert_command \
        command     "grep -qE 'P50: 30ms' '$TMP_DIR/pair-s.txt' && [[ \"\$(msg_cells pair-s '/Thingworx/Metrics')\" == '0ms 0ms 2ms' ]] && check absent --file '$TMP_DIR/pair-s.txt' --regex '(?<![\\w.])0(?:\\.\\d+)? ?(?:s|sec|seconds)\\b'" \
        label       'under -du s the legend reads P50: 30ms, a zero reads 0ms, and nothing below a second reads in seconds' \
        asserts     'Under -du s on seconds with three decimals, a value below a second renders in milliseconds and a zero in the millisecond' \
        produced_by 'render_histogram_legend() and print_message_summary() in ltl, through value_text()' \
        contract    "$PRECISION_CONTRACT § 2; AC1"
    assert_command \
        command     "cmp '$TMP_DIR/pair-ms-csv/messages.csv' '$TMP_DIR/pair-s-csv/messages.csv' && cmp '$TMP_DIR/pair-ms-csv/stats.csv' '$TMP_DIR/pair-s-csv/stats.csv'" \
        label       'the MESSAGES and STATS CSVs are identical, duration_nice included' \
        asserts     'Every value is stored in milliseconds and rendered at the same precision, so the CSVs of the two readings are the same bytes' \
        produced_by 'build_messages_csv_columns() and build_stats_csv_columns() in ltl' \
        contract    "$PRECISION_CONTRACT AC1"
}

# ---------------------------------------------------------------------------
# precision-zero (AC2): a zero renders in the precision: 0ms on whole
# milliseconds, 0us on milliseconds with three decimals, 0s on whole seconds
# and 0ms on seconds with three decimals (-du s), on the timeline latency
# cells and duration column, the messages table and the heatmap header.
# Generated: three zeros in one bucket and a non-zero in another (-bs 1, no
# heatmap, so the latency cells draw), and the zeros alone under -hm, where
# the header has nothing else to show.
# ---------------------------------------------------------------------------
scenario_precision_zero() {
    current_scenario="precision-zero"
    echo "[$current_scenario]"
    local row tag zero five du unit long gen du_args
    for row in "ms|0|5||ms|milliseconds" "ms3|0.000|5.000||us|microseconds" "s|0|5|s|s|seconds" "s3|0.000|0.005|s|ms|milliseconds"; do
        IFS='|' read -r tag zero five du unit long <<< "$row"
        du_args=(); [[ -n "$du" ]] && du_args=(-du "$du")
        gen="$TMP_DIR/zero-$tag.txt"
        { access_line 00:10 /vd/zero "$zero"; access_line 00:20 /vd/zero "$zero"; access_line 00:30 /vd/zero "$zero"; } > "$gen"
        render "pz-$tag-hm" "$gen" "${du_args[@]}" -bs 1 -n 1 --terminal-width 160 -hm duration || return 0
        access_line 02:10 /vd/five "$five" >> "$gen"
        render "pz-$tag" "$gen" "${du_args[@]}" -bs 1 -n 2 --terminal-width 200 --debug-layout || return 0
        assert_command \
            command     "cell_text pz-$tag '^ 2025-05-07 00:00' duration | grep -qx '0 $long' && grep -E '^ 2025-05-07 00:00' '$TMP_DIR/pz-$tag.txt' | grep -qE 'P50:0$unit +P95:0$unit +P99:0$unit +P999:0$unit' && [[ \"\$(msg_cells pz-$tag /vd/zero)\" == '0$unit 0$unit 0$unit' ]] && check tokens --file '$TMP_DIR/pz-$tag-hm.txt' --line 'heatmap \\[duration\\]' --each '0$unit' --min 2" \
            label       "durations written as '$zero'${du:+ under -du $du}: a zero reads 0$unit on the duration column, latency cells, messages table and heatmap header" \
            asserts     "A zero carries no magnitude, so it renders in the raw data's unit combined with the precision it carries" \
            produced_by 'resolve_duration_precision() in ltl; format_time() renders a zero at its floor' \
            contract    "$PRECISION_CONTRACT D1, D2; features/617-width-to-format-rule.md D4 as amended; AC2"
    done
}

# ---------------------------------------------------------------------------
# precision-floor (AC3): nothing renders below the precision. On milliseconds
# with three decimals a 0.5 ms duration reads 500us and nothing reads in
# nanoseconds; on seconds with three decimals under -du s nothing reads below
# the millisecond. -bs 1440 -oe: one bucket; the messages table and heatmap
# header are read.
# ---------------------------------------------------------------------------
scenario_precision_floor() {
    current_scenario="precision-floor"
    echo "[$current_scenario]"
    local gen="$TMP_DIR/floor-sub.txt"
    { access_line 00:10 /vd/half 0.500; access_line 00:11 /vd/half 0.500; access_line 00:12 /vd/half 0.500; access_line 00:20 /vd/frac 12.345; } > "$gen"
    render pf-sub "$gen" -bs 1440 -oe -n 2 --terminal-width 200 -hm duration -hg duration || return 0
    render pf-s "$DURATION_SPREAD_SECONDS" -du s -bs 60 -n 20 --terminal-width 200 -hm duration -hg duration || return 0
    assert_command \
        command     "[[ \"\$(msg_cells pf-sub /vd/half)\" == '500us 500us 500us' ]] && grep -E 'heatmap \\[duration\\]' '$TMP_DIR/pf-sub.txt' | grep -qE '500us' && check absent --file '$TMP_DIR/pf-sub.txt' --regex '(?<![\\w.])[0-9.]+ ?(ns|nsec|nanoseconds?)\\b'" \
        label       'milliseconds with three decimals: 0.5 ms reads 500us, nothing reads in nanoseconds' \
        asserts     'Milliseconds written with three decimals carry the microsecond: a value below a millisecond renders in microseconds, and no unit finer than the microsecond is rendered' \
        produced_by 'resolve_duration_precision() in ltl; format_time() climbs from the floor' \
        contract    "$PRECISION_CONTRACT § 2; AC3"
    assert_command \
        command     "check absent --file '$TMP_DIR/pf-s.txt' --regex '(?<![\\w.])[0-9.]+ ?(us|ns|usec|nsec|microseconds?|nanoseconds?)\\b'" \
        label       'seconds with three decimals under -du s: nothing reads below the millisecond' \
        asserts     'Seconds written with three decimals carry the millisecond, so nothing below a millisecond is rendered' \
        produced_by 'resolve_duration_precision() in ltl; format_time() climbs from the floor' \
        contract    "$PRECISION_CONTRACT § 2; AC3"
}

# ---------------------------------------------------------------------------
# precision-part-group (AC4): one or two decimals step down one unit, as
# three do: 12.3 ms reads 12.3ms, 0.4 ms reads 400us, and 0.05 s under -du s
# reads 50ms. -bs 1440 -oe: the messages table is read.
# ---------------------------------------------------------------------------
scenario_precision_part_group() {
    current_scenario="precision-part-group"
    echo "[$current_scenario]"
    local ms="$TMP_DIR/part-ms.txt" s="$TMP_DIR/part-s.txt"
    { access_line 00:10 /vd/a 12.3; access_line 00:11 /vd/b 0.4; } > "$ms"
    access_line 00:10 /vd/c 0.05 > "$s"
    render pg-ms "$ms" -bs 1440 -oe -n 2 --terminal-width 200 || return 0
    render pg-s "$s" -du s -bs 1440 -oe -n 1 --terminal-width 200 || return 0
    assert_command \
        command     "[[ \"\$(msg_cells pg-ms /vd/a)\" == '12.3ms 12.3ms 12.3ms' && \"\$(msg_cells pg-ms /vd/b)\" == '400us 400us 400us' && \"\$(msg_cells pg-s /vd/c)\" == '50ms 50ms 50ms' ]]" \
        label       '12.3 ms reads 12.3ms, 0.4 ms reads 400us, 0.05 s under -du s reads 50ms' \
        asserts     'A part-group of decimals is a full group whose trailing zeros are not written, so it steps down one unit' \
        produced_by 'fraction_precision() and resolve_duration_precision() in ltl' \
        contract    "$PRECISION_CONTRACT D3; AC4"
}

# ---------------------------------------------------------------------------
# precision-rounding (AC5): a computed value is rounded at the precision. The
# histogram's axis labels are computed bin edges: on whole milliseconds none
# carries a digit below the millisecond; on the same durations written to the
# microsecond (N.000) they carry the microsecond's digits. -bs 1440 -oe -n 0:
# the histogram alone is read.
# ---------------------------------------------------------------------------
scenario_precision_rounding() {
    current_scenario="precision-rounding"
    echo "[$current_scenario]"
    local us="$TMP_DIR/spread-us.txt"
    awk '{ $NF = sprintf("%.3f", $NF); print }' "$DURATION_SPREAD" > "$us"
    render pr-ms "$DURATION_SPREAD" -bs 1440 -oe -n 0 --terminal-width 160 -hg duration || return 0
    render pr-us "$us" -bs 1440 -oe -n 0 --terminal-width 160 -hg duration || return 0
    assert_command \
        command     "grep -E '([0-9]+ms +){4}' '$TMP_DIR/pr-ms.txt' | grep -q . && ! grep -qE '[0-9]\\.[0-9]+ms' '$TMP_DIR/pr-ms.txt' && grep -qE '(^| )[0-9]+\\.[0-9]ms( |\$)' '$TMP_DIR/pr-us.txt'" \
        label       'axis labels: whole milliseconds on whole-millisecond durations, tenths of a millisecond on durations written to the microsecond' \
        asserts     'A computed value shows no digit finer than the precision the raw data carries, and the digits that precision allows' \
        produced_by 'calculate_histogram_x_labels() in ltl, through value_text(); format_time() rounds at the resolution' \
        contract    "$PRECISION_CONTRACT § 5 (a computed value is rounded at the precision); features/608-byte-unit-ladder.md D9; AC5"
}

# ---------------------------------------------------------------------------
# precision-several-files (AC6): a run takes the finest precision any file
# carries: a file of whole milliseconds read with one written to the
# microsecond renders a zero 0us. -bs 1440 -oe: the messages table is read.
# ---------------------------------------------------------------------------
scenario_precision_several_files() {
    current_scenario="precision-several-files"
    echo "[$current_scenario]"
    local whole="$TMP_DIR/several-whole.txt" micro="$TMP_DIR/several-micro.txt"
    { access_line 00:10 /vd/zero 0; access_line 00:11 /vd/five 5; } > "$whole"
    { access_line 00:20 /vd/zero 0.000; access_line 00:21 /vd/five 5.000; } > "$micro"
    local raw="$TMP_DIR/psf.raw" err="$TMP_DIR/psf.stderr"
    ( cd "$TMP_DIR" && "$LTL" --disable-progress -bs 1440 -oe -n 2 --terminal-width 200 "$whole" "$micro" ) > "$raw" 2> "$err" || true
    assert_no_runtime_warnings "$err" "$current_scenario" || { fail=$((fail + 1)); failures+=("$current_scenario :: runtime warnings"); }
    sed -E 's/\x1b\[[0-9;]*m//g' "$raw" > "$TMP_DIR/psf.txt"
    assert_command \
        command     "[[ \"\$(msg_cells psf /vd/zero)\" == '0us 0us 0us' ]]" \
        label       'whole milliseconds read with milliseconds written to the microsecond: a zero reads 0us' \
        asserts     'A run takes the finest precision any file carries; one written with fewer decimals does not lower it' \
        produced_by 'resolve_duration_precision() in ltl' \
        contract    "$PRECISION_CONTRACT § 5 (several files); AC6"
}

# ---------------------------------------------------------------------------
# precision-udm-fallback (AC7, D5 as amended): a metric the detection sample
# never reaches takes its decimals from the buckets' stored extremes after the
# read. Generated: 700 lines of the seconds-metric fixture's format, about 113
# KB, whose only metric lines (elapsed=0.012) start at byte 24,138, between
# the sample's front part and its middle one. -bs 1440 -oe -n 0: one bucket,
# its timeline cell and the heatmap header are read.
# ---------------------------------------------------------------------------
scenario_precision_udm_fallback() {
    current_scenario="precision-udm-fallback"
    echo "[$current_scenario]"
    local gen="$TMP_DIR/udm-fallback.txt"
    "$PERL" -e 'for my $i (0..699) { my $tail = ($i >= 150 && $i < 156) ? "VD-seconds executed elapsed=0.012" : "VD-filler executed without a value to read here at all"; printf "2026-01-26 10:%02d:%02d.000+0000 [L: INFO] [O: ValueDisplayFixture] [I: ] [U: admin] [S: ] [P: ] [T: pool-a-1] %s\n", int($i/60)%60, $i % 60, $tail }' > "$gen"
    render puf "$gen" -bs 1440 -oe -n 0 --terminal-width 160 --debug-layout -udm 'elapsed:s:max' -hm elapsed || return 0
    assert_command \
        command     "[[ \$(awk '/elapsed=/ { print c; exit } { c += length(\$0) + 1 }' '$gen') -gt 8192 ]] && cell_text puf '^ 2026-01-26 00:00' udm_elapsed | grep -qE '^12 ?(ms|msec|milliseconds)\$' && grep -E 'heatmap \\[elapsed\\]' '$TMP_DIR/puf.txt' | grep -qE '12ms .*heatmap \\[elapsed\\] +12ms *\$'" \
        label       'a seconds metric first seen past the sample reads 12 milliseconds on its timeline cell and heatmap header' \
        asserts     "A metric the detection sample never reaches takes its decimals from the buckets' stored extremes, read back in its declared unit: 0.012 s carries the millisecond" \
        produced_by 'resolve_udm_decimals() in ltl, after the read; udm_precision() gives the floor' \
        contract    "features/759-duration-precision-rendering.md D5 as amended, AC7"
}

scenario_register count-spelling fixed-budget-sweep zero-duration floor-unit cv-agreement user-defined-kind rate-suffix fit-sweep common-maxima boundary-carry messages-total axis-tick exact-counts no-trailing-zero precision-pair precision-zero precision-floor precision-part-group precision-rounding precision-several-files precision-udm-fallback
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
scenario_wanted exact-counts       && { scenario_exact_counts; echo ""; }
scenario_wanted no-trailing-zero   && { scenario_no_trailing_zero; echo ""; }
scenario_wanted precision-pair          && { scenario_precision_pair; echo ""; }
scenario_wanted precision-zero          && { scenario_precision_zero; echo ""; }
scenario_wanted precision-floor         && { scenario_precision_floor; echo ""; }
scenario_wanted precision-part-group    && { scenario_precision_part_group; echo ""; }
scenario_wanted precision-rounding      && { scenario_precision_rounding; echo ""; }
scenario_wanted precision-several-files && { scenario_precision_several_files; echo ""; }
scenario_wanted precision-udm-fallback  && { scenario_precision_udm_fallback; echo ""; }

echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 || "$pass" -eq 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do echo "  - $f"; done
    exit 1
fi
echo "ALL VALUE-DISPLAY TESTS PASSED"
