# Feature: Memory Tracking Improvements

**Issue:** #45
**Branch:** `45-memory-tracking-improvements`
**Status:** Complete

## Overview

Improve memory tracking to provide accurate, low-overhead measurements with structural breakdown showing where memory is consumed.

## Implementation Summary

### Default Behavior
- RSS (Resident Set Size) high-water mark is always captured and displayed as MAXIMUM MEMORY USED in the summary table
- Measurement occurs after each major processing phase using `measure_memory_structures()`

### With `-mem` Flag
- Additionally displays structural breakdown showing memory usage by data structure
- Uses `Devel::Size` to measure individual structures
- Shows percentage breakdown relative to total measured structures

### Key Changes
1. Replaced scattered `get_memory_usage()` calls with centralized `measure_memory_structures()` function
2. High-water mark tracking ensures peak values are captured even when structures are later cleared
3. Measurement points after: `read_and_process_logs()`, `initialize_empty_time_windows()`, `calculate_all_statistics()`, `calculate_heatmap_buckets()`, `calculate_histogram_buckets()`

### Data Structures Tracked
- `%log_occurrences` - Count tallies across time buckets
- `%log_analysis` - Time bucket statistics (including durations array)
- `%log_messages` - Message groupings
- `%log_stats` - Statistical calculations
- `%log_threadpools` - Threadpool data
- `%threadpool_activity` - Threadpool activity
- `%log_userdefinedmetrics` - User-defined metrics
- `%heatmap_data` / `%heatmap_data_hl` - Heatmap bucket counts
- `%heatmap_raw` / `%heatmap_raw_hl` - Raw heatmap values (when heatmap enabled)
- `%histogram_values` - Histogram values

## Output Format

### Default (no flags)
```
  TOTAL TIME                        2.1 sec
  MAXIMUM MEMORY USED               83.0 MB
  ─────────────────────────────────────────
```

### With `-mem` flag
```
  TOTAL TIME                        2.1 sec
  MAXIMUM MEMORY USED               83.0 MB
    log_messages         (15%)      12.2 MB
    log_analysis         (10%)       8.5 MB
    log_stats            (<1%)       5.4 kB
    log_occurrences      (<1%)       2.4 kB
    unattributed         (75%)      62.3 MB
  ─────────────────────────────────────────
```

