#!/usr/bin/env bash
# validate-read-path.sh — harness for the read path: which path each file is
# read by (the generated body above the size threshold, the standard path at
# or below it and under -D), and that the generated body gives the standard
# path's output, byte for byte.
#
# The file name tracks the -V read-path section. The scenarios read that
# section; the identity scenario compares every output the read loop feeds
# (standard output with every -V section, the STATS and MESSAGES CSVs, the
# YAML aggregate export, the run index row) between --generated-loop-threshold=0
# and -D over option shapes that switch every gate marker of the loop on, and
# fails when a marker is never kept or a file falls back. Faults are injected
# into a copy of ltl in the harness's own directory, never into ltl.
#
# Inputs: 20,000-line slices of five families from the corpus (a day of
# web-server access log carrying duration and bytes; a web-server access log
# carrying thread and session; an application server log carrying thread and
# user; a script log carrying durationMS and count fields; a CSV of system
# metrics, whole). The slice above 2 MB is the large file, its first 1,000
# lines the small one.
#
# Each assertion records, per tests/HARNESS-DESIGN.md § Self-documenting
# assertions: asserts, produced_by (function name), contract. All three are
# surfaced on failure.
#
# Usage: ./tests/validate-read-path.sh [--list | --scenario NAME]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# Always the script itself, never an override: this harness chooses both paths
# explicitly, counts the markers in the source and injects faults into a copy.
LTL="$REPO_DIR/ltl"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"
# shellcheck source=lib/logs-dir.sh
source "$SCRIPT_DIR/lib/logs-dir.sh"
# shellcheck source=lib/run-dir.sh
source "$SCRIPT_DIR/lib/run-dir.sh"

neutralize_colour_env

ACCESS_LOG="$LOGS_DIR/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt"
ACCESS_TS_LOG="$LOGS_DIR/AccessLogs/localhost_access_log-twx01-twx-thingworx-4.2026-01-26.txt"
APP_LOG="$LOGS_DIR/ThingworxLogs/ApplicationLog.2025-05-05.0.log"
SCRIPT_LOG="$LOGS_DIR/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log"
METRICS_CSV="$LOGS_DIR/UDM/connection-server-custom-metrics.csv"

DOC='features/621-generated-read-loop-body.md'
C_PATH="$DOC § 6 and § 9, path choice; § 7 D1, D2"
C_OPTION="$DOC § 7 D2 and § 9, observability (a row of @quantity_options, a size with min 0)"
C_IDENTITY="$DOC § 2 (the two paths kept comparable) and § 7 D3; criterion 7"
C_COVERAGE="$DOC § 7 D3 and D7 (every marker's gate switched on at least once); criterion 7"
C_FALLBACK="$DOC § 7 D4 and D7; criterion 14"
C_EXIT="$DOC § 9, fallback and exit status; criteria 9 and 12"
C_COST="$DOC § 9 contracts (-mem and -V) and observability; criterion 10"
C_HELP="$DOC § 7 D1 and D2; criterion 6"

