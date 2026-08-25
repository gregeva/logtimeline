#!/usr/bin/env perl
#
# 426-native-span-merge-pairs.pl — #426 N2 merge-pair timing with the fill
# OUTSIDE the timed region (426-native-span-merge.pl --mode timing subtracts a
# separate fill baseline, which carries the fill's variance into the result).
# Each run rebuilds a fresh store untimed, then times only the merge loop.
#
use strict; use warnings;
use FindBin; use Getopt::Long;
require "$FindBin::Bin/426-revalidate-lib.pm";
use Time::HiRes ();

my ($bpd, $file, $runs, $pairs, $limit) = (53, undef, 3, 5000, 0);
GetOptions('bpd=i'=>\$bpd,'file=s'=>\$file,'runs=i'=>\$runs,'pairs=i'=>\$pairs,'limit=i'=>\$limit) or die;
die "--file required\n" unless $file;
Revalidate426::configure(bpd => $bpd);

my (@k,@d);
my %o = $limit ? (max_lines=>$limit) : ();
my $c = Revalidate426::iterate_durations($file, sub { my(undef,$key,$dur)=@_; push @k,$key; push @d,$dur }, %o);
printf "# perl %vd  bpd=%d  file=%s\n", $^V, $bpd, $file;
printf "# lines=%d positive=%d samples=%d\n", $c->{lines}, $c->{positive}, scalar @k;
printf "# runs=%d, fill EXCLUDED from the timed region (fresh store per run, untimed)\n", $runs;

sub fill { my ($arm)=@_; my $st = Revalidate426::store_new($arm, bpd=>$bpd);
           $st->add($k[$_], $d[$_]) for 0..$#k; return $st }

print "\narm\tbpd\tmerges\tmedian_s\tmin_s\tmax_s\tus_per_merge\tdigest\n";
my %dig;
for my $arm (qw(T S S2)) {
    my (@t, $nm);
    for my $r (0 .. $runs) {                 # run 0 = untimed warmup
        my $st = fill($arm);
        my @keys = sort { $a cmp $b } $st->keys;
        my @plan;
        my $done = 0;
        for (my $i = 0; $i + 1 <= $#keys && $done < $pairs; $i += 2) {
            push @plan, [$keys[$i], $keys[$i+1]]; $done++;
        }
        $nm = $done;
        my $t0 = Time::HiRes::time();
        $st->merge($_->[0], $_->[1], drop_source => 1) for @plan;
        my $el = Time::HiRes::time() - $t0;
        push @t, $el if $r > 0;
        $dig{$arm} = $st->digest if $r == $runs;
    }
    my ($m,$mn,$mx) = Revalidate426::median_min_max(@t);
    printf "%s\t%d\t%d\t%.4f\t%.4f\t%.4f\t%.2f\t%s\n", $arm,$bpd,$nm,$m,$mn,$mx,$m/$nm*1e6, substr($dig{$arm},0,12);
}
my $ok = ($dig{T} eq $dig{S}) && ($dig{S} eq $dig{S2});
printf "\n# post-merge digest parity T=S=S2: %s\n", $ok ? "IDENTICAL ($dig{T})" : "DIVERGENT T=$dig{T} S=$dig{S} S2=$dig{S2}";
exit($ok ? 0 : 2);
