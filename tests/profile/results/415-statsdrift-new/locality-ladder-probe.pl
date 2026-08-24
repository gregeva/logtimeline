{ require Time::HiRes; require Scalar::Util;
  my ($cat) = sort { keys(%{$log_messages{$b}}) <=> keys(%{$log_messages{$a}}) } keys %log_messages;
  my $h = $log_messages{$cat}; my @ks = keys %$h;
  my @addr = sort { $a <=> $b } map { Scalar::Util::refaddr($h->{$_}) } @ks;
  my %pg; $pg{int($_ / 16384)}++ for @addr;
  printf STDERR "### LOCALITY cat=%s keys=%d entry_pages=%d span_MB=%.1f\n", $cat, scalar @ks, scalar keys %pg, ($addr[-1]-$addr[0])/1e6;
  my $t = sub { my ($hh) = @_; my $best; for (1..5) { my $t0 = Time::HiRes::time(); my $s = 0; for my $k (@ks) { $s += $hh->{$k}{occurrences} // 0 } my $d = Time::HiRes::time() - $t0; $best = $d if !defined $best || $d < $best } $best };
  my $w = sub { my ($hh) = @_; my $best; for (1..5) { my $t0 = Time::HiRes::time(); my $s = 0; for my $k (keys %$hh) { my $e = $hh->{$k}; $s += scalar @{ $e->{durations} // [] } } my $d = Time::HiRes::time() - $t0; $best = $d if !defined $best || $d < $best } $best };
  printf STDERR "### L0 as-built        lookup=%.4f walk=%.4f\n", $t->($h), $w->($h);
  my %f1 = %$h;                                   printf STDERR "### L1 fresh-HEs       lookup=%.4f walk=%.4f\n", $t->(\%f1), $w->(\%f1);
  my %f2 = map { $_ => { %{ $h->{$_} } } } @ks;   printf STDERR "### L2 fresh-HEs+entry lookup=%.4f walk=%.4f\n", $t->(\%f2), $w->(\%f2);
  my %f3 = map { my $k = "$_"; ($k => { %{ $h->{$_} } }) } @ks; printf STDERR "### L3 fresh-keys+all  lookup=%.4f walk=%.4f\n", $t->(\%f3), $w->(\%f3);
}
