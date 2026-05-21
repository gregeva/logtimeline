#!/usr/bin/env bash
# validate-histogram-bin-counters.sh — Validate the histogram-bin-counters `-V`
# section emits the locked Decision 8 contract surface (Issues #187, #189).
# Usage: ./tests/validate-histogram-bin-counters.sh
#
# Reference implementation of the self-documenting assertion design from
# tests/HARNESS-DESIGN.md. Every assertion records:
#   - asserts:     the application invariant being tested
#   - produced_by: where in ltl the invariant is produced (function name)
#   - contract:    the stability contract that makes it stable
# All three are surfaced on failure so the reader can act without
# opening external docs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"
ACCESS_LOG="$REPO_DIR/logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt"

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"
    exit 1
fi
if [[ ! -f "$ACCESS_LOG" ]]; then
    echo "ERROR: ACCESS_LOG not found: $ACCESS_LOG"
    exit 1
fi

pass=0
fail=0
failures=()
current_scenario=""

# Run ltl with -V histogram-bin-counters and the standard suppression flag.
# Captures combined output to a temp file, echoes the path.
# Args after the function name are forwarded verbatim before the input file.
run_section() {
    local outfile
    outfile=$(mktemp)
    "$LTL" --disable-progress -V histogram-bin-counters "$@" "$ACCESS_LOG" > "$outfile" 2>&1 || true
    echo "$outfile"
}

# Self-documenting assertion: a line matching `pattern` must be present.
# Required named fields: pattern, asserts, produced_by, contract.
# On failure, all four are surfaced alongside the captured output path.
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

# Self-documenting assertion: no line matching `pattern` may be present.
# Same field requirements as assert_line.
assert_no_line() {
    local outfile="$1"
    shift
    local pattern asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            pattern)     pattern="$2";     shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_no_line: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${pattern:?assert_no_line requires pattern}"
    : "${asserts:?assert_no_line requires asserts}"
    : "${produced_by:?assert_no_line requires produced_by}"
    : "${contract:?assert_no_line requires contract}"

    if grep -qE "$pattern" "$outfile"; then
        echo "  FAIL  $current_scenario"
        echo "        pattern:     !$pattern (unexpectedly present)"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
        failures+=("$current_scenario :: !$pattern (unexpectedly present)")
    else
        echo "  PASS  $current_scenario :: !$pattern"
        pass=$((pass + 1))
    fi
}

# Common assertion shared by every scenario: the section header must be
# present. Per HARNESS-DESIGN.md "harnesses must fail on missing anchors",
# this guard ensures a renamed section header produces a visible failure
# rather than zero matches across the scenario's other assertions.
assert_header_present() {
    local outfile="$1"
    assert_line "$outfile" \
        pattern     '^=== histogram-bin-counters ===$' \
        asserts     'The histogram-bin-counters section is emitted whenever -V histogram-bin-counters is requested, regardless of which downstream features are active' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl' \
        contract    'Issue #226 framework + features/187-histogram-bin-counter-percentiles.md § Decision 8 — section name is stability-contracted; renames are breaking'
}

# ---------------------------------------------------------------------------
# Scenario 1: default run — no percentile-mode flags
# ---------------------------------------------------------------------------
scenario_default() {
    current_scenario="default"
    echo "[$current_scenario]"
    local out
    out=$(run_section)

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^opt_out_active: no$' \
        asserts     'When --exact-percentiles is not given, opt_out_active reports `no` and the unified bin-counter percentile path is active for migrated consumers' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl (run-level header block)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — locked run-level field; opt-out is the only escape hatch back to pre-#187 sort-based computation'

    assert_line "$out" \
        pattern     '^percentile_precision: 5 \(default\)$' \
        asserts     'With no precision flags, percentile_precision reports tier 5 (the default level in the locked tier table) with source annotation `(default)`' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl (run-level header block)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 + § Decision 2 — tier 5 is the default level; source annotation form is locked'

    assert_line "$out" \
        pattern     '^buckets_per_decade: 53 \(default\)$' \
        asserts     'With no precision flags, buckets_per_decade reports the default 53 (the bpd corresponding to tier 5) with source annotation `(default)`' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl (run-level header block)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 + § Decision 2 — tier 5 → bpd 53 is locked'

    assert_no_line "$out" \
        pattern     '^opt_out_notice:' \
        asserts     'opt_out_notice is conditional — it appears only when --exact-percentiles is active; it must be absent in a default run' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl (run-level header block)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — opt_out_notice is gated on --exact-percentiles'

    rm -f "$out"
}

