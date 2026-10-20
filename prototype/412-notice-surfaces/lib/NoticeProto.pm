package NoticeProto;

# Shared pieces of the #412 notice-surface prototypes: the terminal state
# guard, the terminal size, the constants sliced out of ltl, and the two
# visual languages (D6: boxes and pop-ups in the new style, inline text in the
# ltl look). Each prototype adapts these to its own surface; nothing
# here is a candidate for ltl.

use strict;
use warnings;
use utf8;
use Exporter 'import';
use File::Basename qw(dirname);
use File::Spec;
use Term::ReadKey qw(ReadMode ReadKey GetTerminalSize);
use Time::HiRes qw(time);
use Unicode::UCD qw(charprop);

our @EXPORT_OK = qw(
    ltl_constants interactive terminal_size raw_mode restore_mode
    query_cursor_column query_cursor_position expected_width style_for strip_sgr
    display_width wrap_text categories
    set_answers_ahead answer_ahead read_key timed_yes_no
);

# The Windows console, prepared when this module loads, so no prototype can
# forget it, exactly as ltl does at startup: the code page to UTF-8, and the
# cmd.exe this runs leaves VT processing on (docs/terminal-output.md
# § Encoding, § Escape sequences).
system("chcp 65001 > nul") if $^O eq 'MSWin32';
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
    windows_vt_input();
    $mode_changed = 1;
    return;
}

# On Windows the console hands the terminal's answers to the program only
# with ENABLE_VIRTUAL_TERMINAL_INPUT (0x0200) on its input handle: without it
# a cursor position report reads as one NUL byte instead of ESC [ row ; col R
# (docs/terminal-output.md § Input). ReadMode('restore') puts the input mode
# back as it was before the first ReadMode.
my %win_in;

