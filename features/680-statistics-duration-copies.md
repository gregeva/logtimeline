# Computing a row's statistics copies its raw durations twice (Issue #680)

## Status

`status: in progress`. Scope as locked last, 2026-10-07: § 5.0 (rows keep
their data by default; the release is behind a hidden `-mem release`). Scope widened by the architect on 2026-10-07 to every
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

### 4.8 Delivery measurements of the pattern (`ef95ff4` against `a585f97`)

Three rounds, interleaved base then branch, one run each per round, on this
machine; the month of § 4.2 with `-bs 1440 -m uuid --terminal-width 200
-V benchmark-data -mem` plus the scenario's options: `g` is `-n 25 -g`, `n25`
is `-n 25`, `hmhg` is `-n 25 -hm -hg -hmdm raw -hgdm raw`. Peak resident size
is the operating system's (`/usr/bin/time -l`); `-mem`'s own `rss_peak`
samples between steps and misses the spike inside statistics (969 MB against
1,124 MB on the same base run). Medians with ranges:

```
== g
  metric                              base median [range]        branch median [range]     change
  peak resident (OS)            1,236.1 [1,123.9–1,239.9]          970.2 [905.5–978.8]     -21.5%
  log_messages high-water             253.6 [253.6–253.6]          172.3 [172.3–172.3]     -32.1%
  log_messages at end                 253.6 [253.6–253.6]                1.1 [1.1–1.1]     -99.5%
  clusters high-water                 221.0 [221.0–221.0]          221.0 [221.0–221.0]      -0.0%
  clusters at end                     221.0 [221.0–221.0]                0.9 [0.9–0.9]     -99.6%
  log_analysis high-water             254.0 [254.0–254.0]          254.0 [254.0–254.0]      +0.0%
  heatmap_raw high-water                    0.0 [0.0–0.0]                0.0 [0.0–0.0]      +0.0%
  histogram high-water                      0.0 [0.0–0.0]                0.0 [0.0–0.0]      +0.0%
  statistics step                        6.42 [5.94–7.07]             4.97 [3.99–5.20]     -22.7%
    bucket_stats                         3.39 [3.34–3.85]             2.28 [1.76–2.41]     -32.7%
    group_calc                           3.02 [2.59–3.20]             2.68 [2.22–2.78]     -11.4%
  read files (untouched)           153.37 [119.43–156.25]       156.83 [116.68–157.26]      +2.3%
  total                            165.18 [130.11–168.77]       167.39 [125.15–167.97]      +1.3%
== n25
  metric                              base median [range]        branch median [range]     change
  peak resident (OS)                  800.0 [774.2–810.4]          758.5 [755.3–759.2]      -5.2%
  log_messages high-water             376.6 [376.6–386.2]          376.6 [376.6–376.6]      -0.0%
  log_messages at end                 376.6 [376.6–386.2]          104.2 [104.2–104.2]     -72.3%
  clusters high-water                       0.0 [0.0–0.0]                0.0 [0.0–0.0]      +0.0%
  clusters at end                           0.0 [0.0–0.0]                0.0 [0.0–0.0]      +0.0%
  log_analysis high-water             253.3 [253.3–253.3]          253.3 [253.3–253.3]      +0.0%
  heatmap_raw high-water                    0.0 [0.0–0.0]                0.0 [0.0–0.0]      +0.0%
  histogram high-water                      0.0 [0.0–0.0]                0.0 [0.0–0.0]      +0.0%
  statistics step                        2.75 [2.71–3.64]             2.94 [2.89–3.73]      +7.0%
    bucket_stats                         1.84 [1.83–2.39]             1.63 [1.63–2.12]     -11.1%
    group_calc                           0.47 [0.47–0.68]             0.82 [0.80–1.07]     +73.2%
  read files (untouched)            101.46 [97.27–130.97]         99.00 [98.01–127.50]      -2.4%
  total                            104.24 [100.00–134.65]       101.96 [100.92–131.27]      -2.2%
== hmhg
  metric                              base median [range]        branch median [range]     change
  peak resident (OS)            2,278.0 [2,122.4–2,394.4]    2,054.4 [2,020.7–2,083.4]      -9.8%
  log_messages high-water             386.2 [376.6–386.2]          386.2 [376.6–386.2]      -0.0%
  log_messages at end                 386.2 [376.6–386.2]          113.8 [104.2–113.8]     -70.5%
  clusters high-water                       0.0 [0.0–0.0]                0.0 [0.0–0.0]      +0.0%
  clusters at end                           0.0 [0.0–0.0]                0.0 [0.0–0.0]      +0.0%
  log_analysis high-water                   0.0 [0.0–0.0]                0.0 [0.0–0.0]      -8.9%
  heatmap_raw high-water              589.7 [589.7–589.7]          589.7 [589.7–589.7]      +0.0%
  histogram high-water                794.4 [794.4–794.4]          794.4 [794.4–794.4]      +0.0%
  statistics step                        0.91 [0.91–1.29]             1.44 [1.32–1.87]     +58.3%
    bucket_stats                         0.00 [0.00–0.00]             0.00 [0.00–0.00]      +0.0%
    group_calc                           0.44 [0.43–0.62]             0.93 [0.89–1.32]    +112.6%
  heatmap step                        11.10 [11.01–15.07]          11.71 [11.49–14.55]      +5.4%
  histogram step                      22.85 [22.75–30.70]          25.83 [25.18–32.75]     +13.0%
  read files (untouched)           104.20 [103.59–147.94]       102.61 [101.85–138.30]      -1.5%
  total                            139.10 [138.29–195.05]       141.62 [139.87–187.52]      +1.8%
```

