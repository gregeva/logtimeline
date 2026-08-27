#!/usr/bin/env bash
# validate-message-control-characters.sh — control-character normalisation of
# extracted message text (Issue #447).
#
# This is a RENDER-INVARIANT harness (tests/HARNESS-DESIGN.md § Render-invariant
# harnesses) with two companion surfaces. The messages table budgets its message
# column in characters and pads with sprintf "%-Ns", both of which assume one
# character occupies one terminal column. A control character inside the message
# breaks that assumption, so the invariant asserted here is:
#
#   every rendered messages-table row occupies exactly the same number of
#   terminal COLUMNS as every other row, and no message-derived output on any
#   surface carries a C0 control character or DEL.
#
# The fix is a single normalisation at parse time, not per-consumer cleaning:
# one call in read_and_process_logs() at the point every ingest path has
# finished writing the message and before anything reads it. The harness asserts
# on three consumers of the key — the rendered table, the messages CSV, and the
# -V message-grouping cluster-membership records — precisely because that is
# what a parse-time fix buys: all three come out clean without any of them
# knowing about the problem. Asserting on the table alone would also pass for a
# fix applied at render, which is the design this issue rejected.
#
# The assertions are properties, not frozen values: they hold for any input, so
# buggy-but-stable output cannot pass (HARNESS-DESIGN.md § Render-invariant
# harnesses).
#
# Each assertion records, per HARNESS-DESIGN.md § Self-documenting assertions:
#   - asserts:     the invariant being tested
#   - produced_by: where in ltl it is produced (function name, never a line)
#   - contract:    the source that makes the invariant stable
# All three are surfaced on failure.
#
# Usage: ./tests/validate-message-control-characters.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

LTL="$REPO_DIR/ltl"
PERL="${PERL:-/opt/homebrew/bin/perl}"
command -v "$PERL" >/dev/null 2>&1 || PERL=perl

# Invocation shape (HARNESS-DESIGN.md § Invocation coherence): the invariants
# read the rendered messages table, the messages CSV and one -V section. None of
# them depends on the time axis, so every run uses the coarsest bucket with
# empty buckets suppressed (-bs 1440 -oe) over a seven-line fixture spanning
# seconds. -ni keeps the developer's ltl-index.csv out of the run.
FIXTURE="$REPO_DIR/tests/fixtures/message-control-characters.txt"
UNMATCHED_FIXTURE="$REPO_DIR/tests/fixtures/message-control-characters-unmatched.txt"
WIDTH=140

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"

# Ambient FORCE_COLOR/NO_COLOR must not decide what this harness asserts against
# (HARNESS-DESIGN.md § Colour rendering is controlled, never inherited).
neutralize_colour_env

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"; exit 1
fi
if [[ ! -f "$FIXTURE" ]]; then
    echo "ERROR: fixture not found: $FIXTURE"; exit 1
fi
if [[ ! -f "$UNMATCHED_FIXTURE" ]]; then
    echo "ERROR: fixture not found: $UNMATCHED_FIXTURE"; exit 1
fi

TMP_DIR=$(mktemp -d); trap 'rm -rf "$TMP_DIR"' EXIT

pass=0
fail=0
failures=()
current_scenario=""

strip_ansi() { sed -E 's/\x1b\[[0-9;]*m//g'; }

# Self-documenting assertion (HARNESS-DESIGN.md § When the assertion isn't a
# simple line grep): runs `command`; PASS on exit 0, FAIL otherwise. On failure
# surfaces the command plus asserts/produced_by/contract.
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

# ---------------------------------------------------------------------------
# Checkers. Each exits non-zero with a diagnostic when the invariant is broken,
# and treats "anchor not found" as a hard failure (HARNESS-DESIGN.md §
# Harnesses must fail on missing anchors).
# ---------------------------------------------------------------------------

