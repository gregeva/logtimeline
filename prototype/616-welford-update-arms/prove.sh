#!/usr/bin/env bash
# #616 D12: the behaviour proof. Runs every probe on each selection with the
# statistics written at full precision and the moment sums kept on both stores
# (-o demands the shape statistics), and records each CSV the run wrote, named
# by probe and selection, for compare.pl to read against the base.
#
#   usage: prove.sh <probe dir> <out dir> <selection>...
#     selection: <label>=<options>@<absolute path to the log file>
#   env: CANDIDATES="base b c hoist b-hoist c-hoist" (default)
set -euo pipefail
PROBES="$1"; OUT="$2"; shift 2
CANDIDATES="${CANDIDATES:-base b c hoist b-hoist c-hoist}"
mkdir -p "$OUT"
for sel in "$@"; do
    label="${sel%%=*}"; rest="${sel#*=}"; opts="${rest%@*}"; file="${rest##*@}"
    for c in $CANDIDATES; do
        dir="$OUT/$label/$c"; mkdir -p "$dir"
        # shellcheck disable=SC2086
        (cd "$dir" && "$PROBES/ltl-$c" --disable-progress -ni -o -cp full --terminal-width 200 $opts "$file" > stdout.txt 2> stderr.txt) \
            || { echo "FAIL $label $c" >&2; continue; }
        for kind in MESSAGES STATS; do
            f=$(ls "$dir"/*-LTL-"$kind"-*.csv 2>/dev/null | head -1)
            [[ -n "$f" ]] && mv "$f" "$dir/$kind.csv"
        done
        echo "ran $label $c" >&2
    done
done
