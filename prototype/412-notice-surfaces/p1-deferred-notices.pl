#!/usr/bin/env perl
# P1: the notices deferred during the run, presented by category once the
# data work has finished and before the timeline is drawn.
#
# A mock-up inside a real ltl run: ltl's own title, a simulated progress line
# finishing, the notice surface, then ltl's real timeline, tables and summary
# for the log given.
#
#   perl p1-deferred-notices.pl [--form lines|boxes|sections] [--style ltl|new]
#        [--set typical|minimal] [--glyphs symbol|emoji|ascii] [--bg dark|light]
#        [--width N] [--height N] [--log FILE] [--no-progress] [--all]
#
# --all prints every form in both styles one after the other, without the
# backdrop, for side-by-side comparison.

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";
use File::Basename qw(basename);
use Getopt::Long;
use Time::HiRes qw(sleep);
use NoticeProto qw(interactive terminal_size style_for display_width wrap_text
                   categories ltl_backdrop ltl_path);

my %opt = (
    form   => 'sections',
    style  => 'ltl',
    set    => 'typical',
    glyphs => 'symbol',
    bg     => 'dark',
    log    => "$FindBin::Bin/../../tests/fixtures/tomcat-access-duration-spread.txt",
);
GetOptions( \%opt, 'form=s', 'style=s', 'set=s', 'glyphs=s', 'bg=s', 'width=i',
    'height=i', 'log=s', 'no-progress', 'all' ) or die "bad options\n";
my ( $W, $H ) = terminal_size( width => $opt{width}, height => $opt{height} );

my $sets = do "$FindBin::Bin/notices/sets.pl" or die "notices/sets.pl: $@ $!\n";
my $notices = $sets->{ $opt{set} } or die "no notice set '$opt{set}'\n";

my %render = ( lines => \&render_lines, boxes => \&render_boxes, sections => \&render_sections );

if ( $opt{all} ) {
    for my $style (qw(ltl new)) {
        for my $form (qw(lines boxes sections)) {
            my $s = style_for( $style, $opt{bg} );
            print "\n$s->{dim}── form: $form   style: $style ──$s->{reset}\n\n";
            print "$_\n" for $render{$form}->( $notices, $s, $W );
        }
    }
    exit 0;
}

$render{ $opt{form} } or die "no form '$opt{form}'\n";
my $style = style_for( $opt{style}, $opt{bg} );
my $backdrop = ltl_backdrop( width => $W, height => $H, bg => $opt{bg}, log => $opt{log} );

print @{ $backdrop->{title} };
simulate_progress( basename( $opt{log} ) ) unless $opt{'no-progress'};
print "\n";
print "$_\n" for $render{ $opt{form} }->( $notices, $style, $W );
print "\n";
print @{ $backdrop->{body} };

# --- the progress line, as ltl paints it ------------------------------------
#
# Frames follow progress_line_text() and paint_progress_line(): "\r", the
# text, padded to the terminal width less one. The completion rows follow the
# bright-green "... completed." lines ltl prints after the read. In a terminal
# the frames are animated; otherwise only the completion rows are printed.

sub simulate_progress {
    my ($file) = @_;
    my $green = "\e[92m";
    my $nc    = "\e[0m";
    if ( interactive() ) {
        my $lines = 1_284_000;
        for my $step ( 1 .. 15 ) {
            my $pct  = sprintf '%.0f%%', 100 * $step / 15;
            my $text = sprintf 'Processing %s line %s, %s lines/sec: %s', $pct,
                commify( int( $lines * $step / 15 ) ), '856.2k', $file;
            print "\r$text", ' ' x ( $W - 1 - length $text );
            sleep 0.1;
        }
    }
    for my $done ( 'Processing completed.', 'Consolidating similar messages completed.',
        'Calculating statistics completed.', 'Scaling and normalizing data completed.' ) {
        print "\r$green$done$nc", ' ' x ( $W - length $done ), "\n";
        sleep 0.15 if interactive();
    }
}

sub commify {
    my $n = reverse shift;
    $n =~ s/(\d{3})(?=\d)/$1,/g;
    return scalar reverse $n;
}

# --- shared by the forms ------------------------------------------------------

sub glyph_of {
    my ($cat) = @_;
    return $opt{glyphs} eq 'emoji' ? $cat->{emoji} : $opt{glyphs} eq 'ascii' ? $cat->{ascii} : $cat->{glyph};
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
            push @rows, '  ' . $fg . glyph_of($cat) . ' ' . uc( $cat->{name} ) . $s->{reset}
                . $s->{dim} . ' (' . scalar(@$in) . ') ' . $cat->{reads} . $s->{reset};
            push @rows, ' ' . $s->{frame} . ( $b->{h_line} x ( $width - 2 ) ) . $s->{reset};
            push @rows, notice_rows( $_, $s, $fg, $width - 1, $fg . '•' . $s->{reset} . ' ', '  ', '  ' ) for @$in;
        }
        else {
            my $bar = $fg . $s->{bar} . $s->{reset};
            push @rows, $bar . ' ' . $s->{bold} . $fg . glyph_of($cat) . ' ' . ucfirst( $cat->{name} ) . $s->{reset}
                . '  ' . $s->{dim} . $cat->{reads} . $s->{reset};
            my $rail = $fg . $b->{v_line} . $s->{reset} . ' ';
            push @rows, notice_rows( $_, $s, $fg, $width - 1, $rail . '• ', $rail . '  ', $rail . '  ' ) for @$in;
        }
    }
    return @rows;
}