**Notes:**
- Only structures with >= 1KB are displayed (empty structures are hidden); the `unattributed` row is always shown
- Percentages are shares of MAXIMUM MEMORY USED (peak RSS), so the displayed rows plus `unattributed` reconcile to the peak (Issue #356)
- `unattributed` = peak RSS minus the sum of ALL structure high-water marks (including hidden sub-1KB ones), floored at zero; it aggregates interpreter baseline, allocator-retained transients, and allocation slack — see the Memory Diagnostic Method section for why this cannot be attributed per structure
- Each structure's high-water mark may be captured at different measurement points, which is why the subtraction is floored rather than exact

## Performance Results

### Before Implementation
**Test file: `localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt` (277MB, 1,430,678 lines)**

| Mode | Total Time | CALCULATE STATISTICS | SCALE DATA TO TERMINAL |
|------|------------|---------------------|------------------------|
| Without `-mem` | 16.5 sec | 465 msec | 655 usec |
| With `-mem` | 17.1 sec | 712 msec | 140 msec |

Overhead: ~600ms (3.6% of total runtime)

### After Implementation

| Mode | Total Time | CALCULATE STATISTICS | SCALE DATA TO TERMINAL |
|------|------------|---------------------|------------------------|
| Without `-mem` | 16.3 sec | 455 msec | 619 usec |
| With `-mem` | 16.3 sec | 457 msec | 587 usec |

Overhead: **~0ms** (within measurement noise)

**Improvement:** ~600ms overhead eliminated

## Files Modified

- `ltl` - Main implementation
  - Added `%memory_high_water_marks` global hash
  - Added `measure_memory_structures()` function
  - Updated `print_summary_table()` for structural breakdown output
  - Renamed `$track_memory` to `$show_memory`
- `build/generate-cpanfile.sh` - Devel::Size dependency auto-detected

## Progress

- [x] Benchmark current implementation
- [x] Prototype Devel::Size approach
- [x] Implementation
  - [x] Add `%memory_high_water_marks` global hash
  - [x] Add `measure_memory_structures()` function with high-water mark tracking
  - [x] Add measurement calls after key subroutines in MAIN
  - [x] Remove scattered `get_memory_usage()` calls from loops
  - [x] Add structural breakdown to summary table output
  - [x] Always display RSS, structural breakdown only with `-mem`
- [x] Testing
- [x] Documentation

## References

- [Devel::Size on CPAN](https://metacpan.org/pod/Devel::Size)

## Issue #356 Specification — Peak-RSS Coherence

**Status: Implemented** (branch `356-mem-untracked-rss-residual`).

The #356 investigation decomposed the untracked peak-RSS residual into named categories (findings comment on the issue). The dominant term — an O(`-n`) transient range-list burst in the output subs — is a behavioral defect fixed separately under #362. This specification covers the remaining remedy: making every user-facing memory surface coherent against peak RSS.

### S1. Final measurement point after the output phase

`measure_memory_structures()` is additionally called (a) at the entry to the summary-table rendering, so the displayed MAXIMUM MEMORY USED includes the normalize/bar-graph/CSV phase, and (b) after the output stages (`print_message_summary()` / `print_threadpool_summary()`, before exit), which keeps the recorded peak honest for the full process lifetime and surfaces through the `-mem debug` end-of-run line. The displayed value structurally cannot include allocations made by the output stages that print after it; with the #362 clamp in place that blind spot is the message/threadpool row rendering only (~KBs at dev scale). Before this change the last measurement preceded the entire output phase and MAXIMUM MEMORY USED under-reported the true process peak by 34% at dev scale (316 MB reported vs 478 MB actual).

### S2. `%message_key_order` joins the named-structure map

Added to `named_structure_sizes()`. It is O(total keys × key length) under large `-n` (9.0 MB at 43,820 keys) and was the only named store above 1 MB missing from the map.

### S3. The `-mem` terminal breakdown becomes a full account of MAXIMUM MEMORY USED

- Percentages become relative to `rss_peak` (previously: relative to the total of measured structures).
- A final `unattributed` row is displayed: `max(0, rss_peak − Σ per-structure HWMs)` with its percentage, so the displayed rows plus `unattributed` reconcile to MAXIMUM MEMORY USED.
- Documented semantics: Σ of high-water marks is a sum of maxima captured at different instants, so the row is a visibility surface — it aggregates interpreter baseline, allocator-retained transients, and allocation slack — not a precise gauge. `-mem debug` (S4) is the per-instant instrument.
- The `benchmark-data` `-V` section gains a `MEMORY	unattributed` row. HARNESS-DESIGN obligations apply: `benchmark-data` is owned by `features/memory-baseline-profiling.md`, whose section contract must be updated in the same commit, and the `tests/baseline/` consumers must be verified tolerant of the additive row.

### S4. `-mem debug` diagnostic mode

- Grammar: `-mem` takes an optional literal operand `debug`; bare `-mem` is unchanged. Only the literal `debug` is recognized — any other following token must remain a file argument (`ltl -mem access.log` keeps meaning `-mem` plus a file; the operand must not swallow it).
- Behavior: everything `-mem` does, plus TSV diagnostic lines on STDERR:
  - a full decomposition line (`rss`, `named_sum`, `unattributed`, top structures) at each phase boundary — startup, after read, after bucket initialization, after grouping, after statistics, after heatmap/histogram, after normalize, after each output stage, end;
  - RSS-only samples inside the hot loops: read loop every 75,000 lines; per-message-key statistics and output loops every 10,000 keys. Cadence is deliberately coarse for Windows, where each RSS read is a syscall (see the #143 history) — a debug run must not multiply that cost.
- `Devel::Size` walks happen only at phase boundaries (bounded count per run), never inside loops.
- Help/docs parity: `print_help()` and `docs/usage.md` updated in the same commit.

### S5. Single resolution surface

`named_structure_sizes()` (extracted during the investigation) is the only place the named map is defined; `measure_memory_structures()` and the `-mem debug` sampler both consume it. The `MEMORY_FINAL` emission in the benchmark block still lists structures ad hoc — converge it onto the same surface when touched.

### Non-goals

- Per-structure attribution of allocator-retained churn: impossible from an in-process structure walk; quantified as ~76 B/line (bin-vs-raw delta, consistent from 240k to 8M lines).
- The O(`-n`) slice fix — #362.

## Issue #709: unmeasured stores and a peak that misses working memory

**Status:** filed 2026-10-12, `status: backlog`; no work started. Found while
reading the third `all`-tier benchmark round of 0.19.0. Nothing here is a
locked decision.

### The architect's direction (2026-10-12)

- **The aim is a correct peak, not full attribution.** Attributing a routine's
  working memory to a named store is not a goal.
- **No measurement with an iterative cost.** Nothing is read per line, per row
  or per call of a routine that runs many times. A reading taken once per run,
  or a few times, costs nothing that matters.
- **Two aims, two expectations.** The size of each store matters only under
  `-mem`. The overall peak RSS is the one memory figure every run reports, with
  or without `-mem`. So where a routine holds a very large local variable, a
  reading inside it at the right moment is relevant to every run. No single
  condition covers both cases.
- **Where the reading goes.** A reading just before a routine returns is too
  late, because deletions usually happen at a routine's end. The high-water
  reading is taken before a deletion. A deletion made one item at a time inside
  a loop cannot be read there, so the reading goes in front of the loop.
- **Inside a loop, at most once.** One option raised: a single conditional
  reading at the moment of highest pressure. The evaluation of that condition
  runs on every pass and is not free, so it is placed with care and its
  overhead is measured with a before/after benchmark. Another option raised: a
  compiled routine that includes the condition or omits it, chosen by the
  run's parameters, noted as possibly over-complicated.
- **Prototype first.** A prototype compares the options on timing overhead,
  complexity, simplicity and readability before anything is built
  (`prototype/README.md`). The focus is the cases where a local copy is known
  to grow very large, read while it exists.

### Findings

All measured on macOS, one run per case unless stated. The step-by-step
figures come from a scratch copy of `ltl` that adds `-mem debug` decomposition
samples inside `group_similar_messages()` and `calculate_all_statistics()` and
adds every input-sized global store to the named map; the tracked `ltl` was
not changed.

**The highlighted raw histogram values are not measured.** On a one-day web
application access log carrying execution time in the duration field (148 MB,
761,698 lines), with `-V benchmark-data -mem`:

| Options | Histogram raw values | Highlighted raw values (scratch copy) | Unattributed, as shipped | Unattributed, scratch copy |
|---|---|---|---|---|
| `-hg -hgdm raw` | 68.1 MB | 0 | 76.8 MB | 77.1 MB |
| `-hg -hgdm raw -h HTTP` (every line highlighted) | 68.1 MB | 68.1 MB | 132.6 MB | 73.4 MB |
| `-hg -hgdm raw -h POST` | 68.1 MB | 59.0 MB | 123.0 MB | 69.9 MB |
| `-hg -h HTTP` (default data model) | 0 | 0 | 51.0 MB | 48.7 MB |

The highlighted copy costs about 94 bytes a value, as the unhighlighted one
does, and grows with the highlighted population, which can be the whole input.
It has been missing from the named map since at least 0.18.0.

**No other global store is a meaningful gap.** Across the eleven benchmark
scenarios on one month of one server's web application access logs (1.5 GB,
28 files, `-bs 1440`), no unmeasured global store reached 256 KB. That covers
the per-message maps that streaming consolidation keeps, plus the per-group,
per-file, index, verbose-output and telemetry stores.

**Working memory held inside a routine is the larger gap.** Same input and
scenarios. These are the steps where RSS rose while no measured store grew:

| Step | Scenarios | RSS rise outside every measured store |
|---|---|---|
| Reading the files | every scenario with a message table | +106 to +147 MB (+12 and +13 MB with `-n 0`) |
| Time-bucket statistics | every scenario without a heatmap | RSS +23 to +59 MB while the 242 MB time-bucket store is freed |
| Ranking every message row on an available value | standard, top25, histogram | +89 MB |
| | heatmap, heatmap-histogram | +145 MB |
| The walk over every row to rank on a calculated statistic | sort-p99 | +109 MB |
| | sort-skewness | +42 MB |
| Selecting the displayed rows after that walk | sort-p99 | +49 MB |
| Statistics of the displayed rows | top25-consolidate | +197 MB |
| | heatmap-histogram-consolidate | +223 MB |

The displayed rows' rise is the sorted copy of each row's durations, the
behaviour accepted under #680 (statistics over raw values copy each array;
`features/680-statistics-duration-copies.md` § 5.0). In the grouped runs the
largest displayed row is a consolidated group of 3,751,230 durations. Copying
and sorting that many integer values costs 144 MB in a standalone Perl
measurement.

**Message grouping's own working memory is measured.** The final grouping pass
raises RSS by about 80 MB. Its window index (50 MB high-water) and trigram cache
(26 MB) are named stores, measured inside each window before they are freed,
so their high-water marks already cover that rise. Its skip decision and full
key sort add about 1 MB.

**The reported peak missed the true peak by 95 MB in one scenario.** In
heatmap-histogram-consolidate, RSS read 733 MB at the end of the displayed
rows' statistics, inside the routine. After the routine returned it read
638 MB, which is the peak `-mem` would report; `time -l` reports 733 MB. In the
other ten scenarios the reported peak was within 1 MB of the operating
system's: the allocator kept the pages, so the peak was right and only its
attribution was missing. On the one-day log, with every line highlighted, the
reported peak was 252.7 MB against 276.3 MB from the operating system.

**Where measurement happens today.** Only the grouping checkpoint
(`run_consolidation_checkpoint()`) and the final pass's window
(`process_final_pass_window()`) call `measure_memory_structures()` from inside,
before freeing their working structures. Every other reading is taken in the
pipeline steps after the work routine has returned (`pipeline_parse`,
`pipeline_accumulate`, `pipeline_finalize`, `pipeline_render`). No reading
follows `group_similar_messages()`: the next is after statistics.

**Routines that free large amounts of memory while they run:**

| Routine | What it frees | Where the direction above would place the reading |
|---|---|---|
| `calculate_all_statistics()` | each time bucket's durations, one bucket at a time (the store fell from 244 MB to under 4 MB); per-bucket sessions and thread pools; each displayed row's sorted copy; its local ranking lists when each category's pass ends | in front of the bucket loop (also the missing after-grouping point); before the ranking lists go out of scope |
| `group_similar_messages()` | the streaming consolidation maps, cleared at the start of the final pass; the key-sort maps; rows absorbed into groups, deleted one at a time | before the clear; before the key-sort maps are freed; in front of the absorbing loop |

A copy allocated and freed inside a loop, such as each displayed row's sorted
durations, is neither a deletion before a loop nor one at a routine's end, so
neither placement reads it. The largest row and the largest bucket are known
before their loops start, from each one's observation count.

**"Unattributed" mixes instants.** It is peak RSS minus the sum of every named
store's high-water mark, and those marks come from different moments. The
time-bucket store (242 MB) peaks during reading and is freed during statistics,
before the run's peak, yet it is still subtracted. On the one-server month
top25-consolidate case the figure read 348, 43 and 196 MB across three
benchmark rounds of the same code; three identical runs peaked at 932, 936 and
969 MB, each equal to `time -l`.

**An RSS reading against a size walk.** A standalone Perl script copied and
sorted 3,751,230 non-integer values. Reading the process's RSS the way `ltl`
does on macOS (launching `ps`) took 8.8 ms (mean of 20); the process grew
276 MB. `Devel::Size::total_size` of the copy took 198 ms and reported 229 MB:
22 times the cost, and 47 MB short of what the copy cost the process. The Linux
reading is a file read and was not measured.

## Issue #146: Windows process memory, validated before the old dependency goes

**Status:** in progress, branch `146-windows-process-memory`.

#146 was to be the point where the Windows process-memory reading introduced
under #143 (a direct `K32GetProcessMemoryInfo` call through `Win32::API`, in
place of the WMI-based `Win32::Process::Info`) was validated before the old
module left the build.

