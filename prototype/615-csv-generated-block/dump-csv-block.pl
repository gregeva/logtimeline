#!/usr/bin/env perl
#
# dump-csv-block.pl - AC5 of features/615-csv-registry-entry.md: the source of
# the CSV block ltl generates for one header, as csv_block_src() returns it,
# so the column positions compiled into it can be read. The header is the
# file's first line, and every -udm and -ucm option given is applied as a run
# would apply it.
#
# Usage: perl dump-csv-block.pl LTL_PATH CSV_FILE LAYOUT [ltl options...]
#        LAYOUT: csv | csv_ddmm | csv_epoch

use strict;
use warnings;

my ($ltl_path, $csv_file, $layout, @opts) = @ARGV;
die "usage: $0 LTL_PATH CSV_FILE csv|csv_ddmm|csv_epoch [ltl options...]\n" unless defined $layout;
my $ltl_src = do { open my $fh, '<', $ltl_path or die "open $ltl_path: $!"; local $/; <$fh> };
$ltl_src =~ s/^## MAIN ##.*\z//ms or die "no ## MAIN ## marker in $ltl_path";
my $header = do { open my $fh, '<', $csv_file or die "open $csv_file: $!"; my $l = <$fh>; $l =~ s/[\r\n]+$//; $l };
my $driver = do { local $/; <DATA> };
@ARGV = ('--disable-progress', '-ni', @opts, $csv_file);
our ($HEADER, $LAYOUT) = ($header, $layout);
eval "#line 1 \"$ltl_path\"\n$ltl_src\n;\n#line 1 \"615-dump-csv-block\"\n$driver";
die $@ if $@;
exit 0;

__DATA__
{
    open my $saved_out, '>&', \*STDOUT or die;
    open STDOUT, '>', '/dev/null' or die;
    adapt_to_command_line_options( title => 0 );
    adapt_to_terminal_settings();
    build_format_registry();
    open STDOUT, '>&', $saved_out or die;
}
detect_and_parse_csv_header($main::HEADER) or die "not a CSV header: $main::HEADER\n";
my $shape = csv_block_shape($main::LAYOUT);
print "signature: $shape->{sig}\n", csv_block_src($shape), "\n";
