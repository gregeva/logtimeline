#!/usr/bin/env perl
# Claude Code PreToolUse hook for Write, Edit, MultiEdit and NotebookEdit
# (wired in .claude/settings.json). Blocks writes to paths that are read-only
# or that must never hold the kind of content being written.
use strict;
use warnings;
use JSON::PP;

local $/;
my $in = <STDIN> // '';
my $call = eval { decode_json($in) } || {};
# On Windows a path arrives with backslashes and a drive letter in either case;
# every path is compared in forward-slash form, the project root without
# regard to case there.
my $windows = $^O =~ /^(?:msys|cygwin|MSWin32)$/;
sub slashed { ( my $path = $_[0] // '' ) =~ tr{\\}{/}; $path }
my $p = slashed( $call->{tool_input}{file_path} // $call->{tool_input}{notebook_path} );
exit 0 if $p eq '';
my $root = slashed( $ENV{CLAUDE_PROJECT_DIR} );
my $rel = $p;
if ( $root ne '' ) { $windows ? $rel =~ s{^\Q$root\E/}{}i : $rel =~ s{^\Q$root\E/}{} }

sub deny { print STDERR "[claude-hook] BLOCKED: $_[0]\n"; exit 2 }
sub ask  {
    print encode_json({ hookSpecificOutput => {
        hookEventName => 'PreToolUse', permissionDecision => 'ask',
        permissionDecisionReason => "[claude-hook] $_[0]" } });
    exit 0;
}

# The per-line read loop of an ltl source: read_and_process_logs from its
# `while (1) {` to that loop's closing brace, the text the generated read body
# is built from. Returns the loop's text and its byte span in the source, or
# nothing when the source has no such loop.
sub read_loop_span {
    my ($source) = @_;
    my ( $in_sub, $offset, $from, $indent ) = ( 0, 0 );
    for my $line ( split /(?<=\n)/, $source ) {
        my $at = $offset;
        $offset += length $line;
        if ( !$in_sub ) { $in_sub = 1 if $line =~ /^sub read_and_process_logs \{/; next }
        return if $line =~ /^sub /;
        if ( !defined $from ) {
            ( $indent ) = $line =~ /^(\s*)while \(1\) \{/ or next;
            $from = $at;
            next;
        }
        return ( substr( $source, $from, $offset - $from ), $from, $offset ) if $line =~ /^\Q$indent\E\}\s*$/;
    }
    return;
}

# A shell command line split into the commands it runs: at ;, &, | and
# newlines outside quotes, so a quoted sed script or grep alternation stays
# with its command.
sub command_segments {
    my ($cmd) = @_;
    my @segments;
    my ( $current, $quote ) = ( '', '' );
    for my $ch ( split //, $cmd ) {
        if    ( $quote ne '' )            { $quote = '' if $ch eq $quote }
        elsif ( $ch eq "'" || $ch eq '"' ) { $quote = $ch }
        elsif ( $ch =~ /[;&|\n]/ )        { push @segments, $current; $current = ''; next }
        $current .= $ch;
    }
    return ( @segments, $current );
}

deny "writes under logs/ are forbidden - the corpora are read-only to Claude"
    if $rel =~ m{^logs/} || $p =~ m{/logs/};
deny "released benchmark baselines are deliverables and are never overwritten"
    if $rel =~ m{^tests/baseline/results/v[0-9][^/]*\.tsv$};
deny "problem reports and tool feedback are never repository content - write them to the scratchpad or /tmp"
    if $rel !~ m{^/} && $rel =~ m{(^|/)(problem-report|feedback-report|tool-feedback)}i;
deny "settings.local.json is machine-local and never edited by Claude"
    if $rel eq '.claude/settings.local.json';

# A feature doc may cite a record (a features/ or docs/ Markdown file) only
# when this session has read it: a Read of the file, or a shell command that
# reads it (cat, sed, head, tail, awk, grep, less, perl, python). A record is
# cited by its path, or by its issue number alone: #451, or 451 before a
# decision label (451 D4) or a possessive (451's), names every
# features/451-*.md. The doc's own number is not a citation. The check reads
# the text being written, so a citation already in the doc is checked only
# when the write repeats it. Records that do not exist in the checkout being
# written (a file still to be created) are not checked.
if ( $p =~ m{^(.*)/features/([^/]+)\.md$} ) {
    my ( $checkout, $own ) = ( $1, $2 );
    my ($own_number) = $own =~ /^(\d+)-/;
    my $ti = $call->{tool_input} // {};
    my $text = join "\n", grep { defined } $ti->{content}, $ti->{new_string},
        map { $_->{new_string} } @{ $ti->{edits} // [] };
    my %cited;
    while ( $text =~ m{(?<![\w/.-])((?:features|docs)/[\w./-]+\.md)}g ) {
        my $record = $1;
        next if $p =~ m{/\Q$record\E$};
        $cited{$record} = 1 if -f "$checkout/$record";
    }
    my %numbers;
    $numbers{$1} = 1 while $text =~ m{(?<![\w#/.-])#(\d{2,5})\b}g;
    $numbers{$1} = 1 while $text =~ m{(?<![\w#/.-])(\d{2,5})(?=(?: [DORF]\d|'s\b))}g;
    delete $numbers{$own_number} if defined $own_number;
    for my $number ( keys %numbers ) {
        for my $file ( glob "$checkout/features/$number-*.md" ) {
            ( my $record = $file ) =~ s{^\Q$checkout\E/}{};
            $cited{$record} = 1;
        }
    }
    my $transcript = $call->{transcript_path} // '';
    if ( %cited && $transcript ne '' && open my $fh, '<', $transcript ) {
        local $/ = "\n";
        my %read;
        while ( my $line = <$fh> ) {
            next unless $line =~ /"tool_use"/;
            my $entry = eval { decode_json($line) } or next;
            my $content = $entry->{message}{content};
            next unless ref $content eq 'ARRAY';
            for my $block (@$content) {
                next unless ref $block eq 'HASH' && ( $block->{type} // '' ) eq 'tool_use';
                my $input = $block->{input} // {};
                my $name  = $block->{name} // '';
                for my $record ( keys %cited ) {
                    if ( $name eq 'Read' ) {
                        $read{$record} = 1 if slashed( $input->{file_path} ) =~ m{/\Q$record\E$};
                    } elsif ( $name eq 'Bash' ) {
                        # The reading command and the record share one
                        # segment of the command line, so a `wc` or `ls` of
                        # the record beside a grep of another file is not a read.
                        $read{$record} = 1
                            if grep { index( $_, $record ) >= 0 && /\b(?:cat|sed|head|tail|awk|grep|less|perl|python3?)\b/ }
                               command_segments( $input->{command} // '' );
                    }
                }
            }
        }
        close $fh;
        my @unread = sort grep { !$read{$_} } keys %cited;
        deny "this feature doc cites records this session has not read: "
           . join( ', ', @unread )
           . ". Read each one before citing it (CLAUDE.md, Before planning)"
            if @unread;
    }
}

# An edit to ltl that changes the per-line read loop asks first: the loop pays
# once per line for everything it carries, so a change to it is weighed
# against what such changes have measured before it is made, not after.
if ( $p =~ m{(?:^|/)ltl$} && -f $p && open my $fh, '<', $p ) {
    my $source = <$fh>;
    close $fh;
    my ( $loop, $from, $to ) = read_loop_span($source);
    if ( defined $loop ) {
        my $ti = $call->{tool_input} // {};
        my $touches = 0;
        for my $old ( grep { defined && $_ ne '' } $ti->{old_string}, map { $_->{old_string} } @{ $ti->{edits} // [] } ) {
            for ( my $at = index( $source, $old ); $at >= 0; $at = index( $source, $old, $at + 1 ) ) {
                $touches = 1 if $at < $to && $at + length($old) > $from;
            }
        }
        if ( defined $ti->{content} ) {
            my ($new_loop) = read_loop_span( $ti->{content} );
            $touches = 1 if ( $new_loop // '' ) ne $loop;
        }
        ask "this edit changes ltl's per-line read loop (read_and_process_logs, its while (1) loop), which pays once per line for everything it carries. "
          . "Before it is made: docs/architecture-patterns.md § Hot-loop discipline (a gate that does not execute measured about 1.6% on access logs), "
          . "and a new per-line or per-value cost is prototyped or measured, and recorded in the owning feature doc, before it is decided (prototype/README.md § When a prototype is required). "
          . "Confirm that record exists"
            if $touches;
    }
}

exit 0;
