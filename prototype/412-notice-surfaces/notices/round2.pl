# The round 2 notices: the stage 1 sets, with the parts a notice is told
# apart by (focus, statement, evidence, remedy) set where the first round ran
# them together, and the views a guidance notice offers.

use utf8;

my $sets = do( ( __FILE__ =~ s{[^/]+$}{}r ) . 'sets.pl' ) or die "sets.pl: $@ $!\n";
my %n = %{ $sets->{notice} };

my @views = (
    { label => 'Sort the messages by bimodality', args => '-so bimodality_coef',
      effect => 'this API comes first in the messages table, with any other whose durations split the same way' },
    { label => 'Isolate this API, with its histogram', args => '-i QueryStreamEntries -hg',
      effect => "only this API's lines are kept, and its two populations are drawn as a histogram of durations" },
    { label => 'Continue as planned', args => '',
      effect => 'the charts are drawn with the options given' },
);

$n{bimodal} = {
    category  => 'guidance',
    focus     => 'POST .../QueryStreamEntriesWithData',
    statement => 'has two populations of durations, about 1 s and about 5.5 s',
    evidence  => [ 'bimodality coefficient 0.71; 36 requests, 18 in each' ],
    views     => \@views,
};
$n{stall} = { %{ $n{stall} }, focus => '01:05 to 01:12', statement => 'requests were held and released together at 01:13: a stall' };
$n{timeout_cluster} = { %{ $n{timeout_cluster} }, focus => '1,180 failed requests', statement => 'cluster just above 60 s, a round timeout boundary' };
$n{memory} = {
    category  => 'runtime condition',
    focus     => 'Memory use 3.2 GB',
    statement => 'and still growing: at this rate the read needs about 7.9 GB',
    evidence  => [ '62% of 12.8 GB physical memory; 40% of the input read' ],
    remedy    => 'stop and narrow the read with -st/-et, or group with -g',
};

my %replaced = map { $sets->{notice}{$_} => $n{$_} } qw(bimodal stall timeout_cluster);
my @heavy   = map { $replaced{$_} // $_ } @{ $sets->{heavy} };
my @typical = map { $replaced{$_} // $_ } @{ $sets->{typical} };

return {
    minimal => $sets->{minimal},
    typical => \@typical,
    options => $sets->{options},
    heavy   => \@heavy,
    notice  => \%n,
    views   => \@views,
};
