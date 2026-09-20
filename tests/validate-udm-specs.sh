#!/usr/bin/env bash
# validate-udm-specs.sh — Validate the udm-specs `-V` section and the
# user-defined-metric diagnostics it makes observable (Issues #443, #449):
# parse-time rejection of provable spec defects, the whole-match value when a
# regex has no capture group, the zero-match notice with its interpretation
# and its single intent hint, and the run-wide production derived from the
# bucket accumulators.
#
# Follows the self-documenting assertion design from tests/HARNESS-DESIGN.md
# (reference: tests/validate-histogram-bin-counters.sh). Every assertion
# records asserts / produced_by / contract and surfaces all three on failure.
#
# Fixture: tests/fixtures/udm-specs.txt — synthetic Tomcat access log, 4 lines
# in one day, hand-computed expectations:
#   3 lines carry /app/Download/<file> with 2 distinct files (report-a x2, report-b)
#   1 line carries rows=40 (a single match: no delta can be computed from it)
#   durations 12.345 15.221 8.004 9.500 -> sum 45.07 min 8.004 max 15.221
#   no line carries an "absent" field

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"
# Invocation shape (tests/HARNESS-DESIGN.md section Invocation coherence): the
# subject is per-spec interpretation and run-wide production, which is the
# same at any bucket size, so one bucket (-bs 1440) with -oe on a 4-line
# fixture; -du ms names the producer so the format's unit note stays out of
# the stderr being asserted.
FIXTURE="$REPO_DIR/tests/fixtures/udm-specs.txt"
# Colliding-name scenarios need a field that moves, which udm-specs.txt does not
# carry: its one rows= line cannot produce a delta at all. udm-collision.txt is
# 4 lines in one bucket with rows= 10, 30, 60, 100 and a second numeric field
# (pages=), so the hand-computed answers are raw 200 over 4 occurrences (10..100),
# delta 90 over 3 (20..40, the first occurrence seeding the state), and pages is
# a second extraction target for the same metric name.
COLLISION_FIXTURE="$REPO_DIR/tests/fixtures/udm-collision.txt"
# The user-defined metric that replaces the "N milliseconds" duration read the
# Integration Runtime and Connection Server formats no longer make: one
# synthetic file of each shape, five of eight lines carrying the value
# (152 48 3017 152 7 -> sum 3376 min 7 max 3017; the Connection Server file
# has 15000 in place of 7 -> sum 18369 min 48 max 15000).
MS_IR_FIXTURE="$REPO_DIR/tests/fixtures/format-detection/milliseconds-integration-runtime.txt"
MS_CS_FIXTURE="$REPO_DIR/tests/fixtures/format-detection/milliseconds-connection-server.txt"
MS_SPEC='elapsed:ms::/ (\d+) milliseconds/'

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"
neutralize_colour_env

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"
    exit 1
fi
for f in "$FIXTURE" "$COLLISION_FIXTURE" "$MS_IR_FIXTURE" "$MS_CS_FIXTURE"; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: fixture not found: $f"
        exit 1
    fi
done

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT


pass=0
fail=0
failures=()
current_scenario=""

CONTRACT='features/user-defined-metrics.md section Diagnostics and -V udm-specs (Issues #443, #449) - decisions D1-D12 locked 2026-08-28; section content stability-contracted per tests/HARNESS-DESIGN.md'
# Issue #482 (two -udm specs with the same name and aggregation but different
# transforms collapse into one column): specs differing in aggregation,
# transform or unit are separate metrics whose resolved names carry what
# differs within the colliding group; specs a name cannot tell apart are
# refused, and a repeated identical argument is dropped with a notice.
CONTRACT_482='features/user-defined-metrics.md section Colliding metric names become separate metrics (Issue #482) - decisions D1-D13; section content stability-contracted per tests/HARNESS-DESIGN.md'

# Run ltl with the given args against the fixture; stdout to the echoed file,
# stderr beside it as <capture>.stderr.
run_ltl() {
    local outfile
    outfile=$(mktemp "$TMP_DIR/out.XXXXXX")
    "$LTL" --disable-progress -ni -bs 1440 -oe -du ms -V udm-specs "$@" "$FIXTURE" > "$outfile" 2>"$outfile.stderr" || true
    echo "$outfile"
}

# Same shape against the collision fixture. The exit status is recorded rather
# than swallowed, because one scenario's subject is that the run no longer dies.
LAST_EXIT=0
run_collision() {
    local outfile
    outfile=$(mktemp "$TMP_DIR/out.XXXXXX")
    set +e
    "$LTL" --disable-progress -ni -bs 1440 -oe -V udm-specs "$@" "$COLLISION_FIXTURE" > "$outfile" 2>"$outfile.stderr"
    LAST_EXIT=$?
    set -e
    echo "$outfile"
}

check_capture_warnings() {
    if ! assert_no_runtime_warnings "$1.stderr" "$current_scenario"; then
        fail=$((fail + 1))
        failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
    fi
}

# Fixed-string line assertion (the section prints compiled patterns, which
# are full of regex metacharacters).
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

    if grep -qF -- "$pattern" "$outfile"; then
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

# Fixed-string absence assertion: the line must NOT appear.
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
    : "${pattern:?}" ; : "${asserts:?}" ; : "${produced_by:?}" ; : "${contract:?}"

    if grep -qF -- "$pattern" "$outfile"; then
        echo "  FAIL  $current_scenario"
        echo "        must be absent: $pattern"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
        failures+=("$current_scenario :: absent: $pattern")
    else
        echo "  PASS  $current_scenario :: absent: $pattern"
        pass=$((pass + 1))
    fi
}

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
    : "${command:?}" ; : "${label:?}" ; : "${asserts:?}" ; : "${produced_by:?}" ; : "${contract:?}"

    if eval "$command" > /dev/null 2>&1; then
        echo "  PASS  $current_scenario :: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        label:       $label"
        echo "        command:     $command"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
        failures+=("$current_scenario :: $label")
    fi
}

# Every scenario consuming the section asserts its brackets first, so a
# renamed section fails visibly rather than as zero matches elsewhere.
assert_section_present() {
    local outfile="$1"
    assert_line "$outfile" \
        pattern     '=== udm-specs ===' \
        asserts     'The udm-specs section is emitted whenever -V udm-specs is requested' \
        produced_by 'emit_udm_specs_verbose() in ltl' \
        contract    "$CONTRACT"
    assert_line "$outfile" \
        pattern     '=== END udm-specs ===' \
        asserts     'The udm-specs section is closed by its END marker' \
        produced_by 'emit_udm_specs_verbose() in ltl' \
        contract    "$CONTRACT"
}

