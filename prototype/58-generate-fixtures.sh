#!/bin/bash
#
# 58-generate-fixtures.sh — regenerate the #58 prototype fixture dataset.
#
# Builds deterministic fixture files into /tmp/ltl-58-fixtures/ from the
# repository's known test logs (docs/test-logs.md). Re-running always
# produces the identical dataset: sources are concatenated in a fixed
# order and sliced with head(1) — no sampling, no randomness.
#
# Fixture families (x sizes 1k / 10k / 100k / 1m):
#   pure-access     Tomcat 9 access log (the #369 regression format)
#   pure-scriptlog  ThingWorx ScriptLog family. Metric-bearing lines (any of
#                   bytes=/count=/durationMs=) are sparse and cluster late in
#                   the pool: none in the first 1k, ~0.5% at 100k, ~13% at 1m
#   pure-scriptlog-dense
#                   ScriptLog-DPMExtended-clean: every line bears at least one
#                   of bytes=/count=/durationMs= at every size — the
#                   message-metric probe fixture. Source is 122,808 lines,
#                   so this family stops at 100k (no 1m size)
#   pure-gc         JVM G1 GC log ([info]; ~29% non-pause lines never match)
#   twx-blend       ThingWorx app-log family incl. ScriptErrorLog stack traces
#                   (~17% at 1m; ScriptErrorLog leads so small sizes are
#                   continuation-heavy) — the no-match population fixture
#   concat-pair     access then scriptlog, format boundary at the midpoint
#                   (the MTF change-point workload)
#   interleave-100  access/scriptlog alternating in 100-line blocks
#                   (stray-line/reorder-churn stress)
#
# Usage: ./prototype/58-generate-fixtures.sh
# Output: /tmp/ltl-58-fixtures/<family>-<size>.log + manifest.tsv

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOGS="$REPO_ROOT/logs"
OUT=/tmp/ltl-58-fixtures
SIZES="1000:1k 10000:10k 100000:100k 1000000:1m"

mkdir -p "$OUT"
WORK="$OUT/.sources"
mkdir -p "$WORK"

echo "Assembling source pools under $WORK ..."

# Pool: access (single file, 1,430,678 lines)
head -n 1000000 "$LOGS/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt" > "$WORK/access.pool"

# Pool: scriptlog with full metrics (concatenated across days, 1,530,399 lines total)
cat "$LOGS/ThingworxLogs/CustomThingworxLogs/ScriptLog.2025-04-09.1.log" \
    "$LOGS/ThingworxLogs/CustomThingworxLogs/ScriptLog.2025-04-09.2.log" \
    "$LOGS/ThingworxLogs/CustomThingworxLogs/ScriptLog.2025-04-09.3.log" \
    "$LOGS/ThingworxLogs/CustomThingworxLogs/ScriptLog.2025-04-09.4.log" \
    "$LOGS/ThingworxLogs/CustomThingworxLogs/ScriptLog.2025-04-10.0.log" \
  > "$WORK/scriptlog.pool.full"
head -n 1000000 "$WORK/scriptlog.pool.full" > "$WORK/scriptlog.pool" && rm "$WORK/scriptlog.pool.full"

# Pool: metric-dense scriptlog (single file, 122,808 lines — 100k max)
head -n 100000 "$LOGS/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log" > "$WORK/scriptlog-dense.pool"

# Pool: GC (two largest rotations, 1,380,464 lines total)
cat "$LOGS/GC/logs-gc/gc-twx01-twx-thingworx-2.out.8" \
    "$LOGS/GC/logs-gc/gc-twx01-twx-thingworx-3.out.6" \
  > "$WORK/gc.pool.full"
head -n 1000000 "$WORK/gc.pool.full" > "$WORK/gc.pool" && rm "$WORK/gc.pool.full"

