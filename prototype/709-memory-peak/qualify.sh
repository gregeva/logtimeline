#!/usr/bin/env bash
# #709 P1: qualify candidate inputs and options before the timed runs. Two
# untimed runs per candidate:
#   census  ltl as tracked, no -mem, -V message-grouping: the checkpoints each
#           group fired, its final-pass windows, whether its final pass was
#           skipped. The section only adds bookkeeping (member keys, accounting
#           stages), never a decision, so its counts are the run's control flow
#   trace   the trace arm, -mem -V benchmark-data,memory-usage: the walks per
#           site and their time, and every store's size at every reading
# qualify-summary.py reads both.
#
#   usage: qualify.sh <arms dir> <output dir> <candidates file> [name ...]
#   candidates file: one per line, name|files (globs, relative to LOGS)|options
set -u
here="$(cd "$(dirname "$0")" && pwd)"
arms="$1"; out="$2"; candidates="$3"; shift 3
LOGS="${LOGS:-$here/../../logs}"
mkdir -p "$out"
while IFS='|' read -r name globs opts; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    if (( $# )) && [[ ! " $* " == *" $name "* ]]; then continue; fi
    files=""
    for g in $globs; do for f in $LOGS/$g; do [[ -f "$f" ]] && files="$files $f"; done; done
    [[ -z "$files" ]] && { echo "$name: no files matched $globs" >&2; continue; }
    # word lists, unquoted on purpose
    ( cd "$out" && "$arms/ltl-tracked" --disable-progress -V benchmark-data,message-grouping $opts $files \
        > "$out/census-$name.out" 2> "$out/census-$name.err" )
    c=$?
    ( cd "$out" && P1_TRACE="$out/trace-$name.tsv" /usr/bin/time -l "$arms/ltl-trace" \
        --disable-progress -V benchmark-data,memory-usage -mem $opts $files \
        > "$out/trace-$name.out" 2> "$out/trace-$name.err" )
    echo "$name: census exit $c, trace exit $? ($(echo $files | wc -w | tr -d ' ') files)"
done < "$candidates"