**Memory.** Peak resident size is lower in all three scenarios; no structure's
high-water mark is higher; after statistics no durations array remains (a probe
on a scratch copy counts 0 arrays on the `g` run), so the message store ends
70 % to 99.5 % smaller. The `+79 MB` of the single `hmhg` run in § 4.4's
tables was run-to-run variation: the base alone ranges 2,122 to 2,394 MB.

**Time, attributed.** File reading, untouched, varies by up to 30 % between
rounds, so totals are compared within a round.
- *Releasing the rows not displayed* costs about 0.35 to 0.5 s in group_calc
  when most of the month's 7.7 million values sit in rows not displayed (`n25`,
  `hmhg`): freeing them. The base never freed them; it held them to exit.
- *A pass over values sorted in place is slower.* After an in-place sort,
  neighbouring elements point to scalars scattered through memory in the order
  the read allocated them, so a pass in sorted order misses the cache; a sorted
  copy lays its scalars out in order. On 7,750,000 integers allocated among
  other structures, in isolation:

  | Order | sort + pass + free | Peak resident |
  |---|---|---|
  | Sort into a copy, pass over the copy (base) | 3.21 to 3.22 s | 1,785 to 1,839 MB |
  | Sort in place, pass in sorted order (`ef95ff4`) | 4.40 to 4.43 s | 1,589 MB |
  | Pass over the unsorted values first, then sort in place for percentiles | 3.30 to 3.36 s | 1,589 MB |

  The histogram (+3.0 s median) and heatmap (+0.6 s) steps each make a
  bucket-counting pass over every value after sorting; the count does not
  depend on order. The shape-moment loop of `calculate_statistics` makes the
  same kind of pass, under shape demand only, and its floating-point sums
  depend on the order, so moving it would change the reported moments.

### 4.9 Completion gate (`d6f1ecf`, version restored to `0.19.0`)

**D9 on the raw heatmap and histogram** (`hmhg` of § 4.8, three interleaved
rounds, medians with ranges):

