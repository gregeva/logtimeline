#!/usr/bin/env bash
# validate-explain.sh — Validate the --help statistics / --explain framework
# (Issue #261). Asserts that every topic in %explain_topics renders, that
# aliases resolve correctly, that the registry and index views list all
# topics, that unknown topics produce hard errors, that the short -ex alias
# works, that rendered output respects --terminal-width, and that table
# blocks render with Unicode box-drawing characters.
# Invocation shape (tests/HARNESS-DESIGN.md section Invocation coherence):
# --explain / --help only - no log input, nothing to shape.
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

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"

# Ambient FORCE_COLOR/NO_COLOR must not decide what this harness asserts
# against (tests/HARNESS-DESIGN.md section Colour rendering is controlled,
# never inherited; issue #438).
neutralize_colour_env

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

# Run ltl with the given args. Captures stdout to a temp file (stderr goes
# to a sibling <label>.stderr capture), echoes the path. Suppresses
# pipefail-style aborts so the harness can inspect non-zero exits in
# scenarios that expect them.
run_ltl() {
    local label="$1"; shift
    local out="$TMP_DIR/$label.raw"
    local stripped="$TMP_DIR/$label.txt"
    set +e
    "$LTL" "$@" > "$out" 2>"$TMP_DIR/$label.stderr"
    local ec=$?
    set -e
    strip_decoration "$out" > "$stripped"
    echo "$ec:$stripped"
}

# Runtime-warning cleanliness for a captured ltl stderr file
# (HARNESS-DESIGN.md section Runtime-warning cleanliness, issue #341).
# Runs in the main shell so the fail counters persist - a
# command-substitution subshell could not update them. Silent when clean.
check_stderr_warnings() {
    local stderr_file="$1"
    if ! assert_no_runtime_warnings "$stderr_file" "$current_scenario"; then
        fail=$((fail + 1))
        failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
    fi
}

