use strict; use warnings;
require "/Users/gregeva/Documents/GitHub/logtimeline/.claude/worktrees/426-per-message-statistics-store/prototype/426-revalidate-lib.pm";
my $bpd=53; Revalidate426::configure(bpd=>$bpd, seed_decades=>5);
my %V; Revalidate426::iterate_durations('/tmp/ltl-426-fixtures/bin-dpm-full.log', sub { push @{$V{"$_[0]\x1f$_[1]"}}, $_[2] });
my @k = grep { @{$V{$_}}>=2 } sort keys %V;
my $off = $ENV{OFF} // 0; my @g = @k[$off..$off+7];
for my $arm (qw(T S G)) {
  my (%c);
  for my $ord ([@g],[reverse @g],[@g[3,1,7,0,5,2,6,4]],[@g[5,4,3,2,1,0,7,6]]) {
    my $st = Revalidate426::store_new($arm, bpd=>$bpd);
    for my $x (@g) { $st->add($x,$_) for @{$V{$x}} }
    $st->merge("\x00A",$_,drop_source=>1) for @$ord;
    $c{ $st->canonical("\x00A") }++;
  }
  printf "%s distinct_canonicals=%d\n", $arm, scalar keys %c;
}
# hand-check one T depth breach: build a 16-key chain, report bins error at d15 vs oracle
my @chain = @k[0..15];
for my $arm (qw(T G)) {
  my $st = Revalidate426::store_new($arm, bpd=>$bpd);
  for my $x (@chain) { $st->add($x,$_) for @{$V{$x}} }
  my @acc = @{$V{$chain[0]}};
  for my $i (1..15) { $st->merge($chain[0],$chain[$i],drop_source=>1); push @acc, @{$V{$chain[$i]}} }
  my @ex = Revalidate426::oracle_percentiles(\@acc,[0.5,0.99]);
  for my $qi (0,1) {
    my ($v)=$st->percentile($chain[0],(0.5,0.99)[$qi],'int');
    printf "%s d15 q%s est=%.6g exact=%.6g bins=%.4f n=%d\n",$arm,(0.5,0.99)[$qi],$v,$ex[$qi],abs(log($v/$ex[$qi])/log(10))*$bpd,$st->n($chain[0]);
  }
}
