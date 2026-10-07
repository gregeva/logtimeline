# Computing a row's statistics copies its raw durations twice (Issue #680)

## Status

`status: in progress`. Design (D1 to D3) and acceptance criteria locked by the
architect on 2026-10-07; implementation under way.

## 1. The motivating consumer

Peak memory of a grouped run. Under the raw data model, the statistics step
holds three arrays of one row's durations at once: the row's own, a working
copy, and the sorted copy. A consolidated row grows with every message merged
into it, so peak memory grows with the largest row. 0.19.0's intermediate
benchmark showed peak resident size up 40 % to 71 % on the four grouping cases
of the two month-scale access-log selections, all of it unattributed memory
(`features/619-per-run-key-cut.md` § 11.16, which holds the measurement, the
bisect and the trial fix this issue inherits).

## 2. Requirement

Computing the statistics of a message row or a time bucket under the raw data
model holds no copy of its durations beyond the one the store already keeps.
Every statistic, every table and every CSV is unchanged.

## 3. The sites, as they are today (`release/0.19.0` at `a585f97`)

- **Message rows, `calculate_all_statistics`, the group_calc sub-stage.** Each
  retained key builds a working record and copies the key's array into it:
  `push @{$aggregated_data->{durations}}, @{$log_messages{$category}{$log_key}{durations}}`.
  The key's own array is kept.
- **Message rows, the population walk** (the sort pre-pass for a statistic
  operand). Already hands over the key's array without copying; its comment
  rests on `calculate_statistics` never mutating its input.
- **Time buckets, `calculate_all_statistics`.** The same copy into a working
  record, `push @{$aggregated_data->{durations}}, @{$log_analysis{$bucket}{durations}}`,
  after which the bucket's own array is deleted.
- **`calculate_statistics`.** Sorts into a new array,
  `my @sorted = sort { $a <=> $b } @{$bucket_data->{durations}};`, then takes
  `min(@sorted)` and `max(@sorted)` by two further full passes.

The bin data model (`-bdm bin`, `-mdm bin`) collects no durations array and
reaches `calculate_statistics_bin`; it is untouched by this issue.

## 4. Findings

### 4.1 Nothing reads a durations array in arrival order after statistics

The issue's open question, audited on `a585f97`. Every reference to a
`durations` array in `ltl`:

| Reader | When it runs | Reads order? |
|---|---|---|
| Read loop: push of each line's duration (message key, time bucket, the first line of a streamed cluster) | during the read | writes only |
| Consolidation: `merge_consolidation_stats` concatenates a source's array into a cluster's; the final pass hands a cluster's array to its row | `group_similar_messages`, in `pipeline_finalize` before `calculate_all_statistics` | no |
| `consolidation_accounting_add`: `scalar @{ $entry->{durations} }` | consolidation stages, before statistics | count only |
| Population walk and group_calc: hand the array to `calculate_statistics` | `calculate_all_statistics` | sorts it |
| `calculate_statistics` | the statistics step | sorts it |

No reader runs after `calculate_all_statistics`, and none before it depends on
order. A row's array may be shared by reference between a cluster and the row
the final pass creates from it; sorting it in place sorts both, which nothing
observes.

### 4.2 The premise, re-measured on the base

The code has moved since the issue was written (#605, the bound declaration
and units on inputs, landed since `8462ae3`). The issue's command
(`-bs 1440 -n 25 -g -m uuid --terminal-width 200 -V benchmark-data -mem`, a
month of one server's Tomcat access logs carrying the thread name, 28 daily
files, 1.5 GB), one run on `a585f97` on this machine:

| Measure | `a585f97` |
|---|---|
| Maximum resident size (`/usr/bin/time -l`) | 1,162 MB |
| `MEMORY rss_peak` | 1,000.6 MB |
| `finalize/calculate_statistics/group_calc` | 2.68 s |
| total | 131.6 s |

The record's 1,243 MB at `8462ae3` was measured on the benchmarking machine;
the two are not comparable, which is why the fix's before and after are both
measured here (§ 7).

## 5. Design (locked by the architect, 2026-10-07)

The record's variant C, measured on scratch copies at `8462ae3` (§ 11.16:
1,243 MB to 973 MB maximum resident size, message table byte-identical, the
pre-regression commit at 982 MB).

- **D1 — The working record takes the store's array by reference.** In
  group_calc and in the time-bucket block, `$aggregated_data->{durations}` is
  the store's arrayref, not a copy of its contents. The time bucket's
  `delete` after statistics stays, and frees the array once the working record
  goes out of scope.
- **D2 — `calculate_statistics` sorts its input in place.** The array it is
  given is sorted ascending afterwards; min and max are its first and last
  elements. Perl sorts in place only when the result is assigned back to the
  same *named* array (`@x = sort … @x`); through a reference
  (`@$r = sort … @$r`) it builds a temporary list, which the record measured at
  293 MB against 160 MB on 3,751,230 values. So the arrayref is aliased to a
  named array for the sort. The form proposed is a package array aliased with
  `local *name = $arrayref`, the form the record probed; the alternative,
  `\my @x = $arrayref`, needs the experimental `refaliasing` feature, which
  `ltl` does not use anywhere.
- **D3 — The population walk's comment is rewritten** to the new contract: the
  array it hands over comes back sorted, which group_calc then re-sorts at the
  cost of a pass over already-ordered input.

## 6. Acceptance criteria

- [ ] **AC1 — Peak memory no longer carries the copies** (assertable): the
  issue's command on the month of one server's Tomcat access logs, run before
  and after on this machine, shows maximum resident size falling by at least
  the size of two copies of the largest row's durations, and `group_calc` time
  no worse. Read from `/usr/bin/time -l` and `-V benchmark-data`.
- [ ] **AC2 — Every statistic unchanged, raw data model** (assertable): on the
  same input before and after, with and without `-g`, the rendered message
  table, the STATS CSV and the MESSAGES CSV (`-o`) are byte-identical after
  version normalisation. By direct diff, on the single-day access log and on
  the month selection of AC1. `tests/validate-statistics.sh` (the statistics
  oracle) passes.
- [ ] **AC3 — Bin data model unchanged** (assertable): the AC2 diff under
  `-bdm bin -mdm bin` on the single-day access log is byte-identical.
- [ ] **AC4 — A statistic sort operand unchanged** (assertable): under
  `-so p99` (the population walk's path) the message table is byte-identical
  before and after.
- [ ] **AC5 — No runtime warnings** (assertable): no ` at <file> line <N>` on
  stderr for any run of AC1 to AC4.
- [ ] **AC6 — Completion gate** (assertable): the full harness suite passes;
  the before/after benchmark on `single-day-access-log-standard` shows no
  metric worse by more than 1 %, and the month-scale grouping case of AC1
  (`month-single-server-access-logs-top25-consolidate`) is benchmarked before
  and after, as the architect directed on 2026-10-05 (`features/619-per-run-key-cut.md`
  § 11.16, Disposition).

No new harness: the outputs are asserted by the statistics oracle and the
existing CSV harnesses, and peak memory by the benchmark, as § 11.16 records
for this defect.

## 7. Measurement obligations

- `680-before` on `single-day-access-log-standard`, captured on `a585f97`.
- AC1's run, before: § 4.2. After: the same command on the branch, from a
  worktree beside the base's.
- `month-single-server-access-logs-top25-consolidate` before and after, through
  `run-benchmark.sh`.
