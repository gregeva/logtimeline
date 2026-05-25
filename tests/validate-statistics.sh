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
SKIP_L3=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --scenario)                ONLY_SCENARIO="$2"; shift 2 ;;
        --show-all)                SHOW_ALL=1; shift ;;
        --capture-baselines)       CAPTURE_BASELINES=1; shift ;;
        --ignore-row-key-mismatch) IGNORE_ROW_KEY_MISMATCH=1; shift ;;
        --skip-l3)                 SKIP_L3=1; shift ;;
        -h|--help)
            sed -n '2,48p' "$0"
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

# Layer 3 dependency preflight. Per acceptance criterion: fail fast with
# install hint if any of python3 / numpy / scipy is missing — DO NOT
# silently skip Layer 3 (that would be a false-pass). The --skip-l3 flag
# is the explicit opt-out for debugging / capture mode.
ORACLE_SCRIPT="$HARNESS_DIR/oracle/calculate-reference.py"
L3_ENABLED=1
if [[ $SKIP_L3 -eq 1 || $CAPTURE_BASELINES -eq 1 ]]; then
    L3_ENABLED=0
fi
if [[ $L3_ENABLED -eq 1 ]]; then
    if ! command -v python3 >/dev/null 2>&1; then
        echo "ERROR: Layer 3 requires python3 (not found on PATH)." >&2
        echo "       macOS:  brew install python" >&2
        echo "       Ubuntu: sudo apt-get install python3 python3-pip" >&2
        echo "       Or pass --skip-l3 to run without external-oracle validation." >&2
        exit 1
    fi
    if ! python3 -c 'import numpy, scipy' >/dev/null 2>&1; then
        echo "ERROR: Layer 3 requires NumPy and SciPy (one or both missing)." >&2
        echo "       Install (avoiding PEP 668):" >&2
        echo "         pip3 install --user numpy scipy" >&2
        echo "       See README.md 'Test-harness dependencies' for venv alternative." >&2
        echo "       Or pass --skip-l3 to run without external-oracle validation." >&2
        exit 1
    fi
    if [[ ! -x "$ORACLE_SCRIPT" ]]; then
        echo "ERROR: oracle script missing or not executable: $ORACLE_SCRIPT" >&2
        exit 1
    fi
fi

