#!/usr/bin/env bash
# validate-help-layout.sh — Validate `ltl --help` column-alignment layout.
# Usage: ./tests/validate-help-layout.sh
#
# Ensures every option row's description starts at the same column and every
# wrapped-description continuation line aligns at the same column. Catches
# layout regressions when a new long-form option name exceeds the available
# option-text column width without bumping $desc_col — exactly the failure
# mode that shipped silently before PR #189-3 (which added
# --histogram-buckets-per-decade and --percentile-buckets-per-decade).
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

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"
    exit 1
fi

# Extract layout constants from ltl so the test follows future changes
# automatically. The print_help() sub declares three:
#     my $opt_col   = 4;    # indent for option text
#     my $desc_col  = 52;   # column where descriptions begin
#     my $short_col = 8;    # width allocated for short option (incl. comma)
OPT_COL=$(perl -ne   'if (/^\s*my\s+\$opt_col\s*=\s*(\d+)\s*;/)   { print $1; exit }' "$LTL")
DESC_COL=$(perl -ne  'if (/^\s*my\s+\$desc_col\s*=\s*(\d+)\s*;/)  { print $1; exit }' "$LTL")
SHORT_COL=$(perl -ne 'if (/^\s*my\s+\$short_col\s*=\s*(\d+)\s*;/) { print $1; exit }' "$LTL")
if [[ -z "$OPT_COL" || -z "$DESC_COL" || -z "$SHORT_COL" ]]; then
    echo "ERROR: could not locate \$opt_col / \$desc_col / \$short_col in ltl print_help()"
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
"$LTL" --terminal-width 120 --help 2>&1 > "$HELP_OUT" || true

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
note_fail() { fail=$((fail + 1)); failures+=("$1"); echo "  FAIL  $1"; }

# ---------------------------------------------------------------------------
# Sanity: $desc_col found and looks reasonable
# ---------------------------------------------------------------------------
echo "[sanity]"
if [[ "$DESC_COL" -lt 30 || "$DESC_COL" -gt 80 ]]; then
    note_fail "sanity :: \$desc_col=$DESC_COL is out of plausible range (30..80)"
elif [[ "$SHORT_COL" -lt 5 || "$SHORT_COL" -gt 12 ]]; then
    note_fail "sanity :: \$short_col=$SHORT_COL is out of plausible range (5..12)"
elif [[ "$OPT_COL" -lt 2 || "$OPT_COL" -gt 8 ]]; then
    note_fail "sanity :: \$opt_col=$OPT_COL is out of plausible range (2..8)"
elif [[ "$DESC_COL" -le "$EXPECTED_LONG_COL" ]]; then
    note_fail "sanity :: \$desc_col=$DESC_COL must exceed long-form column ($EXPECTED_LONG_COL = \$opt_col + \$short_col)"
else
    note_pass "sanity :: \$opt_col=$OPT_COL  \$short_col=$SHORT_COL  \$desc_col=$DESC_COL  long-form col=$EXPECTED_LONG_COL  desc col=$EXPECTED_DESC_COL"
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
    note_fail "one or more option rows have misaligned description column (see output above)"
elif [[ $rc -eq 3 ]]; then
    note_fail "one or more continuation rows have misaligned column (see output above)"
else
    note_fail "Perl inspector exited with unexpected code $rc"
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
    note_fail "one or more short+long rows misalign the long-form column (see output above)"
else
    note_fail "long-form-column Perl inspector exited with unexpected code $rc"
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
        note_fail "$short, $long  (expected both short and long form on same line)"
    fi
}
assert_pair "-pp"    "--percentile-precision"
assert_pair "-pbpd"  "--percentile-buckets-per-decade"
assert_pair "-ep"    "--exact-percentiles"
assert_pair "-hgbpd" "--histogram-buckets-per-decade"
assert_pair "-hgb"   "--histogram-buckets"

# ---------------------------------------------------------------------------
# Wrap-up
# ---------------------------------------------------------------------------
rm -f "$HELP_OUT" "$STRIPPED"

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
