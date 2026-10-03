#!/usr/bin/env bash
# validate-histogram-colours.sh — the colours the histogram renders, read cell
# by cell from the rendered output (Issue #653).
#
# A render-invariant harness (tests/HARNESS-DESIGN.md § Render-invariant
# harnesses, § Asserting rendered output): what is asserted is the colour a
# reader sees on each cell, decoded by tests/lib/rendered-output.pl, never an
# escape sequence grepped from the line.
#
# What it holds today, from features/653-histogram-highlight-row-light-background.md
# § Contracts and § Acceptance criteria:
#   - the highlighted percentile row's text is black (256-colour index 0) under
#     -lbg, under -dbg and with neither option (C1, AC1);
#   - that text is the same black the timeline's highlighted fill of the same
#     metric carries in the same run (C1, AC2);
#   - with two metrics, each highlighted row sits on a band of its own metric's
#     highlight colour, carries the black text, and lists the same percentiles
#     in the same order as the population row above it (C1, C2, AC3).
#
# Locating the rows. The histogram section's row range comes from
# -V section-layout (the rows of the same run without -V): its last row is the
# highlighted percentile row and the row above it is the population's. A
# metric's band and population text are matched to the metric by the nearest
# "<Metric> Distribution" title in the same section, because the histograms
# print side by side. Timeline cells are cut to one column by the layout
# engine's own offsets (--debug-layout).
#
# Invocation shape (HARNESS-DESIGN.md § Invocation coherence): the committed
# status-family fixture, ten lines in one day, with -h on the path three of
# them share, so the highlight is live and both rows print. -bs 1440 -oe: one
# bucket, no empty ones; -n 1: the messages table is not read; -ni: the
# developer's index is left alone; --terminal-width 160 pins the layout.
#
# Usage: ./tests/validate-histogram-colours.sh [--scenario NAME | --list]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

LTL="$REPO_DIR/ltl"
PERL="${PERL:-/opt/homebrew/bin/perl}"
command -v "$PERL" >/dev/null 2>&1 || PERL=perl
export PERL

FIXTURE="$REPO_DIR/tests/fixtures/http-status-families.txt"
HIGHLIGHT="/store/orders"
WIDTH=160

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/rendered-output.sh
source "$SCRIPT_DIR/lib/rendered-output.sh"
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"

scenario_register legend-text-light \
                  legend-text-dark \
                  legend-text-default \
                  legend-matches-timeline \
                  legend-each-metric
SCENARIO_USAGE_NOTE="Scenarios follow features/653-histogram-highlight-row-light-background.md § Acceptance criteria."
scenario_parse_args "$@"

neutralize_colour_env

for f in "$LTL" "$FIXTURE"; do
    [[ -e "$f" ]] || { echo "ERROR: missing $f"; exit 1; }
done

TMP_DIR=$(mktemp -d); trap 'rm -rf "$TMP_DIR"' EXIT

pass=0; fail=0; failures=(); current_scenario=""

CONTRACT_653="features/653-histogram-highlight-row-light-background.md"

assert_command() {
    local command label asserts produced_by contract
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
    : "${command:?assert_command requires command}"
    : "${label:?assert_command requires label}"
    : "${asserts:?assert_command requires asserts}"
    : "${produced_by:?assert_command requires produced_by}"
    : "${contract:?assert_command requires contract}"
    local cmd_out cmd_rc
    set +e
    cmd_out=$(eval "$command" 2>&1); cmd_rc=$?
    set -e
    if [[ "$cmd_rc" -eq 0 ]]; then
        echo "  PASS  $current_scenario :: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario :: $label"
        echo "        command:     $command"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        echo "$cmd_out" | sed 's/^/        | /'
        fail=$((fail + 1))
        failures+=("$current_scenario :: $label")
    fi
}

