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

**Status:** in progress since 2026-10-27, specification stage, recorded
directly on `release/0.20.0`. Filed 2026-10-12, found while reading the third
`all`-tier benchmark round of 0.19.0. Locked so far: D1, the reported peak is
the operating system's kept high-water mark (§ Decisions below).

### Contract of the surfaces touched (confirmed by the architect, 2026-10-27)

What the work serves: the analyst reads MAXIMUM MEMORY USED to know what a
run needed; the developer reads the `-mem` breakdown and the benchmark's
memory rows to attribute a memory change to the store that made it.

| Surface | Contract | Record |
|---|---|---|
| MAXIMUM MEMORY USED, the run summary | "RSS (Resident Set Size) high-water mark is always captured and displayed as MAXIMUM MEMORY USED in the summary table", on every run, with or without `-mem` | § Default Behavior; restated in the direction below: "the one memory figure every run reports" |
| The `-mem` breakdown | A row per named store of at least 1 KB, as a share of the peak, then an `unattributed` row: the peak less the sum of every store's high-water mark, floored at zero, so the rows reconcile to the peak | § Output Format, the notes; § Issue #356 Specification, S3 |
| `-V benchmark-data`, `MEMORY` rows | `rss_peak` whenever `-V` is active; under `-mem` a row per store's high-water mark, then `MEMORY unattributed`, a reserved name in the row namespace | `features/memory-baseline-profiling.md` DD-03 |
| `-V benchmark-data`, `MEMORY_FINAL` rows | Listed by hand in the benchmark block; to converge onto `named_structure_sizes()` when touched | § Issue #356 Specification, S5 |
| `-V memory-usage` | A `site` line per caller of the memory reading, with its count and time; a new reading site joins the list in its fixed order | § `-V memory-usage` section contract |
| The aggregate export, `max_memory_used` | The MAXIMUM MEMORY USED string, as the run summary prints it | `features/503-yaml-aggregate-export.md` D19 |
| The run index, `memory_used` | "Peak memory during processing (bytes)" on a selection entry; the index itself is removed by #710 (remove the run index) | `features/index-file.md` |
| `-mem` in `--help` and `docs/usage.md` | "Display memory consumption statistics after processing completes, including memory that cannot be attributed to any tracked structure" | `docs/usage.md`, the `-mem` row |
| `-mem release`, hidden (added from the records sweep) | "by default the message rows keep their data; the release is behind a hidden `-mem release`": each message row's durations are freed after their last use. Being `-mem`, it also turns on the structure walks | `features/680-statistics-duration-copies.md` § 5.0 |

### Records sweep (2026-10-27)

`./process/find-records.sh --issues` over `-mem`, `-mem debug`, `MAXIMUM
MEMORY USED`, `rss_peak`, `unattributed`, `memory-usage`, `benchmark-data`,
`get_memory_usage`, `measure_memory_structures`, `named_structure_sizes`,
`histogram_values_hl`, `max_memory_used` and `memory_used` listed 95 records
and 41 issues. Every matching passage was read.

**Records that bear on this work:**

| Record | What it settles or constrains |
|---|---|
| `features/680-statistics-duration-copies.md` § 5.0 | A hidden third `-mem` operand, `release`, frees each message row's durations after its last use. Like any `-mem`, it also turns on the structure walks. It is a surface of `-mem` that the contract table above does not list. § 4.8 had already measured the peak gap: "`-mem`'s own `rss_peak` samples between steps and misses the spike inside statistics (969 MB against 1,124 MB on the same base run)". |
| `features/180-named-pipeline-stages.md` | "Hard constraint: the `measure_memory_structures()` / `memory_debug_decomposition()` instrumentation checkpoints woven between steps keep their positions — their labels are observable `-mem`/debug output." Any decision that moves a reading meets this line. |
| `features/457-summary-section-at-end-of-output.md` D2 | The reading that feeds MAXIMUM MEMORY USED sits immediately before the summary render. |
| `features/616-gated-mean-derivation.md`, *The peak memory the run reports* | `$reported_max_memory_usage` is taken once, after the reading before the summary. The summary row, its memory shares and the aggregate export read it; "the index row and `-V benchmark-data` keep the lifetime peak". This is why the run index and the summary read different variables, by the architect's direction. |
| `features/memory-baseline-profiling.md` DD-03a | `benchmark-data` reads the reading counters when its block prints, during the render, so it can trail the section's totals. Its `rss_peak` is read at the same moment, before the render's last two readings. |
| `features/520-inert-sort-bytes-aggregate-demand.md` | "the structure walk raises RSS": memory there was measured from a separate `-mem` run per arm, apart from the timing. An earlier observation that `-mem` itself moves the peak. |
| `features/472-highlight-bin-counter-telemetry.md` | `-mem` reports high-water marks, not live residency. |
| `features/fuzzy-message-consolidation.md`, the decision on memory visibility | "All new data structures introduced by consolidation … are included in the `-mem` memory summary output". A rule of store coverage, kept by the consolidation stores in the map. #171 (transient consolidation structures tracked) and #346 (the message-statistics counter store missing from the map) are earlier cases of a store missing from the map. |
| `features/2-memory-ceiling-progressive-eviction.md` E3; #2 (memory ceiling, open) | The planned ceiling controller steers on RSS read during the run, and RSS exceeds `Devel::Size` by 12.6 to 40.6 % per store. It would consume whatever in-run reading this work settles. No gate either way: each can reach a clean implementation without the other. |
| `features/log-format-registry.md` D62 | `format_scan_subs` is a compile-boundary RSS delta, not a structure walk. It joins the high-water marks as a running total. |
| `features/621-generated-read-loop-body.md` | The read loop's `-mem debug` sample carries a `#@when` gate marker. The packaged runtime adds 14 to 15 MB of unattributed memory. |
| `features/614-operand-settlement.md` § 4.5 | `-mem` settles its operands (`debug`, the hidden `release`) through `settle_optional_operand()`. Any other word is a file argument. |
| `features/412-notice-surfaces.md` | `get_memory_usage()` raises the `memory-unreadable` notice once per run on Windows. |
| `docs/architecture-patterns.md` | Consumption sites of the run-scoped activation flag (`$memory_readings_active`), the `-V` telemetry sections (`emit_memory_usage_verbose`), the raw-store release table (`-mem release`) and the named pipeline stages. A new reading site or flag is recorded there. |
| `features/189-bin-counter-primitives-implementation-readiness-audit.md` B13 | Catalogues `%histogram_values_hl` as a highlight twin to migrate with its base array. It does not note its absence from the `-mem` map. |
| `features/528-record-lexical-retained-representation.md` D5; `features/561-retained-durations-as-numbers.md` | Harness assertions read the exact `MEMORY` rows of `-V benchmark-data`, `tests/validate-format-registry.sh` among them. Any row added or renamed reaches them. |
| #354 (large message rows move to the bin data model, open); #372 (paired-event correlation, open); `features/60-metric-visibility-demand-map.md` (open) | Use `-mem` as their measuring instrument. None sets a contract on it. |

