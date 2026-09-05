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

The gate changes per-line work only on runs that combine `-n 0` with a bytes-family
sort operand and no `-o`, so that is the shape it is measured on. Same machine, same
file, five interleaved runs per arm; the before arm is the base commit's `ltl`
(`b5389e7`) verified byte-identical to `git show b5389e7:ltl`.

Input: `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt`
(155 MB, 761,698 lines). Invocation: `--disable-progress -ni --terminal-width 200
-bs 60 -n 0 -so bytes_min -V benchmark-data`.

| metric | before (median) | after (median) | change |
|---|---|---|---|
| `parse/read_files` | 7.399 s | 7.302 s | **-97 ms, -1.31%** |
| `TIMING/total` | 7.501 s | 7.406 s | **-95 ms, -1.27%** |

Ranges: before `parse` 7.365-7.414 s, after 7.226-7.356 s; before `total`
7.466-7.517 s, after 7.330-7.457 s. **The two distributions do not overlap on either
metric.** Normalised, the saving is 0.127 s per million lines - the three hash
operations per bytes-carrying line that the gate now skips.

Memory, from a separate `-mem` run per arm (the structure walk raises RSS, so it is
not merged with the timing table):

| structure | before | after | change |
|---|---|---|---|
| `MEMORY/log_analysis` | 55,259,354 B | 55,254,897 B | -4,457 B |
| `MEMORY/rss_peak` | 92,651,520 B | 92,372,992 B | -278,528 B |

The store saving is small here because `-bs 60` over one day is 24 buckets, and the
family costs about 186 B per bucket. It scales with bucket count, not with line
count; the line-count-proportional saving is the time above.

The same store measurement on a five-bucket slice makes acceptance criterion 1 exact:
`-n 0 -so bytes_min` sized `%log_analysis` at 365,474 B against 363,897 B for plain
`-n 0`, and now reports the same 363,897 B.

## Completion gate

Run on the finished change with `$version_number` restored to `0.18.0`.

**Harness suite - 32 of 32 pass**, every summary line reporting checks actually run:
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
`b5389e7` prior to the first code change, after on the finished change, one run each:
`parse/read_files` 9.5 s to 9.4 s (-150 ms), `TIMING/total` 9.7 s to 9.6 s (-143 ms),
`MEMORY/rss_peak` 143.5 MB to 143.9 MB (+432 KB), `MEMORY/log_analysis` unchanged at
52.7 MB. **That case passes no options, so the demand flag resolves to 0 on both
sides and the run never takes the gated path** - the unchanged `log_analysis` is the
direct evidence. Its deltas are run-to-run variation in both directions and attribute
nothing to this change; the attributed figures are the interleaved medians under
§ Measurement. Both TSVs deleted afterwards.