# ---------------------------------------------------------------------------
# Scenario 2: --exact-percentiles opt-out active
# ---------------------------------------------------------------------------
scenario_opt_out() {
    current_scenario="opt-out"
    echo "[$current_scenario]"
    local out
    out=$(run_section --exact-percentiles)

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^opt_out_active: yes$' \
        asserts     'When --exact-percentiles is given, opt_out_active reports `yes` and all migrated consumers revert to pre-#187 sort-based percentile computation' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl (run-level header block)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — opt-out semantics are locked'

    assert_line "$out" \
        pattern     '^opt_out_notice: --exact-percentiles is set; .*deprecated' \
        asserts     'When opt-out is active, opt_out_notice surfaces the deprecation message for --exact-percentiles' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl (run-level header block, line after opt_out_active)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — deprecation notice text is locked surface; --exact-percentiles will be removed in a future release'

    assert_line "$out" \
        pattern     '^percentile_precision: 5 \(default; not in effect this run\)$' \
        asserts     'When opt-out is active, percentile_precision reports the default tier but its source annotation is suffixed `; not in effect this run` to signal the value is not consulted by any consumer this run' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl (run-level header block; $not_in_effect suffix)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — locked suffix form for opt-out state'

    assert_line "$out" \
        pattern     '^buckets_per_decade: 53 \(default; not in effect this run\)$' \
        asserts     'When opt-out is active, buckets_per_decade reports the default bpd but its source annotation is suffixed `; not in effect this run`' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl (run-level header block; $not_in_effect suffix)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — locked suffix form for opt-out state'

    rm -f "$out"
}

# ---------------------------------------------------------------------------
# Scenario 3: --percentile-precision 7 (tier override)
# ---------------------------------------------------------------------------
scenario_precision_tier() {
    current_scenario="precision-tier"
    echo "[$current_scenario]"
    local out
    out=$(run_section --percentile-precision 7)

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^percentile_precision: 7 \(--percentile-precision 7\)$' \
        asserts     'When --percentile-precision N is given without -pbpd, percentile_precision reports N with source annotation `(--percentile-precision N)`' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl (run-level header block; --percentile-precision branch of source annotation)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — source annotation form is locked per branch'

    assert_line "$out" \
        pattern     '^buckets_per_decade: 115 \(--percentile-precision 7\)$' \
        asserts     'When --percentile-precision 7 resolves through the tier table, buckets_per_decade reports 115 (the bpd for tier 7) with matching source annotation' \
        produced_by 'adapt_to_command_line_options() in ltl (tier table %level_to_bpd) + emit_bin_counter_mode_verbose() (source annotation)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 2 — tier 7 → bpd 115 is locked'

    rm -f "$out"
}

# ---------------------------------------------------------------------------
# Scenario 4: -pbpd 100 (non-tier value -> literal `n/a` per audit A5)
# ---------------------------------------------------------------------------
scenario_pbpd_non_tier() {
    current_scenario="pbpd-non-tier"
    echo "[$current_scenario]"
    local out
    out=$(run_section -pbpd 100)

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^percentile_precision: n/a \(-pbpd 100\)$' \
        asserts     'When -pbpd resolves to a value with no tier-table match, percentile_precision reports the literal string `n/a` (not an integer) with source annotation reflecting the -pbpd source' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl (run-level header block; bpd-without-tier-match branch)' \
        contract    'features/189-percentile-mode-audit.md § Bucket A § A5 — literal `n/a` rendering for non-tier bpd values is locked'

    assert_line "$out" \
        pattern     '^buckets_per_decade: 100 \(-pbpd 100\)$' \
        asserts     'When -pbpd N is given, buckets_per_decade reports N with source annotation `(-pbpd N)`' \
        produced_by 'adapt_to_command_line_options() in ltl (-pbpd branch) + emit_bin_counter_mode_verbose() (source annotation)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — source annotation form is locked'

    rm -f "$out"
}