# Per-logfile oracle JSON cache. The oracle parses the full source log
# (potentially seconds to minutes for the 277MB Tomcat file) so caching
# by logfile-shorthand avoids the cost being paid once per scenario.
# The cache key includes the percentile-algorithm name (Issue #280) so
# raw and bin scenarios on the same logfile don't collide.
ORACLE_CACHE_DIR="$SCRIPT_DIR/.artifacts/oracle"
oracle_json_for_logfile() {
    # Args: logfile_path, bucket_size_seconds, duration_unit, format, algorithm
    # Echoes the resolved oracle JSON path on stdout; produces it if not
    # cached. Returns non-zero if the oracle invocation fails.
    local logfile="$1" bs_sec="$2" du_unit="$3" fmt="$4" algorithm="$5"
    local log_shorthand
    log_shorthand="$(csv_cache_logfile_shorthand "$logfile")"
    local cache_name="${fmt}_${log_shorthand}_bs${bs_sec}_du${du_unit}_${algorithm}.json"
    local cache_path="$ORACLE_CACHE_DIR/$cache_name"
    if [[ -f "$cache_path" ]]; then
        echo "$cache_path"
        return 0
    fi
    mkdir -p "$ORACLE_CACHE_DIR"
    local abs_log
    if [[ "$logfile" = /* ]]; then
        abs_log="$logfile"
    else
        abs_log="$REPO_DIR/$logfile"
    fi
    if ! python3 "$ORACLE_SCRIPT" \
            --log "$abs_log" \
            --bucket-size-seconds "$bs_sec" \
            --duration-unit "$du_unit" \
            --format "$fmt" \
            --percentile-algorithm "$algorithm" \
            > "$cache_path" 2>"$cache_path.stderr"; then
        echo "ERROR: oracle failed for $logfile (see $cache_path.stderr)" >&2
        rm -f "$cache_path"
        return 1
    fi
    echo "$cache_path"
    return 0
}

# Per-scenario percentile-algorithm capture. Calls ltl with
# `-V percentile-algorithm` against the same logfile + options the
# scenario uses, then extracts the effective_algorithm for one surface.
# This is the contract Issue #280 establishes between ltl and the
# harness: the harness MUST NOT re-derive which algorithm ltl used —
# it MUST read it from the section ltl emits.
#
# Cached at $SCRIPT_DIR/.artifacts/oracle/pa-<scenario>.txt to avoid
# re-running ltl per file-kind.
PA_CAPTURE_DIR="$SCRIPT_DIR/.artifacts/oracle"
pa_capture_for_scenario() {
    # Args: scenario_id, logfile, options
    # Echoes the resolved capture file path on stdout. Returns non-zero
    # on ltl failure.
    local scenario="$1" logfile="$2" options="$3"
    mkdir -p "$PA_CAPTURE_DIR"
    local cache_path="$PA_CAPTURE_DIR/pa-${scenario}.txt"
    if [[ -f "$cache_path" ]]; then
        echo "$cache_path"
        return 0
    fi
    local abs_log
    if [[ "$logfile" = /* ]]; then
        abs_log="$logfile"
    else
        abs_log="$REPO_DIR/$logfile"
    fi
    local tmp
    tmp="$(mktemp)"
    # shellcheck disable=SC2086  # word-splitting on $options is intentional
    if ! "$LTL" --disable-progress -V percentile-algorithm $options "$abs_log" \
            >"$tmp" 2>"$tmp.stderr"; then
        echo "ERROR: ltl -V percentile-algorithm failed for scenario=$scenario" >&2
        sed 's/^/        /' "$tmp.stderr" >&2
        rm -f "$tmp" "$tmp.stderr"
        return 1
    fi
    mv "$tmp" "$cache_path"
    rm -f "$tmp.stderr"
    echo "$cache_path"
    return 0
}

# Read the effective_algorithm for one surface out of a captured
# -V percentile-algorithm dump. HARNESS-DESIGN.md trap 1/3/4: confirm
# the sub-section header is present, then extract the value, then fail
# loudly if nothing was found. Echoes the algorithm name on success.
pa_algorithm_for_surface() {
    local capture_file="$1" surface="$2"
    if ! grep -qE "^=== percentile-algorithm / ${surface} ===$" "$capture_file"; then
        echo "ERROR: missing '=== percentile-algorithm / ${surface} ===' anchor in $capture_file" >&2
        return 1
    fi
    local algo
    algo="$(
        sed -n "/^=== percentile-algorithm \/ ${surface} ===$/,/^=== END percentile-algorithm \/ ${surface} ===$/p" \
            "$capture_file" \
            | sed -nE 's/^effective_algorithm: (.+)$/\1/p' \
            | head -1
    )"
    if [[ -z "$algo" ]]; then
        echo "ERROR: missing 'effective_algorithm:' line under '/ ${surface}' in $capture_file" >&2
        return 1
    fi
    echo "$algo"
    return 0
}

# Extract bucket size (seconds) from an ltl options string by looking
# for "-bs N" (N is in minutes). Returns "0" if not found.
extract_bucket_size_seconds() {
    local opts="$*"
    local bs_min
    bs_min="$(echo "$opts" | sed -nE 's/.*-bs ([0-9]+).*/\1/p')"
    if [[ -z "$bs_min" ]]; then
        echo "0"
        return
    fi
    echo "$((bs_min * 60))"
}

# Extract duration unit (ms or us) from an ltl options string. Default ms.
extract_duration_unit() {
    local opts="$*"
    if echo "$opts" | grep -qE '(^|[[:space:]])-du[[:space:]]+us($|[[:space:]])'; then
        echo "us"
    else
        echo "ms"
    fi
}

# Map an ltl logfile path to an oracle format identifier. Phase F
# supports tomcat-access only; other formats return empty (skip L3).
oracle_format_for_logfile() {
    local logfile="$1"
    case "$logfile" in
        logs/AccessLogs/localhost_access_log-twx*) echo "tomcat-access" ;;
        *) echo "" ;;
    esac
}

