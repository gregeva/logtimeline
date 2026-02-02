# Feature: Memory Tracking Improvements

**Issue:** #45
**Branch:** `45-memory-tracking-improvements`
**Status:** Planning

## Overview

Improve memory tracking to provide accurate, low-overhead measurements with structural breakdown showing where memory is consumed.

## Background

The current implementation uses `Proc::ProcessTable` (Unix) and `Win32::Process::Info` (Windows) with frequent sampling during processing. Benchmark results show:

| Method | Per Call (macOS) | Notes |
|--------|------------------|-------|
| `Proc::ProcessTable` | ~10ms | Returns incorrect values on macOS |
| `ps` command | ~2ms | Correct values, 5x faster |

Both approaches are too slow for per-line or per-bucket tracking and provide only total RSS without structural insight.

## Goals

1. Low runtime overhead (single measurement point)
2. Structural breakdown showing memory usage by data structure
3. Cross-platform consistency
4. Actionable insight for optimization work

## Approach: Checkpoint + Structure Sizing

Measure RSS once at peak memory usage (after all data structures are populated), then use `Devel::Size` to measure individual structures and calculate percentage breakdown.

### Measurement Point

After `read_and_process_logs()` completes - this is when:
- `%log_occurrences` is fully populated
- `%log_analysis` has all time buckets
- `%log_messages` contains all message groupings
- `%heatmap_data` / `%histogram_values` are populated (if enabled)

### Key Data Structures to Measure

From `ltl` globals (lines 82-233):

| Structure | Purpose | Expected Impact |
|-----------|---------|-----------------|
| `%log_occurrences` | Count tallies across time buckets | High - grows with unique messages x buckets |
| `%log_analysis` | Time bucket statistics | Medium - one entry per bucket |
| `%log_messages` | Message groupings | High - stores message text |
| `%log_stats` | Statistical calculations | Low - derived data |
| `%heatmap_data` | Histogram bucket counts | Medium - when heatmap enabled |
| `%histogram_values` | Raw values for histogram | High - when histogram enabled |
| `@heatmap_boundaries` | Bucket boundaries | Low - small array |

### Special Case: group-similar

The `group-similar` feature consolidates messages, which can shift memory from `%log_messages` to grouping structures. This should be noted in output when active.

## Implementation Plan

### Phase 1: Add Devel::Size dependency

- Add to `build/generate-cpanfile.sh`
- Update build documentation

### Phase 2: Create measurement function

```perl
sub measure_memory_structures {
    return {} unless $track_memory;

    require Devel::Size;

    return {
        log_occurrences => Devel::Size::total_size(\%log_occurrences),
        log_analysis    => Devel::Size::total_size(\%log_analysis),
        log_messages    => Devel::Size::total_size(\%log_messages),
        log_stats       => Devel::Size::total_size(\%log_stats),
        heatmap_data    => Devel::Size::total_size(\%heatmap_data),
        histogram_values => Devel::Size::total_size(\%histogram_values),
        # ... other structures
    };
}
```

### Phase 3: Replace current tracking

- Remove frequent `get_memory_usage()` calls throughout code
- Add single measurement call after `read_and_process_logs()`
- Optionally keep one RSS measurement for total process memory

### Phase 4: Update output

Enhance summary table output when `-mem` flag is used. Structure breakdown appears as indented sub-items under MEMORY USED, with percentages right-aligned:

```
  TOTAL TIME                        2.1 sec
  MEMORY USED                       69.0 MB
    log_messages          (59%)     40.5 MB
    log_occurrences       (31%)     21.4 MB
    log_stats             ( 5%)      3.7 MB
    histogram_values      ( 4%)      3.1 MB
    heatmap_data          (<1%)    214.4 KB
    log_analysis          (<1%)     45.6 KB
  ─────────────────────────────────────────
```

**Requirements:**
- Only display structures that are populated (non-empty). Skip structures with zero size to keep output clean and relevant to the actual run configuration.
- Use `<1%` for percentages below 1%.
- If the summary table width needs to increase to accommodate memory breakdown, all existing content (categories, values) must be widened proportionally so that column justification works as expected.

### Phase 5: Optimize RSS measurement

- Linux: Use direct `/proc/$$/statm` access (sub-millisecond)
- macOS: Use `ps -o rss=` command (~2ms)
- Windows: Single measurement only (avoid repeated slow calls)

## Performance Benchmarking

### Before/After Comparison

Capture and store performance measurements to validate the improvement:

**Baseline (current implementation):**
- Run `prototype/memory-benchmark.pl` to establish per-call overhead
- Measure total runtime with `-mem` on test files
- Record in this document

**After implementation:**
- Re-run benchmark to measure new per-call overhead
- Measure total runtime with `-mem` on same test files
- Calculate improvement percentage

### Benchmark Results

#### Baseline (before changes)

| Platform | Method | Per Call | Test File Runtime |
|----------|--------|----------|-------------------|
| macOS | `Proc::ProcessTable` | 9.84 ms | TBD |
| macOS | `ps` command | 2.03 ms | N/A (not currently used) |
| Linux | TBD | TBD | TBD |
| Windows | TBD | TBD | TBD |

#### After Implementation

| Platform | Method | Per Call | Test File Runtime | Improvement |
|----------|--------|----------|-------------------|-------------|
| macOS | TBD | TBD | TBD | TBD |
| Linux | TBD | TBD | TBD | TBD |
| Windows | TBD | TBD | TBD | TBD |

## Testing

Use test files from `docs/test-logs.md`:
- Heatmap tests: `logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log`
- Large file: `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt`

Validation:
- Runtime with `-mem` flag enabled (before vs after)
- Accuracy of reported values vs system tools (`ps`, Activity Monitor)

## Files to Modify

- `ltl` - Main implementation
- `build/generate-cpanfile.sh` - Add Devel::Size dependency
- `CLAUDE.md` - Update architecture notes if needed

## Progress

- [x] Benchmark current implementation (`prototype/memory-benchmark.pl`)
- [ ] Prototype Devel::Size approach
- [ ] Implementation
- [ ] Testing
- [ ] Documentation

## References

- [Devel::Size on CPAN](https://metacpan.org/pod/Devel::Size)
- [Perl Memory Use - Tim Bunce](https://www.slideshare.net/Tim.Bunce/perl-memory-use-lpw2013)
- [perlmaven - How much memory does my Perl application use?](https://perlmaven.com/how-much-memory-does-the-perl-application-use)
