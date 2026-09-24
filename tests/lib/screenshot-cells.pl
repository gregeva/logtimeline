#!/usr/bin/env perl
# screenshot-cells.pl: read a screenshot SVG written by build/capture-screenshots.pl
# back into cells and compare them with ltl's own output, decoded independently
# by tests/lib/rendered-output.pl (tests/HARNESS-DESIGN.md § Asserting rendered
# output). Used by tests/validate-screenshot-capture.sh.
#
#   screenshot-cells.pl chars   SVG CAPTURE FIRST LAST COL_FIRST COL_STOP PAD
#   screenshot-cells.pl colours SVG CAPTURE FIRST LAST COL_FIRST COL_STOP PAD
#   screenshot-cells.pl ticks   SVG CAPTURE FIRST LAST COL_FIRST COL_STOP PAD
#   screenshot-cells.pl heatmap SVG CAPTURE FIRST LAST COL_FIRST COL_STOP PAD LAYOUT GRADIENT
#   screenshot-cells.pl edges   SVG CAPTURE FIRST LAST COL_FIRST COL_STOP PAD
#
# CAPTURE is ltl's standard output; FIRST and LAST are the crop's rows (from 1),
# COL_FIRST and COL_STOP its columns (from 0, stop exclusive); PAD is the
# image's padding as top,right,bottom,left. Exit 0 when the check holds, 1 with
# the differences on standard output when it does not.
use strict;
use warnings;
use File::Basename qw(dirname);
use File::Spec;
use File::Temp qw(tempdir);
require( File::Spec->rel2abs( dirname(__FILE__) ) . '/rendered-output.pl' );

# Cell geometry of the images: CELL_WIDTH, CELL_HEIGHT and BASELINE in
# build/capture-screenshots.pl.
use constant CELL_WIDTH  => 7.2;
use constant CELL_HEIGHT => 15;
use constant BASELINE    => 0.76;

binmode STDOUT, ':encoding(UTF-8)';
my ( $mode, $svg_file, $capture_file, $first, $last, $col_first, $col_stop, $pad, @rest ) = @ARGV;
die "usage: screenshot-cells.pl MODE SVG CAPTURE FIRST LAST COL_FIRST COL_STOP PAD [...]\n" unless defined $pad;
my ( $pad_top, undef, undef, $pad_left ) = split /,/, $pad;
my ( $rows, $cols ) = ( $last - $first + 1, $col_stop - $col_first );

# ---- The image, as cells -----------------------------------------------------

