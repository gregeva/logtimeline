#!/usr/bin/env bash
# validate-histogram-ticks.sh — Validate Issue #185 (percentile tick marks on histogram x-axis)
# Usage: ./tests/validate-histogram-ticks.sh
#
# For each width variant, asserts:
#   1. Every percentile shown in the legend has a corresponding axis indicator
#      (`┴`/`┻` upward tick, OR `┼`/`╋` cross when also a bucket boundary).
#   2. Duplicate-column collapse is allowed: when two percentile values map to
#      the same column (e.g. P1 and P10 both at the data floor), one axis tick
#      represents both — so the assertion is the inequality
#      `1 <= tick_count <= legend_entries`, not an equality.
#   3. No `┴`/`┻`/`┼`/`╋` characters appear outside the histogram x-axis row.
#   4. Tick characters match the colour of the rest of the axis frame.
#      The existing frame chars (┗ ━ ┳ ┛) are emitted without any ANSI
#      wrapping, so the ticks must be too — same emission = same colour.
#   5. Each percentile tick sits within one column of where the log mapping puts
#      its legend value, anchored on the lowest and highest rendered ticks
#      (#450). See assert_tick_positions() for what the tolerance does and does
#      not catch.
#   6. Multi-histogram runs (`-hg duration,bytes`): each histogram independently
#      carries its own tick set matching its own legend.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"

# Ambient FORCE_COLOR/NO_COLOR must not decide what this harness asserts
# against (tests/HARNESS-DESIGN.md section Colour rendering is controlled,
# never inherited; issue #438).
neutralize_colour_env
# shellcheck source=lib/fixtures.sh
source "$SCRIPT_DIR/lib/fixtures.sh"

# Transient files (derived fixture) live in a temp directory cleaned on EXIT
# per HARNESS-DESIGN.md Trap 10.
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# ACCESS_LOG is derived deterministically from the clean full-day 2025-05-07
# corpus (see tests/lib/fixtures.sh): full-range duration/bytes spread for the
# log-scale tick assertions.
ACCESS_LOG="$TMP_DIR/access-sampled.txt"
# Invocation shape (tests/HARNESS-DESIGN.md section Invocation coherence):
# the assertions read the histogram block (ticks vs legend) and scan the
# rest of the render for stray tick characters, so the timeline collapses
# to one bucket and the table to one row - both stay rendered as the
# "nowhere else" surface - while the histogram itself sees every duration.
SHAPE="-bs 1440 -oe -n 1"

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"
    exit 1
fi
derive_sampled_access_log "$ACCESS_LOG"

pass=0
fail=0
failures=()

note_pass() { pass=$((pass + 1)); echo "  PASS: $1"; }

