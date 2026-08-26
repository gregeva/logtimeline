#!/bin/bash
# Driver for prototype/426-revalidate-v3.pl — captures every run under
# prototype/426-results/revalidate-v3-*.txt. Run from the repo root.
#
#   Part A per-arm processes (memory/RSS + timing, one arm per process, 3 timed
#   runs after a warmup) at bpd 53 and 616 on the #189 V3 277 MB Tomcat file;
#   Part A --arm all at each bpd (T/S digest assertion + per-key T-vs-G comparison
#   + per-key TSV); Part B; Part C.
set -u
cd "$(dirname "$0")/.." || exit 1
OUT=prototype/426-results
FILE=${FILE:-logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt}
RUNS=${RUNS:-3}
rc=0
for bpd in 53 616; do
  for arm in T S G; do
    perl prototype/426-revalidate-v3.pl --part A --arm $arm --bpd $bpd --runs $RUNS --file "$FILE" \
      > "$OUT/revalidate-v3-partA-arm$arm-bpd$bpd.txt" 2>&1 || rc=1
  done
  perl prototype/426-revalidate-v3.pl --part A --arm all --bpd $bpd --runs 0 --file "$FILE" \
      --per-key "$OUT/revalidate-v3-partA-perkey.tsv" \
      > "$OUT/revalidate-v3-partA-all-bpd$bpd.txt" 2>&1 || rc=1
done
perl prototype/426-revalidate-v3.pl --part B --bpd 53,616 > "$OUT/revalidate-v3-partB.txt" 2>&1 || rc=1
perl prototype/426-revalidate-v3.pl --part C --bpd 53   > "$OUT/revalidate-v3-partC.txt" 2>&1 || rc=1
echo "driver exit=$rc"
exit $rc
