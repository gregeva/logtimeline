#!/usr/bin/env perl
# osc11.pl <out>: asks the terminal it runs in for its background colour
# (OSC 11), as ltl's detect_terminal does, and writes the reply to <out>.
# macOS only: it is run inside a Terminal.app window by measure.sh.
use strict; use warnings; use IO::Handle;
open my $tty, '+<', '/dev/tty' or die;
system 'stty raw -echo </dev/tty';
print $tty "\e]11;?\a"; $tty->flush;
my ($r, $rin) = ('', '');
vec($rin, fileno($tty), 1) = 1;
while (select(my $rout = $rin, undef, undef, 1)) { sysread($tty, my $b, 64) or last; $r .= $b; last if $r =~ /\a|\e\\/ }
system 'stty sane </dev/tty';
open my $o, '>', $ARGV[0] or die; print $o (length $r ? ($r =~ s/\e/ESC/gr) : '(no reply)'), "\n";
