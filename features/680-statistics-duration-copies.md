# Computing a row's statistics copies its raw durations twice (Issue #680)

## Status

`status: in progress`. The first design (D1 to D3, locked 2026-10-07) was
implemented in `ee1326c` and regresses peak memory when every row is given
statistics on a log with non-integer durations (§ 4.4). The architect then set
the resource guidelines of § 2; the design and the acceptance criteria below
are being re-examined against the map of every duration store (§ 4.5).

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

**Resource guidelines, set by the architect on 2026-10-07**, which the design
and the acceptance criteria answer to:

1. Higher memory during a subroutine, in a local variable freed when it
   returns, is a per-execution peak of that routine and acceptable.
2. The core data structures do not grow with these changes.
3. Overall resource usage is not sacrificed to optimise a single routine.
4. A large data structure no longer needed is deleted after its last use: a
   message row's durations array once its statistics are done.
5. Temporary spikes are acceptable, provided the memory that stays is memory
   the run still needs.
6. Data is written back to a structure only when there is a need for it and
   the data is known to have changed; the same array of durations is never
   sorted more than once.

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

### 4.3 Delivery measurements (`ee1326c` against `a585f97`, this machine)

**Peak memory (AC1).** The issue's command, one run each:

| Measure | `a585f97` | `ee1326c` | change |
|---|---|---|---|
| Maximum resident size (`/usr/bin/time -l`) | 1,162 MB | 924 MB | -238 MB (-20.5 %) |
| `MEMORY rss_peak` | 1,000.6 MB | 923.4 MB | -77.2 MB |
| `finalize/calculate_statistics/group_calc` | 2.68 s | 2.08 s | -0.60 s |
| total | 131.6 s | 125.9 s | |

The largest row on this run holds 3,751,230 occurrences; two copies of that
many numeric values at about 32 bytes each is 240 MB, the fall measured.

**Outputs unchanged (AC2 to AC5).** Each run before and after, from a worktree
of each commit side by side, compared after removing the version stamp, the
checkout path, timestamps, run time and peak memory:

| Input | Options (plus `--disable-progress --terminal-width 200 -o`) | Table, STATS CSV, MESSAGES CSV, aggregate export, stderr |
|---|---|---|
| One day of one server's Tomcat access log (761,698 lines) | `-n 25` | identical |
| same | `-n 25 -g -m uuid` | identical |
| same | `-n 25 -g -m uuid -bdm bin -mdm bin` | identical |
| same | `-n 25 -so p99` | identical |
| same | `-n 25 -g -m uuid -so p99` | identical |
| The month of § 4.2 | `-bs 1440 -n 25` | identical |
| same | `-bs 1440 -n 25 -g -m uuid` | identical |

The run index differs only in its read rate, peak memory and processing time
columns. No run printed a runtime warning.

### 4.4 The in-place sort enlarges the stored values it sorts (found at delivery)

**What grows.** Each duration is one Perl scalar: 24 bytes, plus 8 for its
slot in the array. Perl's optimised numeric sort (`sort { $a <=> $b }`) reads
the scalars it sorts, and when an array holds at least one non-integer value
it converts every scalar in it to a larger type that caches a second numeric
form (`NV` or `IV` to `PVNV`, 24 to 56 bytes; seen with `Devel::Peek`). Perl
never converts a scalar back, so the growth lasts as long as the scalar. An
array of integers only is left unchanged. This happens whether the sort writes
to a new array or in place: it reads the original scalars either way. Before
this change the sorted scalars were the working copy's, freed after the row's
statistics; with the in-place sort they are the store's, and stay for the run.

**Which arrays hold a non-integer.** Any log whose duration field carries a
fraction, and any row merging lines of such a log. In the month of § 4.2 the
later files write the duration with a decimal (`3125.6`) and the earlier files
as integers; the largest row (3,751,230 values) mixes both, so after its
statistics it measures 241.4 MB on `ee1326c` against 121.4 MB on `a585f97`,
while the next two rows (1,014,511 and 546,779 values, integers only) are the
same size on both.

**Every path that sorts a stored durations array**, measured on that month
(`-bs 1440 -m uuid --terminal-width 200 -V benchmark-data -mem`, one run each,
`a585f97` against `ee1326c`):