total_pass=0
total_fail=0
scenarios_run=0

# Per-scenario state stashed during the main loop for the L4 pairing
# pass afterwards. Parallel indexed arrays keep this compatible with
# macOS system Bash 3.2 (no associative arrays).
SCENARIO_NAMES=()
SCENARIO_LOGFILES=()
SCENARIO_MSG_CSVS=()
SCENARIO_STATS_CSVS=()

# L4 pairing counters (aggregated across all scenario-pairs).
l4_total_pairs=0
l4_pairs_ok=0
l4_pairs_fail=0

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

        # Layer 3: resolve oracle JSON per-logfile (cached). The oracle
        # only supports tomcat-access in Phase F; other formats skip L3
        # (engine reports L3=N/A via absence of --oracle-json). The
        # percentile algorithm is read from ltl's
        # `-V percentile-algorithm` capture per the Issue #280 contract;
        # the surface is selected by file-kind (messages → message-stats,
        # stats → bucket-stats). When the effective algorithm has no
        # oracle reference implementation yet (i.e.
        # exponential_interpolation_within_bucket), L3 is skipped for
        # that scenario+kind with no diagnostic noise.
        if [[ $L3_ENABLED -eq 1 ]]; then
            fmt="$(oracle_format_for_logfile "$logfile")"
            if [[ -n "$fmt" ]]; then
                bs_sec="$(extract_bucket_size_seconds "$options")"
                du_unit="$(extract_duration_unit "$options")"
                if [[ "$bs_sec" != "0" ]]; then
                    if [[ "$kind" == "messages" ]]; then
                        pa_surface="message-stats"
                    else
                        pa_surface="bucket-stats"
                    fi
                    set +e
                    pa_capture="$(pa_capture_for_scenario "$scenario" "$logfile" "$options")"
                    pac=$?
                    set -e
                    if [[ $pac -eq 0 && -n "$pa_capture" ]]; then
                        set +e
                        pa_algorithm="$(pa_algorithm_for_surface "$pa_capture" "$pa_surface")"
                        pasc=$?
                        set -e
                        if [[ $pasc -eq 0 && -n "$pa_algorithm" ]]; then
                            # Algorithms with no oracle reference: skip
                            # L3 for this scenario+kind. exp-interp is
                            # reserved for a follow-up to #280.
                            if [[ "$pa_algorithm" == "exponential_interpolation_within_bucket" ]]; then
                                : # L3 skipped — engine reports L3=N/A
                            else
                                set +e
                                oracle_json="$(oracle_json_for_logfile \
                                    "$logfile" "$bs_sec" "$du_unit" "$fmt" "$pa_algorithm")"
                                orc=$?
                                set -e
                                if [[ $orc -eq 0 && -n "$oracle_json" ]]; then
                                    engine_args+=(--oracle-json "$oracle_json")
                                fi
                            fi
                        fi
                    fi
                fi
            fi
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

    # Stash scenario state for L4 pairing pass after the main loop.
    SCENARIO_NAMES+=("$scenario")
    SCENARIO_LOGFILES+=("$logfile")
    SCENARIO_MSG_CSVS+=("$msg_csv")
    SCENARIO_STATS_CSVS+=("$stats_csv")

    scenarios_run=$((scenarios_run + 1))
    if [[ $scen_fail -eq 0 ]]; then
        total_pass=$((total_pass + 1))
        echo "PASS  scenario=$scenario"
    else
        total_fail=$((total_fail + 1))
        echo "FAIL  scenario=$scenario failed_kinds=${failed_kinds[*]} (see FAIL lines emitted by engine above)"
    fi
