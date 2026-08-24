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
# connection_server_standard, windchill_method_server) are asserted against fixtures derived from
# the format registry's own sample lines (issue #58) — the same lines the
# D24 load-time gates validate, so fixture and registry cannot drift.
# windchill_workgroup_manager is asserted against the committed wgm-client.txt fixture
# staged under each of its three producer-true names (issue #395).
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
# Invocation shape (HARNESS-DESIGN.md section Invocation coherence): every
# scenario reads the -V format-detection section or a stderr note - which
# entry bound, on what evidence, with what scan telemetry - so the run
# takes the coarsest bucket with no empty buckets and the smallest table
# (`-bs 1440 -oe -n 1 -osum`); the section is identical at any shape.
#
# HARNESS-DESIGN.md Trap 1: preserve stderr, check exit code.
run_format_detection() {
    local log="$1"
    shift
    local outfile
    outfile="$TMP_DIR/$(basename "$log" | tr -c 'A-Za-z0-9._-' '_').out"
    set +e
    "$LTL" --disable-progress -ni -bs 1440 -oe -n 1 -osum -V format-detection "$@" "$log" > "$outfile" 2>"$outfile.stderr"
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


# assert_command: eval a command; PASS on exit 0. Same self-documenting
# triple as assert_line (reference: tests/validate-csv-input.sh).
assert_command() {
    local command="" label="" asserts="" produced_by="" contract=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            command)     command="$2"; shift 2 ;;
            label)       label="$2"; shift 2 ;;
            asserts)     asserts="$2"; shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2"; shift 2 ;;
            *) echo "assert_command: unknown field '$1'" >&2; exit 2 ;;
        esac
    done
    : "${command:?assert_command requires command}"
    : "${asserts:?assert_command requires asserts}"
    : "${produced_by:?assert_command requires produced_by}"
    : "${contract:?assert_command requires contract}"
    if eval "$command" >/dev/null 2>&1; then
        echo "  PASS  $current_scenario :: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario :: $label"
        echo "        command:     $command"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
        failures+=("$current_scenario :: $label")
    fi
}

# Stage a committed fixture (tests/fixtures/format-detection/<fixture>)
# under a producer-true name in a per-scenario directory (D51): the
# committed name is never fed to ltl, and two scenarios may stage the same
# staged name without colliding. Echoes the staged path.
FIXTURE_DIR="$REPO_DIR/tests/fixtures/format-detection"
stage_fixture() {
    local fixture="$1" staged_as="$2"
    local dir="$TMP_DIR/$current_scenario"
    mkdir -p "$dir"
    if [[ ! -f "$FIXTURE_DIR/$fixture" ]]; then
        echo "  FAIL  $current_scenario :: fixture $FIXTURE_DIR/$fixture is missing" >&2
        fail=$((fail + 1)); failures+=("$current_scenario :: fixture missing"); return 1
    fi
    cp "$FIXTURE_DIR/$fixture" "$dir/$staged_as"
    echo "$dir/$staged_as"
}

# One variant-selection assertion block: format, selected member, basis.
assert_variant_selection() {
    local out="$1" format="$2" selected="$3" basis="$4" confidence="$5"
    assert_line "$out" pattern "^  format: $format\$" \
        asserts "The file binds the $format format" \
        produced_by 'read_and_process_logs() in ltl (first-match block)' \
        contract 'features/log-format-registry.md section -V format-detection section-contract'
    assert_line "$out" pattern "^  selected: $selected\$" \
        asserts "Variant selection put $selected in its group slot for this file (D47)" \
        produced_by 'select_format_variants() in ltl' \
        contract 'features/log-format-registry.md section -V format-detection section-contract (#384 additions)'
    assert_line "$out" pattern "^  selection_basis: $basis\$" \
        asserts "The selection basis is $basis" \
        produced_by 'select_format_variants() in ltl' \
        contract 'features/log-format-registry.md section -V format-detection section-contract (#384 additions)'
    assert_line "$out" pattern "^  confidence: $confidence\$" \
        asserts "Confidence = selected score / sum of live members (I1 weights)" \
        produced_by 'select_format_variants() in ltl' \
        contract 'features/log-format-registry.md section Drop 1.5 I1 (evidence weights)'
}

