#!/bin/bash
# 426-revalidate-v4.sh — driver for aspect V4 (the -V histogram-bin-counters
# section under the proposed representation). Run from the repo root.
# Captures everything under prototype/426-results/revalidate-v4-*.txt.
set -e
R=prototype/426-results
F=logs/AccessLogs/localhost_access_log.2025-03-21.txt
COMMON="--disable-progress -ni -V histogram-bin-counters,percentile-algorithm --terminal-width 200 -bs 1440 -oe"

# 1. Real ltl output (the shape the prototype must match), one run per scenario
#    that today's lever can express. NB: the first capture uses only
#    -V histogram-bin-counters (the section the field diff reads).
./ltl --disable-progress -ni -mdm bin -V histogram-bin-counters --terminal-width 200 -bs 1440 -oe $F > $R/revalidate-v4-ltl-real.txt 2>&1
./ltl $COMMON -mdm bin -dmp 7 $F > $R/revalidate-v4-ltl-real-dmp7.txt 2>&1
./ltl $COMMON -mdm bin -dmp 9 $F > $R/revalidate-v4-ltl-real-dmp9.txt 2>&1
./ltl $COMMON -mdm raw        $F > $R/revalidate-v4-ltl-real-raw.txt  2>&1

# 2. All arms, all scenarios, one process (parity digests printed before each
#    scenario's blocks; exit non-zero on T/S divergence).
perl prototype/426-revalidate-v4.pl --file $F > $R/revalidate-v4-all.txt 2>&1

# 3. Field-set and value diff of the prototype's arm-T block against the real
#    section (counter_memory_bytes masked — Devel::Size of two different
#    processes' hashes; both values are reported in the md).
section() { sed -n '/^=== histogram-bin-counters ===/,/^=== END histogram-bin-counters ===/p' "$1"; }
proto_block() { # file scenario arm -> the first section after that banner
  awk -v s="# Scenario $2:" -v a="# arm: $3 " '
    $0 ~ "^"s { inS=1 } inS && index($0,a)==1 { inA=1 } inA && /^=== histogram-bin-counters ===/ { p=1 }
    p { print } p && /^=== END histogram-bin-counters ===/ { exit }' "$1"; }
mask() { sed 's/counter_memory_bytes: [0-9]*/counter_memory_bytes: N/'; }
{
  for pair in "1:revalidate-v4-ltl-real.txt" "2:revalidate-v4-ltl-real-dmp7.txt" "3:revalidate-v4-ltl-real-dmp9.txt" "6:revalidate-v4-ltl-real-raw.txt"; do
    s=${pair%%:*}; f=${pair#*:}
    for arm in T S; do
      echo "--- scenario $s arm $arm vs $f (counter_memory_bytes masked)"
      if diff <(section $R/$f | mask) <(proto_block $R/revalidate-v4-all.txt $s $arm | mask); then echo "IDENTICAL"; fi
      echo "counter_memory_bytes real=$(section $R/$f | grep -o 'counter_memory_bytes: [0-9]*' | cut -d' ' -f2) proto_$arm=$(proto_block $R/revalidate-v4-all.txt $s $arm | grep -o 'counter_memory_bytes: [0-9]*' | cut -d' ' -f2)"
    done
    echo "--- scenario $s arm G (locked field set) vs $f: field NAMES"
    if diff <(section $R/$f | sed -n 's/^\(  [a-z_]*\):.*/\1/p') <(proto_block $R/revalidate-v4-all.txt $s G | sed -n 's/^\(  [a-z_]*\):.*/\1/p'); then echo "FIELD NAMES IDENTICAL"; fi
    echo "--- scenario $s arm G (locked field set) vs $f: VALUES (unmasked)"
    diff <(section $R/$f) <(proto_block $R/revalidate-v4-all.txt $s G) || true
  done
} > $R/revalidate-v4-diff.txt 2>&1

# 4. Timing + memory, one arm per process, scenario 1 (bpd 53) and 3 (bpd 616):
#    one warmup + 3 timed runs of telemetry + audit + render; RSS delta of the
#    store build is clean here because each process builds exactly one store.
for arm in T S G; do
  perl prototype/426-revalidate-v4.pl --file $F --arm $arm --scenario 1,3 --timing 3 > $R/revalidate-v4-timing-$arm.txt 2>&1
done
grep -h '^timing\|^rss_delta\|^file:' $R/revalidate-v4-timing-*.txt > $R/revalidate-v4-timing.tsv
echo done
