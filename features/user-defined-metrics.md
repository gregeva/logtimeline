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
| `unit` | No | Measurement unit for conversion/display | `ms`, `s`, `m`, `min`, `h`, `us`, `ns`, `B`, `KB`, `KiB`, `MB`, `MiB`, `GB`, `GiB`, `TB`, `TiB`, `k`, `K`, `M`, `G`, `T` |
| `function` | No | Transform and/or aggregation function | `delta`, `max`, `avg(delta)` |
| `/pattern/` | No | Custom regex with capture group for value extraction | `/in (\d+\.\d+)/` |

### Unit Types

- **Time units**: `ns`, `us`, `ms`, `s`, `m` (or `min`), `h` — converted to milliseconds internally, displayed via `format_time()`
- **Byte units**: `B`, `kB`, `KB`, `KiB`, `MB`, `MiB`, `GB`, `GiB`, `TB`, `TiB` — converted to bytes internally, displayed via `format_bytes()`. Case-insensitive matching (e.g., `kb` = `KB`). All byte units currently use base-1024 (see #63 — `kB` should use base-1000 per SI convention).
- **SI number units**: `k`, `K`, `M`, `G`, `T` — unitless SI multipliers (base-1000), displayed via `format_number()`. Case-sensitive (`m` = minutes, `M` = mega).
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
| CSV column naming | `name[_unit]_stat` lowercase | Consistent pattern across count and UDM metrics in both STATS and MESSAGES CSVs. Unit included when defined (e.g., `latency_ms_min`), omitted when unitless (e.g., `rows_min`). Count columns use `count_stat` (not PascalCase). |
| Unit auto-detection | Not implemented | Users declare units explicitly |
| Non-access-log support | Set `$is_access_log = 1` when UDM values captured | Follows count metric precedent (line 1593); enables storage in time-bucket and per-message blocks |
| Latency stats suppression | `$print_durations` only set when duration/bytes/count present | Prevents empty P50/P95/P99/P999 columns when only UDM metrics are active |
| Default aggregation | `sum` | Consistent with pre-aggregation behavior; `delta` without explicit aggregation means `sum(delta)` |
| Case normalization | Normalize in `parse_udm_configs()` before lookup | Avoids changing `convert_bytes()` / `convert_duration_to_ms()` which are used elsewhere |
| Aggregation affects display only | Bar graph column driven by aggregation; CSV always outputs all five stats | CSV preserves full data regardless of display selection |

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

## Known Issues

- **Same metric name with different functions is not supported**: Using the same metric name in multiple `-udm` flags with different aggregations or transforms (e.g., `-udm "x::sum" -udm "x::max"`) does not produce two separate columns. Both configs share the same `%udm_values` key and `%udm_last_value` delta state, so the second config's extracted value overwrites the first during per-line processing. Use distinct names instead (e.g., `-udm "x_sum::sum" -udm "x_max::max"` with custom regex patterns).

### Resolved

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
- [ ] Test each time unit: `-udm "metric:ns"`, `us`, `ms`, `s`, `m`, `min`, `h`
- [ ] Test each byte unit: `-udm "metric:B"`, `kB`, `KB`, `KiB`, `MB`, `MiB`, `GB`, `GiB`, `TB`, `TiB`
- [ ] Test SI number units: `-udm "metric:k"`, `K`, `M`, `G`, `T` — verify base-1000 conversion
- [ ] Case edge: `-udm "metric:m"` = minutes, `-udm "metric:M"` = mega
- [ ] Alias: `-udm "metric:min"` = same as `m`
- [ ] Verify unknown unit warning: `-udm "metric:xyz"`
- [ ] GC log regression: verify `convert_bytes("512M")` still works (non-UDM path)

### CSV Columnar Input — DONE

When a CSV file is processed with `-udm`, ltl auto-detects the CSV format from the first line (header row), maps UDM metric names to column headers, and extracts values directly by column index instead of regex matching.

**Options:**
- `-ucm "col1 col2"` — specify CSV columns to use as the message grouping key (space-separated names, repeatable flag)
- `-ucs ","` — override auto-detected separator (auto-detects `,`, `;`, `\t`)

**Behavior:**
- CSV detection only triggers when `-udm` is present and the first line looks like a header (has separators)
- Column matching is case-insensitive
- Per-file state: different CSV files in the same invocation can have different schemas
- All transforms (`delta`, `idelta`) and aggregations (`min`, `max`, `avg`) work with CSV input
- CSV lines use fixed category `DATA` (no log levels in CSV)
- Without `-ucm`, all CSV rows group under a single "CSV data" message

**Limitations:**
- No support for quoted fields with embedded separators (uses simple `split()`)
- Timestamp column must be named `timestamp` (case-insensitive) or defaults to column 0
- Same metric name with different aggregation functions is not supported (#99)

**Epoch timestamps** (Issue #98): Numeric epoch timestamps (e.g., `1771078373.207929`) are auto-detected on the first CSV data line. No new flags needed. The `-du` flag overrides the epoch unit if values aren't seconds (`-du ms` for milliseconds, `-du us` for microseconds, `-du ns` for nanoseconds).

## Future Enhancements (Out of Scope)

- ~~CSV column naming convention for UDM stats~~ — Done: consistent `name[_unit]_stat` lowercase pattern across both STATS and MESSAGES CSVs. Unit included between name and stat when defined (e.g., `latency_ms_occurrences`), omitted when unitless (e.g., `rows_occurrences`). Count columns normalized from PascalCase to `count_stat`.
- ~~Heatmap support for UDM metrics~~ — Done: `-hm <udm_name>` uses color gradient matching the metric's bar graph column
- ~~Histogram support for UDM metrics~~ — Done: `-hg <udm_name>` renders histogram with color matching the metric's bar graph column position. Multiple UDM histograms supported side-by-side.
- Percentile statistics (requires storing individual values per bucket)
