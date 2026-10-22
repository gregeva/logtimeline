#!/usr/bin/env perl
# panel-report.pl — the notices panels of a capture, decoded to cells
# (tests/lib/rendered-output.pl), as facts a harness asserts on: what each
# panel and each of its rows shows, and in which colour and emphasis.
#
# Usage: perl panel-report.pl CAPTURE
#
# One line per fact, tab-separated:
#   P <panel> <key> <value>       a panel: first (its top row's line number in
#                                 the capture), rows, width, widths (equal or
#                                 the list), frame_fg, side_fg, title, title_fg,
#                                 title_dim, pad_left, pad_right
#   R <panel> <row> <kind> <text> <attributes>
#                                 one inside row; kind is heading, notice,
#                                 continuation or blank; attributes are
#                                 key=value pairs separated by ';'
# A panel is the rows from one beginning with a rounded top-left corner to the
# next beginning with a rounded bottom-left corner. Exits 1 when the capture
# holds none, 2 on a usage error.
use strict;
use warnings;
use File::Basename qw(dirname);
use File::Spec;

my ($capture) = @ARGV;
if ( !defined $capture ) { print STDERR "usage: panel-report.pl CAPTURE\n"; exit 2 }
require( File::Spec->rel2abs( dirname(__FILE__) . '/../lib/rendered-output.pl' ) );

open my $fh, '<:encoding(UTF-8)', $capture or die "cannot read $capture: $!\n";
my @lines = <$fh>;
close $fh;
binmode STDOUT, ':encoding(UTF-8)';

my $text = sub { join '', map { $_->{ch} } @_ };
my $set  = sub { my %s = map { $_ => 1 } @_; join ',', sort keys %s };
my $flag = sub { my ( $key, @c ) = @_; ( grep { !$_->{$key} } @c ) ? 'no' : 'yes' };

my $panel = 0;
for ( my $i = 0; $i <= $#lines; $i++ ) {
    my $top = decode_line( $lines[$i] );
    next unless @$top && $top->[0]{ch} eq "\x{256d}";
    my $j = $i;
    $j++ while $j <= $#lines && !( @{ decode_line( $lines[$j] ) } && decode_line( $lines[$j] )->[0]{ch} eq "\x{2570}" );
    last if $j > $#lines;
    $panel++;
    my @rows = map { decode_line( $lines[$_] ) } $i .. $j;
    my %w = map { scalar(@$_) => 1 } @rows;
    my @title_cells = @$top[ 2 .. $#$top - 1 ];
    pop @title_cells while @title_cells && $title_cells[-1]{ch} eq "\x{2500}";
    my @shown = grep { $_->{ch} ne ' ' } @title_cells;
    my @inside = @rows[ 1 .. $#rows - 1 ];
    my ( @left, @right );
    for my $r (@inside) {
        my $body = $text->( @$r[ 1 .. $#$r - 1 ] );
        next unless $body =~ /\S/;
        my ($l) = $body =~ /^( *)/;
        my ($t) = $body =~ /( *)$/;
        push @left, length $l;
        push @right, length $t;
    }
    my $min = sub { my $m; $m = !defined $m || $_ < $m ? $_ : $m for @_; $m // '-' };
    print join( "\t", 'P', $panel, @$_ ), "\n" for
        [ first => $i + 1 ], [ rows => scalar @rows ], [ width => scalar @$top ],
        [ widths => keys(%w) == 1 ? 'equal' : join( ',', sort { $a <=> $b } keys %w ) ],
        [ frame_fg => $top->[0]{fg} ], [ side_fg => ( @inside ? $inside[0][0]{fg} : '-' ) ],
        [ title => $text->(@title_cells) =~ s/^\s+|\s+$//gr ], [ title_fg => $set->( map { $_->{fg} } @shown ) ],
        [ title_dim => $flag->( 'dim', @shown ) ], [ pad_left => $min->(@left) ], [ pad_right => $min->(@right) ];
    for my $n ( 0 .. $#inside ) {
        my @full = @{ $inside[$n] }[ 1 .. $#{ $inside[$n] } - 1 ];
        my $lead = 0;
        $lead++ while $lead < $#full && $full[$lead]{ch} eq ' ';
        my @c = @full[ $lead .. $#full ];
        my $body = $text->(@c);
        ( my $shown_text = $body ) =~ s/\s+$//;
        my ( $kind, @attr );
        if ( $shown_text eq '' ) {
            $kind = 'blank';
        } elsif ( $c[0]{ch} eq "\x{2014}" ) {
            $kind = 'notice';
            push @attr, "bullet_fg=$c[0]{fg}";
            my @words = @c[ 2 .. $#c ];
            push @attr, 'bold=' . ( $text->( grep { $_->{bold} } @words ) =~ s{\s+}{}gr );
        } elsif ( $lead > $min->(@left) ) {
            $kind = 'continuation';
        } else {
            $kind = 'heading';
            my @name = grep { $_->{ch} =~ /[A-Z]/ } @c;
            push @attr, "glyph_fg=$c[0]{fg}", "glyph_bold=" . ( $c[0]{bold} ? 'yes' : 'no' ),
                        "name_fg=" . $set->( map { $_->{fg} } @name ), 'name_bold=' . $flag->( 'bold', @name );
            if ( $shown_text =~ /^(.*?\(\d+\))  (.+)$/ ) {
                my $off = length($1) + 2;
                my @reads = grep { $_->{ch} ne ' ' } @c[ $off .. $off + length($2) - 1 ];
                push @attr, 'reads_dim=' . $flag->( 'dim', @reads ), 'reads_fg=' . $set->( map { $_->{fg} } @reads );
            }
        }
        # The parts of a notice row or a continuation, told apart by their markers.
        if ( $kind eq 'notice' || $kind eq 'continuation' ) {
            my $at;
            for my $k ( 0 .. $#c ) {
                $at = 'evidence' if $c[$k]{ch} eq "\x{00b7}";
                $at = 'remedy'   if $c[$k]{ch} eq "\x{2192}";
                next unless $at && $c[$k]{ch} ne ' ';
                $c[$k]{in} = $at;
            }
            for my $part (qw(evidence remedy)) {
                my @p = grep { ( $_->{in} // '' ) eq $part } @c;
                next unless @p;
                push @attr, "${part}_fg=" . $set->( map { $_->{fg} } @p ), "${part}_dim=" . $flag->( 'dim', @p );
            }
            push @attr, 'text_fg=' . $set->( map { $_->{fg} } grep { $_->{ch} ne ' ' && !$_->{bold} && !$_->{in} } @c[ ( $kind eq 'notice' ? 2 : 0 ) .. $#c ] );
        }
        print join( "\t", 'R', $panel, $n + 1, $kind, $shown_text, join( ';', @attr ) ), "\n";
    }
    $i = $j;
}
exit( $panel ? 0 : 1 );
