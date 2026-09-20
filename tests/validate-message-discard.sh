#!/usr/bin/env bash
# validate-message-discard.sh — named keys and values removed from the run
# (Issue #567, acceptance criteria 1-13).
#
# The feature: `-d <name>` / `--discard <name>` names a part of the line that
# takes no part in the run. Nothing is left behind: a discarded parsed field
# is absent from the message key and from every count and capture of it, a
# discarded key written in the line goes with its value and one separator, a
# discarded UUID or IP address closes the gap it leaves, and a discarded
# metric is not read at all. Several names are given as a comma-separated
# list or by repeating the option.
#
# This harness reads the MESSAGES CSV, which carries the message key verbatim
# (cut at 350 characters), rather than the rendered table: the key is internal
# state the table only displays, and a width-dependent assertion would be a
# different test. The rendered output is read only where the criterion is
# about a rendered surface - the thread-pool activity table under -d thread.
#
# Each assertion records, per tests/HARNESS-DESIGN.md section Self-documenting
# assertions:
#   - asserts:     the invariant being tested
#   - produced_by: where in ltl it is produced (function name, never a line)
#   - contract:    the source that makes the invariant stable
# All three are surfaced on failure, and every anchor that matches nothing is a
# hard failure (section Harnesses must fail on missing anchors).
#
# Every expected key in this file is computed from the committed fixture text,
# never read back from ltl. The fixture lines are short, so no key reaches the
# 350-character cut: a key cut after a removal cannot be predicted by removing
# from the uncut key.
#
# Usage: ./tests/validate-message-discard.sh [--scenario NAME]
#        ./tests/validate-message-discard.sh --list

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

LTL="$REPO_DIR/ltl"
PERL="${PERL:-/opt/homebrew/bin/perl}"
command -v "$PERL" >/dev/null 2>&1 || PERL=perl

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"

# Ambient FORCE_COLOR/NO_COLOR must not decide what this harness asserts
# against (HARNESS-DESIGN.md section Colour rendering is controlled, never
# inherited).
neutralize_colour_env

# Invocation shape (HARNESS-DESIGN.md section Invocation coherence): every
# assertion reads the message key out of the MESSAGES CSV, a count out of one
# -V section, a rendered thread-pool table, or a stderr notice. None depends
# on the time axis, so every run uses the coarsest bucket with empty buckets
# suppressed (-bs 1440 -oe) over fixtures spanning seconds; -n 100 is larger
# than the distinct-message count of every fixture, so no message row is
# dropped from the CSV (-n 0 would write no CSV at all); -ni keeps the
# developer's ltl-index.csv out of the run; -o writes the CSVs into a
# directory this harness created and owns.

CONTRACT_DOC='features/567-discard-named-values-from-message.md'
PRODUCED_RESOLVE='adapt_to_command_line_options() in ltl, through resolve_discard_names() (the -d/--discard resolution into the field, substitution and metric lists)'
PRODUCED_FIELD='read_and_process_logs() in ltl (the discarded-field clearing, applied where every ingest path has written the fields and nothing has read them)'
PRODUCED_MESSAGE='read_and_process_logs() in ltl (the discard block, applied to the formed message after the exposed values are added and before the masks run)'
PRECEDENCE='apply_discard_precedence() in ltl (discard wins over expose and over mask, and the notice that says so)'

DISCARD_FIXTURE="$REPO_DIR/tests/fixtures/message-discard-values.txt"
DOWNLOAD_FIXTURE="$REPO_DIR/tests/fixtures/message-expose-download-requests.txt"
THREAD_FIXTURE="$REPO_DIR/tests/fixtures/format-detection/access-thread-session.txt"
USERS_FIXTURE="$REPO_DIR/tests/fixtures/format-detection/access-users-sessions.txt"
OBJECT_FIXTURE="$REPO_DIR/tests/fixtures/format-detection/thingworx-application-log.txt"
METRICS_FIXTURE="$REPO_DIR/tests/fixtures/numeric-highlight-boundary.txt"
QS_FIXTURE="$REPO_DIR/tests/fixtures/udm-counting-query-string.txt"

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"; exit 1
fi
for f in "$DISCARD_FIXTURE" "$DOWNLOAD_FIXTURE" "$THREAD_FIXTURE" "$USERS_FIXTURE" \
         "$OBJECT_FIXTURE" "$METRICS_FIXTURE" "$QS_FIXTURE"; do
    if [[ ! -f "$f" ]]; then echo "ERROR: fixture not found: $f"; exit 1; fi
done

TMP_DIR=$(mktemp -d); trap 'rm -rf "$TMP_DIR"' EXIT

pass=0
fail=0
failures=()
current_scenario=""

# ---------------------------------------------------------------------------
# Assertions
# ---------------------------------------------------------------------------

# Self-documenting assertion (HARNESS-DESIGN.md section When the assertion
# isn't a simple line grep): runs `command`; PASS on exit 0, FAIL otherwise.
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

record_failure() {
    local what="$1"
    fail=$((fail + 1))
    failures+=("$current_scenario :: $what")
}

