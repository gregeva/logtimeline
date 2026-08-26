#!/bin/bash
# Driver for prototype/426-n6-fanout-percentile.pl — #426 N6/N8: one process per
# arm per bpd over the fan-out fixture, so the RSS delta measures exactly one
# store. Captures to prototype/426-results/n3n6n8/n6-pct-arm<A>-bpd<N>.txt.
set -u
cd "$(dirname "$0")/.." || exit 1
OUT=prototype/426-results/n3n6n8
mkdir -p "$OUT"
FILE=${FILE:-/tmp/ltl-426-fixtures/bin-twxdur-full.log}
TAG=${TAG:-n6-pct}
RUNS=${RUNS:-3}
rc=0
for bpd in ${BPDS:-53 616}; do
  for arm in T S G; do
    perl prototype/426-n6-fanout-percentile.pl --file "$FILE" --arm $arm --bpd $bpd --runs $RUNS \
      > "$OUT/$TAG-arm$arm-bpd$bpd.txt" 2>&1 || rc=1
  done
done
echo "driver exit=$rc"
exit $rc