sub unxml { my $s = shift; $s =~ s/&lt;/</g; $s =~ s/&gt;/>/g; $s =~ s/&quot;/"/g; $s =~ s/&amp;/&/g; return $s }

open my $fh, '<:encoding(UTF-8)', $svg_file or die "cannot read $svg_file: $!\n";
my $svg = do { local $/; <$fh> };
close $fh;
my ($base_bg) = $svg =~ /<rect width="100%" height="100%" fill="(#[0-9a-f]{6})"\/>/ or die "no background rectangle in $svg_file\n";
my @image = map { [ map { { ch => ' ', fg => undef, bg => $base_bg } } 1 .. $cols ] } 1 .. $rows;
my ( $ox, $oy ) = ( $pad_left * CELL_WIDTH, $pad_top * CELL_HEIGHT );
my @placement_errors;

sub cell_index {
    my ( $value, $origin, $size ) = @_;
    my $i = ( $value - $origin ) / $size;
    return abs( $i - int( $i + 0.5 ) ) < 0.01 ? int( $i + 0.5 ) : undef;
}

while ( $svg =~ /<rect x="([\d.]+)" y="([\d.]+)" width="([\d.]+)" height="([\d.]+)" fill="(#[0-9a-f]{6})"/g ) {
    my ( $x, $y, $w, $h, $fill ) = ( $1, $2, $3, $4, $5 );
    next if $h < CELL_HEIGHT;    # an underline, not a background
    my ( $c, $r, $n ) = ( cell_index( $x, $ox, CELL_WIDTH ), cell_index( $y, $oy, CELL_HEIGHT ), cell_index( $w, 0, CELL_WIDTH ) );
    unless ( defined $c && defined $r && defined $n ) { push @placement_errors, "background rectangle at x=$x y=$y is off the cell grid"; next }
    $image[$r][$_]{bg} = $fill for $c .. $c + $n - 1;
}
while ( $svg =~ /<text x="([\d.]+)" y="([\d.]+)" fill="(#[0-9a-f]{6})"[^>]*>([^<]*)<\/text>/g ) {
    my ( $x, $y, $fill, $text ) = ( $1, $2, $3, unxml($4) );
    my ( $c, $r ) = ( cell_index( $x, $ox, CELL_WIDTH ), cell_index( $y - CELL_HEIGHT * BASELINE, $oy, CELL_HEIGHT ) );
    unless ( defined $c && defined $r ) { push @placement_errors, "text '$text' at x=$x y=$y is off the cell grid"; next }
    my @chars = split //, $text;
    for my $k ( 0 .. $#chars ) {
        if ( $r >= $rows || $c + $k >= $cols ) { push @placement_errors, "text '$text' runs outside the crop"; last }
        @{ $image[$r][ $c + $k ] }{qw(ch fg)} = ( $chars[$k], $fill );
    }
}

# ---- ltl's output, as cells --------------------------------------------------

open my $cf, '<:encoding(UTF-8)', $capture_file or die "cannot read $capture_file: $!\n";
my @lines = <$cf>;
close $cf;
chomp @lines;
# A terminal carries colour state across a newline: ltl sets a colour at the
# end of one row and prints the next in it. decode_line() starts every line
# from the default, so each line is decoded after the colour codes of every
# line before it, which leaves it in the state the terminal would be in.
my ( @expected, $state );
$state = '';
for my $n ( 1 .. $last ) {
    my $line = $lines[ $n - 1 ] // '';
    if ( $n >= $first ) {
        my $cells = decode_line( $state . $line );
        push @expected, [ map { $cells->[$_] // { ch => ' ', fg => 'default', bg => 'default' } } $col_first .. $col_stop - 1 ];
    }
    $state .= join '', $line =~ /(\e\[[0-9;]*m)/g;
}

my @problems = @placement_errors;
sub report { my $label = shift; if (@problems) { print "$_\n" for @problems[ 0 .. ( $#problems < 9 ? $#problems : 9 ) ]; print "... ", scalar @problems, " in all\n" if @problems > 10; exit 1 } print "$label\n"; exit 0 }

if ( $mode eq 'chars' ) {
    for my $r ( 0 .. $rows - 1 ) {
        my $want = join '', map { $_->{ch} } @{ $expected[$r] };
        my $got  = join '', map { $_->{ch} } @{ $image[$r] };
        s/\s+$// for $want, $got;
        # The summary's run time and memory differ on every run (D13): the
        # image and this capture are two runs, so their figures are masked.
        if ( $want =~ /^\s*(?:TOTAL TIME|MAXIMUM MEMORY USED)\b/ ) { s/[\d.]+/N/g for $want, $got; s/ +/ /g for $want, $got }
        push @problems, sprintf( "row %d: ltl printed '%s'\n        the image shows '%s'", $first + $r, $want, $got ) if $want ne $got;
    }
    report("$rows rows x $cols columns: every cell's character equals ltl's output");
}

if ( $mode eq 'colours' ) {
    # Each colour ltl names maps to one colour in the image; the 256-colour cube
    # and greys (16-255) to the standard xterm values.
    my @level = ( 0, 95, 135, 175, 215, 255 );
    my sub xterm {
        my $n = shift;
        return sprintf '#%02x%02x%02x', ( 8 + 10 * ( $n - 232 ) ) x 3 if $n >= 232;
        $n -= 16;
        return sprintf '#%02x%02x%02x', $level[ int( $n / 36 ) ], $level[ int( $n / 6 ) % 6 ], $level[ $n % 6 ];
    }
    my ( %seen, $cells );
    for my $r ( 0 .. $rows - 1 ) {
        for my $c ( 0 .. $cols - 1 ) {
            my ( $want, $got ) = ( $expected[$r][$c], $image[$r][$c] );
            next if $want->{fg} eq 'reverse';
            $cells++;
            $seen{"background $want->{bg}"}{ $got->{bg} }++;
            $seen{"text $want->{fg}"}{ $got->{fg} }++ if $want->{ch} ne ' ' && defined $got->{fg};
        }
    }
    for my $key ( sort keys %seen ) {
        my @hex = sort keys %{ $seen{$key} };
        push @problems, "$key is drawn in more than one colour: @hex" if @hex > 1;
        if ( $key =~ /256:(\d+)$/ && $1 >= 16 && $hex[0] ne xterm($1) ) {
            push @problems, "$key is drawn as $hex[0], not the xterm value " . xterm($1);
        }
    }
    push @problems, "the default background is drawn as " . join( ' ', sort keys %{ $seen{'background default'} } ) . ", not the image's background $base_bg"
        if $seen{'background default'} && join( '', keys %{ $seen{'background default'} } ) ne $base_bg;
    report( sprintf '%d cells, %d distinct colours: each drawn consistently, 256-colour indices at their xterm values', $cells, scalar keys %seen );
}

if ( $mode eq 'ticks' ) {
    # Tick glyphs on the histogram axis rows: columns in the image equal ltl's.
    my %tick = map { $_ => 1 } ( "\x{2533}", "\x{254B}", "\x{253B}" );
    my $axis = 0;
    for my $r ( 0 .. $rows - 1 ) {
        my $row_text = join '', map { $_->{ch} } @{ $expected[$r] };
        next unless $row_text =~ /\x{2517}/;    # the axis row starts with its corner
        $axis++;
        my @want = grep { $tick{ $expected[$r][$_]{ch} } } 0 .. $cols - 1;
        my @got  = grep { $tick{ $image[$r][$_]{ch} } } 0 .. $cols - 1;
        push @problems, "row " . ( $first + $r ) . ": no tick marks on the axis" unless @want;
        push @problems, sprintf( "row %d: ltl's ticks at columns %s, the image's at %s", $first + $r, "@want", "@got" ) if "@want" ne "@got";
    }
    push @problems, 'no histogram axis row in the crop' unless $axis;
    report("$axis axis rows: every tick mark in the image sits in the column ltl printed it");
}

if ( $mode eq 'heatmap' ) {
    # Cells of the heatmap column carry only colours of the gradient
    # -V heatmap-palette reports.
    my ( $layout_file, $gradient ) = @rest;
    my $layout = parse_debug_layout($layout_file);
    my ($heatmap) = grep { $_->{id} eq 'heatmap' } @$layout or die "no heatmap column in the layout table\n";
    my %allowed = map { ( "256:$_" => 1 ) } split /,/, $gradient;
    my $blocks = 0;
    for my $r ( 0 .. $rows - 1 ) {
        for my $abs ( $heatmap->{start} .. $heatmap->{start} + $heatmap->{width} - 1 ) {
            my $c = $abs - $col_first;
            next if $c < 0 || $c >= $cols;
            my $want = $expected[$r][$c];
            next unless $want->{ch} eq "\x{2588}";
            $blocks++;
            push @problems, sprintf( 'row %d column %d: heatmap cell in %s, not a gradient colour', $first + $r, $abs, $want->{fg} ) unless $allowed{ $want->{fg} };
            push @problems, sprintf( 'row %d column %d: heatmap cell missing from the image', $first + $r, $abs ) unless ( $image[$r][$c]{ch} // '' ) eq "\x{2588}";
        }
    }
    push @problems, 'no heatmap cells in the crop' unless $blocks;
    report("$blocks heatmap cells: each in a colour of the reported gradient, each present in the image");
}

if ( $mode eq 'edges' ) {
    # Criterion 11: as displayed (Quick Look, WebKit), a full block sits within
    # its own columns: sampled just inside its left and right edges it is its
    # colour. Heights follow the viewer's font (D14) and are not sampled.
    my $dir = tempdir( CLEANUP => 1 );
    my ( $sw, $sh ) = $svg =~ /<svg [^>]*width="([\d.]+)" height="([\d.]+)"/;
    ( my $fit = $svg ) =~ s{(<svg [^>]*)width="[\d.]+" height="[\d.]+"}{ sprintf '%swidth="768" height="%s"', $1, 768 * $sh / $sw }e;
    open my $out, '>:encoding(UTF-8)', "$dir/fit.svg" or die $!;
    print {$out} $fit;
    close $out;
    system("qlmanage -t -s 3200 -o '$dir' '$dir/fit.svg' >/dev/null 2>&1") == 0 or die "qlmanage failed\n";
    system("sips -s format bmp '$dir/fit.svg.png' --out '$dir/r.bmp' >/dev/null 2>&1") == 0 or die "sips failed\n";
    open my $b, '<:raw', "$dir/r.bmp" or die $!;
    my $bmp = do { local $/; <$b> };
    my ($offset) = unpack 'V', substr $bmp, 10, 4;
    my ( $bw, $bh ) = unpack 'l<l<', substr $bmp, 18, 8;
    my ($bpp) = unpack 'v', substr $bmp, 28, 2;
    my $top_down = $bh < 0;
    $bh = abs $bh;
    my $stride = int( ( $bw * $bpp / 8 + 3 ) / 4 ) * 4;
    my $scale = 3200 / $sw;
    my $samples = 0;
    for my $r ( 0 .. $rows - 1 ) {
        for my $c ( 0 .. $cols - 1 ) {
            next unless $image[$r][$c]{ch} eq "\x{2588}";
            my @want = map { hex } $image[$r][$c]{fg} =~ /^#(..)(..)(..)$/;
            my $y = $oy + $r * CELL_HEIGHT + CELL_HEIGHT / 2;
            for my $x ( $ox + $c * CELL_WIDTH + 1.5 / $scale, $ox + ( $c + 1 ) * CELL_WIDTH - 1.5 / $scale ) {
                my ( $px, $py ) = ( int( $x * $scale ), int( $y * $scale ) );
                my $row = $top_down ? $py : $bh - 1 - $py;
                my ( $bb, $gg, $rr ) = unpack 'CCC', substr $bmp, $offset + $row * $stride + $px * $bpp / 8, 3;
                $samples++;
                push @problems, sprintf( 'row %d column %d: pixel #%02x%02x%02x, not the block colour %s', $first + $r, $col_first + $c, $rr, $gg, $bb, $image[$r][$c]{fg} )
                    if grep { abs( ( $rr, $gg, $bb )[$_] - $want[$_] ) > 24 } 0 .. 2;
            }
        }
    }
    push @problems, 'no full-block cells in the crop' unless $samples;
    report("$samples edge samples: every full block fills its own columns as displayed");
}

die "unknown mode '$mode'\n";
