#!/usr/bin/env bash
# validate-summary-contribution-bar.sh — the category rows of the run summary
# carry a contribution bar drawn over the row's own text, in the category's
# own colour (Issue #448).
#
# The bar is what makes the distribution readable without going through the
# numbers, and it exists only in the escape sequences: it is drawn by filling
# the background behind the row's leading characters, so a run with colour
# stripped shows the same glyphs whether the bar is there or not. The snapshot
# references (tests/reference-output/) strip ANSI before comparing, so no
# golden can assert this — which is why this harness exists.
#
# What it holds:
#
#   - the fill is present, in the category's own colour, and its extent is the
#     category's share of the largest category rounded to whole characters;
#   - the colour is reset before the table's trailing padding, so the fill
#     cannot bleed into the file-details pane printed beside the table on the
#     same physical line;
#   - each variant does what it says: -sbo emits no fill, -sbm fills without
#     the category colours, -sbr fills from the right edge, -sba scales
#     against every included line, -sbl scales logarithmically;
#   - every colour has a highlighted twin carrying a background, so a category
#     whose colour is neither one of the five that were hand-mapped nor a
#     basic ANSI colour still gets a fill.
#
# This is a RENDER-INVARIANT harness (tests/HARNESS-DESIGN.md § Render-invariant
# harnesses): the rendered row, escape sequences included, is the surface under
# test. It asserts properties of that surface — which characters are inside the
# fill, where the reset falls — never a frozen copy of it.
#
# Colour is pinned on both sides through tests/lib/colour-env.sh
# (HARNESS-DESIGN.md § Colour rendering is controlled, never inherited).
# The bar is not gated by help_ansi_enabled(): like the timeline's own bars it
# renders whether or not stdout is a terminal, so the assertions below hold
# under both colour modes and the harness proves that rather than assuming it.
#
# Each assertion records, per HARNESS-DESIGN.md § Self-documenting assertions:
#   - asserts:     the invariant being tested
#   - produced_by: where in ltl it is produced (function name, never a line)
#   - contract:    the source that makes the invariant stable
# All three are surfaced on failure.
#
# Usage: ./tests/validate-summary-contribution-bar.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

LTL="$REPO_DIR/ltl"
PERL="${PERL:-/opt/homebrew/bin/perl}"
command -v "$PERL" >/dev/null 2>&1 || PERL=perl

# Invocation shape (HARNESS-DESIGN.md § Invocation coherence): every assertion
# reads one category row of the run summary. That row is a total over the whole
# run and does not depend on the time axis at all, so the runs use the coarsest
# bucket with empty buckets suppressed, over a 53-line fixture spanning one
# minute, and -n 1 keeps the messages table to a single row. -lf pins the access
# format so the run does not depend on filename evidence and emits no
# unit-ambiguity note. -ni keeps the developer's ltl-index.csv out of the run.
#
# The fixture's four categories are deliberately far apart — 40 / 8 / 4 / 1 of
# 53 lines — so the four bar lengths are distinct at every scale and a bar drawn
# against the wrong reference cannot coincidentally land on the right length.
FIXTURE="$REPO_DIR/tests/fixtures/category-contribution-skew.txt"
ACCESS_FORMAT="tomcat_access_with_duration"
WIDTH=140

# The category row: two spaces of table padding, then 41 characters of row.
ROW_WIDTH=41

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"

neutralize_colour_env

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"; exit 1
fi
if [[ ! -f "$FIXTURE" ]]; then
    echo "ERROR: fixture not found: $FIXTURE"; exit 1
fi

TMP_DIR=$(mktemp -d); trap 'rm -rf "$TMP_DIR"' EXIT

pass=0
fail=0
failures=()
current_scenario=""

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

