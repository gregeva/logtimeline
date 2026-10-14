#!/usr/bin/env bash
# #342 item 8: interleaved timing rounds over the probe binaries.
#
# Runs every candidate once per round on each file, odd rounds forward and even
# rounds in reverse (order-balanced, so drift inside a round is shared and its
# direction alternates), with the benchmark runner's exact invocation, and
# records the tool's own TIMING total and rss_peak per run. Nothing else should
# run on the host while this does.
#
#   usage: run-curve.sh <probe dir> <results tsv> <rounds> <file selection>...
#     file selection: <label>=<absolute path to the log file>
#   env: CANDIDATES="base gate-10 ..." (default: all eleven)
set -euo pipefail
PROBES="$1"; TSV="$2"; ROUNDS="$3"; shift 3
CANDIDATES="${CANDIDATES:-base gate-10 gate-20 gate-40 str-10 str-20 str-40 hash-10 hash-20 hash-40 hoist}"
read -r -a cands <<< "$CANDIDATES"
SCRATCH="$(mktemp -d)"
[[ -s "$TSV" ]] || printf 'round\tcandidate\tfile\ttiming_total\trss_peak\tlog_messages_entries\n' > "$TSV"
for r in $(seq 1 "$ROUNDS"); do
    order=("${cands[@]}")
    if (( r % 2 == 0 )); then
        order=(); for (( i=${#cands[@]}-1; i>=0; i-- )); do order+=("${cands[$i]}"); done
    fi
    for sel in "$@"; do
        label="${sel%%=*}"; file="${sel#*=}"
        for c in "${order[@]}"; do
            bin="$PROBES/ltl-$c"
            out=$(cd "$SCRATCH" && "$bin" --disable-progress -V benchmark-data -mem --terminal-width 200 -bs 60 "$file" 2>&1) || { echo "FAIL round $r $c $label" >&2; continue; }
            t=$(printf '%s\n' "$out" | awk -F'\t' '$1=="TIMING" && $2=="total"{print $3}')
            m=$(printf '%s\n' "$out" | awk -F'\t' '$1=="MEMORY" && $2=="rss_peak"{print $3}')
            l=$(printf '%s\n' "$out" | awk -F'\t' '$1=="COUNTS" && $2=="log_messages_entries"{print $3}')
            printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$r" "$c" "$label" "$t" "$m" "$l" >> "$TSV"
            echo "round $r $label $c total=$t" >&2
        done
    done
done
rm -rf "$SCRATCH"
echo "done: $TSV" >&2