### Contract of the surfaces touched

- **Peak memory.** "RSS (Resident Set Size) high-water mark is always captured
  and displayed as MAXIMUM MEMORY USED in the summary table" (§ Default
  Behavior above). The #709 direction restates it: "The overall peak RSS is the
  one memory figure every run reports, with or without `-mem`."
- **Windows exception.** `releases/v0.14.3.md`: "disabled by default on Windows
  until validated — opt in with `-mem`". `get_memory_usage()` returns 0 on
  Windows unless `-mem` is given.
- **Windows build dependencies.** `build/cpanfile.windows` is generated by
  `build/generate-cpanfile.sh` from the modules `ltl` loads with `use` or
  `require`, minus the Unix-only list.

### Findings

**The module already left the build, unvalidated.** Once `ltl` stopped loading
`Win32::Process::Info`, the next regeneration of `build/cpanfile.windows`
dropped it, on the day of the #143 change. Every release since, through
v0.19.0, built its Windows executable without it. Restoring the cpanfile line
alone would not restore the old reading: `ltl` no longer calls the module.

**The Windows reading takes the wrong counter.** `get_memory_usage()` reads 8
bytes at offset 24 of `PROCESS_MEMORY_COUNTERS` on 64-bit Perl. Offset 24 is
`QuotaPeakPagedPoolUsage`; `WorkingSetSize` is at offset 16 (`cb` 4 +
`PageFaultCount` 4 + `PeakWorkingSetSize` 8). The 32-bit branch reads 16 where
`WorkingSetSize` is at 12. Every field read from one Strawberry Perl 5.42 x64
process on a Windows 11 ARM64 host:

