{ require Time::HiRes;
  my ($cat) = sort { keys(%{$log_messages{$b}}) <=> keys(%{$log_messages{$a}}) } keys %log_messages;
  my $h = $log_messages{$cat}; my @ks = keys %$h; my $best;
  for (1..5) { my $t0 = Time::HiRes::time(); my $s = 0; for my $k (@ks) { $s += $h->{$k}{occurrences} // 0 } my $d = Time::HiRes::time() - $t0; $best = $d if !defined $best || $d < $best }
  printf STDERR "### L0 %.4f keys=%d\n", $best, scalar @ks;
}
