#!/usr/bin/env bash
# capture-regression.sh — Capture reference output for column layout regression testing
# Usage: ./tests/capture-regression.sh [output_dir]
#
# Runs ltl with --disable-progress -ni and --terminal-width against test logs,
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

# Run from the directory containing the log corpus so the log paths handed
# to ltl below stay relative. ltl records paths verbatim and the file legend
# renders them, so relative paths keep the captured references portable
# across checkouts (#209). That is the repo root unless LTL_LOGS_DIR names a
# corpus elsewhere (#436); it must be named `logs` so the captured prefix is
# unchanged. Must match validate-regression.sh, which replays these commands.
# Everything else here is absolute and unaffected by the cd.
if [[ -n "${LTL_LOGS_DIR:-}" ]]; then
    if [[ ! -d "$LTL_LOGS_DIR" ]]; then
        echo "ERROR: LTL_LOGS_DIR is not a directory: $LTL_LOGS_DIR" >&2
        exit 1
    fi
    if [[ "$(basename "$LTL_LOGS_DIR")" != "logs" ]]; then
        echo "ERROR: LTL_LOGS_DIR must be a directory named 'logs' for this harness;" >&2
        echo "       the captured references embed the literal path prefix 'logs/'." >&2
        echo "       Got: $LTL_LOGS_DIR" >&2
        exit 1
    fi
    cd "$(cd "$(dirname "$LTL_LOGS_DIR")" && pwd)"
else
    cd "$REPO_DIR"
fi

# Common options: suppress progress, summary table, and limit top messages
COMMON="--disable-progress -ni -osum -n 1"

# shellcheck source=lib/fixtures.sh
source "$SCRIPT_DIR/lib/fixtures.sh"

# Transient files (derived fixture, stderr captures) live in a temp directory
# cleaned up unconditionally on exit. They MUST NOT be written into the
# deliverable reference-output directory.
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Test log files. ACCESS_LOG is derived deterministically from the clean
# full-day 2025-05-07 corpus (see tests/lib/fixtures.sh); validate-regression.sh
# derives the identical fixture, so captured references replay byte-for-byte.
ACCESS_LOG="$TMP_DIR/access-sampled.txt"
derive_sampled_access_log "$ACCESS_LOG"
# SCRIPT_LOG is the deterministic 5k-line ScriptLog slice (7-minute span):
# the heatmap/histogram goldens it feeds render a handful of timeline rows
# and one histogram, so the slice carries the whole rendered surface; its
# runs take `-bs 1` so the 7-minute span yields seven timeline rows of
# heatmap cells (tests/HARNESS-DESIGN.md section Invocation coherence).
SCRIPT_LOG="logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean-5k.log"
# Issue #235 — additional fixtures for the extended heatmap/histogram tests
# below. APACHE_LOG is the canonical clean Apache HTTP2 access log; it ships
# bytes + microsecond-%D durations and is small (~100 KB), keeping capture
# time tight.
APACHE_LOG="logs/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log"
# Issue #312 — numeric-highlight rendering fixtures. PLOT_LOG has sparse metric
# presence (durationMS/count on 220 of 2,992 lines); DPM5K_LOG is the
# deterministic 5k-line ScriptLog slice with durationMS on every line.
PLOT_LOG="logs/ThingworxLogs/CustomThingworxLogs/ScriptLog.GetComplexPlotByIndex.log"
DPM5K_LOG="logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean-5k.log"

# Verify test files exist
for f in "$ACCESS_LOG" "$SCRIPT_LOG" "$APACHE_LOG" "$PLOT_LOG" "$DPM5K_LOG"; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: Test file not found: $f"
        exit 1
    fi
done

# Strip ANSI escape codes and non-deterministic lines (timing, memory) from stdin.
#
# The TOP OVERALL MESSAGES block is not part of the layout surface these
# references freeze, so it is dropped. The drop is bounded by the run summary
# that closes the output: the skip ends on the summary's first line -- the rule
# above the Category header, two spaces in and padded on the right -- so the
# category totals, the HIGHLIGHTED row and the file/format legend stay inside
# the captured surface. Per tests/HARNESS-DESIGN.md an anchor that matches
# nothing is a failure: reaching end of input with the skip still open exits 3,
# so a truncated surface aborts instead of being captured. A run invoked with
# -osum prints no summary, and the echoed options line -- which sits under the
# bar graph, ahead of the skipped block -- says so, so such a run has nothing
# to close the skip and is exempt.
# Must match validate-regression.sh exactly.
strip_nondeterministic() {
    perl -pe 's/\e\[[0-9;]*[a-zA-Z]//g; s/\e\[\d*m//g; s/log timeline \[[^\]]+\]/log timeline [VERSION]/' \
    | perl -ne 'BEGIN{$skip=0; $want_summary=1} END{ $? = 3 if $skip && $want_summary } $want_summary=0 if /^(?:environment|command-line) options: / && /(?:^|\s)(?:-osum|--omit-summary)(?=\s|$)/; $skip=1 if /TOP OVERALL/; $skip=0 if /^ {2}(?:─)+ +$/; print unless $skip || /PROCESSING TIME|TOTAL TIME|MAXIMUM MEMORY|INITIALIZE EMPTY|CALCULATE STATISTICS|HEATMAP STATISTICS|HISTOGRAM STATISTICS|GROUP SIMILAR MESSAGES|SCALE DATA|DETECT: FORMAT REGISTRY BUILD|PARSE: FILE PROCESSING|ACCUMULATE: EMPTY BUCKETS|FINALIZE: (?:GROUP SIMILAR|CALCULATE STATISTICS|HEATMAP STATISTICS|HISTOGRAM STATISTICS)|RENDER: SCALE DATA/i'
}