# ---------------------------------------------------------------------------
# Capture
# ---------------------------------------------------------------------------
RUN_DIR=""; RUN_OUT=""; RUN_ERR=""; MSG_CSV=""; STATS_CSV=""
run_messages() {
    local label="$1"; shift
    RUN_DIR="$TMP_DIR/$current_scenario/$label"
    mkdir -p "$RUN_DIR"
    RUN_OUT="$RUN_DIR/run.out"; RUN_ERR="$RUN_DIR/run.err"; MSG_CSV=""; STATS_CSV=""
    local rc
    set +e
    ( cd "$RUN_DIR" && "$LTL" --disable-progress -ni -bs 1440 -oe -n 100 -o "$@" \
        > run.out 2> run.err )
    rc=$?
    set -e

    if ! assert_no_runtime_warnings "$RUN_DIR/run.err" "$current_scenario/$label"; then
        record_failure "perl-runtime-warnings-on-stderr ($label)"
    fi
    if [[ "$rc" -ne 0 ]]; then
        echo "  FAIL  $current_scenario :: ltl exited $rc for run '$label'"
        echo "        command:     ltl --disable-progress -ni -bs 1440 -oe -n 100 -o $*"
        echo "        asserts:     every ltl invocation in this harness completes and writes its CSVs"
        echo "        produced_by: $PRODUCED_RESOLVE"
        echo "        contract:    $CONTRACT_DOC section Decisions D7 - -d/--discard is an accepted option"
        sed 's/^/        | /' "$RUN_DIR/run.err"
        record_failure "ltl exit $rc ($label)"
        return 1
    fi

    MSG_CSV=$(find "$RUN_DIR" -name '*-LTL-MESSAGES-*.csv' -print -quit)
    if [[ -z "$MSG_CSV" ]]; then
        echo "  FAIL  $current_scenario :: anchor not found: run '$label' wrote no MESSAGES CSV"
        record_failure "no MESSAGES CSV ($label)"
        return 1
    fi
    STATS_CSV=$(find "$RUN_DIR" -name '*-LTL-STATS-*.csv' -print -quit)
    if [[ -z "$STATS_CSV" ]]; then
        echo "  FAIL  $current_scenario :: anchor not found: run '$label' wrote no STATS CSV"
        record_failure "no STATS CSV ($label)"
        return 1
    fi
    return 0
}

# ---------------------------------------------------------------------------
# Checkers
# ---------------------------------------------------------------------------

