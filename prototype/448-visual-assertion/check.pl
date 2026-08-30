#!/usr/bin/env perl
use strict; use warnings;
require "/Users/gregeva/Documents/GitHub/logtimeline/prototype/448-visual-assertion/render-grid.pl";
my ($file, $label, $ROW_WIDTH) = @ARGV;
$ROW_WIDTH //= 41;
open my $fh, '<', $file or die $!;
my @lines = <$fh>; close $fh;
for my $l (@lines) {
    my $plain = $l; $plain =~ s/\e\[[0-9;]*m//g;
    # The summary table occupies a fixed row width; the file-details pane is
    # printed on the same physical line and is NOT part of the row. Isolate the
    # row before decoding, and match the label exactly (a prefix match picks the
    # "(HL)" twin when asked for its plain sibling).
    next unless $plain =~ /^  \Q$label\E\s+\d/;
    my $cells = decode_line($l);
    @$cells = @{$cells}[0 .. ($ROW_WIDTH + 1)] if @$cells > $ROW_WIDTH + 2;
    my ($bad, $filled, $plaincount) = bar_inverts($cells);
    printf "%-22s extent=%-3d fill=%-9s text=%-9s width=%d\n",
        $label, fill_extent($cells), fill_colour($cells), text_colour($cells), scalar(@$cells);
    print "    VIOLATION: $_\n" for @$bad[0 .. ($#$bad > 1 ? 1 : $#$bad)];
    last;
}
