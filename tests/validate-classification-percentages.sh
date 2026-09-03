#!/usr/bin/env bash
# validate-classification-percentages.sh — the success and failure percentage
# columns, the analysis-overview keys, the UNCLASSIFIED summary row, and the
# qualifying notices (Issue #452).
#
# Derived from features/452-success-failure-percentage-columns.md
# § Acceptance criteria BEFORE implementation (docs/test-driven-development.md):
# these assertions state the requirement, and the feature is done when they
# pass. Written red-first: on the pre-#452 tree every column/key/notice
# assertion fails as a missing anchor.
#
# What it holds:
#   - two value-only columns, success then failure, between occurrences and
#     duration (AC4), rendering the classified-denominator percentage per
#     bucket (AC1) via the shared percentage formatter (AC2);
#   - no bar and the value in the column's own colour (AC3), centred (AC5);
#   - the columns' insertion leaves the following columns' colours unchanged
#     (AC6, durable form: duration and bytes fills pinned to their tables);
#   - auto-hide ordering: failure right after the latency panel, success
#     outliving duration/bytes/count (AC7 — provisional priorities, the
#     inequalities are the contract);
#   - default visibility gated on the event-ledger + both-criteria ladder
#     (AC8), one option pair --hide-classification/--show-classification
#     (AC9/D8);
#   - overview keys on format-detection / classification numerically equal to
#     the shipped counters (AC10/D5);
#   - the UNCLASSIFIED summary row (R13) and run-level share suppression on a
#     non-qualifying run (D10);
#   - notice 3 on an explicit request against formats without both criteria,
#     and silence on a clean qualifying run (AC11 — notice 1 and the
#     non-zero-leakage notice 2 have no shipped format that can produce their
#     condition; recorded as gaps in the feature doc § Scenario-design
#     findings, not asserted here).
#
# Timeline cells are read through the column selector
# (tests/lib/rendered-output.sh timeline_cell_report; method:
# prototype/452-timeline-cell-selector/FINDINGS.md) — never by escape-code
# grepping (HARNESS-DESIGN.md § Asserting rendered output).
#
# Invocation shape (HARNESS-DESIGN.md § Invocation coherence): the fixtures
# span five hourly buckets of a single day, run at -bs 60 so every bucket is
# one row; -ni keeps the developer's index out; -lf pins the access format so
# no filename-evidence note fires; -n 1 keeps the messages table minimal.
#
# Usage: ./tests/validate-classification-percentages.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

LTL="$REPO_DIR/ltl"
PERL="${PERL:-/opt/homebrew/bin/perl}"
command -v "$PERL" >/dev/null 2>&1 || PERL=perl
export PERL

ACCESS_FIXTURE="$REPO_DIR/tests/fixtures/access-classification-buckets.txt"
DIAG_FIXTURE="$REPO_DIR/tests/fixtures/diagnostics-classification-overlap.txt"
GC_FIXTURE="$REPO_DIR/tests/fixtures/gc-g1-categories.txt"
ACCESS_FORMAT="access_common_duration_ms"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/rendered-output.sh
source "$SCRIPT_DIR/lib/rendered-output.sh"

neutralize_colour_env

for f in "$LTL" "$ACCESS_FIXTURE" "$DIAG_FIXTURE" "$GC_FIXTURE"; do
    [[ -e "$f" ]] || { echo "ERROR: missing $f"; exit 1; }
done

TMP_DIR=$(mktemp -d); trap 'rm -rf "$TMP_DIR"' EXIT

pass=0; fail=0; failures=(); current_scenario=""

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
    local cmd_out cmd_rc
    set +e
    cmd_out=$(eval "$command" 2>&1); cmd_rc=$?
    set -e
    if [[ "$cmd_rc" -eq 0 ]]; then
        echo "  PASS  $current_scenario :: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario :: $label"
        echo "        command:     $command"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        echo "$cmd_out" | sed 's/^/        | /'
        fail=$((fail + 1))
        failures+=("$current_scenario :: $label")
    fi
}