# capture_run OUTFILE ARGS... — one render with ANSI intact and
# -V section-layout, stderr to OUTFILE.stderr. A non-zero exit or an empty
# capture is a hard failure. The run's stderr is then checked for Perl runtime
# warnings and the whole capture for lines wider than the terminal; both are
# counted as assertions of the scenario that asked for the capture.
capture_run() {
    local outfile="$1"; shift
    local rc
    set +e
    with_ansi_colour "$LTL" --disable-progress --terminal-width "$WIDTH" \
        -ni -bs 1440 -oe -n 1 -h "$HIGHLIGHT" -V section-layout "$@" "$FIXTURE" \
        > "$outfile" 2> "$outfile.stderr"
    rc=$?
    set -e
    if [[ $rc -ne 0 || ! -s "$outfile" ]]; then
        echo "ERROR: capture failed (rc=$rc) for: $*" >&2
        sed 's/^/    /' "$outfile.stderr" >&2
        exit 1
    fi

    if assert_no_runtime_warnings "$outfile.stderr" "$current_scenario"; then
        echo "  PASS  $current_scenario :: no Perl runtime warning on stderr ($*)"
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        failures+=("$current_scenario :: runtime warnings ($*)")
    fi

    if assert_no_soft_wrap "$outfile" "$WIDTH" "$current_scenario"; then
        echo "  PASS  $current_scenario :: output fits $WIDTH columns ($*)"
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        failures+=("$current_scenario :: soft wrap ($*)")
    fi
}

# legend_report CAPTURE [LAYOUT_FILE] — decoded facts about the histogram's
# percentile rows, one line per item:
#   band metric=M fill=F text=T cells=N labels=P10,P25,...
#   population metric=M text=T labels=P10,P25,...
#   timeline metric=M fill=F text=T cells=N      (only with LAYOUT_FILE)
# "text" is the set of foreground colours over the item's non-blank cells.
# A timeline line reports the cells of metric M's timeline column whose
# background is the colour of M's band. Any anchor that is not found (the
# section-layout table, the histogram's row range, a title, a band) is a
# hard failure, never an empty report.
legend_report() {
    local capture="$1" layout="${2:-}"
    "$PERL" -e '
        require $ARGV[0];
        binmode(STDOUT, ":encoding(UTF-8)");
        my ($lib, $file, $layout_file) = @ARGV;
        open my $fh, "<:encoding(UTF-8)", $file or die "cannot open $file: $!\n";
        my @lines = <$fh>;
        close $fh;

        # Section rows from -V section-layout.
        my (%sec, $in);
        for (@lines) {
            if (/^=== section-layout ===$/)     { $in = 1; next }
            if (/^=== END section-layout ===$/) { $in = 0; next }
            next unless $in;
            chomp;
            my ($name, $state, $start, $rows) = split /\t/;
            next unless defined $rows && $start =~ /^\d+$/;
            $sec{$name} = { start => $start, rows => $rows, state => $state };
        }
        my $h = $sec{histogram} or die "no rendered histogram row in -V section-layout\n";
        die "histogram has $h->{rows} rows; needs a population and a highlighted row\n" if $h->{rows} < 2;
        my $first = $h->{start};
        my $last  = $h->{start} + $h->{rows} - 1;
        die "histogram rows $first..$last run past the capture\n" if $last > @lines;
        my $row = sub { decode_line($lines[$_[0] - 1]) };

        # Metric titles and their centre column.
        my @titles;
        for my $r ($first .. $last) {
            my $t = row_text($row->($r));
            while ($t =~ /(\S+) Distribution/g) {
                my $metric = lc $1;
                my $centre = $-[0] + (length("$1 Distribution") - 1) / 2;
                push @titles, { metric => $metric, centre => $centre };
            }
            last if @titles;
        }
        die "no \"<Metric> Distribution\" title in histogram rows $first..$last\n" unless @titles;
        my $metric_at = sub {
            my ($centre) = @_;
            my ($best) = sort { abs($a->{centre} - $centre) <=> abs($b->{centre} - $centre) } @titles;
            return $best->{metric};
        };

        # Runs of contiguous cells sharing a predicate.
        my $runs = sub {
            my ($cells, $in_run) = @_;
            my (@out, $cur);
            for my $i (0 .. $#$cells) {
                if ($in_run->($cells->[$i])) {
                    $cur //= { from => $i, cells => [] };
                    push @{ $cur->{cells} }, $cells->[$i];
                } elsif ($cur) { push @out, $cur; undef $cur }
            }
            push @out, $cur if $cur;
            return @out;
        };
        my $text_set = sub {
            my %s = map { $_->{fg} => 1 } grep { $_->{ch} ne " " } @{ $_[0] };
            return join(",", sort keys %s) || "none";
        };
        my $labels = sub {
            my $t = join "", map { $_->{ch} } @{ $_[0] };
            my @l = $t =~ /(P[0-9.]+):/g;
            return @l ? join(",", @l) : "none";
        };
        my $centre_of = sub { $_[0]{from} + (@{ $_[0]{cells} } - 1) / 2 };

        my %band_fill;
        my @bands = $runs->($row->($last), sub { $_[0]{bg} ne "default" });
        die "no filled band on the histogram row $last (the highlighted percentile row)\n" unless @bands;
        for my $b (@bands) {
            my %fills = map { $_->{bg} => 1 } @{ $b->{cells} };
            my $fill = join ",", sort keys %fills;
            my $m = $metric_at->($centre_of->($b));
            $band_fill{$m} = $fill;
            printf "band metric=%s fill=%s text=%s cells=%d labels=%s\n",
                $m, $fill, $text_set->($b->{cells}), scalar @{ $b->{cells} }, $labels->($b->{cells});
        }

        my @pop = $runs->($row->($last - 1), sub { $_[0]{fg} ne "default" && $_[0]{bg} eq "default" });
        die "no coloured text on the histogram row " . ($last - 1) . " (the population percentile row)\n" unless @pop;
        for my $p (@pop) {
            printf "population metric=%s text=%s labels=%s\n",
                $metric_at->($centre_of->($p)), $text_set->($p->{cells}), $labels->($p->{cells});
        }

        exit 0 unless $layout_file;
        my $layout = parse_debug_layout($layout_file);
        my $t = $sec{timeline} or die "no rendered timeline row in -V section-layout\n";
        for my $m (sort keys %band_fill) {
            my @hit;
            for my $r ($t->{start} .. $t->{start} + $t->{rows} - 1) {
                my $cells = $row->($r);
                my $slice = eval { column_slice($cells, $layout, $m) } or next;
                push @hit, grep { $_->{bg} eq $band_fill{$m} } @$slice;
            }
            printf "timeline metric=%s fill=%s text=%s cells=%d\n",
                $m, $band_fill{$m}, $text_set->(\@hit), scalar @hit;
        }
    ' "$SCRIPT_DIR/lib/rendered-output.pl" "$capture" "$layout"
}

