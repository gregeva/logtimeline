# Clamp MAGNITUDE probe: when the clamp fires, how far outside [min,max] was
# the raw value? Reported as the multiplicative gap (raw/min for low clamps,
# raw/max for high clamps). This separates "the clamp is bounded by the bin
# geometry" from "the clamp is repairing an arbitrary seed artefact".
use strict; use warnings;
use FindBin; require "$FindBin::Bin/426-revalidate-lib.pm";
my ($file,$bs,$bpd)=@ARGV;
Revalidate426::configure(bpd=>$bpd);
my @bk; my %raw; my $seq=0;
Revalidate426::iterate_durations($file, sub{ my(undef,undef,$d)=@_;
  my $k=sprintf("b%05d",int($seq++/$bs)); push @bk,$k unless exists $raw{$k};
  push @{$raw{$k}},$d; });
my @Q=(0.01,0.05,0.10,0.25,0.50,0.75,0.90,0.95,0.99,0.999,0.9999);
printf("file=%s bs=%d bpd=%d buckets=%d  bin_width=%.6f\n",$file,$bs,$bpd,scalar @bk,10**(1/$bpd));
printf("%-4s %14s %14s %14s %14s\n",'arm','lo_max_gap','lo_med_gap','hi_max_gap','hi_med_gap');
for my $arm (qw(T S G)){
  my $st=Revalidate426::store_new($arm,bpd=>$bpd);
  for my $k (@bk){ $st->add($k,$_) for @{$raw{$k}} }
  my (@lo,@hi);
  for my $k (@bk){
    my @s=sort{$a<=>$b}@{$raw{$k}}; my ($mn,$mx)=($s[0],$s[-1]);
    for my $q (@Q){ my ($v)=$st->percentile($k,$q,'int'); next unless defined $v;
      push @lo, $mn/$v if $v<$mn; push @hi, $v/$mx if $v>$mx; }
  }
  my $med=sub{ my @a=sort{$a<=>$b}@_; @a?$a[int($#a/2)]:0 };
  my $mx_=sub{ my $m=0; for(@_){$m=$_ if $_>$m} $m };
  printf("%-4s %14.6f %14.6f %14.6f %14.6f\n",$arm,
    $mx_->(@lo),$med->(@lo),$mx_->(@hi),$med->(@hi));
}
