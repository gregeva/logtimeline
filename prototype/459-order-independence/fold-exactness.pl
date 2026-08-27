use strict; use warnings; use POSIX ();
our $percentile_seed_decades = 5;
do '/tmp/459-subs.pl'; die $@ if $@;

# Grow by doubling the log-span while holding the bucket COUNT fixed, i.e.
# letting buckets-per-decade halve. Each new bucket should be exactly two old
# buckets, so counts fold 2-into-1 with nothing moved.
sub grow_by_fold {
    my ($e) = @_;
    my $p = $e->{partition};
    my $B = $p->{bin_count};
    my @old = @{ $e->{bins} };
    # new span = old span squared in ratio terms (log-span doubled), min fixed
    my $new_max = $p->{min} * (($p->{max} / $p->{min}) ** 2);
    my @new;
    for my $i (0 .. $B - 1) { $new[$i] = 0 }
    for my $i (0 .. $B - 1) { $new[int($i / 2)] += ($old[$i] // 0) }
    $p->{max} = $new_max;
    $p->{decades} = log($new_max / $p->{min}) / log(10);
    $p->{bpd} = $B / $p->{decades};
    $p->{log_ratio} = log($new_max / $p->{min});
    $e->{bins} = \@new;
}

for my $bpd (53, 616) {
    my $e = counter_entry_new(100, $bpd);
    counter_entry_observe($e, 10 ** (rand() * 3 + 1)) for 1 .. 5000;
    my @q = (0.01, 0.10, 0.50, 0.90, 0.99);
    my @before = map { (percentile($e, $_))[0] } @q;
    my $bins_before = $e->{partition}{bin_count};
    my $mass_before = 0; $mass_before += $_ // 0 for @{ $e->{bins} };

    grow_by_fold($e);
    grow_by_fold($e);
    my @after = map { (percentile($e, $_))[0] } @q;
    my $mass_after = 0; $mass_after += $_ // 0 for @{ $e->{bins} };

    my $bw = 10 ** (1 / $bpd) - 1;
    printf("start bpd %-4d  buckets %d -> %d (unchanged)  mass %d -> %d\n",
           $bpd, $bins_before, $e->{partition}{bin_count}, $mass_before, $mass_after);
    printf("   effective buckets/decade now %.1f\n", $e->{partition}{bpd});
    for my $k (0 .. $#q) {
        printf("   q%-5s %.6f -> %.6f   moved %.4f original bucket widths\n",
               $q[$k], $before[$k], $after[$k],
               abs($after[$k] - $before[$k]) / $before[$k] / $bw);
    }
}
