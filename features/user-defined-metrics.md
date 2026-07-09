# User-Defined Metrics (Issue #22)

## Status
- **Issue**: #22
- **Branch**: `22-user-defined-metrics`
- **Phase**: Implementation

## Overview

User-defined metrics (`-udm`) allow users to extract arbitrary numeric values from log lines, track them across time buckets, and display them as additional bar graph columns alongside the built-in duration/bytes/count metrics.

## Syntax

```
-udm "name[:unit[:function]][:key|:/pattern/]"
```

Multiple metrics can be specified with repeated `-udm` flags:
```
./ltl -udm "rows" -udm "latency:ms" -udm "errors::delta" logfile.txt
```

### Fields

| Field | Required | Description | Examples |
|-------|----------|-------------|----------|
| `name` | Yes | Metric identifier (used in column headers); also the default extraction key when no `key` or `/pattern/` is given | `rows`, `latency`, `tcp_errors` |
| `unit` | No | Measurement unit for conversion/display; ignored (with a warning) for counting aggregations | `ms`, `s`, `m`, `min`, `h`, `us`, `ns`, `B`, `KB`, `KiB`, `MB`, `MiB`, `GB`, `GiB`, `TB`, `TiB`, `k`, `K`, `M`, `G`, `T` |
| `function` | No | Transform and/or aggregation function | `delta`, `max`, `mean(delta)`, `distinct` |
| `key` | No | Token key: default patterns are built from this token instead of the name, leaving the name a pure display label. Mutually exclusive with `/pattern/` (both → warn + skip) | `exception_variety::distinct:JavaException` |
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
- **`mean`**: Average of all values in the bucket (`avg` accepted as an input alias; `mean` is canonical everywhere — internal aggregation value, #99 collision headers, CSV columns)

#### Counting aggregations (Issue #313)

Counting aggregations count extracted values per bucket instead of doing arithmetic on them, and fully support string tokens (IDs, usernames, exception class names). Raw extracted strings are preserved: numeric coercion, unit conversion, and transforms do not apply, and combining one with `delta`/`idelta` is rejected at parse (warn + skip).

- **`count`**: Number of extracted occurrences in the bucket
- **`distinct`**: Number of unique extracted values in the bucket (aliases `dcount`, `unique`); per-bucket semantics identical to the sessions column, including the free-after-count memory lifecycle of `%udm_distinct`
- **`ratio`**: Occurrences ÷ distinct — the repetition factor (≥ 1; occurrences > 0 implies distinct ≥ 1)
- **`rate`**: Occurrences per rate unit — honors the tool-wide `-ru` (default per-minute), same multiplier/suffix machinery as err-rate/msg-rate
- **`drate`**: Distinct values per rate unit — same `-ru` handling

Highlight behavior follows the sessions pattern: every matched line feeds the bucket totals; `-h`-matched lines additionally feed the highlight counterparts, and derived aggregations compute over the highlight counterparts (not the totals). Counting UDMs are rejected (with a warning) as `-hm`/`-hg` metrics and are excluded from bare `-hg` auto-inclusion — a per-line distribution over string events is meaningless. Default extraction uses a token-capture pattern `\bkey\s*[=:]\s*([^\s,;"'\])]+)` built from the token key (or the name), form-1 only — `]` and `)` are excluded so bracket-delimited fields capture cleanly.

Observability: the `-V udm-counting` section emits per-bucket per-metric occurrences/distinct (plain and highlight), display and highlight values, and a sessions oracle reference line (consumed by `tests/validate-udm-counting.sh`).

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
| `mean` | none | mean | Average raw value in bucket (`avg` accepted as alias) |
| `delta` | delta | sum | Sum of deltas (shorthand for `sum(delta)`) |
| `idelta` | idelta | sum | Sum of positive deltas (shorthand for `sum(idelta)`) |
| `sum(delta)` | delta | sum | Explicit sum of deltas |
| `min(delta)` | delta | min | Minimum delta in bucket |
| `max(delta)` | delta | max | Maximum delta in bucket (largest spike) |
| `mean(delta)` | delta | mean | Average delta in bucket |
| `sum(idelta)` | idelta | sum | Sum of positive deltas |
| `min(idelta)` | idelta | min | Minimum positive delta in bucket |
| `max(idelta)` | idelta | max | Maximum positive delta in bucket |
| `mean(idelta)` | idelta | mean | Average positive delta in bucket |
| `count` / `distinct` / `ratio` / `rate` / `drate` | none (rejected if combined) | counting | See Counting aggregations above |

### Default Pattern

When no custom `/pattern/` is provided, the extraction key (the `key` field when given, otherwise the metric name) is used to build the default patterns.

Numeric aggregations get two patterns:
1. `\bkey\s*[=:]\s*(number)` — matches `rows=42`, `rows: 42`, etc.
2. `(number)\s*[=:]?\s*key\b` — matches `42 rows`, `42=rows`, etc.

Counting aggregations get a single token-capture pattern:
1. `\bkey\s*[=:]\s*([^\s,;"'\])]+)` — matches `userId=abc123`, `[U: Administrator]`, `JavaException: SomeClass`, capturing the token up to whitespace or a field delimiter (`]` and `)` excluded).

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
-udm "rows::mean"                      # average rows per bucket (avg accepted as alias)
-udm "response_size:KB:min"            # min response size per bucket

# Combined transform + aggregation
-udm "tcp_errors::max(delta)"          # largest single error spike per bucket
-udm "tcp_errors::avg(idelta)"         # average positive delta per bucket
-udm "counter::sum(delta)"             # explicit form of just "delta"

# Counting aggregations on identity tokens (zero-regex via the token key)
-udm "active_users::distinct:U"        # distinct users per bucket from [U: name] fields
-udm "actions_per_user::ratio:U"       # repetition factor per bucket
-udm "logins::rate:userId"             # occurrences per rate unit (-ru)

# Multiple metrics
-udm "rows" -udm "latency:ms:max" -udm "cache_hits::mean(delta)"
```

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Stats model | Count-style (min/max/mean/sum) | Avoids memory cost of storing individual values; percentiles deferred to #23 |
| Delta state | Reset between files | Avoids spurious deltas at file boundaries |
| Delta on raw vs converted | Delta on raw, then convert | Preserves counter semantics |
| Column key prefix | `udm_` prefix internally | Avoids collision with existing keys; stripped for display headers |
| CSV column naming | `name[_unit]_stat` lowercase | Consistent pattern across count and UDM metrics in both STATS and MESSAGES CSVs. Unit included when defined (e.g., `latency_ms_min`), omitted when unitless (e.g., `rows_min`). Count columns use `count_stat` (not PascalCase). Counting aggregations emit one column per metric, `{base_name}_{agg}` (e.g. `users_distinct`), with the `-ru` CSV suffix for `rate`/`drate` (e.g. `logins_rate_min`); in MESSAGES, `count` carries per-message occurrences and the distinct-derived columns are blank (distinct is bucket-scoped). |
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

Counting configs accumulate only `_occurrences`/`_occurrences-HL` here, plus the distinct value sets in a dedicated hash (deleted per bucket immediately after counting in `calculate_all_statistics`, mirroring `%log_sessions`):
```
$udm_distinct{$bucket}{$name}{plain}{$value}
$udm_distinct{$bucket}{$name}{highlight}{$value}
```

### Per-Message Storage (`%log_messages`)
```
$log_messages{$cat}{$key}{"udm_${name}_sum"}
$log_messages{$cat}{$key}{"udm_${name}_occurrences"}
$log_messages{$cat}{$key}{"udm_${name}_min"}
$log_messages{$cat}{$key}{"udm_${name}_max"}
$log_messages{$cat}{$key}{"udm_${name}_mean"}   # numeric aggregations only
```

The per-message mean is derived in `calculate_all_statistics()` as `sum / occurrences` and exists only for numeric aggregations. Counting aggregations (`count`, `distinct`, `ratio`, `rate`, `drate`) track `udm_${name}_occurrences` without ever writing `udm_${name}_sum`, so the mean derivation skips `agg_kind eq 'counting'` configs entirely and guards against an undefined sum (Issue #326).

### Statistics (`%log_stats`)
```
$log_stats{$bucket}{"udm_$name"}           # display value (selected by aggregation)
$log_stats{$bucket}{"udm_$name-HL"}        # highlighted display value (aggregation-aware)
$log_stats{$bucket}{"udm_${name}_occurrences"}
$log_stats{$bucket}{"udm_${name}_min"}
$log_stats{$bucket}{"udm_${name}_max"}
$log_stats{$bucket}{"udm_${name}_mean"}
$log_stats{$bucket}{"udm_${name}_sum"}
```

Counting configs additionally store (consumed by the `-V udm-counting` section):
```
$log_stats{$bucket}{"udm_${name}_occurrences-HL"}
$log_stats{$bucket}{"udm_${name}_distinct"}
$log_stats{$bucket}{"udm_${name}_distinct-HL"}
```

### Highlight Behavior by Aggregation

The `-HL` (highlight) value controls what portion of the bar renders in highlight color:

| Aggregation | Highlight behavior |
|-------------|-------------------|
| `sum` | `-HL` = sum of highlighted values. Bar shows highlighted portion proportionally. |
| `min` | `-HL` = display value if the highlighted min equals the overall min (entire bar highlights). Otherwise `undef` (no highlight). |
| `max` | `-HL` = display value if the highlighted max equals the overall max (entire bar highlights). Otherwise `undef` (no highlight). |
| `mean` | `-HL` = `undef`. No meaningful highlight for averages. |
| `count` | `-HL` = highlighted occurrence count. Proportional, like `sum`. |
| `distinct` | `-HL` = distinct count of the highlight value set. Proportional. |
| `ratio` / `rate` / `drate` | `-HL` = the same arithmetic computed over the highlight counterparts (highlighted occurrences / highlighted distinct). |

## Relationship to Issue #23

This implementation serves as a proving ground for Issue #23's derived metrics architecture. It tests custom metric extraction, unit handling, delta functions, and data model integration in a lightweight form before the full core redesign.

## Known Issues

- **Same metric name with different functions is not supported**: Using the same metric name in multiple `-udm` flags with different aggregations or transforms (e.g., `-udm "x::sum" -udm "x::max"`) does not produce two separate columns. Both configs share the same `%udm_values` key and `%udm_last_value` delta state, so the second config's extracted value overwrites the first during per-line processing. Use distinct names instead (e.g., `-udm "x_sum::sum" -udm "x_max::max"` with custom regex patterns).

### Resolved

- **Counting aggregations triggered uninitialized-value warnings in the per-message mean loop (Issue #326)**: the per-message mean derivation divided `udm_${name}_sum` by occurrences for every UDM config, but counting aggregations never populate `_sum`, producing one `Use of uninitialized value in division` warning per message key. Fixed by skipping counting configs in the mean loop and guarding on a defined sum. The csv-output harness now fails any scenario whose stderr carries Perl runtime warnings, so this class of unguarded data path can no longer pass silently.
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
- Rows whose timestamp column is neither epoch nor ISO (`YYYY-MM-DD HH:MM:SS`) are skipped, never fed to the fixed-offset substr/`timegm()` parse: the first such row in a file warns with file, line, and offending value; a per-file total is reported at end of file (Issue #328 — a quoted-timestamp CSV from a previous `ltl -o` run swept into a multi-file glob previously died fatally with `Month '-1' out of range`). Covered by `tests/validate-csv-input.sh`.

**Limitations:**
- No support for quoted fields with embedded separators (uses simple `split()`)
- Timestamp column must be named `timestamp` (case-insensitive) or defaults to column 0
- ~~Same metric name with different aggregation functions~~ — Resolved (#99): duplicate names are auto-disambiguated with `:aggregation` suffix (e.g., `request_size:min`, `request_size:avg`, `request_size:max`)

**Epoch timestamps** (Issue #98): Numeric epoch timestamps (e.g., `1771078373.207929`) are auto-detected on the first CSV data line. No new flags needed. The `-du` flag overrides the epoch unit if values aren't seconds (`-du ms` for milliseconds, `-du us` for microseconds, `-du ns` for nanoseconds).

## Counting Aggregations (Issue #313)

### Status
- **Issue**: #313
- **Branch**: `313-udm-count-distinct-aggregations`
- **Target release**: v0.16.0
- **Phase**: Implemented 2026-07-08 — all seven phases landed; shipped behavior folded into the standing sections above. This section remains as the decision/design record.

### Overview

Adds counting aggregation functions to the UDM function field: `count` (occurrences per bucket), `distinct` (distinct extracted values per bucket), and three derived arithmetic aggregations — `ratio` (occurrences ÷ distinct, the repetition factor: how many times the average value repeats within the bucket), `rate` (occurrences per rate unit), `drate` (distinct values per rate unit). `rate`/`drate` honor the tool-wide `-ru` rate unit (default per-minute) — the same single configuration surface as the built-in err-rate/msg-rate columns. Motivating case: a log line with no session ID but an embedded user ID (`userId=abc123`) — a distinct-count UDM turns those IDs into a load-shape metric per time bucket, exactly as the built-in sessions column does for session IDs.

### Requirements

1. `count` displays the number of extracted occurrences per bucket.
2. `distinct` displays the number of distinct raw extracted values per bucket — **string values fully supported** (IDs, tokens), not just numbers.
3. `ratio`, `rate`, `drate` derive from the same data with display-time arithmetic.
4. Highlight behavior follows the sessions pattern: every line's value enters the bucket's total set; `-HL`-tagged lines (the `-h` highlight regex) additionally enter the highlight set. Example: `userId=123 ... GET /api/orders` under `-udm "userId::distinct" -h "orders"` → `123` counts in the bucket's total distinct AND highlight distinct.
5. Memory: per-bucket distinct sets follow the sessions free-after-count lifecycle.
6. **No new naming or output schemes** — headers and CSV columns compose from the existing patterns (`name[_unit]_stat` family shape, rate-unit CSV suffix); only new functions are added.
7. **Token key decouples label from extraction**: a bare (non-slash-delimited) fourth field names the token to build the default pattern from, so the metric name serves purely as the display label — `exception_variety::distinct:JavaException` extracts the `JavaException:` token but labels the column `exception_variety`. Applies to numeric and counting configs alike.

### Decisions (locked 2026-07-06, revised 2026-07-08, user-approved)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Keywords | `count`, `distinct`, `ratio`, `rate`, `drate`, plus alias map `dcount`/`unique` → `distinct`, `avg` → `mean` (small `%udm_agg_aliases` normalization before the parse regex, applied to combined forms too: `avg(delta)` → `mean(delta)`) | SQL-familiar set operations; the alias map also makes the docs/usage.md aggregation-alias claim true (no alias resolution exists in the parser today) |
| Canonical `mean` replaces `avg` | `mean` becomes the canonical aggregation keyword; internal aggregation value `'mean'`; `avg` accepted as alias. The #99 collision suffix and disambiguated CSV column become `:mean`/`x:mean` (previously `:avg`/`x:avg`) | Everywhere else in ltl `mean` is canonical (summary table column, `_mean` CSV stat suffix, `-so mean`, docs alias table) — the UDM parser was the outlier, accepting only `avg` on input while printing `mean` on output. Aligns input with terminal and CSV output; avoids the mean/median ambiguity of "average" |
| Ratio direction | `ratio` = occurrences ÷ distinct (repetition factor, ≥ 1) | Matches the load-shape motivation ("each user ID appeared 3.2 times on average this bucket"); occurrences > 0 implies distinct ≥ 1, so no division by zero |
| Rate unit | `rate`/`drate` honor the tool-wide `-ru` rate unit: value = occurrences (or distinct) ÷ `$bucket_size_seconds` × `$rate_multiplier{$rate_unit}`, terminal suffix from `%rate_suffix`, CSV suffix from `%rate_csv_suffix` | Single configuration surface, mirroring err-rate/msg-rate exactly (same default per-minute, same suffixes); a per-second-only UDM rate would be incoherent with the tool's existing rate concept |
| Distinct semantics | Per-bucket distinct count (sessions-column semantics); no cumulative variant | Cumulative needs a never-freed global set, violating the memory lifecycle |
| Value types | Raw extracted **string** preserved for counting aggs: skip numeric coercion (`+0`), unit conversion, and transforms | The motivating userId case is a string; numeric pipeline is meaningless for cardinality |
| Transform combinations | `distinct(delta)` etc. rejected at parse: warn + skip config | Transforms are numeric-only concepts |
| Unit field with counting agg | Warn + ignore unit | Matches the existing unknown-unit warn-and-continue tone |
| Column headers | Today's rule unchanged: header = user-chosen name; `:agg` suffix only on duplicate-name collision (#99) | Same pattern for all aggregations; user controls the name; sessions precedent (label the meaning, not the mechanism) |
| STATS CSV | Single value column per counting UDM, named `{name}_{agg}` (`userId_distinct`, `logins_count`); `rate`/`drate` additionally append the `-ru` CSV suffix (`logins_rate_min`). Gated on `agg_kind` at the four single-column sites that today test `name ne base_name` | Reads as the existing `name[_unit]_stat` family pattern with the aggregation as the stat (unit slot empty — units are ignored for counting); rate columns mirror `msg-rate_min`. The bare-name #99 path stays as-is for collision disambiguation; the agg suffix also means two counting configs on the same base name never collide in CSV |
| MESSAGES CSV | `count` → occurrences; `distinct`/`ratio`/`rate`/`drate` → blank, documented | Per-message distinct is not tracked (would need per-key sets plus set-union in consolidation merges) |
| Default pattern for counting configs | Token capture, form-1 only: `\bkey\s*[=:]\s*([^\s,;"'\])]+)` — `]` and `)` excluded from the token; `key` is the token key when given, else the metric name | The numeric default patterns can never match `userId=abc123`; the reversed form-2 pattern is too greedy for arbitrary tokens; excluding `]`/`)` keeps bracket-delimited fields clean (ThingWorx `[U: Administrator]` yields `Administrator`, not `Administrator]`) |
| Token key field (decided 2026-07-08) | Syntax becomes `name[:unit[:function]][:key|:/pattern/]`: a bare fourth field is the token key — default patterns (numeric form-1/form-2, counting token capture) are built from the key instead of the name. `/…/` = regex as today; bare word = token key; absent = name is the key. Supplying both a key and a regex (`name::agg:key:/re/`) warns + skips the config | The name otherwise does double duty as label and extraction key; wanting a readable column header forced a fall from zero-regex to full-regex (found while writing the #313 demo use cases). Applies to all UDMs, not just counting |
| Rendering | No counting-specific decimal branch: values format through the existing renderers (`format_number` dynamic decimals on the terminal, existing CSV precision rules) | `ratio`/`rate`/`drate` are fractional; the terminal render already auto-adjusts decimals to magnitude and available space |
| Time-axis folding (#256) | `distinct` counts across all periods folded into a display bucket (identical to the sessions column); `rate`/`drate` divide by the single-period `$bucket_size_seconds`, exactly as err-rate/msg-rate do | Counting UDMs inherit folding semantics from the columns they mirror — no #313-specific folding behavior |
| Deferred | `mode`/`first`/`last`/top-N (need a string-display column render model), cumulative distinct, uniqueness ratio (distinct ÷ occurrences, the reciprocal of `ratio`) | Follow-up issues if wanted. Uniqueness adds no information (exact reciprocal) and its 0..1 range renders poorly as bars; it is pure display-time arithmetic over data already held, so adding a keyword later is non-breaking |
| Highlight observability (decided 2026-07-08, user-approved) | New `-V udm-counting` section: per-bucket per-metric occurrences/distinct plain+highlight, display and highlight values, plus a sessions/sessions-HL oracle reference line. Registered in the section registry and HARNESS-DESIGN reserved names | Highlight values appear on no machine-readable surface (not in CSVs); HARNESS-DESIGN forbids scraping the render for computed values, so the highlight oracle and derived-HL arithmetic tests required a `-V` section |

### Design

- New `agg_kind => 'numeric' | 'counting'` field on the UDM config hash; parse alternation extended (including `mean`), aliases normalized first — the normalization must also rewrite the aggregation inside combined forms (`avg(delta)` → `mean(delta)`).
- Token key: in `parse_udm_configs()`, after the trailing `/pattern/` extraction, the `split(/:/, $arg, 3)` becomes limit 4; a non-empty fourth field is stored as `token_key` and default-pattern construction substitutes it for the name. Both key and regex present → warn + skip config.
- Canonical `mean`: the parse regex alternation replaces `avg` with `mean`; every internal comparison against the aggregation value (`'avg'` today) follows in the same change.
- New `%udm_distinct{$bucket}{$name}{plain|highlight}{$value}` mirroring `%log_sessions` exactly: populate during bucket accumulation (plain always; highlight additionally when `$category_bucket =~ /-HL$/`); count via `scalar keys` in `calculate_all_statistics`; delete each bucket's sets immediately after counting; add to the `-mem` Devel::Size report.
- `count` display value = the existing `udm_${name}_occurrences` counter (already accumulated); `ratio`/`rate`/`drate` are display-time arithmetic: ratio = occurrences ÷ distinct; rate = occurrences ÷ `$bucket_size_seconds` × `$rate_multiplier{$rate_unit}`; drate the same over distinct — reusing the err-rate/msg-rate machinery (`%rate_multiplier`, `%rate_suffix`, `%rate_csv_suffix`).
- String guard on every numeric consumer of `%udm_values`: per-message stats seed, per-message accumulation, bucket accumulation (skip `_sum/_min/_max` for counting configs), heatmap capture, histogram capture (raw + streaming). `-hg`/`-hm` naming a counting UDM is rejected with a warning — a per-line distribution over string events is meaningless.
- Fuzzy-consolidation merge helpers currently key on `defined "udm_${name}_sum"` and would silently drop counting-UDM occurrences on merge — add an `agg_kind` branch merging `_occurrences` only.
- Render: counting values dispatch to the existing formatters (`format_number` with its dynamic decimal adjustment on the terminal; the existing precision rules in CSV) — no counting-specific formatting branch. Fractional `ratio`/`rate`/`drate` values rely on the dynamic decimals; `rate`/`drate` terminal values carry the `%rate_suffix` unit suffix like msg-rate.
- Highlight display values: `count` → `_occurrences-HL` (proportional bright prefix, like `sum`); `distinct` → `scalar keys` of the highlight sub-hash; `ratio`/`rate`/`drate` → arithmetic over the highlight counterparts.

### Implementation plan (approved 2026-07-08)

Phases land one at a time, each presented for confirmation before the next begins. Phase boundaries are natural commit boundaries (Phase 1 may split into mean-canonicalization + token-key + counting-keywords commits if that reads better in review). Progress is ticked here as phases land.

- [x] **Phase 1 — Parser: aliases, canonical `mean`, counting keywords, token key.** All in `parse_udm_configs()` plus the downstream `'avg'` literals. (1) New `%udm_agg_aliases` (`dcount`/`unique` → `distinct`, `avg` → `mean`) applied to the function field before the parse regex, including inside combined forms. (2) Parse-regex alternation `avg` → `mean`; update every downstream `'avg'` comparison: bucket display-value selection and highlight-value selection in `calculate_all_statistics`, the MESSAGES CSV stat-key mapping in `print_message_summary`, and the #99 collision suffix in `parse_udm_configs()`. The `-so` sort handling already accepts both `mean|avg` — verify, no change expected. (3) Extend the alternation with `count|distinct|ratio|rate|drate`; set `agg_kind => 'numeric'|'counting'` on the config hash; counting agg in combined form → warn + skip; unit + counting agg → warn + ignore unit. (4) Token key: the field `split(/:/, $arg, 3)` becomes limit 4 (after the trailing `/pattern/` extraction); non-empty bare fourth field → `token_key`; key + regex both present → warn + skip; default-pattern construction substitutes the key for the name, for numeric and counting configs alike. (5) Counting default pattern: form-1 token capture only, `\bkey\s*[=:]\s*([^\s,;"'\])]+)`, built from `token_key // name`.
- [x] **Phase 2 — Accumulation: string values, distinct sets, numeric guards.** (1) In per-line extraction, counting configs skip numeric coercion, unit conversion, and transforms — raw string kept in `%udm_values`. (2) New `%udm_distinct` global populated in the per-bucket accumulation block (plain always; highlight additionally when `$category_bucket =~ /-HL$/`), mirroring the `%log_sessions` capture; counting configs skip `_sum/_min/_max` accumulation while `_occurrences`/`_occurrences-HL` still accumulate. (3) Per-message stats: counting configs accumulate `_occurrences` only. (4) `-hm`/`-hg` naming a counting UDM rejected with a warning at heatmap/histogram config resolution, so the capture sites never see counting values. (5) Add `udm_distinct` to `measure_memory_structures()`.
- [x] **Phase 3 — Statistics and terminal display.** (1) Counting branch at the UDM stats-promotion block in `calculate_all_statistics`: `distinct` = `scalar keys` of the plain set; `count` = `_occurrences`; `ratio` = occurrences ÷ distinct; `rate`/`drate` = count/distinct ÷ `$bucket_size_seconds` × `$rate_multiplier{$rate_unit}`; highlight counterparts from the highlight set / `_occurrences-HL`; free each bucket's `%udm_distinct` sets immediately after counting (model: sessions). (2) Rendering unchanged: values flow through the existing UDM terminal render and `format_number` dynamic decimals; `rate`/`drate` terminal values carry `%rate_suffix{$rate_unit}` (model: msg-rate). (3) Column registration unchanged (`add_dynamic_column`).
- [x] **Phase 4 — CSV output.** (1) STATS CSV: gate single-value-column emission on `agg_kind eq 'counting'` (alongside the existing `name ne base_name` #99 path) at column registration in `normalize_data_for_output` and row emission in `print_bar_graph`; column name `{name}_{agg}`; `rate`/`drate` append `%rate_csv_suffix{$rate_unit}` in the header rewrite (model: msg-rate). (2) MESSAGES CSV value emission and header in `print_message_summary`: `count` → occurrences; `distinct`/`ratio`/`rate`/`drate` → blank column, documented.
- [x] **Phase 5 — Consolidation merge.** Both merge gates key on `defined "udm_${name}_sum"` and would silently drop counting occurrences: the `group_similar_messages` flush block and `merge_consolidation_stats`. Add an `agg_kind` branch merging `_occurrences` only for counting configs.
- [x] **Phase 6 — Tests.** Per the test strategy below. Read `tests/HARNESS-DESIGN.md` before touching anything under `tests/`. New string-ID fixture under `tests/fixtures/`; sessions + highlight oracles; first UDM coverage in `tests/csv-output/` (scenario + column rules); all validation paths (transform rejection, unit warning, `-hg`/`-hm` rejection, #99 duplicates, alias/canonical `mean`, token key, `-ru` scaling, `-g` merge, `-mem` lifecycle).
- [x] **Phase 7 — Documentation (same commit as help changes).** `print_help()` `-udm` spec-format + function lines; `docs/usage.md` spec table, example, Alternate Names table; README options reference; fold shipped behavior into the standing sections of this file and fill Lessons Learned. (`demo-use-cases.md` already done on this branch.)

Verification gates: `validate-help-content.sh`, `validate-help-layout.sh`, `CI=1 validate-csv-output.sh`, `validate-doc-examples.sh`, `validate-regression.sh` all pass; end-to-end demo commands from `demo-use-cases.md` (ScriptLog.2025-05-05.0.log → 4 distinct exception classes over 19,750 lines; ApplicationLog.2025-05-06.0.log → 167 distinct users); sessions-oracle run compared bucket-for-bucket against the sessions column.

### Test strategy

- **Sessions oracle** (strongest check): a distinct UDM extracting the session ID must equal the built-in sessions column per bucket. Log survey (2026-07-08): every ThingWorx-format log in `logs/` has an empty `[S:]` field — the populated session source is the Tomcat access-log trailing positional field. Large-scale one-off run: `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-4.2026-01-26.txt` (107 MB, 32-hex session IDs plus sessionless `-` lines exercising the no-value path), custom regex on the trailing hex field — verified 12/12 buckets identical during Phase 3. (Correction 2026-07-08: the 5k extract named here earlier has no session field at all — 11 fields/line vs 13; the per-commit oracle runs on the synthetic fixture instead.) The harness oracle compares value-to-value from `-V udm-counting`, not against frozen numbers.
- **Highlight oracle**: the sessions-oracle comparison repeated in the highlight dimension via `-h` — the distinct UDM's `distinct_hl` must equal `sessions_hl` per bucket, read from `-V udm-counting`.
- **Derived-aggregation highlight arithmetic**: on the fixture (highlighted subset known by construction), `count`-HL is the `-HL` occurrence total and `ratio`/`rate`/`drate` compute over the highlight counterparts, not the totals — asserted with exact hand-computed values in `tests/validate-udm-counting.sh`.
- **Fixture**: `tests/fixtures/udm-counting-tokens.txt` — synthetic 12-line Tomcat access log (no real data; public repo), two 1-minute buckets, `userId=` tokens for the default token pattern, 32-hex session fields, sessionless probe lines, and an `orders` URL subset for `-h`. All expected values hand-computed and documented in the harness header.
- **Harness**: `tests/validate-udm-counting.sh` (28 assertions, self-documenting per HARNESS-DESIGN) — fixture values plain+HL, sessions oracle, token-key equivalence, `-ru` scaling, all warning paths, alias canonicalization (`dcount`/`unique`/`avg`→`x:mean` CSV header), CSV column shape, `-g` conservation, `-mem` tracking.
- Motivating string case on the `[U: …]` user field via custom regex: `logs/ThingworxLogs/ApplicationLog.2025-05-06.0.log` (6.5 MB, 167 distinct users) or `ScriptLog.2025-05-05.0.log` (13 MB, 51 users); `count` cross-checked against `_occurrences` in a numeric-UDM STATS CSV with the same pattern.
- Default token pattern on real logs (no custom regex): `JavaException` in `logs/ThingworxLogs/ScriptLog.2025-05-05.0.log` — 19,750 `JavaException: <class>` occurrences across 4 distinct class strings (hand-verifiable distinct/ratio); CONN_MON `Local=`/`Peer=` in `logs/UDM/rea-assets-5402_-TW_SSL_READ-Read_0_bytes-trace_logs.log` for the degenerate 1-2-distinct edge.
- Validation paths: `distinct(delta)` (warn+skip), unit+distinct (unit warning), `-hg`/`-hm` on a counting UDM (rejection), duplicate names `u::count` + `u::distinct` (headers `u:count`/`u:distinct` via #99).
- Alias/canonical paths: `mean(delta)` and `x::avg` both parse; duplicate names `x::avg` + `x::max` produce headers `x:mean`/`x:max` (input written with the alias, output in canonical form).
- Rate unit: the same rate UDM under default `-ru` and `-ru s`/`-ru h` — value scales by `%rate_multiplier`, terminal suffix and CSV header suffix (`name_rate_min` vs `name_rate_sec`) follow.
- Token key: `exception_variety::distinct:JavaException` equals the same-pattern run named `JavaException` value-for-value (label-only difference); a numeric config with a token key (`latency::max:elapsed`) builds the numeric defaults from the key; key + regex together warns + skips; headers/CSV use the name (`exception_variety_distinct`), never the key.
- Folding: the sessions-oracle comparison repeated under a `-pr` mode — distinct UDM must still equal the sessions column per folded bucket. Multi-day input by passing consecutive files together: `localhost_access_log-twx01-twx-thingworx-0.2025-05-05/-06/-07.txt` (986/953/720 unique sessions; 148-277 MB each — one-off validation scale, not a per-commit harness case).
- First-ever UDM coverage in `tests/csv-output/`: the `udm-counting` scenario (all five counting aggregations on ApplicationLog `[U:]`) with `udm-counting`-family column rules in both rules TSVs. A companion `udm-numeric` scenario for the five-column numeric family was drafted and immediately caught a pre-existing #268 gap (MESSAGES-CSV numeric-UDM columns bypass `--csv-precision` formatting); per user decision it was dropped pending the fix — filed as #324. Resolved with #324: the MESSAGES emission builds the same column names as the header and routes every UDM value through `format_csv_value()`, so each value resolves to the same precision family as its column (numeric-UDM columns carry the `count` family per `resolve_csv_column_family()`); the `udm-numeric` scenario (`job_ms:ms:max:durationMS` on ScriptLog) now runs in `tests/csv-output/` with `udm-numeric`-family rules rows in both rules TSVs (the drafted scenario was never committed, so it was recreated rather than restored).
- `-g` consolidation run with counting UDMs (merge branch); `-mem` on a large log observing `%udm_distinct` size and free-after-count.
- Suites: validate-help-content (add `-udm` function-list assertion), validate-help-layout, validate-csv-output, validate-doc-examples (new usage.md example is executed), validate-regression.
- Docs in the same commit as help changes (CLAUDE.md alignment rule): `print_help()` `-udm` function list, docs/usage.md spec table + example + alias table, README.

### Risks

- **Memory**: distinct sets live for the read phase (buckets × distinct values) — same worst case as sessions; mitigated by free-after-count and `-mem` visibility. High-cardinality IDs over multi-GB files with small buckets is the stress case.
- **String leakage into numeric sites**: any missed `%udm_values` consumer produces Perl "isn't numeric" warnings — grep every consumer during implementation.
- **Consolidation merge**: unbranched `_sum` guards silently drop counting occurrences.
- **CSV shape**: single-value columns vary header shape by aggregation — harness rules must accommodate (precedent: #99 disambiguated columns).
- **Visible behavior change from `mean` canonicalization**: invocations using duplicate names with `::avg` see the collision header change from `x:avg` to `x:mean` (and the matching STATS CSV column). Input keeps working via the alias; the release notes bullet must state the header change.

### Lessons Learned

- **First harness coverage of an old surface finds latent bugs.** The very first csv-output UDM scenario draft caught a pre-existing gap unrelated to this feature (MESSAGES-CSV numeric-UDM columns bypass `--csv-precision` — #324). Budget for this when a feature brings first-ever coverage to an adjacent surface.
- **Verify test-strategy file claims against the actual files before locking them.** The strategy named a 5k access-log extract as the fast sessions-oracle input with "191 sessions"; the file has no session field at all. Caught only when the oracle produced no sessions column in Phase 3 — a one-minute `awk` field-count check at strategy-writing time would have caught it.
- **Check observability surfaces before promising oracle tests.** The highlight oracle was specced against values (`sessions-HL`, UDM `-HL`) that existed on no machine-readable surface; honoring HARNESS-DESIGN required adding the `-V udm-counting` section mid-phase (user-approved). Asking "where will the harness read this from?" per test-strategy bullet would have surfaced the need at planning time.
- **`.gitignore` blocks `*.log` repo-wide** — fixture logs under `tests/fixtures/` must use `.txt` (matching the `logs/AccessLogs/*.txt` convention).

## Future Enhancements (Out of Scope)

- ~~CSV column naming convention for UDM stats~~ — Done: consistent `name[_unit]_stat` lowercase pattern across both STATS and MESSAGES CSVs. Unit included between name and stat when defined (e.g., `latency_ms_occurrences`), omitted when unitless (e.g., `rows_occurrences`). Count columns normalized from PascalCase to `count_stat`.
- ~~Heatmap support for UDM metrics~~ — Done: `-hm <udm_name>` uses color gradient matching the metric's bar graph column
- ~~Histogram support for UDM metrics~~ — Done: `-hg <udm_name>` renders histogram with color matching the metric's bar graph column position. Multiple UDM histograms supported side-by-side.
- Percentile statistics (requires storing individual values per bucket)
