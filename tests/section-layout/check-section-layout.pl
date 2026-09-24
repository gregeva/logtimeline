#!/usr/bin/env perl
# check-section-layout.pl — reads an ltl standard-output capture that carries
# `-V section-layout` and checks the reported layout against the rows the run
# printed (features/597-section-visibility.md § D3-D14).
#
#   check-section-layout.pl accounting CAPTURE
#       Every row of standard output is placed: the -V ranges, the sections at
#       the rows they are reported on, one blank separator between two rendered
#       sections, and the one blank row that closes the run. Anything else is
#       reported by row number and fails.
#   check-section-layout.pl anchor CAPTURE NAME OFFSET TEXT
#       The row at OFFSET from NAME's reported start holds TEXT. OFFSET is a row
#       count from the start, `last`, or `last-N`.
#   check-section-layout.pl state CAPTURE NAME STATE [ROWS]
#       NAME is reported in STATE, and with ROWS rows when given.
#   check-section-layout.pl strip CAPTURE
#       Standard output as the terminal shows it, -V ranges removed.
#   check-section-layout.pl compare CAPTURE_A CAPTURE_B
#       With their -V ranges removed, the two captures print the same rows: the
#       same count, the same text. Rows that differ between any two runs (time,
#       memory) are dropped by the caller, through tests/lib/nondeterministic.sh.
#
# A row is read as the terminal leaves it: escape sequences removed, and only
# the text after the last carriage return, which a progress row overwrites.
# Exit 0 when the check holds; 1 with a diagnostic when it does not; 2 on a
# malformed capture (no section-layout range).

use strict;
use warnings;

my ( $mode, @args ) = @ARGV;
die "usage: $0 accounting|anchor|state|compare CAPTURE ...\n" unless $mode && @args;