# Capture one ltl render into $1 with its escape sequences INTACT — they are
# what this harness is about — and its stderr into $1.stderr. Fails hard on a
# non-zero exit or an empty capture (HARNESS-DESIGN.md Trap 1).
capture_render() {
    local outfile="$1"; shift
    local mode="$1"; shift
    local stderrfile="$outfile.stderr"
    local runner=with_ansi_colour
    [[ "$mode" == "ascii" ]] && runner=with_ascii_colour
    set +e
    ( cd "$TMP_DIR" && "$runner" "$LTL" "$@" ) >"$outfile" 2>"$stderrfile"
    local status=$?
    set -e
    if [[ "$status" -ne 0 ]]; then
        echo "  FAIL  $current_scenario :: ltl exited $status while rendering" >&2
        sed 's/^/        /' "$stderrfile" >&2
        exit 1
    fi
    if [[ ! -s "$outfile" ]]; then
        echo "  FAIL  $current_scenario :: rendered output is empty" >&2
        exit 1
    fi
    if ! assert_no_runtime_warnings "$stderrfile" "$current_scenario"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
    fi
}

# Read one category row and report what the bar does to it, as a set of
# key=value fields the individual checks below assert against:
#
#   extent=N        characters covered by the fill, counted in glyphs
#   side=left|right which end of the row the fill starts from
#   fill=<sgr>      the SGR parameters that opened the fill
#   text=<glyphs>   the row with every escape sequence removed
#   tail_reset=yes  the row's escapes end with a reset, so nothing the table
#                   prints after the row inherits the fill
#
# The row is located by its label in the ANSI-stripped text, then walked
# character by character, tracking whether a background is currently set.
row_bar_report() {
    "$PERL" -e '
        my ($render, $label, $row_width) = @ARGV;
        open my $fh, "<", $render or die "cannot open $render: $!\n";
        my $row;
        while (my $line = <$fh>) {
            ( my $plain = $line ) =~ s/\e\[[0-9;]*m//g;
            next unless length($plain) >= 2 + $row_width;
            next unless substr($plain, 0, 2) eq "  ";
            next unless substr($plain, 2, $row_width) =~ /^\Q$label\E\s/;
            # Keep only the table row: the file-details pane is printed on the
            # same physical line, past the row boundary, and is not ours.
            my ($glyphs, $kept, $bg) = (0, "", "");
            my $tail_reset = 0;
            my @fill;      # per glyph index: is a background set?
            my $pos = 0;
            # Two leading spaces of table padding sit before the row.
            while ($line =~ /\G(\e\[([0-9;]*)m|.)/gs) {
                my ($tok, $sgr) = ($1, $2);
                if (defined $sgr) {
                    $kept .= $tok;
                    if ($sgr =~ /(?:^|;)(?:0|49)(?:;|$)/ || $sgr eq "") { $bg = "" }
                    elsif ($sgr =~ /(?:^|;)48;5;\d+(?:;|$)/) { $bg = $sgr }
                    elsif ($sgr =~ /(?:^|;)7(?:;|$)/)        { $bg = $sgr }
                    $tail_reset = ( $sgr eq "0" || $sgr =~ /(?:^|;)0(?:;|$)/ ) ? 1 : 0;
                    next;
                }
                $pos++;
                next if $pos <= 2;                    # table padding
                last if $pos > 2 + $row_width;        # past the row
                $glyphs++;
                push @fill, ( $bg ne "" ? 1 : 0 );
            }
            my $extent = 0;
            $extent++ for grep { $_ } @fill;
            my ($side) = ("none");
            if ($extent > 0) {
                $side = $fill[0] ? "left" : "right";
                # The filled characters must be contiguous: a bar with a hole
                # in it is not a bar.
                my $seen_end = 0;
                my $prev = $fill[0];
                for my $f (@fill) { $seen_end++ if $f != $prev; $prev = $f }
                if ($seen_end > 1) { print "fill is not contiguous in row [$label]\n"; exit 1 }
            }
            my ($fill_sgr) = ( $kept =~ /(\e\[(?:[0-9;]*;)?(?:48;5;\d+|7)m)/ );
            $fill_sgr = defined $fill_sgr ? do { (my $s = $fill_sgr) =~ s/\e/ESC/; $s } : "none";
            ( my $text = $line ) =~ s/\e\[[0-9;]*m//g;
            $text = substr($text, 2, $row_width);
            $text =~ s/\s+$//;
            printf "extent=%d side=%s fill=%s tail_reset=%s text=%s\n",
                $extent, $side, $fill_sgr, ($tail_reset ? "yes" : "no"), $text;
            exit 0;
        }
        close $fh;
        print "no category row labelled [$label] in the render\n";
        exit 1;
    ' "$1" "$2" "$3"
}

# Assert one field of the row report equals an expected value.
check_row_field() {
    local render="$1" label="$2" field="$3" expected="$4"
    local report
    if ! report=$(row_bar_report "$render" "$label" "$ROW_WIDTH"); then
        echo "$report"; return 1
    fi
    # text= is emitted last and carries spaces, so it is read to end of line;
    # every other field is a single token.
    local got
    if [[ "$field" == "text" ]]; then
        got=$(printf '%s\n' "$report" | sed -nE "s/.*(^| )text=(.*)$/\2/p")
    else
        got=$(printf '%s\n' "$report" | sed -nE "s/.*(^| )$field=([^ ]*).*/\2/p")
    fi
    if [[ "$got" == "$expected" ]]; then
        echo "row [$label] $field=$got"
        return 0
    fi
    echo "row [$label] $field is [$got], expected [$expected]"
    echo "  report: $report"
    return 1
}

# The colour table gives every colour a highlighted twin, and the twin of a
# category colour carries a background. This is what lets the bar be filled in
# a category's own colour without a per-category fill table: the twin is
# derived from the foreground by one rule.
check_every_category_has_a_fill() {
    "$PERL" -e '
        my ($ltl) = @ARGV;
        open my $fh, "<", $ltl or die "cannot open $ltl: $!\n";
        my $src = do { local $/; <$fh> };
        close $fh;
        # Everything the twins are built from is sliced out of ltl and run
        # here, the construction loop included, so this checks what the tool
        # actually builds rather than a second implementation of the rule.
        my ($levels) = $src =~ /(^my \@log_levels = \(.*?^\);)/ms;
        my ($table)  = $src =~ /(^my %colors = \(.*?^\);)/ms;
        my ($sat)    = $src =~ /(^my \@ansi_saturated_256 = .*?;)/ms;
        my ($derive) = $src =~ /(^sub derive_background_color \{.*?^\}$)/ms;
        my ($build)  = $src =~ /(^foreach my \$key \(keys %colors\) \{.*?^\}$)/ms;
        my %part = ( "\@log_levels" => $levels, "%colors" => $table,
                     "\@ansi_saturated_256" => $sat,
                     "derive_background_color()" => $derive,
                     "the -HL twin construction loop" => $build );
        my @missing = sort grep { !defined $part{$_} } keys %part;
        if (@missing) {
            print "could not read out of ltl: @missing\n";
            exit 1;
        }
        s/^my // for ($levels, $table, $sat);
        our (@log_levels, %colors, @ansi_saturated_256);
        eval "$levels\n$table\n$sat\n$derive\n$build; 1"
            or do { print "could not evaluate the colour table: $@\n"; exit 1 };

        # Categories that reach the summary table, excluding the derived rate
        # rows and the normalisation placeholder, which are not categories.
        my @categories = grep { !/^(empty|err-rate|msg-rate)$/ }
                         grep { !/-HL$/ } @log_levels;
        unless (@categories) { print "no categories found in \@log_levels\n"; exit 1 }

        my @without;
        for my $category (@categories) {
            my $fg = $colors{$category};
            unless (defined $fg) { push @without, "$category (no colour at all)"; next }
            my $bg = derive_background_color($fg);
            push @without, $category unless defined $bg;
            # The -HL twin the renderer actually reads must carry that background.
            my $twin = $colors{"$category-HL"};
            push @without, "$category-HL (twin missing the background)"
                if defined $bg && ( !defined $twin || index($twin, $bg) < 0 );
        }
        if (@without) {
            print "categories with no highlighted fill: @without\n";
            exit 1;
        }
        printf "all %d categories have a highlighted twin carrying a derived background\n",
            scalar @categories;
        exit 0;
    ' "$1"
}

run_ltl_args() {
    printf '%s\n' --disable-progress -ni -lf "$ACCESS_FORMAT" \
        -bs 1440 -oe -n 1 --terminal-width "$WIDTH" "$@" "$FIXTURE"
}

BAR_PRODUCED='summary_category_row() and summary_bar_extent() in ltl, called from print_summary_table()'

# ---------------------------------------------------------------------------
# Scenario: the default bar — largest category full width, the rest relative.
#
# The fixture's categories hold 40, 8, 4 and 1 of 53 lines. Normalised to the
# largest, over a 41-character row, that is 41, 8, 4 and 1 characters.
# ---------------------------------------------------------------------------

current_scenario="default-bar-normalised-to-the-largest-category"
echo "[$current_scenario]"

DEFAULT_RENDER="$TMP_DIR/default.txt"
# shellcheck disable=SC2046
capture_render "$DEFAULT_RENDER" ansi $(run_ltl_args)

while IFS='|' read -r label extent; do
    assert_command \
        command     "check_row_field '$DEFAULT_RENDER' '$label' extent '$extent'" \
        label       "[$label] fills $extent of $ROW_WIDTH characters" \
        asserts     'Each category bar is as long as that category is large relative to the LARGEST category, so the biggest row spans the row and every other is drawn against it. Normalising to the largest is what gives the small contributors the whole row width to be told apart in: against the whole population a dominant category leaves most of the width unused and the rest collapse into a character or two each. The printed percentage carries the absolute share either way.' \
        produced_by "$BAR_PRODUCED" \
        contract    'features/448-category-summary-share-and-bar.md § D3 — default bar length is normalised to the largest category'
done <<'ROWS'
2xx Success|41
3xx Redirection|8
4xx Client error|4
5xx Server error|1
ROWS

assert_command \
    command     "check_row_field '$DEFAULT_RENDER' '2xx Success' side left" \
    label       'the bar is drawn from the left edge of the row by default' \
    asserts     'The default direction is left to right, the direction the row is read in. -sbr is what draws it from the other end.' \
    produced_by "$BAR_PRODUCED" \
    contract    'features/448-category-summary-share-and-bar.md § D5 — -sbr reverses the direction, so the default is the other one'

for label in '2xx Success' '5xx Server error'; do
    assert_command \
        command     "check_row_field '$DEFAULT_RENDER' '$label' tail_reset yes" \
        label       "[$label] resets its colour before the table's trailing padding" \
        asserts     "The file-details pane is printed on the same physical line as the table row. A fill left open at the end of the row would run straight through the table's trailing padding and into that pane, colouring text that has nothing to do with the category. The row's escapes therefore end with a reset." \
        produced_by "$BAR_PRODUCED" \
        contract    'features/448-category-summary-share-and-bar.md § D4 — the colour is reset before the padding so the fill never bleeds into the file-details pane'
done

assert_command \
    command     "check_row_field '$DEFAULT_RENDER' '5xx Server error' fill 'ESC[48;5;196m'" \
    label       'the bar is filled in the category own colour' \
    asserts     "The fill is the category's own colour, so a row is recognisable by the same colour whether it is read as text or as a bar. 5xx is red, and red's highlighted twin fills with the saturated 256-colour red derived from that foreground rather than from a per-category table." \
    produced_by 'derive_background_color() in ltl, applied to every colour when the -HL twins are built' \
    contract    'features/448-category-summary-share-and-bar.md § D2 — the fill colour is derived from the category foreground by one rule for every colour'

# ---------------------------------------------------------------------------
# Scenario: every category can be filled.
#
# The gap this closes: five foreground codes were mapped to a background by
# hand and every other colour fell back to the terminal default, so cyan
# (CREATE) and any 256-colour category had no highlighted background at all.
# ---------------------------------------------------------------------------

current_scenario="every-category-colour-has-a-highlighted-twin"
echo "[$current_scenario]"

assert_command \
    command     "check_every_category_has_a_fill '$LTL'" \
    label       'every category colour has a highlighted twin carrying a background' \
    asserts     'The bar is filled with the category colour highlighted twin, so a category whose twin carries no background would render with no bar at all — silently, and only for that category. One derivation rule covers every colour ltl defines, including the 256-colour ones, so a category added later inherits a fill without an entry anywhere.' \
    produced_by 'derive_background_color() in ltl, applied over %colors when the -HL twins are built' \
    contract    'features/448-category-summary-share-and-bar.md § D2 — every category colour gets a highlighted twin; no explicit per-category fill table'

# ---------------------------------------------------------------------------
# Scenario: -sbo removes the bar and leaves the numbers.
# ---------------------------------------------------------------------------

current_scenario="summary-bar-off"
echo "[$current_scenario]"

OFF_RENDER="$TMP_DIR/off.txt"
# shellcheck disable=SC2046
capture_render "$OFF_RENDER" ansi $(run_ltl_args -sbo)

for label in '2xx Success' '3xx Redirection' '5xx Server error'; do
    assert_command \
        command     "check_row_field '$OFF_RENDER' '$label' extent 0" \
        label       "[$label] has no fill under -sbo" \
        asserts     'The off switch removes the fill entirely rather than drawing it in the background colour: no character of the row carries a background.' \
        produced_by "$BAR_PRODUCED" \
        contract    'features/448-category-summary-share-and-bar.md § D5 — -sbo, no bar'
done

assert_command \
    command     "check_row_field '$OFF_RENDER' '2xx Success' text '2xx Success                    40 (75.5%)'" \
    label       'the share percentage stays when the bar is switched off' \
    asserts     'The bar and the share are separate: -sbo is about the bar, and the count with its share is still what the row says. The two are controlled independently because they answer the same question at different precisions.' \
    produced_by 'share_row_text() in ltl' \
    contract    'features/448-category-summary-share-and-bar.md § D1 — the share follows the count (pct%) convention; D5 scopes -sbo to the bar'

# ---------------------------------------------------------------------------
# Scenario: -sbm fills without the category colours.
# ---------------------------------------------------------------------------

current_scenario="summary-bar-mono"
echo "[$current_scenario]"

MONO_RENDER="$TMP_DIR/mono.txt"
# shellcheck disable=SC2046
capture_render "$MONO_RENDER" ansi $(run_ltl_args -sbm)

assert_command \
    command     "check_row_field '$MONO_RENDER' '5xx Server error' fill 'ESC[7m'" \
    label       'the fill carries no category colour under -sbm' \
    asserts     "Monochrome draws the bar in a plain reverse-video fill instead of the category's own colour, so the bar length can be judged on its own without the colours arguing with it. The category colours are not otherwise disturbed — this is a rendering choice for the bar, not a second opinion about whether colour should be emitted at all." \
    produced_by "$BAR_PRODUCED" \
    contract    'features/448-category-summary-share-and-bar.md § D5 — -sbm, plain foreground/background; D7 — it affects the category rows only'

assert_command \
    command     "check_row_field '$MONO_RENDER' '3xx Redirection' extent 8" \
    label       'the bar keeps its length under -sbm' \
    asserts     'Monochrome changes only the colour the bar is drawn in. The length is the same measurement it always was, which is the point of being able to judge it without the colours.' \
    produced_by "$BAR_PRODUCED" \
    contract    'features/448-category-summary-share-and-bar.md § D7 — -sbm is a rendering choice for the bar'

# ---------------------------------------------------------------------------
# Scenario: -sbr draws from the right edge.
# ---------------------------------------------------------------------------

current_scenario="summary-bar-reverse"
echo "[$current_scenario]"

REVERSE_RENDER="$TMP_DIR/reverse.txt"
# shellcheck disable=SC2046
capture_render "$REVERSE_RENDER" ansi $(run_ltl_args -sbr)

assert_command \
    command     "check_row_field '$REVERSE_RENDER' '3xx Redirection' side right" \
    label       'the bar starts at the right edge of the row under -sbr' \
    asserts     'Reversing the bar draws it inward from the row boundary, where the value sits, rather than outward from the label. Both directions are available so the one that reads better on real logs can be chosen by looking at them.' \
    produced_by "$BAR_PRODUCED" \
    contract    'features/448-category-summary-share-and-bar.md § D5 — -sbr, bar drawn right-to-left'

assert_command \
    command     "check_row_field '$REVERSE_RENDER' '3xx Redirection' extent 8" \
    label       'the bar keeps its length under -sbr' \
    asserts     'The direction the bar is drawn in does not change how long it is: the same share occupies the same number of characters at either end of the row.' \
    produced_by "$BAR_PRODUCED" \
    contract    'features/448-category-summary-share-and-bar.md § D5 — -sbr changes the direction only'

# ---------------------------------------------------------------------------
# Scenario: -sba scales against every included line.
#
# 40, 8, 4 and 1 of 53 lines over a 41-character row: 31, 6, 3 and 1.
# ---------------------------------------------------------------------------

current_scenario="summary-bar-absolute"
echo "[$current_scenario]"

ABSOLUTE_RENDER="$TMP_DIR/absolute.txt"
# shellcheck disable=SC2046
capture_render "$ABSOLUTE_RENDER" ansi $(run_ltl_args -sba)

while IFS='|' read -r label extent; do
    assert_command \
        command     "check_row_field '$ABSOLUTE_RENDER' '$label' extent '$extent'" \
        label       "[$label] fills $extent of $ROW_WIDTH characters under -sba" \
        asserts     'The absolute scale makes the full row width stand for every line included, so the bar lengths sum to the row and the largest category no longer reaches the end unless it holds everything. This is the reading the default trades away to give the small categories room.' \
        produced_by "$BAR_PRODUCED" \
        contract    'features/448-category-summary-share-and-bar.md § D5 — -sba, table width = 100% of lines included'
done <<'ROWS'
2xx Success|31
3xx Redirection|6
4xx Client error|3
5xx Server error|1
ROWS

# ---------------------------------------------------------------------------
# Scenario: -sbl gives the tail a visible length.
#
# The point of the log scale is that the smallest category is no longer a
# stub, so the assertion is a relationship between the rows rather than a
# fixed length: every bar is longer than it is on the linear scale, the
# ordering is preserved, and the largest still fills the row.
# ---------------------------------------------------------------------------

current_scenario="summary-bar-log"
echo "[$current_scenario]"

LOG_RENDER="$TMP_DIR/log.txt"
# shellcheck disable=SC2046
capture_render "$LOG_RENDER" ansi $(run_ltl_args -sbl)

check_log_scale_spreads_the_tail() {
    local linear="$1" logscale="$2"
    "$PERL" -e '
        my ($linear_file, $log_file, $row_width, @labels) = @ARGV;
        my %extent;
        for my $which (["linear", $linear_file], ["log", $log_file]) {
            my ($name, $file) = @$which;
            open my $fh, "<", $file or die "cannot open $file: $!\n";
            my @lines = <$fh>;
            close $fh;
            for my $label (@labels) {
                for my $line (@lines) {
                    ( my $plain = $line ) =~ s/\e\[[0-9;]*m//g;
                    next unless length($plain) >= 2 + $row_width;
                    next unless substr($plain, 2, $row_width) =~ /^\Q$label\E\s/;
                    my ($pos, $bg, $filled) = (0, "", 0);
                    while ($line =~ /\G(\e\[([0-9;]*)m|.)/gs) {
                        my ($tok, $sgr) = ($1, $2);
                        if (defined $sgr) {
                            if ($sgr =~ /(?:^|;)(?:0|49)(?:;|$)/ || $sgr eq "") { $bg = "" }
                            elsif ($sgr =~ /(?:^|;)(?:48;5;\d+|7)(?:;|$)/) { $bg = $sgr }
                            next;
                        }
                        $pos++;
                        next if $pos <= 2;
                        last if $pos > 2 + $row_width;
                        $filled++ if $bg ne "";
                    }
                    $extent{$name}{$label} = $filled;
                    last;
                }
                unless (defined $extent{$name}{$label}) {
                    print "row [$label] not found in the $name render\n";
                    exit 1;
                }
            }
        }
        # The smallest category is a single character on the linear scale and
        # must be materially longer on the log scale: that is the whole reason
        # the log scale exists.
        my $smallest = $labels[-1];
        unless ($extent{log}{$smallest} > $extent{linear}{$smallest}) {
            printf "log scale did not lengthen the smallest category [%s]: linear %d, log %d\n",
                $smallest, $extent{linear}{$smallest}, $extent{log}{$smallest};
            exit 1;
        }
        # Order is preserved: a longer bar still means a larger category.
        for my $i (1 .. $#labels) {
            if ($extent{log}{$labels[$i-1]} < $extent{log}{$labels[$i]}) {
                printf "log scale reordered the categories: [%s] %d is shorter than [%s] %d\n",
                    $labels[$i-1], $extent{log}{$labels[$i-1]},
                    $labels[$i],   $extent{log}{$labels[$i]};
                exit 1;
            }
        }
        # The reference still fills the row.
        unless ($extent{log}{$labels[0]} == $row_width) {
            printf "the largest category [%s] fills %d of %d characters on the log scale\n",
                $labels[0], $extent{log}{$labels[0]}, $row_width;
            exit 1;
        }
        printf "log scale: %s\n",
            join(", ", map { "$_ " . $extent{linear}{$_} . "->" . $extent{log}{$_} } @labels);
        exit 0;
    ' "$linear" "$logscale" "$ROW_WIDTH" \
      '2xx Success' '3xx Redirection' '4xx Client error' '5xx Server error'
}

assert_command \
    command     "check_log_scale_spreads_the_tail '$DEFAULT_RENDER' '$LOG_RENDER'" \
    label       'the log scale lengthens the tail without reordering the categories' \
    asserts     'Logarithmic scaling exists for the case where one category holds almost everything and the rest are stubs: it gives the smallest category a length that can actually be seen. It must do that without lying about the ordering — a longer bar still means a larger category — and the reference still fills the row, so the two scales can be read against each other.' \
    produced_by 'summary_bar_extent() in ltl' \
    contract    'features/448-category-summary-share-and-bar.md § D5 — -sbl, logarithmic length scaling; D3 — log scaling applies on top of the same largest-is-full-width reference'

# ---------------------------------------------------------------------------
# Scenario: the bar renders under both colour modes.
#
# The bar is not gated by help_ansi_enabled() — it renders whether or not
# stdout is a terminal, exactly as the timeline's own bars do. This scenario
# pins the other side of the colour switch and proves the row is unchanged.
# ---------------------------------------------------------------------------

current_scenario="bar-renders-under-both-colour-modes"
echo "[$current_scenario]"

ASCII_RENDER="$TMP_DIR/ascii.txt"
# shellcheck disable=SC2046
capture_render "$ASCII_RENDER" ascii $(run_ltl_args)

assert_command \
    command     "check_row_field '$ASCII_RENDER' '3xx Redirection' extent 8" \
    label       'the bar renders with NO_COLOR pinned' \
    asserts     "The bar follows what the tool already does for its other bars: the escapes are emitted regardless of whether stdout is a terminal, so a redirected run carries the same rows an interactive one does. NO_COLOR gates the help renderer, not the analytical output, and this assertion is what stops that distinction being erased by accident." \
    produced_by "$BAR_PRODUCED" \
    contract    'features/448-category-summary-share-and-bar.md § D6 — non-terminal output follows what the tool does today; the ANSI escapes are emitted regardless of TTY'

echo
echo "─────────────────────────────────────────"
echo "  PASS: $pass    FAIL: $fail"
if [[ "$fail" -gt 0 ]]; then
    echo
    echo "  Failed assertions:"
    printf '    - %s\n' "${failures[@]}"
    exit 1
fi
echo "─────────────────────────────────────────"
exit 0
