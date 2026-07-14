#!/usr/bin/env bash
# validate-help-layout.sh — Validate `ltl --help` column-alignment layout.
# Usage: ./tests/validate-help-layout.sh
#
# Ensures every option row's description starts at the same column and every
# wrapped-description continuation line aligns at the same column. Catches
# layout regressions when a new long-form option name exceeds the available
# option-text column width without bumping $desc_col.
#
# Project requirement: every CLI option in ltl exposes both a short and a
# long form. This test guards the help-output column layout so that the
# `--help` table stays grep-friendly and visually aligned as new options
# are added.
#
# The test runs `ltl --help` at a fixed --terminal-width so wrap behavior
# is deterministic across machines. It strips the terminal-formatting
# bytes (underline / bold sequences and backspaces from `man`-style
# overprint) before column-checking, then asserts:
#
#   - Every option row's description begins at the locked column.
#   - Every continuation line of a wrapped description begins at the locked
#     column with leading whitespace only (no overflow into the option-text
#     region).
#
# The locked column is read from `ltl` itself ($desc_col in print_help) so
# the test moves automatically if a future PR re-bumps it.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"
    exit 1
fi

# Extract layout constants from ltl so the test follows future changes
# automatically. As of Issue #261 these are module-scope so they can be
# shared with --help statistics / --explain renderers:
#     my $help_opt_col   = 4;    # indent for option text
#     my $help_short_col = 8;    # width allocated for short option (incl. comma)
#     my $help_desc_col  = 52;   # column where descriptions begin
OPT_COL=$(perl -ne   'if (/^\s*my\s+\$help_opt_col\s*=\s*(\d+)\s*;/)   { print $1; exit }' "$LTL")
DESC_COL=$(perl -ne  'if (/^\s*my\s+\$help_desc_col\s*=\s*(\d+)\s*;/)  { print $1; exit }' "$LTL")
SHORT_COL=$(perl -ne 'if (/^\s*my\s+\$help_short_col\s*=\s*(\d+)\s*;/) { print $1; exit }' "$LTL")
if [[ -z "$OPT_COL" || -z "$DESC_COL" || -z "$SHORT_COL" ]]; then
    echo "ERROR: could not locate \$help_opt_col / \$help_desc_col / \$help_short_col at module scope in ltl"
    exit 1
fi
# 1-indexed columns derived from the print_help layout invariants.
EXPECTED_DESC_COL=$((DESC_COL + 1))                # description starts here
EXPECTED_LONG_COL=$((OPT_COL + SHORT_COL + 1))     # long form starts here

# Pin the width so wrap behavior is deterministic.
# 120 cols gives every existing option's description enough room to wrap
# meaningfully (at least 60 chars per description line) so wrap-continuation
# alignment can be exercised.
HELP_OUT=$(mktemp)
"$LTL" --terminal-width 120 --help > "$HELP_OUT" 2>"$HELP_OUT.stderr" || true

# Strip terminal-rendering bytes: ANSI escape sequences and backspace
# overstrike used for emphasis on terminals without color (see print_help in
# ltl). Three patterns to collapse, applied repeatedly until idempotent:
#   1. ANSI CSI sequences (just in case any leak in).
#   2. Bold: "X\bX"  → "X"  (bs_bold)
#   3. Underline: "_\bX" → "X"  (bs_underline)
STRIPPED=$(mktemp)
perl -CSDA -pe '
    s/\e\[[0-9;]*[A-Za-z]//g;
    1 while s/(.)\x08\1/$1/g;
    1 while s/_\x08(.)/$1/g;
' "$HELP_OUT" > "$STRIPPED"

pass=0
fail=0
failures=()

note_pass() { pass=$((pass + 1)); echo "  PASS  $1"; }

# Self-documenting failure emitter per tests/HARNESS-DESIGN.md
# § Self-documenting assertions. Required named fields: label, asserts,
# produced_by, contract. An optional `detail` field appends an extra line
# (used when the inspector produced a more specific diagnostic, e.g.
# the exact mismatched column number).
emit_fail() {
    local label asserts produced_by contract detail
    detail=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            label)       label="$2";       shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            detail)      detail="$2";      shift 2 ;;
            *) echo "emit_fail: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${label:?emit_fail requires label}"
    : "${asserts:?emit_fail requires asserts}"
    : "${produced_by:?emit_fail requires produced_by}"
    : "${contract:?emit_fail requires contract}"
    echo "  FAIL  $label"
    echo "        asserts:     $asserts"
    echo "        produced_by: $produced_by"
    echo "        contract:    $contract"
    if [[ -n "$detail" ]]; then
        echo "        detail:      $detail"
    fi
    fail=$((fail + 1))
    failures+=("$label")
}

