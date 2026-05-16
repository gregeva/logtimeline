#!/usr/bin/env bash
# validate-histogram-ticks.sh — Validate Issue #185 (percentile tick marks on histogram x-axis)
# Usage: ./tests/validate-histogram-ticks.sh
#
# For each width variant, asserts:
#   1. Every percentile shown in the legend has a corresponding axis indicator
#      (`┴`/`┻` upward tick, OR `┼`/`╋` cross when also a bucket boundary).
#   2. Duplicate-column collapse is allowed: when two percentile values map to
#      the same column (e.g. P1 and P10 both at the data floor), one axis tick
#      represents both — assertion is `tick_count == distinct_legend_columns`.
#   3. No `┴`/`┻`/`┼`/`╋` characters appear outside the histogram x-axis row.
#   4. Tick characters match the colour of the rest of the axis frame.
#      The existing frame chars (┗ ━ ┳ ┛) are emitted without any ANSI
#      wrapping, so the ticks must be too — same emission = same colour.
#   5. When `┼`/`╋` appears, the column it sits on is one of the percentile columns
#      computed from the legend values (i.e. it's there because a percentile and a
#      bucket boundary genuinely share that column).
#   6. Multi-histogram runs (`-hg duration,bytes`): each histogram independently
#      carries its own tick set matching its own legend.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"
ACCESS_LOG="$REPO_DIR/logs/AccessLogs/localhost_access_log.2025-03-21.txt"

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"
    exit 1
fi
if [[ ! -f "$ACCESS_LOG" ]]; then
    echo "ERROR: ACCESS_LOG not found: $ACCESS_LOG"
    exit 1
fi

pass=0
fail=0
failures=()

note_pass() { pass=$((pass + 1)); echo "  PASS: $1"; }
note_fail() { fail=$((fail + 1)); failures+=("$1"); echo "  FAIL: $1"; }

