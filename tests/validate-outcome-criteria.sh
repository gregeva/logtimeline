#!/usr/bin/env bash
# validate-outcome-criteria.sh — the success/failure filter and highlight
# criteria (-if/-ef/-is/-es, -hf/-hs) (Issue #455).
#
# Derived from features/455-success-failure-filter-highlight-criteria.md
# § Acceptance criteria: filters select on the classification outcome the
# format produced and shift every computed statistic (AC1/AC2); excluding
# both outcomes leaves exactly the unclassified remainder (AC3); highlights
# mark through the existing highlight mechanism without changing the analysed
# population (AC4) and AND-compose with the other highlight families (AC5);
# an outcome filter enters the index-cache filter signature (AC6); the
# retired option names are rejected and the renamed ones accepted (AC7/AC8);
# all six options are inert on lines classified to neither outcome and on
# formats that declare no rule for the named outcome (AC9).
#
# State assertions read the format-detection / classification -V block
# (lines_included, successes, failures, unclassified) per the
# application-observability contract; the HIGHLIGHTED summary row is read as
# the highlight mechanism's own marker, ANSI-stripped.
#
# Invocation shape (HARNESS-DESIGN.md § Invocation coherence): counter and
# selection assertions never read a time bucket, so every run uses -bs 1440
# -oe -n 1 -ni on the smallest fixture carrying the signal; the index
# scenario drops -ni because the index is its subject and runs in its own
# temp dir.
#
# Usage: ./tests/validate-outcome-criteria.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

LTL="$REPO_DIR/ltl"

ACCESS_FIXTURE="$REPO_DIR/tests/fixtures/access-classification-buckets.txt"
DIAG_FIXTURE="$REPO_DIR/tests/fixtures/diagnostics-classification-overlap.txt"
GC_FIXTURE="$REPO_DIR/tests/fixtures/gc-g1-categories.txt"
ACCESS_FORMAT="access_common_duration"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"

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

# capture OUTFILE EXTRA_ARGS... — one counter-shaped run: coarsest bucket, no
# empty buckets, minimal messages table, classification block requested.
# Non-zero exit or empty capture is a hard failure.
capture() {
    local outfile="$1"; shift
    local rc
    set +e
    "$LTL" --disable-progress -bs 1440 -oe -n 1 -ni -V format-detection "$@" \
        > "$outfile" 2> "$outfile.stderr"
    rc=$?
    set -e
    if [[ $rc -ne 0 || ! -s "$outfile" ]]; then
        echo "ERROR: capture failed (rc=$rc) for: $*" >&2
        cat "$outfile.stderr" >&2
        exit 1
    fi
}

# cls_key CAPTURE KEY -> the value of one classification-block key; a missing
# block or key is a hard failure, never an empty string.
cls_key() {
    local capture="$1" key="$2"
    grep -qE '^=== format-detection / classification ===$' "$capture" || {
        echo "MISSING-CLASSIFICATION-BLOCK"; return 1; }
    local v
    v=$(sed -n '/^=== format-detection \/ classification ===/,/^=== END format-detection \/ classification ===/p' "$capture" \
        | sed -n "s/^$key: //p" | head -1)
    [[ -n "$v" ]] || { echo "MISSING-KEY-$key"; return 1; }
    echo "$v"
}

# highlighted_count CAPTURE -> the HIGHLIGHTED summary-row count,
# ANSI-stripped; zero-match is a hard failure.
highlighted_count() {
    local capture="$1" v
    v=$(sed -E $'s/\x1b\\[[0-9;]*m//g' "$capture" \
        | sed -n -E 's/^ *HIGHLIGHTED +([0-9]+).*$/\1/p' | head -1)
    [[ -n "$v" ]] || { echo "MISSING-HIGHLIGHTED-ROW"; return 1; }
    echo "$v"
}

