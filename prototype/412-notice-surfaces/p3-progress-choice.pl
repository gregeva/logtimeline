#!/usr/bin/env perl
# P3: a yes or no raised while the progress line is on screen (memory use
# growing high during the read): the progress row is set aside, the notice and
# its timed question shown, and the progress line resumes cleanly.
# Terminal layout only: the progress line and the notice are fixed content.
#
#   perl p3-progress-choice.pl [--place above|inplace|box] [--style ltl|new]
#        [--seconds N] [--answer y|n|default] [--glyphs symbol|emoji|ascii]
#        [--bg dark|light] [--width N]
#
#   above    the notice and question print where the progress row was and
#            stay; the progress line resumes on the row below
#   inplace  the question takes the progress row itself, on one row; once
#            answered the row returns to the progress line, and the answer is
#            recorded under the completion row
#   box      the notice is a small box above the question; once answered both
#            collapse to one row recording the answer, and progress resumes

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";
use Getopt::Long;
use Time::HiRes qw(sleep);
use NoticeProto qw(interactive terminal_size style_for timed_yes_no set_answers_ahead categories);
use NoticeForms qw(set_glyphs glyph_of %render);

my %opt = ( place => 'above', style => 'ltl', seconds => 10, glyphs => 'symbol', bg => 'dark' );
GetOptions( \%opt, 'place=s', 'style=s', 'seconds=i', 'answer=s', 'glyphs=s', 'bg=s', 'width=i' )
    or die "bad options\n";
my ($W) = terminal_size( width => $opt{width} );
set_glyphs( $opt{glyphs} );
set_answers_ahead( $opt{answer} );

my $s = style_for( $opt{style}, $opt{bg} );
my ($cat) = grep { $_->{name} eq 'runtime condition' } categories();
my $fg = $s->{fg}{'runtime condition'};
my $green = "\e[92m";
my $file  = 'access_log.2025-05-05.txt';
my $total = 1_430_678;

my $notice = {
    category  => 'runtime condition',
    producer  => 'planned: #2 memory ceiling, #44 source file heuristics',
    statement => 'memory use has reached 3.2 GB and is still growing: at this rate the read needs about 7.9 GB',
    evidence  => ['62% of the 12.8 GB of physical memory; 40% of the input read'],
    remedy    => 'stop and narrow the read with -st/-et, or group with -g',
};
my $question = 'Continue reading?';

print "\n";
my $stop_at = 40;
my $record;
for my $pct ( 1 .. 100 ) {
    paint_frame($pct);
    sleep 0.03 if interactive();
    next unless $pct == $stop_at;
    my $ans = ask();
    if ( $ans eq 'n' ) {
        print "\r\e[2K", "\e[93mProcessing stopped at $pct%.\e[0m\n";
        print "\n $s->{dim}(the figures would cover the lines read so far)$s->{reset}\n\n";
        exit 0;
    }
}
print "\r$green", 'Processing completed.', "\e[0m", ' ' x ( $W - 21 ), "\n";
print "$record\n" if $record;
print "$green", 'Calculating statistics completed.', "\e[0m\n";
print "\n $s->{dim}(the timeline would follow)$s->{reset}\n\n";

# A frame as paint_progress_line() paints one: "\r", the text, padded to the
# terminal width less one.
sub paint_frame {
    my ($pct) = @_;
    my $line = int( $total * $pct / 100 );
    1 while $line =~ s/^(\d+)(\d{3})/$1,$2/;
    my $text = "Processing $pct% line $line, 856.2k lines/sec: $file";
    $text = substr( $text, 0, $W - 1 ) if length $text > $W - 1;
    print "\r$text", ' ' x ( $W - 1 - length $text );
}

sub ask {
    my $g = glyph_of($cat);
    if ( $opt{place} eq 'inplace' ) {
        my $lead = "$fg$g Memory 3.2 GB and growing (about 7.9 GB needed)$s->{reset} - ";
        my ( $ans, $how ) = timed_yes_no( style => $s, question => $question, default => 'y',
            seconds => $opt{seconds}, lead => $lead, yes => 'continuing', no => 'stopping' );
        # The question's row is given back to the progress line.
        print "\e[1A\r\e[2K";
        $record = " $fg$g$s->{reset} $s->{text}continued at $stop_at% with memory at 3.2 GB and growing$s->{reset} $s->{dim}($how)$s->{reset}"
            if $ans eq 'y';
        return $ans;
    }
    print "\r\e[2K";
    my @rows = $opt{place} eq 'box'
        ? $render{boxes}->( [$notice], $s, $W )
        : $render{lines}->( [$notice], $s, $W );
    print "$_\n" for @rows;
    my ( $ans, $how ) = timed_yes_no( style => $s, question => " $question", default => 'y',
        seconds => $opt{seconds}, yes => 'continuing', no => 'stopping' );
    if ( $opt{place} eq 'box' ) {
        # Notice and question collapse to one row recording the answer.
        my $n = @rows + 1;
        print "\e[${n}A\r\e[J";
        print " $fg$g$s->{reset} $s->{text}memory at 3.2 GB and growing at $stop_at%:$s->{reset} "
            . ( $ans eq 'y' ? 'continued' : 'stopped' ) . " $s->{dim}($how)$s->{reset}\n";
    }
    return $ans;
}
