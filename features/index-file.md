# Feature: Index File for Progressive File Metadata Caching

## Overview

Implement a persistent index file (`ltl-index.csv`) that stores pre-computed metadata about log files and filtered selections. This enables faster subsequent analysis runs by avoiding redundant file processing and provides the foundation for intelligent heuristics in other performance features.

## Motivation

When analyzing log files, users typically work through the same files multiple times with different filters and options. Currently, each run re-reads and re-processes the entire file. An index file allows:

1. **Progressive building** - Each analysis session adds to the index, making subsequent runs faster
2. **Heuristics foundation** - Other performance features (#2, #34, #41, #44) need file metadata to make intelligent decisions about memory usage, two-pass processing, and binning algorithms
3. **User visibility** - CSV format allows users to inspect the index and understand their log files at a glance

## File Format

### Location

- **Primary**: `ltl-index.csv` in current working directory (uses relative paths)
- **Fallback**: `ltl-index.csv` in system temp directory if cwd is not writable (uses absolute paths)

When using the temp directory, a single shared index file serves all directories the user explores.

### Structure

Standard CSV format (RFC 4180) with header row. Read and written using `Text::CSV` for proper quoting and field separation.

```
entry_type,entry_date,file_path,file_size,file_mtime,line_count,match_count,first_timestamp,last_timestamp,ts_precision,duration_count,duration_min,duration_max,duration_avg,bytes_count,bytes_min,bytes_max,bytes_avg,count_count,count_min,count_max,count_avg,read_rate,memory_used,processing_time,filters
```

### Entry Types

#### File Entry (`entry_type = "file"`)

Stores whole-file metadata from a complete file read. Cache key is `file_path`.

| Column | Description |
|--------|-------------|
| entry_type | "file" |
| entry_date | ISO 8601 - when this index entry was created |
| file_path | Relative (cwd index) or absolute (temp index) |
| file_size | File size in bytes |
| file_mtime | ISO 8601 - file modification time (for staleness detection) |
| line_count | Total lines in file |
| match_count | Lines matching a parsing format (drives memory usage) |
| first_timestamp | ISO 8601 - earliest timestamp found |
| last_timestamp | ISO 8601 - latest timestamp found |
| ts_precision | Timestamp precision: "s", "ms", "us" |
| duration_count | Number of lines with duration values |
| duration_min | Minimum duration value |
| duration_max | Maximum duration value |
| duration_avg | Average duration value (for human readability) |
| bytes_count | Number of lines with bytes values |
| bytes_min | Minimum bytes value |
| bytes_max | Maximum bytes value |
| bytes_avg | Average bytes value (for human readability) |
| count_count | Number of lines with count values |
| count_min | Minimum count value |
| count_max | Maximum count value |
| count_avg | Average count value (for human readability) |
| read_rate | Lines per second during indexing |
| memory_used | `-` (not applicable for file entries) |
| processing_time | `-` (not applicable for file entries) |
| filters | `-` (not applicable for file entries) |

#### Selection Entry (`entry_type = "selection"`)

Stores run statistics for a specific combination of file and filter options. A selection entry is written for every run — including unfiltered runs (with `-` as the filters value). This captures per-run memory usage and processing time. Cache key is `file_path + filters`.

| Column | Description |
|--------|-------------|
| entry_type | "selection" |
| entry_date | ISO 8601 - when this index entry was created |
| file_path | Same as referenced file entry |
| file_size | `-` |
| file_mtime | `-` |
| line_count | `-` |
| match_count | Lines matching after filters applied |
| first_timestamp | ISO 8601 - earliest timestamp in filtered set |
| last_timestamp | ISO 8601 - latest timestamp in filtered set |
| ts_precision | `-` |
| duration_count | Filtered count |
| duration_min | Filtered min |
| duration_max | Filtered max |
| duration_avg | Filtered avg |
| bytes_count | Filtered count |
| bytes_min | Filtered min |
| bytes_max | Filtered max |
| bytes_avg | Filtered avg |
| count_count | Filtered count |
| count_min | Filtered min |
| count_max | Filtered max |
| count_avg | Filtered avg |
| read_rate | `-` |
| memory_used | Peak memory during processing (bytes) |
| processing_time | Total processing time (seconds) |
| filters | Serialized filter options, or `-` for unfiltered runs |

### Filter Serialization

Filters are serialized as sorted key=value pairs with semicolon delimiter. Values are URL-encoded to handle spaces and special characters in regex patterns.

Example:
```
-dmin=100;-et=09%3A00%3A00;-i=error%20in%20module;-st=08%3A00%3A00
```

Filter options included:
- `-i` (include pattern)
- `-e` (exclude pattern)
- `-if` (include file)
- `-ef` (exclude file)
- `-st` (start time)
- `-et` (end time)
- `-dmin`, `-dmax` (duration filters)
- `-cmin`, `-cmax` (count filters)
- `-bmin`, `-bmax` (bytes filters)

### Example Index File

```
entry_type,entry_date,file_path,file_size,file_mtime,line_count,match_count,first_timestamp,last_timestamp,ts_precision,duration_count,duration_min,duration_max,duration_avg,bytes_count,bytes_min,bytes_max,bytes_avg,count_count,count_min,count_max,count_avg,read_rate,memory_used,processing_time,filters
file,2026-02-03T10:15:00,access.log,2684354,2026-02-01T08:00:00,52000,51843,2026-02-01T00:00:01,2026-02-01T23:59:58,ms,51843,12,8934,487.00,0,-,-,-,0,-,-,-,45000,-,-,-
selection,2026-02-03T10:15:00,access.log,-,-,-,51843,2026-02-01T00:00:01,2026-02-01T23:59:58,-,51843,12,8934,487.00,0,-,-,-,0,-,-,-,-,26738688,2.100,-
selection,2026-02-03T10:16:00,access.log,-,-,-,5765,2026-02-01T08:00:03,2026-02-01T08:59:57,-,5765,45,2341,312.00,0,-,-,-,0,-,-,-,-,8470000,1.300,-dmin=40;-et=09%3A00%3A00;-st=08%3A00%3A00
```

Empty or not-applicable fields use `-` as placeholder to ensure correct column alignment when viewed with tools like `column -s, -t`.


## Cache Behavior

### Cache Lookup

1. On startup, load index file if present
2. For each input file, check for file entry with matching `file_path`
3. If found, verify `file_mtime` matches current file - if not, entry is stale
4. For current filter options, check for selection entry with matching `file_path + filters`
5. Use cached metadata to inform heuristics and skip redundant processing

### Cache Invalidation

- **File modified**: If `file_mtime` differs from current file modification time, discard file entry and all related selection entries
- **Entry expiration**: Entries older than a configurable threshold (e.g., 3 months) are removed on next index write

### Cache Updates

- After processing a file, add/update file entry
- After processing with filters, add selection entry
- Write index file atomically (write to temp, rename)

## Implementation Considerations

### Staleness Detection

Compare `file_mtime` in index with actual file modification time. If different, the file has changed and cached data is invalid.

### Contiguity Analysis

Determining if time ranges across multiple files are contiguous is deferred to runtime analysis after loading relevant file entries from the index. This informs whether `--omit-empty` should be auto-applied.

### Memory Estimation

With `match_count`, `duration_count`, `bytes_count`, and `count_count` from the index, we can estimate memory requirements before processing:
- Each matched line contributes to base data structures
- Each metric value (duration/bytes/count) contributes to statistical storage

### Two-Pass Optimization

If the index already contains `duration_min`, `duration_max`, etc., the first pass of two-pass processing can be skipped entirely - we already know the value ranges needed for binning.

## Related Issues

This feature is a prerequisite for:
- #2 - Performance: Implement maximum memory usage ceiling and default auto-detection
- #34 - Performance: Memory-optimized mode for histogram and heatmap (two-pass streaming)
- #41 - Performance: Align heatmap with histogram binning algorithms
- #44 - Performance: Source file heuristics enabling automatic application of memory and time optimizations

## Acceptance Criteria

- [ ] Index file created in cwd when writable, temp directory otherwise
- [ ] File entries capture all specified metadata columns
- [ ] Selection entries capture filtered statistics with serialized filter options
- [ ] Cache lookup correctly identifies valid/stale entries
- [ ] Old entries cleaned up based on entry_date
- [ ] Index file is standard CSV format (RFC 4180) with header row
- [ ] File entry is skipped if file modification time is unchanged since last index
- [ ] Atomic file writes prevent corruption
