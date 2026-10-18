#!/usr/bin/env perl
# P5: a long list of notices (25, every category) as a navigable list: one
# row per notice, a notice selected to see its detail.
# Terminal layout only, from a fixed notice set.
#
#   perl p5-notice-browser.pl [--mode inline|fullscreen] [--style ltl|new]
#        [--rows N] [--glyphs symbol|emoji|ascii] [--bg dark|light]
#        [--width N] [--height N]
#
#   inline      a window of --rows rows (default 10) opens below the cursor
#               with a detail pane beneath it; on leaving, it collapses to
#               one row of counts by category
#   fullscreen  the alternate screen: a bar of category tabs, the list and the
#               detail side by side from 120 columns, stacked below that; on
#               leaving, the screen is given back as it was, and the row of
#               counts is printed
#
# Keys: up/down move, PgUp/PgDn page, Tab and left/right change the category
# shown (fullscreen), 1-6 jump to a category, q, Esc or Enter leave.
# Not in a terminal, the first frame is printed as plain rows.

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";
use Getopt::Long;
use NoticeProto qw(interactive terminal_size style_for display_width wrap_text
                   read_key raw_mode restore_mode categories);
use NoticeForms qw(set_glyphs glyph_of grouped notice_rows);

my %opt = ( mode => 'inline', style => 'ltl', rows => 10, glyphs => 'symbol', bg => 'dark' );
GetOptions( \%opt, 'mode=s', 'style=s', 'rows=i', 'glyphs=s', 'bg=s', 'width=i', 'height=i' )
    or die "bad options\n";
my ( $W, $H ) = terminal_size( width => $opt{width}, height => $opt{height} );
set_glyphs( $opt{glyphs} );

my $s = style_for( $opt{style}, $opt{bg} );
my $b = $s->{box};
my $sets = do "$FindBin::Bin/notices/sets.pl" or die "notices/sets.pl: $@ $!\n";

# The notices in presentation order, each with its category.
my @items;
for my $g ( grouped( $sets->{heavy} ) ) {
    my ( $cat, $in ) = @$g;
    push @items, map { { cat => $cat, n => $_ } } @$in;
}
my @cats = grep { my $c = $_; grep { $_->{cat} == $c } @items } categories();

my $live = interactive();
$opt{mode} eq 'fullscreen' ? fullscreen() : inline();

# --- shared ---------------------------------------------------------------

sub counts_row {
    # With each category's name when the row fits, its glyph and count alone
    # when it does not.
    for my $named ( 1, 0 ) {
        my $row = ' ' . $s->{bold} . scalar(@items) . ' notices about this run' . $s->{reset} . '  ';
        for my $c (@cats) {
            my $n = grep { $_->{cat} == $c } @items;
            $row .= ' ' . $s->{fg}{ $c->{name} } . glyph_of($c) . " $n" . $s->{reset}
                . ( $named ? ' ' . $s->{dim} . $c->{name} . $s->{reset} : '' ) . ' ';
        }
        return $row if !$named || display_width($row) <= $W - 1;
    }
}

# A plain string cut to $w display cells, with an ellipsis when cut.
sub fit {
    my ( $text, $w ) = @_;
    return $text if display_width($text) <= $w;
    my $out = '';
    for my $ch ( split //, $text ) {
        last if display_width( $out . $ch ) > $w - 1;
        $out .= $ch;
    }
    return $out . '…';
}

sub pad_to {
    my ( $row, $w ) = @_;
    my $pad = $w - display_width($row);
    return $row . ( ' ' x ( $pad > 0 ? $pad : 0 ) );
}

sub list_row {
    my ( $item, $selected, $w ) = @_;
    my $fg = $s->{fg}{ $item->{cat}{name} };
    my $text = fit( $item->{n}{statement}, $w - 5 );
    return $selected
        ? " $fg▶$s->{reset} $fg" . glyph_of( $item->{cat} ) . "$s->{reset} \e[7m" . pad_to( $text, $w - 5 ) . "\e[27m$s->{reset}"
        : "   $fg" . glyph_of( $item->{cat} ) . "$s->{reset} $s->{text}$text$s->{reset}";
}

