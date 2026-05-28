#!/usr/bin/env bash
# capture-regression.sh — Capture reference output for column layout regression testing
# Usage: ./tests/capture-regression.sh [output_dir]
#
# Runs ltl with --disable-progress and --terminal-width against test logs,
# strips ANSI escape codes, and saves output to reference files.
# Uses -osum -n 1 to suppress summary table and limit top messages (not under test).
#
# At narrow widths, auto-hide removes low-priority columns automatically.
# The -os/-od/-ov tests verify manual column hiding still works alongside auto-hide.

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
# Issue #235 — additional fixtures for the extended heatmap/histogram tests
# below. APACHE_LOG is the canonical clean Apache HTTP2 access log; it ships
# bytes + microsecond-%D durations and is small (~100 KB), keeping capture
# time tight. Per repo memory (feedback_test_logs.md), new fixtures must NOT
# use logs/AccessLogs/localhost_access_log.2025-03-21.txt due to corrupt lines.
APACHE_LOG="$REPO_DIR/logs/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log"

# Verify test files exist
for f in "$ACCESS_LOG" "$SCRIPT_LOG" "$APACHE_LOG"; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: Test file not found: $f"
        exit 1
    fi
done

# Strip ANSI escape codes and non-deterministic lines (timing, memory) from stdin
strip_nondeterministic() {
    perl -pe 's/\e\[[0-9;]*[a-zA-Z]//g; s/\e\[\d*m//g; s/log timeline \[[0-9.]+\]/log timeline [VERSION]/' \
    | perl -ne 'BEGIN{$skip=0} $skip=1 if /TOP OVERALL/; print unless $skip || /PROCESSING TIME|TOTAL TIME|MAXIMUM MEMORY|INITIALIZE EMPTY|CALCULATE STATISTICS|SCALE DATA/i'
}

# Create output directory
mkdir -p "$REF_DIR"

count=0
# Transient stderr captures live in a temp directory and are cleaned up
# unconditionally on exit. They MUST NOT be written into the deliverable
# reference-output directory.
STDERR_DIR=$(mktemp -d)
trap 'rm -rf "$STDERR_DIR"' EXIT

