# Feature Requirements: Multi-Threaded File Processing

## Branch
`1-multi-thread-file-read`

## Overview
Implement parallel file processing to improve performance when analyzing multiple log files. Each worker processes complete files independently, with results merged by the parent process after completion.

## Background / Problem Statement

### Current Performance Bottleneck
File read performance is sluggish for large files, especially on remote/cloud storage. Current benchmarks show approximately 45 seconds for 2 million lines (900MB) from a local SSD. This performance degrades significantly on network storage where logs are often analyzed in-place.

Since typical log analysis workflows involve multiple iterations to hone in on specific aspects, fast execution is critical for productive usage.

### Why File-Level Parallelism (Not Chunk-Level)
An alternative approach would be to split individual large files into chunks for parallel processing. This was considered and rejected for the following reasons:

1. **Chunk boundary alignment** - Splitting files at arbitrary byte offsets requires seek/read-ahead logic to find line boundaries, adding complexity and potential for bugs

2. **Data merge complexity** - Perl's fork model creates separate memory spaces per process. All accumulated data structures (`%log_occurrences`, `%log_analysis`, `%log_messages`, `%heatmap_data`, etc.) would need serialization, IPC transfer, and complex merge logic for nested hashes containing arrays

3. **Progress coordination overhead** - Coordinating progress reporting across chunk workers adds complexity with minimal benefit

4. **Common use case mismatch** - The typical use case involves multiple log files (rotated logs, logs from multiple servers), making file-level parallelism the natural fit

File-level parallelism avoids these complexities while addressing the common multi-file scenario directly.

## Goals

1. **Parallel file processing** - Multiple files processed simultaneously by worker processes
2. **Configurable worker count** - User-controllable via command-line option, with sensible defaults
3. **Correct result merging** - Parent process correctly combines results from all workers
4. **Cross-platform compatibility** - Works on Linux, BSD (macOS), and Windows
5. **Progress indication** - Users see progress updates approximately every second during processing
6. **Graceful degradation** - Falls back to sequential processing for single-file scenarios or on error

## Non-Goals