| Path | Arrays sorted | Lifetime after the sort | Options | `rss_peak` base → branch | `log_messages` base → branch |
|---|---|---|---|---|---|
| Time-bucket statistics | every bucket | freed after its statistics | (every run) | | |
| Message rows given statistics | the top `-n` rows of each category | to the end of the run | `-n 25 -g` (the issue's) | 1,000.6 → 923.4 MB | 253.6 → 373.7 MB |
| same | same | same | `-n 25` | 780.6 → 779.9 MB | 376.6 → 411.5 MB |
| same | every row | same | `-n 99999999` | **837.1 → 988.0 MB (+18.0 %)** | 491.7 → 621.5 MB |
| Sort pre-pass for a statistic operand | every key at or above the statistic's floor | to the end of the run, on both commits | `-n 25 -so p99` | 911.1 → 887.7 MB | 496.9 → 496.9 MB |

The last row shows the pre-pass already enlarged every key's array on the
base: it sorts the stored scalars. With every row given statistics, the
in-place sort is a regression: the growth accumulates across rows where the
base's copies were transient, one row at a time.

A comparator the optimiser does not recognise reads the scalars without
converting them, at a cost in time. On 3,751,230 random non-integer values,
sorted in place in isolation:

| Sort form | Sort time | Array after | Process peak |
|---|---|---|---|
| `sort { $a <=> $b }` (optimised) | 1.63 s | 120.0 MB to 240.1 MB | 569 MB |
| `sort { $a < $b ? -1 : $a > $b ? 1 : 0 }` | 3.84 s | 120.0 MB, unchanged | 431 MB |

### 4.5 Where a duration lives, from read to exit (code reading, `a585f97`)

Five stores hold raw duration values under the raw data model. A line's value
can be in the time-bucket store, the message store, the heatmap store (`-hm`
on durations) and the histogram store (`-hg`) at once, each its own copy; a
consolidated row's values are also referenced by its cluster. Phases run top
to bottom in `pipeline_finalize` order (`group_similar_messages`,
`calculate_all_statistics`, `calculate_heatmap_buckets`,
`calculate_histogram_buckets`, output). ✓ marks an array released after its
last use; ✗ marks a copy, a second sort or a retention the § 2 guidelines
rule out.

```
             │ Time buckets      │ Message rows           │ Clusters (-g)        │ Heatmap (-hm)     │ Histogram (-hg)
─────────────┼───────────────────┼────────────────────────┼──────────────────────┼───────────────────┼─────────────────────
READ         │ each line's value │ each line's value      │ a line matching a    │ each line's value │ each line's value,
per line     │ appended          │ appended               │ pattern: value       │ appended          │ one array for the
             │                   │                        │ copied in            │                   │ whole run
─────────────┼───────────────────┼────────────────────────┼──────────────────────┼───────────────────┼─────────────────────
CONSOLIDATE  │                   │ a merged row: values   │ grows with each      │                   │
(-g; also at │                   │ copied into its        │ merge                │                   │
checkpoints  │                   │ cluster, row deleted   │ final pass: gives    │                   │
during READ) │                   │ (2x one row, briefly)  │ its array to the new │                   │
             │                   │                        │ row and KEEPS it  ✗  │                   │
─────────────┼───────────────────┼────────────────────────┼──────────────────────┼───────────────────┼─────────────────────
STATISTICS   │ per bucket:       │ -so <stat>: EVERY row  │                      │                   │
             │ copy -> sorted    │ sorted; the stored     │                      │                   │
             │ copy -> stats;    │ values enlarged, kept ✗│                      │                   │
             │ stored array      │ select the top -n rows │                      │                   │
             │ deleted  ✓        │ per top row: copy ->   │                      │                   │
             │ peak 3x one       │ sorted copy -> stats   │                      │                   │
             │ bucket            │ peak 3x one row  ✗     │                      │                   │
             │                   │ -so: top rows sorted a │                      │                   │
             │                   │ second time  ✗         │                      │                   │
─────────────┼───────────────────┼────────────────────────┼──────────────────────┼───────────────────┼─────────────────────
HEATMAP,     │                   │                        │                      │ per bucket: sorted│ sorted copy of the
HISTOGRAM    │                   │                        │                      │ copy -> values;   │ whole run -> stats;
             │                   │                        │                      │ deleted  ✓        │ emptied  ✓
             │                   │                        │                      │ peak 2x one bucket│ peak 2x every line ✗
─────────────┼───────────────────┼────────────────────────┼──────────────────────┼───────────────────┼─────────────────────
OUTPUT, EXIT │                   │ every row's array kept │ kept to exit  ✗      │                   │
             │                   │ to exit, displayed or  │                      │                   │
             │                   │ not; no reader  ✗      │                      │                   │
```

Every computation over a raw store follows one pattern: sort the stored values
into a new array, compute, then (except the message store) release the stored
array. The sort reads the stored scalars, so it also enlarges them when they
hold a non-integer (§ 4.4). Where the store is released straight after, the
copy has no purpose. The heatmap and histogram rows come from code reading
and are not measured.

## 5. Design (revised to § 2, awaiting the architect's lock)

- **D1 — The working record takes the store's array by reference** (kept from
  the first design). In group_calc and in the time-bucket block,
  `$aggregated_data->{durations}` is the store's arrayref, not a copy of its
  contents.
