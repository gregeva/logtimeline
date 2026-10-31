#!/usr/bin/env bash
# #709 P1: one run of the trace arm per input, untimed. Each writes a record
# per reading (site, held keys, clusters, RSS, the walk's time, every store's
# size) for simulate.py to replay the conditional arms over any margin.
#
#   usage: trace.sh <arms dir> <output dir>      (LOGS defaults to the repo's logs/)
set -u
here="$(cd "$(dirname "$0")" && pwd)"
arms="$1"; out="$2"
LOGS="${LOGS:-$here/../../logs}"
source "$here/inputs.sh"
mkdir -p "$out"
for input in "${INPUTS[@]}"; do
    # word lists, unquoted on purpose
    files=$(input_files "$input"); opts=$(input_options "$input")
    ( cd "$out" && P1_TRACE="$out/trace-$input.tsv" /usr/bin/time -l "$arms/ltl-trace" \
        --disable-progress -V benchmark-data,memory-usage -mem $opts $files \
        > "$out/trace-$input.out" 2> "$out/trace-$input.err" )
    echo "$input: exit $? $(grep -c '^reading' "$out/trace-$input.tsv") readings"
done
