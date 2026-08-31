#!/usr/bin/env perl
# selector.pl — prototype (#452, trigger (d)): select ONE timeline column's
# cells out of a rendered timeline row, driven by the --debug-layout table,
# so a harness can assert colour, fill and centring per column rather than
# per line. Consumes tests/lib/rendered-output.pl for the cell decoding.
#
# The question this prototype answers: can the offsets printed by the layout
# engine's own debug table locate a column's cells reliably enough to state
# AC3 (no bar, coloured value), AC5 (centred value) and AC6 (following
# columns' colours unchanged) as assertions that distinguish known-good from
# known-bad rendering?

use strict;
use warnings;

# parse_debug_layout($capture_path) -> arrayref of { id, start, width }
# for every VISIBLE column, 0-based start offset in display cells.
# Offsets are accumulated exactly as the layout engine spends width:
# before-spacing, then the column, then after-spacing; invisible columns
# (Vis 0) spend nothing. A capture with no debug table is a hard failure,
# never an empty result (HARNESS-DESIGN: a grep that matches nothing fails).
sub parse_debug_layout {
    my ($capture) = @_;
    open my $fh, '<:encoding(UTF-8)', $capture or die "cannot open $capture: $!\n";
    my ( $in_table, $pos ) = ( 0, 0 );
    my @cols;
    while ( my $line = <$fh> ) {
        if ( $line =~ /^--- Layout Engine Debug/ ) { $in_table = 1; next }
        next unless $in_table;
        last if $line =~ /^---\s*$/;
        next if $line =~ /^\s*Column\s+Type/;
        next if $line =~ /TOTAL/;
        if ( $line =~ /^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*$/ ) {
            my ( $id, $type, $width, $bef, $aft, $vis ) = ( $1, $2, $3, $4, $5, $6 );
            next unless $vis;
            die "visible column $id has non-numeric width '$width'\n" unless $width =~ /^\d+$/;
            $pos += $bef;
            push @cols, { id => $id, start => $pos, width => $width };
            $pos += $width + $aft;
        }
    }
    close $fh;
    die "no Layout Engine Debug table found in $capture\n" unless $in_table && @cols;
    return \@cols;
}

# column_slice($cells, $layout, $id) -> arrayref of the column's cells.
# Missing column id is a hard failure, not an empty slice.
sub column_slice {
    my ( $cells, $layout, $id ) = @_;
    my ($col) = grep { $_->{id} eq $id } @$layout;
    die "column '$id' is not a visible column in the layout table\n" unless $col;
    my ( $s, $w ) = ( $col->{start}, $col->{width} );
    die "row has " . scalar(@$cells) . " cells; column $id needs [$s," . ( $s + $w ) . ")\n"
        if @$cells < $s + $w;
    return [ @{$cells}[ $s .. $s + $w - 1 ] ];
}

# centred_report($slice) -> "centred" | description of the imbalance.
# The rule under test (feature doc AC5): on an odd remainder the extra space
# sits on the LEFT, so left padding is equal to or one greater than right.
sub centred_report {
    my ($slice) = @_;
    my $text = join '', map { $_->{ch} } @$slice;
    return 'empty' if $text =~ /^\s*$/;
    my ($left)  = $text =~ /^( *)/;
    my ($right) = $text =~ /( *)$/;
    my ( $l, $r ) = ( length $left, length $right );
    return 'centred' if $l == $r || $l == $r + 1;
    return "left=$l right=$r (not centred)";
}

1;
