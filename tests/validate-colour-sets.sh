#!/usr/bin/env bash
# validate-colour-sets.sh — Validate the colours ltl writes for the background:
# the dark set with -dbg, the light set with -lbg, and ltl's own codes when the
# background is not known, the text over every fill black or white, whichever
# reads (features/749-terminal-colour-codes.md AC2, AC4 to AC6, AC8, AC10,
# AC11; D4).
# Usage: ./tests/validate-colour-sets.sh [--scenario NAME]... [--list]
#
# Follows the self-documenting assertion design from tests/HARNESS-DESIGN.md.
# Every assertion records asserts, produced_by and contract.
#
# Why this harness exists: the sets are what the architect validated, cell by
# cell, through the prototype's rewrite of ltl's output (feature doc § 9.1,
# § 12). This harness holds one cell per role in each condition to a table
# copied from the validated sets (palettes/t4.tsv on the issue branch, with
# § 12.8's grey), not read from ltl, so a change to ltl's table fails here.
# The render is the surface under test (tests/HARNESS-DESIGN.md
# § Render-invariant harnesses): each cell is decoded by tests/lib/rendered-output.pl.
#
# Inputs: tests/fixtures/ten-column-metrics.txt, 27 synthetic log lines in three
# 30-minute buckets, each carrying ten metrics named after the ten column
# colours in the order user-defined metrics take them, a third of them the
# token HL, at three levels; tests/fixtures/http-status-families.txt for the
# heatmap and the histogram.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="${LTL:-$REPO_DIR/ltl}"
PERL="${PERL:-perl}"

METRICS="$REPO_DIR/tests/fixtures/ten-column-metrics.txt"
ACCESS="$REPO_DIR/tests/fixtures/http-status-families.txt"
UDM=()
for c in blue magenta red orange pink teal purple yellow green cyan; do UDM+=(-udm "$c::sum"); done

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"

neutralize_colour_env

DOC='features/749-terminal-colour-codes.md'

scenario_register \
    timeline-dark timeline-light timeline-unknown \
    help-dark help-light help-unknown \
    lines-dark lines-light lines-unknown
scenario_parse_args "$@"

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"
    exit 1
fi

pass=0
fail=0
failures=()
current_scenario=""

TMP_DIR=$(mktemp -d); trap 'rm -rf "$TMP_DIR"' EXIT

# The checker: one mode per role, reading a capture through decode_line and
# comparing each cell with the table below. Prints what it found; exits 1 on
# a cell that departs from the table, or on a row or cell it cannot find.
CHECK="$TMP_DIR/colour-check.pl"
cat > "$CHECK" <<'PERL'
use strict;
use warnings;
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
my ( $lib, $mode, $file, $cond, @arg ) = @ARGV;
require $lib;