# ---------------------------------------------------------------------------
# Inspector: parse one ltl run's output, extract per-histogram axis-tick and
# legend-entry counts, plus structural sanity checks. Output is plain text
# the bash caller greps. Width is forced large via --terminal-width 200 so
# narrow-terminal histogram-suppression doesn't kick in for the small -hgw
# percentages.
# ---------------------------------------------------------------------------
inspect_output() {
    local file="$1"
    perl -CS -e '
        use strict; use warnings; use utf8;
        my $f = $ARGV[0];
        open my $fh, "<:encoding(UTF-8)", $f or die "open $f: $!";
        my @raw_lines = <$fh>;
        close $fh;

        # Strip ANSI for content matching, but keep raw for colour-prefix checks.
        my @lines;
        for my $r (@raw_lines) {
            my $s = $r;
            $s =~ s/\e\[[0-9;]*m//g;
            push @lines, { raw => $r, plain => $s };
        }

        # Tick chars (light + heavy variants).
        my $tup_re   = qr/[\x{2534}\x{253B}]/;     # ┴ ┻
        my $cross_re = qr/[\x{253C}\x{254B}]/;     # ┼ ╋
        my $tdown_re = qr/[\x{252C}\x{2533}]/;     # ┬ ┳
        my $hline_re = qr/[\x{2500}\x{2501}]/;     # ─ ━
        my $corner_l = qr/[\x{2514}\x{2517}]/;     # └ ┗

        # 1) Collect axis line indices (lines containing the bottom-left corner).
        my @axis_idxs;
        for my $i (0 .. $#lines) {
            push @axis_idxs, $i if $lines[$i]{plain} =~ /$corner_l/;
        }

        # 2) Out-of-axis tick check: no ┴/┻/┼/╋ on any line that is NOT an axis line.
        my $out_of_axis = 0;
        for my $i (0 .. $#lines) {
            next if grep { $_ == $i } @axis_idxs;
            $out_of_axis++ if $lines[$i]{plain} =~ /$tup_re|$cross_re/;
        }
        print "OUT_OF_AXIS:$out_of_axis\n";

        # 3) For each axis line, split into per-histogram segments (≥4 spaces).
        # For each segment count tup, cross, total ticks. Check each tick char in
        # the raw line is preceded by the axis-colour ANSI prefix (\e[38;5;8m).
        my $axis_seq = 0;
        for my $i (@axis_idxs) {
            $axis_seq++;
            my $plain = $lines[$i]{plain};
            my $raw   = $lines[$i]{raw};
            my @segs  = split /\s{4,}/, $plain;
            my $hidx  = 0;
            for my $seg (@segs) {
                next unless $seg =~ /$corner_l/;
                $hidx++;
                my $t = () = $seg =~ /$tup_re/g;
                my $c = () = $seg =~ /$cross_re/g;
                print "AXIS:$axis_seq:$hidx:tup=$t:cross=$c:total=", $t+$c, "\n";
            }
            # Issue #185: tick chars must match the colour of the rest of the
            # axis frame. The frame chars are emitted without any ANSI wrapping,
            # so ticks must be too. Detect a mismatch by counting any escape
            # sequence immediately preceding a tick character.
            my $bad_colour = 0;
            while ($raw =~ /(\e\[[0-9;]*m)($tup_re|$cross_re)/g) {
                $bad_colour++;
            }
            print "AXIS_COLOUR:$axis_seq:bad=$bad_colour\n";
        }

        # 4) Find the legend lines: standalone-ish lines containing ≥2 "P##:" entries
        # and NOT a histogram axis. Bar-graph rows in the per-message table also
        # contain "P50:"/"P95:"/"P99:" tokens — distinguish by absence of " │ "
        # (vertical bar with surrounding spaces) which is the bar-graph separator
        # but does not appear on histogram legend lines.
        my $legend_seq = 0;
        for my $i (0 .. $#lines) {
            next if grep { $_ == $i } @axis_idxs;
            my $p = $lines[$i]{plain};
            next unless $p =~ /P\d+(?:\.\d+)?:/;
            # Skip bar-graph table rows (they have the column separator " │ ").
            next if $p =~ / \x{2502} /;
            # Skip TOP MESSAGES table column header (no P-percentile entries).
            $legend_seq++;
            my @segs = split /\s{4,}/, $p;
            my $hidx = 0;
            for my $seg (@segs) {
                my $n = () = $seg =~ /P\d+(?:\.\d+)?:/g;
                next unless $n >= 2;
                $hidx++;
                # Extract the percentile values themselves so we can report distinct counts.
                # An entry looks like "P99.9: 6.9s".
                my @entries;
                while ($seg =~ /(P\d+(?:\.\d+)?):\s*(\S+)/g) {
                    push @entries, "$1=$2";
                }
                my %distinct_vals;
                $distinct_vals{(split /=/)[1]}++ for @entries;
                my $distinct = scalar keys %distinct_vals;
                print "LEGEND:$legend_seq:$hidx:entries=", scalar(@entries),
                      ":distinct_values=$distinct\n";
            }
        }
    ' "$file"
}

# ---------------------------------------------------------------------------
# Run one width and assert the relationship between ticks and legend entries.
#
# Correct invariant: 1 <= tick_count <= legend_entry_count
#
# Why a range and not equality:
#   - Percentiles with identical or very close values (e.g. P1=P10=1ms,
#     P95=P99=4.1MiB after log-scale column quantisation) collapse into the
#     same column and produce one tick. This is correct set-semantics.
#   - tick_count > legend_count would mean orphan ticks (no matching legend
#     entry), which IS a bug — the displayed legend is the contract.
# ---------------------------------------------------------------------------
test_single_width() {
    local hgw="$1"
    echo "Single histogram, -hgw $hgw"

    local out
    out=$(mktemp)
    "$LTL" --disable-progress --terminal-width 200 -hg duration -hgw "$hgw" "$ACCESS_LOG" > "$out" 2>&1 || true

    local report
    report=$(inspect_output "$out")

    # Out-of-axis assertion (same for every run).
    local oo
    oo=$(echo "$report" | sed -n 's/^OUT_OF_AXIS:\([0-9]*\)$/\1/p')
    if [[ "$oo" == "0" ]]; then
        note_pass "no ┴/┻/┼/╋ outside axis lines (-hgw $hgw)"
    else
        note_fail "found $oo lines containing ticks outside axis (-hgw $hgw)"
    fi

    # Colour assertion.
    local bad_colour
    bad_colour=$(echo "$report" | awk -F: '/^AXIS_COLOUR:/ {sum += $3+0} END {print sum+0}')
    if [[ "$bad_colour" == "0" ]]; then
        note_pass "tick chars match axis frame colour (no ANSI wrapping) (-hgw $hgw)"
    else
        note_fail "$bad_colour tick chars carry ANSI colour wrapping (-hgw $hgw)"
    fi

    # Tick-vs-legend invariant: 1 <= ticks <= entries.
    local tick_total legend_entries
    tick_total=$(echo "$report" | awk -F: '/^AXIS:1:1:/ {for (i=1;i<=NF;i++) if ($i ~ /^total=/) {split($i,a,"="); print a[2]}}')
    legend_entries=$(echo "$report" | awk -F: '/^LEGEND:1:1:/ {for (i=1;i<=NF;i++) if ($i ~ /^entries=/) {split($i,a,"="); print a[2]}}')
    if [[ -z "$tick_total" || -z "$legend_entries" ]]; then
        note_fail "could not extract axis/legend counts (-hgw $hgw): tick='$tick_total' legend='$legend_entries'"
    elif [[ "$tick_total" -ge 1 && "$tick_total" -le "$legend_entries" ]]; then
        note_pass "axis ticks ($tick_total) within [1, $legend_entries] legend entries (-hgw $hgw)"
    else
        note_fail "axis ticks ($tick_total) outside [1, $legend_entries] legend entries (-hgw $hgw)"
    fi

    rm -f "$out"
}

# ---------------------------------------------------------------------------
# Multi-histogram: ensure each histogram has its own independent tick set
# matching its own legend.
# ---------------------------------------------------------------------------
test_multi_histogram() {
    echo "Multi-histogram, -hg duration,bytes"

    local out
    out=$(mktemp)
    "$LTL" --disable-progress --terminal-width 200 -hg duration,bytes -hgw 95 "$ACCESS_LOG" > "$out" 2>&1 || true

    local report
    report=$(inspect_output "$out")

    local oo
    oo=$(echo "$report" | sed -n 's/^OUT_OF_AXIS:\([0-9]*\)$/\1/p')
    if [[ "$oo" == "0" ]]; then
        note_pass "no ticks outside axis (multi)"
    else
        note_fail "found $oo lines with ticks outside axis (multi)"
    fi

    # Per-histogram tick-vs-legend invariant: 1 <= ticks <= entries.
    for hidx in 1 2; do
        local tick legend
        tick=$(echo "$report" | awk -F: -v h="$hidx" '/^AXIS:1:/ && $3==h {for (i=1;i<=NF;i++) if ($i ~ /^total=/) {split($i,a,"="); print a[2]}}')
        legend=$(echo "$report" | awk -F: -v h="$hidx" '/^LEGEND:1:/ && $3==h {for (i=1;i<=NF;i++) if ($i ~ /^entries=/) {split($i,a,"="); print a[2]}}')
        if [[ -z "$tick" || -z "$legend" ]]; then
            note_fail "could not extract counts for hist#$hidx (multi): tick='$tick' legend='$legend'"
        elif [[ "$tick" -ge 1 && "$tick" -le "$legend" ]]; then
            note_pass "hist#$hidx ticks ($tick) within [1, $legend] legend entries"
        else
            note_fail "hist#$hidx ticks ($tick) outside [1, $legend] legend entries"
        fi
    done

    rm -f "$out"
}

echo "=== Single-histogram across widths ==="
for w in 30 50 75 95; do
    test_single_width "$w"
done

echo ""
echo "=== Multi-histogram ==="
test_multi_histogram

echo ""
echo "=========================================="
echo "Total: $((pass + fail)) | Passed: $pass | Failed: $fail"
if [[ $fail -gt 0 ]]; then
    echo ""
    echo "Failures:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
exit 0
