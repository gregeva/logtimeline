# The named inputs of round 4: the use cases as data any component takes
# (contract § Components). Built on the stage 1 sets (sets.pl); each input is
# what a producer would hand the framework: the notices, and for a question
# its category, question, buttons and options.
#
# A button: label, the choice letter the caller passes (underlined in the
# label, accepted in either case) and its role, which fixes its position:
# 'stop' leftmost, 'more' between, 'default' rightmost and highlighted.
# An option: its parts under the consumer's headings (D8), the command options
# that apply it, and its effect in one line.

use utf8;

my $sets = do( ( __FILE__ =~ s{[^/]+$}{}r ) . 'sets.pl' ) or die "sets.pl: $@ $!\n";
my %n = %{ $sets->{notice} };

# The options of the bimodality notice (D8: what, how, why; the why from the
# producer as part of the notice).
my @options = (
    { parts => [ 'Sort the messages by bimodality', '-so bimodality_coef', 'other APIs whose durations split the same way show up beside it' ],
      args  => '-so bimodality_coef',
      effect => 'this API comes first in the messages table, with any other whose durations split the same way' },
    { parts => [ 'Isolate this API, with its histogram', '-i GetDateAndTime -hg', 'its percentiles blend the two populations and describe neither' ],
      args  => '-i GetDateAndTime -hg',
      effect => "only this API's lines are kept, and its two populations are drawn as a histogram of durations" },
    { parts => [ 'Continue as planned', '', 'the run as it was asked for' ],
      args  => '',
      effect => 'the charts are drawn with the options given' },
);

# A guidance notice whose detail is tall: the API's duration histogram as ltl
# renders it, with its percentile legend (notices/histogram.pl, captured from
# a real run), above its options. The browser is sized for it before it is
# drawn.
my $histogram = do( ( __FILE__ =~ s{[^/]+$}{}r ) . 'histogram.pl' ) or die "histogram.pl: $@ $!\n";

$n{bimodal} = {
    category  => 'guidance',
    focus     => 'POST .../Services/GetDateAndTime',
    statement => 'has two populations of durations, about 1 ms and about 60 ms',
    evidence  => ['bimodality coefficient 0.71; 213,951 requests, P50 59 ms, P99.9 229 ms'],
    question  => 'Look at the options on offer?',
    options   => \@options,
    detail    => $histogram,
};
$n{stall}           = { %{ $n{stall} }, focus => '01:05 to 01:12', statement => 'requests were held and released together at 01:13: a stall' };
$n{timeout_cluster} = { %{ $n{timeout_cluster} }, focus => '1,180 failed requests', statement => 'cluster just above 60 s, a round timeout boundary' };
$n{memory} = {
    category  => 'runtime condition',
    focus     => 'Memory use 3.2 GB',
    statement => 'and still growing: at this rate the read needs about 7.9 GB',
    evidence  => ['62% of 12.8 GB physical memory; 40% of the input read'],
    remedy    => 'stop and narrow the read with -st/-et, or group with -g',
};

my %replaced = map { $sets->{notice}{$_} => $n{$_} } qw(bimodal stall timeout_cluster);
my @heavy   = map { $replaced{$_} // $_ } @{ $sets->{heavy} };
my @typical = map { $replaced{$_} // $_ } @{ $sets->{typical} };

return {
    # the notices known once the data work is done, nothing to answer
    deprecation => { notices => [ $n{deprecation} ] },
    typical     => { notices => \@typical },
    heavy       => { notices => \@heavy },

    # a question before the read: the option notices, continue or stop
    preread => {
        category => 'your options',
        notices  => $sets->{options},
        question => 'Continue with these options?',
        buttons  => [
            { label => 'Stop and correct them', key => 's', role => 'stop' },
            { label => 'Continue',              key => 'c', role => 'default' },
        ],
    },
    # a question during the read: memory growing
    memory => {
        category => 'runtime condition',
        notices  => [ $n{memory} ],
        question => 'Continue reading?',
        buttons  => [
            { label => 'Stop here',        key => 's', role => 'stop' },
            { label => 'Continue reading', key => 'c', role => 'default' },
        ],
    },
    # a question once a pattern is found: a choice with a second stage
    pattern => {
        category => 'guidance',
        notices  => [ $n{bimodal} ],
        question => $n{bimodal}{question},
        buttons  => [
            { label => 'Look at the options', key => 'l', role => 'more' },
            { label => 'Continue as planned', key => 'c', role => 'default' },
        ],
        options        => \@options,
        option_default => $#options,
    },
    notice => \%n,
};
