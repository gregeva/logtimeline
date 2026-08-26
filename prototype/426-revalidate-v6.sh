#!/bin/bash
#
# 426-revalidate-v6.sh — driver for the V6 aspect (display-geometry-bound
# consumers under T, S and G).
#
# Runs the two canonical files across the locked %TIER_BPD rungs that the
# display surfaces can resolve to. #293's tier table gives histogram and
# heatmap [53, 80, 115, 256, 616, 616, 616, 616, 616] — so the distinct
# streaming resolutions those surfaces ever see are 53, 80, 115, 256 and 616.
# The default tier 5 resolves both to 616.
#
# Usage: ./prototype/426-revalidate-v6.sh [outdir]
set -euo pipefail

cd "$(dirname "$0")/.."
OUT="${1:-prototype/426-results}"
DPM=logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log
TOM=logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt

for f in "$DPM" "$TOM"; do
  [ -r "$f" ] || { echo "missing: $f" >&2; exit 2; }
done

run() { # run <tag> <file> <bpd> <bucket-lines>
  local tag="$1" file="$2" bpd="$3" bl="$4"
  local dir="$OUT/v6-$tag-$bpd"
  mkdir -p "$dir"
  echo "=== $tag bpd=$bpd ==="
  perl prototype/426-revalidate-v6.pl --file "$file" --bpd "$bpd" \
       --bucket-lines "$bl" --out "$dir" > "$dir/run.txt" 2>&1
  grep -E '^(PART A|PART D  T vs S|  [TSG] )' "$dir/run.txt" | head -20
}

for bpd in 53 80 115 256 616; do
  run dpm    "$DPM" "$bpd" 5000
  run tomcat "$TOM" "$bpd" 24000
done

# One combined TSV for the report.
head -1 "$OUT/v6-dpm-53/revalidate-v6.tsv" > "$OUT/v6-all.tsv"
for d in "$OUT"/v6-*-*/revalidate-v6.tsv; do tail -n +2 "$d"; done >> "$OUT/v6-all.tsv"
echo "combined: $OUT/v6-all.tsv ($(( $(wc -l < "$OUT/v6-all.tsv") - 1 )) rows)"