# ---------------------------------------------------------------------------
# Scenario: undelimited-regex — the reported case. A regex written into the
# fourth field without slashes is a token key, matched literally; the run
# produces nothing for it, the notice says so, and the hint fires.
# ---------------------------------------------------------------------------
scenario_undelimited_regex() {
    current_scenario="undelimited-regex"
    echo "[$current_scenario]"
    local out
    out=$(run_ltl -udm 'unique_files::distinct:Download\/([^ ?]+)')
    check_capture_warnings "$out"
    assert_section_present "$out"

    assert_line "$out" \
        pattern     "udm: name=unique_files spec='unique_files::distinct:Download\\/([^ ?]+)'" \
        asserts     'The section names the metric and echoes the argument as given' \
        produced_by 'emit_udm_specs_verbose() in ltl' \
        contract    "$CONTRACT"
    assert_line "$out" \
        pattern     "  read_as: unit=none(raw)  aggregation=distinct  transform=none  extraction=token_key  key='Download\\/([^ ?]+)'  source=line" \
        asserts     'D1: an undelimited fourth field is read as a token key, never reinterpreted as a regex' \
        produced_by 'parse_udm_configs() (extraction) + udm_read_as() in ltl' \
        contract    "$CONTRACT"
    assert_line "$out" \
        pattern     '  produced: occurrences=0 buckets=0' \
        asserts     'D7: the literally-escaped key matched nothing, derived from the bucket accumulators' \
        produced_by 'derive_udm_production() in ltl' \
        contract    "$CONTRACT"
    assert_line "$out" \
        pattern     '  hint: token_key_has_regex_chars' \
        asserts     'D6: a token key carrying regex characters is flagged on the section' \
        produced_by 'parse_udm_configs() (hint) in ltl' \
        contract    "$CONTRACT"

    assert_line "$out.stderr" \
        pattern     "Note: -udm 'unique_files::distinct:Download\\/([^ ?]+)': no metrics produced from matching lines" \
        asserts     'D8: the zero-match notice is spoken for a metric whose derived occurrences are zero' \
        produced_by 'emit_udm_zero_match_notices() in ltl' \
        contract    "$CONTRACT"
    assert_line "$out.stderr" \
        pattern     '      read as: unit=none(raw)  aggregation=distinct  transform=none  extraction=token_key' \
        asserts     'D9: the notice shows the interpretation acted on, from the same config entry the section prints' \
        produced_by 'emit_udm_zero_match_notices() + udm_read_as() in ltl' \
        contract    "$CONTRACT"
    assert_line "$out.stderr" \
        pattern     "      hint: the token key 'Download\\/([^ ?]+)' contains regex characters and is matched literally - if you meant a regex, wrap it in slashes: /Download\\/([^ ?]+)/" \
        asserts     'D4(b)/D6: the intent hint is spoken inside the zero-match notice' \
        produced_by 'emit_udm_zero_match_notices() in ltl' \
        contract    "$CONTRACT"
    assert_absent "$out.stderr" \
        pattern     'Warning:' \
        asserts     'D4(b): the hint is never spoken at parse time - the spec is valid by the grammar' \
        produced_by 'parse_udm_configs() in ltl' \
        contract    "$CONTRACT"
    rm -f "$out" "$out.stderr"
}

# ---------------------------------------------------------------------------
# Scenario: whole-match — the same regex, delimited, with no capture group:
# the whole match is the value, distinct sees 2 files, and no notice fires.
# ---------------------------------------------------------------------------
scenario_whole_match() {
    current_scenario="whole-match"
    echo "[$current_scenario]"
    local out
    out=$(run_ltl -udm 'files::distinct:/Download\/[^ ?]+/')
    check_capture_warnings "$out"
    assert_section_present "$out"

    assert_line "$out" \
        pattern     "  read_as: unit=none(raw)  aggregation=distinct  transform=none  extraction=regex  key='-'  source=line" \
        asserts     'A slash-delimited fourth field is read as a regex' \
        produced_by 'parse_udm_configs() (extraction) + udm_read_as() in ltl' \
        contract    "$CONTRACT"
    assert_line "$out" \
        pattern     '  produced: occurrences=3 buckets=1 distinct_max=2' \
        asserts     'D2: without a capture group the whole match is the value - 3 Download lines, 2 distinct files' \
        produced_by 'read_and_process_logs() extraction site (whole match) + derive_udm_production() in ltl' \
        contract    "$CONTRACT"
    assert_absent "$out.stderr" \
        pattern     'Note: -udm' \
        asserts     'No zero-match notice for a metric that produced values' \
        produced_by 'emit_udm_zero_match_notices() in ltl' \
        contract    "$CONTRACT"
    assert_absent "$out" \
        pattern     '  hint:' \
        asserts     'No hint on a regex spec' \
        produced_by 'parse_udm_configs() (hint) in ltl' \
        contract    "$CONTRACT"
    rm -f "$out" "$out.stderr"
}

# ---------------------------------------------------------------------------
# Scenario: absent-field — a well-formed default-pattern metric whose field is
# simply not in the file: notice, no hint, both default patterns shown.
# ---------------------------------------------------------------------------
scenario_absent_field() {
    current_scenario="absent-field"
    echo "[$current_scenario]"
    local out
    out=$(run_ltl -udm 'absent')
    check_capture_warnings "$out"
    assert_section_present "$out"

    assert_line "$out" \
        pattern     "  read_as: unit=none(raw)  aggregation=sum  transform=none  extraction=name  key='absent'  source=line" \
        asserts     'With neither key nor regex the default patterns are built from the name' \
        produced_by 'parse_udm_configs() (extraction) + udm_read_as() in ltl' \
        contract    "$CONTRACT"
    assert_line "$out" \
        pattern     '  pattern[1]: ' \
        asserts     'A numeric default-pattern metric lists both compiled patterns' \
        produced_by 'emit_udm_specs_verbose() in ltl' \
        contract    "$CONTRACT"
    assert_line "$out" \
        pattern     '  produced: occurrences=0 buckets=0' \
        asserts     'The absent field produced nothing' \
        produced_by 'derive_udm_production() in ltl' \
        contract    "$CONTRACT"
    assert_line "$out.stderr" \
        pattern     "Note: -udm 'absent': no metrics produced from matching lines" \
        asserts     'D8: the notice fires for a genuinely absent field - information, not an error' \
        produced_by 'emit_udm_zero_match_notices() in ltl' \
        contract    "$CONTRACT"
    assert_absent "$out.stderr" \
        pattern     '      hint:' \
        asserts     'D4(c): no hint is offered when no rule fires - the field may simply not be in the file' \
        produced_by 'emit_udm_zero_match_notices() in ltl' \
        contract    "$CONTRACT"
    assert_absent "$out.stderr" \
        pattern     'Warning:' \
        asserts     'D3: an absent field is never a parse-time warning' \
        produced_by 'parse_udm_configs() in ltl' \
        contract    "$CONTRACT"
    rm -f "$out" "$out.stderr"
}

