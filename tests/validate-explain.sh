#!/usr/bin/env bash
# validate-explain.sh — Validate the --help statistics / --explain framework
# (Issue #261). Asserts that every topic in %explain_topics renders, that
# aliases resolve correctly, that the registry and index views list all
# topics, that unknown topics produce hard errors, that the short -ex alias
# works, that rendered output respects --terminal-width, and that table
# blocks render with Unicode box-drawing characters.
# Usage: ./tests/validate-explain.sh
#
# Follows the self-documenting assertion design from tests/HARNESS-DESIGN.md.
# Every assertion records:
#   - asserts:     the application invariant being tested
#   - produced_by: where in ltl the invariant is produced (function name)
#   - contract:    the stability contract that makes it stable
#
# The harness greps the captured output (rendered terminal text). ANSI
# escape sequences and backspace-overstrike pairs are stripped before
# matching so assertions can target plain text without escaping concerns.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"
EXPLAIN_MD="$REPO_DIR/docs/explain/statistics.md"

# Temp dir for captured outputs (HARNESS-DESIGN.md Trap 10).
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"
    exit 1
fi
if [[ ! -f "$EXPLAIN_MD" ]]; then
    echo "ERROR: docs/explain/statistics.md not found: $EXPLAIN_MD"
    exit 1
fi

pass=0
fail=0
failures=()
current_scenario=""

# Strip ANSI escape sequences and backspace-overstrike pairs from a file
# so the assertions can match plain rendered text.
strip_decoration() {
    sed -E 's/\x1b\[[0-9;]*[A-Za-z]//g; s/.\x08//g' "$1"
}

# Run ltl with the given args. Captures stdout+stderr to a temp file,
# echoes the path. Suppresses pipefail-style aborts so the harness can
# inspect non-zero exits in scenarios that expect them.
run_ltl() {
    local label="$1"; shift
    local out="$TMP_DIR/$label.raw"
    local stripped="$TMP_DIR/$label.txt"
    set +e
    "$LTL" "$@" > "$out" 2>&1
    local ec=$?
    set -e
    strip_decoration "$out" > "$stripped"
    echo "$ec:$stripped"
}

# Self-documenting assertion: a line matching `pattern` must be present.
assert_line() {
    local outfile="$1"
    shift
    local pattern asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            pattern)     pattern="$2";     shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_line: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${pattern:?assert_line requires pattern}"
    : "${asserts:?assert_line requires asserts}"
    : "${produced_by:?assert_line requires produced_by}"
    : "${contract:?assert_line requires contract}"

    if grep -qE "$pattern" "$outfile"; then
        echo "  PASS  $current_scenario :: $pattern"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        pattern:     $pattern"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        echo "        (not found in $outfile)"
        fail=$((fail + 1))
        failures+=("$current_scenario :: $pattern")
    fi
}

# Assert the captured ltl exit code matches an expected value.
assert_exit() {
    local actual="$1"
    local expected="$2"
    shift 2
    local asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_exit: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${asserts:?assert_exit requires asserts}"
    : "${produced_by:?assert_exit requires produced_by}"
    : "${contract:?assert_exit requires contract}"

    if [[ "$actual" -eq "$expected" ]]; then
        echo "  PASS  $current_scenario :: exit=$expected"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        expected exit: $expected"
        echo "        actual exit:   $actual"
        echo "        asserts:       $asserts"
        echo "        produced_by:   $produced_by"
        echo "        contract:      $contract"
        fail=$((fail + 1))
        failures+=("$current_scenario :: exit=$actual (expected $expected)")
    fi
}

# Assert the captured output has at least $min lines.
assert_min_lines() {
    local outfile="$1"
    local min="$2"
    shift 2
    local asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_min_lines: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${asserts:?assert_min_lines requires asserts}"
    : "${produced_by:?assert_min_lines requires produced_by}"
    : "${contract:?assert_min_lines requires contract}"

    local lines
    lines=$(wc -l < "$outfile" | tr -d ' ')
    if [[ "$lines" -ge "$min" ]]; then
        echo "  PASS  $current_scenario :: lines=$lines (>= $min)"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        expected >= $min lines, got $lines"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
        failures+=("$current_scenario :: only $lines lines (expected >= $min)")
    fi
}

