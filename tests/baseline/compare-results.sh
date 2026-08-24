#!/bin/bash
#
# compare-results.sh — Compare two benchmark TSV result files
# Usage: ./compare-results.sh [summary|detailed|table|all] [--markdown] [--save] <baseline.tsv> <current.tsv>
#
# Modes:
#   summary  — per-stage timing rollup, per-category memory rollup, metrics
#              new to the current version, then timing total and RSS peak
#              per test case (default)
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
# old -> new entry to TIMING_TMAP_AWK below IN THE SAME COMMIT — that is the
# single definition every section of the report resolves through; otherwise
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

# --- TIMING label compat map — THE one definition ---
# Old label -> the label in use today. Baselines are kept for years and carry
# whatever labels their release emitted, so every rename of a TIMING row must
# add an entry here IN THE SAME CHANGE or cross-version rows stop pairing —
# the old and new names each become a half-empty N/A row and the metric
# silently drops out of every comparison spanning the rename.
#
# Chains are resolved (a -> b -> c collapses to c), so a second rename of an
# already-renamed row only needs its own new entry.
#
# Every awk program in this script that reads a TIMING label shares this
# block and calls canon_timing(). A second copy of the table would mean a
# rename could be recorded in one place and missed in another, so the rows
# pair in one section of the report and silently stop pairing in another —
# the exact failure the map exists to prevent.
#
# #180 moved the flat stage labels to stage/step form:
TIMING_TMAP_AWK='
    BEGIN {
        tmap["read_files"] = "parse/read_files"
        tmap["initialize_buckets"] = "accumulate/initialize_buckets"
        tmap["group_similar"] = "finalize/group_similar"
        tmap["calculate_statistics"] = "finalize/calculate_statistics"
        tmap["heatmap_statistics"] = "finalize/heatmap_statistics"
        tmap["histogram_statistics"] = "finalize/histogram_statistics"
        tmap["normalize_data"] = "render/normalize_data"
    }

    # Follow the chain so a label renamed more than once still lands on the
    # current name; the guard stops a mistaken cycle looping.
    function canon_timing(label,    hops) {
        hops = 0
        while (label in tmap && hops++ < 10) label = tmap[label]
        return label
    }
'

