use strict; use warnings;
use FindBin; require "/Users/gregeva/Documents/GitHub/logtimeline/.claude/worktrees/426-per-message-statistics-store/prototype/426-revalidate-lib.pm";
# Verify the S2 span representation itself (not just the digest projection):
# no undef inside the span, base >= 0, base < bin_count, span within bin_count,
# and the RAW span array equal element-for-element to arm S's.
for my $bpd (53, 616) {
  Revalidate426::configure(bpd=>$bpd);
  my (@k,@d);
  Revalidate426::iterate_durations("/tmp/ltl-426-fixtures/bin-dpm-full.log", sub { my(undef,$key,$dur)=@_; push @k,$key; push @d,$dur });
  my %st;
  for my $arm (qw(S S2)) {
    my $s = Revalidate426::store_new($arm, bpd=>$bpd);
    $s->add($k[$_], $d[$_]) for 0..$#k;
    my @keys = sort { $a cmp $b } $s->keys;
    my $acc = shift @keys;
    $s->merge($acc,$_,drop_source=>1) for @keys;
    $st{$arm} = [$s, $acc];
  }
  my ($sS,$accS) = @{$st{S}}; my ($sS2,$accS2) = @{$st{S2}};
  my $iS = $sS->{row}{$accS}; my $iS2 = $sS2->{row}{$accS2};
  my $bS = $sS->{bins}[$iS]; my $bS2 = $sS2->{bins}[$iS2];
  my @prob;
  push @prob, "span length S=".scalar(@$bS)." S2=".scalar(@$bS2) if @$bS != @$bS2;
  for my $j (0..$#$bS2) {
    push @prob, "undef at $j" and last if !defined $bS2->[$j];
    push @prob, "elem $j S=".($bS->[$j]//'u')." S2=".$bS2->[$j] and last
      if defined $bS->[$j] && $bS->[$j] != $bS2->[$j];
  }
  my $bc = $sS2->{pbc}[$iS2];
  push @prob, "base $bS2->[0] out of [0,$bc)" if $bS2->[0] < 0 || $bS2->[0] >= $bc;
  push @prob, "span end ".($bS2->[0]+$#$bS2-1)." >= bin_count $bc" if $bS2->[0]+$#$bS2-1 >= $bc;
  push @prob, "leading zero"  if @$bS2 > 1 && $bS2->[1] == 0;
  push @prob, "trailing zero" if @$bS2 > 1 && $bS2->[-1] == 0;
  printf "bpd=%-4d bin_count=%-5d span_len=%-5d base=%-5d RAW-SPAN %s%s\n",
    $bpd, $bc, scalar(@$bS2)-1, $bS2->[0], @prob ? "PROBLEMS: " : "IDENTICAL to S, well-formed", join('; ',@prob);
}
