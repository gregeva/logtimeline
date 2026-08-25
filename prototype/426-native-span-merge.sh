#!/usr/bin/env bash
# Driver for #426 N2 (native span merge). Captures every result once, under
# prototype/426-results/native-span-merge/.
set -u
cd "$(dirname "$0")/.."
OUT=prototype/426-results/native-span-merge
mkdir -p "$OUT"
FANOUT=/tmp/ltl-426-fixtures/bin-twxdur-full.log
DPM=/tmp/ltl-426-fixtures/bin-dpm-full.log

case "${1:-all}" in
  parity)
    perl prototype/426-native-span-merge.pl --mode parity --bpd 53  > "$OUT/parity-edge-bpd53.txt" 2>&1
    perl prototype/426-native-span-merge.pl --mode parity --bpd 616 > "$OUT/parity-edge-bpd616.txt" 2>&1
    for b in 53 616; do
      perl prototype/426-native-span-merge.pl --mode parity --bpd $b --file "$DPM" --pairs 725 \
        > "$OUT/parity-dpm-bpd$b.txt" 2>&1
    done
    ;;
  timing)
    B=$2; LIM=${3:-0}; PAIRS=${4:-725}; TAG=${5:-full}
    caffeinate -s perl prototype/426-native-span-merge.pl --mode timing --bpd "$B" \
      --file "$FANOUT" --limit "$LIM" --pairs "$PAIRS" --runs 3 \
      > "$OUT/timing-fanout-$TAG-bpd$B.txt" 2>&1
    echo "exit=$? -> $OUT/timing-fanout-$TAG-bpd$B.txt"
    ;;
esac
