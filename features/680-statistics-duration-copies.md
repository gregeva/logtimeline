# Computing a row's statistics copies its raw durations twice (Issue #680)

## Status

`status: in progress`. Scope widened by the architect on 2026-10-07 to every
store of raw values (§ 2). The first design (`ee1326c`, in-place sort of the
stored array) regresses peak memory when every row is given statistics on a log
with non-integer durations (§ 4.4); the design of § 5 replaces it, locked by the
architect on 2026-10-07 with the acceptance criteria of § 6.

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

**Scope, widened by the architect on 2026-10-07.** Every store of raw values
whose statistics are computed by sorting them follows one pattern, and the fix
is that pattern applied to all five: the time-bucket store, the message store,
the consolidation clusters' references to it, the heatmap's raw store and the
histogram's raw store (§ 4.5). The pattern is recorded in
`docs/architecture-patterns.md`.

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
   the data is known to have changed. The accumulated values of an array are
   sorted once, and the messages are ranked once; neither is redone. Sorts
   happen at a defined moment, after the data they order is final (never
   before consolidation, which merges arrays).

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
copy has no purpose.

**The heatmap and histogram hold raw values only when pinned to the raw data
model** (`-hmdm raw`, `-hgdm raw`, or `-dm raw`); by default they use bin
counters. The release benchmark (`tests/baseline/results/v0.19.0-first.tsv`,
`all` tier, `-mem` high-water marks) shows the stores' measured sizes; no case
pins the heatmap or histogram to raw, so their raw stores measure 0 throughout:

| Case | `log_messages` | `consolidation_clusters` | `log_analysis` | `heatmap_counters` | `histogram_counters` | `rss_peak` |
|---|---|---|---|---|---|---|
| month, many servers, standard | 6,731.2 MB | 0 | 1,267.2 MB | 0 | 0 | 9,439.4 MB |
| month, many servers, `-so p99` | 7,636.7 MB | 0 | 1,267.2 MB | 0 | 0 | 10,807.5 MB |
| month, many servers, top25 consolidate | 1,282.5 MB | 1,162.3 MB | 1,275.4 MB | 0 | 0 | 4,644.2 MB |
| month, one server, standard | 1,316.1 MB | 0 | 255.9 MB | 0 | 0 | 1,894.4 MB |
| month, one server, heatmap histogram | 1,393.7 MB | 0 | 0 | 2.5 MB | 0.3 MB | 1,727.3 MB |

The message store is the largest structure in every case that keeps messages,
and it is held to exit. Releasing its arrays after their last use frees memory
for the rest of the run, but does not lower a peak reached while the store is
whole: the peak falls only by the copies removed from the statistics step.

### 4.6 Sorts after the change (code reading, AC3a)

Every numeric sort in `ltl` that orders raw values, after the change:

| Sort | Sub | Array | Runs |
|---|---|---|---|
| `sort_numeric_in_place` (the only one) | `calculate_statistics` | a time bucket's array taken out of its store; a displayed row's array taken out of its store; under `-so` on a statistic, each row's stored array in the ranking pre-pass | once per array: group_calc skips the sort for a key the pre-pass sorted (`durations_sorted`, from `%presorted`) |
| same helper | `calculate_heatmap_buckets_exact` | the bucket's raw values, deleted after | once per bucket |
| same helper | `calculate_histogram_buckets_exact` | the metric's raw values and their highlight twin, emptied after | once per metric |

Every one runs from `pipeline_finalize` after `group_similar_messages` has
returned. The other numeric sorts in `ltl` order bucket timestamps, partition
telemetry and cliff edges, not raw values. group_calc no longer writes
`total_bytes` back (D7).

### 4.7 Hand-forward: every entry is created with an empty durations array

The read loop creates `durations => []` on every message entry and every time
bucket whatever the data model and whether any surface demands statistics
(the entry initialisers in `read_and_process_logs`). Under `-mdm bin`, `-bdm
bin`, or `-od`, each entry carries an empty array no reader uses. This change
releases them at the statistics step (D1, D2), but they exist from the read
until then. Changing it is a read-loop change, outside this issue: not filed
yet, for the architect to decide.

## 5. Design (one pattern for every raw store, locked by the architect, 2026-10-07)

**The pattern.** At a raw array's last use, the computation that needs it in
order takes it out of its store, sorts it in place, computes from it and lets
it go. No copy is made; the enlargement of § 4.4 falls on an array the routine
owns and ends with it (guidelines 1, 5); nothing is written back to the store
(guideline 6); the store never holds an array past its last use (guideline 4).
`calculate_statistics` sorts the array it is given in place (aliased to a named
array, the only form Perl sorts in place) and reads min and max from its ends,
unless the caller states the array is already sorted.

