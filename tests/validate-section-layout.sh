#!/usr/bin/env bash
# validate-section-layout.sh — the `-V section-layout` report against the rows
# ltl prints (Issue #597, features/597-section-visibility.md).
#
# A render-invariant harness (tests/HARNESS-DESIGN.md § Render-invariant
# harnesses) whose expected side is read from -V: `section-layout` reports where
# each output section starts and how many rows it has, and the checker
# (tests/section-layout/check-section-layout.pl) holds that report against the
# standard output of the same run. Three kinds of check:
#
#   accounting  every row of standard output is placed: -V ranges, the sections
#               at their reported rows, one blank separator between two rendered
#               sections, and the one blank row closing the run (D5, D14)
#   anchor      known static text sits at a fixed offset from a reported start
#               row, under each section's variability (D4)
#   state       a section or part is reported rendered, hidden or absent (D13)
#
# Every run pins --terminal-width so column positions are deterministic, and
# captures standard error apart from standard output (D12).
#
# Each assertion records asserts / produced_by / contract, surfaced on failure
# (tests/HARNESS-DESIGN.md § Self-documenting assertions).
#
# Usage: ./tests/validate-section-layout.sh [--scenario NAME] [--list]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"
CHECKER="$SCRIPT_DIR/section-layout/check-section-layout.pl"
# Homebrew Perl only, never the system Perl (build/macos-setup.sh installs it).
PERL="${PERL:-/opt/homebrew/bin/perl}"
WIDTH=160

# Invocation shape (tests/HARNESS-DESIGN.md § Invocation coherence): the report
# and the rows it describes are the subject, so each run is a small committed
# access log with only the options that give a section its variability. The
# timeline is part of every layout; a day-sized or two-hour bucket keeps it to
# a handful of rows.
THREAD_LOG="$REPO_DIR/tests/fixtures/format-detection/access-thread-session.txt"   # 12 lines, one day, thread and session
SPREAD_LOG="$REPO_DIR/tests/fixtures/tomcat-access-duration-spread.txt"             # 434 lines over 14.5 h, durations and 4xx/5xx
MULTI_LOGS=(
    "$REPO_DIR/tests/fixtures/progress-multi-file/part-1.txt"
    "$REPO_DIR/tests/fixtures/progress-multi-file/part-2.txt"
    "$REPO_DIR/tests/fixtures/progress-multi-file/part-3.txt"
)

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/rendered-output.sh
source "$SCRIPT_DIR/lib/rendered-output.sh"
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"

neutralize_colour_env

for f in "$PERL" "$LTL" "$CHECKER" "$THREAD_LOG" "$SPREAD_LOG" "${MULTI_LOGS[@]}"; do
    [[ -e "$f" ]] || { echo "ERROR: required file not found: $f"; exit 1; }
done

TMP_DIR=$(mktemp -d); trap 'rm -rf "$TMP_DIR"' EXIT

pass=0
fail=0
failures=()
current_scenario=""

CONTRACT="features/597-section-visibility.md § D3, D5, D6, D13, D14"

# Run ltl in its own directory, standard output and standard error captured
# apart. Fails the scenario on a non-zero exit, an empty capture, a runtime
# warning or a soft-wrapped row. Usage: run_ltl <tag> <ltl-args...>
# The capture lands at $TMP_DIR/<tag>/out, standard error at .../err.
# SOFT_WRAP_CHECK=0 skips the soft-wrap check for a capture whose rows are
# painted over in place with carriage returns (the progress rows): the check
# measures every byte of a row, the terminal shows only the last paint.
run_ltl() {
    local tag="$1"; shift
    local dir="$TMP_DIR/$tag"
    mkdir -p "$dir"
    set +e
    ( cd "$dir" && "$LTL" -ni --terminal-width "$WIDTH" "$@" > out 2> err )
    local rc=$?
    set -e
    if [[ "$rc" -ne 0 ]]; then
        echo "  FAIL  $current_scenario :: ltl exited $rc ($tag)"
        sed 's/^/        | /' "$dir/err"
        fail=$((fail + 1)); failures+=("$current_scenario :: ltl exited $rc"); return 1
    fi
    if [[ ! -s "$dir/out" ]]; then
        echo "  FAIL  $current_scenario :: standard output is empty ($tag)"
        fail=$((fail + 1)); failures+=("$current_scenario :: empty capture"); return 1
    fi
    if ! assert_no_runtime_warnings "$dir/err" "$current_scenario"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr"); return 1
    fi
    if [[ "${SOFT_WRAP_CHECK:-1}" != 0 ]] && ! assert_no_soft_wrap "$dir/out" "$WIDTH" "$current_scenario"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: soft-wrapped row"); return 1
    fi
}

capture() { echo "$TMP_DIR/$1/out"; }