sub windows_vt_input {
    return unless $^O eq 'MSWin32';
    unless (%win_in) {
        require Win32::API;
        %win_in = (
            get => Win32::API->new( 'kernel32', 'GetConsoleMode', [ 'N', 'P' ], 'I' ),
            set => Win32::API->new( 'kernel32', 'SetConsoleMode', [ 'N', 'N' ], 'I' ),
        );
        $win_in{handle} = Win32::API->new( 'kernel32', 'GetStdHandle', ['N'], 'N' )->Call(-10);    # STD_INPUT_HANDLE
    }
    my $mode = pack 'L', 0;
    $win_in{get}->Call( $win_in{handle}, $mode ) or return;
    $win_in{set}->Call( $win_in{handle}, unpack( 'L', $mode ) | 0x0200 );
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

# The row and column the cursor stands on, from the terminal's own answer to
# a cursor position report (CSI 6n), or an empty list when nothing answers
# within the timeout.
sub query_cursor_position {
    my ($timeout) = @_;
    $timeout //= 0.3;
    print "\e[6n";
    my $reply = '';
    while ( defined( my $c = ReadKey($timeout) ) ) {
        $reply .= $c;
        last if $c eq 'R';
    }
    return $reply =~ /\e\[(\d+);(\d+)R/ ? ( $1, $2 ) : ();
}

sub query_cursor_column { my @p = query_cursor_position(@_); return @p ? $p[1] : undef }

# The width a terminal following Unicode's East Asian Width and emoji
# presentation properties gives a string: two for a wide or full-width
# character, or an emoji presented as emoji (by default, or by U+FE0F);
# nothing for a variation selector or zero-width joiner; one otherwise.
# Unicode::UCD answers slowly; each code point is looked up once.
my ( %eaw_of, %emoji_of );

sub expected_width {
    my ($s) = @_;
    my @cp = map { ord } split //, $s;
    my $w = 0;
    for my $i ( 0 .. $#cp ) {
        my $cp = $cp[$i];
        next if $cp == 0xFE0E || $cp == 0xFE0F || $cp == 0x200D;
        my $vs16 = $i < $#cp && $cp[ $i + 1 ] == 0xFE0F;
        my $vs15 = $i < $#cp && $cp[ $i + 1 ] == 0xFE0E;
        my $eaw   = $eaw_of{$cp}   //= charprop( $cp, 'East_Asian_Width' );
        my $emoji = $emoji_of{$cp} //= charprop( $cp, 'Emoji_Presentation' ) eq 'Yes' ? 1 : 0;
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
    # What the analyst picks (a choice, a key) stands out from the text.
    my $pick  = $bg eq 'light' ? "\e[1;30m"     : "\e[1;97m";
    if ( $name eq 'ltl' ) {
        return {
            name  => 'ltl',
            box   => $c->{box}{light},
            heavy => $c->{box}{heavy},
            fg    => \%fg,
            frame => $frame,
            text  => $text,
            pick  => $pick,
            bg    => $bg,
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
        pick  => $pick,
        bg    => $bg,
        bold  => "\e[1m",
        dim   => "\e[2m",
        reset => "\e[0m",
    };
}

# --- text --------------------------------------------------------------------

# Display width of a string with its SGR codes removed; ASCII is one cell
# each without consulting Unicode's tables.
sub display_width {
    my $s = strip_sgr( $_[0] );
    return length $s if $s !~ /[^\x00-\x7f]/;
    return expected_width($s);
}

# Words wrapped to lines of at most $width display cells.
sub wrap_text {
    my ( $text, $width ) = @_;
    $width = 10 if $width < 10;
    my @lines;
    my $line = '';
    for my $word ( split / +/, $text ) {
        if ( $line eq '' ) { $line = $word; next }
        if ( display_width("$line $word") <= $width ) { $line .= " $word"; next }
        push @lines, $line;
        $line = $word;
    }
    push @lines, $line if $line ne '';
    return @lines;
}

# --- the categories ---------------------------------------------------------
#
# D1's six categories in the order a surface presents them, each with how the
# analyst reads it and the glyph that heads it (D2: a text glyph and a colour;
# the order, glyphs, colours and how-to-read text are the contract's category
# sheet, settled 2026-10-19). The order puts what bears on trusting the
# figures first and the next step last; the glyphs are single-width text
# symbols. On Windows three of them are drawn as colour emoji covering the
# next cell, so each has a Windows glyph seen one cell wide and in its colour
# there (docs/terminal-output.md § Glyphs and width).

my @categories = (
    { name => 'data anomaly',           glyph => '⚠', windows => '▲', reads => 'check the source data or the options before trusting the figures' },
    { name => 'figure caveat',          glyph => '≈', reads => 'the figures cover less than they appear to' },
    { name => 'your options',           glyph => '⚙', windows => '⛭', reads => 'command usage warnings' },
    { name => 'decision taken for you', glyph => '↻', reads => 'what the run did instead of what was asked' },
    { name => 'runtime condition',      glyph => '⏱', windows => '⧖', reads => "a condition of the run's environment" },
    { name => 'guidance',               glyph => '➤', reads => 'a next step worth trying' },
);
if ( $^O eq 'MSWin32' ) { $_->{glyph} = $_->{windows} // $_->{glyph} for @categories }

sub categories { return @categories }

# --- input ------------------------------------------------------------------
#
# Answers given ahead of time (--answer y,n,2,...) are taken one per choice
# point, in order, before any key is waited for; with no terminal and no
# answer left, every choice point takes its default at once.

my @answers_ahead;

sub set_answers_ahead { @answers_ahead = map { split /,/ } grep { defined } @_; return }

sub answer_ahead { return @answers_ahead ? shift @answers_ahead : undef }

# One key, decoded: 'up', 'down', 'left', 'right', 'enter', 'esc', 'tab',
# 'shift-tab', 'pgup', 'pgdn', or the character itself; undef when the
# timeout passes.
# The terminal must be in cbreak or raw mode.
sub read_key {
    my ($timeout) = @_;
    my $c = ReadKey( defined $timeout ? $timeout : 0 );
    return undef unless defined $c;
    return 'enter' if $c eq "\n" || $c eq "\r";
    return 'tab'   if $c eq "\t";
    return $c unless $c eq "\e";
    my $n = ReadKey(0.05);
    return 'esc' unless defined $n && ( $n eq '[' || $n eq 'O' );
    my $seq = '';
    while ( defined( my $d = ReadKey(0.05) ) ) {
        $seq .= $d;
        last if $d =~ /[A-Za-z~]/;
    }
    return { A => 'up', B => 'down', C => 'right', D => 'left', Z => 'shift-tab', '5~' => 'pgup', '6~' => 'pgdn' }->{$seq} // 'esc';
}

# A yes or no with a timed default and a visible countdown: the question,
# its [Y/n] block, and in brackets the seconds left, redrawn every second on
# one row while a single key is awaited. Enter takes the default. When the
# answer is in, the row is rewritten to the answer taken and how it was taken.
# Returns (answer, how): answer 'y' or 'n'; how 'key', 'default after Ns',
# 'given ahead' or 'default, no terminal'.
sub timed_yes_no {
    my (%a) = @_;
    my $s       = $a{style};
    my $default = $a{default} // 'y';
    my $secs    = $a{seconds} // 10;
    my $lead    = $a{lead} // '';
    my $block   = $default eq 'y' ? '[Y/n]' : '[y/N]';
    my $q       = $a{question};
    # A row drawn inside a frame gets its right edge back at a fixed column.
    my $close   = defined $a{close} ? "\e[$a{close_col}G$a{close}" : q{};
    my $word    = sub { $_[0] eq 'y' ? ( $a{yes} // 'yes' ) : ( $a{no} // 'no' ) };
    my $final   = sub {
        my ( $ans, $how ) = @_;
        print "\r\e[2K$lead$s->{text}$q$s->{reset} $s->{bold}" . $word->($ans) . "$s->{reset} $s->{dim}($how)$s->{reset}$close\n";
        return ( $ans, $how );
    };
    if ( defined( my $given = answer_ahead() ) ) {
        my $ans = $given eq 'default' ? $default : lc substr( $given, 0, 1 ) eq 'n' ? 'n' : 'y';
        return $final->( $ans, 'given ahead' );
    }
    return $final->( $default, 'default, no terminal' ) unless interactive();
    raw_mode('cbreak');
    print "\e[?25l";
    my $end = time + $secs;
    my $ans;
    while (1) {
        my $left = int( $end - time + 0.999 );
        last if $left <= 0;
        print "\r\e[2K$lead$s->{text}$q$s->{reset} $s->{bold}$block$s->{reset} $s->{dim}(${left}s)$s->{reset}$close";
        my $wait = $end - time - ( $left - 1 );
        my $k = read_key( $wait > 0 ? $wait : 0.01 );
        next unless defined $k;
        if ( $k eq 'enter' ) { $ans = $default; last }
        if ( lc $k eq 'y' || lc $k eq 'n' ) { $ans = lc $k; last }
    }
    restore_mode();
    return $final->( $ans, 'key' ) if defined $ans;
    return $final->( $default, "default after ${secs}s" );
}

1;
