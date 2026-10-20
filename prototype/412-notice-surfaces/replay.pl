#!/usr/bin/env perl
# Replay a raw capture of a prototype through a terminal emulator
# (Term::VT102) and print the screen it leaves, one row per line, trailing
# blanks removed. A capture made from a file has bare line feeds, which a
# terminal's line discipline would have turned into CR LF; they are converted
# the same way.
#
#   perl replay.pl CAPTURE [--cols N] [--rows N]

use strict;
use warnings;
use Getopt::Long;
use Term::VT102;

my %opt = ( cols => 120, rows => 60 );
GetOptions( \%opt, 'cols=i', 'rows=i' ) or die "bad options\n";
my $file = shift or die "usage: replay.pl CAPTURE [--cols N] [--rows N]\n";

system("chcp 65001 > nul") if $^O eq 'MSWin32';    # the console's code page to UTF-8, as ltl does (docs/terminal-output.md § Encoding)
binmode STDOUT, ':encoding(UTF-8)';
open my $fh, '<:encoding(UTF-8)', $file or die "$file: $!\n";
my $data = do { local $/; <$fh> };
$data =~ s/(?<!\r)\n/\r\n/g;

my $t = Term::VT102->new( cols => $opt{cols}, rows => $opt{rows} );
$t->process($data);
my @rows = map { my $r = $t->row_plaintext($_); $r =~ s/\s+\z//; $r } 1 .. $opt{rows};
pop @rows while @rows && $rows[-1] eq '';
print "$_\n" for @rows;
