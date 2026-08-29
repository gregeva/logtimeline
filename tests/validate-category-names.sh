#!/usr/bin/env bash
# validate-category-names.sh — the category summary table names a category
# descriptively where a descriptive name exists, and shows the category's own
# name where none does (Issue #463).
#
# The category table is where a reader who does not already know a format's
# vocabulary tries to understand what they are looking at. HTTP status families
# are the motivating case: 4xx and 5xx say nothing to a reader who has not
# memorised them. A descriptive name is looked up per category; a category
# without one is unaffected.
#
# The descriptive names are longer than the raw ones, so this harness also
# holds the row geometry: the name occupies a fixed-width cell at the left of
# the row and the value — the total with its share of the lines included —
# stays right-aligned to the row's boundary. The label is cut to its cell at
# render, so a name that outgrew the column loses its tail rather than pushing
# the value out of line and misaligning the file-details pane beside it.
# Reading the label at the row's left edge and the value at its boundary
# catches either outcome.
#
# The short raw name stays on the two surfaces where it is the contract: the
# per-bucket legend (a horizontal budget shared with the bar graph) and the
# CSV column headers (machine-readable, consumed by external tooling).
#
# This is a RENDER-INVARIANT harness (tests/HARNESS-DESIGN.md § Render-invariant
# harnesses): the rendered category table is the surface under test, not a
# proxy for internal state.
#
# Each assertion records, per HARNESS-DESIGN.md § Self-documenting assertions:
#   - asserts:     the invariant being tested
#   - produced_by: where in ltl it is produced (function name, never a line)
#   - contract:    the source that makes the invariant stable
# All three are surfaced on failure.
#
# Usage: ./tests/validate-category-names.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

LTL="$REPO_DIR/ltl"
PERL="${PERL:-/opt/homebrew/bin/perl}"
command -v "$PERL" >/dev/null 2>&1 || PERL=perl

# Invocation shape (HARNESS-DESIGN.md § Invocation coherence): every assertion
# reads the category table, the legend strip on the single timeline row, or the
# stats CSV header. None of the three depends on the time axis, so the runs use
# the coarsest bucket with empty buckets suppressed over ten-line fixtures
# spanning seconds, and -n 1 keeps the messages table to one row. -lf pins the
# access format so the run does not depend on filename evidence and emits no
# unit-ambiguity note. -ni keeps the developer's ltl-index.csv out of the run.
FAMILIES_FIXTURE="$REPO_DIR/tests/fixtures/http-status-families.txt"
LEVELS_FIXTURE="$REPO_DIR/tests/fixtures/log-level-vocabulary.txt"
ACCESS_FORMAT="tomcat_access_with_duration"
WIDTH=140

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"

neutralize_colour_env

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"; exit 1
fi
for fixture in "$FAMILIES_FIXTURE" "$LEVELS_FIXTURE"; do
    if [[ ! -f "$fixture" ]]; then
        echo "ERROR: fixture not found: $fixture"; exit 1
    fi
done

TMP_DIR=$(mktemp -d); trap 'rm -rf "$TMP_DIR"' EXIT

pass=0
fail=0
failures=()
current_scenario=""

strip_ansi() { sed -E 's/\x1b\[[0-9;]*m//g'; }

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