# ---------------------------------------------------------------------------
# Scenario: parse-time-rejections — the two D5 checks plus command-line
# ordering of rejected entries among accepted ones. The run continues (D3):
# the accepted metric before and after both produce.
# ---------------------------------------------------------------------------
scenario_parse_time_rejections() {
    current_scenario="parse-time-rejections"
    echo "[$current_scenario]"
    local out
    out=$(run_ltl -udm 'lat:ms:max:/HTTP\/1.1" \d+ \d+ ([\d.]+)/' \
                  -udm 'files:distinct:/Download\/[^ ?]+/' \
                  -udm 'x::distinct:/report/' \
                  -udm 'files::distinct:/Download\/[^ ?]+/')
    check_capture_warnings "$out"
    assert_section_present "$out"

    assert_line "$out.stderr" \
        pattern     "Warning: 'distinct' in the unit slot of -udm 'files:distinct:/Download\\/[^ ?]+/' is a function, not a unit - did you mean 'files::distinct:/Download\\/[^ ?]+/'? (leave the unit slot empty when there is no unit), skipping" \
        asserts     'D5(i): a function name in the unit slot is a provable defect, spoken at parse time with the corrected spec' \
        produced_by 'parse_udm_configs() (unit-slot check) in ltl' \
        contract    "$CONTRACT"
    assert_line "$out" \
        pattern     "udm: spec='files:distinct:/Download\\/[^ ?]+/' rejected=unit_slot_holds_function" \
        asserts     'A rejected spec is listed on the section with its reason token' \
        produced_by 'parse_udm_configs() (reject) + emit_udm_specs_verbose() in ltl' \
        contract    "$CONTRACT"
    assert_line "$out.stderr" \
        pattern     "Warning: the pattern /report/ in -udm 'x::distinct:/report/' is a fixed string, so 'distinct' can only ever be 1 - give it a capture group or a varying pattern, skipping" \
        asserts     'D5(ii): a fixed-string pattern under distinct is a provable defect, spoken at parse time' \
        produced_by 'parse_udm_configs() (literal-pattern check) in ltl' \
        contract    "$CONTRACT"
    assert_line "$out" \
        pattern     "udm: spec='x::distinct:/report/' rejected=literal_pattern_under_distinct" \
        asserts     'The fixed-string rejection carries its reason token' \
        produced_by 'parse_udm_configs() (reject) + emit_udm_specs_verbose() in ltl' \
        contract    "$CONTRACT"
    assert_line "$out" \
        pattern     '  produced: occurrences=4 buckets=1 sum=45.07 min=8.004 max=15.221' \
        asserts     'D3/D7: the run continues past rejections and the numeric fold matches the hand-computed durations (12.345+15.221+8.004+9.5)' \
        produced_by 'derive_udm_production() in ltl' \
        contract    "$CONTRACT"
    assert_line "$out" \
        pattern     '  produced: occurrences=3 buckets=1 distinct_max=2' \
        asserts     'D3: the accepted metric after the rejections still produces' \
        produced_by 'derive_udm_production() in ltl' \
        contract    "$CONTRACT"
    assert_command \
        command     "[ \"\$(grep -n '^udm: ' '$out' | grep -c .)\" = 4 ] && [ \"\$(grep '^udm: ' '$out' | sed -n 2p | grep -c 'rejected=unit_slot_holds_function')\" = 1 ] && [ \"\$(grep '^udm: ' '$out' | sed -n 3p | grep -c 'rejected=literal_pattern_under_distinct')\" = 1 ]" \
        label       'four entries in command-line order, rejected ones in place' \
        asserts     'The section lists every -udm argument, accepted or rejected, in the order given' \
        produced_by 'emit_udm_specs_verbose() (spec_index sort) in ltl' \
        contract    "$CONTRACT"
    assert_absent "$out" \
        pattern     ' files:distinct ' \
        asserts     'A rejected spec gets no column' \
        produced_by 'parse_udm_configs() (skip) in ltl' \
        contract    "$CONTRACT"
    rm -f "$out" "$out.stderr"
}

# ---------------------------------------------------------------------------
# Scenario: delta-single-match — rows=40 appears once; delta needs two, so
# the metric accumulates nothing and the one notice wording covers it (D8).
# ---------------------------------------------------------------------------
scenario_delta_single_match() {
    current_scenario="delta-single-match"
    echo "[$current_scenario]"
    local out
    out=$(run_ltl -udm 'rows::delta')
    check_capture_warnings "$out"
    assert_section_present "$out"

    assert_line "$out" \
        pattern     "  read_as: unit=none(raw)  aggregation=sum  transform=delta  extraction=name  key='rows'  source=line" \
        asserts     'delta is read as transform=delta with the default sum aggregation' \
        produced_by 'parse_udm_configs() + udm_read_as() in ltl' \
        contract    "$CONTRACT"
    assert_line "$out" \
        pattern     '  produced: occurrences=0 buckets=0' \
        asserts     'D7/D8: a single match under delta accumulates nothing and reads as zero' \
        produced_by 'derive_udm_production() in ltl' \
        contract    "$CONTRACT"
    assert_line "$out.stderr" \
        pattern     "Note: -udm 'rows::delta': no metrics produced from matching lines" \
        asserts     'D8: one wording for every case, including the delta edge' \
        produced_by 'emit_udm_zero_match_notices() in ltl' \
        contract    "$CONTRACT"
    assert_absent "$out.stderr" \
        pattern     '      hint:' \
        asserts     'No hint on a plain name spec' \
        produced_by 'emit_udm_zero_match_notices() in ltl' \
        contract    "$CONTRACT"
    rm -f "$out" "$out.stderr"
}