# Create output directory
mkdir -p "$REF_DIR"

count=0
# Stderr captures share the transient temp directory declared above.
STDERR_DIR="$TMP_DIR"

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
    # strip_nondeterministic exits 3 when it reached end of input still skipping,
    # i.e. the run summary that ends the TOP OVERALL skip never appeared. Per
    # tests/HARNESS-DESIGN.md an anchor that matches nothing is a failure —
    # blessing a truncated reference would weaken every later run silently.
    if [[ "${pipe_status[1]}" -ne 0 ]]; then
        echo "  FAIL  $name :: output filter found no run summary to end the TOP OVERALL skip; the reference would be truncated" >&2
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
run_test "scriptlog-w100" "$LTL" $COMMON --terminal-width 100 -os -ov -bs 1 "$SCRIPT_LOG"

echo "ScriptLog at widths 160, 200:"
for w in 160 200; do
    run_test "scriptlog-w${w}" "$LTL" $COMMON --terminal-width $w -bs 1 "$SCRIPT_LOG"
done

# --- Heatmap modes at width 160 ---
# -dm raw pins these captures to the sort-and-index path. The
# unified bin-counter path (#34/#201) is approximate within bin-resolution
# bound and would make the reference fragile to precision tweaks. Layout
# coverage is what we want; bin-counter accuracy is covered by
# tests/validate-histogram-bin-counters.sh.
echo "Heatmap modes at width 160:"
for mode in duration bytes count; do
    run_test "heatmap-${mode}-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hm "$mode" -bs 1 "$SCRIPT_LOG"
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
run_test "autohide-hm-w120" "$LTL" $COMMON -dm raw --terminal-width 120 -hm duration -bs 1 "$SCRIPT_LOG"

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
run_test "heatmap-duration-w80"  "$LTL" $COMMON -dm raw --terminal-width 80  -hm duration -bs 1 "$SCRIPT_LOG"
run_test "heatmap-duration-w100" "$LTL" $COMMON -dm raw --terminal-width 100 -hm duration -bs 1 "$SCRIPT_LOG"
run_test "heatmap-bytes-w120"    "$LTL" $COMMON -dm raw --terminal-width 120 -hm bytes    -bs 1 "$SCRIPT_LOG"
run_test "heatmap-count-w100"    "$LTL" $COMMON -dm raw --terminal-width 100 -hm count    -bs 1 "$SCRIPT_LOG"

echo "Light-background heatmap:"
run_test "heatmap-lbg-duration-w160" "$LTL" $COMMON -dm raw --light-background --terminal-width 160 -hm duration -bs 1 "$SCRIPT_LOG"

echo "Custom heatmap width:"
run_test "heatmap-hmw30-duration-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hm duration -hmw 30 -bs 1 "$SCRIPT_LOG"
run_test "heatmap-hmw80-duration-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hm duration -hmw 80 -bs 1 "$SCRIPT_LOG"

echo "Histogram single-metric across widths:"
run_test "hg-duration-w80"  "$LTL" $COMMON -dm raw --terminal-width 80  -hg duration "$APACHE_LOG"
run_test "hg-duration-w120" "$LTL" $COMMON -dm raw --terminal-width 120 -hg duration "$APACHE_LOG"
run_test "hg-duration-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hg duration "$APACHE_LOG"

echo "Histogram per metric (axis formatters):"
run_test "hg-bytes-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hg bytes "$APACHE_LOG"
run_test "hg-count-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hg count -bs 1 "$SCRIPT_LOG"

echo "Multi-histogram stacked panels:"
run_test "hg-multi-duration-bytes-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hg duration,bytes        "$APACHE_LOG"
run_test "hg-multi-all-w160"            "$LTL" $COMMON -dm raw --terminal-width 160 -hg duration,bytes,count -bs 1 "$SCRIPT_LOG"

