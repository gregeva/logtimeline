#!/usr/bin/env bash
# capture-regression.sh — Capture reference output for column layout regression testing
# Usage: ./tests/capture-regression.sh [output_dir]
#
# Runs ltl with --disable-progress and --terminal-width against test logs,
# strips ANSI escape codes, and saves output to reference files.
# Uses -osum -n 1 to suppress summary table and limit top messages (not under test).
#
# At narrow widths (80, 100), columns are omitted to avoid overflow since
# auto-hide is not yet implemented. Wider widths test the full column set.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"
REF_DIR="${1:-$SCRIPT_DIR/reference-output}"

# Common options: suppress progress, summary table, and limit top messages
COMMON="--disable-progress -osum -n 1"

# Test log files
ACCESS_LOG="$REPO_DIR/logs/AccessLogs/localhost_access_log.2025-03-21.txt"
SCRIPT_LOG="$REPO_DIR/logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log"

# Verify test files exist
for f in "$ACCESS_LOG" "$SCRIPT_LOG"; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: Test file not found: $f"
        exit 1
    fi
done

# Strip ANSI escape codes and non-deterministic lines (timing, memory) from stdin
strip_nondeterministic() {
    perl -pe 's/\e\[[0-9;]*[a-zA-Z]//g; s/\e\[\d*m//g' \
    | perl -ne 'BEGIN{$skip=0} $skip=1 if /TOP OVERALL/; print unless $skip || /PROCESSING TIME|TOTAL TIME|MAXIMUM MEMORY|INITIALIZE EMPTY|CALCULATE STATISTICS|SCALE DATA/i'
}

# Create output directory
mkdir -p "$REF_DIR"

count=0
run_test() {
    local name="$1"
    shift
    local outfile="$REF_DIR/$name.txt"
    echo "  Capturing: $name"
    "$@" 2>/dev/null | strip_nondeterministic > "$outfile"
    count=$((count + 1))
}

echo "Capturing regression reference output to: $REF_DIR"
echo ""

# --- Access log: narrow width with reduced columns ---
echo "Access log at width 80 (reduced columns):"
run_test "access-w80" "$LTL" $COMMON --terminal-width 80 -os -od -ov "$ACCESS_LOG"

# --- Access log at wider widths (full column set) ---
echo "Access log at widths 120, 160, 200:"
for w in 120 160 200; do
    run_test "access-w${w}" "$LTL" $COMMON --terminal-width $w "$ACCESS_LOG"
done

# --- ScriptLog at various widths ---
echo "ScriptLog at width 100 (reduced columns):"
run_test "scriptlog-w100" "$LTL" $COMMON --terminal-width 100 -os -ov "$SCRIPT_LOG"

echo "ScriptLog at widths 160, 200:"
for w in 160 200; do
    run_test "scriptlog-w${w}" "$LTL" $COMMON --terminal-width $w "$SCRIPT_LOG"
done

# --- Heatmap modes at width 160 ---
echo "Heatmap modes at width 160:"
for mode in duration bytes count; do
    run_test "heatmap-${mode}-w160" "$LTL" $COMMON --terminal-width 160 -hm "$mode" "$SCRIPT_LOG"
done

# --- Omit flags at width 160 ---
echo "Omit flags at width 160:"
run_test "omit-ov-w160" "$LTL" $COMMON --terminal-width 160 -ov "$ACCESS_LOG"
run_test "omit-or-w160" "$LTL" $COMMON --terminal-width 160 -or "$ACCESS_LOG"
run_test "omit-os-w160" "$LTL" $COMMON --terminal-width 160 -os "$ACCESS_LOG"
run_test "omit-ov-or-w160" "$LTL" $COMMON --terminal-width 160 -ov -or "$ACCESS_LOG"

# --- Millisecond precision with constrained time range ---
echo "Millisecond precision at width 160:"
run_test "ms-w160" "$LTL" $COMMON --terminal-width 160 -ms -bs 1000 -st 00:00 -et 00:05 "$ACCESS_LOG"

echo ""
echo "Captured $count reference files to: $REF_DIR"
echo "Done."