# Self-documenting failure emitter per tests/HARNESS-DESIGN.md
# § Self-documenting assertions. Required named fields: label, asserts,
# produced_by, contract. Optional `detail` carries the run-specific
# diagnostic (counts, widths, etc.).
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

                # Tick COLUMNS, for the position assertion (#450). Anchored on
                # the bottom-left corner glyph, never on a fixed left margin:
                # print_histograms() prefixes every line with a data-dependent
                # centering offset.
                my @chars = split //, $seg;
                my ($corner_at) = grep { $chars[$_] =~ /$corner_l/ } 0 .. $#chars;
                if (defined $corner_at) {
                    my @cols;
                    for my $j ($corner_at + 1 .. $#chars) {
                        push @cols, $j - $corner_at - 1
                            if $chars[$j] =~ /$tup_re|$cross_re/;
                    }
                    print "TICKCOL:$axis_seq:$hidx:", join(",", @cols), "\n" if @cols;
                }
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

                # Legend values converted to one base unit, for the position
                # assertion (#450). This is a harness-side reader of the
                # rendered vocabulary -- the render is the only place these
                # values appear, so the harness must parse what is displayed.
                # Values are display-rounded, which is exactly why the position
                # assertion carries a tolerance.
                my %unit_scale = (
                    ""    => 1,          "us" => 1,        "\x{00B5}s" => 1,
                    "ms"  => 1e3,        "s"  => 1e6,      "m" => 6e7,
                    "h"   => 3.6e9,      "d"  => 8.64e10,
                    "B"   => 1,          "KiB" => 1024,    "MiB" => 1048576,
                    "GiB" => 1073741824, "KB" => 1000,     "MB" => 1e6, "GB" => 1e9,
                );
                my @vals;
                my $unparsed = 0;
                while ($seg =~ /(P\d+(?:\.\d+)?):\s*([0-9.]+)\s*([A-Za-z\x{00B5}]*)/g) {
                    my ($label, $num, $unit) = ($1, $2, $3);
                    if (!exists $unit_scale{$unit}) { $unparsed++; next; }
                    # Half of the last displayed decimal place is how much this
                    # value could really differ from what is printed. Carried
                    # alongside so the position assertion can size its tolerance
                    # to the precision the render actually offers.
                    my $decimals = ($num =~ /\.(\d+)/) ? length($1) : 0;
                    my $half_ulp = 0.5 * (10 ** -$decimals);
                    push @vals, "$label=" . ($num * $unit_scale{$unit})
                              . "=" . ($half_ulp * $unit_scale{$unit});
                }
                print "LEGENDVAL:$legend_seq:$hidx:unparsed=$unparsed:",
                      join(",", @vals), "\n";
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