# The validated sets (palettes/t4.tsv, dark and light columns, with
# § 12.8's grey), and ltl's own codes for when the background is not known,
# in decode_line's vocabulary.
my %want = (
    dark => {
        grey => 'rgb:#797c81', s1 => 'rgb:#d57464', s2 => 'rgb:#6caa71', s3 => 'rgb:#c4ac62', s4 => 'rgb:#719bb9',
        s5 => 'rgb:#bf7dcf', s6 => 'rgb:#7ccbcd', s11 => 'rgb:#e5c872', f208 => '256:208', f213 => '256:213',
        f43 => '256:43', f93 => 'rgb:#9758fe', f160 => 'rgb:#f53629', f178 => '256:178', f111 => '256:111',
        e => 'rgb:#f0f0f0', b21 => '256:27',
    },
    light => {
        grey => 'rgb:#747474', s1 => 'rgb:#b45648', s2 => 'rgb:#5a9860', s3 => 'rgb:#a89046', s4 => 'rgb:#4a799c',
        s5 => 'rgb:#a057b1', s6 => 'rgb:#4fadb0', s11 => 'rgb:#c8ab55', f208 => 'rgb:#db7302', f213 => 'rgb:#e36de4',
        f43 => 'rgb:#05ba97', f93 => '256:93', f160 => '256:160', f178 => 'rgb:#b99709', f111 => 'rgb:#6f96e4',
        e => 'rgb:#313c44', b21 => '256:27',
    },
    unknown => {
        grey => 'ansi:90', s1 => 'ansi:31', s2 => 'ansi:32', s3 => 'ansi:33', s4 => 'ansi:34',
        s5 => 'ansi:35', s6 => 'ansi:36', s11 => 'ansi:93', f208 => '256:208', f213 => '256:213',
        f43 => '256:43', f93 => '256:93', f160 => '256:160', f178 => '256:178', f111 => '256:111',
        e => 'default', b21 => '256:21',
    },
);
my $w = $want{$cond} or die "unknown condition $cond\n";
# Each column colour: its text role, and its plain and highlighted fills as ltl writes them.
my %column = (
    blue => [ 's4', 20, 'b21' ], magenta => [ 's5', 127, 201 ], red => [ 's1', 124, 196 ], orange => [ 'f208', 166, 208 ],
    pink => [ 'f213', 169, 213 ], teal => [ 'f43', 29, 43 ], purple => [ 'f93', 55, 93 ], yellow => [ 's11', 184, 226 ],
    green => [ 's2', 34, 46 ], cyan => [ 's6', 30, 36 ],
);
# Black or white over a fill, whichever has the higher contrast (WCAG 2), from
# the fill's xterm value (D4).
sub text_over {
    my ($fill) = @_;
    my ($n) = $fill =~ /^256:(\d+)$/ or return '?';
    my @lv = ( 0, 95, 135, 175, 215, 255 );
    my @c = $n >= 232 ? ( ( 8 + 10 * ( $n - 232 ) ) x 3 ) : ( $lv[ int( ( $n - 16 ) / 36 ) ], $lv[ int( ( $n - 16 ) / 6 ) % 6 ], $lv[ ( $n - 16 ) % 6 ] );
    my $l = 0;
    my @k = ( 0.2126, 0.7152, 0.0722 );
    for my $i ( 0 .. 2 ) { my $x = $c[$i] / 255; $l += $k[$i] * ( $x <= 0.04045 ? $x / 12.92 : ( ( $x + 0.055 ) / 1.055 )**2.4 ) }
    return 1.05 / ( $l + 0.05 ) > ( $l + 0.05 ) / 0.05 ? '256:231' : '256:16';
}
sub role { my $r = shift; return $r =~ /^\d+$/ ? "256:$r" : $w->{$r} }

