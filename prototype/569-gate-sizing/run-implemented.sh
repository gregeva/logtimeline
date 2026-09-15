#!/usr/bin/env bash
# Run probe-implemented.pl over the ten first-checkpoint batches.
#   usage: run-implemented.sh <batch dir> <out dir> [sources=500]
# <batch dir> holds <family>/batch-plain_<group>.txt dumps (real log content: keep them
# outside the repository); one TSV per batch is written to <out dir>.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
ltl="$here/../../ltl"
batch_dir="$1"
out_dir="$2"
sources="${3:-500}"
mkdir -p "$out_dir"
for b in day-dl/200 app/ERROR day-mixed/200 errors/ERROR script/INFO script/ERROR script/WARN app/DEBUG app/WARN tomcat/200; do
    family="${b%/*}"
    group="${b#*/}"
    label="$family-$group"
    perl "$here/probe-implemented.pl" "$ltl" "$label" "$batch_dir/$family/batch-plain_$group.txt" "$sources" > "$out_dir/$label.tsv"
    echo "wrote $out_dir/$label.tsv"
done
