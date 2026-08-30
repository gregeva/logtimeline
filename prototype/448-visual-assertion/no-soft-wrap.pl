#!/usr/bin/env perl
# Assert that no line the application prints exceeds the terminal width.
#
# The whole output model rests on known character placement: a line longer than
# the terminal soft-wraps onto the next row, every line below it shifts, and
# every column the reader relies on is displaced. It is a rendering failure
# regardless of how the content reads.
#
# Measurement rules that matter, each of which produced a wrong answer while
# this was being written:
#   - decode UTF-8 before measuring. The box-drawing rules are multi-byte;
#     counting bytes reports a 160-column rule as 480.
#   - SGR and OSC escapes occupy no columns and are stripped.
#   - C0 control characters occupy no column.
#   - a trailing newline is not a column.
use strict; use warnings;

sub display_width {
    my ($line) = @_;
    $line =~ s/\e\[[0-9;]*m//g;         # SGR
    $line =~ s/\e\][^\a]*\a//g;         # OSC
    $line =~ s/\e\[[0-9;]*[A-Za-z]//g;  # other CSI
    $line =~ s/[\x00-\x08\x0b-\x1f\x7f]//g;
    $line =~ s/\r?\n\z//;
    return length($line);               # caller must have decoded UTF-8
}

# Returns (ok, [offenders]) where each offender is [line_no, width, excerpt].
sub check_no_soft_wrap {
    my ($path, $width, %opt) = @_;
    open my $fh, '<:encoding(UTF-8)', $path or die "cannot open $path: $!\n";
    my (@bad, $n);
    while (my $l = <$fh>) {
        $n++;
        next if $opt{skip_lines} && $n <= $opt{skip_lines};
        my $w = display_width($l);
        next if $w <= $width;
        (my $p = $l) =~ s/\e\[[0-9;]*m//g; chomp $p;
        push @bad, [ $n, $w, substr($p, 0, 60) ];
    }
    close $fh;
    return (scalar(@bad) == 0, \@bad);
}
1;
