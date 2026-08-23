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
# Scope: slugs with fixtures under logs/ are asserted directly;
# tomcat_access_common is asserted against a fixture derived on the fly
# from the Tomcat 9 log (duration field stripped, issue #345), and
# jboss_access against a fixture derived from the same log (quoted
# referrer/user-agent + trailing duration appended, issue #365). The
# remaining slugs (thingworx_rac_client, connection_server_json,
# java_gc_g1, tw_analytics_v2, tw_analytics_worker,
# connection_server_standard) are asserted against fixtures derived from
# the format registry's own sample lines (issue #58) — the same lines the
# D24 load-time gates validate, so fixture and registry cannot drift.
# The `format-detection / scan` sub-section (registry scan telemetry,
# issue #58) is asserted by the scan-telemetry scenarios.
#
# Implements the self-documenting-assertion design from
# tests/HARNESS-DESIGN.md. Reference: tests/validate-histogram-bin-counters.sh.
#
# Sub-task of issue #225. Issue #228.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"

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

# Contracted-absence assertion: a line matching `pattern` must NOT be
# present (HARNESS-DESIGN.md: absence asserted only when it is itself a
# contracted invariant, stated explicitly in `asserts`). A missing capture
# file is a hard failure, never a pass.
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
        echo "        (found in $outfile)"
        fail=$((fail + 1))
        failures+=("$current_scenario :: absent-pattern found: $pattern")
    else
        echo "  PASS  $current_scenario :: absent: $pattern"
        pass=$((pass + 1))
    fi
}

