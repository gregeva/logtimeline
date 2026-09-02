#!/usr/bin/env perl
# Claude Code PreToolUse hook for the Bash tool (wired in .claude/settings.json).
# Reads the tool call as JSON on stdin and enforces the mechanical rules from
# CLAUDE.md that a command string can be checked against. Exit 2 blocks the call
# and returns the message to Claude; a JSON "ask" decision hands the call to the
# architect for an explicit yes.
use strict;
use warnings;
use JSON::PP;

local $/;
my $in = <STDIN> // '';
my $call = eval { decode_json($in) } || {};
my $c = $call->{tool_input}{command} // '';
exit 0 if $c eq '';

# Command-shape rules look at the commands, not at the text they carry:
# heredoc bodies and quoted -m messages are removed first. The trailer rule
# below reads the full text on purpose.
my $cmd = $c;
$cmd =~ s/<<-?\s*(['"]?)(\w+)\1[^\n]*\n.*?\n\s*\2(?=\n|$)/<<HEREDOC/gs;
$cmd =~ s/(-m|--message)(=|\s+)(['"])(?:\\.|(?!\3).)*\3/$1 MSG/gs;

sub deny { print STDERR "[claude-hook] BLOCKED: $_[0]\n"; exit 2 }
sub ask  {
    print encode_json({ hookSpecificOutput => {
        hookEventName => 'PreToolUse', permissionDecision => 'ask',
        permissionDecisionReason => "[claude-hook] $_[0]" } });
    exit 0;
}

# --- logs/ and untracked corpora are read-only (CLAUDE.md § Repository hygiene)
deny "destructive operation targets logs/ - the corpora are unrecoverable; propose it to the architect instead"
    if $cmd =~ /(^|[;&|(]\s*)(sudo\s+)?(rm|mv|rmdir|shred|truncate|unlink)\b[^;&|]*\blogs\//;
deny "'git clean' is never run in this repository (untracked artifacts are read-only)"
    if $cmd =~ /\bgit\s+clean\b/;
deny "'git checkout -- .' discards the working tree; name the file, or propose it"
    if $cmd =~ /\bgit\s+checkout\s+--\s+\.(\s|$)/;
deny "redirect would truncate a file under logs/"
    if $cmd =~ /(^|[^>])>\s*logs\//;

# --- every direct ltl run carries --disable-progress
if ($cmd =~ /(^|[;&|(]\s*|\b(?:time|caffeinate\s+-s)\s+)(?:\.\/|\S*\/)?ltl(\s|$)/
    && $cmd !~ /--disable-progress/
    && $cmd !~ /(^|[;&|(]\s*|\s)(?:\.\/|\S*\/)?ltl\s+(-v|--version|-h|--help|--explain)\b/) {
    deny "ltl invoked without --disable-progress (progress output wastes tokens; CLAUDE.md § Before running a command)";
}

# --- merges go through PRs; release branches are preserved
deny "'git merge' is never used here - open a PR with gh pr create and merge it with gh pr merge"
    if $cmd =~ /\bgit\s+merge\b/;
deny "direct push to main - main is updated only by merging the release PR"
    if $cmd =~ /\bgit\s+push\b[^;&|]*\bmain\b/;
deny "--delete-branch is never used - feature branches are deleted explicitly after release, release branches never"
    if $cmd =~ /--delete-branch\b/;

# --- commit trailer is model-agnostic (reads the full text, message included)
deny "commit message names a model version - the trailer is 'Co-Authored-By: Claude <noreply\@anthropic.com>'"
    if $cmd =~ /\bgit\s+commit\b/ && $c =~ /Claude\s+(Opus|Sonnet|Haiku|Fable|Mythos)\b|claude-(opus|sonnet|haiku|fable|mythos)-/i;

# --- release-only instruments and guard overrides need the architect's yes
ask "run-benchmark.sh full/xl/all is a release-gate instrument (about 2.5 h), never a development tool - confirm this is the release cut"
    if $cmd =~ /run-benchmark\.sh\s+(full|xl|all)\b/;
ask "commit with --no-verify bypasses the pre-commit guard - confirm"
    if $cmd =~ /\bgit\s+commit\b[^;&|]*--no-verify\b/;

exit 0;
