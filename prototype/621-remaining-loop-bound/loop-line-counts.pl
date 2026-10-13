#!/usr/bin/env perl
# #621: per-line execution counts of read_and_process_logs()'s per-line loop,
# read from an NYTProf profile, with the source text beside each line.
#
# The loop is found by the landmarks make-probes.pl uses (the `while (1) {`
# inside the sub and the `close $fh;` after it), so the dump follows the code
# rather than a line number.
#
#   usage: loop-line-counts.pl <ltl> <nytprof.out>
#   prints: line <TAB> count <TAB> seconds <TAB> source
use strict;
use warnings;
use Devel::NYTProf::Data;

my ($ltl, $out) = @ARGV;
die "usage: loop-line-counts.pl <ltl> <nytprof.out>\n" unless defined $ltl && defined $out;
open my $fh, '<', $ltl or die "$ltl: $!";
my @src = <$fh>;
close $fh;
chomp @src;

my ($sub_ln) = grep { $src[$_] =~ /^sub read_and_process_logs \{/ } 0 .. $#src;
die "no sub read_and_process_logs\n" unless defined $sub_ln;
my ($next_sub) = grep { $src[$_] =~ /^sub / } $sub_ln + 1 .. $#src;
my @loops = grep { $src[$_] =~ /^\s*while \(1\) \{/ } $sub_ln .. $next_sub;
die "expected one per-line loop, found " . @loops . "\n" unless @loops == 1;
my ($close) = grep { $src[$_] =~ /^\s*close \$fh;/ } $loops[0] .. $next_sub;
die "no close \$fh after the loop\n" unless defined $close;

my $p = Devel::NYTProf::Data->new({ filename => $out, quiet => 1 });
(my $name = $ltl) =~ s{.*/}{};
my ($fi) = grep { ($_->filename // '') =~ m{(^|/)\Q$name\E$} } $p->all_fileinfos;
die "$name not found in the profile\n" unless $fi;
my $ld = $fi->line_time_data;

for my $i ($loops[0] .. $close) {
    my $ln = $i + 1;
    my ($time, $count) = @{ $ld->[$ln] // [0, 0] };   # NYTProf line data: [seconds, count]
    printf "%d\t%d\t%.6f\t%s\n", $ln, $count // 0, $time // 0, $src[$i];
}