| | Store | Sorted | By | Released |
|---|---|---|---|---|
| D1 | Time buckets | once, in place | bucket statistics, after taking the array out of the bucket | when the bucket's statistics are done |
| D2 | Message rows, no `-so` on a statistic | once, in place | group_calc, after taking the array out of the row | when the row's statistics are done; a row not displayed, once the selection is made |
| D3 | Message rows, `-so` on a statistic | once, in place in the store | the ranking step, which needs every row's statistic before it can rank the messages | a row not displayed, once the selection is made; a displayed row, after group_calc computes its full statistics from the sorted array without sorting it again |
| D4 | Consolidation clusters: the cluster structure, consolidation's working store | not in that structure: at the final pass each cluster becomes a consolidated row in the message store, sorted, given statistics and ranked by D2 or D3 like any message | (the final pass) | the cluster structure hands its array to the row and keeps no reference, so releasing the row's array frees it |
| D5 | Heatmap raw store (`-hmdm raw`) | once, in place | the heatmap's per-bucket percentiles | when the bucket is done (as today) |
| D6 | Histogram raw store (`-hgdm raw`) | once, in place | the histogram's percentiles, per metric and its highlight twin | when the metric is done (as today) |

- **D3, the order of sorts.** The values of each row are sorted once and the
  messages are ranked once. The ranking step's in-place sort is the one
  write-back to the store, and the order it writes is the order group_calc
  reads. group_calc knows which arrays the ranking step sorted from that
  step's own transient map of computed values plus the keys it demoted; no flag
  is stored on the entry (guideline 2). A row ranked without a value (below the
  statistic's floor) was not sorted, and group_calc sorts it if it is
  displayed. For a log with non-integer durations, the ranking step enlarges
  every row's array at once, as the base's ranking step already does, and the
  enlargement ends with each row's release; the architect accepted this on
  2026-10-07.
- **D7 — group_calc writes back only what it derives** (guideline 6).
  `$log_messages{…}{total_bytes} = $aggregated_data->{total_bytes}` stores back
  the value group_calc has just read from the same entry; it goes.
- **D8 — The pattern is recorded in `docs/architecture-patterns.md`**, with its
  consumption sites, in the commit that implements it.
- **Sort moments.** No raw array is sorted before or during consolidation;
  every sort above runs after `group_similar_messages` has returned, when the
  arrays are final.

## 6. Acceptance criteria (locked by the architect, 2026-10-07)

The scenarios are those of § 4.4 on the month of § 4.2, base `a585f97`
against the branch, on this machine: `-n 25 -g` (the issue's command),
`-n 25`, `-n 99999999` (every row given statistics), `-n 25 -so p99`, and
`-n 25 -hm -hg -hmdm raw -hgdm raw` (the heatmap and histogram raw stores),
each with `-bs 1440 -m uuid --terminal-width 200 -V benchmark-data -mem`.

- [ ] **AC1 — Peak memory no higher in any scenario, lower on the issue's**
  (assertable): `MEMORY rss_peak` and the maximum resident size of
  `/usr/bin/time -l` are no higher than the base's in every scenario, and lower
  on `-n 25 -g`.
- [ ] **AC2 — The core data structures do not grow** (assertable, guideline 2):
  in every scenario the `-mem` high-water marks of `log_messages`,
  `consolidation_clusters`, `log_analysis`, `heatmap_raw` and
  `histogram_values` are no higher than the base's.
- [ ] **AC3 — Durations are released after their last use** (assertable,
  guideline 4): after statistics no message row and no cluster holds a
  durations array under the raw data model, so `MEMORY_FINAL log_messages` is
  lower than the base's by the arrays released. Verified by `-mem` and by a
  one-off probe on a scratch copy that counts the arrays left after
  statistics.
- [ ] **AC3a — Each array sorted once, the messages ranked once, nothing
  written back unchanged** (assertable by code reading, guideline 6): every
  sort of a raw array is one of D1 to D6, runs after consolidation has
  returned, and no path reaches a second sort of the same array; group_calc
  writes back nothing it did not derive.
- [ ] **AC4 — Time not sacrificed** (assertable, guideline 3): the
  before/after benchmark on `single-day-access-log-standard` and on
  `month-single-server-access-logs-top25-consolidate` shows no metric worse by
  more than 1 % across repeated runs.
- [ ] **AC5 — Every statistic unchanged** (assertable): the rendered table,
  STATS CSV, MESSAGES CSV and aggregate export are byte-identical before and
  after, after removing the version stamp, paths, timestamps, run time and
  peak memory: on the single-day access log with `-n 25`, `-n 25 -g -m uuid`,
  `-n 25 -g -m uuid -bdm bin -mdm bin`, `-n 25 -so p99` and
  `-n 25 -g -m uuid -so p99` and `-n 25 -hm -hg -hmdm raw -hgdm raw`, and on the
  month with `-bs 1440 -n 25` with and without `-g -m uuid`. `tests/validate-statistics.sh` (the statistics oracle)
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
