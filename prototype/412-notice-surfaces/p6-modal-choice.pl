#!/usr/bin/env perl
# P6: a choice presented as a modal dialog: a framed box holding the notice,
# two buttons and a countdown to the default, which holds the run until it is
# answered. Shown at either moment a choice arises.
# Terminal layout only, from fixed content.
#
#   perl p6-modal-choice.pl [--moment read|after] [--screen inline|alt]
#        [--style ltl|new] [--seconds N] [--answer y|n|default]
#        [--glyphs symbol|emoji|ascii] [--bg dark|light] [--width N] [--height N]
#
#   --moment read   memory use growing high while the progress line runs
#   --moment after  a pattern detected once the statistics are computed
#   --screen inline the dialog is drawn in the rows below the cursor, and once
#                   answered gives them back to one row recording the answer
#   --screen alt    the dialog is drawn centred on the alternate screen, and
#                   the screen is given back as it was once it is answered
#
# Keys: left/right or Tab move between the buttons, Enter presses the one
# focused, y and n press them directly.

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";
use Getopt::Long;
use Time::HiRes qw(sleep time);
use NoticeProto qw(interactive terminal_size style_for display_width wrap_text
                   set_answers_ahead answer_ahead read_key raw_mode restore_mode categories);
use NoticeForms qw(set_glyphs glyph_of);

my %opt = ( moment => 'read', screen => 'inline', style => 'ltl', seconds => 10, glyphs => 'symbol', bg => 'dark' );
GetOptions( \%opt, 'moment=s', 'screen=s', 'style=s', 'seconds=i', 'answer=s', 'glyphs=s', 'bg=s', 'width=i', 'height=i' )
    or die "bad options\n";
my ( $W, $H ) = terminal_size( width => $opt{width}, height => $opt{height} );
set_glyphs( $opt{glyphs} );
set_answers_ahead( $opt{answer} );

my $s = style_for( $opt{style}, $opt{bg} );
my $b = $s->{box};
my $green = "\e[92m";
my $live = interactive();

my %dialog = (
    read => {
        category  => 'runtime condition',
        title     => 'Memory use is growing',
        statement => 'Memory use has reached 3.2 GB and is still growing. At this rate the read needs about 7.9 GB, more than half of the 12.8 GB of physical memory.',
        evidence  => '40% of the input read',
        hint      => 'Stopping keeps the figures for the lines read so far; -st/-et or -g narrow the next run.',
        buttons   => [ 'Continue reading', 'Stop here' ],
        default   => 0,
    },
    after => {
        category  => 'guidance',
        title     => 'A pattern was found',
        statement => 'POST .../QueryStreamEntriesWithData has two populations of durations (bimodality coefficient 0.71): about 1 s and about 5.5 s.',
        evidence  => '36 requests, 18 in each population',
        hint      => 'Two views might change what this run shows: sorting by bimodality, or isolating this API with its histogram.',
        buttons   => [ 'Look at the views', 'Continue as planned' ],
        default   => 1,
    },
);
my $d = $dialog{ $opt{moment} } or die "no moment '$opt{moment}'\n";
my ($cat) = grep { $_->{name} eq $d->{category} } categories();
my $fg = $s->{fg}{ $d->{category} };

print "\n";
if ( $opt{moment} eq 'read' ) {
    progress($_) for 1 .. 40;
    print "\r\e[2K";
    my ( $i, $how ) = modal();
    if ( $i == 1 ) {
        print "\e[93mProcessing stopped at 40%.\e[0m\n\n $s->{dim}(the figures would cover the lines read so far)$s->{reset}\n\n";
        exit 0;
    }
    progress($_) for 41 .. 100;
    print "\r$green", 'Processing completed.', "\e[0m", ' ' x ( $W - 21 ), "\n";
    print "$green", 'Calculating statistics completed.', "\e[0m\n\n $s->{dim}(the timeline would follow)$s->{reset}\n\n";
}
else {
    print "$green", 'Processing completed.', "\e[0m\n";
    print "$green", 'Calculating statistics completed.', "\e[0m\n";
    my ($i) = modal();
    print "\n $s->{dim}("
        . ( $i == 0 ? 'stage two, the views on offer, would follow' : 'the charts would follow, as planned' )
        . ")$s->{reset}\n\n";
}

sub progress {
    my ($pct) = @_;
    my $text = "Processing $pct% line " . int( 14306.78 * $pct ) . ", 856.2k lines/sec: access_log.2025-05-05.txt";
    print "\r$text", ' ' x ( $W - 1 - length $text );
    sleep 0.02 if $live;
}

# --- the dialog ---------------------------------------------------------------

