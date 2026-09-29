#!/usr/bin/env bash
# validate-byte-units.sh — Validate the one byte-unit ladder every byte
# surface reads (issue #608): the byte values the tool derives and the byte
# strings it renders.
#
# Contract: features/608-byte-unit-ladder.md (D5 one byte ladder, D11 GC heap
# values unchanged) and its Acceptance criteria. The byte-unit feature has no
# owning -V section: the criteria read the STATS CSV cells a run writes, so
# the harness is named for the feature, as validate-bucket-size-units.sh is.
#
# Usage: ./tests/validate-byte-units.sh [--scenario NAME | --list]
#
# Implements the self-documenting-assertion design from
# tests/HARNESS-DESIGN.md. Reference: tests/validate-bucket-size-units.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"

neutralize_colour_env

# Invocation shape (tests/HARNESS-DESIGN.md section Invocation coherence):
# the assertions read the STATS CSV's run totals, which do not depend on the
# bucket size, so one day-wide bucket, no empty buckets, no index. The G1 GC
# fixture carries five heap transitions, all written in M.
GC_FIXTURE="$REPO_DIR/tests/fixtures/gc-g1-categories.txt"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

for f in "$LTL" "$GC_FIXTURE"; do
    if [[ ! -e "$f" ]]; then
        echo "ERROR: required file missing: $f" >&2
        exit 1
    fi
done

CONTRACT_D11='features/608-byte-unit-ladder.md D11 (the GC transform maps its suffixes to ladder tokens at their present values; no GC value changes)'

pass=0
fail=0
failures=()
current_scenario=""

fail_with() {
    # fail_with LABEL ASSERTS PRODUCED_BY CONTRACT [DETAIL...]
    local label="$1" asserts="$2" produced_by="$3" contract="$4"
    shift 4
    echo "  FAIL  $current_scenario :: $label"
    echo "        asserts:     $asserts"
    echo "        produced_by: $produced_by"
    echo "        contract:    $contract"
    local d
    for d in "$@"; do echo "        $d"; done
    fail=$((fail + 1))
    failures+=("$current_scenario :: $label")
}

pass_with() {
    echo "  PASS  $current_scenario :: $1"
    pass=$((pass + 1))
}

# run_ltl_in DIR TAG ARGS... — runs ltl inside DIR (the CSV files land
# there), stdout to DIR/TAG.out, stderr to DIR/TAG.err, exit code to
# DIR/TAG.rc, and applies the runtime-warning check.
run_ltl_in() {
    local dir="$1" tag="$2"; shift 2
    mkdir -p "$dir"
    set +e
    ( cd "$dir" && "$LTL" "$@" ) > "$dir/$tag.out" 2> "$dir/$tag.err"
    echo $? > "$dir/$tag.rc"
    set -e
    if ! assert_no_runtime_warnings "$dir/$tag.err" "$current_scenario/$tag"; then
        fail=$((fail + 1))
        failures+=("$current_scenario :: runtime warnings ($tag)")
    fi
}

# stats_cell DIR COLUMN — the COLUMN value of the STATS CSV's first data row;
# a missing file or column is reported as MISSING-ANCHOR (Trap 3/4).
stats_cell() {
    local dir="$1" column="$2" file
    file=$(ls "$dir"/*STATS*.csv 2>/dev/null | head -1)
    if [[ -z "$file" ]]; then
        echo "MISSING-ANCHOR:STATS-csv"
        return
    fi
    python3 - "$file" "$column" <<'PY'
import csv, sys
rows = list(csv.DictReader(open(sys.argv[1], newline='')))
if not rows or sys.argv[2] not in rows[0]:
    print("MISSING-ANCHOR:" + sys.argv[2])
else:
    print(rows[0][sys.argv[2]])
PY
}

# ---------------------------------------------------------------------------
# Criterion 12 — the GC heap delta is byte-identical: the suffixes read
# through the ladder at their present values (K 1024; M, G, T powers of
# 1000), so 69,786,000,000 bytes over the fixture's five transitions. The run
# exiting 0 is also the GC entry's self-validation passing: its sample rows
# (2433M->66M expecting 2367000000) are checked on every invocation, and a
# mismatch ends the run.
# ---------------------------------------------------------------------------
scenario_gc_heap_values_unchanged() {
    current_scenario="gc-heap-values-unchanged"
    echo "[$current_scenario]"
    local dir="$TMP_DIR/gc" rc bytes nice
    run_ltl_in "$dir" gc --disable-progress -ni -bs 1440 -oe -o "$GC_FIXTURE"
    rc=$(cat "$dir/gc.rc")
    if [[ "$rc" == 0 ]]; then
        pass_with "the run exits 0: the GC entry's self-validation rows pass"
    else
        fail_with "the run exits 0: the GC entry's self-validation rows pass" \
            'The GC entry sample 2433M->66M still extracts 2367000000 bytes; a self-validation mismatch ends the run' \
            'build_format_registry() self-validation in ltl, over the gc_heap_delta transform and gc_heap_size_bytes()' \
            "$CONTRACT_D11" "exit: $rc" "stderr: $(head -3 "$dir/gc.err")"
    fi
    bytes=$(stats_cell "$dir" bytes)
    if [[ "$bytes" == "69786000000" ]]; then
        pass_with "STATS bytes total is 69786000000"
    else
        fail_with "STATS bytes total is 69786000000" \
            'The five heap transitions in M sum to 69,786,000,000 bytes: M is read as a power of 1000, as before' \
            'gc_heap_size_bytes() via the gc_heap_delta transform in ltl' \
            "$CONTRACT_D11" "got: $bytes"
    fi
    nice=$(stats_cell "$dir" bytes_nice)
    if [[ "$nice" == "65 GiB" ]]; then
        pass_with "STATS bytes_nice is 65 GiB"
    else
        fail_with "STATS bytes_nice is 65 GiB" \
            'The GC total renders as it did before the byte ladder' \
            'format_bytes() in ltl' \
            "$CONTRACT_D11" "got: $nice"
    fi
}

scenario_register gc-heap-values-unchanged
scenario_parse_args "$@"

while read -r _scenario; do
    case "$_scenario" in
        gc-heap-values-unchanged) scenario_gc_heap_values_unchanged ;;
    esac
done < <(scenario_selected)

# ---------------------------------------------------------------------------
echo
echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    printf '  %s\n' "${failures[@]}"
    exit 1
fi
exit 0
