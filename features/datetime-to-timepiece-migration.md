# Feature: DateTime to Time::Piece Migration

**Issue:** #43
**Status:** Planning
**Branch:** TBD

## Summary

Migrate from DateTime.pm to Time::Piece for date/time parsing to achieve significant performance improvements and enable millisecond precision support.

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

Even with timestamp caching (which the code already implements), the module initialization and method call overhead is substantial.

### Current Implementation

**Location:** Lines 1543-1570 in `ltl`

```perl
# Line 55
use DateTime;

# Lines 1543-1551 (ISO format timestamps)
$timestamp = DateTime->new(
    year      => substr($timestamp_str, 0, 4),
    month     => substr($timestamp_str, 5, 2),
    day       => substr($timestamp_str, 8, 2),
    hour      => substr($timestamp_str, 11, 2),
    minute    => substr($timestamp_str, 14, 2),
    second    => substr($timestamp_str, 17, 2),
    time_zone => 'UTC',
);

# Lines 1560-1568 (Apache format timestamps)
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

**Cache exists at:** `%timestamp_cache` (line ~1540, 1552, 1569)

### DateTime Methods Used

Audit of DateTime method calls in the codebase:

| Method | Location | Purpose |
|--------|----------|---------|
| `->new()` | Lines 1543, 1560 | Create timestamp object |
| `->epoch()` | Line 1576+ | Get Unix epoch for comparisons |
| `->ymd()` | Display formatting | Format date portion |
| `->hms()` | Display formatting | Format time portion |

## Proposed Migration

### Option A: Time::Piece (Recommended)

Time::Piece is a core Perl module (no external dependencies) with strptime parsing.

```perl
use Time::Piece;

# ISO format
my $tp = Time::Piece->strptime($timestamp_str, "%Y-%m-%d %H:%M:%S");
my $epoch = $tp->epoch;

# Apache format
my $tp = Time::Piece->strptime($timestamp_str, "%d/%b/%Y:%H:%M:%S");
my $epoch = $tp->epoch;
```

**Pros:**
- Core module, no dependencies
- Fast strptime parsing
- Supports milliseconds via custom handling
- Object-oriented API similar to DateTime

**Cons:**
- strptime format strings differ from DateTime
- Timezone handling less sophisticated

### Option B: Time::Local (Lightest)

```perl
use Time::Local qw(timegm);

my $epoch = timegm($sec, $min, $hour, $day, $month - 1, $year);
```

**Pros:**
- Absolute minimum overhead
- Core module

**Cons:**
- No object API
- Must manually handle all formatting
- More code changes required

### Recommendation

Use **Time::Piece** as it provides a good balance of performance and API convenience, while enabling the millisecond support required by issue #43.

## Millisecond Support Design

### Storage

Store milliseconds separately or as fractional epoch:

```perl
# Option 1: Separate storage
$timestamp_cache{$timestamp_str} = {
    epoch => $tp->epoch,
    ms    => $milliseconds,
};

# Option 2: Fractional epoch
$timestamp_cache{$timestamp_str} = $tp->epoch + ($milliseconds / 1000);
```

### Parsing

Extract milliseconds before Time::Piece parsing:

```perl
my ($base_timestamp, $ms) = $timestamp_str =~ /^(.+)\.(\d{3})$/;
$ms //= 0;
my $tp = Time::Piece->strptime($base_timestamp, $format);
```

## Implementation Plan

1. **Create wrapper module/functions** for timestamp operations
2. **Migrate ISO format parsing** (match_type 1, 2, 5, 6, 7, 8, 10, 11)
3. **Migrate Apache format parsing** (match_type 3, 4, 9, 12)
4. **Add millisecond extraction and storage**
5. **Update display formatting** to include milliseconds
6. **Update -ts/-te options** to accept millisecond precision
7. **Update -bs option** to support sub-second buckets (e.g., 10ms)
8. **Remove DateTime dependency** from use statement and cpanfile

## Expected Performance Improvement

Based on profiling data:
- **Current:** ~7.9s spent in DateTime overhead
- **Expected:** <0.5s with Time::Piece
- **Savings:** ~7.4s (~45% of current runtime)

## Test Plan

1. Benchmark before/after migration
2. Verify timestamp parsing accuracy across all log formats
3. Test millisecond precision with synthetic test data
4. Verify -ts/-te filtering with millisecond timestamps
5. Test edge cases (midnight, year boundaries, leap seconds)

## Documentation Updates

Per issue #43 requirements:
- [ ] Update CLAUDE.md: timestamps support millisecond precision
- [ ] Remove README.md known issue about sub-second precision
- [ ] Add README.md examples for millisecond features

## Related Issues

- #47 - I/O and processing optimizations (source of profiling data)
- #1 - Multi-threaded file processing (benefits from faster timestamp parsing)
