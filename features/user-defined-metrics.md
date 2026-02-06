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
| `unit` | No | Measurement unit for conversion/display | `ms`, `s`, `us`, `ns`, `B`, `KB`, `KiB`, `MB`, `MiB`, `GB`, `GiB`, `TB`, `TiB` |
| `function` | No | Transform and/or aggregation function | `delta`, `max`, `avg(delta)` |
| `/pattern/` | No | Custom regex with capture group for value extraction | `/in (\d+\.\d+)/` |

### Unit Types

- **Time units**: `ns`, `us`, `ms`, `s` — converted to milliseconds internally, displayed via `format_time()`
- **Byte units**: `B`, `kB`, `KB`, `KiB`, `MB`, `MiB`, `GB`, `GiB`, `TB`, `TiB` — converted to bytes internally, displayed via `format_bytes()`. Case-insensitive matching (e.g., `kb` = `KB`). Binary units (`KiB`, `MiB`, etc.) use base-1024; `kB` (lowercase k) uses base-1000; all others use base-1024.
- **No unit**: displayed as raw numbers via `format_number()`

### Functions

Functions control how extracted values are transformed and aggregated per time bucket.

#### Transforms (applied per-line to raw values)

- **`delta`**: Computes difference between consecutive values. Useful for monotonic counters.
- **`idelta`**: Like delta but discards negative values (counter resets). "Increase delta."

Delta state is reset between files to avoid spurious deltas at file boundaries.

#### Aggregations (applied per time bucket)

- **`sum`**: Total of all values in the bucket (default)
- **`min`**: Minimum value in the bucket
- **`max`**: Maximum value in the bucket
- **`avg`**: Average (mean) of all values in the bucket

#### Combining transforms and aggregations

Transforms and aggregations can be combined using function-call syntax: `aggregation(transform)`. The transform is applied first to each line, then the aggregation is applied to the resulting values within each time bucket.

- When only a transform is specified (e.g., `delta`), aggregation defaults to `sum` — i.e., `delta` is shorthand for `sum(delta)`.
- When only an aggregation is specified (e.g., `max`), no transform is applied — the raw extracted values are aggregated directly.
- When neither is specified, the default is `sum` of raw values.

Valid combinations:

| Function value | Transform | Aggregation | Description |
|---------------|-----------|-------------|-------------|
| *(empty)* | none | sum | Sum of raw values (default) |
| `sum` | none | sum | Explicit sum of raw values |
| `min` | none | min | Minimum raw value in bucket |
| `max` | none | max | Maximum raw value in bucket |
| `avg` | none | avg | Average raw value in bucket |
| `delta` | delta | sum | Sum of deltas (shorthand for `sum(delta)`) |
| `idelta` | idelta | sum | Sum of positive deltas (shorthand for `sum(idelta)`) |
| `sum(delta)` | delta | sum | Explicit sum of deltas |
| `min(delta)` | delta | min | Minimum delta in bucket |
| `max(delta)` | delta | max | Maximum delta in bucket (largest spike) |
| `avg(delta)` | delta | avg | Average delta in bucket |
| `sum(idelta)` | idelta | sum | Sum of positive deltas |
| `min(idelta)` | idelta | min | Minimum positive delta in bucket |
| `max(idelta)` | idelta | max | Maximum positive delta in bucket |
| `avg(idelta)` | idelta | avg | Average positive delta in bucket |

### Default Pattern

When no custom `/pattern/` is provided, the metric name is used to build two default patterns:
1. `\bname\s*[=:]\s*(number)` — matches `rows=42`, `rows: 42`, etc.
2. `(number)\s*[=:]?\s*name\b` — matches `42 rows`, `42=rows`, etc.

### Examples

