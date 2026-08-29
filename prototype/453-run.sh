#!/usr/bin/env bash
# Assemble and run the #453 classification probe: production slice first,
# driver second, one file, so the generated source the driver evals sees
# the record lexicals exactly as ltl's generated blocks do.
#   ./prototype/453-run.sh <family> [driver options] <fixture> [...]
# Budgets are the mapped benchmark case's parse/read_files per line from
# tests/baseline/results/0.18.0-453-before.tsv (access 13.35 us, scriptlog 10.80 us).
set -euo pipefail
cd "$(dirname "$0")/.."
SLICE=/tmp/453-slice.pl
PROTO=/tmp/453-proto.pl
./prototype/453-extract-slice.sh "$SLICE" >/dev/null
{ echo 'use strict; use warnings; use Time::Local qw(timegm);'; cat "$SLICE" prototype/453-classify-mini.pl; } > "$PROTO"
perl -c "$PROTO" >/dev/null
exec perl "$PROTO" "$@"
