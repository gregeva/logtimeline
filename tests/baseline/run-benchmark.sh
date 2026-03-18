#!/bin/bash
#
# run-benchmark.sh — Run ltl benchmark test cases and capture results as TSV
# Usage: ./run-benchmark.sh [target] [--label <name>]
#
# Targets:
#   quick — single test case for dev/testing (twx-unique-errors-standard)
#   full  — standard file selections 1-5 x all scenarios (default)
#   xl    — extra-large file selections 6-7 x all scenarios
#   all   — all file selections x all scenarios
#   <name> — run a single named test case (e.g. "twx-unique-errors-standard")
#
# Test cases are the cross-product of 7 file selections x 7 option scenarios = 49 total.
#
# Issue #56: Memory Baseline Profiling

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LTL="$SCRIPT_DIR/../../ltl"
RESULTS_DIR="$SCRIPT_DIR/results"
LOGS_DIR="$SCRIPT_DIR/../../logs"

# Default label is timestamp
LABEL="$(date +%Y%m%d-%H%M%S)"
TARGET="full"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --label)
            LABEL="$2"
            shift 2
            ;;
        *)
            TARGET="$1"
            shift
            ;;
    esac
done

OUTPUT_FILE="$RESULTS_DIR/${LABEL}.tsv"

# --- File Selections ---
# Format: short_name|tier|description|files_glob|base_options
# base_options are file-specific (e.g. -bs), applied to every scenario for this file selection
declare -a FILE_SELECTIONS=()

FILE_SELECTIONS+=("humungous-log-uniqueness|std|97 MB, 1 file, 286K unique messages|ThingworxLogs/HundredsOfThousandsOfUniqueErrors.log|")
FILE_SELECTIONS+=("single-day-application-log|std|85 MB, 1 file|ThingworxLogs/ApplicationLog.2025-05-05.0.log|")
FILE_SELECTIONS+=("multi-day-application-logs|std|315 MB, 41 files|ThingworxLogs/archives/ApplicationLog*|-bs 480")
FILE_SELECTIONS+=("multi-day-custom-logs|std|463 MB, 5 files|ThingworxLogs/CustomThingworxLogs/ScriptLog.2025-*|")
FILE_SELECTIONS+=("single-day-access-log|std|148 MB, 1 file|AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt|")
FILE_SELECTIONS+=("month-single-server-access-logs|xl|1.5 GB, 28 files|AccessLogs/really-big/*thingworx-1.2026-01-*|-bs 1440")
FILE_SELECTIONS+=("month-many-servers-access-logs|xl|7.6 GB, 140 files|AccessLogs/really-big/*.2026-01-*|-bs 1440")

# --- Scenarios ---
# Format: scenario_name|scenario_options
# These options are appended to the file selection's base_options
declare -a SCENARIOS=()

SCENARIOS+=("standard|")
SCENARIOS+=("top25|-n 25")
SCENARIOS+=("top25-consolidate|-n 25 -g")
SCENARIOS+=("heatmap|-hm")
SCENARIOS+=("histogram|-hg")
SCENARIOS+=("heatmap-histogram|-hm -hg")
SCENARIOS+=("heatmap-histogram-consolidate|-hm -hg -g")

# --- Test Execution ---

should_run_test() {
    local test_name="$1"
    local tier="$2"

    case "$TARGET" in
        quick) [[ "$test_name" == "single-day-application-log-standard" ]] ;;
        full)  [[ "$tier" == "std" ]] ;;
        xl)    [[ "$tier" == "xl" ]] ;;
        all)   return 0 ;;
        *)     [[ "$test_name" == "$TARGET" ]] ;;
    esac
}

run_test() {
    local test_name="$1"
    local files_glob="$2"
    local options="$3"

    # Expand glob relative to LOGS_DIR
    local file_args=""
    local found=0
    for f in $LOGS_DIR/$files_glob; do
        if [[ ! -f "$f" ]]; then
            echo "SKIP: $test_name — no files matched: $LOGS_DIR/$files_glob" >&2
            return 1
        fi
        file_args="$file_args $f"
        ((found++))
    done

    if [[ $found -eq 0 ]]; then
        echo "SKIP: $test_name — no files matched: $LOGS_DIR/$files_glob" >&2
        return 1
    fi

    echo "RUN:  $test_name ($found file(s))" >&2

    # Run ltl and capture output
    local output
    if ! output=$($LTL --disable-progress -V -mem $options $file_args 2>&1); then
        echo "FAIL: $test_name — ltl returned non-zero" >&2
        return 1
    fi

    # Extract benchmark data block
    local benchmark_data
    benchmark_data=$(echo "$output" | sed -n '/^=== BENCHMARK DATA ===/,/^=== END BENCHMARK DATA ===/p' | grep -v '^=== ')

    if [[ -z "$benchmark_data" ]]; then
        echo "FAIL: $test_name — no benchmark data found in output" >&2
        return 1
    fi

    # Write each benchmark row with test metadata prepended
    while IFS= read -r line; do
        printf "%s\t%s\t%s\n" "$test_name" "$options" "$line"
    done <<< "$benchmark_data"

    echo "OK:   $test_name" >&2
}

