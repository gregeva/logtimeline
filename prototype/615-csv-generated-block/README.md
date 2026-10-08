# CSV input through a generated block: drop 1 prototype

Owning record: `features/615-csv-registry-entry.md` § 8 (the question, the
method, the arms, the fixtures and the exit criterion) and the findings
section that follows it there. This directory holds the instruments only.

## Question

Does a block generated from a CSV file's header, through the emitter the
scanned formats use, with the memo and with the column positions compiled in,
cost no more per row than today's inline CSV arms and per-row column lookup,
with identical output; and what does generating and validating it once per
file cost?

## Instruments

| File | What it does |
|---|---|
| `gen-fixtures.pl OUTDIR [--sizes 1k,10k,100k,1m]` | writes the performance fixtures (an epoch family in the network-latency specimen's row shape, an ISO family in the system-metrics specimen's row shape, one row per second and ten rows per second, at each size) and the correctness fixtures (`c-*.csv`), all neutral and deterministic |
| `csv-block.pl --mode parity\|timing\|perfile\|src --file F -- <ltl options>` | evaluates `ltl` up to `## MAIN ##` and drives its subs; slices arm A out of `read_and_process_logs()` verbatim; generates arm B from the header through the timestamp part of `format_entry_block_src()` |
| `parity.sh FIXTURE_DIR` | the parity battery: every correctness fixture at `-tp m`, `s`, `ms`, `us`, `ns` and with `-o`, plus the metric, message and date-order cases |
| `timing.sh FIXTURE_DIR [ROUNDS]` | per-row cost of A, B and B-no-memo at each family, density, metric count, size and read-gate state; then the per-file cost of generation and validation |

## Arms

- **A**: the read loop's per-line declarations, the steady CSV arm, the shared
  metric capture and the timestamp arms, sliced by anchor lines from
  `read_and_process_logs()` and compiled into one loop over the rows.
- **B**: the same loop with the steady arm replaced by a call to the block
  generated for the file's header shape, and the capture's CSV branch reading
  the value the block extracted by the metric's position in the `-udm` list.
  The block's ISO timestamp text is the emitter's own (fraction under the read
  gate, memo, layout parse); the day-first layout takes the day-first offsets
  as the day-first ISO layout does. The epoch layout is prototype text.
- **B-no-memo**: B without the memo; attribution only.

The fixtures are generated into a scratch directory, never committed: the
performance fixtures at 1M rows are about 65 MB each.

## Running

```bash
perl prototype/615-csv-generated-block/gen-fixtures.pl "$SCRATCH/615-fix"
prototype/615-csv-generated-block/parity.sh "$SCRATCH/615-fix" > parity.tsv 2> parity.err
prototype/615-csv-generated-block/timing.sh "$SCRATCH/615-fix" 5 > timing.tsv 2> timing.err
```
