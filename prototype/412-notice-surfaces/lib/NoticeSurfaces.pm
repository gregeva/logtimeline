package NoticeSurfaces;

# The standard surface patterns of stage 1's second round. One way to present
# a block of notices (the panel), three ways to ask (a row, a box, a modal),
# a view selector that runs inside whichever surface asked, and a navigable
# list of notices in a box. Every moment of the run calls these; no moment has
# a presentation of its own.
#
# Rules every pattern keeps, from the architect's first-round feedback:
#   - a notice is one row; its parts are told apart by colour and by the
#     separators (· before the evidence, → before the remedy), never by a
#     row break; it wraps only past the width;
#   - a category's name is shown once, upper case, with how to read it;
#   - a surface that asks erases itself once answered; what it showed and
#     the answer are carried to the panel at the end of the run;
#   - any key that is not a choice stops a countdown;
#   - j and k move wherever the arrow keys do.

use strict;
use warnings;
use utf8;
use Exporter 'import';
use List::Util qw(max);
use Time::HiRes qw(time);
use NoticeProto qw(interactive display_width strip_sgr categories read_key raw_mode restore_mode answer_ahead);

our @EXPORT_OK = qw(cat_named grouped fit pad_to notice_line heading frame panel
                    out live_row ask browser);

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

# A notice as one row where it fits: its focus in bold (what it is about), the
# statement, the evidence dim after a dot, the remedy after an arrow in the
# category's colour. Past $width it wraps by words, the rows after the first
# indented by $indent cells. A record (the answer given at a choice) is one
# dim row after a hooked arrow.
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