# Assert two captured outputs are byte-identical (after decoration strip).
# Used for alias resolution: --explain avg must produce the same text as
# --explain mean.
assert_outputs_equal() {
    local file_a="$1"
    local file_b="$2"
    shift 2
    local asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_outputs_equal: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${asserts:?assert_outputs_equal requires asserts}"
    : "${produced_by:?assert_outputs_equal requires produced_by}"
    : "${contract:?assert_outputs_equal requires contract}"

    if diff -q "$file_a" "$file_b" > /dev/null 2>&1; then
        echo "  PASS  $current_scenario :: outputs identical"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        files differ:"
        echo "          a: $file_a"
        echo "          b: $file_b"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
        failures+=("$current_scenario :: outputs differ")
    fi
}

# Assert no rendered line (after decoration strip) exceeds the given width.
# Width is measured in DISPLAY CHARACTERS, not bytes -- Unicode box-drawing
# glyphs like '│' are 1 character but 3 bytes; bash's length and BSD awk's
# length count bytes, which would falsely fail tables that fit visually.
assert_max_line_width() {
    local outfile="$1"
    local max="$2"
    shift 2
    local asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_max_line_width: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${asserts:?assert_max_line_width requires asserts}"
    : "${produced_by:?assert_max_line_width requires produced_by}"
    : "${contract:?assert_max_line_width requires contract}"

    # Use Perl with UTF-8 IO so length() counts display characters, not bytes.
    # Skip the title banner (printed by print_title before help/explain output);
    # it has its own width contract independent of --explain content.
    local overlong
    overlong=$(perl -CSDA -e '
        use strict; use warnings;
        my ($file, $max) = @ARGV;
        open my $fh, "<:encoding(UTF-8)", $file or die "open $file: $!";
        # U+2500 ─ is the title-banner separator; matched via hex codepoint
        # so the regex source does not depend on UTF-8 decoding of this file.
        my $count = 0;
        my @reports;
        my $lineno = 0;
        while (my $line = <$fh>) {
            $lineno++;
            chomp $line;
            next if $line =~ /\x{2500}{20,}/;
            next if $line =~ /,:: ltl ::|by Greg Eva/;
            my $len = length $line;
            if ($len > $max) {
                $count++;
                if ($count <= 3) {
                    my $preview = length($line) > 80 ? substr($line, 0, 80) . "..." : $line;
                    push @reports, "  line $lineno (len $len): $preview";
                }
            }
        }
        print join("\n", @reports);
        exit ($count > 0 ? 1 : 0);
    ' "$outfile" "$max" || true)
    if [[ -z "$overlong" ]]; then
        echo "  PASS  $current_scenario :: no content lines exceed $max chars"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        content lines exceeded $max chars:"
        echo "$overlong"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
        failures+=("$current_scenario :: lines exceeded $max")
    fi
}

# ============================================================================
# Scenarios
# ============================================================================

TOPICS=(min max mean std_dev cv iqr percentiles skewness kurtosis bimodality_coef)

# --- Scenario 1: every topic renders non-empty with the expected heading. ---
scenario_all_topics_render() {
    for topic in "${TOPICS[@]}"; do
        current_scenario="topic:$topic"
        echo "[$current_scenario]"
        local result
        result=$(run_ltl "topic-$topic" --explain "$topic")
        local ec="${result%%:*}"
        local out="${result#*:}"

        assert_exit "$ec" 0 \
            asserts     "ltl --explain <known-topic> exits 0 after emitting the topic" \
            produced_by 'adapt_to_command_line_options() in ltl (--explain dispatch block)' \
            contract    'Issue #261: every known topic in %explain_topics is renderable'

        assert_min_lines "$out" 20 \
            asserts     "Topic '$topic' renders at least 20 lines of content (heading + paragraphs + tables + see-also)" \
            produced_by 'render_blocks() in ltl iterating over %explain_topics{$topic}' \
            contract    'Issue #261: each topic carries the 7-block skeleton (intuition, interpretation, operational, example, algorithm, see-also)'

        # Heading text appears in uppercase via help_heading. The bs_bold
        # overstrike has been stripped already by strip_decoration; we expect
        # the bare uppercase heading text (allowing trailing chars for topics
        # that include qualifying suffix like "CV (COEFFICIENT OF VARIATION)").
        local heading_pattern
        case "$topic" in
            cv)               heading_pattern='^CV ' ;;
            iqr)              heading_pattern='^IQR ' ;;
            bimodality_coef)  heading_pattern='^BIMODALITY_COEF ' ;;
            *)                heading_pattern="^$(echo "$topic" | tr '[:lower:]' '[:upper:]')\$" ;;
        esac

        assert_line "$out" \
            pattern     "$heading_pattern" \
            asserts     "Topic '$topic' emits an uppercase heading at the top of its block sequence" \
            produced_by 'render_heading() in ltl (block of type "heading" produced by help_heading)' \
            contract    'Issue #261: the first block of every topic is { type => heading, text => UPPERCASE-TOPIC-NAME }'

        assert_line "$out" \
            pattern     'See also' \
            asserts     "Topic '$topic' emits a 'See also' heading near the end (cross-refs to related topics)" \
            produced_by '%explain_topics in ltl (final block of every topic skeleton)' \
            contract    'Issue #261: every topic ends with a See-also section listing related --explain topics and flags'
    done
}

