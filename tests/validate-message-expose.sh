#!/usr/bin/env bash
# validate-message-expose.sh — named keys and values preserved in the message
# key (Issue #566, acceptance criteria 1-10).
#
# The feature: `-x <name>` / `--expose <name>` names a value the tool would
# otherwise remove from the message, and puts it back at the end of the key as
# ` name=value`, in command-line order. A built-in name (thread, session, user,
# query-string, a metric name or a -udm metric) names what the tool already
# extracts; any other name is a key found in the raw line by the same token rule
# the counting user-defined metrics use.
#
# This harness reads the MESSAGES CSV, which carries the message key verbatim,
# rather than the rendered table: the key is internal state the table only
# displays, and the CSV cuts it at 350 characters rather than at the terminal
# width, so no assertion here is a width assertion in disguise.
#
# Each assertion records, per tests/HARNESS-DESIGN.md § Self-documenting
# assertions:
#   - asserts:     the invariant being tested
#   - produced_by: where in ltl it is produced (function name, never a line)
#   - contract:    the source that makes the invariant stable
# All three are surfaced on failure, and every anchor that matches nothing is a
# hard failure (§ Harnesses must fail on missing anchors).
#
# Every expected key in this file is computed from the committed fixture text,
# never read back from ltl.
#
# Usage: ./tests/validate-message-expose.sh [--scenario NAME]
#        ./tests/validate-message-expose.sh --list

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

# Ambient FORCE_COLOR/NO_COLOR must not decide what this harness asserts against
# (HARNESS-DESIGN.md § Colour rendering is controlled, never inherited).
neutralize_colour_env

# Invocation shape (HARNESS-DESIGN.md § Invocation coherence): every assertion
# reads the message key out of the MESSAGES CSV or the classification counts out
# of one -V section. Neither depends on the time axis, so every run uses the
# coarsest bucket with empty buckets suppressed (-bs 1440 -oe) over fixtures
# spanning seconds; -n 100 is larger than the distinct-message count of every
# fixture, so no message row is dropped from the CSV (-n 0 would write no CSV at
# all); -ni keeps the developer's ltl-index.csv out of the run; -o writes the
# CSVs into a directory this harness created and owns.
DOWNLOAD_FIXTURE="$REPO_DIR/tests/fixtures/message-expose-download-requests.txt"
QS_FIXTURE="$REPO_DIR/tests/fixtures/udm-counting-query-string.txt"
THREAD_FIXTURE="$REPO_DIR/tests/fixtures/format-detection/access-thread-session.txt"
USERS_FIXTURE="$REPO_DIR/tests/fixtures/format-detection/access-users-sessions.txt"
METRICS_FIXTURE="$REPO_DIR/tests/fixtures/numeric-highlight-boundary.txt"

CONTRACT_DOC='features/566-preserve-named-values-in-message.md'
PRODUCED_APPEND='read_and_process_logs() in ltl (the expose append, applied to the formed message immediately before the message key is assembled)'
PRODUCED_RESOLVE='adapt_to_command_line_options() in ltl (the -x/--expose resolution into the ordered expose list)'

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"; exit 1
fi
for f in "$DOWNLOAD_FIXTURE" "$QS_FIXTURE" "$THREAD_FIXTURE" "$USERS_FIXTURE" "$METRICS_FIXTURE"; do
    if [[ ! -f "$f" ]]; then echo "ERROR: fixture not found: $f"; exit 1; fi
done

TMP_DIR=$(mktemp -d); trap 'rm -rf "$TMP_DIR"' EXIT

pass=0
fail=0
failures=()
current_scenario=""

# ---------------------------------------------------------------------------
# Assertion helpers
# ---------------------------------------------------------------------------

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