# Same check for a run_ltl capture, addressed by the stripped-stdout path
# run_ltl echoes; the stderr capture lives beside it as <label>.stderr.
check_capture_warnings() {
    check_stderr_warnings "${1%.txt}.stderr"
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

# Self-documenting assertion: no line matching `pattern` may be present.
# Same field requirements as assert_line; inverse semantics.
assert_no_line() {
    local outfile="$1"
    shift
    local pattern asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            pattern)     pattern="$2";     shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_no_line: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${pattern:?assert_no_line requires pattern}"
    : "${asserts:?assert_no_line requires asserts}"
    : "${produced_by:?assert_no_line requires produced_by}"
    : "${contract:?assert_no_line requires contract}"

    if grep -qE "$pattern" "$outfile"; then
        echo "  FAIL  $current_scenario"
        echo "        pattern:     !$pattern (unexpectedly present)"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
        failures+=("$current_scenario :: !$pattern (unexpectedly present)")
    else
        echo "  PASS  $current_scenario :: !$pattern"
        pass=$((pass + 1))
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

TOPICS=(min max mean std_dev cv iqr percentiles skewness kurtosis bimodality_coef heatmap histogram classification)

# Analysis-technique topics (#504). TECHNIQUE_GROUPS are the group pages,
# one per group; TECHNIQUE_TOPICS are the technique leaf pages. The two
# lists together are the technique family, and both are listed in the
# registry under the ANALYSIS TECHNIQUES category. Delivered in drops, so
# a list grows as a drop lands and the roster the feature record gives is
# reached at the last one.
TECHNIQUE_GROUPS=(time population shape comparison load correlation)
TECHNIQUE_TOPICS=(window-narrowing resolution-zoom traffic-load-profiling contribution-highlighting api-isolation attribute-isolation rank-then-isolate outcome-isolation remainder attribute-surfacing tail-excursion bimodal-split shape-comparison timeout-clustering period-over-period status-composition load-over-time custom-metric cross-log-correlation)

# Technique count per group. Read from the registry the tool itself prints
# rather than hardcoded here, so a technique added to a group but never
# listed on its group page is a failure. The registry lists the group page
# first and its techniques after it, under the group's own subheading, so
# the count is the topics under that subheading less the group page itself.
technique_count_for_group() {
    local group_label="$1"
    "$LTL" --explain 2>/dev/null | awk -v g="  $group_label" '
        $0 == g            { inside = 1; next }
        inside && /^  [A-Z]/ { inside = 0 }
        inside && /^ANALYSIS TECHNIQUES$|^STATISTICS$|^VISUALIZATIONS$|^METHODOLOGY$/ { inside = 0 }
        inside && /^    [a-z]/ { n++ }
        END { print (n > 0 ? n - 1 : 0) }
    '
}

# --- Scenario 1: every topic renders non-empty with the expected heading. ---
scenario_all_topics_render() {
    for topic in "${TOPICS[@]}"; do
        current_scenario="topic:$topic"
        echo "[$current_scenario]"
        local result
        result=$(run_ltl "topic-$topic" --explain "$topic")
        local ec="${result%%:*}"
        local out="${result#*:}"
        check_capture_warnings "$out"

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
    check_capture_warnings "${r1#*:}"
    check_capture_warnings "${r2#*:}"
    assert_outputs_equal "${r1#*:}" "${r2#*:}" \
        asserts     "ltl --explain avg produces output identical to ltl --explain mean" \
        produced_by 'resolve_explain_topic() in ltl (consults %explain_aliases hash)' \
        contract    'Issue #261: avg is an alias to mean per %explain_aliases'

    current_scenario="alias:stddev-equals-std_dev"
    echo "[$current_scenario]"
    r1=$(run_ltl "alias-std_dev" --explain std_dev)
    r2=$(run_ltl "alias-stddev"  --explain stddev)
    check_capture_warnings "${r1#*:}"
    check_capture_warnings "${r2#*:}"
    assert_outputs_equal "${r1#*:}" "${r2#*:}" \
        asserts     "ltl --explain stddev produces output identical to ltl --explain std_dev" \
        produced_by 'resolve_explain_topic() in ltl (consults %explain_aliases hash)' \
        contract    'Issue #261: stddev is an alias to std_dev per %explain_aliases'

    current_scenario="alias:p95-equals-percentiles"
    echo "[$current_scenario]"
    r1=$(run_ltl "alias-percentiles" --explain percentiles)
    r2=$(run_ltl "alias-p95"          --explain p95)
    check_capture_warnings "${r1#*:}"
    check_capture_warnings "${r2#*:}"
    assert_outputs_equal "${r1#*:}" "${r2#*:}" \
        asserts     "ltl --explain p95 produces output identical to ltl --explain percentiles" \
        produced_by 'resolve_explain_topic() in ltl (every percentile slug routes to the shared topic)' \
        contract    'Issue #261: every percentile slug (p1..p99999) resolves to percentiles via %explain_aliases'

    current_scenario="alias:p99999-equals-percentiles"
    echo "[$current_scenario]"
    r1=$(run_ltl "alias-percentiles" --explain percentiles)
    r2=$(run_ltl "alias-p99999"      --explain p99999)
    check_capture_warnings "${r1#*:}"
    check_capture_warnings "${r2#*:}"
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
    check_capture_warnings "$out"

    assert_exit "$ec" 0 \
        asserts     "ltl --explain (no argument) exits 0 after printing the topic registry" \
        produced_by 'adapt_to_command_line_options() in ltl (--explain dispatch block, empty-string branch)' \
        contract    'Issue #261: bare --explain prints the grouped registry'

    # No top-level heading: the registry mixes categories (Statistics +
    # Visualizations) so a single top heading would be misleading. The
    # group subheadings (Range, ..., Visualizations) carry the structure.
    assert_line "$out" \
        pattern     "Use 'ltl --explain <topic>' for a long-form explanation" \
        asserts     "Registry view leads with the intro sentence positioning the page (no top-level heading by design)" \
        produced_by 'print_explain_registry() in ltl' \
        contract    'Issue #261 phase 2: registry intro is the sole framing; group subheadings carry the structure'

    # Statistics group subheadings must appear under the STATISTICS heading.
    for group in 'Range' 'Central tendency' 'Spread' 'Percentiles' 'Distribution shape'; do
        assert_line "$out" \
            pattern     "^  ${group}\$" \
            asserts     "Registry view emits the '$group' subheading under STATISTICS" \
            produced_by 'print_explain_registry() in ltl iterating @explain_groups' \
            contract    'Issue #261: registry groups match @explain_groups exactly'
    done

    # Category section headings must appear (STATISTICS, VISUALIZATIONS).
    for cat in 'STATISTICS' 'VISUALIZATIONS'; do
        assert_line "$out" \
            pattern     "^${cat}\$" \
            asserts     "Registry view emits the '$cat' top-level section heading" \
            produced_by 'print_explain_registry() in ltl emitting help_heading per category transition' \
            contract    'Issue #261 phase 2: registry has two section headings: STATISTICS for stats topics, VISUALIZATIONS for chart topics'
    done

    # The redundant "Visualizations" subheading (group name == category
    # heading) must be suppressed.
    assert_no_line "$out" \
        pattern     '^  Visualizations$' \
        asserts     "Registry suppresses the group subheading when it would duplicate the category heading (one-group-named-same case)" \
        produced_by 'print_explain_registry() in ltl (uc group name vs category-heading dedup)' \
        contract    'Issue #261 phase 2 layout: avoid stuttering category/group when they are identical'

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
    check_capture_warnings "$out"

    assert_exit "$ec" 1 \
        asserts     "ltl --explain <unknown-topic> exits 1 with an error" \
        produced_by 'adapt_to_command_line_options() in ltl (die print_usage on unknown topic)' \
        contract    'Issue #261: unknown topics are a hard error, not silent fall-through'

    # The usage/error diagnostic is an intentional stderr emission, so the
    # assertion targets the stderr capture, not the stdout capture.
    assert_line "${out%.txt}.stderr" \
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
    check_capture_warnings "$out"

    assert_exit "$ec" 0 \
        asserts     "ltl --help statistics exits 0 after printing the index" \
        produced_by 'adapt_to_command_line_options() in ltl (--help dispatch, statistics branch)' \
        contract    'Issue #261: --help statistics is a recognized topic'

    assert_line "$out" \
        pattern     '^STATISTICS$' \
        asserts     "Statistics index emits the STATISTICS heading" \
        produced_by 'print_help_statistics() in ltl' \
        contract    'Issue #261: --help statistics emits a top-level STATISTICS heading'

    # Group subheadings -- statistics groups only. The Visualizations
    # group (heatmap, histogram) is intentionally absent because
    # --help statistics stays narrow (#261 phase 2: visualizations belong
    # in --explain, not in the statistics index).
    for group in 'Range' 'Central tendency' 'Spread' 'Percentiles' 'Distribution shape'; do
        assert_line "$out" \
            pattern     "^  ${group}\$" \
            asserts     "Statistics index emits the '$group' subheading" \
            produced_by 'print_help_statistics() in ltl iterating @explain_groups[0..$_explain_stats_group_count-1]' \
            contract    'Issue #261: --help statistics groups mirror the statistics-only slice of @explain_groups'
    done

    # The Visualizations group must NOT appear in --help statistics.
    assert_no_line "$out" \
        pattern     '^  Visualizations$' \
        asserts     "--help statistics excludes the Visualizations group; that content belongs to --explain (#261 phase 2)" \
        produced_by 'print_help_statistics() in ltl (stats-only slice of @explain_groups)' \
        contract    'Issue #261 phase 2: $_explain_stats_group_count constant bounds the slice; widening it here would re-introduce the bug'

    # Every statistics topic appears in the index. heatmap and histogram
    # are excluded per the narrowing rule.
    local stats_topics=(min max mean std_dev cv iqr percentiles skewness kurtosis bimodality_coef)
    for topic in "${stats_topics[@]}"; do
        assert_line "$out" \
            pattern     "^    ${topic}[[:space:]]" \
            asserts     "Statistics index lists topic '$topic'" \
            produced_by 'print_help_statistics() in ltl' \
            contract    'Issue #261: the statistics index covers every statistic in %explain_topics'
    done

    # heatmap, histogram and classification must NOT appear in --help statistics.
    for topic in heatmap histogram classification; do
        assert_no_line "$out" \
            pattern     "^    ${topic}[[:space:]]" \
            asserts     "Visualization topic '$topic' must not appear in --help statistics; it belongs to --explain only" \
            produced_by 'print_help_statistics() in ltl (stats-only slice)' \
            contract    'Issue #261 phase 2: --help statistics is the statistics index; visualization topics live under --explain'
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
    check_capture_warnings "$out"

    assert_exit "$ec" 1 \
        asserts     "ltl --help <unknown-topic> exits 1 with an error" \
        produced_by 'adapt_to_command_line_options() in ltl (die print_usage on unknown --help topic)' \
        contract    'Issue #261: unknown --help topics are a hard error'

    # The usage/error diagnostic is an intentional stderr emission, so the
    # assertion targets the stderr capture, not the stdout capture.
    assert_line "${out%.txt}.stderr" \
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
    check_capture_warnings "$out"

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
        check_capture_warnings "$out"

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
        check_capture_warnings "$out"

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

# --- Scenario 9b: table borders align with column dividers. ---
# Regression guard for the misalignment caused when ANSI bold/underline
# in headers was not stripped from visible_length() in render_table.
# Symptom: top/bottom borders extended past column verticals because
# bold-wrapped headers measured wrong, leaving body cells short.
# Property: for every top border line (^\s*┌), the column positions of
# the box-drawing characters (┌ ┬ ┐) must equal the column positions of
# the verticals (│) on the next body row, AND the column positions on
# the corresponding bottom border (└ ┴ ┘).
# Implemented in Perl with UTF-8 decoding so multi-byte glyphs map to
# single character positions.
scenario_table_border_alignment() {
    for topic in cv mean std_dev iqr skewness kurtosis bimodality_coef percentiles; do
        current_scenario="table-border-align:$topic"
        echo "[$current_scenario]"
        # FORCE_COLOR puts bold/underline ANSI escapes around headers --
        # exactly the conditions under which the original bug manifested
        # (render_table's visible_length() failed to strip ANSI codes,
        # causing column widths to be computed wrong, which left borders
        # extending past the cell verticals). The Perl probe below strips
        # ANSI before measuring column positions so the comparison is
        # apples-to-apples.
        local raw="$TMP_DIR/border-align-$topic.raw"
        set +e
        with_ansi_colour "$LTL" --explain "$topic" > "$raw" 2>"$raw.stderr"
        set -e
        check_stderr_warnings "$raw.stderr"

        # Run a Perl probe that finds each top-border line and verifies
        # the column positions of ┌ ┬ ┐ align with the verticals on the
        # next body row. ANSI CSI sequences are stripped before measuring
        # positions so bold-wrapped headers do not inflate column indices.
        local probe_result
        probe_result=$(perl -CSDA -e '
            use strict; use warnings;
            my $file = shift;
            open my $fh, "<:encoding(UTF-8)", $file or die "open $file: $!";
            my @lines;
            while (my $l = <$fh>) {
                chomp $l;
                # Strip ANSI CSI sequences so column-position comparison
                # measures only visible characters.
                $l =~ s/\x1b\[[0-9;]*[A-Za-z]//g;
                push @lines, $l;
            }
            close $fh;

            my $tables_found = 0;
            my $mismatch = 0;
            my @details;
            for (my $i = 0; $i < $#lines; $i++) {
                # Top border: contains ┌ and (zero or more) ┬ and ┐.
                next unless $lines[$i] =~ /\x{250c}/;
                next unless $lines[$i] =~ /\x{2510}/;

                # Collect column positions of ┌ ┬ ┐ on this top line.
                my @top_cols;
                for my $c (0 .. length($lines[$i]) - 1) {
                    my $ch = substr($lines[$i], $c, 1);
                    if ($ch eq "\x{250c}" || $ch eq "\x{252c}" || $ch eq "\x{2510}") {
                        push @top_cols, $c;
                    }
                }

                # Find the next line below that has ┌ glyph siblings --
                # i.e. body row with │. The body row immediately follows
                # the top border in our renderer.
                my $body = $lines[$i + 1];
                last unless defined $body;

                # Collect column positions of │ on the body row.
                my @body_cols;
                for my $c (0 .. length($body) - 1) {
                    if (substr($body, $c, 1) eq "\x{2502}") {
                        push @body_cols, $c;
                    }
                }

                # Also locate the matching bottom border (next line with └).
                my $bot_line_idx;
                for my $j ($i + 1 .. $#lines) {
                    if ($lines[$j] =~ /\x{2514}/ && $lines[$j] =~ /\x{2518}/) {
                        $bot_line_idx = $j;
                        last;
                    }
                }
                last unless defined $bot_line_idx;

                my @bot_cols;
                for my $c (0 .. length($lines[$bot_line_idx]) - 1) {
                    my $ch = substr($lines[$bot_line_idx], $c, 1);
                    if ($ch eq "\x{2514}" || $ch eq "\x{2534}" || $ch eq "\x{2518}") {
                        push @bot_cols, $c;
                    }
                }

                $tables_found++;
                my $top_str  = join(",", @top_cols);
                my $body_str = join(",", @body_cols);
                my $bot_str  = join(",", @bot_cols);
                if ($top_str ne $body_str) {
                    $mismatch = 1;
                    push @details, "  table at top-line $i: top cols [$top_str] != body cols [$body_str]";
                }
                if ($top_str ne $bot_str) {
                    $mismatch = 1;
                    push @details, "  table at top-line $i: top cols [$top_str] != bottom cols [$bot_str]";
                }
            }

            print "tables=$tables_found mismatch=$mismatch\n";
            print "$_\n" for @details;
        ' "$raw")

        local tables_found
        tables_found=$(echo "$probe_result" | head -1 | sed -n "s/tables=\([0-9]*\).*/\1/p")
        local mismatch
        mismatch=$(echo "$probe_result" | head -1 | sed -n "s/.*mismatch=\([0-9]*\)/\1/p")

        if [[ "$tables_found" -lt 1 ]]; then
            echo "  FAIL  $current_scenario"
            echo "        no tables found in rendered output -- topic '$topic' should contain at least one table"
            echo "        asserts:     topic '$topic' renders at least one box-drawn table"
            echo "        produced_by: render_table() in ltl"
            echo "        contract:    Issue #261: topics with interpretation tables must render those tables"
            fail=$((fail + 1))
            failures+=("$current_scenario :: no tables found in $topic")
        elif [[ "$mismatch" -eq 0 ]]; then
            echo "  PASS  $current_scenario :: ${tables_found} table(s), all borders aligned with column dividers"
            pass=$((pass + 1))
        else
            echo "  FAIL  $current_scenario"
            echo "$probe_result" | tail -n +2
            echo "        asserts:     Top border and bottom border column positions must match the vertical-divider positions on body rows"
            echo "        produced_by: render_table() in ltl + visible_length() correctly stripping non-printing decorations"
            echo "        contract:    Issue #261 phase 2: visible_length must strip ANSI codes AND backspace overstrike so cell padding aligns with border glyphs"
            fail=$((fail + 1))
            failures+=("$current_scenario :: table borders misaligned in $topic")
        fi
    done
}

# --- Scenario 10: short -ex alias works. ---
scenario_short_alias() {
    current_scenario="short-alias:-ex"
    echo "[$current_scenario]"
    local r1 r2
    r1=$(run_ltl "short-explain" --explain mean)
    r2=$(run_ltl "short-ex"      -ex mean)
    check_capture_warnings "${r1#*:}"
    check_capture_warnings "${r2#*:}"
    assert_outputs_equal "${r1#*:}" "${r2#*:}" \
        asserts     "ltl -ex mean produces output identical to ltl --explain mean" \
        produced_by 'GetOptions wiring in ltl (--explain|ex:s)' \
        contract    'Issue #261: -ex is the short-form alias for --explain'
}

# --- Scenario: bold/underline render correctly in ASCII and ANSI modes. ---
# Industry-standard env vars control rendering:
#   - NO_COLOR set    (no-color.org convention) -> force ASCII; plain text
#                     headings with NO ANSI bold/underline escapes.
#   - FORCE_COLOR set (npm/node/chalk convention) -> force ANSI; headings
#                     wrapped in SGR 1/22 (bold) and SGR 4/24 (underline)
#                     so color-aware terminals and less -R render them.
# Default (TTY without either env) -> ANSI. Non-TTY (harness default) and
# NO_COLOR both fall back to plain ASCII.
scenario_ascii_and_ansi_modes() {
    current_scenario="mode:ascii (NO_COLOR=1)"
    echo "[$current_scenario]"
    local out_ascii="$TMP_DIR/mode-ascii.raw"
    set +e
    with_ascii_colour "$LTL" --explain mean > "$out_ascii" 2>"$out_ascii.stderr"
    set -e
    check_stderr_warnings "$out_ascii.stderr"

    # No ANSI bold/underline SGR codes should appear anywhere.
    # SGR 1 (bold), SGR 22 (no-bold), SGR 4 (underline), SGR 24 (no-underline).
    # Title banner uses 38;5; foreground codes which are out of scope here.
    if perl -e '
        my $f = shift;
        open my $fh, "<", $f or die $!;
        local $/;
        my $c = <$fh>;
        if ($c =~ /\x1b\[(?:1|22|4|24)m/) { exit 1 }
        exit 0;
    ' "$out_ascii"; then
        echo "  PASS  $current_scenario :: no bold/underline ANSI escapes in output"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        ASCII mode (NO_COLOR=1) should suppress SGR 1/22/4/24 codes"
        echo "        asserts:     With NO_COLOR set, headings render as plain text -- no ANSI bold/underline escapes leak through"
        echo "        produced_by: help_ansi_enabled() in ltl (returns 0 when NO_COLOR is defined)"
        echo "        contract:    Issue #261 phase 2: bold/underline gated by help_ansi_enabled; NO_COLOR convention honored"
        fail=$((fail + 1))
        failures+=("$current_scenario :: ANSI bold/underline leaked under NO_COLOR")
    fi

    # In ASCII mode the heading text must still appear (just not styled).
    assert_line "$out_ascii" \
        pattern     '^MEAN$' \
        asserts     "ASCII mode: heading text is plain (no ANSI), still recognizable" \
        produced_by 'bs_bold() returns plain text when help_ansi_enabled() is false' \
        contract    'Issue #261 phase 2: bold and underline must work in ASCII mode -- plain text is the universal fallback'

    # Subheadings (Operational use, etc.) must also render plain in ASCII mode.
    assert_line "$out_ascii" \
        pattern     '^  Operational use$' \
        asserts     "ASCII mode: subheading text is plain, no ANSI underline escapes" \
        produced_by 'bs_underline() returns plain text when help_ansi_enabled() is false' \
        contract    'Issue #261 phase 2: subheadings render readably without ANSI'

    # ----- ANSI mode -----
    current_scenario="mode:ansi (FORCE_COLOR=1)"
    echo "[$current_scenario]"
    local out_ansi="$TMP_DIR/mode-ansi.raw"
    set +e
    with_ansi_colour "$LTL" --explain mean > "$out_ansi" 2>"$out_ansi.stderr"
    set -e
    check_stderr_warnings "$out_ansi.stderr"

    # Bold ANSI escape (SGR 1) must appear -- the MEAN heading is bolded.
    # NOTE: exit(($match) ? 0 : 1) -- the outer parens are required to
    # bind the ternary to exit's argument; otherwise perl parses it as
    # `exit($match) ? 0 : 1` and exits with the match result directly.
    if perl -e '
        my $f = shift;
        open my $fh, "<", $f or die $!;
        local $/;
        my $c = <$fh>;
        exit (($c =~ /\x1b\[1m/) ? 0 : 1);
    ' "$out_ansi"; then
        echo "  PASS  $current_scenario :: ANSI bold (SGR 1) present"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        ANSI mode (FORCE_COLOR=1) should emit SGR 1 (bold) around headings"
        echo "        asserts:     With FORCE_COLOR set, headings are wrapped in ANSI bold (SGR 1)"
        echo "        produced_by: help_ansi_enabled() in ltl (returns 1 when FORCE_COLOR is set)"
        echo "        contract:    Issue #261 phase 2: FORCE_COLOR (npm/chalk standard) forces ANSI on; color terminals render styled headings"
        fail=$((fail + 1))
        failures+=("$current_scenario :: ANSI bold missing under FORCE_COLOR")
    fi

    # Underline ANSI escape (SGR 4) must appear -- subheadings are underlined.
    if perl -e '
        my $f = shift;
        open my $fh, "<", $f or die $!;
        local $/;
        my $c = <$fh>;
        exit (($c =~ /\x1b\[4m/) ? 0 : 1);
    ' "$out_ansi"; then
        echo "  PASS  $current_scenario :: ANSI underline (SGR 4) present"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        ANSI mode (FORCE_COLOR=1) should emit SGR 4 (underline) around subheadings"
        echo "        asserts:     Subheadings (Operational use, etc.) wrapped in ANSI underline (SGR 4)"
        echo "        produced_by: help_ansi_enabled() in ltl + bs_underline() emitting SGR 4"
        echo "        contract:    Issue #261 phase 2: FORCE_COLOR enables subheading underlines; they are visually important for navigability"
        fail=$((fail + 1))
        failures+=("$current_scenario :: ANSI underline missing under FORCE_COLOR")
    fi
}

# --- Scenario X: Visualization topics carry the synthetic ANSI chart. ---
# heatmap and histogram topics include a synthetic example chart authored
# with 256-color ANSI escape sequences and full-block characters. This
# scenario asserts the chart bytes survived heredoc assembly and render
# correctly. Because run_ltl pipes through strip_decoration, we capture a
# RAW version without stripping to look for the ANSI sequences directly.
scenario_visualization_charts() {
    for topic in heatmap histogram; do
        current_scenario="viz-chart:$topic"
        echo "[$current_scenario]"
        local raw_file="$TMP_DIR/viz-$topic.raw"
        # Run ltl WITHOUT decoration stripping so ANSI bytes are visible.
        set +e
        "$LTL" --explain "$topic" > "$raw_file" 2>"$raw_file.stderr"
        set -e
        check_stderr_warnings "$raw_file.stderr"

        # Use Perl to count ANSI CSI sequences in the captured raw output.
        local ansi_count
        ansi_count=$(perl -e '
            my ($file) = @ARGV;
            open my $fh, "<", $file or die $!;
            local $/;
            my $content = <$fh>;
            close $fh;
            my $count = () = $content =~ /\x1b\[/g;
            print $count;
        ' "$raw_file")

        # The synthetic chart has many ANSI sequences (one per colored cell).
        # 20 is a safe lower bound -- both heatmap and histogram should have
        # 50+ each.
        if [[ "$ansi_count" -ge 20 ]]; then
            echo "  PASS  $current_scenario :: ANSI sequences=$ansi_count (>=20)"
            pass=$((pass + 1))
        else
            echo "  FAIL  $current_scenario"
            echo "        expected >= 20 ANSI CSI sequences in raw output, found $ansi_count"
            echo "        asserts:     Topic '$topic' embeds a synthetic ANSI example chart in a pre block; the chart bytes (ANSI 256-color escape sequences) must survive heredoc assembly and render unmolested through the pager."
            echo "        produced_by: populate_explain_topics() in ltl (heredoc assembly for \$explain_${topic}_example)"
            echo "        contract:    Issue #261 phase 2: visualization topics include synthetic colored charts; this assertion guards against accidental ANSI stripping at authoring time"
            fail=$((fail + 1))
            failures+=("$current_scenario :: only $ansi_count ANSI sequences (expected >=20)")
        fi
    done
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
        asserts     "strip_ansi() helper exists in ltl. It is the fallback for environments where the pager cannot interpret ANSI (notably legacy Windows \`more\`) and for the pager-failure path." \
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
# Issue #287: --explain compute sections were rewritten to describe both
# the raw and bin data models (and to drop the deprecated `-ep` references).
# Lock the post-#287 prose so a regression that reverts to data-model-blind
# language or restores `-ep` references is caught at validation time.
# ---------------------------------------------------------------------------
scenario_data_model_aware_prose() {
    # --- min and max: sidecar phrasing must appear ---
    current_scenario="prose:min-mentions-bin-sidecar"
    echo "[$current_scenario]"
    local out
    out=$(run_ltl "prose-min" --explain min)
    out="${out#*:}"
    check_capture_warnings "$out"
    assert_line "$out" \
        pattern     'bin counter path maintains a running min sidecar' \
        asserts     "--explain min compute section describes the bin-path sidecar source post-#287; previously said 'first element of the sorted duration array' which is raw-only language" \
        produced_by '$explain_min_compute in ltl' \
        contract    'features/287-message-stats-bin-counter-data-model.md section R3.2 - derivation table names the sidecar source for min under -mdm bin'

    current_scenario="prose:max-mentions-bin-sidecar"
    echo "[$current_scenario]"
    out=$(run_ltl "prose-max" --explain max)
    out="${out#*:}"
    check_capture_warnings "$out"
    assert_line "$out" \
        pattern     'bin counter path maintains a running max sidecar' \
        asserts     "--explain max compute section describes the bin-path sidecar source post-#287" \
        produced_by '$explain_max_compute in ltl' \
        contract    'features/287-message-stats-bin-counter-data-model.md section R3.2'

    # --- iqr: data-model dependency must be stated ---
    current_scenario="prose:iqr-mentions-both-models"
    echo "[$current_scenario]"
    out=$(run_ltl "prose-iqr" --explain iqr)
    out="${out#*:}"
    check_capture_warnings "$out"
    assert_line "$out" \
        pattern     'within-bucket interpolation' \
        asserts     "--explain iqr describes the data-model dependency of its precision; within-bucket interpolation language identifies the bin-counter path" \
        produced_by '$explain_iqr_compute in ltl' \
        contract    'features/272-percentile-algorithm-industry-grounding.md - both algorithms must be discoverable from --explain.'

    # --- percentiles: both algorithms named + surface defaults stated + -ep absent ---
    current_scenario="prose:percentiles-names-both-algorithms"
    echo "[$current_scenario]"
    out=$(run_ltl "prose-percentiles" --explain percentiles)
    out="${out#*:}"
    check_capture_warnings "$out"
    assert_line "$out" \
        pattern     'exponential interpolation within the bucket' \
        asserts     "--explain percentiles names the bin-counter algorithm by its locked term per #272 + #187 Decision 1" \
        produced_by '$explain_percentiles_compute in ltl' \
        contract    'features/272-percentile-algorithm-industry-grounding.md section Locked decisions - algorithm-name text is the user-facing identifier the harness oracle dispatches on (#280); pinning here prevents drift.'

    assert_line "$out" \
        pattern     'nearest-rank' \
        asserts     "--explain percentiles names the raw-data-model algorithm by its locked term (#272)" \
        produced_by '$explain_percentiles_compute in ltl' \
        contract    'features/272-percentile-algorithm-industry-grounding.md section Locked decisions.'

    assert_line "$out" \
        pattern     'message-stats|per-message-key' \
        asserts     "--explain percentiles names the per-message-key surface to disambiguate which surface uses which default" \
        produced_by '$explain_percentiles_compute in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md section R12 - surface naming locked at Decision 8 consumer strings'

    # Patterns leading with '-' would be parsed as grep flags; wrap in a
    # character class so the first char is data, not an option prefix.
    assert_no_line "$out" \
        pattern     'ltl [-]ep ' \
        asserts     "--explain percentiles examples block does not reference -ep; user-facing examples guide users to the data-model selectors (-dm/-hgdm/-hmdm/-mdm)" \
        produced_by '%explain_topics{percentiles} example block in ltl' \
        contract    'Issue #266 - the data-model selectors are the locked opt-out surface for the histogram and heatmap percentile algorithms.'

    assert_line "$out" \
        pattern     '[-]mdm bin' \
        asserts     "--explain percentiles examples block includes -mdm bin to demonstrate the per-message-key bin-counter opt-in path shipped by #287" \
        produced_by '%explain_topics{percentiles} example block in ltl' \
        contract    'features/287-message-stats-bin-counter-data-model.md - opt-in flag must be discoverable from --explain examples.'

    # --- skewness and kurtosis: Welford-Pébay must be named under the bin path ---
    current_scenario="prose:skewness-mentions-welford-pebay"
    echo "[$current_scenario]"
    out=$(run_ltl "prose-skewness" --explain skewness)
    out="${out#*:}"
    check_capture_warnings "$out"
    assert_line "$out" \
        pattern     'Welford-Pébay' \
        asserts     "--explain skewness names the online central-moment accumulator family used under the bin path post-#287" \
        produced_by '$explain_skewness_compute in ltl' \
        contract    'features/287-message-stats-bin-counter-data-model.md section Algorithm appendix - Welford-Pébay (Pébay 2008) is the locked accumulator family.'

    current_scenario="prose:kurtosis-mentions-welford-pebay"
    echo "[$current_scenario]"
    out=$(run_ltl "prose-kurtosis" --explain kurtosis)
    out="${out#*:}"
    check_capture_warnings "$out"
    assert_line "$out" \
        pattern     'Welford-Pébay' \
        asserts     "--explain kurtosis names the online central-moment accumulator family used under the bin path post-#287" \
        produced_by '$explain_kurtosis_compute in ltl' \
        contract    'features/287-message-stats-bin-counter-data-model.md section Algorithm appendix.'
}

# --- Scenario: every technique-family topic renders with the page anatomy. ---
# AC2: each of the technique-family names exits 0, renders at least twenty
# lines, opens with an uppercase heading and carries a See also near the end.
# Same shape as scenario_all_topics_render, over the technique roster.
scenario_technique_topics_render() {
    local topic
    for topic in "${TECHNIQUE_GROUPS[@]}" "${TECHNIQUE_TOPICS[@]}"; do
        current_scenario="technique-topic:$topic"
        echo "[$current_scenario]"
        local result
        result=$(run_ltl "tech-$topic" --explain "$topic")
        local ec="${result%%:*}"
        local out="${result#*:}"
        check_capture_warnings "$out"

        assert_exit "$ec" 0 \
            asserts     "ltl --explain $topic exits 0 after emitting the technique-family page" \
            produced_by 'adapt_to_command_line_options() in ltl (--explain dispatch block)' \
            contract    'Issue #504 AC2: every technique-family topic is reachable by the distinctive words of its name in kebab case'

        assert_min_lines "$out" 20 \
            asserts     "Technique-family topic '$topic' renders at least 20 lines of content" \
            produced_by 'render_blocks() in ltl iterating over %explain_topics{$topic}' \
            contract    'Issue #504 AC2: a technique-family page carries the full anatomy, not a stub'

        # Heading is the full name uppercased; the topic name is the
        # distinctive words, so the heading is asserted per topic rather
        # than derived from the name.
        assert_line "$out" \
            pattern     '^[A-Z][A-Z ()./-]*$' \
            asserts     "Technique-family topic '$topic' opens with an uppercase heading" \
            produced_by 'render_heading() in ltl (block of type "heading" produced by help_heading)' \
            contract    'Issue #504 AC2: the first block of every technique-family page is an uppercase heading carrying the full name'

        assert_line "$out" \
            pattern     '^  See also$' \
            asserts     "Technique-family topic '$topic' carries a See also section near the end" \
            produced_by '%explain_topics in ltl (final block of the technique-family page anatomy)' \
            contract    'Issue #504 AC2, AC3, AC4: See also closes every technique-family page'
    done
}

# --- Scenario: technique page anatomy (AC3). ---
# A technique page renders, in order, a paragraph, a "The signal"
# subheading followed by a pre block, a "How to read it" subheading, a
# "Command" subheading followed by a pre block, and See also; and carries
# no "How ltl computes this" subheading, because a technique is not
# computed.
scenario_technique_page_anatomy() {
    local topic
    for topic in "${TECHNIQUE_TOPICS[@]}"; do
        current_scenario="technique-anatomy:$topic"
        echo "[$current_scenario]"
        local result
        result=$(run_ltl "tech-anatomy-$topic" --explain "$topic")
        local out="${result#*:}"
        check_capture_warnings "$out"

        local sub
        for sub in 'The signal' 'How to read it' 'Command' 'See also'; do
            assert_line "$out" \
                pattern     "^  ${sub}\$" \
                asserts     "Technique page '$topic' carries the '$sub' subheading" \
                produced_by 'render_subheading() in ltl (technique page anatomy in %explain_topics)' \
                contract    'Issue #504 AC3: the technique page anatomy is question, The signal, How to read it, Command, See also'
        done

        assert_no_line "$out" \
            pattern     '^  How ltl computes this$' \
            asserts     "Technique page '$topic' carries no 'How ltl computes this' section; a technique is not computed" \
            produced_by '%explain_topics in ltl (technique pages drop the statistics family compute section)' \
            contract    'Issue #504 AC3, R4: the compute section belongs to the statistics family only'

        # Section order. The four subheadings must appear in the anatomy
        # order; a page that carries them all in the wrong order reads as
        # a different page.
        local order
        order=$(grep -nE '^  (The signal|How to read it|Command|See also)$' "$out" | sed 's/.*:  //' | tr '\n' '|')
        if [[ "$order" == "The signal|How to read it|Command|See also|" ]]; then
            echo "  PASS  $current_scenario :: anatomy order"
            pass=$((pass + 1))
        else
            echo "  FAIL  $current_scenario"
            echo "        expected order: The signal|How to read it|Command|See also|"
            echo "        got:            $order"
            echo "        asserts:     A technique page renders its sections in the anatomy order: the question, The signal, How to read it, Command, See also."
            echo "        produced_by: %explain_topics in ltl (block order of the technique page)"
            echo "        contract:    Issue #504 AC3, R4: the order is the page contract, not just the presence of the sections"
            fail=$((fail + 1))
            failures+=("$current_scenario :: anatomy order was '''$order'''")
        fi
    done
}

# --- Scenario: group page anatomy (AC4). ---
# A group page renders a paragraph, a "When to use it" subheading, a
# table, and See also; the table's data-row count equals the number of
# techniques the roster gives that group.
scenario_technique_group_anatomy() {
    local group
    for group in "${TECHNIQUE_GROUPS[@]}"; do
        current_scenario="technique-group:$group"
        echo "[$current_scenario]"
        local result
        result=$(run_ltl "tech-group-$group" --explain "$group")
        local out="${result#*:}"
        check_capture_warnings "$out"

        local sub
        for sub in 'When to use it' 'Techniques' 'See also'; do
            assert_line "$out" \
                pattern     "^  ${sub}\$" \
                asserts     "Group page '$group' carries the '$sub' subheading" \
                produced_by 'render_subheading() in ltl (group page anatomy in %explain_topics)' \
                contract    'Issue #504 AC4: a group page says what the grouping is, when to use it, and lists its techniques'
        done

        assert_line "$out" \
            pattern     '┌' \
            asserts     "Group page '$group' renders its technique listing as a table" \
            produced_by 'render_table() in ltl using %histogram_box_sets{light} glyphs' \
            contract    'Issue #504 AC4: the technique listing is a table block, so it reflows with the terminal'

        # Row count: data rows are the table body lines carrying a topic
        # name in the first cell. Count the verticals-delimited body rows
        # between the header separator and the bottom border.
        # The group's registry subheading is its name title-cased; the
        # topic name is the same word lower-cased.
        local group_label
        group_label="$(tr '[:lower:]' '[:upper:]' <<< "${group:0:1}")${group:1}"
        local expected
        expected=$(technique_count_for_group "$group_label")
        if [[ -z "$expected" || "$expected" -eq 0 ]]; then
            echo "  FAIL  $current_scenario"
            echo "        the registry lists no techniques under the '$group_label' group"
            echo "        asserts:     The registry lists each technique group's own techniques beneath its subheading."
            echo "        produced_by: print_explain_registry() in ltl iterating @explain_groups"
            echo "        contract:    Issue #504 AC4: a group with no techniques in the registry means the anchor moved or the group is empty; an unfound anchor is a failure, never a pass"
            fail=$((fail + 1))
            failures+=("$current_scenario :: no techniques found under $group_label in the registry")
            continue
        fi
        local rows
        rows=$(awk '/^  ├/{body=1; next} /^  └/{body=0} body && /^  │/{n++} END{print n+0}' "$out")
        if [[ "$rows" == "$expected" ]]; then
            echo "  PASS  $current_scenario :: technique rows=$rows (== $expected)"
            pass=$((pass + 1))
        else
            echo "  FAIL  $current_scenario"
            echo "        expected $expected technique rows, got $rows"
            echo "        asserts:     The group page'''s Techniques table lists exactly the techniques the roster gives that group."
            echo "        produced_by: %explain_topics in ltl (the group page'''s table block rows)"
            echo "        contract:    Issue #504 AC4: the table row count equals the group'''s technique count; a technique added to a group without a row here is a listing the analyst cannot reach"
            fail=$((fail + 1))
            failures+=("$current_scenario :: $rows technique rows (expected $expected)")
        fi
    done
}

# --- Scenario: technique signals survive to raw output with ANSI intact. ---
# AC6: each technique page'''s signal is a generated block drawn from the
# tool'''s own colour definitions; a CSI count over the raw bytes fails if
# the escapes are stripped at authoring time. Same method as
# scenario_visualization_charts.
scenario_technique_signals() {
    local topic
    for topic in "${TECHNIQUE_TOPICS[@]}"; do
        current_scenario="technique-signal:$topic"
        echo "[$current_scenario]"
        local raw_file="$TMP_DIR/tech-signal-$topic.raw"
        set +e
        "$LTL" --explain "$topic" > "$raw_file" 2>"$raw_file.stderr"
        set -e
        check_stderr_warnings "$raw_file.stderr"

        local ansi_count
        ansi_count=$(perl -e '''
            my ($file) = @ARGV;
            open my $fh, "<", $file or die $!;
            local $/;
            my $content = <$fh>;
            close $fh;
            my $count = () = $content =~ /\x1b\[/g;
            print $count;
        ''' "$raw_file")

        if [[ "$ansi_count" -ge 20 ]]; then
            echo "  PASS  $current_scenario :: ANSI sequences=$ansi_count (>=20)"
            pass=$((pass + 1))
        else
            echo "  FAIL  $current_scenario"
            echo "        expected >= 20 ANSI CSI sequences in raw output, found $ansi_count"
            echo "        asserts:     Technique topic '$topic' embeds a generated signal block whose colour escapes survive assembly and reach the pager unmolested."
            echo "        produced_by: the signal generator for $topic in ltl (built from %colors, beside the heatmap and histogram example builders)"
            echo "        contract:    Issue #504 AC6, R5: the signal is rendered from the tool'''s own colour definitions, not described in prose; this guards against accidental stripping at authoring time"
            fail=$((fail + 1))
            failures+=("$current_scenario :: only $ansi_count ANSI sequences (expected >=20)")
        fi
    done
}

# --- Scenario: the registry lists the technique family (AC1). ---
scenario_technique_registry() {
    current_scenario="technique-registry"
    echo "[$current_scenario]"
    local result
    result=$(run_ltl "tech-registry" --explain)
    local out="${result#*:}"
    check_capture_warnings "$out"

    assert_line "$out" \
        pattern     '^ANALYSIS TECHNIQUES$' \
        asserts     "Registry emits the ANALYSIS TECHNIQUES top-level section heading" \
        produced_by 'print_explain_registry() in ltl emitting help_heading per category transition' \
        contract    'Issue #504 AC1, R1: the technique family is a fourth category beside STATISTICS, VISUALIZATIONS and METHODOLOGY'

    local group
    for group in Time Population Shape Comparison Load Correlation; do
        assert_line "$out" \
            pattern     "^  ${group}\$" \
            asserts     "Registry emits the '$group' group subheading under ANALYSIS TECHNIQUES" \
            produced_by 'print_explain_registry() in ltl iterating @explain_groups' \
            contract    'Issue #504 AC1, R1: the technique family is organised in six groups'
    done

    local topic
    for topic in "${TECHNIQUE_GROUPS[@]}" "${TECHNIQUE_TOPICS[@]}"; do
        assert_line "$out" \
            pattern     "^    ${topic}[[:space:]]+[^[:space:]]" \
            asserts     "Registry lists technique-family topic '$topic' with a one-line summary" \
            produced_by 'print_explain_registry() in ltl iterating @explain_groups{topics} against %explain_summary' \
            contract    'Issue #504 AC1, R2: every technique-family topic is listed and summarised, so the table of contents is the index'
    done

    # AC8: none of the technique-family topics may leak into the
    # statistics index, which stays the statistics index.
    local stats_out
    result=$(run_ltl "tech-help-stats" --help statistics)
    stats_out="${result#*:}"
    check_capture_warnings "$stats_out"
    for topic in "${TECHNIQUE_GROUPS[@]}" "${TECHNIQUE_TOPICS[@]}"; do
        assert_no_line "$stats_out" \
            pattern     "^    ${topic}[[:space:]]" \
            asserts     "Technique-family topic '$topic' must not appear in ltl --help statistics" \
            produced_by 'print_help_statistics() in ltl (stats-only slice of @explain_groups)' \
            contract    'Issue #504 AC8, R7: the leading-statistics slice keeps describing what it names as the registry grows'
    done
}

# --- Scenario: no page is introduced as something it is not (AC7). ---
# The single fixed intro sentence used to tell every reader they were
# looking at a per-message statistic ranked by -so. Each category now
# carries its own, and the technique groups carry a further one.
scenario_topic_intro_matches_category() {
    local topic
    for topic in "${TECHNIQUE_GROUPS[@]}" "${TECHNIQUE_TOPICS[@]}"; do
        current_scenario="intro:$topic"
        echo "[$current_scenario]"
        local result
        result=$(run_ltl "intro-$topic" --explain "$topic")
        local out="${result#*:}"
        check_capture_warnings "$out"

        assert_no_line "$out" \
            pattern     'one of the statistics ltl computes for every message entry' \
            asserts     "Technique-family topic '$topic' is not introduced as a per-message statistic" \
            produced_by 'print_explain_topic() in ltl (per-category intro selected via explain_topic_category())' \
            contract    'Issue #504 AC7, R6: no topic is introduced by prose that misdescribes it'

        assert_line "$out" \
            pattern     'analysis technique' \
            asserts     "Technique-family topic '$topic' is introduced as analysis-technique content" \
            produced_by 'print_explain_topic() in ltl (%explain_topic_intro, techniques entry)' \
            contract    'Issue #504 AC7, R6: every page tells the reader what kind of page it is'
    done

    # The existing non-statistic topics keep an introduction of their own,
    # and it is no longer the statistics sentence.
    local pair
    for pair in 'heatmap:one of the charts ltl draws' 'histogram:one of the charts ltl draws' 'classification:the reasoning behind a figure'; do
        topic="${pair%%:*}"
        local expect="${pair#*:}"
        current_scenario="intro:$topic"
        echo "[$current_scenario]"
        result=$(run_ltl "intro-$topic" --explain "$topic")
        out="${result#*:}"
        check_capture_warnings "$out"

        assert_no_line "$out" \
            pattern     'one of the statistics ltl computes for every message entry' \
            asserts     "Topic '$topic' is no longer introduced as a per-message statistic" \
            produced_by 'print_explain_topic() in ltl (per-category intro selected via explain_topic_category())' \
            contract    'Issue #504 AC7, R6: the fixed statistics sentence was wrong for every non-statistic topic'

        assert_line "$out" \
            pattern     "$expect" \
            asserts     "Topic '$topic' is introduced as what it is" \
            produced_by 'print_explain_topic() in ltl (%explain_topic_intro)' \
            contract    'Issue #504 AC7, R6: each category carries an introduction describing that category'
    done

    # A statistics topic keeps the sentence that is true of it.
    current_scenario="intro:mean"
    echo "[$current_scenario]"
    result=$(run_ltl "intro-mean" --explain mean)
    out="${result#*:}"
    check_capture_warnings "$out"
    assert_line "$out" \
        pattern     'one of the statistics ltl computes for every message entry' \
        asserts     "A statistics topic keeps the statistics introduction" \
        produced_by 'print_explain_topic() in ltl (%explain_topic_intro, statistics entry)' \
        contract    'Issue #504 AC7, R6: the fix narrows the sentence to the topics it is true of; it does not remove it'
}

# --- Scenario: the documented capabilities are stated on their pages (AC9). ---
scenario_technique_documented_capabilities() {
    current_scenario="documented:cross-log-marker-states"
    echo "[$current_scenario]"
    local result
    result=$(run_ltl "documented-xlog" --explain cross-log-correlation)
    local out="${result#*:}"
    check_capture_warnings "$out"

    # The three marker states, each named as what the analyst sees.
    local state
    for state in 'green tick' 'bright-green background' 'red chi'; do
        assert_line "$out" \
            pattern     "$state" \
            asserts     "The cross-log page names the '$state' file-list marker state" \
            produced_by 'print_summary_table() in ltl draws the marker column; the page documents it' \
            contract    'Issue #504 AC9, R8: file attribution under filter and highlight works today and was documented nowhere; all three marker states are named'
    done

    assert_line "$out" \
        pattern     'include, exclude and highlight criterion' \
        asserts     "The cross-log page says every include, exclude and highlight criterion drives the markers, not only a text pattern" \
        produced_by '%explain_topics in ltl (the cross-log page How to read it section)' \
        contract    'Issue #504 AC9, R8: the numeric thresholds and the outcome filters drive the markers as much as a pattern does'
}

# --- Scenario: no internals leak into the technique pages (AC10). ---
# No Perl identifier, issue number or decision label may reach a rendered
# page or the mirror. The page is user-facing prose.
scenario_technique_no_internals() {
    local topic
    for topic in "${TECHNIQUE_GROUPS[@]}" "${TECHNIQUE_TOPICS[@]}"; do
        current_scenario="no-internals:$topic"
        echo "[$current_scenario]"
        local result
        result=$(run_ltl "internals-$topic" --explain "$topic")
        local out="${result#*:}"
        check_capture_warnings "$out"

        # Issue references (#NNN) and decision labels (D5, F12, AC3, R7)
        # standing as their own token.
        assert_no_line "$out" \
            pattern     '#[0-9]{2,}' \
            asserts     "Technique-family topic '$topic' carries no issue number" \
            produced_by '%explain_topics in ltl (technique-family content)' \
            contract    'Issue #504 AC10, R10: user-facing prose carries no issue numbers'

        assert_no_line "$out" \
            pattern     '(^|[^A-Za-z0-9_])(D|F|R|AC)[0-9]+([^A-Za-z0-9_]|$)' \
            asserts     "Technique-family topic '$topic' carries no decision, finding, requirement or acceptance-criterion label" \
            produced_by '%explain_topics in ltl (technique-family content)' \
            contract    'Issue #504 AC10, R10: decision labels belong to the feature record, never to a rendered page'

        # Perl identifiers: a sigil-prefixed name, or a sub call written
        # with parentheses.
        assert_no_line "$out" \
            pattern     '[%$@][a-z_]+_[a-z_]+' \
            asserts     "Technique-family topic '$topic' names no Perl variable" \
            produced_by '%explain_topics in ltl (technique-family content)' \
            contract    'Issue #504 AC10, R10: the page describes what the analyst sees, never how it is stored'

        assert_no_line "$out" \
            pattern     '[a-z_]+_[a-z_]+\(\)' \
            asserts     "Technique-family topic '$topic' names no Perl sub" \
            produced_by '%explain_topics in ltl (technique-family content)' \
            contract    'Issue #504 AC10, R10: internals stay out of user-facing prose'
    done
}

# --- Scenario: every technique-family topic is mirrored (AC11). ---
# docs/explain/techniques.md carries the whole family in one file, the
# family precedent docs/explain/statistics.md sets.
scenario_technique_mirror() {
    current_scenario="mirror:techniques"
    echo "[$current_scenario]"
    local mirror="$REPO_DIR/docs/explain/techniques.md"

    if [[ ! -f "$mirror" ]]; then
        echo "  FAIL  $current_scenario"
        echo "        asserts:     Every technique-family topic is mirrored under docs/explain/, as the statistics, heatmap, histogram and classification topics are."
        echo "        produced_by: docs/explain/techniques.md (the family mirror)"
        echo "        contract:    Issue #504 AC11, R9: the mirror is where the analyst follows a cross-reference; a missing file breaks every link"
        echo "        (not found: $mirror)"
        fail=$((fail + 1))
        failures+=("$current_scenario :: docs/explain/techniques.md missing")
        return
    fi

    local topic
    for topic in "${TECHNIQUE_GROUPS[@]}" "${TECHNIQUE_TOPICS[@]}"; do
        assert_line "$mirror" \
            pattern     "^#{2,3} .*[\`]${topic}[\`]" \
            asserts     "The mirror carries a section for technique-family topic '$topic' addressed by its topic name" \
            produced_by 'docs/explain/techniques.md (one section per topic, in roster order)' \
            contract    'Issue #504 AC11, R9: the mirror holds a page per topic so a wiki reader reaches the same content as the terminal'
    done

    # AC10 over the mirror: the same no-internals rule.
    assert_no_line "$mirror" \
        pattern     '(^|[^A-Za-z0-9_])(D|F|R|AC)[0-9]+([^A-Za-z0-9_]|$)' \
        asserts     "The mirror carries no decision, finding, requirement or acceptance-criterion label" \
        produced_by 'docs/explain/techniques.md' \
        contract    'Issue #504 AC10, R10: the no-internals rule applies to the mirror as much as to the rendered page'

    assert_no_line "$mirror" \
        pattern     '[%$@][a-z_]+_[a-z_]+' \
        asserts     "The mirror names no Perl variable" \
        produced_by 'docs/explain/techniques.md' \
        contract    'Issue #504 AC10, R10: the mirror is user-facing prose'
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
scenario_table_border_alignment
echo ""
scenario_visualization_charts
echo ""
scenario_short_alias
echo ""
scenario_pager_ansi
echo ""
scenario_data_model_aware_prose
echo ""
scenario_ascii_and_ansi_modes
echo ""
scenario_technique_registry
echo ""
scenario_technique_topics_render
echo ""
scenario_technique_page_anatomy
echo ""
scenario_technique_group_anatomy
echo ""
scenario_technique_signals
echo ""
scenario_topic_intro_matches_category
echo ""
scenario_technique_documented_capabilities
echo ""
scenario_technique_no_internals
echo ""
scenario_technique_mirror

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
