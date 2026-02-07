# Feature: I/O and Processing Optimizations

**Issue:** #47, #48
**Status:** Partial Implementation Complete
**Branch:** `48-processing-optimizations`

## Summary

Investigation into performance optimizations for large file processing. Profiling reveals that I/O is not the bottleneck - processing overhead dominates runtime. This document captures findings and proposes optimizations.

## Benchmark Results

### Test Configuration
- **File:** `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt`
- **Size:** 277MB, 1.43M lines
- **Platform:** macOS (Apple Silicon)

### Baseline Performance

| Metric | Pure I/O | ltl Full Processing |
|--------|----------|---------------------|
| Time | 0.18s | 16.6s |
| Lines/sec | ~8M | ~86K |
| MB/sec | ~1,560 | ~16.7 |

**Key Finding:** Pure I/O is ~94x faster than full processing. I/O accounts for ~1% of runtime; processing accounts for ~99%.

### Profiler Results (Devel::NYTProf)

| Function/Operation | Exclusive Time | % of Total | Calls |
|-------------------|---------------|------------|-------|
| `read_and_process_logs` | 29.7s | 67.9% | 1 |
| DateTime.pm | 6.73s | 15.4% | - |
| `CORE:subst` (regex substitution) | 2.64s | 6.0% | 12.8M |
| `CORE:match` (regex matching) | 2.47s | 5.7% | 12.5M |
| `visualize_carets` | 1.54s | 3.5% | 1.43M |
| Math::Round | 1.10s | 2.5% | - |
| Eval::Closure (DateTime dep) | 1.13s | 2.6% | - |
| `CORE:readline` (I/O) | 407ms | 0.9% | 1.43M |

## Proposed Optimizations

### 1. Remove `visualize_carets()` Function

**Current:** Called once per line (1.43M times) to replace non-printable control characters with caret notation.

**Location:** Line 911 (definition), Line 1615 (call site)

**Cost:** 1.54s (3.5% of runtime)

**Action:** Remove function and call site. Non-printable characters in log messages are rare and the visual representation adds minimal value.

**Estimated Savings:** ~1.5s

---

### 2. Replace DateTime.pm with Time::Piece

**See Issue #43** - This optimization is tracked separately as it involves broader changes including millisecond support.

**Cost:** 6.73s (15.4% of runtime) plus 1.13s in Eval::Closure dependency

**Profiling evidence added to:** `features/datetime-to-timepiece-migration.md`

**Estimated Savings:** ~5-6s

---

### 3. Replace Math::Round with Built-in Operations

**Current:** `Math::Round::round()` is imported and called in the hot loop.

**Location:**
- Line 53: `use Math::Round;`
- Line 1670: `round(...)` - **in hot loop, called per duration value**
- Lines 2188, 2241, 2307, 2402: Statistics calculations
- Lines 2763, 3103, 4234: Display formatting

**Cost:** 1.10s (2.5% of runtime)

**Proposed Change:** Replace with Perl built-in:

```perl
# Current
use Math::Round;
$value = round($x);

# Proposed (no module needed)
$value = int($x + 0.5);
# Or for negative numbers:
$value = $x >= 0 ? int($x + 0.5) : int($x - 0.5);
# Or using sprintf:
$value = sprintf("%.0f", $x);
```

**Estimated Savings:** ~0.8s

---

### 4. Remove TEMPORARY Substitutions

**Current:** Lines 1351-1363 contain substitutions marked `# START TEMPORARY` that run for every ThingWorx log line (match_type 1), regardless of whether they match.

**Location:** Lines 1352-1362

```perl
# START TEMPORARY the following are temporary
$message =~ s/(session id: )\d+/$1\?\?/g;
$message =~ s/(\w+_)+\d{14}-/ModelFamily_CustomerPC_DateString-/g;
$message =~ s/Successfully added for import \/.+$/Successfully added for import \/ThingworxStorage\/repository\/SystemRepository\/\.\.\./g;
$message =~ s/Setting visibility permissions for (.+)$/Setting visibility permissions for \.\.\./g;
$message =~ s/Ancestors for Entity(.+)$/Ancestors for Entity \.\.\./g;
$message =~ s/input document: (.+)$/input document: \.\.\./g;
$message =~ s/Transaction was successfully ended for request (.+)$/Transaction was successfully ended for request \.\.\./g;
$message =~ s/Ending transaction for request (.+)$/Ending transaction for request \.\.\./g;
$message =~ s/(TimerEventHandler|TimerThing)\@(\S+)/$1\@/g;
$message =~ s/correspond to sent message (\S+) \]/correspond to sent message ###################### \]/g;
# END TEMPORARY
```

**Cost:** Estimated 1-2s (contributes to the 2.64s CORE:subst total)

**Action:** Remove these temporary substitutions entirely. They appear to be customer-specific message normalization that was never cleaned up.

**Estimated Savings:** ~1-2s

---

### 5. Conditionalize Metric Extraction Substitutions

**Current:** Line 1341 runs a substitution to mask bytes/duration values for every line, even when no metric was extracted.

**Location:** Lines 1338-1341

```perl
( $bytes ) = $message =~ / bytes\s*=\s*(\d+)/;
( $duration ) = $message =~ / durationM[sS]\s*=\s*(\d+)/;
$is_access_log = 1 if defined $bytes || defined $duration;
$message =~ s/ ((bytes|durationM[sS])\s*=\s*)(\d+)/ $1?/g;  # Always runs!
```

