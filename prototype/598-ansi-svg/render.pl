#!/usr/bin/env perl
# Prototype for #598 D6: render ltl's captured ANSI output to SVG.
#
#   render.pl --profile dark|light --renderer text|geometry [--width N]
#             [--cell-width W] [--cell-height H] [--font-size S] INPUT > OUT.svg
#
# The input is parsed into a grid of cells (character, foreground, background,
# attributes) and the grid is drawn. Two renderers are compared:
#   text      every glyph is <text>, each run forced to its cells with textLength
#   geometry  as text, but block elements and box-drawing lines are drawn as
#             rectangles and lines at cell coordinates
# Codes the parser does not know are counted and reported on standard error.
use strict;
use warnings;
use Getopt::Long;

my %opt = ( profile => 'dark', renderer => 'geometry', width => 211,
            'cell-width' => 7.2, 'cell-height' => 15, 'font-size' => 12 );
GetOptions( \%opt, 'profile=s', 'renderer=s', 'width=i', 'cell-width=f',
            'cell-height=f', 'font-size=f', 'rows=s', 'cols=s', 'crisp!', 'grid=s' ) or die "bad options\n";
die "usage: render.pl [options] INPUT\n" unless @ARGV == 1;
die "--profile is dark or light\n" unless $opt{profile} =~ /^(dark|light)$/;
die "--renderer is text or geometry\n" unless $opt{renderer} =~ /^(text|geometry)$/;

# Terminal.app profiles "Clear Dark" and "Clear Light" (features/598-screenshot-
# capture.md § Rendering prototype): ANSIBlackColor .. ANSIBrightWhiteColor,
# TextColor, TextBoldColor, BackgroundColor (drawn opaque), as NSRGB components.
my %profiles = (
    dark => {
        ansi => [
            [0.208221729, 0.2588729473, 0.2961375701], [0.7050900829, 0.3357157301, 0.2811490643],
            [0.4241566305, 0.6672818346, 0.4415227165], [0.768627451, 0.6745098039, 0.3843137255],
            [0.4274509804, 0.5882352941, 0.7058823529], [0.7411764706, 0.4823529412, 0.8039215686],
            [0.4847151205, 0.7950070909, 0.805706814],  [0.8687835755, 0.8995435314, 0.9221739477],
            [0.2763328949, 0.3625957779, 0.4260602691], [0.8761320153, 0.424238529, 0.352688727],
            [0.4742048482, 0.7433320203, 0.4923891166], [0.8980392157, 0.7843137255, 0.4470588235],
            [0.4039215686, 0.7098039216, 0.9294117647], [0.8274509804, 0.537254902, 0.8980392157],
            [0.5177743662, 0.8677316158, 0.8797991071], [0.8995791401, 0.9354739751, 0.9618821747],
        ],
        text       => [0.8776108099, 0.8776108099, 0.8776108099],
        bold       => [0.9285714286, 0.9285714286, 0.9285714286],
        background => [0.09838771145, 0.1138777476, 0.152602838],
    },
    light => {
        ansi => [
            [0.1764705882, 0.2196078431, 0.2509803922], [0.7050900829, 0.3357157301, 0.2811490643],
            [0.4241566305, 0.6672818346, 0.4415227165], [0.768627451, 0.6745098039, 0.3843137255],
            [0.337254902, 0.5215686275, 0.6588235294],  [0.6784313725, 0.3921568627, 0.7450980392],
            [0.4117647059, 0.7764705882, 0.7882352941], [0.7568627451, 0.7843137255, 0.8],
            [0.3137254902, 0.3960784314, 0.4509803922], [0.8761320153, 0.424238529, 0.352688727],
            [0.4742048482, 0.7433320203, 0.4923891166], [0.8980392157, 0.7843137255, 0.4470588235],
            [0.2862745098, 0.6352941176, 0.8823529412], [0.8274509804, 0.537254902, 0.8980392157],
            [0.4666666667, 0.8823529412, 0.8980392157], [0.8470588235, 0.8823529412, 0.9058823529],
        ],
        text       => [0.1752953329, 0.2185359088, 0.2494220344],
        bold       => [0.1438920459, 0.1793862877, 0.2047393176],
        background => [1, 1, 1],
    },
);
my $profile = $profiles{ $opt{profile} };