- **D2 — Each array is sorted once, in place, by the routine that owns it at
  that moment** (replaces both the in-place sort of the stored array and the
  private copy). `calculate_statistics` sorts the array it is given in place
  (aliased to a named array, the only form Perl sorts in place) unless the
  caller states the array is already sorted, and reads min and max from its
  ends. What it is given:
  - *group_calc*: the row's array taken out of the store (`delete`), so the
    sort is of an array the routine owns, nothing is written back to the
    store, and the array is freed when the row's statistics are done (D4). Any
    enlargement (§ 4.4) lasts only for that row (guideline 1).
  - *time buckets*: the same, the bucket's array taken out of the store.
  - *the sort pre-pass under `-so`*: the stored array, sorted in place, since
    group_calc needs the same values in the same order for the keys selected.
    That write-back is the one the sort produces and group_calc reads
    (guideline 6). The keys whose array the pre-pass sorted are known from its
    own transient map of computed values, plus the keys it demoted, so group_calc
    passes "already sorted" for them and no array is sorted twice; no flag is
    stored on the entry (guideline 2). The pre-pass enlarges the arrays it
    sorts as the base's pre-pass already does (§ 4.4, `-so p99`); those of
    unselected keys are deleted right after the selection (D4).
- **D3 — The population walk's comment** states the contract: the array it
  hands over comes back sorted, and group_calc does not sort it again.
- **D4 — A message row's durations array is deleted after its last use**
  (guideline 4). Its readers end with statistics (§ 4.1), so:
  - a row given statistics in group_calc has its array taken out of the store
    for them (D2) and freed when they are done;
  - a row not selected for display has its array deleted once the selection
    is made (after the sort pre-pass under `-so`, which reads it);
  - at the final consolidation pass the cluster hands its array to the row it
    becomes, keeping no reference of its own, so deleting the row's array
    frees it. Nothing reads a cluster's durations after that hand-over: the
    reported accounting stage reads the message store alone.
  - Time buckets already delete theirs after statistics.
- **D5 — group_calc writes back only what it derives** (guideline 6).
  `$log_messages{…}{total_bytes} = $aggregated_data->{total_bytes}` stores back
  the value group_calc has just read from the same entry; it goes. The
  statistics, the means and impact are derived there and stay.

**Alternative not taken.** Sorting a private copy in every caller leaves the
store untouched but sorts a selected key's values twice under `-so`
(guideline 6) and holds a copy of each row beside its array in group_calc.

## 6. Acceptance criteria (revised to § 2, awaiting the architect's lock)

The scenarios are those of § 4.4 on the month of § 4.2, base `a585f97`
against the branch, on this machine: `-n 25 -g` (the issue's command),
`-n 25`, `-n 99999999` (every row given statistics) and `-n 25 -so p99`, each
with `-bs 1440 -m uuid --terminal-width 200 -V benchmark-data -mem`.

- [ ] **AC1 — Peak memory no higher in any scenario, lower on the issue's**
  (assertable): `MEMORY rss_peak` and the maximum resident size of
  `/usr/bin/time -l` are no higher than the base's in every scenario, and lower
  on `-n 25 -g`.
- [ ] **AC2 — The core data structures do not grow** (assertable, guideline 2):
  in every scenario the `-mem` high-water marks of `log_messages`,
  `consolidation_clusters` and `log_analysis` are no higher than the base's.
- [ ] **AC3 — Durations are released after their last use** (assertable,
  guideline 4): after statistics no message row and no cluster holds a
  durations array under the raw data model, so `MEMORY_FINAL log_messages` is
  lower than the base's by the arrays released. Verified by `-mem` and by a
  one-off probe on a scratch copy that counts the arrays left after
  statistics.
- [ ] **AC3a — No array sorted twice, nothing written back unchanged**
  (assertable, guideline 6): a one-off probe on a scratch copy counts the
  sorts of each array on the single-day access log with `-n 25 -g -m uuid` and
  with `-n 25 -so p99`, and every array is sorted at most once; group_calc
  writes nothing back to an entry that it did not derive (code reading).
- [ ] **AC4 — Time not sacrificed** (assertable, guideline 3): the
  before/after benchmark on `single-day-access-log-standard` and on
  `month-single-server-access-logs-top25-consolidate` shows no metric worse by
  more than 1 % across repeated runs.
- [ ] **AC5 — Every statistic unchanged** (assertable): the rendered table,
  STATS CSV, MESSAGES CSV and aggregate export are byte-identical before and
  after, after removing the version stamp, paths, timestamps, run time and
  peak memory: on the single-day access log with `-n 25`, `-n 25 -g -m uuid`,
  `-n 25 -g -m uuid -bdm bin -mdm bin`, `-n 25 -so p99` and
  `-n 25 -g -m uuid -so p99`, and on the month with `-bs 1440 -n 25` with and
  without `-g -m uuid`. `tests/validate-statistics.sh` (the statistics oracle)
  passes.
- [ ] **AC6 — No runtime warnings** (assertable): no ` at <file> line <N>` on
  stderr for any run above.
- [ ] **AC7 — Completion gate** (assertable): the full harness suite passes.

No new harness: the outputs are asserted by the statistics oracle and the
existing CSV harnesses, and memory by the measurements above, as
`features/619-per-run-key-cut.md` § 11.16 records for this defect.

## 7. Measurement obligations

- `680-before` on `single-day-access-log-standard`, captured on `a585f97`.
- The four scenarios of § 6, before (§ 4.4) and after, from worktrees side by
  side; the in-place alternative of § 5 measured on the same four.
- `month-single-server-access-logs-top25-consolidate` before and after, through
  `run-benchmark.sh`.
