#!/usr/bin/env bash
# validate-classification-states.sh — the per-message classification indicator
# and the classification states behind it (issue #456): the CLASSIFICATION
# CONFLICT line outcome, the MIXED message-row state, the per-bucket
# unclassified count and the revised percentage suppression, the verification
# format that produces all four line states, and the export of the new figures.
#
# Derived from features/456-per-message-success-failure-indicator.md
# § Acceptance criteria BEFORE implementation (docs/test-driven-development.md).
# Reads the classification sub-section of -V format-detection (contract:
# features/453-success-failure-classification-event-ledger.md § Extension under
# #456), the rendered message rows through tests/lib/rendered-output.pl, the
# timeline cells through the layout engine's own offsets, the STATS and
# MESSAGES CSVs, and the YAML aggregate export.
#
# Usage: ./tests/validate-classification-states.sh
#
# Invocation shape (tests/HARNESS-DESIGN.md section Invocation coherence): the
# fixture spans four days, so every run takes -bs 1440 -oe; counting runs add
# -n 0 (no rows, F5) or -n 25 (every row retained); rendered runs pin the width.
# -lf binds the verification format, which no file can bind by detection.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"
FIXTURE="$REPO_DIR/tests/fixtures/classification-states.txt"
CHECKER="$REPO_DIR/tests/aggregate-export/validate-aggregate-export.pl"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/rendered-output.sh
source "$SCRIPT_DIR/lib/rendered-output.sh"

neutralize_colour_env

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

for f in "$LTL" "$FIXTURE" "$CHECKER"; do
    [[ -e "$f" ]] || { echo "ERROR: required file missing: $f" >&2; exit 1; }
done

FORMAT=classification_verification
PIN=(-lf "$FORMAT")
COMMON=(--disable-progress -ni -oe -bs 1440)
SPEC='features/456-per-message-success-failure-indicator.md'
CLS_CONTRACT='features/453-success-failure-classification-event-ledger.md section Extension under #456 (fourth outcome, counted unclassified, -V classification keys)'

pass=0; fail=0; failures=(); current_scenario=""

fail_with() {
    local label="$1" asserts="$2" produced_by="$3" contract="$4"; shift 4
    echo "  FAIL  $current_scenario :: $label"
    echo "        asserts:     $asserts"
    echo "        produced_by: $produced_by"
    echo "        contract:    $contract"
    local d; for d in "$@"; do echo "        $d"; done
    fail=$((fail + 1)); failures+=("$current_scenario :: $label")
}
pass_with() { echo "  PASS  $current_scenario :: $1"; pass=$((pass + 1)); }

