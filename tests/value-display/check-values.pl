#!/usr/bin/env perl
# check-values.pl - token checks for tests/validate-value-display.sh over an
# ANSI-stripped capture of ltl's rendered output.
#
#   tokens   --file F --line REGEX --each REGEX [--min N] [--after LABEL]
#       Every number-with-unit token on the lines matching --line matches
#       --each (anchored); at least --min tokens (default 1) are read. With
#       --after, only the token that directly follows each LABEL: is read
#       (the percentile legend: --after 'P\d+(?:\.\d+)?').
#   absent   --file F --regex REGEX
#       No line of the capture matches REGEX.
#   same     --file F --line REGEX
#       Every number-with-unit token on the matching lines is one string.
#   column   --file F --column ID --kind duration|bytes-si|bytes-iec|count --lib L
#            [--source-unit U]
#       Every timeline row's cell of column ID, read through the layout
#       engine's offsets (L is tests/lib/rendered-output.pl; the capture
#       carries the --debug-layout table), is one whole value: a number and a
#       complete unit spelling of one tier of its kind, never cut. Down the
#       column every value carries one tier and one fit; a long-tier word is
#       never tight. With --source-unit, a duration shown in that unit carries
#       no decimals. Prints `tiers=<tier>` for the column on success.
#
# A token is a number, optionally with a decimal part, directly followed by
# letters: `1.5k`, `0ms`, `2s`, `999B`. A selection that reads no token, or
# matches no line, is a failure (tests/HARNESS-DESIGN.md section Harnesses
# must fail on missing anchors). Exit 0 on pass; 1 with a diagnostic on fail.
use strict;
use warnings;
use Getopt::Long;
binmode STDOUT, ':encoding(UTF-8)';

my $mode = shift @ARGV // die "usage: check-values.pl tokens|absent|same --file F ...\n";
my %o = ( min => 1 );
GetOptions( \%o, 'file=s', 'line=s', 'each=s', 'min=i', 'after=s', 'regex=s', 'column=s', 'kind=s', 'lib=s', 'source-unit=s' )
    or die "check-values.pl: bad arguments\n";
