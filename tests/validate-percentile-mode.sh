#!/usr/bin/env bash
# validate-percentile-mode.sh — Validate Issue #189 (`=== PERCENTILE MODE ===`
# `-V` block) behavior.
# Usage: ./tests/validate-percentile-mode.sh
#
# Each scenario invokes ltl with -V plus a specific combination of
# percentile-mode CLI flags and asserts that the `=== PERCENTILE MODE ===`
# section emits the locked Decision 8 contract surface — section header,
# run-level field names, source-annotation forms, n/a rendering for non-tier
# -pbpd values, opt-out behavior, and `consumers_active: none` line.
#
# Departs from validate-regression.sh in assertion style: greps the -V
# section for expected key/value lines rather than diffing full output
# against a reference fixture. The two suites are complementary:
# validate-regression.sh ensures rendered analytical output is byte-identical;
# this suite ensures the unified-contract -V audit surface holds the
# stability promises in:
#   features/187-histogram-bin-counter-percentiles.md § Decision 8
#
# PR #189-2 ships only the run-level header + `consumers_active: none`;
# no consumer is migrated yet so no per-consumer block scenarios exist here.
# Consumer-block scenarios will be added by each consumer's own migration
# ticket per the locked stability contract.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"
ACCESS_LOG="$REPO_DIR/logs/AccessLogs/localhost_access_log.2025-03-21.txt"

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

# Run ltl with -V and the standard suppression flag, capture combined
# output to a temp file, echo path. Args after the function name are
# forwarded verbatim before the input file.
run_ltl_v() {
    local outfile
    outfile=$(mktemp)
    "$LTL" --disable-progress -V "$@" "$ACCESS_LOG" > "$outfile" 2>&1 || true
    echo "$outfile"
}

# Assert a regex matches a line in the captured -V output.
assert_line() {
    local name="$1" file="$2" pattern="$3"
    if grep -qE "$pattern" "$file"; then
        echo "  PASS  $name :: $pattern"
        pass=$((pass + 1))
    else
        echo "  FAIL  $name :: $pattern"
        echo "        (not found in $file)"
        fail=$((fail + 1))
        failures+=("$name :: $pattern")
    fi
}

# Assert a regex does NOT match any line in the captured -V output.
assert_no_line() {
    local name="$1" file="$2" pattern="$3"
    if grep -qE "$pattern" "$file"; then
        echo "  FAIL  $name :: !$pattern (unexpectedly present)"
        fail=$((fail + 1))
        failures+=("$name :: !$pattern (unexpectedly present)")
    else
        echo "  PASS  $name :: !$pattern"
        pass=$((pass + 1))
    fi
}

# ---------------------------------------------------------------------------
# Scenario 1: default run — no percentile-mode flags
# ---------------------------------------------------------------------------
# Spec example: features/187-...-percentiles.md § Decision 8 (lines 1602-1606)
scenario_default() {
    local name="default"
    local out
    out=$(run_ltl_v)
    assert_line    "$name" "$out" '^=== PERCENTILE MODE ===$'
    assert_line    "$name" "$out" '^opt_out_active: no$'
    assert_line    "$name" "$out" '^percentile_precision: 5 \(default\)$'
    assert_line    "$name" "$out" '^buckets_per_decade: 53 \(default\)$'
    assert_line    "$name" "$out" '^consumers_active: none$'
    # opt_out_notice is conditional — absent unless opt-out is active.
    assert_no_line "$name" "$out" '^opt_out_notice:'
    rm -f "$out"
}

# ---------------------------------------------------------------------------
# Scenario 2: --exact-percentiles opt-out active
# ---------------------------------------------------------------------------
# Spec example: features/187-...-percentiles.md § Decision 8 (lines 1556-1560)
# Locked: opt_out_notice present, both fields suffixed `; not in effect this run`.
scenario_opt_out() {
    local name="opt-out"
    local out
    out=$(run_ltl_v --exact-percentiles)
    assert_line "$name" "$out" '^opt_out_active: yes$'
    assert_line "$name" "$out" '^opt_out_notice: --exact-percentiles is set; .*deprecated'
    assert_line "$name" "$out" '^percentile_precision: 5 \(default; not in effect this run\)$'
    assert_line "$name" "$out" '^buckets_per_decade: 53 \(default; not in effect this run\)$'
    assert_line "$name" "$out" '^consumers_active: none$'
    rm -f "$out"
}

