#!/usr/bin/env perl
# check-accounting.pl - consolidation's core mandate, checked over
# -V message-grouping captures for tests/validate-message-grouping.sh: merging
# similar messages while every occurrence and its data is accounted for
# exactly once (features/619-per-run-key-cut.md § 6, AC18 to AC21; the records
# read are the `accounting` and `cluster-membership` sub-sections, contract in
# § 7).
#
#   across-runs   --grouped G --ungrouped U
#       AC18. The `reported` stage records of the grouped and the ungrouped run
#       carry the same categories and grouping keys, with equal occurrences,
#       duration count, duration total, bytes count and bytes total; the
#       grouped run's occurrences sum to its `lines_included` (G carries
#       -V filter-summary).
#   per-pass      --grouped G [--min-checkpoints N]
#       AC19. Every `-before` stage record has its `-after` record and the five
#       totals are equal; at least one final-pass pair, and at least N
#       checkpoint pairs (default 1), are present.
#   one-row       --grouped G --ungrouped U
#       AC20. No key is a member of two clusters, and no member is also a row
#       of its own; the members together with the rows that are not clusters
#       are exactly the ungrouped run's rows.
#   durations-once --grouped G --ungrouped U --model raw|bin
#       AC21. Under raw, every grouped row retains as many durations as its
#       duration count; under bin, every row reports `-` retained. Every
#       cluster's duration count equals the sum of its members' duration
#       counts in the ungrouped run.
#
# A capture without the sub-section read, or a selection that reads no record,
# is a failure (tests/HARNESS-DESIGN.md section Harnesses must fail on missing
# anchors). Exit 0 on pass; 1 with a diagnostic on fail; 2 on bad arguments.
use strict;
use warnings;
use Getopt::Long;

my @FIVE = qw(occurrences duration_count duration_total bytes_count bytes_total);

my $mode = shift @ARGV // usage();
my %o = ( 'min-checkpoints' => 1 );
GetOptions(\%o, 'grouped=s', 'ungrouped=s', 'min-checkpoints=i', 'model=s') or usage();
usage() unless defined $o{grouped};

sub usage { print STDERR "usage: check-accounting.pl across-runs|per-pass|one-row|durations-once --grouped G [--ungrouped U] ...\n"; exit 2 }
sub fail { print "$_\n" for @_; exit 1 }

# The lines between a sub-section's markers; a missing start or end marker is
# a failure, never an empty section.
sub subsection {
    my ($path, $name) = @_;
    open my $fh, '<', $path or fail("cannot open $path: $!");
    my (@body, $in, $closed);
    while (my $line = <$fh>) {
        chomp $line;
        if ($line eq "=== message-grouping / $name ===") { $in = 1; next }
        if ($line eq "=== END message-grouping / $name ===") { $closed = 1 if $in; last }
        push @body, $line if $in;
    }
    close $fh;
    fail("no '=== message-grouping / $name ===' sub-section in $path") unless $in;
    fail("'=== message-grouping / $name ===' is not closed in $path") unless $closed;
    return @body;
}

# The accounting records as hashes keyed by the header's field names. The key
# is the last field, so the split stops before it.
sub accounting {
    my ($path) = @_;
    my ($header, @lines) = subsection($path, 'accounting');
    fail("the accounting sub-section of $path has no header") unless defined $header;
    my @fields = split /\t/, $header;
    fail("accounting header of $path does not end in 'key': $header") unless $fields[-1] eq 'key';
    my @records;
    for my $line (grep { length } @lines) {
        my @v = split /\t/, $line, scalar @fields;
        fail("accounting record of $path has " . scalar(@v) . " fields, header has " . scalar(@fields) . ": $line")
            unless @v == @fields;
        my %r; @r{@fields} = @v;
        push @records, \%r;
    }
    return @records;
}

sub same_value {
    my ($a, $b) = @_;
    my $scale = abs($a) > abs($b) ? abs($a) : abs($b);
    $scale = 1 if $scale < 1;
    return abs($a - $b) <= 1e-9 * $scale;
}

sub reported_stages {
    my %by;
    for my $r (@_) {
        next unless $r->{kind} eq 'stage' && $r->{stage} eq 'reported';
        $by{"$r->{category}|$r->{grouping_key}"} = $r;
    }
    return %by;
}

sub rows { my %by; for my $r (@_) { $by{"$r->{category}\x1f$r->{key}"} = $r if $r->{kind} eq 'row' } return %by }

# Cluster (category \x1f canonical) to its member keys.
sub membership {
    my ($path) = @_;
    my (%clusters, $current);
    for my $line (subsection($path, 'cluster-membership')) {
        if ($line =~ /^  cluster: (.*)$/s) { $current = $1; $clusters{$current} = [] }
        elsif ($line =~ /^    member: (.*)$/s) {
            fail("member line before any cluster line in $path: $line") unless defined $current;
            push @{ $clusters{$current} }, $1;
        }
    }
    return %clusters;
}

my @g = accounting($o{grouped});