# Prepare output file — merge with existing results if file already exists
mkdir -p "$RESULTS_DIR"
MERGE_EXISTING=false
if [[ -f "$OUTPUT_FILE" ]]; then
    MERGE_EXISTING=true
    EXISTING_FILE="${OUTPUT_FILE}.existing"
    cp "$OUTPUT_FILE" "$EXISTING_FILE"
fi
echo -e "test_name\toptions\tmetric_type\tmetric_name\tvalue" > "$OUTPUT_FILE"

# Generate and run cross-product of file selections x scenarios
run_count=0
skip_count=0

for file_def in "${FILE_SELECTIONS[@]}"; do
    IFS='|' read -r file_name tier file_desc files_glob base_options <<< "$file_def"

    for scenario_def in "${SCENARIOS[@]}"; do
        IFS='|' read -r scenario_name scenario_options <<< "$scenario_def"

        test_name="${file_name}-${scenario_name}"

        if ! should_run_test "$test_name" "$tier"; then
            continue
        fi

        # Combine base options with scenario options
        local_options="$base_options"
        if [[ -n "$scenario_options" ]]; then
            local_options="$base_options $scenario_options"
        fi
        # Trim leading/trailing whitespace
        local_options="${local_options## }"
        local_options="${local_options%% }"

        if result=$(run_test "$test_name" "$files_glob" "$local_options"); then
            printf '%s\n' "$result" >> "$OUTPUT_FILE"
            ((run_count++))
        else
            ((skip_count++))
        fi
    done
done

if [[ $run_count -eq 0 ]]; then
    if [[ "$TARGET" != "quick" && "$TARGET" != "full" && "$TARGET" != "xl" && "$TARGET" != "all" ]]; then
        echo "ERROR: No test case named '$TARGET' found." >&2
        echo "" >&2
    fi
    echo "Available file selections:" >&2
    for file_def in "${FILE_SELECTIONS[@]}"; do
        IFS='|' read -r name tier desc _ _ <<< "$file_def"
        printf "  %-25s [%s] %s\n" "$name" "$tier" "$desc" >&2
    done
    echo "" >&2
    echo "Scenarios applied to each:" >&2
    for scenario_def in "${SCENARIOS[@]}"; do
        IFS='|' read -r name opts <<< "$scenario_def"
        printf "  %-35s %s\n" "$name" "${opts:-(default)}" >&2
    done
    echo "" >&2
    echo "Test names: {file-selection}-{scenario} (e.g. twx-unique-errors-standard)" >&2
    echo "Targets: quick (1 test), full (std files, default), xl (extra-large files), all (everything)" >&2
    rm -f "$OUTPUT_FILE"
    # Restore previous results if we backed them up
    if [[ "$MERGE_EXISTING" == true && -f "$EXISTING_FILE" ]]; then
        mv "$EXISTING_FILE" "$OUTPUT_FILE"
    fi
    exit 1
fi

# Merge previous results for test names not re-run in this invocation
if [[ "$MERGE_EXISTING" == true && -f "$EXISTING_FILE" ]]; then
    # Extract unique test names from this run
    ran_tests=$(tail -n +2 "$OUTPUT_FILE" | cut -f1 | sort -u)

    # Append rows from previous file whose test_name was not re-run
    merged_count=0
    while IFS= read -r line; do
        tname="${line%%	*}"
        if ! echo "$ran_tests" | grep -qxF "$tname"; then
            printf '%s\n' "$line" >> "$OUTPUT_FILE"
            ((merged_count++))
        fi
    done < <(tail -n +2 "$EXISTING_FILE")

    rm -f "$EXISTING_FILE"
    if [[ $merged_count -gt 0 ]]; then
        echo "Merged:  $merged_count rows from previous run" >&2
    fi
fi

echo "" >&2
echo "Results: $run_count passed, $skip_count skipped" >&2
echo "Output:  $OUTPUT_FILE" >&2