run_test() {
    local name="$1"
    shift
    local outfile="$REF_DIR/$name.txt"
    local stderrfile="$STDERR_DIR/$name.stderr"
    echo "  Capturing: $name"

    # Run ltl, capturing stdout to outfile (after filtering) and stderr to
    # a temp file. Per tests/HARNESS-DESIGN.md, we do not swallow stderr —
    # a silent failure of the captured tool would otherwise produce an
    # empty reference file that downstream regression tests accept as
    # authoritative. On failure we print stderr inline and abort; on success
    # the temp file is discarded with the rest of $STDERR_DIR.
    set +e
    "$@" 2>"$stderrfile" | strip_nondeterministic > "$outfile"
    local pipe_status=("${PIPESTATUS[@]}")
    set -e

    if [[ "${pipe_status[0]}" -ne 0 ]]; then
        echo "  FAIL  $name :: ltl exited ${pipe_status[0]}; stderr:" >&2
        sed 's/^/        /' "$stderrfile" >&2
        rm -f "$outfile"
        exit 1
    fi
    if [[ ! -s "$outfile" ]]; then
        echo "  FAIL  $name :: captured reference is empty (anchor or output disappeared); stderr:" >&2
        sed 's/^/        /' "$stderrfile" >&2
        rm -f "$outfile"
        exit 1
    fi
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
# -dm raw pins these captures to the sort-and-index path. The
# unified bin-counter path (#34/#201) is approximate within bin-resolution
# bound and would make the reference fragile to precision tweaks. Layout
# coverage is what we want; bin-counter accuracy is covered by
# tests/validate-histogram-bin-counters.sh.
echo "Heatmap modes at width 160:"
for mode in duration bytes count; do
    run_test "heatmap-${mode}-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hm "$mode" "$SCRIPT_LOG"
done

# --- Omit flags at width 160 ---
echo "Omit flags at width 160:"
run_test "omit-ov-w160" "$LTL" $COMMON --terminal-width 160 -ov "$ACCESS_LOG"
run_test "omit-or-w160" "$LTL" $COMMON --terminal-width 160 -or "$ACCESS_LOG"
run_test "omit-os-w160" "$LTL" $COMMON --terminal-width 160 -os "$ACCESS_LOG"
run_test "omit-ov-or-w160" "$LTL" $COMMON --terminal-width 160 -ov -or "$ACCESS_LOG"

# --- Auto-hide tests (Issue #73) ---
echo "Auto-hide at narrow widths:"
run_test "autohide-w80" "$LTL" $COMMON --terminal-width 80 "$ACCESS_LOG"
run_test "autohide-w100" "$LTL" $COMMON --terminal-width 100 "$ACCESS_LOG"
run_test "noautohide-w80" "$LTL" $COMMON --terminal-width 80 --no-auto-hide "$ACCESS_LOG"
run_test "autohide-hm-w120" "$LTL" $COMMON -dm raw --terminal-width 120 -hm duration "$SCRIPT_LOG"

# --- Millisecond precision with constrained time range ---
echo "Millisecond precision at width 160:"
run_test "ms-w160" "$LTL" $COMMON --terminal-width 160 -ms -bs 1000 -st 00:00 -et 00:05 "$ACCESS_LOG"

# ---------------------------------------------------------------------------
# Issue #235 — extended heatmap and histogram rendering coverage
# ---------------------------------------------------------------------------
# Mirror of the additions made to tests/validate-regression.sh. Both files
# must move in lockstep: validate-regression.sh asserts on fixtures captured
# by this script. Light-background auto-detection is inert under shell
# redirection (ltl:2722 checks -t STDOUT before doing OSC 11 query); no
# environment override needed. Issue #250 tracks the missing
# --no-light-background flag.

echo "Heatmap at narrow widths (autohide interaction):"
run_test "heatmap-duration-w80"  "$LTL" $COMMON -dm raw --terminal-width 80  -hm duration "$SCRIPT_LOG"
run_test "heatmap-duration-w100" "$LTL" $COMMON -dm raw --terminal-width 100 -hm duration "$SCRIPT_LOG"
run_test "heatmap-bytes-w120"    "$LTL" $COMMON -dm raw --terminal-width 120 -hm bytes    "$SCRIPT_LOG"
run_test "heatmap-count-w100"    "$LTL" $COMMON -dm raw --terminal-width 100 -hm count    "$SCRIPT_LOG"

echo "Light-background heatmap:"
run_test "heatmap-lbg-duration-w160" "$LTL" $COMMON -dm raw --light-background --terminal-width 160 -hm duration "$SCRIPT_LOG"

echo "Custom heatmap width:"
run_test "heatmap-hmw30-duration-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hm duration -hmw 30 "$SCRIPT_LOG"
run_test "heatmap-hmw80-duration-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hm duration -hmw 80 "$SCRIPT_LOG"

echo "Histogram single-metric across widths:"
run_test "hg-duration-w80"  "$LTL" $COMMON -dm raw --terminal-width 80  -hg duration "$APACHE_LOG"
run_test "hg-duration-w120" "$LTL" $COMMON -dm raw --terminal-width 120 -hg duration "$APACHE_LOG"
run_test "hg-duration-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hg duration "$APACHE_LOG"

echo "Histogram per metric (axis formatters):"
run_test "hg-bytes-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hg bytes "$APACHE_LOG"
run_test "hg-count-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hg count "$SCRIPT_LOG"

echo "Multi-histogram stacked panels:"
run_test "hg-multi-duration-bytes-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hg duration,bytes        "$APACHE_LOG"
run_test "hg-multi-all-w160"            "$LTL" $COMMON -dm raw --terminal-width 160 -hg duration,bytes,count "$SCRIPT_LOG"

echo "Custom histogram dimensions:"
run_test "hg-hgw30-duration-w160"     "$LTL" $COMMON -dm raw --terminal-width 160 -hg duration       -hgw 30 "$APACHE_LOG"
run_test "hg-hgw50-multi-w160"        "$LTL" $COMMON -dm raw --terminal-width 160 -hg duration,bytes -hgw 50 "$APACHE_LOG"
run_test "hg-hgh4-duration-w160"      "$LTL" $COMMON -dm raw --terminal-width 160 -hg duration       -hgh 4  "$APACHE_LOG"
run_test "hg-hgh16-duration-w160"     "$LTL" $COMMON -dm raw --terminal-width 160 -hg duration       -hgh 16 "$APACHE_LOG"

echo "Composition (heatmap + histogram together):"
run_test "hm-hg-duration-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hm duration -hg duration "$SCRIPT_LOG"

echo ""
echo "Captured $count reference files to: $REF_DIR"
echo "Done."