```
  metric                              base median [range]        branch median [range]    change
  peak resident (OS)            2,269.0 [2,209.3–2,291.7]    2,085.0 [1,982.3–2,119.4]     -8.1%
  log_messages high-water             386.2 [376.6–386.2]          386.2 [376.6–386.2]     -0.0%
  log_messages at end                 386.2 [376.6–386.2]          113.8 [104.2–113.8]    -70.5%
  heatmap_raw high-water              589.7 [589.7–589.7]          589.7 [589.7–589.7]     +0.0%
  histogram high-water                794.4 [794.4–794.4]          794.4 [794.4–794.4]     +0.0%
  statistics step                        0.91 [0.91–0.92]             1.42 [1.38–1.53]    +55.9%
    group_calc                           0.44 [0.43–0.44]             0.93 [0.93–0.95]   +112.0%
  heatmap step                        10.85 [10.81–10.89]          10.17 [10.12–10.41]     -6.3%
  histogram step                      22.30 [22.24–23.01]          22.62 [22.54–22.66]     +1.4%
  read files (untouched)           102.29 [102.13–102.76]       101.83 [101.60–101.88]     -0.5%
  total                            136.85 [136.18–137.10]       135.94 [135.83–136.47]     -0.7%
```

The heatmap step is now faster than the base; the histogram step is 0.32 s
(1.4 %) slower on 7.75 million values; the total is 0.7 % faster.

**Before/after benchmarks**, three interleaved rounds each, `release/0.19.0`
at `a585f97` and the branch, both from worktrees side by side under
`.claude/worktrees/` (medians with ranges; memory in MB, time in s):

```
== single-day-access-log-standard
  MEMORY:consolidation_clusters                                   0.00 [0.00–0.00] ->      0.00 [0.00–0.00] MB    +0.0%
  MEMORY:log_analysis                                            24.79 [24.79–24.79] ->     24.79 [24.79–24.79] MB    +0.0%
  MEMORY:log_messages                                            27.48 [27.48–27.48] ->     27.47 [27.47–27.47] MB    -0.0%
  MEMORY:rss_peak                                               105.78 [105.73–105.82] ->    100.81 [100.81–101.50] MB    -4.7%
  MEMORY:unattributed                                            51.96 [51.88–52.06] ->     46.98 [46.95–47.69] MB    -9.6%
  TIMING:finalize/calculate_statistics                            0.10 [0.10–0.10] ->      0.08 [0.08–0.08] s   -18.2%
  TIMING:finalize/calculate_statistics/bucket_stats               0.07 [0.07–0.07] ->      0.05 [0.05–0.05] s   -30.0%
  TIMING:finalize/calculate_statistics/group_calc                 0.02 [0.02–0.02] ->      0.03 [0.03–0.03] s   +17.4%
  TIMING:parse/read_files                                         8.56 [8.48–8.56] ->      8.52 [8.49–8.54] s    -0.5%
  TIMING:total                                                    8.68 [8.60–8.68] ->      8.62 [8.60–8.65] s    -0.7%
== month-single-server-access-logs-top25-consolidate
  MEMORY:consolidation_clusters                                 220.98 [220.98–220.98] ->    220.98 [220.98–220.98] MB    -0.0%
  MEMORY:log_analysis                                           254.00 [254.00–254.00] ->    254.00 [254.00–254.00] MB    +0.0%
  MEMORY:log_messages                                           253.64 [253.64–253.64] ->    172.34 [172.34–172.34] MB   -32.1%
  MEMORY:rss_peak                                              1224.59 [1056.15–1240.76] ->    903.53 [903.43–905.49] MB   -26.2%
  MEMORY:unattributed                                           407.68 [239.04–429.98] ->    167.88 [167.74–169.69] MB   -58.8%
  TIMING:finalize/calculate_statistics                            5.30 [5.29–5.43] ->      3.86 [3.85–3.91] s   -27.1%
  TIMING:finalize/calculate_statistics/bucket_stats               2.84 [2.83–2.99] ->      1.70 [1.69–1.70] s   -40.2%
  TIMING:finalize/calculate_statistics/group_calc                 2.45 [2.44–2.46] ->      2.17 [2.15–2.21] s   -11.6%
  TIMING:finalize/group_similar                                   4.39 [4.38–4.42] ->      4.49 [4.45–4.51] s    +2.2%
  TIMING:parse/read_files                                       115.89 [115.88–116.15] ->    116.08 [115.33–116.89] s    +0.2%
  TIMING:total                                                  125.63 [125.59–126.00] ->    124.42 [123.75–125.28] s    -1.0%
```