done < <(tail -n +2 "$SCENARIOS_TSV" | grep -v '^#')

# Layer 4 cross-model pairing pass. Per Decision 9, pairs (default,
# bin-data-model) per logfile. Both members must have run during the
# main loop. Skipped entirely in --capture-baselines mode (capture
# produces both halves; nothing to compare).
if [[ $CAPTURE_BASELINES -eq 0 && ${#SCENARIO_NAMES[@]} -gt 0 ]]; then
    # Build unique logfile list by scanning the stash. The `${a[@]+...}`
    # idiom keeps `set -u` from erroring on empty arrays in Bash 3.2.
    seen_logfiles=()
    for i in "${!SCENARIO_NAMES[@]}"; do
        lf="${SCENARIO_LOGFILES[$i]}"
        found=0
        for prev in ${seen_logfiles[@]+"${seen_logfiles[@]}"}; do
            [[ "$prev" == "$lf" ]] && found=1 && break
        done
        [[ $found -eq 0 ]] && seen_logfiles+=("$lf")
    done

    for logfile in ${seen_logfiles[@]+"${seen_logfiles[@]}"}; do
        # Find the (default, bin-data-model) pair for this logfile.
        # Convention: scenario name ends with the family suffix.
        raw_scenario=""; bin_scenario=""
        raw_msg=""; raw_stats=""; bin_msg=""; bin_stats=""
        for i in "${!SCENARIO_NAMES[@]}"; do
            [[ "${SCENARIO_LOGFILES[$i]}" != "$logfile" ]] && continue
            s="${SCENARIO_NAMES[$i]}"
            if [[ "$s" == *-default ]]; then
                raw_scenario="$s"
                raw_msg="${SCENARIO_MSG_CSVS[$i]}"
                raw_stats="${SCENARIO_STATS_CSVS[$i]}"
            elif [[ "$s" == *-bin-data-model ]]; then
                bin_scenario="$s"
                bin_msg="${SCENARIO_MSG_CSVS[$i]}"
                bin_stats="${SCENARIO_STATS_CSVS[$i]}"
            fi
        done

        # Skip pairing if either side is missing (e.g. --scenario filter
        # excluded one of the pair).
        [[ -z "$raw_scenario" || -z "$bin_scenario" ]] && continue

        l4_total_pairs=$((l4_total_pairs + 1))
        pair_fail=0
        for kind in messages stats; do
            if [[ "$kind" == "messages" ]]; then
                raw_csv="$raw_msg"
                bin_csv="$bin_msg"
            else
                raw_csv="$raw_stats"
                bin_csv="$bin_stats"
            fi

            engine_args=(
                --scenario "$raw_scenario"
                --file-kind "$kind"
                --new "$raw_csv"
                --paired-with "$bin_scenario"
                --paired-new "$bin_csv"
            )
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
                pair_fail=$((pair_fail + 1))
            fi
        done

        if [[ $pair_fail -eq 0 ]]; then
            l4_pairs_ok=$((l4_pairs_ok + 1))
            echo "PASS  pair=$raw_scenario<->$bin_scenario"
        else
            l4_pairs_fail=$((l4_pairs_fail + 1))
            echo "FAIL  pair=$raw_scenario<->$bin_scenario (see FAIL lines emitted by engine above)"
        fi
    done
fi

echo ""
if [[ $CAPTURE_BASELINES -eq 1 ]]; then
    echo "=== Baseline capture: $scenarios_run scenarios captured, $total_fail failed ==="
else
    echo "=== Statistics drift: $scenarios_run scenarios, $total_pass pass, $total_fail fail | L4 pairs: $l4_total_pairs total, $l4_pairs_ok ok, $l4_pairs_fail fail ==="
fi

if [[ $scenarios_run -eq 0 ]]; then
    echo "ERROR: no scenarios were run (check --scenario filter and scenarios.tsv)" >&2
    exit 1
fi

[[ $total_fail -eq 0 && $l4_pairs_fail -eq 0 ]] || exit 1
exit 0