open my $fh, '<:encoding(UTF-8)', $file or die "cannot open $file: $!\n";
my @lines = <$fh>;
close $fh;
my @bad;
my $plain = sub { ( my $p = $_[0] ) =~ s/\e\[[0-9;]*m//g; $p };
my $first_row = sub {
    my ($re) = @_;
    for my $l (@lines) { return decode_line($l) if $plain->($l) =~ $re }
    die "no row matching $re in $file\n";
};
my $check = sub { my ( $what, $got, $exp ) = @_; push @bad, "$what: $got, expected $exp" if $got ne $exp };

if ( $mode eq 'rule' ) {
    # The timeline's header rule: a line of rule glyphs that opens with its own colour.
    my ($line) = grep { /^\e\[[0-9;]*m/ && $plain->($_) =~ /^─{20,}\s*$/ } @lines;
    die "no rule line opening with its colour in $file\n" unless defined $line;
    my $cells = decode_line($line);
    $check->( 'the header rule', $cells->[0]{fg}, $w->{grey} );
    print "the header rule in $cells->[0]{fg}\n";
}
elsif ( $mode eq 'legend' ) {
    my $layout = parse_debug_layout($file);
    my $row = $first_row->(qr/^ 2026-08-21 04:00/);
    my $legend = column_slice( $row, $layout, 'legend' );
    my $text = row_text($legend);
    my $at = index( $text, 'ERROR' );
    die "no ERROR in the legend: $text\n" if $at < 0;
    $check->( 'the legend ERROR', $legend->[$at]{fg}, $w->{s1} );
    my @twin = grep { $_->{bg} ne 'default' && $_->{ch} ne ' ' } @$legend;
    die "no highlighted count in the legend\n" unless @twin;
    $check->( "a highlighted count over $_->{bg}", $_->{fg}, text_over( $_->{bg} ) ) for @twin;
    my $occ = column_slice( $row, $layout, 'occurrences' );
    my @hl = grep { $_->{ch} eq "\x{2588}" && $_->{bg} eq '256:226' } @$occ;
    die "no highlighted WARN block in the occurrences bar\n" unless @hl;
    $check->( 'a highlighted WARN block', $_->{fg}, $w->{s3} ) for @hl;
    printf "ERROR in %s; %d highlighted count cells; %d highlighted WARN blocks in %s\n",
        $legend->[$at]{fg}, scalar @twin, scalar @hl, $hl[0]{fg};
}
elsif ( $mode eq 'columns' ) {
    my $layout = parse_debug_layout($file);
    my ( %fills, %texts );
    for my $l ( grep { $plain->($_) =~ /^ 2026-08-21 0[45]:[03]0/ } @lines ) {
        my $row = decode_line($l);
        for my $name ( sort keys %column ) {
            my ( $text_role, $plain_fill, $hl_fill ) = @{ $column{$name} };
            my %fill_ok = map { $_ => 1 } role($plain_fill), role($hl_fill);
            for my $c ( @{ column_slice( $row, $layout, "udm_$name" ) } ) {
                next if $c->{ch} eq ' ' && $c->{bg} eq 'default';
                if ( $c->{bg} ne 'default' ) {
                    $fills{$name}{ $c->{bg} }++;
                    push @bad, "$name: a fill in $c->{bg}, expected " . join( ' or ', sort keys %fill_ok ) unless $fill_ok{ $c->{bg} };
                    $check->( "$name: text over $c->{bg}", $c->{fg}, text_over( $c->{bg} ) ) if $c->{ch} ne ' ';
                } else {
                    $texts{$name}++;
                    $check->( "$name: text past the bar", $c->{fg}, $w->{$text_role} );
                }
            }
        }
    }
    for my $name ( sort keys %column ) {
        push @bad, "$name: no filled cell" unless $fills{$name};
        my $hl = role( $column{$name}[2] );
        push @bad, "$name: no highlighted fill ($hl)" unless $fills{$name}{$hl};
    }
    my %seen; @seen{ map { s/:.*//r } @bad } = ();
    printf "ten columns: fills %s\n", join ' ', map { "$_=" . join( ',', sort keys %{ $fills{$_} } ) } sort keys %fills;
}
elsif ( $mode eq 'summary' ) {
    my $row = $first_row->(qr/^  ERROR\s/);
    my @filled = grep { $_->{bg} ne 'default' } @$row;
    die "the ERROR row draws no contribution bar\n" unless @filled;
    $check->( "ERROR's bar text over $_->{bg}", $_->{fg}, text_over( $_->{bg} ) ) for grep { $_->{ch} ne ' ' } @filled;
    my @after = grep { $_->{bg} eq 'default' && $_->{ch} =~ /\d/ } @$row[ 0 .. 40 ];
    $check->( "ERROR's count past the bar", $after[0]{fg}, $w->{s1} ) if @after;
    my $fail = $first_row->(qr/^  FAILURE CLASSIFIED/);
    my ($fc) = grep { $_->{ch} =~ /\S/ } @$fail;
    $check->( 'FAILURE CLASSIFIED', $fc->{fg}, $w->{f160} );
    my $unc = $first_row->(qr/^  UNCLASSIFIED/);
    my ($uc) = grep { $_->{ch} =~ /\S/ } @$unc;
    $check->( 'UNCLASSIFIED', $uc->{fg}, $w->{f178} );
    my $fmt = $first_row->(qr/windchill_method_server/);
    my $text = row_text($fmt);
    my $at = index( $text, '1 windchill_method_server' );
    die "no format number before windchill_method_server\n" if $at < 0;
    $check->( 'the format number', $fmt->[$at]{fg}, $w->{f111} );
    printf "ERROR's bar %d cells over %s; FAILURE CLASSIFIED %s; UNCLASSIFIED %s; format number %s\n",
        scalar @filled, $filled[0]{bg}, $fc->{fg}, $uc->{fg}, $fmt->[$at]{fg};
}
elsif ( $mode eq 'bold' ) {
    my @bold = map { grep { $_->{bold} && $_->{ch} =~ /\S/ } @{ decode_line($_) } } grep { /\e\[1m/ } @lines;
    die "no bold cell in $file\n" unless @bold;
    my %fg; $fg{ $_->{fg} }++ for @bold;
    $check->( "bold cells", join( ',', sort keys %fg ), $w->{e} );
    printf "%d bold cells in %s\n", scalar @bold, join( ',', sort keys %fg );
}
elsif ( $mode eq 'heatmap-lines' ) {
    my @scale = map { grep { $_->{ch} eq "\x{2534}" } @{ decode_line($_) } } @lines;
    my @marker = map { grep { $_->{ch} eq '|' && $_->{bg} ne 'default' } @{ decode_line($_) } } grep { $plain->($_) =~ /^ 2025-05-07/ } @lines;
    die "no scale line under the heatmap\n" unless @scale;
    die "no percentile marker in the heatmap\n" unless @marker;
    my %fg; $fg{ $_->{fg} }++ for @scale, @marker;
    $check->( 'the heatmap scale line and markers', join( ',', sort keys %fg ), $w->{grey} );
    printf "%d scale and %d marker cells in %s\n", scalar @scale, scalar @marker, join( ',', sort keys %fg );
}
elsif ( $mode eq 'gridlines' ) {
    my $unknown_grid = $cond eq 'unknown' ? '256:8' : $w->{grey};
    my @grid;
    for my $l ( grep { $plain->($_) =~ /^\s*\S*\s*[├┣]/ } @lines ) {
        push @grid, grep { $_->{ch} eq "\x{2500}" && $_->{fg} ne 'default' } @{ decode_line($l) };
    }
    die "no histogram gridline\n" unless @grid;
    my %fg; $fg{ $_->{fg} }++ for @grid;
    $check->( 'the histogram gridlines', join( ',', sort keys %fg ), $unknown_grid );
    printf "%d gridline cells in %s\n", scalar @grid, join( ',', sort keys %fg );
}
else { die "unknown mode $mode\n" }

if (@bad) { print "$_\n" for @bad[ 0 .. ( $#bad < 7 ? $#bad : 7 ) ]; exit 1 }
exit 0;
PERL

# Self-documenting assertion over a command that exits 0 when it holds.
assert_command() {
    local command label asserts produced_by contract out rc=0
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
    out=$(eval "$command" 2>&1) || rc=$?
    if [[ $rc -eq 0 ]]; then
        echo "  PASS  $current_scenario :: $label ($out)"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario :: $label"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        printf '%s\n' "$out" | sed 's/^/        | /' | head -10
        fail=$((fail + 1))
        failures+=("$current_scenario :: $label")
    fi
}

run_failed() {
    echo "  FAIL  $current_scenario :: $1"
    echo "        asserts:     the run exits 0 and writes the output its checks read"
    echo "        produced_by: ltl"
    echo "        contract:    tests/HARNESS-DESIGN.md Trap 13"
    sed 's/^/        | /' "$2" | head -5
    echo "  SKIP  $current_scenario :: its checks (the run gave nothing to read)"
    fail=$((fail + 1)); failures+=("$current_scenario :: $1")
}

# capture OUT ARGS...: ltl piped, standard error beside it; one failure for a
# run that fails or writes nothing, and the runtime-warning check.
capture() {
    local out="$1"; shift
    local rc=0
    "$@" > "$out" 2> "$out.stderr" || rc=$?
    if [[ $rc -ne 0 || ! -s "$out" ]]; then
        run_failed "the run (exit $rc): ${*:2}" "$out.stderr"
        return 1
    fi
    if ! assert_no_runtime_warnings "$out.stderr" "$current_scenario"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
    fi
}

flag_for() { case "$1" in dark) echo -dbg ;; light) echo -lbg ;; *) echo '' ;; esac; }
what_for() { case "$1" in dark) echo 'the dark set (-dbg)' ;; light) echo 'the light set (-lbg)' ;; *) echo "ltl's own codes (the background not known)" ;; esac; }

# ---------------------------------------------------------------------------
# The timeline and the run summary: lines, the legend, the ten column colours
# with their fills, the summary's bars and its classification rows.
# ---------------------------------------------------------------------------
scenario_timeline() {
    local cond="$1"
    scenario_wanted "timeline-$cond" || return 0
    current_scenario="timeline-$cond"
    echo "[$current_scenario]"
    local out="$TMP_DIR/timeline-$cond.txt" what
    what=$(what_for "$cond")
    # shellcheck disable=SC2046
    capture "$out" "$LTL" --disable-progress $(flag_for "$cond") -ni -bs 30m -n 0 -h HL "${UDM[@]}" \
        --terminal-width 190 --debug-layout "$METRICS" || return 0
    # The layout table is written to standard error; the checks read it with the run.
    cat "$out.stderr" >> "$out"
    assert_command \
        command     "'$PERL' '$CHECK' '$SCRIPT_DIR/lib/rendered-output.pl' rule '$out' $cond" \
        label       "the header rule in the grey of $what" \
        asserts     "Every line and all secondary text take one grey: #797c81 on dark, #747474 on light; bright black when the background is not known" \
        produced_by 'resolve_colour_set() in ltl, through %colors' \
        contract    "$DOC AC8; AC2"
    assert_command \
        command     "'$PERL' '$CHECK' '$SCRIPT_DIR/lib/rendered-output.pl' legend '$out' $cond" \
        label       "the legend's categories and highlighted counts, and the occurrences bar, in $what" \
        asserts     "A category takes the set's colour for its hue; a highlighted count is black or white, whichever reads on its fill, in every condition; a highlighted block keeps the category's colour over the fill" \
        produced_by 'resolve_colour_set() and build_highlight_twins() in ltl' \
        contract    "$DOC AC4, AC5, D4"
    assert_command \
        command     "'$PERL' '$CHECK' '$SCRIPT_DIR/lib/rendered-output.pl' columns '$out' $cond" \
        label       "the ten column colours: fills, the text over them, and the text past them, in $what" \
        asserts     "Each column's text past its bar takes the set's colour for it; its fills are today's, but blue's highlighted fill, 27 in both sets and 21 when the background is not known; the text over every fill is black or white, whichever has the higher contrast with the fill" \
        produced_by 'resolve_colour_set() in ltl, through @column_colors' \
        contract    "$DOC AC4, AC5, AC6, D4"
    assert_command \
        command     "'$PERL' '$CHECK' '$SCRIPT_DIR/lib/rendered-output.pl' summary '$out' $cond" \
        label       "the run summary's contribution bar, classification rows and format number in $what" \
        asserts     "The category row still draws its contribution bar, its text over the bar black or white; the classification rows and the format number take the set's colours" \
        produced_by 'summary_bar_color() and summary_category_row() in ltl' \
        contract    "$DOC AC4, AC5, AC11"
}

# ---------------------------------------------------------------------------
# Bold over the default foreground (--help headings and table cells).
# ---------------------------------------------------------------------------
scenario_help() {
    local cond="$1"
    scenario_wanted "help-$cond" || return 0
    current_scenario="help-$cond"
    echo "[$current_scenario]"
    local out="$TMP_DIR/help-$cond.txt" what
    what=$(what_for "$cond")
    # shellcheck disable=SC2046
    capture "$out" with_ansi_colour "$LTL" --disable-progress $(flag_for "$cond") --help || return 0
    assert_command \
        command     "'$PERL' '$CHECK' '$SCRIPT_DIR/lib/rendered-output.pl' bold '$out' $cond" \
        label       "bold in the emphasis colour of $what" \
        asserts     "Bold over the default foreground takes the set's emphasis colour, #f0f0f0 on dark and #313c44 on light, and stays in the default foreground when the background is not known" \
        produced_by 'bs_bold() and colour_emphasis() in ltl' \
        contract    "$DOC AC10; AC2"
}

# ---------------------------------------------------------------------------
# The lines of the heatmap and the histogram.
# ---------------------------------------------------------------------------
scenario_lines() {
    local cond="$1"
    scenario_wanted "lines-$cond" || return 0
    current_scenario="lines-$cond"
    echo "[$current_scenario]"
    local out="$TMP_DIR/lines-$cond.txt" what
    what=$(what_for "$cond")
    # shellcheck disable=SC2046
    capture "$out" "$LTL" --disable-progress $(flag_for "$cond") -ni -bs 1m -n 0 -osum -h /store/orders -hm duration -hg duration \
        --terminal-width 160 "$ACCESS" || return 0
    assert_command \
        command     "'$PERL' '$CHECK' '$SCRIPT_DIR/lib/rendered-output.pl' heatmap-lines '$out' $cond" \
        label       "the heatmap's scale line and percentile markers in the grey of $what" \
        asserts     "The lines around the heatmap take the grey of the header and footer rules" \
        produced_by 'print_heatmap_footer_scale() and print_heatmap_row() in ltl, through %colors' \
        contract    "$DOC AC8, § 12.8"
    assert_command \
        command     "'$PERL' '$CHECK' '$SCRIPT_DIR/lib/rendered-output.pl' gridlines '$out' $cond" \
        label       "the histogram's gridlines in the grey of $what" \
        asserts     "The histogram's gridlines take the set's grey; index 8 when the background is not known" \
        produced_by 'render_histogram_row() in ltl ($histogram_gridline_sgr)' \
        contract    "$DOC AC8, § 12.8"
}

for cond in dark light unknown; do scenario_timeline "$cond"; echo ""; done
for cond in dark light unknown; do scenario_help "$cond"; echo ""; done
for cond in dark light unknown; do scenario_lines "$cond"; echo ""; done

echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
echo "ALL COLOUR-SET TESTS PASSED"