# Runtime-warning cleanliness for the --help capture (HARNESS-DESIGN.md
# section Runtime-warning cleanliness, issue #341). Silent when clean.
if ! assert_no_runtime_warnings "$HELP_OUT.stderr" "ltl --help capture"; then
    fail=$((fail + 1))
    failures+=("ltl --help capture :: perl-runtime-warnings-on-stderr")
fi

# ---------------------------------------------------------------------------
# Sanity: $desc_col found and looks reasonable
# ---------------------------------------------------------------------------
echo "[sanity]"
SANITY_ASSERTS='The three help-layout column constants ($help_opt_col, $help_short_col, $help_desc_col) extracted from ltl fall within plausible bounds, and $help_desc_col exceeds the long-form column so descriptions cannot overlap the long-form option text'
SANITY_PRODUCED_BY='print_help() in ltl - module-scope my-declarations of $help_opt_col, $help_short_col, $help_desc_col'
SANITY_CONTRACT='Issue #261 hoisted these constants to module scope so --help, --help statistics, and --explain share one source of truth; bounds here exist to catch typo-class regressions where one is reset to an obviously-wrong value'

if [[ "$DESC_COL" -lt 30 || "$DESC_COL" -gt 80 ]]; then
    emit_fail \
        label       "sanity" \
        asserts     "$SANITY_ASSERTS" \
        produced_by "$SANITY_PRODUCED_BY" \
        contract    "$SANITY_CONTRACT" \
        detail      "\$help_desc_col=$DESC_COL is out of plausible range (30..80)"
elif [[ "$SHORT_COL" -lt 5 || "$SHORT_COL" -gt 12 ]]; then
    emit_fail \
        label       "sanity" \
        asserts     "$SANITY_ASSERTS" \
        produced_by "$SANITY_PRODUCED_BY" \
        contract    "$SANITY_CONTRACT" \
        detail      "\$help_short_col=$SHORT_COL is out of plausible range (5..12)"
elif [[ "$OPT_COL" -lt 2 || "$OPT_COL" -gt 8 ]]; then
    emit_fail \
        label       "sanity" \
        asserts     "$SANITY_ASSERTS" \
        produced_by "$SANITY_PRODUCED_BY" \
        contract    "$SANITY_CONTRACT" \
        detail      "\$help_opt_col=$OPT_COL is out of plausible range (2..8)"
elif [[ "$DESC_COL" -le "$EXPECTED_LONG_COL" ]]; then
    emit_fail \
        label       "sanity" \
        asserts     "$SANITY_ASSERTS" \
        produced_by "$SANITY_PRODUCED_BY" \
        contract    "$SANITY_CONTRACT" \
        detail      "\$help_desc_col=$DESC_COL must exceed long-form column ($EXPECTED_LONG_COL = \$help_opt_col + \$help_short_col)"
else
    note_pass "sanity :: \$help_opt_col=$OPT_COL  \$help_short_col=$SHORT_COL  \$help_desc_col=$DESC_COL  long-form col=$EXPECTED_LONG_COL  desc col=$EXPECTED_DESC_COL"
fi

