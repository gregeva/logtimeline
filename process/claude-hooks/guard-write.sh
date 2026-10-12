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
my $p = $call->{tool_input}{file_path} // $call->{tool_input}{notebook_path} // '';
exit 0 if $p eq '';
my $root = $ENV{CLAUDE_PROJECT_DIR} // '';
my $rel = $p;
$rel =~ s{^\Q$root\E/}{} if $root ne '';

sub deny { print STDERR "[claude-hook] BLOCKED: $_[0]\n"; exit 2 }

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
# reads it (cat, sed, head, tail, awk, grep, less, perl, python). The check
# reads the text being written, so a citation already in the doc is checked
# only when the write repeats it. Records that do not exist in the checkout
# being written (a file still to be created) are not checked.
if ( $p =~ m{^(.*)/features/[^/]+\.md$} ) {
    my $checkout = $1;
    my $ti = $call->{tool_input} // {};
    my $text = join "\n", grep { defined } $ti->{content}, $ti->{new_string},
        map { $_->{new_string} } @{ $ti->{edits} // [] };
    my %cited;
    while ( $text =~ m{(?<![\w/.-])((?:features|docs)/[\w./-]+\.md)}g ) {
        my $record = $1;
        next if $p =~ m{/\Q$record\E$};
        $cited{$record} = 1 if -f "$checkout/$record";
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
                        $read{$record} = 1 if ( $input->{file_path} // '' ) =~ m{/\Q$record\E$};
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

exit 0;
