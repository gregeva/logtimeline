#!/usr/bin/env perl
# Pure I/O benchmark - standard Perl file reading
# Tests the I/O ceiling without any processing overhead

use strict;
use warnings;
use Time::HiRes qw(time);

my $file = shift or die "Usage: $0 <filename>\n";
my $lines = 0;
my $bytes = 0;

my $start = time();

open my $fh, '<', $file or die "Cannot open $file: $!";
while (my $line = <$fh>) {
    $lines++;
    $bytes += length($line);
}
close $fh;

my $elapsed = time() - $start;

printf "File: %s\n", $file;
printf "Lines: %d\n", $lines;
printf "Bytes: %d (%.1f MB)\n", $bytes, $bytes / 1024 / 1024;
printf "Time: %.3f seconds\n", $elapsed;
printf "Rate: %.0f lines/sec\n", $lines / $elapsed;
printf "Rate: %.1f MB/sec\n", ($bytes / 1024 / 1024) / $elapsed;
