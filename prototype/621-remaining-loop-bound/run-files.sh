#!/usr/bin/env bash
# #621: interleaved timing rounds over a run of many files, the multi-file
# counterpart of prototype/342-read-loop-cost-curve/run-curve.sh (same order
# balancing, same invocation, the same TSV columns).
#
#   usage: run-files.sh <probe dir> <results tsv> <rounds> <label> <file>...
#   env: CANDIDATES="base gen-file gen-run" (default), EXTRA="" (options added
#        to the benchmark runner's invocation, e.g. "-bs 480")
set -euo pipefail
PROBES="$1"; TSV="$2"; ROUNDS="$3"; LABEL="$4"; shift 4
CANDIDATES="${CANDIDATES:-base gen-file gen-run}"
read -r -a cands <<< "$CANDIDATES"
read -r -a extra <<< "${EXTRA:-}"
SCRATCH="$(mktemp -d)"
[[ -s "$TSV" ]] || printf 'round\tcandidate\tfile\ttiming_total\trss_peak\tlog_messages_entries\n' > "$TSV"
for r in $(seq 1 "$ROUNDS"); do
    order=("${cands[@]}")
    if (( r % 2 == 0 )); then
        order=(); for (( i=${#cands[@]}-1; i>=0; i-- )); do order+=("${cands[$i]}"); done
    fi
    for c in "${order[@]}"; do
        out=$(cd "$SCRATCH" && "$PROBES/ltl-$c" --disable-progress -V benchmark-data -mem --terminal-width 200 -bs 60 "${extra[@]}" "$@" 2>&1) || { echo "FAIL round $r $c" >&2; continue; }
        t=$(printf '%s\n' "$out" | awk -F'\t' '$1=="TIMING" && $2=="total"{print $3}')
        m=$(printf '%s\n' "$out" | awk -F'\t' '$1=="MEMORY" && $2=="rss_peak"{print $3}')
        l=$(printf '%s\n' "$out" | awk -F'\t' '$1=="COUNTS" && $2=="log_messages_entries"{print $3}')
        printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$r" "$c" "$LABEL" "$t" "$m" "$l" >> "$TSV"
        echo "round $r $LABEL $c total=$t" >&2
    done
done
rmdir "$SCRATCH" 2>/dev/null || true
echo "done: $TSV" >&2
