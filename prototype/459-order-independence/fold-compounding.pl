use strict; use warnings; use POSIX ();
our $percentile_seed_decades = 5;
do '/tmp/459-subs.pl'; die $@ if $@;
sub grow_by_fold {
    my ($e) = @_; my $p = $e->{partition}; my $B = $p->{bin_count};
    my @old = @{ $e->{bins} }; my @new = (0) x $B;
    $new[int($_ / 2)] += ($old[$_] // 0) for 0 .. $B - 1;
    $p->{max} = $p->{min} * (($p->{max} / $p->{min}) ** 2);
    $p->{decades} = log($p->{max} / $p->{min}) / log(10);
    $p->{bpd} = $B / $p->{decades};
    $p->{log_ratio} = log($p->{max} / $p->{min});
    $e->{bins} = \@new;
}
srand(42);
my @raw = map { 10 ** (rand() * 3 + 1) } 1 .. 20000;
my @sorted = sort { $a <=> $b } @raw;
sub exact { my $q = shift; return $sorted[ POSIX::ceil($q * scalar @sorted) - 1 ]; }
my @q = (0.01, 0.10, 0.50, 0.90, 0.99);
my $e = counter_entry_new($raw[0], 616);
counter_entry_observe($e, $_) for @raw;
printf("%-7s %-10s %-12s %s\n", "folds", "buckets", "buckets/dec", "worst error vs raw data, in CURRENT bucket widths");
for my $f (0 .. 5) {
    grow_by_fold($e) if $f;
    my $p = $e->{partition};
    my $bw = ($p->{max} / $p->{min}) ** (1 / $p->{bin_count}) - 1;
    my $worst = 0;
    for my $qq (@q) {
        my $d = abs((percentile($e, $qq))[0] - exact($qq)) / exact($qq) / $bw;
        $worst = $d if $d > $worst;
    }
    printf("%-7d %-10d %-12.1f %.4f\n", $f, $p->{bin_count}, $p->{bpd}, $worst);
}