# The section-layout row for NAME is present in both captures and identical.
# Usage: same_layout_row <name> <capture-a> <capture-b>
same_layout_row() {
    local name="$1" a b
    a=$(grep "^$name"$'\t' "$2") || { echo "no $name row in $2"; return 1; }
    b=$(grep "^$name"$'\t' "$3") || { echo "no $name row in $3"; return 1; }
    [[ "$a" == "$b" ]] || { printf 'differ:\n  %s\n  %s\n' "$a" "$b"; return 1; }
}

# The checker as a command string for assert_command. Usage: checker_cmd <mode> <args...>
checker_cmd() {
    printf '%q ' "$PERL" "$CHECKER" "$@"
}

# Self-documenting assertion (tests/HARNESS-DESIGN.md § When the assertion
# isn't a simple line grep): runs `command`; PASS on exit 0.
assert_command() {
    local command label asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            command)     command="$2";     shift 2 ;;
            label)       label="$2";       shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_command: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${command:?assert_command requires command}"
    : "${label:?assert_command requires label}"
    : "${asserts:?assert_command requires asserts}"
    : "${produced_by:?assert_command requires produced_by}"
    : "${contract:?assert_command requires contract}"

    local cmd_out cmd_rc
    set +e
    cmd_out=$(eval "$command" 2>&1); cmd_rc=$?
    set -e
    if [[ "$cmd_rc" -eq 0 ]]; then
        echo "  PASS  $current_scenario :: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario :: $label"
        echo "        command:     $command"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        echo "$cmd_out" | sed 's/^/        | /'
        fail=$((fail + 1))
        failures+=("$current_scenario :: $label")
    fi
}

assert_accounting() {
    local tag="$1"
    assert_command \
        command     "$(checker_cmd accounting "$(capture "$tag")")" \
        label       "every row of standard output is placed ($tag)" \
        asserts     'With the -V ranges removed, standard output is exactly the rendered sections at their reported start rows and row counts, one blank row between two rendered sections, and the one blank row closing the run: nothing unplaced, nothing claimed twice' \
        produced_by 'open_section(), open_part() and LTL::RowCounter record; print_section_layout() reports; each print_* section printer prints, in ltl' \
        contract    "$CONTRACT"
}

# Usage: assert_anchor <tag> <section> <offset> <text> <printer>
assert_anchor() {
    local tag="$1" section="$2" offset="$3" text="$4" printer="$5"
    assert_command \
        command     "$(checker_cmd anchor "$(capture "$tag")" "$section" "$offset" "$text")" \
        label       "'$text' at $section + $offset ($tag)" \
        asserts     "The row at offset $offset from the start row -V section-layout reports for $section holds the static text '$text'" \
        produced_by "open_section() / open_part() record the start; $printer prints the row, in ltl" \
        contract    "features/597-section-visibility.md § D4, D13"
}

# Usage: assert_state <tag> <name> <state> [rows]
assert_state() {
    local tag="$1" name="$2" state="$3" rows="${4:-}"
    assert_command \
        command     "$(checker_cmd state "$(capture "$tag")" "$name" "$state" ${rows:+"$rows"})" \
        label       "$name reported $state${rows:+ with $rows rows} ($tag)" \
        asserts     "-V section-layout reports $name as $state${rows:+ with $rows rows}; a section that is not rendered carries no start or row count" \
        produced_by 'section_state() and print_section_layout() in ltl' \
        contract    "features/597-section-visibility.md § D7, D13, D17"
}

scenario_register \
    layout-baseline \
    layout-highlight-split \
    layout-many-files \
    layout-memory \
    layout-heatmap \
    histogram-verbose-on-off \
    layout-no-match \
    layout-environment-options \
    states-absent-and-hidden \
    verbose-removed-matches-plain \
    progress-rendered \
    datetime-warning-stderr
scenario_parse_args "$@"

echo "Section layout (-V section-layout) against standard output, width $WIDTH"
echo ""

# Every section a small run can show: timeline, histogram, options, messages,
# thread pools, summary.
if scenario_wanted layout-baseline; then
    current_scenario=layout-baseline
    if run_ltl base --disable-progress -bs 1440 -hg duration -n 3 -tpas -V section-layout "$THREAD_LOG"; then
        assert_accounting base
        assert_anchor base title 2 'log timeline' 'print_title()'
        assert_anchor base timeline 1 'timestamp' 'print_bar_graph()'
        assert_anchor base histogram 0 'Distribution' 'print_histograms()'
        assert_anchor base histogram last 'P50:' 'print_histograms()'
        assert_anchor base options 0 'command-line options:' 'print_run_options()'
        assert_anchor base messages-overall 0 'TOP OVERALL MESSAGES' 'print_message_summary()'
        assert_anchor base threadpools-overall 0 'TOP OVERALL THREAD POOLS' 'print_threadpool_summary()'
        assert_anchor base summary 1 'Category' 'print_summary_table()'
        assert_anchor base summary-files last-2 'Log Formats' 'print_summary_table()'
    fi
    echo ""
