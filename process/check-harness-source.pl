#!/usr/bin/env perl
# Reads a harness's source for the three faults of tests/HARNESS-DESIGN.md
# § The failed-run checker that are certain from the source alone:
#
#   counted-in-subshell  a function that changes the pass or fail count (or
#                        calls one that does) runs inside $( ), <( ) or
#                        backticks, so what it counts is lost (Trap 12)
#   summary-in-scenario  the line printing the summary sits inside a block
#                        other than a top-level `if` that does not test the
#                        scenario selection, so a selection can skip it
#   lookup-no-fallback   a variable is assigned from a command substitution
#                        holding a `grep` or an `ls`, with no `||` inside it
#                        or after it, so a lookup that finds nothing ends the
#                        harness under `set -e` (shape 10)
#
# The source is read through bash's own parser: the harness is wrapped in a
# function and printed back with `declare -f`, which joins continued lines and
# indents every level of nesting by four spaces. It never runs the harness.
#
# Usage: check-harness-source.pl HARNESS [HARNESS ...]
#   Prints one line per fault, `<harness>: <rule>: <statement>`, the statement
#   as bash prints it; and `<harness>: ok` for a harness with none.
#
# Exit status: 0 when no harness has a fault, 1 otherwise, 2 on a usage error.
use strict;
use warnings;

my @harnesses = @ARGV;
usage('no harness named') unless @harnesses;
usage("unknown option $harnesses[0]") if $harnesses[0] =~ /^-/;

my $faults = 0;
for my $harness (@harnesses) {
    my ( $lines, $error ) = normalised($harness);
    if ( !$lines ) {
        print "$harness: unreadable: $error\n";
        $faults++;
        next;
    }
    my @found = (
        counted_in_subshell($lines),
        summary_in_scenario($lines),
        lookup_no_fallback($lines),
    );
    print "$harness: $_\n" for @found;
    print "$harness: ok\n" unless @found;
    $faults += @found;
}
exit( $faults ? 1 : 0 );

# The harness as bash prints it back from a function wrapping it, with the
# bodies of here-documents blanked so their text is never read as code.
sub normalised {
    my ($harness) = @_;
    return ( undef, 'not a file' ) unless -f $harness;
    my $script = 'eval "__harness() {
$(cat "$1")
}" && declare -f __harness';
    open my $fh, '-|', 'bash', '-c', $script, '_', $harness or return ( undef, "cannot run bash: $!" );
    my @lines = <$fh>;
    close $fh;
    return ( undef, 'bash could not parse it' ) if $? || !@lines;
    chomp @lines;
    my $delimiter;
    for my $line (@lines) {
        if ( defined $delimiter ) {
            if ( $line =~ /^\t*\Q$delimiter\E$/ ) { undef $delimiter }
            else                                   { $line = '' }
            next;
        }
        $delimiter = $2 if $line =~ /(?<!<)<<-?\s*(['"]?)(\w+)\1(?!<)/;
    }
    return ( \@lines, undef );
}

sub indent_of { return length( ( $_[0] =~ /^( *)/ )[0] ) }

# Each function defined in the harness, by name, with the lines of its body.
sub functions {
    my ($lines) = @_;
    my %body;
    for my $i ( 0 .. $#$lines ) {
        next unless $lines->[$i] =~ /^( *)function ([\w:.-]+) \(\)\s*$/;
        my ( $indent, $name ) = ( $1, $2 );
        my @body;
        for my $j ( $i + 2 .. $#$lines ) {
            last if $lines->[$j] =~ /^\Q$indent\E\}/;
            push @body, $lines->[$j];
        }
        $body{$name} = \@body;
    }
    return \%body;
}

# The counters a harness reports, read from its summary lines, and its
# failures array.
sub counters {
    my ($lines) = @_;
    my %counter = ( failures => 1 );
    for my $line ( summary_lines($lines) ) {
        $counter{$1} = 1 while $line->[1] =~ /\$\{?(\w+)\}?/g;
    }
    delete @counter{qw(f i n s)};
    return \%counter;
}

