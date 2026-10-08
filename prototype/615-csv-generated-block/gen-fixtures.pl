#!/usr/bin/env perl
#
# gen-fixtures.pl - fixtures for the CSV generated-block prototype
# (features/615-csv-registry-entry.md § 8).
#
# Usage: perl gen-fixtures.pl OUTDIR [--sizes 1k,10k,100k,1m]
#
# Performance fixtures, two families at two densities and four sizes (D12):
#   perf-epoch-{one,several}-{size}.csv  the network-latency specimen's row
#       shape: an epoch timestamp with a six-digit fraction in column 0, then
#       a second epoch, latency, request and response sizes, an id, a stream.
#   perf-iso-{one,several}-{size}.csv    the system-metrics specimen's row
#       shape: a `timestamp` column `YYYY-MM-DD HH:MM:SS`, two text columns,
#       then numeric metric columns.
#   one     = one row per distinct second (the memo always misses)
#   several = ten rows per second (the memo mostly hits)
#
# Correctness fixtures (c-*.csv), each about 40 KiB or more so that rows lie
# outside the detection sample's three 8 KiB parts. Content is neutral and
# deterministic.

use strict;
use warnings;
use POSIX qw(floor);

my $out = shift @ARGV or die "usage: $0 OUTDIR [--sizes LIST]\n";
my $sizes = '1k,10k,100k,1m';
while (@ARGV) { my $a = shift @ARGV; $sizes = shift @ARGV if $a eq '--sizes'; }
my %n_of = ( '1k' => 1_000, '10k' => 10_000, '100k' => 100_000, '1m' => 1_000_000 );
mkdir $out unless -d $out;

my $seed = 615;
sub rnd { $seed = ($seed * 1103515245 + 12345) % 2147483648; return $seed / 2147483648; }

# Calendar from first principles (days since 1970-01-01), not Time::Local, so
# the prototype's hand-derived values never share code with the tool.
sub civil { my ($z) = @_; $z += 719468; my $era = floor($z / 146097); my $doe = $z - $era * 146097;
    my $yoe = floor(($doe - floor($doe/1460) + floor($doe/36524) - floor($doe/146096)) / 365);
    my $y = $yoe + $era * 400; my $doy = $doe - (365*$yoe + floor($yoe/4) - floor($yoe/100));
    my $mp = floor((5*$doy + 2)/153); my $d = $doy - floor((153*$mp+2)/5) + 1; my $m = $mp < 10 ? $mp+3 : $mp-9;
    return ($y + ($m <= 2 ? 1 : 0), $m, $d); }
sub iso { my ($t, $sep) = @_; $sep //= ' '; my $days = floor($t / 86400); my $s = $t - $days*86400;
    my ($y,$m,$d) = civil($days);
    return sprintf('%04d-%02d-%02d%s%02d:%02d:%02d', $y, $m, $d, $sep, int($s/3600), int($s%3600/60), $s%60); }

my $EPOCH0 = 1_771_000_000;          # a whole second in 2026
my $ISO0   = 1_757_400_000;          # a whole second in 2025

sub epoch_row {
    my ($i, $per_sec, $fdigits) = @_;
    my $sec  = $EPOCH0 + int($i / $per_sec);
    my $frac = int(rnd() * 10**$fdigits);
    my $lat  = 2 + rnd() * 40;
    my $resp = $sec + 0.01;
    return sprintf("%d.%0${fdigits}d,%.6f,%.6f,%d,%d,%d,0", $sec, $frac, $resp, $lat, 40 + int(rnd()*500), 17 + int(rnd()*3000), $i + 1);
}
my $EPOCH_HEADER = 'request_timestamp,response_timestamp,latency_ms,request_size,response_size,request_id,stream';

sub iso_row {
    my ($i, $per_sec, %o) = @_;
    my $t = $ISO0 + int($i / $per_sec);
    my $ts = iso($t, $o{sep});
    $ts .= sprintf(".%0$o{frac}d", int(rnd() * 10**$o{frac})) if $o{frac};
    return join(',', $ts, 'N/A', 'host-01', map { sprintf('%.2f', rnd() * 100) } 1 .. 6);
}
my $ISO_HEADER = 'timestamp,namespace,host,cpu_user,cpu_system,cpu_total,mem_percent,conn_active,conn_waiting';

sub write_file {
    my ($name, $header, $n, $row) = @_;
    open my $fh, '>', "$out/$name" or die "$out/$name: $!";
    print $fh "$header\n";
    print $fh $row->($_), "\n" for 0 .. $n - 1;
    close $fh;
    print "$name\t$n\n";
}

