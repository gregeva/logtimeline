#!/usr/bin/env perl
# rendered-output.pl — decode a rendered terminal line into the cells a terminal
# would actually display, so a harness can assert what the READER SEES rather
# than which escape sequence was emitted
# (tests/HARNESS-DESIGN.md § Asserting rendered output).
#
# Why this exists. A harness that greps the raw output for an escape sequence
# confirms only that some code was emitted somewhere on the line. It cannot say
# WHICH cell carries an attribute, what the COMBINATION of foreground and
# background on one cell is, how two rows COMPARE, or that an attribute is
# ABSENT. Worse, such a grep is written from the implementation: when a bar was
# built from the wrong colour vocabulary under #448, assertions were written for
# the codes that vocabulary emits and they passed — 23 of them, against five
# simultaneous defects. Decoding to cells makes the assertion a statement of the
# requirement instead.
#
# Public functions:
#   decode_line($line)                -> arrayref of { ch, fg, bg } per cell
#   display_width($line)              -> printable columns (escapes are 0-width)
#   fill_extent($cells)               -> cells carrying a background
#   fill_colour($cells)               -> the single fill colour, 'none', or MIXED:
#   text_colour($cells)               -> colours of unfilled, non-blank cells
#   bar_inverts($cells)               -> (violations, filled, plain)
#   row_text($cells)                  -> the characters, escapes removed
#   slice_row($cells, $width)         -> the first $width cells (row isolation)
#   parse_debug_layout($capture)      -> visible columns' {id,start,width} offsets
#   column_slice($cells, $layout, $id)-> one timeline column's cells
#   centred_report($slice)            -> 'centred' or the imbalance
#
# Attribute vocabulary: 'default', "ansi:<code>" (30-37/90-97 fg, 40-47/100-107
# bg), "256:<n>" for 38;5;n / 48;5;n, and 'reverse' for SGR 7.
#
# TRAPS, each of which produced a wrong answer while this was written:
#   - Decode UTF-8 BEFORE measuring. The box-drawing rules are multi-byte;
#     counting bytes reports a 160-column rule as 480 and manufactures failures
#     that do not exist.
#   - 38;5;0 is a 256-colour BLACK FOREGROUND, not a reset. Reading SGR
#     parameters with a regex that matches a trailing ";0" treats every bar
#     fill's black text as a reset and measures a full-width bar as zero.
#     Parameters are read as whole values, longest first.
#   - Isolate the row before decoding. The file-details pane is printed on the
#     same physical line as the summary table; decoding the whole line pulls its
#     colours into the row's attribute set and reports phantom violations.
#
# This file is meant to be require'd by a Perl helper, not executed directly.

use strict;
use warnings;