die "check-values.pl: --file is required\n" unless defined $o{file};
open my $fh, '<:encoding(UTF-8)', $o{file} or die "cannot open $o{file}: $!\n";
my @lines = <$fh>;
close $fh;
s/\e\[[0-9;]*m//g for @lines;

my $TOKEN = qr/(?<![\w.])(\d+(?:\.\d+)?[A-Za-z]+)(?![\w.])/;

sub tokens_of {
    my ($line) = @_;
    if ( defined $o{after} ) {
        my @t;
        push @t, $1 while $line =~ /(?:^|\s)$o{after}:\s*(\d+(?:\.\d+)?[A-Za-z]+)(?![\w.])/g;
        return @t;
    }
    my @t;
    push @t, $1 while $line =~ /$TOKEN/g;
    return @t;
}

sub selected {
    my @hit = grep { /$o{line}/ } @lines;
    if ( !@hit ) {
        print "FAIL: no line of $o{file} matches /$o{line}/\n";
        exit 1;
    }
    return @hit;
}

if ( $mode eq 'tokens' ) {
    die "tokens needs --line and --each\n" unless defined $o{line} && defined $o{each};
    my ( $read, $bad ) = ( 0, 0 );
    for my $line ( selected() ) {
        for my $t ( tokens_of($line) ) {
            $read++;
            next if $t =~ /^(?:$o{each})$/;
            $bad++;
            ( my $show = $line ) =~ s/\s+$//;
            print "FAIL: token '$t' does not match /^(?:$o{each})\$/\n      line: $show\n";
        }
    }
    if ( $read < $o{min} ) {
        print "FAIL: read $read token(s) on lines matching /$o{line}/, expected at least $o{min}\n";
        exit 1;
    }
    exit( $bad ? 1 : 0 );
}
elsif ( $mode eq 'absent' ) {
    die "absent needs --regex\n" unless defined $o{regex};
    my @hit = grep { /$o{regex}/ } @lines;
    for my $line (@hit) { ( my $show = $line ) =~ s/\s+$//; print "FAIL: /$o{regex}/ found\n      line: $show\n" }
    exit( @hit ? 1 : 0 );
}
elsif ( $mode eq 'same' ) {
    die "same needs --line\n" unless defined $o{line};
    my %seen;
    $seen{$_}++ for map { tokens_of($_) } selected();
    if ( keys %seen != 1 ) {
        print "FAIL: expected one spelling on lines matching /$o{line}/, read: " . join( ', ', map { "'$_'" } sort keys %seen ) . "\n";
        exit 1;
    }
    exit 0;
}
elsif ( $mode eq 'column' ) {
    die "column needs --column, --kind and --lib\n" unless defined $o{column} && defined $o{kind} && defined $o{lib};
    require $o{lib};
    my %units = (
        duration => {
            short  => [qw( ns us ms s m h d w mo y )],
            medium => [qw( nsec usec msec sec min hr day wk mon yr )],
            long   => [qw( nanoseconds microseconds milliseconds seconds minutes hours days weeks months years
                           nanosecond microsecond millisecond second minute hour day week month year )],
        },
        'bytes-si'  => { token => [qw( B kB MB GB TB )],    long => [qw( bytes kilobytes megabytes gigabytes terabytes byte kilobyte megabyte gigabyte terabyte )] },
        'bytes-iec' => { token => [qw( B KiB MiB GiB TiB )], long => [qw( bytes kibibytes mebibytes gibibytes tebibytes byte kibibyte mebibyte gibibyte tebibyte )] },
        count => { short => [qw( k M B T )], medium => [qw( k Mil Bil Tril )], long => [qw( thousand million billion trillion )] },
    );
    my $vocab = $units{ $o{kind} } or die "column: unknown kind $o{kind}\n";
    my $layout = parse_debug_layout( $o{file} );
    open my $in, '<:encoding(UTF-8)', $o{file} or die "cannot open $o{file}: $!\n";
    my ( @cells, $bad );
    while ( my $line = <$in> ) {
        ( my $plain = $line ) =~ s/\e\[[0-9;]*m//g;
        next unless $plain =~ /^ \d{4}-\d{2}-\d{2} \d{2}:\d{2}/;
        my $text = row_text( column_slice( decode_line($line), $layout, $o{column} ) );
        $text =~ s/^\s+|\s+$//g;
        push @cells, $text if length $text;
    }
    if ( !@cells ) { print "FAIL: no populated $o{column} cell in $o{file}\n"; exit 1 }
    my ( %tiers, %fits );
    for my $cell (@cells) {
        my ( $number, $space, $unit ) = $cell =~ /^(-?\d+(?:\.\d+)?)( ?)([A-Za-z]*)$/;
        if ( !defined $number ) { print "FAIL: cell '$cell' is not one number and one unit\n"; $bad++; next }
        if ( $unit eq '' ) {
            next if $o{kind} eq 'count';
            print "FAIL: cell '$cell' carries no unit\n"; $bad++; next;
        }
        my @tier = grep { my $t = $_; grep { $_ eq $unit } @{ $vocab->{$t} } } sort keys %$vocab;
        if ( !@tier ) { print "FAIL: cell '$cell': '$unit' is no complete unit spelling of $o{kind}\n"; $bad++; next }
        my $tier = @tier > 1 ? join( '|', @tier ) : $tier[0];
        $tiers{$tier}++;
        $fits{ $space ? 'loose' : 'tight' }++;
        if ( $tier eq 'long' && !$space ) { print "FAIL: cell '$cell': a long-tier word directly follows the number\n"; $bad++ }
        if ( defined $o{'source-unit'} && $unit eq $o{'source-unit'} && $number =~ /\./ ) {
            print "FAIL: cell '$cell' shows a decimal in the source unit $o{'source-unit'}\n"; $bad++;
        }
    }
    # Tiers whose spellings coincide (k is short and medium) are one vocabulary
    # with either; a long word beside an abbreviation, or two abbreviations
    # only one tier has, is not.
    my @distinct = keys %tiers;
    my %named = map { $_ => 1 } map { split /\|/ } @distinct;
    my $common = grep { my $t = $_; !grep { !( "|$_|" =~ /\|\Q$t\E\|/ ) } @distinct } keys %named;
    if ( !$common ) { print "FAIL: column $o{column} mixes tiers: " . join( ', ', sort @distinct ) . "\n"; $bad++ }
    if ( keys %fits > 1 ) { print "FAIL: column $o{column} mixes fits: " . join( ', ', sort keys %fits ) . " over " . join( ' | ', @cells ) . "\n"; $bad++ }
    exit 1 if $bad;
    print "tiers=" . join( ',', sort @distinct ) . "\n";
    exit 0;
}
die "check-values.pl: unknown mode '$mode'\n";
