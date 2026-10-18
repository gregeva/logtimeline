package NoticeProto;

# Shared pieces of the #412 notice-surface prototypes: the terminal state
# guard, the terminal size, the constants sliced out of ltl, and the two
# visual languages. Each prototype adapts these to its own surface; nothing
# here is a candidate for ltl.

use strict;
use warnings;
use utf8;
use Exporter 'import';
use File::Basename qw(dirname);
use File::Spec;
use Term::ReadKey qw(ReadMode ReadKey GetTerminalSize);
use Unicode::UCD qw(charprop);

our @EXPORT_OK = qw(
    ltl_constants interactive terminal_size raw_mode restore_mode
    query_cursor_column expected_width style_for strip_sgr
);

binmode STDOUT, ':encoding(UTF-8)';
$| = 1;

my $ltl_path = File::Spec->catfile( dirname(__FILE__), '..', '..', '..', 'ltl' );

# --- constants sliced out of ltl -------------------------------------------
#
# The ltl look is drawn from ltl's own tables, read from the source at run
# time: %histogram_box_sets (box glyphs), @column_colors (the colour table per
# column and background) and get_title_string() (the title banner).

my %ltl;

sub ltl_constants {
    return \%ltl if %ltl;
    open my $fh, '<:encoding(UTF-8)', $ltl_path or die "cannot read $ltl_path: $!\n";
    my $src = do { local $/; <$fh> };
    close $fh;
    my $box     = slice_block( $src, qr/^my %histogram_box_sets = \(/m );
    my $colours = slice_block( $src, qr/^my \@column_colors = \(/m );
    my $title   = slice_block( $src, qr/^sub get_title_string \{/m );
    my ($version) = $src =~ /^my \$version_number = "([^"]+)";/m
        or die "version_number not found in ltl\n";
    my ( %histogram_box_sets, @column_colors );
    my $version_number = $version;
    s/\Amy // for $box, $colours;
    eval "$box; $colours; 1" or die "ltl constants did not evaluate: $@";
    my $title_sub = eval "sub { $title; return get_title_string() }"
        or die "get_title_string did not evaluate: $@";
    %ltl = (
        box     => \%histogram_box_sets,
        colours => { map { $_->{name} => $_ } @column_colors },
        title   => $title_sub->(),
        version => $version,
    );
    return \%ltl;
}

# The text from the line the pattern matches to the line that closes it,
# counted by brace and parenthesis depth.
sub slice_block {
    my ( $src, $start ) = @_;
    $src =~ $start or die "block $start not found in ltl\n";
    my $from = $-[0];
    my $depth = 0;
    my $seen  = 0;
    for my $i ( $from .. length($src) - 1 ) {
        my $c = substr( $src, $i, 1 );
        if    ( $c eq '(' || $c eq '{' ) { $depth++; $seen = 1 }
        elsif ( $c eq ')' || $c eq '}' ) { $depth-- }
        if ( $seen && $depth == 0 ) {
            my $end = index( $src, "\n", $i );
            return substr( $src, $from, $end - $from );
        }
    }
    die "block $start not closed in ltl\n";
}

# --- terminal --------------------------------------------------------------

sub interactive { return -t STDIN && -t STDOUT }

sub terminal_size {
    my (%opt) = @_;
    my ( $w, $h );
    if ( -t STDOUT ) {
        local $SIG{__WARN__} = sub { };
        ( $w, $h ) = eval { ( GetTerminalSize(*STDOUT) )[ 0, 1 ] };
    }
    $w = $opt{width}  if $opt{width};
    $h = $opt{height} if $opt{height};
    return ( $w || 80, $h || 24 );
}

# Every prototype that changes the tty mode restores it on every way out:
# normal end, die, Ctrl-C and TERM. The cursor is shown again too.
my $mode_changed = 0;

sub raw_mode {
    my ($mode) = @_;
    ReadMode( $mode // 'cbreak' );
    $mode_changed = 1;
    return;
}

sub restore_mode {
    return unless $mode_changed;
    ReadMode('restore');
    print "\e[?25h\e[0m";
    $mode_changed = 0;
    return;
}

$SIG{INT}  = sub { restore_mode(); print "\n"; exit 130 };
$SIG{TERM} = sub { restore_mode(); exit 143 };
$SIG{__DIE__} = sub { restore_mode() unless $^S };
END { restore_mode() }

# The column the cursor stands on, from the terminal's own answer to a cursor
# position report (CSI 6n), or undef when nothing answers within the timeout.
sub query_cursor_column {
    my ($timeout) = @_;
    $timeout //= 0.3;
    print "\e[6n";
    my $reply = '';
    while ( defined( my $c = ReadKey($timeout) ) ) {
        $reply .= $c;
        last if $c eq 'R';
    }
    return $reply =~ /\e\[\d+;(\d+)R/ ? $1 : undef;
}

# The width a terminal following Unicode's East Asian Width and emoji
# presentation properties gives a string: two for a wide or full-width
# character, or an emoji presented as emoji (by default, or by U+FE0F);
# nothing for a variation selector or zero-width joiner; one otherwise.
sub expected_width {
    my ($s) = @_;
    my @cp = map { ord } split //, $s;
    my $w = 0;
    for my $i ( 0 .. $#cp ) {
        my $cp = $cp[$i];
        next if $cp == 0xFE0E || $cp == 0xFE0F || $cp == 0x200D;
        my $vs16 = $i < $#cp && $cp[ $i + 1 ] == 0xFE0F;
        my $vs15 = $i < $#cp && $cp[ $i + 1 ] == 0xFE0E;
        my $eaw  = charprop( $cp, 'East_Asian_Width' );
        my $emoji = charprop( $cp, 'Emoji_Presentation' ) eq 'Yes';
        $w += ( $eaw eq 'Wide' || $eaw eq 'Fullwidth' || ( $emoji && !$vs15 ) || $vs16 ) ? 2 : 1;
    }
    return $w;
}

sub strip_sgr {
    my ($s) = @_;
    $s =~ s/\e\[[0-9;]*m//g;
    return $s;
}

# --- the two visual languages ----------------------------------------------
#
# ltl: the existing look. Rules are the box glyphs of %histogram_box_sets,
# colours the fg of @column_colors on a dark background and the darkest step
# of each colour's light gradient on a light one, grey (90) for frames as in
# the title banner.
#
# new: a style the rest of the output might later adopt. Rounded corners, a
# coloured left bar per notice, bold category headings, dim evidence.
#
# The colour given to each category is Claude's proposal for the prototypes.

my %category_colour = (
    'data anomaly'           => 'orange',
    'your options'           => 'cyan',
    'decision taken for you' => 'blue',
    'figure caveat'          => 'magenta',
    'guidance'               => 'green',
    'runtime condition'      => 'teal',
);

sub style_for {
    my ( $name, $bg ) = @_;
    $bg //= 'dark';
    my $c = ltl_constants();
    my %fg;
    for my $cat ( keys %category_colour ) {
        my $col = $c->{colours}{ $category_colour{$cat} };
        $fg{$cat} = $bg eq 'light' ? "\e[38;5;$col->{gradient_light}[-1]m" : $col->{fg};
    }
    my $frame = $bg eq 'light' ? "\e[38;5;244m" : "\e[90m";
    my $text  = $bg eq 'light' ? "\e[30m"       : "\e[37m";
    if ( $name eq 'ltl' ) {
        return {
            name  => 'ltl',
            box   => $c->{box}{light},
            heavy => $c->{box}{heavy},
            fg    => \%fg,
            frame => $frame,
            text  => $text,
            bold  => '',
            dim   => $frame,
            reset => "\e[0m",
        };
    }
    return {
        name => 'new',
        box  => {
            %{ $c->{box}{light} },
            corner_tl => '╭', corner_tr => '╮', corner_bl => '╰', corner_br => '╯',
        },
        heavy => $c->{box}{heavy},
        bar   => '▌',
        fg    => \%fg,
        frame => $frame,
        text  => $text,
        bold  => "\e[1m",
        dim   => "\e[2m",
        reset => "\e[0m",
    };
}

1;