# Rendered messages-table rows all occupy the same number of terminal columns.
# Columns, not characters: a TAB advances to the next eight-column tab stop, so
# a row whose character count is correct can still overflow the table. Reads the
# ANSI-stripped render; the message rows are those carrying the fixture's logger
# name inside the bracketed key prefix.
check_render_columns() {
    "$PERL" -e '
        my ($render) = @ARGV;
        open my $fh, "<", $render or die "cannot open $render: $!\n";
        my (@rows, $n);
        while (my $line = <$fh>) {
            $line =~ s/\r?\n$//;
            next unless $line =~ /\[wt\.method\.server\./;
            # Terminal columns: TAB advances to the next multiple of 8; other
            # C0 characters and DEL occupy none.
            my $cols = 0;
            for my $ch (split //, $line) {
                if    ($ch eq "\t")      { $cols += 8 - ($cols % 8) }
                elsif ($ch =~ /[\x00-\x1f\x7f]/) { }
                else                     { $cols++ }
            }
            push @rows, { cols => $cols, chars => length($line), text => $line };
        }
        close $fh;
        unless (@rows) {
            print "anchor not found: no messages-table rows matched in $render\n";
            exit 1;
        }
        my %widths; $widths{ $_->{cols} }++ for @rows;
        if (keys %widths > 1) {
            printf "messages-table rows occupy differing terminal column counts: %s\n",
                join(", ", map { "$_ cols x$widths{$_}" } sort { $a <=> $b } keys %widths);
            for my $r (@rows) {
                printf "  cols=%-4d chars=%-4d %s\n", $r->{cols}, $r->{chars}, substr($r->{text}, 0, 90);
            }
            exit 1;
        }
        printf "%d rows, all %d terminal columns\n", scalar @rows, (keys %widths)[0];
        exit 0;
    ' "$1"
}

# No C0 control character or DEL survives anywhere in a message-derived field.
# Takes a file and a description; scans the whole file, so it also catches a
# control character that reached a surface the row scan above does not read.
# LF is excluded because it is the record separator of every surface checked.
check_no_control_chars() {
    "$PERL" -e '
        my ($path, $what, $allow) = @ARGV;
        $allow = "" unless defined $allow;
        open my $fh, "<", $path or die "cannot open $path: $!\n";
        local $/; my $data = <$fh>; close $fh;
        unless (length $data) { print "anchor not found: $path is empty\n"; exit 1 }
        my %ok = map { $_ => 1 } (0x0a, map { hex } split /,/, $allow ? $allow : "");
        my %seen;
        while ($data =~ /([\x00-\x1f\x7f])/g) {
            my $b = ord $1;
            next if $ok{$b};
            $seen{$b}++;
        }
        if (%seen) {
            printf "%s carries control bytes: %s\n", $what,
                join(", ", map { sprintf "0x%02x x%d", $_, $seen{$_} } sort { $a <=> $b } keys %seen);
            exit 1;
        }
        print "$what carries no control characters\n";
        exit 0;
    ' "$1" "$2" "${3:-}"
}

# A TAB in the source message renders as the agreed four spaces, and the other
# control characters are gone. Property, not a frozen row: the assertion is that
# the fixture's tab-bearing message reads with a four-space run at the point the
# tab occupied, and that no fixture message still shows a control character.
check_tab_expansion() {
    "$PERL" -e '
        my ($render) = @ARGV;
        open my $fh, "<", $render or die "cannot open $render: $!\n";
        my $found = 0;
        while (my $line = <$fh>) {
            next unless $line =~ /Horizontal tab here:/;
            $found = 1;
            unless ($line =~ /Horizontal tab here:    and text/) {
                print "tab did not expand to four spaces: ", substr($line, 0, 120), "\n";
                exit 1;
            }
        }
        unless ($found) {
            print "anchor not found: no row carrying the tab fixture message in $render\n";
            exit 1;
        }
        print "tab expanded to four spaces\n";
        exit 0;
    ' "$1"
}

# Every CSV record occupies exactly one physical line. A message carrying a CR
# or LF produces a quoted multi-line field, so the count of logical records
# parsed by a conformant reader diverges from the count of physical lines.
check_csv_one_line_per_record() {
    "$PERL" -MText::CSV -e '
        my ($path) = @ARGV;
        my $csv = Text::CSV->new({ binary => 1 });
        open my $fh, "<", $path or die "cannot open $path: $!\n";
        my $records = 0;
        $records++ while $csv->getline($fh);
        close $fh;
        open $fh, "<", $path or die "cannot open $path: $!\n";
        my $lines = 0;
        $lines++ while <$fh>;
        close $fh;
        unless ($records) { print "anchor not found: no CSV records in $path\n"; exit 1 }
        if ($records != $lines) {
            printf "CSV logical records (%d) != physical lines (%d): a field carries an embedded record separator\n",
                $records, $lines;
            exit 1;
        }
        printf "%d records, one physical line each\n", $records;
        exit 0;
    ' "$1"
}

# ---------------------------------------------------------------------------
# Scenario: one fixture, three surfaces.
# ---------------------------------------------------------------------------

current_scenario="control-character-normalisation"
echo "[$current_scenario]"

RENDER="$TMP_DIR/render.txt"
STDERR="$TMP_DIR/render.stderr"

set +e
( cd "$TMP_DIR" && "$LTL" --disable-progress -ni -bs 1440 -oe -g 60 -o \
    --terminal-width "$WIDTH" -V message-grouping "$FIXTURE" ) \
    2>"$STDERR" | strip_ansi > "$RENDER"
render_status=("${PIPESTATUS[@]}")
set -e

# The -V sections and the rendered table share one stream. Split them: the table
# invariants below assert on the table alone, and the cluster-membership records
# are asserted separately (they legitimately carry 0x1f as their own category/key
# separator, which is not message-derived).
TABLE="$TMP_DIR/table.txt"
VSECTIONS="$TMP_DIR/vsections.txt"
sed -n '/^=== message-grouping/,/^=== END message-grouping ===/p' "$RENDER" > "$VSECTIONS"
sed '/^=== message-grouping/,/^=== END message-grouping ===/d' "$RENDER" > "$TABLE"

if [[ "${render_status[0]}" -ne 0 ]]; then
    echo "  FAIL  $current_scenario :: ltl exited ${render_status[0]} while rendering" >&2
    sed 's/^/        /' "$STDERR" >&2
    exit 1
fi
if [[ ! -s "$RENDER" ]]; then
    echo "  FAIL  $current_scenario :: rendered output is empty" >&2
    exit 1
fi

# Runtime-warning cleanliness (HARNESS-DESIGN.md § Runtime-warning cleanliness).
if ! assert_no_runtime_warnings "$STDERR" "$current_scenario"; then
    fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
fi

MESSAGES_CSV=$(find "$TMP_DIR" -name '*-LTL-MESSAGES-*.csv' -print -quit)
if [[ -z "$MESSAGES_CSV" ]]; then
    echo "  FAIL  $current_scenario :: anchor not found: no messages CSV emitted by -o" >&2
    exit 1
fi

assert_command \
    command     "check_render_columns '$TABLE'" \
    label       'every messages-table row occupies the same number of terminal columns' \
    asserts     'Rows of the messages table are budgeted in characters and padded with sprintf "%-Ns", so one character must occupy one terminal column. Every rendered row must therefore occupy an identical column count; a TAB (which advances to the next eight-column tab stop) or any other control character in the message would make one row wider or narrower than its siblings and push the Occurrences cell off the line.' \
    produced_by 'read_and_process_logs() in ltl — the control-character normalisation on the ingest path; rows rendered by print_message_summary() in ltl' \
    contract    'features/447-message-control-character-normalisation.md § D1 — TAB expands to four spaces, other C0 characters and DEL are removed, at ingest'

assert_command \
    command     "check_no_control_chars '$TABLE' 'the rendered table'" \
    label       'no control character survives into the rendered output' \
    asserts     'C0 control characters other than the record separator must not reach the rendered surface. Each corrupts it differently: CR returns the cursor to column zero so the rest of the row overwrites its own start, and ESC is executed by the terminal as an ANSI sequence, re-colouring everything printed after it.' \
    produced_by 'read_and_process_logs() in ltl — the control-character normalisation on the ingest path' \
    contract    'features/447-message-control-character-normalisation.md § D1 — normalisation happens at ingest, so no render path can reintroduce it'

# The messages CSV carries the message key verbatim in column 2. A raw CR or LF
# there becomes an embedded newline inside a quoted field: still valid RFC 4180,
# but one logical row spread over two physical lines, which every line-oriented
# consumer (grep, awk, sed) reads as two records. 0x1f is likewise structural —
# it is the field separator of the per-message counter store.
assert_command \
    command     "check_no_control_chars '$MESSAGES_CSV' 'the messages CSV'" \
    label       'no control character survives into the messages CSV' \
    asserts     'The messages CSV writes the message key verbatim. A control character there is not merely cosmetic: a CR or LF becomes an embedded newline inside a quoted field, so one logical record spans two physical lines and every line-oriented consumer misreads it. Normalising at ingest means the CSV receives the same clean key the table does.' \
    produced_by 'read_and_process_logs() in ltl — the control-character normalisation on the ingest path; CSV written by print_message_summary() in ltl' \
    contract    'features/447-message-control-character-normalisation.md § D2 — one normalisation at ingest serves every consumer of the key'

assert_command \
    command     "check_csv_one_line_per_record '$MESSAGES_CSV'" \
    label       'every messages-CSV record occupies exactly one physical line' \
    asserts     'A message carrying a CR or LF produces a quoted multi-line CSV field, so the count of logical CSV records diverges from the count of physical lines. Equality of the two proves no message-derived field smuggled a record separator into the file.' \
    produced_by 'read_and_process_logs() in ltl — the control-character normalisation on the ingest path; CSV written by print_message_summary() in ltl' \
    contract    'features/447-message-control-character-normalisation.md § D2 — one normalisation at ingest serves every consumer of the key'

# The cluster-membership records use 0x1f to separate category from key, so a
# raw 0x1f inside a member key forges a boundary. Exactly one per `cluster:`
# line is legitimate; a `member:` line must carry none.
assert_command \
    command     "$PERL -e 'my \$bad=0; my \$seen=0; open my \$fh,\"<\",\$ARGV[0] or die; while (<\$fh>) { if (/^  cluster: /) { \$seen++; my \$n=tr/\\x1f//; if (\$n != 1) { print \"cluster line carries \$n unit separators, expected exactly 1: \$_\"; \$bad++ } } elsif (/^    member: /) { \$seen++; my \$n=tr/\\x1f//; if (\$n) { print \"member line carries \$n unit separators, expected 0: \$_\"; \$bad++ } } } close \$fh; unless (\$seen) { print \"anchor not found: no cluster/member records in the -V output\\n\"; exit 1 } exit(\$bad ? 1 : 0)' '$VSECTIONS'" \
    label       'no message key forges a unit-separator boundary in the cluster-membership records' \
    asserts     'The -V message-grouping cluster-membership records are line-oriented and use 0x1f to separate category from canonical key. A raw 0x1f inside a message key would forge that boundary, so a cluster line must carry exactly one separator and a member line none.' \
    produced_by 'read_and_process_logs() in ltl — the control-character normalisation on the ingest path; records emitted by group_similar_messages() in ltl' \
    contract    'features/447-message-control-character-normalisation.md § D2 — one normalisation at ingest serves every consumer of the key'

# ---------------------------------------------------------------------------
# Scenario 2: ungrouped. Without -g each message keeps its own row, so the
# per-message text is readable in the table and the TAB expansion can be
# asserted directly. Scenario 1 runs with -g 60 because the cluster-membership
# records only exist under consolidation; there the fixture's messages collapse
# into one wildcard row and no individual message text survives to assert on.
# ---------------------------------------------------------------------------

current_scenario="ungrouped-tab-expansion"
echo
echo "[$current_scenario]"

RENDER2="$TMP_DIR/render-ungrouped.txt"
STDERR2="$TMP_DIR/render-ungrouped.stderr"

set +e
( cd "$TMP_DIR" && "$LTL" --disable-progress -ni -bs 1440 -oe \
    --terminal-width "$WIDTH" "$FIXTURE" ) \
    2>"$STDERR2" | strip_ansi > "$RENDER2"
render2_status=("${PIPESTATUS[@]}")
set -e

if [[ "${render2_status[0]}" -ne 0 ]]; then
    echo "  FAIL  $current_scenario :: ltl exited ${render2_status[0]} while rendering" >&2
    sed 's/^/        /' "$STDERR2" >&2
    exit 1
fi
if [[ ! -s "$RENDER2" ]]; then
    echo "  FAIL  $current_scenario :: rendered output is empty" >&2
    exit 1
fi

if ! assert_no_runtime_warnings "$STDERR2" "$current_scenario"; then
    fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
fi

assert_command \
    command     "check_render_columns '$RENDER2'" \
    label       'every messages-table row occupies the same number of terminal columns' \
    asserts     'Rows of the messages table are budgeted in characters and padded with sprintf "%-Ns", so one character must occupy one terminal column. With each message on its own row, a TAB or other control character in any one of them would make that row wider or narrower than its siblings and push the Occurrences cell off the line.' \
    produced_by 'read_and_process_logs() in ltl — the control-character normalisation on the ingest path; rows rendered by print_message_summary() in ltl' \
    contract    'features/447-message-control-character-normalisation.md § D1 — TAB expands to four spaces, other C0 characters and DEL are removed, at ingest'

assert_command \
    command     "check_tab_expansion '$RENDER2'" \
    label       'a TAB in the source message renders as four spaces' \
    asserts     'TAB is the one control character with a defensible width and is preserved as separation rather than dropped: it expands to exactly four spaces. A fixed expansion is stable regardless of which column the tab lands in, unlike a terminal tab stop, whose advance depends on where the tab falls.' \
    produced_by 'read_and_process_logs() in ltl — the control-character normalisation on the ingest path' \
    contract    'features/447-message-control-character-normalisation.md § D1 — TAB expands to four spaces'

assert_command \
    command     "check_no_control_chars '$RENDER2' 'the rendered table'" \
    label       'no control character survives into the rendered output' \
    asserts     'C0 control characters other than the record separator must not reach the rendered surface. Each corrupts it differently: CR returns the cursor to column zero so the rest of the row overwrites its own start, and ESC is executed by the terminal as an ANSI sequence, re-colouring everything printed after it.' \
    produced_by 'read_and_process_logs() in ltl — the control-character normalisation on the ingest path' \
    contract    'features/447-message-control-character-normalisation.md § D1 — normalisation happens at ingest, so no render path can reintroduce it'

# ---------------------------------------------------------------------------
# Scenario 3: a line no format matches contributes no message. The record
# lexicals are cleared as a side effect of the scan's failed list-assignment
# matches; a space-led line is rejected by the whitespace dispatch before any
# block runs, so it performs no such match and $message still holds the PREVIOUS
# matched line's text. The message key is built behind an $is_line_match gate
# that already excludes such a line, so this scenario is regression cover for
# that exclusion — it is what makes it safe for #447 to normalise ahead of it.
# ---------------------------------------------------------------------------

current_scenario="unmatched-line-not-normalised"
echo
echo "[$current_scenario]"

RENDER3="$TMP_DIR/render-unmatched.txt"
STDERR3="$TMP_DIR/render-unmatched.stderr"

set +e
( cd "$TMP_DIR" && "$LTL" --disable-progress -ni -bs 1440 -oe -n 10 \
    --terminal-width "$WIDTH" "$UNMATCHED_FIXTURE" ) \
    2>"$STDERR3" | strip_ansi > "$RENDER3"
render3_status=("${PIPESTATUS[@]}")
set -e

if [[ "${render3_status[0]}" -ne 0 ]]; then
    echo "  FAIL  $current_scenario :: ltl exited ${render3_status[0]} while rendering" >&2
    sed 's/^/        /' "$STDERR3" >&2
    exit 1
fi

if ! assert_no_runtime_warnings "$STDERR3" "$current_scenario"; then
    fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
fi

assert_command \
    command     "$PERL -e 'my (\$read, \$incl); open my \$fh, \"<\", \$ARGV[0] or die; while (<\$fh>) { \$read = \$1 if /LINES READ\\s+(\\d+)/; \$incl = \$1 if /LINES INCLUDED\\s+(\\d+)/ } close \$fh; unless (defined \$read && defined \$incl) { print \"anchor not found: LINES READ / LINES INCLUDED absent\\n\"; exit 1 } if (\$read != 3 || \$incl != 2) { print \"expected 3 read / 2 included, got \$read / \$incl\\n\"; exit 1 } print \"3 read, 2 included\\n\"; exit 0' '$RENDER3'" \
    label       'the space-led unmatched line is read but not counted as a message' \
    asserts     'A line no format matches must not contribute a message. The fixture is three lines: two matched and one space-led line the whitespace dispatch rejects before any format block runs, which therefore still carries the preceding line text in the record lexicals. Read must be 3 and included 2 — an included count of 3 would mean that stale message was re-counted.' \
    produced_by 'read_and_process_logs() in ltl — the $is_line_match gate on message-key construction' \
    contract    'features/447-message-control-character-normalisation.md § D5 — an unmatched line carries no message of its own'

assert_command \
    command     "$PERL -e 'my \$n = 0; open my \$fh, \"<\", \$ARGV[0] or die; while (<\$fh>) { \$n++ if /\\[wt\\.method\\.server\\./ } close \$fh; unless (\$n) { print \"anchor not found: no message rows rendered\\n\"; exit 1 } if (\$n != 2) { print \"expected 2 distinct message rows, got \$n\\n\"; exit 1 } print \"2 distinct message rows\\n\"; exit 0' '$RENDER3'" \
    label       'the unmatched line produces no additional message row' \
    asserts     'The two matched lines carry different text, so exactly two message rows must render. A third row, or a duplicated one, would mean the unmatched line was processed as though it carried the previous line message.' \
    produced_by 'read_and_process_logs() in ltl — the $is_line_match gate on message-key construction; rows rendered by print_message_summary() in ltl' \
    contract    'features/447-message-control-character-normalisation.md § D5 — an unmatched line carries no message of its own'

assert_command \
    command     "check_no_control_chars '$RENDER3' 'the rendered table'" \
    label       'no control character survives into the rendered output' \
    asserts     'The matched line carries a TAB, so the normalisation must still run on it; the unmatched line must not reintroduce a control character. Both hold only if the gate admits matched lines and excludes unmatched ones.' \
    produced_by 'read_and_process_logs() in ltl — the control-character normalisation on the ingest path' \
    contract    'features/447-message-control-character-normalisation.md § D1 — normalisation happens at ingest'

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
