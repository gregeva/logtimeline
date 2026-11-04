#!/usr/bin/env perl
# wt-console-text.pl <out.txt>
#
# Run in a Windows console (Windows Terminal or the classic console host),
# typed at its prompt after a command: writes to <out.txt> the console's
# input and output modes as this program finds them, then the text of the
# screen buffer from its top to the cursor's row, each row with its trailing
# blanks removed. A mode is GetConsoleMode's value: input 0x0001 processed,
# 0x0002 line input, 0x0004 echo, 0x0200 virtual terminal input.
use strict;
use warnings;
use Win32::Console;

my ($out) = @ARGV or die "usage: wt-console-text.pl <out.txt>\n";
my $in  = Win32::Console->new(STD_INPUT_HANDLE);
my $con = Win32::Console->new(STD_OUTPUT_HANDLE);
my @info = $con->Info();    # size x, size y, cursor x, cursor y, attr, left, top, right, bottom, max x, max y
my ( $w, $cursor_row ) = @info[ 0, 3 ];
open my $fh, '>', $out or die "$out: $!\n";
printf $fh "input_mode: 0x%04x\noutput_mode: 0x%04x\nbuffer: %d by %d, cursor row %d\n", $in->Mode(), $con->Mode(), $w, $info[1], $cursor_row;
for my $row ( 0 .. $cursor_row ) {
    my $text = $con->ReadChar( $w, 0, $row ) // '';
    $text =~ s/\s+\z//;
    print $fh "$text\n";
}
close $fh or die "$out: $!\n";
