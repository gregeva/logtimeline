# Feature: Align Heatmap with Histogram Binning

## Overview

Align the heatmap and histogram features to use a shared binning algorithm (HdrHistogram-inspired buckets-per-decade) and shared data structures. This improves statistical consistency between features and reduces memory usage when both are enabled.

## GitHub Issue

[#41](https://github.com/gregeva/logtimeline/issues/41)

## Background

### Current State

Both heatmap and histogram use logarithmic bucket boundaries, but with different approaches:

| Aspect | Heatmap | Histogram |
|--------|---------|-----------|
| Bucket count | Display width (~52) | Data-driven (decades × buckets_per_decade) |
| Bucket calculation | `min * (max/min)^(i/num_buckets)` | Same formula, different bucket count |
| Raw value storage | `%heatmap_raw{$time_bucket}` | `%histogram_values{$metric}` |
| Tallying | Per time bucket | Global across all data |

### Problems

1. **Statistical inconsistency**: Same value may fall into different buckets between features due to different bucket counts
2. **Memory duplication**: When both features enabled, raw values stored twice
3. **Code duplication**: Similar bucket boundary calculation in two places
4. **False precision**: Heatmap's 52 buckets (display-driven) may suggest more precision than statistically meaningful

### Research: HdrHistogram Approach

The histogram feature adopted the HdrHistogram "buckets per decade" model (see `features/histogram-charts.md` lines 366-414):

- Bucket count = decades × buckets_per_decade
- Default: 8 buckets/decade (~5% relative precision)
- Provides consistent relative precision across all magnitudes
- Industry standard for latency analysis

## Goals

1. **Statistical consistency**: Same bucket boundaries for both features
2. **Memory efficiency**: Single storage of raw values, shared tallying
3. **Code consolidation**: One bucket calculation function
4. **Meaningful precision**: Bucket count based on data characteristics, not display width

## Requirements

### Shared Bucket Calculation

Create a single function used by both features:

```perl
sub calculate_log_boundaries {
    my ($min, $max, $buckets_per_decade) = @_;
    $buckets_per_decade //= 8;  # Default ~5% precision

    my $decades = log10($max) - log10($min);
    my $bucket_count = int($decades * $buckets_per_decade + 0.5);
    $bucket_count = max($bucket_count, 4);  # Minimum 4 buckets

    my @boundaries;
    for my $i (0 .. $bucket_count) {
        push @boundaries, $min * ($max / $min) ** ($i / $bucket_count);
    }
    return (\@boundaries, $bucket_count);
}
```

### Shared Data Storage

Replace separate storage with unified structure:

```perl
# Current (duplicated):
my %heatmap_raw;           # {$time_bucket} = [values]
my %histogram_values;      # {$metric} = [values]

# Proposed (shared):
my %metric_raw_values;     # {$metric}{$time_bucket} = [values]
my %metric_buckets;        # {$metric}{$time_bucket}{$bucket_index} = count
my %metric_boundaries;     # {$metric} = [boundary values]
my %metric_min_max;        # {$metric} = {min => X, max => Y}
```

### Tallying Flow

1. **During parsing**: Store raw values in `%metric_raw_values{$metric}{$time_bucket}`
2. **After parsing**:
   - Calculate shared boundaries from global min/max
   - Tally raw values into `%metric_buckets{$metric}{$time_bucket}{$bucket_index}`
   - Free raw values immediately after tallying each time bucket
3. **Rendering**:
   - Heatmap: Read `%metric_buckets{$metric}{$time_bucket}{...}` directly
   - Histogram: Sum across time buckets: `sum over $time_bucket of %metric_buckets{$metric}{$time_bucket}{$bucket_index}`

### Heatmap Rendering Changes

Decouple bucket count from display width:

| Data buckets | Display width | Rendering |
|--------------|---------------|-----------|
| 40 | 80 | 2 characters per bucket |
| 40 | 120 | 3 characters per bucket |
| 40 | 40 | 1 character per bucket |
| 40 | 30 | Compress (aggregate adjacent buckets for display only) |

User's `-hmw` option becomes a rendering preference, not a bucket count.

### Command Line Changes

| Option | Current | Proposed |
|--------|---------|----------|
| `-hmw <N>` | Sets bucket count | Sets display width (rendering) |
| `-hgbpd <N>` | Histogram only | Shared: affects both features |
| `-hgb <N>` | Histogram only | Shared: affects both features |

Consider renaming to feature-neutral options:
- `-bpd <N>` / `--buckets-per-decade <N>` - shared precision control
- `-hmw <N>` / `--heatmap-width <N>` - heatmap display width (unchanged meaning but different effect)

### Validation Criteria

With `-b 1440` (single time bucket covering full day):
- Heatmap shows one row with distribution across N buckets
- Histogram shows same N buckets with same counts
- Bucket boundaries are identical between features

## Non-Requirements

- Changing histogram's visual rendering approach
- Adding new metrics (separate feature)
- Changing percentile calculations

## Dependencies

- **Memory tracking improvements** (see GitHub issue): Need accurate memory measurement to validate efficiency gains

## Implementation Phases

### Phase 1: Shared Bucket Calculation
- Extract common `calculate_log_boundaries()` function
- Both features call it with same parameters
- No data structure changes yet

### Phase 2: Unified Data Storage
- Merge `%heatmap_raw` and `%histogram_values` into `%metric_raw_values`
- Single pass for tallying
- Memory reduction when both features enabled

### Phase 3: Heatmap Rendering Decoupling
- Separate bucket count from display width
- Implement bucket-to-character mapping (expansion/compression)
- Update `-hmw` behavior

### Phase 4: Documentation
- Update README.md with binning algorithm explanation
- Update help text
- Add examples showing consistency between features

## Acceptance Criteria

- [ ] Single `calculate_log_boundaries()` function used by both features
- [ ] Raw values stored once, not duplicated
- [ ] Histogram totals derivable from heatmap bucket data
- [ ] Heatmap display width independent of bucket count
- [ ] `-b 1440` produces matching bucket counts and boundaries
- [ ] Memory usage reduced when both features enabled (measured)
- [ ] README.md documents shared binning approach

## Test Plan

### Unit Tests
1. `calculate_log_boundaries()` returns correct boundaries for various ranges
2. Bucket assignment consistent between features
3. Histogram totals equal sum of heatmap time bucket counts

### Integration Tests
1. Run with both `-hm` and `-hg`: verify no duplicate raw value storage
2. Run with `-b 1440 -hm -hg`: verify matching output
3. Memory profiling with large log files

### Visual Verification
1. Heatmap renders correctly with bucket count ≠ display width
2. Bucket expansion (multiple chars per bucket) looks correct
3. Bucket compression (display < buckets) maintains accuracy

## Progress Tracking

| Task | Status | Notes |
|------|--------|-------|
| Feature document created | Done | |
| GitHub issue created | Done | #41 |
| Memory tracking dependency | Pending | Separate issue required |
| Phase 1: Shared calculation | Pending | |
| Phase 2: Unified storage | Pending | |
| Phase 3: Rendering decoupling | Pending | |
| Phase 4: Documentation | Pending | |

## Decisions Log

| Decision | Rationale | Date |
|----------|-----------|------|
| Use HdrHistogram buckets-per-decade for both | Industry standard, consistent precision, already proven in histogram | 2026-02-02 |
| Derive histogram from heatmap data | Reduces memory, ensures consistency, histogram is aggregation of time buckets | 2026-02-02 |
| Decouple heatmap bucket count from display width | Allows statistical consistency while maintaining visual flexibility | 2026-02-02 |
| Memory tracking as prerequisite | Need accurate measurement to validate efficiency claims | 2026-02-02 |
