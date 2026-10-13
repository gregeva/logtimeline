#!/usr/bin/env perl
# #621: the gate series of prototype/342-read-loop-cost-curve/make-probes.pl,
# re-cut for today's loop. The audit's generator also builds a hoist probe
# whose landmarks the hoisting work (#620) has since removed; the gate series
# is the part the remaining bound needs: N always-false boolean tests inserted
# at the every-included-line point, each a mechanical, behaviour-neutral edit.
#
#   usage: make-probes.pl <base ltl> <output dir>
#
# Writes <output dir>/ltl-base (a copy) and ltl-gate-{10,20,40}.
use strict;
use warnings;

my ($base, $out) = @ARGV;
die "usage: make-probes.pl <base ltl> <output dir>\n" unless defined $base && defined $out;
mkdir $out unless -d $out;
open my $fh, '<', $base or die "$base: $!";
my @src = <$fh>;
close $fh;

sub find_one {
    my ($re, $what, $from, $to) = @_;
    $from //= 0; $to //= $#src;
    my @hits = grep { $src[$_] =~ $re } $from .. $to;
    die "make-probes: expected exactly one line matching $what, found " . scalar(@hits) . "\n" unless @hits == 1;
    return $hits[0];
}
my $version_ln  = find_one(qr/^my \$version_number = /, 'the version stamp');
my $sub_ln      = find_one(qr/^sub read_and_process_logs \{/, 'sub read_and_process_logs');
my $next_sub_ln = (grep { $src[$_] =~ /^sub / } $sub_ln + 1 .. $#src)[0];
my $loop_ln     = find_one(qr/^\s*while \(1\) \{/, 'the per-line loop', $sub_ln, $next_sub_ln);
my $close_ln    = find_one(qr/^\s*close \$fh;/, 'close \$fh after the loop', $loop_ln, $next_sub_ln);
my $insert_ln   = find_one(qr/^\s*\$total_lines_included\+\+;/, 'the every-included-line point', $loop_ln, $close_ln);
my ($indent)    = $src[$insert_ln] =~ /^(\s*)/;

sub write_probe {
    my ($name, $lines) = @_;
    my $path = "$out/ltl-$name";
    open my $o, '>', $path or die "$path: $!";
    print {$o} @$lines;
    close $o;
    chmod 0755, $path;
    print "wrote $path\n";
}

write_probe('base', [@src]);
my $gate    = 'if ($probe_false) { $probe_sink++; }';
my $globals = "my (\$probe_false, \$probe_sink) = (0, 0);\n";
for my $n (10, 20, 40) {
    my @p = @src;
    splice @p, $insert_ln + 1, 0, map { "$indent$gate\n" } 1 .. $n;
    splice @p, $version_ln + 1, 0, $globals;
    write_probe("gate-$n", \@p);
}
print "done: 4 binaries\n";