**Dismissed, with the reason:**

- *They use the memory rows as evidence of their own change and set no
  contract on them:* `features/` 34, 189-histogram-bin-counter-primitives,
  213, 225, 273, 303, 305, 342 (both docs), 358, 395, 412-notice-surfaces-research,
  417, 420, the three 426 docs, 444, 445, 446, 453, 458, 459, 460, 476, 478, 524,
  525, 564, 567, 580, 605, 609, 615, 619, 620, 640, 665, 674, 747, 750,
  `bin-counter-accuracy-and-observability.md`, `duration-statistics.md`,
  `user-defined-metrics.md`, `nytprof-profiling-workflow.md`; `features/` 58,
  179 and 209 (other `benchmark-data` rows).
- *They set how the memory rows are formatted, which this work does not
  change:* `features/608-byte-unit-ladder.md`,
  `features/617-width-to-format-rule.md`, `docs/percentage-presentation.md`,
  `features/269-output-ordering-audit.md` F11 (the tie order of the breakdown,
  now broken by name).
- *They hold process or images:* `docs/process/workflow.md`,
  `docs/process/screenshots.md`, `features/598-screenshot-capture.md`,
  `docs/toolchain-guidance.md`.
- *They record the run index's `memory_used` as read by nothing:*
  `features/708-run-index-deprecation.md`.
- *Release notes,* which are history: v0.10.2, v0.10.4, v0.13.0, v0.14.3, v0.14.4,
  v0.15.0, v0.16.0, v0.17.0, v0.20.0.
- *Closed issues,* whose record is a feature doc above or whose fix shipped:
  #46, #50, #51, #131, #146, #171, #172, #180, #226, #289 (its highlight
  counter store was retired under #472), #346, #356, #358, #362, #400, #413,
  #415, #416, #417, #453, #455 (its record has no memory passage), #472, #503,
  #561, #614, #680. #729 (process, tests and build, open) mentions `-mem` in
  passing.

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

**The structure walks under `-mem` are an iterative cost (handed forward from
#146, 2026-10-15).** Each grouping checkpoint and each final-pass window calls
`measure_memory_structures()`, which under `-mem` walks every named store with
`Devel::Size`; the checkpoints multiply with the input and each walk grows with
the stores. On one server's web application access log (one day, 33 MB, and
three days, 65 MB; `-g -V benchmark-data`, Windows, three runs), `-mem` added
8% and then 17% to the run, all of it in the reading and grouping stages, and a
scratch probe put the walks there: 14 checkpoint walks of 0.77 to 0.81 s and 6
final-pass walks of 0.61 to 0.64 s at one day, 17 of 1.66 s and 6 of 2.05 s at
three days. The process-memory readings over the same runs cost 26 to 28 ms.
Measured in § Issue #146 › Drop 2. This conflicts with the direction above (no
measurement with an iterative cost) and belongs with the placement it sets.

### Premise re-measured on the release branch (2026-10-27)

The code has moved since the findings above. #146 changed the reading and
added `-V memory-usage`, so the issue's cases were run again on
`release/0.20.0` at `6290d95a`, on macOS, one run each, one after another.
Each ran from a scratch directory with the benchmark's own options
(`--disable-progress -V benchmark-data,memory-usage --terminal-width 200`, and
`-mem` where stated) under `/usr/bin/time -l` for the operating system's peak.
The benchmark's `-V benchmark-data` is used rather than bare `-V`, which makes
grouping keep member keys (§ Memory Diagnostic Method).

