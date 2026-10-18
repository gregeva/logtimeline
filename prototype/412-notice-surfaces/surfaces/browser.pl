#!/usr/bin/env perl
# The notice browser: many notices as a navigable list in a box,
# category tabs across its top, the selected notice's detail beneath. A notice
# offering views opens them in the detail's place. On the alternate screen
# over the dimmed run (--screen alt), or below the cursor (--screen inline);
# erased on closing, leaving no trace.
# Terminal layout only, from a fixed notice set.
#
#   perl surfaces/browser.pl [--screen alt|inline] [--style new|ltl] [--rows N]
#        [--bg dark|light] [--width N] [--height N]
#
# Keys: up/down or k/j move, PgUp/PgDn page, left/right, h/l or Tab change the
# tab, 1-7 choose a tab, Enter opens a notice's views, q or Esc close.

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Getopt::Long;
use NoticeProto qw(terminal_size style_for);
use NoticeSurfaces qw(out browser);

my %opt = ( screen => 'alt', style => 'new', rows => 10, bg => 'dark' );
GetOptions( \%opt, 'screen=s', 'style=s', 'rows=i', 'bg=s', 'width=i', 'height=i' ) or die "bad options\n";
my ( $W, $H ) = terminal_size( width => $opt{width}, height => $opt{height} );
my $s = style_for( $opt{style}, $opt{bg} );
my $sets = do "$FindBin::Bin/../notices/round2.pl" or die "notices/round2.pl: $@ $!\n";

out( '', "$s->{dim}\$ ltl access_log.2025-05-05.txt$s->{reset}", '',
    "\e[92mProcessing completed.\e[0m", "\e[92mCalculating statistics completed.\e[0m" );
print "\n";
my $chosen = browser( s => $s, W => $W, H => $H, screen => $opt{screen}, rows => $opt{rows}, notices => $sets->{heavy} );
my @args = map { $_->[0]{views}[ $_->[1] ]{args} } @$chosen;
@args = grep { $_ ne '' } @args;
print " $s->{dim}(the timeline would follow" . ( @args ? ', as if given ' . join( ' ', @args ) : '' ) . ")$s->{reset}\n\n";