**Proposed Change:** Only run substitution when metrics were found:

```perl
( $bytes ) = $message =~ / bytes\s*=\s*(\d+)/;
( $duration ) = $message =~ / durationM[sS]\s*=\s*(\d+)/;
if (defined $bytes || defined $duration) {
    $is_access_log = 1;
    $message =~ s/ ((bytes|durationM[sS])\s*=\s*)(\d+)/ $1?/g;
}
```

**Estimated Savings:** ~0.5-1s

---

### 6. I/O Optimizations (Low Priority)

The original issue hypothesized I/O optimizations. Profiling shows these would have minimal impact on local SSD (~1% of runtime). However, they may still be valuable for:

- Network/cloud storage with high latency
- Very large files where OS read-ahead is exhausted

**Potential approaches (for future consideration):**
- Buffered I/O tuning with `:perlio` layers
- Memory-mapped file reading with `File::Map`
- `sysread` with manual line buffering

**Recommendation:** Defer I/O optimizations unless users report performance issues on network storage.

---

## Implementation Priority

| Priority | Optimization | Effort | Savings | Issue |
|----------|-------------|--------|---------|-------|
| 1 | Remove `visualize_carets()` | Low | ~1.5s | #47 |
| 2 | Remove TEMPORARY substitutions | Low | ~1-2s | #47 |
| 3 | Replace DateTime.pm | Medium | ~5-6s | #43 |
| 4 | Replace Math::Round | Low | ~0.8s | #47 |
| 5 | Conditionalize substitutions | Low | ~0.5-1s | #47 |

**Total Estimated Savings:** 9-11 seconds (~55-65% faster)

## Implementation Results (Issue #48)

### Optimizations Implemented

The following optimizations were implemented in commit `1e18a05`:

1. **Removed `visualize_carets()` function** - deleted function and call site
2. **Removed TEMPORARY substitutions block** - deleted customer-specific patterns
3. **Replaced Math::Round with built-in operations** - using `sprintf()` and `int()`
4. **Conditionalized metric extraction substitution** - only runs when metrics found

### Benchmark Results

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Average time | 16.6s | 16.1s | -3% |
| Savings | - | ~0.5s | - |

**Result:** The implemented optimizations had less real-world impact than profiler estimates suggested. The ~3% improvement falls short of the >20% target.

### Post-Implementation Profiling Analysis

Re-profiling after implementation revealed where the actual time is spent in `read_and_process_logs`:

| Time | Calls | Operation |
|------|-------|-----------|
| **6.46s** | 1.43M | ThingWorx format regex match (fails every line on access log files) |
| **2.54s** | 1.43M | `s/(\d)\d{2}/$1xx/` HTTP status bucketing |
| **1.58s** | 1.43M | Code inside `if( $is_line_match )` block |
| **1.43s** | 1.43M | `grep { $_ eq $category_bucket } @log_levels` |
| **1.36s** | 1.43M | `s/[\r\n]+$//` line ending removal |
| **1.07s** | 1.43M | `s/ HTTP\/\d\.\d$//` HTTP version removal |
| **1.01s** | 1.43M | `s/ \+\d{4}$//` timezone removal |
| **0.98s** | 1.43M | `s/\?.+$//` query string removal |
| **0.82s** | 1.43M | `/ count\s*=\s*(\d+)/` extraction |
| **0.72s** | 1.43M | `s/-HL$//` highlight suffix removal |
| **0.69s** | 1.43M | `s/(:\d{2}:\d{2})\.\d{3}/$1/` milliseconds removal |
| **0.68s** | 1.43M | DateTime epoch() filter check |

### Key Finding: Failed Regex Matches Are Expensive

The test file is an **access log** matching the pattern at line 1382, but the profiler shows the **ThingWorx pattern at line 1325 consuming 6.46s** because it attempts (and fails) that complex regex match on every single line before falling through to the correct pattern.

**This represents ~40% of the hot loop time on access log files** and is the core problem that Issue #23 (Log Format Registry) is designed to solve through format detection once per file.

### Opportunities for Further Optimization

1. **Log Format Registry (Issue #23)** - Detect format once per file, eliminating 6.46s of failed regex attempts
2. **Hash lookup for log levels** - Replace `grep { $_ eq $category_bucket } @log_levels` with hash lookup (1.43s)
3. **Regex consolidation** - Combine multiple small substitutions into compiled patterns
4. **Format-specific substitutions** - Many substitutions only apply to certain formats but run unconditionally
5. **DateTime migration (Issue #43)** - Replace DateTime.pm with Time::Piece (~5-6s)

---

## Success Criteria

- [x] Baseline benchmark documented (16.6s for 277MB file)
- [x] Profiling analysis complete
- [x] Optimizations implemented (#48)
- [x] Post-implementation profiling complete
- [ ] No regression in output accuracy (needs verification)
- [ ] Final benchmark shows >40% improvement (not achieved - requires #23 and #43)

## Test Plan

1. Run baseline benchmark (3 runs, average)
2. Apply each optimization incrementally
3. Benchmark after each change
4. Verify output matches baseline for test files
5. Test edge cases (empty files, malformed timestamps, etc.)

## Files Modified

- `ltl` - Main script (all changes)

## Related Issues

- #43 - DateTime to Time::Piece migration (captures the largest single optimization)
- #1 - Multi-threaded file processing (these optimizations benefit each worker thread)
- #23 - Log format registry (would eliminate ~6.5s of failed regex matching per file)