**The highlighted raw histogram values are still unmeasured.** On the one-day
web application access log carrying execution time in the duration field
(148 MB, 761,698 lines), with `-mem`:

| Options | `histogram_values` | `unattributed` | `rss_peak` | OS peak |
|---|---|---|---|---|
| `-hg -hgdm raw` | 71.4 MB | 83.4 MB | 209.5 MB | 209.6 MB |
| `-hg -hgdm raw -h HTTP` (every line highlighted) | 71.4 MB | 143.1 MB | 269.0 MB | 293.7 MB |
| `-hg -hgdm raw -h POST` | 71.4 MB | 132.3 MB | 258.2 MB | 278.8 MB |
| `-hg -h HTTP` (default data model) | 0 | 52.8 MB | 107.6 MB | 107.8 MB |

With every line highlighted, `unattributed` rises by 59.7 MB over the
unhighlighted run. `-mem` has no row for the highlighted copy, and
`%histogram_values_hl` is still missing from `named_structure_sizes()`.

**The reported peak falls short of the operating system's in three of the six
cases, with `-mem` and without it:**

| Input and options | With `-mem`: `rss_peak` / OS peak | Short by | Without `-mem`: `rss_peak` / OS peak | Short by |
|---|---|---|---|---|
| one-day log, `-hg -hgdm raw -h HTTP` | 269.0 / 293.7 MB | 24.7 MB | 264.4 / 291.6 MB | 27.2 MB |
| one month of one server's web application access logs (1.5 GB, 28 files), `-bs 1440 -n 25 -g -m uuid` | 860.8 / 1,019.2 MB | 158.4 MB | 852.8 / 1,011.2 MB | 158.4 MB |
| the same month, `-bs 1440 -hm -hg -g -m uuid` | 670.5 / 769.7 MB | 99.3 MB | 764.6 / 764.6 MB | 0 |

- **The structure walks do not cause the gap.** It is the same with `-mem`
  and without it on the first two cases.
- **Where the reclaim falls varies from run to run.** On the third case the
  reading after statistics caught the peak in one run and missed it by 99 MB
  in the other, as § Findings describes.
- **The `-n 25 -g -m uuid` case is new.** In the 0.19.0 rounds its three
  identical runs peaked at 932, 936 and 969 MB, each equal to `time -l`. On
  the release branch the OS peak is 1,011 to 1,019 MB, and the reported peak is
  158 MB below it in both runs.
- **Reading counts are the same with and without `-mem`.** The one-day log
  took 8 readings: 6 at phase boundaries and 2 around the scan-sub compiles.
  The month took 67 and 69: 5 and 7 at phase boundaries, 43 at grouping
  checkpoints, 15 at final-pass windows and 4 around the scan-sub compiles.
- **On macOS each reading launches `ps`.** The 58 grouping readings on the
  month took 0.46 to 0.55 s, and every reading together 0.56 to 0.64 s of a
  90 to 120 s run. The grouping readings grow in number with the input.
- **No run's stderr carries ` at <file> line <N>`.**

**Where the missed peak falls.** Each of the two cases that fell short in both
runs was run once more with `-mem debug`, and its `memory-usage / debug`
records were read:

| Case | OS peak | Highest reading | Readings on either side of the miss | Step between them |
|---|---|---|---|---|
| one-day log, `-hg -hgdm raw -h HTTP` | 293.2 MB | 268.5 MB, after statistics | 268.5 MB after statistics, 266.0 MB after the histogram | `calculate_histogram_buckets()`, with no reading inside it |
| the month, `-bs 1440 -n 25 -g -m uuid` | 1,017.4 MB | 859.0 MB, after statistics | 717.9 MB after the read (its 103 in-loop samples reach 642.7 MB), 793.5 MB after grouping, 859.0 MB after statistics | the final grouping pass or `calculate_all_statistics()` |

On the month, the final pass's window readings stayed at or below 859.0 MB.
No `-mem debug` sample falls inside either step, because the per-key samples
come every 10,000 keys and `-n 25` gives statistics 25 rows. Placing the peak
in one of the two steps needs a step probe on a scratch copy (§ Memory
Diagnostic Method).

### Store inventory (2026-10-27)

**Method.** `ltl` has 255 file-scope hashes and arrays. A scan of every
assignment, increment and push after the declarations found 185 that are
written while the tool runs; 23 of those are in `named_structure_sizes()`.
Most of the rest are option settings, registries, display tables or other
per-run constants. The 38 that could grow with lines, keys, buckets or files
were added to the map of a scratch copy (rows prefixed `x_`). The copy ran
with `-mem --terminal-width 200` under option families the eleven benchmark
scenarios do not reach:
- on the one-day log: bare `-V -n 25 -g -m uuid`;
  `-V benchmark-data -hg -hgdm raw -hm -hmdm raw -mdm raw -h HTTP`;
  `-V benchmark-data -idx`, run twice so the index is written and then read
  back; `-V benchmark-data -n 25 -g -m uuid`;
- on the month: `-V benchmark-data -bs 1440 -n 25 -g -m uuid`.

No run's stderr carries ` at <file> line <N>`.

**Unmeasured stores of 64 KB or more:**

