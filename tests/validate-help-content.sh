#!/usr/bin/env bash
# validate-help-content.sh — Validate that every flag declared in
# GetOptions appears in print_help() (and in docs/usage.md), with the
# stated exceptions for hidden flags; and that the version string
# emitted by `-v` / `-V benchmark-data` matches the in-source
# $version_number literal.
# Usage: ./tests/validate-help-content.sh
#
# Sibling to validate-help-layout.sh (visual column alignment). This
# harness covers content correctness, which has a documented history
# of drift (CLAUDE.md § Before writing or changing code: a new option updates print_help() and docs/usage.md in the same commit).
#
# Implements the self-documenting-assertion design from
# tests/HARNESS-DESIGN.md. Every assertion records:
#   - asserts:     the application invariant being tested
#   - produced_by: where in ltl the invariant is produced (function name)
#   - contract:    the stability contract that makes it stable
# All three are surfaced on failure so the reader can act without
# opening external docs. Reference: tests/validate-histogram-bin-counters.sh.
#
# Sub-task of issue #225. Issue #232.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib/logs-dir.sh
source "$SCRIPT_DIR/lib/logs-dir.sh"
LTL="$REPO_DIR/ltl"
USAGE_MD="$REPO_DIR/docs/usage.md"
# Test log: tiny clean access log (~83 KB). Per repo memory
# (feedback_test_logs.md) avoid the corrupt 2025-03-21 file; Codebeamer's
# log is the smallest clean fixture available.
TEST_LOG="$LOGS_DIR/Codebeamber/codebeamer_access_log.2025-10-29.txt"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"

# Ambient FORCE_COLOR/NO_COLOR must not decide what this harness asserts
# against (tests/HARNESS-DESIGN.md section Colour rendering is controlled,
# never inherited; issue #438).
neutralize_colour_env


# Temp dir for captured outputs; cleaned up on EXIT (HARNESS-DESIGN.md Trap 10).
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"
    exit 1
fi
if [[ ! -f "$USAGE_MD" ]]; then
    echo "ERROR: docs/usage.md not found: $USAGE_MD"
    exit 1
fi
if [[ ! -f "$TEST_LOG" ]]; then
    echo "ERROR: test log not found: $TEST_LOG"
    exit 1
fi

pass=0
fail=0
warn=0
failures=()
current_scenario=""

# Runtime-warning cleanliness for a captured ltl stderr file
# (HARNESS-DESIGN.md section Runtime-warning cleanliness, issue #341).
# Silent when clean; the shared helper prints the failure block.
check_stderr_warnings() {
    local stderr_file="$1"
    local context="$2"
    if ! assert_no_runtime_warnings "$stderr_file" "$context"; then
        fail=$((fail + 1))
        failures+=("$context :: perl-runtime-warnings-on-stderr")
    fi
}

# Self-documenting assertion: a line matching `pattern` must be present.
# Required named fields: pattern, asserts, produced_by, contract.
# On failure, all four are surfaced alongside the captured output path.
assert_line() {
    local outfile="$1"
    shift
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

    if grep -qE "$pattern" "$outfile"; then
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

# Self-documenting assertion: every element in $required must appear
# in $haystack (both newline-separated lists held in files).
# Failure surfaces the missing elements alongside the documentation fields.
assert_all_present() {
    local required_file="$1"
    local haystack_file="$2"
    shift 2
    local label asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            label)       label="$2";       shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_all_present: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${label:?assert_all_present requires label}"
    : "${asserts:?assert_all_present requires asserts}"
    : "${produced_by:?assert_all_present requires produced_by}"
    : "${contract:?assert_all_present requires contract}"

    # Missing = required - haystack. Both files are newline-separated.
    local missing
    missing=$(grep -F -v -x -f "$haystack_file" "$required_file" || true)
    if [[ -z "$missing" ]]; then
        echo "  PASS  $current_scenario :: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        label:       $label"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        echo "        missing:     $(echo "$missing" | tr '\n' ' ' | sed 's/  *$//')"
        fail=$((fail + 1))
        failures+=("$current_scenario :: $label :: missing $(echo "$missing" | tr '\n' ',' | sed 's/,$//')")
    fi
}

# Self-documenting equality assertion. Both values are simple strings.
assert_equal() {
    local actual="$1"
    local expected="$2"
    shift 2
    local label asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            label)       label="$2";       shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_equal: unknown field '$1'"; exit 2 ;;
        esac
    done

    if [[ "$actual" == "$expected" ]]; then
        echo "  PASS  $current_scenario :: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        label:       $label"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        echo "        expected:    $expected"
        echo "        actual:      $actual"
        fail=$((fail + 1))
        failures+=("$current_scenario :: $label (expected=$expected actual=$actual)")
    fi
}

# Self-documenting soft warning. Same field shape as an assertion but
# does not increment fail/pass.
emit_warning() {
    local label asserts produced_by contract detail
    while [[ $# -gt 0 ]]; do
        case "$1" in
            label)       label="$2";       shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            detail)      detail="$2";      shift 2 ;;
            *) echo "emit_warning: unknown field '$1'"; exit 2 ;;
        esac
    done
    echo "  WARN  $current_scenario :: $label"
    echo "        asserts:     $asserts"
    echo "        produced_by: $produced_by"
    echo "        contract:    $contract"
    echo "        detail:      $detail"
    warn=$((warn + 1))
}

