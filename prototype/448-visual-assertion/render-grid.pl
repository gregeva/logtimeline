#!/usr/bin/env perl
# Decode a rendered terminal line into per-cell attributes: the character, its
# foreground and its background, as a terminal would resolve them. The unit an
# assertion reads is then a CELL, not an escape sequence.
use strict; use warnings;

sub decode_line {
    my ($line) = @_;
    my (@cells, $fg, $bg);
    ($fg, $bg) = ('default', 'default');
    while ($line =~ /\G(\e\[([0-9;]*)m|.)/gs) {
        my ($tok, $sgr) = ($1, $2);
        if (defined $sgr) {
            my @p = split /;/, $sgr, -1;
            @p = (0) unless @p;
            my $i = 0;
            while ($i <= $#p) {
                my $c = $p[$i];
                if (($c eq '38' || $c eq '48') && ($p[$i+1]//'') eq '5') {
                    my $v = $p[$i+2] // '';
                    $c eq '38' ? ($fg = "256:$v") : ($bg = "256:$v");
                    $i += 3; next;
                }
                if ($c eq '0' || $c eq '')       { ($fg,$bg) = ('default','default') }
                elsif ($c eq '39')               { $fg = 'default' }
                elsif ($c eq '49')               { $bg = 'default' }
                elsif ($c =~ /^3[0-7]$/)         { $fg = "ansi:$c" }
                elsif ($c =~ /^9[0-7]$/)         { $fg = "ansi:$c" }
                elsif ($c =~ /^4[0-7]$/)         { $bg = "ansi:$c" }
                elsif ($c =~ /^10[0-7]$/)        { $bg = "ansi:$c" }
                elsif ($c eq '7')                { ($fg,$bg) = ("reverse","reverse") }
                $i++;
            }
            next;
        }
        next if $tok eq "\r" || $tok eq "\n";
        push @cells, { ch => $tok, fg => $fg, bg => $bg };
    }
    return \@cells;
}

# Render a decoded line as a human-auditable grid: the text, then one row per
# attribute so a reader SEES what each column carries.
sub grid {
    my ($cells) = @_;
    my $text = join '', map { $_->{ch} } @$cells;
    my %seen_fg = map { $_->{fg} => 1 } @$cells;
    my %seen_bg = map { $_->{bg} => 1 } @$cells;
    return ($text, [sort keys %seen_fg], [sort keys %seen_bg]);
}
1;

# --- Requirement-shaped predicates -----------------------------------------
# Each answers a question the ARCHITECT asked, not a question about escapes.

# "The bar inverts": every filled cell carries a background AND black text;
# every unfilled cell carries the colour as foreground and no background.
sub bar_inverts {
    my ($cells) = @_;
    my (@bad, $filled, $plain);
    for my $i (0 .. $#$cells) {
        my $c = $cells->[$i];
        next if $c->{ch} eq ' ' && $c->{bg} eq 'default';   # padding
        if ($c->{bg} ne 'default') {
            $filled++;
            push @bad, "col $i: filled cell text is $c->{fg}, expected black (256:0)"
                unless $c->{fg} eq '256:0' || $c->{fg} eq 'reverse';
        } else {
            $plain++;
            push @bad, "col $i: unfilled cell has no colour"
                if $c->{fg} eq 'default';
        }
    }
    return (\@bad, $filled // 0, $plain // 0);
}

# "How many cells does the bar cover?" — the honest extent, in characters.
sub fill_extent { my ($c)=@_; scalar grep { $_->{bg} ne 'default' } @$c }

# "What colour is the fill?" — one value, or a complaint if it is not uniform.
sub fill_colour {
    my ($cells) = @_;
    my %seen = map { $_->{bg} => 1 } grep { $_->{bg} ne 'default' } @$cells;
    my @k = keys %seen;
    return @k == 1 ? $k[0] : (@k == 0 ? 'none' : 'MIXED:' . join(',', sort @k));
}

# "What colour is the row's text where it is not filled?"
sub text_colour {
    my ($cells) = @_;
    my %seen = map { $_->{fg} => 1 }
               grep { $_->{bg} eq 'default' && $_->{ch} ne ' ' } @$cells;
    my @k = grep { $_ ne 'default' } keys %seen;
    return @k ? join(',', sort @k) : 'none';
}
1;

# "The row never exceeds its budget" (S9) and "the value holds the boundary".
sub row_width_ok {
    my ($cells, $budget) = @_;
    my $text = join '', map { $_->{ch} } @$cells;
    $text =~ s/\s+$//;
    return (length($text) <= $budget, length($text));
}

# "The value is right-aligned to the table boundary": where does the last
# non-space character sit?
sub value_right_edge {
    my ($cells) = @_;
    my $text = join '', map { $_->{ch} } @$cells;
    $text =~ s/\s+$//;
    return length($text);
}
1;
