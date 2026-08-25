#!/usr/bin/env bash
# Driver for 426-n5-merge-shapes.pl: parity FIRST (T vs S digests on every merge
# shape), then the full matrix. One arm per process.
set -u
cd "$(dirname "$0")/.."
OUT=prototype/426-results/n5-merge-shapes
mkdir -p "$OUT"
PL=prototype/426-n5-merge-shapes.pl
FAN=/tmp/ltl-426-fixtures/bin-twxdur-full.log
DPM=/tmp/ltl-426-fixtures/bin-dpm-full.log
RUNS=${RUNS:-3}
COMMON="--runs $RUNS --rollup-keys 2000 --disjoint-pairs 200 --depth-groups 200 --order-keys 200 --order-perms 4"
# The fan-out fixture is singleton-dominated (286,659 keys, only 148 with N>=2),
# so D/P/O there run with --min-n 1 or they have no material to merge.
minn_for() { [ "$1" = fanout ] && echo 1 || echo 2; }

run() { # arm bpd fixture-tag file
  local arm=$1 bpd=$2 tag=$3 f=$4
  echo ">>> $arm bpd=$bpd $tag"
  perl "$PL" --arm "$arm" --bpd "$bpd" --file "$f" $COMMON --min-n "$(minn_for "$tag")" > "$OUT/$arm-bpd$bpd-$tag.txt" 2>&1
  local rc=$?
  tail -1 "$OUT/$arm-bpd$bpd-$tag.txt" | grep -q DONE || { echo "FAIL $arm/$bpd/$tag rc=$rc"; return 1; }
  return 0
}

FAILED=0
for tag_f in "fanout:$FAN" "dpm:$DPM"; do
  tag=${tag_f%%:*}; f=${tag_f#*:}
  for bpd in 53 616; do
    for arm in T S G; do
      run "$arm" "$bpd" "$tag" "$f" || FAILED=1
    done
  done
done

echo
echo "=== PARITY: T vs S digests (must be identical on every merge shape) ==="
PARITY_OK=1
for tag in fanout dpm; do
  for bpd in 53 616; do
    for m in rollup_digest disjoint_digest; do
      t=$(grep "^$m=" "$OUT/T-bpd$bpd-$tag.txt" 2>/dev/null | cut -d= -f2)
      s=$(grep "^$m=" "$OUT/S-bpd$bpd-$tag.txt" 2>/dev/null | cut -d= -f2)
      if [ -n "$t" ] && [ "$t" = "$s" ]; then echo "PASS $tag/$bpd/$m $t"
      else echo "FAIL $tag/$bpd/$m T=$t S=$s"; PARITY_OK=0; fi
    done
    # accuracy digests: the whole per-quantile error vector must agree too
    for m in disjoint_bins_err_max depth15_bins_err_max rollup_bins_err_max order_groups_differing; do
      t=$(grep "^$m=" "$OUT/T-bpd$bpd-$tag.txt" 2>/dev/null | cut -d= -f2)
      s=$(grep "^$m=" "$OUT/S-bpd$bpd-$tag.txt" 2>/dev/null | cut -d= -f2)
      if [ "$t" = "$s" ]; then echo "PASS $tag/$bpd/$m $t"
      else echo "FAIL $tag/$bpd/$m T=$t S=$s"; PARITY_OK=0; fi
    done
  done
done
echo "PARITY_OK=$PARITY_OK  RUNS_FAILED=$FAILED"

echo
echo "=== N conservation (rollup_n_after must equal rollup_values) ==="
for f in "$OUT"/*.txt; do
  a=$(grep '^rollup_values=' "$f" | cut -d= -f2); b=$(grep '^rollup_n_after=' "$f" | cut -d= -f2)
  [ "$a" = "$b" ] && echo "PASS $(basename $f) $a" || echo "FAIL $(basename $f) values=$a after=$b"
done

grep -h '^TSV' "$OUT"/*.txt | sort > "$OUT/timings.tsv"
echo; echo "timings -> $OUT/timings.tsv"