echo "Custom histogram dimensions:"
run_test "hg-hgw30-duration-w160"     "$LTL" $COMMON -dm raw --terminal-width 160 -hg duration       -hgw 30 "$APACHE_LOG"
run_test "hg-hgw50-multi-w160"        "$LTL" $COMMON -dm raw --terminal-width 160 -hg duration,bytes -hgw 50 "$APACHE_LOG"
run_test "hg-hgh4-duration-w160"      "$LTL" $COMMON -dm raw --terminal-width 160 -hg duration       -hgh 4  "$APACHE_LOG"
run_test "hg-hgh16-duration-w160"     "$LTL" $COMMON -dm raw --terminal-width 160 -hg duration       -hgh 16 "$APACHE_LOG"

echo "Composition (heatmap + histogram together):"
run_test "hm-hg-duration-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hm duration -hg duration -bs 1 "$SCRIPT_LOG"

# ---------------------------------------------------------------------------
# Issue #312 — numeric highlight criteria rendering coverage
# ---------------------------------------------------------------------------
# Mirror of the additions made to tests/validate-regression.sh; both files
# move in lockstep. HL_COMMON keeps the summary table (no -osum) so the
# HIGHLIGHTED row is part of the captured surface, alongside the bar-prefix
# rendering, the TOP HIGHLIGHTED MESSAGES block, the per-file highlight
# indicator in the file legend, and the histogram/heatmap HL overlays.
# -dm raw on overlay scenarios for the same byte-stability reason as above.
HL_COMMON="--disable-progress -ni -n 1"

echo "Numeric highlight criteria (Issue #312):"
run_test "hl-regex-only-w160"      "$LTL" $HL_COMMON --terminal-width 160 -du us -h BomTransformation "$APACHE_LOG"
run_test "hl-hdmin-w160"           "$LTL" $HL_COMMON --terminal-width 160 -du us -hdmin 100 "$APACHE_LOG"
run_test "hl-hbmin-w160"           "$LTL" $HL_COMMON --terminal-width 160 -du us -hbmin 5000 "$APACHE_LOG"
run_test "hl-regex-hdmin-w160"     "$LTL" $HL_COMMON --terminal-width 160 -du us -h BomTransformation -hdmin 100 "$APACHE_LOG"
run_test "hl-hcmin-plotlog-w160"   "$LTL" $HL_COMMON --terminal-width 160 -ic -hcmin 45000 "$PLOT_LOG"
run_test "hl-heatmap-hdmin-w160"   "$LTL" $HL_COMMON -dm raw --terminal-width 160 -hm duration -hdmin 963 "$DPM5K_LOG"
run_test "hl-histogram-hdmin-w160" "$LTL" $HL_COMMON -dm raw --terminal-width 160 -du us -hg duration -hdmin 100 "$APACHE_LOG"
run_test "hl-filelegend-two-files-w160" "$LTL" $HL_COMMON --terminal-width 160 -hdmin 100000 "$DPM5K_LOG" "$PLOT_LOG"

# ---------------------------------------------------------------------------
# #453 — the error rate reads the per-line failure classification (D13), so
# a highlighted failure counts toward errRate like any other (D12). The
# unhighlighted access run is the R7 parity anchor: its errRate must stay
# 4/d on the ten-status-family fixture; the highlighted runs pin the
# corrected rate (a highlighted 404 still counts: 4/d, not 3/d; a
# highlighted ERROR on a diagnostics log: 2/d, not 1/d).
# ---------------------------------------------------------------------------
FIXTURES="$SCRIPT_DIR/fixtures"
run_test "errrate-access-unhighlighted-w160"          "$LTL" $HL_COMMON --terminal-width 160 -bs 1440 -ru d "$FIXTURES/http-status-families.txt"
run_test "errrate-access-highlighted-failure-w160"    "$LTL" $HL_COMMON --terminal-width 160 -bs 1440 -ru d -h store/missing "$FIXTURES/http-status-families.txt"
run_test "errrate-diagnostics-highlighted-failure-w160" "$LTL" $HL_COMMON --terminal-width 160 -bs 1440 -ru d -h ERROR "$FIXTURES/log-level-vocabulary.txt"

echo "Bin data model renders (Issue #450):"
# ---------------------------------------------------------------------------
# Bin data model — the shipped default for both display surfaces (#450)
# ---------------------------------------------------------------------------
# The -dm raw scenarios above pin the sort-and-index path, which users reach
# only by asking for it: choose_data_model('heatmap') and
# choose_data_model('histogram') both default to 'bin'. Without the block
# below, the rendering users actually get by default was compared against no
# reference at all.
#
# The raw scenarios stay — they assert a different, still-shipped path — so
# each surface now carries both arms and the pair is the raw-vs-bin diff.
#
# -hmdm bin / -hgdm bin rather than -dm bin: each scenario pins only the
# surface it asserts, per HARNESS-DESIGN.md § Invocation coherence. -dm bin
# would additionally flip per-time-bucket statistics, moving the timeline
# P50/P95 cells in every histogram scenario — an unrelated surface inside the
# asserted bytes.
#
# These references are expected to move under #459 (combination arithmetic)
# and #460 (percentile source). That is the point: they are blessed now, before
# those changes, so the diff measures what the changes did.

