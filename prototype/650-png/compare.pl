#!/usr/bin/env perl
# compare.pl: compare the top-left WIDTH x HEIGHT pixels of two PNGs, read
# through sips as BMP (the pixel reading of the edges check in
# tests/lib/screenshot-cells.pl).
#
#   prototype/650-png/compare.pl A.png B.png WIDTH HEIGHT
#
# Prints both images' sizes, the number of pixels whose largest channel
# difference exceeds 0, 8, 24 and 64, and the largest difference.
use strict;
use warnings;
use File::Temp qw(tempdir);

my ( $a_png, $b_png, $w, $h ) = @ARGV;
die "usage: compare.pl A.png B.png WIDTH HEIGHT\n" unless defined $h;
my $dir = tempdir( CLEANUP => 1 );

sub pixels {
    my ( $png, $tag ) = @_;
    system("sips -s format bmp '$png' --out '$dir/$tag.bmp' >/dev/null 2>&1") == 0 or die "sips failed on $png\n";
    open my $fh, '<:raw', "$dir/$tag.bmp" or die $!;
    my $bmp = do { local $/; <$fh> };
    my ($offset) = unpack 'V', substr $bmp, 10, 4;
    my ( $bw, $bh ) = unpack 'l<l<', substr $bmp, 18, 8;
    my ($bpp) = unpack 'v', substr $bmp, 28, 2;
    my $top_down = $bh < 0;
    $bh = abs $bh;
    my $stride = int( ( $bw * $bpp / 8 + 3 ) / 4 ) * 4;
    return { w => $bw, h => $bh, at => sub {
        my ( $x, $y ) = @_;
        my $row = $top_down ? $y : $bh - 1 - $y;
        my ( $b, $g, $r ) = unpack 'CCC', substr $bmp, $offset + $row * $stride + $x * $bpp / 8, 3;
        return ( $r, $g, $b );
    } };
}

my ( $pa, $pb ) = ( pixels( $a_png, 'a' ), pixels( $b_png, 'b' ) );
printf "A %dx%d  B %dx%d  compared %dx%d\n", $pa->{w}, $pa->{h}, $pb->{w}, $pb->{h}, $w, $h;
die "an image is smaller than the compared area\n" if $pa->{w} < $w || $pa->{h} < $h || $pb->{w} < $w || $pb->{h} < $h;
my %over = map { $_ => 0 } 0, 8, 24, 64;
my $max = 0;
for my $y ( 0 .. $h - 1 ) {
    for my $x ( 0 .. $w - 1 ) {
        my @a = $pa->{at}->( $x, $y );
        my @b = $pb->{at}->( $x, $y );
        my ($d) = sort { $b <=> $a } map { abs( $a[$_] - $b[$_] ) } 0 .. 2;
        $max = $d if $d > $max;
        $d > $_ and $over{$_}++ for keys %over;
    }
}
printf "pixels differing by more than %2d: %d of %d\n", $_, $over{$_}, $w * $h for sort { $a <=> $b } keys %over;
printf "largest channel difference: %d\n", $max;