# ---------------------------------------------------------------------------
# Captures. Access fixture: 15 lines — 9 success (2xx), 6 failure (4xx/5xx),
# 0 unclassified. Diagnostics fixture: 4 lines — 2 ERROR (failure), 2 INFO
# (unclassified); the format declares no success rule. GC fixture: the format
# declines classification, so every included line is unclassified.
B="$TMP_DIR/base.out";        capture "$B"    -lf "$ACCESS_FORMAT" "$ACCESS_FIXTURE"
IF="$TMP_DIR/inc-fail.out";   capture "$IF"   -if -lf "$ACCESS_FORMAT" "$ACCESS_FIXTURE"
IS="$TMP_DIR/inc-succ.out";   capture "$IS"   -is -lf "$ACCESS_FORMAT" "$ACCESS_FIXTURE"
EF="$TMP_DIR/exc-fail.out";   capture "$EF"   -ef -lf "$ACCESS_FORMAT" "$ACCESS_FIXTURE"
EFES="$TMP_DIR/exc-both.out"; capture "$EFES" -ef -es -lf "$ACCESS_FORMAT" "$ACCESS_FIXTURE"
HF="$TMP_DIR/hl-fail.out";    capture "$HF"   -hf -lf "$ACCESS_FORMAT" "$ACCESS_FIXTURE"
HFH="$TMP_DIR/hl-and.out";    capture "$HFH"  -hf -h ' 404 ' -lf "$ACCESS_FORMAT" "$ACCESS_FIXTURE"
HS="$TMP_DIR/hl-succ.out";    capture "$HS"   -hs -lf "$ACCESS_FORMAT" "$ACCESS_FIXTURE"
DB="$TMP_DIR/diag-base.out";  capture "$DB"   "$DIAG_FIXTURE"
DEFES="$TMP_DIR/diag-both.out"; capture "$DEFES" -ef -es "$DIAG_FIXTURE"
DES="$TMP_DIR/diag-es.out";   capture "$DES"  -es "$DIAG_FIXTURE"
DIS="$TMP_DIR/diag-is.out";   capture "$DIS"  -is "$DIAG_FIXTURE"
GB="$TMP_DIR/gc-base.out";    capture "$GB"   "$GC_FIXTURE"
GEFES="$TMP_DIR/gc-both.out"; capture "$GEFES" -ef -es "$GC_FIXTURE"

# ---------------------------------------------------------------------------
current_scenario="outcome-filters"

assert_command \
    label "-if keeps only the 6 failure-classified lines; -is only the 9 successes (AC1)" \
    command "[[ \$(cls_key '$IF' lines_included) == 6 && \$(cls_key '$IF' failures) == 6 && \$(cls_key '$IF' successes) == 0 && \$(cls_key '$IS' lines_included) == 9 && \$(cls_key '$IS' successes) == 9 && \$(cls_key '$IS' failures) == 0 ]]" \
    asserts "an include filter admits only lines whose classification outcome is the named one; every downstream statistic, the classification counters included, is computed over that subset" \
    produced_by "the outcome-filter block in read_and_process_logs(), reading the \$line_outcome the scan block set" \
    contract "features/455-success-failure-filter-highlight-criteria.md D6, AC1" \

assert_command \
    label "-ef removes the failures from all statistics: 9 included, failure counter 0 (AC2)" \
    command "[[ \$(cls_key '$EF' lines_included) == 9 && \$(cls_key '$EF' failures) == 0 && \$(cls_key '$EF' successes) == 9 ]]" \
    asserts "an exclude filter drops its named outcome before any counter increments, so the classification counters report 0 for the excluded outcome rather than remembering the dropped lines" \
    produced_by "the outcome-filter block in read_and_process_logs(), ahead of the include-point accounting" \
    contract "features/455-success-failure-filter-highlight-criteria.md D6/D7, AC2" \

assert_command \
    label "-ef -es leaves exactly the unclassified remainder: 0 here, 2 on the diagnostics fixture, equal to the unfiltered unclassified count (AC3)" \
    command "[[ \$(cls_key '$EFES' lines_included) == 0 && \$(cls_key '$DEFES' lines_included) == \$(cls_key '$DB' unclassified) && \$(cls_key '$DEFES' unclassified) == \$(cls_key '$DB' unclassified) ]]" \
    asserts "excluding both outcomes keeps precisely the lines that classified to neither — the answer to the unclassified-lines notice's implicit question" \
    produced_by "the outcome-filter block in read_and_process_logs(); unclassified lines (outcome 0) survive every exclude" \
    contract "features/455-success-failure-filter-highlight-criteria.md AC3 (fixture: diagnostics-classification-overlap.txt, 2 of 4 lines unclassified)" \