- Chunking individual files for parallel processing (complexity vs. benefit tradeoff)
- Shared memory threading (Perl's threading model is not suitable)
- Real-time result streaming (batch merge after completion is acceptable)

## Design

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Parent Process                           │
│  - Distributes files to workers                                 │
│  - Displays aggregated progress                                 │
│  - Merges results from all workers                              │
│  - Continues with statistics calculation and output             │
└─────────────────────────────────────────────────────────────────┘
        │                    │                    │
        ▼                    ▼                    ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│   Worker 1    │   │   Worker 2    │   │   Worker N    │
│  - Reads file │   │  - Reads file │   │  - Reads file │
│  - Parses     │   │  - Parses     │   │  - Parses     │
│  - Accumulates│   │  - Accumulates│   │  - Accumulates│
│  - Returns    │   │  - Returns    │   │  - Returns    │
│    results    │   │    results    │   │    results    │
└───────────────┘   └───────────────┘   └───────────────┘
```

### Worker Count Determination

Default behavior (in priority order):
1. If `-j N` specified, use N workers (capped at file count)
2. If single file, use sequential processing (no worker overhead)
3. Otherwise, use `min(CPU_cores, file_count, 8)` as default

The cap of 8 workers by default prevents resource exhaustion on high-core-count systems while allowing override via `-j`.

### Data Structures Requiring Merge

The following global structures are modified during file processing and must be merged:

| Structure | Type | Merge Strategy |
|-----------|------|----------------|
| `%log_occurrences` | `{bucket}{category}{occurrences}` | Sum values |
| `%log_analysis` | `{bucket}{field}` | Sum numeric, concat arrays |
| `%log_messages` | `{category}{key}{stats}` | Sum counts, merge durations arrays |
| `%log_threadpools` | `{bucket}{pool}{category}{thread}` | Sum values |
| `%threadpool_activity` | `{category}{pool}{thread}` | Sum values |
| `%heatmap_raw` | `{bucket} => [values]` | Concat arrays |
| `%heatmap_raw_hl` | `{bucket} => [values]` | Concat arrays |
| `%histogram_values` | `{metric} => [values]` | Concat arrays |
| `$total_lines_read` | scalar | Sum |
| `$total_lines_included` | scalar | Sum |
| `$output_timestamp_min` | scalar | Min |
| `$output_timestamp_max` | scalar | Max |
| `$heatmap_min` | scalar | Min |
| `$heatmap_max` | scalar | Max |
| `%in_files_matched` | `{file} => status` | Union |
| `@files_processed` | array | Concat |

### IPC Mechanism

Use `Storable` for serialization - it's core Perl (no external dependency) and handles complex nested data structures efficiently.

Options for data transfer:
1. **Temporary files** (recommended) - Each worker writes serialized results to a temp file, parent reads and merges. Simple, reliable, cross-platform.
2. **Pipes** - More complex, potential buffer size issues with large result sets.
3. **Shared memory** - Platform-specific, adds complexity.

### Progress Reporting

With parallel workers, progress reporting changes:
- Each worker tracks its own progress (lines read, current file)
- Workers periodically write progress to a shared mechanism (temp file or pipe)
- Parent aggregates and displays combined progress approximately every second
- Display format: `Processing: N files, M total lines (X lines/sec)`

Alternative simpler approach:
- Workers run silently
- Parent displays "Processing N files with M workers..."
- Detailed progress shown only in sequential mode

### Command-Line Interface

```
-j N, --jobs N     Number of parallel workers (default: auto)
                   auto = min(CPU_cores, file_count, 8)
                   Use -j 1 to force sequential processing
```

## Implementation Phases

### Phase 1: Foundation
- [ ] Add `-j` command-line option with validation
- [ ] Implement CPU core detection (cross-platform)
- [ ] Create worker count determination logic
- [ ] Add sequential fallback for single file

### Phase 2: Worker Implementation
- [ ] Extract file processing into isolatable function
- [ ] Implement worker process spawning using `Parallel::ForkManager`
- [ ] Implement result serialization with `Storable`
- [ ] Implement temp file based result return

### Phase 3: Result Merging
- [ ] Implement merge logic for each data structure
- [ ] Add merge validation/sanity checks
- [ ] Test with various file combinations

### Phase 4: Progress & Polish
- [ ] Implement progress reporting for parallel mode
- [ ] Add error handling for worker failures
- [ ] Performance benchmarking and tuning
- [ ] Documentation updates

## Dependencies

- `Parallel::ForkManager` - Already used in build scripts, may need to add to runtime deps
- `Storable` - Core Perl module, no additional dependency

## Testing Strategy

1. **Correctness tests** - Compare parallel vs. sequential results for identical inputs
2. **Performance tests** - Benchmark with varying file counts and sizes
3. **Edge cases** - Single file, more workers than files, worker failure
4. **Platform tests** - Verify on Linux, macOS, Windows

Test files:
- Quick: Multiple small files from `logs/` directory
- Large: Multiple copies of `logs/AccessLogs/localhost_access_log.2025-03-21.txt`

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Memory pressure from parallel workers | High | Limit default worker count, document memory implications |
| Result merge bugs | High | Extensive testing comparing parallel vs. sequential |
| Platform-specific fork issues (Windows) | Medium | Test on Windows, document limitations |
| Progress reporting complexity | Low | Accept simpler progress display in parallel mode |

## Success Criteria

1. Multi-file processing shows linear speedup up to worker count (accounting for I/O limits)
2. Results identical between parallel and sequential modes
3. Works correctly on Linux, macOS, and Windows
4. No regression in single-file performance

## Related Issues

- Issue #47: I/O optimizations for single-file performance (complementary)
- Issue #23: Log format registry (independent, but per-file format detection would integrate naturally with file-level parallelism)
