#!/usr/bin/env bash
# validate-statistics-demand.sh — Validate the statistics-demand `-V` section:
# per-store statistics-group demand resolution with raising consumers, the
# per-store moment source, and the per-store statistics-calculation counters
# (stats_calls invocations plus per-group computed/skipped_demand/ineligible)
# (Issues #305, #303).
# Usage: ./tests/validate-statistics-demand.sh
#
# Follows the self-documenting assertion design from tests/HARNESS-DESIGN.md
# (reference implementation: tests/validate-histogram-bin-counters.sh).
# Every assertion records:
#   - asserts:     the application invariant being tested
#   - produced_by: where in ltl the invariant is produced (function name)
#   - contract:    the stability contract that makes it stable
# All three are surfaced on failure.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
ACCESS_LOG="$REPO_DIR/logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt"

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"
    exit 1
fi
if [[ ! -f "$ACCESS_LOG" ]]; then
    echo "ERROR: ACCESS_LOG not found: $ACCESS_LOG"
    exit 1
fi

# Scenario 2 passes -o, which writes CSV artifacts into the CWD; run every
# scenario inside a scratch workdir so no artifacts land in the repo.
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
cd "$WORKDIR"

CONTRACT='features/duration-statistics.md § -V statistics-demand section contract — stability-contracted; renames are breaking'

pass=0
fail=0
failures=()
current_scenario=""

# Run ltl with the requested -V section(s) and the standard suppression flag.
# Captures stdout to a temp file (path echoed); stderr lands beside it.
# Args after the function name are forwarded verbatim before the input file.
run_section() {
    local sections="$1"; shift
    local outfile
    outfile=$(mktemp)
    "$LTL" --disable-progress --terminal-width 200 -V "$sections" "$@" "$ACCESS_LOG" > "$outfile" 2>"$outfile.stderr" || true
    echo "$outfile"
}

# Runtime-warning cleanliness for a run_section capture (stderr lives beside
# the captured stdout as <capture>.stderr). Runs in the main shell so the
# fail counters persist. HARNESS-DESIGN.md § Runtime-warning cleanliness.
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

# Self-documenting assertion for anything beyond a single-line grep.
# `command` is eval'd (PASS if exit 0); `label` names it on the PASS line.
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

    if eval "$command" >/dev/null 2>&1; then
        echo "  PASS  $current_scenario :: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        command:     $command"
        echo "        label:       $label"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
        failures+=("$current_scenario :: $label")
    fi
}

# Extract the statistics-demand section body; hard-fail (per HARNESS-DESIGN
# "must fail on missing anchors") if the start or end marker is absent.
extract_section() {
    local outfile="$1"
    local body="$outfile.section"
    if ! grep -q '^=== statistics-demand ===$' "$outfile" \
       || ! grep -q '^=== END statistics-demand ===$' "$outfile"; then
        echo "  FAIL  $current_scenario"
        echo "        pattern:     === statistics-demand === ... === END statistics-demand ==="
        echo "        asserts:     The statistics-demand section is emitted with both start and end markers when requested via -V"
        echo "        produced_by: emit_statistics_demand_verbose() in ltl"
        echo "        contract:    $CONTRACT"
        echo "        (anchor not found in $outfile)"
        fail=$((fail + 1))
        failures+=("$current_scenario :: section-anchor-missing")
        return 1
    fi
    sed -n '/^=== statistics-demand ===$/,/^=== END statistics-demand ===$/p' "$outfile" > "$body"
    echo "$body"
}

# Extract the per-store sub-block (lines from `store: <name>` up to the next
# `store:` or the section end marker) so per-store assertions cannot match
# the other store's lines.
extract_store() {
    local body="$1" store="$2"
    local out="$body.$store"
    awk -v store="$store" '
        $0 == "store: " store { inside=1; print; next }
        inside && (/^store: / || /^=== END /) { inside=0 }
        inside { print }
    ' "$body" > "$out"
    echo "$out"
}