# Helper: stage the first 300 lines of a corpus file under $TMP_DIR. The
# corpus scenarios assert only which entry bound (slug + match_type), and
# detection samples the file rather than scanning it, so a 300-line head
# carries the whole signal (HARNESS-DESIGN.md section Invocation coherence).
# Usage: slice=$(head_slice <source> <staged-name>)
head_slice() {
    local src="$1" name="$2" dest="$TMP_DIR/$2"
    head -300 "$src" > "$dest"
    if [[ ! -s "$dest" ]]; then
        echo "FAIL: could not derive 300-line slice from $src" >&2
        exit 1
    fi
    echo "$dest"
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

    local log; log=$(head_slice "$REPO_DIR/logs/ThingworxLogs/ApplicationLog.2025-05-05.0.log" ApplicationLog.2025-05-05.0.log)
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

    local log; log=$(head_slice "$REPO_DIR/logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log" ScriptLog-DPMExtended-clean.log)
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

    local log; log=$(head_slice "$REPO_DIR/logs/UDM/rea-assets-5402_-TW_SSL_READ-Read_0_bytes-trace_logs.log" tw-edge-c-sdk-trace.log)
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

    local log; log=$(head_slice "$REPO_DIR/logs/UDM/results_data_idonly-timestampMs.csv" results_data_idonly-timestampMs.csv)
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

scenario_windchill_method_server() {
    current_scenario="windchill-method-server"
    echo "[$current_scenario]"
    local log="$TMP_DIR/MethodServer-2507180627-9144-log4j.log"
    cat > "$log" <<'EOF'
2025-07-18 04:46:41,354 INFO  [main] wt.method.server.startup  - Starting BackgroundMethodServer
2025-07-18 08:19:31,762 ERROR [ActiveMQ Session Task-3] com.ptc.windchill.esi.txn.ESITransactionUtility wcadmin - Exception while fetching a transaction from the input parameters. (wt.federation.federationResource/109) wt.util.WTException: Unable to find target object "OR:wt.part.WTPart:123456789".
2025-07-18 04:52:55,260 WARN  [JMX Monitor ThreadGroup<main> Executor Pool [Thread-21]] wt.jmx.notif.methodContextGauge  - Time=2025-07-18 04:52:55.257 +0000, Name=MethodContextsGaugeNotifier
EOF
    assert_registry_sample_scenario "$log" windchill_method_server 17 3
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
        pattern     '^entries: 15$' \
        asserts     'All 15 scanned registry entries are compiled into the scan (csv is outside the scan array by design)' \
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
        pattern     '^promotions: 0$' \
        asserts     'A single-format file causes NO promotion: election fronts the format the evidence named before line 1, so every line hits the already-optimal front block' \
        produced_by 'format_elect_scan_front() in ltl fronts the elected group; format_registry_promote() increments only on actual reorders' \
        contract    'features/log-format-registry.md section -V format-detection section-contract (D60 elevation by election)'

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

    # D47/I6 (#384): binding a variant-group member that was selected by
    # default — nothing in the file name or content decided between the
    # producers — emits one stderr note naming the consequence (here the
    # duration unit) and the overrides. The note is an intentional
    # diagnostic — it never carries an ` at ... line` suffix, so
    # check_capture_warnings stays clean. The Tomcat file's name does not
    # carry the producer's stem, so the group default holds by its standing
    # credit (basis default).
    local tomcat="$REPO_DIR/logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt"
    local out
    out=$(run_format_detection "$tomcat")
    check_capture_warnings "$out"

    assert_line "$out.stderr" \
        pattern     '^Note: the detected log format \(tomcat_access_with_duration\) is written by more than one producer and the duration unit differs between them \(assumed ms\); nothing in the file names or content decided which - use -du <unit> or -lf httpd_access_with_duration if the files come from the other producer$' \
        asserts     'Binding a default-selected variant-group member without deciding evidence emits the run-level note on stderr: no filename, naming the consequence class (unit) and the assumption, pointing at -du and at -lf with the other member' \
        produced_by 'format_variant_ambiguity_note() in ltl (first-match block)' \
        contract    'features/log-format-registry.md section Drop 1.5 I6 (ambiguity note); the note text is part of the contract'
    assert_line "$out" \
        pattern     '^  selection_basis: default$' \
        asserts     'The note fires only when the selection basis is default' \
        produced_by 'select_format_variants() in ltl' \
        contract    'features/log-format-registry.md section -V format-detection section-contract (#384 additions)'

    # Contracted absence 1: an explicit -du suppresses the note — the user
    # has stated the unit, so there is no assumption to surface.
    local out_du
    out_du=$(run_format_detection "$tomcat" -du ms)
    check_capture_warnings "$out_du"

    assert_absent "$out_du.stderr" \
        pattern     '^Note: the detected log format' \
        asserts     'With -du given (any unit), the unit note is contracted ABSENT: the note exists only to surface an assumption, and -du removes the assumption' \
        produced_by 'format_variant_ambiguity_note() in ltl (duration_unit_override gate)' \
        contract    'features/log-format-registry.md section Drop 1.5 I6 (ambiguity note)'

    # Contracted absence 2: a format outside any variant group (codebeamer)
    # never triggers the note.
    local out_cb
    out_cb=$(run_format_detection "$REPO_DIR/logs/Codebeamber/codebeamer_access_log.2025-10-29.txt")
    check_capture_warnings "$out_cb"

    assert_absent "$out_cb.stderr" \
        pattern     '^Note: the detected log format' \
        asserts     'A format that is not a member of a variant group is contracted to never emit the note — the gate is group membership plus a default-basis selection' \
        produced_by 'format_variant_ambiguity_note() in ltl (variant-group gate)' \
        contract    'features/log-format-registry.md section Drop 1.5 I6 (ambiguity note)'

    # Contracted absence 3: the same content under the producer-true name
    # is decided by evidence (stem), so no assumption is in effect.
    local staged="$TMP_DIR/localhost_access_log.2025-05-05.txt"
    cp "$tomcat" "$staged"
    local out_named
    out_named=$(run_format_detection "$staged")
    check_capture_warnings "$out_named"

    assert_absent "$out_named.stderr" \
        pattern     '^Note: the detected log format' \
        asserts     'Filename stem evidence decides the variant (basis evidence), so the default-selection note is contracted ABSENT' \
        produced_by 'format_variant_ambiguity_note() in ltl (selection-basis gate)' \
        contract    'features/log-format-registry.md section Drop 1.5 I6 (ambiguity note)'
    assert_line "$out_named" \
        pattern     '^  selection_basis: evidence$' \
        asserts     'The producer-true Tomcat name selects the Tomcat member by stem evidence' \
        produced_by 'select_format_variants() in ltl' \
        contract    'features/log-format-registry.md section -V format-detection section-contract (#384 additions)'
}


# ---------- #384 variant selection (committed fixtures, D51) ----------------
# Every run uses -bs 1440 -oe: the fixtures span months (and the mixed
# fixture pairs files a year apart), and these scenarios assert detection,
# not buckets — no empty-bucket memory for a time axis nobody reads.

scenario_variant_connection_server() {
    current_scenario="variant-connection-server"
    echo "[$current_scenario]"
    local log; log=$(stage_fixture connection-server.txt cxserver.1.log) || return
    local out; out=$(run_format_detection "$log"); check_capture_warnings "$out"
    assert_variant_selection "$out" connection_server_standard mt10 evidence '1\.00'
    assert_line "$out" pattern '^  filename_evidence: stem=mt10 ext=match date=- index=present$' \
        asserts 'cxserver.1.log decomposes to the Connection Server stem, the declared extension and a rotation index (D45/I4)' \
        produced_by 'format_filename_evidence() in ltl' \
        contract 'features/log-format-registry.md section -V format-detection section-contract (#384 additions)'
    assert_line "$out" pattern '^  candidates: mt10=[0-9.]+,mt10ir=0\.00$' \
        asserts 'The Integration Runtime member is eliminated: day tokens > 12 are impossible under yyyy-dd-MM (D52 probe a)' \
        produced_by 'format_sample_probes() in ltl' \
        contract 'features/log-format-registry.md section Drop 1.5 D52'
}

scenario_variant_integration_runtime_named() {
    current_scenario="variant-integration-runtime-named"
    echo "[$current_scenario]"
    local log; log=$(stage_fixture integration-runtime.txt IntegrationRuntime-46b44bb3-cd86-44a6-a268-012144ff23af.log) || return
    local out; out=$(run_format_detection "$log"); check_capture_warnings "$out"
    assert_variant_selection "$out" integration_runtime_standard mt10ir evidence '1\.00'
    assert_line "$out" pattern '^  filename_evidence: stem=mt10ir ext=match date=- index=-$' \
        asserts 'The IntegrationRuntime-<uuid>.log name matches the Integration Runtime stem' \
        produced_by 'format_filename_evidence() in ltl' \
        contract 'features/log-format-registry.md section -V format-detection section-contract (#384 additions)'
    assert_line "$out" pattern '^  matched_lines: 124$' \
        asserts 'Every timestamped line of the slice is read under yyyy-dd-MM with no fatal (#385)' \
        produced_by 'compile_format_scan_sub() in ltl (iso_ms_ddmm block)' \
        contract 'features/log-format-registry.md section Drop 1.5 D47/N10'
    assert_absent "$out.stderr" pattern '^Note: ' \
        asserts 'No diagnostic: the layout is right and the decision was made by evidence' \
        produced_by 'format_probe_signal() / format_variant_ambiguity_note() in ltl' \
        contract 'features/log-format-registry.md section Drop 1.5 D52/I6'
}

scenario_variant_integration_runtime_unnamed() {
    current_scenario="variant-integration-runtime-unnamed"
    echo "[$current_scenario]"
    local log; log=$(stage_fixture integration-runtime.txt app.log) || return
    local out; out=$(run_format_detection "$log"); check_capture_warnings "$out"
    assert_variant_selection "$out" integration_runtime_standard mt10ir evidence '1\.00'
    assert_line "$out" pattern '^  filename_evidence: stem=- ext=- date=- index=-$' \
        asserts 'app.log carries no name evidence for any entry' \
        produced_by 'format_filename_evidence() in ltl' \
        contract 'features/log-format-registry.md section -V format-detection section-contract (#384 additions)'
    assert_line "$out" pattern '^  candidates: mt10=0\.00,mt10ir=[0-9.]+$' \
        asserts 'With no name evidence the sample alone decides: the default is eliminated by impossible months under yyyy-MM-dd (F6)' \
        produced_by 'format_sample_probes() in ltl' \
        contract 'features/log-format-registry.md section Drop 1.5 F6'
}

scenario_variant_tomcat_named() {
    current_scenario="variant-tomcat-named"
    echo "[$current_scenario]"
    local log; log=$(stage_fixture tomcat-access.txt localhost_access_log.2025-05-05.txt) || return
    local out; out=$(run_format_detection "$log"); check_capture_warnings "$out"
    assert_variant_selection "$out" tomcat_access_with_duration mt3 evidence '0\.86'
    assert_line "$out" pattern '^  filename_evidence: stem=mt3 ext=match date=present index=-$' \
        asserts 'The Tomcat name decomposes to stem, .txt and a date' \
        produced_by 'format_filename_evidence() in ltl' \
        contract 'features/log-format-registry.md section -V format-detection section-contract (#384 additions)'
    assert_absent "$out.stderr" pattern '^Note: ' \
        asserts 'Stem evidence decided the unit; no ambiguity note' \
        produced_by 'format_variant_ambiguity_note() in ltl' \
        contract 'features/log-format-registry.md section Drop 1.5 I6'
}

scenario_variant_tomcat_extension_only() {
    current_scenario="variant-tomcat-extension-only"
    echo "[$current_scenario]"
    local log; log=$(stage_fixture tomcat-access.txt whatever.log) || return
    local out; out=$(run_format_detection "$log"); check_capture_warnings "$out"
    assert_variant_selection "$out" tomcat_access_with_duration mt3 default '0\.50'
    assert_line "$out" pattern '^  candidates: mt3=2\.00,mt3us=2\.00$' \
        asserts 'An extension alone ties the group default (standing credit = extension weight) and never moves the selection off it (I1)' \
        produced_by 'select_format_variants() in ltl' \
        contract 'features/log-format-registry.md section Drop 1.5 I1'
    assert_line "$out.stderr" pattern '^Note: the detected log format \(tomcat_access_with_duration\) is written by more than one producer' \
        asserts 'A default-basis selection surfaces the assumption' \
        produced_by 'format_variant_ambiguity_note() in ltl' \
        contract 'features/log-format-registry.md section Drop 1.5 I6'
}

scenario_variant_httpd_named() {
    current_scenario="variant-httpd-named"
    echo "[$current_scenario]"
    local log; log=$(stage_fixture httpd-access.txt access.log-20260609) || return
    local out; out=$(run_format_detection "$log"); check_capture_warnings "$out"
    assert_variant_selection "$out" httpd_access_with_duration mt3us evidence '0\.71'
    assert_line "$out" pattern '^  filename_evidence: stem=mt3us ext=match date=present index=-$' \
        asserts 'access.log-20260609 decomposes under after-placement: stem, .log, then the compact date' \
        produced_by 'format_filename_evidence() in ltl' \
        contract 'features/log-format-registry.md section Drop 1.5 D45/I4'
    assert_absent "$out.stderr" pattern '^Note: ' \
        asserts 'Evidence decided the microsecond member; no -du needed and no note' \
        produced_by 'format_variant_ambiguity_note() in ltl' \
        contract 'features/log-format-registry.md section Drop 1.5 I6'
    # The microsecond unit is applied: a -du us run must render identically.
    local out_du; out_du=$(run_format_detection "$log" -du us); check_capture_warnings "$out_du"
    assert_command label "httpd member carries microseconds (output identical to -du us)" \
        command "diff <(grep -av '^duration_unit_override' '$out') <(grep -av '^duration_unit_override' '$out_du') > /dev/null" \
        asserts 'The httpd member declares %D in microseconds, so the evidence-selected run equals the explicit -du us run' \
        produced_by 'read_and_process_logs() in ltl (FR_DURATION_UNIT conversion)' \
        contract 'features/log-format-registry.md section Drop 1.5 D47 (first variant groups)'
}

scenario_variant_httpd_renamed() {
    current_scenario="variant-httpd-renamed"
    echo "[$current_scenario]"
    local log; log=$(stage_fixture httpd-access.txt renamed.txt) || return
    local out; out=$(run_format_detection "$log"); check_capture_warnings "$out"
    assert_variant_selection "$out" tomcat_access_with_duration mt3 default '0\.75'
    assert_line "$out.stderr" pattern '^Note: the detected log format \(tomcat_access_with_duration\) is written by more than one producer' \
        asserts 'A renamed httpd file falls to the default with the note (D44: visible-or-good-enough)' \
        produced_by 'format_variant_ambiguity_note() in ltl' \
        contract 'features/log-format-registry.md section Drop 1.5 D44/I6'
}

scenario_variant_thingworx_rolled() {
    current_scenario="variant-thingworx-rolled"
    echo "[$current_scenario]"
    local log; log=$(stage_fixture thingworx-application-log.txt ApplicationLog.2025-05-06.0.log) || return
    local out; out=$(run_format_detection "$log"); check_capture_warnings "$out"
    assert_line "$out" pattern '^  filename_evidence: stem=mt1std ext=match date=match index=present$' \
        asserts 'A logback-rolled ThingWorx name decomposes to stem, date, index and extension, and the filename date agrees with the first content timestamp (D52 probe c)' \
        produced_by 'format_filename_evidence() / format_sample_probes() in ltl' \
        contract 'features/log-format-registry.md section Drop 1.5 D45/D52'
    assert_line "$out" pattern '^  format: thingworx_standard$' \
        asserts 'A format outside any variant group is unaffected by selection' \
        produced_by 'read_and_process_logs() in ltl' \
        contract 'features/log-format-registry.md section -V format-detection section-contract'
}

# Windchill method-server fixture: 21 log4j records and 30 continuation
# lines (tab-indented frames, `Nested exception is:` / `Caused by:`,
# property-dump and blank lines). `-bs 1440 -oe`: detection assertions
# only; the fixture spans one day.
assert_windchill_fixture_detection() {
    local out="$1"
    assert_line "$out" pattern '^  format: windchill_method_server$' \
        asserts 'The log4j method-server layout binds the windchill_method_server format' \
        produced_by 'read_and_process_logs() in ltl (first-match block); registry entry mt17 in format_registry_specs()' \
        contract 'features/396-windchill-method-server-log4j-format.md section Format contract; %match_type_to_slug in ltl'
    assert_line "$out" pattern '^  match_type: 17$' \
        asserts 'windchill_method_server binds to internal match_type 17' \
        produced_by 'emit_format_detection_verbose() in ltl (per-file match_type field)' \
        contract 'features/log-format-registry.md section -V format-detection section-contract'
    assert_line "$out" pattern '^  matched_lines: 21$' \
        asserts 'Every timestamped record of the fixture matches, including the nested-bracket thread name and the empty NDC (user) slot' \
        produced_by 'emit_format_detection_verbose() in ltl (per-file matched_lines field)' \
        contract 'features/396-windchill-method-server-log4j-format.md section Format contract (thread and user slots)'
    assert_line "$out" pattern '^  unmatched_lines: 30$' \
        asserts 'Continuation lines (stack-trace frames, Nested exception is:, Caused by:, property dumps, blank lines) carry no timestamp and match no entry' \
        produced_by 'read_and_process_logs() in ltl (no-match branch)' \
        contract 'features/396-windchill-method-server-log4j-format.md section Format contract (continuation lines)'
}

scenario_windchill_method_server_named() {
    current_scenario="windchill-method-server-named"
    echo "[$current_scenario]"
    local log; log=$(stage_fixture windchill-method-server.txt BackgroundMethodServerESI-2507180624-9559-log4j.log) || return
    local out; out=$(run_format_detection "$log"); check_capture_warnings "$out"
    assert_windchill_fixture_detection "$out"
    assert_line "$out" pattern '^  filename_evidence: stem=mt17 ext=match date=- index=-$' \
        asserts 'A producer-true method-server name (service stem, start-time and pid tokens, -log4j, .log) decomposes to the mt17 stem and a matching extension; an unrolled file carries no date or index' \
        produced_by 'format_filename_evidence() / compile_format_filename_matcher() in ltl' \
        contract 'features/396-windchill-method-server-log4j-format.md section Filename evidence (D54/D55)'
    assert_line "$out" pattern '^  formats: windchill_method_server$' \
        asserts 'The file reports exactly one format in its bracket' \
        produced_by 'read_and_process_logs() in ltl (N7 snapshot); emit_format_detection_evidence_verbose()' \
        contract 'features/log-format-registry.md section -V format-detection section-contract (#384 additions)'
}

scenario_windchill_method_server_rolled() {
    current_scenario="windchill-method-server-rolled"
    echo "[$current_scenario]"
    local log; log=$(stage_fixture windchill-method-server.txt MethodServer-2507180627-9144-log4j.log.2025-07-18_3) || return
    local out; out=$(run_format_detection "$log"); check_capture_warnings "$out"
    assert_windchill_fixture_detection "$out"
    assert_line "$out" pattern '^  filename_evidence: stem=mt17 ext=match date=match index=present$' \
        asserts 'A log4j daily-rolled name (.YYYY-MM-DD_N after the extension) decomposes through the date_n index form, and the roll date agrees with the first content timestamp (D52 probe c)' \
        produced_by 'format_filename_decompose() / format_sample_probes() in ltl (date_n in %format_filename_index_re)' \
        contract 'features/396-windchill-method-server-log4j-format.md section Filename evidence (D55)'
}

scenario_windchill_method_server_bare() {
    current_scenario="windchill-method-server-bare"
    echo "[$current_scenario]"
    local log; log=$(stage_fixture windchill-method-server.txt MethodServer.log) || return
    local out; out=$(run_format_detection "$log"); check_capture_warnings "$out"
    assert_windchill_fixture_detection "$out"
    assert_line "$out" pattern '^  filename_evidence: stem=mt17 ext=match date=- index=-$' \
        asserts 'A bare service name (no start-time/pid/-log4j tail) still earns mt16 stem evidence and a matching extension: the stem alone matches, the producer tail is optional' \
        produced_by 'format_filename_evidence() / compile_format_filename_matcher() in ltl' \
        contract 'features/396-windchill-method-server-log4j-format.md section Filename evidence (D57, architect-locked 2026-08-23)'
}

scenario_windchill_method_server_renamed() {
    current_scenario="windchill-method-server-renamed"
    echo "[$current_scenario]"
    local log; log=$(stage_fixture windchill-method-server.txt app.txt) || return
    local out; out=$(run_format_detection "$log"); check_capture_warnings "$out"
    assert_windchill_fixture_detection "$out"
    assert_line "$out" pattern '^  filename_evidence: stem=- ext=- date=- index=-$' \
        asserts 'A renamed file yields no filename evidence; recognition is decided by content alone' \
        produced_by 'format_filename_evidence() in ltl' \
        contract 'features/log-format-registry.md section Drop 1.5 D44/D45 (a missing name signal withholds, never contradicts)'
}

scenario_variant_mixed_legend() {
    current_scenario="variant-mixed-legend"
    echo "[$current_scenario]"
    local log; log=$(stage_fixture mixed.txt mixed.log) || return
    local out; out=$(run_format_detection "$log"); check_capture_warnings "$out"
    assert_line "$out" pattern '^  formats: connection_server_standard,tomcat_access_with_duration$' \
        asserts 'Every format found in the file is listed, first-bound first' \
        produced_by 'read_and_process_logs() in ltl (per-file formats, N7)' \
        contract 'features/log-format-registry.md section -V format-detection section-contract (#384 additions)'
    assert_line "$out" pattern '^legend: 1=connection_server_standard,2=tomcat_access_with_duration$' \
        asserts 'The legend numbers formats in first-detection order across the run (I8)' \
        produced_by 'emit_format_detection_verbose() in ltl' \
        contract 'features/log-format-registry.md section -V format-detection section-contract (#384 additions)'
    local render="$TMP_DIR/$current_scenario/render.out"
    "$LTL" --disable-progress -ni --terminal-width 160 -bs 1440 -oe "$log" > "$render" 2> "$render.stderr"
    assert_no_runtime_warnings "$render.stderr" "$current_scenario render"
    assert_command label "console bracket [1,2] after the file name" \
        command "perl -pe 's/\\e\\[[0-9;]*[a-zA-Z]//g' '$render' | grep -q 'mixed.log  *\\[1,2\\]'" \
        asserts 'The summary file list carries the formats found as legend numbers in brackets (D50)' \
        produced_by 'print_summary_table() in ltl' \
        contract 'features/log-format-registry.md section Drop 1.5 D50'
    assert_command label "console legend title" \
        command "perl -pe 's/\\e\\[[0-9;]*[a-zA-Z]//g' '$render' | grep -q '  Log Formats *\$'" \
        asserts 'The legend is introduced by a "Log Formats" title, rendered like the file-list heading (D50)' \
        produced_by 'print_summary_table() in ltl' \
        contract 'features/log-format-registry.md section Drop 1.5 D50'
    assert_command label "console legend line" \
        command "perl -pe 's/\\e\\[[0-9;]*[a-zA-Z]//g' '$render' | grep -q '  1 connection_server_standard  2 tomcat_access_with_duration *\$'" \
        asserts 'One legend line below the title names the numbered formats (D50)' \
        produced_by 'print_summary_table() in ltl' \
        contract 'features/log-format-registry.md section Drop 1.5 D50'
}

# Windchill Workgroup Manager client log (issue #395). The fixture is a
# scrubbed uwgm_client.log.1 slice: the self-describing header block plus
# data lines covering every msgtype letter, #-qualified areas and a
# bracketed message (the mt2 cross-shadow case). `-bs 1440 -oe -n 1 -osum`
# via run_format_detection: every assertion reads -V format-detection or
# the benchmark-data line counts; the 8-second span never reads a bucket.
scenario_windchill_workgroup_manager() {
    current_scenario="wgm-client"
    echo "[$current_scenario]"
    local log; log=$(stage_fixture wgm-client.txt uwgm_client.log.1) || return
    local out; out=$(run_format_detection "$log" -V benchmark-data); check_capture_warnings "$out"
    assert_line "$out" pattern '^  format: windchill_workgroup_manager$' \
        asserts 'A WGM client log binds the windchill_workgroup_manager format' \
        produced_by 'read_and_process_logs() in ltl (first-match block); emitted by emit_format_detection_verbose()' \
        contract '%match_type_to_slug in ltl GLOBALS - slug names are locked; renames are breaking under HARNESS-DESIGN.md section Stability contract'
    assert_line "$out" pattern '^  match_type: 16$' \
        asserts 'Slug windchill_workgroup_manager binds to internal match_type 16' \
        produced_by 'emit_format_detection_verbose() in ltl (per-file match_type field)' \
        contract 'features/log-format-registry.md section -V format-detection section-contract - match_type integers are diagnostic; the slug is the user-facing contract'
    assert_line "$out" pattern '^  matched_lines: 44$' \
        asserts 'Every line of the fixture - header block and data lines alike - matches the mt16 pattern (no fallthroughs)' \
        produced_by 'emit_format_detection_verbose() in ltl (per-file matched_lines field)' \
        contract 'features/395-wgm-client-log-format.md section Format contract; the fixture and this count change in the same commit'
    assert_line "$out" pattern '^  unmatched_lines: 0$' \
        asserts 'No WGM line falls through the scan' \
        produced_by 'emit_format_detection_verbose() in ltl (per-file unmatched_lines field)' \
        contract 'features/395-wgm-client-log-format.md section Format contract'
    assert_line "$out" pattern $'^lines_included\t44$' \
        asserts 'Every matched line survives the category-vocabulary gate: the wgm_msgtype transform maps each msgtype letter to a member of @log_levels (a raw letter would be dropped silently)' \
        produced_by 'wgm_msgtype transform in %format_transform_code, spliced by format_entry_block_src(); the gate and $total_lines_included in read_and_process_logs(); emitted by the benchmark-data section' \
        contract 'features/395-wgm-client-log-format.md section D54 (msgtype mapping); @log_levels in ltl GLOBALS'
    assert_line "$out" pattern '^  filename_evidence: stem=mt16 ext=match date=- index=present$' \
        asserts 'uwgm_client.log.1 decomposes as stem uwgm_client + .log + rotation index (placement after; no date declared)' \
        produced_by 'format_filename_decompose() in ltl; emitted by emit_format_detection_evidence_verbose()' \
        contract 'features/log-format-registry.md section -V format-detection section-contract (#384 additions); features/395-wgm-client-log-format.md section D55 (filename family)'
    assert_line "$out" pattern '^  sample_whole_file: yes$' \
        asserts 'A file no larger than sample_parts x sample_bytes_per_part is read once, whole, as a single part' \
        produced_by 'sample_file_for_detection() in ltl; emitted by emit_format_detection_sample_verbose()' \
        contract 'features/log-format-registry.md section -V format-detection section-contract (detection-evidence keys, umbrella D53)'
    assert_line "$out" pattern '^  sample_formats: mt16=44$' \
        asserts 'The evidence sample recognises every fixture line as mt16 in static cascade order - no earlier entry (mt1std, connection_server) accepts the WGM shape' \
        produced_by 'sample_file_for_detection() in ltl (direct pattern recognition, static cascade order)' \
        contract 'features/log-format-registry.md section -V format-detection section-contract (detection-evidence keys, umbrella D53)'
    assert_line "$out" pattern '^final_order: mt16,' \
        asserts 'After the run mt16 (no pinned ancestors) leads the MTF scan order' \
        produced_by 'format_registry_promote() in ltl; emitted by emit_format_detection_verbose()' \
        contract 'features/log-format-registry.md section -V format-detection section-contract (D26 pinned-closure MTF)'
}

# The three WGM filenames share one entry (a group of one, D55): each stem
# decomposes to mt16, `uwgm` is not consumed as a prefix of `uwgm_client`,
# and a renamed file still binds by shape with the stem signal withheld.
scenario_wgm_filename_family() {
    current_scenario="wgm-filename-family"
    echo "[$current_scenario]"
    local name log out
    for name in genlwsc.log.1 uwgm.log.1; do
        log=$(stage_fixture wgm-client.txt "$name") || return
        out=$(run_format_detection "$log"); check_capture_warnings "$out"
        assert_line "$out" pattern '^  filename_evidence: stem=mt16 ext=match date=- index=present$' \
            asserts "$name decomposes to the windchill_workgroup_manager entry's stem, extension and rotation index" \
            produced_by 'format_filename_decompose() in ltl; emitted by emit_format_detection_evidence_verbose()' \
            contract 'features/395-wgm-client-log-format.md section D55 (filename family)'
        assert_line "$out" pattern '^  format: windchill_workgroup_manager$' \
            asserts "$name binds the windchill_workgroup_manager format" \
            produced_by 'read_and_process_logs() in ltl (first-match block)' \
            contract 'features/log-format-registry.md section -V format-detection section-contract'
    done
    log=$(stage_fixture wgm-client.txt renamed.txt) || return
    out=$(run_format_detection "$log"); check_capture_warnings "$out"
    assert_line "$out" pattern '^  filename_evidence: stem=- ext=- date=- index=-$' \
        asserts 'A renamed WGM file matches no declared stem: the name signal is withheld, never contradicting (D45)' \
        produced_by 'format_filename_decompose() in ltl; emitted by emit_format_detection_evidence_verbose()' \
        contract 'features/log-format-registry.md section Drop 1.5 D45'
    assert_line "$out" pattern '^  format: windchill_workgroup_manager$' \
        asserts 'A group of one binds by line shape alone; filename evidence only reports' \
        produced_by 'read_and_process_logs() in ltl (first-match block)' \
        contract 'features/395-wgm-client-log-format.md section D55 (filename family)'
}

scenario_format_pin() {
    current_scenario="format-pin"
    echo "[$current_scenario]"
    local log; log=$(stage_fixture integration-runtime.txt IntegrationRuntime-46b44bb3-cd86-44a6-a268-012144ff23af.log) || return
    local out; out=$(run_format_detection "$log" -lf connection_server_standard); check_capture_warnings "$out"
    assert_line "$out" pattern '^format_pin: connection_server_standard$' \
        asserts 'The run-level pin is reported' \
        produced_by 'emit_format_detection_verbose() in ltl' \
        contract 'features/log-format-registry.md section -V format-detection section-contract (#384 additions)'
    assert_line "$out" pattern '^  format: connection_server_standard$' \
        asserts 'The pin outranks stem evidence and the probes (D49): the file reads as the pinned format' \
        produced_by 'apply_format_pin() in ltl' \
        contract 'features/log-format-registry.md section Drop 1.5 D49/N9'
    assert_line "$out" pattern '^  selection_basis: pin$' \
        asserts 'Selection basis is pin under -lf' \
        produced_by 'emit_format_detection_evidence_verbose() in ltl' \
        contract 'features/log-format-registry.md section -V format-detection section-contract (#384 additions)'
    assert_line "$out" pattern '^entries: 1$' \
        asserts 'The scan is restricted to the entries carrying the pinned name' \
        produced_by 'apply_format_pin() in ltl' \
        contract 'features/log-format-registry.md section Drop 1.5 N9'
    assert_line "$out.stderr" pattern "^Note: .*line [0-9]+: timestamp '[0-9 :-]+' has an impossible date component under the connection_server_standard format's date layout; such lines are kept at the previous line's time - use -lf to pin the correct log format\$" \
        asserts 'An impossible date under the pinned layout is reported once per file (D52/#385) and never crashes' \
        produced_by 'format_probe_signal() in ltl' \
        contract 'features/log-format-registry.md section Drop 1.5 D52'
    local out2; out2=$(run_format_detection "$log" -lf thingworx_standard); check_capture_warnings "$out2"
    assert_line "$out2" pattern '^entries: 2$' \
        asserts 'A name carried by two registry entries pins both (N9)' \
        produced_by 'apply_format_pin() in ltl' \
        contract 'features/log-format-registry.md section Drop 1.5 N9'
    local err="$TMP_DIR/$current_scenario/unknown.stderr"
    if "$LTL" --disable-progress -ni -bs 1440 -oe -lf nonsense "$log" > /dev/null 2> "$err"; then
        echo "  FAIL  $current_scenario :: -lf nonsense exited 0"; fail=$((fail + 1)); failures+=("$current_scenario :: -lf nonsense exited 0")
    else
        assert_line "$err" pattern '^Error: Unknown log format .nonsense. for -lf\. Known formats: .*connection_server_standard.*integration_runtime_standard.*tomcat_access_with_duration' \
            asserts 'An unknown pin name is a usage error listing the known format names (D49)' \
            produced_by 'apply_format_pin() in ltl' \
            contract 'features/log-format-registry.md section Drop 1.5 D49'
    fi
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
scenario_windchill_method_server; echo ""
scenario_scan_telemetry;        echo ""
scenario_scan_telemetry_nomatch; echo ""
scenario_unit_ambiguity_warning; echo ""
scenario_variant_connection_server; echo ""
scenario_variant_integration_runtime_named; echo ""
scenario_variant_integration_runtime_unnamed; echo ""
scenario_variant_tomcat_named; echo ""
scenario_variant_tomcat_extension_only; echo ""
scenario_variant_httpd_named; echo ""
scenario_variant_httpd_renamed; echo ""
scenario_variant_thingworx_rolled; echo ""
scenario_windchill_method_server_named; echo ""
scenario_windchill_method_server_rolled; echo ""
scenario_windchill_method_server_bare; echo ""
scenario_windchill_method_server_renamed; echo ""
scenario_variant_mixed_legend; echo ""
scenario_windchill_workgroup_manager; echo ""
scenario_wgm_filename_family;   echo ""
scenario_format_pin

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
