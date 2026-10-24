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
# Every run passes -mem: on Windows a run without it takes no reading, so the
# counts asserted here would not be reached there.
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

neutralize_colour_env

# Twelve lines of a combined-format web-server access log.
ACCESS_FIXTURE="$REPO_DIR/tests/fixtures/format-detection/access-combined.txt"

DOC='features/memory-tracking-improvements.md'
C_SECTION="$DOC § -V memory-usage section contract; criterion 8"
C_GATE="$DOC § -V memory-usage section contract (the activation flag); criteria 9 and 17"
C_DEBUG="$DOC § Decisions D5, D6 and the section contract; criteria 10 and 11"
C_BENCH="$DOC § -V memory-usage section contract (benchmark-data); criterion 12"

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

# run_ltl <tag> <args...>: one ltl run in the harness's own directory; stdout
# and stderr land in $TMP_DIR/<tag>.out and .err, the exit status in .rc. A
# Perl runtime warning on stderr, a non-zero exit, or an empty standard output
# is a failure.
run_ltl() {
    local tag="$1"; shift
    local rc=0
    ( cd "$TMP_DIR" && "$LTL" --disable-progress -ni "$@" ) > "$TMP_DIR/$tag.out" 2> "$TMP_DIR/$tag.err" || rc=$?
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

scenario_register phase-boundary \
                  grouping \
                  compiles \
                  section-off \
                  debug \
                  debug-samples \
                  benchmark-rows
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
