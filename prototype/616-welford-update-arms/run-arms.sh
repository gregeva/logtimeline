#!/usr/bin/env bash
# #616 D12: interleaved timing rounds over the probe binaries.
#
# The driver of prototype/342-read-loop-cost-curve/run-curve.sh with options per
# selection: every candidate runs once per round on each selection, odd rounds
# forward and even rounds in reverse (order-balanced, so drift inside a round is
# shared and its direction alternates), with the benchmark runner's invocation
# (tests/baseline/run-benchmark.sh run_test: --terminal-width 200 -bs 60), and
# records the tool's own TIMING total and rss_peak per run. Nothing else should
# run on the host while this does.
#
#   usage: run-arms.sh <probe dir> <results tsv> <rounds> <selection>...
#     selection: <label>=<options>@<absolute path to the log file>
#   env: CANDIDATES="base b c hoist b-hoist c-hoist" (default)
set -euo pipefail
PROBES="$1"; TSV="$2"; ROUNDS="$3"; shift 3
CANDIDATES="${CANDIDATES:-base b c hoist b-hoist c-hoist}"
read -r -a cands <<< "$CANDIDATES"
SCRATCH="$(mktemp -d)"
[[ -s "$TSV" ]] || printf 'round\tcandidate\tselection\ttiming_total\trss_peak\n' > "$TSV"
for r in $(seq 1 "$ROUNDS"); do
    order=("${cands[@]}")
    if (( r % 2 == 0 )); then
        order=(); for (( i=${#cands[@]}-1; i>=0; i-- )); do order+=("${cands[$i]}"); done
    fi
    for sel in "$@"; do
        label="${sel%%=*}"; rest="${sel#*=}"; opts="${rest%@*}"; file="${rest##*@}"
        for c in "${order[@]}"; do
            # shellcheck disable=SC2086
            out=$(cd "$SCRATCH" && "$PROBES/ltl-$c" --disable-progress -V benchmark-data -mem --terminal-width 200 -bs 60 $opts "$file" 2>&1) \
                || { echo "FAIL round $r $c $label" >&2; continue; }
            t=$(printf '%s\n' "$out" | awk -F'\t' '$1=="TIMING" && $2=="total"{print $3}')
            m=$(printf '%s\n' "$out" | awk -F'\t' '$1=="MEMORY" && $2=="rss_peak"{print $3}')
            printf '%s\t%s\t%s\t%s\t%s\n' "$r" "$c" "$label" "$t" "$m" >> "$TSV"
            echo "round $r $label $c total=$t" >&2
        done
    done
done
rm -rf "$SCRATCH"
echo "done: $TSV" >&2