| Store | Grows with | Filled under | High-water mark |
|---|---|---|---|
| `%histogram_values_hl` | highlighted lines | `-hg` on the raw data model with a highlight | 69.8 MB, the day with every line highlighted |
| `%consolidation_key_generation`, `%consolidation_key_checkpoint_count` | distinct message keys | `-g` | 559 KB each on the day, with or without bare `-V`; 1.28 MB each on the month |
| `@verbose_output` | the verbose sections printed | bare `-V` | 513 KB, the day grouped |
| `%format_detection_evidence`, `%format_detection_sample` | files read | every run | 195 KB and 111 KB, the month's 28 files |
| `%index_file_data` | files read | every run | 69 KB, the month's 28 files |

The other 31 candidates stayed under 64 KB in every run: the other streaming
grouping maps, the per-file and index-read stores, the per-bucket heatmap
percentiles, the histogram's buckets, boundaries and statistics with their
highlight twins, the telemetry and demand stores, the timestamp date cache,
the `-mem debug` records and the notice records. The mapped twin
`heatmap_raw_hl` reads 41.7 MB on the same highlighted run, beside
`heatmap_raw` at 41.7 MB.

Out of the scan's reach:
- *Stores holding compiled code* (`%format_scan_sub_cache`,
  `@format_registry`). A `Devel::Size` walk of these segfaults (§ Memory
  Diagnostic Method), and the `format_scan_subs` compile-boundary figure stands
  for them.
- *Stores declared after `named_structure_sizes()`.* Those are the notice and
  terminal stores, each per notice or per run.

**An observation against finding 5.** § Findings states that no unmeasured
global store reached 256 KB on the month. The two per-key grouping maps reach
1.28 MB each here. The scratch copy's store list behind that finding is not
recorded, so this is raised as a question, not a correction.

**The same case caught its peak in this run.** On the month's
`-n 25 -g -m uuid`, the scratch copy reported 1,018.1 MB against the OS's
1,018.2 MB. The unmodified `ltl` fell 158 MB short in each of its three runs.
The copy's only difference is 38 more structure walks at each reading, which
change when a reading falls against the allocator handing memory back.

### The peak each platform keeps for the process (2026-10-27)

Each operating system keeps the process's own high-water mark. Read once, it
gives the true peak up to the moment of the reading, whatever was freed
before it. For each platform:

| Platform | The kept peak | Its measure | Reached from Perl | One reading | Measured here |
|---|---|---|---|---|---|
| Linux | `VmHWM` in `/proc/self/status` | resident set size, the measure read today | a file read, as `get_memory_usage()` reads `/proc/self/statm` | not measured | no; no Linux host in this stage |
| Windows | `PeakWorkingSetSize`, offset 8 of the `PROCESS_MEMORY_COUNTERS` that `get_memory_usage()` already fills | working set, the measure read today | the same call, another offset | that call: 0.15 to 0.25 ms after the run's first (§ Issue #146, Drop 2) | the field's value is in § Issue #146 › Findings |
| macOS | `ru_maxrss` from `getrusage` | resident set size, the measure read today | not through Homebrew Perl 5.44's own functions: `syscall` is not implemented (`d_syscall='undef'`). Through `BSD::Resource`, a compiled CPAN module not in the project's dependencies: version 1.2911 builds and passes its tests against Perl 5.44, installed into a scratch library only | 1.0 to 1.2 µs | yes, below |
| macOS | `phys_footprint_peak`, printed by `footprint -p <pid>` | physical footprint, not resident set size | launching `footprint` and parsing its output, as the current reading launches `ps` | 25 to 38 ms | yes, below |
| macOS | "Physical footprint (peak)", printed by `vmmap --summary <pid>` | physical footprint | launching `vmmap` | 570 to 590 ms | in a standalone script only |

`ps` on macOS offers `%mem`, `pmem`, `rss` and `vsz`, with no peak. In a
standalone script, memory freed with `undef` stayed resident (`ps` read
481 MB after a 500 MB string was freed), so a toy process cannot show a peak
above the current reading. The `footprint` reading was therefore probed in
`ltl` itself: a scratch copy that calls `footprint -p` once, after the run's
last reading in `pipeline_render()`. It ran under `time -l` on the three cases
that had fallen short, one run each:

| Case | `time -l` maximum resident set size | `time -l` peak memory footprint | `phys_footprint_peak` at the end of the run | `rss_peak`, the phase-boundary readings | `footprint` call |
|---|---|---|---|---|---|
| one-day log, `-hg -hgdm raw -h HTTP` | 291.0 MB | 288.1 MB | 275 MiB (288.4 MB) | 263.8 MB | 25.2 ms |
| the month, `-bs 1440 -n 25 -g -m uuid` | 1,011.5 MB | 1,008.9 MB | 962 MiB (1,008.7 MB) | 1,011.4 MB | 38.3 ms |
| the month, `-bs 1440 -hm -hg -g -m uuid` | 766.3 MB | 763.7 MB | 728 MiB (763.4 MB) | 666.8 MB | 36.0 ms |

- **A single end-of-run reading gives the operating system's own footprint
  peak.** `footprint` prints mebibytes under the label `MB`. Converted, its
  peak matches `time -l`'s peak memory footprint to the mebibyte in all three
  cases.
- **The footprint peak is a different measure from the resident peak.** It
  sat 0.3 to 1.0 % below the resident peak in these runs.
