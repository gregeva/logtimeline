#!/bin/bash
#
# run-profile.sh — Profile ltl with Devel::NYTProf
#
# Usage:
#   ./run-profile.sh [options] -- <ltl-args-and-files>
#
# Options:
#   --label <name>         Output directory label (default: timestamp)
#   --force                Overwrite existing output directory
#   --no-html              Skip nytprofhtml generation (faster)
#   --top N                Rows in text summary (default: 25)
#   --sort incl|excl       Sort column for summary (default: incl)
#   --samples <list>       Comma-separated sample sizes: 1k,10k,100k,full (default: 1k,10k,100k)
#   --no-samples           Skip sample truncation, single run with exact args
#   -- <ltl-args>          Full ltl command line (required)
#
# Sample sizes:
#   1k     = 1,000 lines  — immediate feedback, catches obvious regressions
#   10k    = 10,000 lines — catches O(N²) behavior early
#   100k   = 100,000 lines — production-representative
#   full   = original files unchanged — only when samples look good
#
# Cross-validation:
#   ltl is run with -V so verbose output is captured alongside NYTProf data.
#   extract-profile.pl compares NYTProf call counts against ltl's internal
#   counters (fc_calls, S1 inline count, lines_read) and flags discrepancies.
#
# Output structure:
#   tests/profile/results/<label>/
#     <sample_size>/
#       nytprof.out     — raw profile data
#       nytprof/        — HTML report (unless --no-html)
#       verbose.txt     — ltl -V output for cross-validation
#       summary.txt     — text summary from extract-profile.pl
#
# Issue #138: Standardized NYTProf profiling workflow

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LTL="$PROJECT_DIR/ltl"
RESULTS_DIR="$SCRIPT_DIR/results"
SAMPLES_DIR="$SCRIPT_DIR/samples"
EXTRACT_SCRIPT="$SCRIPT_DIR/extract-profile.pl"

# Hardcoded tool paths — no PATH dependency
PERL=/opt/homebrew/bin/perl
NYTPROFHTML=/opt/homebrew/Cellar/perl/5.42.0/bin/nytprofhtml

# Defaults
LABEL="$(date +%Y%m%d-%H%M%S)"
FORCE=0
NO_HTML=0
TOP=25
SORT_BY="incl"
SAMPLES="1k,10k,100k"
NO_SAMPLES=0
LTL_ARGS=()
PARSING_LTL=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    if [[ $PARSING_LTL -eq 1 ]]; then
        LTL_ARGS+=("$1")
        shift
        continue
    fi
    case "$1" in
        --label)   LABEL="$2";   shift 2 ;;
        --force)   FORCE=1;      shift   ;;
        --no-html) NO_HTML=1;    shift   ;;
        --top)     TOP="$2";     shift 2 ;;
        --sort)    SORT_BY="$2"; shift 2 ;;
        --samples) SAMPLES="$2"; shift 2 ;;
        --no-samples) NO_SAMPLES=1; shift ;;
        --)
            PARSING_LTL=1
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Usage: $0 [options] -- <ltl-args-and-files>" >&2
            exit 1
            ;;
    esac
done

if [[ ${#LTL_ARGS[@]} -eq 0 ]]; then
    echo "ERROR: No ltl arguments provided. Use -- to separate ltl args." >&2
    echo "Example: $0 -- --disable-progress -g 85 logs/AccessLogs/localhost_access_log.2025-03-21.txt" >&2
    exit 1
fi

OUTPUT_BASE="$RESULTS_DIR/$LABEL"

if [[ -d "$OUTPUT_BASE" && $FORCE -eq 0 ]]; then
    echo "ERROR: Output directory already exists: $OUTPUT_BASE" >&2
    echo "Use --force to overwrite, or --label to specify a different name." >&2
    exit 1
fi

# --- Sample size resolution ---
# Convert size names to line counts
size_to_lines() {
    case "$1" in
        1k)   echo 1000   ;;
        10k)  echo 10000  ;;
        100k) echo 100000 ;;
        full) echo 0      ;;  # 0 = no truncation
        [0-9]*) echo "$1" ;;  # raw number
        *)
            echo "ERROR: Unknown sample size '$1'. Use: 1k, 10k, 100k, full, or a number." >&2
            exit 1
            ;;
    esac
}

