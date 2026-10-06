#!/usr/bin/env bash
# validate-option-resolution.sh — harness for how ltl resolves the options
# that take a quantity: the count, byte and duration bounds (-dmin/-dmax,
# -bmin/-bmax, -cmin/-cmax and their -h* highlight mirrors), declared once and
# read by every site that names them.
#
# The file name tracks the -V option-resolution section (reserved by #231,
# built by #605): each option that takes a count, a byte size or a duration,
# as entered beside what it resolved to. The scenarios read that section, the
# filter-summary counts and runtime-config values a resolved value drives, the
# settlement checks' exit code and stderr, and the source (the declaration is
# the requirement, so it is checked where it lives).
#
# Each assertion records, per tests/HARNESS-DESIGN.md § Self-documenting
# assertions: asserts, produced_by (function name), contract. All three are
# surfaced on failure.
#
# Usage: ./tests/validate-option-resolution.sh [--list | --scenario NAME]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"

neutralize_colour_env

# Boundary fixture: every line carries a duration, a byte count and a count;
# the settlement checks stop the run before any line is read.
BOUNDARY_FIXTURE="$REPO_DIR/tests/fixtures/numeric-highlight-boundary.txt"

CONTRACT_DECL='features/605-input-units.md § 4 D1 (one declaration of the bound set; enumerations derive from it) and § 5.2'
CONTRACT_NEG='features/605-input-units.md § 4 D2 (a negative bound is a usage error, checked at settlement beside the inverted-range check) and § 5.5'

SUBMS_FIXTURE="$REPO_DIR/tests/fixtures/access-bracketed-sub-millisecond.txt"

CONTRACT_UNITS='features/605-input-units.md section 2.2 and section 5.3 (one parse for a quantity: a bare number as it stands, a unit read in the option'"'"'s kind only)'
CONTRACT_SECTION='features/605-input-units.md section 5.6 (the -V option-resolution section) and section 4 D17'

# The twelve bound options, as the user types them.
BOUND_SHORTS=(dmin dmax bmin bmax cmin cmax hdmin hdmax hbmin hbmax hcmin hcmax)

pass=0
fail=0
failures=()
current_scenario=""

pass_with() {
    echo "  PASS  $current_scenario :: $1"
    pass=$((pass + 1))
}

# fail_with <label> <asserts> <produced_by> <contract> [detail...]
fail_with() {
    local label="$1" asserts="$2" produced_by="$3" contract="$4"
    shift 4
    echo "  FAIL  $current_scenario :: $label"
    echo "        asserts:     $asserts"
    echo "        produced_by: $produced_by"
    echo "        contract:    $contract"
    local d
    for d in "$@"; do echo "        $d"; done
    fail=$((fail + 1))
    failures+=("$current_scenario :: $label")
}

# run_ltl <tag> <args...>: one ltl run in the harness's own directory; stdout
# and stderr land in $TMP_DIR/<tag>.out and .err, the exit code in $rc. A
# Perl runtime warning on stderr is a failure.
rc=0
run_ltl() {
    local tag="$1"; shift
    set +e
    ( cd "$TMP_DIR" && "$LTL" --disable-progress "$@" ) > "$TMP_DIR/$tag.out" 2> "$TMP_DIR/$tag.err"
    rc=$?
    set -e
    if ! assert_no_runtime_warnings "$TMP_DIR/$tag.err" "$current_scenario/$tag"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: $tag perl-runtime-warnings-on-stderr")
    fi
}

# block_value <tag> <option> <key>: a key of one option's block in the
# option-resolution section of a run's stdout; empty when absent.
block_value() {
    awk -v opt="$2" -v key="$3" '
        /^=== option-resolution ===$/ { in_s = 1; next }
        /^=== END option-resolution ===$/ { in_s = 0 }
        in_s && /^option: / { cur = substr($0, 9) }
        in_s && cur == opt && index($0, "  " key ": ") == 1 { print substr($0, length(key) + 5); exit }
    ' "$TMP_DIR/$1.out"
}
# line_value <tag> <key>: the first "key: value" line of a run's stdout.
line_value() { sed -n "s/^$2: //p" "$TMP_DIR/$1.out" | head -1; }

