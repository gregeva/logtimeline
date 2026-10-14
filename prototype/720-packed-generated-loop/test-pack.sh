#!/usr/bin/env bash
# #720: checks on one platform's packed probes.
#   usage: test-pack.sh <platform> <exe suffix> [runner]
set -uo pipefail
P=$1; EXT=$2; RUNNER=${3:-}
B=/x/out/$P; R=/x/results/$P; rm -rf $R; mkdir -p $R/cands $R/w
run() { $RUNNER "$@"; }
{
echo "== par0, first run then cached"; run $B/par0$EXT; run $B/par0$EXT
echo "== generated path taken"
for v in gen-run gen-file; do echo "-- $v"; ( cd $R/w && LTL_GEN_TIMING=1 run $B/$v$EXT --disable-progress -ni -bs 5 /x/slices/access.txt 2>&1 >/dev/null ) | grep -a GENERATED; done
echo "== injected warning"
for v in warn-gen-run warn-gen-file; do for g in 0 1; do echo "-- $v LTL_GENERATED_LOOP=$g"; ( cd $R/w && LTL_GENERATED_LOOP=$g run $B/$v$EXT --disable-progress -ni -bs 5 /x/slices/access.txt 2>&1 >/dev/null ) | grep -a probe; done; done
} > $R/checks.txt 2>&1
printf '#!/bin/sh\nLTL_GENERATED_LOOP=0 exec %s %s "$@"\n' "$RUNNER" "$B/gen-run$EXT" > $R/cands/ltl-base
printf '#!/bin/sh\nexec %s %s "$@"\n' "$RUNNER" "$B/gen-run$EXT" > $R/cands/ltl-packed-run
printf '#!/bin/sh\nexec %s %s "$@"\n' "$RUNNER" "$B/gen-file$EXT" > $R/cands/ltl-packed-file
chmod +x $R/cands/*
sl=/x/slices
mapfile -t cases < <(grep -v '^#' /x/shapes.txt | grep . | sed -e "s|@ACCESS_TS\$|@$sl/access-ts.txt|" -e "s|@ACCESS\$|@$sl/access.txt|" -e "s|@APP\$|@$sl/app.txt|" -e "s|@SCRIPT\$|@$sl/script.txt|" -e "s|@METRICS\$|@$sl/metrics.csv|")
echo "${#cases[@]} cases" > $R/prove.err
start=$(date +%s)
PERL_HASH_SEED=0 PERL_PERTURB_KEYS=0 CANDIDATES="base packed-run packed-file" bash /x/prove.sh $R/cands $R/prove base "${cases[@]}" > $R/prove.out 2>> $R/prove.err
echo "prove seconds: $(( $(date +%s) - start ))" >> $R/prove.err
echo "test-pack $P done"