# capture_run OUTFILE WIDTH EXTRA_ARGS... — one ltl render with ANSI intact,
# --debug-layout so the column selector has its offsets, stderr to
# OUTFILE.stderr. Non-zero exit or empty capture is a hard failure.
capture_run() {
    local outfile="$1"; shift
    local width="$1"; shift
    local rc
    set +e
    with_ansi_colour "$LTL" --disable-progress --terminal-width "$width" \
        -ni -bs 60 -n 1 --debug-layout "$@" > "$outfile" 2> "$outfile.stderr"
    rc=$?
    set -e
    if [[ $rc -ne 0 || ! -s "$outfile" ]]; then
        echo "ERROR: capture failed (rc=$rc) for: $*" >&2
        cat "$outfile.stderr" >&2
        exit 1
    fi
    # The debug-layout table prints on stderr; the column selector reads it
    # from the capture, so append the delimited block (and only it) here.
    sed -n '/^--- Layout Engine Debug/,/^---$/p' "$outfile.stderr" >> "$outfile"
    grep -q '^--- Layout Engine Debug' "$outfile" || {
        echo "ERROR: no debug-layout table on stderr for: $*" >&2; exit 1; }
}

# cell REPORT_CAPTURE ROW COL -> the timeline_cell_report line (fails hard on
# missing row/column per the selector's own contract).
cell() { timeline_cell_report "$1" "$2" "$3"; }

