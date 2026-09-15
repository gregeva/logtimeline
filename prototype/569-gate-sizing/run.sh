#!/usr/bin/env bash
# Run probe.pl over first-checkpoint batches, one at a time so timings are not
# contended. Each batch file is <batch dir>/<family>/batch-<category>_<group>.txt,
# as written by a copy of ltl that dumps run_consolidation_checkpoint()'s first batch.
#   usage: run.sh <batch dir> <output dir> [sources=500] [timed passes=3]
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
batches="$1"; out="$2"; n_src="${3:-500}"; passes="${4:-3}"
mkdir -p "$out"
"$here/extract-subs.sh" "$out/subs.pl"
# Reported cases first, then the families where the shipped gate is lossless.
for b in day-dl/batch-plain_200 app/batch-plain_ERROR day-mixed/batch-plain_200 \
         errors/batch-plain_ERROR script/batch-plain_INFO script/batch-plain_ERROR \
         script/batch-plain_WARN app/batch-plain_DEBUG app/batch-plain_WARN tomcat/batch-plain_200; do
    label="${b%%/*}-${b##*_}"
    echo "$(date +%H:%M:%S) $label" >> "$out/progress.txt"
    perl "$here/probe.pl" "$out/subs.pl" "$label" "$batches/$b.txt" "$n_src" "$passes" \
        > "$out/$label.tsv" 2> "$out/$label.err"
done
echo "$(date +%H:%M:%S) ALL_DONE" >> "$out/progress.txt"