echo "=== validate-statistics-demand: statistics-demand -V section (Issue #305) ==="
echo "fixture: $ACCESS_LOG"
echo

############################################################
current_scenario="scenario-1-terminal-only-default"
echo "--- $current_scenario ---"
out=$(run_section statistics-demand)
check_capture_warnings "$out"
if body=$(extract_section "$out"); then
    for store in bucket message; do
        sb=$(extract_store "$body" "$store")
        assert_line "$sb" \
            pattern     '^  store_demand: 1$' \
            asserts     "On a default terminal run the $store store is demanded (its terminal surface is active)" \
            produced_by 'resolve_statistics_group_demand() in ltl (store-level booleans from adapt_to_command_line_options)' \
            contract    "$CONTRACT"
        assert_line "$sb" \
            pattern     '^  group terminal_core: demanded=1 consumers=' \
            asserts     "terminal_core is demanded on the $store store whenever the store is (every store-activating consumer declares it)" \
            produced_by 'resolve_statistics_group_demand() in ltl' \
            contract    "$CONTRACT"
        for group in csv_body extended_percentiles shape_moments; do
            assert_line "$sb" \
                pattern     "^  group $group: demanded=0 consumers=-\$" \
                asserts     "On a terminal-only run no consumer raises $group demand on the $store store (terminal surfaces read only terminal_core fields)" \
                produced_by 'resolve_statistics_group_demand() in ltl' \
                contract    "$CONTRACT"
        done
        assert_line "$sb" \
            pattern     '^  moment_source: none$' \
            asserts     "With shape_moments undemanded the $store store reports moment_source none" \
            produced_by 'emit_statistics_demand_verbose() in ltl' \
            contract    "$CONTRACT"
        assert_line "$sb" \
            pattern     '^  stats_calls: [1-9][0-9]*$' \
            asserts     "The $store store reports a non-zero count of statistics-primitive invocations on a demanded store (every call is counted, including no-duration early returns)" \
            produced_by 'calculate_statistics() / calculate_statistics_bin() in ltl (stats_calls in %stats_demand_telemetry)' \
            contract    "$CONTRACT"
        assert_line "$sb" \
            pattern     '^  group_calc terminal_core: computed=[1-9][0-9]* skipped_demand=0 ineligible=0$' \
            asserts     "terminal_core is derived on every non-early-returned invocation of the $store store's statistics primitive (never demand-skipped: terminal_core demand equals store demand)" \
            produced_by 'calculate_statistics() / calculate_statistics_bin() in ltl (group_calc counters)' \
            contract    "$CONTRACT"
        assert_line "$sb" \
            pattern     '^  group_calc shape_moments: computed=0 skipped_demand=[0-9]+ ineligible=[0-9]+$' \
            asserts     "On a terminal-only run the $store store's shape-moment derivation never runs — eligible (n>=4) calls are demand-skipped and n<4 calls are counted ineligible, so every invocation is accounted for" \
            produced_by 'calculate_statistics() / calculate_statistics_bin() in ltl (group_calc counters)' \
            contract    "$CONTRACT"
    done
    sm=$(extract_store "$body" message)
    assert_line "$sm" \
        pattern     '^  group_calc shape_moments: computed=0 skipped_demand=[1-9][0-9]* ineligible=[0-9]+$' \
        asserts     'On a terminal-only run the message store demand-skips the shape derivation for every eligible key — the observable proof that demand gating fires' \
        produced_by 'calculate_statistics() in ltl (group_calc counters in %stats_demand_telemetry)' \
        contract    "$CONTRACT"
fi
echo

