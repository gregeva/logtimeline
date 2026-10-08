#!/usr/bin/env bash
#
# timing.sh - per-row cost of arms A, B and B-no-memo
# (features/615-csv-registry-entry.md § 8): two families, two densities, one
# and three metric columns, 1k to 1M rows, the read gate closed (the default
# minute precision) and open (-tp ms). Then the per-file cost of generating
# and validating B, with and without the day-first retry.
#
# Usage: timing.sh FIXTURE_DIR [ROUNDS] > timing.tsv
#
# Columns (per-row): fixture, metrics, gate, arm, rows, reps, rounds,
#   median ns/row, min, max. Each round runs the three arms in a rotated
#   order (order-balanced); below 200k rows a pass repeats the rows so each
#   timing covers at least 200k rows.
# Columns (per-file): fixture, metrics, sampled rows, validation outcome,
#   compiles, generate+compile median/min/max us, instantiate (generate,
#   compile, validate, retry) median/min/max us.

set -u
FIX="${1:?fixture directory}"
ROUNDS="${2:-5}"
HERE="$(cd "$(dirname "$0")" && pwd)"
DRV="$HERE/csv-block.pl"

for size in 1k 10k 100k 1m; do
  for family in epoch iso; do
    for density in one several; do
      f="$FIX/perf-$family-$density-$size.csv"
      if [[ $family == epoch ]]; then
        M1=( -udm latency_ms ); M3=( -udm latency_ms -udm request_size -udm response_size )
      else
        M1=( -udm cpu_total );  M3=( -udm cpu_user -udm cpu_total -udm conn_active )
      fi
      for gate in "-tp m" "-tp ms"; do
        # shellcheck disable=SC2086
        perl "$DRV" --mode timing --rounds "$ROUNDS" --file "$f" -- "${M1[@]}" $gate | grep -v '^#'
        # shellcheck disable=SC2086
        perl "$DRV" --mode timing --rounds "$ROUNDS" --file "$f" -- "${M3[@]}" $gate | grep -v '^#'
      done
    done
  done
done

echo "# per-file"
perl "$DRV" --mode perfile --rounds 21 --file "$FIX/perf-epoch-one-1m.csv"  -- -udm latency_ms | grep -v '^#'
perl "$DRV" --mode perfile --rounds 21 --file "$FIX/perf-iso-one-1m.csv"    -- -udm cpu_total | grep -v '^#'
perl "$DRV" --mode perfile --rounds 21 --file "$FIX/perf-iso-one-1m.csv"    -- -udm cpu_user -udm cpu_total -udm conn_active | grep -v '^#'
perl "$DRV" --mode perfile --rounds 21 --file "$FIX/c-iso-dayfirst.csv"     -- -udm cpu_total -tp s | grep -v '^#'
perl "$DRV" --mode perfile --rounds 21 --file "$FIX/c-iso-feb30.csv"        -- -udm cpu_total -tp s | grep -v '^#'
