#!/usr/bin/env bash
# validate-message-truncation.sh — where a message too long for its length is
# cut, in the messages table and the messages CSV (-mt, --message-truncation).
#
# A message is cut twice: when its key is stored (at the per-run length: the
# terminal width, or 350 under -o or -g) and again when the messages table fits
# it to its column. Both cuts apply the chosen position, right (the end, the
# default and the behaviour before the option existed), left (the start) or
# center (the middle), keep the composed attributes at the start of the key
# ([level] [thread] [object]) and mark the cut with one ellipsis. The harness
# reads both surfaces, the rendered table and the CSV, and holds each to the
# same standard: the text shown is exactly the cut of the original message.
#
# The expected text is computed here, independently of ltl, from the fixture
# lines: the attributes and the leading text each fixture's format composes
# are written below per fixture family, and the cut rule (equal parts for
# center, the odd character at the end; the ellipsis one column on the
# terminal, three bytes in the CSV) is reimplemented in the checker. A cut of a
# cut equals the cut of the original, so the table shows the same text whether
# the stored key was cut at the terminal width or at 350.
#
# Each assertion records, per HARNESS-DESIGN.md § Self-documenting assertions:
#   - asserts:     the invariant being tested
#   - produced_by: where in ltl it is produced (function name, never a line)
#   - contract:    the source that makes the invariant stable
# All three are surfaced on failure.
#
# Usage: ./tests/validate-message-truncation.sh [--list] [--scenario NAME]...

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

LTL="${LTL:-$REPO_DIR/ltl}"
PERL="${PERL:-perl}"

DOC='features/564-message-truncation-position.md'

# Invocation shape (HARNESS-DESIGN.md § Invocation coherence): every assertion
# reads the messages table, the messages CSV or one -V section; none depends on
# the time axis, so every run uses the coarsest bucket with empty buckets
# suppressed (-bs 1440 -oe) over fixtures of a few lines spanning seconds.
# -n 20 shows every fixture message. --terminal-width is pinned: the column
# width and the stored length follow it.
FIXTURES=(
    "$REPO_DIR/tests/fixtures/message-truncation-level.txt"
    "$REPO_DIR/tests/fixtures/message-truncation-thread.txt"
    "$REPO_DIR/tests/fixtures/message-truncation-object.txt"
    "$REPO_DIR/tests/fixtures/message-truncation-thread-object.txt"
)
GROUPING_IDS_FIXTURE="$REPO_DIR/tests/fixtures/message-truncation-grouping-ids.txt"
GROUPING_PAIRS_FIXTURE="$REPO_DIR/tests/fixtures/message-truncation-grouping-pairs.txt"
GROUPING_AROUND_CUT_FIXTURE="$REPO_DIR/tests/fixtures/message-truncation-grouping-around-cut.txt"
GROUPING_OFFCENTRE_FIXTURE="$REPO_DIR/tests/fixtures/message-truncation-grouping-offcentre.txt"
WIDTH=160
KEY_CAP=350

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"

# Ambient FORCE_COLOR/NO_COLOR must not decide what this harness asserts against
# (HARNESS-DESIGN.md § Colour rendering is controlled, never inherited).
neutralize_colour_env

scenario_register option-values right-unchanged table-cut stored-cut-csv grouped
scenario_parse_args "$@"

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"; exit 1
fi
for f in "${FIXTURES[@]}" "$GROUPING_IDS_FIXTURE" "$GROUPING_PAIRS_FIXTURE" "$GROUPING_AROUND_CUT_FIXTURE" "$GROUPING_OFFCENTRE_FIXTURE"; do
    [[ -f "$f" ]] || { echo "ERROR: fixture not found: $f"; exit 1; }
done

TMP_DIR=$(mktemp -d); trap 'rm -rf "$TMP_DIR"' EXIT

pass=0
fail=0
failures=()
current_scenario=""

strip_ansi() { sed -E 's/\x1b\[[0-9;]*m//g'; }

# Self-documenting assertion: runs `command`; PASS on exit 0, FAIL otherwise,
# surfacing the command, its output and asserts/produced_by/contract.
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
    : "${command:?}" "${label:?}" "${asserts:?}" "${produced_by:?}" "${contract:?}"
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

