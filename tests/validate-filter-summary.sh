#!/usr/bin/env bash
# validate-filter-summary.sh - the run's line accounting as the funnel it
# passed through, observed on -V filter-summary (Issue #503).
#
# Every line read is exactly one of: unmatched by any format, excluded by a
# criterion after matching (counted per cause), or included. One scenario per
# cause proves its counter against a fixture whose drop count is known by
# construction; the identities lines_read = lines_unmatched + lines_excluded +
# lines_included and lines_excluded = sum of the five causes hold on every
# scenario; the same counters are read back from the two other surfaces that
# print them (-V format-detection / classification and -V benchmark-data); and
# the run summary table carries no new row.
#
# Contract: features/503-yaml-aggregate-export.md section
# "-V filter-summary section contract"; tests/HARNESS-DESIGN.md.
#
# Invocation shape (HARNESS-DESIGN.md section Invocation coherence): every
# assertion reads a -V section or the run summary, so each run takes the
# coarsest bucket, no empty buckets, the smallest table and no index
# (-bs 1440 -oe -n 1 -ni); -osum is dropped only where the summary is read.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"
FIXTURES="$REPO_DIR/tests/fixtures"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
neutralize_colour_env

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"
    exit 1
fi

ONLY_SCENARIO=""
if [[ "${1:-}" == "--scenario" ]]; then
    ONLY_SCENARIO="${2:?--scenario needs a name}"
fi

pass=0
fail=0
failures=()
current_scenario=""

CONTRACT='features/503-yaml-aggregate-export.md section -V filter-summary section contract - key names and the funnel identities are stability-contracted (HARNESS-DESIGN.md section Stability contract)'
PRODUCER='emit_filter_summary_verbose() in ltl'

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

# Contracted absence: a line matching `pattern` must NOT be present. A
# missing capture is a hard failure, never a pass.
assert_absent() {
    local outfile="$1"
    shift
    local pattern asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            pattern)     pattern="$2";     shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_absent: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${pattern:?assert_absent requires pattern}"
    : "${asserts:?assert_absent requires asserts}"
    : "${produced_by:?assert_absent requires produced_by}"
    : "${contract:?assert_absent requires contract}"

    if [[ ! -f "$outfile" ]]; then
        echo "  FAIL  $current_scenario :: capture file missing: $outfile" >&2
        fail=$((fail + 1))
        failures+=("$current_scenario :: missing capture for absence check")
        return
    fi
    if grep -qE "$pattern" "$outfile"; then
        echo "  FAIL  $current_scenario"
        echo "        pattern:     $pattern (contracted ABSENT, but found)"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
        failures+=("$current_scenario :: absent-pattern found: $pattern")
    else
        echo "  PASS  $current_scenario :: absent: $pattern"
        pass=$((pass + 1))
    fi
}

# Equality between two integers read from surfaces, with the same triple.
assert_equal() {
    local label="$1" left="$2" right="$3"
    shift 3
    local asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_equal: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${asserts:?assert_equal requires asserts}"
    : "${produced_by:?assert_equal requires produced_by}"
    : "${contract:?assert_equal requires contract}"
    if [[ -n "$left" && -n "$right" && "$left" -eq "$right" ]]; then
        echo "  PASS  $current_scenario :: $label ($left == $right)"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario :: $label ('$left' != '$right')"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
        failures+=("$current_scenario :: $label")
    fi
}

# Read `key: N` from a captured section. A key that is absent is a hard
# failure here (a lookup that matches nothing is never a pass), reported
# through the same accounting so the run continues to the summary.
section_value() {
    local outfile="$1" key="$2"
    local v
    v=$(grep -E "^${key}: [0-9]+$" "$outfile" | head -1 | sed -E 's/^[^:]+: //')
    if [[ -z "$v" ]]; then
        echo "  FAIL  $current_scenario :: key '$key' absent from $outfile" >&2
        fail=$((fail + 1))
        failures+=("$current_scenario :: key $key absent")
        echo ""
        return
    fi
    echo "$v"
}

# Read a benchmark-data TSV row (`key<TAB>N`).
benchmark_value() {
    local outfile="$1" key="$2"
    local v
    v=$(grep -E "^${key}	[0-9]+$" "$outfile" | head -1 | cut -f2)
    if [[ -z "$v" ]]; then
        echo "  FAIL  $current_scenario :: benchmark-data row '$key' absent from $outfile" >&2
        fail=$((fail + 1))
        failures+=("$current_scenario :: benchmark-data row $key absent")
        echo ""
        return
    fi
    echo "$v"
}

