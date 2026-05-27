#!/usr/bin/env bash
# validate-format-detection.sh — Validate the `format-detection` `-V`
# section emits the locked slug + match_type per fixture log.
# Usage: ./tests/validate-format-detection.sh
#
# Asserts ltl's log-format auto-detection cascade against representative
# fixtures already committed under logs/. Each scenario invokes ltl with
# -V format-detection on a specific log, parses the resulting section,
# and asserts the expected slug, match_type, and matched_lines.
#
# Scope: 7 of 14 slugs have committed fixtures. The remaining 7 slugs
# (thingworx_rac_client, connection_server_json, java_gc_log,
# tw_analytics_v2, tw_analytics_worker, jboss_access, connection_server_standard,
# tomcat_access_common) are out of scope until fixtures exist or until
# the format-registry rewrite (#23) lands.
#
# Implements the self-documenting-assertion design from
# tests/HARNESS-DESIGN.md. Reference: tests/validate-histogram-bin-counters.sh.
#
# Sub-task of issue #225. Issue #228.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"

# Temp dir for captured outputs; cleaned up on EXIT per HARNESS-DESIGN.md Trap 10.
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"
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

# Helper: run ltl -V format-detection against $1 (log path), forward
# any extra args ($2..) before the log. Output captured to a temp file
# whose path is echoed for the caller.
#
# HARNESS-DESIGN.md Trap 1: preserve stderr, check exit code.
run_format_detection() {
    local log="$1"
    shift
    local outfile
    outfile="$TMP_DIR/$(basename "$log" | tr -c 'A-Za-z0-9._-' '_').out"
    set +e
    "$LTL" --disable-progress -V format-detection "$@" "$log" > "$outfile" 2>"$outfile.stderr"
    local ec=$?
    set -e
    if [[ "$ec" -ne 0 ]]; then
        echo "FAIL: ltl exited $ec for $log; stderr:" >&2
        sed 's/^/    /' "$outfile.stderr" >&2
        exit 1
    fi
    if [[ ! -s "$outfile" ]]; then
        echo "FAIL: empty capture for $log" >&2
        exit 1
    fi
    # HARNESS-DESIGN.md Trap 3: confirm section header present before
    # returning the file path. A missing header is a hard fail visible
    # at each scenario's first assertion.
    if ! grep -qE '^=== format-detection ===$' "$outfile"; then
        echo "FAIL: format-detection section header not found in capture for $log" >&2
        echo "       capture: $outfile" >&2
        exit 1
    fi
    echo "$outfile"
}

# ---------- Scenarios -----------------------------------------------------

scenario_tomcat9_ms() {
    current_scenario="tomcat9-ms"
    echo "[$current_scenario]"

    local log="$REPO_DIR/logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt"
    local out
    out=$(run_format_detection "$log")

    assert_line "$out" \
        pattern     '^  format: tomcat_access_with_duration$' \
        asserts     'Tomcat 9 access log with %D millisecond duration binds to slug `tomcat_access_with_duration`. Detection regex: ltl:4907 (match_type 3).' \
        produced_by 'emit_format_detection_verbose() in ltl' \
        contract    '%match_type_to_slug in ltl GLOBALS - slug names are locked; renames are breaking under HARNESS-DESIGN.md section Stability contract'

    assert_line "$out" \
        pattern     '^  match_type: 3$' \
        asserts     'Tomcat 9 access log binds to internal match_type 3' \
        produced_by 'emit_format_detection_verbose() in ltl (per-file match_type field)' \
        contract    'features/225-test-harness-coverage-gaps.md section #228 - match_type integers are an implementation detail surfaced for diagnostic value; the slug is the user-facing contract'

    assert_line "$out" \
        pattern     '^  matched_lines: 5000$' \
        asserts     '5k-line Tomcat 9 fixture parses every line as match_type 3 (no fallthroughs)' \
        produced_by 'emit_format_detection_verbose() in ltl (per-file matched_lines field)' \
        contract    'Fixture is hand-truncated to exactly 5000 lines; if the fixture changes, the expected count must change in the same commit'
}