# The MESSAGES CSV holds exactly the expected message keys, as a multiset.
check_keys() {
    "$PERL" -MText::CSV -e '
        my ($csv_path, $expected_path) = @ARGV;
        my $csv = Text::CSV->new({ binary => 1 });
        open my $fh, "<", $csv_path or die "cannot open $csv_path: $!\n";
        my $header = $csv->getline($fh);
        unless ($header && @$header && $header->[1] eq "message") {
            print "anchor not found: $csv_path has no message column in its header\n";
            exit 1;
        }
        my @got;
        while (my $row = $csv->getline($fh)) {
            next unless defined $row->[1] && length $row->[1];
            push @got, $row->[1];
        }
        close $fh;
        unless (@got) { print "anchor not found: no message rows in $csv_path\n"; exit 1 }
        open my $ef, "<", $expected_path or die "cannot open $expected_path: $!\n";
        my @want = grep { length } map { chomp; $_ } <$ef>;
        close $ef;
        unless (@want) { print "harness defect: no expected keys given\n"; exit 1 }
        my %g; $g{$_}++ for @got;
        my %w; $w{$_}++ for @want;
        my (@missing, @extra);
        for my $k (sort keys %w) {
            my $short = $w{$k} - ($g{$k} // 0);
            push @missing, $k for 1 .. ($short > 0 ? $short : 0);
        }
        for my $k (sort keys %g) {
            my $over = $g{$k} - ($w{$k} // 0);
            push @extra, $k for 1 .. ($over > 0 ? $over : 0);
        }
        if (@missing || @extra) {
            printf "message keys differ: %d expected, %d produced\n", scalar @want, scalar @got;
            print "  expected but absent: $_\n" for @missing;
            print "  produced but not expected: $_\n" for @extra;
            exit 1;
        }
        printf "%d message keys, all as expected\n", scalar @got;
        exit 0;
    ' "$1" "$2"
}

# No message key in the CSV matches the pattern. The CSV must carry rows, so
# an empty CSV cannot pass an absence assertion.
check_no_key_matches() {
    "$PERL" -MText::CSV -e '
        my ($csv_path, $pattern) = @ARGV;
        my $csv = Text::CSV->new({ binary => 1 });
        open my $fh, "<", $csv_path or die "cannot open $csv_path: $!\n";
        my $header = $csv->getline($fh);
        unless ($header && @$header && $header->[1] eq "message") {
            print "anchor not found: $csv_path has no message column in its header\n";
            exit 1;
        }
        my (@rows, @hit);
        while (my $row = $csv->getline($fh)) {
            next unless defined $row->[1] && length $row->[1];
            push @rows, $row->[1];
            push @hit, $row->[1] if $row->[1] =~ /$pattern/;
        }
        close $fh;
        unless (@rows) { print "anchor not found: no message rows in $csv_path\n"; exit 1 }
        if (@hit) {
            printf "%d of %d keys still match /%s/:\n", scalar @hit, scalar @rows, $pattern;
            print "  $_\n" for @hit[0 .. ($#hit > 4 ? 4 : $#hit)];
            exit 1;
        }
        printf "none of %d keys match /%s/\n", scalar @rows, $pattern;
        exit 0;
    ' "$1" "$2"
}

# At least one message key matches, so an absence assertion elsewhere is known
# to be testing something the fixture actually carries.
check_some_key_matches() {
    "$PERL" -MText::CSV -e '
        my ($csv_path, $pattern) = @ARGV;
        my $csv = Text::CSV->new({ binary => 1 });
        open my $fh, "<", $csv_path or die "cannot open $csv_path: $!\n";
        my $header = $csv->getline($fh);
        unless ($header && @$header && $header->[1] eq "message") {
            print "anchor not found: $csv_path has no message column in its header\n";
            exit 1;
        }
        my (@rows, @hit);
        while (my $row = $csv->getline($fh)) {
            next unless defined $row->[1] && length $row->[1];
            push @rows, $row->[1];
            push @hit, $row->[1] if $row->[1] =~ /$pattern/;
        }
        close $fh;
        unless (@rows) { print "anchor not found: no message rows in $csv_path\n"; exit 1 }
        unless (@hit) {
            printf "anchor not found: none of %d keys match /%s/, so the fixture does not carry the case\n",
                scalar @rows, $pattern;
            exit 1;
        }
        printf "%d of %d keys match /%s/\n", scalar @hit, scalar @rows, $pattern;
        exit 0;
    ' "$1" "$2"
}

# Two CSVs carry identical content, and the comparison is not empty-vs-empty.
check_same_csv() {
    local a="$1" b="$2" what="$3"
    if [[ ! -s "$a" || ! -s "$b" ]]; then
        echo "anchor not found: one of the two $what CSVs is missing or empty ($a, $b)"
        return 1
    fi
    local rows
    rows=$(($(wc -l < "$a")))
    if [[ "$rows" -lt 2 ]]; then
        echo "anchor not found: $a carries only a header, so an equality assertion proves nothing"
        return 1
    fi
    if ! cmp -s "$a" "$b"; then
        echo "$what CSVs differ:"
        { diff --unified=2 "$a" "$b" || true; } | head -30
        return 1
    fi
    echo "$what CSVs identical over $rows lines"
    return 0
}

# A stderr file carries exactly one notice matching the pattern.
check_one_notice() {
    local errfile="$1" pattern="$2"
    if [[ ! -f "$errfile" ]]; then
        echo "anchor not found: no stderr captured at $errfile"
        return 1
    fi
    local n
    n=$(grep -cE "$pattern" "$errfile" || true)
    if [[ "$n" -ne 1 ]]; then
        echo "expected exactly one notice matching /$pattern/, found $n:"
        sed 's/^/  | /' "$errfile"
        return 1
    fi
    echo "one notice matching /$pattern/"
    return 0
}

# A named column is present in, or absent from, the rendered table's header
# row. The header is the one line carrying the timestamp column, so the test
# cannot be satisfied by the echoed command line or by a filename in the file
# list - both of which carry option and fixture names as ordinary text. A
# missing header row is a hard failure, never a pass.
check_column_header() {
    local outfile="$1" column="$2" expectation="$3"
    local header
    header=$(sed 's/\x1b\[[0-9;]*m//g' "$outfile" | grep -E '^\s+timestamp\s' | head -1 || true)
    if [[ -z "$header" ]]; then
        echo "anchor not found: no column header row in $outfile"
        return 1
    fi
    if grep -qE "[[:space:]]${column}([[:space:]]|\$)" <<<"$header"; then
        if [[ "$expectation" == "present" ]]; then
            echo "column $column is in the header"
            return 0
        fi
        echo "column $column is still in the header: $header"
        return 1
    fi
    if [[ "$expectation" == "absent" ]]; then
        echo "column $column is not in the header"
        return 0
    fi
    echo "column $column is not in the header: $header"
    return 1
}

# Write an expectation file, one message key per argument.
write_expected() {
    local path="$1"; shift
    mkdir -p "$(dirname "$path")"
    : > "$path"
    local row
    for row in "$@"; do printf '%s\n' "$row" >> "$path"; done
    printf '%s' "$path"
}

# ---------------------------------------------------------------------------
# The fixtures, and the keys they imply
# ---------------------------------------------------------------------------
# tests/fixtures/message-discard-values.txt — fourteen ThingWorx standard
# lines on one thread and one object, whose messages carry:
#   lines 1-6   the six separator positions of D16, each with sign=abc: the
#               pair between two others, first after the ?, last after an &,
#               alone after the ?, mid-message between spaces, and last in
#               the message.
#   lines 7-11  the five cases of D19: a UUID between slashes, an IPv4
#               address between spaces, a UUID in brackets, an IPv4 address
#               in brackets, and a UUID as a key's value.
#   lines 12-14 IPv6 addresses between spaces, between slashes, and beside
#               an IPv4 address, so that -d ipv4 and -d ipv6 are told apart.
#   lines 15-16 the same key written with a colon, and both spellings on one
#               line, so that the = and : of the shared token rule are both
#               asserted rather than only the one the other fixtures use.
# Addresses are from the documentation ranges (192.0.2.0/24, 2001:db8::/32).
# Every line shares the level, thread and object, so the key prefix is fixed
# and the assertions are about the message alone.
DF='[INFO] [pool-a] [DiscardFixture]'

# Criterion 2 (D16): each separator position ends exactly as the table says.
scenario_key_separators() {
    current_scenario="key-separators"
    echo "[$current_scenario]"

    run_messages plain "$DISCARD_FIXTURE" || return 0
    assert_command \
        command     "check_some_key_matches '$MSG_CSV' 'sign=abc'" \
        label       'the fixture carries the sign key the removal is asserted against' \
        asserts     'The absence assertions below test a key the fixture actually carries: without -d, sign=abc is present in the message keys.' \
        produced_by "$PRODUCED_MESSAGE" \
        contract    "$CONTRACT_DOC section Acceptance criteria 2"

    run_messages discard -d sign "$DISCARD_FIXTURE" || return 0
    local expected
    expected=$(write_expected "$TMP_DIR/$current_scenario/expected.txt" \
        "$DF GET /app/regen?folderId=1&sT=9" \
        "$DF GET /app/regen?sT=9" \
        "$DF GET /app/regen?folderId=1" \
        "$DF GET /app/regen" \
        "$DF Request done status=ok" \
        "$DF Request done status:ok" \
        "$DF Request done" \
        "$DF mixed and other here" \
        "$DF GET /store/orders/3f9c2a71-8be4-4d0a-9c15-6e2b7d40a8f3/items/summary" \
        "$DF connection from 192.0.2.10 closed" \
        "$DF ErrorCode(de4882d2-d816-4940-ae83-c2f346e19335), Cause(null)" \
        "$DF client (192.0.2.11) refused" \
        "$DF id=3f9c2a71-8be4-4d0a-9c15-6e2b7d40a8f3&x=1" \
        "$DF peer 2001:db8::8a2e:370:7334 disconnected" \
        "$DF route /gw/2001:db8::1/inbound ready" \
        "$DF pair 192.0.2.12 and 2001:db8::2 established")

    assert_command \
        command     "check_keys '$MSG_CSV' '$expected'" \
        label       'each of the six separator positions ends exactly as D16 states' \
        asserts     'A discarded key takes its value and the separator that follows it, or, at the end of the message, the one before it: a pair between two others leaves one separator, a pair alone after the ? leaves neither, and a pair at the end of the message takes the space or ? before it.' \
        produced_by "$PRODUCED_MESSAGE" \
        contract    "$CONTRACT_DOC section Decisions D16 (the six-row table) and Acceptance criteria 2"

    assert_command \
        command     "check_no_key_matches '$MSG_CSV' '(&&|[?]&|[&?]\$)'" \
        label       'no key carries a doubled or dangling separator' \
        asserts     'Removing a key-value pair never leaves && or ?& behind, and never leaves a key ending in & or ?.' \
        produced_by "$PRODUCED_MESSAGE" \
        contract    "$CONTRACT_DOC section Decisions D16"

    assert_command \
        command     "check_no_key_matches '$MSG_CSV' 'sign[=:]'" \
        label       'the key goes whether it is written with = or with :' \
        asserts     'The value of a named key is read by the token rule -udm and -x share, which accepts = or : between the key and its value, so a key written either way is removed. A log writing sign:abc is read exactly as one writing sign=abc.' \
        produced_by "$PRODUCED_MESSAGE" \
        contract    "$CONTRACT_DOC section Decisions D2 - the token rule -udm and -x use, one resolution surface for all three"
    assert_command \
        command     "check_some_key_matches '$MSG_CSV' 'Request done status:ok'" \
        label       'a colon-separated pair takes its separator and leaves the rest of the message' \
        asserts     'Request done sign:abc status:ok becomes Request done status:ok: the colon form takes the space after the pair exactly as the equals form does, and the neighbouring colon-separated pair is left as written.' \
        produced_by "$PRODUCED_MESSAGE" \
        contract    "$CONTRACT_DOC section Decisions D16"
    assert_command \
        command     "check_some_key_matches '$MSG_CSV' 'mixed and other here'" \
        label       'both spellings go in one pass on the same line' \
        asserts     'A line carrying the named key written both ways loses both occurrences: the two separators are not alternatives the analyst must choose between.' \
        produced_by "$PRODUCED_MESSAGE" \
        contract    "$CONTRACT_DOC section Decisions D16 - every occurrence goes"
}

# Criterion 11 (D14, D19): the identifier cases, and the versions told apart.
scenario_identifiers() {
    current_scenario="identifiers"
    echo "[$current_scenario]"

    run_messages uuid -d uuid "$DISCARD_FIXTURE" || return 0
    local expected_uuid
    expected_uuid=$(write_expected "$TMP_DIR/$current_scenario/expected-uuid.txt" \
        "$DF GET /store/orders/items/summary" \
        "$DF ErrorCode(), Cause(null)" \
        "$DF id=&x=1" \
        "$DF GET /app/regen?folderId=1&sign=abc&sT=9" \
        "$DF GET /app/regen?sign=abc&sT=9" \
        "$DF GET /app/regen?folderId=1&sign=abc" \
        "$DF GET /app/regen?sign=abc" \
        "$DF Request done sign=abc status=ok" \
        "$DF Request done sign=abc" \
        "$DF Request done sign:abc status:ok" \
        "$DF mixed sign=abc and other sign:def here" \
        "$DF connection from 192.0.2.10 closed" \
        "$DF client (192.0.2.11) refused" \
        "$DF peer 2001:db8::8a2e:370:7334 disconnected" \
        "$DF route /gw/2001:db8::1/inbound ready" \
        "$DF pair 192.0.2.12 and 2001:db8::2 established")
    assert_command \
        command     "check_keys '$MSG_CSV' '$expected_uuid'" \
        label       'a removed UUID closes the gap it leaves, and leaves brackets standing' \
        asserts     'A UUID between two slashes takes the slash after it; one in brackets leaves the brackets; one that is a key value leaves the key and its separator. IP addresses are untouched by -d uuid.' \
        produced_by "$PRODUCED_MESSAGE" \
        contract    "$CONTRACT_DOC section Decisions D19 (the five-row table)"

    run_messages ipv4 -d ipv4 "$DISCARD_FIXTURE" || return 0
    assert_command \
        command     "check_no_key_matches '$MSG_CSV' '192[.]0[.]2[.]'" \
        label       '-d ipv4 removes every IPv4 address' \
        asserts     'Every IPv4 address in the documentation range is gone from the message keys.' \
        produced_by "$PRODUCED_MESSAGE" \
        contract    "$CONTRACT_DOC section Decisions D14 - ip, ipv4 and ipv6 are built-in names"
    assert_command \
        command     "check_some_key_matches '$MSG_CSV' '2001:db8'" \
        label       '-d ipv4 leaves the IPv6 addresses as written' \
        asserts     'Naming one address version does not remove the other.' \
        produced_by "$PRODUCED_MESSAGE" \
        contract    "$CONTRACT_DOC section Acceptance criteria 11"
    assert_command \
        command     "check_some_key_matches '$MSG_CSV' 'client [(][)] refused'" \
        label       'an IPv4 address in brackets leaves the brackets' \
        asserts     'Where no separator sits either side of the address, only the address goes: client (192.0.2.11) refused becomes client () refused.' \
        produced_by "$PRODUCED_MESSAGE" \
        contract    "$CONTRACT_DOC section Decisions D19"

    run_messages ipv6 -d ipv6 "$DISCARD_FIXTURE" || return 0
    assert_command \
        command     "check_no_key_matches '$MSG_CSV' '2001:db8'" \
        label       '-d ipv6 removes every IPv6 address' \
        asserts     'Every IPv6 address in the documentation range is gone from the message keys.' \
        produced_by "$PRODUCED_MESSAGE" \
        contract    "$CONTRACT_DOC section Decisions D14"
    assert_command \
        command     "check_some_key_matches '$MSG_CSV' '192[.]0[.]2[.]'" \
        label       '-d ipv6 leaves the IPv4 addresses as written' \
        asserts     'Naming one address version does not remove the other.' \
        produced_by "$PRODUCED_MESSAGE" \
        contract    "$CONTRACT_DOC section Acceptance criteria 11"
    assert_command \
        command     "check_some_key_matches '$MSG_CSV' 'route /gw/inbound ready'" \
        label       'an IPv6 address between slashes takes the slash after it' \
        asserts     'The same-separator rule holds for IPv6 as for IPv4 and UUIDs: route /gw/2001:db8::1/inbound ready becomes route /gw/inbound ready.' \
        produced_by "$PRODUCED_MESSAGE" \
        contract    "$CONTRACT_DOC section Decisions D19"

    run_messages ip -d ip "$DISCARD_FIXTURE" || return 0
    assert_command \
        command     "check_no_key_matches '$MSG_CSV' '(192[.]0[.]2[.]|2001:db8)'" \
        label       '-d ip removes both address versions' \
        asserts     'ip names either version, so no address of either kind survives.' \
        produced_by "$PRODUCED_RESOLVE" \
        contract    "$CONTRACT_DOC section Decisions D14 - ip names either version"
    assert_command \
        command     "check_some_key_matches '$MSG_CSV' 'de4882d2-d816-4940-ae83-c2f346e19335'" \
        label       '-d ip leaves the UUIDs as written' \
        asserts     'Naming the addresses does not remove UUIDs.' \
        produced_by "$PRODUCED_MESSAGE" \
        contract    "$CONTRACT_DOC section Acceptance criteria 11"
}

# Criterion 1, 3 (D1, D2, D6, D10, D16): the download requests the issue is for.
scenario_download_requests() {
    current_scenario="download-requests"
    echo "[$current_scenario]"

    run_messages list -xqs -d sign,sT "$DOWNLOAD_FIXTURE" || return 0
    local list_msg="$MSG_CSV"
    assert_command \
        command     "check_no_key_matches '$list_msg' '(sign=|sT=)'" \
        label       'no key carries sign= or sT=' \
        asserts     'Both named keys are gone from every message key, with the query string exposed.' \
        produced_by "$PRODUCED_MESSAGE" \
        contract    "$CONTRACT_DOC section Acceptance criteria 1"
    assert_command \
        command     "check_no_key_matches '$list_msg' '(&&|[?]&|[&?]\$)'" \
        label       'no key carries a doubled or dangling separator' \
        asserts     'Removing two adjacent pairs from a query string leaves the remaining parameters correctly separated.' \
        produced_by "$PRODUCED_MESSAGE" \
        contract    "$CONTRACT_DOC section Decisions D16"
    assert_command \
        command     "check_some_key_matches '$list_msg' 'fileName=alpha[.]pdf'" \
        label       'the keys the analyst wants are still there' \
        asserts     'Discarding the per-request parameters leaves the file identity in the message: the removal is targeted, not a truncation of the query string.' \
        produced_by "$PRODUCED_MESSAGE" \
        contract    "$CONTRACT_DOC section Motivating consumer"

    run_messages repeated -xqs -d sign -d sT "$DOWNLOAD_FIXTURE" || return 0
    assert_command \
        command     "check_same_csv '$list_msg' '$MSG_CSV' 'messages'" \
        label       '-d sign,sT is the same as -d sign -d sT' \
        asserts     'A comma-separated list names the same parts as repeating the option, and produces the same messages.' \
        produced_by "$PRODUCED_RESOLVE" \
        contract    "$CONTRACT_DOC section Decisions D10"

    # Criterion 3 (D6): -x fileName adds nothing, the exposed query string
    # already carrying it, so the run is identical to -xqs -d sign alone.
    run_messages sign_only -xqs -d sign "$DOWNLOAD_FIXTURE" || return 0
    local sign_only_msg="$MSG_CSV"
    run_messages sign_expose -xqs -d sign -x fileName "$DOWNLOAD_FIXTURE" || return 0
    assert_command \
        command     "check_same_csv '$sign_only_msg' '$MSG_CSV' 'messages'" \
        label       '-xqs -d sign -x fileName is identical to -xqs -d sign' \
        asserts     'An exposed key whose value the formed message still yields is not appended, so naming it alongside a discard changes nothing.' \
        produced_by "$PRODUCED_MESSAGE" \
        contract    "$CONTRACT_DOC section Decisions D6"
}

# Criterion 4 (D8, D9, D12, D13): the thread, cleared from the whole run.
scenario_thread() {
    current_scenario="thread"
    echo "[$current_scenario]"

    run_messages plain -tpas "$THREAD_FIXTURE" || return 0
    assert_command \
        command     "check_some_key_matches '$MSG_CSV' '\\[https-jsse-nio-8443-\\]'" \
        label       'the fixture carries the thread segment the removal is asserted against' \
        asserts     'Without -d thread, every message key carries the bracketed segment derived from the thread name.' \
        produced_by 'read_and_process_logs() in ltl (the thread-pool block and the message key assembly)' \
        contract    "$CONTRACT_DOC section Findings - Where each nameable part reaches the message today"
    assert_command \
        command     "grep -qE 'THREAD POOLS' '$RUN_OUT'" \
        label       'the thread-pool activity table renders without -d thread' \
        asserts     'The -tpas surface has rows to show on this fixture, so its absence under -d thread is the removal and not an empty input.' \
        produced_by 'calculate_all_statistics() in ltl (the thread-pool activity roll-up)' \
        contract    "$CONTRACT_DOC section Decisions D8"

    run_messages discard -tpas -xt -d thread "$THREAD_FIXTURE" || return 0
    assert_command \
        command     "check_no_key_matches '$MSG_CSV' '(\\[https-jsse|thread=)'" \
        label       'no key carries a thread segment or an appended thread' \
        asserts     'A discarded thread leaves no bracketed segment in any message key, and -x thread appends nothing, the value no longer existing.' \
        produced_by "$PRODUCED_FIELD" \
        contract    "$CONTRACT_DOC section Decisions D8 and D13"
    assert_command \
        command     "! grep -qE 'THREAD POOLS' '$RUN_OUT'" \
        label       'the thread-pool activity table is gone' \
        asserts     'Discard is never partial: with no thread captured, the thread-pool accumulators are empty and -tpas renders no thread-pool rows.' \
        produced_by "$PRODUCED_FIELD" \
        contract    "$CONTRACT_DOC section Decisions D8 - the thread-pool activity surfaces get no thread"
    assert_command \
        command     "check_one_notice '$RUN_ERR' 'thread.*both.*expose.*discard'" \
        label       'one notice names the thread as both exposed and discarded' \
        asserts     'A name given to both -x and -d is discarded, and a notice naming it prints on stderr, which --disable-progress does not suppress.' \
        produced_by "$PRECEDENCE" \
        contract    "$CONTRACT_DOC section Decisions D13"
}

# Criterion 5 (D9, D12, D13): the session and the user.
scenario_session_user() {
    current_scenario="session-user"
    echo "[$current_scenario]"

    run_messages plain "$USERS_FIXTURE" || return 0
    assert_command \
        command     "check_column_header '$RUN_OUT' 'sessions' present && check_column_header '$RUN_OUT' 'users' present" \
        label       'the sessions and users columns render without -d' \
        asserts     'The fixture carries sessions and users, so their absence under -d is the removal and not an empty input.' \
        produced_by 'calculate_all_statistics() in ltl (the sessions and users distinct counts)' \
        contract    "$CONTRACT_DOC section Decisions D12"

    run_messages discard -xs -xu -d session,user "$USERS_FIXTURE" || return 0
    assert_command \
        command     "check_column_header '$RUN_OUT' 'sessions' absent && check_column_header '$RUN_OUT' 'users' absent" \
        label       'the sessions and users columns are gone' \
        asserts     'Discarding a field leaves every count of it empty: with no session or user captured, neither distinct-count column is populated.' \
        produced_by "$PRODUCED_FIELD" \
        contract    "$CONTRACT_DOC section Decisions D12 - the built-in distinct counts are left empty"
    assert_command \
        command     "check_no_key_matches '$MSG_CSV' '(session=|user=)'" \
        label       'no key carries an appended session or user' \
        asserts     '-x session and -x user append nothing for a discarded field, the value no longer existing.' \
        produced_by "$PRODUCED_FIELD" \
        contract    "$CONTRACT_DOC section Decisions D13"
    assert_command \
        command     "check_one_notice '$RUN_ERR' 'session.*user.*both.*expose.*discard'" \
        label       'one notice names both values as exposed and discarded' \
        asserts     'The notice names every value given to both options, and prints once for the run.' \
        produced_by "$PRECEDENCE" \
        contract    "$CONTRACT_DOC section Decisions D13"
}

# Criterion 6 (D9): the object.
scenario_object() {
    current_scenario="object"
    echo "[$current_scenario]"

    run_messages plain "$OBJECT_FIXTURE" || return 0
    assert_command \
        command     "check_some_key_matches '$MSG_CSV' '\\] \\[[a-z]'" \
        label       'the fixture carries the object segment the removal is asserted against' \
        asserts     'Without -d object, message keys carry a bracketed object segment after the thread segment.' \
        produced_by 'read_and_process_logs() in ltl (the message key assembly)' \
        contract    "$CONTRACT_DOC section Findings - Where each nameable part reaches the message today"

    run_messages discard -d object "$OBJECT_FIXTURE" || return 0
    assert_command \
        command     "check_no_key_matches '$MSG_CSV' '\\[\\]'" \
        label       'no key carries an empty bracketed segment' \
        asserts     'A discarded object leaves nothing behind, not even the brackets it sat in: the key drops the segment rather than carrying an empty one.' \
        produced_by "$PRODUCED_FIELD" \
        contract    "$CONTRACT_DOC section Decisions D1 - neither the key, the value, nor a placeholder remains"
}

# Criterion 7 (D14): a built-in name resolves before a key written in the line.
scenario_builtin_precedence() {
    current_scenario="builtin-precedence"
    echo "[$current_scenario]"

    run_messages plain -xqs "$DOWNLOAD_FIXTURE" || return 0
    assert_command \
        command     "check_some_key_matches '$MSG_CSV' 'user=bob'" \
        label       'the fixture carries a user= key in the query string' \
        asserts     'One line carries the remote user alice and user=bob in its query string, so the precedence rule has both readings available to it.' \
        produced_by 'read_and_process_logs() in ltl (the message key assembly with the query string exposed)' \
        contract    "$CONTRACT_DOC section Decisions D14"
    assert_command \
        command     "check_column_header '$RUN_OUT' 'users' present" \
        label       'the users column renders without -d' \
        asserts     'The fixture carries a remote user, so the column absence under -d user is the removal and not an empty input.' \
        produced_by 'calculate_all_statistics() in ltl (the users distinct count)' \
        contract    "$CONTRACT_DOC section Decisions D12"

    run_messages discard -xqs -d user "$DOWNLOAD_FIXTURE" || return 0
    assert_command \
        command     "check_some_key_matches '$MSG_CSV' 'user=bob'" \
        label       'the query-string key survives -d user' \
        asserts     'The built-in name user names the parsed field, not a key of the same spelling written in the line, so user=bob is left as written.' \
        produced_by "$PRODUCED_RESOLVE" \
        contract    "$CONTRACT_DOC section Decisions D14 - a built-in name resolves before a key found in the line"
    assert_command \
        command     "check_column_header '$RUN_OUT' 'users' absent" \
        label       'the users column is gone' \
        asserts     'The parsed user field is cleared, so nothing counts it, while the query-string key of the same name keeps its place in the message.' \
        produced_by "$PRODUCED_FIELD" \
        contract    "$CONTRACT_DOC section Decisions D12 and D14"
}

# Criterion 8 (D5, D14): the metrics the omit options suppress.
scenario_metrics() {
    current_scenario="metrics"
    echo "[$current_scenario]"

    local -a pairs=( "duration -od" "bytes -ob" "count -oc" )
    local pair
    for pair in "${pairs[@]}"; do
        local name="${pair%% *}" omit="${pair##* }"
        run_messages "omit-$name" "$omit" "$METRICS_FIXTURE" || return 0
        local omit_msg="$MSG_CSV" omit_stats="$STATS_CSV"
        run_messages "discard-$name" -d "$name" "$METRICS_FIXTURE" || return 0
        assert_command \
            command     "check_same_csv '$omit_msg' '$MSG_CSV' 'messages'" \
            label       "-d $name produces the same messages as $omit" \
            asserts     "Naming a metric on --discard does what its omit option does: the metric is not read, so the message keys are the same either way." \
            produced_by "$PRODUCED_RESOLVE" \
            contract    "$CONTRACT_DOC section Decisions D5"
        assert_command \
            command     "check_same_csv '$omit_stats' '$STATS_CSV' 'statistics'" \
            label       "-d $name produces the same statistics as $omit" \
            asserts     "The metric is absent from the statistics under either spelling, so no column of it survives." \
            produced_by "$PRODUCED_RESOLVE" \
            contract    "$CONTRACT_DOC section Decisions D5"
    done

    # The three duration spellings are one name (D14).
    run_messages dur-plain -d duration "$METRICS_FIXTURE" || return 0
    local dur_msg="$MSG_CSV"
    local spelling
    for spelling in durationMs durationMS; do
        run_messages "dur-$spelling" -d "$spelling" "$METRICS_FIXTURE" || return 0
        assert_command \
            command     "check_same_csv '$dur_msg' '$MSG_CSV' 'messages'" \
            label       "-d $spelling is the same name as -d duration" \
            asserts     'The three duration spellings name one metric, so all three produce the same run.' \
            produced_by "$PRODUCED_RESOLVE" \
            contract    "$CONTRACT_DOC section Decisions D14 - the three spellings are one name"
    done
}

# Criterion 9 (D12): a user-defined metric whose own key is discarded.
scenario_udm_switched_off() {
    current_scenario="udm-switched-off"
    echo "[$current_scenario]"

    run_messages plain -xqs -udm sign::distinct -V udm-counting "$DOWNLOAD_FIXTURE" || return 0
    assert_command \
        command     "grep -qE '^counting_udms: 1\$' '$RUN_OUT'" \
        label       'the metric counts without -d' \
        asserts     'The fixture yields a counting metric on sign, so its absence under -d sign is the switch-off and not an empty input.' \
        produced_by 'parse_udm_configs() in ltl' \
        contract    "$CONTRACT_DOC section Acceptance criteria 9"

    run_messages discard -xqs -udm sign::distinct -d sign -V udm-counting "$DOWNLOAD_FIXTURE" || return 0
    assert_command \
        command     "grep -qE '^counting_udms: none\$' '$RUN_OUT'" \
        label       'the metric produces nothing' \
        asserts     'A metric whose own key is discarded is switched off when the options are resolved, so it reports no line rather than reporting zero, and the built-in and user-defined counts of the same value cannot disagree.' \
        produced_by "$PRECEDENCE" \
        contract    "$CONTRACT_DOC section Decisions D12"
    assert_command \
        command     "! grep -qE 'metric: sign' '$RUN_OUT'" \
        label       'no udm-counting line names the metric' \
        asserts     'The switched-off metric leaves no trace in the verbose surface.' \
        produced_by "$PRECEDENCE" \
        contract    "$CONTRACT_DOC section Decisions D12"
}

# Criterion 10 (D13, D15): the query string as a name.
scenario_query_string() {
    current_scenario="query-string"
    echo "[$current_scenario]"

    # A metric counting a key inside the query string reads the raw line, so
    # discarding the query string does not switch it off.
    run_messages metric-only -udm fileName::distinct -V udm-counting "$DOWNLOAD_FIXTURE" || return 0
    local metric_only="$RUN_OUT"
    run_messages metric-discard -d query-string -udm fileName::distinct -V udm-counting "$DOWNLOAD_FIXTURE" || return 0
    assert_command \
        command     "grep -qE '^counting_udms: 1\$' '$RUN_OUT' && grep -qE 'metric: fileName' '$RUN_OUT'" \
        label       'a metric counting a query-string key keeps counting' \
        asserts     'D12 switches off only a metric whose own key is discarded; a metric counting a key inside a discarded query string reads the raw line and is unaffected.' \
        produced_by "$PRECEDENCE" \
        contract    "$CONTRACT_DOC section Decisions D15"

    run_messages exposed -xqs -d query-string "$DOWNLOAD_FIXTURE" || return 0
    assert_command \
        command     "check_no_key_matches '$MSG_CSV' '[?]'" \
        label       'the query string is gone although -xqs asked for it' \
        asserts     'Discard wins over expose: naming the query string on both options removes it.' \
        produced_by "$PRODUCED_MESSAGE" \
        contract    "$CONTRACT_DOC section Decisions D15"
    assert_command \
        command     "check_one_notice '$RUN_ERR' 'query-string.*both.*expose.*discard'" \
        label       'one notice names the query string as both exposed and discarded' \
        asserts     'The D13 notice names the value and prints once for the run.' \
        produced_by "$PRECEDENCE" \
        contract    "$CONTRACT_DOC section Decisions D13 and D15"
}

# Criterion 12 (D17): an identifier given to both --mask and --discard.
scenario_masked_and_discarded() {
    current_scenario="masked-and-discarded"
    echo "[$current_scenario]"

    run_messages discard-only -d uuid "$DISCARD_FIXTURE" || return 0
    local discard_only="$MSG_CSV"

    local spelling
    for spelling in "-m uuid" "-uuid"; do
        local label="${spelling// /-}"
        # shellcheck disable=SC2086
        run_messages "both$label" $spelling -d uuid "$DISCARD_FIXTURE" || return 0
        assert_command \
            command     "check_same_csv '$discard_only' '$MSG_CSV' 'messages'" \
            label       "$spelling with -d uuid is identical to -d uuid alone" \
            asserts     'A value given to both masking and discarding is discarded: it is removed before the masks run, so no placeholder of its shape appears.' \
            produced_by "$PRECEDENCE" \
            contract    "$CONTRACT_DOC section Decisions D17"
        assert_command \
            command     "check_one_notice '$RUN_ERR' 'uuid.*both.*mask.*discard'" \
            label       "$spelling with -d uuid prints one notice naming the value" \
            asserts     'The notice names the value and prints on every run, the deprecated spelling included.' \
            produced_by "$PRECEDENCE" \
            contract    "$CONTRACT_DOC section Decisions D17"
    done

    run_messages mask-ip -m ip -d ip "$DISCARD_FIXTURE" || return 0
    assert_command \
        command     "check_no_key_matches '$MSG_CSV' '(###[.]###|####:####)'" \
        label       '-m ip -d ip leaves no address placeholder' \
        asserts     'The addresses are discarded rather than masked, so neither the address nor a placeholder of its shape is in the key.' \
        produced_by "$PRECEDENCE" \
        contract    "$CONTRACT_DOC section Decisions D17"
}

# Criterion 13 (D12): selection and highlighting read the raw line.
scenario_selection_unchanged() {
    current_scenario="selection-unchanged"
    echo "[$current_scenario]"

    run_messages included -i 'sign=Kf7a01xQ' -xqs "$DOWNLOAD_FIXTURE" || return 0
    local base_lines
    base_lines=$(grep -cE '^[^,]' "$MSG_CSV" || true)
    assert_command \
        command     "test '$base_lines' -gt 1" \
        label       'the include pattern selects lines without -d' \
        asserts     'The pattern names text the fixture carries, so the same selection under -d is a real comparison.' \
        produced_by 'read_and_process_logs() in ltl (the include filter, matched against the raw line)' \
        contract    "$CONTRACT_DOC section Decisions D12"

    run_messages discarded -i 'sign=Kf7a01xQ' -xqs -d sign "$DOWNLOAD_FIXTURE" || return 0
    local disc_lines
    disc_lines=$(grep -cE '^[^,]' "$MSG_CSV" || true)
    assert_command \
        command     "test '$base_lines' -eq '$disc_lines'" \
        label       'the same lines are selected with the named key discarded' \
        asserts     'An include pattern naming the text of a discarded key still selects the same lines: selection matches the raw line, before any removal.' \
        produced_by 'read_and_process_logs() in ltl (the include filter, matched against the raw line before the discard block)' \
        contract    "$CONTRACT_DOC section Decisions D12 - -include, -exclude and -highlight match the raw line"
    assert_command \
        command     "check_no_key_matches '$MSG_CSV' 'sign='" \
        label       'the selected lines carry no sign= in their keys' \
        asserts     'The key that selected the line is still removed from the message it produces.' \
        produced_by "$PRODUCED_MESSAGE" \
        contract    "$CONTRACT_DOC section Decisions D12"
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
# Scenario selector (tests/HARNESS-DESIGN.md section The scenario selector).
SCENARIO_USAGE_NOTE="  (acceptance criteria 1-13 of $CONTRACT_DOC):)"
scenario_register key-separators \
                  identifiers \
                  download-requests \
                  thread \
                  session-user \
                  object \
                  builtin-precedence \
                  metrics \
                  udm-switched-off \
                  query-string \
                  masked-and-discarded \
                  selection-unchanged
scenario_parse_args "$@"

echo "Validating message discard (-d/--discard), issue #567 acceptance criteria 1-13"
echo "  ltl:       $LTL"
echo ""

while read -r s; do
    case "$s" in
        key-separators)       scenario_key_separators ;;
        identifiers)          scenario_identifiers ;;
        download-requests)    scenario_download_requests ;;
        thread)               scenario_thread ;;
        session-user)         scenario_session_user ;;
        object)               scenario_object ;;
        builtin-precedence)   scenario_builtin_precedence ;;
        metrics)              scenario_metrics ;;
        udm-switched-off)     scenario_udm_switched_off ;;
        query-string)         scenario_query_string ;;
        masked-and-discarded) scenario_masked_and_discarded ;;
        selection-unchanged)  scenario_selection_unchanged ;;
    esac
    echo ""
done < <(scenario_selected)

echo "─────────────────────────────────────────"
echo "  Results: $pass passed, $fail failed  (scenarios: $(scenario_selected | paste -sd" " -))"
if [[ "$fail" -gt 0 ]]; then
    echo ""
    echo "  Failed assertions:"
    printf '    - %s\n' "${failures[@]}"
    exit 1
fi
echo "─────────────────────────────────────────"
exit 0