# Run ltl with the four sections the scenarios read. Extra args precede the
# log. Echoes the capture path; stderr sits beside it as <capture>.stderr.
run_sections() {
    local log="$1"
    shift
    local outfile="$TMP_DIR/$current_scenario.out"
    set +e
    "$LTL" --disable-progress -ni -bs 1440 -oe -n 1 -osum \
        -V filter-summary,format-detection,benchmark-data,profile "$@" "$log" \
        > "$outfile" 2>"$outfile.stderr"
    local ec=$?
    set -e
    if [[ "$ec" -ne 0 ]]; then
        echo "FAIL: ltl exited $ec for $current_scenario; stderr:" >&2
        sed 's/^/    /' "$outfile.stderr" >&2
        exit 1
    fi
    if ! grep -qE '^=== filter-summary ===$' "$outfile"; then
        echo "FAIL: filter-summary section header not found in $outfile" >&2
        exit 1
    fi
    if ! assert_no_runtime_warnings "$outfile.stderr" "$current_scenario"; then
        fail=$((fail + 1))
        failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
    fi
    echo "$outfile"
}

# The identities every scenario must satisfy, plus the two cross-surface
# read-backs: format-detection / classification prints the run's unmatched
# total from the same counter, benchmark-data re-emits read / excluded /
# included (HARNESS-DESIGN.md: one source, two surfaces).
assert_funnel_identities() {
    local out="$1"
    local read unmatched excluded included tw pr fi nu ot
    read=$(section_value "$out" lines_read)
    unmatched=$(section_value "$out" lines_unmatched)
    excluded=$(section_value "$out" lines_excluded)
    included=$(section_value "$out" lines_included)
    tw=$(section_value "$out" excluded_time_window)
    pr=$(section_value "$out" excluded_profile)
    fi=$(section_value "$out" excluded_filter)
    nu=$(section_value "$out" excluded_numeric)
    ot=$(section_value "$out" excluded_other)
    [[ -z "$read$unmatched$excluded$included$tw$pr$fi$nu$ot" ]] && return
    assert_equal "read = unmatched + excluded + included" "$read" $((unmatched + excluded + included)) \
        asserts 'Every line read is exactly one of unmatched, excluded or included; the three stages partition lines_read' \
        produced_by "$PRODUCER" \
        contract "$CONTRACT - the funnel identity"
    assert_equal "excluded = sum of causes" "$excluded" $((tw + pr + fi + nu + ot)) \
        asserts 'lines_excluded is the sum of the five per-cause counters, nothing more' \
        produced_by 'lines_excluded_total() in ltl' \
        contract "$CONTRACT - lines_excluded definition"
    local fd_unmatched bd_read bd_excluded bd_included
    fd_unmatched=$(section_value "$out" unmatched_lines)
    assert_equal "format-detection unmatched_lines" "$fd_unmatched" "$unmatched" \
        asserts 'The classification sub-section of -V format-detection prints the run unmatched total from the same counter' \
        produced_by 'emit_format_detection_verbose() in ltl (classification sub-section, unmatched_lines)' \
        contract "$CONTRACT - lines_unmatched is the value format-detection / classification prints as unmatched_lines"
    bd_read=$(benchmark_value "$out" lines_read)
    bd_excluded=$(benchmark_value "$out" lines_excluded)
    bd_included=$(benchmark_value "$out" lines_included)
    assert_equal "benchmark-data lines_read" "$bd_read" "$read" \
        asserts 'benchmark-data re-emits lines_read from the same variable' \
        produced_by 'print_verbose_output() in ltl (benchmark-data lines_read row)' \
        contract 'tests/HARNESS-DESIGN.md section one source, two surfaces'
    assert_equal "benchmark-data lines_excluded" "$bd_excluded" "$excluded" \
        asserts 'benchmark-data re-emits lines_excluded through the one sum lines_excluded_total()' \
        produced_by 'print_verbose_output() in ltl (benchmark-data lines_excluded row)' \
        contract 'tests/HARNESS-DESIGN.md section one source, two surfaces; features/503-yaml-aggregate-export.md D12'
    assert_equal "benchmark-data lines_included" "$bd_included" "$included" \
        asserts 'benchmark-data re-emits lines_included from the same variable' \
        produced_by 'print_verbose_output() in ltl (benchmark-data lines_included row)' \
        contract 'tests/HARNESS-DESIGN.md section one source, two surfaces'
}

