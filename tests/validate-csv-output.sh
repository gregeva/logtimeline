#!/usr/bin/env bash
# validate-csv-output.sh — Categorical CSV-output integrity harness (Issue #223)
#
# Validates structural correctness of -o CSV outputs (MESSAGES and STATS):
# column presence, ordering, population, family group consistency, data-type
# correctness, fixed-decimal rules. All checks are pass/fail (no tolerance).
#
# Sibling to validate-statistics.sh (#224), which handles numeric drift,
# intra-row consistency, and oracle correctness.
# Run this BEFORE the statistics harness — structural correctness is a
# precondition for meaningful drift comparison.
#
# CSV production is delegated to tests/lib/csv-cache.sh which caches
# produced CSVs under deterministic filenames in tests/.artifacts/csv/
# so the statistics harness can reuse them.
#
# Orchestration: set CI=1 (industry-standard env var, also set by all
# major CI runners) when chaining this harness with others, so the cache
# is preserved for the next harness in the chain. The orchestrator is
# responsible for calling cleanup-test-artifacts.sh at the end. When CI
# is unset, this harness cleans up its own artifacts at end of run.
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

# shellcheck source=lib/csv-cache.sh
source "$SCRIPT_DIR/lib/csv-cache.sh"

# End-of-run cleanup runs only when standalone (CI unset). Trap covers
# both clean exit and error paths.
trap csv_cache_maybe_cleanup EXIT

ONLY_SCENARIO=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --scenario) ONLY_SCENARIO="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,24p' "$0"
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

    log_shorthand="$(csv_cache_logfile_shorthand "$logfile")"

    set +e
    csv_cache_produce "$scenario" "$logfile" "$options" "$log_shorthand"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        # csv_cache_produce already printed the diagnostic.
        total_fail=$((total_fail + 1))
        scenarios_run=$((scenarios_run + 1))
        continue
    fi

    msg_csv="$CSV_CACHE_MESSAGES"
    stats_csv="$CSV_CACHE_STATS"

    # Capture -V csv-output separately. csv_cache_produce only stages the
    # CSV files; the precision observability surface (#268) is requested
    # here via a second invocation against the same logfile + options so
    # the per-family decimal ceiling assertions can read the run's actual
    # emit contract. The capture lives in a per-scenario tempdir under
    # tests/.artifacts/v-csv-output/ — independent of the shared csv-cache
    # so the contract between this harness and the cache stays narrow.
    v_capture_dir="$SCRIPT_DIR/.artifacts/v-csv-output/$scenario"
    mkdir -p "$v_capture_dir"
    abs_log=""
    if [[ "$logfile" = /* ]]; then
        abs_log="$logfile"
    else
        abs_log="$REPO_DIR/$logfile"
    fi
    set +e
    # shellcheck disable=SC2086  # word-splitting on $options is intentional
    (
        cd "$v_capture_dir"
        "$LTL" --disable-progress -V csv-output $options -o "$abs_log" \
            >"$v_capture_dir/ltl.stdout" 2>"$v_capture_dir/ltl.stderr"
    )
    vrc=$?
    set -e
    # Discard the timestamped CSV copies ltl emits as a side effect of
    # `-o`; the csv-cache already produced the authoritative copies for
    # validation. Keeping only ltl.stdout/ltl.stderr for the -V capture.
    find "$v_capture_dir" -maxdepth 1 -name '*-LTL-*.csv' -delete 2>/dev/null || true
    if [[ $vrc -ne 0 ]]; then
        echo "FAIL  scenario=$scenario v-csv-output-capture-failed exit=$vrc" >&2
        sed 's/^/        /' "$v_capture_dir/ltl.stderr" >&2
        total_fail=$((total_fail + 1))
        scenarios_run=$((scenarios_run + 1))
        continue
    fi

    # Extract -V csv-output / precision sub-section into a file the
    # validator reads. Anchored by the 'precision' sub-section markers
    # so the parent 'csv-output' wrapper is filtered out. (#268)
    v_precision="$v_capture_dir/csv-output-precision.txt"
    awk '/=== csv-output \/ precision ===/{flag=1; next} /=== END csv-output \/ precision ===/{flag=0} flag' \
        "$v_capture_dir/ltl.stdout" > "$v_precision"
    if [[ ! -s "$v_precision" ]]; then
        echo "FAIL  scenario=$scenario missing-v-csv-output-precision-block" >&2
        echo "        -V csv-output / precision sub-section was empty or absent in ltl stdout" >&2
        echo "        asserts: every -o run must emit -V csv-output / precision when -V csv-output is requested" >&2
        echo "        produced_by: emit_csv_output_verbose() in ltl" >&2
        echo "        contract: Issue #268 section locked observability surface" >&2
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
