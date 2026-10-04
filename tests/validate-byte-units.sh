#!/usr/bin/env bash
# validate-byte-units.sh — Validate the one byte-unit ladder every byte
# surface reads (issue #608): the byte values the tool derives and the byte
# strings it renders.
#
# Contract: features/608-byte-unit-ladder.md (D5 one byte ladder, D6/D16 the
# value climb, D7/D17 one notation per run and its option, D12 the format's
# declaration, D13/D20 mixed declarations, D15 one notation on every byte
# string) and its Acceptance criteria; features/609-gc-heap-suffix-convention.md
# (D1 a GC heap figure's letter is an IEC prefix, D2 read on the one ladder at
# the format's declared notation) and its Acceptance criteria. The byte-unit feature has no
# owning -V section: the criteria read the STATS CSV cells a run writes, so
# the harness is named for the feature, as validate-bucket-size-units.sh is.
#
# Usage: ./tests/validate-byte-units.sh [--scenario NAME | --list]
#
# Implements the self-documenting-assertion design from
# tests/HARNESS-DESIGN.md. Reference: tests/validate-bucket-size-units.sh.

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

# Invocation shape (tests/HARNESS-DESIGN.md section Invocation coherence):
# the assertions read the STATS CSV's run totals, which do not depend on the
# bucket size, so one day-wide bucket, no empty buckets, no index. The G1 GC
# fixture carries five heap transitions, all written in M.
GC_FIXTURE="$REPO_DIR/tests/fixtures/gc-g1-categories.txt"
# Four G1 pause lines, one per minute, one heap transition per prefix letter:
# 3K->1K, 3M->1M, 3G->1G and 3T->1T. HotSpot writes only M on a pause line;
# these lines are constructed so every step of the ladder is read. At -bs 1
# each line is its own bucket, so the STATS bytes cells read one delta each.
GC_PREFIX_FIXTURE="$REPO_DIR/tests/fixtures/gc-heap-byte-units.txt"
# Nine access-log lines, one per minute, whose response sizes sit either side
# of each step: 999, 1000, 1023, 1024, 999999, 1000000, 1048575, 1048576 and
# 1500000 bytes. At -bs 1 each line is its own bucket, so the STATS
# bytes_nice cells read the formatter's answer for each size in turn.
BOUNDARY_FIXTURE="$REPO_DIR/tests/fixtures/byte-boundary.txt"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

for f in "$LTL" "$GC_FIXTURE" "$GC_PREFIX_FIXTURE" "$BOUNDARY_FIXTURE"; do
    if [[ ! -e "$f" ]]; then
        echo "ERROR: required file missing: $f" >&2
        exit 1
    fi
done

CONTRACT_CLIMB='features/608-byte-unit-ladder.md D6 and D16 (the display climb compares the ladder multiplier against the value)'
CONTRACT_CARRY='features/617-width-to-format-rule.md D19 (the rounding carry at a unit boundary, handed on by features/608-byte-unit-ladder.md D16 and section 5.11)'
CONTRACT_OPTION='features/608-byte-unit-ladder.md D7 and D17 (one notation per run, -bn si|iec in any case, honoured from LTL_CONFIG, the command line overriding; SI when no format declares one)'
CONTRACT_DECLARE='features/608-byte-unit-ladder.md D7 and D12 (a format declares its byte notation in its spec; the Java GC format declares IEC)'
CONTRACT_MIXED='features/608-byte-unit-ladder.md D13 and D20 (IEC only when every file declares IEC, else SI with one notice; no notice under -bn; an unrecognised file declares nothing)'
CONTRACT_REACH='features/608-byte-unit-ladder.md D15 (the run notation reaches every byte string, the memory rows and the export included)'
CONTRACT_STRUCT='features/608-byte-unit-ladder.md D5 (one byte ladder; no sub keeps a table of its own), D8 (help rows interpolate the ladder lists) and D9/D18 (decimals are a field of the time-ladder step)'
CONTRACT_GC_IEC="features/609-gc-heap-suffix-convention.md D1 (the letter of a GC heap figure is an IEC prefix: K, M, G, T are KiB, MiB, GiB, TiB) and D2 (read on the one ladder at the notation the format declares, not the run output notation)"

pass=0
fail=0
failures=()
current_scenario=""

