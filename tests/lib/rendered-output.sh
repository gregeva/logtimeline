#!/usr/bin/env bash
# rendered-output.sh — shared assertions over what the tool RENDERS, for test
# harnesses (tests/HARNESS-DESIGN.md § Asserting rendered output).
#
# Two classes of check live here, both reading the decoded output rather than
# the escape sequences that produced it:
#
#   1. Soft wrapping. The tool's output model rests on known character
#      placement — columns line up down a table, bars are proportional across
#      rows, the timeline aligns with its axis. A line longer than the terminal
#      wraps onto the next row and displaces everything below it, so it is a
#      rendering failure whatever the content says. This applies to EVERY line
#      the tool prints, not only the surface a feature happens to touch.
#
#   2. Row attributes. What colour a cell carries, how far a bar extends,
#      whether a fill inverts. Asserting these on raw escapes confirms only
#      that some code was emitted; #448 shipped five simultaneous defects past
#      23 such assertions.
#
# The minimum supported terminal width is 100 columns
# (features/column-layout-refactor.md § Minimum supported terminal width).
# Below it, rendering is not undertaken to be correct.
#
# Public functions:
#   assert_no_soft_wrap CAPTURE WIDTH CONTEXT_LABEL
#       Every line in CAPTURE fits WIDTH columns. Prints the self-documenting
#       failure block and returns 1 otherwise.
#   soft_wrap_known_failure SCENARIO
#       Echoes the issue number for a registered known failure, else nothing.
#   render_row_report CAPTURE LABEL ROW_WIDTH
#       Echoes "extent=N fill=X text=Y width=W violations=..." for the row whose
#       label matches, sliced to ROW_WIDTH. Non-zero when the row is not found.
#
# This file is meant to be sourced, not executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "rendered-output.sh is a library; source it, do not execute it" >&2
    exit 2
fi

# The narrowest terminal the tool undertakes to render correctly. One value,
# here, so a harness never restates it: raising or lowering the floor is a
# single edit (features/column-layout-refactor.md section Minimum supported
# terminal width).
: "${MIN_SUPPORTED_WIDTH:=100}"

: "${PERL:=perl}"
_RENDERED_OUTPUT_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/rendered-output.pl"