# layout_field CAPTURE COL FIELD -> start|width|hideo|vis for one debug-table
# row; zero-match is a hard failure.
layout_field() {
    local capture="$1" col="$2" field="$3"
    "$PERL" -ne '
        BEGIN { my %i = (width=>2, bef=>3, aft=>4, vis=>5, hideo=>6); $::f = $i{$ARGV[1] // ""} }
        next unless /^\s*'"$col"'\s+\S+\s+(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*(?:\(auto-hidden\))?\s*$/;
        my @v = ($1,$2,$3,$4,$5);
        my %idx = (width=>0, bef=>1, aft=>2, vis=>3, hideo=>4);
        print $v[$idx{"'"$field"'"}], "\n"; exit 0;
    ' "$capture" | { read -r v && echo "$v" || { echo "COLUMN-NOT-IN-TABLE" ; return 1; }; }
}

# ---------------------------------------------------------------------------
# Capture A: qualifying access run, width 160.
A="$TMP_DIR/access-160.out"
capture_run "$A" 160 -lf "$ACCESS_FORMAT" -V format-detection "$ACCESS_FIXTURE"
# Capture A2: width 120 (auto-hide active).
A2="$TMP_DIR/access-120.out"
capture_run "$A2" 120 -lf "$ACCESS_FORMAT" "$ACCESS_FIXTURE"
# Capture A3: width 120 with the heatmap (which hides last), so the failure
# column is the top hide candidate — the width point where the R5 ladder is
# observable on rendered layout. Used ONLY for the visibility assertion: the
# heatmap's own overflow at this width is the filed #497 defect, so this
# capture is deliberately not in the soft-wrap sweep.
A3="$TMP_DIR/access-120-hm.out"
capture_run "$A3" 120 -lf "$ACCESS_FORMAT" -hm duration "$ACCESS_FIXTURE"
# Capture H: --hide-classification.
H="$TMP_DIR/access-hidden.out"
capture_run "$H" 160 -lf "$ACCESS_FORMAT" --hide-classification "$ACCESS_FIXTURE"
# Capture D0: diagnostics run, default.
D0="$TMP_DIR/diag-default.out"
capture_run "$D0" 160 "$DIAG_FIXTURE"
# Capture D1: diagnostics run, explicit enable.
D1="$TMP_DIR/diag-show.out"
capture_run "$D1" 160 --show-classification "$DIAG_FIXTURE"
# Capture G1: declining ledger, explicit enable.
G1="$TMP_DIR/gc-show.out"
capture_run "$G1" 160 --show-classification "$GC_FIXTURE"
# Capture M: mixed access + diagnostics run.
M="$TMP_DIR/mixed.out"
capture_run "$M" 160 -V format-detection "$ACCESS_FIXTURE" "$DIAG_FIXTURE"
# Capture M2: the same mixed run explicitly enabled.
M2="$TMP_DIR/mixed-show.out"
capture_run "$M2" 170 --show-classification "$ACCESS_FIXTURE" "$DIAG_FIXTURE"
# Capture SM: the diagnostics run under -sm, for the monochrome half of the
# summary-row colour contract (the same rows as D0, with no colour to apply).
SM="$TMP_DIR/diag-mono.out"
capture_run "$SM" 160 -sm "$DIAG_FIXTURE"

# ---------------------------------------------------------------------------
current_scenario="column-placement"

assert_command \
    label "success_pct and failure_pct sit right of the legend, before the legend|graph separator (AC4, R1, R7; placement corrected by the architect 2026-08-31)" \
    command "$PERL -ne 'push @o, \$1 if /^\\s*(\\S+)\\s+\\S+\\s+\\S+\\s+\\d+\\s+\\d+\\s+\\d+\\s+\\d+\\s*\$/; END { my \$ids = join(q{,}, @o); exit(\$ids =~ /legend,success_pct,failure_pct,sep_legend_graph,occurrences/ ? 0 : 1) }' '$A'" \
    asserts "the two new layout entries are declared in array order after the legend and before the legend|graph separator, and both render by default on an all-ledger both-criteria run" \
    produced_by "build_column_layout() in ltl" \
    contract "features/452-success-failure-percentage-columns.md R1 placement, D4 default-on ladder"

# ---------------------------------------------------------------------------
current_scenario="bucket-values"

bucket_expect() {  # ROW SUCCESS_TEXT FAILURE_TEXT LABEL
    local row="$1" s_want="$2" f_want="$3" label="$4"
    assert_command \
        label "$label" \
        command "s=\$(cell '$A' '^ $row' success_pct) && f=\$(cell '$A' '^ $row' failure_pct) && [[ \$s == *\"text='\"*\"$s_want\"* ]] && [[ \$f == *\"text='\"*\"$f_want\"* ]] || { echo \"success: \$s\"; echo \"failure: \$f\"; false; }" \
        asserts "the rendered cell values are the classified-denominator percentages: successes/(successes+failures) per bucket, formatted by format_percentage() significant mode — the same rule the category and classified summary shares use (architect correction 2026-08-31)" \
        produced_by "normalize_data_for_output() derives the per-bucket ratio from %bucket_outcomes; the render step prints it via format_percentage()" \
        contract "features/452-success-failure-percentage-columns.md AC1/AC2/AC14, docs/percentage-presentation.md (significant/3, trailing zeros trimmed)"
}

bucket_expect '2025-05-07 00:00' '75%'     '25%'      "3 successes + 1 failure reads 75% / 25% (AC1)"
bucket_expect '2025-05-07 02:00' '0%'      '100%'     "failures-only bucket reads 0% success / 100% failure, never blank (AC14)"
bucket_expect '2025-05-07 03:00' '100%'    '0%'       "successes-only bucket reads 100% / 0%, never 100.000% (AC2)"
bucket_expect '2025-05-07 04:00' '33.3%' '66.7%'  "1 of 3 renders under the significant-digits rule the summary shares use: 33.3% / 66.7% (AC2)"

assert_command \
    label "an empty bucket renders both cells blank — a measured 0% and an absent measurement never look the same (AC14, D11)" \
    command "s=\$(cell '$A' '^ 2025-05-07 01:00' success_pct) && f=\$(cell '$A' '^ 2025-05-07 01:00' failure_pct) && [[ \$s == *'centred=empty'* && \$f == *'centred=empty'* ]] || { echo \"success: \$s\"; echo \"failure: \$f\"; false; }" \
    asserts "a bucket with no classified line (no %bucket_outcomes entry) renders blank cells, not 0%" \
    produced_by "normalize_data_for_output() leaves the derived value unset for a bucket without outcomes; the render step prints nothing" \
    contract "features/452-success-failure-percentage-columns.md D11, F9; CLAUDE.md § Before writing or changing code (derived output is gated on an observation count, never on defined-ness)"

# ---------------------------------------------------------------------------
current_scenario="value-only-rendering"

assert_command \
    label "no bar: fill extent 0 in both cells; value text carries each column's own colour, green vs red distinct (AC3, D1, D14)" \
    command "s=\$(cell '$A' '^ 2025-05-07 00:00' success_pct) && f=\$(cell '$A' '^ 2025-05-07 00:00' failure_pct) && [[ \$s == *'extent=0'* && \$f == *'extent=0'* ]] && sfg=\$(sed -E 's/.* fg=([^ ]+).*/\\1/' <<<\"\$s\") && ffg=\$(sed -E 's/.* fg=([^ ]+).*/\\1/' <<<\"\$f\") && [[ \$sfg =~ ^(ansi:32|256:(2|22|28|34|64|70))\$ ]] && [[ \$ffg =~ ^(ansi:31|256:(1|52|88|124|160))\$ ]] && [[ \$sfg != \"\$ffg\" ]] || { echo \"success: \$s\"; echo \"failure: \$f\"; false; }" \
    asserts "the columns are value-only (no background fill anywhere in the cell) and the values print in a kelly-green / rosso-corsa named colour definition, not via any @column_colors index" \
    produced_by "the value-only flag on the layout entry read by the render step; named colour definitions per D14" \
    contract "features/452-success-failure-percentage-columns.md AC3, D1, D14 (exact shade locked at tuning; the family and distinctness are the contract)"

assert_command \
    label "values are centred in the cell, extra space on the left on an odd remainder (AC5, R4)" \
    command "for row in '00:00' '02:00' '03:00' '04:00'; do s=\$(cell '$A' \"^ 2025-05-07 \$row\" success_pct); [[ \$s == *'centred=centred'* ]] || { echo \"\$row success: \$s\"; exit 1; }; f=\$(cell '$A' \"^ 2025-05-07 \$row\" failure_pct); [[ \$f == *'centred=centred'* ]] || { echo \"\$row failure: \$f\"; exit 1; }; done" \
    asserts "every non-blank value is centred within the column's characters, the header-rule geometry (odd remainder leaves the extra space left)" \
    produced_by "the centred value print in the render step" \
    contract "features/452-success-failure-percentage-columns.md AC5 (method: centred_report(), prototype/452-timeline-cell-selector/FINDINGS.md)"

# ---------------------------------------------------------------------------
current_scenario="following-columns-unchanged"

assert_command \
    label "duration and bytes render their own colour tables after the insertion (AC6, R6, D14)" \
    command "d=\$('$PERL' -e 'require \$ARGV[0]; my \$l = parse_debug_layout(\$ARGV[1]); open my \$fh, \"<:encoding(UTF-8)\", \$ARGV[1] or die; while (<\$fh>) { (my \$p = \$_) =~ s/\\e\\[[0-9;]*m//g; next unless \$p =~ /^ 2025-05-07 03:00/; my \$c = decode_line(\$_); for my \$id (qw(duration bytes)) { my \$s = column_slice(\$c, \$l, \$id); print \$id, \"=\", fill_colour(\$s), \"\\n\"; } exit 0 } die \"row not found\\n\"' '$SCRIPT_DIR/lib/rendered-output.pl' '$A') && grep -q 'duration=256:184\\|duration=256:226\\|duration=MIXED:256:184,256:226' <<<\"\$d\" && grep -q 'bytes=256:34\\|bytes=256:46\\|bytes=MIXED:256:34,256:46' <<<\"\$d\" || { echo \"\$d\"; false; }" \
    asserts "the columns after the insertion point keep their own fill tables: duration yellow (226/184), bytes green (46/34) — the new columns consume no palette index, so the dynamic-column colour walk is unchanged" \
    produced_by "print_bar_graph() colour resolution by column id; the new columns use named colour definitions (D14)" \
    contract "features/452-success-failure-percentage-columns.md AC6, F4; features/column-layout-refactor.md § Colour Scheme Requirements"

# ---------------------------------------------------------------------------
current_scenario="auto-hide-ordering"

assert_command \
    label "hide priorities: latency first, failure_pct immediately after; success_pct outlives duration, bytes and count (AC7, R5)" \
    command "lat=\$(layout_field '$A' latency hideo) && fp=\$(layout_field '$A' failure_pct hideo) && sp=\$(layout_field '$A' success_pct hideo) && dur=\$(layout_field '$A' duration hideo) && byt=\$(layout_field '$A' bytes hideo) && occ=\$(layout_field '$A' occurrences hideo) && (( lat > fp )) && (( fp > byt )) && (( fp > dur )) && (( sp < dur )) && (( sp < byt )) && (( sp > occ )) || { echo \"lat=\$lat fp=\$fp sp=\$sp dur=\$dur byt=\$byt occ=\$occ\"; false; }" \
    asserts "auto-hide order (higher hides first): latency > failure_pct > duration/bytes/count, and occurrences < success_pct < duration — the inequalities are the contract, exact values are the R5 tuning item" \
    produced_by "the hide-order values declared in build_column_layout()" \
    contract "features/452-success-failure-percentage-columns.md AC7, R5 (provisional priorities, locked after tuning)"

assert_command \
    label "under width pressure the failure column hides first and success survives (AC7; -hm 120, where the ladder binds)" \
    command "fpv=\$(layout_field '$A3' failure_pct vis) && spv=\$(layout_field '$A3' success_pct vis) && [[ \$fpv == 0 && \$spv == 1 ]] || { echo \"failure vis=\$fpv success vis=\$spv\"; false; }" \
    asserts "as width shrinks the failure column is among the first hidden while the success column persists — on the default view every supported width fits both once the latency panel goes, so the binding point is the heatmap view" \
    produced_by "the width-allocation auto-hide pass in build_column_layout()" \
    contract "features/452-success-failure-percentage-columns.md AC7 (width point re-checked at tuning lock)"

# ---------------------------------------------------------------------------
current_scenario="options"

assert_command \
    label "--hide-classification removes exactly the two columns (AC9, D8)" \
    command "[[ \$(layout_field '$H' success_pct vis) == 0 && \$(layout_field '$H' failure_pct vis) == 0 && \$(layout_field '$H' duration vis) == 1 ]]" \
    asserts "the hide option turns the pair off where it is on by default, leaving every other column's visibility untouched" \
    produced_by "the single-sited visibility gate (D15) reading the hide option" \
    contract "features/452-success-failure-percentage-columns.md D8, D15, AC9"

# ---------------------------------------------------------------------------
current_scenario="overview-parity"

assert_command \
    label "overview keys equal the shipped counters: success_pct 60, failure_pct 40 over classified 15 (AC10, D5, D13)" \
    command "sed -n '/=== format-detection \\/ classification ===/,/=== END format-detection \\/ classification ===/p' '$A' > '$TMP_DIR/cls.block' && [[ -s '$TMP_DIR/cls.block' ]] && awk -F': ' '\$1==\"successes\"{s=\$2} \$1==\"failures\"{f=\$2} \$1==\"classified\"{c=\$2} \$1==\"success_pct\"{sp=\$2} \$1==\"failure_pct\"{fp=\$2} END { if (c != s+f) { print \"classified \" c \" != \" s+f; exit 1 }; if (sp==\"\" || fp==\"\") { print \"pct keys missing\"; exit 1 }; ds = sp - (s/c*100); df = fp - (f/c*100); if (ds<0) ds=-ds; if (df<0) df=-df; if (ds>0.05 || df>0.05) { print \"pct drift: \" sp \" vs \" s/c*100 \", \" fp \" vs \" f/c*100; exit 1 } }' '$TMP_DIR/cls.block'" \
    asserts "the overall percentages are computed from the totalised counts over the classified denominator — one reconciliation sub, no second accumulator — and land as additive keys on the existing classification block" \
    produced_by "the shared reconciliation sub (D13) feeding emit_format_detection_verbose()" \
    contract "features/452-success-failure-percentage-columns.md AC10, D5, D13; HARNESS-DESIGN stability contract (additive keys)"

assert_command \
    label "the run-level eligibility state is observable: pct_eligible 1 on the qualifying run (D5)" \
    command "grep -q '^pct_eligible: 1' '$TMP_DIR/cls.block'" \
    asserts "the printed-or-blank decision is observable on the -V surface" \
    produced_by "emit_format_detection_verbose() emitting the D2/D4 run-level resolution" \
    contract "features/452-success-failure-percentage-columns.md D5"

# ---------------------------------------------------------------------------
current_scenario="non-qualifying-run"

assert_command \
    label "columns absent by default on a classifying non-ledger run (AC8, D4)" \
    command "[[ \$(layout_field '$D0' success_pct vis) == 0 && \$(layout_field '$D0' failure_pct vis) == 0 ]]" \
    asserts "default-off when the matched formats are not qualifying event ledgers" \
    produced_by "the single-sited visibility gate (D15) evaluating the D2/D4 ladder" \
    contract "features/452-success-failure-percentage-columns.md AC8, D4"

assert_command \
    label "no UNCLASSIFIED row on a fully-classified run — the row prints only when non-zero (R13; architect 2026-08-31)" \
    command "! grep -q 'UNCLASSIFIED' '$A'" \
    asserts "a permanent zero row is noise; leakage is surfaced only when it exists" \
    produced_by "print_summary_table() gating the row on a non-zero unclassified count" \
    contract "features/452-success-failure-percentage-columns.md R13 zero-suppression"

assert_command \
    label "LINES READ precedes LINES INCLUDED in the summary tallies (architect 2026-08-31)" \
    command "r=\$(grep -n 'LINES READ' '$A' | head -1 | cut -d: -f1) && i=\$(grep -n 'LINES INCLUDED' '$A' | head -1 | cut -d: -f1) && (( r < i ))" \
    asserts "the tally block reads as a funnel: lines read, then lines included, then the classified breakdown" \
    produced_by "print_summary_table() row order" \
    contract "features/452-success-failure-percentage-columns.md § summary-row order (architect instruction 2026-08-31)"

assert_command \
    label "the UNCLASSIFIED summary row carries count and share of included lines: 2 (50%) (R13, R14)" \
    command "grep -E 'UNCLASSIFIED' '$D0' | grep -qE '2 \\(50(\\.0*)?%\\)'" \
    asserts "matched lines that matched neither classification are surfaced as their own run-summary row over the included-lines denominator — leakage is called out, never absorbed" \
    produced_by "print_summary_table() rendering the unclassified count via share_row_text()" \
    contract "features/452-success-failure-percentage-columns.md R13, R14 (vocabulary pinned by the architect 2026-08-31)"

assert_command \
    label "explicit request against a format without both criteria: no columns, notice 3 explains why (AC8, AC11, D4)" \
    command "[[ \$(layout_field '$D1' success_pct vis) == 0 && \$(layout_field '$D1' failure_pct vis) == 0 ]] && grep -q 'percentage columns are not shown' '$D1.stderr'" \
    asserts "an explicit --show-classification against formats that do not declare both success and failure criteria shows no columns and says why, rather than leaving them silently absent" \
    produced_by "the post-read notice emission (D12) evaluating the D4 floor" \
    contract "features/452-success-failure-percentage-columns.md R9 notice 3, D4"

assert_command \
    label "declining ledger (java_gc_g1) explicitly requested: no columns, notice 3 (AC8, F8)" \
    command "[[ \$(layout_field '$G1' success_pct vis) == 0 && \$(layout_field '$G1' failure_pct vis) == 0 ]] && grep -q 'percentage columns are not shown' '$G1.stderr'" \
    asserts "a format that declares classification 'none' is treated as declaring no criteria: notice 3, never the leakage warning (F8's misfire is prevented by the D2 predicate)" \
    produced_by "the post-read notice emission (D12)" \
    contract "features/452-success-failure-percentage-columns.md F8, D2, R9 notice 3"

# ---------------------------------------------------------------------------
current_scenario="mixed-run"

assert_command \
    label "mixed run: run-level percentages suppressed everywhere — pct_eligible 0, no pct keys, classified-row shares suppressed (AC15, D2, D10)" \
    command "sed -n '/=== format-detection \\/ classification ===/,/=== END format-detection \\/ classification ===/p' '$M' > '$TMP_DIR/mixed.block' && [[ -s '$TMP_DIR/mixed.block' ]] && grep -q '^pct_eligible: 0' '$TMP_DIR/mixed.block' && ! grep -qE '^(success_pct|failure_pct):' '$TMP_DIR/mixed.block' && grep -E 'SUCCESS CLASSIFIED' '$M' | grep -vq '(' " \
    asserts "a run with any non-qualifying contribution prints no run-level percentages on any surface: the -V keys are absent, the eligibility state says why, and the summary rows keep counts but drop their shares" \
    produced_by "the shared reconciliation sub (D13) gated by the D2 run-level predicate; print_summary_table() share suppression" \
    contract "features/452-success-failure-percentage-columns.md R12, D10, AC15 (bucket-level cells: pending the D2/D4 mixed-run visibility resolution, feature doc § Open decisions)"

assert_command \
    label "mixed run default: columns not rendered — visibility is the format test, not data eligibility (AC15, D4)" \
    command "[[ \$(layout_field '$M' success_pct vis) == 0 && \$(layout_field '$M' failure_pct vis) == 0 ]]" \
    asserts "default-on requires every bound file's format to be an event ledger declaring both criteria; a mixed run fails that test" \
    produced_by "classification_columns_visible() reading per-file event_ledger/cls_both" \
    contract "features/452-success-failure-percentage-columns.md D4 (visibility is a render-surface question — architect correction 2026-08-31)"

assert_command \
    label "mixed run + --show-classification: columns render; ineligible buckets print counts, qualifying buckets print shares; notice 1 fires (AC15, AC18, R12, D2)" \
    command "[[ \$(layout_field '$M2' success_pct vis) == 1 ]] && s0=\$(cell '$M2' '^ 2025-05-07 00:00' success_pct) && f0=\$(cell '$M2' '^ 2025-05-07 00:00' failure_pct) && s3=\$(cell '$M2' '^ 2025-05-07 03:00' success_pct) && s4=\$(cell '$M2' '^ 2025-05-07 04:00' failure_pct) && [[ \$s0 == *\"text='\"*'3'* && \$s0 != *'%'* ]] && [[ \$f0 == *\"text='\"*'2'* && \$f0 != *'%'* ]] && [[ \$s3 == *\"text='\"*'100%'* ]] && [[ \$s4 == *'66.7%'* ]] && grep -q 'cover only operations the log records' '$M2.stderr' || { echo \"s0=\$s0\"; echo \"f0=\$f0\"; echo \"s3=\$s3\"; echo \"s4=\$s4\"; false; }" \
    asserts "per-bucket eligibility is a data question independent of visibility: a bucket touched by a source that cannot report a success shows the counts the share would have been built from — never a share, and never blank, which would read as a window with no successes and no failures — while an untouched bucket keeps its stable figure and the partial-coverage caution names the blind spots" \
    produced_by "normalize_data_for_output() per-bucket derivation gated on %bucket_outcomes slot 3; emit_classification_percentage_notices()" \
    contract "features/452-success-failure-percentage-columns.md R12/D2, R9 notice 1"

assert_command \
    label "an ineligible window with no successes shows the count 0, not a blank cell (AC18, D2 as amended)" \
    command "s=\$(cell '$M2' '^ 2025-05-07 02:00' success_pct) && f=\$(cell '$M2' '^ 2025-05-07 02:00' failure_pct) && [[ \$s == *\"text='\"*'0'* && \$s != *'%'* ]] && [[ \$f == *\"text='\"*'4'* ]] || { echo \"success: \$s\"; echo \"failure: \$f\"; false; }" \
    asserts "a measured zero in an ineligible window is reported as a zero count: the D11 blank is reserved for a window with no classified line at all, so the two remain distinguishable after the count fallback was added" \
    produced_by "normalize_data_for_output() setting the *_count keys on a slot-3 bucket with classified lines; the value-only render branch choosing format_number over format_percentage" \
    contract "features/452-success-failure-percentage-columns.md D2 as amended (architect, 2026-09-01), D11, AC18"

# ---------------------------------------------------------------------------
current_scenario="summary-row-colour"

assert_command \
    label "the classified summary rows carry the classification shades: success kelly-green, failure rosso-corsa (D14)" \
    command "grep -aE $'\\033\\[38;5;34m *SUCCESS CLASSIFIED' '$A' >/dev/null && grep -aE $'\\033\\[38;5;160m *FAILURE CLASSIFIED' '$A' >/dev/null" \
    asserts "an outcome reads in one colour wherever the run reports it: the summary rows take the same named definitions as the timeline's percentage columns, not a colour of their own" \
    produced_by "the classified-row emitter in print_summary_table() resolving through summary_colour()" \
    contract "features/452-success-failure-percentage-columns.md D14"

assert_command \
    label "the UNCLASSIFIED summary row carries the gold shade, distinct from both outcome colours (D14)" \
    command "grep -aE $'\\033\\[38;5;178m *UNCLASSIFIED' '$D0' >/dev/null" \
    asserts "the row for lines that are neither a success nor a failure is told apart from both at a glance, in a third named definition" \
    produced_by "the classified-row emitter in print_summary_table() resolving through summary_colour()" \
    contract "features/452-success-failure-percentage-columns.md D14"

assert_command \
    label "-sm renders the same rows with no colour at all (D14, -sm contract)" \
    command "! grep -aE 'CLASSIFIED|CONFLICT|MIXED' '$SM' | grep -aE $'\\033\\[38;5;(34|160|178|173|135)m' >/dev/null && grep -aq 'UNCLASSIFIED' '$SM'" \
    asserts "monochrome is a property of the whole summary table: the classified rows inherit the switch through summary_colour() rather than reading %colors directly, so none of the classification shades survives -sm on a summary row (the message blocks' classification indicator is outside -sm, which renders the run summary table alone)" \
    produced_by "summary_colour() returning empty under \$summary_mono" \
    contract "features/452-success-failure-percentage-columns.md D14; ltl summary_colour()"

# ---------------------------------------------------------------------------
current_scenario="share-omission-notice"

assert_command \
    label "a run whose shares are withheld says why, naming the formats that define no success rule (R9)" \
    command "grep -q 'shares are omitted' '$M.stderr' && grep -q 'these formats define no success rule: windchill_method_server' '$M.stderr'" \
    asserts "when the classified rows drop their shares because a contributing format can report failures but never successes, the run says so and names that format — the reader is not left to infer why two percentages vanished" \
    produced_by "emit_classification_percentage_notices(), outside the columns-visible gate: the summary rows print whether or not the timeline columns do" \
    contract "features/452-success-failure-percentage-columns.md R9 notice 4, D10"

# ---------------------------------------------------------------------------
current_scenario="clean-run-hygiene"

assert_command \
    label "no qualifying notice fires on a clean, fully-classified ledger run (AC11)" \
    command "! grep -qE 'percentage columns are not shown|matched neither the success nor the failure classification|cover only operations the log records|shares are omitted' '$A.stderr'" \
    asserts "the qualifying notices are mutually exclusive by condition and silent when no condition holds — including the share-omission notice, which has nothing to say on a run whose shares print" \
    produced_by "the post-read notice emission (D12)" \
    contract "features/452-success-failure-percentage-columns.md R9, AC11"

for cap in "$A" "$A2" "$H" "$D0" "$D1" "$G1" "$M" "$M2" "$SM"; do
    label_name=$(basename "$cap")
    assert_command \
        label "no runtime warnings on stderr ($label_name)" \
        command "assert_no_runtime_warnings '$cap.stderr' '$label_name'" \
        asserts "no ' at ltl line N' unguarded data path fires on any scenario run" \
        produced_by "any sub touched by this feature" \
        contract "tests/HARNESS-DESIGN.md § Runtime-warning cleanliness"
done

current_scenario="soft-wrap"
for spec in "$A:160" "$A2:120" "$M:160"; do
    cap="${spec%%:*}"; w="${spec##*:}"
    wrap_scenario="classification-percentages-w$w-$(basename "$cap" .out)"
    wrap_issue=$(soft_wrap_known_failure "$wrap_scenario")
    if assert_no_soft_wrap "$cap" "$w" "$wrap_scenario" 2>/dev/null; then
        if [[ -n "$wrap_issue" ]]; then
            echo "  XPASS $wrap_scenario :: no longer exceeds its terminal width — remove its entry from tests/rendered-output/soft-wrap-known-failures.tsv (#$wrap_issue)"
        else
            echo "  PASS  soft-wrap :: output fits $w columns ($(basename "$cap"))"
        fi
        pass=$((pass + 1))
    elif [[ -n "$wrap_issue" ]]; then
        wrap_detail=$(assert_no_soft_wrap "$cap" "$w" "$wrap_scenario" 2>&1 >/dev/null || true)
        printf '%s\n' "${wrap_detail//  FAIL /  XFAIL}" >&2
        echo "  XFAIL soft-wrap :: $wrap_scenario exceeds its terminal width — known, #$wrap_issue"
        pass=$((pass + 1))
    else
        echo "  FAIL  soft-wrap :: output does not fit $w columns ($(basename "$cap"))"
        assert_no_soft_wrap "$cap" "$w" "$wrap_scenario" || true
        fail=$((fail + 1))
        failures+=("soft-wrap :: $wrap_scenario")
    fi
done

# ---------------------------------------------------------------------------
echo
echo "Results: $pass passed, $fail failed"
if [[ $fail -gt 0 ]]; then
    echo "Failed:"
    for f in "${failures[@]}"; do echo "  - $f"; done
    exit 1
fi
exit 0
