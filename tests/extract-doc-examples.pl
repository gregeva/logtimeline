#!/usr/bin/env perl
# extract-doc-examples.pl — Stream a markdown file and emit one TSV row
# per testable `ltl …` invocation inside a qualifying fenced code block.
#
# Output format (one row per emitted command, tab-separated):
#   file<TAB>line<TAB>command
# where `line` is the source line number of the command itself (not the
# opening fence).
#
# A fence qualifies for testing when:
#   - Its info-string is `bash`, `sh`, `shell`, or empty.
#   - It is not preceded by an `<!-- ltl-test: skip -->` HTML comment
#     on a line immediately above the opening fence (with or without
#     blank lines between).
# Inside a qualifying fence, every line whose first non-whitespace token
# is `ltl ` or `./ltl ` is emitted as one row. Comment lines (`#`) are
# ignored. Multi-line `ltl` invocations using `\` line continuations are
# joined into a single command before emission.
#
# Driver: tests/validate-doc-examples.sh (issue #234).

use strict;
use warnings;

@ARGV or die "Usage: extract-doc-examples.pl <markdown-file> [<markdown-file>...]\n";

for my $file (@ARGV) {
    open my $fh, '<', $file or do {
        warn "extract-doc-examples.pl: cannot open $file: $!\n";
        next;
    };

    my $in_fence       = 0;
    my $fence_lang     = '';
    my $fence_skip     = 0;
    my $pending_skip   = 0;   # set when an `<!-- ltl-test: skip -->` HTML
                              # comment is seen; consumed by the next fence
    my $line_no        = 0;
    my $continuation   = '';  # multi-line `ltl … \` accumulator
    my $continuation_line = 0;

    while (my $line = <$fh>) {
        $line_no++;
        chomp $line;

        if (!$in_fence) {
            # Skip annotation lookahead.
            if ($line =~ /^\s*<!--\s*ltl-test:\s*skip\s*-->\s*$/) {
                $pending_skip = 1;
                next;
            }
            # Blank lines between annotation and fence are tolerated.
            if ($pending_skip && $line =~ /\S/ && $line !~ /^```/) {
                $pending_skip = 0;
            }
            # Fence open.
            if ($line =~ /^```\s*(\S*)\s*$/) {
                $fence_lang = lc($1 // '');
                # Only run bash/sh/shell or unlabelled fences.
                if ($fence_lang eq '' || $fence_lang =~ /^(bash|sh|shell)$/) {
                    $in_fence  = 1;
                    $fence_skip = $pending_skip;
                } else {
                    # Non-shell fence: treat the inside as opaque content
                    # we ignore until the closing fence.
                    $in_fence  = 1;
                    $fence_skip = 1;
                }
                $pending_skip = 0;
            }
            next;
        }

        # Inside a fence.
        if ($line =~ /^```\s*$/) {
            # Flush any pending continuation first.
            if ($continuation ne '') {
                _emit($file, $continuation_line, $continuation) unless $fence_skip;
                $continuation = '';
            }
            $in_fence   = 0;
            $fence_lang = '';
            $fence_skip = 0;
            next;
        }

        next if $fence_skip;

        # Handle line continuations: accumulate until the trailing `\` is gone.
        if ($continuation ne '') {
            my $next = $line;
            $next =~ s/^\s+//;
            if ($next =~ s/\\\s*$//) {
                $continuation .= ' ' . $next;
            } else {
                $continuation .= ' ' . $next;
                _emit($file, $continuation_line, $continuation);
                $continuation = '';
            }
            next;
        }

        # Strip comment-only lines.
        next if $line =~ /^\s*#/;
        next if $line =~ /^\s*$/;

        # Is this a candidate ltl command line?
        my $stripped = $line;
        $stripped =~ s/^\s+//;
        next unless $stripped =~ /^(\.\/)?ltl(\s|$)/;

        if ($stripped =~ s/\\\s*$//) {
            $continuation      = $stripped;
            $continuation_line = $line_no;
        } else {
            _emit($file, $line_no, $stripped);
        }
    }

    # File ended mid-continuation: still emit what we have.
    if ($continuation ne '') {
        _emit($file, $continuation_line, $continuation) unless $fence_skip;
    }

    close $fh;
}

sub _emit {
    my ($file, $line, $cmd) = @_;
    $cmd =~ s/\s+$//;
    print join("\t", $file, $line, $cmd), "\n";
}