- **The month `-n 25 -g -m uuid` case caught its peak in this run.** It read
  1,011.4 MB against 1,011.5 MB, where the unmodified `ltl` fell 158 MB short
  in each of three runs. The copy differs only after the last reading. So
  whether a phase-boundary reading lands before the memory is handed back
  varies between identical runs.

The resident peak was probed the same way: a scratch copy that, at the same
point, reads `getrusage` through `BSD::Resource` and times 1,000 calls, with
the module loaded from the scratch library. One run each:

| Case | `time -l` maximum resident set size | `ru_maxrss` at the end of the run | `rss_peak`, the phase-boundary readings | `getrusage` call |
|---|---|---|---|---|
| one-day log, `-hg -hgdm raw -h HTTP` | 291,160,064 bytes | 291,160,064 bytes | 263.9 MB | 1.16 µs |
| the month, `-bs 1440 -hm -hg -g -m uuid` | 762,920,960 bytes | 762,920,960 bytes | 762.7 MB | 1.01 µs |

- **`ru_maxrss` read once at the end equals the operating system's resident
  peak to the byte** in both cases, including the one-day case, where the
  phase-boundary readings fell 27.2 MB short.
- **The month case caught its peak in this run** (762.7 against 762.9 MB),
  where it fell 99 MB short in one of the two premise runs.
- **Neither run's stderr carries ` at <file> line <N>`.**

### Decisions

- **D1 (locked 2026-10-27): the reported peak is the high-water mark the
  operating system keeps for the process.** It is read wherever a peak is
  reported (`-V benchmark-data`'s `rss_peak`, MAXIMUM MEMORY USED and the
  aggregate export, the end of the run), in place of the highest of the
  readings taken between steps. It is the only way to the done-when's "true
  peak at no iterative cost" by construction: a peak freed inside a step,
  such as the one inside `calculate_histogram_buckets()` on the one-day log,
  is caught whatever the allocator does before the next reading, and so is the
  month `-n 25 -g -m uuid` case, which fell 158 MB short in three runs and
  caught its peak in two. The alternative, readings placed before deletions
  and in front of loops with one conditional reading inside a loop, cannot be
  shown to catch every peak and adds a test to every pass of each loop it
  instruments; its remaining value would be attribution, which the issue sets
  as a non-goal. Linux reads `VmHWM` and Windows `PeakWorkingSetSize`, the
  same measure as today's reading; how macOS reads it is decided separately.
  The `-mem` rows still come from the readings between steps.

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
- **D3 (locked 2026-10-15): the cpanfile drift is fixed within #146.** See
  Scope 3.
- **D4 (locked 2026-10-15): memory readings are observable in a new
  `-V memory-usage` section.** Every call of `get_memory_usage()` is counted
  and timed per caller, and `benchmark-data` repeats the totals (one source,
  two surfaces, `tests/HARNESS-DESIGN.md`). The context: v0.14.3 took the
  Windows reading out of default runs because the WMI call it then used was so
  slow it degraded the whole run; the count and cost of the replacement are
  measured through a very large run before the gate.
- **D5 (locked 2026-10-15): the `-mem debug` output moves into the
  `memory-usage / debug` sub-section.** Its diagnostic lines no longer go to
  stderr.
- **D6 (locked 2026-10-15): `-mem debug` stays the switch and requests the
  section.** `ltl -mem debug <file>` prints `memory-usage` with its `debug`
  sub-section at the end of the run without `-V` being named. Plain `-V` and
  `-V memory-usage` carry the reading counts only, so the structure walks at
  each phase boundary run only when `-mem debug` asks for them. The lines no
  longer stream while the run goes; they arrive together at its end.

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
4. The `-V memory-usage` section and its `debug` sub-section (D4 to D6), their
   consumers and records: `get_memory_usage()` and its callers, the `-mem debug`
   emitters, `print_help()` and `docs/usage.md` for `-mem`,
   `tests/HARNESS-DESIGN.md` § Reserved section names, the `benchmark-data`
   contract (`features/memory-baseline-profiling.md`), the comparison's
   within-parent rule in `tests/baseline/compare-results.sh`, the `memory-debug`
   option set of `tests/validate-read-path.sh`, and a new
   `tests/validate-memory-usage.sh`.

### `-V memory-usage` section contract

Printed once, after the run's last reading (`pipeline_render()` returns), when
`-V` selects the section or `-mem debug` is given (D6). A count is of calls of
the system interface: a reading the platform branch skips before calling it is
not counted.

Built on the established patterns (`docs/architecture-patterns.md`), each
consumption site recorded there in the same commit:

- **`-V` telemetry sections as the test surface.** `memory-usage` is registered
  in `%verbose_section_registry` and `@verbose_section_order`, emitted by
  `emit_memory_usage_verbose()` gated on `section_requested('memory-usage')`,
  in the content shape. Like `section-layout` and `aggregate-export` it prints
  at its own site, after the run's last reading, rather than through
  `print_verbose_output()`, which flushes before the render's readings.
- **Run-scoped activation flags resolved once.** Whether readings are counted
  is one flag settled with the options (the section requested, which `-mem
  debug` does); each reading tests that flag and nothing else. With the flag
  off, no counting or timing code runs.
- **Hot-loop discipline.** No counting code is in the per-line loop: readings
  happen at phase boundaries, grouping checkpoints and windows, compiles and
  the debug samples. The read loop's debug sample keeps its existing
  `#@when $show_memory_debug` gate marker, so a generated read body without
  `-mem debug` carries none of it.