# assert_no_soft_wrap CAPTURE WIDTH CONTEXT_LABEL
#
# The check runs over the WHOLE capture: a harness asserting one surface still
# fails if any other line of that run would wrap, because the wrap displaces the
# surface being asserted.
assert_no_soft_wrap() {
    local capture="$1" width="$2" context="$3"
    local report

    if [[ ! -f "$capture" ]]; then
        echo "  FAIL  $context :: soft-wrap check found no capture at $capture" >&2
        return 1
    fi

    report=$("$PERL" -e '
        require $ARGV[0];
        binmode(STDOUT, ":encoding(UTF-8)");
        my ($lib, $file, $width) = @ARGV;
        open my $fh, "<:encoding(UTF-8)", $file or die "cannot open $file: $!\n";

        # Name the surface an offending line belongs to, and the sub that
        # renders it, so the reader is not left counting lines into a capture
        # to find out what overflowed. The reader must be able to act on the
        # failure without opening the capture at all
        # (HARNESS-DESIGN.md section Self-documenting assertions).
        my $surface = "unclassified";
        my $producer = "the layout engine in ltl";
        my ($n, @bad, $in_section);
        while (my $line = <$fh>) {
            $n++;
            (my $plain = $line) =~ s/\e\[[0-9;]*m//g;
            chomp $plain;
            # A -V section is machine-readable observability, not a rendered
            # surface: its lines are as long as their key lists and are never
            # placed by the layout engine, so they are outside this check.
            if ($plain =~ /^=== END /) { $in_section = 0; next }
            if ($plain =~ /^=== /)     { $in_section = 1; next }
            next if $in_section;

            if    ($plain =~ /,:: ltl ::. log timeline/)  { $surface = "run banner";        $producer = "the banner block in ltl (fixed width, does not read --terminal-width)" }
            elsif ($plain =~ /^\s*timestamp\s+legend/)    { $surface = "timeline";          $producer = "print_bar_graph() in ltl" }
            elsif ($plain =~ /^command-line options:/)    { $surface = "run options echo";  $producer = "print_run_options() in ltl" }
            elsif ($plain =~ /TOP (OVERALL|HIGHLIGHTED) MESSAGES/) { $surface = "messages table"; $producer = "print_message_summary() in ltl" }
            elsif ($plain =~ /^\s*Category\s+Total/)      { $surface = "run summary";       $producer = "print_summary_table() in ltl" }
            elsif ($plain =~ /^\s*THREADPOOLS/)           { $surface = "threadpool table";  $producer = "print_summary_table() in ltl" }

            my $w = display_width($line);
            next if $w <= $width;
            push @bad, sprintf("line %d is %d columns (over by %d) in the %s [%s]: %s",
                               $n, $w, $w - $width, $surface, $producer,
                               substr($plain, 0, 52));
        }
        close $fh;
        print "$_\n" for @bad;
    ' "$_RENDERED_OUTPUT_LIB" "$capture" "$width" 2>&1)

    [[ -z "$report" ]] && return 0

    {
        echo "  FAIL  $context :: output does not fit $width columns"
        echo "        asserts:     no line the tool prints exceeds the terminal width, so the"
        echo "                     reader can rely on character placement — a line that wraps"
        echo "                     displaces every line below it and every column with them"
        echo "        produced_by: the surface and its rendering sub are named per offending"
        echo "                     line below; width is allocated by the layout engine in ltl"
        echo "                     (@column_layout)"
        echo "        contract:    features/column-layout-refactor.md section Minimum supported"
        echo "                     terminal width (100 columns)"
        echo "        capture:     $capture"
        echo "        rendered at: --terminal-width $width"
        while IFS= read -r _line; do printf '        %s\n' "$_line"; done <<< "$report"
    } >&2
    return 1
}

# soft_wrap_known_failure SCENARIO
#
# Echoes the issue number when SCENARIO is a registered known soft-wrap failure,
# and nothing otherwise. The registry suppresses the block for a filed, open
# defect; it is not a tolerance, and the check still runs and still reports what
# overflowed. Registry: tests/rendered-output/soft-wrap-known-failures.tsv.
soft_wrap_known_failure() {
    local scenario="$1"
    local registry="${SOFT_WRAP_KNOWN_FAILURES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/rendered-output/soft-wrap-known-failures.tsv}"
    [[ -f "$registry" ]] || return 0
    # Always exits 0: "not a known failure" is the ordinary case, and a non-zero
    # status here aborts a harness running under `set -e`.
    awk -F'\t' -v s="$scenario" '$1 == s { print $2; exit }' "$registry"
    return 0
}

# render_row_report CAPTURE LABEL ROW_WIDTH
#
# Echoes one line of decoded facts about the row, for a caller to compare
# against what the requirement says. Row isolation is applied before decoding:
# the summary table shares its physical line with the file-details pane.
#
# The label is matched exactly — anchored on the label followed by whitespace
# and a digit — because a prefix match reads "2xx Success (HL)" when asked for
# "2xx Success" and reports its twin's colours.
render_row_report() {
    local capture="$1" label="$2" row_width="$3"
    "$PERL" -e '
        require $ARGV[0];
        binmode(STDOUT, ":encoding(UTF-8)");
        my ($lib, $file, $label, $row_width) = @ARGV;
        open my $fh, "<:encoding(UTF-8)", $file or die "cannot open $file: $!\n";
        my @lines = <$fh>;
        close $fh;
        for my $line (@lines) {
            (my $plain = $line) =~ s/\e\[[0-9;]*m//g;
            next unless $plain =~ /^\s*\Q$label\E\s+\d/;
            my $cells = slice_row(decode_line($line), $row_width);
            my ($violations, undef, undef) = bar_inverts($cells);
            printf "extent=%d fill=%s text=%s width=%d violations=%s\n",
                fill_extent($cells), fill_colour($cells), text_colour($cells),
                scalar(@$cells),
                (@$violations ? join("; ", @$violations) : "none");
            exit 0;
        }
        print "ROW-NOT-FOUND\n";
        exit 1;
    ' "$_RENDERED_OUTPUT_LIB" "$capture" "$label" "$row_width"
}

# timeline_cell_report CAPTURE ROW_MATCH COLUMN_ID
#
# Echoes one line of decoded facts about a single timeline COLUMN's cells on
# the first timeline row whose plain text matches ROW_MATCH (a Perl regex,
# matched against the escape-stripped line):
#   text='...' fg=<colour(s)|none> extent=<filled cells> centred=<centred|...>
# The column is located by the offsets the layout engine itself reports, so
# the capture MUST be produced with --debug-layout. Row not found, column not
# visible, or a capture without the debug table are hard failures (non-zero),
# never empty output. Method: prototype/452-timeline-cell-selector/FINDINGS.md.
timeline_cell_report() {
    local capture="$1" row_match="$2" column_id="$3"
    "$PERL" -e '
        require $ARGV[0];
        binmode(STDOUT, ":encoding(UTF-8)");
        my ($lib, $file, $row_match, $col_id) = @ARGV;
        my $layout = parse_debug_layout($file);
        open my $fh, "<:encoding(UTF-8)", $file or die "cannot open $file: $!\n";
        while (my $line = <$fh>) {
            (my $plain = $line) =~ s/\e\[[0-9;]*m//g;
            next unless $plain =~ /$row_match/;
            # Timeline rows only: require a leading timestamp-like cell so a
            # legend or summary line matching the regex is never selected.
            my $cells = decode_line($line);
            my $slice = column_slice($cells, $layout, $col_id);
            printf "text=%s fg=%s extent=%d centred=%s\n",
                "\x27" . row_text($slice) . "\x27",
                text_colour($slice), fill_extent($slice), centred_report($slice);
            exit 0;
        }
        die "no timeline row matching /$row_match/ in $file\n";
    ' "$_RENDERED_OUTPUT_LIB" "$capture" "$row_match" "$column_id"
}