# ---------------------------------------------------------------------------
# Check every option row's description starts at the expected column.
# An "option row" is one of:
#   1. Indented 4 spaces, starts with `-` (short+long, or short-only)
#   2. Indented 4 spaces, starts with `--` (long-only)
#   3. Indented 6 spaces, plain identifier — UDM sub-rows (name, unit, etc.)
#      and INFO `--help` row
# Skipped lines:
#   - Subheadings (indented 2 spaces, single word or word-with-formatting)
#   - Section headers in OPTIONS / ENVIRONMENT / INFO (no leading indent or
#     all-caps doubled-letter pattern)
#   - The EXAMPLES table (different layout)
#   - Continuation lines (handled separately below)
#   - Blank lines, prose paragraphs (Notes section)
#
# We detect the EXAMPLES section heading and stop scanning after it.
# ---------------------------------------------------------------------------
echo ""
echo "[option-row alignment]"
perl -e '
    use strict; use warnings;
    my ($file, $expected_desc_col, $expected_long_col) = @ARGV;
    open my $fh, "<", $file or die "open $file: $!";
    my $in_examples = 0;
    my $option_rows_checked = 0;
    my $continuation_rows_checked = 0;
    my @bad_option_rows;
    my @bad_continuation_rows;
    my $line_no = 0;
    my $prev_was_option_or_cont = 0;
    # Long-only rows place "--" at $expected_long_col; the start of the
    # leading whitespace is at column 1, so the indent before "--" is
    # ($expected_long_col - 1) spaces. We use this to identify long-only
    # option rows (e.g., --help in the INFO section).
    my $long_only_indent = " " x ($expected_long_col - 1);
    while (my $line = <$fh>) {
        $line_no++;
        chomp $line;

        # EXAMPLES section uses a different layout — stop scanning.
        if ($line =~ /^EXAMPLES\s*$/) { $in_examples = 1; next; }
        next if $in_examples;

        # Section headers (no leading spaces, all-caps-ish): ignore.
        next if $line =~ /^[A-Z]/;

        # Subheadings: indented exactly 2 spaces, then a non-dash token.
        next if $line =~ /^  [^- ]/;

        # Blank line resets the wrapped-description state.
        if ($line =~ /^\s*$/) { $prev_was_option_or_cont = 0; next; }

        # Option row variants:
        #   1. Short form: indented 4 spaces, starts with `-` (e.g., -bs).
        #   2. UDM sub-row: indented 10 spaces, starts with letter or `/`
        #      (e.g., `      name`).  (Indent 10 = 4 + short_col(8) - 2)
        #      Actually these use $opt_col + (short_col - 1) spacing.
        #   3. Long-only row: indented ($expected_long_col - 1) spaces,
        #      starts with `--` (e.g., `--help`).
        my $is_option_row = 0;
        if ($line =~ /^    -/) {
            $is_option_row = 1;
        } elsif ($line =~ /^\Q$long_only_indent\E--/) {
            $is_option_row = 1;
        } elsif ($line =~ /^          [^- ]/) {
            # UDM-style sub-row: 10 leading spaces then a letter or slash.
            # These are not full option rows but follow the same description
            # column. The leading-indent count is hardcoded to 10 because
            # the UDM block in print_help emits them with that literal
            # spacing; the test treats them as option-text-empty rows for
            # the purpose of description-column alignment.
            $is_option_row = 1;
        }

        if ($is_option_row) {
            if ($line =~ /^(.*\S)( {2,})(\S.*)$/) {
                my $desc_starts_at = length($1) + length($2) + 1;  # 1-indexed
                if ($desc_starts_at != $expected_desc_col) {
                    push @bad_option_rows, {
                        line => $line_no, expected => $expected_desc_col,
                        got => $desc_starts_at, text => $line,
                    };
                }
                $option_rows_checked++;
                $prev_was_option_or_cont = 1;
            }
            next;
        }

        # Continuation row: ($expected_desc_col - 1) leading spaces then
        # non-space. Only treat as such if we just saw an option row or
        # another continuation row.
        if ($prev_was_option_or_cont && $line =~ /^( +)(\S.*)$/) {
            my $lead = length($1);
            my $cont_starts_at = $lead + 1;
            if ($cont_starts_at != $expected_desc_col) {
                push @bad_continuation_rows, {
                    line => $line_no, expected => $expected_desc_col,
                    got => $cont_starts_at, text => $line,
                };
            }
            $continuation_rows_checked++;
            next;
        }

        $prev_was_option_or_cont = 0;
    }
    close $fh;

    print "checked $option_rows_checked option rows, $continuation_rows_checked continuation rows\n";
    if (@bad_option_rows) {
        print "BAD_OPTION_ROWS: ", scalar(@bad_option_rows), "\n";
        for my $b (@bad_option_rows) {
            print sprintf("  line %d: expected col %d, got col %d  ::  %s\n",
                $b->{line}, $b->{expected}, $b->{got}, $b->{text});
        }
        exit 2;
    }
    if (@bad_continuation_rows) {
        print "BAD_CONTINUATION_ROWS: ", scalar(@bad_continuation_rows), "\n";
        for my $b (@bad_continuation_rows) {
            print sprintf("  line %d: expected col %d, got col %d  ::  %s\n",
                $b->{line}, $b->{expected}, $b->{got}, $b->{text});
        }
        exit 3;
    }
    exit 0;
