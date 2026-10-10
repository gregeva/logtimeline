#!/usr/bin/env bash
# validate-csv-input.sh — CSV columnar input harness (Issues #328, #640, #615)
#
# Validates the -udm CSV columnar input path (features/user-defined-metrics.md
# § CSV Columnar Input): valid ISO and epoch timestamp CSVs are ingested; a
# CSV row whose timestamp cannot be placed on the timeline is a line no format
# matched, read silently and kept away from the metric capture and the date
# parse (features/640-csv-unplaced-rows-silent.md D1); a metric whose column
# is missing from the header of CSV files whose rows matched is reported once
# per run, without file names. Each file is read by the block generated from
# its header, validated on its sampled rows with the day-first retry
# (features/615-csv-registry-entry.md D1, D9, D10, D15, D16): the bucket rows,
# metric values and timestamps it gives are derived by hand from the fixtures.
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
# shellcheck source=lib/run-dir.sh
source "$SCRIPT_DIR/lib/run-dir.sh"

# Ambient FORCE_COLOR/NO_COLOR must not decide what this harness asserts
# against (tests/HARNESS-DESIGN.md section Colour rendering is controlled,
# never inherited; issue #438).
neutralize_colour_env

# Scenario selector (tests/HARNESS-DESIGN.md section The scenario selector).
scenario_register csv-input \
                  quoted-timestamp-csv \
                  accepted-forms \
                  index-read-as-input \
                  unplaced-rows \
                  unbound-metric-note \
                  block-iso \
                  block-epoch \
                  block-message-columns \
                  block-fraction-digits \
                  block-column-order \
                  day-first-sampled \
                  day-first-small \
                  day-first-then-month-first \
                  day-first-then-ambiguous \
                  separator-detected \
                  separator-option
scenario_parse_args "$@"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

pass=0
fail=0

CONTRACT_611='features/611-timestamp-acceptance.md C8 (CSV forms: quoted, without seconds, 13-digit epoch milliseconds), AC8; features/640-csv-unplaced-rows-silent.md D2 (these forms deferred to #611)'
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

# run_o TAG ARGS... — ltl -o in a directory of its own, $TMP_DIR/TAG, so the
# STATS CSV, MESSAGES CSV and YAML export found there are this run's
# (tests/HARNESS-DESIGN.md section A harness owns the directory it runs ltl
# in); stdout to out.txt, stderr to out.txt.stderr, the exit code to rc.
# Shape: the assertions read the written bucket rows, messages and export,
# and the -V sections named; -ni, no index.
run_o() {
    local tag="$1"; shift
    local dir="$TMP_DIR/$tag" rc=0
    if ! claim_run_dir "$dir"; then fail=$((fail + 1)); return 0; fi
    ( cd "$dir" && "$LTL" --disable-progress -ni -o "$@" > out.txt 2> out.txt.stderr ) || rc=$?
    echo "$rc" > "$dir/rc"
    check_capture_warnings "$dir/out.txt" "$tag"
}