# run_ltl <label> <ltl options...>: one run in its own directory, the render
# ANSI-stripped to <dir>/render.txt, stderr to <dir>/stderr.txt; a non-zero
# exit or a runtime warning is a failure of the scenario.
run_ltl() {
    local label="$1"; shift
    local dir="$TMP_DIR/$label"
    mkdir -p "$dir"
    set +e
    ( cd "$dir" && "$LTL" --disable-progress -ni -bs 1440 -oe --terminal-width "$WIDTH" "$@" ) \
        2>"$dir/stderr.txt" | strip_ansi > "$dir/render.txt"
    local rc=${PIPESTATUS[0]}
    set -e
    if [[ "$rc" -ne 0 ]]; then
        echo "  FAIL  $current_scenario :: ltl exited $rc ($label)"
        sed 's/^/        /' "$dir/stderr.txt"
        fail=$((fail + 1)); failures+=("$current_scenario :: ltl exit ($label)")
    fi
    if ! assert_no_runtime_warnings "$dir/stderr.txt" "$current_scenario ($label)"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr ($label)")
    fi
}

messages_csv() { find "$TMP_DIR/$1" -name '*-LTL-MESSAGES-*.csv' -print -quit; }

# The messages table of a render: its heading through its last row. The
# command-line echo, timings and memory around it differ between any two runs.
messages_table() { sed -n '/TOP OVERALL MESSAGES/,/^$/p' "$TMP_DIR/$1/render.txt"; }

# The checker: compares every fixture message, in the rendered table or the
# messages CSV, with the cut computed here from the fixture line.
#   check.pl table <position> <render> <fixture...>
#   check.pl csv   <position> <cap> <csv> <fixture...>
# A table check finds the column width from the rows themselves (a cut message
# fills it and ends with its TAIL marker) and prints it as column=N.
CHECK="$TMP_DIR/check.pl"
cat > "$CHECK" <<'PERL'
use strict;
use warnings;
use Text::CSV;

my ($surface, $position, @rest) = @ARGV;
my $cap = $surface eq 'csv' ? shift @rest : undef;
my ($observed, @fixtures) = @rest;
my $E = "\xe2\x80\xa6";

# Per fixture family: the attributes ltl composes and the text the message
# carries before the fixture's own body (written from the right-cut keys).
my %family = (
    TO => [ '[INFO] [main] [wt.method.server.startup] ', '' ],
    T  => [ '[INFO] [pool-2-thread] ', 'io.netty.util.ResourceLeakDetector - ' ],
    O  => [ '[ERROR] [ajp_marshal_into_msgb] ', '' ],
    L  => [ '[200] ', 'GET /' ],
);

# Original messages by tag, from the fixture lines.
my %message;
for my $f (@fixtures) {
    open my $fh, '<', $f or die "cannot open $f: $!\n";
    while (my $line = <$fh>) {
        next unless $line =~ m{(HEAD([A-Z]+)[ /].*?[ /]TAIL\2)};
        my ($body, $tag) = ($1, $2);
        (my $fam = $tag) =~ s/[SML]$//;
        my ($prefix, $lead) = @{ $family{$fam} or die "no family for $tag\n" };
        $message{$tag} = { prefix => $prefix, text => $lead . $body };
    }
}
die "anchor not found: no fixture messages read\n" unless %message;

# The cut, as the feature defines it: right keeps the start and adds no marker;
# left keeps the end; center keeps equal parts, the odd character at the end.
sub cut {
    my ($text, $room, $marker_len, $marker) = @_;
    return $text if length($text) <= $room;
    return substr($text, 0, $room) if $position eq 'right';
    my $keep = $room - $marker_len;
    return $marker . substr($text, -$keep) if $position eq 'left';
    my $head = int($keep / 2);
    return substr($text, 0, $head) . $marker . substr($text, -($keep - $head));
}

sub tag_of {
    my ($s) = @_;
    return $1 if $s =~ /(?:HEAD|TAIL)([A-Z]+)/;
    return uc $1 if $s =~ /\b([a-z]{1,3})\d{3}\b/;
    return;
}

