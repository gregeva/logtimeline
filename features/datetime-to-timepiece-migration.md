# Feature: DateTime to Time::Piece Migration

**Issue:** #43
**Status:** Investigation
**Branch:** `43-datetime-to-timepiece`

## Summary

Migrate from DateTime.pm to Time::Piece for date/time parsing to achieve significant performance improvements and enable millisecond precision support.

## Key Constraints (from Architect)

- **No timezone conversion** - all timestamps treated as-is from log files (UTC assumed)
- **Internal representation uses milliseconds** - with floating point for sub-ms precision (e.g., microseconds stored as 123.456 ms)
- **Various input timestamp formats** must be supported
- Timezone offsets in logs are truncated/ignored

---

## Investigation Findings

### Current Library Usage

**DateTime** (line 54):
- `use DateTime;` - imported but used minimally
- `DateTime->new()` - used at lines 1522-1530 (ISO format) and 1539-1547 (Apache format)
- Methods used: `->epoch()`, `->hour`, `->minute`, `->second`

**Time::Piece** (line 53):
- `use Time::Piece;` - already imported
- Used only in `calculate_start_end_filter_timestamps()` (lines 1206-1216) for parsing `-st`/`-et` options

### DateTime Usage Details

Both usages are in `read_and_process_logs()` within the main parsing loop:

**ISO Format Parsing** (lines 1518-1532) - match_types 1, 2, 5, 6, 7, 8, 10, 11:
```perl
$timestamp = DateTime->new(
    year      => substr($timestamp_str, 0, 4),
    month     => substr($timestamp_str, 5, 2),
    day       => substr($timestamp_str, 8, 2),
    hour      => substr($timestamp_str, 11, 2),
    minute    => substr($timestamp_str, 14, 2),
    second    => substr($timestamp_str, 17, 2),
    time_zone => 'UTC',
);
```

**Apache Format Parsing** (lines 1533-1549) - match_types 3, 4, 9, 12:
```perl
my ($day, $month_str, $year, $hour, $minute, $second) =
    $timestamp_str =~ m/(\d{2})\/([A-Za-z]+)\/(\d{4}):(\d{2}):(\d{2}):(\d{2})/;
my $month = $month_map{$month_str};
$timestamp = DateTime->new(
    year      => $year,
    month     => $month,
    day       => $day,
    hour      => $hour,
    minute    => $minute,
    second    => $second,
    time_zone => 'UTC',
);
```

### DateTime Object Method Usage

After creation, `$timestamp` is used as:
- `$timestamp->epoch()` - for filtering (line 1555), min/max tracking (lines 1578-1579), bucket calculation (line 1581)
- `$log_time->hour`, `$log_time->minute`, `$log_time->second` - in `calculate_start_end_filter_timestamps()` (line 1199) to calculate midnight of log date

### Timestamp Cache

- Defined at line 150: `my %timestamp_cache;`
- Stores full DateTime objects keyed by timestamp string
- Cache lookup before DateTime creation (lines 1519-1520, 1534-1535)
- Cache write after creation (lines 1531, 1548)

### Millisecond Stripping (The Core Problem)

**Critical line 1514:**
```perl
$timestamp_str =~ s/(:\d{2}:\d{2})\.\d{3}/$1/;  # remove the milliseconds if present
```

This strips milliseconds BEFORE parsing. **This is the fundamental blocker for millisecond support** - we discard the data before it can be used.

Sub-second formats found in log patterns:
- `.481` - period separator, 3 digits (most common)
- `,40` - comma separator, 2 digits (Edge C SDK, match_type 11) - represents 400ms

### Supported Timestamp Formats (match_types)

| Type | Format | Example | Parsing Branch |
|------|--------|---------|----------------|
| 1 | ThingWorx standard | `2025-02-04 12:05:57.481+0000` | ISO (substr) |
| 2 | RAC client | `[2025-02-04T12:06:22.784] [TRACE]` | ISO (substr) |
| 3 | Tomcat access w/duration | `[02/Feb/2025:00:00:11 +0000]` | Apache (regex) |
| 4 | Tomcat access w/o duration | `[02/Feb/2025:00:00:11 +0000]` | Apache (regex) |
| 5 | Connection Server JSON | `"@timestamp":"2025-02-02T21:03:06.725+00:00"` | ISO (substr) |
| 6 | Java GC log | ISO format | ISO (substr) |
| 7 | Analytics V2 adaptor/sync | ISO format | ISO (substr) |
| 8 | Analytics worker | ISO format | ISO (substr) |
| 9 | JBoss access log | Apache format | Apache (regex) |
| 10 | Connection Server standard | `2025-08-14 21:00:34.633` | ISO (substr) |
| 11 | Edge C SDK | `2025-08-09 18:27:18,40` | ISO (substr) |
| 12 | CodeBeamer access | Apache format | Apache (regex) |

### Existing Time::Piece Usage

In `calculate_start_end_filter_timestamps()` (lines 1197-1224), Time::Piece is already used for parsing user-supplied `-st`/`-et` values:

```perl
if ( $value =~ /^\d{4}-\d{1,2}-\d{1,2} \d{1,2}:\d{2}:\d{2}/ ) {
    $epoch_value = Time::Piece->strptime( $value, "%Y-%m-%d %H:%M:%S" )->epoch;
} elsif ( $value =~ /^\d{4}-\d{1,2}-\d{1,2} \d{1,2}:\d{2}/ ) {
    $epoch_value = Time::Piece->strptime( $value, "%Y-%m-%d %H:%M" )->epoch;
} # ... more formats
```

