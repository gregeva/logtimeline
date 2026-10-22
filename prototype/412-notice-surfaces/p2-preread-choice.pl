#!/usr/bin/env perl
# P2: the notices known before the read starts (the analyst's own options),
# presented at once with a timed yes or no: continue, or stop and correct them.
# Terminal layout only, from a fixed notice set.
#
#   perl p2-preread-choice.pl [--form lines|boxes|sections] [--style ltl|new]
#        [--frame none|shared] [--seconds N] [--answer y|n|default]
#        [--glyphs symbol|emoji|ascii] [--bg dark|light] [--width N]
#
# --frame shared draws the notices and the question in one frame, the question
# set off below a divider; none puts the question on the row below the block.

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";
use Getopt::Long;
use NoticeProto qw(terminal_size style_for display_width timed_yes_no set_answers_ahead);
use NoticeForms qw(set_glyphs notice_rows %render);

my %opt = ( form => 'boxes', style => 'ltl', frame => 'none', seconds => 10, glyphs => 'symbol', bg => 'dark' );
GetOptions( \%opt, 'form=s', 'style=s', 'frame=s', 'seconds=i', 'answer=s', 'glyphs=s', 'bg=s', 'width=i' )
    or die "bad options\n";
my ($W) = terminal_size( width => $opt{width} );
set_glyphs( $opt{glyphs} );
set_answers_ahead( $opt{answer} );

my $sets = do "$FindBin::Bin/notices/sets.pl" or die "notices/sets.pl: $@ $!\n";
my $s = style_for( $opt{style}, $opt{bg} );
my $b = $s->{box};
my $fg = $s->{fg}{'your options'};
my $question = 'Continue with these options?';

print "\n";
if ( $opt{frame} eq 'shared' ) {
    # One frame: the block's rows inside, a divider, the question on the last
    # row inside the frame.
    my $edge  = $s->{name} eq 'ltl' ? $s->{frame} : $fg;
    my $outer = $W - 2;
    my $inner = $outer - 4;
    my $title = ' ' . ( $s->{name} eq 'ltl' ? 'BEFORE THE READ' : 'Before the read' ) . ' ';
    my $count = ' ' . scalar( @{ $sets->{options} } ) . ' notices about the options given ';
    my $fill  = $outer - 3 - display_width($title) - display_width($count);
    print ' ', $edge, $b->{corner_tl}, $b->{h_line}, $s->{reset}, $s->{bold}, $fg, $title, $s->{reset},
        $s->{dim}, $count, $s->{reset}, $edge, $b->{h_line} x $fill, $b->{corner_tr}, $s->{reset}, "\n";
    my @rows = map { notice_rows( $_, $s, $fg, $inner, $fg . "• " . $s->{reset}, "  ", "  " ) } @{ $sets->{options} };
    for my $r (@rows) {
        my $pad = $inner - display_width($r);
        print ' ', $edge, $b->{v_line}, $s->{reset}, ' ', $r, ' ' x ( $pad > 0 ? $pad : 0 ), ' ', $edge, $b->{v_line}, $s->{reset}, "\n";
    }
    print ' ', $edge, $b->{t_right}, $b->{h_line} x ( $outer - 2 ), $b->{t_left}, $s->{reset}, "\n";
    # The question row is drawn inside the frame; the bottom edge is printed
    # once it is answered.
    my $lead = ' ' . $edge . $b->{v_line} . $s->{reset} . ' ';
    my ($ans) = timed_yes_no( style => $s, question => $question, default => 'y', seconds => $opt{seconds},
        lead => $lead, close => $edge . $b->{v_line} . $s->{reset}, close_col => $outer + 1, yes => 'continuing', no => 'stopping' );
    print ' ', $edge, $b->{corner_bl}, $b->{h_line} x ( $outer - 2 ), $b->{corner_br}, $s->{reset}, "\n";
    after($ans);
}
else {
    print "$_\n" for $render{ $opt{form} }->( $sets->{options}, $s, $W );
    print "\n";
    my ($ans) = timed_yes_no( style => $s, question => " $question", default => 'y', seconds => $opt{seconds},
        yes => 'continuing', no => 'stopping' );
    after($ans);
}

sub after {
    my ($ans) = @_;
    print "\n";
    print $ans eq 'y'
        ? " $s->{dim}(the read would start here, with the progress line)$s->{reset}\n"
        : " $s->{dim}(ltl stops here, before reading: correct the options and run again)$s->{reset}\n";
    print "\n";
}
