#!/bin/bash
#
# compare-results.sh — Compare two benchmark TSV result files
# Usage: ./compare-results.sh [summary|detailed|table|all] [--markdown] [--save] <baseline.tsv> <current.tsv>
#
# Modes:
#   summary  — timing total and RSS peak per test case (default)
#   detailed — all timing stages and per-structure memory
#   table    — matrix view: file selections x scenarios, time and memory deltas
#   all      — summary + detailed + table
#
# Options:
#   --markdown — output tables in markdown format for release notes
#   --save     — write full markdown report to tests/baseline/results/comparison-{baseline}-vs-{current}.md
#
# MAINTENANCE — renaming a TIMING row is a breaking change to this script.
# Committed baselines are kept for years and carry whatever labels their
# release emitted. When a TIMING label in ltl is renamed, add an
# old -> new entry to the tmap block below IN THE SAME COMMIT; otherwise
# every comparison spanning the rename silently stops pairing that row and
# reports it as two half-empty N/A rows instead of a delta. The script
# reports unpaired TIMING labels on stderr after each run as a backstop,
# but the note cannot distinguish a missed rename from a genuinely new row
# — that judgement is the author's.
#
# Issue #56: Memory Baseline Profiling. Rename maintenance: Issue #422.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/results"

MODE="summary"
MARKDOWN=0
SAVE=0
BASELINE=""
CURRENT=""

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        summary|detailed|table|all)
            MODE="$arg"
            ;;
        --markdown)
            MARKDOWN=1
            ;;
        --save)
            SAVE=1
            ;;
        *)
            if [[ -z "$BASELINE" ]]; then
                BASELINE="$arg"
            elif [[ -z "$CURRENT" ]]; then
                CURRENT="$arg"
            else
                echo "Usage: $0 [summary|detailed|table|all] [--markdown] [--save] <baseline.tsv> <current.tsv>" >&2
                exit 1
            fi
            ;;
    esac
done

if [[ -z "$BASELINE" || -z "$CURRENT" ]]; then
    echo "Usage: $0 [summary|detailed|table|all] [--markdown] [--save] <baseline.tsv> <current.tsv>" >&2
    exit 1
fi

# --save implies --markdown and all mode
if [[ $SAVE -eq 1 ]]; then
    MARKDOWN=1
    MODE="all"
    SAVE_FILE="$RESULTS_DIR/comparison-$(basename "$BASELINE" .tsv)-vs-$(basename "$CURRENT" .tsv).md"
fi

if [[ ! -f "$BASELINE" ]]; then
    echo "ERROR: Baseline file not found: $BASELINE" >&2
    exit 1
fi

if [[ ! -f "$CURRENT" ]]; then
    echo "ERROR: Current file not found: $CURRENT" >&2
    exit 1
fi

# --- Header: extract run metadata ---
# Per tests/HARNESS-DESIGN.md, awk extractions against required anchors must
# not silently succeed with empty/zero values. A benchmark TSV with no
# `version` row or no `TIMING\ttotal\t...` rows is malformed; comparing it
# would silently produce a meaningless report.
print_header() {
    local file="$1"
    local label="$2"

    local version
    version=$(awk -F'\t' '$3 == "version" { v=$4 } END { print v }' "$file")
    if [[ -z "$version" ]]; then
        echo "ERROR: $file has no 'version' row; cannot compare benchmark TSVs without it" >&2
        echo "       Expected anchor: column 3 == \"version\"" >&2
        exit 1
    fi

    local test_count
    test_count=$(awk -F'\t' 'NR > 1 && $3 == "TIMING" && $4 == "total" { n++ } END { print n+0 }' "$file")
    if [[ "$test_count" -eq 0 ]]; then
        echo "ERROR: $file has no 'TIMING/total' rows; benchmark TSV contains no test data" >&2
        echo "       Expected anchor: column 3 == \"TIMING\" AND column 4 == \"total\"" >&2
        exit 1
    fi

    local filename
    filename=$(basename "$file" .tsv)

    printf "  %-12s %s (v%s, %d test cases)\n" "$label:" "$filename" "$version" "$test_count"
}

