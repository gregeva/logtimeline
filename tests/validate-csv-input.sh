#!/usr/bin/env bash
# validate-csv-input.sh — CSV columnar input harness (Issues #328, #640)
#
# Validates the -udm CSV columnar input path (features/user-defined-metrics.md
# § CSV Columnar Input): valid ISO and epoch timestamp CSVs are ingested; a
# CSV row whose timestamp cannot be placed on the timeline is a line no format
# matched, read silently and kept away from the metric capture and the date
# parse (features/640-csv-unplaced-rows-silent.md D1); a metric whose column
# is missing from the header of CSV files whose rows matched is reported once
# per run, without file names.
#
# Fixtures are generated inline: their content is the contract under test and
# has no value as committed files. The index scenario produces a real
# ltl-index.csv in the harness's own directory and reads it back as input.
#
# Usage: ./tests/validate-csv-input.sh [--scenario NAME] [--list]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LTL="$(cd "$SCRIPT_DIR/.." && pwd)/ltl"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"

# Ambient FORCE_COLOR/NO_COLOR must not decide what this harness asserts
# against (tests/HARNESS-DESIGN.md section Colour rendering is controlled,
# never inherited; issue #438).
neutralize_colour_env

# Scenario selector (tests/HARNESS-DESIGN.md section The scenario selector).
scenario_register csv-input \
                  quoted-timestamp-csv \
                  index-read-as-input \
                  unplaced-rows \
                  unbound-metric-note
scenario_parse_args "$@"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

pass=0
fail=0

CONTRACT_640='features/640-csv-unplaced-rows-silent.md D1 (a CSV row without a parsable timestamp is read and not matched, silently; metric messages are run-level)'

# assert_command: eval a command; PASS if exit code 0. Surfaces the
# asserts/produced_by/contract triple on failure (HARNESS-DESIGN.md).
assert_command() {
    local command="" label="" asserts="" produced_by="" contract=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            command)     command="$2"; shift 2 ;;
            label)       label="$2"; shift 2 ;;
            asserts)     asserts="$2"; shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2"; shift 2 ;;
            *) echo "assert_command: unknown field '$1'" >&2; exit 2 ;;
        esac
    done
    if eval "$command" >/dev/null 2>&1; then
        echo "  PASS  $current_scenario :: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario :: $label"
        echo "        command:     $command"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
    fi
}

# Never toggles errexit itself: callers capture the exit code with
# `rc=0; run_ltl ... || rc=$?`, which is condition context under set -e.
# Shape (tests/HARNESS-DESIGN.md section Invocation coherence): the
# assertions read the exit code, stderr, -V sections and the presence of the
# -udm column; one bucket and one table row suffice.
run_ltl() {
    local out="$1"; shift
    "$LTL" --disable-progress -ni -bs 1440 -oe -n 1 "$@" > "$out" 2>"$out.stderr"
}

# Runtime-warning cleanliness check for a run_ltl capture (stderr lives at
# <capture>.stderr). Silent when clean; increments the fail counter on a
# Perl runtime warning (HARNESS-DESIGN.md section Runtime-warning cleanliness).
check_capture_warnings() {
    local capture="$1" context="$2"
    if ! assert_no_runtime_warnings "$capture.stderr" "$context"; then
        fail=$((fail + 1))
    fi
}

# The value of <key> in the -V format-detection block of the file whose path
# ends in /<name>; prints nothing when the file or the key is absent, which
# the equality test at the call site reads as a failure.
file_detection_value() {
    local out="$1" name="$2" key="$3"
    awk -v name="/$name" -v key="  $key: " '
        /^file: / { in_file = (substr($0, length($0) - length(name) + 1) == name); next }
        /^[^ ]/   { in_file = 0 }
        in_file && index($0, key) == 1 { print substr($0, length(key) + 1); exit }
    ' "$out"
}

# A ThingWorx-format log whose lines carry latency=N for the -udm metric, so a
# run that also reads a CSV lacking the column still produces the metric and
# prints no zero-match note.
write_latency_log() {
    printf '%s\n' \
        '2026-06-01 10:00:00.100+0000 [L: WARN] [O: obj] [I: ] [U: u] [S: ] [P: ] [T: pool-1] message one latency=12' \
        '2026-06-01 10:01:00.100+0000 [L: WARN] [O: obj] [I: ] [U: u] [S: ] [P: ] [T: pool-1] message two latency=34' \
        > "$1"
}