# One per-cause scenario: run, assert the counter, assert the identities.
# Arguments: name, fixture, key, expected, asserts-text, then ltl options.
cause_scenario() {
    local name="$1" fixture="$2" key="$3" expected="$4" asserts="$5"
    shift 5
    current_scenario="$name"
    [[ -n "$ONLY_SCENARIO" && "$ONLY_SCENARIO" != "$name" ]] && return
    local out
    out=$(run_sections "$fixture" "$@")
    assert_line "$out" pattern "^${key}: ${expected}\$" \
        asserts "$asserts" \
        produced_by "$PRODUCER" \
        contract "$CONTRACT"
    assert_funnel_identities "$out"
}

echo "Validating -V filter-summary line accounting (Issue #503)"
echo ""

# --- no filter: nothing excluded, the one unrecognised line is unmatched ---
cause_scenario unmatched "$FIXTURES/message-control-characters-unmatched.txt" \
    lines_unmatched 1 \
    'The space-led continuation line no format recognises is the one unmatched line; the two matched lines are included'
if [[ -z "$ONLY_SCENARIO" || "$ONLY_SCENARIO" == unmatched ]]; then
    out="$TMP_DIR/unmatched.out"
    assert_line "$out" pattern '^lines_excluded: 0$' \
        asserts 'With no criterion in force nothing is excluded: unmatched is not excluded' \
        produced_by "$PRODUCER" contract "$CONTRACT"
    assert_line "$out" pattern '^lines_included: 2$' \
        asserts 'The two matched lines pass every gate' \
        produced_by "$PRODUCER" contract "$CONTRACT"
fi

# --- time window: absolute bound, and time-of-day bound ---
# tomcat-access-duration-spread.txt: 434 lines over 14.5 h from 00:00 on
# 2025-05-07; 360 fall before noon, 74 at or after it.
cause_scenario time-window-absolute "$FIXTURES/tomcat-access-duration-spread.txt" \
    excluded_time_window 360 \
    'An absolute -st drops every line before the bound: 360 of the 434 lines precede 12:00 on the fixture day' \
    -st "2025-05-07 12:00:00"
cause_scenario time-window-time-of-day "$FIXTURES/tomcat-access-duration-spread.txt" \
    excluded_time_window 360 \
    'A time-of-day -st drops the same 360 lines through the repeating daily window' \
    -st "12:00"

# --- profile fold: five daily lines Wed..Sun, -pr workday drops Sat and Sun ---
cause_scenario profile-fold "$FIXTURES/profile-weekend-fold.txt" \
    excluded_profile 2 \
    'The two weekend lines fold to no day under -pr workday and are counted as profile drops' \
    -pr workday
if [[ -z "$ONLY_SCENARIO" || "$ONLY_SCENARIO" == profile-fold ]]; then
    out="$TMP_DIR/profile-fold.out"
    assert_line "$out" pattern '^samples_dropped: 2$' \
        asserts 'excluded_profile reads the same counter -V profile prints as samples_dropped' \
        produced_by 'emit_profile_verbose() in ltl' \
        contract 'features/451-weekday-weekend-profile-modes.md section -V profile section contract; features/503-yaml-aggregate-export.md D12 (the fold is its own cause, read from $profile_dropped_samples)'
fi

# --- content filter: five /store/catalog lines of the ten ---
cause_scenario content-filter "$FIXTURES/http-status-families.txt" \
    excluded_filter 5 \
    '-e drops the five lines whose request path matches; the content and outcome filters share one cause' \
    -e catalog

# --- outcome filter: the four 4xx/5xx lines are the failures ---
cause_scenario outcome-filter "$FIXTURES/http-status-families.txt" \
    excluded_filter 4 \
    '-ef drops the four lines the access-log rule classifies as failures (two 4xx, two 5xx)' \
    -ef

# --- numeric thresholds: 19 lines, 4 carry a duration inside [100,200] ---
cause_scenario numeric-threshold "$FIXTURES/numeric-highlight-boundary.txt" \
    excluded_numeric 15 \
    '-dmin 100 -dmax 200 keeps at-min, inside, at-max and cross-both; the other 15 lines, the one with no duration among them, are numeric drops' \
    -dmin 100 -dmax 200
if [[ -z "$ONLY_SCENARIO" || "$ONLY_SCENARIO" == numeric-threshold ]]; then
    out="$TMP_DIR/numeric-threshold.out"
    assert_line "$out" pattern '^lines_included: 4$' \
        asserts 'Exactly the four in-range lines survive' \
        produced_by "$PRODUCER" contract "$CONTRACT"
