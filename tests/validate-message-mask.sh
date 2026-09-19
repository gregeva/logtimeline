#!/usr/bin/env bash
# validate-message-mask.sh — identifiers replaced in the message key by a
# placeholder of their shape (Issue #580, acceptance criteria 1-10 and 12).
#
# The feature: `-m <name>` / `--mask <name>` names an identifier class whose
# every occurrence in the message is replaced by a fixed placeholder of the same
# shape, so that messages differing only by that identifier become one key that
# still shows where the identifier sat. `uuid` masks hexadecimal UUIDs, `ipv4`
# and `ipv6` mask valid addresses of that version, `ip` both. `-uuid` is the
# deprecated spelling of `-m uuid` and prints a notice.
#
# This harness reads the MESSAGES CSV, which carries the message key verbatim
# (cut at 350 characters), rather than the rendered table. Corpus scenarios use
# the logs the feature doc's findings were measured on, isolated with -i to the
# lines that carry the identifier; the synthetic fixture carries only what the
# corpus lacks (IPv6 addresses, invalid IPv4 outlines, lines differing by one
# identifier).
#
# Each assertion records, per tests/HARNESS-DESIGN.md § Self-documenting
# assertions:
#   - asserts:     the invariant being tested
#   - produced_by: where in ltl it is produced (function name, never a line)
#   - contract:    the source that makes the invariant stable
# All three are surfaced on failure, and every anchor that matches nothing is a
# hard failure (§ Harnesses must fail on missing anchors).
#
# Every expected key in this file is computed from the committed fixture text or
# from a figure measured and recorded in the feature doc, never read back from
# ltl.
#
# Usage: ./tests/validate-message-mask.sh [--scenario NAME]
#        ./tests/validate-message-mask.sh --list

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

LTL="$REPO_DIR/ltl"
PERL="${PERL:-/opt/homebrew/bin/perl}"
command -v "$PERL" >/dev/null 2>&1 || PERL=perl

# shellcheck source=lib/logs-dir.sh
source "$SCRIPT_DIR/lib/logs-dir.sh"
# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"

# Ambient FORCE_COLOR/NO_COLOR must not decide what this harness asserts against
# (HARNESS-DESIGN.md § Colour rendering is controlled, never inherited).
neutralize_colour_env

# Invocation shape (HARNESS-DESIGN.md § Invocation coherence): every assertion
# reads the message key out of the MESSAGES CSV, the classification counts out
# of one -V section, or a stderr diagnostic. None depends on the time axis, so
# every run uses the coarsest bucket with empty buckets suppressed (-bs 1440
# -oe); -n 100000 exceeds the distinct-message count of every input, so no key
# is dropped from the CSV; -ni keeps the developer's ltl-index.csv out of the
# run; -o writes the CSVs into a directory this harness created and owns; -i
# isolates the corpus lines that carry the identifier under test.
FIXTURE="$REPO_DIR/tests/fixtures/message-mask-values.txt"

# Corpus inputs (docs/test-logs.md): the ThingWorx application log of hundreds
# of thousands of error messages differing by a UUID; one day of the thirty-day
# Tomcat access logs, whose file-repository gateway paths carry UUID-shaped
# names that are not UUIDs; a Windchill method server log whose request-monitor
# lines carry the client address; the smallest complete WGM client log, whose
# version lines carry dotted version numbers of four and five parts.
TWX_LOG="$(resolve_log_path 'logs/ThingworxLogs/HundredsOfThousandsOfUniqueErrors.log')"
ACC_LOG="$(resolve_log_path 'logs/AccessLogs/really-big/localhost_access_log-twx01-twx-thingworx-2.2025-12-31.txt')"
MS_LOG="$(resolve_log_path 'logs/MethodServer/multi-node-prod/04-05Aug2025/Node3/MethodServer-2507260857-1773103-log4j.log.2025-08-05_2')"
WGM_LOG="$(resolve_log_path 'logs/WGM/large-assembly-retrieval/Lightweight Mode/Log_PROE_41_2024_09_16_07_40_41_15976_000001/uwgm.log.1')"
ACC_INCLUDE='FileRepositories/.*_GW_'

# Figures measured on the base build and recorded in the feature doc § Findings:
# the ThingWorx log yields 333 keys with UUIDs masked (every match there is a
# hexadecimal UUID, so the loose and the hexadecimal pattern agree); the
# gateway-path lines yield 1,489 keys unmasked, 1,327 with the loose pattern
# (two gateway names differing only in a TEST and a PROD part merged) and 1,328
# with hexadecimal UUIDs only; the method server request lines yield 589 keys
# with or without the mask, 584 of them carrying a client address; the WGM
# version lines yield 4 keys over 61 lines, 3 of them carrying four-part
# version numbers that are valid addresses.
TWX_KEYS_MASKED=333
ACC_KEYS_MASKED=1328
MS_KEYS=589
MS_KEYS_WITH_ADDRESS=584
WGM_KEYS=4
WGM_LINES=61
WGM_KEYS_WITH_ADDRESS=3