Two metrics are worse by more than 1 %. group_calc on the single day,
0.02 to 0.03 s: releasing the rows not displayed. `finalize/group_similar` on
the month, 4.39 [4.38–4.42] to 4.49 [4.45–4.51] s: not the change. The only
change inside consolidation is the cluster's `delete` at the hand-over, and
the branch against a copy of itself without it, from the same worktree, two
rounds each, measured 4.38 and 4.42 s with it and 4.39 and 4.39 s without,
the base's range.

**Harness suite.** 48 of 49 harnesses pass. `validate-message-discard.sh`
failed one assertion in the gate run (`metrics :: -d durationMs switches
duration off and removes nothing from lines written durationMS=`); run alone,
its `metrics` scenario failed once and passed once on the branch and passed
twice on the base. Cause, pre-existing and in the harness: `run_messages`
writes each run into a directory named from its label, and the labels
`dur-durationMS` and `dur-durationMs` name one directory on a case-insensitive
file system, so the second run's directory holds both runs' CSVs and
`find … -print -quit` returns whichever the directory lists first. The failing
run read `…-ddurationMS.csv` from the `dur-durationMs` directory.

### 4.10 Where memory goes after statistics (stage timeline, `-mem debug`)

One run each, `a585f97` against `ef95ff4`, the month of § 4.2; process size at
the end of each stage (`MEMDIAG-FULL`), peak from `/usr/bin/time -l`. Perl keeps
freed memory for reuse, so a release shows as later stages not growing.

| Stage | `hmhg` base | `hmhg` branch | `g` base | `g` branch |
|---|---|---|---|---|
| read | 1,760 MB | 1,640 MB | 717 MB | 714 MB |
| consolidation | | | 793 | 790 |
| statistics | 1,802 | 1,684 | 1,058 | 903 |
| heatmap | 2,075 | 1,925 | | |
| histogram | 2,069 | 1,813 | | |
| normalise, bar graph, message table and CSV, summary | +0 to +9 per stage | +0 to +9 per stage | +0 | +0 |
| peak | 2,198 | 1,987 | 1,242 | 903 |

The stages after statistics that use memory are the heatmap and histogram, and
only on the raw data model (their defaults are bin counters, 2.5 MB and 0.3 MB on
this month); output uses none. Two findings on both commits: the heatmap step
grows the process by about 250 MB without a named structure holding it (not
measured inside the step), and the histogram empties its arrays but keeps their
allocated slots, 130 MB, to exit.

### 4.11 The locked default (§ 5.0) measured (`d298fd1` against `a585f97`)

Three rounds, interleaved base then branch, the month of § 4.2 with `-bs 1440
-m uuid --terminal-width 200 -V benchmark-data -mem` plus: `g` `-n 25 -g`,
`n25` `-n 25`, `sop99` `-n 25 -so p99`, `hmhg` `-n 25 -hm -hg -hmdm raw -hgdm
raw`. Peak resident size from `/usr/bin/time -l`; "% of run" is the change
against the base's median total.

