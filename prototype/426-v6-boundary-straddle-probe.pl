use strict; use warnings; use POSIX ();
use FindBin; require "/Users/gregeva/Documents/GitHub/logtimeline/.claude/worktrees/426-per-message-statistics-store/prototype/426-revalidate-lib.pm";
my $BPD = $ARGV[0] // 80;
Revalidate426::configure(bpd => $BPD);
my @values;
Revalidate426::iterate_durations('/Users/gregeva/Documents/GitHub/logtimeline/logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log',
    sub { push @values, $_[2] });
my ($vmin,$vmax)=($values[0],$values[0]);
for (@values){ $vmin=$_ if $_<$vmin; $vmax=$_ if $_>$vmax }
my $W=52; my $lr=log($vmax/$vmin);
my @exact=(0)x$W;
for my $v (@values){ my $i=int($W*log($v/$vmin)/$lr); $i=0 if $i<0; $i=$W-1 if $i>=$W; $exact[$i]++ }
# T
my $st = Revalidate426::store_new('T', bpd=>$BPD);
$st->add('_all',$_) for @values;
my $e=$st->entry('_all');
sub bb { my ($p,$i)=@_; $p->{min}*exp($p->{log_ratio}*$i/$p->{bin_count}) }
my @fin=(0)x$W;
for my $oi (0..$e->{partition}{bin_count}-1){
  my $c=$e->{bins}[$oi]; next unless $c;
  my $mid=sqrt(bb($e->{partition},$oi)*bb($e->{partition},$oi+1));
  my $ni=int($W*log($mid/$vmin)/$lr); $ni=0 if $ni<0; $ni=$W-1 if $ni>=$W;
  $fin[$ni]+=$c;
}
printf "bpd=%d  top deviating cells (cell: exact -> T):\n",$BPD;
my @idx = sort { abs($fin[$b]-$exact[$b]) <=> abs($fin[$a]-$exact[$a]) } 0..$W-1;
for my $i (@idx[0..7]) {
  printf "  cell %2d: exact=%7d  T=%7d  diff=%+7d   cell range [%.4g, %.4g)\n",
    $i,$exact[$i],$fin[$i],$fin[$i]-$exact[$i],
    $vmin*exp($lr*$i/$W), $vmin*exp($lr*($i+1)/$W);
}
my $tot=0; $tot+=abs($fin[$_]-$exact[$_]) for 0..$W-1;
printf "total abs dev %d of %d (%.4f%%)\n",$tot,scalar(@values),100*$tot/@values;
# what fraction of observations sit exactly at integer values?
my %vc; $vc{$_}++ for @values;
my @top = sort { $vc{$b} <=> $vc{$a} } keys %vc;
printf "most common values: "; printf "%s(x%d) ", $_, $vc{$_} for @top[0..4]; print "\n";
# --- G arm on the same data, same display ---
my $g = Revalidate426::store_new('G', bpd=>$BPD);
$g->add('_all',$_) for @values;
my $gi = $g->{row}{'_all'}; my $span = $g->{bins}[$gi];
my @gfin=(0)x$W; my $base=$span->[0];
for my $j (1..$#$span){ my $c=$span->[$j]; next unless $c;
  my $idx=$base+$j-1; my $mid=10**(($idx+0.5)/$BPD);
  my $ni=int($W*log($mid/$vmin)/$lr); $ni=0 if $ni<0; $ni=$W-1 if $ni>=$W;
  $gfin[$ni]+=$c }
my $gtot=0; $gtot+=abs($gfin[$_]-$exact[$_]) for 0..$W-1;
printf "G: total abs dev %d (%.4f%%);  cell2 exact=%d G=%d  cell3 exact=%d G=%d\n",
  $gtot,100*$gtot/@values,$exact[2],$gfin[2],$exact[3],$gfin[3];