# ---------- Extract from ltl source --------------------------------------

# $version_number literal. Required for scenarios D and E.
VERSION_NUMBER=$(perl -ne '
    if (/^my\s+\$version_number\s*=\s*"([^"]+)"/) { print $1; exit }
' "$LTL")
if [[ -z "$VERSION_NUMBER" ]]; then
    echo "ERROR: could not extract \$version_number from $LTL"
    exit 1
fi

# GetOptions entries. Each line of output is TAB-separated:
#   long-name<TAB>short-or-empty<TAB>hidden-flag(0|1)
# Short forms are distinguished from long forms by the absence of `-`.
# `# hidden` annotation on the line marks intentionally hidden flags.
GETOPTS_TSV="$TMP_DIR/getopts.tsv"
perl -ne '
    BEGIN { $in_block = 0 }
    if (/GetOptions\(/)         { $in_block = 1; next }
    # End of the GetOptions(...) call: either a trailing `) or die ...` or the
    # closing `);` on its own line (the call is wrapped in a warning-capturing
    # do-block). Mid-line `);` inside single-line option callbacks is not at
    # line start, so `^\s*\);` only matches the real close.
    if ($in_block && (/\)\s*or\s+die/ || /^\s*\);\s*$/)) { $in_block = 0; next }
    next unless $in_block;
    next if /^\s*$/ || /^\s*#/;
    next unless /^\s*[\x27"]([^\x27"]+)[\x27"]\s*=>/;
    my $spec = $1;
    my $hidden = (/#\s*hidden\b/) ? 1 : 0;
    (my $names = $spec) =~ s/[=:].*$//;
    my @parts = split /\|/, $names;
    my ($long, $short);
    if (@parts == 1) {
        $long = $parts[0];
    } else {
        # In every two-token GetOptions name in this codebase, the long
        # form is the longer string. This holds for the short-first
        # declarations (e.g. hgb, dmp, ep) where the *full* spelling is on
        # the right of the pipe but is still the longer string. length-based
        # pick is robust where the hyphen heuristic was not (e.g., pause|p,
        # start|st, end|et — long forms with no hyphen and length < 6).
        my @sorted = sort { length($b) <=> length($a) } @parts;
        $long  = $sorted[0];
        $short = $sorted[1];
    }
    $short //= "";
    print join("\t", $long, $short, $hidden), "\n";
' "$LTL" > "$GETOPTS_TSV"

GETOPTS_COUNT=$(wc -l < "$GETOPTS_TSV" | tr -d ' ')
if [[ "$GETOPTS_COUNT" -lt 50 ]]; then
    echo "ERROR: parsed only $GETOPTS_COUNT GetOptions entries - parser likely broken"
    head "$GETOPTS_TSV"
    exit 1
fi

# Required-form files for set assertions.
VISIBLE_LONGS_FILE="$TMP_DIR/visible-longs.txt"
HIDDEN_LONGS_FILE="$TMP_DIR/hidden-longs.txt"
VISIBLE_SHORTS_FILE="$TMP_DIR/visible-shorts.txt"

# `help` is special-cased — its short forms are non-Getopt PreProcessor
# aliases (`-?`, `/help`) and the GetOptions key is just `help`. The harness
# treats it as out-of-band for set assertions.
awk -F'\t' '$3 == 0 && $1 != "help" { print $1 }' "$GETOPTS_TSV" | sort -u > "$VISIBLE_LONGS_FILE"
awk -F'\t' '$3 == 1                 { print $1 }' "$GETOPTS_TSV" | sort -u > "$HIDDEN_LONGS_FILE"
awk -F'\t' '$3 == 0 && $1 != "help" && $2 != "" { print $2 }' "$GETOPTS_TSV" | sort -u > "$VISIBLE_SHORTS_FILE"

# ---------- Capture --help -----------------------------------------------

HELP_OUT="$TMP_DIR/help.txt"
HELP_LONGS_FILE="$TMP_DIR/help-longs.txt"
HELP_SHORTS_FILE="$TMP_DIR/help-shorts.txt"

# Pin terminal width for deterministic capture (matches validate-help-layout.sh).
# HARNESS-DESIGN.md Trap 1: preserve stderr, check exit code.
set +e
"$LTL" --disable-progress -ni --terminal-width 160 --help > "$HELP_OUT" 2>"$TMP_DIR/help.stderr"
help_ec=$?
set -e
if [[ "$help_ec" -ne 0 ]]; then
    echo "ERROR: ltl --help exited $help_ec; stderr:"
    sed 's/^/    /' "$TMP_DIR/help.stderr"
    exit 1
fi
if [[ ! -s "$HELP_OUT" ]]; then
    echo "ERROR: ltl --help produced empty output"
    exit 1
fi
check_stderr_warnings "$TMP_DIR/help.stderr" "capture:--help"

# Strip ANSI escapes from the help output (print_help colorizes).
perl -i -pe 's/\e\[[0-9;]*[a-zA-Z]//g' "$HELP_OUT"

# Extract every --<long-name> and -<short> token from the help text.
perl -ne 'while (/(--[a-zA-Z][a-zA-Z0-9-]*)/g) { (my $t = $1) =~ s/^--//; print "$t\n" }' "$HELP_OUT" | sort -u > "$HELP_LONGS_FILE"
perl -ne 'while (/(?:^|\s)(-[a-zA-Z][a-zA-Z0-9]*)(?=[,\s])/g) { (my $t = $1) =~ s/^-//; print "$t\n" }' "$HELP_OUT" | sort -u > "$HELP_SHORTS_FILE"

# ---------- Capture docs/usage.md tokens ---------------------------------

USAGE_LONGS_FILE="$TMP_DIR/usage-longs.txt"
perl -ne 'while (/(--[a-zA-Z][a-zA-Z0-9-]*)/g) { (my $t = $1) =~ s/^--//; print "$t\n" }' "$USAGE_MD" | sort -u > "$USAGE_LONGS_FILE"

# ---------- Scenarios -----------------------------------------------------

scenario_A_help_contains_all_visible_longs() {
    current_scenario="A-help-contains-visible-longs"
    echo "[$current_scenario]"

    assert_all_present "$VISIBLE_LONGS_FILE" "$HELP_LONGS_FILE" \
        label       'every non-hidden GetOptions long-form appears in --help output' \
        asserts     'For every option declared in GetOptions that is NOT annotated `# hidden`, print_help() must document the option by its long name. Drift here means a user-visible flag is documented in code but missing from --help.' \
        produced_by 'print_help() in ltl - must add a $opt->("-short, --long ...", "description") line for every non-hidden GetOptions entry' \
        contract    'features/232-help-coverage.md section 3 + section 8 - hidden flags are annotated `# hidden` in GetOptions; everything else must appear in --help'
}

scenario_B_usage_contains_all_visible_longs() {
    current_scenario="B-usage-contains-visible-longs"
    echo "[$current_scenario]"

    assert_all_present "$VISIBLE_LONGS_FILE" "$USAGE_LONGS_FILE" \
        label       'every non-hidden GetOptions long-form appears in docs/usage.md' \
        asserts     'docs/usage.md is the canonical wiki source per CLAUDE.md (overwritten on each release); every non-hidden flag must appear there. The -hgb doc bug found during research (declared, in print_help, missing from usage.md) is exactly this class.' \
        produced_by 'docs/usage.md option tables - manually maintained, must be updated alongside any non-hidden flag addition' \
        contract    'docs/process/workflow.md section Post-release (wiki sync) + features/232-help-coverage.md section 3 - usage.md is part of the user-facing contract'
}

scenario_C_help_short_forms_match_getopts() {
    current_scenario="C-help-short-forms-match-getopts"
    echo "[$current_scenario]"

    assert_all_present "$VISIBLE_SHORTS_FILE" "$HELP_SHORTS_FILE" \
        label       'every short form declared in GetOptions appears in --help output' \
        asserts     'When a flag has both -short and --long forms in GetOptions, print_help() must document both. A long form documented without its short form (or vice versa) is content drift.' \
        produced_by 'print_help() $opt->() call site - first arg should be "-short, --long" not just "--long"' \
        contract    'features/232-help-coverage.md section 8 - every GetOptions entry with a short form must surface that short form in help'
}

scenario_D_dash_v_matches_version_number() {
    current_scenario="D-dash-v-matches-version-number"
    echo "[$current_scenario]"

    local vout="$TMP_DIR/dash-v.txt"
    set +e
    "$LTL" --disable-progress -ni -v > "$vout" 2>"$vout.stderr"
    local ec=$?
    set -e
    check_stderr_warnings "$vout.stderr" "$current_scenario"
    if [[ "$ec" -ne 0 ]]; then
        echo "  FAIL  $current_scenario"
        echo "        label:       ltl -v exited non-zero ($ec)"
        echo "        asserts:     ltl -v exits 0 and emits the version string"
        echo "        produced_by: print_version() in ltl"
        echo "        contract:    features/232-help-coverage.md section 4 - -v is one of three in-binary version-emission sites that must agree with \$version_number"
        echo "        (captured in $vout)"
        fail=$((fail + 1))
        failures+=("$current_scenario :: ltl -v non-zero exit")
        return
    fi

    assert_line "$vout" \
        pattern     "^Version: ${VERSION_NUMBER}$" \
        asserts     "The -v flag emits 'Version: ${VERSION_NUMBER}' matching the \$version_number literal in ltl source. This is one of three in-binary emission sites; all must agree." \
        produced_by 'print_version() in ltl' \
        contract    'features/232-help-coverage.md section 4 - version string emission sites are stability-contracted to agree with $version_number'
}

scenario_E_benchmark_data_section_matches_version_number() {
    current_scenario="E-benchmark-data-version-matches"
    echo "[$current_scenario]"

    local bout="$TMP_DIR/benchmark-data.txt"
    set +e
    # Shape: only the section's version field is read (HARNESS-DESIGN.md
    # section Invocation coherence).
    "$LTL" --disable-progress -ni -bs 1440 -oe -n 1 -osum -V benchmark-data "$TEST_LOG" > "$bout" 2>"$bout.stderr"
    local ec=$?
    set -e
    check_stderr_warnings "$bout.stderr" "$current_scenario"
    if [[ "$ec" -ne 0 ]]; then
        echo "  FAIL  $current_scenario"
        echo "        label:       ltl -V benchmark-data exited non-zero ($ec)"
        echo "        asserts:     ltl -V benchmark-data <log> exits 0 and emits the benchmark-data section"
        echo "        produced_by: print_verbose_output() in ltl (benchmark-data section dispatch)"
        echo "        contract:    Issue #226 framework + tests/HARNESS-DESIGN.md section Reserved section names - benchmark-data is a reserved section"
        echo "        (captured in $bout)"
        fail=$((fail + 1))
        failures+=("$current_scenario :: ltl -V benchmark-data non-zero exit")
        return
    fi

    # HARNESS-DESIGN.md Trap 3: check the start anchor before consuming the body.
    assert_line "$bout" \
        pattern     '^=== benchmark-data ===$' \
        asserts     'The benchmark-data section header is emitted when requested via -V benchmark-data' \
        produced_by 'print_verbose_output() in ltl (benchmark-data emitter)' \
        contract    'tests/HARNESS-DESIGN.md section Delimiter contract + Reserved section names - section header is stability-contracted'

    # End-marker presence check before extracting body (HARNESS-DESIGN.md Trap 3).
    assert_line "$bout" \
        pattern     '^=== END benchmark-data ===$' \
        asserts     'The benchmark-data section is closed with the required end marker per the delimiter contract' \
        produced_by 'print_verbose_output() in ltl (benchmark-data emitter)' \
        contract    'tests/HARNESS-DESIGN.md section Delimiter contract - end markers are required'

    # Extract the section body and assert the version row matches.
    local body
    body=$(sed -n '/^=== benchmark-data ===$/,/^=== END benchmark-data ===$/p' "$bout")
    if [[ -z "$body" ]]; then
        echo "  FAIL  $current_scenario"
        echo "        label:       benchmark-data body extraction returned empty"
        echo "        asserts:     The body between '=== benchmark-data ===' and '=== END benchmark-data ===' must contain the version TSV row"
        echo "        produced_by: print_verbose_output() in ltl (benchmark-data TSV row writer)"
        echo "        contract:    features/232-help-coverage.md section 4 + tests/HARNESS-DESIGN.md section Stability contract - version row format is locked"
        echo "        (captured in $bout)"
        fail=$((fail + 1))
        failures+=("$current_scenario :: benchmark-data body empty")
        return
    fi

    local body_file="$TMP_DIR/benchmark-data.body.txt"
    printf '%s\n' "$body" > "$body_file"
    assert_line "$body_file" \
        pattern     "^version	${VERSION_NUMBER}$" \
        asserts     "The benchmark-data section's 'version' TSV row matches the \$version_number literal. This is the second of three in-binary emission sites; all must agree." \
        produced_by 'print_verbose_output() in ltl (benchmark-data TSV row writer)' \
        contract    'features/232-help-coverage.md section 4 + tests/HARNESS-DESIGN.md section Stability contract - version row format is locked'
}

# Issue #567 criterion 16 (567 D7): one -d, --discard <name> entry in --help
# and docs/usage.md alike.
scenario_I_discard_option_rows() {
    current_scenario="I-discard-option-rows"
    echo "[$current_scenario]"

    local help_out="$TMP_DIR/help-discard.txt"
    "$LTL" --disable-progress -ni --terminal-width 400 --help > "$help_out" 2>"$help_out.stderr" || true
    check_stderr_warnings "$help_out.stderr" "$current_scenario"
    perl -i -pe 's/\e\[[0-9;]*[a-zA-Z]//g' "$help_out"

    assert_line "$help_out" \
        pattern     '^\s+-d,\s+--discard <name>\s+Remove a named part of the line' \
        asserts     '--help carries one -d, --discard <name> row describing what the option removes' \
        produced_by 'print_help() in ltl (the -d row after the -x row)' \
        contract    'features/567-discard-named-values-from-message.md section Decisions D7 - one option names anything to discard, with one help entry'
    assert_equal "$(grep -c -- '--discard <name>' "$help_out")" "1" \
        label       'exactly one --discard <name> row in --help' \
        asserts     'The option is documented once, not once per name it accepts' \
        produced_by 'print_help() in ltl' \
        contract    'features/567-discard-named-values-from-message.md section Decisions D7'

    assert_line "$USAGE_MD" \
        pattern     '^\| `-d, --discard <name>` \| Remove a named part of the line' \
        asserts     'docs/usage.md carries the -d, --discard <name> row' \
        produced_by 'docs/usage.md option table - manually maintained alongside print_help()' \
        contract    'CLAUDE.md section Before writing or changing code (help and usage.md edited together)'
    assert_equal "$(grep -c -- '`-d, --discard <name>`' "$USAGE_MD")" "1" \
        label       'exactly one --discard row in docs/usage.md' \
        asserts     'The option has one row in the user documentation, matching --help' \
        produced_by 'docs/usage.md option table' \
        contract    'features/567-discard-named-values-from-message.md section Decisions D7'
}

scenario_F_description_quality_warnings() {
    current_scenario="F-description-quality (soft)"
    echo "[$current_scenario]"

    # Extract every $opt->("flags", "description") tuple from print_help()
    # in the ltl source and apply two description-quality heuristics:
    #   H1: placeholder tokens (TODO / FIXME / XXX / undocumented / TBD / tk / ???)
    #   H2: single-word descriptions
    local warnings_tsv="$TMP_DIR/desc-warnings.tsv"
    perl -ne '
        # Multi-line aware: read whole file, find $opt->("…", "…") calls
        BEGIN { $/ = undef; $data = "" }
        $data .= $_;
        END {
            while ($data =~ /\$opt->\(\s*"([^"]*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*\)/g) {
                my ($flags, $desc) = ($1, $2);
                $desc =~ s/\\"/"/g;
                $desc =~ s/\\\\/\\/g;
                # H1: placeholder tokens.
                if ($desc =~ /\b(?:TODO|FIXME|XXX|undocumented|TBD|tk|\?\?\?)\b/i) {
                    print "H1\t$flags\t$desc\n";
                }
                # H2: single-word.
                my @words = split /\s+/, $desc;
                if (@words < 2) {
                    print "H2\t$flags\t$desc\n";
                }
            }
        }
    ' "$LTL" > "$warnings_tsv"

    if [[ ! -s "$warnings_tsv" ]]; then
        echo "  PASS  $current_scenario :: no placeholder tokens or single-word descriptions found"
        pass=$((pass + 1))
        return
    fi

    while IFS=$'\t' read -r heur flags desc; do
        case "$heur" in
            H1)
                emit_warning \
                    label       "placeholder token in help description: $flags" \
                    asserts     'Help descriptions must not contain placeholder tokens (TODO/FIXME/XXX/undocumented/TBD/tk/???); these indicate unfinished documentation.' \
                    produced_by 'print_help() $opt->() call site for this flag' \
                    contract    'features/232-help-coverage.md section 5 heuristic 1 - placeholder-token check is locked as a hard signal of unfinished work' \
                    detail      "flags='$flags' desc='$desc'"
                ;;
            H2)
                emit_warning \
                    label       "single-word description: $flags" \
                    asserts     'Help descriptions should be at least two words; single-word descriptions are usually tautological or truncated.' \
                    produced_by 'print_help() $opt->() call site for this flag' \
                    contract    'features/232-help-coverage.md section 5 heuristic 2 - single-word descriptions are soft signal of drift' \
                    detail      "flags='$flags' desc='$desc'"
                ;;
        esac
    done < "$warnings_tsv"

    echo "  INFO  $current_scenario :: $warn warning(s) (soft; non-blocking)"
}

