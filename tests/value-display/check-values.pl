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
#
# A token is a number, optionally with a decimal part, directly followed by
# letters: `1.5k`, `0ms`, `2s`, `999B`. A selection that reads no token, or
# matches no line, is a failure (tests/HARNESS-DESIGN.md section Harnesses
# must fail on missing anchors). Exit 0 on pass; 1 with a diagnostic on fail.
use strict;
use warnings;
use Getopt::Long;

my $mode = shift @ARGV // die "usage: check-values.pl tokens|absent|same --file F ...\n";
my %o = ( min => 1 );
GetOptions( \%o, 'file=s', 'line=s', 'each=s', 'min=i', 'after=s', 'regex=s' )
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
die "check-values.pl: unknown mode '$mode'\n";