# run_ltl TAG ARGS... — capture stdout/stderr/rc under $TMP_DIR/TAG.*; the
# runtime-warning check runs on every capture.
run_ltl() {
    local tag="$1"; shift
    set +e
    "$LTL" "$@" > "$TMP_DIR/$tag.out" 2> "$TMP_DIR/$tag.err"
    echo $? > "$TMP_DIR/$tag.rc"
    set -e
    if ! assert_no_runtime_warnings "$TMP_DIR/$tag.err" "$current_scenario/$tag"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: runtime warnings ($tag)")
    fi
}
# key FILE NAME — the value of "NAME: value" inside the classification
# sub-section; a missing anchor is a hard failure (HARNESS-DESIGN.md Trap 3).
key() {
    local file="$1" name="$2" body value
    if ! grep -qE '^=== format-detection / classification ===$' "$file"; then
        echo "MISSING-SECTION"; return
    fi
    body=$(sed -n '/^=== format-detection \/ classification ===$/,/^=== END format-detection \/ classification ===$/p' "$file")
    value=$(printf '%s\n' "$body" | sed -nE "s/^${name}: (.*)$/\1/p" | head -1)
    [[ -n "$value" ]] && echo "$value" || echo "MISSING-ANCHOR:$name"
}
# expect_key FILE NAME EXPECTED LABEL
expect_key() {
    local file="$1" name="$2" expected="$3" label="$4" got
    got=$(key "$file" "$name")
    if [[ "$got" == "$expected" ]]; then
        pass_with "$label ($name: $got)"
    else
        fail_with "$label" "$name in the classification sub-section is $expected" \
            'emit_format_detection_verbose() in ltl, reading classification_reconciliation()' "$CLS_CONTRACT" "got: $got"
    fi
}
# partition FILE LABEL — successes + failures + conflicts + mixed + unclassified = lines_included (D5)
partition() {
    local file="$1" label="$2" s f c m u n
    s=$(key "$file" successes); f=$(key "$file" failures); c=$(key "$file" conflicts)
    m=$(key "$file" mixed); u=$(key "$file" unclassified); n=$(key "$file" lines_included)
    if [[ "$s$f$c$m$u$n" == *MISSING* ]]; then
        fail_with "$label" 'the five outcome figures and lines_included are all present' 'emit_format_detection_verbose() in ltl' "$CLS_CONTRACT" "s=$s f=$f c=$c m=$m u=$u n=$n"
    elif (( s + f + c + m + u == n )); then
        pass_with "$label: $s + $f + $c + $m + $u = $n"
    else
        fail_with "$label" 'SUCCESS + FAILURE + CLASSIFICATION CONFLICT + MIXED + UNCLASSIFIED = LINES INCLUDED (D5)' \
            'classification_reconciliation() and resolve_message_classification_states() in ltl' "$SPEC D5" "s=$s f=$f c=$c m=$m u=$u n=$n"
    fi
}
# indicator CAPTURE MESSAGE — decodes the first message row whose plain text
# carries MESSAGE and prints "char=<c> fg=<colour> rest=<colours of the rest>".
indicator() {
    local capture="$1" message="$2"
    "$PERL" -e '
        require $ARGV[0];
        binmode(STDOUT, ":encoding(UTF-8)");
        my ($lib, $file, $msg) = @ARGV;
        open my $fh, "<:encoding(UTF-8)", $file or die "cannot open $file: $!\n";
        while (my $line = <$fh>) {
            (my $plain = $line) =~ s/\e\[[0-9;]*m//g;
            next unless index($plain, $msg) >= 0 && $plain =~ /^\S?\s*\[/;
            my $cells = decode_line($line);
            my $first = $cells->[0];
            my %rest = map { $_->{fg} => 1 } grep { $_->{ch} ne " " } @{$cells}[1 .. $#$cells];
            printf "char=%s fg=%s rest=%s\n", $first->{ch} eq " " ? "space" : $first->{ch}, $first->{fg}, join(",", sort keys %rest);
            exit 0;
        }
        print "ROW-NOT-FOUND\n"; exit 1;
    ' "$_RENDERED_OUTPUT_LIB" "$capture" "$message"
}
expect_indicator() {
    # expect_indicator CAPTURE MESSAGE EXPECTED_CHAR EXPECTED_FG LABEL
    local capture="$1" message="$2" want_ch="$3" want_fg="$4" label="$5" got
    got=$(indicator "$capture" "$message" || true)
    if [[ "$got" == "char=$want_ch fg=$want_fg rest=default" ]]; then
        pass_with "$label ($got)"
    else
        fail_with "$label" "the row for '$message' carries $want_ch in $want_fg in the consolidation marker position and plain text elsewhere" \
            'print_message_summary() in ltl (indicator in the marker position, message_classification_state())' "$SPEC D1, D2, D8, D10" "got: $got"
    fi
}

echo "Validating the classification states and the per-message indicator (Issue #456)"
echo

# ---------------------------------------------------------------------------
current_scenario="producer/fixture-tracked"
if ( cd "$REPO_DIR" && git ls-files --error-unmatch tests/fixtures/classification-states.txt > /dev/null 2>&1 ) \
   && grep -q 'classification-states.txt' "$REPO_DIR/docs/test-logs.md"; then
    pass_with "fixture is tracked and recorded in docs/test-logs.md"
else
    fail_with "fixture tracked and recorded" 'the synthetic fixture is committed as .txt and described in docs/test-logs.md' 'repository' "$SPEC acceptance criterion 1"
fi

current_scenario="producer/contained"
run_ltl unpinned "${COMMON[@]}" -n 0 -osum -V format-detection "$FIXTURE"
if grep -qE '^  format: -$' "$TMP_DIR/unpinned.out" && grep -qE '^  unmatched_lines: 16$' "$TMP_DIR/unpinned.out"; then
    pass_with "the fixture is unrecognised without -lf (16 unmatched lines)"
else
    fail_with "fixture unrecognised without -lf" 'the verification entry never joins the scan cascade, so no file binds it by detection' \
        'build_format_registry() in ltl (scanned => 0 keeps the entry out of the cascade)' "$SPEC D12" \
        "$(grep -E '^  (format|unmatched_lines):' "$TMP_DIR/unpinned.out" | tr '\n' ' ')"
fi
run_ltl help --help formats
if [[ "$(cat "$TMP_DIR/help.rc")" == 0 ]] && ! grep -q "$FORMAT" "$TMP_DIR/help.out"; then
    pass_with "--help formats does not list $FORMAT"
else
    fail_with "--help formats omits the verification entry" 'a verification-only entry never appears in user-facing prose' 'print_help_formats() in ltl' "$SPEC D12"
fi
run_ltl badpin "${COMMON[@]}" -n 0 -lf nonsense "$FIXTURE"
if [[ "$(cat "$TMP_DIR/badpin.rc")" != 0 ]] && grep -q 'Known formats:' "$TMP_DIR/badpin.err" && ! grep -q "$FORMAT" "$TMP_DIR/badpin.err"; then
    pass_with "the -lf rejection's known-format list omits $FORMAT"
else
    fail_with "-lf known-format list omits the verification entry" 'the user-facing list of pinnable formats never names a verification-only entry' 'apply_format_pin() in ltl' "$SPEC D12"
fi
run_ltl pinned "${COMMON[@]}" -n 0 -osum -V format-detection "${PIN[@]}" "$FIXTURE"
if grep -qE "^  format: $FORMAT$" "$TMP_DIR/pinned.out" && grep -qE '^  matched_lines: 16$' "$TMP_DIR/pinned.out"; then
    pass_with "-lf $FORMAT binds every fixture line"
else
    fail_with "-lf binds the verification entry" 'the harness reaches the verification entry by pin' 'apply_format_pin() in ltl' "$SPEC D12" \
        "$(grep -E '^  (format|matched_lines):' "$TMP_DIR/pinned.out" | tr '\n' ' ')" "stderr: $(head -2 "$TMP_DIR/pinned.err" | tr '\n' ' ')"
fi

# ---------------------------------------------------------------------------
current_scenario="line-states/no-rows"
# -n 0 retains no message, so nothing can be MIXED (F5): the four line
# states as the fixture was designed: 7 success, 4 failure, 2 conflict,
# 3 unclassified over 16 lines.
expect_key "$TMP_DIR/pinned.out" successes 7 'successes match the designed composition'
expect_key "$TMP_DIR/pinned.out" failures 4 'failures match the designed composition'
expect_key "$TMP_DIR/pinned.out" conflicts 2 'the two lines satisfying both criteria are conflicts, in neither success nor failure'
expect_key "$TMP_DIR/pinned.out" unclassified 3 'unclassified is the counted figure'
expect_key "$TMP_DIR/pinned.out" mixed 0 'no retained rows, no MIXED (F5)'
expect_key "$TMP_DIR/pinned.out" unclassified_qualifying 3 'every unclassified line came from the qualifying verification format'
partition "$TMP_DIR/pinned.out" 'five-way partition under -n 0'

current_scenario="line-states/rows-retained"
run_ltl rows "${COMMON[@]}" -n 25 -osum -V format-detection "${PIN[@]}" "$FIXTURE"
# checkout (1 success + 1 failure) and search (1 success + 1 unclassified) are
# non-uniform rows: their four lines leave their counters for MIXED (D5, D10).
expect_key "$TMP_DIR/rows.out" mixed 4 'two non-uniform rows move exactly their four lines to MIXED'
expect_key "$TMP_DIR/rows.out" successes 5 'successes lose the two lines of the mixed rows'
expect_key "$TMP_DIR/rows.out" failures 3 'failures lose the one line of the mixed checkout row'
expect_key "$TMP_DIR/rows.out" unclassified 2 'unclassified loses the one line of the mixed search row'
expect_key "$TMP_DIR/rows.out" conflicts 2 'the all-conflict row stays uniform and its lines stay conflicts'
expect_key "$TMP_DIR/rows.out" pct_eligible 0 'a non-zero mixed count withholds the run-level shares (D9)'
partition "$TMP_DIR/rows.out" 'five-way partition with rows retained'

current_scenario="line-states/consolidated"
run_ltl grouped "${COMMON[@]}" -n 25 -osum -g 85 -V format-detection "${PIN[@]}" "${FIXTURE}"
# The architect's worked case (D5): "order 1001 placed" (success) and
# "order 1002 placed" (failure) consolidate into one entry; success and
# failure each decrement by one and mixed increments by two.
expect_key "$TMP_DIR/grouped.out" mixed 6 'consolidating one success and one failure line adds two to MIXED'
expect_key "$TMP_DIR/grouped.out" successes 4 'successes decrement by one for the consolidated pair'
expect_key "$TMP_DIR/grouped.out" failures 2 'failures decrement by one for the consolidated pair'
partition "$TMP_DIR/grouped.out" 'five-way partition after the final consolidation pass'

current_scenario="line-states/mixed-alone-suppresses"
# Day 1 only: three successes and three failures, no conflict, no
# unclassified line, one non-uniform row (checkout). With rows retained the
# mixed count alone withholds the shares (D9); with no rows the shares print.
run_ltl day1rows "${COMMON[@]}" -n 25 -osum -i 'catalog fetch|upload|checkout' -V format-detection "${PIN[@]}" "$FIXTURE"
run_ltl day1none "${COMMON[@]}" -n 0 -osum -i 'catalog fetch|upload|checkout' -V format-detection "${PIN[@]}" "$FIXTURE"
expect_key "$TMP_DIR/day1rows.out" conflicts 0 'the day-1 subset carries no conflict'
expect_key "$TMP_DIR/day1rows.out" unclassified 0 'the day-1 subset carries no unclassified line'
expect_key "$TMP_DIR/day1rows.out" mixed 2 'the checkout row is mixed'
expect_key "$TMP_DIR/day1rows.out" pct_eligible 0 'mixed alone withholds the run-level shares (D9)'
expect_key "$TMP_DIR/day1none.out" mixed 0 '-n 0 on the same subset: nothing is mixed (F5)'
expect_key "$TMP_DIR/day1none.out" pct_eligible 1 '-n 0 on the same subset: the shares print by the ordinary rule'
expect_key "$TMP_DIR/day1none.out" success_pct 50.000 'the printed share is over the classified pair'
if ! grep -qE '\-n 0|top_n_messages == 0|top_n_messages eq' <(grep -n 'mixed' "$LTL"); then
    pass_with "no -n 0 branch in the MIXED bookkeeping (F5)"
else
    fail_with "no -n 0 branch" 'a run that retains no messages needs no special case' 'resolve_message_classification_states() in ltl' "$SPEC F5, acceptance criterion 13"
fi

# ---------------------------------------------------------------------------
current_scenario="summary-rows"
run_ltl summary "${COMMON[@]}" -n 25 --terminal-width 200 -sm "${PIN[@]}" "$FIXTURE"
summary_plain=$(sed -E 's/\x1b\[[0-9;]*m//g' "$TMP_DIR/summary.out")
if printf '%s\n' "$summary_plain" | grep -qE 'CLASSIFICATION CONFLICT +2\b' \
   && printf '%s\n' "$summary_plain" | grep -qE 'MIXED +4\b'; then
    pass_with "CLASSIFICATION CONFLICT 2 and MIXED 4 rows print in the run summary"
else
    fail_with "conflict and mixed summary rows" 'the run summary gains CLASSIFICATION CONFLICT and MIXED rows on the UNCLASSIFIED pattern, printed when non-zero' \
        'print_summary_table() in ltl' "$SPEC § Surfaces to update" "$(printf '%s\n' "$summary_plain" | grep -E 'CLASSIFIED|CONFLICT|MIXED|UNCLASSIFIED' | sed -E 's/ +/ /g' | tr '\n' '~')"
fi
if printf '%s\n' "$summary_plain" | "$PERL" -ne '$ok = 1 if /SUCCESS CLASSIFIED\s+5(?!\s*\()/; END { exit($ok ? 0 : 1) }'; then
    pass_with "SUCCESS CLASSIFIED prints its count without a share on a mixed run (D9)"
else
    fail_with "success row count without share" 'with a non-zero mixed count the classified rows print counts, not shares' 'print_summary_table() in ltl' "$SPEC D9" \
        "$(printf '%s\n' "$summary_plain" | grep -E 'SUCCESS CLASSIFIED' | sed -E 's/ +/ /g')"
fi
run_ltl summaryclean "${COMMON[@]}" -n 0 --terminal-width 200 -i 'catalog fetch|upload' "${PIN[@]}" "$FIXTURE"
if ! sed -E 's/\x1b\[[0-9;]*m//g' "$TMP_DIR/summaryclean.out" | grep -qE 'CLASSIFICATION CONFLICT|MIXED'; then
    pass_with "a clean run prints neither the conflict nor the mixed row"
else
    fail_with "rows absent when zero" 'the new rows print only when non-zero' 'print_summary_table() in ltl' "$SPEC § Surfaces to update"
fi

# ---------------------------------------------------------------------------
current_scenario="eligibility/per-bucket"
# Rendered with --debug-layout so the success and failure columns are read
# at the layout engine's own offsets (tests/lib/rendered-output.sh).
set +e
with_ansi_colour "$LTL" "${COMMON[@]}" -n 1 --terminal-width 200 --debug-layout "${PIN[@]}" "$FIXTURE" > "$TMP_DIR/cells.out" 2> "$TMP_DIR/cells.err"
rc=$?
set -e
sed -n '/^--- Layout Engine Debug/,/^---$/p' "$TMP_DIR/cells.err" >> "$TMP_DIR/cells.out"
if [[ $rc -ne 0 ]] || ! grep -q '^--- Layout Engine Debug' "$TMP_DIR/cells.out"; then
    fail_with "debug-layout capture" 'the rendered run carries its layout table' 'print_bar_graph() in ltl' 'tests/HARNESS-DESIGN.md section Asserting rendered output' "rc=$rc"
else
    assert_no_runtime_warnings "$TMP_DIR/cells.err" "$current_scenario" || { fail=$((fail + 1)); failures+=("$current_scenario :: runtime warnings"); }
    cell_text() { timeline_cell_report "$TMP_DIR/cells.out" "$1" "$2" 2>/dev/null | sed -nE "s/^text='([^']*)'.*/\1/p" | sed -E 's/^ +| +$//g'; }
    check_cells() {
        # check_cells DAY WANT_SUCCESS WANT_FAILURE LABEL CONTRACT
        local day="$1" ws="$2" wf="$3" label="$4" contract="$5" gs gf
        gs=$(cell_text "^ $day" success_pct); gf=$(cell_text "^ $day" failure_pct)
        if [[ "$gs" == "$ws" && "$gf" == "$wf" ]]; then
            pass_with "$label (success '$gs', failure '$gf')"
        else
            fail_with "$label" "the $day bucket renders success '$ws' and failure '$wf'" 'normalize_data_for_output() in ltl (per-bucket eligibility), rendered by print_bar_graph()' "$contract" "got success '$gs' failure '$gf'"
        fi
    }
    check_cells 2025-06-01 '50%' '50%' 'a bucket with neither cause keeps its percentages' "$SPEC acceptance criterion 8"
    check_cells 2025-06-02 '1' '0' 'a bucket holding a conflict renders absolute counts' "$SPEC D6 (conflict path), acceptance criterion 7"
    check_cells 2025-06-03 '1' '0' 'a bucket holding a qualifying-source unclassified line renders absolute counts' "$SPEC D6 (qualifying-unclassified path), acceptance criterion 7; features/452-success-failure-percentage-columns.md D3 as revised"
fi

# ---------------------------------------------------------------------------
current_scenario="indicator/rows"
set +e
with_ansi_colour "$LTL" "${COMMON[@]}" -n 25 --terminal-width 200 "${PIN[@]}" "$FIXTURE" > "$TMP_DIR/ind.out" 2> "$TMP_DIR/ind.err"
set -e
assert_no_runtime_warnings "$TMP_DIR/ind.err" "$current_scenario" || { fail=$((fail + 1)); failures+=("$current_scenario :: runtime warnings"); }
expect_indicator "$TMP_DIR/ind.out" 'catalog fetch'  '•'     '256:34'  'an all-success row renders the bullet in kelly-green'
expect_indicator "$TMP_DIR/ind.out" 'upload'         '•'     '256:160' 'an all-failure row renders the bullet in rosso-corsa'
expect_indicator "$TMP_DIR/ind.out" 'index rebuild'  '•'     '256:135' 'an all-conflict row renders the bullet in amethyst'
expect_indicator "$TMP_DIR/ind.out" 'cache warm'     'space' 'default' 'an all-unclassified row stays unmarked'
expect_indicator "$TMP_DIR/ind.out" 'checkout'       '•'     '256:178' 'a success/failure row renders the bullet in gold (MIXED)'
expect_indicator "$TMP_DIR/ind.out" 'search'         '•'     '256:178' 'a success/unclassified row is MIXED too (D10)'

current_scenario="indicator/consolidated"
set +e
with_ansi_colour "$LTL" "${COMMON[@]}" -n 25 --terminal-width 200 -g 85 "${PIN[@]}" "$FIXTURE" > "$TMP_DIR/indg.out" 2> "$TMP_DIR/indg.err"
set -e
assert_no_runtime_warnings "$TMP_DIR/indg.err" "$current_scenario" || { fail=$((fail + 1)); failures+=("$current_scenario :: runtime warnings"); }
expect_indicator "$TMP_DIR/indg.out" 'placed' '~' '256:178' 'the consolidated success/failure pair renders ~ in gold'
expect_indicator "$TMP_DIR/indg.out" 'catalog fetch' '•' '256:34' 'an unconsolidated row keeps the bullet under -g'

# ---------------------------------------------------------------------------
current_scenario="export"
mkdir -p "$TMP_DIR/export"
set +e
( cd "$TMP_DIR/export" && "$LTL" "${COMMON[@]}" -n 25 -o "${PIN[@]}" "$FIXTURE" > out 2> err; echo $? > rc )
set -e
assert_no_runtime_warnings "$TMP_DIR/export/err" "$current_scenario" || { fail=$((fail + 1)); failures+=("$current_scenario :: runtime warnings"); }
yaml=$(ls "$TMP_DIR/export"/*.yaml 2>/dev/null | head -1 || true)
stats=$(ls "$TMP_DIR/export"/*-LTL-STATS-*.csv 2>/dev/null | head -1 || true)
msgs=$(ls "$TMP_DIR/export"/*-LTL-MESSAGES-*.csv 2>/dev/null | head -1 || true)
yget() { "$PERL" "$CHECKER" get --yaml "$yaml" --path "$1" 2>/dev/null || true; }
if [[ -n "$yaml" ]]; then
    for pair in "measurements.conflicts|2" "measurements.mixed|4" "measurements.unclassified|2" "measurements.successes|5" "measurements.failures|3" \
                "measurements.unclassified_qualifying_lines|3" "series.buckets.1.conflicts|2" "series.buckets.2.unclassified_qualifying_lines|2"; do
        IFS='|' read -r path want <<< "$pair"
        got=$(yget "$path")
        if [[ "$got" == "$want" ]]; then
            pass_with "$path = $got"
        else
            fail_with "$path" "the aggregate export carries the new outcome figures at run and bucket scope, and the cause of each absent percentage" \
                'write_aggregate_export() in ltl' 'features/503-yaml-aggregate-export.md § Extension under #456, D16' "got '$got' want '$want'"
        fi
    done
else
    fail_with "yaml written" 'a -o run writes the YAML export' 'write_aggregate_export() in ltl' 'features/503-yaml-aggregate-export.md'
fi
if [[ -n "$stats" ]] && head -1 "$stats" | tr ',' '\n' | grep -qx conflicts; then
    pass_with "STATS CSV carries a conflicts column"
else
    fail_with "STATS CSV conflicts column" 'the per-bucket outcome columns gain conflicts beside successes and failures' 'write_stats_csv() in ltl' "$SPEC § Surfaces to update" "header: $(head -1 "${stats:-/dev/null}" | cut -c1-120)"
fi
if [[ -n "$msgs" ]]; then
    col=$(head -1 "$msgs" | tr ',' '\n' | grep -nx conflicts | cut -d: -f1)
    row=$(grep 'index rebuild' "$msgs" | head -1)
    got=$(printf '%s\n' "$row" | "$PERL" -MText::CSV -e 'my $c = Text::CSV->new; my $r = $c->getline(\*STDIN); print $r->[$ARGV[0]-1] // "?"' "${col:-0}")
    if [[ -n "$col" && "$got" == 2 ]]; then
        pass_with "MESSAGES CSV conflicts = 2 for the all-conflict row"
    else
        fail_with "MESSAGES CSV conflicts column" 'the per-message outcome columns gain conflicts' 'print_message_summary() in ltl (CSV branch)' "$SPEC § Surfaces to update" "column: ${col:-absent} value: ${got:-?}"
    fi
else
    fail_with "MESSAGES CSV written" 'a -o run with retained rows writes the MESSAGES CSV' 'print_message_summary() in ltl' "$SPEC"
fi

# ---------------------------------------------------------------------------
current_scenario="regression-guard/short-circuit"
if ! grep -qF '"($f) ? 2 : ($s) ? 1 : 0"' "$LTL"; then
    pass_with "the failure-first short-circuit is retired from the compiled classifier"
else
    fail_with "short-circuit retired" 'a line satisfying both criteria is evaluated on both and filed as a conflict' 'format_classification_src() in ltl' "$CLS_CONTRACT; $SPEC D3"
fi

echo
echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"; printf '  %s\n' "${failures[@]}"; exit 1
fi
exit 0