sub read_capture {
    my ($file) = @_;
    open my $fh, '<:raw', $file or die "cannot read $file: $!\n";
    local $/;
    my $content = <$fh>;
    close $fh;
    my @lines = split /\n/, $content, -1;
    pop @lines if @lines && $lines[-1] eq '';

    my ( @rows, @layout, $depth, $in_layout );
    $depth = 0;
    for my $line (@lines) {
        my $plain = $line;
        $plain =~ s/\e\[[0-9;]*[A-Za-z]//g;
        $plain =~ s/.*\r//s;
        if ( $plain =~ /^=== (END )?(.+?) ===\s*$/ ) {
            my ( $end, $name ) = ( $1, $2 );
            $depth += $end ? -1 : 1;
            $in_layout = !$end if $name eq 'section-layout';
            next;
        }
        if ($depth) {
            push @layout, [ split /\t/, $plain, -1 ] if $in_layout && $plain !~ /^name\t/;
            next;
        }
        push @rows, $plain;
    }
    return ( \@rows, \@layout );
}

sub layout_of {
    my ($layout) = @_;
    my ( %entry, @order );
    for my $fields (@$layout) {
        my ( $name, $state, $start, $rows ) = @$fields;
        $entry{$name} = { state => $state, start => $start, rows => $rows };
        push @order, $name;
    }
    # A part is named for its section: the section's name, a hyphen, the part.
    for my $name (@order) {
        my ($prefix) = $name =~ /^([^-]+)-/ or next;
        $entry{$name}{parent} = $prefix if exists $entry{$prefix};
    }
    return ( \%entry, \@order );
}

sub load {
    my ($file) = @_;
    my ( $rows, $layout ) = read_capture($file);
    unless (@$layout) {
        print "no section-layout range in $file\n";
        exit 2;
    }
    my ( $entry, $order ) = layout_of($layout);
    return ( $rows, $entry, $order );
}

sub is_blank { return $_[0] !~ /\S/ }

if ( $mode eq 'accounting' ) {
    my ($file) = @args;
    my ( $rows, $entry, $order ) = load($file);
    my @problems;
    my @placed = (0) x ( @$rows + 1 );    # 1-based: what each row was placed as
    my $previous_end = 0;
    my ( $section_rows, $separators ) = ( 0, 0 );

    for my $name (@$order) {
        my $e = $entry->{$name};
        next unless $e->{state} eq 'rendered';
        my ( $start, $count ) = ( $e->{start}, $e->{rows} );
        if ( $e->{parent} ) {
            my $p = $entry->{ $e->{parent} };
            push @problems, "$name rows $start-" . ( $start + $count - 1 ) . " fall outside $e->{parent} rows $p->{start}-" . ( $p->{start} + $p->{rows} - 1 )
                if $start < $p->{start} || $start + $count > $p->{start} + $p->{rows};
            next;
        }
        if ($previous_end) {
            my $separator = $previous_end + 1;
            if ( $start != $separator + 1 ) {
                push @problems, "$name starts at row $start; one separator after row $previous_end puts it at " . ( $separator + 1 );
            } elsif ( !is_blank( $rows->[ $separator - 1 ] // '' ) ) {
                push @problems, "row $separator separating $name from the section above is not blank: '$rows->[$separator - 1]'";
            } else {
                $placed[$separator] = 'separator';
                $separators++;
            }
        } elsif ( $start != 1 ) {
            push @problems, "$name is the first section but starts at row $start, not row 1";
        }
        for my $r ( $start .. $start + $count - 1 ) {
            if ( $r > @$rows ) {
                push @problems, "$name claims row $r, beyond the " . @$rows . " rows printed";
                last;
            }
            $placed[$r] = $name;
        }
        $section_rows += $count;
        $previous_end = $start + $count - 1;
    }

    # Declared fixed spacing: the one blank row that closes the run.
    my $closing = $previous_end + 1;
    if ( $closing == @$rows && is_blank( $rows->[ $closing - 1 ] ) ) {
        $placed[$closing] = 'closing blank row';
    } else {
        push @problems, "the blank row closing the run is missing after row $previous_end";
    }
    my @unplaced = grep { !$placed[$_] } 1 .. scalar @$rows;
    push @problems, "row $_ is placed in no section: '" . substr( $rows->[ $_ - 1 ], 0, 80 ) . "'" for @unplaced;
    my $remainder = @$rows - $section_rows - $separators - ( $placed[$closing] ? 1 : 0 );

    if (@problems) {
        print "$_\n" for @problems;
        print "total=" . @$rows . " sections=$section_rows separators=$separators remainder=$remainder\n";
        exit 1;
    }
    print "total=" . @$rows . " sections=$section_rows separators=$separators fixed=1 remainder=0\n";
    exit 0;
}

if ( $mode eq 'anchor' ) {
    my ( $file, $name, $offset, $text ) = @args;
    my ( $rows, $entry ) = load($file);
    my $e = $entry->{$name};
    unless ( $e && $e->{state} eq 'rendered' ) {
        print "$name is not reported rendered (" . ( $e ? $e->{state} : 'not reported' ) . ")\n";
        exit 1;
    }
    my $row;
    if    ( $offset =~ /^\d+$/ )        { $row = $e->{start} + $offset }
    elsif ( $offset =~ /^last(?:-(\d+))?$/ ) { $row = $e->{start} + $e->{rows} - 1 - ( $1 // 0 ) }
    else  { die "bad offset '$offset'\n" }
    my $got = $rows->[ $row - 1 ] // '';
    if ( index( $got, $text ) < 0 ) {
        print "row $row ($name start $e->{start} + $offset) does not hold '$text': '" . substr( $got, 0, 100 ) . "'\n";
        exit 1;
    }
    print "row $row holds '$text'\n";
    exit 0;
}

if ( $mode eq 'state' ) {
    my ( $file, $name, $state, $count ) = @args;
    my ( undef, $entry ) = load($file);
    my $e = $entry->{$name};
    my $got = $e ? $e->{state} . ( $e->{state} eq 'rendered' ? " $e->{rows}" : '' ) : 'not reported';
    my $ok = $e && $e->{state} eq $state && ( !defined $count || ( $e->{rows} // '' ) eq $count );
    unless ($ok) {
        print "$name reported '$got', expected '$state" . ( defined $count ? " $count" : '' ) . "'\n";
        exit 1;
    }
    unless ( $state eq 'rendered' || ( $e->{start} eq '' && $e->{rows} eq '' ) ) {
        print "$name is $state but carries a position: start '$e->{start}' rows '$e->{rows}'\n";
        exit 1;
    }
    print "$name $got\n";
    exit 0;
}

if ( $mode eq 'strip' ) {
    my ($rows) = read_capture( $args[0] );
    print "$_\n" for @$rows;
    exit 0;
}

if ( $mode eq 'compare' ) {
    my ( $file_a, $file_b ) = @args;
    my ($a_rows) = read_capture($file_a);
    my ($b_rows) = read_capture($file_b);
    if ( @$a_rows != @$b_rows ) {
        print "$file_a: " . @$a_rows . " rows; $file_b: " . @$b_rows . " rows\n";
        exit 1;
    }
    for my $i ( 0 .. $#$a_rows ) {
        next if $a_rows->[$i] eq $b_rows->[$i];
        print "row " . ( $i + 1 ) . " differs:\n  '$a_rows->[$i]'\n  '$b_rows->[$i]'\n";
        exit 1;
    }
    print scalar(@$a_rows) . " rows identical\n";
    exit 0;
}

die "unknown mode '$mode'\n";
