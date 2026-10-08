#!/usr/bin/env bash
#
# parity.sh - the parity battery of features/615-csv-registry-entry.md § 8:
# every correctness fixture through arms A, B and B-no-memo, per row, at each
# precision of the matrix (D16) and with -o at the default precision.
#
# Usage: parity.sh FIXTURE_DIR > parity.tsv     (narrative on stderr)

set -u
FIX="${1:?fixture directory}"
HERE="$(cd "$(dirname "$0")" && pwd)"
DRV="$HERE/csv-block.pl"

PRECISIONS=( "-tp m" "-tp s" "-tp ms" "-tp us" "-tp ns" "-o" )

run() {   # fixture, ltl options...
    local f="$1"; shift
    perl "$DRV" --mode parity --file "$FIX/$f" -- "$@"
}

ISO1=( -udm cpu_total )
ISO3=( -udm cpu_user -udm cpu_total -udm conn_active )
EPO1=( -udm latency_ms )
EPO3=( -udm latency_ms -udm request_size -udm response_size )

PROTO_HEADER=1 run c-iso-nofrac.csv "${ISO1[@]}" -tp m | head -1
for p in "${PRECISIONS[@]}"; do
    # shellcheck disable=SC2086
    {
    run c-iso-nofrac.csv        "${ISO1[@]}" $p
    run c-iso-frac3.csv         "${ISO3[@]}" $p
    run c-iso-frac6.csv         "${ISO1[@]}" $p
    run c-iso-frac9.csv         "${ISO1[@]}" $p
    run c-iso-T.csv             "${ISO1[@]}" $p
    run c-epoch-whole.csv       "${EPO1[@]}" $p
    run c-epoch-frac6.csv       "${EPO3[@]}" $p
    run c-epoch-frac9.csv       "${EPO1[@]}" $p
    run c-epoch-ms.csv          "${EPO1[@]}" -du ms $p
    run c-iso-badrows.csv       "${ISO3[@]}" -udm 'cpu_total::delta' $p
    run c-epoch-badrows.csv     "${EPO1[@]}" -udm 'latency_ms::delta' $p
    } | grep -v '^#'
done
# metric and message shapes, at the default precision
{
run c-iso-frac3.csv     -udm cpu_total -udm no_such_column
run c-iso-semicolon.csv "${ISO1[@]}" -ucm 'namespace host'
run c-iso-frac3.csv     "${ISO1[@]}" -ucm 'host'
run c-iso-dayfirst.csv  "${ISO1[@]}" -tp s
run c-iso-feb30.csv     "${ISO1[@]}" -tp s
run c-iso-month13-outside.csv "${ISO1[@]}" -tp s
} | grep -v '^#'