my (%seen, @bad);
if ($surface eq 'csv') {
    my $csv = Text::CSV->new({ binary => 1 });
    open my $fh, '<', $observed or die "cannot open $observed: $!\n";
    $csv->getline($fh);
    while (my $row = $csv->getline($fh)) {
        my $key = $row->[1];
        utf8::encode($key) if utf8::is_utf8($key);
        my $tag = tag_of($key) or next;
        my $m = $message{$tag} or next;
        $seen{$tag}++;
        my $expected = $m->{prefix} . cut($m->{text}, $cap - length($m->{prefix}), length($E), $E);
        push @bad, "$tag: key is " . length($key) . " bytes, over the cap $cap" if length($key) > $cap;
        push @bad, "$tag:\n  expected [$expected]\n  observed [$key]" if $key ne $expected;
    }
} else {
    open my $fh, '<:encoding(UTF-8)', $observed or die "cannot open $observed: $!\n";
    my (@rows, %widths);
    while (my $line = <$fh>) {
        chomp $line;
        next unless $line =~ /HEAD|TAIL|\b[a-z]{1,3}\d{3}\b/;
        next unless $line =~ /^(.)\s(.*?)\s+(\d+)\s*$/;
        my $text = $2;
        my $tag = tag_of($text) or next;
        push @rows, [ $tag, $text ];
        $widths{ length $line }++;
    }
    die "anchor not found: no message rows in $observed\n" unless @rows;
    push @bad, "rows occupy differing column counts: " . join(', ', map { "$_ x$widths{$_}" } sort keys %widths)
        if keys %widths > 1;
    my ($width) = keys %widths;
    push @bad, "rows are $width columns, wider than the terminal" if $width > 160;
    my $column = 0;
    for (@rows) { $column = length $_->[1] if length $_->[1] > $column }
    print "column=$column\n";
    for my $r (@rows) {
        my ($tag, $text) = @$r;
        my $m = $message{$tag} or next;
        $seen{$tag}++;
        my $expected = $m->{prefix} . cut($m->{text}, $column - length($m->{prefix}), 1, "\x{2026}");
        $expected =~ s/\s+$//;
        push @bad, "$tag:\n  expected [$expected]\n  observed [$text]" if $text ne $expected;
    }
}
my @missing = grep { !$seen{$_} } sort keys %message;
push @bad, "fixture messages missing from $surface: @missing" if @missing;
if (@bad) { print "$_\n" for @bad; exit 1 }
printf "%d messages, each the %s cut of its original\n", scalar(keys %seen), $position;
exit 0;
PERL

check() { "$PERL" "$CHECK" "$@"; }

# ---------------------------------------------------------------------------
if scenario_wanted option-values; then
current_scenario="option-values"
echo "[$current_scenario]"
# -n 1 over one fixture: only -V runtime-config and the exit status are read.
for given in left l LEFT center c C right r; do
    run_ltl "value-$given" -n 1 -mt "$given" -V runtime-config "${FIXTURES[0]}"
done
for given in left l LEFT center c C right r; do
    case "$given" in l|L|left|LEFT) full=left ;; c|C|center) full=center ;; *) full=right ;; esac
    assert_command \
        command     "grep -qx 'message_truncation: $full' '$TMP_DIR/value-$given/render.txt' || { echo 'runtime-config line message_truncation: $full not found'; exit 1; }" \
        label       "-mt $given resolves to $full" \
        asserts     'A position is named in full or by its first letter, in any case, and -V runtime-config reports the full name the run acts on.' \
        produced_by 'adapt_to_command_line_options() in ltl (the -mt validation); emitted by the runtime-config section' \
        contract    "$DOC § 3.1 D2 (left, center, right; l, c, r); AC9"
done
set +e
( cd "$TMP_DIR" && "$LTL" --disable-progress -ni -bs 1440 -oe -mt x "${FIXTURES[0]}" ) > "$TMP_DIR/invalid.out" 2> "$TMP_DIR/invalid.err"
invalid_rc=$?
set -e
assert_command \
    command     "[[ $invalid_rc -ne 0 ]] && grep -q 'left, center, right' '$TMP_DIR/invalid.err' && ! grep -q 'TOP OVERALL' '$TMP_DIR/invalid.out' || { echo 'exit $invalid_rc'; cat '$TMP_DIR/invalid.err'; exit 1; }" \
    label       'an unknown value exits non-zero, names the values and runs nothing' \
    asserts     'A value that names no position is refused before anything is read: a non-zero exit, an error naming the accepted values, and no messages table.' \
    produced_by 'adapt_to_command_line_options() in ltl (the -mt validation)' \
    contract    "$DOC § 3.1 D2; AC9"
fi

