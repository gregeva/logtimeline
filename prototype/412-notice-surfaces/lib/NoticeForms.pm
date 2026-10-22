package NoticeForms;

# The three forms a block of notices takes on the terminal (lines, a box per
# category, headed sections), in either visual language. Shared by the
# prototypes that present notices.

use strict;
use warnings;
use utf8;
use Exporter 'import';
use NoticeProto qw(display_width wrap_text categories);

our @EXPORT_OK = qw(set_glyphs glyph_of grouped notice_rows render_lines render_boxes render_sections %render);

my $glyphs = 'symbol';

sub set_glyphs { $glyphs = shift // 'symbol'; return }

our %render = ( lines => \&render_lines, boxes => \&render_boxes, sections => \&render_sections );

# --- shared by the forms ------------------------------------------------------

sub glyph_of {
    my ($cat) = @_;
    return $glyphs eq 'emoji' ? $cat->{emoji} : $glyphs eq 'ascii' ? $cat->{ascii} : $cat->{glyph};
}

# The notices grouped by category, in the categories' presentation order.
sub grouped {
    my ($list) = @_;
    my @groups;
    for my $cat ( categories() ) {
        my @in = grep { $_->{category} eq $cat->{name} } @$list;
        push @groups, [ $cat, \@in ] if @in;
    }
    return @groups;
}

# A notice's own rows at a given width: the statement, the evidence (dim), the
# remedy after an arrow in the category's colour. $first and $rest prefix the
# statement's first and following rows; $more prefixes evidence and remedy.
sub notice_rows {
    my ( $n, $s, $fg, $width, $first, $rest, $more ) = @_;
    my @rows;
    my @st = wrap_text( $n->{statement}, $width - display_width($first) );
    push @rows, $first . $s->{text} . shift(@st) . $s->{reset};
    push @rows, $rest . $s->{text} . $_ . $s->{reset} for @st;
    for my $e ( @{ $n->{evidence} // [] } ) {
        push @rows, $more . $s->{dim} . $_ . $s->{reset} for wrap_text( $e, $width - display_width($more) );
    }
    if ( $n->{remedy} ) {
        my @r = wrap_text( $n->{remedy}, $width - display_width($more) - 2 );
        push @rows, $more . $fg . '→ ' . shift(@r) . $s->{reset};
        push @rows, $more . '  ' . $fg . $_ . $s->{reset} for @r;
    }
    return @rows;
}

# --- (a) prefixed lines -------------------------------------------------------
#
# One notice to a line (wrapped), led by its category's glyph and name, as a
# plain stream: the lightest form.

sub render_lines {
    my ( $list, $s, $width ) = @_;
    my @rows;
    for my $g ( grouped($list) ) {
        my ( $cat, $in ) = @$g;
        my $fg = $s->{fg}{ $cat->{name} };
        for my $n (@$in) {
            if ( $s->{name} eq 'ltl' ) {
                my $label = ' ' . glyph_of($cat) . ' ' . ucfirst( $cat->{name} ) . ': ';
                my $lead  = $fg . $label . $s->{reset};
                my $pad   = ' ' x display_width($label);
                push @rows, notice_rows( $n, $s, $fg, $width - 1, $lead, $pad, $pad );
            }
            else {
                my $bar   = $fg . $s->{bar} . $s->{reset} . ' ';
                my $label = $s->{bold} . $fg . glyph_of($cat) . ' ' . ucfirst( $cat->{name} ) . $s->{reset} . '  ';
                my $pad = ' ' x display_width($label);
                push @rows, notice_rows( $n, $s, $fg, $width - 1, $bar . $label, $bar . $pad, $bar . $pad );
            }
        }
    }
    return @rows;
}

# --- (b) one box per category -------------------------------------------------
#
# Each category a framed block, its heading set in the top edge with how to
# read what is inside; notices as bullets within.

sub render_boxes {
    my ( $list, $s, $width ) = @_;
    my $b = $s->{box};
    my $outer = $width - 2;
    my $inner = $outer - 4;
    my @rows;
    my @groups = grouped($list);
    for my $gi ( 0 .. $#groups ) {
        my ( $cat, $in ) = @{ $groups[$gi] };
        my $fg = $s->{fg}{ $cat->{name} };
        my $edge = $s->{name} eq 'ltl' ? $s->{frame} : $fg;
        my $name = $s->{name} eq 'ltl' ? uc $cat->{name} : ucfirst $cat->{name};
        my $head = ' ' . glyph_of($cat) . " $name ";
        my $sub  = " $cat->{reads} ";
        my $fill = $outer - 2 - 1 - display_width($head) - display_width($sub);
        $sub = '', $fill = $outer - 3 - display_width($head) if $fill < 1;
        push @rows, ' ' . $edge . $b->{corner_tl} . $b->{h_line} . $s->{reset}
            . $s->{bold} . $fg . $head . $s->{reset} . $s->{dim} . $sub . $s->{reset}
            . $edge . ( $b->{h_line} x $fill ) . $b->{corner_tr} . $s->{reset};
        for my $ni ( 0 .. $#$in ) {
            for my $r ( notice_rows( $in->[$ni], $s, $fg, $inner, '• ', '  ', '  ' ) ) {
                my $pad = $inner - display_width($r);
                push @rows, ' ' . $edge . $b->{v_line} . $s->{reset} . ' ' . $r . ( ' ' x ( $pad > 0 ? $pad : 0 ) )
                    . ' ' . $edge . $b->{v_line} . $s->{reset};
            }
        }
        push @rows, ' ' . $edge . $b->{corner_bl} . ( $b->{h_line} x ( $outer - 2 ) ) . $b->{corner_br} . $s->{reset};
    }
    return @rows;
}

# --- (c) headed category sections -------------------------------------------
#
# Each category a heading and a rule, then its notices as bullets, the way
# ltl's messages tables are headed and listed.

# A category heading with how to read it on the same row when it fits, on
# the row below when it does not.
sub heading {
    my ( $head, $reads, $s, $width, $indent ) = @_;
    my $one = $head . '  ' . $s->{dim} . $reads . $s->{reset};
    return $one if display_width($one) <= $width - 1;
    return ( $head, $indent . $s->{dim} . $reads . $s->{reset} );
}

sub render_sections {
    my ( $list, $s, $width ) = @_;
    my $b = $s->{box};
    my @rows;
    my @groups = grouped($list);
    for my $gi ( 0 .. $#groups ) {
        my ( $cat, $in ) = @{ $groups[$gi] };
        my $fg = $s->{fg}{ $cat->{name} };
        push @rows, '' if $gi;
        if ( $s->{name} eq 'ltl' ) {
            push @rows, heading( '  ' . $fg . glyph_of($cat) . ' ' . uc( $cat->{name} ) . $s->{reset}
                . $s->{dim} . ' (' . scalar(@$in) . ')' . $s->{reset}, $cat->{reads}, $s, $width, '  ' );
            push @rows, ' ' . $s->{frame} . ( $b->{h_line} x ( $width - 2 ) ) . $s->{reset};
            push @rows, notice_rows( $_, $s, $fg, $width - 1, $fg . '•' . $s->{reset} . ' ', '  ', '  ' ) for @$in;
        }
        else {
            my $bar = $fg . $s->{bar} . $s->{reset};
            push @rows, heading( $bar . ' ' . $s->{bold} . $fg . glyph_of($cat) . ' ' . ucfirst( $cat->{name} ) . $s->{reset},
                $cat->{reads}, $s, $width, $bar . ' ' );
            my $rail = $fg . $b->{v_line} . $s->{reset} . ' ';
            push @rows, notice_rows( $_, $s, $fg, $width - 1, $rail . '• ', $rail . '  ', $rail . '  ' ) for @$in;
        }
    }
    return @rows;
}

1;
