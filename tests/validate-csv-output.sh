#!/usr/bin/env bash
# validate-csv-output.sh — Categorical CSV-output integrity harness (Issue #223)
#
# Validates structural correctness of -o CSV outputs (MESSAGES and STATS):
# column presence, ordering, population, family group consistency, data-type
# correctness, fixed-decimal rules. All checks are pass/fail (no tolerance).
#
# Sibling to validate-percentile-values.sh (#224), which handles numeric drift.
# Run this BEFORE drift checks — structural correctness is a precondition for
# meaningful drift comparison.
#
# Usage:
#   ./tests/validate-csv-output.sh                       # all scenarios
#   ./tests/validate-csv-output.sh --scenario <name>     # single scenario

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"
HARNESS_DIR="$SCRIPT_DIR/csv-output"
SCENARIOS_TSV="$HARNESS_DIR/scenarios.tsv"
RULES_MESSAGES="$HARNESS_DIR/rules/messages-columns.tsv"
RULES_STATS="$HARNESS_DIR/rules/stats-columns.tsv"
VALIDATOR="$HARNESS_DIR/validate-csv-output.pl"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

ONLY_SCENARIO=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --scenario) ONLY_SCENARIO="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,15p' "$0"
            exit 0
            ;;
        *) echo "unknown arg: $1" >&2; exit 2 ;;
    esac
done

# Sanity: required files exist. A missing file would silently skip work and
# falsely pass, so fail loudly here.
for f in "$LTL" "$SCENARIOS_TSV" "$RULES_MESSAGES" "$RULES_STATS" "$VALIDATOR"; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: required file missing: $f" >&2
        exit 1
    fi
done

total_pass=0
total_fail=0
scenarios_run=0

# Single loop fed by process substitution so counter mutations stay in the
# parent shell. Skip the header line of the TSV.
while IFS=$'\t' read -r scenario logfile options families; do
    [[ -z "$scenario" ]] && continue
    [[ "$scenario" =~ ^# ]] && continue
    if [[ -n "$ONLY_SCENARIO" && "$scenario" != "$ONLY_SCENARIO" ]]; then
        continue
    fi

    abs_log="$REPO_DIR/$logfile"
    if [[ ! -f "$abs_log" ]]; then
        echo "FAIL  scenario=$scenario logfile-missing=$abs_log" >&2
        total_fail=$((total_fail + 1))
        scenarios_run=$((scenarios_run + 1))
        continue
    fi

    scen_dir="$TMP_DIR/$scenario"
    mkdir -p "$scen_dir"

    # Run ltl in the per-scenario tempdir — `-o` writes CSV files with
    # timestamped filenames into the current working directory.
    # `-V csv-output` requested in the same invocation so the precision
    # observability surface is captured alongside the CSVs; the validator
    # reads it for per-family decimal ceiling assertions (#268).
    pushd "$scen_dir" >/dev/null
    set +e
    # shellcheck disable=SC2086  # word-splitting on $options is intentional
    "$LTL" --disable-progress -V csv-output $options -o "$abs_log" >"$scen_dir/ltl.stdout" 2>"$scen_dir/ltl.stderr"
    rc=$?
    set -e
    popd >/dev/null

    if [[ $rc -ne 0 ]]; then
        echo "FAIL  scenario=$scenario ltl-exit=$rc" >&2
        sed 's/^/        /' "$scen_dir/ltl.stderr" >&2
        total_fail=$((total_fail + 1))
        scenarios_run=$((scenarios_run + 1))
        continue
    fi

    # Find produced CSV files by ltl's filename convention.
    msg_csv="$(ls "$scen_dir"/*-LTL-MESSAGES-*.csv 2>/dev/null | head -1 || true)"
    stats_csv="$(ls "$scen_dir"/*-LTL-STATS-*.csv 2>/dev/null | head -1 || true)"

    if [[ -z "$msg_csv" || -z "$stats_csv" ]]; then
        echo "FAIL  scenario=$scenario missing-csv-files messages=${msg_csv:-MISSING} stats=${stats_csv:-MISSING}" >&2
        total_fail=$((total_fail + 1))
        scenarios_run=$((scenarios_run + 1))
        continue
    fi

    # Extract -V csv-output / precision sub-section into a file the
    # validator reads. Anchored by the 'precision' sub-section markers
    # so the parent 'csv-output' wrapper is filtered out. (#268)
    v_precision="$scen_dir/csv-output-precision.txt"
    awk '/=== csv-output \/ precision ===/{flag=1; next} /=== END csv-output \/ precision ===/{flag=0} flag' \
        "$scen_dir/ltl.stdout" > "$v_precision"
    if [[ ! -s "$v_precision" ]]; then
        echo "FAIL  scenario=$scenario missing-v-csv-output-precision-block" >&2
        echo "        -V csv-output / precision sub-section was empty or absent in ltl stdout" >&2
        echo "        asserts: every -o run must emit -V csv-output / precision when -V csv-output is requested" >&2
        echo "        produced_by: emit_csv_output_verbose() in ltl" >&2
        echo "        contract: Issue #268 § locked observability surface" >&2
        total_fail=$((total_fail + 1))
        scenarios_run=$((scenarios_run + 1))
        continue
    fi

    scen_fail=0

    for kind in messages stats; do
        if [[ "$kind" == "messages" ]]; then
            rules="$RULES_MESSAGES"
            csv="$msg_csv"
        else
            rules="$RULES_STATS"
            csv="$stats_csv"
        fi

        set +e
        perl "$VALIDATOR" \
            --rules "$rules" \
            --csv "$csv" \
            --scenario "$scenario" \
            --file-kind "$kind" \
            --expected-families "$families" \
            --v-precision "$v_precision"
        vrc=$?
        set -e

        if [[ $vrc -ne 0 ]]; then
            scen_fail=$((scen_fail + 1))
        fi
    done

    scenarios_run=$((scenarios_run + 1))
    if [[ $scen_fail -eq 0 ]]; then
        echo "PASS  scenario=$scenario messages+stats validated"
        total_pass=$((total_pass + 1))
    else
        echo "FAIL  scenario=$scenario validator-failures=$scen_fail"
        total_fail=$((total_fail + 1))
    fi
done < <(tail -n +2 "$SCENARIOS_TSV")

echo ""
echo "=== CSV output integrity: $scenarios_run scenarios, $total_pass pass, $total_fail fail ==="

if [[ $scenarios_run -eq 0 ]]; then
    echo "ERROR: no scenarios were run (check --scenario filter and scenarios.tsv)" >&2
    exit 1
fi

[[ $total_fail -eq 0 ]] || exit 1
exit 0