# check <label> <actual> <expected> <asserts> <produced_by> <contract>
check() {
    if [[ -n "$2" && "$2" == "$3" ]]; then
        pass_with "$1 ($2)"
    else
        fail_with "$1" "$4" "$5" "$6" "expected: $3" "actual:   ${2:-MISSING-ANCHOR}"
    fi
}

# ---------------------------------------------------------------------------
# The bound set is declared once; no other site lists the twelve scalars or
# their option names. The read loop's comparisons stay inline (D4) and the
# twelve file-scope scalars stay where the loop reads them, so both are
# exempt. Read from the source, in the shape of validate-byte-units.sh
# one-ladder-structure: each rule a CHECK line.
# ---------------------------------------------------------------------------
scenario_quantity_units_declared() {
    current_scenario="quantity-units-declared"
    echo "[$current_scenario]"
    local report
    report="$(mktemp "$TMP_DIR/structure.XXXX")"
    perl - "$LTL" > "$report" <<'PL'
use strict; use warnings;
open my $fh, '<', $ARGV[0] or die "cannot read $ARGV[0]: $!\n";
my @lines = <$fh>;
my ($cur, $in_decl, %in_decl, %in_loop);
for my $i (0 .. $#lines) {
    my $l = $lines[$i];
    $cur = $1 if $l =~ /^sub (\w+)/;
    $in_loop{$i} = 1 if defined $cur && $cur eq 'read_and_process_logs';
    undef $cur if defined $cur && $l =~ /^\}/;
    $in_decl = 1 if $l =~ /^my \@quantity_options = \(/;
    $in_decl{$i} = 1 if $in_decl;
    $in_decl = 0 if $in_decl && $l =~ /^\);/;
}
my $check = sub { my ($name, $ok, $detail) = @_; print "CHECK\t$name\t", ($ok ? 'ok' : 'fail'), "\t", ($detail // ''), "\n"; };
my $code = sub { my $i = shift; $lines[$i] !~ /^\s*#/ };
my @decl = grep { /^my \@quantity_options = \(/ } @lines;
$check->('one-declaration', scalar(@decl) == 1 && scalar(keys %in_decl) > 1, scalar(@decl) . ' declarations');
my $scalar = qr/\$(?:filter|highlight)_(?:duration|bytes|count)_(?:min|max)\b/;
my @rows = grep { $lines[$_] =~ /\btarget\s*=>\s*\\$scalar/ } sort { $a <=> $b } keys %in_decl;
$check->('twelve-bound-rows', scalar(@rows) == 12, scalar(@rows) . ' rows with a bound target');
my @scalars = grep { $code->($_) && !$in_decl{$_} && !$in_loop{$_}
                     && $lines[$_] !~ /^my \( \$(?:filter|highlight)_/ && $lines[$_] =~ $scalar } 0 .. $#lines;
$check->('bound-scalars-only-in-declaration', !@scalars, join(' | ', map { 'line ' . ($_ + 1) } @scalars));
my $name = qr/['"|](?:-?h?[dbc](?:min|max)|(?:highlight-)?(?:duration|bytes|count)-(?:min|max))['"|=,]/;
my @names = grep { $code->($_) && !$in_decl{$_} && $lines[$_] =~ $name } 0 .. $#lines;
$check->('bound-names-only-in-declaration', !@names, join(' | ', map { 'line ' . ($_ + 1) } @names));
PL
    local name status detail
    local -a expected=(one-declaration twelve-bound-rows bound-scalars-only-in-declaration bound-names-only-in-declaration)
    for name in "${expected[@]}"; do
        status=""; detail=""
        IFS=$'\t' read -r _ _ status detail < <(awk -F'\t' -v n="$name" '$1 == "CHECK" && $2 == n' "$report") || true
        if [[ "$status" == ok ]]; then
            pass_with "$name"
        else
            fail_with "$name" \
                'The twelve numeric bounds are declared once (@quantity_options); option parsing, provenance, runtime-config, the activation tests, the index signature, the settlement checks, the export and the help rows read the declaration rather than a list of their own' \
                'the source of ltl (@quantity_options and every site of features/605-input-units.md § 5.1 except read_and_process_logs)' \
                "$CONTRACT_DECL" \
                "status: ${status:-MISSING-ANCHOR}" "detail: ${detail:-}"
        fi
    done
}

# ---------------------------------------------------------------------------
# A negative bound stops the run with a usage error naming the option and
# quoting the value; a negative top-message count is not a bound and runs as
# before.
# Invocation shape: -ni -bs 1440 -oe -n 1 on the boundary fixture. The
# assertions read the exit code and stderr only.
# ---------------------------------------------------------------------------
scenario_negative_bound() {
    current_scenario="negative-bound"
    echo "[$current_scenario]"
    local short err rc expected
    for short in "${BOUND_SHORTS[@]}"; do
        err="$TMP_DIR/neg-$short.stderr"
        set +e
        ( cd "$TMP_DIR" && "$LTL" --disable-progress -ni -bs 1440 -oe -n 1 "-$short" -5 "$BOUNDARY_FIXTURE" ) > "$TMP_DIR/neg-$short.stdout" 2> "$err"
        rc=$?
        set -e
        if ! assert_no_runtime_warnings "$err" "$current_scenario/-$short"; then
            fail=$((fail + 1)); failures+=("$current_scenario :: -$short perl-runtime-warnings-on-stderr")
        fi
        expected="Error: Invalid -$short '-5': a bound cannot be negative"
        if [[ "$rc" -ne 0 ]] && grep -qxF -- "$expected" "$err"; then
            pass_with "-$short -5 is refused (exit $rc)"
        else
            fail_with "-$short -5 is refused" \
                'A negative bound is a usage error: a non-zero exit and an error line naming the option and quoting the value as typed' \
                'adapt_to_command_line_options() in ltl (the negative-bound check beside the inverted-range check, reading @quantity_options)' \
                "$CONTRACT_NEG" \
                "exit: $rc" "expected stderr line: $expected" "stderr: $(tr '\n' '|' < "$err")"
        fi
    done

    err="$TMP_DIR/neg-n.stderr"
    set +e
    ( cd "$TMP_DIR" && "$LTL" --disable-progress -ni -bs 1440 -oe -n -1 "$BOUNDARY_FIXTURE" ) > "$TMP_DIR/neg-n.stdout" 2> "$err"
    rc=$?
    set -e
    if ! assert_no_runtime_warnings "$err" "$current_scenario/-n"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: -n perl-runtime-warnings-on-stderr")
    fi
    if [[ "$rc" -eq 0 ]] && ! grep -q 'cannot be negative' "$err"; then
        pass_with "-n -1 runs as before (exit 0)"
    else
        fail_with "-n -1 runs as before" \
            'The top-message count is not a bound: a negative value keeps the behaviour it had before the bound declaration (exit 0, no negative-bound error)' \
            'adapt_to_command_line_options() in ltl (the negative-bound check reads bound rows only)' \
            'features/605-input-units.md § 6 AC2 and § 4 D7 (a bare number keeps its meaning)' \
            "exit: $rc" "stderr: $(tr '\n' '|' < "$err")"
    fi
}

# ---------------------------------------------------------------------------
# AC6: a bare number on every option of the declaration is unchanged: the
# runtime-config value is the number typed, the filter and highlight counts
# are the base build's (captured from the build at f7c5daa on this command
# line: 16 excluded, 1 highlighted), and each block resolves to what was
# entered. Boundary fixture, one-day bucket, no empty buckets.
# ---------------------------------------------------------------------------
BARE_ARGS=(-dmin 100 -dmax 200 -bmin 1000 -bmax 5000 -cmin 1 -cmax 50 -hdmin 150 -hdmax 199 -hbmin 1 -hbmax 9999
           -hcmin 5 -hcmax 20 -n 3 -gc 500 --consolidation-trigger 100 --consolidation-ceiling 4 --consolidation-max-patterns 50)
BARE_LONGS=(duration-min duration-max bytes-min bytes-max count-min count-max highlight-duration-min highlight-duration-max
            highlight-bytes-min highlight-bytes-max highlight-count-min highlight-count-max top-messages group-ceiling
            consolidation-trigger consolidation-ceiling consolidation-max-patterns)
scenario_bare_unchanged() {
    current_scenario="bare-unchanged"
    echo "[$current_scenario]"
    run_ltl bare -ni -bs 1440 -oe -V runtime-config,filter-summary,option-resolution "${BARE_ARGS[@]}" "$BOUNDARY_FIXTURE"
    check "exit" "$rc" 0 'A bare number on every unit-bearing option runs' 'adapt_to_command_line_options() in ltl' 'features/605-input-units.md section 4 D7'
    local i long typed
    for i in "${!BARE_LONGS[@]}"; do
        long="${BARE_LONGS[$i]}"; typed="${BARE_ARGS[$((2 * i + 1))]}"
        check "runtime-config $long" "$(line_value bare "$long")" "$typed" \
            'A bare number reaches the runtime as the number typed, as before units were accepted' \
            'resolve_quantity_option() and emit_runtime_config_verbose() in ltl' 'features/605-input-units.md section 6 AC6 and section 4 D7'
        check "$long entered = resolved" "$(block_value bare "$long" entered)|$(block_value bare "$long" resolved)" "$typed|$typed" \
            'A bare number has a block whose entered and resolved values are equal' \
            'emit_option_resolution_verbose() in ltl' "$CONTRACT_SECTION"
    done
    check "excluded_numeric" "$(line_value bare excluded_numeric)" 16 \
        'The bare filter bounds exclude exactly what the base build excluded on the same command line' \
        'read_and_process_logs() in ltl (the filter blocks), emit_filter_summary_verbose()' 'features/605-input-units.md section 6 AC6'
    check "lines_highlighted" "$(line_value bare lines_highlighted)" 1 \
        'The bare highlight bounds mark exactly what the base build marked on the same command line' \
        'read_and_process_logs() in ltl (the highlight test), emit_filter_summary_verbose()' 'features/605-input-units.md section 6 AC6'
}

# ---------------------------------------------------------------------------
# AC7: a value with a unit behaves as its bare equivalent: the same resolved
# value and the same filter and highlight counts.
# ---------------------------------------------------------------------------
scenario_unit_equivalent() {
    current_scenario="unit-equivalent"
    echo "[$current_scenario]"
    local pair opt with bare long
    for pair in "dmin:2s:2000:duration-min" "dmin:0.15s:150:duration-min" "bmin:5MB:5000000:bytes-min" "bmin:2MiB:2097152:bytes-min" \
                "bmin:1kB:1000:bytes-min" "hcmin:1.5k:1500:highlight-count-min" "hdmin:0.2s:200:highlight-duration-min" "gc:2M:2000000:group-ceiling"; do
        IFS=: read -r opt with bare long <<< "$pair"
        run_ltl "u-$opt-unit" -ni -bs 1440 -oe -V filter-summary,option-resolution "-$opt" "$with" "$BOUNDARY_FIXTURE"
        run_ltl "u-$opt-bare" -ni -bs 1440 -oe -V filter-summary,option-resolution "-$opt" "$bare" "$BOUNDARY_FIXTURE"
        check "-$opt $with resolves to $bare" "$(block_value "u-$opt-unit" "$long" resolved)" "$bare" \
            'A value with a unit resolves to its equivalent in the option'"'"'s base unit' 'resolve_quantity_option() in ltl' "$CONTRACT_UNITS"
        check "-$opt $with counts as -$opt $bare" \
            "$(line_value "u-$opt-unit" excluded_numeric)/$(line_value "u-$opt-unit" lines_highlighted)" \
            "$(line_value "u-$opt-bare" excluded_numeric)/$(line_value "u-$opt-bare" lines_highlighted)" \
            'A value with a unit filters and highlights exactly as the bare equivalent does' \
            'read_and_process_logs() in ltl, reading the resolved scalar' 'features/605-input-units.md section 6 AC7'
    done
}

# ---------------------------------------------------------------------------
# AC8: a sub-millisecond duration bound applies as written. The fixture's six
# durations are 150, 199, 200, 201, 250 and 1500 microseconds.
# ---------------------------------------------------------------------------
scenario_sub_millisecond_bound() {
    current_scenario="sub-millisecond-bound"
    echo "[$current_scenario]"
    local value
    for value in 200us 0.2; do
        run_ltl "subms-$value" -ni -bs 1440 -oe -V filter-summary "-dmin" "$value" "$SUBMS_FIXTURE"
        check "-dmin $value excludes 150us and 199us" "$(line_value "subms-$value" excluded_numeric)/$(line_value "subms-$value" lines_included)" "2/4" \
            'A duration bound of 0.2 ms keeps the lines at 0.2 ms and above and excludes those below' \
            'resolve_quantity_option() and read_and_process_logs() in ltl' 'features/605-input-units.md section 6 AC8 and section 4 D20'
    done
}

# ---------------------------------------------------------------------------
# AC9: case and spellings, within the option's own kind.
# ---------------------------------------------------------------------------
scenario_case_and_spellings() {
    current_scenario="case-and-spellings"
    echo "[$current_scenario]"
    local c opt text expected long
    for c in "cmin|5m|5000000|count-min" "cmin|5M|5000000|count-min" "dmin|5m|300000|duration-min" \
             "bmin|1KB|1000|bytes-min" "bmin|1kb|1000|bytes-min" "bmin|1kB|1000|bytes-min" "bmin|1kilobyte|1000|bytes-min" \
             "bmin|2KIBIBYTES|2048|bytes-min" "cmin|1kil|1000|count-min" "cmin|1thousand|1000|count-min" "cmin|1G|1000000000|count-min" \
             "cmin|1B|1000000000|count-min" "cmin|1Bil|1000000000|count-min" "n|1.1k|1100|top-messages"; do
        IFS='|' read -r opt text expected long <<< "$c"
        run_ltl "cs-$opt-$text" -ni -bs 1440 -oe -n 1 -V option-resolution "-$opt" "$text" "$BOUNDARY_FIXTURE"
        check "-$opt $text" "$(block_value "cs-$opt-$text" "$long" resolved)" "$expected" \
            'A unit is matched without regard to case among the spellings of the option'"'"'s kind; m is a million on a count and a minute on a duration' \
            'resolve_quantity_option() in ltl (number_unit_canonical, time_unit_canonical, byte_unit_canonical)' \
            'features/605-input-units.md section 4 D11 and D12, section 6 AC9'
    done
}

# ---------------------------------------------------------------------------
# AC10: every spelling the output prints for a kind is accepted on input of
# that kind. The spellings are read from the ladders the formatters read
# (@time_unit_ladder, @byte_unit_ladder, @number_unit_ladder in ltl): every
# tier's name, and the singular a long word takes at a value of 1.
# ---------------------------------------------------------------------------
scenario_printed_spellings_accepted() {
    current_scenario="printed-spellings-accepted"
    echo "[$current_scenario]"
    local list="$TMP_DIR/spellings.txt"
    perl - "$LTL" > "$list" <<'PL'
use strict; use warnings;
open my $fh, '<', $ARGV[0] or die "cannot read $ARGV[0]: $!\n";
my $src = do { local $/; <$fh> };
my %ladder;
for my $name (qw(time_unit_ladder byte_unit_ladder number_unit_ladder)) {
    my ($body) = $src =~ /^my \@$name = (\(.*?^\);)/ms or die "no \@$name\n";
    $ladder{$name} = [ eval "my \@l = $body; \@l" ];
    die "\@$name: $@" if $@;
}
my %seen;
my $emit = sub { my ($kind, $s) = @_; print "$kind\t$s\n" if defined $s && $s ne '' && !$seen{"$kind $s"}++; };
for my $step (@{ $ladder{time_unit_ladder} }) {
    $emit->(duration => $_) for @$step{qw(short medium long)};
    $emit->(duration => $step->{long} =~ s/s$//r);
}
for my $step (@{ $ladder{byte_unit_ladder} }) {
    for my $n (qw(si iec)) { $emit->(bytes => $step->{$n}{token}); $emit->(bytes => $step->{$n}{word}); $emit->(bytes => $step->{$n}{word} =~ s/s$//r); }
}
for my $step (@{ $ladder{number_unit_ladder} }) { $emit->(count => $_) for @$step{qw(short medium long)}; }
PL
    if [[ ! -s "$list" ]]; then
        fail_with "spellings read from the ladders" 'The printed spellings are read from the ladders the formatters read' 'the source of ltl' \
            'features/605-input-units.md section 4 D24' "no spelling extracted from $LTL"
        return
    fi
    local kind spelling opt long n=0
    while IFS=$'\t' read -r kind spelling; do
        case "$kind" in
            duration) opt=hdmin; long=highlight-duration-min ;;
            bytes)    opt=hbmin; long=highlight-bytes-min ;;
            count)    opt=hcmin; long=highlight-count-min ;;
        esac
        n=$((n + 1))
        run_ltl "ps-$n" -ni -bs 1440 -oe -n 1 -V option-resolution "-$opt" "1$spelling" "$BOUNDARY_FIXTURE"
        if [[ "$rc" -eq 0 && -n "$(block_value "ps-$n" "$long" resolved)" ]]; then
            pass_with "$kind '$spelling' accepted (-$opt 1$spelling -> $(block_value "ps-$n" "$long" resolved))"
        else
            fail_with "$kind '$spelling' accepted" \
                'Every spelling the output prints for a kind is accepted on input of that kind' \
                'resolve_quantity_option() in ltl, through the canonical sub of the kind' \
                'features/605-input-units.md section 4 D24 and section 6 AC10' \
                "exit: $rc" "stderr: $(tr '\n' '|' < "$TMP_DIR/ps-$n.err")"
        fi
    done < "$list"
}

# ---------------------------------------------------------------------------
# AC11: a value the option cannot read stops the run with a usage error naming
# the option, quoting the text and listing the units of its kind as the ladder
# lists them (the list --help units prints).
# ---------------------------------------------------------------------------
scenario_unreadable_value() {
    current_scenario="unreadable-value"
    echo "[$current_scenario]"
    run_ltl units-topic --terminal-width 400 --help units
    local time_list count_list si iec byte_list
    time_list=$(sed -n 's/^Units: \(.*\)\. Each is also accepted.*/\1/p' "$TMP_DIR/units-topic.out" | sed 's/\x1b\[[0-9;]*m//g')
    si=$(sed -n 's/^Units: \(.*\) (powers of 1000) and .*/\1/p' "$TMP_DIR/units-topic.out")
    iec=$(sed -n 's/^Units: .* (powers of 1000) and \(.*\) (powers of 1024)\..*/\1/p' "$TMP_DIR/units-topic.out")
    count_list=$(sed -n 's/^Units: \(.*\) (a thousand.*/\1/p' "$TMP_DIR/units-topic.out")
    byte_list="$si, $iec"
    if [[ -z "$time_list" || -z "$si" || -z "$iec" || -z "$count_list" ]]; then
        fail_with "unit lists read from --help units" 'The units topic prints the list of each kind' 'print_help_units() in ltl' \
            "$CONTRACT_UNITS" "time: $time_list" "bytes: $byte_list" "count: $count_list"
        return
    fi
    local c opt text expected
    for c in "bmin|5s|'s' is not a byte unit ($byte_list)" \
             "bmin|1M|a byte size needs a byte unit ($byte_list)" \
             "cmin|5x|'x' is not a count unit ($count_list)" \
             "dmin|5parsecs|'parsecs' is not a time unit ($time_list)" \
             "dmin|5 s|not a number (time units: $time_list)" \
             "n|2.5|not a whole number (count units: $count_list)" \
             "gc|1.2345k|not a whole number (count units: $count_list)"; do
        IFS='|' read -r opt text expected <<< "$c"
        run_ltl "bad-$opt" -ni -bs 1440 -oe "-$opt" "$text" "$BOUNDARY_FIXTURE"
        expected="Error: Invalid -$opt '$text': $expected"
        if [[ "$rc" -ne 0 ]] && grep -qxF -- "$expected" "$TMP_DIR/bad-$opt.err"; then
            pass_with "-$opt '$text' refused (exit $rc)"
        else
            fail_with "-$opt '$text' refused" \
                'An unreadable value is a usage error with a non-zero exit, naming the option, quoting the text and listing the units of its kind' \
                'resolve_quantity_option() and adapt_to_command_line_options() in ltl' \
                'features/605-input-units.md section 4 D19 and D20, section 6 AC11' \
                "exit: $rc" "expected stderr line: $expected" "stderr: $(tr '\n' '|' < "$TMP_DIR/bad-$opt.err")"
        fi
    done
}

# ---------------------------------------------------------------------------
# AC12: the inverted-range warning quotes both values as typed.
# ---------------------------------------------------------------------------
scenario_inverted_range_quotes() {
    current_scenario="inverted-range-quotes"
    echo "[$current_scenario]"
    run_ltl inverted -ni -bs 1440 -oe -n 1 -dmin 2s -dmax 500ms "$BOUNDARY_FIXTURE"
    local expected='Warning: -dmin 2s is greater than -dmax 500ms - the range is unsatisfiable, no log entries can match'
    if [[ "$rc" -eq 0 ]] && grep -qxF -- "$expected" "$TMP_DIR/inverted.err"; then
        pass_with "inverted range quoted as typed"
    else
        fail_with "inverted range quoted as typed" 'The inverted-range warning compares the resolved values and quotes the values as the user typed them' \
            'adapt_to_command_line_options() in ltl (the inverted-range check over @quantity_options)' 'features/605-input-units.md section 4 D18, section 6 AC12' \
            "exit: $rc" "expected: $expected" "stderr: $(tr '\n' '|' < "$TMP_DIR/inverted.err")"
    fi
}

# ---------------------------------------------------------------------------
# AC13: a duration bound typed in a unit finer than the log's declared one
# gets a note; a bare number or a unit no finer does not; the bound applies
# either way. The boundary fixture's format declares milliseconds.
# ---------------------------------------------------------------------------
scenario_finer_bound_note() {
    current_scenario="finer-bound-note"
    echo "[$current_scenario]"
    local note='Note: -dmin 200us is finer than the log'"'"'s durations, which are recorded in milliseconds'
    run_ltl finer-us -ni -bs 1440 -oe -n 1 -V filter-summary -dmin 200us "$BOUNDARY_FIXTURE"
    if grep -qxF -- "$note" "$TMP_DIR/finer-us.err"; then pass_with "-dmin 200us notes the finer unit"; else
        fail_with "-dmin 200us notes the finer unit" 'A duration bound typed in a unit finer than the log records gets a note quoting it as typed and naming the log unit' \
            'note_finer_duration_bounds() in ltl' 'features/605-input-units.md section 4 D22, section 6 AC13' "expected: $note" "stderr: $(tr '\n' '|' < "$TMP_DIR/finer-us.err")"
    fi
    local value
    for value in 2ms 0.2; do
        run_ltl "finer-$value" -ni -bs 1440 -oe -n 1 -V filter-summary -dmin "$value" "$BOUNDARY_FIXTURE"
        check "-dmin $value prints no note" "$(grep -c 'is finer than the log' "$TMP_DIR/finer-$value.err" || true)" 0 \
            'A bare number, or a unit no finer than the log records, gets no note' 'note_finer_duration_bounds() in ltl' 'features/605-input-units.md section 4 D22, section 6 AC13'
    done
    check "-dmin 200us applies as -dmin 0.2" "$(line_value finer-us excluded_numeric)" "$(line_value finer-0.2 excluded_numeric)" \
        'The note clamps nothing: the bound applies as written' 'note_finer_duration_bounds() and read_and_process_logs() in ltl' 'features/605-input-units.md section 4 D22'
    # A format whose lines each name their unit ([150us]) declares 'line', not a
    # unit: there is no declared unit to be finer than, so no note.
    run_ltl finer-line -ni -bs 1440 -oe -n 1 -V filter-summary -dmin 200us "$SUBMS_FIXTURE"
    check "-dmin 200us on a log naming its unit per line prints no note" "$(grep -c 'is finer than the log' "$TMP_DIR/finer-line.err" || true)" 0 \
        'A log whose lines each name their own duration unit declares no unit to compare a bound with, so a sub-millisecond bound gets no note' \
        'note_finer_duration_bounds() in ltl (a declaration of line contributes no unit)' 'features/605-input-units.md section 4 D22 and D30'
}

# ---------------------------------------------------------------------------
# AC14: -V runtime-config carries the runtime value, and equal values written
# differently write one index signature.
# ---------------------------------------------------------------------------
scenario_runtime_value() {
    current_scenario="runtime-value"
    echo "[$current_scenario]"
    run_ltl rv-us -bs 1440 -oe -n 1 -V runtime-config,index-read-back -dmin 200us "$BOUNDARY_FIXTURE"
    rm -f "$TMP_DIR/ltl-index.csv"
    run_ltl rv-bare -bs 1440 -oe -n 1 -V index-read-back -dmin 0.2 "$BOUNDARY_FIXTURE"
    rm -f "$TMP_DIR/ltl-index.csv"
    check "runtime-config duration-min" "$(line_value rv-us duration-min)" 0.2 \
        '-V runtime-config carries the value converted to the unit ltl uses internally (milliseconds)' \
        'emit_runtime_config_verbose() in ltl (from @quantity_options)' 'features/605-input-units.md section 4 D15, section 6 AC14'
    check "one signature for 200us and 0.2" "$(line_value rv-us index_filter_signature)|$(line_value rv-bare index_filter_signature)" "-dmin=0.2|-dmin=0.2" \
        'The index signature renders each filter bound as its runtime value, so equal values written differently share one index' \
        'serialize_filters() in ltl' 'features/605-input-units.md section 4 D16, section 6 AC14'
}

# ---------------------------------------------------------------------------
# AC15: one block per unit-bearing option given, -bs and -tp included, in the
# declaration's order with -bs and -tp last; none for an option not given.
# ---------------------------------------------------------------------------
scenario_section_blocks() {
    current_scenario="section-blocks"
    echo "[$current_scenario]"
    run_ltl blocks -ni -oe -V option-resolution -bs 1d -tp s -gc 2M -dmin 2s "$BOUNDARY_FIXTURE"
    local options
    options=$(sed -n '/^=== option-resolution ===$/,/^=== END option-resolution ===$/s/^option: //p' "$TMP_DIR/blocks.out" | paste -sd, -)
    check "blocks" "$options" "duration-min,group-ceiling,bucket-size,timestamp-precision" \
        'Each unit-bearing option given has one block, in the order of the declaration, -bs and -tp last; an option not given has none' \
        'emit_option_resolution_verbose() in ltl' "$CONTRACT_SECTION"
    check "bucket-size block" "$(block_value blocks bucket-size entered)|$(block_value blocks bucket-size resolved)|$(block_value blocks bucket-size unit)" "1d|1440|m" \
        'The -bs block shows the width as typed, its value in the run unit, and that unit' 'emit_option_resolution_verbose() in ltl' "$CONTRACT_SECTION"
    check "timestamp-precision block" "$(block_value blocks timestamp-precision entered)|$(block_value blocks timestamp-precision resolved)|$(block_value blocks timestamp-precision unit)" "s|s|-" \
        'The -tp block shows the precision as typed and as resolved; its value is a unit name, so the unit is -' 'emit_option_resolution_verbose() in ltl' "$CONTRACT_SECTION"
    check "duration-min block" "$(block_value blocks duration-min entered)|$(block_value blocks duration-min resolved)|$(block_value blocks duration-min unit)" "2s|2000|ms" \
        'A duration bound resolves to milliseconds' 'emit_option_resolution_verbose() in ltl' "$CONTRACT_SECTION"
}

scenario_register quantity-units-declared \
                  negative-bound \
                  bare-unchanged \
                  unit-equivalent \
                  sub-millisecond-bound \
                  case-and-spellings \
                  printed-spellings-accepted \
                  unreadable-value \
                  inverted-range-quotes \
                  finer-bound-note \
                  runtime-value \
                  section-blocks
scenario_parse_args "$@"

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"; exit 1
fi
for _fixture in "$BOUNDARY_FIXTURE" "$SUBMS_FIXTURE"; do
    if [[ ! -f "$_fixture" ]]; then
        echo "ERROR: fixture not found: $_fixture"; exit 1
    fi
done

TMP_DIR=$(mktemp -d); trap 'rm -rf "$TMP_DIR"' EXIT

while read -r _scenario; do
    case "$_scenario" in
        quantity-units-declared ) scenario_quantity_units_declared ;;
        negative-bound          ) scenario_negative_bound ;;
        bare-unchanged          ) scenario_bare_unchanged ;;
        unit-equivalent         ) scenario_unit_equivalent ;;
        sub-millisecond-bound   ) scenario_sub_millisecond_bound ;;
        case-and-spellings      ) scenario_case_and_spellings ;;
        printed-spellings-accepted ) scenario_printed_spellings_accepted ;;
        unreadable-value        ) scenario_unreadable_value ;;
        inverted-range-quotes   ) scenario_inverted_range_quotes ;;
        finer-bound-note        ) scenario_finer_bound_note ;;
        runtime-value           ) scenario_runtime_value ;;
        section-blocks          ) scenario_section_blocks ;;
    esac
done < <(scenario_selected)

echo
echo "Results: $pass passed, $fail failed"
if [[ "$pass" -eq 0 && "$fail" -eq 0 ]]; then
    echo "FAIL: no assertion ran"
    exit 1
fi
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    printf '  %s\n' "${failures[@]}"
    exit 1
fi
exit 0
