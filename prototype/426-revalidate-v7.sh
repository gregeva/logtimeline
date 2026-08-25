#!/bin/bash
# Driver for V7 (bucket-stats surface). One process per (file,bpd,arm) so the
# RSS delta in Part 4 is a single-store measurement, plus an --arm all pass per
# (file,bpd) for parity and the cross-arm accuracy/clamp tables.
set -u
cd "$(dirname "$0")/.."
OUT=prototype/426-results/v7
mkdir -p "$OUT"
BPDS="16 32 53 115 616"

run() {   # run <tag> <file> <bucket-size> <extra-args...>
  local tag=$1 file=$2 bs=$3; shift 3
  for bpd in $BPDS; do
    echo "=== $tag bpd=$bpd arm=all ==="
    perl prototype/426-revalidate-v7.pl --file "$file" --bpd "$bpd" \
         --bucket-size "$bs" --arm all "$@" > "$OUT/$tag-bpd$bpd-all.txt" 2>&1 || echo "FAILED"
    for arm in T S G; do
      perl prototype/426-revalidate-v7.pl --file "$file" --bpd "$bpd" \
           --bucket-size "$bs" --arm "$arm" "$@" > "$OUT/$tag-bpd$bpd-$arm.txt" 2>&1 || echo "FAILED $arm"
    done
  done
}

# DPM ScriptLog (full fixture: 122,808 lines) — bucket size 2000 gives ~55 buckets.
run dpm /tmp/ltl-426-fixtures/bin-dpm-full.log 2000

# Tomcat access log, the 148 MB canonical file. Bucket size 20000 keeps the
# bucket count in the surface's real range (tens to hundreds) at this N.
run tomcat "logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt" 20000

echo "DONE"
