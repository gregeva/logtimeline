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

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
neutralize_colour_env

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"
    exit 1
fi
if [[ ! -f "$FIXTURE" ]]; then
    echo "ERROR: fixture not found: $FIXTURE"
    exit 1
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

pass=0
fail=0
failures=()
current_scenario=""

CONTRACT='features/user-defined-metrics.md section Diagnostics and -V udm-specs (Issues #443, #449) - decisions D1-D12 locked 2026-08-28; section content stability-contracted per tests/HARNESS-DESIGN.md'

# Run ltl with the given args against the fixture; stdout to the echoed file,
# stderr beside it as <capture>.stderr.
run_ltl() {
    local outfile
    outfile=$(mktemp "$TMP_DIR/out.XXXXXX")
    "$LTL" --disable-progress -ni -bs 1440 -oe -du ms -V udm-specs "$@" "$FIXTURE" > "$outfile" 2>"$outfile.stderr" || true
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

scenario_undelimited_regex
scenario_whole_match
scenario_absent_field
scenario_parse_time_rejections
scenario_delta_single_match
scenario_no_udm

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