# Self-documenting assertion: a line matching `pattern` must be present in the
# named file.
assert_line() {
    local outfile="$1"; shift
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

    if [[ -s "$outfile" ]] && grep -qE "$pattern" "$outfile"; then
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

record_failure() {
    local what="$1"
    fail=$((fail + 1))
    failures+=("$current_scenario :: $what")
}

# ---------------------------------------------------------------------------
# Capture. Runs ltl in a directory this harness created, checks the exit code
# and the runtime-warning cleanliness of its stderr at the point of capture, and
# publishes the products it wrote through globals.
# ---------------------------------------------------------------------------
RUN_DIR=""; RUN_OUT=""; MSG_CSV=""; STATS_CSV=""
run_messages() {
    local label="$1"; shift
    RUN_DIR="$TMP_DIR/$current_scenario/$label"
    mkdir -p "$RUN_DIR"
    RUN_OUT="$RUN_DIR/run.out"; MSG_CSV=""; STATS_CSV=""
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
        echo "        contract:    $CONTRACT_DOC section Decisions D3 - -x/--expose and its aliases are accepted options"
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

# The MESSAGES CSV holds exactly the expected (occurrences, message key) pairs.
# The expected file carries one "<occurrences>TAB<message>" line per key; both
# sides are sorted before comparison, so the assertion does not depend on the
# ranking. An empty CSV, a missing header or a missing expectation file is a
# hard failure, never a pass.
check_messages() {
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
            push @got, sprintf("%s\t%s", $row->[2], $row->[1]);
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
            next if $short <= 0;
            push @missing, $k for 1 .. $short;
        }
        for my $k (sort keys %g) {
            my $over = $g{$k} - ($w{$k} // 0);
            next if $over <= 0;
            push @extra, $k for 1 .. $over;
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

# Two CSVs carry identical content. Used where a criterion states that two
# spellings of the same request must produce the same messages. Both files must
# exist and carry more than the header, so an empty-against-empty comparison
# cannot pass.
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

# The run-level classification counts of two runs agree, and match the counts
# the fixture's own status codes imply.
check_classification() {
    "$PERL" -e '
        my ($a, $b, $exp_succ, $exp_fail) = @ARGV;
        my $read = sub {
            my ($path) = @_;
            open my $fh, "<", $path or die "cannot open $path: $!\n";
            my ($in, %v);
            while (my $line = <$fh>) {
                $in = 1 if $line =~ /^=== format-detection \/ classification ===$/;
                last if $in && $line =~ /^=== END format-detection \/ classification ===$/;
                next unless $in;
                $v{$1} = $2 if $line =~ /^(lines_included|successes|failures|conflicts|unclassified):\s*(\d+)$/;
            }
            close $fh;
            return \%v;
        };
        my $va = $read->($a); my $vb = $read->($b);
        for my $pair ([$a, $va], [$b, $vb]) {
            unless (keys %{ $pair->[1] }) {
                print "anchor not found: no format-detection / classification counts in $pair->[0]\n";
                exit 1;
            }
        }
        my @diff = grep { ($va->{$_} // "-") ne ($vb->{$_} // "-") } sort keys %$va;
        if (@diff) {
            printf "classification counts differ on %s: %s\n", join(", ", @diff),
                join("; ", map { "$_ " . ($va->{$_} // "-") . " vs " . ($vb->{$_} // "-") } @diff);
            exit 1;
        }
        if ($va->{successes} != $exp_succ || $va->{failures} != $exp_fail) {
            printf "classification counts are %d successes / %d failures, the fixture implies %d / %d\n",
                $va->{successes}, $va->{failures}, $exp_succ, $exp_fail;
            exit 1;
        }
        printf "successes %d, failures %d, identical in both runs\n", $va->{successes}, $va->{failures};
        exit 0;
    ' "$1" "$2" "$3" "$4"
}

# Write an expectation file from the arguments, each "<occurrences>TAB<key>".
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
# tests/fixtures/message-expose-download-requests.txt — twelve Apache-style
# access lines binding access_common_duration (common plus a trailing duration;
# no thread, no session). Eleven are download requests against one fixed path,
# /app/servlet/ContentHttp/viewContent, distinguished only by their query
# string: fileName, adId, a per-request sign, sT and userid, with fileName and
# adId in swapped order on three of them. One download line carries no fileName,
# one carries remote user alice while its query string carries user=bob, and one
# line is an ordinary page request with no query string at all. Without -x the
# query string is stripped, so eleven of the twelve lines collapse onto three
# keys (one per status).
DL_BASE='[200] GET /app/servlet/ContentHttp/viewContent'
DL_404='[404] GET /app/servlet/ContentHttp/viewContent'
DL_500='[500] GET /app/servlet/ContentHttp/viewContent'
DL_PAGE='[200] GET /app/index.html'

# ---------------------------------------------------------------------------
# Scenarios
# ---------------------------------------------------------------------------

# Criterion 1: -x fileName on download requests.
scenario_download_filename() {
    current_scenario="download-filename"
    echo "[$current_scenario]"

    run_messages x-filename -x fileName "$DOWNLOAD_FIXTURE" || return 0
    local expected="$TMP_DIR/$current_scenario/expected.tsv"
    write_expected "$expected" \
        "$(printf '3\t%s fileName=alpha.pdf' "$DL_BASE")" \
        "$(printf '3\t%s fileName=beta.docx' "$DL_BASE")" \
        "$(printf '2\t%s fileName=gamma.zip' "$DL_BASE")" \
        "$(printf '1\t%s' "$DL_BASE")" \
        "$(printf '1\t%s' "$DL_PAGE")" \
        "$(printf '1\t%s fileName=delta.txt' "$DL_404")" \
        "$(printf '1\t%s fileName=gamma.zip' "$DL_500")" > /dev/null

    assert_command \
        command     "check_messages '$MSG_CSV' '$expected'" \
        label       'each download key ends fileName=<value>, one key per distinct file name and status' \
        asserts     'A key named on the command line and found in the raw line is appended to the end of the message as " name=value" once the message is formed, so the three distinct file names of the eleven download requests give three keys on the 200 status (3, 3 and 2 occurrences), one on 404 and one on 500. The fileName-less download line keeps the key it has without -x, and the page request, which carries no query string at all, is untouched.' \
        produced_by "$PRODUCED_APPEND" \
        contract    "$CONTRACT_DOC section D7 - a key found in the line is appended only when the formed message no longer yields its value; a line carrying no value for the key gets nothing"

    assert_command \
        command     "! grep -qE 'adId=|sign=|sT=|userid=|[?]&' '$MSG_CSV'" \
        label       'no other query-string parameter reaches the key' \
        asserts     'Naming one key exposes that key alone: the rest of the query string is still stripped, so no key carries adId, sign, sT or userid, and none carries the query string itself.' \
        produced_by "$PRODUCED_APPEND" \
        contract    "$CONTRACT_DOC section Requirements - Keys determined from the line itself: the key-value pairs of interest are concatenated onto the message key, without everything else the query string carries"
}

# Criterion 2: -xqs -x fileName is -xqs (loss, not presence).
scenario_query_string_loss() {
    current_scenario="query-string-loss"
    echo "[$current_scenario]"

    run_messages xqs-only -xqs "$DOWNLOAD_FIXTURE" || return 0
    local qs_csv="$MSG_CSV"
    run_messages xqs-filename -xqs -x fileName "$DOWNLOAD_FIXTURE" || return 0
    local both_csv="$MSG_CSV"

    assert_command \
        command     "check_same_csv '$qs_csv' '$both_csv' 'messages'" \
        label       '-xqs -x fileName gives the messages CSV of -xqs alone' \
        asserts     'The expose append is driven by loss, not by presence: with the query string kept, the formed message still yields fileName through the same token rule, so the key survived and nothing is appended. Adding -x fileName to -xqs must therefore change no key at all.' \
        produced_by "$PRODUCED_APPEND" \
        contract    "$CONTRACT_DOC section D7 - if the rule applied to the formed message yields the same value as on the raw line, nothing is added"
}

# Criterion 3: two keys, appended in command-line order whatever order the line
# carries them in.
scenario_multi_key_order() {
    current_scenario="multi-key-order"
    echo "[$current_scenario]"

    run_messages filename-adid -x fileName -x adId "$DOWNLOAD_FIXTURE" || return 0
    local forward_csv="$MSG_CSV"
    local expected="$TMP_DIR/$current_scenario/expected-forward.tsv"
    write_expected "$expected" \
        "$(printf '2\t%s fileName=alpha.pdf adId=5001' "$DL_BASE")" \
        "$(printf '3\t%s fileName=beta.docx adId=5002' "$DL_BASE")" \
        "$(printf '2\t%s fileName=gamma.zip adId=5003' "$DL_BASE")" \
        "$(printf '1\t%s fileName=alpha.pdf adId=5004' "$DL_BASE")" \
        "$(printf '1\t%s adId=5005' "$DL_BASE")" \
        "$(printf '1\t%s' "$DL_PAGE")" \
        "$(printf '1\t%s fileName=delta.txt adId=5006' "$DL_404")" \
        "$(printf '1\t%s fileName=gamma.zip adId=5007' "$DL_500")" > /dev/null

    assert_command \
        command     "check_messages '$forward_csv' '$expected'" \
        label       'keys end fileName=<f> adId=<a>, and the two lines that carry the pair in the opposite order share one key' \
        asserts     'Two exposed keys are appended in the order they were named on the command line, whatever order the producer wrote them in the line: the two requests for alpha.pdf/5001 (one with fileName first, one with adId first) form a single key, and the download line that carries no fileName is appended its adId alone.' \
        produced_by "$PRODUCED_APPEND" \
        contract    "$CONTRACT_DOC section D2 - several exposed keys are appended in command-line order, so the same combination of values gives the same message however the producer orders its parameters"

    run_messages adid-filename -x adId -x fileName "$DOWNLOAD_FIXTURE" || return 0
    local reverse_expected="$TMP_DIR/$current_scenario/expected-reverse.tsv"
    write_expected "$reverse_expected" \
        "$(printf '2\t%s adId=5001 fileName=alpha.pdf' "$DL_BASE")" \
        "$(printf '3\t%s adId=5002 fileName=beta.docx' "$DL_BASE")" \
        "$(printf '2\t%s adId=5003 fileName=gamma.zip' "$DL_BASE")" \
        "$(printf '1\t%s adId=5004 fileName=alpha.pdf' "$DL_BASE")" \
        "$(printf '1\t%s adId=5005' "$DL_BASE")" \
        "$(printf '1\t%s' "$DL_PAGE")" \
        "$(printf '1\t%s adId=5006 fileName=delta.txt' "$DL_404")" \
        "$(printf '1\t%s adId=5007 fileName=gamma.zip' "$DL_500")" > /dev/null

    assert_command \
        command     "check_messages '$MSG_CSV' '$reverse_expected'" \
        label       '-x adId -x fileName ends adId=<a> fileName=<f>' \
        asserts     'The order of the option occurrences is the order of the appended pairs: naming adId first puts adId first on every key, and the grouping is unchanged because the same values are appended.' \
        produced_by "$PRODUCED_APPEND" \
        contract    "$CONTRACT_DOC section D2 - command-line order"
}

# Criterion 4: the exposed value is read by the rule the counting user-defined
# metrics use, over the fixture the counting metrics are pinned on.
scenario_counted_keys() {
    current_scenario="counted-keys"
    echo "[$current_scenario]"

    # The six requests share one path and thread pool; the query string carries
    # folderId (100 x3, 200 x3), userid (42 on every line), fileName (aaa, bbb,
    # ccc twice each), path (a%2Fb x3, a%2Fc x3), kind (cad|part x3, cad|asm
    # x3), file%5Fid (7, 7, 8, 8, 9, 9), a per-request sign and site (host1 x3,
    # host2 x3). ref=ABC sits in the path, before the query string.
    local base='[200] [pool-exec] GET /dl/item;ref=ABC'

    run_messages x-filename -x fileName "$QS_FIXTURE" || return 0
    local expected="$TMP_DIR/$current_scenario/expected-filename.tsv"
    write_expected "$expected" \
        "$(printf '2\t%s fileName=aaa' "$base")" \
        "$(printf '2\t%s fileName=bbb' "$base")" \
        "$(printf '2\t%s fileName=ccc' "$base")" > /dev/null
    assert_command \
        command     "check_messages '$MSG_CSV' '$expected'" \
        label       '-x fileName appends the three distinct file names the counting rule reads' \
        asserts     'The exposed value is read by the same rule -udm fileName::distinct reads: the value ends at the & before the next parameter, so three file names appear over six requests, two occurrences each.' \
        produced_by 'the shared counting token-pattern builder in ltl, called by parse_udm_configs() and by the expose resolution' \
        contract    "$CONTRACT_DOC section D1 - one resolution surface: --expose <key> and -udm <key>::distinct read the same value from a line"

    run_messages x-kind -x kind "$QS_FIXTURE" || return 0
    local expected_kind="$TMP_DIR/$current_scenario/expected-kind.tsv"
    write_expected "$expected_kind" \
        "$(printf '3\t%s kind=cad|part' "$base")" \
        "$(printf '3\t%s kind=cad|asm' "$base")" > /dev/null
    assert_command \
        command     "check_messages '$MSG_CSV' '$expected_kind'" \
        label       'a pipe does not end an exposed value: kind=cad|part is appended whole' \
        asserts     'The separators that end an exposed value are those of the counting token rule: whitespace, comma, semicolon, quote, bracket, parenthesis, ampersand and question mark. A pipe is not one of them, so cad|part is one value and the six requests form two keys.' \
        produced_by 'the shared counting token-pattern builder in ltl, called by parse_udm_configs() and by the expose resolution' \
        contract    "$CONTRACT_DOC section D1 - the rule is features/user-defined-metrics.md section Query-string separators end a counted value"

    run_messages x-escaped-key -x 'file%5Fid' "$QS_FIXTURE" || return 0
    local expected_fid="$TMP_DIR/$current_scenario/expected-fid.tsv"
    write_expected "$expected_fid" \
        "$(printf '2\t%s file%%5Fid=7' "$base")" \
        "$(printf '2\t%s file%%5Fid=8' "$base")" \
        "$(printf '2\t%s file%%5Fid=9' "$base")" > /dev/null
    assert_command \
        command     "check_messages '$MSG_CSV' '$expected_fid'" \
        label       'a key written with a percent escape is matched literally: file%5Fid gives three values' \
        asserts     'The key is matched as written, quoted for the pattern, so a percent-escaped key in the query string is found and its three values (7, 8, 9) are appended.' \
        produced_by 'the shared counting token-pattern builder in ltl, called by parse_udm_configs() and by the expose resolution' \
        contract    "$CONTRACT_DOC section D1 - the exposed key is read by the counting metrics' token rule, key quoted"

    run_messages x-userid -x userid "$QS_FIXTURE" || return 0
    local expected_userid="$TMP_DIR/$current_scenario/expected-userid.tsv"
    write_expected "$expected_userid" \
        "$(printf '6\t%s userid=42' "$base")" > /dev/null
    assert_command \
        command     "check_messages '$MSG_CSV' '$expected_userid'" \
        label       'a constant parameter appends one value and leaves one key' \
        asserts     'userid carries one value on all six requests, so the six lines still form one key with the value appended. The key is read as written: userid is not the built-in user name, and the built-in user resolution does not claim it.' \
        produced_by "$PRODUCED_RESOLVE" \
        contract    "$CONTRACT_DOC section D6 - a built-in name resolves before a key found in the line; any other name is a key found in the line"

    run_messages x-ref -x ref "$QS_FIXTURE" || return 0
    local expected_ref="$TMP_DIR/$current_scenario/expected-ref.tsv"
    write_expected "$expected_ref" \
        "$(printf '6\t%s' "$base")" > /dev/null
    assert_command \
        command     "check_messages '$MSG_CSV' '$expected_ref'" \
        label       'a key that survived into the formed message is not appended' \
        asserts     'ref=ABC sits in the path, before the question mark, so it survives the query-string strip. The rule applied to the formed message yields the same ABC as the raw line, so nothing is appended and the key is the one the run produces without -x.' \
        produced_by "$PRODUCED_APPEND" \
        contract    "$CONTRACT_DOC section D7 - appended only when the formed message no longer yields the value"
}

# Criterion 5: the built-in user beats a user= in the query string.
scenario_builtin_user_precedence() {
    current_scenario="builtin-user-precedence"
    echo "[$current_scenario]"

    run_messages x-user -x user "$DOWNLOAD_FIXTURE" || return 0
    local expected="$TMP_DIR/$current_scenario/expected.tsv"
    write_expected "$expected" \
        "$(printf '8\t%s' "$DL_BASE")" \
        "$(printf '1\t%s user=alice' "$DL_BASE")" \
        "$(printf '1\t%s' "$DL_PAGE")" \
        "$(printf '1\t%s' "$DL_404")" \
        "$(printf '1\t%s' "$DL_500")" > /dev/null

    assert_command \
        command     "check_messages '$MSG_CSV' '$expected'" \
        label       'the line carrying remote user alice and user=bob in its query string ends user=alice' \
        asserts     'user is a built-in name: it resolves to the user field the format extracts, not to a user= key found in the line. The one line whose remote-user field is alice and whose query string carries user=bob therefore ends " user=alice"; the eleven lines whose remote user is a bare - get nothing appended.' \
        produced_by "$PRODUCED_RESOLVE" \
        contract    "$CONTRACT_DOC section D6 - -x user on a line carrying both a user field and user=bob in its query string exposes the user field"

    assert_command \
        command     "! grep -q 'user=bob' '$MSG_CSV'" \
        label       'no key carries the query string user=bob' \
        asserts     'The built-in resolution must not fall through to the line: user=bob is in the raw line of that request, and it must reach no key.' \
        produced_by "$PRODUCED_RESOLVE" \
        contract    "$CONTRACT_DOC section D6 - a built-in name resolves before a key found in the line"
}

# Criterion 6: -xt and -x thread on the thread-and-session shape.
scenario_thread() {
    current_scenario="thread"
    echo "[$current_scenario]"

    # The committed fixture carries a populated thread on every line and a
    # literal null on the last. The first three lines are rewritten to a bare -
    # here, the way the format-detection harness stages the same file, so the
    # absent-thread case is covered on the same run.
    local staged="$TMP_DIR/$current_scenario/localhost_access_log.2025-05-05.txt"
    mkdir -p "$(dirname "$staged")"
    "$PERL" -pe 's/ \S+ (\S+)$/ - $1/ if $. <= 3' "$THREAD_FIXTURE" > "$staged"
    if [[ ! -s "$staged" ]]; then
        echo "  FAIL  $current_scenario :: staging produced no file"; record_failure "staging"; return 0
    fi

    local pool='[https-jsse-nio-8443-]'
    local t1='https-jsse-nio-8443-exec-1' t2='https-jsse-nio-8443-exec-2' t3='https-jsse-nio-8443-exec-3'
    local expected="$TMP_DIR/$current_scenario/expected.tsv"
    write_expected "$expected" \
        "$(printf '1\t[503] POST /store/catalog')" \
        "$(printf '1\t[200] POST /store/item/42')" \
        "$(printf '1\t[200] POST /store/cart')" \
        "$(printf '1\t[200] %s POST /store/checkout thread=%s' "$pool" "$t1")" \
        "$(printf '1\t[200] %s POST /store/search thread=%s' "$pool" "$t2")" \
        "$(printf '1\t[200] %s POST /store/login thread=%s' "$pool" "$t3")" \
        "$(printf '1\t[503] %s POST /store/logout thread=%s' "$pool" "$t1")" \
        "$(printf '1\t[200] %s POST /store/images/logo.png thread=%s' "$pool" "$t2")" \
        "$(printf '1\t[200] %s POST /store/api/orders thread=%s' "$pool" "$t3")" \
        "$(printf '1\t[200] %s POST /store/api/stock thread=%s' "$pool" "$t1")" \
        "$(printf '1\t[200] %s POST /store/help thread=%s' "$pool" "$t2")" \
        "$(printf '1\t[200] [null] POST /store/account thread=null')" > /dev/null

    run_messages x-thread -x thread "$staged" || return 0
    local long_csv="$MSG_CSV"
    assert_command \
        command     "check_messages '$long_csv' '$expected'" \
        label       'each key ends thread=<full thread name>, the bracketed segment is unchanged, a - thread adds nothing and null gives thread=null' \
        asserts     'An exposed thread is appended whole: the eight lines carrying a worker thread end " thread=https-jsse-nio-8443-exec-N" while their bracketed segment stays the pool name cut to twenty characters, the three lines whose thread field is a bare - get neither a bracketed segment nor an append, and the literal null thread gives " thread=null".' \
        produced_by "$PRODUCED_APPEND" \
        contract    "$CONTRACT_DOC section D4 - the full, unique thread name is visible rather than the segment cut to 20 characters"

    assert_command \
        command     "grep -cE 'thread=https-jsse-nio-8443-exec-[123]\"' '$long_csv' | grep -qx 8 && [ \$(grep -oE 'thread=[^\"]+' '$long_csv' | sort -u | wc -l | tr -d ' ') = 4 ]" \
        label       'the appended thread values are the four distinct threads of the file' \
        asserts     'Eight of the twelve lines carry one of three worker threads and one carries the literal null, so the keys carry exactly four distinct appended thread values; the three bare-dash lines contribute none.' \
        produced_by "$PRODUCED_APPEND" \
        contract    "$CONTRACT_DOC section D4 - one message per distinct thread once the thread is exposed"

    run_messages xt-alias -xt "$staged" || return 0
    assert_command \
        command     "check_same_csv '$long_csv' '$MSG_CSV' 'messages'" \
        label       '-xt gives the messages CSV of -x thread' \
        asserts     '-xt is an alias of -x thread, not a second mechanism: the two spellings produce the same messages CSV.' \
        produced_by "$PRODUCED_RESOLVE" \
        contract    "$CONTRACT_DOC section D3 - one option names anything to expose; the existing options are its aliases, and the thread gains one"
}

# Criterion 7: session and user are appended, not prepended.
scenario_session_user() {
    current_scenario="session-user"
    echo "[$current_scenario]"

    # The fixture carries three users (alice, bob, carol), a bare - on three
    # lines, and three session ids across twelve lines, all on one thread pool.
    local pool='[https-jsse-nio-8443-]'
    local expected="$TMP_DIR/$current_scenario/expected.tsv"
    write_expected "$expected" \
        "$(printf '1\t[200] %s POST /store/catalog user=alice session=S0000AB12CD34EF' "$pool")" \
        "$(printf '1\t[200] %s POST /store/item/42 user=bob session=S0001AB12CD34EF' "$pool")" \
        "$(printf '1\t[200] %s POST /store/cart user=carol session=S0002AB12CD34EF' "$pool")" \
        "$(printf '1\t[200] %s POST /store/checkout session=S0000AB12CD34EF' "$pool")" \
        "$(printf '1\t[200] %s POST /store/search user=alice session=S0001AB12CD34EF' "$pool")" \
        "$(printf '1\t[200] %s POST /store/login user=bob session=S0002AB12CD34EF' "$pool")" \
        "$(printf '1\t[200] %s POST /store/logout user=carol session=S0000AB12CD34EF' "$pool")" \
        "$(printf '1\t[200] %s POST /store/images/logo.png session=S0001AB12CD34EF' "$pool")" \
        "$(printf '1\t[200] %s POST /store/api/orders user=alice session=S0002AB12CD34EF' "$pool")" \
        "$(printf '1\t[200] %s POST /store/api/stock user=bob session=S0000AB12CD34EF' "$pool")" \
        "$(printf '1\t[200] %s POST /store/help user=carol session=S0001AB12CD34EF' "$pool")" \
        "$(printf '1\t[200] %s POST /store/account session=S0002AB12CD34EF' "$pool")" > /dev/null

    run_messages user-session -x user -x session "$USERS_FIXTURE" || return 0
    assert_command \
        command     "check_messages '$MSG_CSV' '$expected'" \
        label       'keys end user=<value> session=<value>, in that order, with no bracketed value at the front' \
        asserts     'An exposed session and user are appended at the end of the message in command-line order, in place of the bracketed value they used to place at the front: nine lines carry a user and all twelve a session, and the three lines whose user field is a bare - are appended their session alone.' \
        produced_by "$PRODUCED_APPEND" \
        contract    "$CONTRACT_DOC section D5 - session and user are appended the same way, in place of the bracketed value at the front of the message"

    assert_command \
        command     "! grep -qE '\\[(alice|bob|carol|S000[0-9]AB12CD34EF)\\]' '$MSG_CSV'" \
        label       'no key carries a bracketed user or session at the front of the message' \
        asserts     'The prepended bracketed value is gone: no key carries [alice], [bob], [carol] or a bracketed session id anywhere.' \
        produced_by "$PRODUCED_APPEND" \
        contract    "$CONTRACT_DOC section D5 - every exposed value reads the same way, appended and machine readable"

    run_messages xu-xs-aliases -xu -xs "$USERS_FIXTURE" || return 0
    assert_command \
        command     "check_messages '$MSG_CSV' '$expected'" \
        label       '-xu -xs gives what -x user -x session gives' \
        asserts     '-xu and -xs are aliases feeding the same ordered list, so -xu -xs appends user then session exactly as -x user -x session does.' \
        produced_by "$PRODUCED_RESOLVE" \
        contract    "$CONTRACT_DOC section D3 - the existing options are aliases of -x"

    local reverse="$TMP_DIR/$current_scenario/expected-reverse.tsv"
    "$PERL" -pe 's/ user=(\S+) session=(\S+)$/ session=$2 user=$1/' "$TMP_DIR/$current_scenario/expected.tsv" > "$reverse"
    run_messages session-user -x session -x user "$USERS_FIXTURE" || return 0
    assert_command \
        command     "check_messages '$MSG_CSV' '$reverse'" \
        label       '-x session -x user appends session first' \
        asserts     'Session and user take their place in the same command-line order sequence as any other exposed name, so naming session first puts session first on every key.' \
        produced_by "$PRODUCED_APPEND" \
        contract    "$CONTRACT_DOC section D2 - command-line order, and D5"

    # An empty value adds nothing: the ThingWorx standard lines carry an empty
    # session field, [S: ], on every line.
    run_messages empty-session -x session "$METRICS_FIXTURE" || return 0
    assert_command \
        command     "! grep -q 'session=' '$MSG_CSV'" \
        label       'an empty session field appends nothing' \
        asserts     'An exposed session is appended only when the value is defined, not empty and not a bare -: on lines whose session field is empty no key carries session= at all.' \
        produced_by "$PRODUCED_APPEND" \
        contract    "$CONTRACT_DOC section D5 - an empty or absent value adds nothing"
}

# Criterion 8: a named metric keeps its number in place of the mask.
scenario_metric_names() {
    current_scenario="metric-names"
    echo "[$current_scenario]"

    # The fixture is nineteen ThingWorx standard lines on one thread and object,
    # each carrying durationMS, bytes and count except one line per metric that
    # omits it. Without -x all three read ?; the message is
    #   [INFO] [pool-a] [BoundaryFixture] BD-<case> executed durationMS=? bytes=? count=?
    local prefix='[INFO] [pool-a] [BoundaryFixture]'

    run_messages plain "$METRICS_FIXTURE" || return 0
    local plain_stats="$STATS_CSV"

    run_messages x-durationms -x durationMS "$METRICS_FIXTURE" || return 0
    local dur_csv="$MSG_CSV" dur_stats="$STATS_CSV"

    assert_command \
        command     "grep -qF '\"$prefix BD-dur-inside executed durationMS=150 bytes=? count=?\"' '$dur_csv'" \
        label       'the line carrying durationMS=150 reads durationMS=150 while bytes and count still read ?' \
        asserts     'A named metric keeps its number in place instead of the mask: with -x durationMS the message reads durationMS=150 on the line that carries 150.' \
        produced_by 'compile_format_scan_sub() in ltl (the entry message_metrics mask, built from the format spec per the run options)' \
        contract    "$CONTRACT_DOC section D7 - a named metric keeps its number in place instead of ?, and is not appended"

    assert_command \
        command     "grep -q 'durationMS=99 ' '$dur_csv' && grep -q 'durationMS=201 ' '$dur_csv' && ! grep -q 'durationMS=?' '$dur_csv'" \
        label       'every durationMS value stays in place and none reads ?' \
        asserts     'The mask is conditional on the exposed names, not removed for one line: every line that carries durationMS keeps its own number, and no message still reads durationMS=?.' \
        produced_by 'compile_format_scan_sub() in ltl (the entry message_metrics mask, built from the format spec per the run options)' \
        contract    "$CONTRACT_DOC section Requirements - Metric values: naming the metric makes the replacement conditional"

    assert_command \
        command     "grep -q 'bytes=?' '$dur_csv' && grep -q 'count=?' '$dur_csv' && ! grep -qE 'bytes=[0-9]' '$dur_csv' && ! grep -qE 'count=[0-9]' '$dur_csv'" \
        label       'the metrics not named still read ?' \
        asserts     'Exposing one metric exposes that metric alone: with -x durationMS the bytes and count values are still masked in every message.' \
        produced_by 'compile_format_scan_sub() in ltl (the entry message_metrics mask) and read_and_process_logs() in ltl (the count mask)' \
        contract    "$CONTRACT_DOC section D7 - only the named metric keeps its number"

    assert_command \
        command     "check_same_csv '$plain_stats' '$dur_stats' 'statistics'" \
        label       'the metric values captured are unchanged by -x' \
        asserts     'Exposing a metric changes what the message reads, never what the run measures: the STATS CSV of the -x run is identical to the run without it.' \
        produced_by 'read_and_process_logs() in ltl (metric capture, upstream of the message mask)' \
        contract    "$CONTRACT_DOC section Requirements - Metric values: in each case the value is still captured as the metric; only the message text loses it"

    run_messages x-durationms-lower -x durationMs "$METRICS_FIXTURE" || return 0
    local lower_csv="$MSG_CSV"
    assert_command \
        command     "check_same_csv '$dur_csv' '$lower_csv' 'messages'" \
        label       '-x durationMs is -x durationMS' \
        asserts     'The metric can be named by either spelling of the key as written in the file: durationMs and durationMS name the same metric and give the same messages.' \
        produced_by "$PRODUCED_RESOLVE" \
        contract    "$CONTRACT_DOC section Requirements - Naming: the analyst can name either the internal metric name or the key as written"

    run_messages x-duration -x duration "$METRICS_FIXTURE" || return 0
    assert_command \
        command     "check_same_csv '$dur_csv' '$MSG_CSV' 'messages'" \
        label       '-x duration is -x durationMS' \
        asserts     'The internal metric name names the same thing as the key as written: -x duration gives the messages -x durationMS gives.' \
        produced_by "$PRODUCED_RESOLVE" \
        contract    "$CONTRACT_DOC section D6 - the metric names and their keys as written name the value the tool already extracts"

    run_messages x-bytes -x bytes "$METRICS_FIXTURE" || return 0
    assert_command \
        command     "grep -q 'bytes=1000 ' '$MSG_CSV' && grep -q 'bytes=6001 ' '$MSG_CSV' && ! grep -q 'bytes=?' '$MSG_CSV' && grep -q 'durationMS=?' '$MSG_CSV' && grep -q 'count=?' '$MSG_CSV'" \
        label       '-x bytes keeps every bytes value and leaves durationMS and count masked' \
        asserts     'bytes is a built-in metric name: naming it excludes that key from the mask the format spec declares, and leaves the other masked key and the count mask untouched.' \
        produced_by 'compile_format_scan_sub() in ltl (the entry message_metrics mask, built from the format spec per the run options)' \
        contract    "$CONTRACT_DOC section D7 - a named metric keeps its number in place"

    run_messages x-count -x count "$METRICS_FIXTURE" || return 0
    assert_command \
        command     "grep -q 'count=10' '$MSG_CSV' && grep -q 'count=51' '$MSG_CSV' && ! grep -q 'count=?' '$MSG_CSV' && grep -q 'durationMS=?' '$MSG_CSV' && grep -q 'bytes=?' '$MSG_CSV'" \
        label       '-x count keeps every count value and leaves durationMS and bytes masked' \
        asserts     'The count mask is applied to every format, not by the format spec, and naming count skips it: the counts stay in place while the two spec-masked metrics still read ?.' \
        produced_by 'read_and_process_logs() in ltl (the count capture mask)' \
        contract    "$CONTRACT_DOC section D7 - count is one of the metric names -x accepts"

    # A user-defined metric masks its own matched value in the message. Naming
    # the metric skips that mask. The metric here reads the case name at the
    # head of each fixture message, which is text the message itself carries.
    run_messages udm-masked -udm 'case::distinct:/(BD-[a-z]+)-/' "$METRICS_FIXTURE" || return 0
    assert_command \
        command     "grep -q '\\[BoundaryFixture\\] ?-inside executed' '$MSG_CSV' && ! grep -q 'BD-dur-inside' '$MSG_CSV'" \
        label       'without -x the user-defined metric masks its matched value in the message' \
        asserts     'A -udm metric replaces the value it matched with ? in the message; this is the mask -x must be able to skip, and it fires here without -x.' \
        produced_by 'read_and_process_logs() in ltl (the user-defined-metric matched-value mask)' \
        contract    "$CONTRACT_DOC section D7 - a named metric (a -udm metric among them) keeps its value in place"

    run_messages udm-exposed -udm 'case::distinct:/(BD-[a-z]+)-/' -x case "$METRICS_FIXTURE" || return 0
    assert_command \
        command     "grep -q 'BD-dur-inside executed' '$MSG_CSV' && grep -q 'BD-count-above executed' '$MSG_CSV' && ! grep -q '?-inside' '$MSG_CSV'" \
        label       '-x <udm metric name> skips that metric value mask' \
        asserts     'Naming a user-defined metric keeps its value in the message instead of the ? the metric would otherwise leave, and appends nothing, exactly as for a built-in metric.' \
        produced_by 'read_and_process_logs() in ltl (the user-defined-metric matched-value mask, gated on the exposed names)' \
        contract    "$CONTRACT_DOC section D6 - any -udm metric name names the value the tool already extracts; D7 - a named metric is not appended"
}

# Criterion 9: -x query-string is -xqs.
scenario_query_string_alias() {
    current_scenario="query-string-alias"
    echo "[$current_scenario]"

    run_messages xqs -xqs "$DOWNLOAD_FIXTURE" || return 0
    local short_csv="$MSG_CSV"
    run_messages x-query-string -x query-string "$DOWNLOAD_FIXTURE" || return 0

    assert_command \
        command     "check_same_csv '$short_csv' '$MSG_CSV' 'messages'" \
        label       '-x query-string gives the messages CSV of -xqs' \
        asserts     'query-string is the built-in name of the query string, and -xqs is its alias: the two spellings keep the query string in the key identically, and neither appends anything.' \
        produced_by "$PRODUCED_RESOLVE" \
        contract    "$CONTRACT_DOC section D6 - the query string is named query-string and -xqs is the alias of -x query-string"

    assert_command \
        command     "grep -q 'viewContent?fileName=alpha.pdf&adId=5001&sign=Kf7a01xQ&sT=1600&userid=u101\"' '$MSG_CSV'" \
        label       'the exposed query string is the line query string, nothing appended' \
        asserts     'Exposing the query string keeps what the line carries and appends nothing after it, so the key ends with the last query-string parameter of the request.' \
        produced_by "$PRODUCED_APPEND" \
        contract    "$CONTRACT_DOC section D6 - query-string keeps the query string; nothing is appended"
}

# Criterion 10: classification counts are untouched by any -x combination.
scenario_classification_unchanged() {
    current_scenario="classification-unchanged"
    echo "[$current_scenario]"

    # Ten of the twelve download lines carry a 2xx status (successes), one a 404
    # and one a 500 (failures).
    run_messages plain -V format-detection "$DOWNLOAD_FIXTURE" || return 0
    local plain_out="$RUN_OUT"

    local combo
    for combo in "-x fileName" "-x fileName -x adId" "-xqs -x fileName -xu" "-x user"; do
        local label="combo${combo// /-}"
        # shellcheck disable=SC2086
        run_messages "$label" $combo -V format-detection "$DOWNLOAD_FIXTURE" || continue
        assert_command \
            command     "check_classification '$plain_out' '$RUN_OUT' 10 2" \
            label       "classification counts under $combo are the counts of the run without -x" \
            asserts     'Exposing a value changes the message key alone: the run-level success, failure, conflict and unclassified counts are what the fixture status codes imply (ten 2xx successes, one 404 and one 500 failure) and are identical with and without -x.' \
            produced_by 'the generated classification block from format_classification_src(), counted in read_and_process_logs() and emitted by emit_format_detection_verbose() in ltl' \
            contract    "$CONTRACT_DOC section Acceptance criteria 10 - success/failure classification counts identical to the run without -x"
    done
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------

SCENARIOS=(download-filename query-string-loss multi-key-order counted-keys
           builtin-user-precedence thread session-user metric-names
           query-string-alias classification-unchanged)

usage() {
    echo "Usage: $0 [--scenario NAME] [--list]"
    echo "Scenarios (acceptance criteria 1-10 of $CONTRACT_DOC):"
    printf '  %s\n' "${SCENARIOS[@]}"
}

selected=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --scenario) selected="${2:-}"; shift 2 ;;
        --list)     usage; exit 0 ;;
        -h|--help)  usage; exit 0 ;;
        *) echo "ERROR: unknown argument '$1'"; usage; exit 2 ;;
    esac
done

if [[ -n "$selected" ]]; then
    found=0
    for s in "${SCENARIOS[@]}"; do [[ "$s" == "$selected" ]] && found=1; done
    if [[ "$found" -ne 1 ]]; then
        echo "ERROR: unknown scenario '$selected'"
        usage
        exit 2
    fi
    SCENARIOS=("$selected")
fi

echo "Validating message expose (-x/--expose), issue #566 acceptance criteria 1-10"
echo "  ltl:       $LTL"
echo ""

for s in "${SCENARIOS[@]}"; do
    case "$s" in
        download-filename)        scenario_download_filename ;;
        query-string-loss)        scenario_query_string_loss ;;
        multi-key-order)          scenario_multi_key_order ;;
        counted-keys)             scenario_counted_keys ;;
        builtin-user-precedence)  scenario_builtin_user_precedence ;;
        thread)                   scenario_thread ;;
        session-user)             scenario_session_user ;;
        metric-names)             scenario_metric_names ;;
        query-string-alias)       scenario_query_string_alias ;;
        classification-unchanged) scenario_classification_unchanged ;;
    esac
    echo ""
done

echo "─────────────────────────────────────────"
echo "  Results: $pass passed, $fail failed  (scenarios: ${SCENARIOS[*]})"
if [[ "$fail" -gt 0 ]]; then
    echo ""
    echo "  Failed assertions:"
    printf '    - %s\n' "${failures[@]}"
    exit 1
fi
echo "─────────────────────────────────────────"
exit 0
