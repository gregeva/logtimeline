# #520 — An inert sort holds no demand

Issue #520 (`-n 0` reports `-so/--sort-on` inert, but its resolved sort key still
holds the bytes aggregate-family demand alive).

## Requirement

Under `-n 0` no message is retained, so `-so` ranks nothing and is reported inert
(`features/458-top-messages-zero-no-per-message-retention.md` D3). The resolved sort
key nevertheless stays in place, and the bytes aggregate-family demand gate
(`features/516-bytes-aggregate-demand-gate.md` D1) reads it: `-n 0 -so bytes_min`
with no `-o` captures `bytes_occurrences` / `bytes_min` / `bytes_max` into
`%log_analysis` on every bytes-carrying line with nothing left to read them.

A sort operand that cannot rank anything creates no demand. The family's other
consumer — the two CSV surfaces — is `-o`, an independent demand term that is not
affected.

The per-message half of the family needs no change: its capture site sits inside the
retention block, so `-n 0` already skips it. Only the per-bucket half is exposed.

## Decisions

### D1 — The sort term of the bytes demand is conditioned on retention

`$bytes_aggregate_demand`'s sort disjunct becomes
`( $capture_messages && $sort_key =~ /^bytes_(?:occurrences|min|mean|max)$/ )`. The
`-o` disjunct and the `!$omit_bytes` conjunct are untouched, so every run that can
produce a bytes-family surface still captures the family.

Conditioning the term rather than clearing `$sort_key` under `-n 0` is deliberate:
#458 D3 keeps the resolved operand so `-V statistics-demand` can report truthfully
what the user asked for (`sort_gate: operand=<key> family=<family> observed=n/a
fallback=none`). Clearing it would make that diagnostic lie.

### D2 — Same shape as the sibling store-level demand flags

`$message_duration_stats_demand` is already `!$omit_durations && $capture_messages`
for the same reason: its surfaces exist only for retained messages. This change puts
the bytes family's message-scoped demand term on the same footing. The other two
flags need no change — `$message_outcomes_demand`'s three write sites all sit inside
the retention block, so the flag is already inert under `-n 0`.

## Acceptance criteria

1. **The wasted capture stops** (assertable): on a bytes-carrying input,
   `-n 0 -so bytes_min` and `-n 0` report an identical `MEMORY log_analysis` value
   in `-V benchmark-data -mem`. Before the change they differ (the delta is the
   family). `Devel::Size` over the same content is deterministic, so equality is an
   exact assertion, and the pre-change inequality is the failure proof.
2. **Nothing rendered changes under `-n 0`** (assertable): the rendered output of
   `-n 0 -so bytes_min` is byte-identical before/after on the same input.
3. **The CSV surfaces are unaffected** (assertable): under `-n 0 -so bytes_min -o`
   the STATS CSV is byte-identical before/after — the `-o` demand term still holds
   the family alive with no message retained.
4. **A retaining run is unaffected** (assertable): `-n 25 -so bytes_min` orders and
   renders the top-messages table identically before/after, and its `-o` CSVs are
   byte-identical.
5. **No runtime warnings** (assertable): stderr carries no ` at ltl line N` lines on
   the criterion 1–4 runs.
6. **Full suite green** (assertable): every `tests/validate-*.sh` passes on the
   commit being merged (completion gate).

## Merge gate

Per-feature workflow step 1: the complete harness suite plus a before/after
benchmark on `single-day-access-log-standard`, the before run captured on the base
commit `b5389e7` before the first code change.

## Measurement

The gate only changes runs that combine `-n 0` with a bytes-family sort operand and
no `-o`, so the benchmark case (which is a retaining run) is a no-op by construction
and measures only that nothing regressed. The effect itself is measured on the store
it stops filling.

Input: `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt`
(5,000 lines, 5 one-minute buckets), `--disable-progress -ni --terminal-width 200
-bs 1 -mem -V benchmark-data`. `Devel::Size` over identical content is deterministic,
so these are exact values, not medians.

| run | `MEMORY log_analysis` before | after |
|---|---|---|
| `-n 0` | 363,897 B | 363,897 B |
| `-n 0 -so bytes_min` | 365,474 B | 363,897 B |

The 1,577 B the inert sort used to add over five buckets is the per-bucket bytes
family. After the change the two runs are identical, which is criterion 1; the
pre-change inequality is its failure proof.

## Completion gate

Run on the finished change with `$version_number` restored to `0.18.0`.

**Harness suite — 32 of 32 pass**, every summary line reporting checks actually run:
`validate-csv-output` 28, `validate-statistics` 21 scenarios, `validate-explain` 154,
`validate-format-detection` 249, `validate-profile` 106, `validate-statistics-demand`
95, `validate-heatmap-palette` 85, `validate-histogram-bin-counters` 84,
`validate-regression` 74, `validate-index-read-back` 59, `validate-profile-render` 50,
`validate-doc-examples` 48, `validate-udm-specs` 43,
`validate-classification-percentages` 41, `validate-summary-contribution-bar` 39,
`validate-runtime-config` 36, `validate-udm-counting` 28, `validate-outcome-criteria`
26, `validate-category-names` 26, `validate-progress-line` 24,
`validate-format-registry` / `validate-recursive-file-selection` 22 each,
`validate-duration-display` / `validate-histogram-ticks` 21 each,
`validate-help-content` / `validate-message-control-characters` 11,
`validate-numeric-criteria-notices` 10, `validate-distribution-shape` 8,
`validate-log-level-vocabulary` 8, `validate-help-layout` 6,
`validate-csv-input` / `validate-message-grouping-notices` 4. Zero failures.
`validate-csv-output.sh` ran before `validate-statistics.sh` for the shared `CI=1`
cache; `./tests/cleanup-test-artifacts.sh` was run afterwards.

**Statistics drift**: no T3 or T4 failure on any layer. The only registered known
failures are the nine #469 cells (one bin-model percentile projection onto the shared
geometry) in `tests/statistics-drift/known-failures.tsv`.

**Benchmark**, `single-day-access-log-standard`, before captured on base commit
`b5389e7` prior to the first code change, after on the finished change, same machine:

| metric | before | after | change |
|---|---|---|---|
| `parse/read_files` | 9.5 s | 9.4 s | -1.6% |
| `TIMING/total` | 9.7 s | 9.6 s | -1.5% |
| `MEMORY/rss_peak` | 143.5 MB | 143.9 MB | +0.3% |
| `MEMORY/log_analysis` | 52.7 MB | 52.7 MB | 0.0% |

Nothing worse by more than 5%. The case is a retaining run with no bytes-family
sort, so it exercises neither side of the gate — the deltas are run-to-run variation.
Both TSVs deleted afterwards.