# report_for CAPTURE [LAYOUT] -> writes CAPTURE.report; a failed report is a
# hard failure of the scenario, printed with its reason.
report_for() {
    local capture="$1" layout="${2:-}"
    if ! legend_report "$capture" "$layout" > "$capture.report" 2> "$capture.report.err"; then
        echo "  FAIL  $current_scenario :: could not locate the histogram's percentile rows"
        echo "        asserts:     the histogram section's last two rows are its population and highlighted percentile rows"
        echo "        produced_by: print_histograms() in ltl (row order), print_section_layout() in ltl (row range)"
        echo "        contract:    features/597-section-visibility.md section D3 (section-layout rows); $CONTRACT_653"
        sed 's/^/        | /' "$capture.report.err"
        fail=$((fail + 1))
        failures+=("$current_scenario :: rows not located")
        return 1
    fi
    sed 's/^/        . /' "$capture.report"
}

# Text of the highlighted percentile row is index-0 black for one background
# option (AC1).
legend_text_black() {
    local bg_label="$1"; shift
    local cap="$TMP_DIR/legend-$current_scenario.out"
    capture_run "$cap" -hg duration "$@"
    report_for "$cap" || return 0
    assert_command \
        label "the highlighted duration percentile row has black text (256:0) on every non-blank cell, $bg_label" \
        command "grep -qE '^band metric=duration fill=256:[0-9]+ text=256:0 cells=[1-9][0-9]* labels=P' '$cap.report'" \
        asserts "the highlighted percentile row prints its text in index-0 black whatever the background option, because its band is a bright colour on every background and white text on it cannot be read" \
        produced_by "render_histogram_legend() in ltl (the highlighted row's text colour)" \
        contract "$CONTRACT_653 C1, AC1, D2"
}