# ---------------------------------------------------------------------------
# Scenario: no-udm — the section is bracketed and empty when no -udm is given.
# ---------------------------------------------------------------------------
scenario_no_udm() {
    current_scenario="no-udm"
    echo "[$current_scenario]"
    local out
    out=$(run_ltl)
    check_capture_warnings "$out"
    assert_section_present "$out"
    assert_absent "$out" \
        pattern     'udm: ' \
        asserts     'No entries when no -udm was given' \
        produced_by 'emit_udm_specs_verbose() in ltl' \
        contract    "$CONTRACT"
    rm -f "$out" "$out.stderr"
}

# ---------------------------------------------------------------------------
# Scenario: collision-transform — the reported case. One name, one aggregation,
# different transforms: two metrics, two names, each carrying its own correct
# answer rather than a mixture of both.
# ---------------------------------------------------------------------------
scenario_collision_transform() {
    current_scenario="collision-transform"
    echo "[$current_scenario]"
    local out
    out=$(run_collision -udm rows -udm 'rows::delta')
    check_capture_warnings "$out"
    assert_section_present "$out"

    assert_line "$out" \
        pattern     "udm: name=rows:sum spec='rows'" \
        asserts     'D3: within a group differing in the function field, the spec that named no function shows the default sum' \
        produced_by 'resolve_udm_metric_names() in ltl' \
        contract    "$CONTRACT_482"
    assert_line "$out" \
        pattern     "udm: name=rows:delta spec='rows::delta'" \
        asserts     'D3: the transform spec is named by its function field in the shorthand spelling' \
        produced_by 'resolve_udm_metric_names() + udm_function_field() in ltl' \
        contract    "$CONTRACT_482"
    assert_line "$out" \
        pattern     '  produced: occurrences=4 buckets=1 sum=200 min=10 max=100' \
        asserts     'D1: the raw metric produces its own answer (10+30+60+100 over 4 lines), matching the single-spec control' \
        produced_by 'derive_udm_production() in ltl' \
        contract    "$CONTRACT_482"
    assert_line "$out" \
        pattern     '  produced: occurrences=3 buckets=1 sum=90 min=20 max=40' \
        asserts     'D1: the delta metric produces its own answer (20+30+40 over 3, the first line seeding the state)' \
        produced_by 'derive_udm_production() in ltl' \
        contract    "$CONTRACT_482"
    assert_absent "$out.stderr" \
        pattern     'Warning:' \
        asserts     'D1: specs a name can tell apart are separated silently, not refused' \
        produced_by 'parse_udm_configs() in ltl' \
        contract    "$CONTRACT_482"
    rm -f "$out" "$out.stderr"
}

# ---------------------------------------------------------------------------
# Scenario: collision-unit — the unit discriminates, and only the spec carrying
# one gains a suffix; the unitless metric keeps its bare name (D6).
# ---------------------------------------------------------------------------
scenario_collision_unit() {
    current_scenario="collision-unit"
    echo "[$current_scenario]"
    local out
    out=$(run_collision -udm rows -udm 'rows:s')
    check_capture_warnings "$out"
    assert_section_present "$out"

    assert_line "$out" \
        pattern     "udm: name=rows spec='rows'" \
        asserts     'D6: when only the unit differs, the spec without one keeps the name exactly as typed' \
        produced_by 'resolve_udm_metric_names() in ltl' \
        contract    "$CONTRACT_482"
    assert_line "$out" \
        pattern     "udm: name=rows:s spec='rows:s'" \
        asserts     'D6: the spec carrying a unit is named by that unit as typed' \
        produced_by 'resolve_udm_metric_names() in ltl' \
        contract    "$CONTRACT_482"
    assert_line "$out" \
        pattern     '  produced: occurrences=4 buckets=1 sum=200 min=10 max=100' \
        asserts     'D6: the unitless metric reports unconverted values, which were unobtainable before' \
        produced_by 'derive_udm_production() in ltl' \
        contract    "$CONTRACT_482"
    assert_line "$out" \
        pattern     '  produced: occurrences=4 buckets=1 sum=200000 min=10000 max=100000' \
        asserts     'D6: the second metric reports the same field converted from seconds to milliseconds' \
        produced_by 'derive_udm_production() in ltl' \
        contract    "$CONTRACT_482"
    rm -f "$out" "$out.stderr"
}

# ---------------------------------------------------------------------------
# Scenario: collision-three-way — a raw spec plus two transforms. The plain
# spec carries no transform and was zeroed by the shared delta state before.
# ---------------------------------------------------------------------------
scenario_collision_three_way() {
    current_scenario="collision-three-way"
    echo "[$current_scenario]"
    local out
    out=$(run_collision -udm rows -udm 'rows::delta' -udm 'rows::idelta')
    check_capture_warnings "$out"
    assert_section_present "$out"

    assert_line "$out" \
        pattern     "udm: name=rows:sum spec='rows'" \
        asserts     'Three specs on one base name resolve to three distinct names' \
        produced_by 'resolve_udm_metric_names() in ltl' \
        contract    "$CONTRACT_482"
    assert_line "$out" \
        pattern     "udm: name=rows:delta spec='rows::delta'" \
        asserts     'The clamped transform is named by its own function field' \
        produced_by 'resolve_udm_metric_names() in ltl' \
        contract    "$CONTRACT_482"
    assert_line "$out" \
        pattern     "udm: name=rows:idelta spec='rows::idelta'" \
        asserts     'The unclamped transform is named by its own function field' \
        produced_by 'resolve_udm_metric_names() in ltl' \
        contract    "$CONTRACT_482"
    assert_line "$out" \
        pattern     '  produced: occurrences=4 buckets=1 sum=200 min=10 max=100' \
        asserts     'D1: the well-formed plain spec reports its own total, not the zero the shared delta state produced' \
        produced_by 'derive_udm_production() in ltl' \
        contract    "$CONTRACT_482"
    assert_absent "$out" \
        pattern     '  produced: occurrences=12' \
        asserts     'D1: no metric counts the per-line value once per colliding config' \
        produced_by 'derive_udm_production() in ltl' \
        contract    "$CONTRACT_482"
    assert_command \
        command     "[ \"\$(grep -c '  produced: occurrences=3 buckets=1 sum=90 min=20 max=40' '$out')\" = 2 ]" \
        label       'both transform metrics report the single-spec answer, neither zero' \
        asserts     'D1: separate delta state per metric, so each transform computes against its own previous value' \
        produced_by 'derive_udm_production() in ltl' \
        contract    "$CONTRACT_482"
    rm -f "$out" "$out.stderr"
}