' "$STRIPPED" "$EXPECTED_DESC_COL" "$EXPECTED_LONG_COL"
rc=$?
if [[ $rc -eq 0 ]]; then
    note_pass "every option row description starts at col $EXPECTED_DESC_COL"
    note_pass "every wrapped-description continuation row starts at col $EXPECTED_DESC_COL"
elif [[ $rc -eq 2 ]]; then
    emit_fail \
        label       "option-row alignment" \
        asserts     "Every option-row description begins at column \$help_desc_col+1 ($EXPECTED_DESC_COL); a row whose description starts to the right means its option text exceeded the column budget and overflowed silently" \
        produced_by 'print_help() in ltl - the option-text rendering uses $help_desc_col as the padding target for the description column' \
        contract    'Issue #189-3 root cause: long-form options exceeding the option-text column budget shipped silently because there was no test asserting the column was honored. This assertion is what makes the failure visible.' \
        detail      "Perl inspector exit code 2 - one or more option rows misaligned (per-row diagnostics printed above)"
elif [[ $rc -eq 3 ]]; then
    emit_fail \
        label       "continuation-row alignment" \
        asserts     'Every wrapped-description continuation line begins at the same column as the description start ($help_desc_col+1)' \
        produced_by 'print_help() in ltl - wrap continuations are emitted with the same leading indent as the description column' \
        contract    'Issue #189-3 - the same column-budget bug that misaligns option rows also misaligns their wrap continuations; both must be guarded together' \
        detail      "Perl inspector exit code 3 - one or more continuation rows misaligned (per-row diagnostics printed above)"
else
    emit_fail \
        label       "option-row alignment (inspector)" \
        asserts     'The Perl inspector must exit 0, 2, or 3; any other exit code means the inspector itself broke and the test is no longer asserting anything' \
        produced_by 'inline Perl inspector at the top of validate-help-layout.sh' \
        contract    'tests/HARNESS-DESIGN.md section Harnesses must fail on missing anchors - an inspector that cannot run is an unasserted test' \
        detail      "Perl inspector exited with unexpected code $rc"
fi

