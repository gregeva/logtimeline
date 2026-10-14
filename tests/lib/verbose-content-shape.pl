#!/usr/bin/env perl
# verbose-content-shape.pl — check -V output against the content shape every
# section follows (tests/HARNESS-DESIGN.md § Content shape).
#
# Usage: perl verbose-content-shape.pl --registered a,b,c capture1 [capture2 ...]
#
# Reads every section of every capture and prints one line per departure:
#   SHAPE<TAB><section><TAB><rule><TAB><line>
# and one line per registered section no capture emitted:
#   UNEMITTED<TAB><section>
# then a summary line "SECTIONS<TAB><n emitted>" and "LINES<TAB><n read>".
# Exits 0 when nothing departs, 1 otherwise, 2 on a usage error.
#
# The rules:
#   - a line inside a section is a delimiter, a blank line, a bulk record
#     (it carries a tab), or "<key>: <value>" at any indentation;
#   - a key is snake_case: [a-z][a-z0-9_]*;
#   - a key with nothing after its colon heads the more-indented facts that
#     follow it, and only then;
#   - an absent value is written "-": never "(not set)", "n/a", "(none)",
#     "(empty)", "undef" or nothing, whether as a value or after key= in a
#     "<entity>: <name> key=value ..." line.
use strict;
use warnings;

my ($registered, @files);
while (@ARGV) {
    my $a = shift @ARGV;
    if    ($a eq '--registered') { $registered = shift @ARGV; }
    elsif ($a =~ /^-/)           { print STDERR "unknown option $a\n"; exit 2; }
    else                         { push @files, $a; }
}
if (!defined $registered || !@files) {
    print STDERR "usage: verbose-content-shape.pl --registered a,b,c capture...\n";
    exit 2;
}

my %absent_word = map { $_ => 1 } ('(not set)', 'n/a', 'N/A', '(none)', '(empty)', 'undef');
my (%emitted, @departures);
my $lines_read = 0;

for my $file (@files) {
    open my $fh, '<', $file or die "cannot read $file: $!\n";
    my @lines = <$fh>;
    close $fh;
    chomp @lines;
    my @open;    # the sections open at this line, innermost last
    for my $i (0 .. $#lines) {
        my $line = $lines[$i];
        if ($line =~ /^=== END (.+) ===$/) { pop @open; next; }
        if ($line =~ /^=== (.+) ===$/) {
            my $name = $1;
            push @open, $name;
            $emitted{$name} = 1 unless $name =~ m{ / };
            next;
        }
        next unless @open;
        $lines_read++;
        my $section = $open[-1];
        next if $line =~ /^\s*$/;
        next if $line =~ /\t/;
        my $depart = sub { push @departures, join("\t", 'SHAPE', $section, $_[0], $line); };
        my ($indent, $key, $value) = $line =~ /^( *)([^ :][^:]*?):(?: (.*))?$/;
        if (!defined $key) { $depart->('not a key: value line'); next; }
        if ($key !~ /^[a-z][a-z0-9_]*$/) { $depart->('key not snake_case'); next; }
        if (!defined $value || $value eq '') {
            my $next = $i < $#lines ? $lines[$i + 1] : '';
            my ($next_indent) = $next =~ /^( *)\S/;
            $depart->('absent value not written -') unless defined $next_indent && length($next_indent) > length($indent) && $next !~ /^===/;
            next;
        }
        if ($absent_word{$value}) { $depart->('absent value not written -'); next; }
        while ($value =~ /(?:^| )([a-z][a-z0-9_]*)=(\S*)/g) {
            if ($2 eq '' || $absent_word{$2}) { $depart->("absent value not written - ($1=)"); last; }
        }
    }
}

print "$_\n" for @departures;
my @unemitted = grep { !$emitted{$_} } split /,/, $registered;
print "UNEMITTED\t$_\n" for @unemitted;
print "SECTIONS\t" . scalar(keys %emitted) . "\n";
print "LINES\t$lines_read\n";
exit((@departures || @unemitted) ? 1 : 0);