CONTRACT_DOC='features/580-mask-uuid-and-ip-address.md'
PRODUCED_MASK='read_and_process_logs() in ltl (the mask substitutions, applied to the formed message after the exposed values are added and before the message key is assembled)'
PRODUCED_RESOLVE='resolve_mask_names() in ltl (the -m/--mask and -uuid resolution into the ordered substitution list)'
PRODUCED_PATTERNS='the %mask_patterns table in ltl (one pattern and placeholder per identifier class, read by resolve_mask_names())'

P4='###.###.###.###'
P6='####:####:####:####:####:####:####:####'
PU='########-####-####-####-############'

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"; exit 1
fi
if [[ ! -f "$FIXTURE" ]]; then echo "ERROR: fixture not found: $FIXTURE"; exit 1; fi
for f in "$TWX_LOG" "$ACC_LOG" "$MS_LOG" "$WGM_LOG"; do
    if [[ ! -f "$f" ]]; then echo "ERROR: corpus log not found: $f"; exit 1; fi
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

record_failure() {
    local what="$1"
    fail=$((fail + 1))
    failures+=("$current_scenario :: $what")
}

# ---------------------------------------------------------------------------
# Capture. Runs ltl in a directory this harness created, checks the exit code
# and the runtime-warning cleanliness of its stderr at the point of capture, and
# publishes the products it wrote through globals. A run expected to fail
# (criterion 12) uses run_expect_error instead.
# ---------------------------------------------------------------------------
RUN_DIR=""; RUN_OUT=""; RUN_ERR=""; MSG_CSV=""
run_messages() {
    local label="$1"; shift
    RUN_DIR="$TMP_DIR/$current_scenario/$label"
    mkdir -p "$RUN_DIR"
    RUN_OUT="$RUN_DIR/run.out"; RUN_ERR="$RUN_DIR/run.err"; MSG_CSV=""
    local rc
    set +e
    ( cd "$RUN_DIR" && "$LTL" --disable-progress -ni -bs 1440 -oe -n 100000 -o "$@" \
        > run.out 2> run.err )
    rc=$?
    set -e

    if ! assert_no_runtime_warnings "$RUN_ERR" "$current_scenario/$label"; then
        record_failure "perl-runtime-warnings-on-stderr ($label)"
    fi
    if [[ "$rc" -ne 0 ]]; then
        echo "  FAIL  $current_scenario :: ltl exited $rc for run '$label'"
        echo "        command:     ltl --disable-progress -ni -bs 1440 -oe -n 100000 -o $*"
        echo "        asserts:     every ltl invocation in this harness completes and writes its CSVs"
        echo "        produced_by: $PRODUCED_RESOLVE"
        echo "        contract:    $CONTRACT_DOC section Requirements - -m/--mask and -uuid are accepted options"
        sed 's/^/        | /' "$RUN_ERR"
        record_failure "ltl exit $rc ($label)"
        return 1
    fi

    MSG_CSV=$(find "$RUN_DIR" -name '*-LTL-MESSAGES-*.csv' -print -quit)
    if [[ -z "$MSG_CSV" ]]; then
        echo "  FAIL  $current_scenario :: anchor not found: run '$label' wrote no MESSAGES CSV"
        record_failure "no MESSAGES CSV ($label)"
        return 1
    fi
    return 0
}

# A run whose exit code and stderr are the subject: no CSV, no exit assertion
# here. Publishes RUN_ERR and RUN_EXIT.
RUN_EXIT=0
run_expect_error() {
    local label="$1"; shift
    RUN_DIR="$TMP_DIR/$current_scenario/$label"
    mkdir -p "$RUN_DIR"
    RUN_OUT="$RUN_DIR/run.out"; RUN_ERR="$RUN_DIR/run.err"
    set +e
    ( cd "$RUN_DIR" && "$LTL" --disable-progress -ni -bs 1440 -oe "$@" > run.out 2> run.err )
    RUN_EXIT=$?
    set -e
    if ! assert_no_runtime_warnings "$RUN_ERR" "$current_scenario/$label"; then
        record_failure "perl-runtime-warnings-on-stderr ($label)"
    fi
}