# ---------- Run -----------------------------------------------------------

echo "Validating help content correctness (issue #232)"
echo "  ltl:       $LTL"
echo "  version:   $VERSION_NUMBER (from \$version_number literal)"
printf "  getopts:   %d entries (%d visible, %d hidden)\n" \
    "$GETOPTS_COUNT" \
    "$(wc -l < "$VISIBLE_LONGS_FILE" | tr -d ' ')" \
    "$(wc -l < "$HIDDEN_LONGS_FILE"  | tr -d ' ')"
echo ""

# Issue #580 criterion 13: one -m, --mask <name> entry, no -uuid row (D8), and
# the -g entry advising --mask uuid, in --help and docs/usage.md alike.
scenario_H_mask_option_rows() {
    current_scenario="H-mask-option-rows"
    echo "[$current_scenario]"

    local help_out="$TMP_DIR/help-mask.txt"
    "$LTL" --disable-progress -ni --terminal-width 400 --help > "$help_out" 2>"$help_out.stderr" || true
    check_stderr_warnings "$help_out.stderr" "$current_scenario"
    perl -i -pe 's/\e\[[0-9;]*[a-zA-Z]//g' "$help_out"

    assert_line "$help_out" \
        pattern     '^\s+-m,\s+--mask <name>\s+Replace an identifier' \
        asserts     '--help carries one -m, --mask <name> row describing the placeholder masking' \
        produced_by 'print_help() in ltl (the -m row after the -g row)' \
        contract    'features/580-mask-uuid-and-ip-address.md section Acceptance criteria 13 - one -m, --mask <name> entry'
    assert_equal "$(grep -c -- '--mask <name>' "$help_out")" "1" \
        label       'exactly one --mask <name> row in --help' \
        asserts     'The option is documented once, not once per name it accepts' \
        produced_by 'print_help() in ltl' \
        contract    'features/580-mask-uuid-and-ip-address.md section Acceptance criteria 13'
    assert_equal "$(grep -c -E -- '(^|\s)-uuid[, ]' "$help_out")" "0" \
        label       'no -uuid row in --help' \
        asserts     '-uuid is deprecated: --help carries no row for it; the notice printed on use names its replacement' \
        produced_by 'print_help() in ltl (the -uuid row is dropped; the GetOptions entry is annotated hidden)' \
        contract    'features/580-mask-uuid-and-ip-address.md section D8 - --help carries no -uuid row'
    # The -g description wraps over several lines at any width, so the help text
    # is collapsed to one line before the phrase is looked for.
    assert_equal "$(tr -s ' \n' '  ' < "$help_out" | grep -c -- 'masking them with --mask uuid is advisable')" "1" \
        label       'the -g row advises --mask uuid' \
        asserts     'The -g entry advises masking UUIDs with --mask uuid, not with the deprecated -uuid' \
        produced_by 'print_help() in ltl (the -g row)' \
        contract    'features/580-mask-uuid-and-ip-address.md section Acceptance criteria 13 - the -g entry names --mask uuid'

    assert_line "$USAGE_MD" \
        pattern     '^\| `-m, --mask <name>` \| Replace an identifier' \
        asserts     'docs/usage.md carries the -m, --mask <name> row' \
        produced_by 'docs/usage.md option table - manually maintained alongside print_help()' \
        contract    'CLAUDE.md section Before writing or changing code (help and usage.md edited together)'
    assert_equal "$(grep -c -- '`-uuid' "$USAGE_MD")" "0" \
        label       'no -uuid row or advice in docs/usage.md' \
        asserts     'docs/usage.md names the deprecated option nowhere; the -g row advises --mask uuid' \
        produced_by 'docs/usage.md option table' \
        contract    'features/580-mask-uuid-and-ip-address.md section D8 and section Acceptance criteria 13 - docs/usage.md agrees'
    assert_line "$USAGE_MD" \
        pattern     '`-g, --group-similar <N>`.*masking them with `--mask uuid` is advisable' \
        asserts     'The docs/usage.md -g row advises --mask uuid' \
        produced_by 'docs/usage.md option table' \
        contract    'features/580-mask-uuid-and-ip-address.md section Acceptance criteria 13'
}