# Detect file arguments from the ltl args (last N args that look like paths or globs)
# Strategy: args starting with - are options; remaining positional args are files
detect_file_args() {
    local -a args=("$@")
    local -a file_args=()
    local i=0
    while [[ $i -lt ${#args[@]} ]]; do
        local arg="${args[$i]}"
        if [[ "$arg" == -* ]]; then
            # Option — skip it and possibly its value
            # Known options that take a value
            case "$arg" in
                -n|-b|-bs|-g|-hm|-hmw|-du|-dmin|-dmax|-st|-et|-if|-ef|-hf|-include|-exclude|-terminal-width)
                    ((i+=2)) || true
                    ;;
                *)
                    ((i+=1)) || true
                    ;;
            esac
        else
            file_args+=("$arg")
            ((i+=1)) || true
        fi
    done
    echo "${file_args[@]}"
}

# Create sample file for a given original file and line count
make_sample() {
    local orig="$1"
    local lines="$2"
    local basename
    basename="$(basename "$orig")"
    # Strip extension for naming
    local stem="${basename%.*}"
    local ext="${basename##*.}"
    [[ "$stem" == "$basename" ]] && ext="log"
    local sample_name="${stem}-${lines}.${ext}"
    local sample_path="$SAMPLES_DIR/$sample_name"

    if [[ ! -f "$sample_path" ]]; then
        echo "  Creating sample: $sample_path ($lines lines from $orig)"
        mkdir -p "$SAMPLES_DIR"
        head -n "$lines" "$orig" > "$sample_path"
        local actual
        actual=$(wc -l < "$sample_path")
        echo "  Sample created: $actual lines"
    else
        echo "  Using existing sample: $sample_path"
    fi
    echo "$sample_path"
}

# Replace file args in ltl args with sample files
replace_files_in_args() {
    local -a orig_args=("$@")
    # Passed as: replace_files_in_args <sample_size> [orig_args...]
    local sample_lines="$1"
    shift
    orig_args=("$@")

    local -a result=()
    local i=0
    while [[ $i -lt ${#orig_args[@]} ]]; do
        local arg="${orig_args[$i]}"
        if [[ "$arg" == -* ]]; then
            result+=("$arg")
            case "$arg" in
                -n|-b|-bs|-g|-hm|-hmw|-du|-dmin|-dmax|-st|-et|-if|-ef|-hf|-include|-exclude|-terminal-width)
                    ((i+=1)) || true
                    result+=("${orig_args[$i]}")
                    ;;
            esac
        else
            # It's a file path — replace with sample
            local sample
            sample=$(make_sample "$arg" "$sample_lines")
            result+=("$sample")
        fi
        ((i+=1)) || true
    done
    echo "${result[@]}"
}

# --- Run a single profiling session ---
run_one_profile() {
    local sample_label="$1"
    local output_dir="$2"
    shift 2
    local -a ltl_run_args=("$@")

    mkdir -p "$output_dir"

    echo ""
    echo "=== Sample: $sample_label ==="
    echo "    Output: $output_dir"
    echo "    ltl:    ${ltl_run_args[*]}"
    echo ""

    # Run ltl under NYTProf — cd to output dir so nytprof.out lands there
    echo "  Profiling..."
    (
        cd "$output_dir"
        "$PERL" -d:NYTProf "$LTL" -V "${ltl_run_args[@]}" > verbose.txt 2>&1
    )
    echo "  Profile data: $output_dir/nytprof.out ($(du -sh "$output_dir/nytprof.out" 2>/dev/null | cut -f1 || echo '?'))"

    # Generate HTML
    if [[ $NO_HTML -eq 0 ]]; then
        echo "  Generating HTML report..."
        "$NYTPROFHTML" --file="$output_dir/nytprof.out" \
                       --out="$output_dir/nytprof" \
                       --no-mergeforks 2>/dev/null \
            && echo "  HTML: $output_dir/nytprof/index.html" \
            || echo "  [WARN] nytprofhtml failed or not available"
    fi

    # Extract and cross-validate
    echo "  Extracting summary..."
    "$PERL" "$EXTRACT_SCRIPT" \
        --file="$output_dir/nytprof.out" \
        --verbose-file="$output_dir/verbose.txt" \
        --top="$TOP" \
        --sort="$SORT_BY" \
        | tee "$output_dir/summary.txt"
}

# --- Main execution ---
echo "NYTProf Profile Run"
echo "Label:   $LABEL"
echo "ltl args: ${LTL_ARGS[*]}"
echo ""

mkdir -p "$OUTPUT_BASE"

if [[ $NO_SAMPLES -eq 1 ]]; then
    # Single run, no sample truncation
    run_one_profile "full" "$OUTPUT_BASE/full" "${LTL_ARGS[@]}"
else
    # Run for each sample size
    IFS=',' read -ra SAMPLE_LIST <<< "$SAMPLES"

    # Detect file paths in ltl args
    FILE_ARGS=()
    while IFS= read -r -d ' ' word; do
        [[ -n "$word" ]] && FILE_ARGS+=("$word")
    done < <(detect_file_args "${LTL_ARGS[@]}" | tr ' ' '\n' | while read -r f; do printf '%s ' "$f"; done)

    if [[ ${#FILE_ARGS[@]} -eq 0 ]]; then
        echo "[WARN] No file arguments detected in ltl args. Running without sample truncation."
        run_one_profile "full" "$OUTPUT_BASE/full" "${LTL_ARGS[@]}"
    else
        for sample_size in "${SAMPLE_LIST[@]}"; do
            lines=$(size_to_lines "$sample_size")
            if [[ $lines -eq 0 ]]; then
                # full — use original args unchanged
                run_one_profile "full" "$OUTPUT_BASE/full" "${LTL_ARGS[@]}"
            else
                # Build args with sample files substituted
                run_args_str=$(replace_files_in_args "$lines" "${LTL_ARGS[@]}")
                read -ra run_args <<< "$run_args_str"
                run_one_profile "$sample_size" "$OUTPUT_BASE/$sample_size" "${run_args[@]}"
            fi
        done

        # Print scaling comparison table
        echo ""
        echo "=== Scaling Comparison ==="
        printf "%-8s  %-6s  %-10s  %-10s  %s\n" "Sample" "Lines" "Total(s)" "Peak RSS" "Top Sub (excl)"
        printf "%s\n" "$(printf '%0.s-' {1..70})"
        for sample_size in "${SAMPLE_LIST[@]}"; do
            summary_file="$OUTPUT_BASE/$sample_size/summary.txt"
            verbose_file="$OUTPUT_BASE/$sample_size/verbose.txt"
            if [[ -f "$summary_file" ]]; then
                lines_read=$(grep "^lines_read" "$verbose_file" 2>/dev/null | awk '{print $2}' || echo "?")
                total_time=$(grep "^TIMING.*total" "$verbose_file" 2>/dev/null | awk '{print $3}' || echo "?")
                rss=$(grep "^MEMORY.*rss_peak" "$verbose_file" 2>/dev/null | awk '{printf "%.0f MB", $3/1048576}' || echo "?")
                top_sub=$(grep "^1 " "$summary_file" 2>/dev/null | awk '{print $2, $6"s"}' || echo "?")
                printf "%-8s  %-6s  %-10s  %-10s  %s\n" "$sample_size" "$lines_read" "${total_time}s" "$rss" "$top_sub"
            fi
        done
    fi
fi

echo ""
echo "Results: $OUTPUT_BASE"
echo ""
echo "Next steps:"
echo "  1. Extract profile:  /opt/homebrew/bin/perl tests/profile/extract-profile.pl \\"
echo "       --file $OUTPUT_BASE/<sample>/nytprof.out \\"
echo "       --verbose-file $OUTPUT_BASE/<sample>/verbose.txt \\"
echo "       --checks-file tests/profile/checks/<feature>.tsv --sort excl"
echo "  2. Write analysis:   $OUTPUT_BASE/analysis.md"
echo "     (hypothesis, surprises, diagnosis, learnings — see nytprof-profiling-workflow.md)"