```
=== memory-usage ===
readings: <N>
readings_us: <N>
site: <name> readings=<N> elapsed_us=<N>
...
=== memory-usage / debug ===
kind	elapsed_s	tag	rss	named_sum	unattributed	structure	bytes
...
=== END memory-usage / debug ===
=== END memory-usage ===
```

- `readings` and `readings_us`: every call of `get_memory_usage()` in the run and
  the wall time spent inside them, in whole microseconds. They equal the sums of
  the `site` lines.
- `site` lines, one per caller that read at least once, in this order:
  `phase_boundary` (the pipeline steps' `measure_memory_structures()`),
  `grouping_checkpoint` (`run_consolidation_checkpoint()`),
  `grouping_final_pass` (`process_final_pass_window()`),
  `format_scan_compile` (`compile_format_scan_sub()`), `csv_block_compile`
  (`compile_csv_block()`), `debug_decomposition`, `debug_sample`.
- The `debug` sub-section is present only under `-mem debug`: one record per
  diagnostic reading in the order taken, eight columns. `kind` is
  `decomposition` (a phase boundary: `rss`, `named_sum`, `unattributed`),
  `sample` (inside a loop: `rss` only), or `structure` (each structure of
  1 MiB or more at the decomposition before it: `structure` and `bytes`); a
  column a kind does not carry is `-`. `elapsed_s` is seconds since the first
  diagnostic reading, three decimals; `rss`, `named_sum`, `unattributed` and
  `bytes` are bytes. The `structure` records carry what `-mem debug` printed
  as its third line form; the contract first agreed omitted them.
- When the section is armed, `benchmark-data` repeats the totals as `COUNTS memory_readings` and
  `TIMING memory/readings` (seconds), read from the same counters at the moment
  `benchmark-data` prints, during the render, as its `MEMORY rss_peak` is. They
  can therefore be lower than the section's totals by the readings taken after
  that point. `memory/readings` is time spent within the stages, so the
  comparison marks it within parent and leaves it out of the stage sum.

### Acceptance criteria

The target is `ltl` run by Strawberry Perl on a Windows development host; a
packaged executable carries the same interpreter and modules and is not
validated separately.

| # | Condition and observable outcome | Triage | Validation |
|---|---|---|---|
| 1 | On Windows x64 Perl, on every run, with or without `-mem`, `-V benchmark-data` `MEMORY rss_peak` on the one-day web application access log (148 MB) is not above the operating system's peak working set for that process and is within 5% below it | assertable | PowerShell launches each run and samples the process's `PeakWorkingSet64` until exit; compared with `rss_peak` |
| 2 | Under `-mem debug`, the `rss` readings follow the run: they rise from startup on the 148 MB log rather than staying constant | assertable | Held on stderr before D5 (Results); after it, the `memory-usage / debug` records on the same log |
| 3 | The 32-bit branch reads `WorkingSetSize` at offset 12 | unassertable | Strawberry Perl is x64 only; the offset is derived from the structure layout (`cb` 4 + `PageFaultCount` 4 + `PeakWorkingSetSize` 4). Recorded gap |
| 4 | macOS and Linux readings unchanged | assertable | The diff changes no line of the `darwin` or `linux` branch of `get_memory_usage()`; the counting (D4) wraps the branches and changes no value they return |
| 5 | Neither cpanfile names `Win32::Process::Info`, and `build/generate-cpanfile.sh` regenerates both byte-identical to the committed files | assertable | Regenerate, `git diff --exit-code build/` |
| 6 | `git grep` finds `Win32::Process::Info` and `Proc::ProcessTable` only in the historical records named in Scope and in this section | assertable | `git grep` |
| 7 | No ` at <file> line <N>` on stderr in any run above | assertable | Captured stderr grepped |
| 8 | Every call of `get_memory_usage()` is counted under its caller, and `readings` / `readings_us` equal the sums of the `site` lines | assertable | `tests/validate-memory-usage.sh`, one scenario per site on the smallest fixture that reaches it: phase boundaries on any run, grouping checkpoint and final pass under `-g`, format-scan compile under `-V benchmark-data`, CSV block compile on a CSV input, both debug kinds under `-mem debug` |
| 9 | Without `-mem debug` there is no `debug` sub-section, no structure walk at a phase boundary, and no `debug_*` site | assertable | Same harness, a plain `-V memory-usage` run |
| 10 | `ltl -mem debug <file>`, with no `-V`, prints `memory-usage` with its `debug` sub-section after the run's output, and nothing of it on stderr | assertable | Same harness; stderr captured separately |
| 11 | The `debug` sub-section holds one `decomposition` record per phase boundary the run reached, from `startup` to `end`, and a `sample` record every 75,000 lines read | assertable | Same harness, on a fixture or log with more than 75,000 lines for the sample |
| 12 | `benchmark-data` carries `COUNTS memory_readings` and `TIMING memory/readings`, not above the section's totals; the comparison reports `memory/readings` within parent | assertable | Same harness; `compare-results.sh summary` on two captures |
| 13 | The read-path comparison still holds under `-mem debug`: the generated read body and the standard loop give the same output | assertable | `tests/validate-read-path.sh --scenario` for its `-mem debug` option set, its consumer updated to the sub-section |
| 14 | `--help` and `docs/usage.md` describe `-mem debug` as printing the `memory-usage` section at the end of the run | assertable | `tests/validate-help-content.sh` |
| 15 | The new section meets the content shape | assertable | `tests/validate-verbose-content-shape.sh` |
| 16 | The cost of the readings is measured and recorded, before and after the fix: the number of readings and the time spent in them per caller, the total time spent reading memory, and that total against the run's total time | assertable (a measurement, recorded under Results) | One server of the thirty-day, five-server access-log folder, the common-plus-duration shape, ramped 1, 3, 7 and 15 days (2026-01-02 onward; 33 MB, 65 MB, 327 MB, 852 MB), `-g -V benchmark-data`. Six variants: before and after the fix, each without `-mem`, with `-mem`, and with `-mem -V memory-usage`. Three runs per point, medians with ranges |
| 17 | The counters cost nothing unless the section is selected (the activation-flag and hot-loop patterns above): no counting or timing code runs, and the generated read body carries none of it | assertable | Code review of the flag, `-V read-path` gate-marker lines on a run without the section, and criterion 16's variants without the section |

### Delivery plan

Each drop is committed and pushed on the issue branch before the next starts.

1. **Observability on the code before the fix.** The fix's two `ltl` changes
   (the offset, D1, and the gate, D2) are backed out, so the section first
   measures the reading as it shipped. Then the `-V memory-usage` section, its
   `debug` sub-section, the `benchmark-data` rows, the comparison's
   within-parent rule, the harness and its consumers (criteria 8 to 15, 17).
   The counters run only when the section is selected; a reading the Windows
   gate skips is not a call of the system interface and is not counted.
2. **Before benchmarks.** Criterion 16's three `before` variants at each ramp
   point, starting at one day and stepping up only once the previous point
   reads sensibly.
3. **The fix.** D1 and D2 re-applied.
4. **After benchmarks.** The three `after` variants at the same points.
5. **Analysis.** The findings report under Results; then the completion gate.

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

### Drop 2: before the fix, 1 and 3 days (criterion 16)

One server of the thirty-day, five-server access-log folder, the
common-plus-duration shape, from 2026-01-02: 1 day (33 MB, 168,981 lines) and
3 days (65 MB), `-ni -g -V benchmark-data`, Strawberry Perl 5.42 x64 on a
Windows 11 ARM64 host, main checkout, the code of drop 1 (offset and gate as
shipped). Three runs per variant, interleaved; medians with ranges. The ramp
stopped at 3 days on the architect's direction once a gap between variants
appeared; the 7-day runs were stopped before they finished.

| Stage | 1 day, no `-mem` | 1 day, `-mem` | Δ | 3 days, no `-mem` | 3 days, `-mem` | Δ |
|---|---|---|---|---|---|---|
| `parse/read_files` | 10.31 s [10.05–11.27] | 10.95 s [10.94–11.07] | +0.64 s | 18.06 s [17.89–18.10] | 19.63 s [19.33–19.99] | +1.57 s |
| `finalize/group_similar` | 3.55 s [3.48–3.60] | 4.14 s [3.96–4.23] | +0.59 s | 5.51 s [5.37–5.60] | 7.63 s [7.48–8.00] | +2.12 s |
| every other stage | ~0.5 s | ~0.5 s | ≈ 0 | ~0.8 s | ~0.8 s | ≈ 0 |
| total | 14.14 s [13.79–15.14] | 15.33 s [15.15–15.54] | +1.19 s (+8%) | 23.99 s [23.95–24.31] | 28.03 s [27.47–28.24] | +4.04 s (+17%) |

With `-mem -V memory-usage` the totals were 15.26 s [15.18–16.56] and 27.36 s
[25.34–27.87], within the `-mem` ranges: the counting costs nothing measurable.

The readings themselves: 27 at 1 day (5 phase boundaries, 14 grouping
checkpoints, 6 final-pass windows, 2 around the scan-sub compile), 26.3 to
27.6 ms in all; 30 at 3 days (17 checkpoints), 27.7 to 28.0 ms. The first
reading of a run costs about 22 ms, loading `Win32::API` and binding the
kernel32 calls; every later one 0.15 to 0.25 ms.

**The `-mem` gap is the structure walks, not the reading.** A scratch copy of
`ltl` timing the `named_structure_sizes()` walk inside
`measure_memory_structures()` per caller (`-g -mem -V benchmark-data`; tracked
`ltl` unchanged):

| Caller | 1 day (3 runs) | 3 days (1 run) |
|---|---|---|
| grouping checkpoints, inside `parse/read_files` | 14 walks, 0.77–0.81 s | 17 walks, 1.66 s |
| final-pass windows, inside `finalize/group_similar` | 6 walks, 0.61–0.64 s | 6 walks, 2.05 s |
| phase boundaries, between the stages | 5 walks, 0.49–0.52 s | 5 walks, 1.56 s |

The checkpoint walks match the reading stage's gap and the final-pass walks the
grouping stage's, at both sizes. Each walk grows with the stores it measures:
about 56 ms a checkpoint walk at 1 day and 98 ms at 3 days, 103 ms and 342 ms a
final-pass walk. The walks run under `-mem` on every platform, whatever the
reading costs; on this host the reading is 0.5 to 2% of the `-mem` overhead.
Handed forward to #709 (§ Issue #709, *The structure walks under `-mem` are an
iterative cost*).

