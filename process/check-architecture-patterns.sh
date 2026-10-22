#!/usr/bin/env bash
# Checks that every entry of docs/architecture-patterns.md is an index entry:
# a definition, intended uses, reasoning, consumption sites, an owning record
# and a status, at most $MAX_LINES lines from its "## " heading to its "---"
# rule, with the owning record naming the docs/ or features/ file where the
# complete pattern lives, or stating that this entry is the record. An entry
# already over the limit in the base version passes as long as it has not
# grown. Run by .githooks/pre-commit on the staged file; usable by hand:
#   process/check-architecture-patterns.sh <file> [<base-file>]
set -euo pipefail

MAX_LINES=60
file=${1:?usage: $0 <file> [<base-file>]}
base=${2:-}

# "<lines>\t<owning record found>\t<heading>" per entry
entry_table() {
    awk '
        function flush() { if (h != "") printf "%d\t%d\t%s\n", n, rec, h }
        /^## / { flush(); h = $0; n = 0; rec = 0; inrec = 0 }
        h != "" { n++ }
        /^\*\*Owning record\.\*\*/ { inrec = 1 }
        inrec && (/(docs|features)\/[A-Za-z0-9._\/-]+\.md/ || /This entry/) { rec = 1 }
        /^\*\*[A-Z][a-z ]*\.\*\*/ && !/^\*\*Owning record\.\*\*/ { inrec = 0 }
        /^---/ { inrec = 0 }
        END { flush() }
    ' "$1"
}

base_table=""
[ -n "$base" ] && base_table=$(entry_table "$base")

status=0
while IFS=$'\t' read -r n rec h; do
    if [ "$rec" -ne 1 ]; then
        echo "architecture-patterns: '$h' has no owning record naming a docs/ or features/ file, or stating that this entry is the record" >&2
        status=1
    fi
    if [ "$n" -gt "$MAX_LINES" ]; then
        was=$(printf '%s\n' "$base_table" | awk -F'\t' -v h="$h" '$3 == h { print $1; exit }')
        if [ -z "$was" ] || [ "$n" -gt "$was" ]; then
            echo "architecture-patterns: '$h' is $n lines; an entry is an index entry of at most $MAX_LINES lines, and the complete pattern is its own docs/ file" >&2
            status=1
        fi
    fi
done < <(entry_table "$file")
exit $status
