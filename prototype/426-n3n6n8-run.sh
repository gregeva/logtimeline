#!/bin/bash
# Driver for #426 N3 (second/third log surface for V1/V3/V5) + N6 (fan-out beyond
# 10^5 keys) + N8 (RSS-vs-Devel::Size memory measure). Reuses the existing aspect
# prototypes verbatim — 426-revalidate-v1.pl, -v3.pl, -v5.pl — over new inputs.
# Every capture lands under prototype/426-results/n3n6n8/. Run from the repo root.
#
#   sh prototype/426-n3n6n8-run.sh n6        fan-out: bin-twxdur-full.log, 286,659 keys
#   sh prototype/426-n3n6n8-run.sh n3-dpm    DPM ScriptLog surface
#   sh prototype/426-n3n6n8-run.sh n3-tomcat 148 MB Tomcat surface
set -u
cd "$(dirname "$0")/.." || exit 1
OUT=prototype/426-results/n3n6n8
mkdir -p "$OUT"
RUNS=${RUNS:-3}
DPM=logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log
TOMCAT=logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt
FANOUT=/tmp/ltl-426-fixtures/bin-twxdur-full.log
rc=0

n6() {
  for bpd in 53 616; do
    for arm in T S G; do
      perl prototype/426-revalidate-v3.pl --part A --arm $arm --bpd $bpd --runs $RUNS --file "$FANOUT" \
        > "$OUT/n6-v3A-arm$arm-bpd$bpd.txt" 2>&1 || rc=1
    done
    perl prototype/426-revalidate-v3.pl --part A --arm all --bpd $bpd --runs 0 --file "$FANOUT" \
      > "$OUT/n6-v3A-all-bpd$bpd.txt" 2>&1 || rc=1
  done
}

# N3 surface: V1 part BC (power-of-ten spikes, T/G bin disagreement, T-S parity,
# determinism) + V3 part A (span/seed telemetry, memory) + V5 (percentile vs oracle).
n3() {
  local tag="$1" file="$2"
  mkdir -p "$OUT/v1-$tag"
  perl prototype/426-revalidate-v1.pl --part BC --file "$file" --bpd 53,616 \
    --check-bpd 53,115,256,616 --out-dir "$OUT/v1-$tag" > "$OUT/n3-$tag-v1BC.txt" 2>&1 || rc=1
  for bpd in 53 616; do
    for arm in T S G; do
      perl prototype/426-revalidate-v3.pl --part A --arm $arm --bpd $bpd --runs $RUNS --file "$file" \
        > "$OUT/n3-$tag-v3A-arm$arm-bpd$bpd.txt" 2>&1 || rc=1
    done
    perl prototype/426-revalidate-v3.pl --part A --arm all --bpd $bpd --runs 0 --file "$file" \
      > "$OUT/n3-$tag-v3A-all-bpd$bpd.txt" 2>&1 || rc=1
    PREFIX="$OUT/n3-$tag-v5" perl prototype/426-revalidate-v5.pl --file "$file" --bpd $bpd \
      --parity-bpd 53 --tsv-prefix "$OUT/n3-$tag-v5" > "$OUT/n3-$tag-v5-bpd$bpd.txt" 2>&1 || rc=1
  done
}

case "${1:-all}" in
  n6)        n6 ;;
  n3-dpm)    n3 dpm "$DPM" ;;
  n3-tomcat) n3 tomcat "$TOMCAT" ;;
  all)       n6; n3 dpm "$DPM"; n3 tomcat "$TOMCAT" ;;
  *) echo "usage: $0 n6|n3-dpm|n3-tomcat|all" >&2; exit 2 ;;
esac
echo "driver exit=$rc"
exit $rc