# ---------------------------------------------------------------------------
if scenario_wanted right-unchanged; then
current_scenario="right-unchanged"
echo
echo "[$current_scenario]"
# -o: the table and the CSV are both compared.
run_ltl default -n 20 -o "${FIXTURES[@]}"
run_ltl right -n 20 -o -mt right "${FIXTURES[@]}"
assert_command \
    command     "[[ -n \"\$(messages_table right)\" ]] && diff <(messages_table default) <(messages_table right) >/dev/null && cmp -s \"\$(messages_csv default)\" \"\$(messages_csv right)\" || { echo 'table or CSV differs, or no table found'; diff <(messages_table default) <(messages_table right) | head -20; exit 1; }" \
    label       '-mt right renders and writes exactly what a run without -mt does' \
    asserts     'Right is the default and the behaviour before the option existed: the table and the messages CSV are byte-identical with and without -mt right.' \
    produced_by 'print_message_summary() and the key site in read_and_process_logs() in ltl, under the default position' \
    contract    "$DOC § 3.1 D2 (default right); AC1"
assert_command \
    command     "! grep -q \$'\\xe2\\x80\\xa6' '$TMP_DIR/right/render.txt' \"\$(messages_csv right)\" || { echo 'an ellipsis appears under -mt right'; exit 1; }" \
    label       'no ellipsis under the right cut' \
    asserts     'The right cut is unchanged and carries no marker, on the table and in the CSV.' \
    produced_by 'print_message_summary() and read_and_process_logs() in ltl' \
    contract    "$DOC § 3.1 D2; AC1"
assert_command \
    command     "check table right '$TMP_DIR/right/render.txt' ${FIXTURES[*]}" \
    label       'the table shows the start of each message, cut at the column' \
    asserts     'Under right each message shows its attributes and its start, cut at the column width; a message that fits is shown whole.' \
    produced_by 'print_message_summary() in ltl' \
    contract    "$DOC § 2 (display cut); AC1, AC4"
fi

# ---------------------------------------------------------------------------
if scenario_wanted table-cut; then
current_scenario="table-cut"
echo
echo "[$current_scenario]"
# No -o or -g: the stored key is cut at the terminal width, so a message longer
# than the terminal keeps its end only because the stored cut applies the
# position too.
declare -A column_of
for position in left center; do
    run_ltl "table-$position" -n 20 -mt "$position" "${FIXTURES[@]}"
    out=$(check table "$position" "$TMP_DIR/table-$position/render.txt" "${FIXTURES[@]}" 2>&1 || true)
    column_of[$position]=$(sed -n 's/^column=//p' <<<"$out")
    assert_command \
        command     "check table $position '$TMP_DIR/table-$position/render.txt' ${FIXTURES[*]}" \
        label       "-mt $position: every row is the $position cut of its original message, attributes kept" \
        asserts     "Each message shows its composed attributes as written, then the $position cut of the message to the column with one ellipsis; a message that fits shows whole; every row occupies the same columns, no wider than the terminal; and a message longer than the terminal width still shows its true end, which needs the stored cut to apply the position. Holds for all four attribute shapes (level; level and thread; level and object; level, thread and object)." \
        produced_by 'fit_message_key_to_column() and cut_message_text() via print_message_summary(); the stored cut in read_and_process_logs() in ltl' \
        contract    "$DOC § 3 (attributes outside the truncation), § 3.1 D1 (the stored cut applies the position); AC2 to AC7"
done
assert_command \
    command     "[[ -n '${column_of[left]}' && '${column_of[left]}' == '${column_of[center]}' ]] || { echo 'column widths: left=${column_of[left]} center=${column_of[center]}'; exit 1; }" \
    label       'the column width does not depend on the position' \
    asserts     'The position changes what a message shows, never the width of the column it is fitted to.' \
    produced_by 'print_message_summary() in ltl' \
    contract    "$DOC § 3.2 scope (no length or size changes); AC6"
fi

# ---------------------------------------------------------------------------
if scenario_wanted stored-cut-csv; then
current_scenario="stored-cut-csv"
echo
echo "[$current_scenario]"
# -o: the key is stored at the 350 cap; the CSV carries it verbatim and the
# table re-cuts it to the column. -V benchmark-data reports the stored length.
for position in right left center; do
    run_ltl "csv-$position" -n 20 -o -mt "$position" -V benchmark-data "${FIXTURES[@]}"