# A category's label: its glyph and upper-case name, in its colour; in the
# new style set as a coloured block.
sub label {
    my ( $cat, $s ) = @_;
    my $fg = $s->{fg}{ $cat->{name} };
    my $text = "$cat->{glyph} " . uc $cat->{name};
    return $s->{name} eq 'new' ? "$fg\e[7m\e[1m $text \e[0m" : "$fg$text$s->{reset}";
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
# $a{foot} in the bottom edge, each row padded to the inside width, a row
# 'RULE' drawn as a divider across the box.
sub frame {
    my (%a) = @_;
    my $s = $a{s};
    my $b = $s->{box};
    my $e = $a{edge} // $s->{frame};
    my $w = $a{width};
    my $edge = sub {
        my ( $l, $text, $r ) = @_;
        $text //= '';
        my $fill = $w - 3 - display_width($text);
        return $e . $l . $b->{h_line} . $s->{reset} . $text . $e . ( $b->{h_line} x ( $fill > 0 ? $fill : 0 ) ) . $r . $s->{reset};
    };
    my @out = ( $edge->( $b->{corner_tl}, $a{title}, $b->{corner_tr} ) );
    for my $r ( @{ $a{rows} } ) {
        if ( $r eq 'RULE' ) {
            push @out, $e . $b->{t_right} . ( $b->{h_line} x ( $w - 2 ) ) . $b->{t_left} . $s->{reset};
            next;
        }
        push @out, $e . $b->{v_line} . $s->{reset} . ' ' . pad_to( $r, $w - 4 ) . ' ' . $e . $b->{v_line} . $s->{reset};
    }
    push @out, $edge->( $b->{corner_bl}, $a{foot}, $b->{corner_br} );
    return @out;
}

# A notice's rows inside a list: a bullet in the category's colour, or the
# hooked arrow alone for a record.
sub bulleted {
    my ( $n, $s, $fg, $width ) = @_;
    my @r = notice_line( $n, $s, $fg, $width - 2, 0 );
    my $first = shift @r;
    return ( ( $n->{record} ? '  ' : "$fg•$s->{reset} " ) . $first, map { "  $_" } @r );
}

# --- the panel: the notices of the run, presented together ------------------
#
# One notice is one row, no frame. More than one is one box round them all:
# each category headed once, its notices one row each, the categories divided
# by a rule ($o{divide} 'rule') or a blank row ('blank'). Records do not count
# as notices.

sub panel {
    my ( $list, $s, $W, %o ) = @_;
    my $divide = $o{divide} // 'rule';
    my @notices = grep { !$_->{record} } @$list;
    my @groups = grouped($list);
    if ( @notices == 1 ) {
        my ($cat) = @{ $groups[0] };
        my $fg = $s->{fg}{ $cat->{name} };
        my $lead = label( $cat, $s ) . ' ';
        my @rows;
        for my $n ( @{ $groups[0][1] } ) {
            my $lw = display_width($lead);
            my @r = notice_line( $n, $s, $fg, $W - 1 - $lw, 2 - $lw );
            push @rows, ( $n->{record} ? '  ' : $lead ) . shift(@r), map { "  $_" } @r;
        }
        return @rows;
    }
    my $iw = $W - 5;
    my @rows;
    for my $gi ( 0 .. $#groups ) {
        my ( $cat, $in ) = @{ $groups[$gi] };
        my $fg = $s->{fg}{ $cat->{name} };
        push @rows, $divide eq 'blank' ? '' : 'RULE' if $gi;
        push @rows, heading( $cat, $s, scalar( grep { !$_->{record} } @$in ), $iw );
        push @rows, bulleted( $_, $s, $fg, $iw ) for @$in;
    }
    my $title = " $s->{pick}NOTICES$s->{reset} $s->{dim}· " . scalar(@notices) . " about this run$s->{reset} ";
    return frame( s => $s, width => $W - 1, title => $title, rows => \@rows );
}

# --- what the run has printed --------------------------------------------------
#
# The rows a prototype prints, kept so that a surface on the alternate screen
# can draw itself over a dimmed copy of them: the analyst sees the run behind
# the question, as a window over it.

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

# --- where a surface that asks is drawn ----------------------------------------
#
# inline: from the cursor's row down, redrawn in place, erased on leaving with
#         the cursor back on the row it started on.
# alt:    centred on the alternate screen over the dimmed rows the run had
#         printed; on leaving the screen is given back as it was.
# plain:  not in a terminal; drawn once, as it would first appear.

sub drawer {
    my ( $mode, $W, $H ) = @_;
    return { mode => interactive() ? $mode : 'plain', W => $W, H => $H, h => 0 };
}

sub draw_rows {
    my ( $d, @rows ) = @_;
    if ( $d->{mode} eq 'plain' ) {
        return if $d->{h}++;
        print "\r\e[2K";
        print "$_\n" for @rows;
        return;
    }
    if ( $d->{mode} eq 'alt' ) {
        print "\e[?1049h" unless $d->{on}++;
        my ( $W, $H ) = @$d{qw(W H)};
        my @bd = ( @printed, $live );
        @bd = @bd[ -$H .. -1 ] if @bd > $H;
        unshift @bd, ('') x ( $H - @bd );
        print "\e[" . ( $_ + 1 ) . ";1H\e[2K\e[2m" . strip_sgr( $bd[$_] ) . "\e[0m" for 0 .. $H - 1;
        my $bw  = max map { display_width($_) } @rows;
        my $top = int( ( $H - @rows ) / 2 ) + 1;
        my $col = int( ( $W - $bw ) / 2 ) + 1;
        print "\e[" . ( $top + $_ ) . ";${col}H$rows[$_]" for 0 .. $#rows;
        return;
    }
    print "\e[" . ( $d->{h} - 1 ) . "A" if $d->{h} > 1;
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
        print "\e[" . ( $d->{h} - 1 ) . "A" if $d->{h} > 1;
        print "\r\e[J";
    }
    $d->{h} = 0;
    return;
}

# --- waiting for the analyst -------------------------------------------------

# A choice with a countdown to its default. $draw->($left) paints the surface
# with the seconds left, undef once paused; $key->($k) returns the choice for
# a key that chooses and undef for any other, which stops the countdown so the
# analyst has the time to read.
sub wait_choice {
    my (%a) = @_;
    my $end = time + $a{seconds};
    my $paused = 0;
    raw_mode('cbreak');
    print "\e[?25l";
    my ( $v, $how );
    while (1) {
        my $left = $paused ? undef : int( $end - time + 0.999 );
        if ( defined $left && $left <= 0 ) { ( $v, $how ) = ( $a{default}, "default after $a{seconds}s" ); last }
        $a{draw}->($left);
        my $wait = $paused ? undef : $end - time - ( $left - 1 );
        my $k = read_key( $paused ? undef : $wait > 0 ? $wait : 0.01 );
        next unless defined $k;
        my $c = $a{key}->($k);
        if ( defined $c ) { ( $v, $how ) = ( $c, 'key' ); last }
        $paused = 1;
    }
    restore_mode();
    return ( $v, $how );
}