### Drops 4 and 5: after the fix, and the analysis (criterion 16)

The same runs on the code of drop 3 (the offset fixed, the gate removed): same
host, checkout, files and options, three runs per variant, interleaved.
Medians with ranges.

| Size | Variant | Before: total | After: total | Before: `rss_peak` | After: `rss_peak` | Readings (time in them) |
|---|---|---|---|---|---|---|
| 1 day | no `-mem` | 14.14 s [13.79–15.14] | 13.46 s [13.43–13.80] | 0 | 183.0 MB [181.7–184.3] | before none; after the same 27 as below |
| 1 day | `-mem` | 15.33 s [15.15–15.54] | 14.32 s [14.21–15.19] | 0.2 MB | 184.4 MB [182.4–185.2] | |
| 1 day | `-mem -V memory-usage` | 15.26 s [15.18–16.56] | 15.35 s [14.44–15.38] | 0.2 MB | 182.9 MB [181.7–185.2] | 27 (before 27.6 ms [26.3–27.6], after 28.2 ms [28.2–30.6]) |
| 3 days | no `-mem` | 23.99 s [23.95–24.31] | 23.42 s [22.97–23.65] | 0 | 281.6 MB [280.8–288.0] | before none; after the same 30 as below |
| 3 days | `-mem` | 28.03 s [27.47–28.24] | 27.12 s [26.77–27.13] | 0.2 MB | 287.8 MB [287.6–288.2] | |
| 3 days | `-mem -V memory-usage` | 27.36 s [25.34–27.87] | 28.18 s [27.02–29.71] | 0.2 MB | 286.4 MB [282.2–288.5] | 30 (before 28.0 ms [27.7–28.0], after 30.2 ms [27.6–30.3]) |