fi

# A highlight splits the messages table in two; a histogram height given on
# the command line changes the histogram's row count.
if scenario_wanted layout-highlight-split; then
    current_scenario=layout-highlight-split
    if run_ltl split --disable-progress -bs 120 -h ' 404 ' -n 4 -hg duration -hgh 12 -V section-layout "$SPREAD_LOG"; then
        assert_accounting split
        assert_state split messages-highlighted rendered
        assert_anchor split messages-highlighted 0 'TOP HIGHLIGHTED MESSAGES' 'print_message_summary()'
        assert_anchor split messages-overall 0 'TOP OVERALL MESSAGES' 'print_message_summary()'
        assert_anchor split histogram 0 'Distribution' 'print_histograms()'
        assert_anchor split histogram last 'P50:' 'print_histograms()'
    fi
    echo ""
fi

# Many files lengthen the summary's file list past its values column.
if scenario_wanted layout-many-files; then
    current_scenario=layout-many-files
    if run_ltl files --disable-progress -bs 1440 -lf access_common_duration -n 2 -V section-layout "${MULTI_LOGS[@]}"; then
        assert_accounting files
        assert_anchor files summary-files 1 'These file(s) were processed' 'print_summary_table()'
        assert_anchor files summary-files last-2 'Log Formats' 'print_summary_table()'
        assert_anchor files summary-values last '───' 'print_summary_table()'
    fi
    echo ""
fi

# The memory option adds one summary row per measured structure.
if scenario_wanted layout-memory; then
    current_scenario=layout-memory
    if run_ltl memory --disable-progress -bs 120 -mem -t -n 2 -V section-layout "$SPREAD_LOG"; then
        assert_accounting memory
        assert_anchor memory summary-values last '───' 'print_summary_table()'
        assert_anchor memory summary 1 'Category' 'print_summary_table()'
    fi
    echo ""
fi

# A heatmap column in the timeline, and two histograms side by side.
if scenario_wanted layout-heatmap; then
    current_scenario=layout-heatmap
    if run_ltl heatmap --disable-progress -bs 120 -hm duration -hg duration -hg bytes -n 2 -V section-layout "$SPREAD_LOG"; then
        assert_accounting heatmap
        assert_anchor heatmap timeline 1 'timestamp' 'print_bar_graph()'
        assert_anchor heatmap histogram 0 'Distribution' 'print_histograms()'
        assert_anchor heatmap histogram last 'P50:' 'print_histograms()'
    fi
    echo ""
fi

# The histogram prints its percentile-ticks -V section directly after its rows,
# inside the output rather than with the other -V sections. The sections below
# it start on the same rows whether its -V sections print or not (D3, D6, D14).
if scenario_wanted histogram-verbose-on-off; then
    current_scenario=histogram-verbose-on-off
    if run_ltl hgoff --disable-progress -bs 120 -h ' 404 ' -n 4 -hg duration -V section-layout "$SPREAD_LOG" \
       && run_ltl hgon --disable-progress -bs 120 -h ' 404 ' -n 4 -hg duration -V all "$SPREAD_LOG"; then
        assert_accounting hgoff
        assert_accounting hgon
        assert_command \
            command     "grep -q '^=== histogram-percentile-ticks ===' $(printf '%q' "$(capture hgon)")" \
            label       'the histogram percentile-ticks -V section printed (hgon)' \
            asserts     'The run requesting the histogram -V sections prints histogram-percentile-ticks, so the comparison below has -V output inside the rendered sections to leave out' \
            produced_by 'emit_histogram_tick_inputs_verbose() from print_histograms() in ltl' \
            contract    'tests/HARNESS-DESIGN.md § Reserved section names (histogram-percentile-ticks)'
        for name in histogram options messages messages-highlighted messages-overall summary; do
            assert_command \
                command     "same_layout_row $name $(printf '%q' "$(capture hgon)") $(printf '%q' "$(capture hgoff)")" \
                label       "$name reported on the same rows with the histogram -V sections on and off" \
                asserts     "-V section-layout reports $name with the same state, start and rows whether or not the histogram's -V sections print" \
                produced_by 'LTL::RowCounter and open_section() in ltl: rows between === delimiters are not counted' \
                contract    'features/597-section-visibility.md § D3, D6, D14'
        done
    fi
    echo ""
fi

# No line matched: the timeline is the one row saying so.
if scenario_wanted layout-no-match; then
    current_scenario=layout-no-match
    if run_ltl nomatch --disable-progress -bs 120 -i NOTHING-MATCHES-THIS -n 2 -V section-layout "$SPREAD_LOG"; then
        assert_accounting nomatch
        assert_state nomatch timeline rendered 1
        assert_anchor nomatch timeline 0 'no lines matched' 'print_bar_graph()'
    fi
    echo ""