```
== g
  metric                                base median [range]          branch median [range]    change  % of run
  peak resident (OS)              1,242.5 [1,213.7–1,242.6]      1,017.5 [1,017.3–1,017.6]    -18.1%          
  log_messages high-water               253.6 [253.6–253.6]            253.6 [253.6–253.6]     +0.0%          
  log_messages at end                   253.6 [253.6–253.6]            253.6 [253.6–253.6]     +0.0%          
  clusters high-water                   221.0 [221.0–221.0]            221.0 [221.0–221.0]     -0.0%          
  clusters at end                       221.0 [221.0–221.0]                  0.9 [0.9–0.9]    -99.6%          
  log_analysis high-water               254.0 [254.0–254.0]            254.0 [254.0–254.0]     -0.0%          
  heatmap_raw high-water                      0.0 [0.0–0.0]                  0.0 [0.0–0.0]     +0.0%          
  histogram high-water                        0.0 [0.0–0.0]                  0.0 [0.0–0.0]     +0.0%          
  statistics step                          5.45 [5.27–5.46]               4.66 [4.62–4.77]    -14.5%    -0.62%
    time-bucket statistics                 2.98 [2.86–3.01]               1.68 [1.67–1.79]    -43.7%    -1.03%
    displayed-row statistics               2.43 [2.40–2.47]               2.98 [2.94–2.98]    +22.6%    +0.43%
  consolidation                            4.39 [4.34–4.42]               4.37 [4.36–4.54]     -0.3%    -0.01%
  read files (untouched)             116.81 [114.91–131.40]         115.46 [114.33–115.98]     -1.2%    -1.07%
  total                              126.70 [124.54–141.28]         124.52 [123.33–125.32]     -1.7%    -1.72%
== n25
  metric                                base median [range]          branch median [range]    change  % of run
  peak resident (OS)                    800.5 [800.0–810.3]            767.8 [759.3–768.5]     -4.1%          
  log_messages high-water               376.6 [376.6–386.2]            386.2 [376.6–386.2]     +2.5%          
  log_messages at end                   376.6 [376.6–386.2]            386.2 [376.6–386.2]     +2.5%          
  clusters high-water                         0.0 [0.0–0.0]                  0.0 [0.0–0.0]     +0.0%          
  clusters at end                             0.0 [0.0–0.0]                  0.0 [0.0–0.0]     +0.0%          
  log_analysis high-water               253.3 [253.3–253.3]            253.3 [253.3–253.3]     +0.0%          
  heatmap_raw high-water                      0.0 [0.0–0.0]                  0.0 [0.0–0.0]     +0.0%          
  histogram high-water                        0.0 [0.0–0.0]                  0.0 [0.0–0.0]     +0.0%          
  statistics step                          2.69 [2.68–2.70]               2.67 [2.67–2.73]     -0.9%    -0.02%
    time-bucket statistics                 1.80 [1.79–1.81]               1.59 [1.58–1.59]    -11.8%    -0.22%
    displayed-row statistics               0.47 [0.47–0.47]               0.63 [0.63–0.72]    +34.9%    +0.17%
  read files (untouched)                95.63 [95.60–96.03]            95.47 [95.21–97.06]     -0.2%    -0.17%
  total                                 98.34 [98.32–98.76]            98.16 [97.97–99.75]     -0.2%    -0.18%
== sop99
  metric                                base median [range]          branch median [range]    change  % of run
  peak resident (OS)                    911.3 [910.4–920.8]            897.6 [887.9–897.6]     -1.5%          
  log_messages high-water               496.9 [496.9–506.4]            506.4 [496.9–506.4]     +1.9%          
  log_messages at end                   496.9 [496.9–506.4]            506.4 [496.9–506.4]     +1.9%          
  clusters high-water                         0.0 [0.0–0.0]                  0.0 [0.0–0.0]     +0.0%          
  clusters at end                             0.0 [0.0–0.0]                  0.0 [0.0–0.0]     +0.0%          
  log_analysis high-water               253.3 [253.3–253.3]            253.3 [253.3–253.3]     -0.0%          
  heatmap_raw high-water                      0.0 [0.0–0.0]                  0.0 [0.0–0.0]     +0.0%          
  histogram high-water                        0.0 [0.0–0.0]                  0.0 [0.0–0.0]     +0.0%          
  statistics step                          3.95 [3.94–4.20]               3.72 [3.71–3.81]     -5.8%    -0.23%
    time-bucket statistics                 1.78 [1.77–1.78]               1.58 [1.57–1.64]    -11.2%    -0.20%
    ranking pre-pass                       1.94 [1.93–2.11]               1.86 [1.86–1.87]     -4.1%    -0.08%
    displayed-row statistics               0.01 [0.01–0.01]               0.00 [0.00–0.00]   -100.0%    -0.01%
  read files (untouched)                94.98 [94.68–95.22]            95.44 [94.89–96.11]     +0.5%    +0.47%
  total                                 98.94 [98.65–99.44]            99.27 [98.63–99.86]     +0.3%    +0.34%
== hmhg
  metric                                base median [range]          branch median [range]    change  % of run
  peak resident (OS)              2,161.8 [2,093.6–2,263.5]      2,071.5 [2,059.4–2,086.1]     -4.2%          
  log_messages high-water               386.2 [386.2–386.2]            376.6 [376.6–386.2]     -2.5%          
  log_messages at end                   386.2 [386.2–386.2]            376.6 [376.6–386.2]     -2.5%          
  clusters high-water                         0.0 [0.0–0.0]                  0.0 [0.0–0.0]     +0.0%          
  clusters at end                             0.0 [0.0–0.0]                  0.0 [0.0–0.0]     +0.0%          
  log_analysis high-water                     0.0 [0.0–0.0]                  0.0 [0.0–0.0]     -8.9%          
  heatmap_raw high-water                589.7 [589.7–589.7]            589.7 [589.7–589.7]     +0.0%          
  histogram high-water                  794.4 [794.4–794.4]            794.4 [794.4–794.4]     +0.0%          
  statistics step                          0.93 [0.90–0.97]               0.92 [0.91–0.93]     -1.1%    -0.01%
    time-bucket statistics                 0.00 [0.00–0.00]               0.00 [0.00–0.00]     +0.0%    +0.00%
    displayed-row statistics               0.44 [0.44–0.45]               0.44 [0.44–0.44]     -0.2%    -0.00%
  heatmap step                          10.92 [10.76–11.16]            10.17 [10.17–10.24]     -6.8%    -0.54%
  histogram step                        23.79 [23.08–23.83]            23.05 [22.71–23.36]     -3.1%    -0.53%
  read files (untouched)             103.09 [102.60–103.61]         102.18 [101.79–103.33]     -0.9%    -0.66%
  total                              138.47 [138.06–139.21]         136.35 [135.62–137.90]     -1.5%    -1.53%
```