| Offset | Field | Bytes |
|---|---|---|
| 8 | PeakWorkingSetSize | 20,967,424 |
| 16 | WorkingSetSize | 20,967,424 (`tasklist`: 22,384 K) |
| 24 | QuotaPeakPagedPoolUsage (read today) | 167,528 |
| 32 | QuotaPagedPoolUsage | 167,528 |
| 56 | PagefileUsage | 13,246,464 |

On a twelve-line combined-format access log fixture, `-mem debug` printed
`rss=172496` at all nine phase boundaries and the summary read
`MAXIMUM MEMORY USED 172.2 kB`. Without `-mem` the summary reads `0 B`. The
`single-day-access-log-standard` benchmark on the same host (a one-day web
application access log carrying execution time in the duration field, 148 MB,
761,698 lines) recorded `MEMORY rss_peak 172664`.

**What the wrong counter reaches.** Windows with `-mem` only: MAXIMUM MEMORY
USED, the `unattributed` row, every breakdown percentage (its denominator), the
`format_scan_subs` row (a compile-boundary process-memory delta), `-V
benchmark-data` `MEMORY rss_peak`, the aggregate export's peak memory, the run
index's memory column, and the `-mem debug` `rss=` lines. Each named structure's
size comes from `Devel::Size` and is unaffected.

