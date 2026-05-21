#!/usr/bin/env bash
# validate-regression.sh — Validate ltl output against regression reference files
# Usage: ./tests/validate-regression.sh [reference_dir]
#
# Re-runs the same ltl commands as capture-regression.sh and diffs against
# the stored reference output. Any difference is a regression.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"
REF_DIR="${1:-$SCRIPT_DIR/reference-output}"
TMP_DIR=$(mktemp -d)
# Cleanup is unconditional — if the script aborts mid-run (under set -e),
# the explicit `rm -rf` at the end never runs. Per tests/HARNESS-DESIGN.md,
# harnesses must not leave temp artifacts behind.
trap 'rm -rf "$TMP_DIR"' EXIT

# Common options: suppress progress, summary table, and limit top messages
COMMON="--disable-progress -osum -n 1"

# Test log files
ACCESS_LOG="$REPO_DIR/logs/AccessLogs/localhost_access_log.2025-03-21.txt"
SCRIPT_LOG="$REPO_DIR/logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log"

# Strip ANSI escape codes and non-deterministic lines (timing, memory) from stdin
strip_nondeterministic() {
    perl -pe 's/\e\[[0-9;]*[a-zA-Z]//g; s/\e\[\d*m//g; s/log timeline \[[0-9.]+\]/log timeline [VERSION]/' \
    | perl -ne 'BEGIN{$skip=0} $skip=1 if /TOP OVERALL/; print unless $skip || /PROCESSING TIME|TOTAL TIME|MAXIMUM MEMORY|INITIALIZE EMPTY|CALCULATE STATISTICS|SCALE DATA/i'
}

# Verify reference directory exists
if [[ ! -d "$REF_DIR" ]]; then
    echo "ERROR: Reference directory not found: $REF_DIR"
    echo "Run capture-regression.sh first to create reference output."
    exit 1
fi

pass=0
fail=0
skip=0

run_test() {
    local name="$1"
    shift
    local reffile="$REF_DIR/$name.txt"
    local tmpfile="$TMP_DIR/$name.txt"
    local stderrfile="$TMP_DIR/$name.stderr"

    if [[ ! -f "$reffile" ]]; then
        echo "  SKIP  $name (no reference file)"
        skip=$((skip + 1))
        return
    fi

    # Run ltl, capturing stdout to tmpfile (after filtering) and stderr
    # separately. Per tests/HARNESS-DESIGN.md, we DO NOT swallow stderr —
    # a silent failure here would produce an empty tmpfile that diffs
    # against an empty reffile and falsely PASSes.
    set +e
    "$@" 2>"$stderrfile" | strip_nondeterministic > "$tmpfile"
    local pipe_status=("${PIPESTATUS[@]}")
    set -e

    if [[ "${pipe_status[0]}" -ne 0 ]]; then
        echo "  FAIL  $name :: ltl exited ${pipe_status[0]}; stderr:" >&2
        sed 's/^/        /' "$stderrfile" >&2
        fail=$((fail + 1))
        return
    fi
    if [[ ! -s "$tmpfile" ]]; then
        echo "  FAIL  $name :: captured output is empty (regression target produced nothing); stderr:" >&2
        sed 's/^/        /' "$stderrfile" >&2
        fail=$((fail + 1))
        return
    fi

    if diff -q "$reffile" "$tmpfile" > /dev/null 2>&1; then
        echo "  PASS  $name"
        pass=$((pass + 1))
    else
        echo "  FAIL  $name"
        # diff returns 1 on differences (intentional); pipefail would propagate
        # that and abort the harness before printing the Results summary.
        # Per tests/HARNESS-DESIGN.md, intentional non-zero exits in a
        # diagnostic pipeline must be neutralized so the harness can complete.
        { diff --unified=3 "$reffile" "$tmpfile" || true; } | head -30
        echo "  ..."
        fail=$((fail + 1))
    fi
}

echo "Validating regression output against: $REF_DIR"
echo ""

# --- Access log: narrow width with reduced columns ---
run_test "access-w80" "$LTL" $COMMON --terminal-width 80 -os -od -ov "$ACCESS_LOG"

# --- Access log at wider widths ---
for w in 120 160 200; do
    run_test "access-w${w}" "$LTL" $COMMON --terminal-width $w "$ACCESS_LOG"
done

# --- ScriptLog at various widths ---
run_test "scriptlog-w100" "$LTL" $COMMON --terminal-width 100 -os -ov "$SCRIPT_LOG"

for w in 160 200; do
    run_test "scriptlog-w${w}" "$LTL" $COMMON --terminal-width $w "$SCRIPT_LOG"
done

# --- Heatmap modes at width 160 ---
# --exact-percentiles pins these to the sort-and-index path so the reference
# stays byte-stable. The unified bin-counter path (#34/#201) is approximate
# within bin-resolution bound (well below visibility threshold per #201 V8)
# but not byte-identical, which would make this layout/rendering regression
# suite fragile to precision tweaks. Layout coverage is what we want here;
# bin-counter accuracy is covered by tests/validate-histogram-bin-counters.sh.
for mode in duration bytes count; do
    run_test "heatmap-${mode}-w160" "$LTL" $COMMON --exact-percentiles --terminal-width 160 -hm "$mode" "$SCRIPT_LOG"
done

# --- Omit flags at width 160 ---
run_test "omit-ov-w160" "$LTL" $COMMON --terminal-width 160 -ov "$ACCESS_LOG"
run_test "omit-or-w160" "$LTL" $COMMON --terminal-width 160 -or "$ACCESS_LOG"
run_test "omit-os-w160" "$LTL" $COMMON --terminal-width 160 -os "$ACCESS_LOG"
run_test "omit-ov-or-w160" "$LTL" $COMMON --terminal-width 160 -ov -or "$ACCESS_LOG"

# --- Auto-hide tests (Issue #73) ---
run_test "autohide-w80" "$LTL" $COMMON --terminal-width 80 "$ACCESS_LOG"
run_test "autohide-w100" "$LTL" $COMMON --terminal-width 100 "$ACCESS_LOG"
run_test "noautohide-w80" "$LTL" $COMMON --terminal-width 80 --no-auto-hide "$ACCESS_LOG"
run_test "autohide-hm-w120" "$LTL" $COMMON --exact-percentiles --terminal-width 120 -hm duration "$SCRIPT_LOG"

# --- Millisecond precision ---
run_test "ms-w160" "$LTL" $COMMON --terminal-width 160 -ms -bs 1000 -st 00:00 -et 00:05 "$ACCESS_LOG"

echo ""
echo "Results: $pass passed, $fail failed, $skip skipped"
# TMP_DIR cleanup handled by EXIT trap at top of script

if [[ $fail -gt 0 ]]; then
    echo "REGRESSION DETECTED"
    exit 1
else
    echo "ALL TESTS PASSED"
    exit 0
fi