echo "Validating CSV columnar input (Issues #328, #640)"
echo ""

# --- ISO and epoch CSVs ingest --------------------------------------------
if scenario_wanted csv-input; then
    current_scenario=csv-input
    printf 'timestamp,latency\n2026-06-01 10:00:05,12\n2026-06-01 10:01:05,34\n2026-06-01 10:02:05,56\n' > "$TMP_DIR/iso.csv"
    printf 'timestamp,latency\n1771078373,12\n1771078433,34\n' > "$TMP_DIR/epoch.csv"

    iso_rc=0; run_ltl "$TMP_DIR/iso.out" "$TMP_DIR/iso.csv" -udm latency:ms:mean || iso_rc=$?
    check_capture_warnings "$TMP_DIR/iso.out" "iso-timestamp-csv"
    assert_command \
        command     "[[ $iso_rc -eq 0 ]] && grep -aq 'latency' '$TMP_DIR/iso.out'" \
        label       'ISO-timestamp CSV ingests: exit 0, latency column rendered' \
        asserts     'A CSV with ISO YYYY-MM-DD HH:MM:SS timestamps and a -udm column is detected and ingested' \
        produced_by 'detect_and_parse_csv_header() + the csv_detected branch of read_and_process_logs() in ltl' \
        contract    'features/user-defined-metrics.md § CSV Columnar Input'

    epoch_rc=0; run_ltl "$TMP_DIR/epoch.out" "$TMP_DIR/epoch.csv" -udm latency:ms:mean || epoch_rc=$?
    check_capture_warnings "$TMP_DIR/epoch.out" "epoch-timestamp-csv"
    assert_command \
        command     "[[ $epoch_rc -eq 0 ]] && grep -aq 'latency' '$TMP_DIR/epoch.out'" \
        label       'epoch-timestamp CSV ingests: exit 0, latency column rendered' \
        asserts     'A CSV with numeric epoch timestamps is auto-detected on the first data line and ingested' \
        produced_by 'csv_epoch_timestamp detection in read_and_process_logs() in ltl' \
        contract    'features/user-defined-metrics.md § CSV Columnar Input (Epoch timestamps, Issue #98)'
fi