if ($mode eq 'across-runs') {
    usage() unless defined $o{ungrouped};
    my %gs = reported_stages(@g);
    my %us = reported_stages(accounting($o{ungrouped}));
    fail("no reported stage record in $o{ungrouped}") unless %us;
    my @bad;
    for my $k (sort keys %{ { %gs, %us } }) {
        if (!$gs{$k} || !$us{$k}) { push @bad, "$k: present in " . ($gs{$k} ? 'grouped' : 'ungrouped') . ' run only'; next }
        for my $f (@FIVE) {
            push @bad, "$k: $f grouped $gs{$k}{$f}, ungrouped $us{$k}{$f}" unless same_value($gs{$k}{$f}, $us{$k}{$f});
        }
    }
    my $occ = 0; $occ += $_->{occurrences} for values %gs;
    open my $fh, '<', $o{grouped} or fail("cannot open $o{grouped}: $!");
    my ($included) = map { /^lines_included: (\d+)$/ ? $1 : () } <$fh>;
    close $fh;
    fail("no 'lines_included:' in $o{grouped} (run with -V filter-summary)") unless defined $included;
    push @bad, "grouped occurrences $occ, lines_included $included" unless $occ == $included;
    fail(@bad) if @bad;
    print "groups=" . scalar(keys %gs) . " occurrences=$occ\n";
}
elsif ($mode eq 'per-pass') {
    my (%pair, @bad);
    for my $r (grep { $_->{kind} eq 'stage' } @g) {
        next unless $r->{stage} =~ /^(.*)-(before|after)$/;
        $pair{"$1 $r->{category}|$r->{grouping_key}"}{$2} = $r;
    }
    my ($checkpoints, $final) = (0, 0);
    for my $k (sort keys %pair) {
        my $p = $pair{$k};
        if (!$p->{before} || !$p->{after}) { push @bad, "$k: " . ($p->{before} ? 'no -after' : 'no -before') . ' record'; next }
        $k =~ /^checkpoint-/ ? $checkpoints++ : $final++;
        for my $f (@FIVE) {
            push @bad, "$k: $f before $p->{before}{$f}, after $p->{after}{$f}" unless same_value($p->{before}{$f}, $p->{after}{$f});
        }
    }
    push @bad, "only $checkpoints checkpoint pairs, at least $o{'min-checkpoints'} expected" if $checkpoints < $o{'min-checkpoints'};
    push @bad, "no final-pass pair" unless $final;
    fail(@bad) if @bad;
    print "checkpoint_pairs=$checkpoints final_pass_pairs=$final\n";
}
elsif ($mode eq 'one-row') {
    usage() unless defined $o{ungrouped};
    my %clusters = membership($o{grouped});
    my %grows = rows(@g);
    my %urows = rows(accounting($o{ungrouped}));
    fail("no row record in $o{ungrouped}") unless %urows;
    my (%owner, @bad);
    for my $c (sort keys %clusters) {
        fail("cluster '$c' of the membership is not a row of $o{grouped}") unless $grows{$c};
        my ($category) = split /\x1f/, $c, 2;
        push @{ $owner{"$category\x1f$_"} }, $c for @{ $clusters{$c} };
    }
    for my $k (sort keys %owner) {
        push @bad, "key in " . scalar(@{ $owner{$k} }) . " clusters: $k" if @{ $owner{$k} } > 1;
        push @bad, "key is a member and a row of its own: $k" if $grows{$k} && !$clusters{$k};
    }
    my %covered = %owner;
    $covered{$_} = 1 for grep { !$clusters{$_} } keys %grows;
    push @bad, "key of the ungrouped run in no row: $_" for grep { !$covered{$_} } sort keys %urows;
    push @bad, "key the ungrouped run does not hold: $_" for grep { !$urows{$_} } sort keys %covered;
    fail(@bad[0 .. ($#bad < 19 ? $#bad : 19)], @bad > 20 ? ("... " . scalar(@bad) . " in all") : ()) if @bad;
    print "clusters=" . scalar(keys %clusters) . " members=" . scalar(keys %owner) . " keys=" . scalar(keys %urows) . "\n";
}
elsif ($mode eq 'durations-once') {
    usage() unless defined $o{ungrouped} && defined $o{model} && $o{model} =~ /^(raw|bin)$/;
    my %clusters = membership($o{grouped});
    my %grows = rows(@g);
    my %urows = rows(accounting($o{ungrouped}));
    fail("no row record in $o{grouped}") unless %grows;
    my @bad;
    for my $k (sort keys %grows) {
        my $r = $grows{$k};
        if ($o{model} eq 'raw') {
            push @bad, "row retains $r->{durations_retained} durations, duration count $r->{duration_count}: $k"
                unless $r->{durations_retained} ne '-' && $r->{durations_retained} == $r->{duration_count};
        } else {
            push @bad, "row under bin reports '$r->{durations_retained}' retained, '-' expected: $k"
                unless $r->{durations_retained} eq '-';
        }
    }
    fail("no cluster in the membership of $o{grouped}") unless %clusters;
    for my $c (sort keys %clusters) {
        my ($category) = split /\x1f/, $c, 2;
        my $sum = 0;
        for my $m (@{ $clusters{$c} }) {
            my $u = $urows{"$category\x1f$m"};
            if (!$u) { push @bad, "member is not a row of the ungrouped run: $m"; next }
            $sum += $u->{duration_count};
        }
        push @bad, "cluster duration count $grows{$c}{duration_count}, its members' $sum: $c"
            unless $grows{$c} && $grows{$c}{duration_count} == $sum;
    }
    fail(@bad[0 .. ($#bad < 19 ? $#bad : 19)], @bad > 20 ? ("... " . scalar(@bad) . " in all") : ()) if @bad;
    print "rows=" . scalar(keys %grows) . " clusters=" . scalar(keys %clusters) . "\n";
}
else { usage() }
