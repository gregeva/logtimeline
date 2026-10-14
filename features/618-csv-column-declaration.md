# One declaration per CSV column, read by the STATS and MESSAGES writers, the aggregate export and the run index (Issue #618)

## Status

**Delivered**, issue closed: PR #714 merged into `release/0.19.0` as 0735cfe on 2026-10-13. The record below is the work as it went.

**Gate passed, 2026-10-13** (on 2e592f7). Decisions D1 to D9 are locked. The audited
current state (§ 3) was read on `release/0.19.0` at 5c03f24. No code has
changed. The acceptance criteria (§ 5) are put to the architect before step 1
of the plan (§ 6).

- **Parent:** #622 (the refactoring the redundant-logic audit dispatched), as a
  sub-issue; the last of its children.
- **Blocks:** #514 (count metric explicit and off by default), which changes the
  count arm of every copy this issue removes, and #301 (per-release correctness
  manifest), which would freeze the family labels into a versioned record.
- **Record of the audit findings:** `features/342-redundant-logic-surfaces-audit-report.md`
  § Item 6 and § Review progress, stages 10 and 12.

---

## 1. Requirement (issue body)

Every CSV column the tool writes is declared once: its name, its precision
family, the gate that includes it, and where its value comes from. The STATS
and MESSAGES headers and rows, the aggregate export and the run index all read
that declaration, so a column cannot appear in a header without its value, or
under one family in the tool and another in the test rules.

**Done when:** each CSV column exists in one declaration; the two CSV files,
the export and the run index write byte-identical output to the capture taken
after the rename of step 1 (D6); the precision family of every column is the
same in the tool and in the rules TSVs' `precision` field, and the tool table's
comment is true; a deliberately dropped value fails the run rather than
padding the row.

## 2. Locked decisions

D1 and D3 are the architect's locks of 2026-09-27 (stage 12 of the #342
review), transcribed from the issue body. D2 confirms the second of those locks
for the tool and D4 replaces its clause on the rules TSVs. D5 to D7 were taken
with the architect on 2026-10-13.

- **D1 — One declaration per CSV column.** Each column carries its name, its
  precision family, the gate that includes it and its value accessor, derived
  from the metric and statistic tables of #613 (`@builtin_metrics`,
  `@statistic_names`). It is read by the STATS header and row, the MESSAGES
  header and row, the aggregate export's walk, and the run index's writer and
  reader. The family lists (`duration`, `bytes`, `count`, the user-defined
  fallback) exist once at file scope. The rate column's renamed name is held
  in the declaration itself, so the header writes what the row formats.
  *Locked 2026-09-27.*
- **D2 — Impact: precision family `shape`, durations gate, no new family.**
  Impact is a log-scale ranking score (`ln(max(mean, 1)^7 × occurrences)`,
  `docs/explain/statistics.md` § impact): unitless, so it takes the `shape`
  decimals (three at the default precision, like `cv`), never the duration
  unit's. Its presence follows durations: filled whenever durations are read,
  empty under `-od` or `-d duration`
  (`features/616-gated-mean-derivation.md` D21 and D27). The declaration keeps
  precision family and gate as two attributes, which is what lets impact be
  formatted as a score and gated as a duration statistic. A family of its own
  was weighed and declined: it would add an entry to each of the three
  decimals tables for one column that needs the decimals `shape` already has.
  *Locked 2026-09-27, reconsidered and confirmed by the architect 2026-10-13.*
- **D3 — The STATS row padding goes, replaced by a hard failure.** A row whose
  value count differs from its header's is a defect that stops the run, not a
  row padded to the header width. *Locked 2026-09-27.*