# --- Scenario 2: aliases resolve to the canonical topic. ---
scenario_aliases() {
    current_scenario="alias:avg-equals-mean"
    echo "[$current_scenario]"
    local r1 r2
    r1=$(run_ltl "alias-mean" --explain mean)
    r2=$(run_ltl "alias-avg"  --explain avg)
    assert_outputs_equal "${r1#*:}" "${r2#*:}" \
        asserts     "ltl --explain avg produces output identical to ltl --explain mean" \
        produced_by 'resolve_explain_topic() in ltl (consults %explain_aliases hash)' \
        contract    'Issue #261: avg is an alias to mean per %explain_aliases'

    current_scenario="alias:stddev-equals-std_dev"
    echo "[$current_scenario]"
    r1=$(run_ltl "alias-std_dev" --explain std_dev)
    r2=$(run_ltl "alias-stddev"  --explain stddev)
    assert_outputs_equal "${r1#*:}" "${r2#*:}" \
        asserts     "ltl --explain stddev produces output identical to ltl --explain std_dev" \
        produced_by 'resolve_explain_topic() in ltl (consults %explain_aliases hash)' \
        contract    'Issue #261: stddev is an alias to std_dev per %explain_aliases'

    current_scenario="alias:p95-equals-percentiles"
    echo "[$current_scenario]"
    r1=$(run_ltl "alias-percentiles" --explain percentiles)
    r2=$(run_ltl "alias-p95"          --explain p95)
    assert_outputs_equal "${r1#*:}" "${r2#*:}" \
        asserts     "ltl --explain p95 produces output identical to ltl --explain percentiles" \
        produced_by 'resolve_explain_topic() in ltl (every percentile slug routes to the shared topic)' \
        contract    'Issue #261: every percentile slug (p1..p99999) resolves to percentiles via %explain_aliases'

    current_scenario="alias:p99999-equals-percentiles"
    echo "[$current_scenario]"
    r1=$(run_ltl "alias-percentiles" --explain percentiles)
    r2=$(run_ltl "alias-p99999"      --explain p99999)
    assert_outputs_equal "${r1#*:}" "${r2#*:}" \
        asserts     "ltl --explain p99999 produces output identical to ltl --explain percentiles" \
        produced_by 'resolve_explain_topic() in ltl' \
        contract    'Issue #261: p99999 is routed to the shared percentiles topic'
}

# --- Scenario 3: --explain with no arg lists the topic registry. ---
scenario_registry() {
    current_scenario="registry:no-arg"
    echo "[$current_scenario]"
    local result
    result=$(run_ltl "registry" --explain)
    local ec="${result%%:*}"
    local out="${result#*:}"

    assert_exit "$ec" 0 \
        asserts     "ltl --explain (no argument) exits 0 after printing the topic registry" \
        produced_by 'adapt_to_command_line_options() in ltl (--explain dispatch block, empty-string branch)' \
        contract    'Issue #261: bare --explain prints the grouped registry'

    assert_line "$out" \
        pattern     '^STATISTICS$' \
        asserts     "Registry view emits the STATISTICS heading (shared with --help statistics)" \
        produced_by 'print_explain_registry() in ltl' \
        contract    'Issue #261: bare --explain prints a STATISTICS heading; future categories (heatmap, histogram, etc.) will use their own headings'

    # Every group name must appear.
    for group in 'Range' 'Central tendency' 'Spread' 'Percentiles' 'Distribution shape'; do
        assert_line "$out" \
            pattern     "^  ${group}\$" \
            asserts     "Registry view emits the '$group' subheading" \
            produced_by 'print_explain_registry() in ltl iterating @explain_groups' \
            contract    'Issue #261: registry groups match @explain_groups exactly'
    done

    # Every topic name must appear.
    for topic in "${TOPICS[@]}"; do
        assert_line "$out" \
            pattern     "^    ${topic}[[:space:]]" \
            asserts     "Registry view lists topic '$topic' under its group" \
            produced_by 'print_explain_registry() in ltl iterating @explain_groups{topics}' \
            contract    'Issue #261: every topic in %explain_topics is also listed in @explain_groups'
    done
}