if scenario_wanted legend-text-light; then
current_scenario="legend-text-light"
legend_text_black "under -lbg" -lbg
fi

if scenario_wanted legend-text-dark; then
current_scenario="legend-text-dark"
legend_text_black "under -dbg" -dbg
fi

if scenario_wanted legend-text-default; then
current_scenario="legend-text-default"
legend_text_black "with no background option"
fi

if scenario_wanted legend-matches-timeline; then
current_scenario="legend-matches-timeline"
cap="$TMP_DIR/legend-timeline.out"
capture_run "$cap" -hg duration -lbg --debug-layout
grep -q '^--- Layout Engine Debug' "$cap.stderr" || {
    echo "ERROR: no Layout Engine Debug table on stderr of the --debug-layout run" >&2; exit 1; }
if report_for "$cap" "$cap.stderr"; then
    assert_command \
        label "the highlighted duration row's text colour equals the text on the timeline's highlighted duration fill (-lbg)" \
        command "b=\$(sed -nE 's/^band metric=duration fill=([^ ]+) text=([^ ]+) .*/\\1 \\2/p' '$cap.report'); t=\$(sed -nE 's/^timeline metric=duration fill=([^ ]+) text=([^ ]+) cells=([1-9][0-9]*)\$/\\1 \\2/p' '$cap.report'); echo \"band: \$b\"; echo \"timeline: \$t\"; [[ -n \$b && -n \$t && \$b == \"\$t\" && \$t != *,* ]]" \
        asserts "the highlighted percentile row reads like every highlighted fill: its band is the duration column's highlighted fill colour and its text is the one colour the timeline prints on that fill, in the same run" \
        produced_by "render_histogram_legend() in ltl (band and text); print_bar_graph() in ltl (the timeline's highlighted fill, from the highlighted_bg entry of @column_colors)" \
        contract "$CONTRACT_653 C1, C2, AC2, D2; features/histogram-charts.md Decisions Log, Highlight colors match bar graph highlight_bg"
fi
fi

if scenario_wanted legend-each-metric; then
current_scenario="legend-each-metric"
cap="$TMP_DIR/legend-metrics.out"
capture_run "$cap" -hg duration,bytes -lbg
if report_for "$cap"; then
    for spec in duration:226 bytes:46; do
        m="${spec%%:*}"; c="${spec##*:}"
        assert_command \
            label "the highlighted $m row is a band of 256:$c with black text (256:0)" \
            command "grep -qE '^band metric=$m fill=256:$c text=256:0 cells=[1-9][0-9]* labels=P' '$cap.report'" \
            asserts "each metric's highlighted percentile row sits on a band of that metric's own highlight colour (duration 226, bytes 46, as the timeline's highlighted fills) and carries index-0 black text" \
            produced_by "render_histogram_legend() in ltl (band from %histogram_highlight_colors, text colour)" \
            contract "$CONTRACT_653 C1, C2, AC3; features/histogram-charts.md Decisions Log, Highlight colors match bar graph highlight_bg"
        assert_command \
            label "the highlighted $m row lists the same percentiles, in the same order, as the $m population row" \
            command "b=\$(sed -nE 's/^band metric=$m .* labels=([^ ]+)\$/\\1/p' '$cap.report'); p=\$(sed -nE 's/^population metric=$m .* labels=([^ ]+)\$/\\1/p' '$cap.report'); echo \"band: \$b\"; echo \"population: \$p\"; [[ -n \$b && \$b != none && \$b == \"\$p\" ]]" \
            asserts "the two percentile rows of one metric carry the same percentile selection in the same order, so the reader compares them column for column" \
            produced_by "render_histogram_legend() in ltl (the highlighted row reuses the population row's selection)" \
            contract "$CONTRACT_653 C2, AC3; features/histogram-charts.md Decisions Log, Two legend lines when highlight exists"
    done
fi
fi

# ---------------------------------------------------------------------------
echo
echo "Results: $pass passed, $fail failed"
if [[ $fail -gt 0 ]]; then
    echo "Failed:"
    for f in "${failures[@]}"; do echo "  - $f"; done
    exit 1
fi
if [[ $pass -eq 0 ]]; then
    echo "FAIL: no assertion ran"
    exit 1
fi
exit 0