- **Memory.** Peak resident size is lower in all four. `log_messages` moves
  between two values, 376.6 and 386.2 MB (496.9 and 506.4 MB under `-so`), on
  base and branch alike: `Devel::Size` measures a hash's allocation, which
  varies with the per-process hash seed (the note above
  `named_structure_sizes`). No structure grows.
- **Rows keep their data.** A probe on a scratch copy after statistics, grouped
  run: by default the largest row's array holds its 3,751,230 values in
  121.4 MB, the base's size, so the store is neither reordered nor enlarged;
  under `-mem release`, 0 arrays remain.
- **Outputs.** Byte-identical to the base on the seven single-day cases and the
  two month cases; under `-mem release` the CSVs and the aggregate export are
  identical (the export's command line names `-mem release`). No runtime
  warnings.
- **Time.** Totals: −1.7 %, −0.2 %, +0.3 %, −1.5 %. One step is slower:
  displayed-row statistics, +22.6 % on `g` (+0.55 s, 0.43 % of the run) and
  +34.9 % on `n25` (+0.16 s). In isolation, a copy sorted in place costs less
  than the base's copy and sorted copy (1.45 s against 1.63 to 1.71 s on
  3,751,230 values, freeing included), so the cost is not the sort itself;
  shape moments are not demanded on these runs (`-V statistics-demand`).
  Attribution: § 4.12.

### 4.12 Attribution: sorting the time buckets in place slows the displayed rows' statistics

The grouped month run (`g` of § 4.11), three interleaved rounds, a scratch copy
of `d298fd1` with two switches, run from the branch's worktree; medians:

| Variant | Peak resident | Time-bucket statistics | Displayed-row statistics | Total |
|---|---|---|---|---|
| Base `a585f97` | 1,225.9 [1,180.7–1,242.5] MB | 3.01 s | 2.47 s | 125.3 s |
| Branch `d298fd1`: buckets sorted in place | 1,015.8 [1,015.5–1,017.1] MB | 1.66 s | 2.95 s | 124.6 s |
| + displayed rows sorted into a fresh copy | 1,181.3 [1,179.9–1,181.6] MB | 1.66 s | 3.30 s | 124.1 s |
| + time buckets sorted into a fresh copy | 1,016.6 [1,016.5–1,016.8] MB | 1.93 s | 2.29 s | 122.7 s |

