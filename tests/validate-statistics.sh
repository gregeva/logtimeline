#!/usr/bin/env bash
# validate-statistics.sh — Calculated-statistics test harness (Issue #224).
#
# Validates every numeric calculated statistic ltl emits to its -o CSV
# outputs through three independent layers:
#   L1  drift against committed baseline
#   L2  intra-row arithmetic consistency
#   L3  algorithm-aware external-oracle (NumPy/SciPy) validation,
#       dispatching its reference computation by the algorithm declared
#       in ltl's -V percentile-algorithm section (Issue #280)
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
# Usage:
#   ./tests/validate-statistics.sh                       # all scenarios
#   ./tests/validate-statistics.sh --scenario <name>     # single scenario
#   ./tests/validate-statistics.sh --show-all            # include T1/T2 advisories
#   ./tests/validate-statistics.sh --capture-baselines   # rebaseline (with prompt)
#   ./tests/validate-statistics.sh --capture-baselines --scenario <name>
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
ENGINE="$HARNESS_DIR/compare-statistics-drift.pl"
BASELINES_DIR="$HARNESS_DIR/baselines"

# shellcheck source=lib/csv-cache.sh
source "$SCRIPT_DIR/lib/csv-cache.sh"

# End-of-run cleanup runs only when standalone (CI unset).
trap csv_cache_maybe_cleanup EXIT

ONLY_SCENARIO=""
SHOW_ALL=0
CAPTURE_BASELINES=0
SKIP_L3=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --scenario)                ONLY_SCENARIO="$2"; shift 2 ;;
        --show-all)                SHOW_ALL=1; shift ;;
        --capture-baselines)       CAPTURE_BASELINES=1; shift ;;
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