write_expected() {
    local path="$1"; shift
    mkdir -p "$(dirname "$path")"
    : > "$path"
    local row
    for row in "$@"; do printf '%s\n' "$row" >> "$path"; done
    printf '%s' "$path"
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

# Shape of a corpus MESSAGES CSV, one figure per name, printed as
# `name=value` pairs on one line: keys, the occurrence total, and over the
# message text alone (the key with its leading bracketed level, thread and
# object segments removed) how many keys carry a valid IPv4 address, the IPv4
# placeholder, a hexadecimal UUID, the UUID placeholder, or a five-part dotted
# number; plus a digest of the set of bracketed prefixes, which a mask must
# leave as it found them. The patterns here are written from the feature doc's
# pattern definitions, independently of ltl. An unreadable or empty CSV is a
# hard failure.
csv_shape() {
    "$PERL" -MText::CSV -MDigest::MD5=md5_hex -e '
        my ($csv_path) = @ARGV;
        my $octet = q{(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)};
        my $ipv4 = qr/(?<![\w.])(?:$octet\.){3}$octet(?!\w|\.\d)/;
        my $uuid = qr/(?<![0-9A-Fa-f])[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}(?![0-9A-Fa-f])/;
        my $five = qr/(?<!\d)(?<!\d\.)\d+(?:\.\d+){4}(?!\d)(?!\.\d)/;
        my $csv = Text::CSV->new({ binary => 1 });
        open my $fh, "<", $csv_path or die "cannot open $csv_path: $!\n";
        my $header = $csv->getline($fh);
        unless ($header && @$header && $header->[1] eq "message") { print "anchor not found: no message column in $csv_path\n"; exit 1 }
        my %n = map { $_ => 0 } qw(keys occurrences ipv4 ipv4_placeholder uuid uuid_placeholder five_part);
        my %prefixes;
        while (my $row = $csv->getline($fh)) {
            next unless defined $row->[1] && length $row->[1];
            $n{keys}++; $n{occurrences} += $row->[2];
            my $text = $row->[1];
            my $prefix = "";
            if ($text =~ s/^((?:\[[^\]]*\] )+)//) { $prefix = $1 }
            $prefixes{$prefix} = 1;
            $n{ipv4}++             if $text =~ $ipv4;
            $n{ipv4_placeholder}++ if index($text, "###.###.###.###") >= 0;
            $n{uuid}++             if $text =~ $uuid;
            $n{uuid_placeholder}++ if index($text, "########-####-####-####-############") >= 0;
            $n{five_part}++        if $text =~ $five;
        }
        unless ($n{keys}) { print "anchor not found: no message rows in $csv_path\n"; exit 1 }
        print join(" ", (map { "$_=$n{$_}" } sort keys %n), "prefixes=" . md5_hex(join("\n", sort keys %prefixes))), "\n";
        exit 0;
    ' "$1"
}

# One `name=value` figure of a csv_shape line equals the expected value.
shape_is() {
    local shape="$1" name="$2" expected="$3"
    local got
    got=$(printf '%s\n' "$shape" | tr ' ' '\n' | sed -n "s/^$name=//p")
    if [[ -z "$got" ]]; then echo "anchor not found: no $name figure in shape '$shape'"; return 1; fi
    if [[ "$got" != "$expected" ]]; then echo "$name is $got, expected $expected (shape: $shape)"; return 1; fi
    echo "$name=$got"
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

# The deprecation notice: exactly one stderr line says -uuid is deprecated and
# names --mask; a run without -uuid prints none.
check_notice() {
    local err="$1" expected="$2"
    if [[ ! -e "$err" ]]; then echo "anchor not found: no stderr capture at $err"; return 1; fi
    local n
    n=$(grep -c -- '-uuid.*deprecated' "$err" || true)
    if [[ "$n" -ne "$expected" ]]; then echo "$n deprecation lines on stderr, expected $expected"; sed 's/^/  | /' "$err"; return 1; fi
    if [[ "$expected" -eq 1 ]] && ! grep -q -- '--mask' "$err"; then echo "the notice does not name --mask"; sed 's/^/  | /' "$err"; return 1; fi
    echo "$n deprecation line(s), as expected"
}

# ---------------------------------------------------------------------------
# The fixture, and the keys it implies
# ---------------------------------------------------------------------------
# tests/fixtures/message-mask-values.txt - twelve Apache-style access-log lines
# whose message key is [status] GET <path>, chosen for what the corpus lacks:
#   3 lines differing only by IPv4 addresses of different lengths, with a port,
#     a leading / and one in brackets (one key under -m ipv4);
#   1 line of dotted quads that are not addresses (256.1.1.1, 01.2.3.4,
#     1.2.3.4.5), never masked;
#   3 lines differing only by one IPv6 address written in full, compressed and
#     compressed with two trailing groups (one key under -m ipv6);
#   1 probe line carrying [::1]:9273, a zoned fe80::1%eth0, Class::method, a
#     bare :: between separators and an IPv4 address;
#   2 lines differing only by an IPv4-ending IPv6 address (::ffff:<ipv4>), one
#     of them a 500;
#   2 lines differing only by a UUID in the query string, one upper-case.
# Ten lines carry a 2xx status and two a 500.
NET_1='[200] GET /net/peer/10.0.0.1:8080/[192.168.1.20]/status'
NET_2='[200] GET /net/peer/172.16.254.3:8080/[8.8.8.8]/status'
NET_3='[200] GET /net/peer/255.255.255.255:8080/[1.2.3.4]/status'
NET_MASKED="[200] GET /net/peer/$P4:8080/[$P4]/status"
INVALID='[500] GET /net/invalid/256.1.1.1/01.2.3.4/1.2.3.4.5'
V6_1='[200] GET /v6/peer/2001:db8:0000:0000:0000:0000:0000:0001/x'
V6_2='[200] GET /v6/peer/2001:db8::1/x'
V6_3='[200] GET /v6/peer/2001:db8::a:b/x'
V6_MASKED="[200] GET /v6/peer/$P6/x"
PROBE='[200] GET /v6/probe/[::1]:9273/fe80::1%eth0/Class::method/::/10.0.0.1'
PROBE_V4="[200] GET /v6/probe/[::1]:9273/fe80::1%eth0/Class::method/::/$P4"
PROBE_V6="[200] GET /v6/probe/[$P6]:9273/$P6%eth0/Class::method/::/10.0.0.1"
PROBE_IP="[200] GET /v6/probe/[$P6]:9273/$P6%eth0/Class::method/::/$P4"
MAPPED_1='[200] GET /v6/mapped/::ffff:192.0.2.1/x'
MAPPED_2='[500] GET /v6/mapped/::ffff:198.51.100.7/x'
MAPPED_1_V4="[200] GET /v6/mapped/::ffff:$P4/x"
MAPPED_2_V4="[500] GET /v6/mapped/::ffff:$P4/x"
MAPPED_1_V6="[200] GET /v6/mapped/$P6/x"
MAPPED_2_V6="[500] GET /v6/mapped/$P6/x"
ORDERS='[200] GET /store/orders'

# ---------------------------------------------------------------------------
# Scenarios
# ---------------------------------------------------------------------------

# Criterion 1: -m uuid on the reference log of UUID-varying errors, and the
# deprecated spelling (criterion 3) on the same input.
scenario_uuid_reference_log() {
    current_scenario="uuid-reference-log"
    echo "[$current_scenario]"

    run_messages m-uuid -m uuid "$TWX_LOG" || return 0
    local m_csv="$MSG_CSV" m_err="$RUN_ERR"
    local shape; shape=$(csv_shape "$m_csv") || { echo "  FAIL  $current_scenario :: $shape"; record_failure "csv shape"; return 0; }
    assert_command \
        command     "shape_is '$shape' keys $TWX_KEYS_MASKED" \
        label       "-m uuid yields the $TWX_KEYS_MASKED keys measured with -uuid on the base build" \
        asserts     'Every message differing only by its UUID becomes one key: the key count is the figure the base build produced with -uuid, where every match on this log is a hexadecimal UUID.' \
        produced_by "$PRODUCED_MASK" \
        contract    "$CONTRACT_DOC section Acceptance criteria 1 and section Findings - the reference log under -uuid on the base build"
    assert_command \
        command     "shape_is '$shape' uuid 0 && shape_is '$shape' uuid_placeholder 3" \
        label       'no raw UUID remains in any key; the placeholder sits where the UUIDs sat' \
        asserts     'Masking replaces every hexadecimal UUID in the message with ########-####-####-####-############ and leaves none as written.' \
        produced_by "$PRODUCED_PATTERNS" \
        contract    "$CONTRACT_DOC section Pattern definitions - UUID, and section D1"

    run_messages uuid -uuid "$TWX_LOG" || return 0
    assert_command \
        command     "check_same_csv '$m_csv' '$MSG_CSV' messages" \
        label       '-uuid produces the messages CSV of -m uuid' \
        asserts     'The deprecated spelling masks exactly as -m uuid does: the same hexadecimal pattern, the same placeholder, the same keys.' \
        produced_by "$PRODUCED_RESOLVE" \
        contract    "$CONTRACT_DOC section Acceptance criteria 3 - identical messages CSV"
    assert_command \
        command     "check_notice '$RUN_ERR' 1 && check_notice '$m_err' 0" \
        label       '-uuid prints one deprecation notice naming --mask; -m uuid prints none' \
        asserts     'Using -uuid tells the user, once, that the option is deprecated in favour of --mask, also under --disable-progress; -m uuid is silent.' \
        produced_by 'adapt_to_command_line_options() in ltl (the -uuid deprecation notice, beside the -os notice)' \
        contract    "$CONTRACT_DOC section Requirements - -uuid is deprecated, not removed; section D8"
}

# Criteria 2 and 3: the access-log lines requesting gateway file repositories,
# whose hyphenated gateway names have the 8-4-4-4-12 outline without being
# UUIDs.
scenario_uuid_gateway_paths() {
    current_scenario="uuid-gateway-paths"
    echo "[$current_scenario]"

    run_messages m-uuid -i "$ACC_INCLUDE" -m uuid "$ACC_LOG" || return 0
    local m_csv="$MSG_CSV"
    local shape; shape=$(csv_shape "$m_csv") || { echo "  FAIL  $current_scenario :: $shape"; record_failure "csv shape"; return 0; }
    assert_command \
        command     "shape_is '$shape' keys $ACC_KEYS_MASKED" \
        label       "-m uuid yields $ACC_KEYS_MASKED keys: hexadecimal UUIDs masked, gateway names left as written" \
        asserts     'Only hexadecimal UUIDs are masked. The base build merged two requests whose gateway names differ in a TEST and a PROD part, because its pattern matched any 8-4-4-4-12 run of non-space characters; with hexadecimal UUIDs only they stay two keys, one more than the base build produced.' \
        produced_by "$PRODUCED_PATTERNS" \
        contract    "$CONTRACT_DOC section D1 and section Findings - the -uuid pattern is not limited to hexadecimal UUIDs"
    assert_command \
        command     "shape_is '$shape' uuid 0 && ! '$PERL' -MText::CSV -e 'my \$c=Text::CSV->new({binary=>1}); open my \$f,\"<\",\$ARGV[0] or die; \$c->getline(\$f); my \$bad=0; while(my \$r=\$c->getline(\$f)){ while(\$r->[1] =~ /(.)$PU/g){ \$bad++ if \$1 ne \"/\" } } print \"placeholders preceded by something other than /: \$bad\\n\"; exit(\$bad ? 0 : 1)' '$m_csv'" \
        label       'every placeholder is preceded by /, and no raw UUID remains' \
        asserts     'A UUID in these paths always follows a /; a placeholder preceded by anything else would mean part of a gateway name was rewritten, as the base build did to the leading / and the first 36 characters of a name.' \
        produced_by "$PRODUCED_PATTERNS" \
        contract    "$CONTRACT_DOC section Acceptance criteria 2 - no placeholder is preceded by anything but /"

    run_messages uuid -i "$ACC_INCLUDE" -uuid "$ACC_LOG" || return 0
    assert_command \
        command     "check_same_csv '$m_csv' '$MSG_CSV' messages && check_notice '$RUN_ERR' 1" \
        label       '-uuid produces the messages CSV of -m uuid and prints the notice' \
        asserts     '-uuid is corrected with -m uuid (hexadecimal UUIDs only), so its output on these lines is identical, and it says it is deprecated.' \
        produced_by "$PRODUCED_RESOLVE" \
        contract    "$CONTRACT_DOC section D1 (-uuid is corrected with it) and section Acceptance criteria 3"
}

# Criterion 4: client addresses inside the method server request-monitor lines.
scenario_ipv4_client_addresses() {
    current_scenario="ipv4-client-addresses"
    echo "[$current_scenario]"

    run_messages plain -i ServletRequestMonitor "$MS_LOG" || return 0
    local plain_shape; plain_shape=$(csv_shape "$MSG_CSV") || { echo "  FAIL  $current_scenario :: $plain_shape"; record_failure "csv shape"; return 0; }
    run_messages m-ipv4 -i ServletRequestMonitor -m ipv4 "$MS_LOG" || return 0
    local shape; shape=$(csv_shape "$MSG_CSV") || { echo "  FAIL  $current_scenario :: $shape"; record_failure "csv shape"; return 0; }

    assert_command \
        command     "shape_is '$plain_shape' ipv4 $MS_KEYS_WITH_ADDRESS && shape_is '$shape' ipv4 0 && shape_is '$shape' ipv4_placeholder $MS_KEYS_WITH_ADDRESS" \
        label       "the $MS_KEYS_WITH_ADDRESS keys carrying a client address now read $P4 there, none carries a valid IPv4 address" \
        asserts     'Every valid IPv4 address in the message text is replaced by the fixed-width placeholder; the unmasked run proves the addresses were there to mask.' \
        produced_by "$PRODUCED_PATTERNS" \
        contract    "$CONTRACT_DOC section D2, D3 and section Findings - client addresses in a method server log"
    assert_command \
        command     "shape_is '$shape' keys $MS_KEYS && shape_is '$shape' occurrences \$(shape_is '$plain_shape' occurrences \$(printf '%s\n' '$plain_shape' | tr ' ' '\n' | sed -n 's/^occurrences=//p') | sed 's/^occurrences=//')" \
        label       "key count $MS_KEYS and occurrence total unchanged by the mask" \
        asserts     'Each of these messages also carries a timestamp and a request identifier, so masking the address merges nothing and loses no line: the key count and the occurrence total are those of the unmasked run.' \
        produced_by "$PRODUCED_MASK" \
        contract    "$CONTRACT_DOC section Acceptance criteria 4 - occurrence totals unchanged"
    assert_command \
        command     "[[ \"\$(printf '%s\n' '$shape' | tr ' ' '\n' | sed -n 's/^prefixes=//p')\" == \"\$(printf '%s\n' '$plain_shape' | tr ' ' '\n' | sed -n 's/^prefixes=//p')\" ]] && echo 'bracketed prefixes identical'" \
        label       'the thread segment [ajp-nio-127.0.0.1-80] is unchanged' \
        asserts     'The mask reads the message alone: the level, thread and object segments of the key, built from the parsed fields, are the same set with and without the mask, so the loopback address in the thread name is still written.' \
        produced_by "$PRODUCED_MASK" \
        contract    "$CONTRACT_DOC section Findings - the thread segment is built from the thread field, which masking does not read"
}

# Criterion 5: dotted version numbers in the WGM client log's version lines.
scenario_ipv4_version_numbers() {
    current_scenario="ipv4-version-numbers"
    echo "[$current_scenario]"

    run_messages plain -i 'Version :' "$WGM_LOG" || return 0
    local plain_shape; plain_shape=$(csv_shape "$MSG_CSV") || { echo "  FAIL  $current_scenario :: $plain_shape"; record_failure "csv shape"; return 0; }
    run_messages m-ipv4 -i 'Version :' -m ipv4 "$WGM_LOG" || return 0
    local shape; shape=$(csv_shape "$MSG_CSV") || { echo "  FAIL  $current_scenario :: $shape"; record_failure "csv shape"; return 0; }

    assert_command \
        command     "shape_is '$plain_shape' ipv4 $WGM_KEYS_WITH_ADDRESS && shape_is '$shape' ipv4 0 && shape_is '$shape' ipv4_placeholder $WGM_KEYS_WITH_ADDRESS" \
        label       "four-part version numbers that are valid addresses read $P4" \
        asserts     'A dotted version number that is also a valid IPv4 address is masked: nothing in the text tells the two apart, and the decision is to mask it.' \
        produced_by "$PRODUCED_PATTERNS" \
        contract    "$CONTRACT_DOC section D2 - a valid address that is really something else is masked all the same"
    assert_command \
        command     "shape_is '$shape' five_part $WGM_KEYS_WITH_ADDRESS && shape_is '$shape' keys $WGM_KEYS && shape_is '$shape' occurrences $WGM_LINES" \
        label       'five-part version strings are as written; keys and lines unchanged' \
        asserts     'A dotted run of five parts is not an address and stays as written in every key that carried one; masking the four-part numbers merges no keys and loses no line.' \
        produced_by "$PRODUCED_PATTERNS" \
        contract    "$CONTRACT_DOC section Pattern definitions - IPv4: 1.2.3.4.5 is left as written"
}

# Criterion 6: IPv4 shapes on the synthetic fixture.
scenario_ipv4_shapes() {
    current_scenario="ipv4-shapes"
    echo "[$current_scenario]"

    run_messages m-ipv4 -m ipv4 "$FIXTURE" || return 0
    local expected="$TMP_DIR/$current_scenario/expected.tsv"
    write_expected "$expected" \
        "$(printf '3\t%s' "$NET_MASKED")" \
        "$(printf '1\t%s' "$INVALID")" \
        "$(printf '1\t%s' "$V6_1")" \
        "$(printf '1\t%s' "$V6_2")" \
        "$(printf '1\t%s' "$V6_3")" \
        "$(printf '1\t%s' "$PROBE_V4")" \
        "$(printf '1\t%s' "$MAPPED_1_V4")" \
        "$(printf '1\t%s' "$MAPPED_2_V4")" \
        "$(printf '2\t%s' "$ORDERS")" > /dev/null
    assert_command \
        command     "check_messages '$MSG_CSV' '$expected'" \
        label       'three lines differing only by IPv4 addresses are one key; a port, a leading / and brackets do not stop a match; invalid outlines stay' \
        asserts     'Addresses of different written lengths become the one fixed-width placeholder, whether followed by a port, preceded by a / or enclosed in brackets; 256.1.1.1, 01.2.3.4 and 1.2.3.4.5 are not addresses and are left as written; the IPv4 tail of an IPv4-ending IPv6 address is masked when only ipv4 is named; IPv6 addresses are as written.' \
        produced_by "$PRODUCED_PATTERNS" \
        contract    "$CONTRACT_DOC section Acceptance criteria 6, section D3 and section Pattern definitions - IPv4"
}

# Criterion 7: IPv6 shapes on the synthetic fixture.
scenario_ipv6_shapes() {
    current_scenario="ipv6-shapes"
    echo "[$current_scenario]"

    run_messages m-ipv6 -m ipv6 "$FIXTURE" || return 0
    local expected="$TMP_DIR/$current_scenario/expected.tsv"
    write_expected "$expected" \
        "$(printf '1\t%s' "$NET_1")" \
        "$(printf '1\t%s' "$NET_2")" \
        "$(printf '1\t%s' "$NET_3")" \
        "$(printf '1\t%s' "$INVALID")" \
        "$(printf '3\t%s' "$V6_MASKED")" \
        "$(printf '1\t%s' "$PROBE_V6")" \
        "$(printf '1\t%s' "$MAPPED_1_V6")" \
        "$(printf '1\t%s' "$MAPPED_2_V6")" \
        "$(printf '2\t%s' "$ORDERS")" > /dev/null
    assert_command \
        command     "check_messages '$MSG_CSV' '$expected'" \
        label       'full and compressed IPv6 addresses are one key; brackets, port and zone stay; Class::method and a bare :: stay; ::1 is masked; IPv4 stays' \
        asserts     'Every valid IPv6 address, written in full or compressed, becomes the one fixed-width placeholder; [::1]:9273 keeps its brackets and port and fe80::1%eth0 its zone around the placeholder; Class::method and a bare :: between separators are not addresses to mask; an IPv4-ending IPv6 address is one IPv6 placeholder; IPv4 addresses are as written.' \
        produced_by "$PRODUCED_PATTERNS" \
        contract    "$CONTRACT_DOC section Acceptance criteria 7, section D3, section D7 and section Pattern definitions - IPv6"
}

# Criterion 8: ip, a comma-separated list and a repeated option are the same
# request.
scenario_ip_spellings() {
    current_scenario="ip-spellings"
    echo "[$current_scenario]"

    run_messages ip -m ip "$FIXTURE" || return 0
    local ip_csv="$MSG_CSV"
    local expected="$TMP_DIR/$current_scenario/expected.tsv"
    write_expected "$expected" \
        "$(printf '3\t%s' "$NET_MASKED")" \
        "$(printf '1\t%s' "$INVALID")" \
        "$(printf '3\t%s' "$V6_MASKED")" \
        "$(printf '1\t%s' "$PROBE_IP")" \
        "$(printf '1\t%s' "$MAPPED_1_V6")" \
        "$(printf '1\t%s' "$MAPPED_2_V6")" \
        "$(printf '2\t%s' "$ORDERS")" > /dev/null
    assert_command \
        command     "check_messages '$ip_csv' '$expected'" \
        label       '-m ip masks both versions; an IPv4-ending IPv6 address is one IPv6 placeholder' \
        asserts     'ip names both address versions; IPv6 is masked before IPv4, so ::ffff:192.0.2.1 becomes one IPv6 placeholder rather than an IPv6 prefix around an IPv4 placeholder.' \
        produced_by "$PRODUCED_RESOLVE" \
        contract    "$CONTRACT_DOC section Pattern definitions - ip: IPv6 is masked before IPv4"

    run_messages list -m ipv4,ipv6 "$FIXTURE" || return 0
    local list_csv="$MSG_CSV"
    run_messages repeated -m ipv4 -m ipv6 "$FIXTURE" || return 0
    assert_command \
        command     "check_same_csv '$ip_csv' '$list_csv' messages && check_same_csv '$ip_csv' '$MSG_CSV' messages" \
        label       '-m ipv4,ipv6 and -m ipv4 -m ipv6 produce the messages CSV of -m ip' \
        asserts     'A comma-separated list and a repeated option name the same identifiers as ip does, and the substitutions run in the same fixed order whatever order the names were given in.' \
        produced_by "$PRODUCED_RESOLVE" \
        contract    "$CONTRACT_DOC section D5 - a comma-separated list names several identifiers; section Acceptance criteria 8"
}

# Criterion 9: masking runs after the exposed values are added.
scenario_uuid_after_expose() {
    current_scenario="uuid-after-expose"
    echo "[$current_scenario]"

    local plain_rows=(
        "$(printf '1\t%s' "$NET_1")" "$(printf '1\t%s' "$NET_2")" "$(printf '1\t%s' "$NET_3")"
        "$(printf '1\t%s' "$INVALID")"
        "$(printf '1\t%s' "$V6_1")" "$(printf '1\t%s' "$V6_2")" "$(printf '1\t%s' "$V6_3")"
        "$(printf '1\t%s' "$PROBE")" "$(printf '1\t%s' "$MAPPED_1")" "$(printf '1\t%s' "$MAPPED_2")"
    )

    run_messages x-id -m uuid -x id "$FIXTURE" || return 0
    local expected="$TMP_DIR/$current_scenario/expected-x-id.tsv"
    write_expected "$expected" "${plain_rows[@]}" "$(printf '2\t%s id=%s' "$ORDERS" "$PU")" > /dev/null
    assert_command \
        command     "check_messages '$MSG_CSV' '$expected'" \
        label       '-m uuid -x id: the appended id value is masked in place' \
        asserts     'The query string is removed from the message, the exposed id is appended at the end, and only then is the UUID in it masked, so the two orders lines are one key ending id=########-####-####-####-############.' \
        produced_by "$PRODUCED_MASK" \
        contract    "$CONTRACT_DOC section D4 - masking runs after --expose; the first row of its table"

    run_messages xqs-x-id -m uuid -xqs -x id "$FIXTURE" || return 0
    expected="$TMP_DIR/$current_scenario/expected-xqs-x-id.tsv"
    write_expected "$expected" "${plain_rows[@]}" "$(printf '2\t%s?id=%s&x=1' "$ORDERS" "$PU")" > /dev/null
    assert_command \
        command     "check_messages '$MSG_CSV' '$expected' && ! grep -qiE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' '$MSG_CSV'" \
        label       '-m uuid -xqs -x id: the kept query string yields id, nothing is appended, the UUID is masked in place; no raw UUID in any key' \
        asserts     'With the query string kept the formed message still yields the raw id, so nothing is appended, and the value is then masked where it sits; neither run leaves a raw UUID in any key.' \
        produced_by "$PRODUCED_MASK" \
        contract    "$CONTRACT_DOC section D4 - the second row of its table, under 566 D7"
}

# Criterion 10: -i, -e and -h read the raw line, which masking never touches.
scenario_selection_unchanged() {
    current_scenario="selection-unchanged"
    echo "[$current_scenario]"

    # Selectors naming a raw address or UUID, with the classification counts the
    # fixture implies for the lines they keep: -i 10.0.0.1 keeps the first peer
    # line and the probe line (two 2xx); -e 2001:db8::1 drops one 2xx line of
    # twelve; -h on the lower-case UUID keeps every line (ten 2xx, two 500).
    local sel
    for sel in "-i 10.0.0.1|2|0" "-e 2001:db8::1|9|2" "-h 3f9c2a71-8be4-4d0a-9c15-6e2b7d40a8f3|10|2"; do
        local opts="${sel%%|*}" rest="${sel#*|}"
        local succ="${rest%%|*}" failn="${rest#*|}"
        local label="plain${opts// /-}"
        # shellcheck disable=SC2086
        run_messages "$label" $opts -V format-detection "$FIXTURE" || continue
        local plain_out="$RUN_OUT" plain_csv="$MSG_CSV"
        local mask
        for mask in "-m ip" "-m uuid,ip"; do
            local mlabel="${label}${mask// /-}"
            # shellcheck disable=SC2086
            run_messages "$mlabel" $opts $mask -V format-detection "$FIXTURE" || continue
            assert_command \
                command     "check_classification '$plain_out' '$RUN_OUT' $succ $failn && [[ \$(shape_is \"\$(csv_shape '$MSG_CSV')\" occurrences 0 2>&1 | sed 's/.*occurrences is \([0-9]*\).*/\1/') == \$(shape_is \"\$(csv_shape '$plain_csv')\" occurrences 0 2>&1 | sed 's/.*occurrences is \([0-9]*\).*/\1/') ]] && echo 'occurrence totals equal'" \
                label       "under $opts with $mask, classification counts and occurrence total are those of the run without the mask" \
                asserts     'Include, exclude and highlight patterns match the raw line, which masking never touches: the lines selected and the run-level classification counts are identical with and without the mask, and so is the number of lines retained as messages.' \
                produced_by "$PRODUCED_MASK" \
                contract    "$CONTRACT_DOC section Acceptance criteria 10 and section Findings - the raw line that -i, -e, -h and -udm read is untouched"
        done
    done
}

# Criterion 12: an unknown name stops the run.
scenario_unknown_name() {
    current_scenario="unknown-name"
    echo "[$current_scenario]"

    run_expect_error foo -m foo "$FIXTURE"
    assert_command \
        command     "[[ $RUN_EXIT -ne 0 ]] && grep -q 'foo' '$RUN_ERR' && grep -q 'uuid' '$RUN_ERR' && grep -qw 'ip' '$RUN_ERR' && grep -qw 'ipv4' '$RUN_ERR' && grep -qw 'ipv6' '$RUN_ERR' && echo \"exit $RUN_EXIT, accepted values named\"" \
        label       '-m foo exits non-zero and the error names uuid, ip, ipv4 and ipv6' \
        asserts     'An unknown mask name is an error naming the value given and every accepted value, as other options with a fixed set of values do; nothing is masked silently.' \
        produced_by "$PRODUCED_RESOLVE" \
        contract    "$CONTRACT_DOC section Pattern definitions - An unknown name; section Acceptance criteria 12"
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------

SCENARIOS=(uuid-reference-log uuid-gateway-paths ipv4-client-addresses ipv4-version-numbers
           ipv4-shapes ipv6-shapes ip-spellings uuid-after-expose selection-unchanged unknown-name)

usage() {
    echo "Usage: $0 [--scenario NAME] [--list]"
    echo "Scenarios (acceptance criteria 1-10 and 12 of $CONTRACT_DOC):"
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

echo "Validating message mask (-m/--mask, -uuid), issue #580 acceptance criteria 1-10 and 12"
echo "  ltl:       $LTL"
echo ""

for s in "${SCENARIOS[@]}"; do
    case "$s" in
        uuid-reference-log)     scenario_uuid_reference_log ;;
        uuid-gateway-paths)     scenario_uuid_gateway_paths ;;
        ipv4-client-addresses)  scenario_ipv4_client_addresses ;;
        ipv4-version-numbers)   scenario_ipv4_version_numbers ;;
        ipv4-shapes)            scenario_ipv4_shapes ;;
        ipv6-shapes)            scenario_ipv6_shapes ;;
        ip-spellings)           scenario_ip_spellings ;;
        uuid-after-expose)      scenario_uuid_after_expose ;;
        selection-unchanged)    scenario_selection_unchanged ;;
        unknown-name)           scenario_unknown_name ;;
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
