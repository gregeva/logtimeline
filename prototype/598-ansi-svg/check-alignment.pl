#!/usr/bin/env perl
# Prototype for #598 criterion 11: do full blocks fill their cells, edge to
# edge, as a browser engine displays the SVG?
#
#   check-alignment.pl SVG GRID CELL_WIDTH CELL_HEIGHT
#
# GRID is render.pl --grid output (row, column, colour of every full-block
# cell). The SVG is rasterised by Quick Look (WebKit, the engine Safari uses)
# and converted to BMP with sips, both part of macOS. For each full-block cell
# the pixel colour is sampled at five points: the centre, and just inside the
# top, bottom, left and right edges. Where the cell below or to the right is a
# full block of the same colour, the shared edge itself is sampled too: a seam
# shows there as a pixel of another colour. A sample passes when every channel
# is within TOLERANCE of the cell's colour.
use strict;
use warnings;
use File::Temp qw(tempdir);
use File::Basename qw(basename);

use constant TOLERANCE => 24;
use constant SIZE      => 3200;    # Quick Look thumbnail size, device pixels
# Quick Look lays an SVG out in a view 768 units wide and cuts off the rest
# (measured: a 1519 x 600 SVG at SIZE 3200 filled 2500 pixels of height). The
# SVG is scaled to that width before rasterising.
use constant VIEW      => 768;

die "usage: check-alignment.pl SVG GRID CELL_WIDTH CELL_HEIGHT\n" unless @ARGV == 4;
my ( $svg, $grid_file, $cw, $ch ) = @ARGV;

my $dir = tempdir( CLEANUP => 1 );
open my $src, '<', $svg or die $!;
my $content = do { local $/; <$src> };
my ( $sw, $sh ) = $content =~ /<svg [^>]*width="([\d.]+)" height="([\d.]+)"/ or die "no SVG size\n";
$content =~ s{(<svg [^>]*)width="[\d.]+" height="[\d.]+"}{ sprintf '%swidth="%s" height="%s"', $1, VIEW, VIEW * $sh / $sw }e;
open my $fit, '>', "$dir/fit.svg" or die $!;
print {$fit} $content;
close $fit;
system( 'qlmanage', '-t', '-s', SIZE, '-o', $dir, "$dir/fit.svg" ) == 0 or die "qlmanage failed\n";
my $png = "$dir/fit.svg.png";
system( 'sips', '-s', 'format', 'bmp', $png, '--out', "$dir/r.bmp" ) == 0 or die "sips failed\n";

# ---- BMP ---------------------------------------------------------------------
open my $fh, '<:raw', "$dir/r.bmp" or die $!;
my $bmp = do { local $/; <$fh> };
my ( $offset ) = unpack 'V', substr $bmp, 10, 4;
my ( $bw, $bh ) = unpack 'l<l<', substr $bmp, 18, 8;
my ( $bpp )     = unpack 'v', substr $bmp, 28, 2;
my $top_down = $bh < 0;
$bh = abs $bh;
my $bytes = $bpp / 8;
my $stride = int( ( $bw * $bytes + 3 ) / 4 ) * 4;
sub pixel {
    my ( $x, $y ) = @_;
    my $row = $top_down ? $y : $bh - 1 - $y;
    my ( $b, $g, $r ) = unpack 'CCC', substr $bmp, $offset + $row * $stride + $x * $bytes, 3;
    return ( $r, $g, $b );
}

# ---- Scale: device pixels per SVG unit, confirmed against the raster --------
my $scale = SIZE / $sw;
my $white_background = $content =~ /<rect width="100%" height="100%" fill="#ffffff"/;
my ($edge) = $white_background ? () : grep { my @p = pixel( 0, $_ ); $p[0] == 255 && $p[1] == 255 && $p[2] == 255 } 0 .. $bh - 1;
die sprintf "content ends at %s, expected %.0f: Quick Look did not lay the SVG out as assumed\n", $edge // 'none', $sh * $scale
    if defined $edge && abs( $edge - $sh * $scale ) > 2;

# ---- Samples ------------------------------------------------------------------
my %block;
open my $g, '<', $grid_file or die $!;
while (<$g>) { chomp; my ( $r, $c, $fg ) = split /\t/; $block{"$r,$c"} = $fg }

my ( $samples, $failures, %by_kind ) = ( 0, 0 );
my @examples;
sub sample {
    my ( $kind, $r, $c, $x, $y, $fg ) = @_;
    my @want = map { hex } $fg =~ /^#(..)(..)(..)$/;
    my ( $px, $py ) = ( int( $x * $scale ), int( $y * $scale ) );
    return if $px >= $bw || $py >= $bh;
    my @got = pixel( $px, $py );
    $samples++;
    $by_kind{$kind}{samples}++;
    if ( grep { abs( $got[$_] - $want[$_] ) > TOLERANCE } 0 .. 2 ) {
        $failures++;
        $by_kind{$kind}{failures}++;
        push @examples, sprintf '%s at row %d col %d: want %s got #%02x%02x%02x', $kind, $r, $c, $fg, @got if @examples < 5;
    }
}
my $inset = 1.5 / $scale;    # 1.5 device pixels inside the edge
for my $key ( sort keys %block ) {
    my ( $r, $c ) = split /,/, $key;
    my $fg = $block{$key};
    my ( $x0, $y0 ) = ( $c * $cw, $r * $ch );
    sample( 'centre', $r, $c, $x0 + $cw / 2, $y0 + $ch / 2, $fg );
    sample( 'top',    $r, $c, $x0 + $cw / 2, $y0 + $inset, $fg );
    sample( 'bottom', $r, $c, $x0 + $cw / 2, $y0 + $ch - $inset, $fg );
    sample( 'left',   $r, $c, $x0 + $inset, $y0 + $ch / 2, $fg );
    sample( 'right',  $r, $c, $x0 + $cw - $inset, $y0 + $ch / 2, $fg );
    sample( 'seam below', $r, $c, $x0 + $cw / 2, $y0 + $ch, $fg ) if ( $block{ ( $r + 1 ) . ",$c" } // '' ) eq $fg;
    sample( 'seam right', $r, $c, $x0 + $cw, $y0 + $ch / 2, $fg ) if ( $block{ "$r," . ( $c + 1 ) } // '' ) eq $fg;
}

printf "%s: %d full-block cells, %d samples, %d failed (scale %.3f%s)\n", basename($svg), scalar( keys %block ), $samples, $failures, $scale, $white_background ? ', not confirmed on a white background' : ', confirmed';
printf "  %-10s %6d samples %6d failed\n", $_, $by_kind{$_}{samples}, $by_kind{$_}{failures} // 0 for sort keys %by_kind;
print "  e.g. $_\n" for @examples;
exit( $failures ? 1 : 0 );
