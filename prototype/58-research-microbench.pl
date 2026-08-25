use strict; use warnings;
use Time::HiRes qw(time);
my $N = 2_000_000;
my $line = '2026-08-20 12:34:56.789 INFO  [pool-1-thread-7] com.example.Foo - handled request in 123 ms';
sub bench { my ($name,$code)=@_; my $t0=time; $code->(); my $dt=time-$t0; printf "%-38s %8.1f ns/iter\n",$name,$dt/$N*1e9; }

# 1. sub call overhead
sub empty {}
sub takes3 { my ($a,$b,$c)=@_; return $a }
bench("empty loop (baseline)", sub { for (1..$N) {} });
bench("empty sub call", sub { empty() for 1..$N });
bench("sub w/ 3 args + unpack", sub { takes3(1,2,3) for 1..$N });
my $cr = sub { my ($a,$b,$c)=@_; return $a };
bench("coderef call 3 args", sub { $cr->(1,2,3) for 1..$N });
my %disp = (fmt=>$cr);
bench("hash-dispatch coderef 3 args", sub { $disp{fmt}->(1,2,3) for 1..$N });

# 2. captures: positional vs named vs @{^CAPTURE}
my $re_pos = qr/^(\S+) (\S+) (\S+)\s+\[([^\]]+)\] (\S+) - .*?(\d+) ms$/;
my $re_nam = qr/^(?<d>\S+) (?<t>\S+) (?<l>\S+)\s+\[(?<th>[^\]]+)\] (?<c>\S+) - .*?(?<ms>\d+) ms$/;
my $M = 500_000;
{ my $t0=time; my $x; for (1..$M){ $line =~ $re_pos and $x = "$1$2$3$4$5$6"; } printf "%-38s %8.1f ns/iter\n","match+positional \$1..\$6", (time-$t0)/$M*1e9; }
{ my $t0=time; my $x; for (1..$M){ $line =~ $re_nam and $x = "$+{d}$+{t}$+{l}$+{th}$+{c}$+{ms}"; } printf "%-38s %8.1f ns/iter\n","match+named %+ x6", (time-$t0)/$M*1e9; }
{ my $t0=time; my $x; for (1..$M){ $line =~ $re_nam and $x = "$1$2$3$4$5$6"; } printf "%-38s %8.1f ns/iter\n","named-group re, positional access", (time-$t0)/$M*1e9; }
{ my $t0=time; my $x; for (1..$M){ $line =~ $re_pos and $x = join '', @{^CAPTURE}; } printf "%-38s %8.1f ns/iter\n","match+\@{^CAPTURE} join", (time-$t0)/$M*1e9; }
{ my $t0=time; my $x; for (1..$M){ $line =~ $re_pos and $x = join '', map { substr($line,$-[$_],$+[$_]-$-[$_]) } 1..6; } printf "%-38s %8.1f ns/iter\n","match+\@-/\@+ substr x6", (time-$t0)/$M*1e9; }

# 3. qr// storage forms
my @arr = ($re_pos);
my %h = (pattern=>$re_pos);
my $entry = \%h;
{ my $t0=time; my $c=0; for (1..$M){ $c++ if $line =~ /^(\S+) (\S+) (\S+)\s+\[([^\]]+)\] (\S+) - .*?(\d+) ms$/; } printf "%-38s %8.1f ns/iter\n","literal pattern", (time-$t0)/$M*1e9; }
{ my $t0=time; my $c=0; for (1..$M){ $c++ if $line =~ $re_pos; } printf "%-38s %8.1f ns/iter\n","lexical qr", (time-$t0)/$M*1e9; }
{ my $t0=time; my $c=0; for (1..$M){ $c++ if $line =~ $arr[0]; } printf "%-38s %8.1f ns/iter\n","array-element qr", (time-$t0)/$M*1e9; }
{ my $t0=time; my $c=0; for (1..$M){ $c++ if $line =~ $entry->{pattern}; } printf "%-38s %8.1f ns/iter\n","hashref-element qr", (time-$t0)/$M*1e9; }
{ my $t0=time; my $c=0; for (1..$M){ $c++ if $line =~ /$re_pos/; } printf "%-38s %8.1f ns/iter\n","interpolated qr in //", (time-$t0)/$M*1e9; }