# ---------------------------------------------------------------------------
# Check every short+long option row's long-form column alignment.
# Long-form-column drift is a real failure mode independent of the description
# column: when a short form's length pushes the long form one or more columns
# right of where shorter short forms put it, the result is a visually ragged
# left margin even though the description column itself stays aligned.
# Locked invariant: every short-form row places its long form starting at
# the SAME column (the one determined by $opt_col + $short_col).
# ---------------------------------------------------------------------------
echo ""
echo "[long-form column alignment]"
perl -e '
    use strict; use warnings;
    my ($file, $expected_col) = @ARGV;
    open my $fh, "<", $file or die "open $file: $!";
    my $in_examples = 0;
    my $checked = 0;
    my @bad;
    while (my $line = <$fh>) {
        if ($line =~ /^EXAMPLES\s*$/) { $in_examples = 1; next; }
        next if $in_examples;
        next unless $line =~ /^    -/;        # short-form rows only
        next unless $line =~ /, +--/;          # must have both forms
        if ($line =~ /(--\S+)/) {
            my $long = $1;
            my $idx = index($line, $long);
            my $col = $idx + 1;  # 1-indexed
            $checked++;
            if ($col != $expected_col) {
                push @bad, { col => $col, line => $line };
            }
        }
    }
    close $fh;
    print "checked $checked short+long rows; expected long-form col $expected_col\n";
    if (@bad) {
        print "BAD_LONG_FORM_COLUMNS: ", scalar(@bad), " row(s) misaligned\n";
        for my $b (@bad) {
            chomp $b->{line};
            print sprintf("  got col %d :: %s\n", $b->{col}, $b->{line});
        }
        exit 2;
    }
    exit 0;
' "$STRIPPED" "$EXPECTED_LONG_COL"
rc=$?
if [[ $rc -eq 0 ]]; then
    note_pass "every short+long row places its long form at col $EXPECTED_LONG_COL"
elif [[ $rc -eq 2 ]]; then
    emit_fail \
        label       "long-form column alignment" \
        asserts     "Every short+long option row places its long form starting at column \$help_opt_col + \$help_short_col + 1 ($EXPECTED_LONG_COL); a short form whose length pushes the long form rightward produces a ragged left margin even though the description column itself can still be honored" \
        produced_by 'print_help() in ltl - the short-form rendering pads to $help_short_col before emitting the long form' \
        contract    "Issue #261 - \$help_short_col was sized to accommodate the longest short form; a regression on either side (short form too long, or \$help_short_col bumped down) breaks left-margin alignment" \
        detail      "Perl inspector exit code 2 - one or more short+long rows misaligned (per-row diagnostics printed above)"
else
    emit_fail \
        label       "long-form column alignment (inspector)" \
        asserts     'The long-form-column Perl inspector must exit 0 or 2; any other exit code means the inspector itself broke' \
        produced_by 'inline Perl inspector in the [long-form column alignment] block of validate-help-layout.sh' \
        contract    'tests/HARNESS-DESIGN.md section Harnesses must fail on missing anchors - an inspector that cannot run is an unasserted test' \
        detail      "long-form-column Perl inspector exited with unexpected code $rc"
fi

# ---------------------------------------------------------------------------
# Spot check: ensure the percentile-mode options (the ones that triggered
# the original bug) are present in the help output with both forms.
# ---------------------------------------------------------------------------
echo ""
echo "[short+long form presence]"
assert_pair() {
    local short="$1" long="$2"
    # Pattern: "$short," followed by spaces then "$long" then either space,
    # <ARG>, [ARG], or end of line. Uses POSIX character class for portability.
    if grep -qE "^[[:space:]]+${short}, +${long}([[:space:]]|<|\[|$)" "$STRIPPED"; then
        note_pass "$short, $long"
    else
        emit_fail \
            label       "$short, $long" \
            asserts     "Both the short form ($short) and long form ($long) appear on the same row of --help output, in the canonical 'short, long' order; missing-pair regressions cost the user a discoverable surface (memory: 'short forms required for every CLI option')" \
            produced_by 'print_help() in ltl - the option-table row that registers this flag emits short+long together' \
            contract    "MEMORY.md feedback_short_forms_required: every CLI flag in ltl must have both short and long form; 'no short form' decisions are errors that need amending before wiring" \
            detail      "no row matched '^[[:space:]]+${short}, +${long}' in stripped --help output"
    fi
}
assert_pair "-dmp"   "--data-model-precision"
assert_pair "-hgb"   "--histogram-buckets"

# ---------------------------------------------------------------------------
# Wrap-up
# ---------------------------------------------------------------------------
rm -f "$HELP_OUT" "$HELP_OUT.stderr" "$STRIPPED"

echo ""
echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
echo "ALL HELP-LAYOUT TESTS PASSED"
