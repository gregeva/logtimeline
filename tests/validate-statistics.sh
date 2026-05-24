#!/usr/bin/env bash
# validate-statistics.sh — Calculated-statistics test harness (Issue #224).
#
# Validates every numeric calculated statistic ltl emits to its -o CSV
# outputs through four independent layers:
#   L1  drift against committed baseline
#   L2  intra-row arithmetic consistency
#   L3  external-oracle (NumPy/SciPy) algorithmic correctness
#   L4  cross-model agreement between raw-array and bin-counter data models
#
# Sibling to validate-csv-output.sh (#223), which handles structural CSV
# correctness. Run validate-csv-output.sh BEFORE this harness — structural
# correctness is a precondition for meaningful drift comparison. The two
# harnesses share a CSV cache so the second one reuses produced CSVs from
# the first.
#
# Orchestration: set CI=1 (industry-standard env var, also set by all
# major CI runners) when chaining this harness with others, so the cache
# is preserved for downstream harnesses. The orchestrator is responsible
# for calling cleanup-test-artifacts.sh at the end. When CI is unset, this
# harness cleans up its own artifacts at end of run.
#
# Phase B status: scaffolding stub. The engine compare-statistics-drift.pl
# is currently a stub that exits 0 without doing real comparison work.
# Layer-by-layer implementation lands in Phase C (L1+L2), Phase E (L4),
# Phase F (L3).
#
# Usage:
#   ./tests/validate-statistics.sh                       # all scenarios
#   ./tests/validate-statistics.sh --scenario <name>     # single scenario
#   ./tests/validate-statistics.sh --show-all            # include T1/T2 advisories
#   ./tests/validate-statistics.sh --capture-baselines   # rebaseline (with prompt)
#   ./tests/validate-statistics.sh --capture-baselines --scenario <name>
#   ./tests/validate-statistics.sh --ignore-row-key-mismatch  # workaround for Issue #269
#
# Exit codes:
#   0  no T3/T4 failures across any layer
#   1  at least one T3/T4 failure (or driver-level error)
#
# Baselines are DELIVERABLES, not disposable artifacts. The
# --capture-baselines flag prompts for confirmation before overwriting
# anything and never runs without explicit operator approval. Use it
# only when the new values are known-correct (e.g., after a reviewed
# change to a statistic algorithm).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"
HARNESS_DIR="$SCRIPT_DIR/statistics-drift"
SCENARIOS_TSV="$HARNESS_DIR/scenarios.tsv"
TOLERANCES_TSV="$HARNESS_DIR/cross-model-tolerances.tsv"
ENGINE="$HARNESS_DIR/compare-statistics-drift.pl"
BASELINES_DIR="$HARNESS_DIR/baselines"

# shellcheck source=lib/csv-cache.sh
source "$SCRIPT_DIR/lib/csv-cache.sh"

# End-of-run cleanup runs only when standalone (CI unset).
trap csv_cache_maybe_cleanup EXIT

ONLY_SCENARIO=""
SHOW_ALL=0
CAPTURE_BASELINES=0
IGNORE_ROW_KEY_MISMATCH=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --scenario)                ONLY_SCENARIO="$2"; shift 2 ;;
        --show-all)                SHOW_ALL=1; shift ;;
        --capture-baselines)       CAPTURE_BASELINES=1; shift ;;
        --ignore-row-key-mismatch) IGNORE_ROW_KEY_MISMATCH=1; shift ;;
        -h|--help)
            sed -n '2,46p' "$0"
            exit 0
            ;;
        *) echo "unknown arg: $1" >&2; exit 2 ;;
    esac
done

# Baseline-capture confirmation prompt. Refuses without explicit yes.
if [[ $CAPTURE_BASELINES -eq 1 ]]; then
    if [[ -n "$ONLY_SCENARIO" ]]; then
        scope="scenario '$ONLY_SCENARIO' only"
    else
        scope="ALL scenarios in scenarios.tsv"
    fi
    echo "About to (re)capture baselines: $scope"
    echo "  Target directory: $BASELINES_DIR/<scenario>/{messages,stats}.csv"
    echo "  This OVERWRITES any existing baseline files for the scope above."
    echo ""
    printf "Proceed? Type 'yes' to confirm: "
    read -r confirm
    if [[ "$confirm" != "yes" ]]; then
        echo "Aborted. No baselines were modified."
        exit 1
    fi
    mkdir -p "$BASELINES_DIR"
fi

for f in "$LTL" "$SCENARIOS_TSV" "$TOLERANCES_TSV" "$ENGINE"; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: required file missing: $f" >&2
        exit 1
    fi
done

total_pass=0
total_fail=0
scenarios_run=0

while IFS=$'\t' read -r scenario logfile options; do
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
    baseline_dir="$BASELINES_DIR/$scenario"

    # Capture mode: copy cached CSVs to the baseline directory and skip
    # comparison (defining the new baseline; nothing to compare against).
    if [[ $CAPTURE_BASELINES -eq 1 ]]; then
        mkdir -p "$baseline_dir"
        cp "$msg_csv"   "$baseline_dir/messages.csv"
        cp "$stats_csv" "$baseline_dir/stats.csv"
        msg_bytes=$(wc -c < "$baseline_dir/messages.csv")
        stats_bytes=$(wc -c < "$baseline_dir/stats.csv")
        echo "CAPTURED  scenario=$scenario  messages=${msg_bytes}B  stats=${stats_bytes}B"
        scenarios_run=$((scenarios_run + 1))
        total_pass=$((total_pass + 1))
        continue
    fi

    scen_fail=0
    failed_kinds=()

    for kind in messages stats; do
        if [[ "$kind" == "messages" ]]; then
            csv="$msg_csv"
            baseline="$baseline_dir/messages.csv"
        else
            csv="$stats_csv"
            baseline="$baseline_dir/stats.csv"
        fi

        engine_args=(
            --scenario "$scenario"
            --file-kind "$kind"
            --new "$csv"
        )
        if [[ -f "$baseline" ]]; then
            engine_args+=(--baseline "$baseline")
        fi
        if [[ $SHOW_ALL -eq 1 ]]; then
            engine_args+=(--show-all)
        fi
        if [[ $IGNORE_ROW_KEY_MISMATCH -eq 1 ]]; then
            engine_args+=(--ignore-row-key-mismatch)
        fi

        set +e
        perl "$ENGINE" "${engine_args[@]}"
        erc=$?
        set -e

        if [[ $erc -ne 0 ]]; then
            scen_fail=$((scen_fail + 1))
            failed_kinds+=("$kind")
        fi
    done

    scenarios_run=$((scenarios_run + 1))
    if [[ $scen_fail -eq 0 ]]; then
        total_pass=$((total_pass + 1))
        echo "PASS  scenario=$scenario"
    else
        total_fail=$((total_fail + 1))
        echo "FAIL  scenario=$scenario failed_kinds=${failed_kinds[*]} (see FAIL lines emitted by engine above)"
    fi
done < <(tail -n +2 "$SCENARIOS_TSV" | grep -v '^#')

echo ""
if [[ $CAPTURE_BASELINES -eq 1 ]]; then
    echo "=== Baseline capture: $scenarios_run scenarios captured, $total_fail failed ==="
else
    echo "=== Statistics drift: $scenarios_run scenarios, $total_pass pass, $total_fail fail ==="
fi

if [[ $scenarios_run -eq 0 ]]; then
    echo "ERROR: no scenarios were run (check --scenario filter and scenarios.tsv)" >&2
    exit 1
fi

[[ $total_fail -eq 0 ]] || exit 1
exit 0