scenario_apache_httpd_us() {
    current_scenario="apache-httpd-us"
    echo "[$current_scenario]"

    local log="$REPO_DIR/logs/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log"
    local out
    # Run with -du us per the documented workaround. Apache HTTP %D is
    # microseconds; without -du us, durations are 1000x off.
    out=$(run_format_detection "$log" -du us)

    assert_line "$out" \
        pattern     '^  format: tomcat_access_with_duration$' \
        asserts     'Apache HTTP Server 2.x access log binds to slug `tomcat_access_with_duration` - same regex as Tomcat 9, currently misclassified pending format-registry rewrite (#23)' \
        produced_by 'emit_format_detection_verbose() in ltl' \
        contract    'features/225-test-harness-coverage-gaps.md section #228 + ltl GLOBALS comment on Apache misclassification - when #23 splits the formats, this scenario must be updated to expect the new Apache-specific slug'

    assert_line "$out" \
        pattern     '^duration_unit_override: us$' \
        asserts     'When `-du us` is given, the format-detection section reports the override value' \
        produced_by 'emit_format_detection_verbose() in ltl (run-level duration_unit_override field)' \
        contract    '%match_type_to_slug and emit_format_detection_verbose() in ltl - duration_unit_override is locked field reporting the user-supplied -du value'
}

scenario_codebeamer() {
    current_scenario="codebeamer"
    echo "[$current_scenario]"

    local log="$REPO_DIR/logs/Codebeamber/codebeamer_access_log.2025-10-29.txt"
    local out
    out=$(run_format_detection "$log")

    assert_line "$out" \
        pattern     '^  format: tomcat_codebeamer$' \
        asserts     'Codebeamer access log with `[Nms] [Ns]` duration fields binds to slug `tomcat_codebeamer`. Detection regex: ltl:4892 (match_type 12).' \
        produced_by 'emit_format_detection_verbose() in ltl' \
        contract    '%match_type_to_slug in ltl GLOBALS - slug names are locked; renames are breaking under HARNESS-DESIGN.md section Stability contract'

    assert_line "$out" \
        pattern     '^  match_type: 12$' \
        asserts     'Codebeamer log binds to internal match_type 12, must precede match_type 3 in cascade order' \
        produced_by 'emit_format_detection_verbose() in ltl (per-file match_type field)' \
        contract    'features/225-test-harness-coverage-gaps.md section #228 - codebeamer regex must remain before tomcat 9 regex in the cascade so it wins for codebeamer-formatted lines'

    assert_line "$out" \
        pattern     '^  matched_lines: 741$' \
        asserts     'Codebeamer fixture (741 lines) parses every line via match_type 12 - no fallthrough to match_type 3' \
        produced_by 'emit_format_detection_verbose() in ltl (per-file matched_lines field)' \
        contract    'A regression in the codebeamer regex would silently fall back to match_type 3; this exact count guards against that'
}

scenario_thingworx_standard() {
    current_scenario="thingworx-standard"
    echo "[$current_scenario]"

    local log="$REPO_DIR/logs/ThingworxLogs/ApplicationLog.2025-05-05.0.log"
    local out
    out=$(run_format_detection "$log")

    assert_line "$out" \
        pattern     '^  format: thingworx_standard$' \
        asserts     'ThingWorx ApplicationLog binds to slug `thingworx_standard`. Detection regex: ltl:4792 (match_type 1).' \
        produced_by 'emit_format_detection_verbose() in ltl' \
        contract    '%match_type_to_slug in ltl GLOBALS - slug names are locked'

    assert_line "$out" \
        pattern     '^  match_type: 1$' \
        asserts     'ThingWorx standard log binds to internal match_type 1' \
        produced_by 'emit_format_detection_verbose() in ltl (per-file match_type field)' \
        contract    'features/225-test-harness-coverage-gaps.md section #228 - match_type 1 covers both full ThingWorx and the Logback-style fallback at ltl:4655'
}