# ---------------------------------------------------------------------------
# Scenario 5: -pbpd + --percentile-precision conflict (-pbpd wins)
# ---------------------------------------------------------------------------
scenario_flag_conflict() {
    current_scenario="flag-conflict"
    echo "[$current_scenario]"
    local out
    out=$(run_section -pbpd 100 --percentile-precision 4)

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^percentile_precision: 4 \(--percentile-precision 4; overridden\)$' \
        asserts     'When both -pbpd and --percentile-precision are given, percentile_precision reports the *requested* level from --percentile-precision with `; overridden` suffix indicating -pbpd won' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl (run-level header block; conflict branch of $level_source)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — conflict annotation form is locked'

    assert_line "$out" \
        pattern     '^buckets_per_decade: 100 \(-pbpd 100; --percentile-precision 4 overridden\)$' \
        asserts     'When both flags conflict, buckets_per_decade reports the *active* bpd from -pbpd with full conflict annotation showing both flags and which one was overridden' \
        produced_by 'adapt_to_command_line_options() in ltl ($percentile_precision_source assembly)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — full conflict annotation is locked'

    rm -f "$out"
}

# ---------------------------------------------------------------------------
# Scenario 6: invalid -pbpd value warns + falls back to default
# ---------------------------------------------------------------------------
scenario_pbpd_out_of_range() {
    current_scenario="pbpd-out-of-range"
    echo "[$current_scenario]"
    local out
    out=$(run_section -pbpd 9999)

    assert_header_present "$out"

    assert_line "$out" \
        pattern     'Invalid -pbpd: 9999' \
        asserts     'When -pbpd is outside the locked 4..616 range, ltl emits a warning to stderr naming the invalid value' \
        produced_by 'adapt_to_command_line_options() in ltl (-pbpd range-check branch)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 2 — valid range is locked at 4..616'

    assert_line "$out" \
        pattern     '^percentile_precision: 5 \(default\)$' \
        asserts     'When -pbpd is out of range, percentile_precision falls back to the default tier 5 (not the invalid value)' \
        produced_by 'adapt_to_command_line_options() in ltl (range-check fallback) + emit_bin_counter_mode_verbose() (source annotation)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 2 — fallback to default is locked behavior'

    assert_line "$out" \
        pattern     '^buckets_per_decade: 53 \(default\)$' \
        asserts     'When -pbpd is out of range, buckets_per_decade falls back to 53 with source annotation reset to `(default)`' \
        produced_by 'adapt_to_command_line_options() in ltl (range-check fallback resets $percentile_precision_source to "default")' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 2 — fallback resets source annotation'

    rm -f "$out"
}

# ---------------------------------------------------------------------------
# Scenario 7: section is always present under -V histogram-bin-counters
# even when no percentile-consuming feature is in use
# ---------------------------------------------------------------------------
scenario_always_present() {
    current_scenario="always-present"
    echo "[$current_scenario]"
    local out
    # Heatmap is enabled but no percentile flags; the section should still emit.
    out=$(run_section -hm duration)

    assert_header_present "$out"

    rm -f "$out"
}

# ---------------------------------------------------------------------------
# Run all scenarios
# ---------------------------------------------------------------------------

echo "Validating histogram-bin-counters -V section (Issues #189, #187, #226)"
echo ""

scenario_default
echo ""
scenario_opt_out
echo ""
scenario_precision_tier
echo ""
scenario_pbpd_non_tier
echo ""
scenario_flag_conflict
echo ""
scenario_pbpd_out_of_range
echo ""
scenario_always_present

echo ""
echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
echo "ALL HISTOGRAM-BIN-COUNTERS TESTS PASSED"
