#!/usr/bin/env perl
#
# dump-entry-src.pl - AC4 of features/615-csv-registry-entry.md: every
# scanned entry's generated source, as format_entry_block_src() returns it,
# under each combination of the compile options that change it. Run against
# the base commit's ltl and the split's, then diff the two dumps.
#
# Usage: perl dump-entry-src.pl LTL_PATH > dump.txt

use strict;
use warnings;

my $ltl_path = shift @ARGV or die "usage: $0 LTL_PATH\n";
my $ltl_src = do { open my $fh, '<', $ltl_path or die "open $ltl_path: $!"; local $/; <$fh> };
$ltl_src =~ s/^## MAIN ##.*\z//ms or die "no ## MAIN ## marker in $ltl_path";
my $driver = do { local $/; <DATA> };
@ARGV = ();
eval "#line 1 \"$ltl_path\"\n$ltl_src\n;\n#line 1 \"615-dump\"\n$driver";
die $@ if $@;
exit 0;

__DATA__
@ARGV = ('--disable-progress', '-ni', $0);   # any readable file: no line is read
{
    open my $saved_out, '>&', \*STDOUT or die;
    open STDOUT, '>', '/dev/null' or die;
    adapt_to_command_line_options( title => 0 );
    adapt_to_terminal_settings();
    build_format_registry();
    open STDOUT, '>&', $saved_out or die;
}
my @combos = (
    [ 'gate closed',            { capture_fraction => 0, capture_ns => 0 } ],
    [ 'gate open',              { capture_fraction => 1, capture_ns => 0 } ],
    [ 'nanosecond',             { capture_fraction => 1, capture_ns => 1 } ],
    [ 'gate open, query string', { capture_fraction => 1, capture_ns => 0, include_query_string => 1 } ],
);
my $n = 0;
for my $name (sort keys %format_registry_spec) {
    my $spec = $format_registry_spec{$name};
    next unless defined $spec->{pattern_src};
    for my $c (@combos) {
        my ($label, $o) = @$c;
        my $opts = { include_query_string => 0, expose_metric => {}, expose_key => {}, %$o };
        my ($aux_decl, $cond_src, $body_src, $aux) = format_entry_block_src($spec, $format_registry_clobbered{$name}, $opts);
        print "===== $name :: $label\n", $aux_decl, "--- cond\n", $cond_src, "\n--- body\n", $body_src, "\n--- aux\n", join(',', @$aux), "\n";
        $n++;
    }
}
print STDERR "entries x combinations dumped: $n\n";
