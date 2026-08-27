use strict; use warnings; use POSIX ();
our $percentile_seed_decades = 5;
do '/tmp/459-subs.pl'; die $@ if $@;
# Does a growth event preserve counts in place (exact) or move them (lossy)?
for my $bpd (4, 16, 53, 115, 616) {
    my $e = counter_entry_new(100, $bpd);
    counter_entry_observe($e, $_) for (60, 80, 100, 150, 300, 900);
    my @before = @{ $e->{bins} };
    my $span_before = $e->{partition}{bin_count};
    # Force one growth by observing above max.
    counter_entry_observe($e, $e->{partition}{max} * 2);
    my @after = @{ $e->{bins} };
    # An exact growth is a pure index shift: the multiset of non-zero runs is
    # preserved and each old bucket lands whole in exactly one new bucket at a
    # constant offset. Find the offset from the first non-zero and check the rest.
    my @nzb = grep { ($before[$_] // 0) > 0 } 0 .. $#before;
    my @nza = grep { ($after[$_]  // 0) > 0 } 0 .. $#after;
    pop @nza while @nza > @nzb;   # drop the newly observed value's bucket
    my $shift = @nzb && @nza ? $nza[0] - $nzb[0] : 0;
    my $exact = (scalar(@nza) == scalar(@nzb)) ? 1 : 0;
    for my $k (0 .. $#nzb) {
        $exact = 0 if !defined $nza[$k] || $nza[$k] - $nzb[$k] != $shift;
        $exact = 0 if !defined $nza[$k] || $after[$nza[$k]] != $before[$nzb[$k]];
    }
    printf("bpd %-4d growth spans %.1f buckets -> %s\n",
           $bpd, $bpd * $percentile_seed_decades / 2,
           $exact ? "EXACT (pure index shift, no count moved)" : "LOSSY (counts remapped by midpoint)");
}
