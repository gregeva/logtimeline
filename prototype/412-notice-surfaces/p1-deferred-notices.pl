#!/usr/bin/env perl
# P1: the notices deferred during the run, presented together by category.
# Terminal layout only, from a fixed notice set.
#
#   perl p1-deferred-notices.pl [--form lines|boxes|sections] [--style ltl|new]
#        [--set minimal|typical] [--glyphs symbol|emoji|ascii] [--bg dark|light]
#        [--width N] [--all]
#
# --all prints every form in both styles one after the other.

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";
use Getopt::Long;
use NoticeProto qw(terminal_size style_for);
use NoticeForms qw(set_glyphs %render);

my %opt = ( form => 'sections', style => 'ltl', set => 'typical', glyphs => 'symbol', bg => 'dark' );
GetOptions( \%opt, 'form=s', 'style=s', 'set=s', 'glyphs=s', 'bg=s', 'width=i', 'all' )
    or die "bad options\n";
my ($W) = terminal_size( width => $opt{width} );
set_glyphs( $opt{glyphs} );

my $sets = do "$FindBin::Bin/notices/sets.pl" or die "notices/sets.pl: $@ $!\n";
my $notices = $sets->{ $opt{set} } or die "no notice set '$opt{set}'\n";

my @show = $opt{all}
    ? map { my $st = $_; map { [ $_, $st ] } qw(lines boxes sections) } qw(ltl new)
    : ( [ $opt{form}, $opt{style} ] );

for my $case (@show) {
    my ( $form, $sname ) = @$case;
    $render{$form} or die "no form '$form'\n";
    my $s = style_for( $sname, $opt{bg} );
    print "\n$s->{dim}── form: $form   style: $sname ──$s->{reset}\n\n" if $opt{all};
    print "$_\n" for $render{$form}->( $notices, $s, $W );
}
print "\n";
