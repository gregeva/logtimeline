# `-n 0`: no specific messages, nothing retained or computed per message (#458)

## Overview

`-n, --top-messages` accepts `0`, meaning the run keeps no individual log message at
all. This is not a display setting: the per-message store is never populated, so
nothing downstream of it exists — no per-message statistics, no messages table, no
MESSAGES CSV. The timeline and the statistics over the whole population are produced
exactly as before, and inclusion/exclusion filtering is unaffected because it decides
whether a line is considered at all, ahead of this decision.

The motivation is cost. Retaining a copy of every unique message is what makes the
tool expensive on large volumes: high cardinality drives memory, and every later pass
over that population pays for it. When the question is about the timeline and the
population as a whole, `-n 0` removes that cost by construction.

## GitHub Issue

https://github.com/gregeva/logtimeline/issues/458

Related: #2 (memory ceiling and automatic detection — `-n 0` is the user-declared way
to reach a minimal footprint), #426 (the per-message statistics store, whose traversal
cost this avoids), #354 (`-mdm bin` message-stats memory on high-cardinality logs),
#44 (source-file heuristics for automatic optimisation), #97 (hierarchical roll-up,
which also changes what the `-n` operand means).

## Locked decisions

### D1 — The decision is taken per line, at the population site

`read_and_process_logs()` guards the whole message-capture branch:

```perl
if( $capture_messages && defined( $message ) ) {
```

`$capture_messages` is a single file-scoped scalar resolved once, in
`adapt_to_command_line_options()`, from the top-message count. Leading the test with
it means a run that retains nothing skips key construction, grouping and per-key
accumulation entirely, and a retaining run pays one boolean per line and nothing
else. Nothing is populated and then cleared: the store is never written.

**Consequence.** No other site needs an emptiness guard. Every consumer of the store
iterates it (`foreach my $category (sort keys %log_messages)`), so an empty store is
zero iterations rather than a special case — this is the "gate on observation counts"
rule satisfied structurally.

### D2 — A count of zero or less retains nothing

`$capture_messages = ( $top_n_messages > 0 ) ? 1 : 0;`. A negative operand was
previously accepted and produced an empty table over a fully populated store; it now
takes the same path as `0`. No new error path was added for negative values.

### D3 — Options that only configure the per-message store are ignored, not rejected

Message grouping (`-g`), the message statistics data model (`-mdm`) and the message
ranking (`-so`) configure something that will never exist. They are not an error —
the retention setting wins — but the user is told, once, naming only the options they
actually passed:

```
Note: -n/--top-messages 0 retains no message, so -g/--group-similar,
-mdm/--message-stats-data-model, -so/--sort-on have no effect
```

The notice is a behavioural notice, not progress output, so it is not gated behind
`--disable-progress`. Grouping is switched off at this point
(`$group_similar_sensitivity = "none"`) rather than left to find an empty store, so
its final pass, its `-V message-grouping` section and its own notices never run.

`-so` is included even though the issue names only `-g` and `-mdm`: it is in the same
class — it orders the messages table and nothing else. Ranking a set of rows that will
never exist is not a partial capability, so `-so` is reported inert exactly as `-g`
and `-mdm` are.