# ---------------------------------------------------------------------------
# Scenario: collision-two-transforms — two transforms and no raw spec; both
# reported a fabricated zero before.
# ---------------------------------------------------------------------------
scenario_collision_two_transforms() {
    current_scenario="collision-two-transforms"
    echo "[$current_scenario]"
    local out
    out=$(run_collision -udm 'rows::delta' -udm 'rows::idelta')
    check_capture_warnings "$out"
    assert_section_present "$out"

    assert_line "$out" \
        pattern     "udm: name=rows:delta spec='rows::delta'" \
        asserts     'Two transforms on one name resolve to two distinct names' \
        produced_by 'resolve_udm_metric_names() in ltl' \
        contract    "$CONTRACT_482"
    assert_line "$out" \
        pattern     "udm: name=rows:idelta spec='rows::idelta'" \
        asserts     'Two transforms on one name resolve to two distinct names' \
        produced_by 'resolve_udm_metric_names() in ltl' \
        contract    "$CONTRACT_482"
    assert_command \
        command     "[ \"\$(grep -c '  produced: occurrences=3 buckets=1 sum=90 min=20 max=40' '$out')\" = 2 ]" \
        label       'both metrics report their single-spec control answer' \
        asserts     'D1: neither metric reports the zero the shared delta state fabricated' \
        produced_by 'derive_udm_production() in ltl' \
        contract    "$CONTRACT_482"
    rm -f "$out" "$out.stderr"
}

# ---------------------------------------------------------------------------
# Scenario: collision-refused — specs differing only in what they extract have
# no readable name to tell them apart, so the later one is refused (D4).
# ---------------------------------------------------------------------------
scenario_collision_refused() {
    current_scenario="collision-refused"
    echo "[$current_scenario]"
    local out
    out=$(run_collision -udm rows -udm 'rows:/(\d+) rows/')
    check_capture_warnings "$out"
    assert_section_present "$out"

    assert_line "$out.stderr" \
        pattern     "Warning: -udm 'rows:/(\\d+) rows/' and -udm 'rows' both resolve to the metric name 'rows' - give them different names, skipping the later one" \
        asserts     'D4: the refusal names both specs and the name they contend for, and says what to change' \
        produced_by 'parse_udm_configs() (identity refusal) in ltl' \
        contract    "$CONTRACT_482"
    assert_line "$out" \
        pattern     "udm: spec='rows:/(\\d+) rows/' rejected=duplicate_metric_identity" \
        asserts     'D4: the refused spec is listed on the section with its reason token' \
        produced_by 'parse_udm_configs() (reject) + emit_udm_specs_verbose() in ltl' \
        contract    "$CONTRACT_482"
    assert_line "$out" \
        pattern     "udm: name=rows spec='rows'" \
        asserts     'D4: the earlier spec keeps the name and the run continues' \
        produced_by 'resolve_udm_metric_names() in ltl' \
        contract    "$CONTRACT_482"
    assert_line "$out" \
        pattern     '  produced: occurrences=4 buckets=1 sum=200 min=10 max=100' \
        asserts     'D4: the surviving metric produces its own correct answer' \
        produced_by 'derive_udm_production() in ltl' \
        contract    "$CONTRACT_482"
    rm -f "$out" "$out.stderr"
}

# ---------------------------------------------------------------------------
# Scenario: collision-identical — a repeated identical argument is one metric,
# the repeat dropped with a notice (D5). This pair exited 255 before.
# ---------------------------------------------------------------------------
scenario_collision_identical() {
    current_scenario="collision-identical"
    echo "[$current_scenario]"
    local out
    out=$(run_collision -udm 'rows::ratio' -udm 'rows::ratio')
    check_capture_warnings "$out"
    assert_section_present "$out"

    assert_line "$out.stderr" \
        pattern     "Note: -udm 'rows::ratio' was given more than once - keeping one metric, dropping the repeat" \
        asserts     'D5: the drop is a behavioural notice, always spoken so a typo is not hidden' \
        produced_by 'parse_udm_configs() (duplicate-argument drop) in ltl' \
        contract    "$CONTRACT_482"
    assert_line "$out" \
        pattern     "udm: spec='rows::ratio' rejected=duplicate_metric_identity" \
        asserts     'D5: the dropped repeat is listed on the section with its reason token' \
        produced_by 'parse_udm_configs() (reject) + emit_udm_specs_verbose() in ltl' \
        contract    "$CONTRACT_482"
    assert_command \
        command     "[ \"\$(grep -c '^udm: name=' '$out')\" = 1 ]" \
        label       'exactly one metric survives two identical arguments' \
        asserts     'D5: identical arguments can name only one metric' \
        produced_by 'parse_udm_configs() (duplicate-argument drop) in ltl' \
        contract    "$CONTRACT_482"
    assert_command \
        command     "[ '$LAST_EXIT' = 0 ]" \
        label       'the run exits 0 where it previously died with a division by zero' \
        asserts     'D7: the duplicate drop removes the second config that read an already-freed distinct set' \
        produced_by 'parse_udm_configs() (duplicate-argument drop) + calculate_all_statistics() in ltl' \
        contract    "$CONTRACT_482"
    assert_command \
        command     "grep -q 'TOP OVERALL MESSAGES' '$out'" \
        label       'the run renders its output rather than producing none' \
        asserts     'D7: exiting 0 is not enough - the run must produce the report it was asked for' \
        produced_by 'print_message_summary() in ltl' \
        contract    "$CONTRACT_482"
    rm -f "$out" "$out.stderr"
}