Note: There's a warning comment about timezone problems with strptime.

### Timestamp Flow Analysis

After parsing, `$timestamp` (DateTime object) flows to:

1. **Filtering** (line 1555): `$timestamp->epoch()` compared against `%filter_range_epoch`
2. **Min/max tracking** (lines 1578-1579): `$timestamp->epoch()` stored in `$output_timestamp_min`/`$output_timestamp_max`
3. **Bucket calculation** (line 1581): `int($timestamp->epoch() / $bucket_size_seconds) * $bucket_size_seconds`
4. **First-timestamp initialization** (line 1552): passed to `calculate_start_end_filter_timestamps()` which uses `->epoch()`, `->hour`, `->minute`, `->second` to calculate midnight

**Existing millisecond display code** (lines 3117, 3899-3900) already expects fractional epoch values:
```perl
$bucket_time_str .= sprintf ".%03d", ($bucket-int($bucket))*1000 if $print_milliseconds;
```

This code currently outputs `.000` because milliseconds are stripped at parse time.

### Command-Line Options (Verified)

**Time filtering:**
- `--start|-st <value>` - start time filter (not `-ts`)
- `--end|-et <value>` - end time filter (not `-te`)

**Display precision:**
- `--seconds|-s` - display seconds in timestamps
- `--milliseconds|-ms` - display milliseconds in timestamps

**Bucket size:**
- `--bucket-size|-bs <integer>` - bucket size, interpretation varies:
  - Default (no flag): value is minutes
  - With `-s`: value is seconds
  - With `-ms`: value is milliseconds

**Variable naming issue:** `$bucket_size_minutes` is misleading since the value's unit depends on flags. Should be renamed to `$time_bucket_size`.

---

## Profiling Evidence (from Issue #47 Investigation)

Performance profiling on a 277MB / 1.43M line access log revealed DateTime.pm as the single largest performance bottleneck:

| Component | Time | % of Runtime |
|-----------|------|--------------|
| DateTime.pm | 6.73s | 15.4% |
| Eval::Closure (DateTime dependency) | 1.13s | 2.6% |
| **Total DateTime overhead** | **~7.9s** | **~18%** |

### Why DateTime is Slow

DateTime.pm loads heavy dependencies:
- Specio type checking system
- Eval::Closure for runtime code generation
- Params::ValidationCompiler
- Multiple timezone handling modules

Even with timestamp caching, the module initialization and method call overhead is substantial.

---

## Time::Piece Capabilities & Limitations

### Research Findings

**Sub-second parsing:** Time::Piece's `strptime` does **not** support sub-second parsing natively. The fractional part must be extracted separately before parsing, then combined with the epoch value.

Reference: [Perl5 GitHub issue #18261](https://github.com/Perl/perl5/issues/18261)

**Available methods** (confirmed equivalent to DateTime):
- `->epoch` - seconds since Unix epoch
- `->hour` - hour (0-23)
- `->min` or `->minute` - minute (0-59)
- `->sec` or `->second` - second (0-59)

**Approach for sub-second handling:**
1. Extract fractional part (`.481`, `,40`, etc.) before parsing
2. Parse base timestamp with `Time::Piece->strptime()`
3. Combine: `$epoch + ($fractional_ms / 1000)`

---

## Migration Scope

### In Scope

1. **Remove millisecond stripping** - change line 1514 from discard to capture
2. **Replace DateTime with Time::Piece** for log timestamp parsing
3. **Store fractional epoch in cache** - numeric value instead of object
4. **Update `calculate_start_end_filter_timestamps()`**:
   - Add millisecond parsing for `-st`/`-et` options (e.g., `"12:34:56.432"`)
   - Calculate midnight using `int($epoch / 86400) * 86400` instead of object methods
5. **Handle sub-second format variations** - `.` and `,` separators, 1-6 digit precision
6. **Rename `$bucket_size_minutes`** to `$time_bucket_size`
7. **Remove DateTime dependency** - delete `use DateTime;` and update cpanfile

### Out of Scope

- Changing bucket size option syntax (current integer + flag approach works)
- Timezone conversion (per constraint: all times treated as-is)

---

## Implementation Plan

*TODO: Define phases for architect review*

---

## Documentation Updates

Per issue #43 requirements:
- [ ] Update CLAUDE.md: timestamps support millisecond precision
- [ ] Remove README.md known issue about sub-second precision
- [ ] Add README.md examples for millisecond features (`-ms` flag, `-bs` with `-ms`, `-st`/`-et` with milliseconds)

## Related Issues

- #47 - I/O and processing optimizations (source of profiling data)
- #1 - Multi-threaded file processing (benefits from faster timestamp parsing)

---

## Progress Log

- 2026-02-03: Started investigation, mapped current DateTime/Time::Piece usage
- 2026-02-03: Traced timestamp flow through codebase, identified all usages
- 2026-02-03: Verified Time::Piece API compatibility and strptime limitations
- 2026-02-03: Corrected option names (-st/-et not -ts/-te), documented bucket size behavior
- 2026-02-03: Defined migration scope
