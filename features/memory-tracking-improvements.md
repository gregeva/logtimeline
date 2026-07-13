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
    log_messages         (59%)      12.2 MB
    log_analysis         (41%)       8.5 MB
    log_stats            (<1%)       5.4 kB
    log_occurrences      (<1%)       2.4 kB
  ─────────────────────────────────────────
```

**Notes:**
- Only structures with >= 1KB are displayed (empty structures are hidden)
- Percentages are relative to total measured structures, not RSS
- Each structure's high-water mark may be captured at different measurement points
- RSS includes Perl interpreter overhead and loaded modules not reflected in structure totals

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

The #356 investigation decomposed the untracked peak-RSS residual into named categories (findings comment on the issue). The dominant term — an O(`-n`) transient range-list burst in the output subs — is a behavioral defect fixed separately under #362. This specification covers the remaining remedy: making every user-facing memory surface coherent against peak RSS.

### S1. Final measurement point after the output phase

`measure_memory_structures()` is additionally called after the output stages (`print_message_summary()` / `print_threadpool_summary()`, before exit). Today the last call precedes the output phase, and MAXIMUM MEMORY USED under-reported the true process peak by 34% at dev scale (316 MB reported vs 478 MB actual).

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

## Memory Diagnostic Method (from the #356 investigation)

Recorded for future memory investigations; the temporary #356 instrumentation is not retained beyond what S4 specifies.

- **Three-level decomposition.** RSS (`get_memory_usage()`) ⊇ live Perl heap (Devel::MAT dump) ⊇ named structures (`named_structure_sizes()`). RSS − live heap = allocator-retained "dark" memory; live heap − named structures = interpreter + unnamed live data.
- **RSS is a ratchet.** Freed memory below the allocator's trim threshold never returns to the OS. Measuring structures after a phase cannot see a transient burst — only in-phase RSS sampling can localize one (this is what isolated the #362 burst to a single statement).
- **Undef probe.** At exit: measure RSS, `undef` every named structure, re-measure. The amount that does not drop is retained-freed memory (at dev scale: freeing 244 MB of structures released zero pages).
- **Devel::MAT recipe.** `cpanm --notest Devel::MAT`; call `Devel::MAT::Dumper::dump($path)` at the phase of interest; `pmat-counts $path` gives live-heap totals by SV kind. Devel::SizeMe does not build on perl 5.42.
- **Probe gotcha.** Constant ranges (`0..1999999`) are folded at compile time; a standalone probe of range-list cost must use a runtime-variable bound or it will silently measure nothing.
- **Churn-rate technique.** Compute the unattributed residual per line at two workload scales; a matching B/line rate attributes the residual to per-line transient allocation (76.2 B/line dev vs 77.5 B/line production for the bin-vs-raw delta).