# ---------------------------------------------------------------------------
# Scenario: collision-safe-boundary — the same-name pairs that worked before
# keep their names and their figures (D10). Regression guard for #99 (same UDM
# name with different aggregation functions showed duplicate values).
# ---------------------------------------------------------------------------
scenario_collision_safe_boundary() {
    current_scenario="collision-safe-boundary"
    echo "[$current_scenario]"
    local out
    out=$(run_collision -udm 'rows::sum' -udm 'rows::max')
    check_capture_warnings "$out"
    assert_section_present "$out"

    assert_line "$out" \
        pattern     "udm: name=rows:sum spec='rows::sum'" \
        asserts     'D10: an aggregation-only pair resolves exactly as it did before this change' \
        produced_by 'resolve_udm_metric_names() in ltl' \
        contract    "$CONTRACT_482"
    assert_line "$out" \
        pattern     "udm: name=rows:max spec='rows::max'" \
        asserts     'D10: an aggregation-only pair resolves exactly as it did before this change' \
        produced_by 'resolve_udm_metric_names() in ltl' \
        contract    "$CONTRACT_482"
    assert_command \
        command     "[ \"\$(grep -c '  produced: occurrences=4 buckets=1 sum=200 min=10 max=100' '$out')\" = 2 ]" \
        label       'both metrics see all four occurrences, as the single-spec run reports' \
        asserts     'D10: separating on the function field does not change what an aggregation-only pair accumulates' \
        produced_by 'derive_udm_production() in ltl' \
        contract    "$CONTRACT_482"
    rm -f "$out" "$out.stderr"

    out=$(run_collision -udm 'rows::count' -udm 'rows::distinct')
    check_capture_warnings "$out"
    assert_line "$out" \
        pattern     "udm: name=rows:count spec='rows::count'" \
        asserts     'D10: a counting pair resolves exactly as it did before this change' \
        produced_by 'resolve_udm_metric_names() in ltl' \
        contract    "$CONTRACT_482"
    assert_line "$out" \
        pattern     "udm: name=rows:distinct spec='rows::distinct'" \
        asserts     'D10: a counting pair resolves exactly as it did before this change' \
        produced_by 'resolve_udm_metric_names() in ltl' \
        contract    "$CONTRACT_482"
    assert_command \
        command     "[ \"\$(grep -c '  produced: occurrences=4 buckets=1 distinct_max=4' '$out')\" = 2 ]" \
        label       'both counting metrics see four occurrences over four distinct values' \
        asserts     'D10: the counting pair keeps its per-bucket distinct sets, which the freed-set defect emptied' \
        produced_by 'derive_udm_production() in ltl' \
        contract    "$CONTRACT_482"
    rm -f "$out" "$out.stderr"
}

# ---------------------------------------------------------------------------
# Scenario: no-collision-names-as-typed — a command line with no shared base
# name is untouched by the rule: every name is exactly what the user wrote.
# ---------------------------------------------------------------------------
scenario_no_collision_names_as_typed() {
    current_scenario="no-collision-names-as-typed"
    echo "[$current_scenario]"
    local out
    out=$(run_collision -udm rows -udm 'pages::max')
    check_capture_warnings "$out"
    assert_section_present "$out"

    assert_line "$out" \
        pattern     "udm: name=rows spec='rows'" \
        asserts     'D3: a base name no other spec uses keeps the name as typed, with no suffix' \
        produced_by 'resolve_udm_metric_names() in ltl' \
        contract    "$CONTRACT_482"
    assert_line "$out" \
        pattern     "udm: name=pages spec='pages::max'" \
        asserts     'D3: a named function adds no suffix when nothing collides with it' \
        produced_by 'resolve_udm_metric_names() in ltl' \
        contract    "$CONTRACT_482"
    assert_absent "$out.stderr" \
        pattern     'Note: -udm' \
        asserts     'Distinct names produce neither a refusal nor a duplicate-drop notice' \
        produced_by 'parse_udm_configs() in ltl' \
        contract    "$CONTRACT_482"
    rm -f "$out" "$out.stderr"
}

# ---------------------------------------------------------------------------
# Scenario: delta-shorthand-canonical — 'delta' and 'sum(delta)' are the same
# spec, so a resolved name must not depend on which the user wrote.
# ---------------------------------------------------------------------------
scenario_delta_shorthand_canonical() {
    current_scenario="delta-shorthand-canonical"
    echo "[$current_scenario]"
    local shorthand expanded
    shorthand=$(run_collision -udm 'rows::delta' -udm 'rows::max')
    check_capture_warnings "$shorthand"
    expanded=$(run_collision -udm 'rows::sum(delta)' -udm 'rows::max')
    check_capture_warnings "$expanded"
    assert_section_present "$expanded"

    assert_line "$expanded" \
        pattern     "udm: name=rows:delta spec='rows::sum(delta)'" \
        asserts     'The shorthand is the canonical spelling: sum(delta) is named delta, so the name never depends on how it was typed' \
        produced_by 'udm_function_field() in ltl' \
        contract    "$CONTRACT_482"
    assert_command \
        command     "[ \"\$(grep '^udm: name=' '$shorthand' | sed 's/ spec=.*//')\" = \"\$(grep '^udm: name=' '$expanded' | sed 's/ spec=.*//')\" ]" \
        label       'both spellings resolve to the same pair of names' \
        asserts     'Two spellings of one spec produce one naming outcome' \
        produced_by 'resolve_udm_metric_names() + udm_function_field() in ltl' \
        contract    "$CONTRACT_482"
    rm -f "$shorthand" "$shorthand.stderr" "$expanded" "$expanded.stderr"
}

