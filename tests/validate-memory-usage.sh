#!/usr/bin/env bash
# validate-memory-usage.sh — harness for the readings of the process memory:
# how many there are and the time spent in them, per caller, and the -mem
# debug diagnostic readings.
#
# The file name tracks the -V memory-usage section and its debug sub-section.
# The scenarios read that section, the benchmark-data rows that repeat its
# totals, the format-registry compile count the compile callers are measured
# against, and the comparison tool's treatment of the reading time.
#
# The runs that count readings between steps pass -mem: without it, where the
# peak the operating system keeps can be read, no reading is taken between
# steps (no-mem-readings asserts that).
#
# Each assertion records, per tests/HARNESS-DESIGN.md § Self-documenting
# assertions: asserts, produced_by (function name), contract. All three are
# surfaced on failure.
#
# Usage: ./tests/validate-memory-usage.sh [--list | --scenario NAME...]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="${LTL:-$REPO_DIR/ltl}"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"
# shellcheck source=lib/notices.sh
source "$SCRIPT_DIR/lib/notices.sh"

neutralize_colour_env

# Twelve lines of a combined-format web-server access log.
ACCESS_FIXTURE="$REPO_DIR/tests/fixtures/format-detection/access-combined.txt"

DOC='features/memory-tracking-improvements.md'
C_SECTION="$DOC § -V memory-usage section contract; criterion 8"
C_GATE="$DOC § -V memory-usage section contract (the activation flag); criteria 9 and 17"
C_DEBUG="$DOC § Decisions D5, D6 and the section contract; criteria 10 and 11"
C_BENCH="$DOC § -V memory-usage section contract (benchmark-data); criterion 12"
C_MAP="$DOC § Issue #709 › Acceptance criteria 9 and 10, § Store inventory; § Issue #356 Specification S3 and S5; features/memory-baseline-profiling.md DD-03"
C_PEAK="$DOC § Issue #709 › Decisions D1 and D2; Acceptance criteria 3, 4, 6 and 12; § -V memory-usage section contract"
C_NOMEM="$DOC § Issue #709 › Decisions (following from D1 and D2: without -mem, no reading is taken between steps); Acceptance criterion 5"

# The callers of the section contract, in the order their lines print.
SITE_ORDER="kept_peak,phase_boundary,grouping_checkpoint,grouping_final_pass,format_scan_compile,csv_block_compile,debug_decomposition,debug_sample"

# The stores § Issue #709 › Store inventory found growing with the input
# outside the map, each under its variable's name.
INVENTORY_STORES=(
    histogram_values_hl histogram_buckets histogram_buckets_hl histogram_stats
    histogram_stats_hl histogram_boundaries heatmap_percentiles
    consolidation_cat_stats consolidation_category_unmatched_count
    consolidation_pattern_generation consolidation_key_generation
    consolidation_key_checkpoint_count consolidation_absorption_ema
    consolidation_streaming_absorbed consolidation_final_pass_skipped
    consolidation_cliff_edge
    files_processed in_files_matched index_file_data index_preseed
    index_aggregated format_detection format_detection_evidence
    format_detection_sample timestamp_date_cache unregistered_levels
    unregistered_levels_by_file
    verbose_output verbose_section_buffer section_rows category_totals
    progress_history notice_records memory_debug_records bin_counter_telemetry
    stats_demand_telemetry udm_skipped_lines numeric_filter_no_metric
)

pass=0
fail=0
failures=()
current_scenario=""

pass_with() {
    echo "  PASS  $current_scenario :: $1"
    pass=$((pass + 1))
}