run_report() {

if [[ $MARKDOWN -eq 1 ]]; then
    echo ""
    echo "## Benchmark Comparison"
    echo ""
    print_header "$BASELINE" "Baseline"
    print_header "$CURRENT"  "Current"
    echo ""
else
    echo ""
    echo "=== Benchmark Comparison ==="
    echo ""
    print_header "$BASELINE" "Baseline"
    print_header "$CURRENT"  "Current"
    echo ""
fi

# --- Format TSV as plain text or markdown table ---
format_table() {
    if [[ $MARKDOWN -eq 1 ]]; then
        awk -F'\t' '
        NR == 1 {
            # Header row
            printf "| "
            for (i = 1; i <= NF; i++) {
                if (i > 1) printf " | "
                printf "%s", $i
            }
            printf " |\n"
            # Separator row
            printf "|"
            for (i = 1; i <= NF; i++) {
                printf " --- |"
            }
            printf "\n"
            next
        }
        {
            printf "| "
            for (i = 1; i <= NF; i++) {
                if (i > 1) printf " | "
                printf "%s", $i
            }
            printf " |\n"
        }'
    else
        column -t -s$'\t'
    fi
}

# --- Comparison output ---
run_comparison() {
    local filter_mode="$1"

    awk -F'\t' -v filter="$filter_mode" '
    # TIMING label compat map: old label -> the label in use today. Baselines
    # are kept for years and carry whatever labels their release emitted, so
    # every rename of a TIMING row must add an entry here IN THE SAME CHANGE
    # or cross-version rows stop pairing — the old and new names each become
    # a half-empty N/A row and the metric silently drops out of every
    # comparison spanning the rename.
    #
    # Chains are resolved (a -> b -> c collapses to c), so a second rename of
    # an already-renamed row only needs its own new entry.
    #
    # #180 moved the flat stage labels to stage/step form:
    BEGIN {
        tmap["read_files"] = "parse/read_files"
        tmap["initialize_buckets"] = "accumulate/initialize_buckets"
        tmap["group_similar"] = "finalize/group_similar"
        tmap["calculate_statistics"] = "finalize/calculate_statistics"
        tmap["heatmap_statistics"] = "finalize/heatmap_statistics"
        tmap["histogram_statistics"] = "finalize/histogram_statistics"
        tmap["normalize_data"] = "render/normalize_data"
    }
    {
        if ($3 == "TIMING") {
            # Follow the chain so a label renamed more than once still lands
            # on the current name; the guard stops a mistaken cycle looping.
            hops = 0
            while ($4 in tmap && hops++ < 10) $4 = tmap[$4]
            if (NR == FNR) timing_base[$4] = 1; else timing_cur[$4] = 1
        }
    }
    # Skip headers
    NR == FNR && FNR == 1 { next }
    NR != FNR && FNR == 1 { next }

    # First file (baseline) — only numeric values
    # Rows from ltl have either 2 or 3 fields (after test_name + options prepended = 4 or 5 cols)
    NR == FNR {
        val = ""
        if ($5 + 0 == $5 && $5 != "" && $3 != "FILES") {
            key = $1 FS $2 FS $3 FS $4; val = $5
        } else if ($4 + 0 == $4 && $4 != "" && $3 != "TIMING" && $3 != "MEMORY" && $3 != "FILES" && $3 != "version") {
            key = $1 FS $2 FS $3 FS $3; val = $4
        }
        if (val != "") {
            baseline[key] = val
            keys_order[++n] = key
            seen[key] = 1
        }
        next
    }

    # Second file (current)
    {
        val = ""
        if ($5 + 0 == $5 && $5 != "" && $3 != "FILES") {
            key = $1 FS $2 FS $3 FS $4; val = $5
        } else if ($4 + 0 == $4 && $4 != "" && $3 != "TIMING" && $3 != "MEMORY" && $3 != "FILES" && $3 != "version") {
            key = $1 FS $2 FS $3 FS $3; val = $4
        }
        if (val != "") {
            current[key] = val
            current_test[$1] = 1
            if (!(key in seen)) {
                keys_order[++n] = key
                seen[key] = 1
            }
        }
    }

    END {
        OFS = "\t"
        print "test_name", "metric", "baseline", "current", "delta", "change%", "result"

        for (i = 1; i <= n; i++) {
            key = keys_order[i]
            split(key, parts, FS)
            test = parts[1]
            opts = parts[2]
            mtype = parts[3]
            mname = parts[4]
            metric = mtype "/" mname

            # Filter based on mode
            if (filter == "summary") {
                if (!(mtype == "TIMING" && mname == "total") && \
                    !(mtype == "MEMORY" && mname == "rss_peak") && \
                    !(mtype == "lines_read" || mtype == "lines_included")) continue
            }

            # A test case the current run did not execute has nothing to
            # report: with a single-case gate run against the full baseline,
            # those produced 248 N/A rows around 4 useful ones. Skip the
            # whole case.
            #
            # A METRIC missing on one side is kept and shown as N/A: it means
            # the metric was added, removed or renamed between the two
            # versions, which is exactly what a comparison should surface
            # (the #180 timing rename appears here as the old names leaving
            # and the stage/step names arriving).
            if (!(test in current_test)) continue

            b = (key in baseline) ? baseline[key] : "N/A"
            c = (key in current) ? current[key] : "N/A"

            if (b == "N/A" || c == "N/A") {
                delta = "N/A"
                pct = "N/A"
                ind = "?"
                if (mtype == mname) metric = mtype
                if (mtype == "MEMORY") {
                    if (b != "N/A") b = format_bytes(b)
                    if (c != "N/A") c = format_bytes(c)
                } else if (mtype == "TIMING") {
                    if (b != "N/A") b = format_time(b)
                    if (c != "N/A") c = format_time(c)
                } else if (mtype == "lines_read" || mtype == "lines_included") {
                    if (b != "N/A") b = format_number(b)
                    if (c != "N/A") c = format_number(c)
                }
                printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", test, metric, b, c, delta, pct, ind
                continue
            }

            delta = c - b
            if (b != 0) {
                pct = sprintf("%.1f%%", (delta / b) * 100)
            } else if (c == 0) {
                pct = "0.0%"
            } else {
                pct = "NEW"
            }

            if (delta > 0) {
                ind = "REGRESS"
            } else if (delta < 0) {
                ind = "IMPROVE"
            } else {
                ind = ""
            }

            # Skip rows where both values are 0
            if (b == 0 && c == 0) continue

            # Display metric name without redundant type/name for simple rows
            if (mtype == mname) metric = mtype

            # Format values for display
            if (mtype == "MEMORY") {
                b = format_bytes(b)
                c = format_bytes(c)
                delta = format_bytes_signed(delta)
            } else if (mtype == "TIMING") {
                b = format_time(b)
                c = format_time(c)
                delta = format_time_signed(delta)
            } else if (mtype == "lines_read" || mtype == "lines_included") {
                b = format_number(b)
                c = format_number(c)
                delta = format_number(delta)
            }

            printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", test, metric, b, c, delta, pct, ind
        }

        # Rename self-check. A TIMING label on one side only is either a row
        # genuinely added/removed this cycle, or a rename whose tmap entry was
        # forgotten. The script cannot tell those apart, so it reports rather
        # than guesses — but an unpaired PAIR (one label gone, one arrived) is
        # the shape of a missed rename and is worth a look before the numbers
        # are trusted.
        nb = 0; nc = 0
        for (t in timing_base) if (!(t in timing_cur)) unpaired_base[nb++] = t
        for (t in timing_cur)  if (!(t in timing_base)) unpaired_cur[nc++] = t
        if (nb > 0 || nc > 0) {
            printf "\n" > "/dev/stderr"
            printf "NOTE: TIMING labels present on only one side of this comparison.\n" > "/dev/stderr"
            printf "      If a row was RENAMED, add old -> new to tmap in compare-results.sh\n" > "/dev/stderr"
            printf "      so baselines spanning the rename keep pairing.\n" > "/dev/stderr"
            for (i = 0; i < nb; i++)
                printf "      baseline only: %s\n", unpaired_base[i] > "/dev/stderr"
            for (i = 0; i < nc; i++)
                printf "      current  only: %s\n", unpaired_cur[i] > "/dev/stderr"
        }
    }

    function format_bytes(n,    abs_n, val, unit) {
        abs_n = (n < 0) ? -n : n
        if (abs_n >= 1073741824) { val = n / 1073741824; unit = "GB" }
        else if (abs_n >= 1048576) { val = n / 1048576; unit = "MB" }
        else if (abs_n >= 1024) { val = n / 1024; unit = "KB" }
        else return sprintf("%d B", n)
        # Drop decimal if .0
        if (sprintf("%.1f", val) == sprintf("%d.0", int(val)))
            return sprintf("%d %s", val, unit)
        return sprintf("%.1f %s", val, unit)
    }

    function format_bytes_signed(n) {
        if (n == 0) return "0 B"
        if (n > 0) return "+" format_bytes(n)
        return format_bytes(n)
    }

    function format_time(n,    abs_n, val) {
        abs_n = (n < 0) ? -n : n
        if (abs_n >= 60) {
            val = n / 60
            if (sprintf("%.1f", val) == sprintf("%d.0", int(val)))
                return sprintf("%d min", val)
            return sprintf("%.1f min", val)
        }
        if (abs_n >= 1) {
            if (sprintf("%.1f", n) == sprintf("%d.0", int(n)))
                return sprintf("%d s", n)
            return sprintf("%.1f s", n)
        }
        if (abs_n >= 0.001) return sprintf("%.0f ms", n * 1000)
        return sprintf("%.0f us", n * 1000000)
    }

    function format_time_signed(n) {
        if (n == 0) return "0 ms"
        if (n > 0) return "+" format_time(n)
        return format_time(n)
    }

    function format_number(n,    neg, s, len, result, i) {
        neg = ""
        if (n + 0 < 0) { neg = "-"; n = -n }
        s = sprintf("%d", n)
        len = length(s)
        result = ""
        for (i = 1; i <= len; i++) {
            if (i > 1 && (len - i) % 3 == 2) result = result ","
            result = result substr(s, i, 1)
        }
        return neg result
    }
    ' "$BASELINE" "$CURRENT" | format_table
}

# --- Table view: matrix of file selections x scenarios ---
# Shared awk block for table definitions and formatting functions
TABLE_AWK_COMMON='
    BEGIN {
        nf = 0
        files[++nf] = "humungous-log-uniqueness"
        files[++nf] = "single-day-application-log"
        files[++nf] = "multi-day-application-logs"
        files[++nf] = "multi-day-custom-logs"
        files[++nf] = "single-day-access-log"
        files[++nf] = "month-single-server-access-logs"
        files[++nf] = "month-many-servers-access-logs"

        ns = 0
        scenarios[++ns] = "standard"
        scenarios[++ns] = "top25"
        scenarios[++ns] = "top25-consolidate"
        scenarios[++ns] = "heatmap"
        scenarios[++ns] = "histogram"
        scenarios[++ns] = "heatmap-histogram"
        scenarios[++ns] = "heatmap-histogram-consolidate"
        scenarios[++ns] = "sort-p99"
        scenarios[++ns] = "sort-skewness"

        slabel[1] = "standard"
        slabel[2] = "top25"
        slabel[3] = "top25-cons"
        slabel[4] = "heatmap"
        slabel[5] = "histogram"
        slabel[6] = "hm+hg"
        slabel[7] = "hm+hg+cons"
        slabel[8] = "sort-p99"
        slabel[9] = "sort-skew"
    }

    NR == FNR && FNR == 1 { next }
    NR != FNR && FNR == 1 { next }

    function format_bytes(n,    abs_n, val, unit) {
        abs_n = (n < 0) ? -n : n
        if (abs_n >= 1073741824) { val = n / 1073741824; unit = "GB" }
        else if (abs_n >= 1048576) { val = n / 1048576; unit = "MB" }
        else if (abs_n >= 1024) { val = n / 1024; unit = "KB" }
        else return sprintf("%d B", n)
        if (sprintf("%.1f", val) == sprintf("%d.0", int(val)))
            return sprintf("%d %s", val, unit)
        return sprintf("%.1f %s", val, unit)
    }

    function format_bytes_signed(n) {
        if (n == 0) return "="
        if (n > 0) return "+" format_bytes(n)
        return format_bytes(n)
    }

    function format_time(n,    abs_n, val) {
        abs_n = (n < 0) ? -n : n
        if (abs_n >= 60) {
            val = n / 60
            if (sprintf("%.1f", val) == sprintf("%d.0", int(val)))
                return sprintf("%d min", val)
            return sprintf("%.1f min", val)
        }
        if (abs_n >= 1) {
            if (sprintf("%.1f", n) == sprintf("%d.0", int(n)))
                return sprintf("%d s", n)
            return sprintf("%.1f s", n)
        }
        if (abs_n >= 0.001) return sprintf("%.0f ms", n * 1000)
        return sprintf("%.0f us", n * 1000000)
    }

    function format_time_signed(n) {
        if (n == 0) return "="
        if (n > 0) return "+" format_time(n)
        return format_time(n)
    }
'

run_table_timing() {
    awk -F'\t' "$TABLE_AWK_COMMON"'
    NR == FNR { if ($3 == "TIMING" && $4 == "total") base[$1] = $5; next }
    { if ($3 == "TIMING" && $4 == "total") cur[$1] = $5 }
    END {
        OFS = "\t"
        printf "#\tfile selection"
        for (s = 1; s <= ns; s++) printf "\t%s", slabel[s]
        printf "\n"
        for (f = 1; f <= nf; f++) {
            printf "%d.\t%s", f, files[f]
            for (s = 1; s <= ns; s++) {
                test = files[f] "-" scenarios[s]
                if (test in base && test in cur) {
                    printf "\t%s", format_pct(cur[test], base[test])
                } else {
                    printf "\t-"
                }
            }
            printf "\n"
        }
    }

    function format_pct(current, baseline,    delta, pct) {
        delta = current - baseline
        if (delta == 0) return "="
        if (baseline == 0) return "NEW"
        pct = (delta / baseline) * 100
        if (pct > 0) return sprintf("+%.1f%%", pct)
        return sprintf("%.1f%%", pct)
    }
    ' "$BASELINE" "$CURRENT" | format_table
}

run_table_memory() {
    awk -F'\t' "$TABLE_AWK_COMMON"'
    NR == FNR { if ($3 == "MEMORY" && $4 == "rss_peak") base[$1] = $5; next }
    { if ($3 == "MEMORY" && $4 == "rss_peak") cur[$1] = $5 }
    END {
        OFS = "\t"
        printf "#\tfile selection"
        for (s = 1; s <= ns; s++) printf "\t%s", slabel[s]
        printf "\n"
        for (f = 1; f <= nf; f++) {
            printf "%d.\t%s", f, files[f]
            for (s = 1; s <= ns; s++) {
                test = files[f] "-" scenarios[s]
                if (test in base && test in cur) {
                    printf "\t%s", format_pct(cur[test], base[test])
                } else {
                    printf "\t-"
                }
            }
            printf "\n"
        }
    }

    function format_pct(current, baseline,    delta, pct) {
        delta = current - baseline
        if (delta == 0) return "="
        if (baseline == 0) return "NEW"
        pct = (delta / baseline) * 100
        if (pct > 0) return sprintf("+%.1f%%", pct)
        return sprintf("%.1f%%", pct)
    }
    ' "$BASELINE" "$CURRENT" | format_table
}

if [[ "$MODE" == "table" || "$MODE" == "all" ]]; then
    if [[ $MARKDOWN -eq 1 ]]; then
        echo "### Timing Delta"
    else
        echo "--- Timing Delta ---"
    fi
    echo ""
    run_table_timing
    echo ""

    if [[ $MARKDOWN -eq 1 ]]; then
        echo "### Memory Delta (RSS Peak)"
    else
        echo "--- Memory Delta (RSS Peak) ---"
    fi
    echo ""
    run_table_memory
    echo ""
fi

if [[ "$MODE" == "summary" || "$MODE" == "all" ]]; then
    if [[ "$MODE" == "all" ]]; then
        if [[ $MARKDOWN -eq 1 ]]; then echo "### Summary"; else echo "--- Summary ---"; fi
        echo ""
    fi
    run_comparison "summary"
    echo ""
fi

if [[ "$MODE" == "detailed" || "$MODE" == "all" ]]; then
    if [[ "$MODE" == "all" ]]; then
        if [[ $MARKDOWN -eq 1 ]]; then echo "### Detailed"; else echo "--- Detailed ---"; fi
        echo ""
    fi
    run_comparison "detailed"
    echo ""
fi

} # end run_report

# --- Execute report ---
if [[ $SAVE -eq 1 ]]; then
    run_report > "$SAVE_FILE"
    echo "Saved: $SAVE_FILE" >&2
else
    run_report
fi