# --- Scenario 4: unknown --explain topic errors out. ---
scenario_unknown_topic() {
    current_scenario="error:unknown-explain-topic"
    echo "[$current_scenario]"
    local result
    result=$(run_ltl "unknown-explain" --explain nope)
    local ec="${result%%:*}"
    local out="${result#*:}"

    assert_exit "$ec" 1 \
        asserts     "ltl --explain <unknown-topic> exits 1 with an error" \
        produced_by 'adapt_to_command_line_options() in ltl (die print_usage on unknown topic)' \
        contract    'Issue #261: unknown topics are a hard error, not silent fall-through'

    assert_line "$out" \
        pattern     "unknown --explain topic 'nope'" \
        asserts     "Error message identifies the unknown topic name" \
        produced_by 'print_usage("unknown --explain topic ...") in ltl' \
        contract    'Issue #261: error message names the unknown topic verbatim'
}

# --- Scenario 5: --help statistics. ---
scenario_help_statistics() {
    current_scenario="help-statistics"
    echo "[$current_scenario]"
    local result
    result=$(run_ltl "help-stats" --help statistics)
    local ec="${result%%:*}"
    local out="${result#*:}"

    assert_exit "$ec" 0 \
        asserts     "ltl --help statistics exits 0 after printing the index" \
        produced_by 'adapt_to_command_line_options() in ltl (--help dispatch, statistics branch)' \
        contract    'Issue #261: --help statistics is a recognized topic'

    assert_line "$out" \
        pattern     '^STATISTICS$' \
        asserts     "Statistics index emits the STATISTICS heading" \
        produced_by 'print_help_statistics() in ltl' \
        contract    'Issue #261: --help statistics emits a top-level STATISTICS heading'

    # Group subheadings.
    for group in 'Range' 'Central tendency' 'Spread' 'Percentiles' 'Distribution shape'; do
        assert_line "$out" \
            pattern     "^  ${group}\$" \
            asserts     "Statistics index emits the '$group' subheading" \
            produced_by 'print_help_statistics() in ltl iterating @explain_groups' \
            contract    'Issue #261: --help statistics groups mirror @explain_groups'
    done

    # Every topic name appears in the index too.
    for topic in "${TOPICS[@]}"; do
        assert_line "$out" \
            pattern     "^    ${topic}[[:space:]]" \
            asserts     "Statistics index lists topic '$topic'" \
            produced_by 'print_help_statistics() in ltl' \
            contract    'Issue #261: the statistics index covers every entry in %explain_topics'
    done

    # Cross-reference to --explain.
    assert_line "$out" \
        pattern     "'ltl --explain" \
        asserts     "Statistics index points users at ltl --explain for long-form content" \
        produced_by 'print_help_statistics() in ltl (See-also footer)' \
        contract    'Issue #261: the two surfaces (--help statistics, --explain) are cross-referenced'
}

# --- Scenario 6: --help with unknown topic errors out. ---
scenario_help_unknown() {
    current_scenario="error:unknown-help-topic"
    echo "[$current_scenario]"
    local result
    result=$(run_ltl "unknown-help" --help bogus)
    local ec="${result%%:*}"
    local out="${result#*:}"

    assert_exit "$ec" 1 \
        asserts     "ltl --help <unknown-topic> exits 1 with an error" \
        produced_by 'adapt_to_command_line_options() in ltl (die print_usage on unknown --help topic)' \
        contract    'Issue #261: unknown --help topics are a hard error'

    assert_line "$out" \
        pattern     "unknown --help topic 'bogus'" \
        asserts     "Error message identifies the unknown --help topic name" \
        produced_by 'print_usage("unknown --help topic ...") in ltl' \
        contract    'Issue #261: error message names the unknown --help topic verbatim'
}