done
for position in left center; do
    assert_command \
        command     "check csv $position $KEY_CAP \"\$(messages_csv csv-$position)\" ${FIXTURES[*]}" \
        label       "-mt $position: every CSV key is the $position cut of its message at $KEY_CAP bytes" \
        asserts     "The messages CSV carries the stored key: the attributes, then the $position cut of the message to the cap, the ellipsis counted as its three bytes, so no key exceeds $KEY_CAP bytes." \
        produced_by 'cut_message_text() at the key site in read_and_process_logs(); written by print_message_summary() in ltl' \
        contract    "$DOC § 3.1 D1 (the stored cut keeps its per-run length and applies the position); AC7, AC8"
    sed '/^=== benchmark-data ===/,/^=== END benchmark-data ===/d' "$TMP_DIR/csv-$position/render.txt" > "$TMP_DIR/csv-$position/table.txt"
    assert_command \
        command     "check table $position '$TMP_DIR/csv-$position/table.txt' ${FIXTURES[*]}" \
        label       "-mt $position: the table re-cuts the stored key to the cut of the original" \
        asserts     'A key stored at 350 and cut again for the column shows exactly what cutting the original message to the column shows, with one ellipsis: the second cut splits a centre cut at the stored ellipsis and puts one back.' \
        produced_by 'fit_message_key_to_column() and cut_message_text() via print_message_summary() in ltl' \
        contract    "$DOC § 3.1 D4 (the display cut splits at the stored ellipsis), § 3.2 (a cut of a cut equals the cut of the original); AC2, AC3"
done
assert_command \
    command     "a=\$(grep -h \$'^CONFIG\\tmax_log_message_length\\t' $TMP_DIR/csv-right/render.txt $TMP_DIR/csv-left/render.txt $TMP_DIR/csv-center/render.txt | sort -u); [[ \"\$a\" == \$'CONFIG\\tmax_log_message_length\\t$KEY_CAP' ]] || { echo \"benchmark-data lines: \$a\"; exit 1; }" \
    label       'the stored length is the same under every position' \
    asserts     'The position changes where a key is cut, never how long it may be: -V benchmark-data reports max_log_message_length 350 under right, left and center.' \
    produced_by 'adapt_to_terminal_settings() in ltl; emitted by the benchmark-data section' \
    contract    "$DOC § 3.1 D1, § 3.2 scope; AC8"
fi

# ---------------------------------------------------------------------------
if scenario_wanted grouped; then
current_scenario="grouped"
echo
echo "[$current_scenario]"
# Four grouping cases, each its own fixture and run, so that keys of one case
# never group with another's (under left every cut key begins with the same
# attributes and ellipsis):
#   ids        (-g 60, left and center) four long messages differing only in a
#              request id at their start and end: one row, the ellipsis kept.
#   pairs      (-g 60, left) a long message and a copy that is not cut, alike
#              once the long one is cut, in both line orders: never grouped.
#   around-cut (-g 60, center) four long messages whose varying text sits
#              against both sides of the stored centre cut: grouping must not
#              fold the ellipsis into the wildcard.
#   offcentre  (-g 50, center) four long messages varying in a long token at
#              their start only: grouping shortens the stored start, leaving
#              the stored ellipsis off-centre; the row still shows one.
for position in left center; do
    run_ltl "ids-$position" -n 20 -g 60 -o -mt "$position" "$GROUPING_IDS_FIXTURE"
done
run_ltl pairs-left -n 20 -g 60 -o -mt left "$GROUPING_PAIRS_FIXTURE"
run_ltl around-cut-center -n 20 -g 60 -o -mt center "$GROUPING_AROUND_CUT_FIXTURE"
run_ltl offcentre-center -n 20 -g 50 -mt center "$GROUPING_OFFCENTRE_FIXTURE"
# rows <run> <case>: the rendered rows of one case, as
# "<occurrences> <ellipses> <attributes kept: 1|0>" lines.
rows() {
    "$PERL" -ne '
        next unless /(?:HEAD|TAIL)'"$2"'\b/;
        my $e = () = /\xe2\x80\xa6/g;
        my $a = /^.\s\[INFO\] \[main\] \[wt\.method\.server\.startup\] / ? 1 : 0;
        /\s(\d+)\s*$/ and print "$1 $e $a\n";
    ' "$TMP_DIR/$1/render.txt"
}
# csv_keys <run>: per CSV key, "<bytes> <ellipses>".
csv_keys() {
    "$PERL" -MText::CSV -e '
        my $c = Text::CSV->new({ binary => 1 });
        open my $fh, "<", $ARGV[0] or die "cannot open $ARGV[0]\n";
        $c->getline($fh);
        while (my $r = $c->getline($fh)) {
            my $k = $r->[1];
            utf8::encode($k) if utf8::is_utf8($k);
            my $e = () = $k =~ /\xe2\x80\xa6/g;
            print length($k), " $e\n";
        }
    ' "$(messages_csv "$1")"
}
for position in left center; do
    assert_command \
        command     "[[ \"\$(rows ids-$position G)\" == '4 1 1' && \"\$(csv_keys ids-$position)\" =~ ^[0-9]+\\ 1\$ ]] || { echo \"rows: \$(rows ids-$position G | tr '\\n' ';') CSV: \$(csv_keys ids-$position | tr '\\n' ';')\"; exit 1; }" \
        label       "-mt $position -g: four messages differing in an id group into one row, attributes and one ellipsis kept" \
        asserts     'Grouping wildcards the varying request id and keeps the ellipsis literally: one row of four with the attributes at its start and exactly one ellipsis, and one CSV key carrying it.' \
        produced_by 'keep_ellipsis_in_mask() in derive_canonical() and derive_regex(); fit_message_key_to_column() in ltl' \
        contract    "$DOC § Acceptance criteria AC5 (the ellipsis is never grouped or consolidated), § 3.1 D4 (never two ellipses)"
