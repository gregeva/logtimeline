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

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
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
# Issue #235 — additional fixtures for the extended heatmap/histogram tests
# below. APACHE_LOG is the canonical clean Apache HTTP2 access log; it ships
# bytes + microsecond-%D durations and is small (~100 KB), keeping capture
# time tight. Per repo memory (feedback_test_logs.md), new fixtures must NOT
# use logs/AccessLogs/localhost_access_log.2025-03-21.txt due to corrupt lines.
APACHE_LOG="$REPO_DIR/logs/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log"
# Issue #312 — numeric-highlight rendering fixtures. PLOT_LOG has sparse metric
# presence (durationMS/count on 220 of 2,992 lines); DPM5K_LOG is the
# deterministic 5k-line ScriptLog slice with durationMS on every line.
PLOT_LOG="$REPO_DIR/logs/ThingworxLogs/CustomThingworxLogs/ScriptLog.GetComplexPlotByIndex.log"
DPM5K_LOG="$REPO_DIR/logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean-5k.log"

# Strip ANSI escape codes and non-deterministic lines (timing, memory) from stdin
strip_nondeterministic() {
    perl -pe 's/\e\[[0-9;]*[a-zA-Z]//g; s/\e\[\d*m//g; s/log timeline \[[0-9.]+\]/log timeline [VERSION]/' \
    | perl -ne 'BEGIN{$skip=0} $skip=1 if /TOP OVERALL/; print unless $skip || /PROCESSING TIME|TOTAL TIME|MAXIMUM MEMORY|INITIALIZE EMPTY|CALCULATE STATISTICS|HEATMAP STATISTICS|HISTOGRAM STATISTICS|GROUP SIMILAR MESSAGES|SCALE DATA/i'
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
failures=()

# Self-documenting fields shared across every run_test assertion. The
# assertion shape is uniform across this harness: a byte-stable rendering
# of `ltl` output (after stripping nondeterministic content) must match
# the captured reference file. The test-name dimension is what varies;
# the invariant, producer, and contract are the same for every case.
# Per tests/HARNESS-DESIGN.md § Self-documenting assertions, these three
# fields are surfaced alongside every failure.
REGRESSION_ASSERTS='ltl output (after stripping ANSI, timing, memory, and other nondeterministic content) is byte-identical to the captured reference file for this scenario'
REGRESSION_PRODUCED_BY='print_bar_graph(), print_summary_table(), print_heatmap_row(), and the layout engine in ltl - composite rendered output'
REGRESSION_CONTRACT='tests/HARNESS-DESIGN.md section Self-documenting assertions + this harness re-runs the commands from capture-regression.sh against tests/reference-output/; rebaselining is a per-release activity, not an automatic remediation'

# Emit a regression-suite failure in the self-documenting multi-line form
# required by tests/HARNESS-DESIGN.md § Self-documenting assertions.
# Args: $1 scenario name, $2 short cause line, $3 (optional) path to a
# file whose contents should be appended as an indented diagnostic body.
emit_regression_fail() {
    local name="$1"
    local cause="$2"
    local body_file="${3:-}"
    echo "  FAIL  $name"
    echo "        cause:       $cause"
    echo "        asserts:     $REGRESSION_ASSERTS"
    echo "        produced_by: $REGRESSION_PRODUCED_BY"
    echo "        contract:    $REGRESSION_CONTRACT"
    if [[ -n "$body_file" && -s "$body_file" ]]; then
        sed 's/^/        /' "$body_file"
    fi
    fail=$((fail + 1))
    failures+=("$name :: $cause")
}

run_test() {
    local name="$1"
    shift
    local reffile="$REF_DIR/$name.txt"
    local tmpfile="$TMP_DIR/$name.txt"
    local stderrfile="$TMP_DIR/$name.stderr"
    local difffile="$TMP_DIR/$name.diff"

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
        emit_regression_fail "$name" "ltl exited ${pipe_status[0]} (stderr below)" "$stderrfile"
        return
    fi
    # Runtime-warning cleanliness (HARNESS-DESIGN.md section Runtime-warning
    # cleanliness): a byte-stable render can still be produced by a warning-
    # emitting data path; the stderr capture is inspected, not just kept.
    if ! assert_no_runtime_warnings "$stderrfile" "$name"; then
        fail=$((fail + 1))
        failures+=("$name :: perl-runtime-warnings-on-stderr")
        return
    fi
    if [[ ! -s "$tmpfile" ]]; then
        emit_regression_fail "$name" "captured output is empty (regression target produced nothing; stderr below)" "$stderrfile"
        return
    fi

    if diff -q "$reffile" "$tmpfile" > /dev/null 2>&1; then
        echo "  PASS  $name"
        pass=$((pass + 1))
    else
        # diff returns 1 on differences (intentional); pipefail would propagate
        # that and abort the harness before printing the Results summary.
        # Per tests/HARNESS-DESIGN.md, intentional non-zero exits in a
        # diagnostic pipeline must be neutralized so the harness can complete.
        { diff --unified=3 "$reffile" "$tmpfile" || true; } | head -30 > "$difffile"
        echo "  ..."  >> "$difffile"
        emit_regression_fail "$name" "rendered output differs from reference (unified diff below, truncated to 30 lines)" "$difffile"
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
# -dm raw pins these to the sort-and-index path so the reference
# stays byte-stable. The unified bin-counter path (#34/#201) is approximate
# within bin-resolution bound (well below visibility threshold per #201 V8)
# but not byte-identical, which would make this layout/rendering regression
# suite fragile to precision tweaks. Layout coverage is what we want here;
# bin-counter accuracy is covered by tests/validate-histogram-bin-counters.sh.
for mode in duration bytes count; do
    run_test "heatmap-${mode}-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hm "$mode" "$SCRIPT_LOG"
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
run_test "autohide-hm-w120" "$LTL" $COMMON -dm raw --terminal-width 120 -hm duration "$SCRIPT_LOG"

# --- Millisecond precision ---
run_test "ms-w160" "$LTL" $COMMON --terminal-width 160 -ms -bs 1000 -st 00:00 -et 00:05 "$ACCESS_LOG"

# ---------------------------------------------------------------------------
# Issue #235 — extended heatmap and histogram rendering coverage
# ---------------------------------------------------------------------------
# All -dm raw for the same reason as the original heatmap tests
# above: pins to the sort-and-index path so byte-identical fixtures survive
# precision tweaks. Light-background auto-detection is inert under shell
# redirection (ltl:2722 checks -t STDOUT before doing OSC 11 query); no
# environment override needed. Issue #250 tracks the missing
# --no-light-background flag if a future change perturbs that.
#
# Fixtures use APACHE_LOG (clean Apache HTTP2 access log) for histogram
# scenarios that benefit from access-log style data, and SCRIPT_LOG (the
# DPM ScriptLog, already in use above) for heatmap and count-axis scenarios.

# --- Heatmap at narrow widths (autohide interaction) ---
run_test "heatmap-duration-w80"  "$LTL" $COMMON -dm raw --terminal-width 80  -hm duration "$SCRIPT_LOG"
run_test "heatmap-duration-w100" "$LTL" $COMMON -dm raw --terminal-width 100 -hm duration "$SCRIPT_LOG"
run_test "heatmap-bytes-w120"    "$LTL" $COMMON -dm raw --terminal-width 120 -hm bytes    "$SCRIPT_LOG"
run_test "heatmap-count-w100"    "$LTL" $COMMON -dm raw --terminal-width 100 -hm count    "$SCRIPT_LOG"

# --- Light-background heatmap ---
run_test "heatmap-lbg-duration-w160" "$LTL" $COMMON -dm raw --light-background --terminal-width 160 -hm duration "$SCRIPT_LOG"

# --- Custom heatmap width ---
run_test "heatmap-hmw30-duration-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hm duration -hmw 30 "$SCRIPT_LOG"
run_test "heatmap-hmw80-duration-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hm duration -hmw 80 "$SCRIPT_LOG"

# --- Histogram single-metric across widths ---
run_test "hg-duration-w80"  "$LTL" $COMMON -dm raw --terminal-width 80  -hg duration "$APACHE_LOG"
run_test "hg-duration-w120" "$LTL" $COMMON -dm raw --terminal-width 120 -hg duration "$APACHE_LOG"
run_test "hg-duration-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hg duration "$APACHE_LOG"

# --- Histogram per metric (axis formatters) ---
run_test "hg-bytes-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hg bytes "$APACHE_LOG"
run_test "hg-count-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hg count "$SCRIPT_LOG"

# --- Multi-histogram stacked panels ---
run_test "hg-multi-duration-bytes-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hg duration,bytes        "$APACHE_LOG"
run_test "hg-multi-all-w160"            "$LTL" $COMMON -dm raw --terminal-width 160 -hg duration,bytes,count "$SCRIPT_LOG"

# --- Custom histogram dimensions ---
run_test "hg-hgw30-duration-w160"     "$LTL" $COMMON -dm raw --terminal-width 160 -hg duration       -hgw 30 "$APACHE_LOG"
run_test "hg-hgw50-multi-w160"        "$LTL" $COMMON -dm raw --terminal-width 160 -hg duration,bytes -hgw 50 "$APACHE_LOG"
run_test "hg-hgh4-duration-w160"      "$LTL" $COMMON -dm raw --terminal-width 160 -hg duration       -hgh 4  "$APACHE_LOG"
run_test "hg-hgh16-duration-w160"     "$LTL" $COMMON -dm raw --terminal-width 160 -hg duration       -hgh 16 "$APACHE_LOG"

# --- Composition: heatmap + histogram together ---
run_test "hm-hg-duration-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hm duration -hg duration "$SCRIPT_LOG"

# ---------------------------------------------------------------------------
# Issue #312 — numeric highlight criteria rendering coverage
# ---------------------------------------------------------------------------
# Mirror of the additions made to tests/capture-regression.sh; both files
# move in lockstep. HL_COMMON keeps the summary table (no -osum) so the
# HIGHLIGHTED row is part of the asserted surface, alongside the bar-prefix
# rendering, the TOP HIGHLIGHTED MESSAGES block, the per-file highlight
# indicator in the file legend, and the histogram/heatmap HL overlays.
# -dm raw on overlay scenarios for the same byte-stability reason as above.
HL_COMMON="--disable-progress -n 1"

run_test "hl-regex-only-w160"      "$LTL" $HL_COMMON --terminal-width 160 -du us -h BomTransformation "$APACHE_LOG"
run_test "hl-hdmin-w160"           "$LTL" $HL_COMMON --terminal-width 160 -du us -hdmin 100 "$APACHE_LOG"
run_test "hl-hbmin-w160"           "$LTL" $HL_COMMON --terminal-width 160 -du us -hbmin 5000 "$APACHE_LOG"
run_test "hl-regex-hdmin-w160"     "$LTL" $HL_COMMON --terminal-width 160 -du us -h BomTransformation -hdmin 100 "$APACHE_LOG"
run_test "hl-hcmin-plotlog-w160"   "$LTL" $HL_COMMON --terminal-width 160 -ic -hcmin 45000 "$PLOT_LOG"
run_test "hl-heatmap-hdmin-w160"   "$LTL" $HL_COMMON -dm raw --terminal-width 160 -hm duration -hdmin 963 "$DPM5K_LOG"
run_test "hl-histogram-hdmin-w160" "$LTL" $HL_COMMON -dm raw --terminal-width 160 -du us -hg duration -hdmin 100 "$APACHE_LOG"
run_test "hl-filelegend-two-files-w160" "$LTL" $HL_COMMON --terminal-width 160 -hdmin 100000 "$DPM5K_LOG" "$PLOT_LOG"

echo ""
echo "Results: $pass passed, $fail failed, $skip skipped"
# TMP_DIR cleanup handled by EXIT trap at top of script

if [[ $fail -gt 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    echo "REGRESSION DETECTED"
    exit 1
else
    echo "ALL TESTS PASSED"
    exit 0
fi
