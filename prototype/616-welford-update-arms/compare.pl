#!/usr/bin/env perl
# #616 D12: compare each probe's CSVs with the base probe's, cell by cell.
#
# Rows are matched by position (the probes differ only in arithmetic, so the
# row order is the base's unless a ranking statistic moved, which is itself
# reported as a key mismatch). For every column that differs anywhere, prints
# the number of moved cells and the largest relative difference.
#
#   usage: compare.pl <out dir from prove.sh>
use strict;
use warnings;

my $root = shift or die "usage: compare.pl <out dir>\n";
use Text::CSV;
my $csv = Text::CSV->new({ binary => 1 });
sub read_csv {
    my ($f) = @_;
    open my $fh, '<', $f or return;
    my @rows;
    while (my $row = $csv->getline($fh)) { push @rows, $row }
    close $fh;
    return \@rows;
}
for my $sel (sort grep { -d } glob "$root/*") {
    my $label = (split m{/}, $sel)[-1];
    for my $kind (qw(MESSAGES STATS)) {
        my $base = read_csv("$sel/base/$kind.csv") or next;
        my @hdr = @{ $base->[0] };
        for my $cdir (sort grep { -d && !m{/base$} } glob "$sel/*") {
            my $c = (split m{/}, $cdir)[-1];
            my $rows = read_csv("$cdir/$kind.csv");
            unless ($rows) { print "$label $kind $c: no file\n"; next }
            if (@$rows != @$base) { print "$label $kind $c: row count ", scalar(@$rows), " vs base ", scalar(@$base), "\n"; next }
            my (%moved, %maxrel, $cells, $diffs);
            for my $r (1 .. $#$base) {
                for my $k (0 .. $#hdr) {
                    my ($x, $y) = ($base->[$r][$k] // '', $rows->[$r][$k] // '');
                    $cells++;
                    next if $x eq $y;
                    $diffs++;
                    $moved{$hdr[$k]}++;
                    if ($x =~ /^-?[\d.]+(?:e[-+]?\d+)?$/i && $y =~ /^-?[\d.]+(?:e[-+]?\d+)?$/i) {
                        my $rel = abs($x - $y) / (abs($x) > 0 ? abs($x) : 1);
                        $maxrel{$hdr[$k]} = $rel if !defined $maxrel{$hdr[$k]} || $rel > $maxrel{$hdr[$k]};
                    } else {
                        $maxrel{$hdr[$k]} = 'text';
                    }
                }
            }
            printf "%s %s %s: %d rows, %d cells, %d moved%s\n", $label, $kind, $c, $#$base, $cells, $diffs // 0,
                $diffs ? '' : ' (byte-identical)';
            for my $col (sort { $moved{$b} <=> $moved{$a} || $a cmp $b } keys %moved) {
                my $m = $maxrel{$col};
                printf "    %-28s %6d cells, max rel %s\n", $col, $moved{$col}, ($m eq 'text' ? 'text' : sprintf('%.3e', $m));
            }
        }
    }
}
