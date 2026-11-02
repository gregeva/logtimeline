#!/usr/bin/env bash
# Checks that CLAUDE.md is within its budget: at most $MAX_LINES lines and
# $MAX_CHARS characters (docs/architecture-patterns.md, Instruction files).
# Run by process/claude-hooks/guard-write.sh on the content a write would
# leave and by .githooks/pre-commit on the staged file; usable by hand:
#   process/check-claude-md.sh <file>
set -euo pipefail

MAX_LINES=250
MAX_CHARS=20000
file=${1:?usage: $0 <file>}

read -r lines chars < <(perl -CSD -e 'local $/; my $t = <STDIN> // ""; my $l = ($t =~ tr/\n//); print "$l ", length($t), "\n"' < "$file")

status=0
if [ "$lines" -gt "$MAX_LINES" ]; then
    echo "CLAUDE.md: $lines lines, budget $MAX_LINES" >&2
    status=1
fi
if [ "$chars" -gt "$MAX_CHARS" ]; then
    echo "CLAUDE.md: $chars characters, budget $MAX_CHARS" >&2
    status=1
fi
exit $status