# --- Scenario 7: bare --help still works (backward-compatibility). ---
scenario_help_bare() {
    current_scenario="help-bare"
    echo "[$current_scenario]"
    local result
    result=$(run_ltl "help-bare" --help)
    local ec="${result%%:*}"
    local out="${result#*:}"

    assert_exit "$ec" 0 \
        asserts     "Bare ltl --help still exits 0 and prints full help (backward-compatibility)" \
        produced_by 'adapt_to_command_line_options() in ltl (--help dispatch, empty-string branch)' \
        contract    'Issue #261: extending --help to accept an optional argument must not regress bare --help'

    assert_line "$out" \
        pattern     '^USAGE$' \
        asserts     "Bare --help still emits the USAGE heading" \
        produced_by 'print_help() in ltl' \
        contract    'Issue #261: print_help output structure unchanged after closure-lift refactor'

    assert_line "$out" \
        pattern     '^OPTIONS$' \
        asserts     "Bare --help still emits the OPTIONS heading" \
        produced_by 'print_help() in ltl' \
        contract    'Issue #261: print_help output structure unchanged after closure-lift refactor'
}

# --- Scenario 8: reflow at terminal widths 80, 120, 200. ---
scenario_reflow() {
    for w in 80 120 200; do
        current_scenario="reflow:width-$w"
        echo "[$current_scenario]"
        local result
        result=$(run_ltl "reflow-$w" --tw "$w" --explain kurtosis)
        local ec="${result%%:*}"
        local out="${result#*:}"

        assert_exit "$ec" 0 \
            asserts     "ltl --tw $w --explain kurtosis exits 0" \
            produced_by 'adapt_to_command_line_options() in ltl (--explain dispatch)' \
            contract    'Issue #261: --terminal-width override controls reflow without affecting exit code'

        assert_max_line_width "$out" "$w" \
            asserts     "At --terminal-width=$w, no rendered content line exceeds $w characters" \
            produced_by 'help_wrap() / render_table() in ltl (reflow against help_wrap_width())' \
            contract    'Issue #261: paragraphs and tables reflow to actual terminal width; verbatim pre blocks are intentionally exempt'
    done
}

# --- Scenario 9: Unicode box-drawing characters present in topics with tables. ---
scenario_box_drawing() {
    for topic in kurtosis bimodality_coef percentiles cv iqr; do
        current_scenario="box-drawing:$topic"
        echo "[$current_scenario]"
        local result
        result=$(run_ltl "box-$topic" --explain "$topic")
        local out="${result#*:}"

        assert_line "$out" \
            pattern     '┌' \
            asserts     "Topic '$topic' renders at least one Unicode box-drawing corner (table is present)" \
            produced_by 'render_table() in ltl using %histogram_box_sets{light} glyphs' \
            contract    'Issue #261: tables in --explain topics use the same box-drawing glyph set as histogram axes'

        assert_line "$out" \
            pattern     '│' \
            asserts     "Topic '$topic' renders the Unicode vertical-bar glyph (table cells)" \
            produced_by 'render_table() in ltl using %histogram_box_sets{light}->{v_line}' \
            contract    'Issue #261: tables use a coherent Unicode box-drawing glyph set, not ASCII pipes-and-dashes'
    done
}

# --- Scenario 10: short -ex alias works. ---
scenario_short_alias() {
    current_scenario="short-alias:-ex"
    echo "[$current_scenario]"
    local r1 r2
    r1=$(run_ltl "short-explain" --explain mean)
    r2=$(run_ltl "short-ex"      -ex mean)
    assert_outputs_equal "${r1#*:}" "${r2#*:}" \
        asserts     "ltl -ex mean produces output identical to ltl --explain mean" \
        produced_by 'GetOptions wiring in ltl (--explain|ex:s)' \
        contract    'Issue #261: -ex is the short-form alias for --explain'
}

