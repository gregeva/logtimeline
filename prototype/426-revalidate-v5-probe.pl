#!/usr/bin/env perl
#
# 426-revalidate-v5-probe.pl — two mechanism probes behind the V5 tables.
#
#   (1) boundary placement of the first sample in T's seed partition, per bpd:
#       partition_new(v0) puts v0 at boundary index bin_count/2 when
#       int(bpd*5) is even; bin_assign then lands v0 at the TOP of bin
#       bin_count/2-1 or the BOTTOM of bin bin_count/2 depending on float
#       rounding. Prints where it lands and what a spike-at-v0 percentile
#       (all mass in that bin, fraction -> 1) returns. G always has 10^k at
#       the bottom of its bin (index = bpd*k exactly).
#   (2) --file F --bpd N --ordinal K --q 0.75: rebuild the K-th key (sorted,
#       N >= --min-N) in T and G, print geometry, the bin the oracle rank
#       lands in, its boundaries, and the walk result — for explaining a
#       specific row of revalidate-v5-key-bpdNN.tsv.
#
use strict;
use warnings;
use FindBin;
use POSIX ();
require "$FindBin::Bin/426-revalidate-lib.pm";

my %opt = (file => undef, bpd => 256, ordinal => undef, q => 0.75, 'min-N' => 100, v0 => '1,10,100,1000');
while (@ARGV) {
    my $o = shift @ARGV;
    if ($o eq '--help') { print "usage: $0 [--file F --bpd N --ordinal K --q 0.75 --min-N 100] [--v0 1,10,100,1000]\n"; exit 0 }
    elsif ($o =~ /^--(file|bpd|ordinal|q|min-N|v0)$/) { $opt{$1} = shift @ARGV }
    else { die "unknown option $o\n" }
}

print "## probe 1: first-sample boundary placement in T's seed partition (seed_decades=5)\n";
printf "%-5s %-7s %-10s %-10s %-9s %-22s %-22s %s\n", 'bpd', 'v0', 'bin_count', 'bc/2', 'assigned', 'lower', 'upper', 'spike percentile (fraction=1) -> value, rel err';
for my $bpd (53, 115, 256, 616) {
    for my $v0 (split /,/, $opt{v0}) {
        my $p = Revalidate426::partition_new($v0, $bpd, 5);
        my ($where, $i) = Revalidate426::bin_assign($p, $v0);
        my $lower = Revalidate426::bin_boundary($p, $i);
        my $upper = Revalidate426::bin_boundary($p, $i + 1);
        my %store; Revalidate426::counter_update(\%store, 'k', $v0, $bpd) for 1 .. 100;
        my ($v) = Revalidate426::percentile($store{k}, 0.99);
        printf "%-5d %-7s %-10d %-10s %-9s %-22.17g %-22.17g %.17g  %+.4f%%  (%s)\n", $bpd, $v0, $p->{bin_count}, $p->{bin_count} / 2, $i, $lower, $upper, $v, 100 * ($v - $v0) / $v0,
            ($lower == $v0 ? 'v0 at BOTTOM of bin' : ($upper == $v0 ? 'v0 at TOP of bin' : 'v0 inside bin'));
    }
}
print "G: grid_index(v0) and boundaries\n";
for my $bpd (53, 115, 256, 616) {
    for my $v0 (split /,/, $opt{v0}) {
        my $i = Revalidate426::grid_index($v0, $bpd);
        my ($ic, $corr) = Revalidate426::grid_index_checked($v0, $bpd);
        my $st = Revalidate426::store_new('G', bpd => $bpd); $st->add('k', $v0) for 1 .. 100;
        my ($v) = $st->percentile('k', 0.99);
        printf "bpd=%-4d v0=%-5s index=%d checked=%d(corrected=%d) lower=%.17g upper=%.17g spike p99 -> %.17g %+.4f%%\n", $bpd, $v0, $i, $ic, $corr,
            Revalidate426::grid_lower($i, $bpd), Revalidate426::grid_upper($i, $bpd), $v, 100 * ($v - $v0) / $v0;
    }
}