- **D4 — The rules TSVs gain a `precision` field; `family` keeps its
  meaning.** The rules TSVs' `family` field is not the tool's precision family:
  it groups the columns that fill together on a row, the grouping the CSV
  harness's group-consistency check reads (`tests/csv-output/README.md` § Rules
  TSV schema: "Family membership follows populate conditions, not statistical
  theme"; `dispersion` fills at two or more observations, `shape` at four or
  more). Relabelling `duration_std_dev` and `duration_cv` from `dispersion` to
  `shape` there would make every row with two or three durations fail on
  correct output, since every main scenario activates both groups. The rules
  TSVs therefore gain a `precision` field carrying the tool's label for every
  column, checked against the tool; `family` is unchanged. Impact is
  `precision` `shape` with `required` `every-row:duration` and `family`
  `duration`, so #616 D21's and D27's wording ("impact stays in the duration
  column family in the CSV rules") holds for the `family` field. The rules
  TSVs stay hand-maintained by design and change in the same commit as the
  tool (`tests/csv-output/README.md` § Updating rules when columns change).
  *Replaces the rules-TSV clause of the 2026-09-27 lock ("the rules TSVs take
  the tool's family labels"); architect, 2026-10-13.*
- **D5 — CSV column names follow the standardized statistic and metric
  names.** `stddev` is the typed statistic name and `std_dev` a deprecated
  spelling (`features/613-one-name-vocabulary.md` D17; `-so duration_std_dev`
  already prints its deprecation notice under #614). The columns renamed:

  | Today | After |
  |---|---|
  | `duration_std_dev` (STATS and MESSAGES) | `duration_stddev` |
  | `err-rate_<unit>` (STATS) | `err_rate_<unit>` |
  | `msg-rate_<unit>` (STATS) | `msg_rate_<unit>` |
  | `std_dev` (aggregate export, each bucket's `duration` mapping) | `stddev` |

  The metric names `err` and `msg` are not changed; only the hyphen goes.
  `<unit>` is the `-ru` suffix from `%rate_csv_suffix`, every unit of the
  ladder. *Architect, 2026-10-13.*
- **D6 — The rename is the first step, on its own.** Only the column names of
  D5 change in it. The reference capture (§ 5, AC2), the statistics-drift
  baselines and any other snapshot are taken after it, so every later step is
  proven against output that already carries the new names, and "byte-identical"
  in the done-when means identical to that post-rename capture. *Architect,
  2026-10-13.*
- **D7 — The run index stays in scope.** The index is deprecated
  (`features/708-run-index-deprecation.md`: off by default, `-idx` turns it
  on) but still present, so its writer and reader read the one declaration
  like every other CSV surface. *Architect, 2026-10-13.*

- **D8 — The declaration has a fixed part and a per-run part.** The fixed
  part exists at file scope: the statistic lists, each column's precision
  family (a duration statistic's from an attribute on its row of the
  statistic table: `min`, `mean` and `max` take the metric's family, the
  percentiles and `iqr` `percentile`, `stddev`, `cv` and the moments `shape`),
  and how a metric's columns are named (`udm_csv_columns`). The per-run part
  is the list of columns one file carries, built once after the logs are read
  and the statistics calculated, from what was observed (a user-defined
  metric has columns only when a line carried a value for it; the duration
  and bytes families only when durations or bytes were observed; a category
  only when it occurred), at the point the header is built today. Each entry
  holds the header name, the precision family and how to compute the cell for
  a bucket or a message; the header is the entries' names and the row their
  cells, so the STATS header no longer renames the rate columns at write
  time. Once both CSVs read it, `%csv_column_family` and the name patterns in
  `resolve_csv_column_family` give way to the declaration. *Architect,
  2026-10-13.*
- **D9 — A user-defined `ratio` is precision family `shape`, fixed in this
  issue.** Measured 2026-10-13 on the first 100,000 lines of the ThingWorx
  application log with `-udm repeat::ratio:U` (206 occurrences over 3
  distinct users): the STATS `repeat_ratio` cell read `69` at the default
  precision and also under `-cp 3`, and `68.6666666666667` under `-cp full`.
  The formatter resolved the column's family from its name, matched none and
  fell back to 0 decimals in every mode but `full`. A ratio is unitless like
  `cv`, so it takes `shape`: `68.667` at the default and under `-cp 3`. The
  other STATS columns that matched no family (sessions, users, thread pools,
  a user-defined `distinct` or `count`) are whole numbers, so declaring their
  family changes no output in any mode. The fix is a user-observable change
  and carries its own release-notes bullet; the reference capture was retaken
  after it (`repeat_ratio` the only column that moved). *Architect,
  2026-10-13.*
  *Extended by the architect 2026-10-13* to the second column class the
  declaration changed: a user-defined metric typed with two functions
  (`-udm c::max:count -udm c::mean:count`) gets one value column per
  function, named `c:max` and `c:mean`, which matched no family and ignored
  `-cp`. Measured on `tests/fixtures/numeric-highlight-boundary.txt` with
  `-bs 1440 -oe -n 1`: under `-cp 3` the `c:mean` cell read `20` and reads
  `20.389`, as `count_mean` beside it does; at the default precision it
  reads `20` both before and after. Its family is `count`, the family of the
  metric's own columns.

**Inherited decisions this issue implements, not re-decided:**

- `features/432-metric-aggregate-naming-parity.md` D3 (CSV headers take the
  `duration_` prefix), D5 (the bytes family `occurrences min mean max` on both
  CSVs), D7 (the index column vocabulary, metric first, `mean` and
  `_occurrences`), D8 (the header and the row consult the same gate, so rows
  always match the header).
- `features/617-width-to-format-rule.md` D21: a user-defined rate metric's CSV
  columns are in the rate family, resolved from the metric by the kind
  resolver, never guessed from the column name's suffix. The declaration reads
  the family from the metric.
- `features/616-gated-mean-derivation.md` D21 and D27: impact undefined, its
  cell empty, under `-od` or `-d duration`; required on every row while
  durations are read, and exempt from the per-row family check.
- `features/column-layout-refactor.md` § Required Separation: the declaration
  is new, not the layout. The layout carries no CSV field and stays out of
  this issue.

## 3. Current state (read 2026-10-13, `release/0.19.0` at 5c03f24)

Every site named in the audit still exists. Each is listed by enclosing sub
and a snippet to grep for.

| Surface | Site | What it does today |
|---|---|---|
| STATS header | `normalize_data_for_output` :: `push @output_columns, "timestamp";` and the walk under `# Build @populated_graph_columns and @output_columns` | An if-chain over `@populated_graph_columns` pushing each metric's columns, then `map { "duration_$_" } @duration_family_stats` behind `stats_csv_duration_columns_active` |
| STATS header write | `pipeline_render` :: `if    ($_ eq 'err-rate') { "err-rate$rate_csv_suffix{$rate_unit}" }` | Renames the two rate columns at write time; the list holds the bare names |
| STATS row | `print_bar_graph` :: `if( $key =~ /^(time\|duration)$/i ) {` | A second if-chain over the same list, kept in step with the header by a comment; the `time` arm cannot match (`@graph_columns` holds `duration`, `bytes`, `count`) |
| STATS row padding | `print_bar_graph` :: `push @row, (undef) x ( $target_width - scalar @row ) if scalar @row < $target_width;` | Pads a short row to the header width, so a drift never reaches the harness's field-count check |
| STATS rate cells | `print_bar_graph` :: `push @csv_data, format_csv_value($output_columns{$category_bucket}, $category_bucket);` | Formats the rate cell under the bare name, not the name the header writes |
| MESSAGES header | `pipeline_render` :: `$csv->print($csv_fh, [qw(category message occurrences successes failures conflicts bytes_occurrences` | A literal list of 41 names, then `@udm_csv_headers` |
| MESSAGES row | `print_message_summary` :: `format_csv_value($occurrences,       'occurrences'),` | A positional list of 41 values, 37 of them repeating the column name as the family tag; per-column locals such as `my $bytes_occurrences =` are a third spelling |
| Family lists | `normalize_data_for_output` :: `push @output_columns, qw( bytes_occurrences bytes_min bytes_mean bytes_max );`; `print_bar_graph` :: `foreach my $metric ( qw( occurrences min mean max ) ) {`; `write_aggregate_export` :: `qw(occurrences min mean` | The bytes family written four times, the count family four times, the user-defined fallback `qw(occurrences min mean max sum)` three times beside `udm_csv_columns` :: `my @stats = qw(occurrences min mean max sum);` |
| Precision family table | `my %csv_column_family = (` (file scope before `resolve_csv_column_family`) | 30 entries under a comment saying it mirrors the rules TSVs; `duration_std_dev`, `duration_cv` and `impact` are `shape` there, while the rules' `family` field has `dispersion`, `dispersion` and `duration` (a different attribute, D4) |
| Family resolver | `resolve_csv_column_family` :: `return 'rate' if $column =~ /^(err\|msg)-rate(_(sec\|min\|hr\|day))?$/;` | Accepts both rate spellings; the suffix alternation names four units of the ladder |
| Run index | `write_index_file` :: `my @index_columns = qw(` and `read_index_file` :: `my @index_columns = qw(` | The column list declared twice with identical contents |
| Shared gates | `stats_csv_duration_columns_active` :: `return ($write_messages_to_csv && !$omit_durations && $durations_observed) ? 1 : 0;` and its bytes twin | Already one predicate per family, called by the header, the row and the export (D8 of #432) |
| The template | `udm_csv_columns` :: `return { shape => 'family', stats => \@stats, columns => [ map { "${prefix}_$_" } @stats ] };` | One declaration serving five consumers: the shape the other columns follow |

**Observation (no primary record line found):** the family resolver's rate
alternation names `sec`, `min`, `hr` and `day`, while `-ru` accepts every
token of the time-unit ladder (`%rate_csv_suffix` is built from
`@time_unit_ladder`), so `msg-rate_wk` exists and does not match the
alternation. No cell is affected today, because the row formats the rate under
its bare name, which the resolver's optional suffix matches. Once the header
and the row read one name (D1), the declaration's rate family must hold for
every ladder suffix; it is set from the declaration, not from a pattern over
the name.

**Measured equality today:** on `tests/fixtures/tomcat-access-single-sample-keys.txt`
with `-o`, the STATS file has 37 header fields and 37 in every row, MESSAGES 41
and 41, both kept equal by hand.

## 4. The rename (step 1) and what reads the old names

Every place outside the audit report that names a renamed column, found by
`git grep` for `duration_std_dev`, `err-rate_`, `msg-rate_` and
`rate_csv_suffix` on 2026-10-13:

| Where | What changes |
|---|---|
| `ltl`: `pipeline_render` (the rate header names, the MESSAGES header literal), `print_message_summary` (the `duration_std_dev` family tag), `%csv_column_family`, `resolve_csv_column_family` | The emitted names and the names the formatter resolves |
| `tests/csv-output/rules/stats-columns.tsv`, `messages-columns.tsv` | The `column` field of the renamed rows |
| `tests/validate-bucket-size-units.sh` (the `msg-rate_wk` assertion), `tests/csv-output/expected/udm-rate-cell.tsv` (the `msg-rate_sec` cell) | The column each assertion looks up |
| `tests/validate-log-level-vocabulary.sh` (the error-rate column it reads), `tests/aggregate-export/rules/keys.tsv` and `validate-aggregate-export.pl` (the export's `duration.std_dev` key and its CSV twin), `tests/statistics-drift/compare-statistics-drift.pl` (`l3_csv_column`, mapping the oracle's `std_dev` to its CSV column) | The name each harness looks up |
| `tests/statistics-drift/baselines/*/{stats,messages}.csv` (50 files) | Header line rewritten to the new names; no other line changes, which the drift harness then confirms against the renamed output (D6) |
| `features/224-validate-statistics-test-harness.md` § Decision 5, `features/503-yaml-aggregate-export.md` (the `err_rate` key's comment), `features/rate-unit.md`, `features/user-defined-metrics.md` | Current-contract mentions of the STATS rate and `std_dev` column names, trued up in the same step |
| `ltl`: `write_aggregate_export` (the duration family's `std_dev` key); `features/503-yaml-aggregate-export.md` (the schema example's `std_dev`) | The export's statistic key |
| `releases/v0.19.0.md` | One bullet: the renamed columns and export key |

Not changed: `-so duration_std_dev` keeps its deprecation notice
(`tests/validate-statistics-demand.sh` asserts it); that is the sort operand,
not a CSV column. The user-defined rate columns (`<name>_rate_<unit>`) already
use an underscore.

## 5. Acceptance criteria

Each criterion is triaged before code. "Capture set" is the reference capture
of D6: STATS, MESSAGES, aggregate export and run index files, written after
step 1 from inputs chosen in `docs/test-logs.md` to exercise every gate (durations on and off, `-od`, bytes, count,
user-defined numeric, counting and rate metrics, `-cp default`, `full` and a
decimal count, two `-ru` units, a highlight).

- [ ] **AC1 — Renamed headers.** Every STATS and MESSAGES header writes
      `duration_stddev`, and STATS writes `err_rate_<unit>` and
      `msg_rate_<unit>` for the run's `-ru` unit, including a unit outside
      `sec`/`min`/`hr`/`day`; no header carries `duration_std_dev`,
      `err-rate` or `msg-rate`. *Assertable:* the CSV-output harness, whose
      rules name every header column, and `validate-bucket-size-units.sh` for
      `-ru w`.
- [ ] **AC2 — Byte-identical to the post-rename capture.** After every later
      step, each file of the capture set is byte-identical to its capture.
      *Assertable:* `cmp` of each file against the capture, run at each step;
      the statistics-drift baselines and the CSV-output harness re-assert it
      in the suite.
- [ ] **AC3 — One declaration.** No column name of either CSV is spelled in
      the STATS or MESSAGES header or row code, the export's walk or the
      index's writer or reader outside the declaration; the family lists
      (`duration`, `bytes`, `count`) appear once at file scope and the
      user-defined fallback is read from `udm_csv_columns`. *Assertable at
      review:* a grep of the writer subs for each family's literal list
      returns only the declaration.
- [ ] **AC4 — The tool and the rules agree on every column's precision
      family.** Every rules row carries a `precision` value equal to the
      family the tool formats that column under, and `%csv_column_family`'s
      comment states what is true. *Assertable:* the tool writes each emitted
      column's precision family into a `-V` section, read from the
      declaration, and the CSV-output harness compares it with the rules'
      `precision` field (`tests/HARNESS-DESIGN.md` followed). *Method agreed
      by the architect 2026-10-13.*
- [ ] **AC5 — A short row fails.** A row whose value count differs from the
      header's stops the run with a message naming the file and both counts.
      *Unassertable by a harness* (it needs a defect in the tool to fire);
      verified once during development by removing one accessor from the
      declaration, with the run's output recorded in this doc.
      *Verified 2026-10-13 (STATS):* the `occurrences` entry's cell made to
      return nothing, run on `tests/fixtures/gated-means-access.txt` with
      `-o -bs 1`: exit 255, stderr `STATS CSV row for 2025-05-07 00:00
      carries 36 values under a header of 37 columns`, no row written. The
      padding it replaces had never fired: a probe that reported any row
      shorter than its header found none over the 36 runs of the reference
      capture.
- [ ] **AC6 — The rate cell is formatted under the name the header writes.**
      The rate cells carry the rate family's decimals under every `-ru` unit
      (one decimal at the default precision). *Assertable:* the CSV-output
      harness's cell expectations (`tests/csv-output/expected/`).
- [ ] **AC7 — The run index reads one list.** The writer and the reader read
      one column declaration; the index read-back harness passes unchanged.
      *Assertable:* `validate-index-read-back.sh`.
- [ ] **AC9 — A user-defined ratio carries the shape decimals.** On a day
      bucket where ten lines carry the key over four distinct values, the
      STATS ratio cell reads `2.5`. *Assertable:* the CSV-output harness's
      `udm-ratio-cell` scenario (`tests/csv-output/expected/udm-ratio-cell.tsv`),
      shown to fail on the code before the fix.
- [ ] **AC10 — A user-defined metric's function column honours `-cp`.**
      Under `-cp 3`, the `c:mean` column of `-udm c::max:count -udm
      c::mean:count` reads `20.389` on the one day bucket of the numeric
      boundary fixture. *Assertable:* the CSV-output harness's
      `udm-function-collision-cell` scenario, shown to fail on the code
      before step 3.
- [ ] **AC8 — No runtime warnings** on any run of the capture set
      (`tests/lib/runtime-warnings.sh`). *Assertable.*

## 6. Plan

One step at a time, each committed and pushed on the issue branch once its
output is read against the capture.

1. **Rename** (D5, D6): § 4's sites, the rules TSVs' `column` field, the
   statistics-drift baselines' header line. Then the capture set is written
   and kept in the scratchpad as the reference. *Done 2026-10-13* (bfb0c06);
   the release-notes bullet is written at close-out on the release branch.
2. **Family lists at file scope** (D1): `bytes` and `count` beside
   `@duration_family_stats`; the user-defined fallback read from
   `udm_csv_columns`. *Done 2026-10-13* (c6a38f1).
   Then the ratio fix (D9, 0810cff), and the reference capture retaken.
3. **The STATS declaration** (D1, D3, D8): header and row from one walk; the
   rate name held in the declaration; the padding replaced by the hard
   failure. `build_stats_csv_columns()` builds `@stats_csv_columns` after
   the read; the statistic table carries each statistic's `precision`; a
   user-defined value column's family comes from `udm_csv_family()`;
   `format_csv_family_value()` formats by family, with `format_csv_value()`
   resolving a name for the MESSAGES file until step 4. The user-defined
   fallback list for a metric with no configuration is gone: every
   `udm_` graph column is named from `@udm_configs` after
   `resolve_udm_metric_names()`, so the configuration is always found.
4. **The MESSAGES declaration** (D1): header and row from the declaration,
   shared with STATS where the column is the same statistic.
   `build_messages_csv_columns()` builds `@messages_csv_columns` when the
   file is opened; `metric_family_csv_columns()` gives both files the
   duration, bytes and count families (each entry naming the stored key its
   value is read under); `csv_declared_row()` writes a row of either file and
   stops the run on a length mismatch. The per-message locals that only the
   CSV row read are gone. `format_csv_value()` formats by family, which every
   caller now passes; `%csv_column_family` and `resolve_csv_column_family()`
   are gone, so no column's family is guessed from its name. The run index's
   fixed-decimal means pass their metric's family, which the fixed decimals
   override. *Verified 2026-10-13 (MESSAGES):* the `impact` entry's cell made
   to return nothing, same input as the STATS probe: the run stops, stderr
   `MESSAGES CSV row for '[200] GET /gm/order' carries 40 values under a
   header of 41 columns`.
5. **Rules `precision` field and its `-V` section** (D4, AC4): the field added
   to both rules TSVs with the tool's label for every column, and the check.
   It follows the two declarations because the section reports the family
   each cell is formatted under, which only the declaration holds: today the
   STATS rate cells and the user-defined cells are formatted under a name
   other than their header's. *Done 2026-10-13* (20c2d40).
   **Section contract, `-V csv-output / columns`:** inside `csv-output`,
   emitted whenever `-o` is active; a tab-separated header row `file`,
   `column`, `precision`, then one row per column of the STATS file and then
   of the MESSAGES file, each in file order; `file` is `stats` or
   `messages`, `column` the header name as written, `precision` the family
   its cells are written in (`meta`, `count`, `duration`, `percentile`,
   `shape`, `bytes`, `level`, `rate`). Read by `validate-csv-output.pl`,
   which fails when a file's rows are not its header in order, or when a
   header column's rules `precision` differs. Of the rules rows, 129 took
   the label the tool reported over the 38 capture runs; 63 STATS rows the
   capture never emits took the label the declaration gives their kind (48
   log-level columns `level`, 14 rate columns `rate`, `sessions-HL` `meta`).
6. **The aggregate export's walk** reads the declaration. *Done 2026-10-13*
   (107cd8b): each `metric_family_csv_columns()` entry carries its
   statistic's typed name, which the export writes as its key; the export's
   duration, bytes and count walks read those entries, a user-defined
   family its `udm_csv_columns()` statistics, and its gates stay the shared
   predicates the STATS declaration asks.
7. **The run index** (D7): one column list read by the writer and the reader.
   *Done 2026-10-13* (55c5fcd): `@index_columns` at file scope; each row is
   built by `index_row()` from cells keyed by column name. A row missing a
   cell or carrying one for no column stops the run: the writer's `eval`,
   which lets an unwritable index file pass silently, re-raises that defect.
   Verified by a probe dropping the `filters` cell: exit 255, stderr
   `ltl-index.csv row: no cell for filters`.

**After step 7:** every file of the reference capture (38 runs, 152 files)
byte-identical to the capture taken after the ratio fix and the step 3
scenario; AC3 checked by grep: no column list is spelled in the STATS or
MESSAGES writers, the export's walk or the index writer outside the
declarations (the index reader names the six columns it reads back as
pre-seed values, a lookup, not a list of the file's columns).
`docs/architecture-patterns.md` names the declaration under *Declarative
table with one resolver*.

## 7. Merge gate

The diff touches executable lines of `ltl`, so the full harness suite and a
before/after benchmark (`single-day-access-log-standard`, `before` captured on
the base commit) run on the commit being merged
(`docs/process/workflow.md` § 3).

**Run 2026-10-13 on 2e592f7** (version `0.19.0`): all 49 harnesses exit 0,
none with a runtime warning, each summary showing its assertions ran.
Benchmarks, before on the base commit (420e598, from the release worktree)
and after on 2e592f7 (from the issue worktree), one run each:
`single-day-access-log-standard` total 6.9 s → 6.2 s, peak RSS 98.2 →
97.8 MB (no CSV written; the time difference is machine variance);
`single-day-access-log-heatmap-histogram-export` (`-o`, the case that
writes the CSVs and the export) total 8.3 s → 8.1 s, peak RSS 68.0 →
67.7 MB. No metric worse by more than 1%. The export case runs with
`-n 0`, so it writes no MESSAGES rows; the MESSAGES file holds at most the
`-n` rows per grouping, so its writer's cost is bounded by `-n`.
