# User-Defined Metrics (Issue #22)

## Status
- **Issue**: #22
- **Branch**: `22-user-defined-metrics`
- **Phase**: Implementation

## Overview

User-defined metrics (`-udm`) allow users to extract arbitrary numeric values from log lines, track them across time buckets, and display them as additional bar graph columns alongside the built-in duration/bytes/count metrics.

## Syntax

```
-udm "name[:unit[:function]][:/pattern/]"
```

Multiple metrics can be specified with repeated `-udm` flags:
```
./ltl -udm "rows" -udm "latency:ms" -udm "errors::delta" logfile.txt
```

### Fields

| Field | Required | Description | Examples |
|-------|----------|-------------|----------|
| `name` | Yes | Metric identifier (used in column headers) | `rows`, `latency`, `tcp_errors` |
| `unit` | No | Measurement unit for conversion/display | `ms`, `s`, `us`, `ns`, `B`, `KB`, `MB`, `GB`, `TB` |
| `function` | No | Aggregation function | `delta`, `idelta` |
| `/pattern/` | No | Custom regex with capture group for value extraction | `/in (\d+\.\d+)/` |

### Unit Types

- **Time units**: `ns`, `us`, `ms`, `s` — converted to milliseconds internally, displayed via `format_time()`
- **Byte units**: `B`, `kB`, `KB`, `MB`, `GB`, `TB` — converted to bytes internally, displayed via `format_bytes()`
- **No unit**: displayed as raw numbers via `format_number()`

### Functions

- **`delta`**: Computes difference between consecutive values. Useful for monotonic counters.
- **`idelta`**: Like delta but discards negative values (counter resets). "Increase delta."
- **No function**: Uses the raw extracted value.

Delta state is reset between files to avoid spurious deltas at file boundaries.

### Default Pattern

When no custom `/pattern/` is provided, the metric name is used to build two default patterns:
1. `\bname\s*[=:]\s*(number)` — matches `rows=42`, `rows: 42`, etc.
2. `(number)\s*[=:]?\s*name\b` — matches `42 rows`, `42=rows`, etc.

### Examples

```bash
# Extract "rows" values using default pattern matching
-udm "rows"

# Extract latency values, interpret as milliseconds
-udm "latency:ms"

# Extract counter, compute per-line delta
-udm "tcp_errors::delta"

# Extract counter, discard negative deltas (counter resets)
-udm "tcp_errors::idelta"

# Custom regex extraction with time unit
-udm "proc_time:s::/processed in ([\d.]+) seconds/"

# Multiple metrics
-udm "rows" -udm "latency:ms" -udm "cache_hits::delta"
```

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Stats model | Count-style (min/max/mean/sum) | Avoids memory cost of storing individual values; percentiles deferred to #23 |
| Delta state | Reset between files | Avoids spurious deltas at file boundaries |
| Delta on raw vs converted | Delta on raw, then convert | Preserves counter semantics |
| Column key prefix | `udm_` prefix internally | Avoids collision with existing keys; stripped for display headers |
| Unit auto-detection | Not implemented | Users declare units explicitly |
| Non-access-log support | Set `$is_access_log = 1` when UDM values captured | Follows count metric precedent (line 1593); enables storage in time-bucket and per-message blocks |
| Latency stats suppression | `$print_durations` only set when duration/bytes/count present | Prevents empty P50/P95/P99/P999 columns when only UDM metrics are active |

## Data Model

### Time Bucket Storage (`%log_analysis`)
```
$log_analysis{$bucket}{"udm_${name}_sum"}
$log_analysis{$bucket}{"udm_${name}_occurrences"}
$log_analysis{$bucket}{"udm_${name}_min"}
$log_analysis{$bucket}{"udm_${name}_max"}
$log_analysis{$bucket}{"udm_${name}_sum-HL"}
$log_analysis{$bucket}{"udm_${name}_occurrences-HL"}
```

### Per-Message Storage (`%log_messages`)
```
$log_messages{$cat}{$key}{"udm_${name}_sum"}
$log_messages{$cat}{$key}{"udm_${name}_occurrences"}
$log_messages{$cat}{$key}{"udm_${name}_min"}
$log_messages{$cat}{$key}{"udm_${name}_max"}
```

### Statistics (`%log_stats`)
```
$log_stats{$bucket}{"udm_$name"}           # sum (used for bar graph scaling)
$log_stats{$bucket}{"udm_$name-HL"}        # highlighted sum
$log_stats{$bucket}{"udm_${name}_occurrences"}
$log_stats{$bucket}{"udm_${name}_min"}
$log_stats{$bucket}{"udm_${name}_max"}
$log_stats{$bucket}{"udm_${name}_mean"}
$log_stats{$bucket}{"udm_${name}_sum"}
```

## Relationship to Issue #23

This implementation serves as a proving ground for Issue #23's derived metrics architecture. It tests custom metric extraction, unit handling, delta functions, and data model integration in a lightweight form before the full core redesign.

## Known Issues (Resolved)

- **Non-access-log formats silently discarded UDM values**: The UDM storage blocks were inside `if ($is_access_log)` gates. Log formats that don't set `$is_access_log` (e.g., match_type 11 — ThingWorx Edge C SDK trace logs) would capture UDM values but never store them. Fixed by setting `$is_access_log = 1` when `%udm_values` is populated, and making `$print_durations` conditional on actual duration/bytes/count data to avoid empty latency columns.

## Future Enhancements (Out of Scope)

- Heatmap support for UDM metrics (`-hm udm_metricname`)
- Histogram support for UDM metrics
- Percentile statistics (requires storing individual values per bucket)