# A selection among $n with no countdown: the analyst chose to look.
sub wait_select {
    my ( $draw, $n, $default, $start ) = @_;
    my $sel = $start // 0;
    raw_mode('cbreak');
    print "\e[?25l";
    my @r;
    while (1) {
        $draw->($sel);
        my $k = read_key();
        next unless defined $k;
        if    ( $k eq 'up' || $k eq 'k' )   { $sel = ( $sel - 1 ) % $n }
        elsif ( $k eq 'down' || $k eq 'j' ) { $sel = ( $sel + 1 ) % $n }
        elsif ( $k =~ /^[1-9]$/ && $k <= $n ) { $sel = $k - 1 }
        elsif ( $k eq 'enter' ) { @r = ( $sel, 'key' ); last }
        elsif ( $k eq 'esc' || $k eq 'q' ) { @r = ( $default, 'Esc' ); last }
    }
    restore_mode();
    return @r;
}

sub countdown {
    my ( $s, $left ) = @_;
    return $s->{dim} . ( defined $left ? "(${left}s)" : '(paused)' ) . $s->{reset};
}

# The views on offer as a vertical list: the highlighted one in reverse video,
# its effect on the row beneath.
sub selector_rows {
    my ( $views, $sel, $s, $fg, $iw ) = @_;
    my $lw = max map { display_width( $_->{label} ) } @$views;
    my @rows;
    for my $i ( 0 .. $#$views ) {
        my $v = $views->[$i];
        my $text = ( $i + 1 ) . '  ' . $v->{label} . ( ' ' x ( $lw - display_width( $v->{label} ) ) ) . '  ' . $v->{args};
        push @rows, $i == $sel
            ? "$fg▶$s->{reset} $s->{pick}\e[7m $text \e[0m"
            : "   $s->{text}$text$s->{reset}";
    }
    push @rows, "    $s->{dim}" . fit( $views->[$sel]{effect}, $iw - 4 ) . $s->{reset};
    return @rows;
}

sub keys_foot {
    my ( $s, $text ) = @_;
    return " $s->{dim}$text$s->{reset} ";
}

# --- asking ----------------------------------------------------------------
#
#   ask( s, W, H, surface => row|box|modal, screen => inline|alt,
#        category, notices => [...], question, buttons => [yes, no],
#        default => 0|1, seconds, views => [...], view_default )
#
# The first button is the yes; when views are given, it leads to them, in the
# same surface, which grows to hold the list. Returns (button, how, view,
# view how), the view undefined when none was looked at.