scenario_G_udm_function_list_parity() {
    current_scenario="G-udm-function-list-parity"
    echo "[$current_scenario]"

    # Wide fixed width so description text is not wrapped mid-phrase; the
    # assertions below match single unwrapped lines.
    local help_out="$TMP_DIR/help-full.txt"
    "$LTL" --terminal-width 400 --help > "$help_out" 2>"$help_out.stderr" || true
    check_stderr_warnings "$help_out.stderr" "$current_scenario"

    assert_line "$help_out" \
        pattern     'Counting: count, distinct \(alias dcount, unique\), ratio, rate, drate' \
        asserts     'The --help -udm function line lists the counting aggregation keywords and the distinct aliases' \
        produced_by 'print_help() in ltl (User-Defined Metrics subheading, function row)' \
        contract    'features/user-defined-metrics.md section Counting Aggregations (Issue #313) - keyword set is locked; CLAUDE.md section Before writing or changing code (help and docs/usage.md edited together)'

    assert_line "$help_out" \
        pattern     'mean \(alias avg\)' \
        asserts     'The --help -udm function line names mean as the canonical aggregation keyword with avg as its alias' \
        produced_by 'print_help() in ltl (User-Defined Metrics subheading, function row)' \
        contract    'features/user-defined-metrics.md section Counting Aggregations (Issue #313) - canonical mean decision; CLAUDE.md section Before writing or changing code (help and docs/usage.md edited together)'

    assert_line "$USAGE_MD" \
        pattern     'Counting:\*\* `count`, `distinct` \(alias `dcount`, `unique`\), `ratio`, `rate`, `drate`' \
        asserts     'The docs/usage.md UDM function row mirrors the --help counting keyword list (the two surfaces must agree per the documentation-alignment rule)' \
        produced_by 'docs/usage.md UDM spec table - manually maintained alongside print_help()' \
        contract    'CLAUDE.md section Before writing or changing code (help and usage.md must carry consistent descriptions)'
}

