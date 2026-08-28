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
# holds the column geometry: the name occupies a fixed-width cell and the
# totals stay aligned down the table. A name that outgrew the column would
# push its total out of line and misalign the whole surface, including the
# file-details pane rendered beside it.
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

# A category row occupies a fixed-width cell: two leading spaces, the label
# left-aligned in 30 columns, one space, the total right-aligned in 10. The
# check reads those exact offsets, so it asserts the label AND the geometry
# that keeps the totals aligned down the table: a label wider than its cell
# would displace the total and fail here.
check_category_row() {
    "$PERL" -e '
        my ($render, $label, $total) = @ARGV;
        my $label_cell = sprintf("%-30s", $label);
        my $total_cell = sprintf("%10s", $total);
        open my $fh, "<", $render or die "cannot open $render: $!\n";
        my ($label_seen, $found) = (0, 0);
        while (my $line = <$fh>) {
            next if length($line) < 45;
            next unless substr($line, 0, 2) eq "  ";
            my $got_label = substr($line, 2, 30);
            next unless $got_label eq $label_cell;
            $label_seen = 1;
            $found = 1 if substr($line, 32, 1) eq " " && substr($line, 33, 10) eq $total_cell;
        }
        close $fh;
        if ($found) { print "row [$label] total [$total] present and aligned\n"; exit 0 }
        if ($label_seen) {
            print "row [$label] is present but its total is not [$total] in the aligned total column\n";
            exit 1;
        }
        print "no category row labelled [$label] in the summary table\n";
        exit 1;
    ' "$1" "$2" "$3"
}

# The descriptive name REPLACES the raw name; it is not shown in addition to
# it. A row whose label cell is exactly the raw category name means the lookup
# did not reach the render.
check_no_raw_category_row() {
    "$PERL" -e '
        my ($render, $raw) = @ARGV;
        my $raw_cell = sprintf("%-30s", $raw);
        open my $fh, "<", $render or die "cannot open $render: $!\n";
        my $found = 0;
        while (my $line = <$fh>) {
            next if length($line) < 45;
            next unless substr($line, 0, 2) eq "  ";
            $found = 1 if substr($line, 2, 30) eq $raw_cell;
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
        asserts     "The highlighted twin of a category carries its own descriptive name rather than a marker appended by code, so the indicator sits where the phrase reads naturally. The trailing form keeps the family name at the left edge of the cell, aligned with the plain row beneath it, and the longest of these names fills the cell exactly - one character more would displace the total." \
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
