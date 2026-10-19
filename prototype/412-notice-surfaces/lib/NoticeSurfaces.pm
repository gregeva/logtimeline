package NoticeSurfaces;

# The three components of the surface framework (features/412-notice-surfaces.md
# § Surface framework contract): the panel, which presents the notices known
# once the data work is done; ask, the one surface for a question during the
# run, as a modal or in its compact box form, with the options list as its
# second stage; and the browser, many notices in a navigable list with a
# detail pane. Every moment of the run calls one of them with its own content;
# no moment has a presentation of its own (D5).
#
# What every component keeps, from the contract:
#   - the defaults table: a caller passes only what it wants otherwise;
#   - one key map (action()): arrows and j/k move, Tab and Shift-Tab step
#     between buttons or tabs, digits choose directly, Enter activates, Esc
#     closes taking the default, q/x quit the application where that is on,
#     any other key stops a countdown and nothing says so (D7);
#   - buttons in fixed places: the default rightmost and highlighted, the
#     countdown beside it, stop leftmost, go-further between; the caller's
#     choice letter underlined in each label, accepted in either case;
#   - a pop-up takes the smallest of three size tiers that fits its content,
#     measured with its second stage, and never changes size while shown;
#   - a surface that asks erases itself (D4); a record is the caller's boolean;
#   - a notice is one row, its parts told apart by colour and a marker (D3);
#   - boxes and pop-ups in the new style, inline text in the ltl look (D6);
#   - a pop-up that will be erased has two cells of padding inside its sides
#     and an empty row above and below each pane's content, and one empty row
#     before it when drawn below the cursor; the panel, which stays, has one
#     cell inside its sides and no empty rows.

use strict;
use warnings;
use utf8;
use Exporter 'import';
use List::Util qw(max min sum);
use Time::HiRes qw(time);
use NoticeProto qw(interactive display_width wrap_text strip_sgr categories read_key raw_mode restore_mode answer_ahead query_cursor_position);

our @EXPORT_OK = qw(defaults panel bullet_candidates bullet_sheet ask browser out live_row);

# --- the defaults table ------------------------------------------------------
#
# contract § Parameters and their defaults by use (settled 2026-10-19).

my %DEFAULTS = (
    'ask-modal' => { placement => 'alt',    size => 'auto',    quit => 1, keybar => 'full',    seconds => 10, record => 0 },
    'ask-box'   => { placement => 'inline', size => 'full',    quit => 0, keybar => 'letters', seconds => 10, record => 0 },
    browser     => { placement => 'alt',    size => 'auto',    quit => 1, keybar => 'full',    seconds => 15 },
    panel       => { placement => 'inline', size => 'content' },
);

sub defaults {
    my ($use) = @_;
    my $d = $DEFAULTS{$use} or die "no use '$use' in the defaults table\n";
    return %$d;
}

# The defaults of a use, overlaid with what the caller passed.
sub with_defaults {
    my ( $use, %a ) = @_;
    my %d = defaults($use);
    $d{$_} = $a{$_} for grep { defined $a{$_} } keys %a;
    return %d;
}

# --- the key map -------------------------------------------------------------
#
# contract § Keys. A decoded key becomes one action, the same on every
# component: 'up' 'down' 'pgup' 'pgdn' 'left' 'right' 'next' 'prev' 'enter'
# 'esc' 'quit' 'digit:N' 'letter:x' or 'other'.

sub action {
    my ( $k, %o ) = @_;
    return 'up'   if $k eq 'up'   || $k eq 'k';
    return 'down' if $k eq 'down' || $k eq 'j';
    return $k     if $k =~ /^(?:pgup|pgdn|left|right|enter|esc)$/;
    return 'next' if $k eq 'tab';
    return 'prev' if $k eq 'shift-tab';
    return "digit:$k" if $k =~ /^[1-9]$/;
    return 'other' if length $k != 1;
    my $l = lc $k;
    return 'quit' if $o{quit} && ( $l eq 'q' || $l eq 'x' );
    return "letter:$l";
}

# The key bar's text: every entry is `keys: action`, the same shape on every
# surface (architect, 2026-10-19: "q/x: quit" throughout), so a pair of keys
# never reads as a key and an action. Takes [keys, action] pairs; quitting is
# appended where it is on.
sub key_bar {
    my ( $pairs, %k ) = @_;
    my @p = map { "$_->[0]: $_->[1]" } @$pairs;
    push @p, 'q/x: quit' if $k{quit};
    return join ' · ', @p;
}

# --- pieces -----------------------------------------------------------------

sub cat_named {
    my ($name) = @_;
    my ($c) = grep { $_->{name} eq $name } categories();
    return $c;
}

# The notices grouped by category, in the categories' presentation order.
sub grouped {
    my ($list) = @_;
    my @groups;
    for my $cat ( categories() ) {
        my @in = grep { $_->{category} eq $cat->{name} } @$list;
        push @groups, [ $cat, \@in ] if @in;
    }
    return @groups;
}

