#!/bin/bash
#
# 426-generate-fixtures.sh — regenerate the #426 prototype fixture dataset.
#
# Builds deterministic fixture files into /tmp/ltl-426-fixtures/ from the
# repository's known test logs (docs/test-logs.md). Re-running always
# produces the identical dataset: sources are sliced with head(1) — no
# sampling, no randomness.
#
# Fixture families:
#   twx-unique   ThingWorx application log, hundreds of thousands of distinct
#                error messages (the humungous-log-uniqueness construct). The
#                non-access-log store path: one field per entry, ~1 key per
#                line. Sizes 1k / 10k / 100k / full (288,025 lines — the
#                source is smaller than 1m, so this ladder tops out at full).
#   access       Tomcat 9 access log with %D durations. The access-log store
#                path: multi-field entries + per-key durations[] array at
#                realistic (low) key cardinality. Sizes 1k / 10k / 100k / 1m.
#
# Usage: [LTL_LOGS=/path/to/logs] ./prototype/426-generate-fixtures.sh
# Output: /tmp/ltl-426-fixtures/<family>-<size>.log + manifest.tsv

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOGS="${LTL_LOGS:-$REPO_ROOT/logs}"
OUT=/tmp/ltl-426-fixtures
mkdir -p "$OUT"

TWX="$LOGS/ThingworxLogs/HundredsOfThousandsOfUniqueErrors.log"
ACCESS="$LOGS/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt"
[ -r "$TWX" ]    || { echo "missing source: $TWX" >&2; exit 2; }
[ -r "$ACCESS" ] || { echo "missing source: $ACCESS" >&2; exit 2; }

MANIFEST="$OUT/manifest.tsv"
printf 'fixture\tlines\tsource\n' > "$MANIFEST"

emit() { # emit <file> <source-description>
  local file="$1" desc="$2" lines
  lines=$(wc -l < "$OUT/$file" | tr -d ' ')
  printf '%s\t%s\t%s\n' "$file" "$lines" "$desc" >> "$MANIFEST"
  echo "  $file ($lines lines)"
}

for entry in 1000:1k 10000:10k 100000:100k; do
  n=${entry%%:*}; tag=${entry##*:}
  head -n "$n" "$TWX" > "$OUT/twx-unique-$tag.log"
  emit "twx-unique-$tag.log" "ThingworxLogs/HundredsOfThousandsOfUniqueErrors.log lines 1-$n"
done
cp "$TWX" "$OUT/twx-unique-full.log"
emit "twx-unique-full.log" "ThingworxLogs/HundredsOfThousandsOfUniqueErrors.log (whole file)"

for entry in 1000:1k 10000:10k 100000:100k 1000000:1m; do
  n=${entry%%:*}; tag=${entry##*:}
  head -n "$n" "$ACCESS" > "$OUT/access-$tag.log"
  emit "access-$tag.log" "AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt lines 1-$n"
done

# Bin-mode families (426-bin-store-mini.pl):
#   bin-dpm     ScriptLog-DPMExtended-clean: every line metric-bearing, ~3.4k
#               distinct messages, ~36 samples each — the real percentile-
#               traversal case. Source is 122,808 lines (full = whole file).
#   bin-twxdur  SYNTHETIC: the twx-unique lines with a deterministic
#               ` durationMs=N` appended (N = 1 + (line_no * 7919) mod 30000,
#               i.e. spread over ~4.5 decades, ~1 sample per key) — the
#               high-cardinality memory case, which no corpus file provides
#               with durations.
DPM="$LOGS/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log"
[ -r "$DPM" ] || { echo "missing source: $DPM" >&2; exit 2; }
for entry in 1000:1k 10000:10k 100000:100k; do
  n=${entry%%:*}; tag=${entry##*:}
  head -n "$n" "$DPM" > "$OUT/bin-dpm-$tag.log"
  emit "bin-dpm-$tag.log" "ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log lines 1-$n"
done
cp "$DPM" "$OUT/bin-dpm-full.log"
emit "bin-dpm-full.log" "ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log (whole file)"

for tag in 100k full; do
  perl -pe 's/\r?\n$//; $_ .= " durationMs=" . (1 + ($. * 7919) % 30000) . "\n"' "$OUT/twx-unique-$tag.log" > "$OUT/bin-twxdur-$tag.log"
  emit "bin-twxdur-$tag.log" "twx-unique-$tag.log + synthetic ' durationMs=N', N = 1 + (line_no * 7919) mod 30000"
done

echo ""
echo "Done. Dataset in $OUT:"
du -sh "$OUT"
echo "Manifest: $MANIFEST"
