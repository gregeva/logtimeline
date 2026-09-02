# #516 — Bytes aggregate family captured only on demand

Issue #516 (bytes aggregate family is captured per line with no consumer on a
default run). Fixes part of the v0.18.0-first parse/read_files regression
attributed in `tests/profile/results/0180-parse-regression/analysis.md`
(~0.30 s of ~0.9 s on single-day-access-log-standard).

## Requirement

The per-line capture of the bytes aggregate family — `bytes_occurrences`,
`bytes_min`, `bytes_max`, at the per-message and per-bucket scopes — runs only
when a surface that reads it is active. The consumers are fixed by
`features/432-metric-aggregate-naming-parity.md` § D8: the two CSV surfaces
(both produced under `-o`) and the bytes-family sort operands
(`-so bytes_occurrences|bytes_min|bytes_mean|bytes_max`). `total_bytes` (the
rendered bytes column at both scopes, and the bare `-so bytes` operand) is not
part of the family and stays captured unconditionally.

## Decisions

### D1 — Store-level demand flag, resolved with the duration-statistics demand

One run-start boolean, `$bytes_aggregate_demand`, computed in the existing
demand-resolution block of `adapt_to_command_line_options()` (beside
`$bucket_duration_stats_demand`), true when `-o` is active or the resolved
`$sort_key` is one of the four family operands, and never true under `-ob`.
Both capture sites test the flag inside their existing bytes guard, so the
total-bytes accumulation and `$bytes_observed` behave exactly as today.

### D2 — Downstream reads are already absence-tolerant, so nothing else moves

`log_stats` projection guards `bytes_mean` on `bytes_occurrences`; the
consolidation merge copies family fields only when defined; the CSV writers run
only under `-o`, where the flag is true. No consumer changes.

## Acceptance criteria

1. **Default run skips the capture** (assertable): on a bytes-carrying input
   with no `-o` and no bytes-family sort, the per-message and per-bucket
   entries carry no `bytes_occurrences`/`bytes_min`/`bytes_max`. Asserted by
   the before/after benchmark on `single-day-access-log-standard`
   (`parse/read_files` recovers on the order of the isolation measurement) —
   and by criterion 2's surfaces being the only place the family appears.
2. **CSV surfaces unchanged** (assertable): with `-o`, the STATS CSV and
   MESSAGES CSV are byte-identical before/after the change on the same input
   (existing mechanism: `stats_csv_bytes_columns_active()` columns and the
   MESSAGES CSV family columns). Asserted by direct diff of the four CSVs and
   by `tests/validate-csv-output.sh`.
3. **Bytes-family sort unchanged** (assertable): `-so bytes_min` (and mean/max/
   occurrences) orders the messages table identically before/after on the same
   input. Asserted by direct diff of the rendered table.
4. **No runtime warnings** (assertable): stderr carries no ` at ltl line N`
   lines on the criterion 1–3 runs (HARNESS-DESIGN.md discriminator).
5. **Full suite green** (assertable): every `tests/validate-*.sh` passes on the
   finished commit (completion gate).

## Merge gate

Per-feature workflow step 1: full harness suite + before/after benchmark
(516-before captured on the base commit).