fi

# LTL_CONFIG adds the environment options row above the command-line one.
if scenario_wanted layout-environment-options; then
    current_scenario=layout-environment-options
    if LTL_CONFIG='-n 2' run_ltl envopts --disable-progress -bs 120 -V section-layout "$SPREAD_LOG"; then
        assert_accounting envopts
        assert_state envopts options rendered 2
        assert_anchor envopts options 0 'environment options:' 'print_run_options()'
        assert_anchor envopts options 1 'command-line options:' 'print_run_options()'
    fi
    echo ""
fi

# A section turned off is hidden, with its parts; one the run produced nothing
# for is absent. --disable-progress hides progress (D9), -osum the summary
# (D20); -n 0 retains no message and no thread-pool table.
if scenario_wanted states-absent-and-hidden; then
    current_scenario=states-absent-and-hidden
    if run_ltl nomsg --disable-progress -bs 120 -n 0 -V section-layout "$SPREAD_LOG"; then
        assert_accounting nomsg
        assert_state nomsg progress hidden
        assert_state nomsg histogram absent
        assert_state nomsg messages absent
        assert_state nomsg messages-highlighted absent
        assert_state nomsg messages-overall absent
        assert_state nomsg threadpools absent
        assert_state nomsg threadpools-overall absent
    fi
    if run_ltl nosum --disable-progress -bs 120 -n 2 -osum -V section-layout "$SPREAD_LOG"; then
        assert_accounting nosum
        assert_state nosum summary hidden
        assert_state nosum summary-values hidden
        assert_state nosum summary-files hidden
    fi
    echo ""
fi

# -V prints nothing outside its delimiters, wherever a section prints (after the
# histogram, after the summary): with its ranges removed, a run prints the rows
# of the same run without -V, so a position read from a -V probe applies to the
# plain run (D6, D14). -o puts the aggregate-export section after the summary.
if scenario_wanted verbose-removed-matches-plain; then
    current_scenario=verbose-removed-matches-plain
    if run_ltl withv --disable-progress -bs 1440 -g -hg duration -n 3 -tpas -o -V all "$THREAD_LOG" \
       && run_ltl plain --disable-progress -bs 1440 -g -hg duration -n 3 -tpas -o "$THREAD_LOG"; then
        assert_accounting withv
        assert_command \
            command     "$(checker_cmd compare "$(capture withv)" "$(capture plain)")" \
            label       'with every -V range removed, the run prints the rows of the run without -V' \
            asserts     'Standard output of a -V all run, with every === name === ... === END name === range removed, has the same rows as the same run without -V, text included, apart from -V on the options row and the time and memory figures' \
            produced_by 'print_verbose_output(), print_histograms() and write_aggregate_export() print -V; the section printers print the rest, in ltl' \
            contract    'features/597-section-visibility.md § D6, D14'
    fi
    echo ""
fi

# Progress shown is a section of its own between the title and the timeline,
# its rows counted as they end.
if scenario_wanted progress-rendered; then
    current_scenario=progress-rendered
    if SOFT_WRAP_CHECK=0 run_ltl progress -bs 120 -n 2 -V section-layout "$SPREAD_LOG"; then
        assert_accounting progress
        assert_state progress progress rendered
        assert_anchor progress progress 0 'Processing completed.' 'read_and_process_logs()'
        assert_anchor progress progress last 'Scaling and normalizing data completed.' 'normalize_data_for_output()'
    fi
    echo ""
fi

# The date/time warning is a notice: it prints on standard error, and standard
# output still accounts for every row (D12).
if scenario_wanted datetime-warning-stderr; then
    current_scenario=datetime-warning-stderr
    if run_ltl datetime --disable-progress -bs 120 -n 2 -st 12h -V section-layout "$SPREAD_LOG"; then
        assert_accounting datetime
        assert_command \
            command     "grep -q 'unhandled date/time format' $(printf '%q' "$TMP_DIR/datetime/err") && ! grep -q 'unhandled date/time format' $(printf '%q' "$(capture datetime)")" \
            label       'the unhandled date/time warning is on standard error, not standard output' \
            asserts     'A -st value in no handled date/time form prints its warning on standard error and nothing on standard output' \
            produced_by 'calculate_start_end_filter_timestamps() through defer_notice() in ltl' \
            contract    'features/597-section-visibility.md § D12'
    fi
    echo ""
fi

echo "Results: $pass passed, $fail failed"
if [[ "$pass" -eq 0 && "$fail" -eq 0 ]]; then
    echo "No assertion ran"; exit 1
fi
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do echo "  - $f"; done
    exit 1
fi
echo "ALL SECTION-LAYOUT TESTS PASSED"
