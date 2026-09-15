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
1. `\bkey\s*[=:]\s*([^\s,;"'\])&?]+)` — matches `userId=abc123`, `[U: Administrator]`, `JavaException: SomeClass`, `?userid=42&fileName=…`, capturing the token up to whitespace or a field delimiter (`]` and `)` excluded, `&` and `?` end it, `%` and `|` do not).

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
| Latency stats suppression | `$durations_observed` only set when a duration value is observed | Prevents empty or fabricated-zero P50/P95/P99/P999 columns when the source carries no durations (bytes/count alone do not activate latency surfaces; issue #345) |
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

- **Specs differing only in extraction cannot share a name**: two `-udm` flags with one name, one function field and one unit, differing only in the token key or the regex they extract with, have no readable way to be told apart in a column header. The later spec is refused at parse time with a warning naming both and `rejected=duplicate_metric_identity` on `-V udm-specs`; give them different names. Specs differing in aggregation, transform or unit are separate metrics and need no workaround — see § *Colliding metric names become separate metrics (Issue #482)*.

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
- ~~Same metric name with different aggregation functions~~ — Resolved (#99, extended by #482: two `-udm` specs with the same name and aggregation but different transforms collapse into one column): specs sharing a name are separated, each name carrying the fields that differ within the group — the function field then the unit field (e.g. `request_size:min`, `request_size:mean`, `request_size:max`; `rows:sum` and `rows:delta`; `rows` and `rows:s`). The columnar path resolves names through the same rule as the line-oriented path

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
| Default pattern for counting configs | Token capture, form-1 only: `\bkey\s*[=:]\s*([^\s,;"'\])&?]+)` — `]` and `)` excluded from the token; `&` and `?` end it (revised 2026-09-15, § *Query-string separators end a counted value (Issue #574)*); `key` is the token key when given, else the metric name | The numeric default patterns can never match `userId=abc123`; the reversed form-2 pattern is too greedy for arbitrary tokens; excluding `]`/`)` keeps bracket-delimited fields clean (ThingWorx `[U: Administrator]` yields `Administrator`, not `Administrator]`) |
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
- Docs in the same commit as help changes (CLAUDE.md § Before writing or changing code): `print_help()` `-udm` function list, docs/usage.md spec table + example + alias table, README.

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

## Diagnostics and `-V udm-specs` (Issues #443, #449)

### Status
- **Issues**: #443 (user-defined metrics fail silently), #449 (`-V` surface for user-defined metrics — folded into #443, delivered together, closes with it)
- **Branch**: `443-user-defined-metrics-fail-silently`
- **Target release**: v0.18.0
- **Phase**: Implemented 2026-08-28 (S1–S6 landed, completion gate passed).

### Problem

A `-udm` specification that produces nothing says nothing. A regex written into the fourth field without `/…/` delimiters is, by the grammar, a token key — escaped character-for-character into a pattern that can never match; a delimited regex with no capture group leaves `$1` undefined at the extraction site and is dropped; a correct regex aimed at text absent from the file matches nothing. All three produce an empty column and no message, and so does the case that is not a mistake at all: the field genuinely never appears.

### How the parser reads a spec (established from the code, 2026-08-28)

The documented grammar `name[:unit[:function]][:key|:/regex/]` reads as if the regex has a fixed fourth slot. The parser does not work that way: `parse_udm_configs()` first looks for `:/…/` at the **end** of the argument, wherever it sits, removes it and compiles it, and only then splits the remainder on `:` into name, unit, function, key. So `rows:/(\d+) rows/`, `rows::/…/` and `rows:::/…/` all read identically (the first is the example in `docs/usage.md`). A fourth field without slashes is always a token key, matched literally after `quotemeta`. "Regex in the wrong slot" is therefore not a defect class; the only regex-shaped mistake is missing delimiters.

### Locked decisions (architect, 2026-08-28)

| ID | Decision | Rationale |
|---|---|---|
| D1 — the grammar does not change | An undelimited fourth field stays a token key. The mistake is diagnosed, never silently reinterpreted as a regex. | Reinterpreting would change the meaning of specs that are correct today (a literal key that happens to contain `.`), and a spec the tool silently rewrote is worse than one it explains. |
| D2 — whole match when no capture group | A slash-delimited regex is an explicit declaration of the regex form. With a capture group, its text is the value; without one, the whole matched text is. Works for every aggregation including `distinct`, since the match varies line to line. | The group is a narrowing device, not a requirement; the tool does not second-guess an explicit declaration. |
| D3 — the run never stops | Every diagnostic — parse-time defect or end-of-run notice — is spoken and the run continues. Parse-time defects keep the existing disposition: warn immediately, skip that metric. | A `-udm` is a selector aimed at a metric with no certainty it exists in the input: across a folder of twenty files the field may be in one of them. Stopping early would discard the analysis the user came for. |
| D4 — three diagnostic tiers | (a) **Hard defects provable from the spec alone** are spoken at parse time, before any file is read. (b) **Strong intent hints** are spoken only inside the end-of-run zero-match notice, never at parse time — the user may have it right. (c) **Speculative guesses** are never shown. | A user should not read a multi-gigabyte log to learn something knowable in the first millisecond; but a hint carries the tool's authority, and a spec that then matched needs no hint. |
| D5 — parse-time hard defects | Added to the existing set (invalid regex, missing name, key + regex both given, counting aggregation wrapped around a transform, unknown function): **(i)** a function or transform name in the unit slot (`name:distinct:…`, `name:max`, `name:delta`) — the message names the fix, `did you mean 'name::distinct'?`; **(ii)** a slash-delimited pattern with no metacharacters and no capture group under `distinct`/`ratio`/`drate` — the whole match is a constant, so distinct can only ever be 1. Both: warn + skip, per D3. | Today (i) is "Unknown unit 'distinct', treating as raw number" and the metric runs with the wrong meaning. Both checks are exact, not heuristic. |
| D6 — the one strong-intent hint | A token key containing regex characters (`\ ( ) [ ] * + ? ^ $ \|`) earns, in the zero-match notice only: *the token key is matched literally — if you meant a regex, wrap it in slashes: `/…/`*. No other hint rules exist; the tier is this single rule until another exact one is agreed. | The token key is passed through `quotemeta`, so those characters can only be literal; a backslash or capture group in a literal key is near-certainly an undelimited regex. |
| D7 — no new counters, nothing on the hot path | The run-wide "what did each metric produce" state is **derived after the read loop by one walk over `%log_analysis`**, folding the per-bucket accumulators that already exist (`udm_<name>_occurrences`, `_sum`, `_min`, `_max`, their `-HL` twins, `_distinct` for counting metrics once counted). The walk runs only when something reads it: the zero-match check or `-V udm-specs`. A run-wide distinct is not derivable (the value sets are freed after counting) and is not fabricated; counting metrics report occurrences and the largest per-bucket distinct. | A per-line counter — even one gated on "is the surface active" — is a hot-path cost paid on every run for a surface most runs never read; #418 D4 (derive from existing accumulators rather than add per-line work) already measured and rejected that shape. Same reasoning, same conclusion. |
| D8 — one notice line for every case | The zero-match notice fires per metric whose derived occurrences are 0 across all buckets, with a single first line for every case: `no metrics produced from matching lines`. Under `delta`/`idelta` a metric that matched only its first line (no previous value) or only counter resets accumulates nothing and reads as zero — the wording is accurate for that case too, and no second variant is introduced for it. | Two wordings for an edge case (delta with a single match) is not worth the surface. The one line is true in every case D7 can produce. |
| D9 — notice shape | Printed after the read loop, before the chart (the position #418's post-walk sort notice uses). Lines: `Note: -udm '<spec>': no metrics produced from matching lines`; `read as: name=… unit=… aggregation=… transform=… extraction=<name|token key '…'|regex> matched against the whole line`; `pattern: <compiled source>`; and `hint: …` only when D6 fires. No file count, no input-source detail — the notice is about the spec. | The `read as:` and `pattern:` lines are printed from the config entry the parser built — the same data the extraction loop reads — never from a second reading of the spec (one resolution surface per vocabulary). |
| D10 — `-V udm-specs` is a new section | Sibling of `udm-counting` (which stays per-bucket *results*): per-spec resolution and the derived run-wide production, present on every run whether or not anything matched. Section contract below; harness `tests/validate-udm-specs.sh`. | The developer-validation purpose: what was interpreted and what the run produced, inspectable regardless of outcome. Extending `udm-counting` would mix per-bucket results with per-spec resolution. |
| D11 — producers registered on #412 | Every notice this issue introduces is registered on #412 (notices surface) as an ad-hoc producer to migrate, in the same table shape #418 used (producing sub, when it fires, text shape). | #412 is not in 0.18.0; the inventory it needs must not be reconstructed later. |
| D12 — documented match target | `--help` and `docs/usage.md` state, in the same commit: the pattern matches the whole raw log line; the capture group is optional (D2); the `/regex/` is recognised by its slashes at the end of the spec so `rows:/…/` and `rows:::/…/` read the same; an undelimited fourth field is always a literal token key; the unit slot is left empty when there is no unit (`name::max`). | Both surfaces are silent on the match target today, and the reported use case depends on it. |

### `-V udm-specs` section-contract

Emitted after the read loop (it reads the D7 walk). One block per `-udm` argument, in command-line order, including arguments rejected at parse time.

```
=== udm-specs ===
udm: name=<name> spec='<raw argument>'
  read_as: unit=<unit|none>(<time|bytes|number|raw>) aggregation=<agg> transform=<delta|idelta|none> extraction=<name|token_key|regex> key='<key>' source=<line|csv:<column>>
  pattern[<i>]: <compiled pattern source, one line per pattern>
  produced: occurrences=<N> buckets=<N> sum=<v> min=<v> max=<v>           # numeric metrics
  produced: occurrences=<N> buckets=<N> distinct_max=<N>                  # counting metrics
  hint: token_key_has_regex_chars                                         # only when D6 fires
udm: spec='<raw argument>' rejected=<reason-token>                        # parse-time skip (D5 and the existing checks)
=== END udm-specs ===
```

| key | meaning |
|---|---|
| `name` | the resolved metric name; on a duplicate-name collision it carries the fields that differ within the colliding group, the function field then the unit field, each as the spec carries it (the naming rule of #482 — two `-udm` specs with the same name and aggregation but different transforms collapse into one column) |
| `spec` | the argument as given, unmodified |
| `read_as` | every field of the interpretation the extraction loop acts on: unit and its type, aggregation, transform, extraction method (`name` = default patterns built from the name; `token_key` = built from the fourth field; `regex` = the delimited pattern), the key those patterns were built from, and the source (`line`, or `csv:<column>` when the file is columnar and the metric is bound to a column) |
| `pattern[i]` | the source of each compiled pattern, in scan order — as compiled, not as typed |
| `produced` | the D7 fold over all buckets: `occurrences` summed, `buckets` = number of buckets with occurrences > 0, `sum` summed, `min` = min of bucket mins, `max` = max of bucket maxes; counting metrics carry `distinct_max` = the largest per-bucket distinct instead of sum/min/max. `occurrences=0` is exactly the condition that fires the D8 notice |
| `hint` | the token of the D6 rule that fired; absent otherwise |
| `rejected` | the parse-time check that skipped the spec: `invalid_regex`, `missing_name`, `key_and_regex`, `counting_with_transform`, `unknown_function`, `unit_slot_holds_function`, `literal_pattern_under_distinct`, `duplicate_metric_identity` (the spec's resolved name is already claimed — it differs from an earlier spec only in what it extracts, or repeats it byte for byte) |

Stability: keys above are the contract; additions are non-breaking, renames and removals follow HARNESS-DESIGN. Consumer: `tests/validate-udm-specs.sh`.

### Notice producers registered on #412

| producer (`ltl`) | when | text shape |
|---|---|---|
| `emit_udm_zero_match_notices()` (post-walk) | after the read loop, one per metric with derived occurrences 0 | `Note: -udm '<spec>': no metrics produced from matching lines` + `read as:` + `pattern:` (+ `hint:` per D6) |
| `parse_udm_configs()` | option parsing — D5 (i) and (ii) | `Warning: … in -udm '<spec>' … skipping` (existing warn-and-skip shape) |

### Implementation plan (approved 2026-08-28)

- [x] **S1 — Parser.** D5 checks in `parse_udm_configs()`; the config entry carries `raw_arg`, `extraction` (`name|token_key|regex`), and `hint` (D6 evaluated at parse, spoken only per D4(b)); rejected specs recorded (spec + reason token) for `-V`.
- [x] **S2 — Extraction site.** D2: value = `$1` when defined, else the whole match (`substr($_, $-[0], $+[0] - $-[0])`).
- [x] **S3 — Post-walk derivation and notice.** One walk over `%log_analysis` producing the per-metric `produced` row (D7); `emit_udm_zero_match_notices()` (D8/D9) at the post-walk notice position.
- [x] **S4 — `-V udm-specs`.** Section registry entry, `@verbose_section_order`, `emit_udm_specs_verbose()` reading S1 + S3 state; HARNESS-DESIGN reserved-names entry.
- [x] **S5 — Docs.** D12 on `print_help()` and `docs/usage.md` in one commit; the spec-grammar line stays, with the end-anchored reading stated beneath it.
- [x] **S6 — Tests.** `tests/validate-udm-specs.sh` (43 assertions, each proven to fail under sabotage: whole-match reverted, hint disabled) on the crafted fixture `tests/fixtures/udm-specs.txt` at `-bs 1440 -oe`: undelimited regex-shaped key (notice + hint, `occurrences=0`); delimited regex with no capture group (`distinct`=2, no notice); well-formed regex absent from the file (notice, no hint); function in the unit slot (warning, `rejected=unit_slot_holds_function`, no column); literal pattern under `distinct` (rejected); `delta` with a single match (notice, no hint); positive control cross-checked against STATS CSV totals; runtime-warning cleanliness.
- [x] **Completion gate** (2026-08-28, version restored to `0.18.0`) — all 27 `tests/validate-*.sh` exit 0 with assertions confirmed; `single-day-access-log-standard` before (pre-change `release/0.18.0` worktree) vs after on the same machine: total 9.8 s → 9.7 s (−0.6 %), peak RSS +0.3 %, nothing worse than 5 %. That case runs no `-udm`, so the changed extraction line was measured directly: `-udm 'b::max:/HTTP\/1.1" \d+ (\d+) /'` on the 148 MB access log, 3 runs each — `parse/read_files` median before 12.82 s (12.77–12.94), after 12.80 s (12.76–13.04): inside the run-to-run noise. The per-feature gate rule in CLAUDE.md was corrected on this branch (before/after on the same machine, never against a released baseline).

## Colliding metric names become separate metrics (Issue #482)

### Status
- **Issue**: #482 (two `-udm` specs with the same name and aggregation but different transforms collapse into one column)
- **Branch**: `482-two-udm-specs-with-the-same-name-and-aggregation-but-different-transforms-collapse-into-one-column`
- **Target release**: v0.18.x
- **Phase**: Implemented. Every assertable acceptance criterion asserts in
  `tests/validate-udm-specs.sh` (118 assertions over 18 scenarios, the 12 new
  collision scenarios each proven to fail under sabotage of the naming rule,
  the duplicate drop and the identity refusal). Completion gate outstanding.

### Motivating consumer

Someone reading a log that carries a monotonic counter wants two views of the
same field at once: the running total per bucket and the per-line increment.
`-udm rows -udm rows::delta` is how that is written, and it is the natural
reading of the spec grammar: one field, two questions. The same shape is the
whole point of asking for a raw value and a converted one (`-udm rows -udm
rows:s`), or a field read two ways (one spec by token key, one by regex).

Today none of those work, and the tool says nothing. The user gets one column,
under a header they recognise, carrying a number that belongs to neither
question. The worst of these cases exits with a Perl runtime error and no
output at all.

Further out, the derived-metrics phase of the format-registry refactor
(#61, Phase 4 of Issue #23: derived metrics, intra-line and inter-line) needs
metrics to be distinct definitions carried under user labels. § *Relationship
to Issue #23* names this implementation as that architecture's proving ground.
Two definitions that silently merge because their labels match is the shape
that phase cannot inherit.

### Requirement

Two `-udm` specs that differ in any of aggregation, transform or unit are two
metrics: separate accumulators, separate columns, separate CSV columns,
separate export keys, and resolved names that say what differs. Two specs whose
resolved names would still be equal are refused at parse time with a message
naming both and asking for distinct names. Two byte-identical `-udm` arguments
are one metric; the duplicate is dropped with a notice.

### Corrections to the issue body

Every factual claim the issue makes verified true on `release/0.18.1`, not only
the `release/0.18.0` it was observed on: nothing in the 0.18.1 range touched
the duplicate-name block in `parse_udm_configs()`. The corrections are
omissions, not errors.

1. The issue calls the two `produced:` rows "identical". They are, but the row
   is a **mixture** of both specs rather than a copy of either: on the
   four-line fixture below, `-udm rows -udm rows::delta` reports
   `occurrences=8 sum=200 min=10 max=40`, where `min=10` is the raw spec's
   first value and `max=40` is the delta spec's largest increment. Neither
   correct answer, 200 over 4 occurrences and 90 over 3, is recoverable.
2. The issue's *Expected* names unit, aggregation and transform as the
   discriminating dimensions and **omits extraction**. Two specs with one name,
   one aggregation and different regexes also collide, and the failure is worse
   than doubling: the `rows` column is **replaced** by whatever the other
   spec's regex captures, so the user reads a plausible number under the header
   they chose.
3. The issue does not mention that **the tool can crash**. Two `rows::ratio`
   specs on one name exit 255 with `Illegal division by zero` and produce no
   output, on the line-oriented path and on the `-ucm` CSV columnar path alike.
4. The issue frames the defect as "two specs that differ in transform". Two
   **byte-identical** specs also collide, and that is the minimal reproducer
   for the crash; nothing deduplicates the raw `-udm` argument list.
5. The defect is already recorded in this file, which the issue does not
   mention. § *Known Issues*, entry "Same metric name with different functions
   is not supported", names `%udm_values` and `%udm_last_value` as the shared
   structures. **That entry is now false for half of what it claims**: its
   example `-udm "x::sum" -udm "x::max"` works correctly today, and § *CSV
   Columnar Input* → *Limitations* says so seventy lines later. Both are trued
   up in the same commit as the fix.
6. The `:aggregation` collision suffix is **undocumented**. The words
   `collision`, `disambigu` and `duplicate name` appear nowhere in
   `docs/usage.md`, and `print_help()`'s `-udm` block is silent on it, yet
   users see `rows:sum` in their column headers and their CSV columns.

### The six collision classes, measured

Measured on a four-line synthetic access log with `rows=` values 10, 30, 60 and
100 in one bucket, at `-bs 1440 -ni -oe`, read from `-V udm-specs`. Correct
answers hand-computed: raw is 200 over 4 occurrences, 10..100; delta is 90 over
3 occurrences (the first occurrence seeds the state), 20..40.

| Input | What the tool does | Correct answer |
|---|---|---|
| `-udm rows -udm rows::delta` | both blocks report `name=rows:sum`, `occurrences=8 sum=200 min=10 max=40`, empty stderr | 200 over 4, and 90 over 3 |
| `-udm rows -udm rows:s` (unit differs) | both report `sum=400000 min=10000 max=100000`, the time-unit spec's converted values; the unitless metric is unobtainable | 200 and 200000 |
| `-udm rows -udm 'rows::sum:/ 200 (\d+) /'` (extraction differs) | both report the other spec's field under the `rows` header; the metric is substituted, not doubled | 200 over 4, and the second field's own total |
| `-udm rows::delta -udm rows::idelta` | both report `sum=0 min=0 max=0`, a fabricated zero | 90 each |
| `-udm rows -udm rows::delta -udm rows::idelta` | **all three** report `sum=0 occurrences=12`, including the plain `-udm rows` that carries no transform and is entirely well-formed | 200, 90, 90 |
| `-udm 'rows::ratio' -udm 'rows::ratio'` (byte-identical) | **`Illegal division by zero`, exit 255, no output** | one ratio metric |

The zeros come from two independent mechanisms, not one. The delta cases are
the shared delta state: two configs on one name consume and overwrite each
other's stored previous value within the same line, so every delta computes
value minus value. The `distinct`/`ratio`/`drate` cases are a different break,
in `calculate_all_statistics()`, where each bucket's distinct set is freed
immediately after the first colliding config counts it and the second reads
zero. The comment above the crash site states the invariant it relies on,
"occurrences > 0 implies distinct >= 1, so the divisions are safe", and a name
collision is exactly what breaks it. Per CLAUDE.md ("Any ` at <file> line <N>`
on `ltl`'s stderr is a bug"), that class is an availability defect.

### What is safe today: the boundary any fix must not regress

A same-name pair survives intact exactly when its aggregations differ.
Measured on the same fixture: `-udm rows::sum -udm rows::max` resolves to
`rows:sum` and `rows:max`, each with `occurrences=4`; `-udm rows::count -udm
rows::distinct` resolves to `rows:count` and `rows:distinct`, each with
`occurrences=4 distinct_max=4`; `x::avg` plus `x::max` on one regex resolves to
`x:mean` and `x:max`. #99 (same UDM name with different aggregation functions
showed duplicate values) is genuinely fixed for its own case. That one-line
rule is written nowhere in the tree, which is why it is enumerated in the
acceptance criteria below.

### Mechanism today

**One block decides the name.** In `parse_udm_configs()`, after the whole
argument list is parsed:

```perl
    my %name_counts;
    $name_counts{$_->{name}}++ for @udm_configs;
    for my $config (@udm_configs) {
        if ($name_counts{$config->{name}} > 1) {
            $config->{name} = "$config->{base_name}:$config->{aggregation}";
        }
    }
```

Three properties are the root cause. The suffix is built from `aggregation`
alone, while `transform`, `unit`, `token_key` and the compiled patterns are all
on the config hash at that point and none is consulted. The loop counts raw
names once and never re-checks whether the suffixed names still collide, so it
does not iterate to a fixed point. And a surviving collision produces no
warning and no rejected-spec entry, so it reaches `-V udm-specs` as two blocks
that merely happen to print the same `name=`.

The reported case collides because of the shorthand recorded in § *Combining
transforms and aggregations*: `delta` is `sum(delta)`, so both specs carry
`aggregation = sum`.

**The name is the identity everywhere.** The resolved `name` keys the per-line
extracted value, the delta state, the per-bucket distinct sets, the
`udm_<name>_*` accumulator keys in `%log_analysis` and `%log_messages`, the
promoted values in `%log_stats`, the `@column_layout` column id, both CSV
column names, and the YAML aggregate-export key. One identity means one set of
structures, so specs the parser distinguished perfectly well then share
everything, and the per-config accumulation loop counts the single surviving
per-line value once per config, which is where the doubled occurrences come
from.

**The freed distinct set.** In `calculate_all_statistics()`, each bucket's
distinct sets are deleted immediately after counting, mirroring the sessions
column's free-after-count lifecycle recorded in § *Counting Aggregations*.
Under a collision the second config counts an already-freed set.

**The shared delta state.** The per-line transform block reads and writes the
previous value under the resolved name, and is reset per file. Two transform
configs on one name therefore corrupt each other within every line.

**Surfaces that consume it.** `resolve_metric_operand()`, the single `-hm` and
`-hg` operand surface, takes the first match with no ambiguity diagnostic, and
`available_metric_names()` returns the duplicate, so the unknown-metric error
lists a name twice. `add_dynamic_column()` splices with no duplicate-id guard,
so two columns carry one id and every `grep { $_->{id} eq ... }` takes the
first. `write_aggregate_export()` assigns into a hash keyed by name, so the
second config overwrites the first: it is the only surface that **loses** a
metric rather than duplicating it.

### Decisions (architect, locked)

| ID | Decision | Rationale |
|---|---|---|
| D1 — colliding specs are separated, not merged and not refused wholesale | Specs that differ in a named dimension become distinct metrics with distinct accumulators and distinct columns. Merge-with-a-notice is ruled out. | A notice does not fix anything. The three-way case zeroes a well-formed spec that carries no transform at all, and the counting cases fabricate a zero through freed state, so a user can lose a metric they wrote correctly while the tool prints a plausible number. Reporting a wrong answer loudly is still a wrong answer. The derived-metrics phase of the registry refactor (#61, Phase 4 of #23) needs metrics to be distinct definitions under user labels, and this implementation is its proving ground. |
| D2 — identity stays the resolved display name | No separate internal identity is introduced. No store changes its key shape. No prototype. | The histogram and heatmap operands, the CSV columns and the export keys must stay simple and typed-as-seen. The collisions that cannot be named are refused under D4, so every accepted spec has a unique resolved name, which can therefore remain the identity everywhere. |
| D3 — the naming rule extends the shipped #99 rule | When specs share a name, the resolved name gains the dimensions that **differ within the colliding group**, function field first then unit field. Each is appended after a colon, spelled from the spec's own field verbatim, so a field the spec does not carry adds nothing. Only differing dimensions are appended, so a spec's resolved name depends on what else is on the command line, as it already does today. Full rule and worked examples below. | #99's shape is shipped, asserted and documented in user-visible output; extending it costs no new concept. Appending only what differs keeps the shortest readable name and leaves every non-colliding spec's header exactly as the user wrote it, which is what the #313 locked decision on column headers ("header = user-chosen name; `:agg` suffix only on duplicate-name collision") protects. |
| D4 — extraction collisions are refused at parse time | Specs differing only in extraction (token key or regex) whose resolved names would still be equal are refused: the later spec is skipped with a warning naming both specs and asking for distinct names, recorded as a new reason token on `-V udm-specs`. | There is no readable way to put a regex into a column header, so a name-based suffix cannot express the dimension at all. Refusing is the honest answer: the user is told exactly what to change and the fix is one word on their command line. Shape follows D3 of #443 (every diagnostic is spoken and the run continues; parse-time defects warn and skip that metric). |
| D5 — byte-identical arguments drop the duplicate | Two identical `-udm` arguments produce one metric; the second is dropped with a behavioural notice that always prints. | Silent dropping hides a typo the user probably wants to know about, and letting it fall through is what produces the crash. No naming rule can ever separate two identical specs, so this needs its own answer. Per CLAUDE.md, behavioural notices always print; `--disable-progress` suppresses progress indicators only. |
| D6 — the unit discriminates | Unit is a named dimension in D3's rule, so `-udm rows -udm rows:s` produces two metrics named `rows` and `rows:s`: the unitless spec keeps its bare name and only the spec carrying a unit gains a suffix. | The issue's *Expected* names unit explicitly, and both specs produce real, different numbers. Today the unitless metric is simply unobtainable. |
| D7 — one issue, one change | The refusal (D4) and the duplicate drop (D5) stop the crash and the fabricated zeros as part of the same change as the separation (D1). No split into a stop-the-bleeding issue plus a follow-up. | Under D2 the separation is not a data-model change and needs no prototype, so the argument for splitting (a small fix now, an expensive one later) does not apply. Splitting would also create a user-visible flip-flop: a pair refused in one patch release and working in the next. |
| D8 — CSV column naming follows the resolved name | The disambiguated STATS and MESSAGES CSV column is the resolved name verbatim, as it is today, with the unit appended by the existing rule. See § *CSV column naming* below for the exact placement and what changes for the existing assertion. | The shipped behaviour at all five sites is "the resolved name is the column", and D3 keeps the resolved name unique, so the column stays unique without a second naming scheme. |
| D9 — the five CSV-naming sites converge onto one sub | `write_aggregate_export()`, `normalize_data_for_output()`, `print_bar_graph()`, `print_message_summary()` and `pipeline_render()` each re-derive the CSV column name from `base_name` and `aggregation` with their own copy of the counting / #99 / default three-way branch. They converge onto one resolution sub in the same change. | CLAUDE.md: one resolution surface per vocabulary, near-duplicates converged in the same change. The five must all change together anyway if the resolved-name shape moves, so converging them is the only safe way to change them. |
| D10 — the safe boundary is enumerated as acceptance criteria | The same-name pairs that work correctly today keep their resolved names and their figures, stated as criteria rather than left to be derived from the code. | `docs/test-driven-development.md` requires criteria agreed in the feature doc before code, and this is the one sentence the whole fix pivots on: without it a fix cannot be proven not to regress #99 while closing the transform, unit and extraction cases. |
| D11 — the assertions cover every surface that is wrong today | `-V udm-specs`, the STATS CSV header, the YAML aggregate export, the rendered `-hg` distribution and its percentiles, the `-hm` axis range, the refusal and duplicate-drop notices, and exit status on the former crash. A new committed `.txt` fixture carries a short monotonic numeric field so a delta is exercisable. | "Covered automatically once names are unique" is exactly the claim that should be asserted rather than reasoned. The `-hg` percentiles are wrong today in a way nothing would catch, and the export is the only surface that loses a metric. |
| D12 — column-id uniqueness follows from resolved-name uniqueness; no guard | `add_dynamic_column()` splices with no duplicate-id guard. No guard is added and none is filed: the column id is the resolved name with the `udm_` prefix, the UDM registration loop is the only source of dynamic columns, and under D3 to D5 every accepted spec has a unique resolved name, so no two columns can share an id. The invariant is stated here and asserted by criterion 22. | Architect's decision (2026-09-13): a guard would defend an invariant this change establishes by construction, against a column source that does not exist. |
| D13 — the record is this section | Decisions live here, matching how the #313 counting-aggregations section and the #443/#449 diagnostics section are recorded. The false § *Known Issues* entry is rewritten and the § *CSV Columnar Input* → *Limitations* line reconciled with it, in the same commit as the fix. The undocumented collision suffix gains a `docs/usage.md` and `print_help()` sentence. | A planning record that starts from a self-contradicting doc starts wrong, and a behaviour users already see in their headers should not be undocumented. |

### The naming rule

The rule runs after every spec is parsed, over each group of specs that share a
`base_name`.

1. A `base_name` used by exactly one accepted spec keeps that name unchanged.
   Nothing in this section alters a command line with no duplicate names.
2. Within a group of two or more, compare two dimensions across the group: the
   **function field** and the **unit field**. Each is the spec's own field as
   the parser holds it. A dimension *differs* when at least two members of the
   group hold different values for it.
3. Every member's resolved name is its `base_name` followed by one
   colon-prefixed field per differing dimension, function first, then unit. A
   dimension that does not differ contributes nothing, to any member; a field
   the spec does not carry contributes nothing, so an absent unit shows
   nothing at all.
4. Each field is the spec's own value, verbatim. The function field is taken
   after the parser's alias normalisation, so `avg` reads as `mean`,
   `avg(delta)` as `mean(delta)`, and `dcount`/`unique` as `distinct`; the rule
   reads the normalised field because that is the field the config carries and
   the one already shown everywhere else in the tool's output. The unit field
   is the unit as typed. When a spec typed no function at all, the field shows
   the default `sum`, which is what makes the shipped #99 output `rows:sum`
   survive unchanged for the aggregation-only case.
5. If two members' resolved names are still equal after step 3, the specs
   differ only in extraction or are identical. Identical arguments are handled
   by D5 (drop the duplicate with a notice); anything else is refused under D4.

No spelling is invented. Every field printed into a name is one the user typed
or the documented default the tool already applies on their behalf.

**The canonical spelling of the delta shorthand.** `delta` and `sum(delta)` are
the same spec, as § *Combining transforms and aggregations* records, so the
resolved name must not depend on which the user wrote. The canonical spelling
is **the shorthand**: `sum(delta)` resolves as `delta`, and `sum(idelta)` as
`idelta`. Chosen over "as typed by the first spec that names it" because that
alternative makes one spec's name depend on the spelling used in a *different*
argument, which is the class of surprise this whole rule exists to remove; and
chosen over always expanding because the shorthand is the shorter column header
and is the form the documentation's own examples use. Every other function
field, `sum`, `max`, `mean(delta)`, `max(idelta)`, `distinct`, has exactly one
spelling after alias normalisation and needs no rule.

**Worked examples**, each the resolved name of every member of the group:

| Command line | Dimension differing | Resolved names |
|---|---|---|
| `-udm rows` | none (no group) | `rows` |
| `-udm rows::sum -udm rows::max` | function | `rows:sum`, `rows:max` (unchanged from today) |
| `-udm rows -udm rows::delta` | function (default `sum` against `delta`) | `rows:sum`, `rows:delta` |
| `-udm rows::count -udm rows::distinct` | function | `rows:count`, `rows:distinct` (unchanged) |
| `-udm x::avg -udm x::max` | function | `x:mean`, `x:max` (unchanged; `avg` normalises to `mean`) |
| `-udm 'rows::mean(delta)' -udm rows::delta` | function | `rows:mean(delta)`, `rows:delta` |
| `-udm rows::delta -udm rows::idelta` | function | `rows:delta`, `rows:idelta` |
| `-udm rows -udm rows::delta -udm rows::idelta` | function | `rows:sum`, `rows:delta`, `rows:idelta` |
| `-udm rows -udm rows:s` | unit | `rows`, `rows:s` |
| `-udm rows:s -udm rows:ms` | unit | `rows:s`, `rows:ms` |
| `-udm rows -udm rows:s:delta` | function and unit | `rows:sum`, `rows:delta:s` |
| `-udm 'rows::mean(delta)' -udm rows::delta -udm rows:s` | function and unit | `rows:mean(delta)`, `rows:delta`, `rows:sum:s` |
| `-udm rows -udm 'rows:/(\d+) rows/'` | neither | refused (D4): both would resolve to `rows` |
| `-udm 'rows::ratio' -udm 'rows::ratio'` | identical arguments | one metric `rows`, duplicate dropped with a notice (D5) |

Two rows repay a second look. In `-udm rows -udm rows:s` the unit differs and
the function does not, so the unitless spec's name is the bare `rows`: an
absent field shows nothing, and the spec that carries a unit is the only one
that gains a suffix. In `-udm rows -udm rows:s:delta` both dimensions differ,
so the function field appears on both members even though only one carries a
unit, and the member without one shows no unit segment.

**Names are unique within a group.** Two members resolve to the same name only
when they agree on every field the rule prints, which is every dimension that
differs; agreeing on all of those means the group did not differ in them at
all, so the pair differs only in extraction and is refused or dropped by step
5. **And across groups.** A group is keyed by `base_name`, which the parser
takes as the first colon-delimited field of the argument and which therefore
can never itself contain a colon. A suffixed name always contains a colon and a
bare name never does, so a bare `rows` can only equal another bare name whose
base name is also `rows`, which is the same group. The unit-differs case that
leaves one member bare is safe for that reason.

### CSV column naming

The shipped rule at all five sites is that a **disambiguated** metric emits one
value column named from the resolved name, with the unit appended by the
existing `name[_unit]_stat` family rule, while a metric that was not
disambiguated emits the five-column `occurrences/min/mean/max/sum` family. Read
from a run of `-udm rows -udm rows::delta`, the STATS CSV header today carries
the resolved name **verbatim, colon included**, twice: `rows:sum`, `rows:sum`.
The MESSAGES CSV does the same.

Under D3 the resolved name is unique, so the existing rule produces unique
columns with no second naming scheme: `rows:sum` and `rows:delta`,
`rows:mean(delta)` and `rows:delta`, `rows` and `rows:s`. The function field
therefore appears in the CSV column exactly where it appears in the resolved
name, before the unit, which is the placement the `name[_unit]_stat` pattern
already implies: name parts first, unit last, stat last of all (here the
function is the stat and is carried inside the resolved name).

The lowercase counting pattern `{base_name}_{agg}` is untouched: counting
metrics take their own branch before the disambiguation branch is reached, and
D3 changes nothing about a counting group whose members differ in aggregation.

**What changes for the existing assertion.** `tests/validate-udm-counting.sh`
scenario `alias-canonical` asserts that `-udm 'x::avg:/…/' -udm 'x::max:/…/'`
produces a STATS CSV column `x:mean` and never `x:avg`. That pair differs in
aggregation only, so under the rule it resolves to `x:mean` and `x:max`
exactly as today: **the assertion stands unchanged and must still pass.** It is
listed in the acceptance criteria as a regression guard for precisely that
reason.

### Surfaces touched

**`ltl`**

- `parse_udm_configs()`: the duplicate-name block above is replaced by the D3
  rule; the D4 refusal and the D5 duplicate drop are added here, both before
  the accepted-config list is finalised. The D5 drop compares the raw argument
  strings, which the config entry already carries as `raw_arg`.
- The five sites that re-derive the CSV column name and each test
  `$config->{name} ne $config->{base_name}` as "this metric was disambiguated"
  (`write_aggregate_export()`, `normalize_data_for_output()`,
  `print_bar_graph()`, `print_message_summary()`, `pipeline_render()`) are
  converged onto one resolution sub per D9. The predicate itself is still
  correct under D3 (a resolved name differs from the base name exactly when the
  spec was disambiguated), so this is convergence, not a behaviour change.
- `emit_udm_specs_verbose()`: emits the new reason token for a D4 refusal
  through the existing `rejected=` line; no new key.
- `resolve_metric_operand()` and `available_metric_names()`: no code change
  required, but their output changes: names are unique, so the first-match
  binding is unambiguous and the unknown-metric error no longer lists a
  duplicate. Asserted, not assumed.
- `print_help()`: one sentence in the `-udm` block stating the collision
  suffix (D13). Proposed wording: *When two metrics share a name, each name
  gains what tells them apart (its function, its unit), so `-udm rows
  -udm rows::delta` labels its columns `rows:sum` and `rows:delta`. Two specs
  that a name cannot tell apart are reported and one is skipped: give them
  different names.*

**`-V udm-specs` contract**

The `name` key's meaning changes from "the resolved metric name (after the #99
duplicate-name `:aggregation` suffix, if applied)" to the D3 rule: *the
resolved metric name; on a duplicate-name collision it carries the fields that
differ within the colliding group, the function field then the unit field, each
as the spec carries it.* The `rejected` enumeration gains one token,
`duplicate_metric_identity`, for the D4 refusal, alongside the seven it lists
today. Both are additions and a redefinition of an existing key's value space,
not a rename or a removal, so per `tests/HARNESS-DESIGN.md` § *Stability
contract* they are non-breaking; the section contract above and the
HARNESS-DESIGN reserved-names entry are updated in the same commit as the code,
and every affected harness is run end to end and confirmed to assert.

**Harnesses**

Nine harnesses invoke `-udm` and every one carries the runtime-warning check,
so a new stderr line would touch all of them. The D4 warning and the D5 notice
fire only on colliding specs, and none of those nine puts two specs on one
name, so none of them gains stderr. That is a claim to confirm by running them,
not to assume.

**Docs**

`docs/usage.md` § *User-Defined Metrics* gains the same sentence as
`print_help()`, in the same commit, so `tests/validate-help-content.sh` keeps
agreeing. § *Known Issues* and § *CSV Columnar Input* → *Limitations* in this
file are trued up per D13.

### Harness plan and fixture

**Fixture.** A new committed `tests/fixtures/udm-collision.txt`: a short
synthetic access log carrying a monotonic `rows=` field over several lines in
one bucket, so a delta is exercisable, plus a second field a regex can target
for the D4 extraction case. Scrubbed, TEST-NET-1 addresses (`192.0.2.0/24`),
neutral paths, no provenance. Named `.txt` because `*.log` and `*.csv` are
gitignored. The existing `tests/fixtures/udm-specs.txt` cannot serve: it has
exactly one `rows=` line and cannot exercise a delta at all.

**Ownership.** `tests/validate-udm-specs.sh` owns the whole set of new
scenarios, because every assertion is about how a spec was **resolved** and
what it **produced** per spec, which is exactly the `udm-specs` section's
contract and that harness's subject; the harness file name tracks the `-V`
section it validates. `tests/validate-udm-counting.sh` owns the aggregation
family and gains nothing new: its `alias-canonical` scenario is already the
regression guard for the aggregation-only case, and it is run and confirmed
still asserting rather than modified. The counting-collision cases
(`rows::count` with `rows::distinct`, and the two-identical-`ratio` crash case)
sit in `validate-udm-specs.sh` with the rest, so one harness carries the
collision story end to end rather than splitting it across two.

### Acceptance criteria

Each criterion is a condition and an observable outcome. Verification method in
the third column; triage in the second.

| # | Triage | Criterion | Method |
|---|---|---|---|
| 1 | assertable | With `-udm rows -udm rows::delta`, `-V udm-specs` shows two blocks with different `name=` values, `rows:sum` and `rows:delta`. | grep the `udm:` lines of the section |
| 2 | assertable | With `-udm rows -udm rows::delta`, the `produced:` rows are the two separate correct answers: the `rows:sum` block's occurrences and sum equal what `-udm rows` alone reports, and the `rows:delta` block's equal what `-udm rows::delta` alone reports. | compare `produced:` against single-spec control runs on the same fixture |
| 3 | assertable | With `-udm rows -udm rows::delta`, the STATS CSV header carries two distinct UDM columns and no repeated column name. | read the header line of the written STATS CSV |
| 4 | assertable | With `-udm rows -udm rows::delta -o`, the YAML aggregate export carries two UDM entries, not one. | count the keys under the export's `udm` mapping |
| 5 | assertable | With `-udm rows -udm rows::delta -hg rows`, two distribution panels render with different titles, and the `rows:sum` panel's P50 and P99 equal the values the single-spec `-udm rows` run reports. | compare the rendered panel titles and percentile line against the single-spec control |
| 6 | assertable | With `-udm rows -udm rows::delta -hm rows`, the heatmap axis range equals the range the single-spec `-hm rows` run shows. | compare the rendered axis end values against the single-spec control |
| 7 | assertable | `-udm rows -udm rows::delta -udm rows::idelta` produces three metrics with three distinct names, and the plain `rows` spec's sum is its own correct total, not zero. | `-V udm-specs` `produced:` rows against three single-spec controls |
| 8 | assertable | `-udm rows -udm rows:s` produces two metrics named `rows` and `rows:s`, one reporting the unconverted values and one the unit-converted values. | `-V udm-specs` `produced:` rows against two single-spec controls |
| 9 | assertable | `-udm rows -udm 'rows:/…/'` (differing only in extraction) prints a warning naming both specs and asking for distinct names, skips the later spec, and `-V udm-specs` shows `rejected=duplicate_metric_identity` on it. | grep stderr and the section's `rejected=` line |
| 10 | assertable | Two byte-identical `-udm` arguments produce exactly one metric and print a notice that the duplicate was dropped. | count `udm:` blocks in the section; grep stderr for the notice |
| 11 | assertable | `-udm 'rows::ratio' -udm 'rows::ratio'` exits 0 and renders output. | exit status plus a non-empty render |
| 12 | assertable | `-udm rows::delta -udm rows::idelta` produces two metrics whose sums each equal their single-spec control, neither zero. | `-V udm-specs` `produced:` against two controls |
| 13 | assertable | Safe boundary: `-udm rows::sum -udm rows::max` still resolves to `rows:sum` and `rows:max`, each with the occurrences the single-spec run reports. | `-V udm-specs` `name=` and `produced:` |
| 14 | assertable | Safe boundary: `-udm rows::count -udm rows::distinct` still resolves to `rows:count` and `rows:distinct`, each with its control's occurrences and `distinct_max`. | `-V udm-specs` `name=` and `produced:` |
| 15 | assertable | Safe boundary: the existing `alias-canonical` assertion in `tests/validate-udm-counting.sh` (`x::avg` plus `x::max` produce a STATS CSV column `x:mean` and never `x:avg`) still passes, unmodified. | run that harness and confirm the assertion fires |
| 16 | assertable | A command line with no duplicate names produces resolved names identical to the metric names as typed, with no suffix on any of them. | `-V udm-specs` `name=` on a multi-metric run with distinct names |
| 17 | assertable | Every `-udm` harness that does not put two specs on one name emits no new stderr line. | the runtime-warning check plus a stderr-empty assertion in the nine `-udm` harnesses |
| 18 | assertable | The `-ucm` CSV columnar path behaves identically: two same-name specs on a columnar input produce two metrics, and two identical `ratio` specs exit 0. | `-V udm-specs` and exit status on a columnar fixture |
| 19 | assertable | `-hm` and `-hg` naming a base name that two specs share resolve without ambiguity, and the unknown-metric error's `Available:` list contains no repeated name. | an `-hm` run with a deliberately unknown metric, reading the error line |
| 20 | assertable | The two spellings of the delta shorthand resolve identically: `-udm 'rows::sum(delta)' -udm rows::max` and `-udm rows::delta -udm rows::max` produce the same pair of resolved names, `rows:delta` and `rows:max`. | `-V udm-specs` `name=` on both runs |
| 21 | unassertable | The message masking that replaces a matched value in the message text behaves for separated metrics as it does for two metrics with different names. See § *Message masking* below: the behaviour is identical by construction once names are unique, but the masking runs per config on one message string and no surface reports which config masked what. Recorded as a known gap; the observable consequence (message grouping) is covered indirectly by criterion 3's CSV and by the TOP MESSAGES render being compared by eye on the fixture. | see below |

| 22 | assertable | On the three-way (`rows`, `rows::delta`, `rows::idelta`) and unit (`rows`, `rows:s`) cases, the rendered timeline header and the STATS CSV header each carry every UDM column once, with no repeated name. Column ids are the resolved names with the `udm_` prefix, so this is the observable form of column-id uniqueness (D12). | compare the header tokens of the render and of the written STATS CSV for repeats |
No criterion lands in the **unknown** state: every verification method above
exists today. `-V udm-specs`, the STATS CSV header, the YAML export and the
exit status are machine-readable; the `-hg` panel titles, percentile line and
`-hm` axis are compared against a single-spec control run of the same fixture,
which is a value comparison rather than a snapshot.

### Measurements taken before finalising the criteria

Three questions the investigation left open were measured on the scratch
fixture before the criteria above were written. Captures under the session
scratchpad; none written into the repository.

**Message masking and TOP MESSAGES grouping.** The per-line masking replaces
the matched value text in the message with `?`, once per config. Measured on a
four-line fixture whose retained message text carries the value
(`GET /app/items/rows=10` and so on, four distinct values), at
`-bs 1440 -ni`:

| Run | TOP MESSAGES rows |
|---|---|
| no `-udm` | four rows, one per distinct value |
| `-udm rows` | one row, `…/rows=?`, 4 occurrences |
| `-udm rows::delta` | two rows: `…/rows=?` with 3 occurrences, and `…/rows=10` with 1; the first line seeds the delta state and takes the skip branch before masking, so its value is never masked |
| `-udm rows -udm rows::delta` (colliding) | one row, `…/rows=?`, 4 occurrences |

The collision case matches the raw single-spec run, not the delta one, because
the raw config masks every line including the first. **This is not a new defect
class and adds no criterion**: masking is a property of each config's own
matched text, the two configs mask the same text here, and separating the
identities changes nothing about how many configs reach that line for one
metric name. It does show that the delta transform's skip-first-occurrence
branch leaves that line's value unmasked, which is a pre-existing behaviour of
a single delta spec and unrelated to collisions. Criterion 21 records it as the
one gap.

**The transform collision across a two-file run.** The fixture was copied to a
second day and both files passed in one invocation. Delta state resets per
file, so each file seeds its own first value. Measured: `-udm rows` alone
reports `occurrences=8 buckets=2 sum=400 min=10 max=100`; `-udm rows::delta`
alone reports `occurrences=6 buckets=2 sum=180 min=20 max=40`; the colliding
pair reports `occurrences=16 buckets=2 sum=400 min=10 max=40` on both blocks.
That is the single-file mixture scaled by the file count, with no new
behaviour. **No multi-file criterion is added**; the single-file cases in the
criteria carry the same signal at lower cost.

**The `-ucm` CSV columnar path.** A four-row columnar input with a `rows`
column, `-ucm job`. Measured: `-udm rows` alone reports `occurrences=4 sum=200
min=10 max=100` with `source=csv:rows`; `-udm rows::delta` alone reports
`occurrences=3 sum=90 min=20 max=40`; the colliding pair reports
`occurrences=8 sum=200 min=10 max=40` on both blocks, identical to the
line-oriented path; and `-udm 'rows::ratio' -udm 'rows::ratio'` exits **255**
with `Illegal division by zero`, the same crash. Although the columnar path
extracts by config position it still writes the name-keyed slot, so it collides
identically. **This adds criterion 18**: the columnar path is asserted
explicitly rather than assumed to follow, because it is a second extraction
path into the same shared structures.

### Message masking

Recorded for criterion 21. The masking substitution runs inside the per-config
extraction loop against one message string, so with two configs on one metric
name both substitute into the same string in command-line order. Once names are
unique the two configs are two metrics and the behaviour is exactly that of two
specs with different names, which is the shipped and intended behaviour. No
surface reports which config masked what, so the claim is verified by comparing
the rendered TOP MESSAGES on the fixture rather than asserted mechanically.

### Prototype triggers

None fires. Per `prototype/README.md`:

- **(a) new or changed data model**: does not fire under D2. No store changes
  its key shape: `%log_analysis`, `%log_messages`, `%log_stats` and the
  per-bucket distinct sets keep keying on the resolved name exactly as today.
  What changes is which strings that name takes, which the shipped #99 suffix
  already changes.
- **(b) new per-line hot-path cost**: does not fire. The whole rule runs once
  in `parse_udm_configs()`, before any file is read, and writes the resolved
  name onto the config hash exactly as today. The per-line extraction and
  accumulation loops read `$config->{name}` unchanged. This is what D7 of
  #443 (no new counters, nothing on the hot path) requires, and the completion
  gate's before/after benchmark is the confirmation.
- **(c) frequency times cost**: does not fire; it is the same question as (b)
  and answered with it.
- **(d) unknown verification method**: does not fire. Every criterion above is
  assertable today from `-V udm-specs`, the STATS CSV header, the YAML
  aggregate export, the rendered output compared against a single-spec control,
  or the exit status. The one criterion that is not assertable is recorded as a
  known gap with its reason, which is the triage's *unassertable* state, not
  *unknown*.

### Completion gate scope

Executable `ltl` lines change, so per `docs/process/workflow.md` § 3 the scope
is the **full harness suite plus a before/after benchmark on this machine**,
with `$version_number` restored before the gate runs and the gate run on the
commit being merged.

The behaviour this change could have altered: every `-udm` run's resolved
names, both CSV surfaces, the YAML export, the rendered columns and the two
`-V` sections. The hot path is expected **unchanged**: names resolve once at
parse time and the per-line loops are untouched, so the benchmark is expected
to show no movement beyond run-to-run noise. That expectation is the reason to
run it, not a reason to skip it.

### Release note

Under Bug Fixes:

- Two `-udm` metrics that share a name are no longer merged into one column.
  Specs differing in aggregation, transform or unit each get their own column,
  with the name carrying what tells them apart (`rows:sum` and `rows:delta`);
  specs a name cannot tell apart are reported and one is skipped, and a
  repeated identical spec is dropped with a notice. Previously such a pair
  produced one column whose numbers belonged to neither metric, could report
  zero for both, or could end the run with an error and no output. (#482)

### Ordering

**#478 (highlight bookkeeping is evaluated on the hot path when no highlight is
active and when the metric is absent)** edits the same per-line UDM
accumulation block in `read_and_process_logs()`. There is **no ordering
requirement in either direction** and no `blocked_by` edge: this change does
not touch that block, and #478 does not touch naming. The two will conflict
**textually** if both are in flight, and whichever lands second rebases onto
the first.

No other issue in the next-up set names anything in this change's blast radius.

### Findings from implementation

**The worked example `-udm rows -udm rows:s::delta` was written with one colon
too many, and the error is in this document, not in the tool.** The spec
grammar is `name[:unit[:function]][:key|:/regex/]`, so when a unit is present
the function is the *third* field: `rows:s:delta`. Written as `rows:s::delta`,
the empty third field means no function and `delta` lands in the fourth slot,
where it is read as a token key and matched literally. Measured on
`release/0.18.1` before any change on this branch and on the finished code,
both report `unit=s(time) aggregation=sum transform=none extraction=token_key
key='delta'`: identical, so this is the shipped parse of that spelling and not
a regression. Corrected to `rows:s:delta` in the worked-examples table, which
resolves to `rows:sum` and `rows:delta:s` as the table intends, and is what the
`collision-unit` and naming scenarios exercise.

**The duplicate drop and the identity refusal overlap, and the overlap is
wanted.** Two byte-identical arguments are caught by the drop; if only the drop
is disabled they are still caught by the refusal, because identical arguments
resolve to one name. Verified by sabotage: disabling the drop alone leaves the
former `Illegal division by zero` fixed (the refusal removes the second
config), and only disabling both reproduces exit 255. Each mechanism is
asserted on what is its own to prove — the drop on its notice and the single
surviving metric, the refusal on its warning and its `rejected=` token — and
the exit-0 assertions bite when both are gone.

**The five CSV-naming sites converged onto `udm_csv_columns()` (D9).** It
answers both questions the sites shared: the emission shape (`single` for one
value column, `family` for the five-column occurrences/min/mean/max/sum set)
and the column spelling, with `stats` naming the accumulator each column reads
positionally so a header and the row beneath it are built from one list. The
counting column keeps `{base_name}_{aggregation}` with the rate-unit suffix
exactly as shipped — no `lc()` was introduced, since the shipped sites do not
lowercase and adding it would change the column of a capitalised metric name.

### Findings forwarded

- **`add_dynamic_column()` has no duplicate-id guard, and none is wanted.**
  Column-id uniqueness is an invariant of `@column_layout` that this change
  establishes by construction (D12) and asserts (criterion 22). A future
  dynamic column source other than the UDM registration loop would have to
  keep it.

## Query-string separators end a counted value (Issue #574)

### Status
- **Issue**: #574 (a distinct-count metric on a query-string key counts the rest of the query string)
- **Branch**: `574-udm-token-query-string-separators`
- **Target release**: v0.18.2
- **Phase**: Implemented 2026-09-15, acceptance criteria agreed and passing; completion gate pending

### Motivating consumer

Counting how many different files were downloaded, and by how many users,
across Windchill direct-download requests: `-udm fileName::distinct` and
`-udm userid::distinct` on a web server access log whose request URLs carry
fifteen query parameters, one of them a signature unique to every request.

### Problem (measured 2026-09-15)

The counting default pattern ends a value at whitespace, `,`, `;`, `"`, `'`,
`]` or `)`. In a query string parameters are separated by `&`, so the value of
a key runs on to the end of the query string. The unique signature parameter
makes every captured value unique, so `distinct` equals the number of matching
lines for every key on those lines. On one day of Windchill Apache access log
(84,876 lines, 74,305 signed download requests), `-bs 1440 -V` with both
metrics reported 74,305 distinct for each; the values up to the next `&` hold
22,431 distinct file names and 1 distinct user id.

### Decisions (architect, 2026-09-15)

| ID | Decision | Rationale |
|---|---|---|
| D1 — `&` and `?` end a value, in every log format | The counting default pattern's value stops at `&` and `?` in addition to the characters it already stops at. This revises the #313 row *Default pattern for counting configs*. | In a query string a key is preceded by `?` or `&` and its value ends at the next `&` or the end of the query string. The rule is generic, not specific to access logs, so `?` ends a value wherever it appears. |
| D2 — `\|` does not end a value | A pipe stays part of the captured value. | No log in the corpus separates `key=value` pairs with a pipe, and a real value containing one would be cut short. |
| D3 — `%` never ends a key or a value | A percent-encoded sequence (`%2F`, `%3D`) is part of the key or value it sits in. | URL encoding is how a query string carries reserved characters inside a key or value; splitting on it would break the key or value apart. |

Unchanged: the numeric default patterns (they capture a number and already stop
at `&`), slash-delimited `/regex/` specs (the user's pattern is the whole
extraction), and the set of characters the counting pattern already stopped at.

### Acceptance criteria

Fixture: a new synthetic access log `tests/fixtures/udm-counting-query-string.txt`,
one bucket, request URLs whose query strings carry a unique `sign` value on
every line. Assertions in `tests/validate-udm-counting.sh`, new scenario, run
`-ni -bs 1440 -oe -n 0 -V udm-counting`.

1. [x] A value ends at the `&` that precedes the next key: on six lines
   `?folderId=…&userid=42&fileName=<one of three>&sign=<unique>`,
   `fileName::distinct` reports 3 and `userid::distinct` reports 1. *Assertable.*
2. [x] The first key of a query string, preceded by `?`, is found and its value
   ends at the next `&`: `folderId::distinct` reports the number of distinct
   folder ids, not distinct query strings. *Assertable.*
3. [x] A value ends at the end of the query string: the last parameter,
   followed by a space, counts its whole value. *Assertable.*
4. [x] A value ends at `?` wherever it appears, not only in a query string:
   `ref=ABC?folderId=…` counts `ABC`. *Assertable.*
5. [x] A percent-encoded sequence is part of the value and of the key: values
   `a%2Fb` and `a%2Fc` count as two distinct values (not one `a`), and a token
   key containing `%5F` finds its value. *Assertable.*
6. [x] A pipe inside a value stays part of it: `kind=cad|part` and
   `kind=cad|asm` count as two distinct values. *Assertable.*
7. [x] Every existing counting scenario (tokens followed by a space, bracketed
   `[U: Administrator]` tokens, token keys) passes unchanged. *Assertable:
   the existing scenarios in `tests/validate-udm-counting.sh`.*
8. [x] On the one-day Windchill access log above, `fileName::distinct` reports
   22,431 and `userid::distinct` reports 1. *Assertable once, by hand on the
   corpus file; recorded under findings, not in a harness.*

### Findings from implementation

- **The new assertions fail without the fix.** On the new fixture, the
  release-branch head reports distinct 6 (one per request) for `ref`,
  `folderId`, `userid`, `fileName`, `path`, `kind` and `fid`, failing seven of
  the eight assertions. `site`, the last parameter, reports 2 before and after:
  its value already ended at the space after the query string.
- **The `%` and `|` assertions fail against a fix that splits on them.** A copy
  of the fixed build whose value also stops at `%` and `|` reports distinct 1
  for `path`, `kind` and `site`, failing those three assertions.
- **Criterion 8, measured 2026-09-15.** The fixed build on the one-day
  Windchill access log (`-ni -bs 1440 -V -udm fileName::distinct -udm
  userid::distinct`), one bucket: `fileName` 74,305 occurrences, 22,431
  distinct; `userid` 74,305 occurrences, 1 distinct. Before the fix both
  reported 74,305 distinct.
- **Harnesses run while working.** `tests/validate-udm-counting.sh` 44 passed,
  0 failed, with the new `query-string-values` scenario;
  `tests/validate-help-content.sh` 11 passed, 0 failed.

### Prototype triggers

None: no data model change; the per-line cost is two more characters in a
negated character class already evaluated on the same lines.

### Completion gate scope

An executable line of `ltl` changes: full harness suite and before/after
`single-day-access-log-standard` benchmark (before captured on the release
branch head, 2026-09-15).

## Future Enhancements (Out of Scope)

- ~~CSV column naming convention for UDM stats~~ — Done: consistent `name[_unit]_stat` lowercase pattern across both STATS and MESSAGES CSVs. Unit included between name and stat when defined (e.g., `latency_ms_occurrences`), omitted when unitless (e.g., `rows_occurrences`). Count columns normalized from PascalCase to `count_stat`.
- ~~Heatmap support for UDM metrics~~ — Done: `-hm <udm_name>` uses color gradient matching the metric's bar graph column
- ~~Histogram support for UDM metrics~~ — Done: `-hg <udm_name>` renders histogram with color matching the metric's bar graph column position. Multiple UDM histograms supported side-by-side.
- Percentile statistics (requires storing individual values per bucket)