- **Correct.** Before the fix a run reported 0 without `-mem` and 0.2 MB (the
  paged-pool quota) with it. After, it reports 183 MB at one day and 282 to
  288 MB at three days, with and without `-mem`. On the one-day file the
  reported peak was 99.9% of the operating system's peak working set without
  `-mem` and 98.8% under `-mem debug` (drop 3's runs).
- **The reading costs 28 to 30 ms a run.** The readings are the same calls with
  and without `-mem` (the phase boundaries, the grouping checkpoints and
  windows, and the compile pair `-V benchmark-data` arms): 27 at one day, 30 at
  three. About 22 to 25 ms of it is the first reading, which loads `Win32::API`
  and binds the kernel32 calls; each later reading costs 0.15 to 0.25 ms. Over a
  run that is 0.2% at one day and 0.1% at three, below the spread of three runs
  of any variant (0.4 s and more). Removing the gate (D2) adds that to every
  Windows run; the totals without `-mem` measured 13.46 s against 14.14 s and
  23.42 s against 23.99 s, the difference inside the noise.
- **The counting costs nothing measurable.** `-mem -V memory-usage` against
  `-mem` overlaps at both sizes, before and after.
- **What `-mem` costs is the structure walks** (Drop 2), unchanged by the fix:
  0.86 s at one day and 3.70 s at three after the fix, against 1.19 s and
  4.04 s before.
- **Ceiling of the alternative.** The WMI reading #143 replaced took 15 to 20 s a
  call (#143's change record); at 27 to 30 readings a run that would be 7 to 10
  minutes, which is the degradation v0.14.3 avoided by turning the reading off.
  The reading in place now costs four orders of magnitude less, so the reason
  for the Windows exception no longer holds.

### Completion gate

- **Benchmark,** `single-day-access-log-standard`, one run each, on this
  Windows 11 ARM64 host, main checkout: before on the base (7746f41), after on
  the version-restored commit (16133b5). Total 27.6 s before, 24.7 s after,
  inside the spread of repeated runs measured above. `rss_peak` 168.6 KB
  before, 117.7 MB after: the fix itself, a peak that was not being read.
- **Full harness suite: skipped, by the architect's decision.** It ran once on
  this Windows host (91cf248): 32 of 52 harnesses passed. Each of the 20
  failures came from the host, not from this change: Perl writing CR LF, Git
  Bash rewriting arguments that start with `/` into Windows paths, the system
  code page altering non-ASCII text on command lines, `ltl`'s Windows bar
  character against references captured on macOS, and `chmod` not making a
  directory unreadable. The harnesses do not run on Windows
  (`docs/toolchain-guidance.md` § Windows development host), and the gate was
  not re-run on macOS. The commit after the run (23cd2e2) changes only
  `docs/toolchain-guidance.md`.
- **Full harness suite, run after the merge on macOS** (2026-10-16, on
  `release/0.20.0` at 891fe91, the merge and its release-notes commits): 50 of
  52 harnesses passed. `tests/validate-memory-usage.sh`, created on the Windows
  host, had been committed as mode 100644, so it and
  `tests/validate-scenario-selector.sh`, which runs every harness, exited 126
  ("Permission denied"). The bit was set by PR #743 (dbc5bcc, merged as
  f4f1e8d), which also records the trap in `docs/toolchain-guidance.md`
  § Windows development host. On that commit both pass: 23 and 39 assertions,
  none failed.

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
