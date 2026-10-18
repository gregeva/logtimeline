#!/usr/bin/env perl
# P0: candidate glyphs for the notice categories, shown as they would head a
# category in both visual languages, with the width each glyph takes.
#
#   perl p0-glyph-sheet.pl [--style ltl|new|both] [--bg dark|light] [--width N]
#
# In a terminal, each glyph's width is measured: the glyph is printed and the
# terminal is asked where the cursor now stands (CSI 6n). Not in a terminal,
# or when nothing answers, only the width Unicode's properties give is shown.
# A glyph whose measured width differs from that width breaks the alignment of
# anything drawn after it on the row (a box's right edge, a column).

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";
use Getopt::Long;
use NoticeProto qw(interactive terminal_size raw_mode restore_mode
                   query_cursor_column expected_width style_for);

my %opt = ( style => 'both', bg => 'dark' );
GetOptions( \%opt, 'style=s', 'bg=s', 'width=i' ) or die "bad options\n";
my ($width) = terminal_size( width => $opt{width} );

# Candidates per category: ascii, a text-presentation symbol, an emoji.
# The symbols are chosen to read without colour; the emoji to be recognised
# at a glance. VS16 (U+FE0F) asks for emoji presentation of a symbol that
# defaults to text, which is where terminals disagree most.
my @categories = (
    [ 'data anomaly',           [ '!', '⚠', '▲', '◆', "\x{26A0}\x{FE0F}", '🔎' ] ],
    [ 'your options',           [ '>', '⚙', '✎', '⌘', "\x{2699}\x{FE0F}", '🛠' ] ],
    [ 'decision taken for you', [ '~', '↻', '➜', '⤷', '🔁', '🤖' ] ],
    [ 'figure caveat',          [ '*', '≈', '◐', 'ⓘ', 'ℹ', "\x{2139}\x{FE0F}", '📉' ] ],
    [ 'guidance',               [ '?', '➤', '★', '✦', '💡', '🧭', '🔍' ] ],
    [ 'runtime condition',      [ '#', '⏱', '⛭', '⌛', "\x{23F1}\x{FE0F}", '🖥', '⏳' ] ],
);

my $measure = interactive();
my %measured;
if ($measure) {
    raw_mode('cbreak');
    print "\e[?25l";
    for my $g ( map { @{ $_->[1] } } @categories ) {
        next if exists $measured{$g};
        print "\r\e[2K$g";
        my $col = query_cursor_column();
        $measured{$g} = defined $col ? $col - 1 : undef;
        if ( !defined $col ) { $measure = 0; last }
    }
    print "\r\e[2K";
    restore_mode();
}

my $ref = style_for( 'ltl', $opt{bg} );
my $r = $ref->{reset};
my $rule = $ref->{frame} . ( $ref->{box}{h_line} x ( $width - 1 ) ) . $r;

print "$rule\n";
print " P0 glyph sheet: candidate category glyphs   background: $opt{bg}   width: $width\n";
print "   width u = from Unicode properties, t = measured in this terminal"
    . ( $measure ? '' : ' (not measured: no terminal answered)' ) . "\n";
print "   a glyph marked with \e[7m reverse \e[0m is drawn wider or narrower than Unicode says\n";
print "$rule\n\n";

for my $cat (@categories) {
    my ( $name, $glyphs ) = @$cat;
    my $fg = $ref->{fg}{$name};
    printf " %s%-24s%s", $fg, $name, $r;
    for my $g (@$glyphs) {
        my $u = expected_width($g);
        my $t = $measured{$g};
        my $bad = defined $t && $t != $u;
        my $cell = sprintf '%s%s%s %s', $fg, $g, $r, ( defined $t ? "u$u t$t" : "u$u" );
        # The cell is padded by what the terminal measured, so the row stays
        # aligned even where the glyph's width is wrong.
        my $drawn = defined $t ? $t : $u;
        my $pad = 10 - $drawn - length( defined $t ? "u$u t$t" : "u$u" ) - 1;
        $cell = "\e[7m$cell\e[0m" if $bad;
        print '  ', $cell, ' ' x ( $pad > 0 ? $pad : 1 );
    }
    print "\n";
}
print "\n";

# Each glyph as it would head a category, in the chosen languages. The right
# edge of each box is placed by Unicode's width, as a renderer without a
# terminal to ask must place it; a glyph drawn wider pushes the edge out.
my @styles = $opt{style} eq 'both' ? qw(ltl new) : ( $opt{style} );
for my $sname (@styles) {
    my $s = style_for( $sname, $opt{bg} );
    my $b = $s->{box};
    my $inner = 34;
    print " $s->{bold}style: $sname$s->{reset}\n\n";
    for my $cat (@categories) {
        my ( $name, $glyphs ) = @$cat;
        my $fg = $s->{fg}{$name};
        my @heads;
        for my $g ( @$glyphs[ 1 .. $#$glyphs ] ) {
            my $label = " $g " . ucfirst($name) . ' ';
            my $w = expected_width($label);
            my $fill = $inner - $w;
            if ( $sname eq 'ltl' ) {
                push @heads, $s->{frame} . $b->{corner_tl} . $b->{h_line}
                    . $s->{reset} . $fg . $label . $s->{reset}
                    . $s->{frame} . ( $b->{h_line} x $fill ) . $b->{corner_tr} . $s->{reset};
            }
            else {
                push @heads, $fg . $s->{bar} . $s->{reset} . $s->{bold} . $fg . $label
                    . $s->{reset} . $s->{frame} . ( $b->{h_line} x $fill ) . $b->{corner_tr} . $s->{reset};
            }
        }
        # Three headings per row fit an 120-column terminal.
        my $per_row = int( ( $width - 2 ) / ( $inner + 4 ) ) || 1;
        while ( my @row = splice @heads, 0, $per_row ) {
            print ' ', join( '  ', @row ), "\n";
        }
    }
    print "\n";
}
print "$rule\n";