# ---------------------------------------------------------------------------
# Tick POSITION assertion (#450, made exact by the observability added in #462).
#
# calculate_histogram_percentile_ticks() maps a percentile value to a column:
#   col = int( log(v/min) / log(max/min) * (bar_width - 1) )
#
# `-V histogram-percentile-ticks` publishes that expression's four inputs at
# full precision -- bar_width, min, max, and each selected percentile value.
# The harness recomputes the mapping from them and compares the resulting
# column set against the columns recovered from the rendered axis row. So the
# -V surface supplies the EXPECTED and the render supplies the ACTUAL, which is
# the split HARNESS-DESIGN.md sanctions; the section deliberately does not
# report the computed columns, since reading those back would compare ltl with
# itself and assert nothing.
#
# Equality, no tolerance. An earlier form of this assertion predicted from the
# rendered legend, whose values are rounded by format_heatmap_value() to one
# decimal and a unit -- that mispredicted 3 of 9 columns on this fixture and
# forced a tolerance wide enough to be inert on the widest histograms. With the
# unrounded inputs the prediction is exact, so a single-column drift now fails,
# which is what D2 requires be provable.
#
# Columns are recovered by anchoring on the bottom-left corner glyph, never on
# a fixed left margin: print_histograms() prefixes every line with a
# data-dependent centering offset.
# ---------------------------------------------------------------------------
assert_tick_positions() {
    local out="$1" report="$2" hidx="$3" label="$4"

    local cols
    cols=$(echo "$report" | awk -F: -v h="$hidx" '/^TICKCOL:1:/ && $3==h {print $4}')

    local verdict
    verdict=$(TICK_COLS="${cols:-}" PANEL="$hidx" perl -CS -e '
        use strict; use warnings;
        my $file = $ARGV[0];
        open my $fh, "<:encoding(UTF-8)", $file or die "open: $!";
        my @l = <$fh>; close $fh;
        my ($in, $panel, @blocks) = (0, 0);
        for my $line (@l) {
            $line =~ s/\e\[[0-9;]*m//g;
            if ($line =~ /^=== histogram-percentile-ticks ===/)     { $in = 1; next }
            if ($line =~ /^=== END histogram-percentile-ticks ===/) { $in = 0; next }
            next unless $in;
            if ($line =~ /^\s+metric:\s+(\S+)\s+bar_width=(\d+)\s+min=(\S+)\s+max=(\S+)/) {
                push @blocks, { metric => $1, w => $2, min => $3, max => $4, vals => [] };
            } elsif (@blocks && $line =~ /^\s+(P[\d.]+)=(\S+)/) {
                push @{ $blocks[-1]{vals} }, [$1, $2];
            }
        }
        if (!@blocks) { print "MISSING:no-tick-inputs-section"; exit }
        # NB: not $a/$b -- a lexical of either name in this scope binds the
        # comparison variables used by sort, silently disabling the sort.
        my $blk = $blocks[ $ENV{PANEL} - 1 ];
        if (!$blk) { print "MISSING:no-block-for-panel-$ENV{PANEL}"; exit }
        my ($w, $min, $max) = ($blk->{w}, $blk->{min}, $blk->{max});
        if (!($min > 0) || !($max > $min)) { print "SKIP:degenerate-range"; exit }
        my $lr = log($max / $min);
        my %exp;
        for my $v (@{ $blk->{vals} }) {
            my ($label, $value) = @$v;
            next unless $value > 0;
            my $pos = log($value / $min) / $lr;
            $pos = 0 if $pos < 0; $pos = 1 if $pos > 1;
            $exp{ int($pos * ($w - 1)) } = 1;
        }
        my @expected = sort { $a <=> $b } keys %exp;
        my @actual   = sort { $a <=> $b } grep { length } split /,/, ($ENV{TICK_COLS} // "");
        if (!@actual)   { print "MISSING:no-tick-columns-on-axis"; exit }
        if (!@expected) { print "SKIP:no-positive-percentile-values"; exit }
        my $want = join(",", @expected);
        my $got  = join(",", @actual);
        print $want eq $got
            ? "OK:$blk->{metric} " . scalar(@expected) . " columns [$want]"
            : "FAIL:$blk->{metric} expected [$want] actual [$got]";
    ' "$out")

    case "$verdict" in
        OK:*)
            note_pass "tick columns exactly match the mapping recomputed from -V inputs (${verdict#OK:}) ($label)" ;;
        SKIP:*)
            note_pass "tick position check not applicable (${verdict#SKIP:}) ($label)" ;;
        MISSING:*)
            emit_fail \
                label       "tick position inputs ($label)" \
                asserts     'The -V histogram-percentile-ticks section must publish a block for every rendered histogram panel, and the axis row must yield at least one tick column; a missing anchor on either side means the section or the render regressed, or this harness stopped reading what ltl emits' \
                produced_by 'emit_histogram_tick_inputs() / emit_histogram_tick_inputs_verbose() in ltl; TICKCOL emission in inspect_output() of this harness' \
                contract    'tests/HARNESS-DESIGN.md section Harnesses must fail on missing anchors - a grep that matches nothing is a failure, not a pass' \
                detail      "${verdict#MISSING:} ($label)"
            return 1 ;;
        *)
            emit_fail \
                label       "tick position ($label)" \
                asserts     'Every percentile tick sits in exactly the column the mapping puts it in, recomputed independently by this harness from the full-precision inputs ltl publishes. Any difference means the rendered tick marks no longer line up with the percentile values printed beside them' \
                produced_by 'calculate_histogram_percentile_ticks() in ltl - col = int(log(v/min)/log(max/min) * (bar_width-1)); rendered by render_histogram_x_axis(); inputs published by emit_histogram_tick_inputs()' \
                contract    'features/bin-counter-accuracy-and-observability.md section D2 - the percentile tick marks must line up accurately with the percentile values that are printed and with their placement on the histogram, validated by test rather than by inspection' \
                detail      "${verdict#FAIL:} ($label)"
            return 1 ;;
    esac
    return 0
}

