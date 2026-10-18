#!/usr/bin/env perl
# The panel: the notices of the run presented together, before the charts.
# One box round them all, however many, each category headed once, its
# notices one row each, the categories divided by a blank row.
# Terminal layout only, from a fixed notice set.
#
#   perl surfaces/panel.pl [--set minimal|typical|heavy] [--divide blank|rule]
#        [--style new|ltl] [--bg dark|light] [--width N]

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Getopt::Long;
use NoticeProto qw(terminal_size style_for);
use NoticeSurfaces qw(panel);

my %opt = ( set => 'typical', divide => 'blank', style => 'new', bg => 'dark' );
GetOptions( \%opt, 'set=s', 'divide=s', 'style=s', 'bg=s', 'width=i' ) or die "bad options\n";
my ($W) = terminal_size( width => $opt{width} );
my $sets = do "$FindBin::Bin/../notices/round2.pl" or die "notices/round2.pl: $@ $!\n";
my $list = $sets->{ $opt{set} } or die "no notice set '$opt{set}'\n";
my $s = style_for( $opt{style}, $opt{bg} );

print "\n\e[92mProcessing completed.\e[0m\n\e[92mCalculating statistics completed.\e[0m\n\n";
print "$_\n" for panel( $list, $s, $W, divide => $opt{divide} );
print "\n $s->{dim}(the timeline would follow)$s->{reset}\n\n";
