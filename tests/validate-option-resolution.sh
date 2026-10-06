#!/usr/bin/env bash
# validate-option-resolution.sh — harness for how ltl resolves the options
# that take a quantity: the count, byte and duration bounds (-dmin/-dmax,
# -bmin/-bmax, -cmin/-cmax and their -h* highlight mirrors), declared once and
# read by every site that names them.
#
# The file name tracks the -V option-resolution section (reserved by #231,
# built by #605); the scenarios that read the section land with it. The
# scenarios here read the source (the declaration is the requirement, so it is
# checked where it lives) and the settlement checks' exit code and stderr.
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

scenario_register quantity-units-declared \
                  negative-bound
scenario_parse_args "$@"

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"; exit 1
fi
if [[ ! -f "$BOUNDARY_FIXTURE" ]]; then
    echo "ERROR: fixture not found: $BOUNDARY_FIXTURE"; exit 1
fi

TMP_DIR=$(mktemp -d); trap 'rm -rf "$TMP_DIR"' EXIT

while read -r _scenario; do
    case "$_scenario" in
        quantity-units-declared ) scenario_quantity_units_declared ;;
        negative-bound          ) scenario_negative_bound ;;
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