# Decode one rendered line into per-cell records. The caller must already have
# decoded UTF-8 (open the capture with '<:encoding(UTF-8)').
sub decode_line {
    my ($line) = @_;
    my @cells;
    my ($fg, $bg) = ('default', 'default');

    while ($line =~ /\G(\e\[([0-9;]*)m|\e\][^\a]*\a|\e\[[0-9;]*[A-Za-z]|.)/gs) {
        my ($tok, $sgr) = ($1, $2);

        if (defined $sgr) {
            my @params = split /;/, $sgr, -1;
            @params = ('0') unless grep { $_ ne '' } @params;
            my $i = 0;
            while ($i <= $#params) {
                my $p = $params[$i];
                # A 256-colour triplet carries its own digits: consume all three
                # so its final value is never read as a standalone parameter.
                if ( ($p eq '38' || $p eq '48') && ( $params[$i+1] // '' ) eq '5' ) {
                    my $v = $params[$i+2] // '';
                    $p eq '38' ? ( $fg = "256:$v" ) : ( $bg = "256:$v" );
                    $i += 3;
                    next;
                }
                if    ( $p eq '0' || $p eq '' ) { ( $fg, $bg ) = ( 'default', 'default' ) }
                elsif ( $p eq '39' )            { $fg = 'default' }
                elsif ( $p eq '49' )            { $bg = 'default' }
                elsif ( $p eq '7' )             { ( $fg, $bg ) = ( 'reverse', 'reverse' ) }
                elsif ( $p =~ /^(?:3[0-7]|9[0-7])$/ )   { $fg = "ansi:$p" }
                elsif ( $p =~ /^(?:4[0-7]|10[0-7])$/ )  { $bg = "ansi:$p" }
                $i++;
            }
            next;
        }

        next if $tok =~ /\A\e/;              # a non-SGR escape: no cell
        next if $tok eq "\r" || $tok eq "\n";
        next if ord($tok) < 32;              # C0 controls occupy no column
        push @cells, { ch => $tok, fg => $fg, bg => $bg };
    }
    return \@cells;
}

# Printable columns the line occupies. This is what a terminal compares against
# its width to decide whether to soft-wrap.
sub display_width {
    my ($line) = @_;
    return scalar @{ decode_line($line) };
}

# The characters of a decoded row, escapes and controls already removed.
sub row_text {
    my ($cells) = @_;
    return join '', map { $_->{ch} } @$cells;
}

# The first $width cells. The summary table shares its physical line with the
# file-details pane, so a row is sliced to its own budget before it is judged.
sub slice_row {
    my ($cells, $width) = @_;
    return $cells if @$cells <= $width;
    return [ @{$cells}[ 0 .. $width - 1 ] ];
}

# How many cells the bar covers.
sub fill_extent {
    my ($cells) = @_;
    return scalar grep { $_->{bg} ne 'default' } @$cells;
}

# The fill colour: one value, 'none' when nothing is filled, or 'MIXED:a,b' when
# the fill is not uniform — which is itself a defect worth naming.
sub fill_colour {
    my ($cells) = @_;
    my %seen = map { $_->{bg} => 1 } grep { $_->{bg} ne 'default' } @$cells;
    my @k = sort keys %seen;
    return 'none'   if @k == 0;
    return $k[0]    if @k == 1;
    return 'MIXED:' . join( ',', @k );
}

# The colour of the row's text where it is NOT filled. 'none' means the row is
# rendering in the terminal's default — which for a category row is the #448
# defect where a row with no bar lost its colour entirely.
sub text_colour {
    my ($cells) = @_;
    my %seen = map { $_->{fg} => 1 }
               grep { $_->{bg} eq 'default' && $_->{ch} ne ' ' } @$cells;
    my @k = sort grep { $_ ne 'default' } keys %seen;
    return @k ? join( ',', @k ) : 'none';
}

# "The bar inverts": inside the fill the colour is the BACKGROUND and the text
# is black; outside it the colour is the FOREGROUND and there is no background.
# Never a foreground and a background colour at once — that inversion is what
# keeps the row legible on a dark terminal and on a light one, because the
# terminal supplies the surrounding foreground either way.
#
# Returns (arrayref of violation strings, filled cells, plain cells).
sub bar_inverts {
    my ($cells) = @_;
    my @violations;
    my ( $filled, $plain ) = ( 0, 0 );

    for my $i ( 0 .. $#$cells ) {
        my $c = $cells->[$i];
        next if $c->{ch} eq ' ' && $c->{bg} eq 'default';   # padding

        if ( $c->{bg} ne 'default' ) {
            $filled++;
            push @violations,
                "col $i: filled cell carries $c->{fg} text, expected black (256:0)"
                unless $c->{fg} eq '256:0' || $c->{fg} eq 'reverse';
        }
        else {
            $plain++;
            push @violations, "col $i: unfilled cell has no colour of its own"
                if $c->{fg} eq 'default';
        }
    }
    return ( \@violations, $filled, $plain );
}

1;

# --- Timeline column selection (#452) ----------------------------------------
# Locate one timeline COLUMN's cells by the offsets the layout engine itself
# reports (--debug-layout), so a predicate can assert colour, fill and
# centring per column rather than per line. Method demonstrated and validated
# against the #448 defect classes in prototype/452-timeline-cell-selector/.

# parse_debug_layout($capture_path) -> arrayref of { id, start, width } for
# every VISIBLE column, 0-based start offset in display cells. Offsets are
# accumulated exactly as the layout engine spends width: before-spacing, the
# column, after-spacing; invisible columns spend nothing. A capture without
# the debug table is a hard failure, never an empty result (HARNESS-DESIGN:
# a grep that matches nothing fails).
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
            my ( $id, $width, $bef, $aft, $vis ) = ( $1, $3, $4, $5, $6 );
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
# A missing column id, or a slice past the row end, is a hard failure — a
# wrong offset must never produce a silent wrong-column read.
sub column_slice {
    my ( $cells, $layout, $id ) = @_;
    my ($col) = grep { $_->{id} eq $id } @$layout;
    die "column '$id' is not a visible column in the layout table\n" unless $col;
    my ( $s, $w ) = ( $col->{start}, $col->{width} );
    die "row has " . scalar(@$cells) . " cells; column $id needs [$s," . ( $s + $w ) . ")\n"
        if @$cells < $s + $w;
    return [ @{$cells}[ $s .. $s + $w - 1 ] ];
}

# centred_report($slice) -> 'centred' | 'empty' | description of the imbalance.
# The centring rule: on an odd remainder the extra space sits on the LEFT
# (features/452-success-failure-percentage-columns.md AC5).
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