exit 0 unless defined $opt{file} && defined $opt{ordinal};
print "\n## probe 2: key ordinal $opt{ordinal} (sorted, N>=$opt{'min-N'}) at bpd=$opt{bpd}, q=$opt{q}\n";
Revalidate426::configure(bpd => $opt{bpd}, seed_decades => 5, max_rebins => undef);
my %samples;
Revalidate426::iterate_durations($opt{file}, sub { my ($c, $k, $d) = @_; push @{ $samples{"$c\x1f$k"} }, $d });
my @big = grep { @{ $samples{$_} } >= $opt{'min-N'} } sort keys %samples;
my $key = $big[$opt{ordinal} - 1];
(my $shown = $key) =~ s/\x1f/ | /;
my @s = sort { $a <=> $b } @{ $samples{$key} };
my $n = @s;
my $rank0 = int($n * $opt{q});
printf "key: %s\nN=%d first_sample=%s oracle=sorted[int(N*q)]=%s (0-based index %d); min=%s max=%s distinct=%d\n", $shown, $n, $samples{$key}[0], $s[$rank0], $rank0, $s[0], $s[-1], scalar(keys %{{ map { $_ => 1 } @s }});
{
    my $seed = Revalidate426::partition_new($samples{$key}[0], $opt{bpd}, 5);
    my $raw = $samples{$key};
    my ($pos) = grep { $raw->[$_] > $seed->{max} || $raw->[$_] < $seed->{min} } 0 .. $#$raw;
    printf "seed partition [%.6g, %.6g] bin_count=%d; first out-of-range sample: %s (arrival position %s of %d; %d samples precede it)\n",
        $seed->{min}, $seed->{max}, $seed->{bin_count}, (defined $pos ? $raw->[$pos] : 'none'), (defined $pos ? $pos + 1 : '-'), $n, (defined $pos ? $pos : 0);
}
my %hist; $hist{$_}++ for @s;
print "value histogram (value:count): ", join(' ', map { "$_:$hist{$_}" } sort { $a <=> $b } keys %hist), "\n";
for my $arm (qw(T G)) {
    my $st = Revalidate426::store_new($arm, bpd => $opt{bpd});
    $st->add($key, $_) for @{ $samples{$key} };
    my $g = $st->geometry($key);
    print "$arm geometry: ", join(' ', map { "$_=" . (defined $g->{$_} ? $g->{$_} : 'undef') } sort keys %$g), "\n";
    print "$arm bins: ", join(' ', $st->bins_pairs($key)), "\n";
    for my $conv (qw(int ceil)) {
        my ($v, $a) = $st->percentile($key, $opt{q}, $conv);
        my $target = Revalidate426::_target_rank($opt{q}, $n, $conv);
        # locate the bin holding the target rank and its boundaries
        my ($lo, $hi, $cum, $c_in, $rank_in) = (undef, undef, 0, undef, undef);
        for my $pair ($st->bins_pairs($key)) {
            my ($i, $c) = split /:/, $pair;
            $cum += $c;
            if ($target <= $cum) {
                if ($arm eq 'T') { my $p = $st->entry($key)->{partition}; ($lo, $hi) = (Revalidate426::bin_boundary($p, $i), Revalidate426::bin_boundary($p, $i + 1)) }
                else { ($lo, $hi) = (Revalidate426::grid_lower($i, $opt{bpd}), Revalidate426::grid_upper($i, $opt{bpd})) }
                ($c_in, $rank_in) = ($c, $target - ($cum - $c));
                last;
            }
        }
        printf "%s %-4s target_rank=%d bin: lower=%.17g upper=%.17g count=%d rank_in_bin=%d fraction=%.6f -> value=%.17g audit=%s rel_err_vs_oracle=%+.4f%%  bin_width=%.4f%%\n",
            $arm, $conv, $target, $lo, $hi, $c_in, $rank_in, $rank_in / $c_in, $v, $a, 100 * ($v - $s[$rank0]) / $s[$rank0], 100 * ($hi / $lo - 1);
    }
}