for f in "$LTL" "$SCENARIOS_TSV" "$ENGINE"; do
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
        PY=$(command -v python3)
        echo "ERROR: Layer 3 requires NumPy and SciPy (one or both missing under $PY)." >&2
        echo "       Install command depends on which Python this is:" >&2
        case "$PY" in
            /opt/homebrew/*|/usr/local/Cellar/*|/usr/local/opt/*)
                echo "         $PY is Homebrew Python - PEP 668 blocks 'pip install --user'." >&2
                echo "         Install via brew (numpy and scipy ship as brew formulas):" >&2
                echo "           brew install numpy scipy" >&2
                ;;
            /Library/Developer/CommandLineTools/*|/usr/bin/*)
                echo "         $PY is Apple Command-Line-Tools Python - pip --user works:" >&2
                echo "           $PY -m pip install --user numpy scipy" >&2
                ;;
            *)
                # Linux PEP-668 distros (Ubuntu 24.04+, Debian 12+, Fedora 38+) also block
                # pip --user; older ones do not. Venv works everywhere.
                echo "         Try pip --user (works on pre-PEP-668 distros):" >&2
                echo "           $PY -m pip install --user numpy scipy" >&2
                echo "         If PEP 668 blocks, use a venv (works everywhere):" >&2
                echo "           $PY -m venv .venv && .venv/bin/python -m pip install numpy scipy" >&2
                echo "           Then re-run the harness with: PATH=\$(pwd)/.venv/bin:\$PATH ./tests/validate-statistics.sh" >&2
                ;;
        esac
        echo "       Verify: $PY -c 'import numpy, scipy'" >&2
        echo "       See README.md 'Test-harness dependencies' for the venv alternative." >&2
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
    # Args: logfile_path, bucket_size_seconds, duration_unit, format, algorithm, bpd
    # Echoes the resolved oracle JSON path on stdout; produces it if not
    # cached. Returns non-zero if the oracle invocation fails.
    #
    # Issue #289: the bpd is part of the cache key AND passed to the oracle.
    # Surfaces run at different bin resolutions (bucket-stats finer than
    # message-stats), so two oracle runs on the same logfile+algorithm but
    # different bpd must not collide, and the oracle must build its reference
    # partition at the resolution ltl actually used (read from -V effective_bpd).
    local logfile="$1" bs_sec="$2" du_unit="$3" fmt="$4" algorithm="$5" bpd="$6"
    local log_shorthand
    log_shorthand="$(csv_cache_logfile_shorthand "$logfile")"
    local cache_name="${fmt}_${log_shorthand}_bs${bs_sec}_du${du_unit}_${algorithm}_bpd${bpd}.json"
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
            --percentile-bpd "$bpd" \
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

# Read the effective_bpd for one surface out of a captured -V
# percentile-algorithm dump (Issue #289). effective_bpd is emitted only when
# the surface runs the exponential-interpolation algorithm (the raw nearest-
# rank path has no bin resolution), so absence is not an error: echo the
# global default (53) so the caller has a value to pass for the
# nearest-rank case where the oracle ignores it. Echoes the bpd on success.
pa_bpd_for_surface() {
    local capture_file="$1" surface="$2"
    if ! grep -qE "^=== percentile-algorithm / ${surface} ===$" "$capture_file"; then
        echo "ERROR: missing '=== percentile-algorithm / ${surface} ===' anchor in $capture_file" >&2
        return 1
    fi
    local bpd
    bpd="$(
        sed -n "/^=== percentile-algorithm \/ ${surface} ===$/,/^=== END percentile-algorithm \/ ${surface} ===$/p" \
            "$capture_file" \
            | sed -nE 's/^effective_bpd: ([0-9]+)$/\1/p' \
            | head -1
    )"
    # effective_bpd absent → surface is on nearest_rank; the oracle ignores
    # bpd in that case, so default to 53 (the global floor).
    [[ -z "$bpd" ]] && bpd=53
    echo "$bpd"
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

# Map an ltl logfile path to an oracle format identifier. Each pattern
# must correspond to a parser registered in PARSERS in
# oracle/calculate-reference.py. Unmatched paths return empty (skip L3).
oracle_format_for_logfile() {
    local logfile="$1"
    case "$logfile" in
        logs/AccessLogs/localhost_access_log-twx*)        echo "tomcat-access" ;;
        logs/AccessLogs/ApacheHTTP2Server-*)              echo "apache-http2" ;;
        logs/Codebeamber/codebeamer_access_log*)          echo "codebeamer-access" ;;
        logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-*) echo "thingworx-scriptlog" ;;
        *) echo "" ;;
    esac
}

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

        # Layer 3: resolve oracle JSON per-logfile (cached). The oracle
        # supports every format in oracle_format_for_logfile (tomcat-access,
        # apache-http2, codebeamer-access, thingworx-scriptlog); a format with
        # no parser skips L3 (engine reports L3=N/A via absence of
        # --oracle-json). The oracle implements BOTH percentile algorithms —
        # nearest_rank and exponential_interpolation_within_bucket — so bin
        # scenarios are validated, not skipped. The algorithm AND the bin
        # resolution are read from ltl's `-V percentile-algorithm` capture per
        # the Issue #280/#289 contract (effective_algorithm + effective_bpd);
        # the surface is selected by file-kind (messages → message-stats,
        # stats → bucket-stats), and the oracle builds its reference partition
        # at the same per-surface bpd ltl used.
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
                            # The oracle implements both nearest_rank and
                            # exponential_interpolation_within_bucket; dispatch
                            # to whichever the surface resolves to per #280.
                            # Issue #289: also read the surface's effective_bpd
                            # so the oracle builds its reference partition at the
                            # SAME resolution ltl used (surfaces tune bpd per
                            # cardinality; bucket-stats runs finer than the 53
                            # default). Without this the oracle false-fails the
                            # finer surface against a coarse reference.
                            set +e
                            pa_bpd="$(pa_bpd_for_surface "$pa_capture" "$pa_surface")"
                            pabc=$?
                            set -e
                            if [[ $pabc -eq 0 && -n "$pa_bpd" ]]; then
                                set +e
                                oracle_json="$(oracle_json_for_logfile \
                                    "$logfile" "$bs_sec" "$du_unit" "$fmt" "$pa_algorithm" "$pa_bpd")"
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