assert_command \
    label "summary shares survive outcome filtering and agree with the bucket columns: -if reads 0 (0%) / 6 (100%), -ef reads 9 (100%) / 0 (0%) (architect bug report 2026-09-01)" \
    command "s=\$(sed -E \$'s/\\x1b\\[[0-9;]*m//g' '$IF' | grep -E '^ *SUCCESS CLASSIFIED') && f=\$(sed -E \$'s/\\x1b\\[[0-9;]*m//g' '$IF' | grep -E '^ *FAILURE CLASSIFIED') && [[ \$s == *'0 (0%)'* && \$f == *'6 (100%)'* ]] && s2=\$(sed -E \$'s/\\x1b\\[[0-9;]*m//g' '$EF' | grep -E '^ *SUCCESS CLASSIFIED') && f2=\$(sed -E \$'s/\\x1b\\[[0-9;]*m//g' '$EF' | grep -E '^ *FAILURE CLASSIFIED') && [[ \$s2 == *'9 (100%)'* && \$f2 == *'0 (0%)'* ]] || { echo \"if: \$s / \$f\"; echo \"ef: \$s2 / \$f2\"; false; }" \
    asserts "the failure-only share suppression is a test of the declared rules, not the surviving data: on a format declaring both rules an outcome filter that zeroes one count leaves the shares printing over the classified denominator, consistent with the per-bucket percentage columns" \
    produced_by "the share_denominator predicate in print_summary_table(), reading \$cls_success_declared" \
    contract "features/452-success-failure-percentage-columns.md D10 as amended under #455 (declaration-based suppression)" \

# ---------------------------------------------------------------------------
current_scenario="outcome-highlights"

assert_command \
    label "-hf highlights the 6 failures through the existing mechanism and changes nothing about the analysed population (AC4)" \
    command "[[ \$(highlighted_count '$HF') == 6 && \$(cls_key '$HF' lines_included) == \$(cls_key '$B' lines_included) && \$(cls_key '$HF' successes) == \$(cls_key '$B' successes) && \$(cls_key '$HF' failures) == \$(cls_key '$B' failures) ]]" \
    asserts "an outcome highlight marks its subset via the same tagging and counters as -h <regex> (the HIGHLIGHTED summary row is that mechanism's own marker) while every population counter stays identical to the unhighlighted run" \
    produced_by "the outcome family in the highlight decision in read_and_process_logs() ('-HL' category tagging)" \
    contract "features/455-success-failure-filter-highlight-criteria.md D6, AC4; #312 precedent (highlight options are not filters)" \

assert_command \
    label "-hs highlights the 9 successes (AC4)" \
    command "[[ \$(highlighted_count '$HS') == 9 && \$(cls_key '$HS' lines_included) == \$(cls_key '$B' lines_included) ]]" \
    asserts "the success side of the outcome highlight uses the same mechanism and leaves the population untouched" \
    produced_by "the outcome family in the highlight decision in read_and_process_logs()" \
    contract "features/455-success-failure-filter-highlight-criteria.md D6, AC4" \

assert_command \
    label "-hf -h ' 404 ' AND-composes: only the 4 failing 404 lines highlight (AC5)" \
    command "[[ \$(highlighted_count '$HFH') == 4 ]]" \
    asserts "with several highlight criteria given, an entry highlights only if it satisfies all of them — the outcome family is a third independent constraint alongside the regex and numeric families" \
    produced_by "the AND-composed highlight condition in read_and_process_logs()" \
    contract "features/455-success-failure-filter-highlight-criteria.md AC5; print_help() filtering note (all-families AND)" \

# ---------------------------------------------------------------------------
current_scenario="inert-outcomes"

assert_command \
    label "no success rule: -es drops nothing, -is admits nothing, and neither errs (AC9)" \
    command "[[ \$(cls_key '$DES' lines_included) == \$(cls_key '$DB' lines_included) && \$(cls_key '$DIS' lines_included) == 0 ]] && ! grep -qiE 'error|unknown option' '$DES.stderr' '$DIS.stderr'" \
    asserts "on a format that declares no rule for the named outcome the option simply drops nothing (exclude) or matches nothing (include) — no error, no notice, no special-casing" \
    produced_by "the outcome-filter block in read_and_process_logs(); a never-produced outcome value never matches" \
    contract "features/455-success-failure-filter-highlight-criteria.md D6, AC9" \