############################################################
current_scenario="scenario-2-csv-full-demand"
echo "--- $current_scenario ---"
out=$(run_section statistics-demand -o)
check_capture_warnings "$out"
if body=$(extract_section "$out"); then
    sb=$(extract_store "$body" bucket)
    assert_line "$sb" \
        pattern     '^  group shape_moments: demanded=1 consumers=.*stats-csv' \
        asserts     'With -o active the STATS CSV raises shape_moments demand on the bucket store' \
        produced_by 'resolve_statistics_group_demand() in ltl (@STAT_CONSUMERS stats-csv declaration)' \
        contract    "$CONTRACT"
    assert_line "$sb" \
        pattern     '^  group extended_percentiles: demanded=1 consumers=.*stats-csv' \
        asserts     'With -o active the STATS CSV raises extended_percentiles demand on the bucket store' \
        produced_by 'resolve_statistics_group_demand() in ltl' \
        contract    "$CONTRACT"
    sm=$(extract_store "$body" message)
    assert_line "$sm" \
        pattern     '^  group shape_moments: demanded=1 consumers=.*messages-csv' \
        asserts     'With -o active the MESSAGES CSV raises shape_moments demand on the message store' \
        produced_by 'resolve_statistics_group_demand() in ltl (@STAT_CONSUMERS messages-csv declaration)' \
        contract    "$CONTRACT"
    assert_line "$sm" \
        pattern     '^  moment_source: second_pass$' \
        asserts     'Under the default raw data model with shape demanded, the message store reports moment_source second_pass' \
        produced_by 'emit_statistics_demand_verbose() in ltl' \
        contract    "$CONTRACT"
    assert_line "$sm" \
        pattern     '^  group_calc shape_moments: computed=[1-9][0-9]* skipped_demand=0 ineligible=[0-9]+$' \
        asserts     'With every group demanded the message store derives shape moments for every eligible key and demand-skips nothing — output parity with the pre-gating behavior' \
        produced_by 'calculate_statistics() in ltl (group_calc counters)' \
        contract    "$CONTRACT"
    assert_command \
        command     "calls=\$(awk '/^  stats_calls: /{print \$2; exit}' '$sm'); tc=\$(grep -oE '^  group_calc terminal_core: computed=[0-9]+' '$sm' | grep -oE '[0-9]+\$'); [[ -n \"\$calls\" && -n \"\$tc\" && \"\$calls\" -ge \"\$tc\" ]]" \
        label       'message stats_calls >= terminal_core computed (early-returned calls are counted as invocations)' \
        asserts     'stats_calls counts every statistics-primitive invocation, so it is always >= the terminal_core computed count (the difference is the early-returned no-duration calls)' \
        produced_by 'calculate_statistics() / calculate_statistics_bin() in ltl (stats_calls vs group_calc counters)' \
        contract    "$CONTRACT"
fi
echo

############################################################
current_scenario="scenario-3-sort-on-skewness"
echo "--- $current_scenario ---"
out=$(run_section statistics-demand -so skewness)
check_capture_warnings "$out"
if body=$(extract_section "$out"); then
    sm=$(extract_store "$body" message)
    assert_line "$sm" \
        pattern     '^  group shape_moments: demanded=1 consumers=sort-on:skewness$' \
        asserts     'Sorting on a statistic makes -so an explicit demand contributor: -so skewness raises shape_moments demand on the message store with sort-on:<field> provenance' \
        produced_by 'resolve_statistics_group_demand() in ltl (@STAT_CONSUMERS sort-on declaration)' \
        contract    "$CONTRACT"
    sb=$(extract_store "$body" bucket)
    assert_line "$sb" \
        pattern     '^  group shape_moments: demanded=0 consumers=-$' \
        asserts     'A message-store sort key raises no demand on the bucket store' \
        produced_by 'resolve_statistics_group_demand() in ltl' \
        contract    "$CONTRACT"
    assert_line "$sm" \
        pattern     '^  moment_source: second_pass$' \
        asserts     'The message store computes shape moments (via the raw second pass) when demanded by the sort key alone' \
        produced_by 'emit_statistics_demand_verbose() in ltl' \
        contract    "$CONTRACT"
    assert_line "$sm" \
        pattern     '^  group_calc shape_moments: computed=[1-9][0-9]* skipped_demand=0 ineligible=[0-9]+$' \
        asserts     'A statistic sort computes the sort statistic for the entire eligible key population — the population-wide cost #303 targets, measured by stats_calls and the per-group computed counts' \
        produced_by 'calculate_statistics() in ltl (group_calc counters; all-keys path in calculate_all_statistics)' \
        contract    "$CONTRACT"