sub ask {
    my (%a) = @_;
    my $s   = $a{s};
    my $cat = cat_named( $a{category} );
    my $fg  = $s->{fg}{ $a{category} };
    my $W   = $a{W};

    if ( defined( my $given = answer_ahead() ) ) {
        my $b = $given eq 'default' ? $a{default} : $given =~ /^n/i ? 1 : 0;
        my $v;
        if ( $b == 0 && $a{views} ) {
            my $g = answer_ahead();
            $v = defined $g && $g =~ /^\d+$/ && $g >= 1 && $g <= @{ $a{views} } ? $g - 1 : $a{view_default};
        }
        return ( $b, 'given ahead', $v, 'given ahead' );
    }

    my $surface = $a{surface};
    my $d = drawer( $surface eq 'modal' ? $a{screen} : 'inline', $W, $a{H} );
    my $yn = $a{default} == 0 ? '[Y/n]' : '[y/N]';
    my $focus = $a{default};
    my $multi = @{ $a{notices} } > 1;
    my $edge  = $s->{name} eq 'new' ? $fg : $s->{frame};
    my $title = ' ' . label( $cat, $s ) . ' ' . ( $multi ? $s->{dim} . scalar( @{ $a{notices} } ) . ' ' . $s->{reset} : '' );
    my $mw = $W - 4 < 100 ? $W - 4 : 100;
    my $mcol = ' ' x ( $surface eq 'modal' && $d->{mode} eq 'inline' ? int( ( $W - $mw ) / 2 ) : 0 );

    # The surface's rows: stage 1 with the seconds left; stage 2 with the
    # view highlighted.
    my $rows = sub {
        my ( $stage, $x ) = @_;
        my $q = "$s->{text}$a{question}$s->{reset}";
        if ( $surface eq 'row' ) {
            my @r = $multi ? map { bulleted( $_, $s, $s->{fg}{ $_->{category} }, $W - 1 ) } @{ $a{notices} } : ();
            my $lead = "$fg$cat->{glyph}$s->{reset} ";
            if ( $stage == 2 ) {
                my $row = $lead . join( '  ', map { "$s->{pick}" . ( $_ + 1 ) . "$s->{reset} $s->{text}" . lc( $a{views}[$_]{label} ) . $s->{reset} } 0 .. $#{ $a{views} } )
                    . "  $s->{dim}1-" . scalar( @{ $a{views} } ) . ', Enter: ' . ( $a{view_default} + 1 ) . $s->{reset};
                return ( @r, fit( $row, $W - 1 ) );
            }
            my $ask = "  $q $s->{pick}$yn$s->{reset} " . countdown( $s, $x );
            my $room = $W - 1 - display_width($lead) - display_width($ask);
            my $text = $multi ? '' : fit( join( ' ', notice_line( $a{notices}[0], $s, $fg, 10_000 ) ), $room );
            return ( @r, $lead . $text . ( $multi ? substr( $ask, 2 ) : $ask ) );
        }
        my $iw = ( $surface eq 'modal' ? $mw : $W - 1 ) - 4;
        my @body = map { $multi ? bulleted( $_, $s, $s->{fg}{ $_->{category} }, $iw ) : notice_line( $_, $s, $fg, $iw, 2 ) } @{ $a{notices} };
        my ( @tail, $foot );
        if ( $stage == 2 ) {
            @tail = ( 'RULE', "$s->{pick}Choose a view$s->{reset}", selector_rows( $a{views}, $x, $s, $fg, $iw ) );
            $foot = keys_foot( $s, '↑↓ j k move · 1-' . scalar( @{ $a{views} } ) . ' · Enter choose · Esc continue as planned' );
        }
        elsif ( $surface eq 'box' ) {
            @tail = ( "$q $s->{pick}$yn$s->{reset} " . countdown( $s, $x ) );
            $foot = keys_foot( $s, 'y/n · Enter: ' . lc( $a{buttons}[ $a{default} ] ) . ' · any other key pauses' );
        }
        else {
            my @btn;
            for my $i ( 0, 1 ) {
                my $l = $a{buttons}[$i] . ( $i == $a{default} ? ' ' . countdown( $s, $x ) : '' );
                push @btn, $i == $focus ? "$fg\e[7m\e[1m  " . strip_sgr($l) . "  \e[0m" : $s->{text} . "[ $l" . $s->{text} . " ]" . $s->{reset};
            }
            my $brow = join '    ', @btn;
            my $widest = display_width($brow) + ( defined $x ? length( $a{seconds} ) - length($x) : length( $a{seconds} ) + 1 - length('paused') );
            @tail = ( '', ( ' ' x int( ( $iw - display_width( strip_sgr($q) ) ) / 2 ) ) . $q,
                ( ' ' x int( ( $iw - $widest ) / 2 ) ) . $brow );
            $foot = keys_foot( $s, '←→ Tab move · Enter choose · y/n · any other key pauses' );
        }
        my @f = frame( s => $s, edge => $edge, width => $iw + 4, title => $title, foot => $foot,
            rows => [ ( $surface eq 'modal' ? '' : () ), @body, @tail, ( $surface eq 'modal' ? '' : () ) ] );
        return map { $mcol . $_ } @f;
    };

    my ( $b, $how );
    if ( $d->{mode} eq 'plain' ) {
        draw_rows( $d, $rows->( 1, $a{seconds} ) );
        ( $b, $how ) = ( $a{default}, 'default, no terminal' );
    }
    else {
        ( $b, $how ) = wait_choice(
            seconds => $a{seconds},
            default => $a{default},
            draw    => sub { draw_rows( $d, $rows->( 1, $_[0] ) ) },
            key     => sub {
                my ($k) = @_;
                return 0 if lc $k eq 'y';
                return 1 if lc $k eq 'n';
                if ( $surface eq 'modal' ) {
                    return $focus if $k eq 'enter';
                    $focus = 1 - $focus if $k =~ /^(left|right|tab|h|l)$/;
                    return undef;
                }
                return $a{default} if $k eq 'enter';
                return undef;
            },
        );
    }
    my ( $v, $vhow );
    if ( $b == 0 && $a{views} && $d->{mode} ne 'plain' ) {
        if ( $surface eq 'row' ) {
            draw_rows( $d, $rows->(2) );
            raw_mode('cbreak');
            while (1) {
                my $k = read_key();
                next unless defined $k;
                if ( $k =~ /^[1-9]$/ && $k <= @{ $a{views} } ) { ( $v, $vhow ) = ( $k - 1, 'key' ); last }
                if ( $k eq 'enter' || $k eq 'esc' ) { ( $v, $vhow ) = ( $a{view_default}, $k eq 'esc' ? 'Esc' : 'Enter' ); last }
            }
            restore_mode();
        }
        else {
            ( $v, $vhow ) = wait_select( sub { draw_rows( $d, $rows->( 2, $_[0] ) ) }, scalar @{ $a{views} }, $a{view_default} );
        }
    }
    close_drawer($d) unless $d->{mode} eq 'plain';
    return ( $b, $how, $v, $vhow );
}

# --- the notice browser: many notices, navigable, in a box ---------------------
#
#   browser( s, W, H, screen => alt|inline, notices => [...], rows => N )
#
# Tabs across the top filter by category (All first); the list below, one row
# per notice; the selected notice's detail beneath. A notice offering views
# opens the selector in the detail's place, and the list comes back once one
# is chosen. Closing erases the box. Returns the views chosen, as
# [notice, view index, how].

sub browser {
    my (%a) = @_;
    my $s = $a{s};
    my ( $W, $H ) = @a{qw(W H)};
    my $d = drawer( $a{screen}, $W, $H );
    my $bw = $d->{mode} eq 'alt' ? $W - 4 : $W - 1;
    my $iw = $bw - 4;
    my @items = map { @{ $_->[1] } } grouped( $a{notices} );
    my @cats = map { $_->[0] } grouped( \@items );
    my $D = 4;
    # The same height in both modes, and whichever tab is shown: a window over
    # the run, never the whole screen.
    my $L = $a{rows} // 10;
    $L = $H - 14 if $L > $H - 14;
    my ( $tab, $sel, $top, $choosing, $vsel ) = ( 0, 0, 0, 0, 0 );
    my %chosen;

    my $shown = sub { $tab ? grep { $_->{category} eq $cats[ $tab - 1 ]{name} } @items : @items };
    my $rows = sub {
        my @shown = $shown->();
        $sel = $#shown if $sel > $#shown;
        $top = $sel if $sel < $top;
        $top = $sel - $L + 1 if $sel >= $top + $L;
        # Every tab by its glyph and count, the one shown by its name too.
        my $tabs = ( $tab == 0 ? "$s->{pick}\e[7m All " . @items . " \e[0m" : "$s->{text} All " . @items . " $s->{reset}" );
        for my $i ( 0 .. $#cats ) {
            my $c  = $cats[$i];
            my $n  = grep { $_->{category} eq $c->{name} } @items;
            my $fg = $s->{fg}{ $c->{name} };
            $tabs .= ' ' . ( $tab == $i + 1 ? "$fg\e[7m\e[1m $c->{glyph} " . uc( $c->{name} ) . " $n \e[0m" : "$fg $c->{glyph} $n $s->{reset}" );
        }
        my @r = ( $tabs, 'RULE' );
        for my $i ( $top .. $top + $L - 1 ) {
            if ( $i > $#shown ) { push @r, ''; next }
            my $n  = $shown[$i];
            my $fg = $s->{fg}{ $n->{category} };
            my $c  = cat_named( $n->{category} );
            my $mark = $n->{views} ? ( defined $chosen{$n} ? "$fg◆$s->{reset}" : "$fg◇$s->{reset}" ) : ' ';
            my $text = fit( join( ' ', notice_line( $n, $s, $fg, 10_000 ) ), $iw - 6 );
            push @r, $i == $sel
                ? "$fg▶$s->{reset} $fg$c->{glyph}$s->{reset} \e[7m" . pad_to( strip_sgr($text), $iw - 6 ) . "\e[0m $mark"
                : "  $fg$c->{glyph}$s->{reset} " . pad_to( $text, $iw - 6 ) . " $mark";
        }
        push @r, 'RULE';
        my $n  = $shown[$sel];
        my $fg = $s->{fg}{ $n->{category} };
        my $c  = cat_named( $n->{category} );
        my @detail;
        if ($choosing) {
            @detail = ( "$s->{pick}Choose a view$s->{reset}", selector_rows( $n->{views}, $vsel, $s, $fg, $iw ) );
        }
        else {
            @detail = ( heading( $c, $s, undef, $iw ), notice_line( $n, $s, $fg, $iw, 2 ) );
            push @detail, $n->{views}
                ? ( defined $chosen{$n}
                    ? "$s->{dim}view chosen:$s->{reset} $s->{pick}" . $n->{views}[ $chosen{$n} ]{label} . "$s->{reset} $fg$n->{views}[ $chosen{$n} ]{args}$s->{reset}"
                    : "$fg◇$s->{reset} $s->{dim}" . scalar( @{ $n->{views} } ) . " views on offer: Enter to choose$s->{reset}" )
                : ();
        }
        my $DD = $choosing ? @{ $n->{views} } + 2 : $D;
        push @r, map { $detail[$_] // '' } 0 .. ( $DD > @detail ? $DD : scalar @detail ) - 1;
        my $foot = $choosing
            ? keys_foot( $s, '↑↓ j k move · Enter choose · Esc back to the list' )
            : keys_foot( $s, '↑↓ j k move · ←→ h l Tab category · 1-' . ( @cats + 1 ) . ' tab · Enter views · q close' );
        my $more = ' ' . ( @shown ? $top + 1 : 0 ) . '-' . ( $top + $L > @shown ? scalar @shown : $top + $L ) . ' of ' . @shown . ' ';
        return frame( s => $s, width => $bw, rows => \@r, foot => $foot,
            title => " $s->{pick}NOTICES$s->{reset} $s->{dim}· " . @items . " about this run ·$more$s->{reset}" );
    };

    if ( $d->{mode} eq 'plain' ) {
        draw_rows( $d, $rows->() );
        return [];
    }
    raw_mode('cbreak');
    print "\e[?25l";
    while (1) {
        draw_rows( $d, $rows->() );
        my $k = read_key();
        next unless defined $k;
        my @shown = $shown->();
        if ($choosing) {
            my $n = $shown[$sel];
            my $nv = @{ $n->{views} };
            if    ( $k eq 'up' || $k eq 'k' )   { $vsel = ( $vsel - 1 ) % $nv }
            elsif ( $k eq 'down' || $k eq 'j' ) { $vsel = ( $vsel + 1 ) % $nv }
            elsif ( $k =~ /^[1-9]$/ && $k <= $nv ) { $vsel = $k - 1 }
            elsif ( $k eq 'enter' ) { $chosen{$n} = $vsel; $choosing = 0 }
            elsif ( $k eq 'esc' || $k eq 'q' ) { $choosing = 0 }
            next;
        }
        last if $k eq 'q' || $k eq 'esc';
        if    ( $k eq 'up' || $k eq 'k' )   { $sel = ( $sel - 1 ) % @shown }
        elsif ( $k eq 'down' || $k eq 'j' ) { $sel = ( $sel + 1 ) % @shown }
        elsif ( $k eq 'pgup' ) { $sel = $sel - $L < 0 ? 0 : $sel - $L }
        elsif ( $k eq 'pgdn' ) { $sel = $sel + $L > $#shown ? $#shown : $sel + $L }
        elsif ( $k eq 'right' || $k eq 'l' || $k eq 'tab' ) { $tab = ( $tab + 1 ) % ( @cats + 1 ); ( $sel, $top ) = ( 0, 0 ) }
        elsif ( $k eq 'left' || $k eq 'h' ) { $tab = ( $tab - 1 ) % ( @cats + 1 ); ( $sel, $top ) = ( 0, 0 ) }
        elsif ( $k =~ /^[1-9]$/ && $k <= @cats + 1 ) { $tab = $k - 1; ( $sel, $top ) = ( 0, 0 ) }
        elsif ( $k eq 'enter' && $shown[$sel]{views} ) { $choosing = 1; $vsel = $chosen{ $shown[$sel] } // 0 }
    }
    restore_mode();
    close_drawer($d);
    return [ map { [ $_, $chosen{$_}, 'key' ] } grep { defined $chosen{$_} } @items ];
}

1;
