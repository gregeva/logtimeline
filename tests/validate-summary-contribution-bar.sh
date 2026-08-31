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
#   - each bar variant does what it says: -sbo emits no fill, -sbr fills from
#     the right edge, -sba scales against every included line, -sbl scales
#     logarithmically;
#   - -sm renders the summary table itself without colour — asserted over the
#     table's whole character range, not row by row, so a row given a colour
#     later is covered by it; and the file listing beside the table, which is
#     a different surface, keeps its colour;
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
#
# The second fixture holds 200 / 3 / 1 lines: a ratio beyond the row width, so
# the smallest category's honest extent is zero characters. It is what the
# sub-character and the monochrome scenarios need — the main fixture's smallest
# category computes to one character on its own merits, so no assertion over it
# can tell a row that draws no bar from one that draws a short one.
SUBCHAR_FIXTURE="$REPO_DIR/tests/fixtures/category-contribution-subcharacter.txt"
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
for fixture in "$FIXTURE" "$SUBCHAR_FIXTURE"; do
    if [[ ! -f "$fixture" ]]; then
        echo "ERROR: fixture not found: $fixture"; exit 1
    fi
done

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
#   colour=<sgrs>   every escape inside the row that is not a plain reset,
#                   comma-separated, or "none" — what the row is coloured with
#   text=<glyphs>   the row with every escape sequence removed
#   tail_reset=yes  the row's escapes end with a reset, so nothing the table
#                   prints after the row inherits the fill
#
# The row is located by its label in the ANSI-stripped text, then walked
# character by character, tracking whether a background is currently set.
row_bar_report() {
    "$PERL" -e '
        my ($render, $label, $row_width) = @ARGV;
        # One reader for the fill state of a rendered row, shared by every
        # caller that needs it. Returns the number of glyphs inside the row
        # that carry a background, and (in list context) the per-glyph flags.
        #
        # SGR parameters are read as whole values, longest first: a 256-colour
        # triplet carries its own digits, so 38;5;0 — the black foreground a
        # bar fill pairs with — must not be mistaken for a reset because it
        # ends in ";0". That misreading made a full-width bar measure as zero.
        sub count_filled_glyphs {
            my ($line, $row_width) = @_;
            my ($pos, $bg) = (0, "");
            my @fill;
            while ($line =~ /\G(\e\[([0-9;]*)m|.)/gs) {
                my ($tok, $sgr) = ($1, $2);
                if (defined $sgr) {
                    my @params = split /;/, $sgr, -1;
                    my $is_reset = ( $sgr eq "" );
                    my $i = 0;
                    while ($i <= $#params) {
                        my $prm = $params[$i];
                        if (($prm eq "38" || $prm eq "48") && ($params[$i+1] // "") eq "5") {
                            $bg = $sgr if $prm eq "48";
                            $i += 3; next;
                        }
                        $is_reset = 1 if $prm eq "0" || $prm eq "49";
                        $bg = $sgr if $prm eq "7";
                        $i++;
                    }
                    # A reset clears the background unless this same escape
                    # also sets one.
                    $bg = "" if $is_reset && $sgr !~ /(?:^|;)48;5;\d+(?:;|$)/;
                    next;
                }
                $pos++;
                next if $pos <= 2;                    # table padding
                last if $pos > 2 + $row_width;        # past the row
                push @fill, ( $bg ne "" ? 1 : 0 );
            }
            my $n = 0; $n += $_ for @fill;
            return wantarray ? ($n, @fill) : $n;
        }
        open my $fh, "<", $render or die "cannot open $render: $!\n";
        my $row;
        while (my $line = <$fh>) {
            ( my $plain = $line ) =~ s/\e\[[0-9;]*m//g;
            next unless length($plain) >= 2 + $row_width;
            next unless substr($plain, 0, 2) eq "  ";
            next unless substr($plain, 2, $row_width) =~ /^\Q$label\E\s+\d/;
            # Keep only the table row: the file-details pane is printed on the
            # same physical line, past the row boundary, and is not ours.
            my ($glyphs, $kept, $bg) = (0, "", "");
            my $tail_reset = 0;
            my ($extent, @fill) = count_filled_glyphs($line, $row_width);
            my $kept = join "", ($line =~ /(\e\[[0-9;]*m)/g);
            $tail_reset = ( $line =~ /\e\[0m[^\e]*$/ ) ? 1 : 0;
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
            # Escapes inside the character range of the row itself, resets
            # aside: what the row is coloured with. The file-details column
            # beyond the row boundary is a separate surface and is excluded.
            my ($cpos, @row_sgr) = (0);
            while ($line =~ /\G(\e\[([0-9;]*)m|.)/gs) {
                my ($tok, $sgr) = ($1, $2);
                if (defined $sgr) {
                    next if $cpos > 2 + $row_width;
                    next if $sgr eq "" || $sgr eq "0";
                    ( my $shown = $tok ) =~ s/\e/ESC/;
                    push @row_sgr, $shown;
                    next;
                }
                $cpos++;
            }
            my $colour = @row_sgr ? join( ",", @row_sgr ) : "none";
            my ($fill_sgr) = ( $kept =~ /(\e\[(?:[0-9;]*;)?(?:48;5;\d+|7)m)/ );
            $fill_sgr = defined $fill_sgr ? do { (my $s = $fill_sgr) =~ s/\e/ESC/; $s } : "none";
            ( my $text = $line ) =~ s/\e\[[0-9;]*m//g;
            $text = substr($text, 2, $row_width);
            $text =~ s/\s+$//;
            printf "extent=%d side=%s fill=%s colour=%s tail_reset=%s text=%s\n",
                $extent, $side, $fill_sgr, $colour, ($tail_reset ? "yes" : "no"), $text;
            exit 0;
        }
        close $fh;
        print "no category row labelled [$label] in the render\n";
        exit 1;
    ' "$1" "$2" "$3"
}

# One field of one row's report. text= is emitted last and carries spaces, so
# it is read to end of line; every other field is a single token.
row_field() {
    local report="$1" field="$2"
    if [[ "$field" == "text" ]]; then
        printf '%s\n' "$report" | sed -nE "s/.*(^| )text=(.*)$/\2/p"
    else
        printf '%s\n' "$report" | sed -nE "s/.*(^| )$field=([^ ]*).*/\2/p"
    fi
}

# Assert one field of the row report equals an expected value.
check_row_field() {
    local render="$1" label="$2" field="$3" expected="$4"
    local report
    if ! report=$(row_bar_report "$render" "$label" "$ROW_WIDTH"); then
        echo "$report"; return 1
    fi
    local got
    got=$(row_field "$report" "$field")
    if [[ "$got" == "$expected" ]]; then
        echo "row [$label] $field=$got"
        return 0
    fi
    echo "row [$label] $field is [$got], expected [$expected]"
    echo "  report: $report"
    return 1
}

# Assert one field of a row reads the same in two renders. This is how "the
# option changes colour only" is asserted: the lengths and the text are read
# out of both renders and compared, rather than restated as literals that
# would pass while both renders moved together.
check_row_field_matches() {
    local render_a="$1" render_b="$2" label="$3" field="$4"
    local report_a report_b got_a got_b
    if ! report_a=$(row_bar_report "$render_a" "$label" "$ROW_WIDTH"); then echo "$report_a"; return 1; fi
    if ! report_b=$(row_bar_report "$render_b" "$label" "$ROW_WIDTH"); then echo "$report_b"; return 1; fi
    got_a=$(row_field "$report_a" "$field")
    got_b=$(row_field "$report_b" "$field")
    if [[ -z "$got_a" ]]; then
        echo "row [$label] reports no $field in $render_a"; return 1
    fi
    if [[ "$got_a" == "$got_b" ]]; then
        echo "row [$label] $field=$got_a in both renders"
        return 0
    fi
    echo "row [$label] $field is [$got_a] with the option and [$got_b] without it"
    return 1
}

# Every escape the render emits between the top of the summary table and its
# last row, split by where it falls: 'inside' is the table's own character
# range — the two columns of padding and the ROW_WIDTH characters of row —
# and 'outside' is everything beyond it on the same physical lines, which is
# the file-details column, a different surface.
#
# The scan is over the table's character range rather than over the rows that
# exist today: that is what lets the monochrome assertion hold for a
# classification, timing or memory row given a colour later without anyone
# remembering to extend it.
table_colour_report() {
    "$PERL" -e '
        my ($render, $row_width, $where) = @ARGV;
        open my $fh, "<", $render or die "cannot open $render: $!\n";
        my ($in_table, @lines) = (0);
        while (my $line = <$fh>) {
            ( my $plain = $line ) =~ s/\e\[[0-9;]*m//g;
            $in_table = 1 if $plain =~ /^  Category\s+Total/;
            next unless $in_table;
            my ($pos, @inside, @outside) = (0);
            while ($line =~ /\G(\e\[([0-9;]*)m|.)/gs) {
                my ($tok, $sgr) = ($1, $2);
                if (defined $sgr) {
                    ( my $shown = $tok ) =~ s/\e/ESC/;
                    # The row runs to 2 + row_width glyphs; the reset that
                    # closes it lands at that boundary and belongs to the row.
                    push @{ $pos <= 2 + $row_width ? \@inside : \@outside }, $shown;
                    next;
                }
                $pos++;
            }
            push @lines, sprintf( "%d:%s", scalar(@lines) + 1,
                                  join( ",", $where eq "inside" ? @inside : @outside ) );
            last if $plain =~ /MAXIMUM MEMORY USED/;
        }
        close $fh;
        unless (@lines) { print "no summary table found in $render\n"; exit 1 }
        print "$_\n" for @lines;
        exit 0;
    ' "$1" "$2" "$3"
}

# The summary table carries no colour of its own. Permitted inside the table:
# the plain reverse-video fill the bar is drawn with under monochrome, and the
# resets that close it. Any other escape is a colour the option should have
# suppressed.
check_table_is_monochrome() {
    local render="$1"
    local report offenders scanned
    if ! report=$(table_colour_report "$render" "$ROW_WIDTH" inside); then
        echo "$report"; return 1
    fi
    scanned=$(printf '%s\n' "$report" | wc -l | tr -d ' ')
    if [[ "$scanned" -lt 5 ]]; then
        echo "only $scanned table lines scanned in $render — the table was not found whole"
        return 1
    fi
    offenders=$(printf '%s\n' "$report" | sed 's/^[0-9]*://' | tr ',' '\n' \
                    | grep -v '^$' | grep -vE '^ESC\[(0|7)m$' || true)
    if [[ -n "$offenders" ]]; then
        echo "colour emitted inside the summary table:"
        printf '%s\n' "$offenders" | sort | uniq -c
        return 1
    fi
    echo "no colour inside the summary table across $scanned lines"
    return 0
}

# The file-details column beside the table is outside the boundary: monochrome
# must leave it exactly as it was. Compared escape for escape against the
# render without the option, and required to carry colour at all, so the
# assertion cannot pass by both sides being empty.
check_pane_keeps_its_colour() {
    local render_mono="$1" render_plain="$2"
    local mono plain
    if ! mono=$(table_colour_report "$render_mono" "$ROW_WIDTH" outside); then echo "$mono"; return 1; fi
    if ! plain=$(table_colour_report "$render_plain" "$ROW_WIDTH" outside); then echo "$plain"; return 1; fi
    if ! printf '%s\n' "$mono" | grep -q 'ESC\['; then
        echo "no escapes at all beside the table in $render_mono — nothing was compared"
        return 1
    fi
    if [[ "$mono" == "$plain" ]]; then
        echo "the file-details column is escape-for-escape identical with and without the option"
        return 0
    fi
    echo "the file-details column changed:"
    diff <(printf '%s\n' "$plain") <(printf '%s\n' "$mono") | sed 's/^/  /'
    return 1
}

# Every category must resolve to an entry in the bar-colour table, because the
# bar is drawn with that entry's fill. A category whose colour finds no entry
# renders with no bar at all — silently, and only for that category.
check_every_category_has_a_fill() {
    "$PERL" -e '
        my ($ltl) = @ARGV;
        open my $fh, "<", $ltl or die "cannot open $ltl: $!\n";
        my $src = do { local $/; <$fh> };
        close $fh;
        # The tables and the resolver are sliced out of ltl and run here, so
        # this checks what the tool actually resolves rather than a second
        # implementation of the rule.
        my ($levels) = $src =~ /(^my \@log_levels = \(.*?^\);)/ms;
        my ($table)  = $src =~ /(^my %colors = \(.*?^\);)/ms;
        my ($bars)   = $src =~ /(^my \@column_colors = \(.*?^\);)/ms;
        my ($resolve)= $src =~ /(^sub summary_bar_color \{.*?^\}$)/ms;
        my %part = ( "\@log_levels" => $levels, "%colors" => $table,
                     "\@column_colors" => $bars,
                     "summary_bar_color()" => $resolve );
        my @missing = sort grep { !defined $part{$_} } keys %part;
        if (@missing) {
            print "could not read out of ltl: @missing\n";
            exit 1;
        }
        s/^my // for ($levels, $table, $bars);
        our (@log_levels, %colors, @column_colors, %bar_entry_by_hue);
        eval "$levels\n$table\n$bars\n$resolve; 1"
            or do { print "could not evaluate the colour tables: $@\n"; exit 1 };

        # Categories that reach the summary table, excluding the derived rate
        # rows and the normalisation placeholder, which are not categories.
        my @categories = grep { !/^(empty|err-rate|msg-rate)$/ }
                         grep { !/-HL$/ } @log_levels;
        unless (@categories) { print "no categories found in \@log_levels\n"; exit 1 }

        my @without;
        for my $category (@categories) {
            unless (defined $colors{$category}) {
                push @without, "$category (no colour at all)"; next;
            }
            my $entry = summary_bar_color($category);
            unless ($entry) { push @without, "$category (no bar-table entry)"; next }
            # The fill the renderer reads must invert: a background paired
            # with the black foreground the timeline bars use.
            push @without, "$category (fill carries no background)"
                unless $entry->{highlighted_bg} =~ /48;5;\d+m/;
            push @without, "$category (fill does not blacken the text)"
                unless $entry->{highlighted_bg} =~ /38;5;0m/;
        }
        if (@without) {
            print "categories with no usable bar fill: @without\n";
            exit 1;
        }
        printf "all %d categories resolve to a bar fill that inverts\n",
            scalar @categories;
        exit 0;
    ' "$1"
}

run_ltl_args() {
    printf '%s\n' --disable-progress -ni -lf "$ACCESS_FORMAT" \
        -bs 1440 -oe -n 1 --terminal-width "$WIDTH" "$@" "$FIXTURE"
}

# The same invocation over the sub-character fixture.
run_subchar_args() {
    printf '%s\n' --disable-progress -ni -lf "$ACCESS_FORMAT" \
        -bs 1440 -oe -n 1 --terminal-width "$WIDTH" "$@" "$SUBCHAR_FIXTURE"
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
    command     "check_row_field '$DEFAULT_RENDER' '5xx Server error' fill 'ESC[48;5;124m'" \
    label       'a plain row is filled in the subdued shade of its own colour' \
    asserts     "The fill is the category's own colour, so a row is recognisable by the same colour whether it is read as text or as a bar. A plain row takes the subdued shade of that colour — the same one the timeline bars use for their unhighlighted length — so that the vivid shade is left to mean something." \
    produced_by 'summary_category_row() in ltl, reading plain_bg from the bar-colour table' \
    contract    'features/448-category-summary-share-and-bar.md § D2 — the bar uses the same bar mechanism and colour table as the timeline columns'

# ---------------------------------------------------------------------------
# Scenario: every category can be filled.
#
# The gap this closes: five foreground codes were mapped to a background by
# hand and every other colour fell back to the terminal default, so cyan
# (CREATE) and any 256-colour category had no highlighted background at all.
# ---------------------------------------------------------------------------

current_scenario="every-category-colour-resolves-to-a-bar-fill"
echo "[$current_scenario]"

assert_command \
    command     "check_every_category_has_a_fill '$LTL'" \
    label       'every category colour resolves to a bar fill that inverts' \
    asserts     'The bar is drawn with the bar-colour table entry for the hue of the category colour, so a category that resolves to no entry would render with no bar at all — silently, and only for that category. The entry must invert: a background paired with a black foreground, which is what keeps the row readable on a dark terminal and on a light one, since the terminal supplies the surrounding foreground.' \
    produced_by 'summary_bar_color() in ltl, resolving a category colour against @column_colors' \
    contract    'features/448-category-summary-share-and-bar.md § D2 — the bar uses the same bar mechanism and colour table as the timeline columns'

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
# Scenario: -sm renders the summary table without colour.
#
# Monochrome is a property of the summary table, not of the bar: the option
# shipped as a bar variant and left the category colours on every row the bar
# did not cover, which on a real access log was every row but the dominant one.
#
# Two things follow, and both are asserted here. The table-wide assertions read
# the table's whole character range rather than the rows that exist today, so a
# classification, timing or memory row given a colour later is covered by them
# with nothing to extend. And the fixture is the sub-character one: at
# 200 / 3 / 1 lines its 5xx row draws no fill at all, which is the case the
# delivered option got wrong and the main fixture cannot reach.
# ---------------------------------------------------------------------------

current_scenario="summary-mono"
echo "[$current_scenario]"

MONO_RENDER="$TMP_DIR/mono.txt"
MONO_BAR_OFF_RENDER="$TMP_DIR/mono-bar-off.txt"
MONO_BASE_RENDER="$TMP_DIR/mono-base.txt"
# shellcheck disable=SC2046
capture_render "$MONO_RENDER" ansi $(run_subchar_args -sm)
# shellcheck disable=SC2046
capture_render "$MONO_BAR_OFF_RENDER" ansi $(run_subchar_args -sm -sbo)
# shellcheck disable=SC2046
capture_render "$MONO_BASE_RENDER" ansi $(run_subchar_args)

MONO_CONTRACT='features/448-category-summary-share-and-bar.md § D7 (amended) — monochrome is a property of the summary table, not of the bar; § Acceptance criteria A1–A4'

assert_command \
    command     "check_table_is_monochrome '$MONO_RENDER'" \
    label       'the summary table emits no colour of its own under -sm' \
    asserts     'Monochrome is asked of the table, so it holds across the table rather than on the rows that happen to be coloured today. The scan covers every line from the Category header to the last row and permits only the plain reverse-video fill and the resets that close it, which is what makes a classification, timing or memory row given a colour later fail here rather than ship uncovered.' \
    produced_by 'summary_colour() in ltl, the one place the summary table resolves a colour, called from summary_category_row()' \
    contract    "$MONO_CONTRACT"

assert_command \
    command     "check_table_is_monochrome '$MONO_BAR_OFF_RENDER'" \
    label       'the summary table emits no colour of its own under -sm with the bar switched off' \
    asserts     'The two options are independent: -sbo removes the bar, -sm removes the colour, and neither depends on the other. A monochrome run with no bar at all is the case where nothing is left to carry the colour, so a row that still emitted one would be showing it for no reason.' \
    produced_by 'summary_colour() in ltl, called from summary_category_row()' \
    contract    "$MONO_CONTRACT"

assert_command \
    command     "check_row_field '$MONO_RENDER' '5xx Server error' colour none" \
    label       'a row whose share draws no fill carries no colour under -sm' \
    asserts     'This is the row the delivered option got wrong. Its share is below one character, so no fill covers it, and the renderer coloured every character the fill did not cover — which for this row was all of them. Monochrome cannot depend on whether a row happened to earn a bar.' \
    produced_by 'summary_category_row() in ltl, the no-fill return' \
    contract    "$MONO_CONTRACT"

assert_command \
    command     "check_row_field '$MONO_RENDER' '2xx Success' fill 'ESC[7m'" \
    label       'the bar is still drawn under -sm, as a plain reverse-video fill' \
    asserts     'Taking the colour away must not take the bar away: the length is what the option exists to let the eye judge, so the fill stays and inverts the terminal own foreground and background instead of carrying a category colour.' \
    produced_by "$BAR_PRODUCED" \
    contract    "$MONO_CONTRACT"

for label in '2xx Success' '3xx Redirection' '5xx Server error'; do
    for field in extent text; do
        assert_command \
            command     "check_row_field_matches '$MONO_RENDER' '$MONO_BASE_RENDER' '$label' $field" \
            label       "[$label] keeps its $field under -sm" \
            asserts     'Monochrome changes the colour and nothing else. The length of every bar and every character of every row is read out of both renders and compared, so a change of scale or of text hiding behind the colour change is caught rather than assumed away.' \
            produced_by "$BAR_PRODUCED" \
            contract    "$MONO_CONTRACT"
    done
done

assert_command \
    command     "check_row_field '$MONO_BASE_RENDER' '5xx Server error' colour 'ESC[31m'" \
    label       'without -sm a row whose share draws no fill keeps its category colour' \
    asserts     'The other side of the same rule, and a regression this table has already suffered once: a row too small to draw a bar previously printed in the terminal default rather than in red. Without the option the row is coloured whether or not a fill covers it.' \
    produced_by 'summary_category_row() in ltl, the no-fill return' \
    contract    'features/448-category-summary-share-and-bar.md § Defects found in the delivered implementation — D-5, a row with no bar keeps its colour'

assert_command \
    command     "check_pane_keeps_its_colour '$MONO_RENDER' '$MONO_BASE_RENDER'" \
    label       'the file-details column beside the table keeps its colour under -sm' \
    asserts     'The summary table is the panel on the left. The file listing printed to its right shares the physical lines but is a different surface, and monochrome does not reach it: its escapes are compared one for one against the run without the option, and it must carry colour at all, so the comparison cannot pass by both sides being empty.' \
    produced_by 'print_summary_table() in ltl, which composes the table and the file-details column as separate surfaces' \
    contract    "$MONO_CONTRACT"

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
        # One reader for the fill state of a rendered row, shared by every
        # caller that needs it. Returns the number of glyphs inside the row
        # that carry a background, and (in list context) the per-glyph flags.
        #
        # SGR parameters are read as whole values, longest first: a 256-colour
        # triplet carries its own digits, so 38;5;0 — the black foreground a
        # bar fill pairs with — must not be mistaken for a reset because it
        # ends in ";0". That misreading made a full-width bar measure as zero.
        sub count_filled_glyphs {
            my ($line, $row_width) = @_;
            my ($pos, $bg) = (0, "");
            my @fill;
            while ($line =~ /\G(\e\[([0-9;]*)m|.)/gs) {
                my ($tok, $sgr) = ($1, $2);
                if (defined $sgr) {
                    my @params = split /;/, $sgr, -1;
                    my $is_reset = ( $sgr eq "" );
                    my $i = 0;
                    while ($i <= $#params) {
                        my $prm = $params[$i];
                        if (($prm eq "38" || $prm eq "48") && ($params[$i+1] // "") eq "5") {
                            $bg = $sgr if $prm eq "48";
                            $i += 3; next;
                        }
                        $is_reset = 1 if $prm eq "0" || $prm eq "49";
                        $bg = $sgr if $prm eq "7";
                        $i++;
                    }
                    # A reset clears the background unless this same escape
                    # also sets one.
                    $bg = "" if $is_reset && $sgr !~ /(?:^|;)48;5;\d+(?:;|$)/;
                    next;
                }
                $pos++;
                next if $pos <= 2;                    # table padding
                last if $pos > 2 + $row_width;        # past the row
                push @fill, ( $bg ne "" ? 1 : 0 );
            }
            my $n = 0; $n += $_ for @fill;
            return wantarray ? ($n, @fill) : $n;
        }
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
                    next unless substr($plain, 2, $row_width) =~ /^\Q$label\E\s+\d/;
                    # The background state machine lives in one place only —
                    # row_bar_report()'"'"'s reader, invoked here — so a change to
                    # how a fill is recognised cannot reach one caller and
                    # miss the other.
                    my $filled = count_filled_glyphs($line, $row_width);
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

# ---------------------------------------------------------------------------
# Scenario: a share too small to fill a character draws no bar.
#
# The main fixture cannot reach this case. Its smallest category is 1 of 40,
# which at a 41-character row computes to int(0.025 * 41 + 0.5) = 1 on its own
# merits — so a forced one-character minimum would produce the same extent the
# arithmetic already gives, and no assertion over that fixture can tell the two
# apart. What is needed is not more skew but more dynamic range: a ratio beyond
# the row width, so the honest extent is zero.
#
# This fixture holds 200 / 3 / 1 lines. Against the largest, over a
# 41-character row: 41, 1 and 0 characters. The 5xx row at 0.49 % is the case
# that matters — one character is nearly 2.4 % of the row, so drawing it would
# claim about five times its true size.
# ---------------------------------------------------------------------------

current_scenario="a-share-below-one-character-draws-no-bar"
echo "[$current_scenario]"

SUBCHAR_RENDER="$TMP_DIR/subcharacter.txt"
# shellcheck disable=SC2046
capture_render "$SUBCHAR_RENDER" ansi $(run_subchar_args)

while IFS='|' read -r label extent; do
    assert_command \
        command     "check_row_field '$SUBCHAR_RENDER' '$label' extent '$extent'" \
        label       "[$label] fills $extent of $ROW_WIDTH characters" \
        asserts     'The bar states a proportion, so it is never rounded up to a character the share has not earned. At a 41-character row one character is nearly 2.4 per cent; a category holding under half of that draws no bar at all, and the printed percentage carries the value. Rounding it up to one character would overstate the smallest category by several times over, on the surface whose only job is to show relative size.' \
        produced_by "$BAR_PRODUCED" \
        contract    'features/448-category-summary-share-and-bar.md § D3 — the bar length is the share of the largest category, with no minimum'
done <<'SUBROWS'
2xx Success|41
3xx Redirection|1
5xx Server error|0
SUBROWS

# The option that exists for exactly this case must still answer it: -sbl
# compresses the scale so the row that draws nothing linearly gets a length.
SUBCHAR_LOG_RENDER="$TMP_DIR/subcharacter-log.txt"
# shellcheck disable=SC2046
capture_render "$SUBCHAR_LOG_RENDER" ansi $(run_subchar_args -sbl)

assert_command \
    command     "check_row_field '$SUBCHAR_LOG_RENDER' '5xx Server error' extent 12" \
    label       'under -sbl the sub-character category has a visible bar' \
    asserts     'Dropping the minimum does not leave the small categories invisible: -sbl is the option for seeing them, and it must give a length to the row the linear scale correctly draws as nothing. If it did not, removing the minimum would have taken away the only way to see a rare category.' \
    produced_by "$BAR_PRODUCED" \
    contract    'features/448-category-summary-share-and-bar.md § D5 — -sbl gives the tail rows a visible length'

# ---------------------------------------------------------------------------
# Scenario: a highlighted row and its plain twin are filled in different shades.
#
# The bar-colour table carries two shades per hue and the timeline uses both:
# the vivid one marks the highlighted length, the subdued one carries the rest.
# The summary rows must do the same, or a highlighted category and its plain
# twin render identically and the highlight says nothing. Highlighting one of
# the two paths in the dominant category splits it into exactly that pair.
# ---------------------------------------------------------------------------

current_scenario="highlighted-and-plain-twins-differ-in-shade"
echo "[$current_scenario]"

HL_RENDER="$TMP_DIR/highlighted.txt"
# shellcheck disable=SC2046
capture_render "$HL_RENDER" ansi $(run_subchar_args -h /catalog)

assert_command \
    command     "check_row_field '$HL_RENDER' '2xx Success (HL)' fill 'ESC[48;5;46m'" \
    label       'the highlighted row is filled in the vivid shade' \
    asserts     'The highlighted twin takes the vivid shade of its hue, the same one the timeline bars use to mark their highlighted length, so a highlighted category is the one that stands out of the table.' \
    produced_by "$BAR_PRODUCED" \
    contract    'features/448-category-summary-share-and-bar.md § D2 — the bar uses the same bar mechanism and colour table as the timeline columns'

assert_command \
    command     "check_row_field '$HL_RENDER' '2xx Success' fill 'ESC[48;5;34m'" \
    label       'the plain twin is filled in the subdued shade of the same hue' \
    asserts     'The plain row takes the subdued shade of the same hue, so the pair reads as one category split in two rather than as two unrelated ones. Rendering both in the vivid shade makes the highlight invisible — the two rows come out identical and nothing says which is which.' \
    produced_by "$BAR_PRODUCED" \
    contract    'features/448-category-summary-share-and-bar.md § D2 — the bar uses the same bar mechanism and colour table as the timeline columns'

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