```bash
# Extract "rows" values using default pattern matching (sum per bucket)
-udm "rows"

# Extract latency values, interpret as milliseconds
-udm "latency:ms"

# Extract counter, compute per-line delta (sum of deltas per bucket)
-udm "tcp_errors::delta"

# Extract counter, discard negative deltas (counter resets)
-udm "tcp_errors::idelta"

# Custom regex extraction with time unit
-udm "proc_time:s::/processed in ([\d.]+) seconds/"

# Aggregation functions — change what the bar graph displays
-udm "latency:ms:max"                  # max latency per bucket
-udm "rows::avg"                       # average rows per bucket
-udm "response_size:KB:min"            # min response size per bucket

# Combined transform + aggregation
-udm "tcp_errors::max(delta)"          # largest single error spike per bucket
-udm "tcp_errors::avg(idelta)"         # average positive delta per bucket
-udm "counter::sum(delta)"             # explicit form of just "delta"

# Multiple metrics
-udm "rows" -udm "latency:ms:max" -udm "cache_hits::avg(delta)"
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
$log_analysis{$bucket}{"udm_${name}_min-HL"}
$log_analysis{$bucket}{"udm_${name}_max-HL"}
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
$log_stats{$bucket}{"udm_$name"}           # display value (selected by aggregation: sum/min/max/avg)
$log_stats{$bucket}{"udm_$name-HL"}        # highlighted display value (aggregation-aware)
$log_stats{$bucket}{"udm_${name}_occurrences"}
$log_stats{$bucket}{"udm_${name}_min"}
$log_stats{$bucket}{"udm_${name}_max"}
$log_stats{$bucket}{"udm_${name}_mean"}
$log_stats{$bucket}{"udm_${name}_sum"}
```

### Highlight Behavior by Aggregation

The `-HL` (highlight) value controls what portion of the bar renders in highlight color:

| Aggregation | Highlight behavior |
|-------------|-------------------|
| `sum` | `-HL` = sum of highlighted values. Bar shows highlighted portion proportionally. |
| `min` | `-HL` = display value if the highlighted min equals the overall min (entire bar highlights). Otherwise `undef` (no highlight). |
| `max` | `-HL` = display value if the highlighted max equals the overall max (entire bar highlights). Otherwise `undef` (no highlight). |
| `avg` | `-HL` = `undef`. No meaningful highlight for averages. |

## Relationship to Issue #23

This implementation serves as a proving ground for Issue #23's derived metrics architecture. It tests custom metric extraction, unit handling, delta functions, and data model integration in a lightweight form before the full core redesign.

## Known Issues (Resolved)

- **Non-access-log formats silently discarded UDM values**: The UDM storage blocks were inside `if ($is_access_log)` gates. Log formats that don't set `$is_access_log` (e.g., match_type 11 — ThingWorx Edge C SDK trace logs) would capture UDM values but never store them. Fixed by setting `$is_access_log = 1` when `%udm_values` is populated, and making `$print_durations` conditional on actual duration/bytes/count data to avoid empty latency columns.

## Next Steps

### Aggregation functions: min, max, avg — DONE
Added `min`, `max`, `avg`, and explicit `sum` as aggregation functions, with support for combining with transforms using function-call syntax: `max(delta)`, `avg(idelta)`, etc. See Functions section above for full syntax specification.

Implementation:
- [x] Parse new function syntax in `parse_udm_configs()`: standalone aggregations, combined `agg(transform)` form
- [x] Store `transform` and `aggregation` per UDM config
- [x] Select correct stored value (min/max/mean/sum) for bar graph display based on aggregation
- [x] Aggregation-aware highlight logic (min-HL, max-HL tracking)

### Unit coverage audit and IEC unit support — DONE
Added IEC binary units and case-insensitive unit matching.

- [x] Add `KiB`, `MiB`, `GiB`, `TiB` to `parse_udm_configs()` unit recognition and `convert_bytes()`
- [x] Case normalization: `kb` → `KB`, `kib` → `KiB`, `ms` → `ms`, etc.
- [ ] Test each time unit: `-udm "metric:ns"`, `-udm "metric:us"`, `-udm "metric:ms"`, `-udm "metric:s"`
- [ ] Test each byte unit with different magnitudes
- [ ] Test shorthand byte units: `-udm "metric:k"`, `-udm "metric:K"`, `-udm "metric:M"`, `-udm "metric:G"`, `-udm "metric:T"`
- [ ] Verify conversion correctness
- [ ] Consider whether additional units are needed (e.g., `min` for minutes, `h` for hours, percentage/rate units)

## Future Enhancements (Out of Scope)

- CSV column naming convention for UDM stats — align with count field naming pattern (`bytes_sent_min`, `bytes_sent_max`, `bytes_sent_avg`, `bytes_sent_sum`) so CSV output reflects the selected aggregation consistently. More complex than a simple rename due to interactions between bar graph display columns, CSV stat columns, and the aggregation selection.
- Heatmap support for UDM metrics (`-hm udm_metricname`)
- Histogram support for UDM metrics
- Percentile statistics (requires storing individual values per bucket)
- Columnar UDM from CSV input — allow defining user-defined metrics by column position or header name in CSV files, rather than regex extraction from unstructured log lines