# --- Comparison output ---
run_comparison() {
    local filter_mode="$1"

    awk -F'\t' -v filter="$filter_mode" "$TIMING_TMAP_AWK"'
    {
        if ($3 == "TIMING") {
            $4 = canon_timing($4)
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
            printf "      If a row was RENAMED, add old -> new to TIMING_TMAP_AWK in compare-results.sh\n" > "/dev/stderr"
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

# --- Rollup: per-stage timing and per-category memory, aggregated across
# --- test cases, plus metrics new to the current version (Issue #416).
#
# The top-line matrices show only TIMING/total and MEMORY/rss_peak, so a
# regression confined to one stage or one memory category sits in the detail
# rows and is found only by manual TSV analysis (#413: a fixed +20 MB in
# MEMORY/unattributed and a new 0.1 s detect/registry_build stage, both
# missed at v0.17.0-first).
#
# Aggregation is the SUM over the test cases the current run executed, not
# the mean of per-case percentages: a 60 s case and a 0.1 s case must not
# carry equal weight in a stage's verdict.
#
# Containment: a TIMING label with a third stage/step/sub_step segment
# measures time INSIDE its parent row, and detect/scan_sub_compile measures
# compile cost that fires within whichever stage triggered it. Neither is
# part of TIMING total. Both are marked "(within parent)" and excluded from
# the additive stage sum, so a sub-stage can never read as exceeding the
# stage that contains it.
run_rollup() {
    local kind="$1"

    awk -F'\t' -v kind="$kind" "$TIMING_TMAP_AWK"'

    NR == FNR && FNR == 1 { next }
    NR != FNR && FNR == 1 { next }

    # Which test cases did the current run execute? A case the current run
    # skipped contributes to neither side (same rule as run_comparison), and
    # that set is only known after the current file has been read — so both
    # files are buffered here and accumulated in END.
    NR != FNR && $3 == "TIMING" && $4 == "total" { current_test[$1] = 1 }

    NR == FNR { base_rows[FNR] = $0; base_n = FNR; next }
    { cur_rows[FNR] = $0; cur_n = FNR }

    END {
        OFS = "\t"

        for (i = 1; i <= base_n; i++) accumulate(base_rows[i], 1)
        for (i = 1; i <= cur_n;  i++) accumulate(cur_rows[i],  0)

        if (kind == "timing")      emit_rollup("TIMING")
        else if (kind == "memory") emit_rollup("MEMORY")
        else if (kind == "new")    emit_new()
    }

    # Accumulate one TSV row into the baseline or current totals for its
    # metric. TIMING labels go through canon_timing() — the same shared
    # rename map the detail comparison uses — so a rollup spanning a rename
    # pairs its rows exactly as the detail rows do.
    function accumulate(row, is_base,    f, nfields, type, name, val, key) {
        nfields = split(row, f, "\t")
        if (nfields < 5) return
        type = f[3]; name = f[4]; val = f[5]
        if (!(f[1] in current_test)) return
        if (type != "TIMING" && type != "MEMORY") return
        if (val + 0 != val || val == "") return

        if (type == "TIMING") name = canon_timing(name)

        key = type "/" name
        if (!(key in seen_metric)) {
            seen_metric[key] = 1
            order[++n_order] = key
        }
        if (is_base) {
            base_sum[key] += val
            base_cases[key]++
            base_val[key, f[1]] = val
        } else {
            cur_sum[key] += val
            cur_cases[key]++
            # Per-test range, for the "new in this version" section.
            if (!(key in cur_min) || val + 0 < cur_min[key] + 0) cur_min[key] = val
            if (!(key in cur_max) || val + 0 > cur_max[key] + 0) cur_max[key] = val
            # Per-case direction. The summed delta alone can report IMPROVE
            # for a metric that regressed in most test cases, when a few
            # large cases move the other way — exactly the shape of the
            # fixed +20 MB in MEMORY/unattributed (#413), which sums to a
            # net improvement against the large cases decreasing. The
            # up/down split makes a uniform small regression visible.
            if ((key SUBSEP f[1]) in base_val) {
                if (val + 0 > base_val[key, f[1]] + 0) cases_up[key]++
                else if (val + 0 < base_val[key, f[1]] + 0) cases_down[key]++
            }
        }
    }

    function is_contained(type, name,    parts) {
        if (type != "TIMING") return 0
        if (name == "detect/scan_sub_compile") return 1
        return (split(name, parts, "/") >= 3)
    }

    function emit_rollup(want_type,    i, key, parts, type, name, b, c,
                         stage_b, stage_c, floor_on) {
        print "metric", "baseline", "current", "delta", "change%", "cases +/-", "result"

        # The noise floor de-ranks the quiet rows so the loud one leads. If
        # nothing is loud there is nothing to rank against, and collapsing
        # the table would hide the whole pipeline to say "all quiet" — so
        # the floor only engages once some row has cleared it.
        floor_on = 0
        for (i = 1; i <= n_order; i++) {
            key = order[i]
            split(key, parts, "/")
            if (parts[1] != want_type) continue
            if (!(key in base_sum)) continue
            name = substr(key, length(parts[1]) + 2)
            if (name == "total" || name == "rss_peak") continue
            if (!is_quiet(want_type, base_sum[key],
                          (key in cur_sum) ? cur_sum[key] : 0)) { floor_on = 1; break }
        }

        stage_b = 0; stage_c = 0
        nrank = 0
        quiet_n = 0; quiet_b = 0; quiet_c = 0
        qc_n = 0; qc_b = 0; qc_c = 0
        for (i = 1; i <= n_order; i++) {
            key = order[i]
            split(key, parts, "/")
            type = parts[1]
            name = substr(key, length(type) + 2)
            if (type != want_type) continue

            # A metric absent from the baseline belongs in the "new in this
            # version" section, which has an aggregate to show; a rollup row
            # comparing it against nothing does not.
            if (!(key in base_sum)) continue

            b = base_sum[key]
            c = (key in cur_sum) ? cur_sum[key] : 0
            if (b == 0 && c == 0) continue

            if (want_type == "TIMING" && name != "total" && !is_contained(type, name)) {
                stage_b += b
                stage_c += c
            }

            # Noise floor. A category that moved by a few hundred bytes, or
            # a stage by a millisecond, carries the same REGRESS badge as a
            # systematic leak and pushes the row that matters down the page.
            # Sub-threshold rows collapse into one line that still accounts
            # for their total, so nothing is hidden — only de-ranked.
            # Contained rows are kept separate from the additive ones, so
            # the collapsed line never mixes time counted inside a parent
            # with time counted alongside it — a mixed total cannot be read
            # against the sum-of-stages row and looks like an inconsistency.
            if (floor_on && is_quiet(want_type, b, c) && name != "total" && name != "rss_peak") {
                if (is_contained(want_type, name)) {
                    qc_n++; qc_b += b; qc_c += c
                } else {
                    quiet_n++; quiet_b += b; quiet_c += c
                }
                continue
            }

            rank_key[++nrank] = key
            rank_name[nrank] = name
            rank_b[nrank] = b
            rank_c[nrank] = c
            rank_mag[nrank] = ((c - b) < 0) ? (b - c) : (c - b)
            # The run-level roof anchors its table regardless of magnitude:
            # TIMING total and MEMORY rss_peak are the frame the categories
            # below them are read against, not competitors for the top slot.
            if (want_type == "TIMING" && name == "total") rank_mag[nrank] = -1
            if (want_type == "MEMORY" && name == "rss_peak") rank_mag[nrank] = 1e18
        }

        # Memory has no intrinsic order, so the largest absolute movement
        # leads — that is the row to drill into. Timing keeps pipeline order
        # (parse -> accumulate -> finalize -> render), which is itself the
        # diagnostic: where in the run the cost moved.
        if (want_type == "MEMORY") sort_by_magnitude(nrank)

        for (i = 1; i <= nrank; i++)
            print_row(want_type, rank_name[i], rank_b[i], rank_c[i],
                      is_contained(want_type, rank_name[i]) ? " (within parent)" : "",
                      rank_key[i])

        if (quiet_n > 0)
            print_row(want_type, sprintf("(%d below noise floor)", quiet_n),
                      quiet_b, quiet_c, "", "")
        if (qc_n > 0)
            print_row(want_type, sprintf("(%d below noise floor)", qc_n),
                      qc_b, qc_c, " (within parent)", "")

        # Additive check: the stages that make up TIMING total should sum to
        # it. A gap means wall-clock time that no stage row accounts for.
        # No per-case split: this row is a sum across metrics, not a metric.
        if (want_type == "TIMING" && stage_b > 0)
            print_row(want_type, "sum of stages", stage_b, stage_c, "", "")
    }

    # Below this movement a row is bookkeeping, not a lead: 1 MB for a
    # memory category, 100 ms for a timing stage, aggregated across every
    # test case in the run.
    function is_quiet(type, b, c,    d) {
        d = (c - b < 0) ? b - c : c - b
        if (type == "MEMORY") return (d < 1048576)
        return (d < 0.100)
    }

    function sort_by_magnitude(cnt,    i, j, t) {
        for (i = 2; i <= cnt; i++)
            for (j = i; j > 1 && rank_mag[j] > rank_mag[j-1]; j--) {
                t = rank_mag[j]; rank_mag[j] = rank_mag[j-1]; rank_mag[j-1] = t
                t = rank_key[j];  rank_key[j]  = rank_key[j-1];  rank_key[j-1]  = t
                t = rank_name[j]; rank_name[j] = rank_name[j-1]; rank_name[j-1] = t
                t = rank_b[j];    rank_b[j]    = rank_b[j-1];    rank_b[j-1]    = t
                t = rank_c[j];    rank_c[j]    = rank_c[j-1];    rank_c[j-1]    = t
            }
    }

    function print_row(type, name, b, c, note, key,
                       delta, pct, ind, bd, cd, dd, up, dn, split_col) {
        delta = c - b
        if (b != 0)       pct = sprintf("%.1f%%", (delta / b) * 100)
        else if (c == 0)  pct = "0.0%"
        else              pct = "NEW"

        if (delta > 0)      ind = "REGRESS"
        else if (delta < 0) ind = "IMPROVE"
        else                ind = ""

        # The summed delta is the magnitude; the per-case split is the
        # breadth. When they disagree — a net improvement carried by a few
        # large cases while most cases got worse — the summed verdict alone
        # is misleading, so the row says so.
        up = (key != "" && (key in cases_up))   ? cases_up[key]   : 0
        dn = (key != "" && (key in cases_down)) ? cases_down[key] : 0
        if (key == "" || (up == 0 && dn == 0)) {
            split_col = "-"
        } else {
            split_col = sprintf("%d/%d", up, dn)
            if (delta < 0 && up > dn)      ind = "IMPROVE (most cases REGRESS)"
            else if (delta > 0 && dn > up) ind = "REGRESS (most cases IMPROVE)"
        }

        if (type == "MEMORY") {
            bd = format_bytes(b); cd = format_bytes(c); dd = format_bytes_signed(delta)
        } else {
            bd = format_time(b); cd = format_time(c); dd = format_time_signed(delta)
        }
        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", name note, bd, cd, dd, pct, split_col, ind
    }

    # Metrics the current run emits that the baseline has no counterpart
    # for. These are the rows that would otherwise render as "N/A -> ?" and
    # feed no summary at all; here they get an aggregate and the per-test
    # range that shows whether the cost is uniform or concentrated.
    function emit_new(   i, key, parts, type, name, any, lo, hi, agg) {
        print "metric", "test cases", "per-test range", "aggregate"
        any = 0
        for (i = 1; i <= n_order; i++) {
            key = order[i]
            if (key in base_sum) continue
            if (!(key in cur_sum)) continue
            split(key, parts, "/")
            type = parts[1]
            name = substr(key, length(type) + 2)

            if (type == "MEMORY") {
                lo = format_bytes(cur_min[key]); hi = format_bytes(cur_max[key])
                agg = format_bytes(cur_sum[key])
            } else {
                lo = format_time(cur_min[key]); hi = format_time(cur_max[key])
                agg = format_time(cur_sum[key])
            }
            printf "%s\t%d\t%s - %s\t%s\n", \
                key (is_contained(type, name) ? " (within parent)" : ""), \
                cur_cases[key], lo, hi, agg
            any = 1
        }
        if (!any) printf "(none)\t-\t-\t-\n"
    }

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

# The rollups precede the per-test Summary: they are the headline the
# matrices above do not carry. Unlike Summary they are always titled, since
# three untitled tables in a row cannot be told apart.
if [[ "$MODE" == "summary" || "$MODE" == "all" ]]; then
    if [[ $MARKDOWN -eq 1 ]]; then echo "### Stage Rollup (timing)"; else echo "--- Stage Rollup (timing) ---"; fi
    echo ""
    run_rollup "timing"
    echo ""

    if [[ $MARKDOWN -eq 1 ]]; then echo "### Category Rollup (memory)"; else echo "--- Category Rollup (memory) ---"; fi
    echo ""
    run_rollup "memory"
    echo ""

    if [[ $MARKDOWN -eq 1 ]]; then echo "### New In This Version"; else echo "--- New In This Version ---"; fi
    echo ""
    run_rollup "new"
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
