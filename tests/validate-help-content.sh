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
# of drift (CLAUDE.md observation 2026-02-07).
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
LTL="$REPO_DIR/ltl"
USAGE_MD="$REPO_DIR/docs/usage.md"
# Test log: tiny clean access log (~83 KB). Per repo memory
# (feedback_test_logs.md) avoid the corrupt 2025-03-21 file; Codebeamer's
# log is the smallest clean fixture available.
TEST_LOG="$REPO_DIR/logs/Codebeamber/codebeamer_access_log.2025-10-29.txt"

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
    if ($in_block && /\)\s*or\s+die/) { $in_block = 0; next }
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
"$LTL" --disable-progress --terminal-width 160 --help > "$HELP_OUT" 2>"$TMP_DIR/help.stderr"
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
        contract    'CLAUDE.md release-process step 15 (Sync Wiki) + features/232-help-coverage.md section 3 - usage.md is part of the user-facing contract'
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
    "$LTL" --disable-progress -v > "$vout" 2>&1
    local ec=$?
    set -e
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
    "$LTL" --disable-progress -V benchmark-data "$TEST_LOG" > "$bout" 2>&1
    local ec=$?
    set -e
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

scenario_A_help_contains_all_visible_longs;        echo ""
scenario_B_usage_contains_all_visible_longs;       echo ""
scenario_C_help_short_forms_match_getopts;         echo ""
scenario_D_dash_v_matches_version_number;          echo ""
scenario_E_benchmark_data_section_matches_version_number; echo ""
scenario_F_description_quality_warnings

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