### Decisions

- **D1 (locked 2026-10-15): the offset is fixed within #146.** `WorkingSetSize`
  is read at offset 16 on 64-bit Perl and 12 on 32-bit, so the validation #146
  exists for is completed by the same change.
- **D2 (locked 2026-10-15): Windows reads process memory on every run.** The
  `-mem` gate in `get_memory_usage()` goes. v0.14.3 disabled the reading until
  it was validated; #146 is that validation, after which Windows meets the
  § Default Behavior contract as macOS and Linux do. One reading costs about
  52 µs (three runs of 1,000 calls: 52.0, 52.2, 52.5 µs).

### Scope

1. `get_memory_usage()`: the offsets (D1) and the gate (D2).
2. References to modules `ltl` no longer loads (`Win32::Process::Info`,
   `Proc::ProcessTable`): the exclusion lists in `build/generate-cpanfile.sh`,
   the comments in `ltl`, `CLAUDE.md` § Platform, `features/windows-automated-build.md`,
   `build/packaging-notes`. Historical records (`releases/`, the redundant-logic
   audit report, `prototype/memory-benchmark.pl`) stay as written.
3. The cpanfiles are generated inputs, never the source of truth (architect,
   2026-10-15). Found while regenerating them for criterion 5:
   - The committed files lacked `Scalar::Util`, which `ltl` loads, and the
     generator emitted the `integer` pragma as a CPAN requirement. `integer`
     joins the generator's pragma list; both files are regenerated (D3, locked
     2026-10-15).
   - `build/windows-setup.ps1` installed from the committed
     `build/cpanfile.windows` without generating it first, so a setup after
     `ltl` gained a module installed from a stale list. It now runs the
     generator first.
   - The generator's output depended on the caller: under Windows Perl it wrote
     CR LF once no `grep` stripped them, and launched from PowerShell its
     `sort` followed the locale (`PerlIO::via` before `POSIX`, `YAML::PP` after
     its submodules). It writes LF and sorts in byte order.

### Acceptance criteria

| # | Condition and observable outcome | Triage | Validation |
|---|---|---|---|
The target is `ltl` run by Strawberry Perl on a Windows development host; a
packaged executable carries the same interpreter and modules and is not
validated separately.