for my $size (split /,/, $sizes) {
    my $n = $n_of{$size} or die "unknown size $size\n";
    for my $density ([ one => 1 ], [ several => 10 ]) {
        my ($dn, $per) = @$density;
        $seed = 615;
        write_file("perf-epoch-$dn-$size.csv", $EPOCH_HEADER, $n, sub { epoch_row($_[0], $per, 6) });
        $seed = 615;
        write_file("perf-iso-$dn-$size.csv", $ISO_HEADER, $n, sub { iso_row($_[0], $per) });
    }
}

# --- correctness fixtures ------------------------------------------------
my $C = 2000;
$seed = 1;
write_file('c-iso-nofrac.csv', $ISO_HEADER, $C, sub { iso_row($_[0], 3) });
write_file('c-iso-frac3.csv',  $ISO_HEADER, $C, sub { iso_row($_[0], 3, frac => 3) });
write_file('c-iso-frac6.csv',  $ISO_HEADER, $C, sub { iso_row($_[0], 3, frac => 6) });
write_file('c-iso-frac9.csv',  $ISO_HEADER, $C, sub { iso_row($_[0], 3, frac => 7 + $_[0] % 3) });
write_file('c-iso-T.csv',      $ISO_HEADER, $C, sub { iso_row($_[0], 3, frac => 3, sep => 'T') });
write_file('c-epoch-whole.csv', $EPOCH_HEADER, $C, sub { my $r = epoch_row($_[0], 3, 6); $r =~ s/^(\d+)\.\d+/$1/; $r });
write_file('c-epoch-frac6.csv', $EPOCH_HEADER, $C, sub { epoch_row($_[0], 3, 6) });
write_file('c-epoch-frac9.csv', $EPOCH_HEADER, $C, sub { epoch_row($_[0], 3, 9) });
# milliseconds since the epoch, read with -du ms; some rows carry a fraction
write_file('c-epoch-ms.csv', $EPOCH_HEADER, $C, sub {
    my $r = epoch_row($_[0], 3, 3); my $tail = $_[0] % 4 == 0 ? '.5' : ''; $r =~ s/^(\d+)\.(\d+)/$1$2$tail/; $r });
# semicolon separator, message columns named by -ucm
write_file('c-iso-semicolon.csv', join(';', split /,/, $ISO_HEADER), $C, sub { join(';', split /,/, iso_row($_[0], 3, frac => 3)) });
# bad rows (AC2): a text timestamp, an empty timestamp, an epoch row in an
# ISO file, a blank metric, a missing trailing field
write_file('c-iso-badrows.csv', $ISO_HEADER, $C, sub {
    my $i = $_[0]; my $r = iso_row($i, 3, frac => 3);
    return "not-a-time,N/A,host-01,1,2,3,4,5,6"          if $i % 97 == 5;
    return ",N/A,host-01,1,2,3,4,5,6"                    if $i % 97 == 6;
    return "1757400000,N/A,host-01,1,2,3,4,5,6"          if $i % 97 == 7;
    $r =~ s/^([^,]+,[^,]+,[^,]+),[^,]+/$1, /             if $i % 97 == 8;
    $r =~ s/,[^,]+$//                                     if $i % 97 == 9;
    return $r; });
write_file('c-epoch-badrows.csv', $EPOCH_HEADER, $C, sub {
    my $i = $_[0]; my $r = epoch_row($i, 3, 6);
    return "2026-02-14 10:00:00,1,2,3,4,5,0"             if $i % 89 == 5;
    return "n/a,1,2,3,4,5,0"                             if $i % 89 == 6;
    return $r; });
# yyyy-dd-MM: rows near the front are ambiguous (day <= 12), rows past the
# middle are not (day > 12), so only the middle and end parts of the
# detection sample see a date that is impossible month first
write_file('c-iso-dayfirst.csv', $ISO_HEADER, $C, sub {
    my $i = $_[0]; my $day = $i < $C / 3 ? 1 + int($i / 200) : 13 + int(($i - $C/3) / 200) % 16;
    my $s = 36000 + $i; my $hh = int($s/3600) % 24; my $mm = int($s%3600/60); my $ss = $s % 60;
    return join(',', sprintf('2025-%02d-03 %02d:%02d:%02d', $day, $hh, $mm, $ss), 'N/A', 'host-01', map { sprintf('%.2f', rnd()*100) } 1 .. 6); });
# February 30 near the end: impossible in either order, aborts (D7)
write_file('c-iso-feb30.csv', $ISO_HEADER, $C, sub {
    my $i = $_[0]; my $r = iso_row($i, 3);
    $r =~ s/^\d{4}-\d{2}-\d{2}/2025-02-30/ if $i == $C - 50; $r });
# month 13 on one row the sample does not see (a quarter of the way in):
# the file settles month first, the row aborts (D7, D15)
write_file('c-iso-month13-outside.csv', $ISO_HEADER, $C, sub {
    my $i = $_[0]; my $r = iso_row($i, 3);
    $r =~ s/^(\d{4})-\d{2}-\d{2}/$1-13-01/ if $i == int($C / 4); $r });