# ---------------------------------------------------------------------------
# Scenario 3: --percentile-precision 7 (tier override)
# ---------------------------------------------------------------------------
# Locked tier table: level 7 -> bpd 115 (features/187-...-percentiles.md § Decision 2).
scenario_precision_tier() {
    local name="precision-tier"
    local out
    out=$(run_ltl_v --percentile-precision 7)
    assert_line "$name" "$out" '^percentile_precision: 7 \(--percentile-precision 7\)$'
    assert_line "$name" "$out" '^buckets_per_decade: 115 \(--percentile-precision 7\)$'
    rm -f "$out"
}

# ---------------------------------------------------------------------------
# Scenario 4: -pbpd 100 (non-tier value -> literal `n/a` per audit A5)
# ---------------------------------------------------------------------------
# Locked: when -pbpd resolves to a non-tier value, percentile_precision
# renders the literal string `n/a` (locked at
# features/189-...-audit.md § Bucket A § A5).
scenario_pbpd_non_tier() {
    local name="pbpd-non-tier"
    local out
    out=$(run_ltl_v -pbpd 100)
    assert_line "$name" "$out" '^percentile_precision: n/a \(-pbpd 100\)$'
    assert_line "$name" "$out" '^buckets_per_decade: 100 \(-pbpd 100\)$'
    rm -f "$out"
}

# ---------------------------------------------------------------------------
# Scenario 5: -pbpd + --percentile-precision conflict (-pbpd wins)
# ---------------------------------------------------------------------------
# Spec example: features/187-...-percentiles.md § Decision 8 (lines 1574-1577)
# Locked: percentile_precision reports the *requested* level with
# "; overridden" annotation; buckets_per_decade reports the *active* bpd
# with the full "-pbpd N; --percentile-precision M overridden" annotation.
scenario_flag_conflict() {
    local name="flag-conflict"
    local out
    out=$(run_ltl_v -pbpd 100 --percentile-precision 4)
    assert_line "$name" "$out" '^percentile_precision: 4 \(--percentile-precision 4; overridden\)$'
    assert_line "$name" "$out" '^buckets_per_decade: 100 \(-pbpd 100; --percentile-precision 4 overridden\)$'
    rm -f "$out"
}

# ---------------------------------------------------------------------------
# Scenario 6: invalid -pbpd value warns + falls back to default
# ---------------------------------------------------------------------------
# Locked range: 4 <= -pbpd <= 616 (features/187-...-percentiles.md § Decision 2).
# Out-of-range -> warning emitted, value resets to default 53,
# source annotation resets to 'default'.
scenario_pbpd_out_of_range() {
    local name="pbpd-out-of-range"
    local out
    out=$(run_ltl_v -pbpd 9999)
    assert_line "$name" "$out" 'Invalid -pbpd: 9999'
    assert_line "$name" "$out" '^percentile_precision: 5 \(default\)$'
    assert_line "$name" "$out" '^buckets_per_decade: 53 \(default\)$'
    rm -f "$out"
}

# ---------------------------------------------------------------------------
# Scenario 7: section is always present under -V even when no percentile
# feature is in use
# ---------------------------------------------------------------------------
# Decision 8 stability contract: section is always present under -V; consumer
# blocks appear only when a consumer is migrated AND active. In PR #189-2 no
# consumer is migrated, so `consumers_active: none` is unconditional.
scenario_always_present() {
    local name="always-present"
    local out
    # Run with a non-percentile feature flag to confirm section still appears.
    out=$(run_ltl_v -hm duration)
    assert_line "$name" "$out" '^=== PERCENTILE MODE ===$'
    assert_line "$name" "$out" '^consumers_active: none$'
    rm -f "$out"
}

# ---------------------------------------------------------------------------
# Run all scenarios
# ---------------------------------------------------------------------------

echo "Validating percentile-mode -V block (Issue #189, PR #189-2)"
echo ""

echo "[scenario_default]"
scenario_default

echo ""
echo "[scenario_opt_out]"
scenario_opt_out

echo ""
echo "[scenario_precision_tier]"
scenario_precision_tier

echo ""
echo "[scenario_pbpd_non_tier]"
scenario_pbpd_non_tier

echo ""
echo "[scenario_flag_conflict]"
scenario_flag_conflict

echo ""
echo "[scenario_pbpd_out_of_range]"
scenario_pbpd_out_of_range

echo ""
echo "[scenario_always_present]"
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
echo "ALL PERCENTILE-MODE TESTS PASSED"
