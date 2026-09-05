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

deny "writes under logs/ are forbidden - the corpora are read-only to Claude"
    if $rel =~ m{^logs/} || $p =~ m{/logs/};
deny "released benchmark baselines are deliverables and are never overwritten"
    if $rel =~ m{^tests/baseline/results/v[0-9][^/]*\.tsv$};
deny "problem reports and tool feedback are never repository content - write them to the scratchpad or /tmp"
    if $rel !~ m{^/} && $rel =~ m{(^|/)(problem-report|feedback-report|tool-feedback)}i;
deny "settings.local.json is machine-local and never edited by Claude"
    if $rel eq '.claude/settings.local.json';

exit 0;