done
for case in QL QM; do
    assert_command \
        command     "[[ \"\$(rows pairs-left $case | cut -d' ' -f1 | tr '\\n' ' ')\" == '1 1 ' ]] || { echo \"$case rows: \$(rows pairs-left $case | tr '\\n' ';')\"; exit 1; }" \
        label       "-mt left -g: a cut message is not grouped with its uncut copy ($case)" \
        asserts     'A key carrying the ellipsis of a cut is never merged with one that does not, whichever of the two the grouping takes as its reference: the pair stays two rows.' \
        produced_by 'cut_markers_match() in the grouping passes (try_consolidation_merge_into_existing() and the candidate merges) in ltl' \
        contract    "$DOC § Acceptance criteria AC5 (the ellipsis is never grouped or consolidated)"
done
assert_command \
    command     "[[ \"\$(csv_keys around-cut-center)\" =~ ^[0-9]+\\ 1\$ ]] || { echo \"CSV keys: \$(csv_keys around-cut-center | tr '\\n' ';')\"; exit 1; }" \
    label       '-mt center -g: varying text against both sides of the stored ellipsis does not wildcard it away' \
    asserts     'The four messages group into one key, and that key still carries the ellipsis of its stored cut: grouping never folds the ellipsis into the wildcard on either side of it.' \
    produced_by 'keep_ellipsis_in_mask() in derive_canonical() and derive_regex() in ltl' \
    contract    "$DOC § Acceptance criteria AC5 (the ellipsis is never grouped or consolidated)"
assert_command \
    command     "[[ \"\$(rows offcentre-center H)\" == '4 1 1' ]] || { echo \"rows: \$(rows offcentre-center H | tr '\\n' ';')\"; exit 1; }" \
    label       '-mt center -g: a grouped key whose stored ellipsis moved off-centre shows one ellipsis' \
    asserts     'Grouping shortens the start of the stored key, so its ellipsis is no longer at the centre; the column cut splits the key at that ellipsis and puts one back, so the row never shows two.' \
    produced_by 'fit_message_key_to_column() and cut_message_text() in ltl' \
    contract    "$DOC § 3.1 D4 (the display cut splits a center-cut key at the stored ellipsis; two ellipses are not acceptable)"
assert_command \
    command     "for r in ids-left ids-center pairs-left around-cut-center; do csv_keys \$r; done | awk '\$1 > $KEY_CAP || \$2 > 1 { bad++ } END { print NR \" keys, \" bad+0 \" over\"; exit (NR == 0 || bad) }'" \
    label       '-g: no CSV key carries more than one ellipsis or exceeds the cap' \
    asserts     'A grouped key written to the CSV keeps at most the one ellipsis of its stored cut and stays within 350 bytes.' \
    produced_by 'keep_ellipsis_in_mask() and cut_markers_match() in ltl; written by print_message_summary()' \
    contract    "$DOC § Acceptance criteria AC5, AC8"
fi

echo
echo "─────────────────────────────────────────"
echo "  PASS: $pass    FAIL: $fail"
echo "─────────────────────────────────────────"
if [[ "$fail" -gt 0 ]]; then
    printf '  failed: %s\n' "${failures[@]}"
    exit 1
fi
echo "ALL MESSAGE-TRUNCATION TESTS PASSED"