fi
echo

############################################################
current_scenario="scenario-4-heatmap-no-bucket-demand"
echo "--- $current_scenario ---"
out=$(run_section statistics-demand -hm duration)
check_capture_warnings "$out"
if body=$(extract_section "$out"); then
    sb=$(extract_store "$body" bucket)
    assert_line "$sb" \
        pattern     '^  store_demand: 0$' \
        asserts     'With the heatmap replacing the timeline latency column and no CSV active, the bucket store has no consumer and store demand is 0' \
        produced_by 'adapt_to_command_line_options() in ltl (store-level demand resolution, #349)' \
        contract    "$CONTRACT"
    for group in terminal_core csv_body extended_percentiles shape_moments; do
        assert_line "$sb" \
            pattern     "^  group $group: demanded=0 consumers=-\$" \
            asserts     "With the bucket store undemanded no group can be demanded on it ($group)" \
            produced_by 'resolve_statistics_group_demand() in ltl (store-level demand is a precondition for every consumer)' \
            contract    "$CONTRACT"
    done
    sm=$(extract_store "$body" message)
    assert_line "$sm" \
        pattern     '^  store_demand: 1$' \
        asserts     'The heatmap does not suppress the message store: the messages table remains active' \
        produced_by 'adapt_to_command_line_options() in ltl (store-level demand resolution, #349)' \
        contract    "$CONTRACT"
fi
echo

############################################################
current_scenario="scenario-5-runtime-config-crosscheck"
echo "--- $current_scenario ---"
out=$(run_section statistics-demand,runtime-config)
check_capture_warnings "$out"
if body=$(extract_section "$out"); then
    assert_command \
        command     "bd=\$(grep -oE 'bucket-duration-stats-demand: [01]' '$out' | grep -oE '[01]\$'); sd=\$(awk '/^store: bucket\$/{f=1;next} f&&/store_demand:/{print \$2; exit}' '$body'); [[ -n \"\$bd\" && \"\$bd\" == \"\$sd\" ]]" \
        label       'bucket store_demand agrees with runtime-config bucket-duration-stats-demand' \
        asserts     'The statistics-demand store_demand line and the runtime-config bucket-duration-stats-demand boolean report the same resolved value (single resolution surface)' \
        produced_by 'emit_statistics_demand_verbose() and emit_runtime_config_verbose() in ltl, both reading $bucket_duration_stats_demand' \
        contract    "$CONTRACT"
    assert_command \
        command     "md=\$(grep -oE 'message-duration-stats-demand: [01]' '$out' | grep -oE '[01]\$'); sd=\$(awk '/^store: message\$/{f=1;next} f&&/store_demand:/{print \$2; exit}' '$body'); [[ -n \"\$md\" && \"\$md\" == \"\$sd\" ]]" \
        label       'message store_demand agrees with runtime-config message-duration-stats-demand' \
        asserts     'The statistics-demand store_demand line and the runtime-config message-duration-stats-demand boolean report the same resolved value (single resolution surface)' \
        produced_by 'emit_statistics_demand_verbose() and emit_runtime_config_verbose() in ltl, both reading $message_duration_stats_demand' \
        contract    "$CONTRACT"
fi
echo

############################################################
echo "=== validate-statistics-demand: $pass passed, $fail failed ==="
if [[ $fail -gt 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do echo "  - $f"; done
    exit 1
fi
exit 0