| # | Condition and observable outcome | Triage | Validation |
|---|---|---|---|
| 1 | On Windows x64 Perl, on every run, with or without `-mem`, `-V benchmark-data` `MEMORY rss_peak` on the one-day web application access log (148 MB) is not above the operating system's peak working set for that process and is within 5% below it | assertable | PowerShell launches each run and samples the process's `PeakWorkingSet64` until exit; compared with `rss_peak` |
| 2 | Under `-mem debug`, the `rss=` readings follow the run: they rise from startup on the 148 MB log rather than staying constant | assertable | `-mem debug` stderr captured on the 148 MB log |
| 3 | The 32-bit branch reads `WorkingSetSize` at offset 12 | unassertable | Strawberry Perl is x64 only; the offset is derived from the structure layout (`cb` 4 + `PageFaultCount` 4 + `PeakWorkingSetSize` 4). Recorded gap |
| 4 | macOS and Linux readings unchanged | assertable | The diff touches only the `MSWin32` branch of `get_memory_usage()` |
| 5 | Neither cpanfile names `Win32::Process::Info`, and `build/generate-cpanfile.sh` regenerates both byte-identical to the committed files | assertable | Regenerate, `git diff --exit-code build/` |
| 6 | `git grep` finds `Win32::Process::Info` and `Proc::ProcessTable` only in the historical records named in Scope and in this section | assertable | `git grep` |
| 7 | No ` at <file> line <N>` on stderr in any run above | assertable | Captured stderr grepped |

### Results

The one-day web application access log (148 MB, 761,698 lines),
`-V benchmark-data`, Strawberry Perl 5.42 x64 on a Windows 11 ARM64 host, one
run each. The operating system's peak is the process's `PeakWorkingSet64`,
sampled every 100 ms until exit.

| Code | Options | OS peak working set | `rss_peak` | `rss_peak` / OS peak |
|---|---|---|---|---|
| before | (none) | 126,742,528 | 0 | 0% |
| before | `-mem` | 128,450,560 | 184,936 | 0.14% |
| after | (none) | 128,688,128 | 125,067,264 | 97.19% |
| after | `-mem` | 128,421,888 | 125,943,808 | 98.07% |
| after | `-mem debug` | 127,750,144 | 125,272,064 | 98.06% |

Criterion 1 holds: 1.9 to 2.8% below the operating system's peak, never above.
Criterion 2 holds: the `-mem debug` phase readings were 58,949,632 at startup,
122,404,864 after reading, 125,251,584 after statistics and 125,313,024 at the
end. Criterion 7 holds: no run's stderr carries ` at <file> line <N>`.

Criterion 6 leaves one mention outside the historical records: the macOS branch
of `get_memory_usage()` explains that it launches `ps` to avoid the
`Proc::ProcessTable` crashes. That is the reason for the current design, and
criterion 4 keeps the macOS branch untouched.

## Memory Diagnostic Method (from the #356 investigation)

Recorded for future memory investigations; the temporary #356 instrumentation is not retained beyond what S4 specifies.

- **Three-level decomposition.** RSS (`get_memory_usage()`) ⊇ live Perl heap (Devel::MAT dump) ⊇ named structures (`named_structure_sizes()`). RSS − live heap = allocator-retained "dark" memory; live heap − named structures = interpreter + unnamed live data.
- **RSS is a ratchet.** Freed memory below the allocator's trim threshold never returns to the OS. Measuring structures after a phase cannot see a transient burst — only in-phase RSS sampling can localize one (this is what isolated the #362 burst to a single statement).
- **Undef probe.** At exit: measure RSS, `undef` every named structure, re-measure. The amount that does not drop is retained-freed memory (at dev scale: freeing 244 MB of structures released zero pages).
- **Devel::MAT recipe.** `cpanm --notest Devel::MAT`; call `Devel::MAT::Dumper::dump($path)` at the phase of interest; `pmat-counts $path` gives live-heap totals by SV kind. Devel::SizeMe does not build on perl 5.42.
- **Probe gotcha.** Constant ranges (`0..1999999`) are folded at compile time; a standalone probe of range-list cost must use a runtime-variable bound or it will silently measure nothing.
- **Step probes on a scratch copy.** Copy `ltl` to the scratchpad and insert
  `memory_debug_decomposition("<tag>")` at the points of interest inside a
  routine; compare each sample's RSS with its named sum, and read a rise in
  RSS with no rise in the named sum as untracked working memory. Run the
  benchmark's own `-V benchmark-data`: bare `-V` makes grouping keep member
  keys, which enlarges the clusters (211 MB against 239 MB on the one-server
  month).
- **Size-walk gotcha.** `Devel::Size::total_size` on a store holding compiled
  code (the scan-sub cache, the format registry) segfaults the process, exit
  139. Leave those stores to the compile-boundary RSS figure.
- **Churn-rate technique.** Compute the unattributed residual per line at two workload scales; a matching B/line rate attributes the residual to per-line transient allocation (76.2 B/line dev vs 77.5 B/line production for the bin-vs-raw delta).