test_single_width() {
    local hgw="$1"
    echo "Single histogram, -hgw $hgw"

    local out
    out=$(mktemp)
    # shellcheck disable=SC2086
    "$LTL" --disable-progress -ni $SHAPE --terminal-width 200 -V histogram-percentile-ticks -hg duration -hgw "$hgw" "$ACCESS_LOG" > "$out" 2>"$out.stderr" || true
    if ! assert_no_runtime_warnings "$out.stderr" "histogram-ticks"; then
        fail=$((fail + 1)); failures+=("perl-runtime-warnings-on-stderr")
    fi

    local report
    report=$(inspect_output "$out")

    # Out-of-axis assertion (same for every run).
    local oo
    oo=$(echo "$report" | sed -n 's/^OUT_OF_AXIS:\([0-9]*\)$/\1/p')
    if [[ "$oo" == "0" ]]; then
        note_pass "no tick characters outside axis lines (-hgw $hgw)"
    else
        emit_fail \
            label       "out-of-axis ticks (-hgw $hgw)" \
            asserts     'Percentile tick characters (upward-tick and cross marks) appear only on the histogram x-axis frame row; appearance elsewhere means the tick emission code is firing on a non-axis row, which is a layout regression' \
            produced_by 'render_histogram_x_axis() in ltl - the tick characters are inserted into the same row that emits the histogram frame characters' \
            contract    'Issue #185 section percentile tick marks on histogram x-axis - tick emission is confined to the axis row by construction; tick characters in other rows are not part of the contract' \
            detail      "found $oo lines containing ticks outside axis (-hgw $hgw)"
    fi

    # Colour assertion.
    local bad_colour
    bad_colour=$(echo "$report" | awk -F: '/^AXIS_COLOUR:/ {sum += $3+0} END {print sum+0}')
    if [[ "$bad_colour" == "0" ]]; then
        note_pass "tick chars match axis frame colour (no ANSI wrapping) (-hgw $hgw)"
    else
        emit_fail \
            label       "tick colour parity (-hgw $hgw)" \
            asserts     'Percentile tick characters are emitted with no ANSI wrapping, matching the rest of the frame which is also unwrapped; an ANSI escape sequence immediately preceding a tick means the tick will render in a different colour than the histogram frame characters' \
            produced_by 'render_histogram_x_axis() in ltl - tick characters are appended to the frame string with no additional colour wrapping' \
            contract    'Issue #185 - visual unity of the axis frame requires tick chars to inherit the frame colour by being emitted in the same uncoloured stream' \
            detail      "$bad_colour tick chars carry ANSI colour wrapping (-hgw $hgw)"
    fi

    # Tick-vs-legend invariant: 1 <= ticks <= entries.
    local tick_total legend_entries
    tick_total=$(echo "$report" | awk -F: '/^AXIS:1:1:/ {for (i=1;i<=NF;i++) if ($i ~ /^total=/) {split($i,a,"="); print a[2]}}')
    legend_entries=$(echo "$report" | awk -F: '/^LEGEND:1:1:/ {for (i=1;i<=NF;i++) if ($i ~ /^entries=/) {split($i,a,"="); print a[2]}}')
    if [[ -z "$tick_total" || -z "$legend_entries" ]]; then
        emit_fail \
            label       "tick/legend extraction (-hgw $hgw)" \
            asserts     'The inspector must successfully extract both an AXIS tick total and a LEGEND entry count from the single-histogram output; a missing anchor here means the histogram or its legend was not emitted, OR the inspector regexes drifted from the rendered output' \
            produced_by 'render_histogram_x_axis() + legend rendering in ltl; inspector regexes in inspect_output() of this harness' \
            contract    'tests/HARNESS-DESIGN.md section Harnesses must fail on missing anchors - a grep that matches nothing is a failure, not a pass' \
            detail      "could not extract axis/legend counts (-hgw $hgw): tick='$tick_total' legend='$legend_entries'"
    elif [[ "$tick_total" -ge 1 && "$tick_total" -le "$legend_entries" ]]; then
        note_pass "axis ticks ($tick_total) within [1, $legend_entries] legend entries (-hgw $hgw)"
    else
        emit_fail \
            label       "tick/legend cardinality (-hgw $hgw)" \
            asserts     'The number of axis ticks is at least 1 and at most the number of legend entries; tick_count > legend_count means orphan ticks with no matching legend entry (the legend is the contract); tick_count < 1 means the percentile marker layer was not rendered at all' \
            produced_by 'calculate_histogram_percentile_ticks() in ltl - tick column derivation maps each legend percentile to a column; duplicate columns collapse to one tick' \
            contract    'Issue #185 - set-semantics: percentiles with identical (or column-quantised-identical) values collapse to one tick; orphan ticks have no place in the rendering' \
            detail      "axis ticks ($tick_total) outside [1, $legend_entries] legend entries (-hgw $hgw)"
    fi

    # Position assertion (#450).
    assert_tick_positions "$out" "$report" 1 "-hgw $hgw" || true


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
    # shellcheck disable=SC2086
    "$LTL" --disable-progress -ni $SHAPE --terminal-width 200 -V histogram-percentile-ticks -hg duration,bytes -hgw 95 "$ACCESS_LOG" > "$out" 2>"$out.stderr" || true
    if ! assert_no_runtime_warnings "$out.stderr" "histogram-ticks"; then
        fail=$((fail + 1)); failures+=("perl-runtime-warnings-on-stderr")
    fi

    local report
    report=$(inspect_output "$out")

    local oo
    oo=$(echo "$report" | sed -n 's/^OUT_OF_AXIS:\([0-9]*\)$/\1/p')
    if [[ "$oo" == "0" ]]; then
        note_pass "no ticks outside axis (multi)"
    else
        emit_fail \
            label       "out-of-axis ticks (multi)" \
            asserts     'In a multi-histogram run, percentile tick characters still appear only on histogram x-axis frame rows; tick leakage into other rows is a layout regression that the single-width tests can miss because multi-histogram layout takes a different code path' \
            produced_by 'print_histograms() in ltl - render_histogram_x_axis() runs once per metric for -hg duration,bytes; each must restrict tick emission to its own axis row' \
            contract    'Issue #185 - multi-histogram is the panel-stacking variant; the same axis-row containment invariant applies independently to each panel' \
            detail      "found $oo lines with ticks outside axis (multi)"
    fi

    # Per-histogram tick-vs-legend invariant: 1 <= ticks <= entries.
    for hidx in 1 2; do
        local tick legend
        tick=$(echo "$report" | awk -F: -v h="$hidx" '/^AXIS:1:/ && $3==h {for (i=1;i<=NF;i++) if ($i ~ /^total=/) {split($i,a,"="); print a[2]}}')
        legend=$(echo "$report" | awk -F: -v h="$hidx" '/^LEGEND:1:/ && $3==h {for (i=1;i<=NF;i++) if ($i ~ /^entries=/) {split($i,a,"="); print a[2]}}')
        if [[ -z "$tick" || -z "$legend" ]]; then
            emit_fail \
                label       "tick/legend extraction (multi hist#$hidx)" \
                asserts     "The inspector must successfully extract both an AXIS tick total and a LEGEND entry count for histogram panel #$hidx; missing data here means the panel was not rendered, or its legend was emitted on a row the inspector cannot identify" \
                produced_by 'print_histograms() (per-panel rendering) + inspect_output() per-segment splitting in this harness' \
                contract    'tests/HARNESS-DESIGN.md section Harnesses must fail on missing anchors - multi-histogram extraction failures must not silently degrade to a passing test' \
                detail      "could not extract counts for hist#$hidx (multi): tick='$tick' legend='$legend'"
        elif [[ "$tick" -ge 1 && "$tick" -le "$legend" ]]; then
            note_pass "hist#$hidx ticks ($tick) within [1, $legend] legend entries"
        else
            emit_fail \
                label       "tick/legend cardinality (multi hist#$hidx)" \
                asserts     "Histogram panel #$hidx has at least 1 axis tick and no more axis ticks than legend entries; each panel carries its own independent tick set matching its own legend" \
                produced_by 'calculate_histogram_percentile_ticks() in ltl - tick column derivation runs independently per panel' \
                contract    'Issue #185 - multi-histogram panels carry independent tick sets; cross-panel sharing would create the orphan-tick failure mode this assertion exists to prevent' \
                detail      "hist#$hidx ticks ($tick) outside [1, $legend] legend entries"
        fi

        assert_tick_positions "$out" "$report" "$hidx" "panel #$hidx" || true

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