for mode in duration bytes count; do
    run_test "heatmap-${mode}-w160-bin" "$LTL" $COMMON -hmdm bin --terminal-width 160 -hm "$mode" -bs 1 "$SCRIPT_LOG"
done

run_test "autohide-hm-w120-bin" "$LTL" $COMMON -hmdm bin --terminal-width 120 -hm duration -bs 1 "$SCRIPT_LOG"

run_test "heatmap-duration-w80-bin"  "$LTL" $COMMON -hmdm bin --terminal-width 80  -hm duration -bs 1 "$SCRIPT_LOG"
run_test "heatmap-duration-w100-bin" "$LTL" $COMMON -hmdm bin --terminal-width 100 -hm duration -bs 1 "$SCRIPT_LOG"
run_test "heatmap-bytes-w120-bin"    "$LTL" $COMMON -hmdm bin --terminal-width 120 -hm bytes    -bs 1 "$SCRIPT_LOG"
run_test "heatmap-count-w100-bin"    "$LTL" $COMMON -hmdm bin --terminal-width 100 -hm count    -bs 1 "$SCRIPT_LOG"

run_test "heatmap-lbg-duration-w160-bin" "$LTL" $COMMON -hmdm bin --light-background --terminal-width 160 -hm duration -bs 1 "$SCRIPT_LOG"

run_test "heatmap-hmw30-duration-w160-bin" "$LTL" $COMMON -hmdm bin --terminal-width 160 -hm duration -hmw 30 -bs 1 "$SCRIPT_LOG"
run_test "heatmap-hmw80-duration-w160-bin" "$LTL" $COMMON -hmdm bin --terminal-width 160 -hm duration -hmw 80 -bs 1 "$SCRIPT_LOG"

run_test "hg-duration-w80-bin"  "$LTL" $COMMON -hgdm bin --terminal-width 80  -hg duration "$APACHE_LOG"
run_test "hg-duration-w120-bin" "$LTL" $COMMON -hgdm bin --terminal-width 120 -hg duration "$APACHE_LOG"
run_test "hg-duration-w160-bin" "$LTL" $COMMON -hgdm bin --terminal-width 160 -hg duration "$APACHE_LOG"

run_test "hg-bytes-w160-bin" "$LTL" $COMMON -hgdm bin --terminal-width 160 -hg bytes "$APACHE_LOG"
run_test "hg-count-w160-bin" "$LTL" $COMMON -hgdm bin --terminal-width 160 -hg count -bs 1 "$SCRIPT_LOG"

run_test "hg-multi-duration-bytes-w160-bin" "$LTL" $COMMON -hgdm bin --terminal-width 160 -hg duration,bytes        "$APACHE_LOG"
run_test "hg-multi-all-w160-bin"            "$LTL" $COMMON -hgdm bin --terminal-width 160 -hg duration,bytes,count -bs 1 "$SCRIPT_LOG"

run_test "hg-hgw30-duration-w160-bin"     "$LTL" $COMMON -hgdm bin --terminal-width 160 -hg duration       -hgw 30 "$APACHE_LOG"
run_test "hg-hgw50-multi-w160-bin"        "$LTL" $COMMON -hgdm bin --terminal-width 160 -hg duration,bytes -hgw 50 "$APACHE_LOG"
run_test "hg-hgh4-duration-w160-bin"      "$LTL" $COMMON -hgdm bin --terminal-width 160 -hg duration       -hgh 4  "$APACHE_LOG"
run_test "hg-hgh16-duration-w160-bin"     "$LTL" $COMMON -hgdm bin --terminal-width 160 -hg duration       -hgh 16 "$APACHE_LOG"

run_test "hm-hg-duration-w160-bin" "$LTL" $COMMON -hmdm bin -hgdm bin --terminal-width 160 -hm duration -hg duration -bs 1 "$SCRIPT_LOG"

run_test "hl-heatmap-hdmin-w160-bin"   "$LTL" $HL_COMMON -hmdm bin --terminal-width 160 -hm duration -hdmin 963 "$DPM5K_LOG"
run_test "hl-histogram-hdmin-w160-bin" "$LTL" $HL_COMMON -hgdm bin --terminal-width 160 -du us -hg duration -hdmin 100 "$APACHE_LOG"

echo ""
echo "Captured $count reference files to: $REF_DIR"
echo "Done."