# Runtime-warning cleanliness for a run_format_detection capture (its stderr
# lives beside the captured stdout as <capture>.stderr). Runs in the main
# shell so the fail counters persist - a command-substitution subshell could
# not update them. HARNESS-DESIGN.md section Runtime-warning cleanliness.
check_capture_warnings() {
    local capture="$1"
    if ! assert_no_runtime_warnings "$capture.stderr" "$current_scenario"; then
        fail=$((fail + 1))
        failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
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
    check_capture_warnings "$out"

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

scenario_tomcat_common() {
    current_scenario="tomcat-common"
    echo "[$current_scenario]"

    # Standard/common access log format (%h %l %u %t "%r" %s %b — no duration
    # field). Derived on the fly from the canonical Tomcat 9 fixture by
    # stripping the trailing %D field, so the two scenarios cannot drift
    # apart and no near-duplicate corpus file is needed. Issue #345.
    local src="$REPO_DIR/logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt"
    local log="$TMP_DIR/tomcat-access-common-5k.txt"
    awk '{NF=NF-1; print}' "$src" > "$log"
    if [[ ! -s "$log" ]]; then
        echo "FAIL: could not derive common-format fixture from $src" >&2
        exit 1
    fi

    local out
    out=$(run_format_detection "$log")
    check_capture_warnings "$out"

    assert_line "$out" \
        pattern     '^  format: tomcat_access_common$' \
        asserts     'A standard/common access log (no duration field) binds to slug `tomcat_access_common`, not to `tomcat_access_with_duration`. The end-anchored match_type 4 regex is ordered before the broader match_type 3 regex so duration-less lines cannot be claimed by the with-duration branch.' \
        produced_by 'emit_format_detection_verbose() in ltl; detection cascade in read_and_process_logs() (match_type 4 branch, `$`-anchored after the bytes field)' \
        contract    '%match_type_to_slug in ltl GLOBALS - slug names are locked; renames are breaking under HARNESS-DESIGN.md section Stability contract'

    assert_line "$out" \
        pattern     '^  match_type: 4$' \
        asserts     'Common access log binds to internal match_type 4' \
        produced_by 'emit_format_detection_verbose() in ltl (per-file match_type field)' \
        contract    'features/225-test-harness-coverage-gaps.md section #228 - match_type integers are an implementation detail surfaced for diagnostic value; the slug is the user-facing contract'

    assert_line "$out" \
        pattern     '^  matched_lines: 5000$' \
        asserts     'Every line of the derived common-format fixture parses as match_type 4 (no fallthroughs to other branches)' \
        produced_by 'emit_format_detection_verbose() in ltl (per-file matched_lines field)' \
        contract    'Derived 1:1 from the hand-truncated 5000-line Tomcat 9 fixture; if that fixture changes, the expected count changes in the same commit'
}

scenario_jboss_enhanced() {
    current_scenario="jboss-enhanced"
    echo "[$current_scenario]"

    # JBoss/Jersey enhanced access log format (%h %l %u %t "%r" %s %b
    # "%{Referer}i" "%{User-Agent}i" %D). Derived on the fly from the canonical
    # Tomcat 9 fixture by rewriting the trailing %D field into quoted referrer +
    # quoted user-agent + duration, so the scenarios cannot drift apart and no
    # near-duplicate corpus file is needed. Lines with "-" bytes are excluded:
    # the match_type 9 regex requires numeric bytes, and such lines fall through
    # to match_type 3 by design. Issue #365.
    local src="$REPO_DIR/logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt"
    local log="$TMP_DIR/jboss-enhanced-access.txt"
    awk '$(NF-1) ~ /^[0-9]+$/ {dur=$NF; $NF="\"-\" \"Jersey/2.37 (HttpUrlConnection 11.0.22)\" " dur; print}' "$src" > "$log"
    if [[ ! -s "$log" ]]; then
        echo "FAIL: could not derive enhanced-format fixture from $src" >&2
        exit 1
    fi
    local expected_lines
    expected_lines=$(wc -l < "$log" | tr -d ' ')
    if [[ -z "$expected_lines" || "$expected_lines" -eq 0 ]]; then
        echo "FAIL: derived enhanced-format fixture is empty" >&2
        exit 1
    fi

    local out
    out=$(run_format_detection "$log")
    check_capture_warnings "$out"

    assert_line "$out" \
        pattern     '^  format: jboss_access$' \
        asserts     'An enhanced/JBoss access log (quoted referrer, quoted user-agent, trailing duration) binds to slug `jboss_access`, not to `tomcat_access_with_duration`. The end-anchored match_type 9 regex is ordered before the broader match_type 3 regex, whose all-optional tail would otherwise claim these lines with duration=undef and junk thread/session captures (issue #365).' \
        produced_by 'emit_format_detection_verbose() in ltl; detection cascade in read_and_process_logs() (match_type 9 branch, `$`-anchored after the trailing duration field)' \
        contract    '%match_type_to_slug in ltl GLOBALS - slug names are locked; renames are breaking under HARNESS-DESIGN.md section Stability contract'

    assert_line "$out" \
        pattern     '^  match_type: 9$' \
        asserts     'Enhanced/JBoss access log binds to internal match_type 9' \
        produced_by 'emit_format_detection_verbose() in ltl (per-file match_type field)' \
        contract    'features/225-test-harness-coverage-gaps.md section #228 - match_type integers are an implementation detail surfaced for diagnostic value; the slug is the user-facing contract'

    assert_line "$out" \
        pattern     "^  matched_lines: $expected_lines\$" \
        asserts     'Every line of the derived enhanced-format fixture parses as match_type 9 (no fallthroughs to match_type 3 or other branches)' \
        produced_by 'emit_format_detection_verbose() in ltl (per-file matched_lines field)' \
        contract    'Derived from the hand-truncated Tomcat 9 fixture (numeric-bytes lines only); the expected count is computed from the derived file so the assertion tracks the fixture'
}

scenario_apache_httpd_us() {
    current_scenario="apache-httpd-us"
    echo "[$current_scenario]"

    local log="$REPO_DIR/logs/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log"
    local out
    # Run with -du us per the documented workaround. Apache HTTP %D is
    # microseconds; without -du us, durations are 1000x off.
    out=$(run_format_detection "$log" -du us)
    check_capture_warnings "$out"

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
    check_capture_warnings "$out"

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
    check_capture_warnings "$out"

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
    check_capture_warnings "$out"

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
    check_capture_warnings "$out"

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
    check_capture_warnings "$out"

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

# Shared shape for the six registry-sample scenarios: write the fixture
# from a heredoc holding the registry entry's sample lines verbatim,
# run, and assert slug + match_type + matched_lines. The samples are the
# same lines build_format_registry() validates at every startup (D24), so
# a passing scenario proves the end-to-end path (file -> scan -> section)
# for a format the corpus has no committed fixture for.
assert_registry_sample_scenario() {
    local fixture="$1" slug="$2" mt="$3" nlines="$4"
    local out
    out=$(run_format_detection "$fixture")
    check_capture_warnings "$out"

    assert_line "$out" \
        pattern     "^  format: $slug\$" \
        asserts     "The registry sample fixture for slug \`$slug\` binds to that slug (registry entry for match_type $mt; samples are the entry's own D24-validated sample lines)" \
        produced_by 'emit_format_detection_verbose() in ltl' \
        contract    '%match_type_to_slug in ltl GLOBALS - slug names are locked; renames are breaking under HARNESS-DESIGN.md section Stability contract'

    assert_line "$out" \
        pattern     "^  match_type: $mt\$" \
        asserts     "Slug \`$slug\` binds to internal match_type $mt" \
        produced_by 'emit_format_detection_verbose() in ltl (per-file match_type field)' \
        contract    'features/log-format-registry.md section -V format-detection section-contract - match_type integers are diagnostic; the slug is the user-facing contract'

    assert_line "$out" \
        pattern     "^  matched_lines: $nlines\$" \
        asserts     "Every line of the registry-sample fixture parses via match_type $mt (no fallthroughs)" \
        produced_by 'emit_format_detection_verbose() in ltl (per-file matched_lines field)' \
        contract    "Fixture is the registry entry's sample lines verbatim; if the samples change in format_registry_specs(), this fixture and count change in the same commit"

    # Evidence sample on a file smaller than the whole sample (D53): read
    # once, whole, as a single part; the fallback window stays disengaged.
    assert_line "$out" \
        pattern     '^  window: 0$' \
        asserts     'A sampled plain file engages no fallback window (window: 0) — the sample served it' \
        produced_by 'read_and_process_logs() in ltl (window engagement); emitted by emit_format_detection_sample_verbose()' \
        contract    'features/log-format-registry.md section -V format-detection section-contract (detection-evidence keys, umbrella D53)'

    assert_line "$out" \
        pattern     '^  sample_whole_file: yes$' \
        asserts     'A file no larger than sample_parts x sample_bytes_per_part is read once, whole, as a single part' \
        produced_by 'sample_file_for_detection() in ltl; emitted by emit_format_detection_sample_verbose()' \
        contract    'features/log-format-registry.md section -V format-detection section-contract (detection-evidence keys, umbrella D53)'

    assert_line "$out" \
        pattern     "^  sample_matched_lines: $nlines\$" \
        asserts     "Every line of the whole-file sample is recognised by the registry patterns directly ($nlines lines), without touching scan_attempts" \
        produced_by 'sample_file_for_detection() in ltl (direct pattern recognition, static cascade order)' \
        contract    'features/log-format-registry.md section -V format-detection section-contract (detection-evidence keys, umbrella D53)'
}

scenario_thingworx_rac_client() {
    current_scenario="thingworx-rac-client"
    echo "[$current_scenario]"
    local log="$TMP_DIR/rac-client.log"
    cat > "$log" <<'EOF'
[2025-02-04T12:06:22.784] [TRACE] tunnel keepalive sent
2025-03-01 08:00:00.123 tunnel worker [INFO] session established
EOF
    assert_registry_sample_scenario "$log" thingworx_rac_client 2 2
}

scenario_connection_server_json() {
    current_scenario="connection-server-json"
    echo "[$current_scenario]"
    local log="$TMP_DIR/cxserver-json.log"
    cat > "$log" <<'EOF'
{"@timestamp":"2025-02-02T21:03:06.725+00:00","@version":1,"message":"Error encountered, closing WebSocket: endpointId=2608459","logger_name":"com.thingworx.connectionserver.alwayson.AbstractClientEndpoint","thread_name":"vert.x-eventloop-thread-16","level":"WARN","level_value":30000}
{"@timestamp":"2025-02-02T21:03:07.001+00:00","@version":1,"message":"Session registered","logger_name":"c.t.c.a.SessionTracker","thread_name":"vert.x-eventloop-thread-2","level":"INFO","level_value":20000}
EOF
    assert_registry_sample_scenario "$log" connection_server_json 5 2
}

scenario_java_gc_g1() {
    current_scenario="java-gc-g1"
    echo "[$current_scenario]"
    local log="$TMP_DIR/gc.log"
    cat > "$log" <<'EOF'
[2025-04-05T11:10:47.867+0000][info][gc] GC(0) Pause Young (Normal) (G1 Evacuation Pause) 2433M->66M(49152M) 18.406ms
[2025-04-05T12:00:03.101+0000][info][gc] GC(7) Pause Young (Concurrent Start) (Metadata GC Threshold) 512M->128M(49152M) 7.250ms
[2025-04-05T11:10:50.305+0000][info][gc] GC(2) Pause Remark 74M->74M(320M) 2.422ms
[2025-04-05T11:10:50.309+0000][info][gc] GC(2) Pause Cleanup 82M->82M(320M) 0.204ms
[2024-10-16T05:27:56.233+0000][info][gc] GC(144521) To-space exhausted
[2025-06-05T11:17:57.418+0000][info][gc] Using G1
EOF
    assert_registry_sample_scenario "$log" java_gc_g1 6 6
}

scenario_tw_analytics_v2() {
    current_scenario="tw-analytics-v2"
    echo "[$current_scenario]"
    local log="$TMP_DIR/analytics-v2.log"
    cat > "$log" <<'EOF'
ERROR [2025-02-19 18:31:00,284] com.thingworx.sdk.impl.transport.netty.NettyChannelHandler: [ClientHandler: 76b37675] WebSocket error: An existing connection was forcibly closed by the remote host, closing connection!
INFO  [2025-02-20 04:49:11,450] org.ehcache.core.EhcacheManager: Cache 'scorefunc_cachex' created in EhcacheManager.
EOF
    assert_registry_sample_scenario "$log" tw_analytics_v2 7 2
}

scenario_tw_analytics_worker() {
    current_scenario="tw-analytics-worker"
    echo "[$current_scenario]"
    local log="$TMP_DIR/analytics-worker.log"
    cat > "$log" <<'EOF'
2025-02-20 10:06:10 [nioEventLoopGroup-2-1] WARN  io.netty.channel.ChannelInitializer - Failed to initialize a channel. Closing: [id: 0x8171dc41]
2025-02-20 10:06:11,123 [pool-2-thread-1] INFO  io.netty.util.ResourceLeakDetector - Leak detection level set to SIMPLE.
EOF
    assert_registry_sample_scenario "$log" tw_analytics_worker 8 2
}

scenario_connection_server_standard() {
    current_scenario="connection-server-standard"
    echo "[$current_scenario]"
    local log="$TMP_DIR/cxserver-standard.log"
    cat > "$log" <<'EOF'
2025-08-14 21:00:34.633 [vert.x-eventloop-thread-12] INFO  c.t.c.a.AlwaysOnHttpServerVerticle - Enabled fix for WebSocket compression sometimes causing frames to exceed maximum WebSocket frame size
2025-08-14 21:00:35.100 [vert.x-eventloop-thread-3] INFO  c.t.c.a.AlwaysOnHttpServerVerticle - Request from 10.1.2.3:52344 completed processing in 152 milliseconds
EOF
    assert_registry_sample_scenario "$log" connection_server_standard 10 2
}

scenario_scan_telemetry() {
    current_scenario="scan-telemetry"
    echo "[$current_scenario]"

    # The codebeamer fixture drives the clean MTF story: mt12 sits behind
    # four non-ancestors in the static order, so the first match promotes
    # it to the front (exactly one promotion), after which every line hits
    # the front block and no further promotion occurs.
    local log="$REPO_DIR/logs/Codebeamber/codebeamer_access_log.2025-10-29.txt"
    local out
    out=$(run_format_detection "$log")
    check_capture_warnings "$out"

    assert_line "$out" \
        pattern     '^=== format-detection / scan ===$' \
        asserts     'The scan-telemetry sub-section is emitted inside the format-detection section' \
        produced_by 'emit_format_detection_verbose() in ltl' \
        contract    'features/log-format-registry.md section -V format-detection section-contract; delimiters per HARNESS-DESIGN.md section Delimiter contract'

    assert_line "$out" \
        pattern     '^entries: 13$' \
        asserts     'All 13 scanned registry entries are compiled into the scan (csv is outside the scan array by design)' \
        produced_by 'build_format_registry() in ltl; emitted by emit_format_detection_verbose()' \
        contract    'features/log-format-registry.md section -V format-detection section-contract - adding or removing a scanned format changes this count in the same commit'

    assert_line "$out" \
        pattern     '^guarded: mt12,mt4,mt9$' \
        asserts     'Exactly the three cheap-superset-guard entries (D28) carry guards, listed in static registry order' \
        produced_by 'compile_format_guard() wiring in build_format_registry(); emitted by emit_format_detection_verbose()' \
        contract    'features/log-format-registry.md section -V format-detection section-contract (D28 guard set)'

    assert_line "$out" \
        pattern     '^window_size: 0$' \
        asserts     'Without --detection-window, the override is 0 (D30/D38); the window engages per file only as the fallback for unsampled input' \
        produced_by 'emit_format_detection_verbose() in ltl ($format_detection_window)' \
        contract    'features/log-format-registry.md section -V format-detection section-contract'

    # Evidence sample (umbrella D53): the dual process's primary path. The
    # 84,857-byte codebeamer fixture is larger than 3 x 8192, so three
    # parts are read at byte offsets 0, 38332, 76665 and the per-part
    # observations are deterministic for the committed fixture.
    assert_line "$out" \
        pattern     '^window_fallback: 1000$' \
        asserts     'The fallback two-phase-store window size for unsampled input is 1000 lines (D53)' \
        produced_by 'emit_format_detection_verbose() in ltl (FORMAT_DETECTION_WINDOW_FALLBACK)' \
        contract    'features/log-format-registry.md section -V format-detection section-contract; features/log-format-registry.md D53'

    assert_line "$out" \
        pattern     '^sample_parts: 3$' \
        asserts     'The evidence sample reads three parts per file: front, middle, end (FORMAT_SAMPLE_PARTS)' \
        produced_by 'emit_format_detection_verbose() in ltl (FORMAT_SAMPLE_PARTS)' \
        contract    'features/log-format-registry.md section #388 findings - the value is the measured default; changing it changes every sample_* value below in the same commit'

    assert_line "$out" \
        pattern     '^sample_bytes_per_part: 8192$' \
        asserts     'The evidence sample reads 8192 bytes per part (FORMAT_SAMPLE_BYTES)' \
        produced_by 'emit_format_detection_verbose() in ltl (FORMAT_SAMPLE_BYTES)' \
        contract    'features/log-format-registry.md section #388 findings - the value is the measured default; changing it changes every sample_* value below in the same commit'

    assert_line "$out" \
        pattern     '^  window: 0$' \
        asserts     'A sampled plain file engages no fallback window (window: 0) — the sample served it' \
        produced_by 'read_and_process_logs() in ltl (window engagement); emitted by emit_format_detection_sample_verbose()' \
        contract    'features/log-format-registry.md section -V format-detection section-contract (detection-evidence keys, umbrella D53)'

    assert_line "$out" \
        pattern     '^  sample: yes$' \
        asserts     'A plain file is sampled (the primary path of the dual process)' \
        produced_by 'sample_file_for_detection() in ltl; emitted by emit_format_detection_sample_verbose()' \
        contract    'features/log-format-registry.md section -V format-detection section-contract (detection-evidence keys, umbrella D53)'

    assert_line "$out" \
        pattern     '^  sample_file_bytes: 84857$' \
        asserts     'The sample records the file byte size it divided (the committed codebeamer fixture is 84,857 bytes)' \
        produced_by 'sample_file_for_detection() in ltl (-s on the sample handle)' \
        contract    'features/log-format-registry.md section -V format-detection section-contract (detection-evidence keys, umbrella D53)'

    assert_line "$out" \
        pattern     '^  sample_whole_file: no$' \
        asserts     'A file larger than sample_parts x sample_bytes_per_part is sampled in parts, not read whole' \
        produced_by 'sample_file_for_detection() in ltl' \
        contract    'features/log-format-registry.md section -V format-detection section-contract (detection-evidence keys, umbrella D53)'

    assert_line "$out" \
        pattern     '^  sample_lines: 230$' \
        asserts     'Three 8192-byte parts of the codebeamer fixture yield 230 whole lines after discarding the partial line at each part edge' \
        produced_by 'sample_file_for_detection() in ltl (edge-line discard)' \
        contract    'features/log-format-registry.md section -V format-detection section-contract (detection-evidence keys, umbrella D53) - value is deterministic for the committed fixture at the default sample shape'

    assert_line "$out" \
        pattern     '^  sample_matched_lines: 230$' \
        asserts     'Every sampled codebeamer line is recognised by the registry patterns directly, without entering the production scan (scan_attempts stays 741)' \
        produced_by 'sample_file_for_detection() in ltl (direct pattern recognition, static cascade order)' \
        contract    'features/log-format-registry.md section -V format-detection section-contract (detection-evidence keys, umbrella D53)'

    assert_line "$out" \
        pattern     '^  sample_formats: mt12=230$' \
        asserts     'The sample attributes all 230 recognised lines to entry mt12, keyed by entry name in static registry order' \
        produced_by 'sample_file_for_detection() in ltl; emitted by emit_format_detection_sample_verbose()' \
        contract    'features/log-format-registry.md section -V format-detection section-contract (detection-evidence keys, umbrella D53)'

    assert_line "$out" \
        pattern     '^  sample_part: 1 offset=0 bytes=8192 lines=86 avg_line=94 matched=86 first_ts="29/Oct/2025:08:03:31 \+0000" last_ts="29/Oct/2025:08:44:07 \+0000"$' \
        asserts     'Part 1 starts at byte 0, keeps 86 whole lines (avg 94 bytes), all recognised, and reports the raw (unparsed) first and last timestamp captures' \
        produced_by 'sample_file_for_detection() in ltl (per-part observations; timestamp_str capture via the field map)' \
        contract    'features/log-format-registry.md section -V format-detection section-contract (detection-evidence keys, umbrella D53) - deterministic for the committed fixture'

    assert_line "$out" \
        pattern     '^  sample_part: 3 offset=76665 bytes=8192 lines=87 avg_line=94 matched=87 first_ts="29/Oct/2025:11:20:56 \+0000" last_ts="29/Oct/2025:12:04:02 \+0000"$' \
        asserts     'The last part is positioned so its read ends at EOF (offset = size - bytes) and its last_ts is the file'"'"'s final timestamp' \
        produced_by 'sample_file_for_detection() in ltl (end-part placement)' \
        contract    'features/log-format-registry.md section -V format-detection section-contract (detection-evidence keys, umbrella D53) - deterministic for the committed fixture'

    assert_line "$out" \
        pattern     '^  sample_us: [0-9]+\.[0-9]$' \
        asserts     'The sample wall time is reported as a one-decimal microsecond value (nondeterministic: shape asserted, never the value)' \
        produced_by 'emit_format_detection_sample_verbose() in ltl' \
        contract    'features/log-format-registry.md section -V format-detection section-contract (detection-evidence keys, umbrella D53)'

    assert_line "$out" \
        pattern     '^final_order: mt12,' \
        asserts     'After the codebeamer run, mt12 (no pinned ancestors) leads the MTF scan order' \
        produced_by 'format_registry_promote() in ltl; emitted by emit_format_detection_verbose()' \
        contract    'features/log-format-registry.md section -V format-detection section-contract (D26 pinned-closure MTF)'

    assert_line "$out" \
        pattern     '^promotions: 1$' \
        asserts     'A single-format file causes exactly one promotion: the first match reorders, every later line hits the already-optimal front block' \
        produced_by 'format_registry_promote() in ltl (counter incremented only on actual reorders; reset after the D24 build gates)' \
        contract    'features/log-format-registry.md section -V format-detection section-contract'

    assert_line "$out" \
        pattern     '^match_counts: .*mt12=741' \
        asserts     'All 741 codebeamer lines are attributed to entry mt12 in the per-entry match counts' \
        produced_by 'FR_MATCHES increment in read_and_process_logs(); emitted by emit_format_detection_verbose()' \
        contract    'features/log-format-registry.md section -V format-detection section-contract - counts are per registry entry (FR_NAME), static registry order'

    assert_line "$out" \
        pattern     '^  scan_attempts: 741$' \
        asserts     'Every line of the 741-line fixture entered the registry scan exactly once' \
        produced_by 'per-file scan counters in read_and_process_logs(); emitted by emit_format_detection_verbose()' \
        contract    'features/log-format-registry.md section -V format-detection section-contract'

    assert_line "$out" \
        pattern     '^  scan_failed_attempts: 0$' \
        asserts     'A fully-matched file records zero failed scan attempts' \
        produced_by 'per-file scan counters in read_and_process_logs(); emitted by emit_format_detection_verbose()' \
        contract    'features/log-format-registry.md section -V format-detection section-contract'
}

scenario_scan_telemetry_nomatch() {
    current_scenario="scan-telemetry-nomatch"
    echo "[$current_scenario]"

    # 300 unmatchable lines exercise the no-match path past the 1-in-256
    # sampling threshold, so exactly one sampled timing must be recorded;
    # 20 codebeamer lines appended after them prove failed attempts and
    # matches coexist in one file's counters.
    local src="$REPO_DIR/logs/Codebeamber/codebeamer_access_log.2025-10-29.txt"
    local log="$TMP_DIR/scan-nomatch-mixed.txt"
    {
        for i in $(seq 1 300); do echo "junk unmatched line $i without any timestamp"; done
        head -20 "$src"
    } > "$log"
    if [[ ! -s "$log" ]]; then
        echo "FAIL: could not derive no-match fixture from $src" >&2
        exit 1
    fi

    local out
    out=$(run_format_detection "$log")
    check_capture_warnings "$out"

    assert_line "$out" \
        pattern     '^  scan_failed_attempts: 300$' \
        asserts     'Each of the 300 unmatchable lines records one failed scan attempt' \
        produced_by 'per-file scan counters in read_and_process_logs(); emitted by emit_format_detection_verbose()' \
        contract    'features/log-format-registry.md section -V format-detection section-contract'

    assert_line "$out" \
        pattern     '^  scan_attempts: 320$' \
        asserts     'scan_attempts counts matched and failed scans together (300 junk + 20 codebeamer lines)' \
        produced_by 'per-file scan counters in read_and_process_logs(); emitted by emit_format_detection_verbose()' \
        contract    'features/log-format-registry.md section -V format-detection section-contract'

    assert_line "$out" \
        pattern     '^nomatch_scan_samples: 1$' \
        asserts     '300 no-match scans cross the 1-in-256 sampling threshold exactly once' \
        produced_by 'no-match sampling in read_and_process_logs() (FORMAT_SCAN_NOMATCH_SAMPLE_EVERY)' \
        contract    'features/log-format-registry.md section -V format-detection section-contract - the sampling interval is part of the contract; changing it changes this count'

    assert_line "$out" \
        pattern     '^nomatch_scan_avg_us: [0-9]+\.[0-9]$' \
        asserts     'With at least one sample, the average no-match scan cost is reported as a one-decimal microsecond value (dash only when zero samples)' \
        produced_by 'emit_format_detection_verbose() in ltl (sampled no-match accumulator)' \
        contract    'features/log-format-registry.md section -V format-detection section-contract'

    # Same fixture through the two-phase-store window path: prefill
    # classifications must fold into the same per-file counters (no
    # double-count on held-line replay) and the resolved N is reported.
    local wout
    wout=$(run_format_detection "$log" --detection-window=8)
    check_capture_warnings "$wout"

    assert_line "$wout" \
        pattern     '^window_size: 8$' \
        asserts     'With --detection-window=8, the sub-section reports the resolved window size' \
        produced_by 'emit_format_detection_verbose() in ltl ($format_detection_window)' \
        contract    'features/log-format-registry.md section -V format-detection section-contract (D30/D38 window structure)'

    assert_line "$wout" \
        pattern     '^  window: 8$' \
        asserts     'The --detection-window override engages the fallback window for a sampled file too (dual process: both paths exercisable), at the override size' \
        produced_by 'read_and_process_logs() in ltl (window engagement: override > sampled ? 0 : fallback)' \
        contract    'features/log-format-registry.md section -V format-detection section-contract (detection-evidence keys, umbrella D53)'

    assert_line "$wout" \
        pattern     '^  scan_attempts: 320$' \
        asserts     'Window prefill classifications count as scan attempts and held-line replays are not re-counted: the total is identical to the windowless run' \
        produced_by 'window prefill + per-file scan counters in read_and_process_logs()' \
        contract    'features/log-format-registry.md section -V format-detection section-contract'
}

scenario_unit_ambiguity_warning() {
    current_scenario="unit-ambiguity-warning"
    echo "[$current_scenario]"

    # D18 (#58 S7): binding a format whose duration unit varies across
    # producers without -du emits one stderr note naming the assumption.
    # The note is an intentional diagnostic — it never carries an
    # ` at ... line` suffix, so check_capture_warnings stays clean.
    local tomcat="$REPO_DIR/logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt"
    local out
    out=$(run_format_detection "$tomcat")
    check_capture_warnings "$out"

    assert_line "$out.stderr" \
        pattern     '^Note: the detected log format'"'"'s duration unit varies across producers; durations are assumed to be milliseconds - use -du to specify the appropriate duration unit for the files being analyzed$' \
        asserts     'Binding a unit-ambiguous format without -du emits the run-level note on stderr: format-generic (the condition is the registry ambiguity flag, not any specific log type), no filename, naming the milliseconds assumption and pointing at -du generically (not prescribing a unit)' \
        produced_by 'read_and_process_logs() in ltl (first-match block, FR_UNIT_AMBIGUOUS gate)' \
        contract    'features/58-format-registry-staged-detection.md section S7 unit-ambiguity note (D18); the note text is part of the contract'

    # Contracted absence 1: an explicit -du suppresses the note — the user
    # has stated the unit, so there is no assumption to surface.
    local out_du
    out_du=$(run_format_detection "$tomcat" -du ms)
    check_capture_warnings "$out_du"

    assert_absent "$out_du.stderr" \
        pattern     '^Note: the detected log format.s duration unit varies' \
        asserts     'With -du given (any unit), the unit-ambiguity note is contracted ABSENT: the note exists only to surface an assumption, and -du removes the assumption' \
        produced_by 'read_and_process_logs() in ltl (first-match block, duration_unit_override gate)' \
        contract    'features/58-format-registry-staged-detection.md section S7 unit-ambiguity note (D18)'

    # Contracted absence 2: an unambiguous format (codebeamer declares ms
    # unconditionally) never triggers the note.
    local out_cb
    out_cb=$(run_format_detection "$REPO_DIR/logs/Codebeamber/codebeamer_access_log.2025-10-29.txt")
    check_capture_warnings "$out_cb"

    assert_absent "$out_cb.stderr" \
        pattern     '^Note: the detected log format.s duration unit varies' \
        asserts     'A format without the unit-ambiguity flag is contracted to never emit the note — the gate is the registry declaration, not the presence of durations' \
        produced_by 'read_and_process_logs() in ltl (first-match block, FR_UNIT_AMBIGUOUS gate)' \
        contract    'features/58-format-registry-staged-detection.md section S7 unit-ambiguity note (D18) - only entries declaring unit_ambiguous carry it'
}

# ---------- Run -----------------------------------------------------------

echo "Validating format-detection -V section (issue #228)"
echo "  ltl:       $LTL"
echo ""

scenario_tomcat9_ms;            echo ""
scenario_tomcat_common;         echo ""
scenario_jboss_enhanced;        echo ""
scenario_apache_httpd_us;       echo ""
scenario_codebeamer;            echo ""
scenario_thingworx_standard;    echo ""
scenario_thingworx_with_metrics; echo ""
scenario_tw_edge_c_sdk;         echo ""
scenario_csv_with_udm;          echo ""
scenario_thingworx_rac_client;  echo ""
scenario_connection_server_json; echo ""
scenario_java_gc_g1;            echo ""
scenario_tw_analytics_v2;       echo ""
scenario_tw_analytics_worker;   echo ""
scenario_connection_server_standard; echo ""
scenario_scan_telemetry;        echo ""
scenario_scan_telemetry_nomatch; echo ""
scenario_unit_ambiguity_warning

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