# The dialog's rows, each exactly $bw cells wide.
sub dialog_rows {
    my ( $focus, $left ) = @_;
    my $bw = $W - 4 < 72 ? $W - 4 : 72;
    my $iw = $bw - 4;
    my $edge = $s->{name} eq 'ltl' ? $s->{frame} : $fg;
    my $tl = $s->{name} eq 'new' ? '╭' : $b->{corner_tl};
    my $tr = $s->{name} eq 'new' ? '╮' : $b->{corner_tr};
    my $bl = $s->{name} eq 'new' ? '╰' : $b->{corner_bl};
    my $br = $s->{name} eq 'new' ? '╯' : $b->{corner_br};
    my $head = ' ' . glyph_of($cat) . ' ' . $d->{title} . ' ';
    my $fill = $bw - 3 - display_width($head);
    my @rows = ( $edge . $tl . $b->{h_line} . $s->{reset} . $s->{bold} . $fg . $head . $s->{reset}
        . $edge . ( $b->{h_line} x $fill ) . $tr . $s->{reset} );
    my $line = sub {
        my ( $text, $colour ) = @_;
        my $pad = $iw - display_width($text);
        push @rows, $edge . $b->{v_line} . $s->{reset} . ' ' . ( $colour // $s->{text} ) . $text . $s->{reset}
            . ( ' ' x ( $pad > 0 ? $pad : 0 ) ) . ' ' . $edge . $b->{v_line} . $s->{reset};
    };
    $line->('');
    $line->($_) for wrap_text( $d->{statement}, $iw );
    $line->( $_, $s->{dim} ) for wrap_text( $d->{evidence}, $iw );
    $line->('');
    $line->( $_, $fg ) for wrap_text( $d->{hint}, $iw );
    $line->('');
    # The buttons, centred; the focused one in reverse video, the default
    # marked with the seconds left.
    my @btn;
    for my $i ( 0 .. $#{ $d->{buttons} } ) {
        my $label = $d->{buttons}[$i] . ( $i == $d->{default} && defined $left ? " ($left)" : '' );
        push @btn, $i == $focus ? "$s->{bold}$fg\e[7m  $label  \e[27m$s->{reset}" : $s->{text} . "[ $label ]" . $s->{reset};
    }
    my $brow = join '    ', @btn;
    # Centred on the row's widest form, so the buttons stay put while the
    # countdown loses a digit.
    my $widest = display_width($brow) + ( defined $left ? length( $opt{seconds} ) - length($left) : 0 );
    my $lpad = int( ( $iw - $widest ) / 2 );
    $line->( ( ' ' x $lpad ) . $brow );
    $line->('');
    my $keys = '←→ Tab move · Enter choose · y/n';
    push @rows, $edge . $bl . $b->{h_line} . ' ' . $s->{reset} . $s->{dim} . $keys . $s->{reset} . ' '
        . $edge . ( $b->{h_line} x ( $bw - 5 - display_width($keys) ) ) . $br . $s->{reset};
    return @rows;
}

sub modal {
    my $focus = $d->{default};
    my ( $i, $how );
    if ( defined( my $given = answer_ahead() ) ) {
        $i = $given eq 'default' ? $d->{default} : lc substr( $given, 0, 1 ) eq 'n' ? 1 : 0;
        $how = 'given ahead';
    }
    elsif ( !$live ) {
        # Not in a terminal: the dialog as it would first appear, then the
        # default.
        my @rows = dialog_rows( $focus, $opt{seconds} );
        my $col = int( ( $W - display_width( $rows[0] ) ) / 2 );
        print ' ' x $col, "$_\n" for @rows;
        ( $i, $how ) = ( $d->{default}, 'default, no terminal' );
    }
    else {
        ( $i, $how ) = run_dialog();
    }
    my $chosen = $d->{buttons}[$i];
    print ' ', $fg, glyph_of($cat), $s->{reset}, ' ', $s->{text}, $d->{title}, ':', $s->{reset}, ' ',
        $s->{bold}, lc $chosen, $s->{reset}, " $s->{dim}($how)$s->{reset}\n";
    return ( $i, $how );
}

sub run_dialog {
    my $focus = $d->{default};
    my $end = time + $opt{seconds};
    my $alt = $opt{screen} eq 'alt';
    my @rows = dialog_rows( $focus, $opt{seconds} );
    my $h = @rows;
    my $col = int( ( $W - display_width( $rows[0] ) ) / 2 ) + 1;
    my $top = int( ( $H - $h ) / 2 ) + 1;
    if ($alt) {
        print "\e[?1049h\e[2J";
    }
    else {
        # Rows reserved below the cursor, the dialog drawn into them.
        print "\n" x $h;
        print "\e[${h}A";
    }
    print "\e[?25l";
    my $draw = sub {
        my ($left) = @_;
        @rows = dialog_rows( $focus, $left );
        if ($alt) {
            print "\e[" . ( $top + $_ ) . ";${col}H$rows[$_]" for 0 .. $#rows;
        }
        else {
            print "\r\e[2K\e[${col}G$rows[$_]" . ( $_ < $#rows ? "\n" : '' ) for 0 .. $#rows;
            print "\e[" . ( $h - 1 ) . "A" if $h > 1;
        }
    };
    raw_mode('cbreak');
    my ( $i, $how );
    while (1) {
        my $left = int( $end - time + 0.999 );
        if ( $left <= 0 ) { ( $i, $how ) = ( $d->{default}, "default after $opt{seconds}s" ); last }
        $draw->($left);
        my $wait = $end - time - ( $left - 1 );
        my $k = read_key( $wait > 0 ? $wait : 0.01 );
        next unless defined $k;
        if    ( $k eq 'left' || $k eq 'right' || $k eq 'tab' ) { $focus = 1 - $focus }
        elsif ( $k eq 'enter' ) { ( $i, $how ) = ( $focus, 'key' ); last }
        elsif ( lc $k eq 'y' )  { ( $i, $how ) = ( 0, 'key' ); last }
        elsif ( lc $k eq 'n' )  { ( $i, $how ) = ( 1, 'key' ); last }
    }
    restore_mode();
    if ($alt) {
        print "\e[?1049l";
    }
    else {
        # The reserved rows are given back.
        print "\r\e[J";
    }
    return ( $i, $how );
}