# A string with SGR codes cut to $w display cells, an ellipsis marking the cut.
sub fit {
    my ( $str, $w ) = @_;
    return $str if display_width($str) <= $w;
    my ( $out, $cw ) = ( '', 0 );
    while ( $str =~ /\G(\e\[[0-9;]*m|.)/gs ) {
        my $t = $1;
        if ( $t =~ /^\e/ ) { $out .= $t; next }
        my $tw = display_width($t);
        last if $cw + $tw > $w - 1;
        $out .= $t;
        $cw += $tw;
    }
    return "$out…\e[0m";
}

sub pad_to {
    my ( $row, $w ) = @_;
    $row = fit( $row, $w );
    return $row . ( ' ' x ( $w - display_width($row) ) );
}

# The longest word of a text, in cells: what cannot be wrapped.
sub longest_word {
    my (@texts) = @_;
    return max( 0, map { display_width($_) } map { split / +/, strip_sgr( $_ // '' ) } @texts );
}

# A notice as one row where it fits (D3): its focus in bold, the statement,
# the evidence dim after a dot, the remedy after an arrow in the category's
# colour. Past $width it wraps by words, the rows after the first indented by
# $indent cells. A record (the answer given at a choice) is one dim row after
# a hooked arrow.
sub notice_line {
    my ( $n, $s, $fg, $width, $indent ) = @_;
    $indent //= 2;
    my @parts;
    if ( $n->{record} ) {
        @parts = ( [ "↳ $n->{statement}", $s->{dim} ] );
    }
    else {
        push @parts, [ $n->{focus}, "\e[1m" . $s->{text} ] if $n->{focus};
        push @parts, [ $n->{statement}, $s->{text} ];
        push @parts, [ '· ' . join( '; ', @{ $n->{evidence} } ), $s->{dim} ] if $n->{evidence} && @{ $n->{evidence} };
        push @parts, [ "→ $n->{remedy}", $fg ] if $n->{remedy};
    }
    my @tok = map { my ( $t, $c ) = @$_; map { [ $_, $c ] } split / +/, $t } @parts;
    my @lines = ( [] );
    my $w = 0;
    for my $t (@tok) {
        my $tw = display_width( $t->[0] );
        my $limit = @lines == 1 ? $width : $width - $indent;
        if ( @{ $lines[-1] } && $w + 1 + $tw > $limit ) { push @lines, []; $w = 0 }
        $w += ( @{ $lines[-1] } ? 1 : 0 ) + $tw;
        push @{ $lines[-1] }, $t;
    }
    return map {
        ( $_ && $indent > 0 ? ' ' x $indent : '' ) . join( ' ', map { $_->[1] . $_->[0] . $s->{reset} } @{ $lines[$_] } )
    } 0 .. $#lines;
}

# A category's label: its glyph and upper-case name, in its colour, bold.
sub label {
    my ( $cat, $s ) = @_;
    my $fg = $s->{fg}{ $cat->{name} };
    return "$s->{bold}$fg$cat->{glyph} " . uc( $cat->{name} ) . $s->{reset};
}

# A category heading on one row: the label, the count, and how to read the
# category, cut to fit.
sub heading {
    my ( $cat, $s, $count, $width ) = @_;
    my $head = label( $cat, $s );
    $head .= " $s->{dim}($count)$s->{reset}" if defined $count;
    my $room = $width - display_width($head) - 2;
    $head .= "  $s->{dim}" . fit( $cat->{reads}, $room ) . $s->{reset} if $room > 12;
    return $head;
}

# Rows framed in a box $a{width} cells wide: $a{title} set in the top edge,
# $a{foot} in the bottom edge, each row padded to the inside width, which
# leaves $a{side} cells of padding inside each edge (two for a pop-up that is
# erased, one for the panel that stays; counted as rendered), a row 'RULE'
# drawn as a divider across the box. inside_width() is what a component lays
# its rows out to.
my $POPUP_SIDE = 2;
my $PANEL_SIDE = 1;

sub inside_width { my ( $box_width, $side ) = @_; return $box_width - 2 - 2 * ( $side // $POPUP_SIDE ) }

sub frame {
    my (%a) = @_;
    my $s = $a{s};
    my $b = $s->{box};
    my $e = $a{edge} // $s->{frame};
    my $w = $a{width};
    my $side = $a{side} // $POPUP_SIDE;
    my $sp = ' ' x $side;
    my $edge = sub {
        my ( $l, $text, $r ) = @_;
        $text //= '';
        $text = fit( $text, $w - 4 );
        my $fill = $w - 3 - display_width($text);
        return $e . $l . $b->{h_line} . $s->{reset} . $text . $e . ( $b->{h_line} x ( $fill > 0 ? $fill : 0 ) ) . $r . $s->{reset};
    };
    my @out = ( $edge->( $b->{corner_tl}, $a{title}, $b->{corner_tr} ) );
    for my $r ( @{ $a{rows} } ) {
        if ( $r eq 'RULE' ) {
            push @out, $e . $b->{t_right} . ( $b->{h_line} x ( $w - 2 ) ) . $b->{t_left} . $s->{reset};
            next;
        }
        push @out, $e . $b->{v_line} . $s->{reset} . $sp . pad_to( $r, inside_width( $w, $side ) ) . $sp . $e . $b->{v_line} . $s->{reset};
    }
    push @out, $edge->( $b->{corner_bl}, $a{foot}, $b->{corner_br} );
    return @out;
}

# The bullet before a notice in a list: a light right stroke in the category's
# colour, so the one character carries the classification (chosen from the
# glyph sheet, round 4). The candidates stay for the sheet.
my @BULLETS = (
    [ '‐', 'U+2010 HYPHEN' ],
    [ '‒', 'U+2012 FIGURE DASH' ],
    [ '–', 'U+2013 EN DASH' ],
    [ '—', 'U+2014 EM DASH' ],
    [ '⁃', 'U+2043 HYPHEN BULLET' ],
    [ '─', 'U+2500 BOX DRAWINGS LIGHT HORIZONTAL' ],
    [ '╶', 'U+2576 BOX DRAWINGS LIGHT RIGHT' ],
    [ '⎯', 'U+23AF HORIZONTAL LINE EXTENSION' ],
    [ '·', 'U+00B7 MIDDLE DOT (not a dash, for contrast)' ],
    [ '◦', 'U+25E6 WHITE BULLET (not a dash, for contrast)' ],
);
my $DEFAULT_BULLET = '╶';

sub bullet_candidates { return @BULLETS }

# A notice's rows inside a list: the bullet in the category's colour, or the
# hooked arrow alone for a record.
sub bulleted {
    my ( $n, $s, $fg, $width, $bullet ) = @_;
    $bullet //= $DEFAULT_BULLET;
    my @r = notice_line( $n, $s, $fg, $width - 2, 0 );
    my $first = shift @r;
    return ( ( $n->{record} ? '  ' : "$fg$bullet$s->{reset} " ) . $first, map { "  $_" } @r );
}

# --- the panel ---------------------------------------------------------------
#
#   panel( s, W, notices => [...], bullet => glyph, form => headed|edge )
#
# One box round all the notices, however many (D9 sends many to the browser):
# each category headed once, its notices one row each, the categories divided
# by a blank row (D3). The title is `notices` and its count, dim. A single
# category takes the edge form (round 5: "this is the one"): the category's
# glyph, name, count and how-to-read text in the top edge, the notices alone
# inside, one row shorter; form => headed asks for the headed form anyway.

sub panel {
    my (%a) = @_;
    my $s = $a{s};
    my $W = $a{W};
    my @notices = grep { !$_->{record} } @{ $a{notices} };
    my @groups = grouped( $a{notices} );
    my $iw = inside_width( $W - 1, $PANEL_SIDE );
    my @rows;
    if ( ( $a{form} // 'edge' ) eq 'edge' && @groups == 1 ) {
        my ( $cat, $in ) = @{ $groups[0] };
        my $fg = $s->{fg}{ $cat->{name} };
        push @rows, bulleted( $_, $s, $fg, $iw, $a{bullet} ) for @$in;
        my $title = ' ' . heading( $cat, $s, scalar(@notices), $W - 7 ) . ' ';
        return frame( s => $s, edge => $fg, width => $W - 1, side => $PANEL_SIDE, title => $title, rows => \@rows );
    }
    for my $gi ( 0 .. $#groups ) {
        my ( $cat, $in ) = @{ $groups[$gi] };
        my $fg = $s->{fg}{ $cat->{name} };
        push @rows, '' if $gi;
        push @rows, heading( $cat, $s, scalar( grep { !$_->{record} } @$in ), $iw );
        push @rows, bulleted( $_, $s, $fg, $iw, $a{bullet} ) for @$in;
    }
    my $title = " $s->{dim}notices (" . scalar(@notices) . ")$s->{reset} ";
    return frame( s => $s, width => $W - 1, side => $PANEL_SIDE, title => $title, rows => \@rows );
}

# The glyph sheet: every bullet candidate in the panel's own context, a
# category heading and two notices under it, so the bullet is judged beside
# the category glyph (round 3: the filled circle overshadowed it).
sub bullet_sheet {
    my (%a) = @_;
    my $s = $a{s};
    my $W = $a{W};
    my $iw = inside_width( $W - 1, $PANEL_SIDE );
    my @groups = grouped( $a{notices} );
    my @rows;
    for my $i ( 0 .. $#BULLETS ) {
        my ( $glyph, $name ) = @{ $BULLETS[$i] };
        my ( $cat, $in ) = @{ $groups[ $i % @groups ] };
        my $fg = $s->{fg}{ $cat->{name} };
        push @rows, '' if $i;
        push @rows, "$s->{pick}" . ( $i + 1 ) . "$s->{reset}  $s->{dim}$name$s->{reset}";
        push @rows, heading( $cat, $s, scalar @$in, $iw );
        push @rows, bulleted( $_, $s, $fg, $iw, $glyph ) for @$in[ 0 .. min( 1, $#$in ) ];
    }
    my $title = " $s->{dim}bullet glyphs (" . scalar(@BULLETS) . ")$s->{reset} ";
    return frame( s => $s, width => $W - 1, side => $PANEL_SIDE, title => $title, rows => \@rows );
}

# --- what the run has printed ------------------------------------------------
#
# The rows a prototype prints, kept so that a surface on the alternate screen
# can draw itself over a dimmed copy of them, each row at the position it has
# on the terminal: the analyst sees the run behind the question, unmoved.

my @printed;
my $live = '';

sub out {
    for (@_) { print "$_\n"; push @printed, $_ }
    $live = '';
    return;
}

# The row being repainted in place (the progress line).
sub live_row {
    my ( $text, $W ) = @_;
    $live = $text;
    print "\r$text", ' ' x ( $W - 1 - display_width($text) );
    return;
}

# The backdrop: H rows as the terminal holds them. The cursor's row, from the
# terminal's own report, is the live row; the printed rows end on the row
# above it; what is above them is unknown and left blank.
sub backdrop_layer {
    my ( $W, $H ) = @_;
    raw_mode('cbreak');
    my ($row) = query_cursor_position();
    $row //= $H;
    $row = $H if $row > $H;
    my @bd = ('') x $H;
    $bd[ $row - 1 ] = $live;
    my $r = $row - 2;
    for my $p ( reverse @printed ) {
        last if $r < 0;
        $bd[ $r-- ] = $p;
    }
    return { rows => \@bd, top => 1, col => 1 };
}

# --- where a component is drawn ----------------------------------------------
#
# alt:    centred on the alternate screen over the dimmed layers under it: the
#         backdrop, and any surface it is layered over; on leaving the screen
#         is given back as it was.
# inline: one empty row, then the box from the next row down, redrawn in
#         place, erased on leaving (the empty row too) with the cursor back on
#         the row it started on.
# over:   centred within the rows of an inline parent, for a modal layered
#         over a surface drawn below the cursor; the parent repaints itself.
# plain:  not in a terminal; drawn once, as it would first appear.

sub drawer {
    my (%a) = @_;
    my $mode = interactive() ? $a{placement} : 'plain';
    my $d = { mode => $mode, W => $a{W}, H => $a{H}, h => 0, under => $a{under} // [], parent => $a{parent} };
    if ( $mode eq 'alt' && !@{ $d->{under} } ) {
        push @{ $d->{under} }, backdrop_layer( $a{W}, $a{H} );
    }
    return $d;
}

sub paint_layer {
    my ( $l, $dimmed ) = @_;
    for my $i ( 0 .. $#{ $l->{rows} } ) {
        my $r = $l->{rows}[$i];
        print "\e[" . ( $l->{top} + $i ) . ";$l->{col}H";
        print $dimmed ? "\e[2m" . strip_sgr($r) . "\e[0m" : $r;
    }
    return;
}

sub draw_rows {
    my ( $d, @rows ) = @_;
    my ( $W, $H ) = @$d{qw(W H)};
    if ( $d->{mode} eq 'plain' ) {
        return if $d->{h}++;
        print "\r\e[2K";
        print "$_\n" for @rows;
        return;
    }
    if ( $d->{mode} eq 'alt' ) {
        print "\e[?1049h" unless $d->{on}++;
        print "\e[H\e[2J";
        paint_layer( $_, 1 ) for @{ $d->{under} };
        my $bw  = max map { display_width($_) } @rows;
        my $top = max( 1, int( ( $H - @rows ) / 2 ) + 1 );
        my $col = max( 1, int( ( $W - $bw ) / 2 ) + 1 );
        $d->{last} = { rows => [@rows], top => $top, col => $col };
        paint_layer( $d->{last}, 0 );
        return;
    }
    if ( $d->{mode} eq 'over' ) {
        my $p   = $d->{parent};
        my $bw  = max map { display_width($_) } @rows;
        my $top = max( 0, int( ( $p->{h} - @rows ) / 2 ) );
        my $col = max( 1, int( ( $W - $bw ) / 2 ) + 1 );
        my $up  = $p->{h} - 1 - $top;
        print "\e[${up}A" if $up > 0;
        print "\r\e[${col}G$rows[$_]" . ( $_ < $#rows ? "\n" : '' ) for 0 .. $#rows;
        my $down = $p->{h} - 1 - ( $top + $#rows );
        print "\e[${down}B" if $down > 0;
        print "\r";
        return;
    }
    if ( $d->{h} ) { print "\e[" . ( $d->{h} - 1 ) . "A" }
    else            { print "\r\e[2K\n"; $d->{lead} = 1 }
    print "\r";
    print "\e[J" if @rows < $d->{h};
    print "\e[2K$rows[$_]" . ( $_ < $#rows ? "\n" : '' ) for 0 .. $#rows;
    $d->{h} = @rows;
    return;
}

sub close_drawer {
    my ($d) = @_;
    if ( $d->{mode} eq 'alt' ) {
        print "\e[?1049l" if $d->{on};
    }
    elsif ( $d->{mode} eq 'inline' && $d->{h} ) {
        print "\e[" . ( $d->{h} - 1 + ( $d->{lead} // 0 ) ) . "A";
        print "\r\e[J";
    }
    $d->{h} = 0;
    return;
}

# The layers a surface layered over this one draws under itself.
sub layers_of {
    my ($d) = @_;
    return [ @{ $d->{under} }, ( $d->{last} ? $d->{last} : () ) ];
}

# --- waiting for the analyst -------------------------------------------------

# A choice with a countdown to its default. $draw->($left) paints the surface
# with the seconds left, undef once the countdown is stopped; $act->($action)
# returns the choice for an action that chooses and undef for any other,
# which stops the countdown (D7) so the analyst has the time to read.
sub wait_choice {
    my (%a) = @_;
    my $end = time + $a{seconds};
    my $stopped = $a{seconds} <= 0;
    raw_mode('cbreak');
    print "\e[?25l";
    my ( $v, $how );
    while (1) {
        my $left = $stopped ? undef : int( $end - time + 0.999 );
        if ( defined $left && $left <= 0 ) { ( $v, $how ) = ( $a{default}, "default after $a{seconds}s" ); last }
        $a{draw}->($left);
        my $wait = $stopped ? undef : $end - time - ( $left - 1 );
        my $k = read_key( $stopped ? undef : $wait > 0 ? $wait : 0.01 );
        next unless defined $k;
        my $c = $a{act}->( action( $k, quit => $a{quit} ) );
        if ( defined $c ) { ( $v, $how ) = ( $c, 'key' ); last }
        $stopped = 1;
    }
    restore_mode();
    return ( $v, $how );
}

# The seconds left, dim in brackets, or the same width of nothing once the
# countdown is stopped, so what stands beside it does not move.
sub countdown {
    my ( $s, $left, $seconds ) = @_;
    my $slot = length("(${seconds}s)");
    return ' ' x $slot unless defined $left;
    my $t = "(${left}s)";
    return "$s->{dim}$t$s->{reset}" . ( ' ' x ( $slot - length $t ) );
}

# --- buttons -------------------------------------------------------------------
#
# contract § Buttons: fixed places by role, the caller's labels, the choice
# letter underlined.

my %ORDER = ( stop => 0, more => 1, default => 2 );

sub ordered_buttons {
    my ($list) = @_;
    return sort { $ORDER{ $a->{role} } <=> $ORDER{ $b->{role} } } @$list;
}

# A label with its choice letter underlined, at the letter's first occurrence
# in either case.
sub lettered {
    my ( $b, $under, $over ) = @_;
    my $l = $b->{label};
    my $i = index( lc $l, lc $b->{key} );
    return $l if $i < 0 || !defined $b->{key};
    return substr( $l, 0, $i ) . "\e[4m" . substr( $l, $i, 1 ) . "\e[24m" . substr( $l, $i + 1 );
}

# The buttons on one row: the highlighted one in reverse video in the
# category's colour, the others framed in brackets. Returns the row of labels
# and, apart, the countdown's slot (always the same width), which the caller
# sets beside the default button outside the centred width, so the buttons
# do not move when the countdown stops.
sub button_row {
    my ( $s, $fg, $btns, $focus, $left, $seconds ) = @_;
    my @b;
    for my $i ( 0 .. $#$btns ) {
        my $b = $btns->[$i];
        my $text = lettered($b);
        push @b, $i == $focus
            ? "$fg\e[7m\e[1m  $text  \e[0m"
            : $s->{text} . "[ $text ]" . $s->{reset};
    }
    return ( join( '    ', @b ), countdown( $s, $left, $seconds ) );
}

# The button row centred in $iw on its labels alone, the countdown after it.
sub centred_buttons {
    my ( $s, $fg, $btns, $focus, $left, $seconds, $iw ) = @_;
    my ( $brow, $cd ) = button_row( $s, $fg, $btns, $focus, $left, $seconds );
    return ( ' ' x max( 0, int( ( $iw - display_width($brow) ) / 2 ) ) ) . "$brow $cd";
}

# --- the options list (the second stage of a choice, D8) ---------------------
#
# Each option on one row in columns under the consumer's headings; the
# columns before the last take their widest part, the last wraps within its
# column; the highlighted option in reverse video, its effect after an empty
# row beneath the list. Fewer parts than headings: fewer columns.

# The columns: how many parts, the fixed widths, the gap between columns
# (one space at the tightest, up to five with room: the spare width shared
# between the gaps and the last column) and where the last column starts.
sub option_columns {
    my ( $options, $headings, $iw ) = @_;
    my $P = min( scalar @$headings, max map { scalar @{ $_->{parts} } } @$options );
    my @w;
    for my $c ( 0 .. $P - 2 ) {
        $w[$c] = max( display_width( $headings->[$c] ), map { display_width( $_->{parts}[$c] // '' ) } @$options );
        $w[$c] = int( $iw * 0.4 ) if $w[$c] > int( $iw * 0.4 );
    }
    my $lead  = 5;    # marker, digit, spaces
    my $gaps  = $P - 1;
    my $fixed = sum( 0, @w );
    my $last_min = min( 24, max( display_width( $headings->[ $P - 1 ] ), longest_word( map { $_->{parts}[ $P - 1 ] } @$options ) ) );
    my $spare = $iw - $lead - $fixed - $last_min;
    my $gap = $gaps ? min( 5, max( 1, int( $spare / ( 2 * $gaps ) ) ) ) : 0;
    my $last_at = $lead + $fixed + $gap * $gaps;
    return ( $P, \@w, $last_at, $gap );
}

sub options_rows {
    my ( $options, $headings, $sel, $s, $fg, $iw ) = @_;
    my ( $P, $w, $last_at, $gap ) = option_columns( $options, $headings, $iw );
    my $room = max( 8, $iw - $last_at );
    my $g = ' ' x $gap;
    my $head = ' ' x $last_at;
    $head = ( ' ' x 5 ) . join( '', map { pad_to( $headings->[$_], $w->[$_] ) . $g } 0 .. $P - 2 ) if $P > 1;
    my @rows = ( "$s->{pick}" . $head . $headings->[ $P - 1 ] . "$s->{reset}" );
    for my $i ( 0 .. $#$options ) {
        my $o = $options->[$i];
        my $fixed = join '', map { pad_to( $o->{parts}[$_] // '', $w->[$_] ) . $g } 0 .. $P - 2;
        my @last = wrap_text( $o->{parts}[ $P - 1 ] // '', $room );
        @last = ('') unless @last;
        my $c = $i == $sel ? $fg : $s->{dim};
        my $mark = $i == $sel ? "$fg▶$s->{reset} " : '  ';
        my $cells = ( $i + 1 ) . '  ' . $fixed;
        push @rows, $mark . ( $i == $sel ? "$s->{pick}\e[7m" . strip_sgr($cells) . "\e[0m" : "$s->{text}$cells$s->{reset}" ) . "$c" . shift(@last) . $s->{reset};
        push @rows, ( ' ' x $last_at ) . "$c$_$s->{reset}" for @last;
    }
    push @rows, '', "   $s->{dim}" . fit( $options->[$sel]{effect} // '', $iw - 3 ) . $s->{reset};
    return @rows;
}

# The width the list needs for its last column to wrap to no more than two
# rows: the fixed columns at the tightest gap, and half the longest last part.
# Dense content takes a wider tier through it (round 4).
sub options_unit {
    my ( $options, $headings ) = @_;
    my ( $P, $w, $last_at ) = option_columns( $options, $headings, 0 );
    my $last = max( 16, map { display_width( $_->{parts}[ $P - 1 ] // '' ) } @$options );
    return $last_at + max( longest_word( map { $_->{parts}[ $P - 1 ] } @$options ), int( ( $last + 1 ) / 2 ) );
}

# --- size tiers ---------------------------------------------------------------
#
# contract § Pop-up size (proposed, to be seen in round 4): three tiers as
# ratios of the terminal; the smallest in which the content's longest
# unbreakable unit fits and its wrapped rows do not exceed the height.

my %TIER = ( small => [ 0.5, 0.3 ], medium => [ 0.7, 0.5 ], large => [ 0.9, 0.8 ] );

sub tier_dims {
    my ( $tier, $W, $H ) = @_;
    my ( $fw, $fh ) = @{ $TIER{$tier} or die "no size tier '$tier'\n" };
    my $bw = int( $W * $fw );
    $bw = 44 if $bw < 44;
    $bw = $W - 2 if $bw > $W - 2;
    my $mh = int( $H * $fh );
    $mh = 6 if $mh < 6;
    return ( $bw, $mh );
}

# ($box width, $max rows, $tier): the named tier, or the smallest that fits
# what $measure->($box width) reports as (unit, rows).
sub choose_tier {
    my ( $W, $H, $measure, $named ) = @_;
    return ( tier_dims( $named, $W, $H ), $named ) if $named && $named ne 'auto';
    for my $t (qw(small medium large)) {
        my ( $bw, $mh ) = tier_dims( $t, $W, $H );
        my ( $unit, $rows ) = $measure->($bw);
        return ( $bw, $mh, $t ) if $unit <= $bw - 4 && $rows <= $mh;
    }
    return ( tier_dims( 'large', $W, $H ), 'large' );
}

# --- asking -------------------------------------------------------------------
#
#   ask( s, W, H, form => modal|box, category, notices => [...], question,
#        buttons => [ { label, key, role } ... ], options => [...], headings,
#        option_default, placement, size, quit, keybar, seconds, record,
#        fixed_height, under => layers, parent => inline drawer, stage => 1|2 )
#
# The one surface for a question raised during the run (D5): a modal, on the
# alternate screen over the dimmed run or below the cursor, or the compact
# box below the cursor with the choices on its question row. A button whose
# role is 'more' leads to the options list in the same surface, its second
# stage; stage => 2 opens on the list (a modal layered over the browser). The
# surface's width is chosen once for both stages; its height is each stage's
# own, growing when the list opens, or the taller stage's for both with
# fixed_height (the contract's size line, proposed, is to be seen: both are
# offered). It is erased once answered (D4).
# Returns (role, how, option index, option how): the role of the button taken
# ('quit' when the analyst quit), the option undefined when none was chosen.

sub ask {
    my (%a) = @_;
    my $s    = $a{s};
    my $form = $a{form} // 'modal';
    my %p    = with_defaults( "ask-$form", map { $_ => $a{$_} } qw(placement size quit keybar seconds record) );
    my $cat  = cat_named( $a{category} );
    my $fg   = $s->{fg}{ $a{category} };
    my ( $W, $H ) = @a{qw(W H)};
    my @btn  = ordered_buttons( $a{buttons} // [] );
    my ($def_i) = grep { $btn[$_]{role} eq 'default' } 0 .. $#btn;
    $def_i //= $#btn;
    my %letter = map { lc( $btn[$_]{key} // '' ) => $_ } grep { defined $btn[$_]{key} } 0 .. $#btn;
    my $headings = $a{headings} // [ 'What?', 'How?', 'Why?' ];
    my $opt_def  = $a{option_default} // 0;
    my $stage    = $a{stage} // 1;
    my $count    = @{ $a{notices} };

    my ( $role, $how, $oi, $ohow );
    if ( defined( my $given = answer_ahead() ) ) {
        my $i = $given eq 'default' ? $def_i : $letter{ lc substr( $given, 0, 1 ) } // $def_i;
        ( $role, $how ) = ( $btn[$i]{role}, 'given ahead' );
        if ( ( $role eq 'more' || $stage == 2 ) && $a{options} ) {
            my $g = answer_ahead();
            $oi = defined $g && $g =~ /^\d+$/ && $g >= 1 && $g <= @{ $a{options} } ? $g - 1 : $opt_def;
            $ohow = 'given ahead';
        }
        leave_record( \%a, \@btn, $role, $how, $oi ) if $p{record};
        return ( $role, $how, $oi, $ohow );
    }

    my $edge  = $fg;
    my $title = ' ' . label( $cat, $s ) . ( $count > 1 ? " $s->{dim}($count)$s->{reset}" : '' ) . ' ';
    my $treads = sub { my ($bw) = @_; my $room = $bw - 6 - display_width($title); return $room > 12 ? "$title$s->{dim}" . fit( $cat->{reads}, $room ) . "$s->{reset} " : $title };
    my $q = "$s->{text}$a{question}$s->{reset}";
    my $esc_takes = lc( $btn[$def_i]{label} // 'close' );

    # The body rows at an inside width: the notices (bulleted when several).
    my $body = sub {
        my ($iw) = @_;
        return map { $count > 1 ? bulleted( $_, $s, $fg, $iw ) : notice_line( $_, $s, $fg, $iw, 0 ) } @{ $a{notices} };
    };
    # Stage 1's tail: the question and the buttons (modal), or the question
    # row with the choices inline (box).
    my $tail1 = sub {
        my ( $iw, $focus, $left ) = @_;
        if ( $form eq 'box' ) {
            my @ch;
            for my $i ( 0 .. $#btn ) {
                my $t = lettered( $btn[$i] );
                push @ch, ( $i == $def_i ? "$s->{pick}$t$s->{reset} " . countdown( $s, $left, $p{seconds} ) : "$s->{text}$t$s->{reset}" );
            }
            return ( $q . '  ' . join( '   ', @ch ) );
        }
        return ( ( ' ' x max( 0, int( ( $iw - display_width($q) ) / 2 ) ) ) . $q, '',
                 centred_buttons( $s, $fg, \@btn, $focus, $left, $p{seconds}, $iw ) );
    };
    my $tail2 = sub {
        my ( $iw, $sel ) = @_;
        return ( 'RULE', '', options_rows( $a{options}, $headings, $sel, $s, $fg, $iw ) );
    };
    my $foot = sub {
        my ($st) = @_;
        return undef if $p{keybar} eq 'none';
        my $esc = $stage == 2 ? 'back' : $esc_takes;
        if ( $p{keybar} eq 'letters' ) {
            my $t = $st == 2
                ? key_bar( [ [ '1-' . scalar( @{ $a{options} } ), 'choose' ], [ 'Esc', $esc ] ], quit => $p{quit} )
                : key_bar( [ [ join( '/', grep { defined } map { $_->{key} } @btn ), 'choose' ] ], quit => $p{quit} );
            return " $s->{dim}$t$s->{reset} ";
        }
        my $t = $st == 2
            ? key_bar( [ [ '↑↓ j k', 'move' ], [ '1-' . scalar( @{ $a{options} } ) . ' Enter', 'choose' ], [ 'Esc', $esc ] ], quit => $p{quit} )
            : key_bar( [ [ '←→ Tab', 'move' ], [ 'Enter', 'choose' ], [ 'Esc', $esc ] ], quit => $p{quit} );
        return " $s->{dim}$t$s->{reset} ";
    };

    # Size: the width from the tier (modal) or the terminal (box); an empty
    # row above and below the content in both forms (both are erased).
    my $pad = 1;
    # A stage's tail: a blank row closes the body's pane, then the question
    # and buttons, or the rule and the list pane (blank, list, blank, effect).
    my $tail = sub {
        my ( $st, $iw, $x, $left ) = @_;
        return ( '', $tail2->( $iw, $x ) ) if $st == 2;
        return ( '', $tail1->( $iw, $x, $left ) );
    };
    # The rows a stage needs, counted from the rows themselves.
    my $stage_rows = sub {
        my ( $iw, $st ) = @_;
        my @b = $body->($iw);
        my @t = $tail->( $st, $iw, 0, $p{seconds} );
        return @b + @t + 2 * $pad;
    };
    # The rows inside the frame: the taller stage's when the height is fixed
    # for both (fixed_height), else each stage's own; the width is one for
    # both stages either way.
    my $rows_in = sub {
        my ( $iw, $st ) = @_;
        return max( $stage_rows->( $iw, 1 ), $a{options} ? $stage_rows->( $iw, 2 ) : 0 ) if $a{fixed_height} || !defined $st;
        return $stage_rows->( $iw, $st );
    };
    my $measure = sub {
        my ($bw) = @_;
        my $iw = inside_width($bw);
        my ($brow) = button_row( $s, $fg, \@btn, 0, $p{seconds}, $p{seconds} );
        my $unit = max( display_width($title) + 6 + min( 24, display_width( $cat->{reads} ) ),
                        display_width( $foot->(1) // '' ) + 4,
                        ( $a{options} ? display_width( $foot->(2) // '' ) + 4 : 0 ),
                        display_width($brow) + 2 + length("(${\ $p{seconds}}s)") + 8,
                        ( $a{options} ? options_unit( $a{options}, $headings ) + 8 : 0 ),
                        longest_word( $a{question}, map { ( $_->{focus}, $_->{statement}, $_->{remedy}, @{ $_->{evidence} // [] } ) } @{ $a{notices} } ) + 8 );
        return ( $unit, $rows_in->($iw) + 2 );
    };
    my ( $bw, $mh, $tier );
    if ( $form eq 'box' ) { ( $bw, $mh, $tier ) = ( $W - 1, $H - 2, 'full' ) }
    else                  { ( $bw, $mh, $tier ) = choose_tier( $W, $H, $measure, $p{size} ) }
    my $iw       = inside_width($bw);
    my $top_edge = $treads->($bw);

    # The frame's rows for a stage, the body at the top and the tail at the
    # bottom, filled to the fixed height.
    my $frame_rows = sub {
        my ( $st, $x, $left ) = @_;
        my $height = min( $rows_in->( $iw, $st ), $mh - 2 );
        my @b = $body->($iw);
        my @t = $tail->( $st, $iw, $x, $left );
        my $fill = $height - 2 * $pad - @b - @t;
        my @in = ( ('') x $pad, @b, ( ('') x max( 0, $fill ) ), @t, ('') x $pad );
        @in = @in[ 0 .. $height - 1 ] if @in > $height;
        return frame( s => $s, edge => $edge, width => $bw, title => $top_edge, foot => $foot->($st), rows => \@in );
    };

    my $placement = $form eq 'modal' ? $p{placement} : 'inline';
    $placement = 'over' if $a{parent};
    my $d = drawer( placement => $placement, W => $W, H => $H, under => $a{under}, parent => $a{parent} );
    my $indent = $d->{mode} eq 'inline' && $form eq 'modal' ? ' ' x int( ( $W - $bw ) / 2 ) : '';
    my $draw = sub { draw_rows( $d, map { "$indent$_" } @_ ) };

    if ( $d->{mode} eq 'plain' ) {
        $draw->( $frame_rows->( $stage, $stage == 2 ? $opt_def : $def_i, $p{seconds} ) );
        ( $role, $how ) = ( $btn[$def_i]{role} // 'default', 'default, no terminal' );
        $a{tier} = $tier;
        return ( $role, $how, undef, undef );
    }

    my $focus = $def_i;
    if ( $stage == 1 ) {
        my ( $i, $h ) = wait_choice(
            seconds => $p{seconds},
            default => $def_i,
            quit    => $p{quit},
            draw    => sub { $draw->( $frame_rows->( 1, $focus, $_[0] ) ) },
            act     => sub {
                my ($act) = @_;
                return 'quit' if $act eq 'quit';
                return $letter{$1} if $act =~ /^letter:(.)$/ && defined $letter{$1};
                return $def_i if $act eq 'esc';
                if ( $form eq 'modal' ) {
                    return $focus if $act eq 'enter';
                    $focus = ( $focus + 1 ) % @btn if $act eq 'right' || $act eq 'next';
                    $focus = ( $focus - 1 ) % @btn if $act eq 'left'  || $act eq 'prev';
                    return undef;
                }
                return $def_i if $act eq 'enter';
                return undef;
            },
        );
        if ( $i eq 'quit' ) { close_drawer($d); return ( 'quit', 'key', undef, undef ) }
        ( $role, $how ) = ( $btn[$i]{role}, $h );
    }
    if ( ( $stage == 2 || $role eq 'more' ) && $a{options} ) {
        my $sel = $opt_def;
        my $n   = @{ $a{options} };
        raw_mode('cbreak');
        print "\e[?25l";
        while (1) {
            $draw->( $frame_rows->( 2, $sel ) );
            my $k = read_key();
            next unless defined $k;
            my $act = action( $k, quit => $p{quit} );
            if    ( $act eq 'up' )   { $sel = ( $sel - 1 ) % $n }
            elsif ( $act eq 'down' ) { $sel = ( $sel + 1 ) % $n }
            elsif ( $act =~ /^digit:(\d)$/ && $1 <= $n ) { $sel = $1 - 1 }
            elsif ( $act eq 'enter' ) { ( $oi, $ohow ) = ( $sel, 'key' ); last }
            elsif ( $act eq 'esc' )   { ( $oi, $ohow ) = $stage == 2 ? ( undef, 'Esc' ) : ( $opt_def, 'Esc' ); last }
            elsif ( $act eq 'quit' )  { restore_mode(); close_drawer($d); return ( 'quit', 'key', undef, undef ) }
        }
        restore_mode();
        $role //= 'more';
        $how  //= $ohow;
    }
    close_drawer($d);
    leave_record( \%a, \@btn, $role, $how, $oi ) if $p{record};
    return ( $role, $how, $oi, $ohow );
}

# What a surface leaves when the caller asks for a record: the notices as
# inline text, in the ltl look, and the answer on the row after them.
sub leave_record {
    my ( $a, $btn, $role, $how, $oi ) = @_;
    my $s   = $a->{s};
    my $cat = cat_named( $a->{category} );
    my $fg  = $s->{fg}{ $a->{category} };
    my $W   = $a->{W};
    my @rows;
    if ( @{ $a->{notices} } == 1 ) {
        my $lead = label( $cat, $s ) . ' ';
        my $lw = display_width($lead);
        my @r = notice_line( $a->{notices}[0], $s, $fg, $W - 1 - $lw, 2 - $lw );
        push @rows, $lead . shift(@r), map { "  $_" } @r;
    }
    else {
        push @rows, heading( $cat, $s, scalar @{ $a->{notices} }, $W - 1 ), map { bulleted( $_, $s, $fg, $W - 1 ) } @{ $a->{notices} };
    }
    my ($b) = grep { $_->{role} eq $role } @$btn;
    my $answer = lcfirst( $b ? $b->{label} : $role );
    if ( defined $oi ) {
        my $o = $a->{options}[$oi];
        $answer .= ': ' . lcfirst( $o->{parts}[0] ) . ( $o->{args} ? " $o->{args}" : '' );
    }
    push @rows, map { "  $_" } notice_line( { record => 1, statement => "$a->{question} $answer ($how)" }, $s, $fg, $W - 3, 2 );
    out(@rows);
    return;
}

# --- the browser ---------------------------------------------------------------
#
#   browser( s, W, H, notices => [...], placement, size, quit, seconds, rows )
#
# Tabs across the top filter by category (All first), every tab named; the
# list below, one row per notice; the selected notice's detail beneath, in a
# pane of fixed height, sized before drawing for the tallest detail any notice
# has (a histogram, options), so the window never changes size or moves while
# the analyst navigates. Enter on a notice with options opens the options list
# as an ask modal layered over the browser; the browser is back as it was when
# it closes. A countdown to closing runs until any key. Closing erases the
# box. Returns the options chosen, as [notice, option index, how], or 'quit'.

sub browser {
    my (%a) = @_;
    my $s = $a{s};
    my %p = with_defaults( 'browser', map { $_ => $a{$_} } qw(placement size quit keybar seconds) );
    my ( $W, $H ) = @a{qw(W H)};
    my $d = drawer( placement => $p{placement}, W => $W, H => $H );
    my @items = map { @{ $_->[1] } } grouped( $a{notices} );
    my @cats  = map { $_->[0] } grouped( \@items );
    my $headings = $a{headings} // [ 'What?', 'How?', 'Why?' ];

    # The detail pane's rows for a notice at an inside width.
    my $detail_rows = sub {
        my ( $n, $iw, $chosen ) = @_;
        my $fg = $s->{fg}{ $n->{category} };
        my $c  = cat_named( $n->{category} );
        my @r = ( heading( $c, $s, undef, $iw ), notice_line( $n, $s, $fg, $iw, 0 ) );
        push @r, '', map { "$s->{text}$_$s->{reset}" } @{ $n->{detail} } if $n->{detail};
        if ( $n->{options} ) {
            push @r, '', defined $chosen
                ? "$s->{dim}chosen:$s->{reset} $s->{pick}" . $n->{options}[$chosen]{parts}[0] . "$s->{reset} $fg$n->{options}[$chosen]{args}$s->{reset}"
                : "$fg◇$s->{reset} $s->{dim}" . scalar( @{ $n->{options} } ) . " options on offer: Enter to choose$s->{reset}";
        }
        return @r;
    };
    # Tabs: every tab named, the selected one a coloured block (D6).
    my $tab_rows = sub {
        my ( $tab, $iw ) = @_;
        my @tabs = ( $tab == 0 ? "$s->{pick}\e[7m All (" . @items . ") \e[0m" : "$s->{text} All (" . @items . ") $s->{reset}" );
        for my $i ( 0 .. $#cats ) {
            my $c  = $cats[$i];
            my $n  = grep { $_->{category} eq $c->{name} } @items;
            my $fg = $s->{fg}{ $c->{name} };
            my $l  = " $c->{glyph} " . uc( $c->{name} ) . " ($n) ";
            push @tabs, $tab == $i + 1 ? "$fg\e[7m\e[1m$l\e[0m" : "$fg$l$s->{reset}";
        }
        my @rows = ('');
        for my $t (@tabs) {
            push @rows, '' if $rows[-1] ne '' && display_width("$rows[-1] $t") > $iw;
            $rows[-1] .= ( $rows[-1] ne '' ? ' ' : '' ) . $t;
        }
        return @rows;
    };

    # Size: the tier's width; the height from the tallest detail, the tabs
    # and as many list rows as fit (at most $a{rows}, default 10), measured
    # before anything is drawn.
    my $want_L = $a{rows} // 10;
    my ( $D, $T, $L );
    my $measure = sub {
        my ($bw) = @_;
        my $iw = inside_width($bw);
        $D = max map { scalar( $detail_rows->( $_, $iw, 0 ) ) } @items;
        $T = scalar( $tab_rows->( 0, $iw ) );
        # The widest row no detail can wrap (a histogram), or a readable list;
        # the rows: the list pane (tabs, a blank, the list) and the detail
        # pane, each with an empty row above and below, a rule between.
        my $unit = max( 40, map { display_width($_) } map { @{ $_->{detail} // [] } } @items ) + 2 + 2 * $POPUP_SIDE;
        return ( $unit, 1 + $T + 1 + $want_L + 1 + 1 + 1 + $D + 1 + 2 );
    };
    my ( $bw, $mh, $tier ) = $d->{mode} eq 'inline' ? ( $W - 1, $H - 2, 'full' ) : choose_tier( $W, $H, $measure, $p{size} );
    # A detail wider than the largest tier (ltl's histograms side by side)
    # takes the whole width rather than being cut.
    ( $bw, $tier ) = ( $W - 1, 'full' ) if $d->{mode} ne 'inline' && ( $measure->($bw) )[0] > $bw - 2 - 2 * $POPUP_SIDE;
    $measure->($bw);
    $L = min( $want_L, $mh - 2 - 5 - $T - 1 - $D );
    $L = 3 if $L < 3;
    my $iw = inside_width($bw);

    my ( $tab, $sel, $top ) = ( 0, 0, 0 );
    my %chosen;
    my $shown = sub { $tab ? grep { $_->{category} eq $cats[ $tab - 1 ]{name} } @items : @items };
    my $rows = sub {
        my ($left) = @_;
        my @shown = $shown->();
        $sel = $#shown if $sel > $#shown;
        $top = $sel if $sel < $top;
        $top = $sel - $L + 1 if $sel >= $top + $L;
        my @r = ( '', $tab_rows->( $tab, $iw ), '' );
        for my $i ( $top .. $top + $L - 1 ) {
            if ( $i > $#shown ) { push @r, ''; next }
            my $n  = $shown[$i];
            my $fg = $s->{fg}{ $n->{category} };
            my $c  = cat_named( $n->{category} );
            my $mark = $n->{options} ? ( defined $chosen{$n} ? "$fg◆$s->{reset}" : "$fg◇$s->{reset}" ) : ' ';
            my $text = fit( join( ' ', notice_line( $n, $s, $fg, 10_000 ) ), $iw - 6 );
            push @r, $i == $sel
                ? "$fg▶$s->{reset} $fg$c->{glyph}$s->{reset} \e[7m" . pad_to( strip_sgr($text), $iw - 6 ) . "\e[0m $mark"
                : "  $fg$c->{glyph}$s->{reset} " . pad_to( $text, $iw - 6 ) . " $mark";
        }
        push @r, '', 'RULE', '';
        my @detail = $detail_rows->( $shown[$sel], $iw, $chosen{ $shown[$sel] } );
        push @r, ( map { $detail[$_] // '' } 0 .. $D - 1 ), '';
        my $cd = defined $left ? ' ' . countdown( $s, $left, $p{seconds} ) : '';
        my $foot = ' ' . $s->{dim} . key_bar( [ [ '↑↓ j k', 'move' ], [ '←→ Tab', 'tabs' ], [ '1-' . ( @cats + 1 ), 'tab' ], [ 'Enter', 'options' ], [ 'Esc', 'close' ] ], quit => $p{quit} ) . $s->{reset} . $cd . ' ';
        my $range = ( @shown ? $top + 1 : 0 ) . '-' . ( $top + $L > @shown ? scalar @shown : $top + $L ) . ' of ' . @shown;
        return frame( s => $s, width => $bw, rows => \@r, foot => $foot,
            title => " $s->{dim}notices (" . @items . ") · $range$s->{reset} " );
    };

    if ( $d->{mode} eq 'plain' ) {
        draw_rows( $d, $rows->( $p{seconds} ) );
        return [];
    }
    raw_mode('cbreak');
    print "\e[?25l";
    my $end = time + $p{seconds};
    my $stopped = $p{seconds} <= 0;
    while (1) {
        my $left = $stopped ? undef : int( $end - time + 0.999 );
        last if defined $left && $left <= 0;
        draw_rows( $d, $rows->($left) );
        my $wait = $stopped ? undef : $end - time - ( $left - 1 );
        my $k = read_key( $stopped ? undef : $wait > 0 ? $wait : 0.01 );
        next unless defined $k;
        $stopped = 1;
        my $act = action( $k, quit => $p{quit} );
        my @shown = $shown->();
        if ( $act eq 'quit' ) { restore_mode(); close_drawer($d); return 'quit' }
        last if $act eq 'esc';
        if    ( $act eq 'up' )   { $sel = ( $sel - 1 ) % @shown }
        elsif ( $act eq 'down' ) { $sel = ( $sel + 1 ) % @shown }
        elsif ( $act eq 'pgup' ) { $sel = $sel - $L < 0 ? 0 : $sel - $L }
        elsif ( $act eq 'pgdn' ) { $sel = $sel + $L > $#shown ? $#shown : $sel + $L }
        elsif ( $act eq 'right' || $act eq 'next' ) { $tab = ( $tab + 1 ) % ( @cats + 1 ); ( $sel, $top ) = ( 0, 0 ) }
        elsif ( $act eq 'left'  || $act eq 'prev' ) { $tab = ( $tab - 1 ) % ( @cats + 1 ); ( $sel, $top ) = ( 0, 0 ) }
        elsif ( $act =~ /^digit:(\d)$/ && $1 <= @cats + 1 ) { $tab = $1 - 1; ( $sel, $top ) = ( 0, 0 ) }
        elsif ( $act eq 'enter' && $shown[$sel]{options} ) {
            my $n = $shown[$sel];
            restore_mode();
            # The options list as a modal layered over the browser (contract
            # § Layered surfaces): on the alternate screen over the dimmed
            # browser, or centred within the browser's rows below the cursor.
            my ( $role, $how, $oi ) = ask(
                s => $s, W => $W, H => $H, form => 'modal', stage => 2,
                category => $n->{category}, notices => [$n], question => $n->{question} // '',
                buttons  => [ { label => 'Continue as planned', key => 'c', role => 'default' } ],
                options  => $n->{options}, headings => $headings, option_default => $chosen{$n} // 0,
                quit     => $p{quit}, seconds => 0,
                ( $d->{mode} eq 'alt' ? ( under => layers_of($d) ) : ( parent => $d ) ),
            );
            if ( $role eq 'quit' ) { close_drawer($d); return 'quit' }
            $chosen{$n} = $oi if defined $oi;
            raw_mode('cbreak');
            print "\e[?25l";
        }
    }
    restore_mode();
    close_drawer($d);
    return [ map { [ $_, $chosen{$_}, 'key' ] } grep { defined $chosen{$_} } @items ];
}

1;
