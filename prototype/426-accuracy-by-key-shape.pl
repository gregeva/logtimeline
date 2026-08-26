# 426-accuracy-by-key-shape.pl — decomposes arm T's and arm G's percentile
# error against the exact oracle by KEY SHAPE (observation count x value
# spread in decades) at a given bins-per-decade.
#
# Written because N4's aggregate re-bless numbers (prototype/426-results/
# v8-rebless) report a T3 rate but not a direction: a cell that classifies T3
# has moved more than 1%, which says nothing about whether it moved toward or
# away from the true value. The aggregate "G further more often than closer"
# turns out to be a composition effect — the two representations have OPPOSITE
# strengths, sorted by key shape, and the population is dominated by the shape
# that favours T at one particular resolution.
#
# The mechanism: T seeds each key's partition around that key's own first
# value (#187 Decision 5), so its bins are adaptive to that key's data — an
# advantage that is largest for low-N, narrow-spread keys. G's grid is global,
# so a key occupying a narrow range gets whatever grid cells fall there —
# but it never wastes resolution on a seeded range the key does not occupy,
# which is the advantage that grows with spread.
#
# Usage: perl prototype/426-accuracy-by-key-shape.pl [bpd]   (default 53)
use strict; use warnings;
use FindBin; require "$FindBin::Bin/426-revalidate-lib.pm";
my $BPD = $ARGV[0] // 53;
Revalidate426::configure(bpd => $BPD);
my %vals;
Revalidate426::iterate_durations(
  ($ENV{LTL_FILE} || "$FindBin::Bin/../logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log"),
  sub { push @{$vals{"$_[0]\x1f$_[1]"}}, $_[2] });
my $T = Revalidate426::store_new('T', bpd=>$BPD);
my $G = Revalidate426::store_new('G', bpd=>$BPD);
for my $k (keys %vals){ for my $v (@{$vals{$k}}){ $T->add($k,$v); $G->add($k,$v) } }

# bucket keys by N and by value spread; report G-vs-T oracle error by band
my %band;
for my $k (keys %vals) {
  my @raw = @{$vals{$k}};
  my $n = @raw;
  my ($mn,$mx)=($raw[0],$raw[0]); for(@raw){ $mn=$_ if $_<$mn; $mx=$_ if $_>$mx }
  my $decades = $mn>0 ? log($mx/$mn)/log(10) : 0;
  my @o = Revalidate426::oracle_percentiles(\@raw,[0.5,0.95]);
  my $bn = $n<10 ? 'N<10' : $n<100 ? 'N<100' : $n<1000 ? 'N<1000' : 'N>=1000';
  my $bd = $decades < 0.1 ? 'spread<0.1dec' : $decades < 1 ? 'spread<1dec' : 'spread>=1dec';
  for my $qi (0,1) {
    my $q = $qi ? 0.95 : 0.5;
    my ($tv)=$T->percentile($k,$q,'int'); my ($gv)=$G->percentile($k,$q,'int');
    my $ov=$o[$qi]; next unless defined $ov && $ov>0 && defined $tv && defined $gv;
    # apply the clamp both arms get in calculate_statistics_bin
    for my $r (\$tv,\$gv){ $$r=$mn if $$r<$mn; $$r=$mx if $$r>$mx }
    my $et=abs($tv-$ov)/$ov; my $eg=abs($gv-$ov)/$ov;
    $band{"$bn / $bd"}{n}++;
    $band{"$bn / $bd"}{et}+=$et; $band{"$bn / $bd"}{eg}+=$eg;
    $band{"$bn / $bd"}{closer}++ if $eg<$et; $band{"$bn / $bd"}{further}++ if $eg>$et;
  }
}
printf "%-28s %7s %10s %10s %8s %8s\n",'band','cells','T mean err','G mean err','G closer','G further';
for my $b (sort keys %band){
  my $d=$band{$b};
  printf "%-28s %7d %9.4f%% %9.4f%% %8d %8d\n",$b,$d->{n},100*$d->{et}/$d->{n},100*$d->{eg}/$d->{n},$d->{closer}//0,$d->{further}//0;
}