assert_command \
    label "declining format (java_gc_g1): -ef -es keeps every included line (AC9)" \
    command "[[ \$(cls_key '$GEFES' lines_included) == \$(cls_key '$GB' lines_included) ]] && ! grep -qiE 'error|unknown option' '$GEFES.stderr'" \
    asserts "on a format that declines classification entirely every line is unclassified, so the excludes are inert and the run is unchanged" \
    produced_by "the outcome-filter block in read_and_process_logs()" \
    contract "features/455-success-failure-filter-highlight-criteria.md D6, AC9" \

# ---------------------------------------------------------------------------
current_scenario="index-signature"

assert_command \
    label "an outcome-filtered run writes its own selection row and never reuses the unfiltered one (AC6)" \
    command "cd '$TMP_DIR' && mkdir -p idx && cd idx && cp '$ACCESS_FIXTURE' f.txt && '$LTL' --disable-progress -bs 1440 -oe -n 1 -lf '$ACCESS_FORMAT' f.txt >/dev/null 2>r1.err && '$LTL' --disable-progress -bs 1440 -oe -n 1 -ef -lf '$ACCESS_FORMAT' f.txt >/dev/null 2>r2.err && [[ \$(grep -c '^selection,' ltl-index.csv) == 2 ]] && grep -q '^selection,.*,-ef\$' ltl-index.csv && [[ \$(grep -c '^selection,' ltl-index.csv) != \$(grep -c '^selection,.*,-ef\$' ltl-index.csv) ]]" \
    asserts "the -ef/-es/-if/-is options enter the persisted filter signature, so a filtered run appends a selection row under its own signature instead of matching the unfiltered row" \
    produced_by "serialize_filters() and has_active_filters() in ltl; write side write_index_file()" \
    contract "features/455-success-failure-filter-highlight-criteria.md D7, AC6" \

# ---------------------------------------------------------------------------
current_scenario="option-surface"

assert_command \
    label "the retired long names are rejected as unknown options (AC7)" \
    command "! '$LTL' --exclude-file /dev/null -ni '$ACCESS_FIXTURE' >/dev/null 2>&1 && ! '$LTL' --include-file /dev/null -ni '$ACCESS_FIXTURE' >/dev/null 2>&1 && ! '$LTL' --highlight-file /dev/null -ni '$ACCESS_FIXTURE' >/dev/null 2>&1 && ! '$LTL' --include-session -ni '$ACCESS_FIXTURE' >/dev/null 2>&1 && ! '$LTL' --include-query-string -ni '$ACCESS_FIXTURE' >/dev/null 2>&1" \
    asserts "the hard break holds: no alias keeps --exclude-file/--include-file/--highlight-file/--include-session/--include-query-string parsing" \
    produced_by "the GetOptions specs in adapt_to_command_line_options()" \
    contract "features/455-success-failure-filter-highlight-criteria.md D2/D4 (hard break, no aliases)" \

assert_command \
    label "the renamed forms parse: -hses, -xs, -xqs, and the pattern files as -ipf/-epf/-hpf (AC7/AC8)" \
    command "printf 'zzz-no-match\\n' > '$TMP_DIR/pat.txt' && '$LTL' --disable-progress -bs 1440 -oe -n 1 -ni -hses -xs -xqs -ipf '$TMP_DIR/pat.txt' -epf '$TMP_DIR/pat.txt' -hpf '$TMP_DIR/pat.txt' -lf '$ACCESS_FORMAT' '$ACCESS_FIXTURE' >/dev/null 2>'$TMP_DIR/renamed.err'" \
    asserts "every renamed option is accepted under its new short and long form in one run (the bound variables are unchanged, so acceptance plus the rename diff carries the behavioural equivalence)" \
    produced_by "the GetOptions specs in adapt_to_command_line_options()" \
    contract "features/455-success-failure-filter-highlight-criteria.md D2/D3/D4, AC7/AC8; tests/validate-help-content.sh enforces the two-surface parity" \

# ---------------------------------------------------------------------------
current_scenario="runtime-warnings"
for cap in "$B" "$IF" "$IS" "$EF" "$EFES" "$HF" "$HFH" "$HS" "$DB" "$DEFES" "$DES" "$DIS" "$GB" "$GEFES"; do
    label_name=$(basename "$cap")
    assert_command \
        label "no runtime warnings on stderr ($label_name)" \
        command "assert_no_runtime_warnings '$cap.stderr' '$label_name'" \
        asserts "no ' at ltl line N' unguarded data path fires on any scenario run" \
        produced_by "any sub touched by this feature" \
        contract "tests/HARNESS-DESIGN.md § Runtime-warning cleanliness" \

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