**Consequence.** The three unsatisfiable-sort notices (#418) are suppressed under
`-n 0`: `apply_parse_time_sort_gate()`, `apply_pre_walk_sort_gate()` and
`apply_post_walk_sort_gate()` all return early. Those notices exist to tell the user
that a requested ranking could not be satisfied and what it fell back to; with no
message retained there is nothing ranked at all, so a fallback notice would report a
substitution that never happened — the inert-option notice above is the accurate
statement, and it is the only one printed. `-V statistics-demand` still records the
operand and its family truthfully (`sort_gate: operand=<key> family=<family>
observed=n/a fallback=none`), so the diagnostic surface still shows what the user
asked for.

### D4 — No MESSAGES CSV file is created, and the user is told

`-o` continues to write the STATS CSV (per time bucket). The MESSAGES CSV is the
per-message store written out; with no rows there is no file. A header-only CSV would
read as a run that found nothing rather than one that was asked to keep nothing.

A CSV request is therefore half-served, and a user who scripts around the file names
must learn that at run time rather than by finding one file where they expected two.
`-o` is not listed among the inert options — its per-time-bucket half still runs — so
it is reported on its own line of the same notice, emitted whenever a CSV was
requested under `-n 0` (a behavioural notice, so never gated behind
`--disable-progress`). Exact text, on stderr:

```
Note: -n/--top-messages 0 retains no message, so -o/--output-csv writes the STATS CSV only: no MESSAGES CSV is written
```

### D5 — The thread-pool summary follows the same top-N operand

`print_threadpool_summary()` ranks by the same `-n` operand as the messages table, so
a top-N of zero leaves it no rows. It is skipped rather than printed empty.

**Consequence.** `-tpas` with `-n 0` produces no thread-pool table. This is the one
decision here that touches a surface the issue does not mention; it follows from the
operand being shared, not from message retention. Giving the thread-pool summary a
row count of its own, independent of `-n`, would be a new operand with its own name,
help row and documentation — a separate requirement and a separate issue, not part of
this one. Until such an operand exists, `-n` governs both tables and `-n 0` empties
both.

## What changed, by surface

| surface | change |
|---|---|
| `ltl` — hot path | `read_and_process_logs()`: message-capture branch gated on `$capture_messages` |
| `ltl` — option resolution | `adapt_to_command_line_options()`: `$capture_messages` resolved before the sort resolution; inert-option notice, half-served-CSV notice and grouping fold before the statistics-demand resolution |
| `ltl` — demand registry | `@STAT_CONSUMERS`: all three message-store consumers (`messages-table`, `messages-csv`, `sort-on`) read `$capture_messages`. `$message_duration_stats_demand` reduces to `!$omit_durations && $capture_messages`: both of its surfaces exist only for retained messages, so retention is the single condition |
| `ltl` — sort gates | `apply_parse_time_sort_gate()`, `apply_pre_walk_sort_gate()`, `apply_post_walk_sort_gate()` return early |
| `ltl` — render | `pipeline_render()`: MESSAGES CSV open, `print_message_summary()`, `print_threadpool_summary()` and the MESSAGES file-handle close all gated |
| `ltl` — help | `print_help()` `-n` row documents `0` |
| `docs/usage.md` | `-n` row documents `0` (parity with `--help`) |
| `tests/validate-statistics-demand.sh` | scenarios 9 to 12 |
| `tests/baseline/run-benchmark.sh` | `no-messages\|-n 0` scenario |
| `tests/baseline/compare-results.sh` | `no-messages` in the table-view scenario list |

## Downstream audit

Every consumer of the per-message store was checked against an empty store. None
needed a guard, and none produces a warning, a division by zero or an empty header:

| consumer | behaviour with an empty store |
|---|---|
| `group_similar_messages()` and its `-V message-grouping` section | never reached — grouping is off (D3) |
| `bin_consolidation_notice()` | returns immediately (grouping is off) |
| `calculate_all_statistics()` message walk, sort selection, group calc | zero iterations over `keys %log_messages` |
| `finalize_message_stats_unified()` | returns on an empty counter store |
| `print_message_summary()` | not called (D4/D5 render gating) |
| MESSAGES CSV | not opened (D4) |
| `-V statistics-demand` | `store: message` reports `store_demand: 0`, `population: 0`, every group `demanded=0`, `stats_calls: 0` |
| `-V benchmark-data` | `COUNTS log_messages_entries 0`, `COUNTS log_messages_population 0` |
| `measure_memory_structures()` / `-mem` | sizes an empty hash |
| index file write side (#46) | does not read the message store |

Combinations exercised end to end on the 5,000-line Tomcat access slice and a
ThingWorx ScriptLog, all exit 0 with no Perl runtime warning on stderr: `-n 0` alone,
`-hm duration -hg duration`, `-V` (all sections), `-o`, `-tpas`, `--profile day`,
`-osum`, `-so impact`, `-od`, `-hst`.

## Measurement

Dev-scale before/after of the option itself — the same build, the same file, `-n 25`
against `-n 0`. Not a release benchmark: it measures what the option does, not what
the change did to the tool.

- Input: `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt`
  (148 MB, 761,698 lines, 3,184 distinct message keys at `-n 25`)
- Invocation: `./ltl --disable-progress -ni --terminal-width 200 -bs 60 -n <N> -V benchmark-data`
- 3 runs each, medians below; values read from the `benchmark-data` section

| metric | `-n 25` | `-n 0` | change |
|---|---|---|---|
| peak RSS | 141.0 MiB | 86.1 MiB | **-38.9%** |
| total runtime | 9.900 s | 7.493 s | **-24.3%** |
| `parse/read_files` | 9.718 s | 7.382 s | **-24.0%** |
| message-store entries | 3,184 | 0 | — |

Ranges across the three runs: `-n 25` total 9.775–9.938 s, RSS 147.77–147.90 MB;
`-n 0` total 7.350–7.994 s, RSS 90.11–90.28 MB. The two distributions do not overlap
on either metric.

The saving lands in the read pass, which is where the issue's benchmark comment
predicted it would have to come from: the per-message accumulation is per line, so
removing it removes per-line work, not a finalize pass.

**Attribution of the memory saving** — a separate `-mem` run on the same file (the
structure walk raises peak RSS slightly, so it is not merged with the table above):

| structure | high-water at `-n 25` |
|---|---|
| `log_messages` | 58,804,089 B (56.1 MiB) |
| peak RSS | 148,488,192 B |

The 57.6 MB the `-n 0` run does not allocate is the message store itself. The store
is not dominated by key count: 3,184 keys hold 761,698 retained duration values
between them under the raw message-statistics data model, about 18.5 KB per key.

## Benchmark-suite coverage

A `no-messages` scenario (`-n 0`) was added to `run-benchmark.sh`, immediately after
`standard`, so every file selection measures it at every scale and the release
comparison picks it up automatically. `compare-results.sh` was extended with the same
scenario in its table view and verified against a synthetic before/after pair (both
`summary` and `table` modes render the new scenario and its deltas).

**The XL tier was not run.** The bundled XL selections are release-gate instruments,
not development tools; the pairing the issue's benchmark comment asks to be read —
`month-many-servers-access-logs-standard` against its `no-messages` counterpart —
belongs to the release-cut benchmark run (release steps 13–14), not to this branch.

## Test coverage

`tests/validate-statistics-demand.sh`:

- **scenario-9-no-message-retention** (`-n 0`): message store reports
  `store_demand: 0`, `population: 0`, every group `demanded=0`, `stats_calls: 0`;
  the bucket store is untouched (`store_demand: 1`); `benchmark-data` reports both
  message-store counts as 0; neither messages-table header is rendered; the timeline
  header row and the latency percentiles are present. Stderr is checked for Perl
  runtime warnings by the shared capture check.
- **scenario-10-no-message-retention-inert-options** (`-n 0 -g 85 -mdm bin -so p50`):
  the inert-option notice names all three options; `sort_gate` records the operand
  with `fallback=none`.
- **scenario-11-negative-top-messages-retains-nothing** (`-n -5`): a negative count
  takes the same path as zero (D2) — the message store reports `store_demand: 0` and
  `population: 0`. Proved to fail with `-n 5` substituted: both assertions failed with
  their `asserts`/`produced_by`/`contract` triple surfaced.
- **scenario-12-no-message-retention-csv-request** (`-bs 1440 -oe -n 0 -o`): the
  half-served-CSV notice is printed verbatim on stderr; the STATS CSV file exists and
  no MESSAGES CSV file does. The run gets its own scratch directory so the two file
  assertions see only its own artifacts, and it is shaped to what it reads — a stderr
  notice and a directory listing, never a bucket row. All three assertions were proved
  to fail: the notice pattern finds no match in the stderr of the same run with `-n 5`
  substituted, the STATS-CSV check fails against an empty directory, and the
  MESSAGES-CSV absence check fails against the `-n 5` run's output directory, which
  contains both files.

The render assertions read the displayed surface because "the messages table is
absent" and "the timeline is present" are properties of that surface with no
internal-state equivalent (`tests/HARNESS-DESIGN.md` § Render-invariant harnesses);
the layout is pinned at `--terminal-width 200` and ANSI is stripped before matching.

**Failure proof** (`tests/HARNESS-DESIGN.md` § Proving a new assertion can fail): both
scenarios were re-run with `-n 10` substituted for `-n 0`. 9 of the 13 new assertions
failed with their `asserts`/`produced_by`/`contract` triple surfaced. The 4 that
still passed are the ones asserting behaviour `-n 0` does *not* change (the bucket
store stays demanded, the timeline and its percentiles are still rendered, and the
CSV/extended/shape groups are undemanded on any terminal-only run).

## Completion gate

Run on `5928714` (`#458: restore release version for the completion gate`), the
commit being merged — the branch rebased onto `release/0.18.0` at `3129fea`
(release notes for #463, the descriptive category names) with `$version_number`
restored to `0.18.0`.

**No benchmark was run.** The architect has ruled that performance benchmarks are
not part of feature work; `tests/baseline/run-benchmark.sh` was not invoked and no
`458-*.tsv` result was produced. The dev-scale before/after under § Measurement
above measures what the option does, not what the change did to the tool, and
stands on its own.

### Rebase

Two conflicts, both the same one-line edit on two surfaces: the `-n` option
description in `print_help()` and its row in `docs/usage.md`. #457 (the run summary
printed at the end of the output) renamed the table the option controls from "the
summary table" to "the top-messages table" on both surfaces; this branch had
extended the same sentence to document `0`. Resolved by keeping the release
branch's name for the table and this branch's documentation of `0` after it, so
the merged row reads "Number of unique messages to show in the top-messages table
(default: 10). 0 keeps no individual message at all: …". Both surfaces carry the
same merge, so the `--help`/`docs/usage.md` parity `validate-help-content.sh`
enforces is preserved. `perl -c ltl` clean; no regression golden conflicted.

### Harness suite — 28 of 28 pass

Every harness exited 0 and its summary line reports checks actually run — 1 175
passing, 0 failing, across the whole suite.

| Harness | Summary |
|---|---|
| `validate-csv-output` | 21 scenarios, 21 pass, 0 fail |
| `validate-statistics` | 21 scenarios, 21 pass, 0 fail |
| `validate-category-names` | PASS 26, FAIL 0 |
| `validate-csv-input` | 4 pass, 0 fail |
| `validate-distribution-shape` | 8 passed, 0 failed |
| `validate-doc-examples` | 46 passed, 0 failed, 9 skipped |
| `validate-duration-display` | 21 passed, 0 failed |
| `validate-explain` | 148 passed, 0 failed |
| `validate-format-detection` | 192 passed, 0 failed |
| `validate-format-registry` | 22 passed, 0 failed |
| `validate-heatmap-palette` | 85 passed, 0 failed |
| `validate-help-content` | 11 passed, 0 failed |
| `validate-help-layout` | 6 passed, 0 failed |
| `validate-histogram-bin-counters` | 84 passed, 0 failed |
| `validate-histogram-ticks` | 21 passed, 0 failed |
| `validate-index-read-back` | 59 passed, 0 failed |
| `validate-log-level-vocabulary` | PASS 8, FAIL 0 |
| `validate-message-control-characters` | PASS 11, FAIL 0 |
| `validate-message-grouping-notices` | 4 passed, 0 failed |
| `validate-numeric-criteria-notices` | 10 passed, 0 failed |
| `validate-profile-render` | 22 passed, 0 failed |
| `validate-profile` | 50 passed, 0 failed |
| `validate-recursive-file-selection` | 22 passed, 0 failed |
| `validate-regression` | 71 passed, 0 failed, 0 skipped |
| `validate-runtime-config` | 36 passed, 0 failed |
| `validate-statistics-demand` | 95 passed, 0 failed |
| `validate-udm-counting` | 28 passed, 0 failed |
| `validate-udm-specs` | 43 passed, 0 failed |

`validate-csv-output.sh` ran before `validate-statistics.sh` for the shared `CI=1`
cache. `./tests/cleanup-test-artifacts.sh` was run afterwards.

### Statistics-drift advisories

No T3 or T4 failure on any of the three layers, so nothing blocks. The advisory
counts are 943 T2 cells, all on the algorithm-aware oracle layer, and 28 registered
known failures — every one of them the single projection onto the shared bin
geometry already tracked as #469 (bin-model percentile projection error), listed in
`tests/statistics-drift/known-failures.tsv`. Both counts are identical to the run
recorded for #463 (descriptive category names) on the same release branch, which is
what a change that retains fewer messages but alters no statistic should produce:
every drift scenario runs with a positive `-n`, so none of them takes the `-n 0`
path at all.
