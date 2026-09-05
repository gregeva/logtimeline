#!/usr/bin/env bash
# #462 / #461 — is counter_memory_bytes' run-to-run variance the hash-seed
# bucket-allocation route, the hash-iteration-order route (merge order changes
# the union geometry, so the store's CONTENTS differ), or both?
#
# Discriminator: the bucket-allocation route moves counter_memory_bytes ONLY.
# The iteration-order route also moves partition_count / max_partition_bins /
# total_rebin_events, because a different merge order yields different geometry.
#
# Invocation shaping (HARNESS-DESIGN Invocation coherence): the assertion reads
# only the `-V histogram-bin-counters` block, which is identical at any bucket
# size, so every run uses `-bs 1440 -oe -n 1 -ni --disable-progress`.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1
LTL=./ltl
OUT=${OUT_DIR:-/tmp/462-memvar}
RUNS=${RUNS:-6}
mkdir -p "$OUT"

FIX_SMALL="tests/fixtures/tomcat-access-duration-spread.txt"
FIX_MED="${LTL_FIX_MED:-tests/fixtures/tomcat-access-duration-spread.txt}"
FIX_LARGE="logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt"

run_arm() {   # name  fixture  extra-opts  env-prefix
  local name=$1 fixture=$2 extra=$3 envp=$4
  [ -f "$fixture" ] || { echo "SKIP $name — missing $fixture"; return; }
  for i in $(seq 1 "$RUNS"); do
    env $envp $LTL --disable-progress -ni -bs 1440 -oe -n 1 \
        $extra -V histogram-bin-counters "$fixture" \
        > "$OUT/$name.run$i.out" 2>"$OUT/$name.run$i.err"
  done
}

# summary_table is the only consumer with a merge path, so read its block.
field() {  # file field
  awk -v f="  $2: " '/^consumer: summary_table$/{s=1;next} /^consumer: /{s=0}
       s && index($0,f)==1 {print substr($0,length(f)+1); exit}' "$1"
}

report() {
  local name=$1
  echo "--- $name"
  printf '%-6s %-14s %-11s %-14s %-13s %-12s %-12s\n' run mem_bytes partitions growth_events merge_events members_live members_max
  for i in $(seq 1 "$RUNS"); do
    local f="$OUT/$name.run$i.out"
    [ -f "$f" ] || continue
    printf '%-6s %-14s %-11s %-14s %-13s %-12s %-12s\n' "$i" \
      "$(field "$f" counter_memory_bytes)" "$(field "$f" partition_count)" \
      "$(field "$f" rebin_growth_events)" "$(field "$f" rebin_merge_events)" \
      "$(field "$f" members_live)" "$(field "$f" members_max)"
  done
}

case "${1:-med}" in
  med)
    run_arm A_nog_med   "$FIX_MED" "-mdm bin"        ""
    run_arm B_g_med     "$FIX_MED" "-mdm bin -g 70"  ""
    run_arm C_nog_fixed "$FIX_MED" "-mdm bin"        "PERL_HASH_SEED=0 PERL_PERTURB_KEYS=0"
    run_arm D_g_fixed   "$FIX_MED" "-mdm bin -g 70"  "PERL_HASH_SEED=0 PERL_PERTURB_KEYS=0"
    for a in A_nog_med B_g_med C_nog_fixed D_g_fixed; do report "$a"; done
    ;;
  large)
    run_arm E_nog_large "$FIX_LARGE" "-mdm bin"       ""
    run_arm F_g_large   "$FIX_LARGE" "-mdm bin -g 70" ""
    for a in E_nog_large F_g_large; do report "$a"; done
    ;;
  report) shift; for a in "$@"; do report "$a"; done ;;
esac