# --- The #328 crash shape: a quoted-timestamp CSV in a glob with a log ------
# The STATS CSV ltl writes quotes its timestamp; no row of it is placed, none
# reaches the date parse, and the file is never named on stderr.
if scenario_wanted quoted-timestamp-csv; then
    current_scenario=quoted-timestamp-csv
    mkdir "$TMP_DIR/mix"
    write_latency_log "$TMP_DIR/mix/app.log"
    printf 'timestamp,occurrences,bytes\n"2026-06-01 10:00",10,100\n"2026-06-01 12:00",20,200\n"2026-06-01 14:00",30,300\n' > "$TMP_DIR/mix/stats.csv"

    mix_rc=0; run_ltl "$TMP_DIR/mix.out" -V format-detection "$TMP_DIR"/mix/* -udm bytes::sum || mix_rc=$?
    check_capture_warnings "$TMP_DIR/mix.out" "mixed-glob-quoted-timestamp-csv"
    assert_command \
        command     "[[ $mix_rc -eq 0 ]]" \
        label       'mixed glob (log + quoted-timestamp CSV) exits 0 instead of dying in timegm()' \
        asserts     'A CSV row whose timestamp column is neither epoch nor ISO never reaches the fixed-offset substr/timegm parse' \
        produced_by 'csv_timestamp_placeable() in ltl, tested before a csv row counts as a match' \
        contract    "features/user-defined-metrics.md § CSV Columnar Input (Issue #328); $CONTRACT_640"
    assert_command \
        command     "[[ \"\$(file_detection_value '$TMP_DIR/mix.out' stats.csv matched_lines)\" == 0 ]]" \
        label       'the quoted-timestamp CSV shows nothing matched' \
        asserts     'No row of a CSV whose timestamps cannot be placed is matched' \
        produced_by 'csv_timestamp_placeable() + note_unmatched_line() in ltl' \
        contract    "$CONTRACT_640"
    assert_command \
        command     "! grep -aq 'stats.csv' '$TMP_DIR/mix.out.stderr' && ! grep -aqi 'timestamp' '$TMP_DIR/mix.out.stderr'" \
        label       'no per-row or per-file timestamp message, the file never named on stderr' \
        asserts     'A CSV row without a parsable timestamp is never reported per row or per file' \
        produced_by 'read_and_process_logs() in ltl (the csv row paths)' \
        contract    "$CONTRACT_640"
fi

# --- ltl's own index read back as input: the reference case -----------------
# An indexed run in the harness's own directory writes a real ltl-index.csv;
# a second run reads it beside the log with -udm naming a column the index
# lacks. The log produces the metric, so any stderr line would come from the
# index: none may.
if scenario_wanted index-read-as-input; then
    current_scenario=index-read-as-input
    mkdir "$TMP_DIR/idx"
    write_latency_log "$TMP_DIR/idx/app.log"
    idx_build_rc=0
    ( cd "$TMP_DIR/idx" && "$LTL" --disable-progress -bs 1440 -oe -n 1 app.log > index-build.out 2> index-build.out.stderr ) || idx_build_rc=$?
    check_capture_warnings "$TMP_DIR/idx/index-build.out" "index-build"
    assert_command \
        command     "[[ $idx_build_rc -eq 0 ]] && [[ \"\$(head -1 '$TMP_DIR/idx/ltl-index.csv' | cut -d, -f1)\" == entry_type ]]" \
        label       'an indexed run writes ltl-index.csv, first field entry_type' \
        asserts     'The fixture is a real index: its header begins with entry_type, not a timestamp' \
        produced_by 'write_index_file() in ltl' \
        contract    'features/179-index-read-back.md (index layout)'

    index_lines=$(wc -l < "$TMP_DIR/idx/ltl-index.csv" | tr -d ' ')
    idx_rc=0; run_ltl "$TMP_DIR/idx-in.out" -V format-detection,filter-summary \
        "$TMP_DIR/idx/app.log" "$TMP_DIR/idx/ltl-index.csv" -udm latency:ms:mean || idx_rc=$?
    check_capture_warnings "$TMP_DIR/idx-in.out" "index-read-as-input"
    assert_command \
        command     "[[ $idx_rc -eq 0 ]] && [[ ! -s '$TMP_DIR/idx-in.out.stderr' ]]" \
        label       'the index read as input produces no stderr output' \
        asserts     'A CSV none of whose rows has a parsable timestamp produces no message, and no metric-column note since its rows never matched' \
        produced_by 'csv_timestamp_placeable() and emit_udm_csv_unbound_notices() in ltl' \
        contract    "$CONTRACT_640"
    assert_command \
        command     "[[ \"\$(file_detection_value '$TMP_DIR/idx-in.out' ltl-index.csv matched_lines)\" == 0 ]]" \
        label       'the index shows nothing matched' \
        asserts     'No row of the index is matched' \
        produced_by 'csv_timestamp_placeable() + note_unmatched_line() in ltl' \
        contract    "$CONTRACT_640"
    assert_command \
        command     "[[ $index_lines -ge 2 ]] && grep -aqx 'lines_unmatched: $index_lines' '$TMP_DIR/idx-in.out' && grep -aqx 'excluded_other: 0' '$TMP_DIR/idx-in.out'" \
        label       "-V filter-summary counts all $index_lines index lines as unmatched, none as excluded" \
        asserts     'Every line of the index (its header and its rows) is read and not matched; no exclusion cause counts them' \
        produced_by 'emit_filter_summary_verbose() in ltl; note_unmatched_line()' \
        contract    "$CONTRACT_640; features/503-yaml-aggregate-export.md § -V filter-summary"
fi

# --- A CSV mixing placeable and unplaceable rows ----------------------------
# The second data row reads "not a date": it is skipped before the metric
# capture, so it sets no delta baseline (the third row's delta is 265 - 100,
# not 265 - 195) and does not count as matched.
if scenario_wanted unplaced-rows; then
    current_scenario=unplaced-rows
    printf 'timestamp,value\n2026-06-01 10:00:05,100\nnot a date,195\n2026-06-01 10:02:05,265\n' > "$TMP_DIR/delta.csv"
    delta_rc=0; run_ltl "$TMP_DIR/delta.out" -V format-detection,udm-specs "$TMP_DIR/delta.csv" -udm 'value::delta:sum' || delta_rc=$?
    check_capture_warnings "$TMP_DIR/delta.out" "unplaced-row-delta"
    assert_command \
        command     "[[ $delta_rc -eq 0 ]] && [[ ! -s '$TMP_DIR/delta.out.stderr' ]]" \
        label       'placeable rows go on the timeline with no per-row or per-file message' \
        asserts     'A CSV mixing parsable and unparsable rows prints nothing about the unparsable ones' \
        produced_by 'csv_timestamp_placeable() in ltl' \
        contract    "$CONTRACT_640"
    assert_command \
        command     "grep -aq '^  produced: occurrences=1 buckets=1 sum=165 ' '$TMP_DIR/delta.out'" \
        label       'the unplaced row sets no delta baseline: delta 165, not 70' \
        asserts     'A CSV row without a parsable timestamp never reaches the metric capture' \
        produced_by 'csv_timestamp_placeable() ahead of the USER DEFINED METRICS CAPTURE block of read_and_process_logs() in ltl' \
        contract    "$CONTRACT_640"
    assert_command \
        command     "[[ \"\$(file_detection_value '$TMP_DIR/delta.out' delta.csv matched_lines)\" == 2 ]]" \
        label       'matched_lines: 2 for the three data rows' \
        asserts     'A CSV row without a parsable timestamp does not count as matched' \
        produced_by 'csv_timestamp_placeable() + note_unmatched_line() in ltl' \
        contract    "$CONTRACT_640"

    # An epoch CSV (decided by its first data row) with a non-numeric row.
    printf 'timestamp,latency\n1771078373,12\nabc,5\n1771078433,34\n' > "$TMP_DIR/epoch-bad.csv"
    eb_rc=0; run_ltl "$TMP_DIR/epoch-bad.out" -V filter-summary "$TMP_DIR/epoch-bad.csv" -udm latency:ms:mean || eb_rc=$?
    check_capture_warnings "$TMP_DIR/epoch-bad.out" "unplaced-row-epoch"
    assert_command \
        command     "[[ $eb_rc -eq 0 ]] && [[ ! -s '$TMP_DIR/epoch-bad.out.stderr' ]] && grep -aqx 'lines_included: 2' '$TMP_DIR/epoch-bad.out'" \
        label       'an epoch CSV row that is not a number is unmatched, silently' \
        asserts     'In an epoch-timestamp CSV a row whose timestamp is not epoch seconds never reaches the epoch conversion' \
        produced_by 'csv_timestamp_placeable() in ltl (epoch arm)' \
        contract    "$CONTRACT_640"
fi

# --- The metric-column note: one per spec, run-level, no file names ---------
if scenario_wanted unbound-metric-note; then
    current_scenario=unbound-metric-note
    mkdir "$TMP_DIR/unbound"
    write_latency_log "$TMP_DIR/unbound/app.log"
    printf 'timestamp,other\n2026-06-01 10:00:05,1\n2026-06-01 10:01:05,2\n' > "$TMP_DIR/unbound/first-nocol.csv"
    cp "$TMP_DIR/unbound/first-nocol.csv" "$TMP_DIR/unbound/second-nocol.csv"
    ub_rc=0; run_ltl "$TMP_DIR/unbound.out" "$TMP_DIR"/unbound/* -udm latency:ms:mean || ub_rc=$?
    check_capture_warnings "$TMP_DIR/unbound.out" "unbound-metric-note"
    assert_command \
        command     "[[ $ub_rc -eq 0 ]] && [[ \$(grep -ac \"^Note: -udm 'latency:ms:mean': \" '$TMP_DIR/unbound.out.stderr') -eq 1 ]]" \
        label       'exactly one Note line for the spec across two CSV files lacking the column' \
        asserts     'A metric whose column is missing from the header of CSV files whose rows matched is reported once per run' \
        produced_by 'emit_udm_csv_unbound_notices() in ltl, counted by udm_note_sources()' \
        contract    "$CONTRACT_640"
    assert_command \
        command     "grep -aq \"^Note: -udm 'latency:ms:mean': .* 2 CSV file\" '$TMP_DIR/unbound.out.stderr' && ! grep -aq 'nocol' '$TMP_DIR/unbound.out.stderr'" \
        label       'the note gives the count of files (2) and no file name' \
        asserts     'The run-level note counts the CSV files and never lists them' \
        produced_by 'emit_udm_csv_unbound_notices() in ltl' \
        contract    "$CONTRACT_640"
fi

echo ""
echo "Results: $pass passed, $fail failed"
if [[ $((pass + fail)) -eq 0 ]]; then
    echo "FAIL: no assertion ran"
    exit 1
fi
[[ $fail -eq 0 ]] || exit 1
echo "ALL CSV INPUT TESTS PASSED"
exit 0