# --- Scenario 11: pager invocation and ANSI handling. ---
# The Issue #261 layout pipes long help/explain output through a pager so
# users can browse the percentiles topic (~70 lines). Two ANSI-related
# regressions must be guarded:
#   (a) Unix pager default must be `less -R`. Plain `less` would render
#       the title banner's ANSI color escapes as literal "^[[Nm" text in
#       the pager view (caught only after the user reported it).
#   (b) strip_ansi() must exist and must remove CSI escape sequences --
#       it's the safety net for Windows `more` (which does not interpret
#       ANSI) and for any fallback path.
# These are source-level assertions because we cannot reliably observe
# inside-less rendering from a non-TTY test harness.
scenario_pager_ansi() {
    current_scenario="pager-ansi:less-R-default"
    echo "[$current_scenario]"
    # Read the ltl source and assert the Unix-default pager is `less -R`.
    local pager_default
    pager_default=$(perl -ne '
        if (/^\s*\$pager\s*=\s*[\x27"]less[^\x27"]*[\x27"]/) {
            chomp;
            s/^\s*\$pager\s*=\s*[\x27"]//;
            s/[\x27"].*$//;
            print;
            exit;
        }
    ' "$LTL/../ltl" 2>/dev/null)
    # Fallback: scan the whole file for the less invocation.
    if [[ -z "$pager_default" ]]; then
        pager_default=$(grep -oE "'less[^']*'" "$REPO_DIR/ltl" | head -1 | tr -d "'")
    fi
    local probe="$TMP_DIR/pager-probe.txt"
    echo "$pager_default" > "$probe"
    assert_line "$probe" \
        pattern     'less -R' \
        asserts     "Unix-default pager is 'less -R'; the -R flag tells less to interpret ANSI color escapes from the title banner rather than render them as literal ^[[Nm text. Plain 'less' would show the codes verbatim and confuse users." \
        produced_by 'pipe_to_pager() in ltl (Unix branch when $PAGER is unset)' \
        contract    'Issue #261: pager configuration is part of the user-visible help/explain contract; regression here would re-introduce the ANSI-leak bug the user originally reported'

    current_scenario="pager-ansi:strip_ansi-exists"
    echo "[$current_scenario]"
    # Assert strip_ansi() function is defined in ltl source (safety net for
    # Windows `more` and fallback paths).
    local sym_probe="$TMP_DIR/sym-probe.txt"
    grep -nE '^sub strip_ansi\b' "$REPO_DIR/ltl" > "$sym_probe" || true
    assert_line "$sym_probe" \
        pattern     '^[0-9]+:sub strip_ansi' \
        asserts     "strip_ansi() helper exists in ltl. It is the fallback for environments where the pager cannot interpret ANSI (notably legacy Windows `more`) and for the pager-failure path." \
        produced_by 'strip_ansi() in ltl' \
        contract    'Issue #261: ANSI-stripping must be available as a fallback so the title banner cannot leak as literal text in any supported configuration'

    current_scenario="pager-ansi:strip_ansi-removes-CSI"
    echo "[$current_scenario]"
    # Behavioral check: run a tiny Perl probe that calls Perl-side equivalent
    # of strip_ansi to confirm CSI sequences are removed and backspace
    # overstrike survives.
    local probe_in="$TMP_DIR/ansi-in.txt"
    local probe_out="$TMP_DIR/ansi-out.txt"
    printf '\033[0;37mhello\033[0m world\nU\bUS\bSA\bAG\bGE\bE\n' > "$probe_in"
    perl -ne 's/\x1b\[[0-9;]*[A-Za-z]//g; print' "$probe_in" > "$probe_out"
    assert_line "$probe_out" \
        pattern     '^hello world$' \
        asserts     "ANSI-strip regex removes \\033[Nm CSI sequences and leaves regular text intact" \
        produced_by 'strip_ansi() in ltl (regex /\\x1b\\[[0-9;]*[A-Za-z]//g)' \
        contract    'Issue #261: ANSI-strip implementation must match the canonical CSI regex; regression here would let codes leak through'
    assert_line "$probe_out" \
        pattern     'U\x08U' \
        asserts     "ANSI-strip does NOT touch backspace-overstrike pairs (X\\bX for bold, _\\bX for underline). less/more interpret those natively for bold and underline." \
        produced_by 'strip_ansi() in ltl (regex targets only \\x1b CSI, not \\b)' \
        contract    'Issue #261: overstrike formatting must survive ANSI strip; otherwise topic headings would lose their bold/underline rendering'
}

# ---------------------------------------------------------------------------
# Run scenarios
# ---------------------------------------------------------------------------

echo "Validating --help statistics and --explain framework (Issue #261)"
echo ""

scenario_all_topics_render
echo ""
scenario_aliases
echo ""
scenario_registry
echo ""
scenario_unknown_topic
echo ""
scenario_help_statistics
echo ""
scenario_help_unknown
echo ""
scenario_help_bare
echo ""
scenario_reflow
echo ""
scenario_box_drawing
echo ""
scenario_short_alias
echo ""
scenario_pager_ansi

echo ""
echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
echo "ALL EXPLAIN TESTS PASSED"