# Capture one ltl render into $1 (stdout, ANSI stripped) and $1.stderr, failing
# hard on a non-zero exit or an empty capture (HARNESS-DESIGN.md Trap 1).
capture_render() {
    local outfile="$1"; shift
    local stderrfile="$outfile.stderr"
    set +e
    ( cd "$TMP_DIR" && "$LTL" "$@" ) 2>"$stderrfile" | strip_ansi > "$outfile"
    local status=("${PIPESTATUS[@]}")
    set -e
    if [[ "${status[0]}" -ne 0 ]]; then
        echo "  FAIL  $current_scenario :: ltl exited ${status[0]} while rendering" >&2
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

# A category row occupies a fixed geometry: two leading spaces, then a
# 41-character row carrying the label at its left edge and the value — the
# total with its share of LINES INCLUDED, "2 (20.0%)" — right-aligned to the
# row's boundary. The value is allowed to run left past the 30-character
# label cell into whatever slack the label leaves, so the check anchors on
# the row boundary rather than on a fixed total column; a label wider than
# its cell would still displace the value and fail here.
#
# The share is asserted for shape, not for a number: the totals the callers
# pass are what identify the row, and the share's denominator is a property
# of the fixture as a whole rather than of the row. A value carrying no share
# at all fails, which is what catches the share being dropped from the row.
check_category_row() {
    "$PERL" -e '
        my ($render, $label, $total) = @ARGV;
        my $row_width = 41;
        open my $fh, "<", $render or die "cannot open $render: $!\n";
        my ($label_seen, $found, @seen) = (0, 0);
        while (my $line = <$fh>) {
            next if length($line) < 2 + $row_width;
            next unless substr($line, 0, 2) eq "  ";
            my $row = substr($line, 2, $row_width);
            next unless $row =~ /^\Q$label\E\s/;
            $label_seen = 1;
            ( my $value = $row ) =~ s/^\Q$label\E\s+//;
            push @seen, $value;
            # Right-aligned to the boundary: the substr above ends at it, so
            # a value that reaches the end of $row is aligned by construction.
            $found = 1 if $value =~ /^\Q$total\E \(\d+(?:\.\d+)?%\)$/;
        }
        close $fh;
        if ($found) { print "row [$label] value [$total (<share>%)] present and right-aligned\n"; exit 0 }
        if ($label_seen) {
            print "row [$label] is present but its value is not [$total] with a share, right-aligned to the row boundary\n";
            print "  saw: [$_]\n" for @seen;
            exit 1;
        }
        print "no category row labelled [$label] in the summary table\n";
        exit 1;
    ' "$1" "$2" "$3"
}

# The descriptive name REPLACES the raw name; it is not shown in addition to
# it. A row whose label is exactly the raw category name means the lookup did
# not reach the render. Anchored the same way as check_category_row: the label
# sits at the left edge of the row and the value is right-aligned to its
# boundary, so the label is read as the text before the run of spaces.
check_no_raw_category_row() {
    "$PERL" -e '
        my ($render, $raw) = @ARGV;
        my $row_width = 41;
        open my $fh, "<", $render or die "cannot open $render: $!\n";
        my $found = 0;
        while (my $line = <$fh>) {
            next if length($line) < 2 + $row_width;
            next unless substr($line, 0, 2) eq "  ";
            my $row = substr($line, 2, $row_width);
            $found = 1 if $row =~ /^\Q$raw\E\s+\d+(?: \(\d+(?:\.\d+)?%\))?$/;
        }
        close $fh;
        if ($found) {
            print "the raw category name [$raw] still labels a summary-table row\n";
            exit 1;
        }
        print "[$raw] does not label a row; its descriptive name replaced it\n";
        exit 0;
    ' "$1" "$2"
}

# The legend strip on a timeline row keeps the short raw name. It is repeated
# on every bucket row and shares its horizontal budget with the bar graph, so
# the descriptive text belongs to the summary table only.
check_legend_uses_raw_name() {
    "$PERL" -e '
        my ($render, $raw, $descriptive) = @ARGV;
        open my $fh, "<", $render or die "cannot open $render: $!\n";
        my ($raw_seen, $descriptive_seen) = (0, 0);
        while (my $line = <$fh>) {
            next unless $line =~ /^\s\d{4}-\d{2}-\d{2} \d{2}:\d{2}\s/;   # a timeline bucket row
            $raw_seen++         if $line =~ /\Q$raw\E: \d/;
            $descriptive_seen++ if index($line, $descriptive) >= 0;
        }
        close $fh;
        unless ($raw_seen) {
            print "no timeline row shows the raw legend entry [$raw: <count>]\n";
            exit 1;
        }
        if ($descriptive_seen) {
            print "the descriptive name [$descriptive] reached the legend, which must stay on the short raw name\n";
            exit 1;
        }
        print "legend shows [$raw: <count>] and not [$descriptive]\n";
        exit 0;
    ' "$1" "$2" "$3"
}

# The stats CSV header is a machine-readable contract: the column is named for
# the category, not for the text a human reads in the table.
check_csv_header_raw_names() {
    "$PERL" -e '
        my ($dir, @raw) = @ARGV;
        my ($csv) = glob("$dir/*STATS*.csv");
        unless (defined $csv && -f $csv) { print "no stats CSV written to $dir\n"; exit 1 }
        open my $fh, "<", $csv or die "cannot open $csv: $!\n";
        my $header = <$fh>;
        close $fh;
        unless (defined $header) { print "stats CSV $csv has no header row\n"; exit 1 }
        chomp $header;
        my %col = map { $_ => 1 } split /,/, $header;
        my @missing = grep { !$col{$_} } @raw;
        if (@missing) {
            print "stats CSV header is missing the raw category column(s): @missing\n";
            print "header: $header\n";
            exit 1;
        }
        for my $descriptive ("Client error", "Server error", "Informational", "Redirection", "Success") {
            if (index($header, $descriptive) >= 0) {
                print "descriptive text [$descriptive] reached the stats CSV header, which must carry raw category names\n";
                print "header: $header\n";
                exit 1;
            }
        }
        print "stats CSV header carries the raw columns: @raw\n";
        exit 0;
    ' "$@"
}

# ---------------------------------------------------------------------------
# Scenario: HTTP status families, three of them also highlighted.
# The fixture carries two lines per family; the highlight matches one 2xx, one
# 4xx and one 5xx line, so each of those families shows both its plain row and
# its highlighted twin.
# ---------------------------------------------------------------------------

current_scenario="http-status-families"
echo "[$current_scenario]"

RENDER="$TMP_DIR/families.txt"
capture_render "$RENDER" --disable-progress -ni -lf "$ACCESS_FORMAT" \
    -bs 1440 -oe -n 1 --terminal-width "$WIDTH" -h orders "$FAMILIES_FIXTURE"

FAMILY_CONTRACT='features/463-friendly-log-level-category-names.md § D1 — the shipped descriptive names for the HTTP status families'
FAMILY_PRODUCED='category_display_name() in ltl, rendered by print_summary_table()'

while read -r raw total descriptive; do
    assert_command \
        command     "check_category_row '$RENDER' '$descriptive' '$total'" \
        label       "$raw is named [$descriptive] with its total aligned" \
        asserts     "A category with a descriptive name is shown under that name in the category summary table, in the fixed-width label cell, with its total left in the aligned total column. The HTTP status families are the motivating case: the numeric shorthand says nothing to a reader who has not memorised it." \
        produced_by "$FAMILY_PRODUCED" \
        contract    "$FAMILY_CONTRACT"
done <<'ROWS'
1xx 2 1xx Informational
2xx 1 2xx Success
3xx 2 3xx Redirection
4xx 1 4xx Client error
5xx 1 5xx Server error
ROWS

while read -r raw total descriptive; do
    assert_command \
        command     "check_category_row '$RENDER' '$descriptive' '$total'" \
        label       "$raw highlighted is named [$descriptive] with its total aligned" \
        asserts     "The highlighted twin of a category carries its own descriptive name rather than a marker appended by code, so the indicator sits where the phrase reads naturally. The trailing form keeps the family name at the left edge of the cell, aligned with the plain row beneath it, and the longest of these names fills the cell exactly - one character more would be cut to the cell and lose its last character." \
        produced_by "$FAMILY_PRODUCED" \
        contract    'features/463-friendly-log-level-category-names.md § D2 — the highlighted twin is its own lookup entry, indicator trailing'
done <<'ROWS'
2xx-HL 1 2xx Success, highlighted
4xx-HL 1 4xx Client error, highlighted
5xx-HL 1 5xx Server error, highlighted
ROWS

for raw in 1xx 2xx 2xx-HL 3xx 4xx 4xx-HL 5xx 5xx-HL; do
    assert_command \
        command     "check_no_raw_category_row '$RENDER' '$raw'" \
        label       "the raw name $raw no longer labels a row" \
        asserts     "The descriptive name replaces the raw category name in the summary table rather than being shown alongside it. A row still labelled with the raw name means the lookup was not consulted on the path that renders it." \
        produced_by "$FAMILY_PRODUCED" \
        contract    "$FAMILY_CONTRACT"
done

assert_command \
    command     "check_legend_uses_raw_name '$RENDER' '5xx' '5xx Server error'" \
    label       'the per-bucket legend keeps the short raw name' \
    asserts     'The legend strip is repeated on every timeline row and shares its horizontal budget with the bar graph, so it stays on the short raw category name. The descriptive text is a summary-table surface only; letting it into the legend would consume the width the timeline exists to show.' \
    produced_by 'print_bar_graph() in ltl — the per-bucket legend strip' \
    contract    'features/463-friendly-log-level-category-names.md § D3 — the legend and the CSV keep the raw category name'

# ---------------------------------------------------------------------------
# Scenario: the longest shipped name fills the category cell exactly.
# The same fixture with the highlight on its 1xx line, which is the only way
# the 30-character name reaches the render. The other scenario's highlight
# never produces it, so the exact-fit boundary would otherwise go unrendered
# by any test - and it is the boundary the fixed-width cell turns on.
# ---------------------------------------------------------------------------

current_scenario="longest-name-fills-the-column"
echo "[$current_scenario]"

WIDEST_RENDER="$TMP_DIR/widest.txt"
capture_render "$WIDEST_RENDER" --disable-progress -ni -lf "$ACCESS_FORMAT" \
    -bs 1440 -oe -n 1 --terminal-width "$WIDTH" -h upload "$FAMILIES_FIXTURE"

while read -r raw total descriptive; do
    assert_command \
        command     "check_category_row '$WIDEST_RENDER' '$descriptive' '$total'" \
        label       "$raw is named [$descriptive] with its total aligned" \
        asserts     'The longest shipped descriptive name fills the fixed-width category cell exactly, so its total still lands in the aligned total column. This is the boundary the cell width turns on: a name one character longer is cut to the cell, and a cell one character narrower would cut this name.' \
        produced_by "$FAMILY_PRODUCED" \
        contract    'features/463-friendly-log-level-category-names.md § D4 — the name fits the column, and a longer one is cut to it'
done <<'ROWS'
1xx-HL 1 1xx Informational, highlighted
1xx 1 1xx Informational
ROWS

# ---------------------------------------------------------------------------
# Scenario: the CSV contract is unchanged by the descriptive names.
# ---------------------------------------------------------------------------

current_scenario="csv-keeps-raw-category-names"
echo "[$current_scenario]"

CSV_DIR="$TMP_DIR/csv"; mkdir -p "$CSV_DIR"
CSV_STDERR="$TMP_DIR/csv.stderr"
set +e
( cd "$CSV_DIR" && "$LTL" --disable-progress -ni -lf "$ACCESS_FORMAT" \
    -bs 1440 -oe -n 1 --terminal-width "$WIDTH" -h orders -o "$FAMILIES_FIXTURE" ) \
    >"$TMP_DIR/csv-render.txt" 2>"$CSV_STDERR"
csv_rc=$?
set -e
if [[ "$csv_rc" -ne 0 ]]; then
    echo "  FAIL  $current_scenario :: ltl exited $csv_rc while writing the CSV" >&2
    sed 's/^/        /' "$CSV_STDERR" >&2
    exit 1
fi
if ! assert_no_runtime_warnings "$CSV_STDERR" "$current_scenario"; then
    fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
fi

assert_command \
    command     "check_csv_header_raw_names '$CSV_DIR' 1xx 2xx 2xx-HL 3xx 4xx 4xx-HL 5xx 5xx-HL" \
    label       'stats CSV columns are named for the raw category, not the descriptive text' \
    asserts     'The CSV is a machine-readable contract consumed by external tooling and by the column-rules validator, so its column names stay the raw category names and their -HL twins. A descriptive name reaching a header would rename columns that downstream consumers address by name.' \
    produced_by 'print_bar_graph() in ltl — the CSV header assembled from @output_columns; column families resolved by resolve_csv_column_family()' \
    contract    'features/463-friendly-log-level-category-names.md § D3 — the legend and the CSV keep the raw category name; tests/csv-output/rules/stats-columns.tsv declares the raw columns'

# ---------------------------------------------------------------------------
# Scenario: a category with no descriptive name shows its own name unchanged.
# The Windchill Method Server levels are self-explanatory and have no entries.
# ---------------------------------------------------------------------------

current_scenario="unmapped-categories-keep-their-own-name"
echo "[$current_scenario]"

LEVELS_RENDER="$TMP_DIR/levels.txt"
capture_render "$LEVELS_RENDER" --disable-progress -ni \
    -bs 1440 -oe -n 1 --terminal-width "$WIDTH" "$LEVELS_FIXTURE"

for level in FATAL ERROR WARN INFO DEBUG TRACE; do
    assert_command \
        command     "check_category_row '$LEVELS_RENDER' '$level' 1" \
        label       "$level is shown under its own name" \
        asserts     'A category with no descriptive name is shown under its own name, unchanged. Formats whose vocabulary already reads plainly need no entries and must be unaffected by the lookup - the fallback is the category name itself, never a blank or a placeholder.' \
        produced_by 'category_display_name() in ltl, rendered by print_summary_table()' \
        contract    'features/463-friendly-log-level-category-names.md § R2 — a category with no entry displays its own name unchanged'
done

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