# Unit-list parity (issue #608, one byte-unit ladder, D8): a help row that
# names a unit vocabulary carries the list the tool's own messages print,
# derived from the ladder, never a literal; docs/usage.md carries the same.
CONTRACT_UNIT_LISTS='features/608-byte-unit-ladder.md D4 (the records say what -udm accepts) and D8 (help rows interpolate the ladder list, with a help-content scenario asserting it)'
UNIT_FIXTURE="$REPO_DIR/tests/fixtures/udm-byte-units.txt"

# assert_row_carries FILE ROW_REGEX TEXT label L asserts A produced_by P contract C
# The first line matching ROW_REGEX must contain TEXT verbatim; a row that
# is not found is a failure, never a pass.
assert_row_carries() {
    local file="$1" row_regex="$2" text="$3"
    shift 3
    local label asserts produced_by contract row
    while [[ $# -gt 0 ]]; do
        case "$1" in
            label)       label="$2";       shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_row_carries: unknown field '$1'"; exit 2 ;;
        esac
    done
    row=$(grep -E -- "$row_regex" "$file" | head -1 || true)
    if [[ -n "$row" && -n "$text" && "$row" == *"$text"* ]]; then
        echo "  PASS  $current_scenario :: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        label:       $label"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        echo "        expected:    $text"
        echo "        row:         ${row:-(no row matches $row_regex in $file)}"
        fail=$((fail + 1))
        failures+=("$current_scenario :: $label")
    fi
}

# "ns, us" -> "`ns`, `us`": a list as docs/usage.md writes it.
backticked_list() {
    sed -E 's/([^, ]+)/`\1`/g' <<< "$1"
}

scenario_J_unit_list_parity() {
    current_scenario="J-unit-list-parity"
    echo "[$current_scenario]"

    local help_out="$TMP_DIR/help-units.txt"
    "$LTL" --disable-progress --terminal-width 400 --help > "$help_out" 2>"$help_out.stderr" || true
    check_stderr_warnings "$help_out.stderr" "$current_scenario"

    # The lists the tool's own rejections and warning print. Each run exits
    # non-zero by design (a usage error) except the -udm one, which warns.
    local err="$TMP_DIR/unit-errors"
    mkdir -p "$err"
    "$LTL" --disable-progress -ni -du xyz "$UNIT_FIXTURE" > "$err/du" 2>&1 || true
    "$LTL" --disable-progress -ni -ru xyz "$UNIT_FIXTURE" > "$err/ru" 2>&1 || true
    "$LTL" --disable-progress -ni -bs 5qq "$UNIT_FIXTURE" > "$err/bs" 2>&1 || true
    "$LTL" --disable-progress -ni -bn xyz "$UNIT_FIXTURE" > "$err/bn" 2>&1 || true
    ( cd "$err" && "$LTL" --disable-progress -ni -bs 1440 -oe -udm 'v:xyz:max' "$UNIT_FIXTURE" ) > "$err/udm.out" 2> "$err/udm" || true
    local f
    for f in du ru bs bn udm; do check_stderr_warnings "$err/$f" "$current_scenario/$f"; done

    local du_list ru_list bs_list udm_time udm_bytes
    du_list=$(sed -n "s/^Error: Invalid duration unit 'xyz'\. Valid values: //p" "$err/du")
    ru_list=$(sed -n "s/^Error: Invalid rate unit 'xyz'\. Valid values: //p" "$err/ru")
    bs_list=$(sed -n "s/^Error: Invalid bucket size '5qq'.* with a unit of //p" "$err/bs")
    local bn_list
    bn_list=$(sed -n "s/^Error: Invalid byte notation 'xyz'\. Valid values: //p" "$err/bn")
    udm_time=$(sed -n "s/^Warning: Unknown unit 'xyz' in -udm .*(time units: \(.*\); byte units: .*)$/\1/p" "$err/udm")
    udm_bytes=$(sed -n "s/^Warning: Unknown unit 'xyz' in -udm .*; byte units: \(.*\))$/\1/p" "$err/udm")

    assert_equal "$( [[ -n "$du_list" && -n "$ru_list" && -n "$bs_list" && -n "$bn_list" && -n "$udm_time" && -n "$udm_bytes" ]] && echo found )" "found" \
        label       'the -du, -ru, -bs and -bn rejections and the -udm unknown-unit warning each print their list' \
        asserts     'Each message the help rows are compared against names its vocabulary; an unmatched message is a failure, not a pass' \
        produced_by 'adapt_to_command_line_options() and parse_udm_configs() in ltl' \
        contract    "$CONTRACT_UNIT_LISTS"
    assert_equal "$ru_list|$bs_list|$udm_time" "$du_list|$du_list|$du_list" \
        label       'the four messages print one time-unit list' \
        asserts     'Every time-unit message derives its list from the one time-unit ladder' \
        produced_by '$time_unit_list over @time_unit_ladder in ltl' \
        contract    "$CONTRACT_UNIT_LISTS"

    # --help rows
    assert_row_carries "$help_out" '^ +-du, +--duration-unit' "($du_list)" \
        label       'the --help -du row carries the -du rejection list' \
        asserts     'The -du help row interpolates the time-unit list' \
        produced_by 'print_help() in ltl' \
        contract    "$CONTRACT_UNIT_LISTS"
    assert_row_carries "$help_out" '^ +-ru, +--rate-unit' "any of $ru_list; default m (the minute)" \
        label       'the --help -ru row carries the -ru rejection list and names its default' \
        asserts     'The -ru help row interpolates the time-unit list and names the minute as the default' \
        produced_by 'print_help() in ltl' \
        contract    "$CONTRACT_UNIT_LISTS"
    assert_row_carries "$help_out" '^ +-bs, +--bucket-size' "(units: $bs_list;" \
        label       'the --help -bs row carries the -bs rejection list' \
        asserts     'The -bs help row interpolates the time-unit list' \
        produced_by 'print_help() in ltl' \
        contract    "$CONTRACT_UNIT_LISTS"
    assert_row_carries "$help_out" '^ +unit +Time: ' "Time: $udm_time. " \
        label       'the --help -udm unit row carries the warning time-unit list' \
        asserts     'The -udm unit help row interpolates the time-unit list' \
        produced_by 'print_help() in ltl (User-Defined Metrics subheading, unit row)' \
        contract    "$CONTRACT_UNIT_LISTS"

    # The byte list: the row gives it by notation; together the two are the
    # list the warning prints.
    local unit_row si_list iec_list
    unit_row=$(grep -E '^ +unit +Time: ' "$help_out" | head -1 || true)
    si_list=$(sed -n 's/.*Bytes: \(.*\) are powers of 1000, .*/\1/p' <<< "$unit_row")
    iec_list=$(sed -n 's/.* are powers of 1000, \(.*\) powers of 1024;.*/\1/p' <<< "$unit_row")
    assert_equal "$si_list, $iec_list" "$udm_bytes" \
        label       'the --help -udm unit row byte lists are the warning byte list' \
        asserts     'The -udm unit help row names the SI tokens as powers of 1000 and the IEC tokens as powers of 1024, from the byte-unit ladder' \
        produced_by 'print_help() in ltl ($byte_unit_si_list, $byte_unit_iec_list over @byte_unit_ladder)' \
        contract    "$CONTRACT_UNIT_LISTS"

    # The -bn row names the values its usage error accepts and the two
    # notations' byte lists.
    assert_row_carries "$help_out" '^ +-bn, +--byte-notation' "SI units ($si_list; powers of 1000) or IEC units ($iec_list; powers of 1024): one of $bn_list." \
        label       'the --help -bn row carries the -bn usage-error values and both byte lists' \
        asserts     'The -bn help row interpolates the notation names and the ladder byte lists' \
        produced_by 'print_help() in ltl ($byte_notation_list, $byte_unit_si_list, $byte_unit_iec_list)' \
        contract    "$CONTRACT_UNIT_LISTS; features/608-byte-unit-ladder.md D17 (the -bn option)"

    # docs/usage.md rows: the same lists, each token in backticks
    assert_row_carries "$USAGE_MD" '^\| `-du, --duration-unit' "($(backticked_list "$du_list"))" \
        label       'the docs/usage.md -du row carries the -du rejection list' \
        asserts     'docs/usage.md agrees with the ladder list the tool prints' \
        produced_by 'docs/usage.md option table' \
        contract    "$CONTRACT_UNIT_LISTS"
    assert_row_carries "$USAGE_MD" '^\| `-ru, --rate-unit' "any of $(backticked_list "$ru_list"); default \`m\` (the minute)" \
        label       'the docs/usage.md -ru row carries the -ru rejection list and names its default' \
        asserts     'docs/usage.md agrees with the ladder list the tool prints' \
        produced_by 'docs/usage.md option table' \
        contract    "$CONTRACT_UNIT_LISTS"
    assert_row_carries "$USAGE_MD" '^\| `-bs, --bucket-size' "(units: $(backticked_list "$bs_list");" \
        label       'the docs/usage.md -bs row carries the -bs rejection list' \
        asserts     'docs/usage.md agrees with the ladder list the tool prints' \
        produced_by 'docs/usage.md option table' \
        contract    "$CONTRACT_UNIT_LISTS"
    assert_row_carries "$USAGE_MD" '^\| `-bn, --byte-notation' "SI units ($(backticked_list "$si_list"); powers of 1000) or IEC units ($(backticked_list "$iec_list"); powers of 1024): one of $(backticked_list "$bn_list")." \
        label       'the docs/usage.md -bn row carries the -bn values and both byte lists' \
        asserts     'docs/usage.md agrees with the ladder lists the tool prints' \
        produced_by 'docs/usage.md option table' \
        contract    "$CONTRACT_UNIT_LISTS; features/608-byte-unit-ladder.md D17 (the -bn option)"
    assert_row_carries "$USAGE_MD" '^\| `unit` \| \*\*Time:\*\*' "**Time:** $(backticked_list "$udm_time") — **Bytes:** $(backticked_list "$si_list") are powers of 1000, $(backticked_list "$iec_list") powers of 1024;" \
        label       'the docs/usage.md -udm unit row carries the time and byte lists' \
        asserts     'docs/usage.md agrees with the ladder lists the tool prints' \
        produced_by 'docs/usage.md UDM spec table' \
        contract    "$CONTRACT_UNIT_LISTS"
}

scenario_register A-help-contains-visible-longs \
                  B-usage-contains-visible-longs \
                  C-help-short-forms-match-getopts \
                  D-dash-v-matches-version-number \
                  E-benchmark-data-version-matches \
                  G-udm-function-list-parity \
                  H-mask-option-rows \
                  I-discard-option-rows \
                  J-unit-list-parity \
                  F-description-quality-soft
scenario_parse_args "$@"

while read -r _scenario; do
    case "$_scenario" in
        A-help-contains-visible-longs   ) scenario_A_help_contains_all_visible_longs ;;
        B-usage-contains-visible-longs  ) scenario_B_usage_contains_all_visible_longs ;;
        C-help-short-forms-match-getopts) scenario_C_help_short_forms_match_getopts ;;
        D-dash-v-matches-version-number ) scenario_D_dash_v_matches_version_number ;;
        E-benchmark-data-version-matches) scenario_E_benchmark_data_section_matches_version_number ;;
        G-udm-function-list-parity      ) scenario_G_udm_function_list_parity ;;
        H-mask-option-rows              ) scenario_H_mask_option_rows ;;
        I-discard-option-rows           ) scenario_I_discard_option_rows ;;
        J-unit-list-parity              ) scenario_J_unit_list_parity ;;
        F-description-quality-soft      ) scenario_F_description_quality_warnings ;;
    esac
    echo ""
done < <(scenario_selected)

echo ""
if [[ "$warn" -gt 0 ]]; then
    echo "Results: $pass passed, $fail failed, $warn warning(s)"
else
    echo "Results: $pass passed, $fail failed"
fi

if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
echo "ALL HELP-CONTENT TESTS PASSED"
exit 0
