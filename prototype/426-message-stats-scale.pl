# 426-message-stats-scale.pl — the locked objective, measured directly on the
# surface #426 exists for.
#
# "Replace the container, and measure what the container change does to the
# constraint" (architect, 2026-08-25). The constraint is per-key cost at
# unbounded message cardinality. This builds all three arms over the real
# message-stats keying ($category\x1f$log_key, as counter_update is called in
# read_and_process_logs) at the full fan-out fixture, and times what the
# statistics pass actually does: build once, then evaluate percentiles across
# every key.
#
# Not a projection from a smaller store — the store is built at size and
# measured. Medians of 3 with min/max.
#
# Usage: perl prototype/426-message-stats-scale.pl [bpd] [file]
use strict; use warnings;
use FindBin; require "$FindBin::Bin/426-revalidate-lib.pm";
my $BPD = $ARGV[0] // 53;
my $FILE = $ARGV[1] || '/tmp/ltl-426-fixtures/bin-twxdur-full.log';
Revalidate426::configure(bpd => $BPD);
my (@cat,@key,@dur);
Revalidate426::iterate_durations($FILE, sub { push @cat,$_[0]; push @key,$_[1]; push @dur,$_[2] });
printf "file=%s bpd=%d observations=%d\n",$FILE,$BPD,scalar @dur;
my %seen; $seen{"$cat[$_]\x1f$key[$_]"}=1 for 0..$#dur;
printf "distinct keys=%d\n", scalar keys %seen;
my @QQ=(0.5,0.95,0.99);
for my $arm (qw(T S G)) {
  my @build = Revalidate426::time_runs(3, sub {
      my $st = Revalidate426::store_new($arm, bpd=>$BPD);
      for my $i (0..$#dur) { $st->add("$cat[$i]\x1f$key[$i]", $dur[$i]) }
      return $st;
  });
  my $st = Revalidate426::store_new($arm, bpd=>$BPD);
  $st->add("$cat[$_]\x1f$key[$_]", $dur[$_]) for 0..$#dur;
  my @k = $st->keys;
  my @pct = Revalidate426::time_runs(3, sub {
      my $n=0; for my $kk (@k){ for my $q (@QQ){ my ($v)=$st->percentile($kk,$q,'ceil'); $n++ } } return $n;
  });
  my ($bm,$bmin,$bmax)=Revalidate426::median_min_max(@build);
  my ($pm,$pmin,$pmax)=Revalidate426::median_min_max(@pct);
  printf "%-2s build %7.3f s [%.3f,%.3f]   percentiles(%d keys x %d q) %7.3f s [%.3f,%.3f]  mem %s\n",
     $arm,$bm,$bmin,$bmax,scalar @k,scalar @QQ,$pm,$pmin,$pmax,
     (eval { my $b=$st->memory_bytes; sprintf("%.1f MB (%.0f B/key)",$b/1048576,$b/(scalar @k||1)) } || 'n/a');
}