# fail_with <label> <asserts> <produced_by> <contract> [detail...]
fail_with() {
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

# check <label> <actual> <expected> <asserts> <produced_by> <contract> [run_free]
# run_free names the input of a check that does not depend on $LTL; the PASS
# line then ends [run-free: <it>] (tests/HARNESS-DESIGN.md section The
# failed-run checker).
check() {
    if [[ -n "$2" && "$2" == "$3" ]]; then
        pass_with "$1 ($2)${7:+ [run-free: $7]}"
    else
        fail_with "$1" "$4" "$5" "$6" "expected: $3" "actual:   ${2:-MISSING-ANCHOR}"
    fi
}

# run_ltl <tag> <args...>: one ltl run in the harness's own directory, or in
# $RUN_IN when set (a run whose files another run must not see); stdout and
# stderr land in $TMP_DIR/<tag>.out and .err, the exit status in .rc. A Perl
# runtime warning on stderr, a non-zero exit, or an empty standard output is
# a failure.
run_ltl() {
    local tag="$1"; shift
    local rc=0
    ( cd "${RUN_IN:-$TMP_DIR}" && "$LTL" --disable-progress -ni "$@" ) > "$TMP_DIR/$tag.out" 2> "$TMP_DIR/$tag.err" || rc=$?
    echo "$rc" > "$TMP_DIR/$tag.rc"
    if [[ "$rc" -ne 0 ]]; then
        fail=$((fail + 1)); failures+=("$current_scenario :: $tag exit $rc")
        echo "  FAIL  $current_scenario :: $tag exited $rc"
        echo "        asserts:     the run exits 0 and writes the output its checks read"
        echo "        produced_by: ltl"
        echo "        contract:    tests/HARNESS-DESIGN.md Trap 13"
        sed 's/^/        /' "$TMP_DIR/$tag.err" | head -5
    elif [[ ! -s "$TMP_DIR/$tag.out" ]]; then
        fail=$((fail + 1)); failures+=("$current_scenario :: $tag printed nothing")
        echo "  FAIL  $current_scenario :: $tag exited 0 and printed nothing"
        echo "        asserts:     the run exits 0 and writes the output its checks read"
        echo "        produced_by: ltl"
        echo "        contract:    tests/HARNESS-DESIGN.md Trap 13"
    fi
    if ! assert_no_runtime_warnings "$TMP_DIR/$tag.err" "$current_scenario/$tag"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: $tag perl-runtime-warnings-on-stderr")
    fi
}

# produced <tag> <pattern> <label>: the run <tag> exited 0, printed, and its
# output holds <pattern>: the evidence a check of an absence, a count of 0 or
# the shape of every record needs, since each holds on a run that printed
# nothing (tests/HARNESS-DESIGN.md Trap 13). A failed run was counted once by
# run_ltl, so the check is skipped; a run without the evidence fails it.
produced() {
    local tag="$1" pattern="$2" label="$3"
    if [[ "$(cat "$TMP_DIR/$tag.rc")" != 0 || ! -s "$TMP_DIR/$tag.out" ]]; then
        echo "  SKIP  $current_scenario :: $label (run $tag failed)"
        return 1
    fi
    if ! grep -qE "$pattern" "$TMP_DIR/$tag.out"; then
        fail_with "$label" 'The run writes what this check reads' 'emit_memory_usage_verbose() in ltl' "$C_SECTION" \
            "run $tag holds no line matching: $pattern"
        return 1
    fi
}

# section <tag>: the memory-usage section of a run, outside its debug
# sub-section; empty when absent.
section() {
    awk '/^=== memory-usage ===$/ { in_s = 1; next } /^=== END memory-usage ===$/ { in_s = 0 }
         /^=== memory-usage \/ debug ===$/ { in_d = 1 } /^=== END memory-usage \/ debug ===$/ { in_d = 0; next }
         in_s && !in_d' "$TMP_DIR/$1.out"
}
# debug_records <tag>: the debug sub-section's records, header excluded.
debug_records() {
    awk '/^=== memory-usage \/ debug ===$/ { in_d = 1; getline; next } /^=== END memory-usage \/ debug ===$/ { in_d = 0 } in_d' "$TMP_DIR/$1.out"
}
# fact <tag> <key>: a "key: value" line of the section.
fact() { section "$1" | sed -n "s/^$2: //p"; }
# site <tag> <name> <field>: a field of one caller's line; empty when absent.
site() { section "$1" | sed -n "s/^site: $2 .*$3=\([0-9]*\).*/\1/p"; }
# site_names <tag>: the callers listed, comma-separated, in order.
site_names() { section "$1" | sed -n 's/^site: \([a-z_]*\) .*/\1/p' | paste -sd, -; }
# sums <tag>: "readings|readings_us" summed over the site lines.
sums() {
    section "$1" | awk '/^site: / { for (i = 3; i <= NF; i++) { split($i, kv, "="); s[kv[1]] += kv[2] } n++ }
                        END { if (n) printf "%d|%d", s["readings"], s["elapsed_us"] }'
}
# bench <tag> <type> <name>: a benchmark-data row's value; empty when absent.
bench() {
    awk -F'\t' -v t="$2" -v n="$3" '/^=== benchmark-data ===$/ { in_s = 1; next } /^=== END benchmark-data ===$/ { in_s = 0 }
        in_s && $1 == t && $2 == n { print $3; exit }' "$TMP_DIR/$1.out"
}

# ---------------------------------------------------------------------------
# Phase boundaries: one reading after reading, after the bucket initialisation,
# after the statistics, before the summary and after the output; the heatmap
# and the histogram each add one. The totals are the sums of the caller lines.
# ---------------------------------------------------------------------------
scenario_phase_boundary() {
    current_scenario="phase-boundary"
    echo "[$current_scenario]"
    run_ltl plain -bs 1440 -oe -mem -V memory-usage "$ACCESS_FIXTURE"
    check "phase-boundary readings" "$(site plain phase_boundary readings)" "5" \
        'A run without heatmap or histogram reads memory at five phase boundaries' \
        'measure_memory_structures() from the pipeline_* steps in ltl' "$C_SECTION"
    check "totals are the caller sums" "$(fact plain readings)|$(fact plain readings_us)" "$(sums plain)" \
        'readings and readings_us equal the sums of the site lines' 'emit_memory_usage_verbose() in ltl' "$C_SECTION"
    run_ltl charts -bs 1440 -oe -mem -hm duration -hg -V memory-usage "$ACCESS_FIXTURE"
    check "phase-boundary readings with heatmap and histogram" "$(site charts phase_boundary readings)" "7" \
        'The heatmap and the histogram statistics each add one phase-boundary reading' \
        'pipeline_finalize() in ltl' "$C_SECTION"
}

# ---------------------------------------------------------------------------
# Grouping: the checkpoints and the final pass's windows each read memory.
# ---------------------------------------------------------------------------
scenario_grouping() {
    current_scenario="grouping"
    echo "[$current_scenario]"
    run_ltl grouped -bs 1440 -oe -mem -g -V memory-usage "$ACCESS_FIXTURE"
    local cp fp
    cp=$(site grouped grouping_checkpoint readings); fp=$(site grouped grouping_final_pass readings)
    check "checkpoint and final-pass callers present" "$([[ "${cp:-0}" -gt 0 && "${fp:-0}" -gt 0 ]] && echo yes || echo "no (checkpoint=${cp:-absent} final_pass=${fp:-absent})")" "yes" \
        'A grouped run counts readings under grouping_checkpoint and grouping_final_pass' \
        'run_consolidation_checkpoint() and process_final_pass_window() in ltl' "$C_SECTION"
    run_ltl ungrouped -bs 1440 -oe -mem -V memory-usage "$ACCESS_FIXTURE"
    if produced ungrouped '^site: ' 'no grouping callers without -g'; then
        check "no grouping callers without -g" "$(site_names ungrouped | tr ',' '\n' | grep -c '^grouping_' || true)" "0" \
            'An ungrouped run lists no grouping caller' 'emit_memory_usage_verbose() in ltl' "$C_SECTION"
    fi
    check "totals are the caller sums" "$(fact grouped readings)|$(fact grouped readings_us)" "$(sums grouped)" \
        'readings and readings_us equal the sums of the site lines' 'emit_memory_usage_verbose() in ltl' "$C_SECTION"
}

# ---------------------------------------------------------------------------
# Compiles: two readings around each compile, a format scan sub or a CSV
# block, measured against the compile count format-registry reports.
# ---------------------------------------------------------------------------
scenario_compiles() {
    current_scenario="compiles"
    echo "[$current_scenario]"
    printf 'timestamp,latency\n2026-06-01 10:00:05,12\n2026-06-01 10:01:05,34\n2026-06-01 10:02:05,56\n' > "$TMP_DIR/metrics.csv"
    run_ltl csv -bs 1440 -oe -mem -udm latency:ms:mean -V memory-usage,format-registry "$TMP_DIR/metrics.csv"
    local compiled scan csv
    compiled=$(sed -n 's/^scan_subs_compiled: //p' "$TMP_DIR/csv.out")
    scan=$(site csv format_scan_compile readings); csv=$(site csv csv_block_compile readings)
    check "csv block readings" "${csv:-}" "2" \
        'The CSV block compile reads memory before and after' 'compile_csv_block() in ltl' "$C_SECTION"
    if produced csv '^scan_subs_compiled: [0-9]' 'two readings per compile'; then
        check "two readings per compile" "$(( ${scan:-0} + ${csv:-0} ))" "$(( ${compiled:-0} * 2 ))" \
            'format_scan_compile and csv_block_compile readings together are twice the compiles format-registry counts' \
            'compile_format_scan_sub() and compile_csv_block() in ltl' "$C_SECTION"
    fi
}

# ---------------------------------------------------------------------------
# The activation flag: without the section nothing is counted or repeated.
# ---------------------------------------------------------------------------
scenario_section_off() {
    current_scenario="section-off"
    echo "[$current_scenario]"
    run_ltl off -bs 1440 -oe -mem -V benchmark-data "$ACCESS_FIXTURE"
    if produced off '^=== benchmark-data ===$' 'no section'; then
        check "no section" "$(grep -c '^=== memory-usage' "$TMP_DIR/off.out" || true)" "0" \
            'No memory-usage section prints unless it is selected or -mem debug is given' \
            'emit_memory_usage_verbose() in ltl' "$C_GATE"
    fi
    check "no benchmark-data rows" "$(bench off TIMING memory/readings)|$(bench off COUNTS memory_readings)|$(bench off TIMING total | sed 's/.*/present/')" "||present" \
        'benchmark-data carries no memory-reading rows while the section is off' \
        'print_verbose_output() in ltl' "$C_GATE"
    run_ltl nodebug -bs 1440 -oe -mem -V memory-usage "$ACCESS_FIXTURE"
    if produced nodebug '^=== memory-usage ===$' 'no debug sub-section or debug callers'; then
        check "no debug sub-section or debug callers" "$(grep -c '^=== memory-usage / debug ===$' "$TMP_DIR/nodebug.out" || true)|$(site_names nodebug | tr ',' '\n' | grep -c '^debug_' || true)" "0|0" \
            'Without -mem debug there is no debug sub-section and no debug reading' \
            'memory_debug_sample() and memory_debug_decomposition() in ltl' "$C_GATE"
    fi
}

# ---------------------------------------------------------------------------
# -mem debug: the section prints without -V, the diagnostics are in its debug
# sub-section and nothing reaches stderr; one decomposition per phase boundary.
# ---------------------------------------------------------------------------
scenario_debug() {
    current_scenario="debug"
    echo "[$current_scenario]"
    run_ltl debug -bs 1440 -oe -mem debug "$ACCESS_FIXTURE"
    check "section and sub-section without -V" "$(grep -c '^=== memory-usage ===$' "$TMP_DIR/debug.out" || true)|$(grep -c '^=== memory-usage / debug ===$' "$TMP_DIR/debug.out" || true)" "1|1" \
        '-mem debug requests the memory-usage section and prints its debug sub-section' \
        'adapt_to_command_line_options() and emit_memory_usage_verbose() in ltl' "$C_DEBUG"
    if produced debug '^=== memory-usage ===$' 'nothing on stderr'; then
        check "nothing on stderr" "$(grep -c . "$TMP_DIR/debug.err" || true)" "0" \
            'The diagnostic readings no longer go to stderr' 'memory_debug_decomposition() in ltl' "$C_DEBUG"
    fi
    check "decomposition per phase boundary" "$(debug_records debug | awk -F'\t' '$1 == "decomposition" { print $3 }' | paste -sd, -)" \
        "startup,after_read,after_bucket_init,after_stats,after_normalize,after_bar_graph,after_message_summary,after_summary_table,end" \
        'One decomposition record per phase boundary the run reached, from startup to end, in order' \
        'memory_debug_decomposition() from the pipeline_* steps in ltl' "$C_DEBUG"
    check "decomposition readings match the records" "$(site debug debug_decomposition readings)" "$(debug_records debug | grep -c '^decomposition' || true)" \
        'Each decomposition record is one reading under debug_decomposition' 'memory_debug_decomposition() in ltl' "$C_DEBUG"
    if produced debug $'^decomposition\t' 'record shape'; then
        check "record shape" "$(debug_records debug | awk -F'\t' 'NF != 8 { bad++ } $1 == "decomposition" && ($7 != "-" || $8 != "-") { bad++ } END { print bad + 0 }')" "0" \
            'Every record has the eight columns; a decomposition carries - for structure and bytes' \
            'emit_memory_usage_verbose() in ltl' "$C_DEBUG"
    fi
}

# ---------------------------------------------------------------------------
# -mem debug samples inside the read loop every 75,000 lines.
# ---------------------------------------------------------------------------
scenario_debug_samples() {
    current_scenario="debug-samples"
    echo "[$current_scenario]"
    perl -e 'local $/; my $lines = <STDIN>; print $lines x 12500' < "$ACCESS_FIXTURE" > "$TMP_DIR/repeated.txt"
    check "input lines" "$(wc -l < "$TMP_DIR/repeated.txt" | tr -d ' ')" "150000" \
        'The input carries exactly two 75,000-line strides' 'the harness' "$C_DEBUG" 'a file the harness writes'
    run_ltl samples -bs 1440 -oe -mem debug "$TMP_DIR/repeated.txt"
    check "read-loop samples" "$(debug_records samples | awk -F'\t' '$1 == "sample" && $3 == "read_lines"' | wc -l | tr -d ' ')" "2" \
        'One sample record every 75,000 lines read' 'memory_debug_sample() from read_and_process_logs() in ltl' "$C_DEBUG"
    check "sample readings match the records" "$(site samples debug_sample readings)" "$(debug_records samples | grep -c '^sample' || true)" \
        'Each sample record is one reading under debug_sample' 'memory_debug_sample() in ltl' "$C_DEBUG"
    if produced samples $'^sample\t' 'sample shape'; then
        check "sample shape" "$(debug_records samples | awk -F'\t' '$1 == "sample" && ($5 != "-" || $6 != "-") { bad++ } END { print bad + 0 }')" "0" \
            'A sample carries - for named_sum and unattributed' 'emit_memory_usage_verbose() in ltl' "$C_DEBUG"
    fi
}

# ---------------------------------------------------------------------------
# benchmark-data repeats the totals, read when it prints; the comparison
# treats the reading time as time within the stages.
# ---------------------------------------------------------------------------
scenario_benchmark_rows() {
    current_scenario="benchmark-rows"
    echo "[$current_scenario]"
    run_ltl bench -bs 1440 -oe -mem -V memory-usage,benchmark-data "$ACCESS_FIXTURE"
    local count total secs us
    count=$(bench bench COUNTS memory_readings); total=$(fact bench readings)
    secs=$(bench bench TIMING memory/readings); us=$(fact bench readings_us)
    check "count not above the section's" "$([[ -n "$count" && -n "$total" && "$count" -gt 0 && "$count" -le "$total" ]] && echo yes || echo "no (row=${count:-absent} section=${total:-absent})")" "yes" \
        'COUNTS memory_readings is present and not above the section readings' 'print_verbose_output() in ltl' "$C_BENCH"
    check "time not above the section's" "$(awk -v s="${secs:--1}" -v u="${us:--1}" 'BEGIN { print (s >= 0 && u >= 0 && s * 1e6 <= u + 500) ? "yes" : "no (row=" s " s, section=" u " us)" }')" "yes" \
        'TIMING memory/readings is present and not above the section readings_us' 'print_verbose_output() in ltl' "$C_BENCH"
    local n
    for n in a b; do
        run_ltl "cmp-$n" -bs 1440 -oe -mem -V memory-usage,benchmark-data "$ACCESS_FIXTURE"
        sed -n '/^=== benchmark-data ===$/,/^=== END benchmark-data ===$/p' "$TMP_DIR/cmp-$n.out" | sed '1d;$d' \
            | awk 'BEGIN { print "test_name\toptions\tmetric_type\tmetric_name\tvalue" } { print "case\t\t" $0 }' > "$TMP_DIR/cmp-$n.tsv"
    done
    "$REPO_DIR/tests/baseline/compare-results.sh" summary "$TMP_DIR/cmp-a.tsv" "$TMP_DIR/cmp-b.tsv" > "$TMP_DIR/cmp.txt" 2>&1 || true
    check "comparison marks the reading time within parent" "$(grep -c '^memory/readings (within parent) ' "$TMP_DIR/cmp.txt" || true)" "1" \
        'compare-results.sh reports memory/readings within parent, out of the stage sum' \
        'is_contained() in tests/baseline/compare-results.sh' "$C_BENCH"
}

# ---------------------------------------------------------------------------
# The memory map: under -mem a MEMORY row per store of the map, every store of
# the inventory among them; unattributed is the peak less the sum of the rows;
# MEMORY_FINAL carries one row per store of the map; the breakdown lists each
# store of 1 KB or more, then unattributed. -bs 1440 -oe: no check reads the
# time axis.
# ---------------------------------------------------------------------------
# rows <tag> <type>: the names of a run's benchmark-data rows of one type, one per line, sorted.
rows() {
    awk -F'\t' -v t="$2" '/^=== benchmark-data ===$/ { in_s = 1; next } /^=== END benchmark-data ===$/ { in_s = 0 }
        in_s && $1 == t { print $2 }' "$TMP_DIR/$1.out" | LC_ALL=C sort
}
# breakdown <tag>: the -mem breakdown's rows beneath MAXIMUM MEMORY USED, "name<TAB>value unit".
breakdown() {
    awk '/MAXIMUM MEMORY USED/ { in_b = 1; next }
         in_b && match($0, /^ +[a-z0-9_]+ +\( *[<0-9]+%\) +[0-9.]+ [A-Za-z]+ *$/) { n = split($0, f, " "); print f[1] "\t" f[n-1] " " f[n]; next }
         in_b { exit }' "$TMP_DIR/$1.out"
}
scenario_memory_map() {
    current_scenario="memory-map"
    echo "[$current_scenario]"
    run_ltl map -bs 1440 -oe -mem -V benchmark-data "$ACCESS_FIXTURE"
    produced map $'^MEMORY\trss_peak\t' 'memory map rows' || return 0

    local missing
    missing=$(comm -23 <(printf '%s\n' "${INVENTORY_STORES[@]}" | LC_ALL=C sort) <(rows map MEMORY) | paste -sd, -)
    check "every inventory store has a MEMORY row" "${missing:-none}" "none" \
        'Under -mem, each store the inventory found growing with the input is in the named-structure map, so benchmark-data carries a MEMORY row for it' \
        'named_structure_sizes() and print_verbose_output() in ltl' "$C_MAP"

    local expected
    expected=$(awk -F'\t' '/^=== benchmark-data ===$/ { in_s = 1; next } /^=== END benchmark-data ===$/ { in_s = 0 }
        in_s && $1 == "MEMORY" && $2 == "rss_peak" { peak = $3; p = 1; next }
        in_s && $1 == "MEMORY" && $2 != "unattributed" { sum += $3 }
        END { if (p) { u = peak - sum; print (u < 0 ? 0 : u) } }' "$TMP_DIR/map.out")
    check "unattributed is the peak less every row" "$(bench map MEMORY unattributed)" "$expected" \
        'MEMORY unattributed equals rss_peak less the sum of every other MEMORY row, floored at zero' \
        'print_verbose_output() in ltl' "$C_MAP"

    check "MEMORY_FINAL carries the map's stores" "$(rows map MEMORY_FINAL | paste -sd, -)" \
        "$(rows map MEMORY | grep -vxE 'rss_peak|unattributed|format_scan_subs' | paste -sd, -)" \
        'MEMORY_FINAL has one row per store of the named-structure map, under the MEMORY rows names: every MEMORY row but rss_peak, unattributed and the format_scan_subs compile-boundary figure' \
        'print_verbose_output() in ltl, through named_structure_sizes()' "$C_MAP"

    # The breakdown prints after the benchmark block and after further walks, so
    # its high-water marks can exceed the block's: it is checked against its own
    # figures, not the block's rows.
    local stray
    stray=$(comm -23 <(breakdown map | cut -f1 | awk '$0 != "unattributed"' | LC_ALL=C sort) <(rows map MEMORY) | paste -sd, -)
    check "the breakdown lists stores of the map, then unattributed" "${stray:-none}|$(breakdown map | tail -1 | cut -f1)" "none|unattributed" \
        'Every row of the -mem breakdown is a store of the named-structure map, and the last row is unattributed' \
        'print_summary_table() in ltl' "$C_MAP"

    # unattributed is MAXIMUM MEMORY USED less the full sum of high-water marks.
    # The breakdown renders two or three significant figures and hides the stores
    # under 1 KB, so the check holds within the precision of every figure it reads
    # plus 1 KB for each store the breakdown does not list.
    local verdict
    verdict=$(breakdown map | awk -F'\t' -v peak="$(sed -nE 's/^ *MAXIMUM MEMORY USED +([0-9.]+ [A-Za-z]+) *$/\1/p' "$TMP_DIR/map.out" | head -1)" \
                                         -v stores="$(rows map MEMORY | grep -cvxE 'rss_peak|unattributed' || true)" '
        function unit(u) { return u == "B" ? 1 : u == "kB" ? 1e3 : u == "MB" ? 1e6 : u == "GB" ? 1e9 : -1 }
        function bytes(t,   p) { split(t, p, " "); return unit(p[2]) < 0 ? -1 : p[1] * unit(p[2]) }
        function step(t,   p, d) { split(t, p, " "); d = index(p[1], ".") ? length(p[1]) - index(p[1], ".") : 0
            return unit(p[2]) * 0.5 * 10 ^ -d }
        $1 == "unattributed" { row = $2; next }
        { if (bytes($2) < 0) bad = $2; sum += bytes($2); slack += step($2); listed++ }
        END { if (row == "" || peak == "" || bad != "" || bytes(row) < 0 || bytes(peak) < 0) { print "unreadable (row=" row ", peak=" peak ", figure=" bad ")"; exit }
              want = bytes(peak) - sum; if (want < 0) want = 0
              diff = bytes(row) - want; if (diff < 0) diff = -diff
              slack += step(row) + step(peak) + 1024 * (stores - listed)
              print (diff <= slack) ? "yes" : "no (unattributed " row ", peak " peak " less " sum " bytes listed, off by " diff ", allowed " slack ")" }')
    check "the breakdown's unattributed is MAXIMUM MEMORY USED less every store" "$verdict" "yes" \
        'The breakdown unattributed row equals MAXIMUM MEMORY USED less the sum of every store high-water mark, floored at zero, within the precision of the rendered figures and the stores under 1 KB it hides' \
        'print_summary_table() in ltl' "$C_MAP"
}

# ---------------------------------------------------------------------------
# The peak: the high-water mark the operating system keeps for the process,
# read once at each moment a peak is reported (-V benchmark-data, before the
# summary, the run index), so every consumer reports it at its moment. On
# macOS without BSD::Resource the run reports the readings' peak and says so.
# -bs 1440 -oe: no check reads the time axis.
# ---------------------------------------------------------------------------
# index_memory_used <dir>: the run index's memory_used, from its selection row.
index_memory_used() {
    [[ -f "$1/ltl-index.csv" ]] || return 0
    perl -MText::CSV -e 'my $c = Text::CSV->new({ binary => 1 }); open my $f, "<", $ARGV[0] or exit;
        my $h = $c->getline($f); my %i; @i{@$h} = 0 .. $#$h;
        while (my $r = $c->getline($f)) { print $r->[$i{memory_used}], "\n" if $r->[$i{entry_type}] eq "selection" }' "$1/ltl-index.csv"
}
# in_order <names> <order>: yes when the comma-separated names appear in the
# comma-separated order, each at most once.
in_order() {
    awk -v names="$1" -v order="$2" 'BEGIN { n = split(order, o, ","); for (i = 1; i <= n; i++) pos[o[i]] = i
        m = split(names, s, ","); last = 0
        for (i = 1; i <= m; i++) { if (!(s[i] in pos) || pos[s[i]] <= last) { print "no (" names ")"; exit } last = pos[s[i]] }
        print (m ? "yes" : "no (no site)") }'
}

scenario_peak_consumers() {
    current_scenario="peak-consumers"
    echo "[$current_scenario]"
    mkdir -p "$TMP_DIR/consumers"
    RUN_IN="$TMP_DIR/consumers" run_ltl consumers -bs 1440 -oe -mem -o -idx -V benchmark-data,memory-usage,notices "$ACCESS_FIXTURE"
    produced consumers $'^MEMORY\trss_peak\t' 'the peak consumers' || return 0

    local peak exported
    peak=$(sed -E 's/\x1b\[[0-9;]*m//g' "$TMP_DIR/consumers.out" | sed -nE 's/^ *MAXIMUM MEMORY USED +(.*[^ ]) *$/\1/p' | head -1 || true)
    exported=$(sed -nE 's/^ *max_memory_used: *//p' "$TMP_DIR/consumers"/*.yaml 2>/dev/null | head -1 || true)
    check "MAXIMUM MEMORY USED and the export carry one value" "$peak" "${exported:-MISSING-ANCHOR}" \
        'The summary and the aggregate export report the peak read once before the summary' \
        'pipeline_render(), print_summary_table() and write_aggregate_export() in ltl' "$C_PEAK"

    local rss used
    rss=$(bench consumers MEMORY rss_peak); used=$(index_memory_used "$TMP_DIR/consumers" | head -1)
    check "the index's peak is the lifetime peak, not below rss_peak" "$([[ -n "$rss" && -n "$used" && "$rss" -gt 0 && "$used" -ge "$rss" ]] && echo yes || echo "no (rss_peak=${rss:-absent} memory_used=${used:-absent})")" "yes" \
        'rss_peak and the index memory_used each read the peak at their moment; the index is written last, so its peak is at or above rss_peak' \
        'print_verbose_output() and write_index_file() in ltl' "$C_PEAK"

    # One kept-peak reading at each reporting moment: benchmark-data, the
    # summary, the index. A run that cannot read it says so and reads none.
    local unreadable expected
    unreadable=$(notice_kind_count "$TMP_DIR/consumers.out" memory-unreadable)
    if [[ "$unreadable" == 0 ]]; then expected=3; else expected=""; fi
    check "kept-peak readings, one per reporting moment" "$(site consumers kept_peak readings)|$unreadable" "$expected|$unreadable" \
        'Where the kept peak is readable it is read once for benchmark-data, once before the summary and once for the index; where it is not, the memory-unreadable notice says so and no kept-peak reading is counted' \
        'read_run_peak_memory() and get_kept_peak_memory() in ltl' "$C_PEAK"
}

scenario_peak_not_below_readings() {
    current_scenario="peak-not-below-readings"
    echo "[$current_scenario]"
    mkdir -p "$TMP_DIR/readings"
    # -g: the grouping callers read too, so the order check sees them.
    RUN_IN="$TMP_DIR/readings" run_ltl readings -bs 1440 -oe -g -mem debug -idx -V benchmark-data "$ACCESS_FIXTURE"
    produced readings $'^decomposition\t' 'the readings against the peak' || return 0

    # benchmark-data prints after the after_normalize record and before the next.
    local rss used
    rss=$(bench readings MEMORY rss_peak); used=$(index_memory_used "$TMP_DIR/readings" | head -1)
    check "no reading before rss_peak is above it" "$(debug_records readings | awk -F'\t' -v peak="${rss:-0}" '
        $4 != "-" && !done { n++; if ($4 > peak) bad = bad " " $3 "=" $4 }
        $1 == "decomposition" && $3 == "after_normalize" { done = 1 }
        END { print (peak > 0 && n > 0 && bad == "") ? "yes" : "no (rss_peak=" peak ", readings=" n ", above:" bad ")" }')" "yes" \
        'The peak benchmark-data reports is never below a reading the run took before it' \
        'read_run_peak_memory() from print_verbose_output() in ltl' "$C_PEAK"
    check "no reading is above the index's peak" "$(debug_records readings | awk -F'\t' -v peak="${used:-0}" '
        $4 != "-" { n++; if ($4 > peak) bad = bad " " $3 "=" $4 }
        END { print (peak > 0 && n > 0 && bad == "") ? "yes" : "no (memory_used=" peak ", readings=" n ", above:" bad ")" }')" "yes" \
        'The peak the index records, read after the last diagnostic reading, is never below any reading the run took' \
        'read_run_peak_memory() from write_index_file() in ltl' "$C_PEAK"
    check "callers in the contract's order" "$(in_order "$(site_names readings)" "$SITE_ORDER")" "yes" \
        'The site lines print in the fixed order of the section contract, the kept-peak caller first' \
        'emit_memory_usage_verbose() in ltl (@memory_reading_sites)' "$C_PEAK"
}

scenario_peak_fallback() {
    current_scenario="peak-fallback"
    echo "[$current_scenario]"
    if [[ "$(uname -s)" != Darwin ]]; then
        echo "  SKIP  $current_scenario :: macOS only: BSD::Resource is read on macOS alone"
        return 0
    fi
    # An @INC hook, given at invocation, that refuses BSD::Resource.
    mkdir -p "$TMP_DIR/hide"
    printf '%s\n' 'package hide_bsd_resource;' \
        'unshift @INC, sub { die "Can'"'"'t locate BSD/Resource.pm in \@INC (hidden by the harness)\n" if $_[1] eq "BSD/Resource.pm"; return };' \
        '1;' > "$TMP_DIR/hide/hide_bsd_resource.pm"
    # Without -mem: the readings between steps are taken for the fallback alone.
    PERL5OPT="-I$TMP_DIR/hide -Mhide_bsd_resource" run_ltl hidden -bs 1440 -oe -V benchmark-data,memory-usage,notices "$ACCESS_FIXTURE"
    produced hidden $'^MEMORY\trss_peak\t' 'the fallback' || return 0

    check "the notice, once, in the panel" "$(notice_kind_count "$TMP_DIR/hidden.out" memory-unreadable)|$(notice_field "$TMP_DIR/hidden.out" memory-unreadable evidence | grep -c 'BSD::Resource module.*is not installed' || true)|$(notice_field "$TMP_DIR/hidden.out" memory-unreadable stage)|$(notice_field "$TMP_DIR/hidden.out" memory-unreadable shown)" "1|1|detect|panel" \
        'Without BSD::Resource on macOS the run raises the memory-unreadable notice once, naming the module, as the pipeline starts, and draws it in the panel rather than in the options review' \
        'resolve_kept_peak_reading() from pipeline_detect() in ltl' "$C_PEAK"
    check "the readings' peak, from the readings between steps" "$(site hidden kept_peak readings)|$(site hidden phase_boundary readings)|$([[ "$(bench hidden MEMORY rss_peak)" -gt 0 ]] && echo peak || echo no-peak)" "|5|peak" \
        'The fallback reads no kept peak; the readings between steps are taken, without -mem too, and their peak is reported' \
        'read_run_peak_memory() and measure_memory_structures() in ltl' "$C_PEAK"
}

# ---------------------------------------------------------------------------
# Without -mem no reading is taken between steps: the kept peak is read once
# at each reporting moment, and the compile readings stay where a memory
# surface armed them. Where the kept peak cannot be read (the notice says so),
# the readings between steps are the run's peak and are taken.
# -bs 1440 -oe: no check reads the time axis.
# ---------------------------------------------------------------------------
# between_steps <tag>: the phase-boundary and grouping callers listed.
between_steps() { site_names "$1" | tr ',' '\n' | awk '/^(phase_boundary|grouping_checkpoint|grouping_final_pass)$/' | paste -sd, -; }

scenario_no_mem_readings() {
    current_scenario="no-mem-readings"
    echo "[$current_scenario]"
    local tag unreadable want_steps want_peak
    for tag in plain grouped; do
        if [[ "$tag" == plain ]]; then
            run_ltl "nomem-$tag" -bs 1440 -oe -V memory-usage,notices "$ACCESS_FIXTURE"
        else
            run_ltl "nomem-$tag" -bs 1440 -oe -g -V memory-usage,notices "$ACCESS_FIXTURE"
        fi
        produced "nomem-$tag" '^=== memory-usage ===$' "readings without -mem ($tag)" || continue
        unreadable=$(notice_kind_count "$TMP_DIR/nomem-$tag.out" memory-unreadable)
        # The summary is the one reporting moment of these runs.
        if [[ "$unreadable" == 0 ]]; then want_steps=""; want_peak=1
        elif [[ "$tag" == grouped ]]; then want_steps="phase_boundary,grouping_checkpoint,grouping_final_pass"; want_peak=""
        else want_steps=phase_boundary; want_peak=""; fi
        check "no reading between steps, one kept peak ($tag)" "$(between_steps "nomem-$tag")|$(site "nomem-$tag" kept_peak readings)" "$want_steps|$want_peak" \
            'Without -mem the run takes no phase-boundary or grouping reading and reads the kept peak once, before the summary; where the kept peak is unreadable it takes the readings between steps instead' \
            'measure_memory_structures() and read_run_peak_memory() in ltl' "$C_NOMEM"
    done

    printf 'timestamp,latency\n2026-06-01 10:00:05,12\n2026-06-01 10:01:05,34\n2026-06-01 10:02:05,56\n' > "$TMP_DIR/nomem-metrics.csv"
    run_ltl nomem-csv -bs 1440 -oe -udm latency:ms:mean -V memory-usage,benchmark-data,notices "$TMP_DIR/nomem-metrics.csv"
    if produced nomem-csv '^=== memory-usage ===$' 'readings without -mem (csv)'; then
        unreadable=$(notice_kind_count "$TMP_DIR/nomem-csv.out" memory-unreadable)
        if [[ "$unreadable" == 0 ]]; then want_steps=""; want_peak=2; else want_steps=phase_boundary; want_peak=""; fi
        check "the compile readings stay, the steps take none (csv)" "$(between_steps nomem-csv)|$(site nomem-csv kept_peak readings)|$(site nomem-csv csv_block_compile readings)" "$want_steps|$want_peak|2" \
            'Without -mem, under -V benchmark-data, the CSV block compile still reads before and after, the kept peak is read for benchmark-data and the summary, and no reading is taken between steps' \
            'compile_csv_block(), measure_memory_structures() and read_run_peak_memory() in ltl' "$C_NOMEM"
    fi
}

scenario_register phase-boundary \
                  grouping \
                  compiles \
                  section-off \
                  debug \
                  debug-samples \
                  benchmark-rows \
                  memory-map \
                  peak-consumers \
                  peak-not-below-readings \
                  peak-fallback \
                  no-mem-readings
scenario_parse_args "$@"

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"; exit 1
fi
if [[ ! -f "$ACCESS_FIXTURE" ]]; then
    echo "ERROR: fixture not found: $ACCESS_FIXTURE"; exit 1
fi

TMP_DIR=$(mktemp -d); trap 'rm -rf "$TMP_DIR"' EXIT

while read -r _scenario; do
    case "$_scenario" in
        phase-boundary ) scenario_phase_boundary ;;
        grouping       ) scenario_grouping ;;
        compiles       ) scenario_compiles ;;
        section-off    ) scenario_section_off ;;
        debug          ) scenario_debug ;;
        debug-samples  ) scenario_debug_samples ;;
        benchmark-rows ) scenario_benchmark_rows ;;
        memory-map     ) scenario_memory_map ;;
        peak-consumers ) scenario_peak_consumers ;;
        peak-not-below-readings ) scenario_peak_not_below_readings ;;
        peak-fallback  ) scenario_peak_fallback ;;
        no-mem-readings ) scenario_no_mem_readings ;;
    esac
done < <(scenario_selected)

echo
echo "Results: $pass passed, $fail failed"
if [[ "$pass" -eq 0 && "$fail" -eq 0 ]]; then
    echo "FAIL: no assertion ran"
    exit 1
fi
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    printf '  %s\n' "${failures[@]}"
    exit 1
fi
exit 0