# Pool: ThingWorx blend with continuation/stack-trace lines (1,015,162 lines total).
# ScriptErrorLog files lead so every slice size contains the no-match population.
cat "$LOGS/ThingworxLogs/ScriptErrorLog.2025-05-05.0.log" \
    "$LOGS/ThingworxLogs/ScriptErrorLog.2025-05-06.0.log" \
    "$LOGS/ThingworxLogs/ScriptErrorLog.log" \
    "$LOGS/ThingworxLogs/ErrorLog.2025-05-05.1.log" \
    "$LOGS/ThingworxLogs/ErrorLog.2025-05-06.0.log" \
    "$LOGS/ThingworxLogs/SecurityLog.2025-05-05.1.log" \
    "$LOGS/ThingworxLogs/SecurityLog.2025-05-06.0.log" \
    "$LOGS/ThingworxLogs/SecurityLog.log" \
  > "$WORK/twx-blend.pool.full"
head -n 1000000 "$WORK/twx-blend.pool.full" > "$WORK/twx-blend.pool" && rm "$WORK/twx-blend.pool.full"

MANIFEST="$OUT/manifest.tsv"
printf 'fixture\tlines\tsources\n' > "$MANIFEST"

emit() { # emit <file> <sources-description>
  local file="$1" desc="$2" lines
  lines=$(wc -l < "$OUT/$file" | tr -d ' ')
  printf '%s\t%s\t%s\n' "$file" "$lines" "$desc" >> "$MANIFEST"
  echo "  $file ($lines lines)"
}

for entry in $SIZES; do
  n=${entry%%:*}; tag=${entry##*:}
  half=$((n / 2))
  echo "Generating size $tag ..."

  head -n "$n" "$WORK/access.pool"    > "$OUT/pure-access-$tag.log"
  emit "pure-access-$tag.log" "AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt"

  head -n "$n" "$WORK/scriptlog.pool" > "$OUT/pure-scriptlog-$tag.log"
  emit "pure-scriptlog-$tag.log" "CustomThingworxLogs/ScriptLog.2025-04-09.1-4 + 2025-04-10.0 (concatenated)"

  if [ "$n" -le 100000 ]; then
    head -n "$n" "$WORK/scriptlog-dense.pool" > "$OUT/pure-scriptlog-dense-$tag.log"
    emit "pure-scriptlog-dense-$tag.log" "CustomThingworxLogs/ScriptLog-DPMExtended-clean.log (100k max; every line metric-bearing)"
  fi

  head -n "$n" "$WORK/gc.pool"        > "$OUT/pure-gc-$tag.log"
  emit "pure-gc-$tag.log" "GC/logs-gc/gc-twx01-twx-thingworx-2.out.8 + -3.out.6 (concatenated)"

  head -n "$n" "$WORK/twx-blend.pool" > "$OUT/twx-blend-$tag.log"
  emit "twx-blend-$tag.log" "ScriptErrorLog 05-05/05-06/current + ErrorLog 05-05/05-06 + SecurityLog 05-05/05-06/current (concatenated)"

  { head -n "$half" "$WORK/access.pool"; head -n "$half" "$WORK/scriptlog.pool"; } > "$OUT/concat-pair-$tag.log"
  emit "concat-pair-$tag.log" "access pool lines 1-$half, then scriptlog pool lines 1-$half"

  perl -e '
    my ($a_file, $b_file, $n, $block) = @ARGV;
    open my $a, "<", $a_file or die "open $a_file: $!";
    open my $b, "<", $b_file or die "open $b_file: $!";
    my $emitted = 0;
    my ($a_open, $b_open) = (1, 1);
    while ($emitted < $n && ($a_open || $b_open)) {
      for my $fh_ref ([\$a, \$a_open], [\$b, \$b_open]) {
        my ($fh, $open) = @$fh_ref;
        next unless $$open;
        for (1 .. $block) {
          last if $emitted >= $n;
          my $line = readline($$fh);
          if (!defined $line) { $$open = 0; last }
          print $line;
          $emitted++;
        }
        last if $emitted >= $n;
      }
    }
    die "interleave underrun: emitted $emitted of $n\n" if $emitted < $n;
  ' "$WORK/access.pool" "$WORK/scriptlog.pool" "$n" 100 > "$OUT/interleave-100-$tag.log"
  emit "interleave-100-$tag.log" "access pool / scriptlog pool alternating 100-line blocks"
done

echo ""
echo "Done. Dataset in $OUT:"
du -sh "$OUT"
echo "Manifest: $MANIFEST"