fi

# --- other: a level outside the vocabulary ---
cause_scenario vocabulary-rejection "$FIXTURES/log-level-outside-vocabulary.txt" \
    excluded_other 1 \
    'A matched line whose level is not in the log-level vocabulary is dropped at the category gate and counted as other'

# --- other: an unparseable CSV timestamp row; the CSV metadata line is unmatched (D22) ---
current_scenario="csv-unparseable-row"
if [[ -z "$ONLY_SCENARIO" || "$ONLY_SCENARIO" == "$current_scenario" ]]; then
    printf 'timestamp,latency\n2026-06-01 10:00:05,12\nnot-a-timestamp,34\n2026-06-01 10:02:05,56\n' > "$TMP_DIR/bad-row.csv"
    out=$(run_sections "$TMP_DIR/bad-row.csv" -udm latency:ms:mean)
    assert_line "$out" pattern '^excluded_other: 1$' \
        asserts 'The row whose timestamp is neither epoch nor ISO is skipped and counted as other' \
        produced_by "$PRODUCER" contract "$CONTRACT"
    assert_line "$out" pattern '^lines_unmatched: 1$' \
        asserts 'The CSV header line is metadata matched to no format and counts as unmatched' \
        produced_by 'note_unmatched_line() in ltl, called at the CSV header stash in read_and_process_logs()' \
        contract 'features/503-yaml-aggregate-export.md D22 (a CSV file first line is metadata and counts as unmatched)'
    assert_line "$out" pattern '^lines_included: 2$' \
        asserts 'The two well-formed rows are included' \
        produced_by "$PRODUCER" contract "$CONTRACT"
    assert_funnel_identities "$out"
fi

# --- highlight: never a drop; the sister row counts the highlighted subset ---
cause_scenario highlight "$FIXTURES/http-status-families.txt" \
    lines_highlighted 3 \
    'A highlight marks the three /store/orders lines without excluding anything' \
    -h orders
if [[ -z "$ONLY_SCENARIO" || "$ONLY_SCENARIO" == highlight ]]; then
    out="$TMP_DIR/highlight.out"
    assert_line "$out" pattern '^lines_excluded: 0$' \
        asserts 'A highlight criterion drops no line' \
        produced_by "$PRODUCER" contract "$CONTRACT"
fi

# --- every cause at once: the sum identity across causes ---
cause_scenario combined-causes "$FIXTURES/http-status-families.txt" \
    lines_excluded 8 \
    '-e catalog drops the five catalog lines first, then -ef drops the three failures among the rest (403 and 500 on /store/orders, 404 on /store/missing); lines_excluded is their sum' \
    -e catalog -ef

# --- the run summary table is unchanged: no accounting row is added ---
current_scenario="summary-table-unchanged"
if [[ -z "$ONLY_SCENARIO" || "$ONLY_SCENARIO" == "$current_scenario" ]]; then
    out="$TMP_DIR/summary.out"
    set +e
    "$LTL" --disable-progress -ni -bs 1440 -oe -n 1 -e catalog "$FIXTURES/http-status-families.txt" > "$out" 2>"$out.stderr"
    ec=$?
    set -e
    [[ "$ec" -eq 0 ]] || { echo "FAIL: ltl exited $ec for $current_scenario" >&2; exit 1; }
    if ! assert_no_runtime_warnings "$out.stderr" "$current_scenario"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
    fi
    assert_line "$out" pattern 'LINES READ +10' \
        asserts 'The run summary keeps its LINES READ row' \
        produced_by 'print_summary_table() in ltl' \
        contract 'features/503-yaml-aggregate-export.md D12 - the run summary table does not change'
    assert_line "$out" pattern 'LINES INCLUDED +5' \
        asserts 'The run summary keeps its LINES INCLUDED row' \
        produced_by 'print_summary_table() in ltl' \
        contract 'features/503-yaml-aggregate-export.md D12 - the run summary table does not change'
    assert_absent "$out" pattern 'LINES (EXCLUDED|UNMATCHED)' \
        asserts 'No excluded or unmatched row joins the run summary; the accounting lives on -V filter-summary and in the aggregate export' \
        produced_by 'print_summary_table() in ltl' \
        contract 'features/503-yaml-aggregate-export.md D12 - the summary stays exactly as it is'
fi

echo ""
echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do echo "  - $f"; done
    exit 1
fi
echo "ALL FILTER-SUMMARY TESTS PASSED"