The displayed rows' sort is not what costs: sorting their copy into a second,
freshly allocated array is slower still, and gives back the memory. The time
buckets are: sorted in place and then freed, each bucket's scalars return to
Perl's free lists in sorted order, scattered through memory, and the displayed
rows' copy, allocated next from those lists, is scattered too, so every pass
over it misses the cache. Sorting each bucket into a fresh copy (`[ sort { $a
<=> $b } @$values ]` on the array already taken out of the store) frees the
store's array in allocation order and the copy in sorted order, both laid out
contiguously: the peak is unchanged (a bucket holds about 280,000 values, a day
of the month), time-bucket statistics are 36 % faster than the base instead of
45 %, displayed-row statistics are 7 % faster than the base instead of 19 %
slower, and the total is the lowest of the four.

This contradicted D1 as first locked (time buckets sorted in place). **D1
revised by the architect on 2026-10-08**: the in-place sort of the time
buckets is proven worse by this measurement, and each bucket's array, taken out
of its store, is sorted into a freshly allocated array
(`calculate_statistics`, `durations_into_copy`). The reasoning is recorded
with the pattern in `docs/architecture-patterns.md`.

## 5. Design (one pattern for every raw store, locked by the architect, 2026-10-07)

### 5.0 Scope as locked after the release costs were measured (2026-10-07)

The measurements of § 4.8 and § 4.9 and the stage timeline of § 4.10 showed that
releasing the message rows' arrays after their last use lowers the peak only
when a raw heatmap or histogram follows statistics, and costs the time to free
them. The architect locked the scope below: by default the message rows keep
their data; the release is behind a hidden `-mem release`. This table governs
where it differs from D2 to D4 below.

| | Default | `-mem release` |
|---|---|---|
| No working copy before statistics (D1) | yes | yes |
| Time buckets taken out of the store, sorted into a fresh array (D1, revised 2026-10-08) | yes | yes |
| Heatmap and histogram raw: count first, then sort in place for percentiles (D5, D6, D9) | yes | yes |
| `total_bytes` write-back (D7) | removed | removed |
| A cluster hands its array to its row and keeps no reference (D4) | yes | yes |
| `-so` on a statistic: the ranking pre-pass sorts each row once, in place, and statistics reuse that order (D3) | yes; the store ends as on the base | yes |
| Displayed rows, ranked on an available value | statistics sort a copy; the store is neither reordered nor enlarged | taken out of the store, sorted in place, freed after statistics |
| Rows not displayed | kept, as on the base | released at the selection |
| Large rows | handed forward to #354 (raw below a crossover, bin partition above) | |

**Why the rows keep their data by default.** After statistics the message store
holds every row's data. An interactive mode that re-ranks the message table
(raised by the architect, 2026-10-07) would recompute statistics for a new top
list from it without re-reading the logs; releasing the rows would remove that.
**Why large rows are not this issue's.** #354 (`-mdm bin` heavier than `-mdm raw`
on singleton-dominated logs; on hold behind #2, the memory ceiling) carries the
fix that keeps a message raw below an occurrence crossover and promotes it to a
bin partition above it (#323 researches the promotion). A row of millions of
values then holds no raw array to copy, sort or release; a raw row holds
hundreds, and releasing it is worth tens of kilobytes.

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
| D1 | Time buckets | once, into a freshly allocated array (revised 2026-10-08) | bucket statistics, after taking the array out of the bucket | the taken-out array and the sorted one, when the bucket's statistics are done |
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
- **D9 — A pass that does not need the order runs before the sort** (locked
  by the architect on 2026-10-07, from § 4.8). The heatmap counts each value
  into its range, and the histogram takes its range and counts each value into
  its bucket, over the values in the order the read stored them; the in-place
  sort follows, for the percentiles only. The shape-moment pass of
  `calculate_statistics` stays in sorted order: its floating-point sums depend
  on the order, so moving it would change the reported moments.
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
- [ ] **AC3 — Durations are released after their last use under `-mem
  release`** (assertable, guideline 4, § 5.0): with `-mem release`, after
  statistics no message row and no cluster holds a durations array under the
  raw data model. Verified by a one-off probe on a scratch copy that counts the
  arrays left after statistics. By default the message rows keep their arrays,
  unsorted unless ranked on a statistic, and `MEMORY_FINAL log_messages` is no
  higher than the base's.
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
