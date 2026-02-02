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