# ---------------------------------------------------------------------------
# Scenario: collision-csv-and-export — the written surfaces. Every UDM column
# appears once on the timeline header and in the STATS CSV, and the aggregate
# export carries one entry per metric rather than losing one to a shared key.
# ---------------------------------------------------------------------------
scenario_collision_csv_and_export() {
    current_scenario="collision-csv-and-export"
    echo "[$current_scenario]"
    local work="$TMP_DIR/csv" render
    mkdir -p "$work"
    render="$TMP_DIR/render.out"
    ( cd "$work" && "$LTL" --disable-progress -ni -bs 1440 -oe --terminal-width 200 -o \
        -udm rows -udm 'rows::delta' -udm 'rows::idelta' "$COLLISION_FIXTURE" ) \
        > "$render" 2>"$render.stderr" || true
    current_scenario="collision-csv-and-export"
    if ! assert_no_runtime_warnings "$render.stderr" "$current_scenario"; then
        fail=$((fail + 1))
        failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
    fi

    local stats
    stats=$(ls "$work"/*STATS*.csv 2>/dev/null | head -1)
    assert_command \
        command     "[ -n '$stats' ] && [ -f '$stats' ]" \
        label       'the STATS CSV was written' \
        asserts     'The written surfaces are exercised, not only the rendered one' \
        produced_by 'print_bar_graph() in ltl' \
        contract    "$CONTRACT_482"
    assert_command \
        command     "head -1 '$stats' | tr ',' '\\n' | grep -c '^rows:sum\$' | grep -qx 1" \
        label       'the STATS CSV header carries rows:sum exactly once' \
        asserts     'D8: the disambiguated CSV column is the resolved name verbatim, and it is unique' \
        produced_by 'udm_csv_columns() + normalize_data_for_output() in ltl' \
        contract    "$CONTRACT_482"
    assert_command \
        command     "head -1 '$stats' | tr ',' '\\n' | grep -c '^rows:delta\$' | grep -qx 1" \
        label       'the STATS CSV header carries rows:delta exactly once' \
        asserts     'D8: each separated metric gets its own CSV column' \
        produced_by 'udm_csv_columns() + normalize_data_for_output() in ltl' \
        contract    "$CONTRACT_482"
    assert_command \
        command     "head -1 '$stats' | tr ',' '\\n' | grep -c '^rows:idelta\$' | grep -qx 1" \
        label       'the STATS CSV header carries rows:idelta exactly once' \
        asserts     'D8: each separated metric gets its own CSV column' \
        produced_by 'udm_csv_columns() + normalize_data_for_output() in ltl' \
        contract    "$CONTRACT_482"
    assert_command \
        command     "[ \"\$(head -1 '$stats' | tr ',' '\\n' | grep -c '^rows')\" = \"\$(head -1 '$stats' | tr ',' '\\n' | grep '^rows' | sort -u | grep -c .)\" ]" \
        label       'no UDM column name repeats in the STATS CSV header' \
        asserts     'D12: resolved-name uniqueness makes column ids unique by construction' \
        produced_by 'udm_csv_columns() + normalize_data_for_output() in ltl' \
        contract    "$CONTRACT_482"
    assert_command \
        command     "[ \"\$(head -2 '$stats' | tail -1 | tr ',' '\\n' | grep -c .)\" -le \"\$(head -1 '$stats' | tr ',' '\\n' | grep -c .)\" ]" \
        label       'the STATS CSV data row fits its header' \
        asserts     'One resolution sub means the header and the row beneath it cannot disagree about shape' \
        produced_by 'udm_csv_columns() in ltl' \
        contract    "$CONTRACT_482"

    local yaml
    yaml=$(ls "$work"/*AGGREGATE*.yaml 2>/dev/null | head -1)
    assert_command \
        command     "[ -n '$yaml' ] && [ -f '$yaml' ]" \
        label       'the YAML aggregate export was written' \
        asserts     'The export is the one surface that lost a metric to a shared key' \
        produced_by 'write_aggregate_export() in ltl' \
        contract    "$CONTRACT_482"
    assert_command \
        command     "grep -q 'rows:sum:' '$yaml' && grep -q 'rows:delta:' '$yaml' && grep -q 'rows:idelta:' '$yaml'" \
        label       'the export carries one entry per separated metric' \
        asserts     'D1: the name-keyed export no longer overwrites one metric with another' \
        produced_by 'write_aggregate_export() in ltl' \
        contract    "$CONTRACT_482"

    assert_command \
        command     "[ \"\$(grep -o 'rows:sum' '$render' | grep -c .)\" -ge 1 ] && [ \"\$(head -40 '$render' | grep -o 'rows:delta' | grep -c .)\" -ge 1 ]" \
        label       'the rendered timeline header names each separated metric' \
        asserts     'D12: each metric gets its own column on the rendered surface' \
        produced_by 'add_dynamic_column() + print_bar_graph() in ltl' \
        contract    "$CONTRACT_482"
    rm -rf "$work" "$render" "$render.stderr"
}

# ---------------------------------------------------------------------------
# Scenario: collision-operands — the -hg and -hm operand surfaces bind without
# ambiguity, and the unknown-metric error lists no name twice.
# ---------------------------------------------------------------------------
scenario_collision_operands() {
    current_scenario="collision-operands"
    echo "[$current_scenario]"
    local hg control unknown
    hg="$TMP_DIR/hg.out"
    "$LTL" --disable-progress -ni -bs 1440 -oe --terminal-width 200 -hg rows \
        -udm rows -udm 'rows::delta' "$COLLISION_FIXTURE" > "$hg" 2>"$hg.stderr" || true
    if ! assert_no_runtime_warnings "$hg.stderr" "$current_scenario"; then
        fail=$((fail + 1))
        failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
    fi
    control="$TMP_DIR/hg-control.out"
    "$LTL" --disable-progress -ni -bs 1440 -oe --terminal-width 200 -hg rows \
        -udm rows "$COLLISION_FIXTURE" > "$control" 2>/dev/null || true

    assert_command \
        command     "grep -q 'rows:sum Distribution' '$hg' && grep -q 'rows:delta Distribution' '$hg'" \
        label       'two distribution panels render, titled by their resolved names' \
        asserts     'A base name shared by two specs resolves to both panels rather than one merged panel' \
        produced_by 'resolve_metric_operand() + print_histograms() in ltl' \
        contract    "$CONTRACT_482"
    assert_command \
        command     "[ \"\$(sed 's/\\x1b\\[[0-9;]*m//g' '$hg' | grep -o 'P50: 30   P99: 100' | grep -c .)\" -ge 1 ] && [ \"\$(sed 's/\\x1b\\[[0-9;]*m//g' '$control' | grep -o 'P50: 30' | grep -c .)\" -ge 1 ]" \
        label       'the raw panel percentiles match the single-spec control' \
        asserts     'The separated metric distributes its own values, not a mixture of both specs' \
        produced_by 'print_histograms() in ltl' \
        contract    "$CONTRACT_482"

    unknown="$TMP_DIR/unknown.out"
    "$LTL" --disable-progress -ni -bs 1440 -oe -hm nosuchmetric \
        -udm rows -udm 'rows::delta' "$COLLISION_FIXTURE" > "$unknown" 2>"$unknown.stderr" || true
    assert_command \
        command     "cat '$unknown' '$unknown.stderr' | grep 'Available:' | grep -q 'rows:sum, rows:delta'" \
        label       'the unknown-metric error lists both resolved names' \
        asserts     'available_metric_names() reports the separated metrics under their resolved names' \
        produced_by 'available_metric_names() in ltl' \
        contract    "$CONTRACT_482"
    assert_command \
        command     "[ \"\$(cat '$unknown' '$unknown.stderr' | grep 'Available:' | sed 's/.*Available: //' | tr ',' '\\n' | sed 's/ //g' | grep -c .)\" = \"\$(cat '$unknown' '$unknown.stderr' | grep 'Available:' | sed 's/.*Available: //' | tr ',' '\\n' | sed 's/ //g' | sort -u | grep -c .)\" ]" \
        label       'the Available list contains no repeated name' \
        asserts     'Resolved names are unique, so the operand list no longer shows one name twice' \
        produced_by 'available_metric_names() in ltl' \
        contract    "$CONTRACT_482"
    rm -f "$hg" "$hg.stderr" "$control" "$unknown" "$unknown.stderr"
}

# ---------------------------------------------------------------------------
# Scenario: collision-columnar — the -ucm CSV columnar path is a second
# extraction route into the same structures, so it is asserted, not assumed.
# ---------------------------------------------------------------------------
scenario_collision_columnar() {
    current_scenario="collision-columnar"
    echo "[$current_scenario]"
    local columnar="$TMP_DIR/columnar.txt" out
    cat > "$columnar" <<'COLUMNAR'
timestamp,job,rows
2026-01-26 10:00:01,alpha,10
2026-01-26 10:00:05,alpha,30
2026-01-26 10:00:12,beta,60
2026-01-26 10:00:20,beta,100
COLUMNAR

    out="$TMP_DIR/columnar.out"
    "$LTL" --disable-progress -ni -bs 1440 -oe -V udm-specs -ucm job \
        -udm rows -udm 'rows::delta' "$columnar" > "$out" 2>"$out.stderr" || true
    if ! assert_no_runtime_warnings "$out.stderr" "$current_scenario"; then
        fail=$((fail + 1))
        failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
    fi
    assert_section_present "$out"
    assert_line "$out" \
        pattern     "udm: name=rows:sum spec='rows'" \
        asserts     'The columnar path resolves names through the same rule as the line-oriented path' \
        produced_by 'resolve_udm_metric_names() in ltl' \
        contract    "$CONTRACT_482"
    assert_line "$out" \
        pattern     '  produced: occurrences=4 buckets=1 sum=200 min=10 max=100' \
        asserts     'The columnar raw metric produces its own answer, as it does on a line-oriented log' \
        produced_by 'derive_udm_production() in ltl' \
        contract    "$CONTRACT_482"
    assert_line "$out" \
        pattern     '  produced: occurrences=3 buckets=1 sum=90 min=20 max=40' \
        asserts     'The columnar delta metric produces its own answer, as it does on a line-oriented log' \
        produced_by 'derive_udm_production() in ltl' \
        contract    "$CONTRACT_482"
    rm -f "$out" "$out.stderr"

    out="$TMP_DIR/columnar-ratio.out"
    set +e
    "$LTL" --disable-progress -ni -bs 1440 -oe -ucm job \
        -udm 'rows::ratio' -udm 'rows::ratio' "$columnar" > "$out" 2>"$out.stderr"
    local ratio_exit=$?
    set -e
    assert_command \
        command     "[ '$ratio_exit' = 0 ]" \
        label       'two identical ratio specs exit 0 on the columnar path too' \
        asserts     'D5/D7: the duplicate drop stops the division by zero on both extraction paths' \
        produced_by 'parse_udm_configs() (duplicate-argument drop) in ltl' \
        contract    "$CONTRACT_482"
    rm -f "$out" "$out.stderr" "$columnar"
}

# ---------------------------------------------------------------------------
# Scenario: milliseconds-replacement — the user-defined metric that replaces
# the "N milliseconds" duration read the Integration Runtime and Connection
# Server formats no longer make produces every value on both line shapes.
# ---------------------------------------------------------------------------
scenario_milliseconds_replacement() {
    current_scenario="milliseconds-replacement"
    echo "[$current_scenario]"
    local fixture expected out ec
    for fixture in "$MS_IR_FIXTURE" "$MS_CS_FIXTURE"; do
        if [[ "$fixture" == "$MS_IR_FIXTURE" ]]; then
            expected='  produced: occurrences=5 buckets=1 sum=3376 min=7 max=3017'
        else
            expected='  produced: occurrences=5 buckets=1 sum=18369 min=48 max=15000'
        fi
        out="$TMP_DIR/milliseconds-$(basename "$fixture" .txt).out"
        set +e
        "$LTL" --disable-progress -ni -bs 1440 -oe -V udm-specs -udm "$MS_SPEC" "$fixture" > "$out" 2>"$out.stderr"
        ec=$?
        set -e
        check_capture_warnings "$out"
        assert_command \
            command     "[ '$ec' = 0 ]" \
            label       "ltl exits 0 on $(basename "$fixture")" \
            asserts     'The replacement metric runs cleanly on the fixture' \
            produced_by 'parse_udm_configs() and read_and_process_logs() in ltl' \
            contract    'features/566-preserve-named-values-in-message.md section #576 acceptance criterion 5'
        assert_section_present "$out"
        assert_line "$out" \
            pattern     "$expected" \
            asserts     "The metric reads every \"N milliseconds\" value on $(basename "$fixture"): five occurrences with the hand-computed sum, min and max" \
            produced_by 'derive_udm_production() in ltl' \
            contract    'features/566-preserve-named-values-in-message.md section #576 acceptance criterion 5'
        rm -f "$out" "$out.stderr"
    done
}

scenario_register milliseconds-replacement \
                  undelimited-regex \
                  whole-match \
                  absent-field \
                  parse-time-rejections \
                  delta-single-match \
                  no-udm \
                  collision-transform \
                  collision-unit \
                  collision-three-way \
                  collision-two-transforms \
                  collision-refused \
                  collision-identical \
                  collision-safe-boundary \
                  no-collision-names-as-typed \
                  delta-shorthand-canonical \
                  collision-csv-and-export \
                  collision-operands \
                  collision-columnar
scenario_parse_args "$@"

while read -r _scenario; do
    case "$_scenario" in
        milliseconds-replacement   ) scenario_milliseconds_replacement ;;
        undelimited-regex          ) scenario_undelimited_regex ;;
        whole-match                ) scenario_whole_match ;;
        absent-field               ) scenario_absent_field ;;
        parse-time-rejections      ) scenario_parse_time_rejections ;;
        delta-single-match         ) scenario_delta_single_match ;;
        no-udm                     ) scenario_no_udm ;;
        collision-transform        ) scenario_collision_transform ;;
        collision-unit             ) scenario_collision_unit ;;
        collision-three-way        ) scenario_collision_three_way ;;
        collision-two-transforms   ) scenario_collision_two_transforms ;;
        collision-refused          ) scenario_collision_refused ;;
        collision-identical        ) scenario_collision_identical ;;
        collision-safe-boundary    ) scenario_collision_safe_boundary ;;
        no-collision-names-as-typed) scenario_no_collision_names_as_typed ;;
        delta-shorthand-canonical  ) scenario_delta_shorthand_canonical ;;
        collision-csv-and-export   ) scenario_collision_csv_and_export ;;
        collision-operands         ) scenario_collision_operands ;;
        collision-columnar         ) scenario_collision_columnar ;;
    esac
done < <(scenario_selected)


echo
echo "Results: $pass passed, $fail failed"
if [[ $fail -gt 0 ]]; then
    echo "Failed assertions:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
exit 0