# stats_rows DIR COLUMN... — the STATS CSV's rows as "bucket|value...;", the
# named columns in order; MISSING-* when the file or a column is absent.
stats_rows() {
    local dir="$1"; shift
    local f
    f=$(find "$dir" -name '*-LTL-STATS-*.csv' -print -quit)
    [[ -n "$f" ]] || { echo 'MISSING-STATS-CSV'; return 0; }
    perl -e 'my ($file, @want) = @ARGV; open my $fh, "<", $file or die; chomp(my $h = <$fh>); my @h = split /,/, $h; my %i; @i{@h} = 0 .. $#h;
             for (@want) { unless (exists $i{$_}) { print "MISSING-COLUMN:$_"; exit } }
             while (<$fh>) { chomp; my @f = split /,/, $_, -1; $f[0] =~ s/"//g; print join("|", $f[0], map { $f[$i{$_}] } @want), ";" }' "$f" "$@"
}

# export_bounds DIR — the YAML export's observed start and end, "START|END".
export_bounds() {
    local f
    f=$(find "$1" -name '*-LTL-AGGREGATE.yaml' -print -quit)
    [[ -n "$f" ]] || { echo 'MISSING-EXPORT'; return 0; }
    perl -ne '$s = $1 if !defined $s && /^\s*start: (.+)$/; $e = $1 if !defined $e && /^\s*end: (.+)$/; END { print(($s // "MISSING-ANCHOR:start") . "|" . ($e // "MISSING-ANCHOR:end")) }' "$f"
}

CONTRACT_615_AC1='features/615-csv-registry-entry.md D1 (CSV input is a registry entry instantiated from each file header), D10 (the header builds the routine) and AC1 (same output for a month-first or epoch CSV)'

echo "Validating CSV columnar input (Issues #328, #640, #615)"
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
        produced_by 'detect_and_parse_csv_header() + the block csv_block_for_file() serves the file with, in read_and_process_logs() in ltl' \
        contract    'features/user-defined-metrics.md § CSV Columnar Input'

    epoch_rc=0; run_ltl "$TMP_DIR/epoch.out" "$TMP_DIR/epoch.csv" -udm latency:ms:mean || epoch_rc=$?
    check_capture_warnings "$TMP_DIR/epoch.out" "epoch-timestamp-csv"
    assert_command \
        command     "[[ $epoch_rc -eq 0 ]] && grep -aq 'latency' '$TMP_DIR/epoch.out'" \
        label       'epoch-timestamp CSV ingests: exit 0, latency column rendered' \
        asserts     'A CSV with numeric epoch timestamps is auto-detected on the first data line and ingested' \
        produced_by 'csv_block_for_file() in ltl (the file kind read from line 2) and the csv_epoch layout of format_timestamp_src()' \
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
        produced_by 'the shape test of the block csv_block_src() generates, before a csv row counts as a match' \
        contract    "features/user-defined-metrics.md § CSV Columnar Input (Issue #328); $CONTRACT_640"
    assert_command \
        command     "[[ \"\$(file_detection_value '$TMP_DIR/mix.out' stats.csv matched_lines)\" == 3 ]]" \
        label       'the quoted, seconds-less CSV ltl writes is read: its three rows match' \
        asserts     'A timestamp in double quotes and without seconds is an accepted CSV form' \
        produced_by 'the shape test and trim of the block csv_block_src() generates' \
        contract    "$CONTRACT_611"
    assert_command \
        command     "! grep -aq 'stats.csv' '$TMP_DIR/mix.out.stderr' && ! grep -aqi 'timestamp' '$TMP_DIR/mix.out.stderr'" \
        label       'no per-row or per-file timestamp message, the file never named on stderr' \
        asserts     'A CSV row without a parsable timestamp is never reported per row or per file' \
        produced_by 'read_and_process_logs() in ltl (the csv row paths)' \
        contract    "$CONTRACT_640"
fi

# --- The accepted CSV forms place their rows where a plain twin does ---------
# The reference rows at whole minutes, unquoted with seconds; the same rows
# quoted, without seconds, quoted with T and no seconds, and as 13-digit epoch
# milliseconds with no -du. Then ltl's own STATS CSV, at -tp m, s and ms,
# read back: each row lands in the minute it names.
if scenario_wanted accepted-forms; then
    current_scenario=accepted-forms
    printf 'timestamp,latency\n2026-06-01 10:00:00,12\n2026-06-01 10:00:00,18\n2026-06-01 10:01:00,34\n' > "$TMP_DIR/forms-ref.csv"
    printf 'timestamp,latency\n"2026-06-01 10:00:00",12\n"2026-06-01 10:00:00",18\n"2026-06-01 10:01:00",34\n' > "$TMP_DIR/forms-quoted.csv"
    printf 'timestamp,latency\n2026-06-01 10:00,12\n2026-06-01 10:00,18\n2026-06-01 10:01,34\n' > "$TMP_DIR/forms-nosec.csv"
    printf 'timestamp,latency\n"2026-06-01T10:00",12\n"2026-06-01T10:00",18\n"2026-06-01T10:01",34\n' > "$TMP_DIR/forms-quoted-t-nosec.csv"
    printf 'timestamp,latency\n1780308000000,12\n1780308000000,18\n1780308060000,34\n' > "$TMP_DIR/forms-epoch-ms.csv"
    want='2026-06-01 10:00|2|15;2026-06-01 10:01|1|34;'
    for form in ref quoted nosec quoted-t-nosec epoch-ms; do
        run_o "forms-$form" -bs 1 -udm latency "$TMP_DIR/forms-$form.csv"
        assert_command \
            command     "[[ \"\$(stats_rows '$TMP_DIR/forms-$form' latency_occurrences latency_mean)\" == '$want' ]]" \
            label       "the $form form places its rows where the plain twin does" \
            asserts     'Each accepted CSV timestamp form names the same instants: quoted, without seconds (second 0), T, 13-digit epoch milliseconds read as milliseconds with no -du' \
            produced_by 'csv_block_src() and csv_block_for_file() in ltl (the trim, the seconds, the epoch unit)' \
            contract    "$CONTRACT_611"
    done
    for tp in m s ms; do
        run_o "forms-stats-$tp" -bs 1 -tp "$tp" -udm latency "$TMP_DIR/forms-ref.csv"
        stats=$(find "$TMP_DIR/forms-stats-$tp" -name '*-LTL-STATS-*.csv' -print -quit)
        run_o "forms-readback-$tp" -bs 1 -udm latency_mean "${stats:-$TMP_DIR/missing-stats-$tp.csv}"
        assert_command \
            command     "[[ \"\$(stats_rows '$TMP_DIR/forms-readback-$tp' latency_mean_occurrences latency_mean_mean)\" == '2026-06-01 10:00|1|15;2026-06-01 10:01|1|34;' ]]" \
            label       "ltl's own STATS CSV written at -tp $tp is read back into the minutes it names" \
            asserts     'The quoted timestamp ltl writes, at every output precision, is an accepted CSV form' \
            produced_by 'csv_block_src() in ltl (the trim and the seconds)' \
            contract    "$CONTRACT_611"
    done
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
        produced_by 'the block csv_block_src() generates (its shape test) and emit_udm_csv_unbound_notices() in ltl' \
        contract    "$CONTRACT_640"
    assert_command \
        command     "[[ \"\$(file_detection_value '$TMP_DIR/idx-in.out' ltl-index.csv matched_lines)\" == 0 ]]" \
        label       'the index shows nothing matched' \
        asserts     'No row of the index is matched' \
        produced_by 'the block csv_block_src() generates (its shape test) + note_unmatched_line() in ltl' \
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
        produced_by 'the block csv_block_src() generates (its shape test) in ltl' \
        contract    "$CONTRACT_640"
    assert_command \
        command     "grep -aq '^  produced: occurrences=1 buckets=1 sum=165 ' '$TMP_DIR/delta.out'" \
        label       'the unplaced row sets no delta baseline: delta 165, not 70' \
        asserts     'A CSV row without a parsable timestamp never reaches the metric capture' \
        produced_by 'the block csv_block_src() generates (its shape test), ahead of the USER DEFINED METRICS CAPTURE block of read_and_process_logs() in ltl' \
        contract    "$CONTRACT_640"
    assert_command \
        command     "[[ \"\$(file_detection_value '$TMP_DIR/delta.out' delta.csv matched_lines)\" == 2 ]]" \
        label       'matched_lines: 2 for the three data rows' \
        asserts     'A CSV row without a parsable timestamp does not count as matched' \
        produced_by 'the block csv_block_src() generates (its shape test) + note_unmatched_line() in ltl' \
        contract    "$CONTRACT_640"

    # An epoch CSV (decided by its first data row) with a non-numeric row.
    printf 'timestamp,latency\n1771078373,12\nabc,5\n1771078433,34\n' > "$TMP_DIR/epoch-bad.csv"
    eb_rc=0; run_ltl "$TMP_DIR/epoch-bad.out" -V filter-summary "$TMP_DIR/epoch-bad.csv" -udm latency:ms:mean || eb_rc=$?
    check_capture_warnings "$TMP_DIR/epoch-bad.out" "unplaced-row-epoch"
    assert_command \
        command     "[[ $eb_rc -eq 0 ]] && [[ ! -s '$TMP_DIR/epoch-bad.out.stderr' ]] && grep -aqx 'lines_included: 2' '$TMP_DIR/epoch-bad.out'" \
        label       'an epoch CSV row that is not a number is unmatched, silently' \
        asserts     'In an epoch-timestamp CSV a row whose timestamp is not epoch seconds never reaches the epoch conversion' \
        produced_by 'the epoch block csv_block_src() generates (its shape test) in ltl' \
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

# --- The header-built block: ISO rows ----------------------------------------
# Three rows, two minutes, a fraction on two of them, the space and the T
# separator, two metrics, and a -udm name the header does not carry. By hand:
# 10:00 holds latency 12 and 18 (mean 15) and size 100 + 300; 10:01 holds
# latency 34 and size 200. The header is the one unmatched line.
if scenario_wanted block-iso; then
    current_scenario=block-iso
    printf 'timestamp,latency,size,host\n2026-06-01 10:00:05.250,12,100,h1\n2026-06-01 10:00:35,18,300,h2\n2026-06-01T10:01:05.5,34,200,h1\n' > "$TMP_DIR/block-iso.csv"
    run_o block-iso -bs 1 -V filter-summary,format-detection -udm latency -udm size::sum -udm absent "$TMP_DIR/block-iso.csv"
    assert_command \
        command     "[[ \$(cat '$TMP_DIR/block-iso/rc') == 0 && \"\$(stats_rows '$TMP_DIR/block-iso' latency_occurrences latency_mean size_sum)\" == '2026-06-01 10:00|2|15|400;2026-06-01 10:01|1|34|200;' ]]" \
        label       'ISO rows land in their minutes with the metric values read from their columns' \
        asserts     'An ISO CSV read by its block gives the bucket rows and metric values derived by hand from the fixture, whatever the date-time separator and the fraction' \
        produced_by 'csv_block_src() (the block) and format_timestamp_src() (its timestamp) in ltl' \
        contract    "$CONTRACT_615_AC1"
    assert_command \
        command     "grep -aqx 'lines_read: 4' '$TMP_DIR/block-iso/out.txt' && grep -aqx 'lines_unmatched: 1' '$TMP_DIR/block-iso/out.txt' && grep -aqx 'lines_included: 3' '$TMP_DIR/block-iso/out.txt' && [[ \"\$(file_detection_value '$TMP_DIR/block-iso/out.txt' block-iso.csv matched_lines)\" == 3 ]]" \
        label       'every line accounted once: the header unmatched, three rows matched and included' \
        asserts     'The block reads line 2 and every row after it once; the header is the one unmatched line' \
        produced_by 'csv_block_for_file() and the csv_detected branch of read_and_process_logs() in ltl; emit_filter_summary_verbose()' \
        contract    "$CONTRACT_615_AC1; features/503-yaml-aggregate-export.md section -V filter-summary"
fi

# --- The header-built block: epoch rows --------------------------------------
# 1780308005 is 2026-06-01 10:00:05 UTC (by hand: timegm(5, 0, 10, 1, 5, 2026)).
# Whole and fractional seconds; the same file in milliseconds read with -du ms.
if scenario_wanted block-epoch; then
    current_scenario=block-epoch
    printf 'timestamp,latency\n1780308005,12\n1780308035.75,18\n1780308065.5,34\n' > "$TMP_DIR/block-epoch.csv"
    printf 'timestamp,latency\n1780308005000,12\n1780308035750,18\n1780308065500,34\n' > "$TMP_DIR/block-epoch-ms.csv"
    run_o block-epoch -bs 1 -udm latency "$TMP_DIR/block-epoch.csv"
    run_o block-epoch-ms -bs 1 -du ms -udm latency "$TMP_DIR/block-epoch-ms.csv"
    want='2026-06-01 10:00|2|15;2026-06-01 10:01|1|34;'
    assert_command \
        command     "[[ \"\$(stats_rows '$TMP_DIR/block-epoch' latency_occurrences latency_mean)\" == '$want' ]]" \
        label       'epoch seconds, whole and fractional, land in their minutes' \
        asserts     'An epoch CSV read by its block places each row at the second its value names' \
        produced_by 'the csv_epoch layout of format_timestamp_src() in ltl' \
        contract    "$CONTRACT_615_AC1"
    assert_command \
        command     "[[ \"\$(stats_rows '$TMP_DIR/block-epoch-ms' latency_occurrences latency_mean)\" == '$want' ]]" \
        label       'epoch milliseconds read with -du ms land in the same minutes' \
        asserts     'The -du unit is folded into the epoch block as a constant scale' \
        produced_by 'the csv_epoch layout of format_timestamp_src() in ltl (epoch_unit)' \
        contract    "$CONTRACT_615_AC1; features/user-defined-metrics.md section Epoch timestamps"
fi

# --- The -ucm columns form the message ---------------------------------------
if scenario_wanted block-message-columns; then
    current_scenario=block-message-columns
    printf 'timestamp,latency,host,pool\n2026-06-01 10:00:05,12,h1,p1\n2026-06-01 10:00:35,18,h2,p2\n2026-06-01 10:01:05,34,h1,p1\n' > "$TMP_DIR/block-msg.csv"
    run_o block-msg -bs 1 -udm latency -ucm 'host pool' "$TMP_DIR/block-msg.csv"
    assert_command \
        command     "f=\$(find '$TMP_DIR/block-msg' -name '*-LTL-MESSAGES-*.csv' -print -quit); [[ -n \"\$f\" ]] && grep -aq '\"\\[DATA\\] \\[\\] h1 p1\",2,' \"\$f\" && grep -aq '\"\\[DATA\\] \\[\\] h2 p2\",1,' \"\$f\"" \
        label       'the -ucm columns, joined by a space, form each row message: h1 p1 twice, h2 p2 once' \
        asserts     'The block reads the -ucm columns at their compiled positions and joins them, trimmed, with a space' \
        produced_by 'csv_block_src() in ltl (the message columns)' \
        contract    "$CONTRACT_615_AC1"
fi

# --- Fraction digits under the standard capture rules (D16) ------------------
# Nine digits read as written under -tp ns, ISO and epoch alike: the export's
# observed bounds carry them.
if scenario_wanted block-fraction-digits; then
    current_scenario=block-fraction-digits
    printf 'timestamp,latency\n2026-06-01 10:00:05.123456789,12\n2026-06-01 10:01:05.987654321,34\n' > "$TMP_DIR/frac-iso.csv"
    printf 'timestamp,latency\n1780308005.123456789,12\n1780308065.987654321,34\n' > "$TMP_DIR/frac-epoch.csv"
    run_o frac-iso -bs 1440 -oe -tp ns -udm latency "$TMP_DIR/frac-iso.csv"
    run_o frac-epoch -bs 1440 -oe -tp ns -udm latency "$TMP_DIR/frac-epoch.csv"
    for k in iso epoch; do
        assert_command \
            command     "[[ \"\$(export_bounds '$TMP_DIR/frac-$k')\" == '2026-06-01 10:00:05.123456789|2026-06-01 10:01:05.987654321' ]]" \
            label       "$k: all nine fraction digits as written under -tp ns" \
            asserts     'A CSV timestamp is read under the run standard capture rules: under nanosecond the digits are kept as written' \
            produced_by 'format_timestamp_src() in ltl (the generic strip for ISO, the csv_epoch layout for epoch)' \
            contract    'features/615-csv-registry-entry.md D16 (a CSV file timestamp is read under the run standard capture rules) and section 5.9'
    done
fi

# --- The header builds the routine: columns in another order -----------------
if scenario_wanted block-column-order; then
    current_scenario=block-column-order
    printf 'timestamp,latency,size\n2026-06-01 10:00:05,12,100\n2026-06-01 10:01:05,34,200\n' > "$TMP_DIR/order-a.csv"
    printf 'size,timestamp,latency\n100,2026-06-01 10:00:05,12\n200,2026-06-01 10:01:05,34\n' > "$TMP_DIR/order-b.csv"
    run_o order-a -bs 1 -udm latency -udm size::sum "$TMP_DIR/order-a.csv"
    run_o order-b -bs 1 -udm latency -udm size::sum "$TMP_DIR/order-b.csv"
    want='2026-06-01 10:00|12|100;2026-06-01 10:01|34|200;'
    assert_command \
        command     "[[ \"\$(stats_rows '$TMP_DIR/order-a' latency_mean size_sum)\" == '$want' && \"\$(stats_rows '$TMP_DIR/order-b' latency_mean size_sum)\" == '$want' ]]" \
        label       'the same columns in another order give the same metric values' \
        asserts     'Each file block reads the timestamp and every metric at the positions its own header gives' \
        produced_by 'csv_block_shape() and csv_block_src() in ltl' \
        contract    'features/615-csv-registry-entry.md D10 (the header builds the routine) and AC5'
fi

# --- Day first, decided from the sampled rows (D9, D15) ----------------------
# Above the three 8 KiB sample parts, written year, day, month. The first 700
# rows (2025-05-03: 5 March) are ambiguous, line 2 among them; the last 700
# (2025-20-03: 20 March) are real only day first, and the end part of the
# sample reads them. By hand: 700 rows on 5 March, 700 on 20 March.
if scenario_wanted day-first-sampled; then
    current_scenario=day-first-sampled
    perl -e 'print "timestamp,v\n"; for my $d ("05", "20") { for my $i (0 .. 699) { printf "2025-%s-03 10:%02d:%02d,1\n", $d, int($i / 60), $i % 60 } }' > "$TMP_DIR/dayfirst-big.csv"
    size=$(wc -c < "$TMP_DIR/dayfirst-big.csv" | tr -d ' ')
    run_o dayfirst-big -bs 1440 -oe -V filter-summary -udm v "$TMP_DIR/dayfirst-big.csv"
    assert_command \
        command     "[[ $size -gt 24576 && \$(cat '$TMP_DIR/dayfirst-big/rc') == 0 && \"\$(stats_rows '$TMP_DIR/dayfirst-big' v_occurrences)\" == '2025-03-05 00:00|700;2025-03-20 00:00|700;' ]]" \
        label       "a ${size}-byte day-first CSV with ambiguous front rows is read day first: 700 rows on 5 March, 700 on 20 March" \
        asserts     'The date order is settled from the rows sampled across the file, not from line 2: the month-first block fails on the end part and the day-first block serves the file' \
        produced_by 'csv_block_for_file() and csv_validate_block() in ltl, on the rows sample_file_for_detection() read' \
        contract    'features/615-csv-registry-entry.md D9 (validation on the sampled rows with the day-first retry), D15 and AC6 (a)'
    assert_command \
        command     "grep -aqx 'lines_read: 1401' '$TMP_DIR/dayfirst-big/out.txt' && grep -aqx 'lines_unmatched: 1' '$TMP_DIR/dayfirst-big/out.txt' && grep -aqx 'lines_included: 1400' '$TMP_DIR/dayfirst-big/out.txt'" \
        label       'every line accounted once: 1401 read, the header unmatched, 1400 included' \
        asserts     'Validation reads the sample through its own handle: no production line is replayed or lost' \
        produced_by 'csv_block_for_file() in ltl; emit_filter_summary_verbose()' \
        contract    'features/615-csv-registry-entry.md D9 and AC6 (c); features/log-format-registry.md D53'
fi

# --- A two-row file real only day first (D15) --------------------------------
if scenario_wanted day-first-small; then
    current_scenario=day-first-small
    printf 'timestamp,v\n2025-13-01 10:00:05,5\n' > "$TMP_DIR/dayfirst-small.csv"
    run_o dayfirst-small -bs 1440 -oe -V filter-summary -udm v "$TMP_DIR/dayfirst-small.csv"
    assert_command \
        command     "[[ \$(cat '$TMP_DIR/dayfirst-small/rc') == 0 && \"\$(stats_rows '$TMP_DIR/dayfirst-small' v_occurrences v_sum)\" == '2025-01-13 00:00|1|5;' ]]" \
        label       'a row dated 2025-13-01 reads as 13 January instead of ending the run' \
        asserts     'A CSV whose sampled rows are real dates only day first is read day first' \
        produced_by 'csv_block_for_file() in ltl (the day-first retry)' \
        contract    'features/615-csv-registry-entry.md D15 and AC6 (b)'
    assert_command \
        command     "grep -aqx 'lines_read: 2' '$TMP_DIR/dayfirst-small/out.txt' && grep -aqx 'lines_unmatched: 1' '$TMP_DIR/dayfirst-small/out.txt' && grep -aqx 'lines_included: 1' '$TMP_DIR/dayfirst-small/out.txt'" \
        label       'every line accounted once: 2 read, the header unmatched, 1 included' \
        asserts     'Validation reads the sample through its own handle: no production line is replayed or lost' \
        produced_by 'csv_block_for_file() in ltl; emit_filter_summary_verbose()' \
        contract    'features/615-csv-registry-entry.md D9 and AC6 (c)'
fi

# --- A month-first file after a day-first one with the same header -----------
if scenario_wanted day-first-then-month-first; then
    current_scenario=day-first-then-month-first
    printf 'timestamp,v\n2025-13-01 10:00:05,5\n' > "$TMP_DIR/a-dayfirst.csv"
    printf 'timestamp,v\n2025-03-20 10:00:05,7\n' > "$TMP_DIR/b-monthfirst.csv"
    run_o dayfirst-then -bs 1440 -oe -udm v "$TMP_DIR/a-dayfirst.csv" "$TMP_DIR/b-monthfirst.csv"
    assert_command \
        command     "[[ \$(cat '$TMP_DIR/dayfirst-then/rc') == 0 && \"\$(stats_rows '$TMP_DIR/dayfirst-then' v_sum)\" == '2025-01-13 00:00|5;2025-03-20 00:00|7;' ]]" \
        label       'the second file is read month first: 13 January from the first, 20 March from the second' \
        asserts     'The live day-first block fails the second file sampled rows, and a month-first block replaces it' \
        produced_by 'csv_block_for_file() in ltl (the live block validated first, then the other order)' \
        contract    'features/615-csv-registry-entry.md D9, D11 and AC6 (e)'
fi

# --- An ambiguous file after a day-first one with the same header (D18) ------
# Every date of the second file (2025-05-03) is real in both orders: it is
# read month first, 3 May, as it would be on its own, not day first (5 March)
# because the file before it was.
if scenario_wanted day-first-then-ambiguous; then
    current_scenario=day-first-then-ambiguous
    printf 'timestamp,v\n2025-13-01 10:00:05,5\n' > "$TMP_DIR/c-dayfirst.csv"
    printf 'timestamp,v\n2025-05-03 10:00:05,7\n' > "$TMP_DIR/d-ambiguous.csv"
    run_o dayfirst-ambiguous -bs 1440 -oe -udm v "$TMP_DIR/c-dayfirst.csv" "$TMP_DIR/d-ambiguous.csv"
    assert_command \
        command     "[[ \$(cat '$TMP_DIR/dayfirst-ambiguous/rc') == 0 && \"\$(stats_rows '$TMP_DIR/dayfirst-ambiguous' v_sum)\" == '2025-01-13 00:00|5;2025-05-03 00:00|7;' ]]" \
        label       'the ambiguous second file is read month first: 13 January from the first, 3 May from the second' \
        asserts     'Every CSV file date order is settled starting month first, whatever file came before it' \
        produced_by 'csv_block_for_file() in ltl (month first tried first, the live block reused only for the order being tried)' \
        contract    'features/615-csv-registry-entry.md D18 and AC6 (f)'
fi

# --- The delimiter, detected or given (D14, AC11) ----------------------------
# Detected from the header among comma, semicolon and tab, with no -ucs and no
# -ucm; -ucs overrides it without -ucm. By hand: latency 12 at 10:00, 34 at
# 10:01.
CONTRACT_D14='features/615-csv-registry-entry.md D14 (the delimiter is auto-detected, comma, semicolon or tab, and -ucs overrides it with or without -ucm) and AC11'
if scenario_wanted separator-detected; then
    current_scenario=separator-detected
    printf 'timestamp;latency\n2026-06-01 10:00:05;12\n2026-06-01 10:01:05;34\n' > "$TMP_DIR/sep-semicolon.csv"
    printf 'timestamp\tlatency\n2026-06-01 10:00:05\t12\n2026-06-01 10:01:05\t34\n' > "$TMP_DIR/sep-tab.csv"
    for k in semicolon tab; do
        run_o "sep-$k" -bs 1 -udm latency "$TMP_DIR/sep-$k.csv"
        assert_command \
            command     "[[ \"\$(stats_rows '$TMP_DIR/sep-$k' latency_mean)\" == '2026-06-01 10:00|12;2026-06-01 10:01|34;' ]]" \
            label       "a $k-separated CSV read with no -ucs and no -ucm is split on its $k" \
            asserts     'The delimiter is detected from the header, among comma, semicolon and tab' \
            produced_by 'detect_and_parse_csv_header() in ltl' \
            contract    "$CONTRACT_D14"
    done
fi

if scenario_wanted separator-option; then
    current_scenario=separator-option
    printf 'timestamp|latency\n2026-06-01 10:00:05|12\n2026-06-01 10:01:05|34\n' > "$TMP_DIR/sep-pipe.csv"
    run_o sep-pipe-given -bs 1 -udm latency -ucs '|' "$TMP_DIR/sep-pipe.csv"
    assert_command \
        command     "[[ \"\$(stats_rows '$TMP_DIR/sep-pipe-given' latency_mean)\" == '2026-06-01 10:00|12;2026-06-01 10:01|34;' ]]" \
        label       'a |-separated CSV read with -ucs and no -ucm is split on |' \
        asserts     '-ucs sets the delimiter without -ucm' \
        produced_by 'detect_and_parse_csv_header() in ltl (the -ucs override)' \
        contract    "$CONTRACT_D14"
    run_o sep-pipe-none -bs 1 -V filter-summary -udm latency "$TMP_DIR/sep-pipe.csv"
    assert_command \
        command     "grep -aqx 'lines_unmatched: 3' '$TMP_DIR/sep-pipe-none/out.txt' && grep -aqx 'lines_included: 0' '$TMP_DIR/sep-pipe-none/out.txt'" \
        label       'the same file without -ucs is not read as CSV: all 3 lines unmatched' \
        asserts     'Only comma, semicolon and tab are detected; any other delimiter needs -ucs' \
        produced_by 'detect_and_parse_csv_header() in ltl' \
        contract    "$CONTRACT_D14"
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