scenario_thingworx_with_metrics() {
    current_scenario="thingworx-with-metrics"
    echo "[$current_scenario]"

    local log="$REPO_DIR/logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log"
    local out
    out=$(run_format_detection "$log")

    assert_line "$out" \
        pattern     '^  format: thingworx_standard$' \
        asserts     'ThingWorx ScriptLog with durationMS=/bytes= fields also binds to `thingworx_standard` - the duration/bytes capture happens within match_type 1, not as a separate slug' \
        produced_by 'emit_format_detection_verbose() in ltl' \
        contract    '%match_type_to_slug in ltl GLOBALS - ThingWorx logs with or without metrics share the same slug; metric presence is signaled via is_access_log=yes'

    assert_line "$out" \
        pattern     '^  is_access_log: yes$' \
        asserts     'A ThingWorx log with durationMS= or bytes= flips is_access_log to yes per ltl:4799-4802' \
        produced_by 'emit_format_detection_verbose() in ltl (per-file is_access_log field)' \
        contract    'features/225-test-harness-coverage-gaps.md section #228 - is_access_log distinguishes ThingWorx logs that have parseable latency/bytes from ones that do not'
}

scenario_tw_edge_c_sdk() {
    current_scenario="tw-edge-c-sdk"
    echo "[$current_scenario]"

    local log="$REPO_DIR/logs/UDM/rea-assets-5402_-TW_SSL_READ-Read_0_bytes-trace_logs.log"
    local out
    out=$(run_format_detection "$log")

    assert_line "$out" \
        pattern     '^  format: tw_edge_c_sdk$' \
        asserts     'ThingWorx Edge C SDK log binds to slug `tw_edge_c_sdk`. Detection regex: ltl:4884 (match_type 11). Format: `LEVEL ts file.cpp:NN message`.' \
        produced_by 'emit_format_detection_verbose() in ltl' \
        contract    '%match_type_to_slug in ltl GLOBALS - slug names are locked'

    assert_line "$out" \
        pattern     '^  match_type: 11$' \
        asserts     'Edge C SDK log binds to internal match_type 11' \
        produced_by 'emit_format_detection_verbose() in ltl (per-file match_type field)' \
        contract    'features/225-test-harness-coverage-gaps.md section #228 - match_type 11'
}

scenario_csv_with_udm() {
    current_scenario="csv-with-udm"
    echo "[$current_scenario]"

    local log="$REPO_DIR/logs/UDM/results_data_idonly-timestampMs.csv"
    local out
    # CSV detection requires at least one -udm flag for the CSV path to
    # be reached; otherwise ltl treats every CSV line as unmatched log content.
    out=$(run_format_detection "$log" -udm latency_ms)

    assert_line "$out" \
        pattern     '^  format: csv$' \
        asserts     'CSV file binds to slug `csv` when -udm is supplied. Detection: detect_and_parse_csv_header() invoked at ltl:4744+4935 (match_type 13).' \
        produced_by 'emit_format_detection_verbose() in ltl' \
        contract    '%match_type_to_slug in ltl GLOBALS - CSV detection requires explicit -udm config; bare ltl on a CSV file gives no matches and is intentional'

    assert_line "$out" \
        pattern     '^  match_type: 13$' \
        asserts     'CSV path uses internal match_type 13' \
        produced_by 'emit_format_detection_verbose() in ltl (per-file match_type field)' \
        contract    'features/225-test-harness-coverage-gaps.md section #228 - match_type 13 is reserved for the CSV path'
}

# ---------- Run -----------------------------------------------------------

echo "Validating format-detection -V section (issue #228)"
echo "  ltl:       $LTL"
echo ""

scenario_tomcat9_ms;            echo ""
scenario_apache_httpd_us;       echo ""
scenario_codebeamer;            echo ""
scenario_thingworx_standard;    echo ""
scenario_thingworx_with_metrics; echo ""
scenario_tw_edge_c_sdk;         echo ""
scenario_csv_with_udm

echo ""
echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
echo "ALL FORMAT-DETECTION TESTS PASSED"
exit 0