# The lines that print a summary, as [index, text].
sub summary_lines {
    my ($lines) = @_;
    my $form = qr/\b(?:echo|printf)\b.*(?:
          Results:\ \$
        | PASS:\ \$\{?\w*pass\w*\}?\s+FAIL:\ \$
        | scenarios,\ \$\{?\w+\}?\ pass,\ \$
        | :\ \$\{?\w*pass\w*\}?\ passed,\ \$
        | Total:\ \$.*Passed:\ \$
    )/xi;
    return map { [ $_, $lines->[$_] ] } grep { $lines->[$_] =~ $form } 0 .. $#$lines;
}

# Faults of the first rule: a counting function called inside $( ), <( ) or
# backticks.
sub counted_in_subshell {
    my ($lines) = @_;
    my $body    = functions($lines);
    my $counter = counters($lines);
    my $names   = join '|', map {quotemeta} keys %$counter;
    my $changes = qr/(?:^|[\s;({&|])(?:$names)(?:\+?=|\[[^]]*\]\+?=)|\(\(\s*(?:$names)\s*(?:\+\+|\+=|=)|\blet\s+(?:$names)\b/;
    my %counts = map { $_ => 1 } grep {
        my $f = $_;
        grep { $_ =~ $changes } @{ $body->{$f} }
    } keys %$body;
    my $more = 1;
    while ($more) {
        $more = 0;
        for my $f ( grep { !$counts{$_} } keys %$body ) {
            for my $c ( keys %counts ) {
                next unless grep {/(?:^|[\s;|&({`!])\Q$c\E(?:\s|;|\)|$)/} @{ $body->{$f} };
                $counts{$f} = 1;
                $more = 1;
                last;
            }
        }
    }
    return () unless %counts;
    my %counting = %counts;
    my @found;
    my $text = join "\n", @$lines;
    for my $sub ( substitutions($text) ) {
        for my $word ( command_words($sub) ) {
            next unless $counting{$word};
            ( my $shown = $sub ) =~ s/\s+/ /g;
            push @found, "counted-in-subshell: $word runs inside $shown";
        }
    }
    return @found;
}

# The text inside each $( ), <( ) and backtick pair. A small lexer: single
# quotes and $'...' are literal, double quotes are literal except for the
# substitutions inside them, ${...} and $((...)) are skipped whole.
sub substitutions {
    my ($text) = @_;
    my @chars = split //, $text;
    my @found;
    my @stack = ( { kind => 'code' } );
    for ( my $i = 0; $i <= $#chars; $i++ ) {
        my $c     = $chars[$i];
        my $next  = $chars[ $i + 1 ] // '';
        my $frame = $stack[-1];
        my $kind  = $frame->{kind};
        if ( $c eq '\\' ) { $i++; next }
        if ( $kind eq 'dq' ) {
            if ( $c eq '"' ) { pop @stack; next }
        }
        elsif ( $kind eq 'bt' ) {
            if ( $c eq '`' ) {
                push @found, join '', @chars[ $frame->{start} .. $i - 1 ];
                pop @stack;
            }
            next;
        }
        elsif ( $kind eq 'brace' ) {
            if    ( $c eq '{' ) { $frame->{depth}++ }
            elsif ( $c eq '}' ) { pop @stack if --$frame->{depth} == 0 }
            next;
        }
        else {    # code: the top level, or the inside of $( ) and <( )
            if ( $c eq "'" ) {
                $i++ while $i < $#chars && $chars[ $i + 1 ] ne "'";
                $i++;
                next;
            }
            if ( $c eq '"' ) { push @stack, { kind => 'dq' }; next }
            if ( $kind eq 'sub' ) {
                if    ( $c eq '(' ) { $frame->{depth}++; next }
                elsif ( $c eq ')' && $frame->{depth} ) { $frame->{depth}--; next }
                elsif ( $c eq ')' ) {
                    push @found, join '', @chars[ $frame->{start} .. $i - 1 ];
                    pop @stack;
                    next;
                }
            }
            if ( $c eq '<' && $next eq '(' ) {
                push @stack, { kind => 'sub', start => $i + 2, depth => 0 };
                $i++;
                next;
            }
        }
        # In code and in double quotes alike.
        if ( $c eq '$' && $next eq "'" && $kind ne 'dq' ) {
            $i += 2;
            while ( $i <= $#chars && $chars[$i] ne "'" ) { $i++ if $chars[$i] eq '\\'; $i++ }
            next;
        }
        if ( $c eq '$' && $next eq '(' && ( $chars[ $i + 2 ] // '' ) eq '(' ) {
            my $depth = 0;
            for ( $i += 1; $i <= $#chars; $i++ ) {
                $depth++ if $chars[$i] eq '(';
                last if $chars[$i] eq ')' && --$depth == 0;
            }
            next;
        }
        if ( $c eq '$' && $next eq '(' ) {
            push @stack, { kind => 'sub', start => $i + 2, depth => 0 };
            $i++;
            next;
        }
        if ( $c eq '$' && $next eq '{' ) {
            push @stack, { kind => 'brace', depth => 1 };
            $i++;
            next;
        }
        if ( $c eq '`' ) { push @stack, { kind => 'bt', start => $i + 1 } }
    }
    return @found;
}

# The words at command position in a piece of shell text.
sub command_words {
    my ($text) = @_;
    my @words;
    for my $segment ( split /\|\||&&|[|;\n(){}]/, $text ) {
        my $s = $segment;
        $s =~ s/^\s+//;
        $s =~ s/^(?:!\s+|then\s+|do\s+|else\s+|\w+=\S*\s+)+//;
        push @words, $1 if $s =~ /^([\w:.-]+)/;
    }
    return @words;
}

# Faults of the second rule: a summary line inside a block other than a
# top-level `if` whose condition does not test the scenario selection.
sub summary_in_scenario {
    my ($lines) = @_;
    my @summary = summary_lines($lines);
    return ('summary-in-scenario: no line prints a summary in a form the capture checker reads')
        unless @summary;
    my @found;
    for my $s (@summary) {
        my ( $i, $text ) = @$s;
        my @openers = enclosing( $lines, $i );
        my @wrong   = grep { $_ !~ /^\s*(?:if|elif)\s/ || /scenario_(?:wanted|selected)/ } @openers;
        next unless @wrong || @openers > 1;
        ( my $shown = $text ) =~ s/^\s+//;
        my ($block) = map { s/^\s+//r } ( @wrong ? $wrong[0] : $openers[0] );
        push @found, "summary-in-scenario: $shown is inside: $block";
    }
    return @found;
}

# The lines opening each block that encloses line $i, innermost first. The
# wrapping function's own level (four spaces) is the top level.
sub enclosing {
    my ( $lines, $i ) = @_;
    my @openers;
    my $level = indent_of( $lines->[$i] ) - 4;
    my $at    = $i;
    while ( $level >= 4 ) {
        my $j = $at - 1;
        $j-- while $j >= 0 && ( $lines->[$j] eq '' || indent_of( $lines->[$j] ) != $level );
        last if $j < 0;
        while ( $j > 0 && $lines->[$j] =~ /^\s*(?:else|elif\s.*|then|do|\{)\s*;?\s*$|^\s*elif\s/ ) {
            $j--;
            $j-- while $j >= 0 && ( $lines->[$j] eq '' || indent_of( $lines->[$j] ) != $level );
        }
        push @openers, $lines->[$j];
        $at = $j;
        $level -= 4;
    }
    return @openers;
}

# Faults of the third rule: an assignment from a command substitution holding
# a grep or an ls, with no || inside it or after it.
sub lookup_no_fallback {
    my ($lines) = @_;
    my @found;
    for my $line (@$lines) {
        next unless $line =~ /^\s*(\w+)=\$\(/;
        my ($sub) = substitutions( $line =~ s/^\s*\w+=//r );
        next unless defined $sub;
        next unless grep { $_ eq 'grep' || $_ eq 'ls' } command_words($sub);
        next if $sub =~ /\|\|/;
        my $after = substr( $line, index( $line, $sub ) + length($sub) + 1 );
        next if $after =~ /^\s*\|\|/;
        ( my $shown = $line ) =~ s/^\s+//;
        push @found, "lookup-no-fallback: $shown";
    }
    return @found;
}

sub usage {
    print STDERR "check-harness-source.pl: $_[0]\n" if @_;
    print STDERR "usage: check-harness-source.pl HARNESS [HARNESS ...]\n";
    exit 2;
}