# The option shapes of the identity comparison: label=options@FAMILY. Every
# gate marker of the loop is kept by at least one of them. A shape with -idx
# runs without -ni; +progress runs it without --disable-progress, the one way to
# reach the progress gate.
SHAPES=(
    "default=-bs 1@ACCESS"
    "no-messages=-n 0 -bs 1@ACCESS"
    "group=-g 50 -bs 5@ACCESS"
    "grouping-section=-V message-grouping -bs 5@ACCESS"
    "heatmap-duration=-hm duration -bs 5@ACCESS"
    "heatmap-bytes-raw=-hm bytes -hmdm raw -bs 5@ACCESS"
    "histogram=-hg -bs 5@ACCESS"
    "histogram-raw=-hg -hgdm raw -bs 5@ACCESS"
    "highlight=-h Things -bs 5@ACCESS"
    "highlight-numeric=-hdmin 100 -bs 5@ACCESS"
    "highlight-failure=-hf -bs 5@ACCESS"
    "highlight-heatmap-histogram=-h Things -hm duration -hg -bs 5@ACCESS"
    "include=-i Things -bs 5@ACCESS"
    "exclude=-e Metrics -bs 5@ACCESS"
    "window-absolute=-st 2025-05-07T00:05 -et 2025-05-07T00:20 -bs 5@ACCESS"
    "window-time-of-day=-st 00:05 -et 00:20 -bs 5@ACCESS"
    "profile=-pr day -bs 5@ACCESS"
    "outcome-filter=-if -bs 5@ACCESS"
    "numeric-filter=-dmin 50 -bmax 100000 -bs 5@ACCESS"
    "duration-unit=-du us -bs 5@ACCESS"
    "bin-models=-mdm bin -bdm bin -bs 5@ACCESS"
    "csv-out=-o -bs 5@ACCESS"
    "omit-metrics=-od -ob -oc -bs 5@ACCESS"
    "milliseconds=-bs 100ms -tp ms@ACCESS"
    "nanosecond-precision=-tp ns -bs 5@ACCESS"
    "index=-idx -bs 5@ACCESS"
    "index-nanoseconds=-idx -tp ns -bs 5@ACCESS"
    "group-bin-model=-g 50 -mdm bin -bs 5@ACCESS"
    "highlight-heatmap-raw=-h Things -hm duration -hmdm raw -bs 5@ACCESS"
    "progress=+progress -bs 5@ACCESS"
    "memory-debug=-mem debug -bs 5@ACCESS"
    "mask-expose-discard=-m uuid -x query-string -d ip -bs 5@ACCESS"
    "sort-bytes=-so bytes -bs 5@ACCESS"
    "verbose-all=-V -bs 5@ACCESS"
    "ts-default=-bs 5@ACCESS_TS"
    "ts-hide-session-user=-hses -hu -bs 5@ACCESS_TS"
    "ts-threadpool=-tpa http -bs 5@ACCESS_TS"
    "ts-threadpool-summary=-tpas -bs 5@ACCESS_TS"
    "ts-expose-discard=-x session -d thread -bs 5@ACCESS_TS"
    "ts-highlight=-h Things -bs 5@ACCESS_TS"
    "ts-threadpool-highlight=-tpa http -h Things -bs 5@ACCESS_TS"
    "app-default=-bs 5@APP"
    "app-highlight-user=-h Error -bs 5@APP"
    "app-discard-user=-d user -bs 5@APP"
    "script-default=-bs 5@SCRIPT"
    "script-count=-x count -hm count -bs 5@SCRIPT"
    "script-omit-count=-oc -bs 5@SCRIPT"
    "script-udm=-udm durationMS::max -bs 5@SCRIPT"
    "script-udm-heatmap-histogram=-udm durationMS::max -hm durationMS -hg durationMS -bs 5@SCRIPT"
    "script-udm-heatmap-highlight=-udm durationMS::max -hm durationMS -h Things -bs 5@SCRIPT"
    "script-udm-group=-udm durationMS::max -g 50 -bs 5@SCRIPT"
    "csv-udm=-udm system_cpu_total -bs 5@METRICS"
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

# check <label> <actual> <expected> <asserts> <produced_by> <contract>
check() {
    if [[ -n "$2" && "$2" == "$3" ]]; then
        pass_with "$1 ($2)"
    else
        fail_with "$1" "$4" "$5" "$6" "expected: $3" "actual:   ${2:-MISSING-ANCHOR}"
    fi
}

# run_ltl <dir> <ltl> <args...>: one run in a fresh directory of its own;
# stdout, stderr and the exit code land in <dir>/out, err and rc. A Perl
# runtime warning on stderr is a failure unless EXPECT_WARNING is set. Every
# run has --disable-progress unless WITH_PROGRESS is set.
run_ltl() {
    local dir="$1" ltl="$2"; shift 2
    if ! claim_run_dir "$dir"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: run directory $dir"); return 1
    fi
    set +e
    local quiet=(--disable-progress); [[ -n "${WITH_PROGRESS:-}" ]] && quiet=()
    ( cd "$dir" && PERL_HASH_SEED=0 PERL_PERTURB_KEYS=0 "$ltl" "${quiet[@]}" --terminal-width 200 "$@" ) > "$dir/out" 2> "$dir/err"
    echo $? > "$dir/rc"
    set -e
    if [[ -z "${EXPECT_WARNING:-}" ]] && ! assert_no_runtime_warnings "$dir/err" "$current_scenario/$(basename "$dir")"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: $(basename "$dir") perl-runtime-warnings-on-stderr")
    fi
}

# section_value <out file> <key>: a top-level fact of the read-path section.
section_value() {
    awk -v key="$2" '
        /^=== read-path ===$/ { in_s = 1; next }
        /^=== END read-path ===$/ { in_s = 0 }
        in_s && index($0, key ": ") == 1 { print substr($0, length(key) + 3); exit }
    ' "$1"
}
# file_value <out file> <file> <key>: a key of one file's block.
file_value() {
    awk -v f="$2" -v key="$3" '
        /^=== read-path ===$/ { in_s = 1; next }
        /^=== END read-path ===$/ { in_s = 0 }
        in_s && /^file: / { cur = substr($0, 7) }
        in_s && cur == f && index($0, "  " key ": ") == 1 { print substr($0, length(key) + 5); exit }
    ' "$1"
}
# paths <out file>: every file's path, space-separated, in reading order.
paths() {
    awk '/^=== read-path ===$/ { in_s = 1; next } /^=== END read-path ===$/ { in_s = 0 }
         in_s && /^  path: / { printf "%s%s", sep, substr($0, 9); sep = " " }' "$1"
}

# normalise <run dir>: every output the run wrote, with what is measured per
# run (timings, memory, the echoed options) and the read-path section set
# aside, so two runs of one shape compare byte for byte. Colour escapes are
# kept: a highlight renders through colour, so stripping them would hide it.
normalise() {
    local dir="$1" f
    perl -ne '
        my $plain = $_; $plain =~ s/\e\[[0-9;]*m//g;
        if ($plain =~ /^=== read-path ===$/ .. $plain =~ /^=== END read-path ===$/) { next }
        next if $plain =~ /command-line options|TOTAL TIME|MAXIMUM MEMORY USED|^(TIMING|MEMORY)\t|^\s*(sample_us|total_time|max_memory_used): |^scan_subs_rss_bytes: /;
        next if $plain =~ /\(\s*(?:<1|\d+)%\)\s+[\d.]+ (?:B|kB|MB|GB)\s*$/;
        print;
    ' "$dir/out"
    for f in "$dir"/*-LTL-*; do
        [[ -e "$f" ]] || continue
        echo "### $(basename "$f" | sed -E 's/^.*-LTL-([A-Z]+).*/\1/')"
        grep -vE '^\s*(command-line|generated_at|total_time|max_memory_used):' "$f"
    done
    if [[ -e "$dir/ltl-index.csv" ]]; then
        echo "### ltl-index.csv"
        perl -F, -lane 'if ($. == 1) { @keep = grep { $F[$_] !~ /^(entry_date|read_rate|memory_used|processing_time)$/ } 0 .. $#F } print join(",", @F[@keep])' "$dir/ltl-index.csv"
    fi
}

# altered_ltl <dir> <name> <perl substitution over the loop's lines>: a copy
# of ltl with one change inside the per-line loop; fails when nothing changed.
altered_ltl() {
    local dir="$1" name="$2" edit="$3"
    perl -e '
        my ($src, $edit) = @ARGV; open my $f, "<", $src or die; my @l = <$f>;
        my ($in, $loop, $done) = (0, 0, 0);
        for (@l) {
            $in = 1 if /^sub read_and_process_logs \{/;
            $loop = 1 if $in && /^        while \(1\) \{$/;
            if ($loop && !$done) { my $was = $_; eval $edit; die $@ if $@; $done = 1 if $_ ne $was }
        }
        die "altered_ltl: the edit changed nothing\n" unless $done;
        print @l;' "$LTL" "$edit" > "$dir/$name"
    chmod +x "$dir/$name"
}

# ---------------------------------------------------------------------------
scenario_paths_by_size() {
    current_scenario="paths-by-size"
    echo "[$current_scenario]"
    local d="$TMP_DIR/$current_scenario" size
    size=$(wc -c < "$SMALL" | tr -d ' ')
    run_ltl "$d/default" "$LTL" -ni -bs 5 -V read-path "$SMALL" "$LARGE"
    check "default threshold" "$(section_value "$d/default/out" threshold_bytes)" "2097152 (default)" \
        'With no option the threshold is 2,097,152 bytes' 'emit_read_path_verbose() in ltl' "$C_PATH"
    check "small file at the default" "$(file_value "$d/default/out" "$SMALL" path)|$(file_value "$d/default/out" "$SMALL" reason)" "standard|at_or_below_threshold" \
        'A file at or below the threshold takes the standard path' 'read_path_wants_generated() in ltl' "$C_PATH"
    check "large file at the default" "$(file_value "$d/default/out" "$LARGE" path)|$(file_value "$d/default/out" "$LARGE" reason)" "generated|above_threshold" \
        'A file above the threshold takes the generated body' 'read_path_wants_generated() in ltl' "$C_PATH"
    run_ltl "$d/at" "$LTL" -ni -bs 5 --generated-loop-threshold="$size" -V read-path "$SMALL"
    check "a file exactly at the threshold" "$(file_value "$d/at/out" "$SMALL" path)" "standard" \
        'The comparison is strictly above: a file of N bytes at threshold N takes the standard path' 'read_path_wants_generated() in ltl' "$C_PATH"
    run_ltl "$d/above" "$LTL" -ni -bs 5 --generated-loop-threshold="$((size - 1))" -V read-path "$SMALL"
    check "a file one byte above the threshold" "$(file_value "$d/above/out" "$SMALL" path)" "generated" \
        'A file of N bytes at threshold N-1 takes the generated body' 'read_path_wants_generated() in ltl' "$C_PATH"
    run_ltl "$d/zero" "$LTL" -ni -bs 5 --generated-loop-threshold=0 -V read-path "$SMALL" "$LARGE"
    check "threshold 0" "$(paths "$d/zero/out")|$(section_value "$d/zero/out" threshold_bytes)" "generated generated|0 (option)" \
        'With the threshold at 0 every file with a line takes the generated body' 'read_path_wants_generated() in ltl' "$C_PATH"
    run_ltl "$d/all-standard" "$LTL" -ni -bs 5 -D -V read-path "$SMALL" "$LARGE"
    if diff -q <(normalise "$d/default") <(normalise "$d/all-standard") > /dev/null; then
        pass_with "mixed sizes: output equals an all-standard run"
    else
        fail_with "mixed sizes: output equals an all-standard run" 'A run over files on different paths gives the all-standard output' 'read_and_process_logs() in ltl' "$C_IDENTITY" \
            "diff: $(diff <(normalise "$d/default") <(normalise "$d/all-standard") | head -5 | tr '\n' ' ')"
    fi
}

scenario_forced_standard() {
    current_scenario="forced-standard"
    echo "[$current_scenario]"
    local d="$TMP_DIR/$current_scenario"
    run_ltl "$d/run" "$LTL" -ni -bs 5 -D --generated-loop-threshold=0 -V read-path "$SMALL" "$LARGE"
    check "-D over threshold 0" "$(paths "$d/run/out")|$(section_value "$d/run/out" standard_path_forced)|$(section_value "$d/run/out" generated_text)" "standard standard|yes|not_needed" \
        'Under -D every file takes the standard path and no body is written, whatever the threshold' 'read_path_wants_generated() in ltl' "$C_PATH"
    check "-D reason" "$(file_value "$d/run/out" "$LARGE" reason)" "forced_standard" \
        'A file -D sends to the standard path records why' 'read_path_wants_generated() in ltl' "$C_PATH"
}

scenario_threshold_values() {
    current_scenario="threshold-values"
    echo "[$current_scenario]"
    local d="$TMP_DIR/$current_scenario" v
    for v in -1 1.5 abc 2k; do
        run_ltl "$d/v$v" "$LTL" -ni --generated-loop-threshold="$v" "$SMALL"
        check "--generated-loop-threshold=$v refused" "$(cat "$d/v$v/rc")|$(grep -c "Invalid --generated-loop-threshold '$v'" "$d/v$v/err")" "1|1" \
            'A threshold that is not a non-negative whole byte size stops the run with an error naming the option' 'resolve_quantity_option() in ltl' "$C_OPTION"
    done
    run_ltl "$d/unit" "$LTL" -ni -bs 5 --generated-loop-threshold=2MB -V read-path "$SMALL"
    check "a byte unit" "$(section_value "$d/unit/out" threshold_bytes)" "2000000 (option)" \
        'The threshold is a byte size and reads a byte unit' 'resolve_quantity_option() in ltl' "$C_OPTION"
}

scenario_identity() {
    current_scenario="identity"
    echo "[$current_scenario]"
    local d="$TMP_DIR/$current_scenario" shape label rest opts family file diffs=0 kept_file="$TMP_DIR/kept-markers"
    : > "$kept_file"
    for shape in "${SHAPES[@]}"; do
        label="${shape%%=*}"; rest="${shape#*=}"; opts="${rest%@*}"; family="${rest##*@}"
        file="${SLICE[$family]}"
        local progress="" ni=-ni
        [[ " $opts " == *" +progress "* ]] && { progress=1; opts="${opts/+progress /}"; }
        [[ " $opts " == *" -idx "* ]] && ni=
        # shellcheck disable=SC2086
        WITH_PROGRESS=$progress run_ltl "$d/$label/generated" "$LTL" $ni --generated-loop-threshold=0 $opts -V read-path "$file"
        # shellcheck disable=SC2086
        WITH_PROGRESS=$progress run_ltl "$d/$label/standard" "$LTL" $ni -D --generated-loop-threshold=0 $opts -V read-path "$file"
        if [[ "$(paths "$d/$label/generated/out")|$(section_value "$d/$label/generated/out" generated_text)" != "generated|written" ]]; then
            fail_with "$label: the generated body read the file" 'With the threshold at 0 the file is read by the generated body, not a fallback' 'read_path_text() in ltl' "$C_IDENTITY" \
                "paths: $(paths "$d/$label/generated/out") generated_text: $(section_value "$d/$label/generated/out" generated_text) fallback_reason: $(section_value "$d/$label/generated/out" fallback_reason)"
            continue
        fi
        sed -n 's/^marker: \([0-9]*\) op=[a-z]* kept=yes$/\1/p' "$d/$label/generated/out" >> "$kept_file"
        if [[ "$(cat "$d/$label/generated/rc")" != "$(cat "$d/$label/standard/rc")" ]] \
           || ! diff -q <(normalise "$d/$label/generated") <(normalise "$d/$label/standard") > /dev/null; then
            diffs=$((diffs + 1))
            fail_with "$label: generated output equals standard output" 'The generated body gives the standard path'"'"'s output for this option shape' 'read_and_process_logs() in ltl' "$C_IDENTITY" \
                "options: $opts" "exit: $(cat "$d/$label/generated/rc") vs $(cat "$d/$label/standard/rc")" \
                "diff: $(diff <(normalise "$d/$label/generated") <(normalise "$d/$label/standard") | head -6 | tr '\n' ' ')"
        fi
    done
    [[ "$diffs" -eq 0 ]] && pass_with "${#SHAPES[@]} option shapes: generated output equals standard output"

    # Every marker of the loop, counted from the source, is kept by a shape.
    local all missing
    all=$(perl -ne '$in = 1 if /^sub read_and_process_logs \{/; $loop = 1 if $in && /^        while \(1\) \{$/; last if $loop && /^        close \$fh;/; print "$.\n" if $loop && /^\s*#\@(when|and|unless|true|false)\s/' "$LTL")
    if [[ -z "$all" ]]; then
        fail_with "markers counted from the source" 'The per-line loop carries gate markers' 'the #@ markers in read_and_process_logs() in ltl' "$C_COVERAGE" "no marker found"
        return
    fi
    missing=$(comm -23 <(sort -u <<< "$all") <(sort -u "$kept_file") | tr '\n' ' ')
    if [[ -z "$missing" ]]; then
        pass_with "every marker kept by a shape ($(wc -l <<< "$all" | tr -d ' ') markers)"
    else
        fail_with "every marker kept by a shape" 'Each gate marker keeps its code in the generated body for at least one shape, so a marker naming the wrong value cannot drop output unseen' 'generated_loop_text() in ltl' "$C_COVERAGE" \
            "markers never kept (source lines): $missing"
    fi
}

scenario_generation_cost() {
    current_scenario="generation-cost"
    echo "[$current_scenario]"
    local d="$TMP_DIR/$current_scenario" g s
    run_ltl "$d/generated" "$LTL" -ni -bs 5 --generated-loop-threshold=0 -V format-registry,benchmark-data "$LARGE"
    run_ltl "$d/standard" "$LTL" -ni -bs 5 -D -V format-registry,benchmark-data "$LARGE"
    check "scan-sub compiles alike" "$(sed -n 's/^scan_subs_compiled: //p' "$d/generated/out")" "$(sed -n 's/^scan_subs_compiled: //p' "$d/standard/out")" \
        'The generated body compiles no format scan sub of its own' 'format_scan_sub_resolve() in ltl' "$C_COST"
    g=$(awk -F'\t' '$1 == "TIMING" && $2 == "read/path_generation" { print $3 }' "$d/generated/out")
    s=$(awk -F'\t' '$1 == "TIMING" && $2 == "read/path_generation" { print $3 }' "$d/standard/out")
    check "generation timed in its own row" "$( [[ -n "$g" && -n "$s" ]] && perl -e 'print $ARGV[0] > 0 && $ARGV[1] == 0 ? "yes" : "no"' "$g" "$s")" "yes" \
        'Writing and compiling the body is reported as TIMING read/path_generation: above zero on the generated path, zero under -D' 'read_path_text() in ltl' "$C_COST"
}

scenario_fallback() {
    current_scenario="fallback"
    echo "[$current_scenario]"
    local d="$TMP_DIR/$current_scenario"
    mkdir -p "$d"
    # The term of an `and` marker renamed, so it no longer matches its condition.
    altered_ltl "$d" ltl-altered 's/^(\s*#\@and )!\$disable_progress$/$1!\$disable_progress_renamed/'
    run_ltl "$d/fallback" "$d/ltl-altered" -ni -bs 5 --generated-loop-threshold=0 -V read-path "$SMALL" "$LARGE"
    run_ltl "$d/standard" "$d/ltl-altered" -ni -bs 5 -D -V read-path "$SMALL" "$LARGE"
    check "a mismatched marker falls back" "$(section_value "$d/fallback/out" generated_text)|$(section_value "$d/fallback/out" fallback_reason)|$(paths "$d/fallback/out")" "failed|marker_mismatch|standard standard" \
        'A marker that does not find its term stops generation and every file takes the standard path' 'generated_loop_text() in ltl' "$C_FALLBACK"
    check "fallback reason per file" "$(file_value "$d/fallback/out" "$LARGE" reason)" "fallback" \
        'A file that fell back records it' 'read_path_fall_back() in ltl' "$C_FALLBACK"
    check "one notice for the run" "$(grep -c '^Note: the faster read path could not be prepared' "$d/fallback/err")" "1" \
        'The fallback notice prints once a run on stderr, however many files fell back' 'read_path_fall_back() in ltl' "$C_FALLBACK"
    if diff -q <(normalise "$d/fallback") <(normalise "$d/standard") > /dev/null; then
        pass_with "fallback output equals -D output"
    else
        fail_with "fallback output equals -D output" 'A fallback loses speed, never output' 'read_and_process_logs() in ltl' "$C_FALLBACK" \
            "diff: $(diff <(normalise "$d/fallback") <(normalise "$d/standard") | head -5 | tr '\n' ' ')"
    fi
}

scenario_exit_and_line() {
    current_scenario="exit-and-line"
    echo "[$current_scenario]"
    local d="$TMP_DIR/$current_scenario" line g s
    mkdir -p "$d"
    altered_ltl "$d" ltl-die 's/^(        while \(1\) \{\n)$/$1            die "read-path probe" if \$line_number == 5;\n/'
    altered_ltl "$d" ltl-warn 's/^(        while \(1\) \{\n)$/$1            my \$probe_undef; my \$probe_text = "x" . \$probe_undef if \$line_number == 5;\n/'
    line=$(grep -n 'read-path probe' "$d/ltl-die" | cut -d: -f1)
    EXPECT_WARNING=1 run_ltl "$d/die-generated" "$d/ltl-die" -ni -bs 5 --generated-loop-threshold=0 "$SMALL"
    EXPECT_WARNING=1 run_ltl "$d/die-standard" "$d/ltl-die" -ni -bs 5 -D "$SMALL"
    g="$(cat "$d/die-generated/rc")|$(grep -o "read-path probe at [^ ]* line [0-9]*" "$d/die-generated/err" | sed 's/ at .*\/\([^/]*\) line / at \1 line /')"
    s="$(cat "$d/die-standard/rc")|$(grep -o "read-path probe at [^ ]* line [0-9]*" "$d/die-standard/err" | sed 's/ at .*\/\([^/]*\) line / at \1 line /')"
    check "a die exits alike" "$g" "$s" \
        'A die in the generated body exits with the status and message it has on the standard path' 'read_path_text() and read_and_process_logs() in ltl' "$C_EXIT"
    check "a die names its source line" "${g#*line }" "$line" \
        'The generated body reports a die at the statement'"'"'s source line' 'read_path_text() in ltl (#line directive)' "$C_EXIT"
    line=$(grep -n 'probe_undef; my' "$d/ltl-warn" | cut -d: -f1)
    EXPECT_WARNING=1 run_ltl "$d/warn-generated" "$d/ltl-warn" -ni -bs 5 --generated-loop-threshold=0 "$SMALL"
    check "a warning names its source line" "$(grep -o 'uninitialized value \$probe_undef in concatenation (.) or string at [^ ]* line [0-9]*' "$d/warn-generated/err" | sed 's/.* line //')" "$line" \
        'A warning raised in the generated body names the statement'"'"'s source line' 'read_path_text() in ltl (#line directive)' "$C_EXIT"
}

scenario_help_rows() {
    current_scenario="help-rows"
    echo "[$current_scenario]"
    local help
    help=$("$LTL" --help 2>&1 | sed -E 's/\x1b\[[0-9;]*m//g')
    check "-D in --help" "$(grep -cE '^\s*-D, +--debug ' <<< "$help")" "1" \
        '-D, --debug has a --help row' 'print_help() in ltl' "$C_HELP"
    check "-D in docs/usage.md" "$(grep -c '^| `-D, --debug` |' "$REPO_DIR/docs/usage.md")" "1" \
        '-D, --debug has a docs/usage.md row' 'docs/usage.md' "$C_HELP"
    check "the threshold hidden" "$(grep -c 'generated-loop-threshold' <<< "$help")|$(grep -c 'generated-loop-threshold' "$REPO_DIR/docs/usage.md")" "0|0" \
        '--generated-loop-threshold is hidden: in neither --help nor docs/usage.md' 'print_help() in ltl, docs/usage.md' "$C_HELP"
}

scenario_register paths-by-size \
                  forced-standard \
                  threshold-values \
                  identity \
                  generation-cost \
                  fallback \
                  exit-and-line \
                  help-rows
scenario_parse_args "$@"

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"; exit 1
fi
for _log in "$ACCESS_LOG" "$ACCESS_TS_LOG" "$APP_LOG" "$SCRIPT_LOG" "$METRICS_CSV"; do
    if [[ ! -f "$_log" ]]; then
        echo "ERROR: corpus file not found: $_log"; exit 1
    fi
done

TMP_DIR=$(mktemp -d); trap 'rm -rf "$TMP_DIR"' EXIT

declare -A SLICE
head -20000 "$ACCESS_LOG"    > "$TMP_DIR/access.txt";    SLICE[ACCESS]="$TMP_DIR/access.txt"
head -20000 "$ACCESS_TS_LOG" > "$TMP_DIR/access-ts.txt"; SLICE[ACCESS_TS]="$TMP_DIR/access-ts.txt"
head -20000 "$APP_LOG"       > "$TMP_DIR/app.txt";       SLICE[APP]="$TMP_DIR/app.txt"
head -20000 "$SCRIPT_LOG"    > "$TMP_DIR/script.txt";    SLICE[SCRIPT]="$TMP_DIR/script.txt"
cp "$METRICS_CSV" "$TMP_DIR/metrics.csv";                SLICE[METRICS]="$TMP_DIR/metrics.csv"
LARGE="${SLICE[ACCESS]}"
SMALL="$TMP_DIR/small.txt"
head -1000 "$LARGE" > "$SMALL"
if (( $(wc -c < "$LARGE") <= 2097152 || $(wc -c < "$SMALL") > 2097152 )); then
    echo "ERROR: the large slice must be above 2 MB and the small one at or below it"; exit 1
fi

while read -r _scenario; do
    case "$_scenario" in
        paths-by-size    ) scenario_paths_by_size ;;
        forced-standard  ) scenario_forced_standard ;;
        threshold-values ) scenario_threshold_values ;;
        identity         ) scenario_identity ;;
        generation-cost  ) scenario_generation_cost ;;
        fallback         ) scenario_fallback ;;
        exit-and-line    ) scenario_exit_and_line ;;
        help-rows        ) scenario_help_rows ;;
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