sub hex_of { return sprintf '#%02x%02x%02x', map { int( $_ * 255 + 0.5 ) } @{ $_[0] } }

# xterm 256-colour table: 0-15 from the profile, 16-231 the 6x6x6 cube, 232-255 greys.
my @palette = map { hex_of($_) } @{ $profile->{ansi} };
my @level = ( 0, 95, 135, 175, 215, 255 );
for my $i ( 16 .. 231 ) {
    my $n = $i - 16;
    push @palette, sprintf '#%02x%02x%02x', $level[ int( $n / 36 ) ], $level[ int( $n / 6 ) % 6 ], $level[ $n % 6 ];
}
push @palette, sprintf '#%02x%02x%02x', ( 8 + 10 * $_ ) x 3 for 0 .. 23;
my $default_fg = hex_of( $profile->{text} );
my $bold_fg    = hex_of( $profile->{bold} );
my $default_bg = hex_of( $profile->{background} );

# ---- Parse -----------------------------------------------------------------

open my $in, '<:encoding(UTF-8)', $ARGV[0] or die "Cannot read $ARGV[0]: $!\n";
my $text = do { local $/; <$in> };
close $in;

my ( @grid, %unknown, %other_escape );
my ( $row, $col ) = ( 0, 0 );
my %sgr = ( fg => undef, bg => undef, bold => 0, underline => 0, reverse => 0 );
my $overflow = 0;

sub apply_sgr {
    my @p = map { $_ eq '' ? 0 : $_ } split /;/, $_[0], -1;
    @p = (0) unless @p;
    while (@p) {
        my $c = shift @p;
        if    ( $c == 0 )  { %sgr = ( fg => undef, bg => undef, bold => 0, underline => 0, reverse => 0 ) }
        elsif ( $c == 1 )  { $sgr{bold} = 1 }
        elsif ( $c == 22 ) { $sgr{bold} = 0 }
        elsif ( $c == 4 )  { $sgr{underline} = 1 }
        elsif ( $c == 24 ) { $sgr{underline} = 0 }
        elsif ( $c == 7 )  { $sgr{reverse} = 1 }
        elsif ( $c == 27 ) { $sgr{reverse} = 0 }
        elsif ( $c >= 30 && $c <= 37 )   { $sgr{fg} = $palette[ $c - 30 ] }
        elsif ( $c >= 90 && $c <= 97 )   { $sgr{fg} = $palette[ $c - 90 + 8 ] }
        elsif ( $c >= 40 && $c <= 47 )   { $sgr{bg} = $palette[ $c - 40 ] }
        elsif ( $c >= 100 && $c <= 107 ) { $sgr{bg} = $palette[ $c - 100 + 8 ] }
        elsif ( $c == 39 ) { $sgr{fg} = undef }
        elsif ( $c == 49 ) { $sgr{bg} = undef }
        elsif ( ( $c == 38 || $c == 48 ) && @p ) {
            my $key  = $c == 38 ? 'fg' : 'bg';
            my $mode = shift @p;
            if ( $mode == 5 && @p ) { $sgr{$key} = $palette[ shift(@p) % 256 ] }
            elsif ( $mode == 2 && @p >= 3 ) { $sgr{$key} = sprintf '#%02x%02x%02x', splice @p, 0, 3 }
            else { $unknown{"$c;$mode"}++ }
        }
        else { $unknown{$c}++ }
    }
}