fail_with() {
    # fail_with LABEL ASSERTS PRODUCED_BY CONTRACT [DETAIL...]
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

pass_with() {
    echo "  PASS  $current_scenario :: $1"
    pass=$((pass + 1))
}

# run_ltl_in DIR TAG ARGS... — runs ltl inside DIR (the CSV files land
# there), stdout to DIR/TAG.out, stderr to DIR/TAG.err, exit code to
# DIR/TAG.rc, and applies the runtime-warning check.
run_ltl_in() {
    local dir="$1" tag="$2"; shift 2
    mkdir -p "$dir"
    set +e
    ( cd "$dir" && "$LTL" "$@" ) > "$dir/$tag.out" 2> "$dir/$tag.err"
    echo $? > "$dir/$tag.rc"
    set -e
    if ! assert_no_runtime_warnings "$dir/$tag.err" "$current_scenario/$tag"; then
        fail=$((fail + 1))
        failures+=("$current_scenario :: runtime warnings ($tag)")
    fi
}

# stats_cell DIR COLUMN — the COLUMN value of the STATS CSV's first data row;
# a missing file or column is reported as MISSING-ANCHOR (Trap 3/4).
stats_cell() {
    local dir="$1" column="$2" file
    file=$(ls "$dir"/*STATS*.csv 2>/dev/null | head -1)
    if [[ -z "$file" ]]; then
        echo "MISSING-ANCHOR:STATS-csv"
        return
    fi
    python3 - "$file" "$column" <<'PY'
import csv, sys
rows = list(csv.DictReader(open(sys.argv[1], newline='')))
if not rows or sys.argv[2] not in rows[0]:
    print("MISSING-ANCHOR:" + sys.argv[2])
else:
    print(rows[0][sys.argv[2]])
PY
}

# stats_column DIR COLUMN — the COLUMN value of every STATS CSV data row,
# joined by '|'; a missing file or column is reported as MISSING-ANCHOR.
stats_column() {
    local dir="$1" column="$2" file
    file=$(ls "$dir"/*STATS*.csv 2>/dev/null | head -1)
    if [[ -z "$file" ]]; then
        echo "MISSING-ANCHOR:STATS-csv"
        return
    fi
    python3 - "$file" "$column" <<'PY'
import csv, sys
rows = list(csv.DictReader(open(sys.argv[1], newline='')))
if not rows or sys.argv[2] not in rows[0]:
    print("MISSING-ANCHOR:" + sys.argv[2])
else:
    print('|'.join(r[sys.argv[2]] for r in rows))
PY
}

# expect_equal LABEL ACTUAL EXPECTED ASSERTS PRODUCED_BY CONTRACT
expect_equal() {
    local label="$1" actual="$2" expected="$3"
    if [[ "$actual" == "$expected" ]]; then
        pass_with "$label"
    else
        fail_with "$label" "$4" "$5" "$6" "expected: $expected" "actual:   $actual"
    fi
}

# notice_count DIR TAG — how many mixed-declaration notices the run printed
notice_count() {
    grep -c '^Note: the log formats of this run declare different byte notations' "$1/$2.err" || true
}

BOUNDARY_SI='999 B|1 kB|1 kB|1 kB|1 MB|1 MB|1 MB|1 MB|1.5 MB'
BOUNDARY_IEC='999 B|1000 B|1023 B|1 KiB|976.6 KiB|976.6 KiB|1 MiB|1 MiB|1.4 MiB'

# ---------------------------------------------------------------------------
# Criterion 6 — the climb compares the value against each step's byte count:
# 1000 bytes is 1 kB in SI and 1000 B in IEC, 1,000,000 is 1 MB in SI and
# 976.6 KiB in IEC.
# ---------------------------------------------------------------------------
scenario_value_climb() {
    current_scenario="value-climb"
    echo "[$current_scenario]"
    local n
    for n in si iec; do
        run_ltl_in "$TMP_DIR/climb-$n" run --disable-progress -ni -bs 1 -oe -o -bn "$n" "$BOUNDARY_FIXTURE"
    done
    expect_equal "SI cells for 999 B to 1.5 MB" "$(stats_column "$TMP_DIR/climb-si" bytes_nice)" "$BOUNDARY_SI" \
        'Under -bn si each size names the largest SI step it reaches: 1000, 1023 and 1024 bytes read 1 kB' \
        'format_bytes() in ltl' "$CONTRACT_CLIMB"
    expect_equal "IEC cells for 999 B to 1.4 MiB" "$(stats_column "$TMP_DIR/climb-iec" bytes_nice)" "$BOUNDARY_IEC" \
        'Under -bn iec 1000 and 1023 bytes stay in bytes and 1024 reads 1 KiB; 1,000,000 bytes reads 976.6 KiB' \
        'format_bytes() in ltl' "$CONTRACT_CLIMB"
}

# ---------------------------------------------------------------------------
# Criterion 7 — the rounding carry: 999,999 bytes is below 1 MB, but one
# decimal rounds it to 1000 kB, the next step's size, so it renders at that
# step: 1 MB (features/617-width-to-format-rule.md D19).
# ---------------------------------------------------------------------------
scenario_boundary_carry() {
    current_scenario="boundary-carry"
    echo "[$current_scenario]"
    run_ltl_in "$TMP_DIR/carry" run --disable-progress -ni -bs 1 -oe -o -bn si "$BOUNDARY_FIXTURE"
    local cell
    cell=$(stats_column "$TMP_DIR/carry" bytes_nice | cut -d'|' -f5)
    expect_equal "999,999 bytes renders 1 MB under SI" "$cell" "1 MB" \
        'A value whose rounding reaches the next step size renders at that step: 999,999 bytes rounds to 1000 kB at one decimal, so it reads 1 MB, never 1000 kB' \
        'format_bytes() in ltl' "$CONTRACT_CARRY"
}

# ---------------------------------------------------------------------------
# Criterion 8 (rendered half) — no option and no declaring format renders SI;
# -bn in any case and its long form select the notation; LTL_CONFIG carries
# it and the command line overrides it; an unknown value is a usage error.
# ---------------------------------------------------------------------------
scenario_notation_option() {
    current_scenario="notation-option"
    echo "[$current_scenario]"
    local common=(--disable-progress -ni -bs 1 -oe -o)
    run_ltl_in "$TMP_DIR/opt-none" run "${common[@]}" "$BOUNDARY_FIXTURE"
    expect_equal "no option renders SI" "$(stats_column "$TMP_DIR/opt-none" bytes_nice)" "$BOUNDARY_SI" \
        'A run whose formats declare no notation renders SI' 'resolve_byte_notation() + format_bytes() in ltl' "$CONTRACT_OPTION"
    local form tag
    for form in "-bn|iec" "-bn|IEC" "--byte-notation|iec"; do
        tag="opt-${form//[|-]/}"
        run_ltl_in "$TMP_DIR/$tag" run "${common[@]}" "${form%%|*}" "${form##*|}" "$BOUNDARY_FIXTURE"
        expect_equal "${form/|/ } renders IEC" "$(stats_column "$TMP_DIR/$tag" bytes_nice)" "$BOUNDARY_IEC" \
            'The option selects IEC in any case and in its long form' 'adapt_to_command_line_options() + resolve_byte_notation() in ltl' "$CONTRACT_OPTION"
    done
    LTL_CONFIG='-bn iec' run_ltl_in "$TMP_DIR/opt-env" run "${common[@]}" "$BOUNDARY_FIXTURE"
    expect_equal "LTL_CONFIG -bn iec renders IEC" "$(stats_column "$TMP_DIR/opt-env" bytes_nice)" "$BOUNDARY_IEC" \
        'The option is honoured from LTL_CONFIG' 'adapt_to_command_line_options() in ltl' "$CONTRACT_OPTION"
    LTL_CONFIG='-bn iec' run_ltl_in "$TMP_DIR/opt-env-cli" run "${common[@]}" -bn si "$BOUNDARY_FIXTURE"
    expect_equal "LTL_CONFIG -bn iec with -bn si renders SI" "$(stats_column "$TMP_DIR/opt-env-cli" bytes_nice)" "$BOUNDARY_SI" \
        'The command line overrides LTL_CONFIG' 'adapt_to_command_line_options() in ltl' "$CONTRACT_OPTION"

    run_ltl_in "$TMP_DIR/opt-bad" run --disable-progress -ni -bn xyz "$BOUNDARY_FIXTURE"
    if [[ "$(cat "$TMP_DIR/opt-bad/run.rc")" != 0 ]] \
        && grep -qF "Invalid byte notation 'xyz'. Valid values: si, iec" "$TMP_DIR/opt-bad/run.err"; then
        pass_with "-bn xyz exits non-zero naming si and iec"
    else
        fail_with "-bn xyz exits non-zero naming si and iec" \
            'An unknown notation is a usage error that names the two it accepts' \
            'adapt_to_command_line_options() in ltl' "$CONTRACT_OPTION" \
            "exit: $(cat "$TMP_DIR/opt-bad/run.rc")" "stderr: $(grep -i notation "$TMP_DIR/opt-bad/run.err" | head -1)"
    fi
}

# ---------------------------------------------------------------------------
# Criterion 9 (rendered half) — the Java GC format declares IEC, so a GC run
# with no option renders IEC; -bn si overrides the declaration.
# ---------------------------------------------------------------------------
scenario_format_declaration() {
    current_scenario="format-declaration"
    echo "[$current_scenario]"
    run_ltl_in "$TMP_DIR/decl" run --disable-progress -ni -bs 1440 -oe -o "$GC_FIXTURE"
    expect_equal "a GC run renders IEC" "$(stats_column "$TMP_DIR/decl" bytes_nice)" "68.2 GiB" \
        'The GC format declares IEC, and a run of its files alone renders in it' \
        'format_registry_specs() (the java_gc_g1 byte_notation) + resolve_byte_notation() in ltl' "$CONTRACT_DECLARE"
    run_ltl_in "$TMP_DIR/decl-si" run --disable-progress -ni -bs 1440 -oe -o -bn si "$GC_FIXTURE"
    expect_equal "a GC run under -bn si renders SI" "$(stats_column "$TMP_DIR/decl-si" bytes_nice)" "73.2 GB" \
        'The option overrides the format declaration' 'resolve_byte_notation() in ltl' "$CONTRACT_DECLARE"
}

# ---------------------------------------------------------------------------
# Criterion 10 — mixed declarations render SI with exactly one notice naming
# the formats and the option; one declaration throughout gives no notice;
# -bn silences it; a file no format recognises declares nothing.
# ---------------------------------------------------------------------------
scenario_mixed_declarations() {
    current_scenario="mixed-declarations"
    echo "[$current_scenario]"
    local common=(--disable-progress -ni -bs 1440 -oe -o)
    local plain="$TMP_DIR/plain-text.txt"
    printf 'first line of plain text\nsecond line of plain text\n' > "$plain"

    run_ltl_in "$TMP_DIR/mix" run "${common[@]}" "$GC_FIXTURE" "$BOUNDARY_FIXTURE"
    expect_equal "GC and access log render SI" "$(stats_column "$TMP_DIR/mix" bytes_nice)" "73.2 GB|5.6 MB" \
        'Files whose formats declare different notations render SI' 'resolve_byte_notation() in ltl' "$CONTRACT_MIXED"
    expect_equal "GC and access log print one notice" "$(notice_count "$TMP_DIR/mix" run)" "1" \
        'One notice for the run, not one per file' 'resolve_byte_notation() in ltl' "$CONTRACT_MIXED"
    if grep -qF 'java_gc_g1: IEC; access_common_duration: none); byte values are shown in SI units. Use -bn si or -bn iec to choose.' "$TMP_DIR/mix/run.err"; then
        pass_with "the notice names both formats' declarations and the option"
    else
        fail_with "the notice names both formats' declarations and the option" \
            'The notice says which format declares what, and how to choose' 'resolve_byte_notation() in ltl' "$CONTRACT_MIXED" \
            "stderr: $(grep '^Note: the log formats' "$TMP_DIR/mix/run.err" | head -1)"
    fi

    run_ltl_in "$TMP_DIR/twice" run "${common[@]}" "$GC_FIXTURE" "$GC_FIXTURE"
    expect_equal "GC twice renders IEC" "$(stats_column "$TMP_DIR/twice" bytes_nice)" "136.3 GiB" \
        'Every file declaring IEC renders IEC' 'resolve_byte_notation() in ltl' "$CONTRACT_MIXED"
    expect_equal "GC twice prints no notice" "$(notice_count "$TMP_DIR/twice" run)" "0" \
        'Files that agree print no notice' 'resolve_byte_notation() in ltl' "$CONTRACT_MIXED"

    run_ltl_in "$TMP_DIR/mix-bn" run "${common[@]}" -bn iec "$GC_FIXTURE" "$BOUNDARY_FIXTURE"
    expect_equal "the mixed pair under -bn iec renders IEC" "$(stats_column "$TMP_DIR/mix-bn" bytes_nice)" "68.2 GiB|5.3 MiB" \
        'The option decides over any declarations' 'resolve_byte_notation() in ltl' "$CONTRACT_MIXED"
    expect_equal "the mixed pair under -bn iec prints no notice" "$(notice_count "$TMP_DIR/mix-bn" run)" "0" \
        'With -bn given the declarations decide nothing, so there is nothing to say' 'resolve_byte_notation() in ltl' "$CONTRACT_MIXED"

    run_ltl_in "$TMP_DIR/gc-plain" run "${common[@]}" "$GC_FIXTURE" "$plain"
    expect_equal "GC beside an unrecognised file renders SI" "$(stats_column "$TMP_DIR/gc-plain" bytes_nice)" "73.2 GB" \
        'A file no format recognised declares nothing, so not every file declares IEC' 'resolve_byte_notation() in ltl' "$CONTRACT_MIXED"
    expect_equal "GC beside an unrecognised file prints one notice" "$(notice_count "$TMP_DIR/gc-plain" run)" "1" \
        'The unrecognised file counts as a disagreeing declaration' 'resolve_byte_notation() in ltl' "$CONTRACT_MIXED"
}

# ---------------------------------------------------------------------------
# Criterion 11 — one notation reaches every byte string of a run: the
# timeline bytes and byte-unit -udm columns, the heatmap scale, the histogram
# axis and markers, the STATS and MESSAGES cells, the memory rows and the
# export. Memory values vary between runs, so the unit token is read, not
# the number; the export's max_memory_used is the peak memory row's string.
# ---------------------------------------------------------------------------
scenario_one_notation_reach() {
    current_scenario="one-notation-reach"
    echo "[$current_scenario]"
    local n dir tokens foreign allowed peak exported
    for n in si iec; do
        dir="$TMP_DIR/reach-$n"
        run_ltl_in "$dir" run --disable-progress -ni -bs 1 -oe -o -hm bytes -hg bytes -mem --terminal-width 200 \
            -udm 'resp:B:max::/ 200 (\d+) /' -bn "$n" "$BOUNDARY_FIXTURE"
        tokens=$(cat "$dir/run.out" "$dir/run.err" "$dir"/*.csv "$dir"/*.yaml 2>/dev/null \
            | sed -E 's/\x1b\[[0-9;]*m//g' \
            | grep -oE '[0-9](\.[0-9]+)? ?(B|kB|KB|KiB|MB|MiB|GB|GiB|TB|TiB)\b' | sed -E 's/^[0-9.]+ ?//' | sort -u | tr '\n' ' ' || true)    # empty is judged below
        if [[ "$n" == si ]]; then allowed='^(B|kB|MB|GB|TB)$'; else allowed='^(B|KiB|MiB|GiB|TiB)$'; fi
        foreign=$(tr ' ' '\n' <<< "$tokens" | grep -v '^$' | grep -vE "$allowed" | tr '\n' ' ' || true)
        if [[ -n "$tokens" && "$tokens" != "B " && -z "$foreign" ]]; then
            pass_with "every byte string under -bn $n is $n ($tokens)"
        else
            fail_with "every byte string under -bn $n is $n" \
                'Every byte-valued surface of the run renders in the run notation' \
                'format_bytes() in ltl, the bytes arm of value_text(), reached from print_bar_graph(), the chart labels, print_summary_table() and write_aggregate_export()' \
                "$CONTRACT_REACH" "tokens: ${tokens:-none}" "foreign: ${foreign:-none}"
        fi
        peak=$(sed -E 's/\x1b\[[0-9;]*m//g' "$dir/run.out" | sed -nE 's/^ *MAXIMUM MEMORY USED +(.*[^ ]) *$/\1/p' | head -1 || true)       # empty is judged below
        exported=$(sed -nE 's/^ *max_memory_used: *//p' "$dir"/*.yaml 2>/dev/null | head -1 || true)
        if [[ -n "$peak" && "$peak" == "$exported" ]]; then
            pass_with "the export's max_memory_used is the peak memory row ($peak)"
        else
            fail_with "the export's max_memory_used is the peak memory row" \
                'The aggregate export carries the peak memory string the summary prints' \
                'print_summary_table() and write_aggregate_export() in ltl' "$CONTRACT_REACH" \
                "row: ${peak:-MISSING-ANCHOR}" "export: ${exported:-MISSING-ANCHOR}"
        fi
    done
}

# ---------------------------------------------------------------------------
# Criterion 5 — one byte ladder, read by every byte surface; no private byte
# table, byte multiplier or unit-keyed decimals table elsewhere; no literal
# unit list in print_help. Read from the source: the mechanism is the
# requirement, so it is checked where it lives.
# ---------------------------------------------------------------------------
scenario_one_ladder_structure() {
    current_scenario="one-ladder-structure"
    echo "[$current_scenario]"
    local report="$TMP_DIR/structure.txt"
    perl - "$LTL" > "$report" <<'PL'
use strict; use warnings;
open my $fh, '<', $ARGV[0] or die "cannot read $ARGV[0]: $!\n";
my @lines = <$fh>;
my (%sub_body, $cur, $in_ladder, @ladder_lines);
for my $i (0 .. $#lines) {
    my $l = $lines[$i];
    $cur = $1 if $l =~ /^sub (\w+)/;
    $sub_body{$cur} .= $l if defined $cur;
    undef $cur if defined $cur && $l =~ /^\}/;
    $in_ladder = 1 if $l =~ /^my \@byte_unit_ladder = \(/;
    push @ladder_lines, $i if $in_ladder;
    $in_ladder = 0 if $in_ladder && $l =~ /^\);/;
}
my %in_ladder = map { $_ => 1 } @ladder_lines;
# Every call passes its condition through scalar(): a failed match in list
# context is an empty list, which would shift the detail into the verdict.
my $check = sub { my ($name, $ok, $detail) = @_; print "CHECK\t$name\t", ($ok ? 'ok' : 'fail'), "\t", ($detail // ''), "\n"; };
my @decl = grep { /^my \@byte_unit_ladder\b/ } @lines;
$check->('one-ladder', @decl == 1 && @ladder_lines > 1, scalar(@decl) . ' declarations');
my @private = grep { /\bsub convert_bytes\b|%byte_units\b|%byte_unit_canonical\b/ } @lines;
$check->('no-private-byte-table', !@private, join(' | ', map { s/^\s+|\s+$//gr } @private));
my @tokens = grep { !$in_ladder{$_} && $lines[$_] =~ /'(?:kB|KB|MB|GB|TB|KiB|MiB|GiB|TiB)'/ } 0 .. $#lines;
$check->('byte-tokens-only-in-ladder', !@tokens, join(' | ', map { 'line ' . ($_ + 1) } @tokens));
my @mult = grep { !$in_ladder{$_} && $lines[$_] !~ /^\s*#/ && $lines[$_] =~ /1024\s*\*\*|=>\s*1024\b/ } 0 .. $#lines;
$check->('byte-multipliers-only-in-ladder', !@mult, join(' | ', map { 'line ' . ($_ + 1) } @mult));
my @dec = grep { $lines[$_] !~ /^\s*#/ && $lines[$_] =~ /\b(?:ns|us)\s*=>\s*\d/ } 0 .. $#lines;
$check->('no-unit-keyed-decimals-table', !@dec, join(' | ', map { 'line ' . ($_ + 1) } @dec));
$check->('unit-slot-reads-ladder', scalar(($sub_body{parse_udm_configs} // '') =~ /byte_unit_canonical\(/ && ($sub_body{parse_udm_configs} // '') =~ /\$byte_unit_bytes\{/) ? 1 : 0, 'parse_udm_configs');
$check->('formatter-reads-ladder', scalar(($sub_body{format_bytes} // '') =~ /\@byte_unit_ladder|\$byte_unit_ladder\[/) ? 1 : 0, 'format_bytes');
$check->('gc-reader-reads-ladder', scalar(($sub_body{gc_heap_size_bytes} // '') =~ /byte_prefix_bytes\(\$letter, \$notation\)/
                                    && ($sub_body{byte_prefix_bytes} // '') =~ /\$byte_unit_by_prefix\{/
                                    && grep { /^my %byte_unit_by_prefix\s*=.*\@byte_unit_ladder;/ } @lines) ? 1 : 0, 'gc_heap_size_bytes -> byte_prefix_bytes -> %byte_unit_by_prefix, a view of @byte_unit_ladder');
my @letters = grep { $lines[$_] !~ /^\s*#/ && $lines[$_] =~ /\b[KMGT]\s*=>\s*(?:'[kKMGT]i?B'|\d)/ } 0 .. $#lines;   # a prefix letter mapped to a byte token or a multiplier
$check->('no-prefix-letter-table', !@letters, join(' | ', map { 'line ' . ($_ + 1) } @letters));
$check->('gc-transform-reads-declared-notation', scalar(grep { /^\s*gc_heap_delta\s*=>.*gc_heap_size_bytes\( \$heap_from, 'BYTE_NOTATION' \)/ } @lines) ? 1 : 0, 'the gc_heap_delta snippet passes the entry byte_notation');
$check->('display-decimals-from-step', scalar(($sub_body{format_time} // '') =~ /\$time_unit_step\{\s*\$opt\{resolution\}\s*\}\{decimals\}/) ? 1 : 0, 'format_time');
$check->('csv-decimals-from-step', scalar(($sub_body{adapt_to_command_line_options} // '') =~ /\$time_unit_step\{\$duration_unit_resolved\}\{decimals\}/) ? 1 : 0, 'adapt_to_command_line_options');
my $help = $sub_body{print_help} // '';
my @lit = grep { $help =~ /$_/ } ('ns, us, ms', 'kB, MB', 'KiB, MiB', 'B, kB');
$check->('help-has-no-unit-literal', length($help) && !@lit, join(' | ', @lit));
PL
    local name status detail
    local -a expected=(one-ladder no-private-byte-table byte-tokens-only-in-ladder byte-multipliers-only-in-ladder
                       no-unit-keyed-decimals-table unit-slot-reads-ladder formatter-reads-ladder gc-reader-reads-ladder
                       no-prefix-letter-table gc-transform-reads-declared-notation
                       display-decimals-from-step csv-decimals-from-step help-has-no-unit-literal)
    for name in "${expected[@]}"; do
        IFS=$'\t' read -r _ _ status detail < <(awk -F'\t' -v n="$name" '$1 == "CHECK" && $2 == n' "$report") || true
        if [[ "$status" == ok ]]; then
            pass_with "$name"
        else
            fail_with "$name" \
                'The byte vocabulary lives in one ladder that every byte surface reads; decimals live on the time-ladder step; help rows carry no literal unit list' \
                'the source of ltl (@byte_unit_ladder, @time_unit_ladder, print_help)' "$CONTRACT_STRUCT" \
                "status: ${status:-MISSING-ANCHOR}" "detail: ${detail:-}"
        fi
        status=""; detail=""
    done
}

# ---------------------------------------------------------------------------
# Criterion 15 — the step's decimals are the source's resolution relative to
# millisecond storage: -V csv-output reports 6 under -du ns, 3 under -du us,
# 0 under -du ms and -du m; -cp 9 gives nine back.
# ---------------------------------------------------------------------------
scenario_ladder_decimals() {
    current_scenario="ladder-decimals"
    echo "[$current_scenario]"
    local row unit want dir got
    for row in "ns|6" "us|3" "ms|0" "m|0"; do
        IFS='|' read -r unit want <<< "$row"
        dir="$TMP_DIR/decimals-$unit"
        run_ltl_in "$dir" run --disable-progress -ni -bs 1440 -oe -o -du "$unit" -V csv-output "$BOUNDARY_FIXTURE"
        got=$(sed -nE 's/^decimals_duration: //p' "$dir/run.out" | head -1)
        expect_equal "-du $unit: decimals_duration $want" "${got:-MISSING-ANCHOR}" "$want" \
            'The CSV duration family takes the resolved unit step decimals' \
            'adapt_to_command_line_options() in ltl ($time_unit_step{...}{decimals})' "$CONTRACT_STRUCT"
    done
    dir="$TMP_DIR/decimals-cp9"
    run_ltl_in "$dir" run --disable-progress -ni -bs 1440 -oe -o -du us -cp 9 -V csv-output "$BOUNDARY_FIXTURE"
    got=$(sed -nE 's/^decimals_duration: //p' "$dir/run.out" | head -1)
    expect_equal "-du us -cp 9: decimals_duration 9" "${got:-MISSING-ANCHOR}" "9" \
        'Higher precision for follow-up analysis is -cp, not a different default' \
        'adapt_to_command_line_options() in ltl' "$CONTRACT_STRUCT"
}

# ---------------------------------------------------------------------------
# 609 AC1, AC2, AC4 — a GC heap figure's letter is an IEC prefix, read at the
# notation the format declares. The fixture's five transitions, all in M, sum
# to 69,786 MiB: 73,175,924,736 bytes. The run exiting 0 is also the GC
# entry's self-validation passing: its sample rows (2433M->66M expecting
# 2481979392, 512M->128M expecting 402653184) are checked on every
# invocation, and a mismatch ends the run. Under -bn si the same bytes are
# read and only the rendering changes: the letters follow the format's
# declaration, not the run's output notation.
# ---------------------------------------------------------------------------
scenario_gc_heap_figures_iec() {
    current_scenario="gc-heap-figures-iec"
    echo "[$current_scenario]"
    local dir="$TMP_DIR/gc" rc
    run_ltl_in "$dir" gc --disable-progress -ni -bs 1440 -oe -o "$GC_FIXTURE"
    rc=$(cat "$dir/gc.rc")
    if [[ "$rc" == 0 ]]; then
        pass_with "the run exits 0: the GC entry's self-validation rows pass"
    else
        fail_with "the run exits 0: the GC entry's self-validation rows pass" \
            'The GC entry sample 2433M->66M extracts 2481979392 bytes and 512M->128M 402653184; a self-validation mismatch ends the run' \
            'build_format_registry() self-validation in ltl, over the gc_heap_delta transform and gc_heap_size_bytes()' \
            "$CONTRACT_GC_IEC" "exit: $rc" "stderr: $(head -3 "$dir/gc.err")"
    fi
    expect_equal "STATS bytes total is 73175924736" "$(stats_cell "$dir" bytes)" "73175924736" \
        'The five heap transitions in M sum to 69,786 MiB: M is read as 1024 squared bytes' \
        'gc_heap_size_bytes() via the gc_heap_delta transform in ltl' "$CONTRACT_GC_IEC"
    expect_equal "STATS bytes_nice is 68.2 GiB" "$(stats_cell "$dir" bytes_nice)" "68.2 GiB" \
        'The GC total renders in the IEC notation the format declares' \
        'format_bytes() in ltl' "$CONTRACT_GC_IEC"

    run_ltl_in "$TMP_DIR/gc-si" gc --disable-progress -ni -bs 1440 -oe -o -bn si "$GC_FIXTURE"
    expect_equal "-bn si: STATS bytes total is still 73175924736" "$(stats_cell "$TMP_DIR/gc-si" bytes)" "73175924736" \
        'The letters are read at the notation the format declares; the run output notation changes only the rendering' \
        'gc_heap_size_bytes() via the gc_heap_delta transform in ltl (BYTE_NOTATION filled from the entry at compile)' "$CONTRACT_GC_IEC"
}

# ---------------------------------------------------------------------------
# 609 AC3 — every step of the ladder is a prefix the GC figures accept: one
# 3X->1X transition per letter frees 2 KiB, 2 MiB, 2 GiB and 2 TiB.
# ---------------------------------------------------------------------------
scenario_gc_heap_prefixes() {
    current_scenario="gc-heap-prefixes"
    echo "[$current_scenario]"
    run_ltl_in "$TMP_DIR/prefix" run --disable-progress -ni -bs 1 -oe -o "$GC_PREFIX_FIXTURE"
    expect_equal "K, M, G, T read as KiB, MiB, GiB, TiB" "$(stats_column "$TMP_DIR/prefix" bytes)" \
        "2048|2097152|2147483648|2199023255552" \
        'Each letter is the IEC step of the byte ladder it prefixes: 1024, 1024^2, 1024^3, 1024^4 bytes' \
        'gc_heap_size_bytes() and byte_prefix_bytes() in ltl' "$CONTRACT_GC_IEC"
}

scenario_register one-ladder-structure \
                  value-climb \
                  boundary-carry \
                  notation-option \
                  format-declaration \
                  mixed-declarations \
                  one-notation-reach \
                  ladder-decimals \
                  gc-heap-figures-iec \
                  gc-heap-prefixes
scenario_parse_args "$@"

while read -r _scenario; do
    case "$_scenario" in
        one-ladder-structure    ) scenario_one_ladder_structure ;;
        value-climb             ) scenario_value_climb ;;
        boundary-carry          ) scenario_boundary_carry ;;
        notation-option         ) scenario_notation_option ;;
        format-declaration      ) scenario_format_declaration ;;
        mixed-declarations      ) scenario_mixed_declarations ;;
        one-notation-reach      ) scenario_one_notation_reach ;;
        ladder-decimals         ) scenario_ladder_decimals ;;
        gc-heap-figures-iec     ) scenario_gc_heap_figures_iec ;;
        gc-heap-prefixes        ) scenario_gc_heap_prefixes ;;
    esac
done < <(scenario_selected)

# ---------------------------------------------------------------------------
echo
echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    printf '  %s\n' "${failures[@]}"
    exit 1
fi
exit 0
