#!/bin/zsh
#
# 426-revalidate-v2.sh — driver for aspect V2 (fan-out at scale, per-line cost,
# merge cost, -g fold). One arm per process. Protocol:
#   1. parity pass: T and S with --parity-only at every bpd; the fill digests
#      must be identical (exit 1 otherwise) BEFORE any timing runs.
#   2. timed pass: T, S, G at every bpd (one untimed warmup + --runs timed runs
#      inside each process).
#   3. post-check: fill_digest, pct_digest, merge_digest, fold_digest and the
#      N conservation lines must agree between T and S (exit 1 otherwise).
# Captures: prototype/426-results/revalidate-v2-parity-<arm>-bpd<bpd>.txt,
#           prototype/426-results/revalidate-v2-<arm>-bpd<bpd>.txt,
#           prototype/426-results/revalidate-v2.tsv (all TSV lines).
#
# Usage: prototype/426-revalidate-v2.sh [--file F] [--bpds "53 616"] [--arms "T S G"] [--runs 3]
set -u
HERE=${0:A:h}
ROOT=${HERE:h}
OUT=$ROOT/prototype/426-results
FILE=$ROOT/logs/AccessLogs/really-big/localhost_access_log-twx01-twx-thingworx-0.2026-01-14.txt
BPDS="53 616"
ARMS="T S G"
RUNS=3
while [[ $# -gt 0 ]]; do
  case $1 in
    --file) FILE=$2; shift 2;;
    --bpds) BPDS=$2; shift 2;;
    --arms) ARMS=$2; shift 2;;
    --runs) RUNS=$2; shift 2;;
    --help) sed -n 2,16p $0; exit 0;;
    *) echo "unknown option $1"; exit 2;;
  esac
done
mkdir -p $OUT
CAFF=""; command -v caffeinate >/dev/null && CAFF="caffeinate -s"
PERL="perl $HERE/426-revalidate-v2.pl --file $FILE"
fail=0

echo "--- parity pass (no timing)"
for bpd in ${=BPDS}; do
  for arm in T S; do
    f=$OUT/revalidate-v2-parity-$arm-bpd$bpd.txt
    ${=CAFF} ${=PERL} --arm $arm --bpd $bpd --parity-only > $f 2>&1 || { echo "FAIL: $arm bpd=$bpd parity run exited non-zero"; fail=1; }
  done
  dT=$(grep '^fill_digest=' $OUT/revalidate-v2-parity-T-bpd$bpd.txt | cut -d= -f2)
  dS=$(grep '^fill_digest=' $OUT/revalidate-v2-parity-S-bpd$bpd.txt | cut -d= -f2)
  kT=$(grep '^keys=' $OUT/revalidate-v2-parity-T-bpd$bpd.txt | cut -d= -f2)
  kS=$(grep '^keys=' $OUT/revalidate-v2-parity-S-bpd$bpd.txt | cut -d= -f2)
  if [[ -n "$dT" && "$dT" == "$dS" && "$kT" == "$kS" ]]; then
    echo "PASS bpd=$bpd T==S fill digest $dT keys=$kT"
  else
    echo "FAIL bpd=$bpd T fill digest '$dT' (keys $kT) != S '$dS' (keys $kS)"; fail=1
  fi
done
if [[ $fail -ne 0 ]]; then echo "parity failed; no timing runs"; exit 1; fi

echo "--- timed pass (runs=$RUNS)"
: > $OUT/revalidate-v2.tsv
echo "arm\tbpd\tmetric\tmedian_s\tmin_s\tmax_s" >> $OUT/revalidate-v2.tsv
for bpd in ${=BPDS}; do
  for arm in ${=ARMS}; do
    f=$OUT/revalidate-v2-$arm-bpd$bpd.txt
    echo "run: arm=$arm bpd=$bpd -> $f"
    ${=CAFF} ${=PERL} --arm $arm --bpd $bpd --runs $RUNS > $f 2>&1 || { echo "FAIL: $arm bpd=$bpd exited non-zero"; fail=1; }
    grep '^TSV' $f | cut -f2- >> $OUT/revalidate-v2.tsv
  done
done

echo "--- post-check T vs S"
for bpd in ${=BPDS}; do
  [[ -f $OUT/revalidate-v2-T-bpd$bpd.txt && -f $OUT/revalidate-v2-S-bpd$bpd.txt ]] || continue
  for k in fill_digest pct_digest merge_digest fold_digest keys merge_keys_after merge_n_total_after fold_n_total fold_percentiles; do
    vT=$(grep "^$k=" $OUT/revalidate-v2-T-bpd$bpd.txt | cut -d= -f2)
    vS=$(grep "^$k=" $OUT/revalidate-v2-S-bpd$bpd.txt | cut -d= -f2)
    if [[ -n "$vT" && "$vT" == "$vS" ]]; then echo "PASS bpd=$bpd $k T==S ($vT)"; else echo "FAIL bpd=$bpd $k T='$vT' S='$vS'"; fail=1; fi
  done
  nsT=$(grep '^n_samples=' $OUT/revalidate-v2-T-bpd$bpd.txt | cut -d= -f2)
  for arm in ${=ARMS}; do
    f=$OUT/revalidate-v2-$arm-bpd$bpd.txt; [[ -f $f ]] || continue
    for k in merge_n_total_after fold_n_total; do
      v=$(grep "^$k=" $f | cut -d= -f2)
      if [[ "$v" == "$nsT" ]]; then echo "PASS bpd=$bpd $arm $k == n_samples ($v)"; else echo "FAIL bpd=$bpd $arm $k=$v != n_samples $nsT"; fail=1; fi
    done
  done
done
[[ $fail -eq 0 ]] && echo "ALL PASS" || echo "FAILED"
exit $fail