while ( $text =~ /\G(?:\e\[([0-9;]*)([\x40-\x7e])|(\e.)|(\n)|(\r)|(.))/gcs ) {
    if ( defined $2 ) {
        if ( $2 eq 'm' ) { apply_sgr($1) } else { $other_escape{"CSI $1$2"}++ }
    }
    elsif ( defined $3 ) { $other_escape{ sprintf 'ESC %s', $3 }++ }
    elsif ( defined $4 ) { $row++; $col = 0 }
    elsif ( defined $5 ) { $col = 0; $other_escape{'CR'}++ }
    else {
        my $ch = $6;
        if ( $ch eq "\t" ) { $other_escape{'TAB'}++; $col = ( int( $col / 8 ) + 1 ) * 8; next }
        if ( $col >= $opt{width} ) { $overflow++; $row++; $col = 0 }
        my ( $fg, $bg ) = ( $sgr{fg}, $sgr{bg} );
        $fg //= $sgr{bold} ? $bold_fg : $default_fg;
        $bg //= $default_bg;
        ( $fg, $bg ) = ( $bg, $fg ) if $sgr{reverse};
        $grid[$row][$col] = { ch => $ch, fg => $fg, bg => $bg, bold => $sgr{bold}, underline => $sgr{underline} };
        $col++;
    }
}
my $rows = @grid;
$rows-- while $rows && !grep { defined } @{ $grid[ $rows - 1 ] || [] };

printf STDERR "rows %d, width %d, wrapped %d, unknown SGR: %s, other escapes: %s\n", $rows, $opt{width}, $overflow,
    ( join( ', ', map {"$_ x$unknown{$_}"} sort keys %unknown ) || 'none' ),
    ( join( ', ', map {"$_ x$other_escape{$_}"} sort keys %other_escape ) || 'none' );

# ---- Geometry for block elements and box drawing ---------------------------

# Box drawing: arms up, right, down, left; 1 light, 2 heavy.
my %box = (
    0x2500 => [0,1,0,1], 0x2501 => [0,2,0,2], 0x2502 => [1,0,1,0], 0x2503 => [2,0,2,0],
    0x250C => [0,1,1,0], 0x250F => [0,2,2,0], 0x2510 => [0,0,1,1], 0x2513 => [0,0,2,2],
    0x2514 => [1,1,0,0], 0x2517 => [2,2,0,0], 0x2518 => [1,0,0,1], 0x251B => [2,0,0,2],
    0x251C => [1,1,1,0], 0x2523 => [2,2,2,0], 0x2524 => [1,0,1,1], 0x252B => [2,0,2,2],
    0x252C => [0,1,1,1], 0x2533 => [0,2,2,2], 0x2534 => [1,1,0,1], 0x253B => [2,2,0,2],
    0x253C => [1,1,1,1], 0x254B => [2,2,2,2],
);
my %weight = ( 1 => 0.1, 2 => 0.2 );    # stroke width as a fraction of the cell width, x2 for heavy

# Block elements: [x0, y0, x1, y1] in eighths of the cell.
my %block = ( 0x2588 => [0,0,8,8], 0x2580 => [0,0,8,4], 0x2590 => [4,0,8,8] );
$block{ 0x2580 + $_ } = [ 0, 8 - $_, 8, 8 ] for 1 .. 8;       # lower 1/8 .. full
$block{ 0x2590 - $_ } = [ 0, 0, $_, 8 ] for 1 .. 7;           # left 1/8 (0x258F) .. 7/8 (0x2589)
$block{0x2588} = [0,0,8,8];
$block{0x2594} = [0,0,8,1];
$block{0x2595} = [7,0,8,8];


# Optional crop, in cells: --rows FIRST:END and --cols FIRST:END, END exclusive.
if ( $opt{rows} || $opt{cols} ) {
    my ( $r0, $r1 ) = $opt{rows} ? split /:/, $opt{rows} : ( 0, $rows );
    my ( $c0, $c1 ) = $opt{cols} ? split /:/, $opt{cols} : ( 0, $opt{width} );
    @grid = map { my $cells = $grid[$_] || []; [ @{$cells}[ $c0 .. $c1 - 1 ] ] } $r0 .. $r1 - 1;
    ( $rows, $opt{width} ) = ( $r1 - $r0, $c1 - $c0 );
}

# Optional: the cropped grid's full-block cells, for check-alignment.pl: row, column, colour.
if ( $opt{grid} ) {
    open my $g, '>', $opt{grid} or die "Cannot write $opt{grid}: $!\n";
    for my $r ( 0 .. $rows - 1 ) {
        my $cells = $grid[$r] || [];
        for my $c ( 0 .. $#$cells ) {
            print {$g} "$r\t$c\t$cells->[$c]{fg}\n" if $cells->[$c] && $cells->[$c]{ch} eq "\x{2588}";
        }
    }
    close $g;
}

my ( $cw, $ch ) = ( $opt{'cell-width'}, $opt{'cell-height'} );
sub n { my $v = sprintf '%.2f', $_[0]; $v =~ s/\.?0+$//; return $v }
sub rect { return sprintf '<rect x="%s" y="%s" width="%s" height="%s" fill="%s"%s/>', map( { n($_) } @_[ 0 .. 3 ] ), $_[4], $opt{crisp} ? ' shape-rendering="crispEdges"' : '' }

my $geometric = $opt{renderer} eq 'geometry'
    ? sub { my $o = ord $_[0]; return exists $box{$o} || exists $block{$o} }
    : sub { 0 };
my $blank = sub { !$_[0] || $_[0]{ch} eq ' ' };

my @out;
my $W = $opt{width} * $cw;
my $H = $rows * $ch;
push @out, sprintf '<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s">', n($W), n($H), n($W), n($H);
push @out, sprintf '<rect width="100%%" height="100%%" fill="%s"/>', $default_bg;
push @out, sprintf '<g font-family="ui-monospace, \'SF Mono\', SFMono-Regular, Menlo, Consolas, \'DejaVu Sans Mono\', monospace" font-size="%s">', n( $opt{'font-size'} );

# Backgrounds: one rectangle per run of cells sharing a colour.
for my $r ( 0 .. $rows - 1 ) {
    my $cells = $grid[$r] || [];
    my $c = 0;
    while ( $c < @$cells ) {
        my $bg = $cells->[$c] ? $cells->[$c]{bg} : $default_bg;
        my $start = $c;
        $c++ while $c < @$cells && ( $cells->[$c] ? $cells->[$c]{bg} : $default_bg ) eq $bg;
        next if $bg eq $default_bg;
        push @out, rect( $start * $cw, $r * $ch, ( $c - $start ) * $cw, $ch, $bg );
    }
}

# Geometric glyphs: a run of one glyph in one colour is drawn as one shape where
# the glyph spans its cell's width (full-width blocks, horizontal lines).
for my $r ( 0 .. $rows - 1 ) {
    my $cells = $grid[$r] || [];
    my $c = 0;
    while ( $c < @$cells ) {
        my $cell = $cells->[$c];
        unless ( $cell && $geometric->( $cell->{ch} ) ) { $c++; next }
        my $start = $c;
        $c++ while $c < @$cells && $cells->[$c] && $cells->[$c]{ch} eq $cell->{ch} && $cells->[$c]{fg} eq $cell->{fg};
        my ( $x0, $x1, $y0, $fg ) = ( $start * $cw, $c * $cw, $r * $ch, $cell->{fg} );
        my $o = ord $cell->{ch};
        if ( my $b = $block{$o} ) {
            my ( $bx0, $by0, $bx1, $by1 ) = @$b;
            my @span = ( $bx0 == 0 && $bx1 == 8 ) ? ( [ $start, $c ] ) : map { [ $_, $_ + 1 ] } $start .. $c - 1;
            push @out, rect( $_->[0] * $cw + $bx0 * $cw / 8, $y0 + $by0 * $ch / 8, ( $_->[1] - $_->[0] - 1 ) * $cw + ( $bx1 - $bx0 ) * $cw / 8, ( $by1 - $by0 ) * $ch / 8, $fg ) for @span;
            next;
        }
        my ( $up, $right, $down, $left ) = @{ $box{$o} };
        my $cy = $y0 + $ch / 2;
        my $th = $cw * $weight{ $left > $right ? $left : $right || 1 };     # horizontal stroke
        my $tv = $cw * $weight{ $up > $down ? $up : $down || 1 };           # vertical stroke
        if ( $left && $right && !$up && !$down ) {                          # a horizontal line run
            push @out, rect( $x0, $cy - $th / 2, $x1 - $x0, $th, $fg );
            next;
        }
        for my $k ( $start .. $c - 1 ) {
            my $cx = $k * $cw + $cw / 2;
            if ( $left || $right ) {
                my $xa = $left  ? $k * $cw       : $cx - ( ( $up || $down ) ? $tv / 2 : 0 );
                my $xb = $right ? ( $k + 1 ) * $cw : $cx + ( ( $up || $down ) ? $tv / 2 : 0 );
                push @out, rect( $xa, $cy - $th / 2, $xb - $xa, $th, $fg );
            }
            if ( $up || $down ) {
                my $ya = $up   ? $y0       : $cy - ( ( $left || $right ) ? $th / 2 : 0 );
                my $yb = $down ? $y0 + $ch : $cy + ( ( $left || $right ) ? $th / 2 : 0 );
                push @out, rect( $cx - $tv / 2, $ya, $tv, $yb - $ya, $fg );
            }
        }
    }
}

# Underlines: one line per run of underlined cells in one colour, blanks included,
# as the terminal draws them.
for my $r ( 0 .. $rows - 1 ) {
    my $cells = $grid[$r] || [];
    my $c = 0;
    while ( $c < @$cells ) {
        my $cell = $cells->[$c];
        unless ( $cell && $cell->{underline} ) { $c++; next }
        my $start = $c;
        $c++ while $c < @$cells && $cells->[$c] && $cells->[$c]{underline} && $cells->[$c]{fg} eq $cell->{fg};
        push @out, rect( $start * $cw, $r * $ch + $ch * 0.76 + 1.5, ( $c - $start ) * $cw, 1, $cell->{fg} );
    }
}

# Text: one <text> per run of non-blank cells sharing colour and attributes,
# started at its first cell and held to its cells' width by adjusting spacing.
my $baseline = $ch * 0.76;
for my $r ( 0 .. $rows - 1 ) {
    my $cells = $grid[$r] || [];
    my $c = 0;
    while ( $c < @$cells ) {
        my $cell = $cells->[$c];
        if ( $blank->($cell) || $geometric->( $cell->{ch} ) ) { $c++; next }
        my $start = $c;
        my $s = '';
        while ( $c < @$cells ) {
            my $k = $cells->[$c];
            last if $blank->($k) || $geometric->( $k->{ch} );
            last if $k->{fg} ne $cell->{fg} || $k->{bold} != $cell->{bold} || $k->{underline} != $cell->{underline};
            $s .= $k->{ch};
            $c++;
        }
        $s =~ s/&/&amp;/g; $s =~ s/</&lt;/g; $s =~ s/>/&gt;/g;
        my $attrs = '';
        $attrs .= ' font-weight="bold"' if $cell->{bold};
        $attrs .= sprintf ' textLength="%s" lengthAdjust="spacing"', n( ( $c - $start ) * $cw ) if $c - $start > 1;
        push @out, sprintf '<text x="%s" y="%s" fill="%s"%s>%s</text>', n( $start * $cw ), n( $r * $ch + $baseline ), $cell->{fg}, $attrs, $s;
    }
}
push @out, '</g>', '</svg>';

binmode STDOUT, ':encoding(UTF-8)';
print join( "\n", @out ), "\n";