sub detail_rows {
    my ( $item, $w ) = @_;
    my $fg = $s->{fg}{ $item->{cat}{name} };
    my $name = $s->{name} eq 'ltl' ? uc $item->{cat}{name} : ucfirst $item->{cat}{name};
    my @rows = ( " $s->{bold}$fg" . glyph_of( $item->{cat} ) . " $name$s->{reset}" );
    push @rows, " $s->{dim}$_$s->{reset}" for wrap_text( $item->{cat}{reads}, $w - 1 );
    push @rows, notice_rows( $item->{n}, $s, $fg, $w - 1, ' ', ' ', ' ' );
    push @rows, " $s->{dim}from $item->{n}{producer}$s->{reset}";
    return @rows;
}

sub step {
    my ( $k, $sel, $n, $page ) = @_;
    return ( $sel - 1 ) % $n if $k eq 'up';
    return ( $sel + 1 ) % $n if $k eq 'down';
    return $sel - $page < 0 ? 0 : $sel - $page if $k eq 'pgup';
    return $sel + $page > $n - 1 ? $n - 1 : $sel + $page if $k eq 'pgdn';
    return undef;
}

# --- inline -----------------------------------------------------------------

sub inline {
    my $L = $opt{rows};
    my $D = 6;
    my ( $sel, $top ) = ( 0, 0 );
    my $frame = sub {
        $top = $sel if $sel < $top;
        $top = $sel - $L + 1 if $sel >= $top + $L;
        my @rows = ( counts_row(), ' ' . $s->{frame} . ( $b->{h_line} x ( $W - 2 ) ) . $s->{reset} );
        for my $i ( $top .. $top + $L - 1 ) {
            push @rows, $i <= $#items ? list_row( $items[$i], $i == $sel, $W - 1 ) : '';
        }
        my $more = sprintf '%d-%d of %d', $top + 1, ( $top + $L > @items ? scalar @items : $top + $L ), scalar @items;
        push @rows, ' ' . $s->{frame} . ( $b->{h_line} x ( $W - 4 - length $more ) ) . $s->{reset} . " $s->{dim}$more$s->{reset}";
        my @d = detail_rows( $items[$sel], $W - 1 );
        push @rows, map { $_ // '' } @d[ 0 .. $D - 1 ];
        push @rows, " $s->{dim}↑↓ move · PgUp/PgDn page · 1-" . scalar(@cats) . " jump to a category · q, Esc or Enter done$s->{reset}";
        return @rows;
    };
    print "\n";
    my @rows = $frame->();
    print "\e[2K$_\n" for @rows;
    unless ($live) { print "\n"; return }
    raw_mode('cbreak');
    print "\e[?25l";
    while (1) {
        my $k = read_key();
        next unless defined $k;
        last if $k eq 'q' || $k eq 'esc' || $k eq 'enter';
        my $next = step( $k, $sel, scalar @items, $L );
        if ( !defined $next && $k =~ /^[1-9]$/ && $k <= @cats ) {
            my $c = $cats[ $k - 1 ];
            ($next) = grep { $items[$_]{cat} == $c } 0 .. $#items;
        }
        next unless defined $next;
        $sel = $next;
        printf "\e[%dA\r", scalar @rows;
        @rows = $frame->();
        print "\e[2K$_\n" for @rows;
    }
    restore_mode();
    # Collapse to the row of counts.
    printf "\e[%dA\r\e[J", scalar @rows;
    print counts_row(), "\n\n";
}

# --- fullscreen ---------------------------------------------------------------

sub fullscreen {
    my ( $sel, $top, $tab ) = ( 0, 0, 0 );    # tab 0 = all categories
    my $frame = sub {
        my @shown = $tab ? grep { $_->{cat} == $cats[ $tab - 1 ] } @items : @items;
        $sel = $#shown if $sel > $#shown;
        my $side = $W >= 120;
        my $listw = $side ? int( $W * 0.45 ) : $W;
        my $body = $H - 4;
        my $L = $side ? $body : int( $body / 2 );
        $top = $sel if $sel < $top;
        $top = $sel - $L + 1 if $sel >= $top + $L;
        my @rows;
        my $titlebar = ' Notices about this run · ' . scalar(@items) . ' ';
        push @rows, "\e[7m" . $s->{bold} . pad_to( $titlebar, $W - 1 ) . $s->{reset};
        my $tabs;
        for my $named ( 1, 0 ) {
            $tabs = ' ' . ( $tab == 0 ? "\e[7m All \e[27m" : ' All ' );
            for my $i ( 0 .. $#cats ) {
                my $c = $cats[$i];
                my $n = grep { $_->{cat} == $c } @items;
                my $label = ' ' . glyph_of($c) . ( $named ? ' ' . ucfirst( $c->{name} ) : '' ) . " $n ";
                $tabs .= ' ' . $s->{fg}{ $c->{name} } . ( $tab == $i + 1 ? "\e[7m$label\e[27m" : $label ) . $s->{reset};
            }
            last if display_width($tabs) <= $W - 1;
        }
        push @rows, $tabs;
        my @list = map { $_ <= $#shown ? list_row( $shown[$_], $_ == $sel, $listw - 1 ) : '' } $top .. $top + $L - 1;
        my @detail = detail_rows( $shown[$sel], $side ? $W - $listw - 2 : $W - 1 );
        if ($side) {
            for my $i ( 0 .. $body - 1 ) {
                push @rows, pad_to( $list[$i] // '', $listw ) . $s->{frame} . $b->{v_line} . $s->{reset} . ( $detail[$i] // '' );
            }
        }
        else {
            push @rows, @list;
            push @rows, ' ' . $s->{frame} . ( $b->{h_line} x ( $W - 2 ) ) . $s->{reset};
            push @rows, map { $detail[$_] // '' } 0 .. $body - $L - 2;
        }
        push @rows, "\e[7m" . pad_to( fit( ' ↑↓ move · PgUp/PgDn page · Tab ←→ category · 1-' . scalar(@cats) . ' jump · q, Esc or Enter back to the run', $W - 1 ), $W - 1 ) . "\e[27m$s->{reset}";
        return @rows;
    };
    unless ($live) {
        print "$_\n" for $frame->();
        print "\n", counts_row(), "\n";
        return;
    }
    print "\e[?1049h\e[?25l";
    raw_mode('cbreak');
    my $draw = sub { print "\e[H"; my @r = $frame->(); print "\e[2K$r[$_]" . ( $_ < $#r ? "\r\n" : '' ) for 0 .. $#r };
    $draw->();
    while (1) {
        my $k = read_key();
        next unless defined $k;
        last if $k eq 'q' || $k eq 'esc' || $k eq 'enter';
        my $n = $tab ? scalar( grep { $_->{cat} == $cats[ $tab - 1 ] } @items ) : scalar @items;
        if    ( $k eq 'tab' || $k eq 'right' ) { $tab = ( $tab + 1 ) % ( @cats + 1 ); ( $sel, $top ) = ( 0, 0 ) }
        elsif ( $k eq 'left' )                 { $tab = ( $tab - 1 ) % ( @cats + 1 ); ( $sel, $top ) = ( 0, 0 ) }
        elsif ( $k =~ /^[1-9]$/ && $k <= @cats ) { $tab = $k; ( $sel, $top ) = ( 0, 0 ) }
        else {
            my $next = step( $k, $sel, $n, $H - 6 );
            next unless defined $next;
            $sel = $next;
        }
        $draw->();
    }
    restore_mode();
    print "\e[?1049l";
    print counts_row(), "\n\n";
}
