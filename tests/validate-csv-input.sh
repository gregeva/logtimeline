#!/usr/bin/env bash
# validate-csv-input.sh — CSV columnar input robustness harness (Issue #328)
#
# Validates the -udm CSV columnar input path (features/user-defined-metrics.md
# § CSV Columnar Input): valid ISO and epoch timestamp CSVs are ingested, and
# a CSV whose timestamp column is neither epoch nor ISO (e.g. a quoted field
# from a previous ltl -o run swept into a multi-file glob) is skipped row by
# row with a warning instead of dying inside timegm().
#
# Fixtures are generated inline: their content is the contract under test and
# has no value as committed files.
#
# Usage: ./tests/validate-csv-input.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LTL="$(cd "$SCRIPT_DIR/.." && pwd)/ltl"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

pass=0
fail=0

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
        echo "  PASS  $label"
        pass=$((pass + 1))
    else
        echo "  FAIL  $label"
        echo "        command:     $command"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
    fi
}

# --- Fixtures -------------------------------------------------------------

# Valid ISO-timestamp CSV
printf 'timestamp,latency\n2026-06-01 10:00:05,12\n2026-06-01 10:01:05,34\n2026-06-01 10:02:05,56\n' > "$TMP_DIR/iso.csv"

# Valid epoch-timestamp CSV
printf 'timestamp,latency\n1771078373,12\n1771078433,34\n' > "$TMP_DIR/epoch.csv"

# Mixed input dir: a ThingWorx-format log next to a CSV whose timestamp
# column is quoted (the shape of ltl's own -o STATS output) — the #328
# crash reproduction.
mkdir "$TMP_DIR/mix"
printf '%s\n' \
    '2026-06-01 10:00:00.100+0000 [L: WARN] [O: obj] [I: ] [U: u] [S: ] [P: ] [T: pool-1] message one durationMS=5' \
    '2026-06-01 10:01:00.100+0000 [L: WARN] [O: obj] [I: ] [U: u] [S: ] [P: ] [T: pool-1] message two durationMS=7' \
    > "$TMP_DIR/mix/app.log"
printf 'timestamp,occurrences,bytes\n"2026-06-01 10:00",10,100\n"2026-06-01 12:00",20,200\n"2026-06-01 14:00",30,300\n' > "$TMP_DIR/mix/stats.csv"

# --- Assertions -----------------------------------------------------------

echo "[csv-input]"

# Never toggles errexit itself: callers capture the exit code with
# `rc=0; run_ltl ... || rc=$?`, which is condition context under set -e.
run_ltl() {
    local out="$1"; shift
    "$LTL" --disable-progress "$@" > "$out" 2>"$out.stderr"
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

# 1. Valid ISO CSV ingests cleanly.
iso_rc=0; run_ltl "$TMP_DIR/iso.out" "$TMP_DIR/iso.csv" -udm latency:ms:mean || iso_rc=$?
check_capture_warnings "$TMP_DIR/iso.out" "iso-timestamp-csv"
assert_command \
    command     "[[ $iso_rc -eq 0 ]] && grep -aq 'latency' '$TMP_DIR/iso.out' && ! grep -aqE ' at .+ line [0-9]+' '$TMP_DIR/iso.out'" \
    label       'ISO-timestamp CSV ingests: exit 0, latency column rendered, no runtime warnings' \
    asserts     'A CSV with ISO YYYY-MM-DD HH:MM:SS timestamps and a -udm column is detected and ingested without Perl runtime warnings' \
    produced_by 'detect_and_parse_csv_header() + the csv_detected branch of read_and_process_logs() in ltl' \
    contract    'features/user-defined-metrics.md § CSV Columnar Input'

# 2. Epoch CSV ingests cleanly.
epoch_rc=0; run_ltl "$TMP_DIR/epoch.out" "$TMP_DIR/epoch.csv" -udm latency:ms:mean || epoch_rc=$?
check_capture_warnings "$TMP_DIR/epoch.out" "epoch-timestamp-csv"
assert_command \
    command     "[[ $epoch_rc -eq 0 ]] && ! grep -aqE ' at .+ line [0-9]+' '$TMP_DIR/epoch.out'" \
    label       'epoch-timestamp CSV ingests: exit 0, no runtime warnings' \
    asserts     'A CSV with numeric epoch timestamps is auto-detected on the first data line and ingested' \
    produced_by 'csv_epoch_timestamp detection in read_and_process_logs() in ltl' \
    contract    'features/user-defined-metrics.md § CSV Columnar Input (Epoch timestamps, Issue #98)'

# 3. Mixed glob with an unparseable-timestamp CSV: no crash, rows skipped with warning.
mix_rc=0; run_ltl "$TMP_DIR/mix.out" "$TMP_DIR"/mix/* -udm endpoints::distinct:endpointId || mix_rc=$?
check_capture_warnings "$TMP_DIR/mix.out" "mixed-glob-quoted-timestamp-csv"
assert_command \
    command     "[[ $mix_rc -eq 0 ]]" \
    label       'mixed glob (log + quoted-timestamp CSV) exits 0 instead of dying in timegm()' \
    asserts     'A CSV row whose timestamp column is neither epoch nor ISO is skipped, never fed to the fixed-offset substr/timegm parse' \
    produced_by 'match_type 13 timestamp guard in read_and_process_logs() in ltl' \
    contract    'features/user-defined-metrics.md § CSV Columnar Input (unparseable-timestamp rows are skipped, Issue #328)'

# The intentional skip diagnostic is printed to stderr, so this assertion
# reads the stderr capture, not the stdout capture.
assert_command \
    command     "grep -aq 'CSV timestamp' '$TMP_DIR/mix.out.stderr' && grep -aq 'skipping row' '$TMP_DIR/mix.out.stderr'" \
    label       'skipped CSV rows are surfaced with a warning naming file, line, and offending value' \
    asserts     'The first unparseable-timestamp row in a file emits a warning naming the file, line number, and value; the run is not silent about dropping data' \
    produced_by 'match_type 13 timestamp guard in read_and_process_logs() in ltl' \
    contract    'features/user-defined-metrics.md § CSV Columnar Input (unparseable-timestamp rows are skipped, Issue #328)'

echo ""
echo "=== CSV input robustness: $pass pass, $fail fail ==="
[[ $fail -eq 0 ]] || exit 1
exit 0
