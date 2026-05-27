LogTimeLine (ltl) is a command-line log analysis tool that identifies hotspots in large log files through time-bucketed visualization and statistical analysis. It reads log files directly, aggregates them into color-coded bar graphs, and pairs temporal metrics with the specific messages that produced them. For more on the design philosophy and intended workflow, see [Purpose and Design Philosophy](Purpose-and-Design-Philosophy).

```
ltl [options] <logfile> [logfile2 ...]
```

## Files

LogTimeLine accepts one or more file paths as arguments. File arguments can appear before options, after options, or interspersed — the option parser consumes recognized flags and treats everything else as a file path.

```bash
ltl access.log error.log app.log
ltl logs/2025-05-*.txt logs/2025-06-*.txt
ltl -bs 5 -i "POST" logs/*/access.log
```

When multiple files are specified, logtimeline processes them sequentially and combines the results into a single timeline. This is useful for analyzing rotated log files, multiple days of logs, or logs from different sources on the same system.

Glob expansion is performed internally by logtimeline rather than relying on the shell, ensuring consistent behavior across platforms — particularly on Windows where the shell does not expand wildcards. Only regular files are accepted; directories and other non-file entries in a glob result are silently skipped.

## Options

### Time & Buckets

The timeline is divided into time buckets — fixed-width windows that aggregate all log activity within that period. The bucket size controls the granularity of the analysis: large buckets (hours, days) reveal macro trends across long time ranges, while small buckets (seconds, milliseconds) expose fine-grained patterns within a narrow window. Adjusting the bucket size is the primary way to zoom in and out of the data. The `-st` and `-et` options define the time range to analyze, allowing you to focus on a specific period of interest without re-processing the entire file.

| Option | Description |
|--------|-------------|
| `-bs, --bucket-size <N>` | Set the width of each time bucket on the timeline (default unit: minutes; `-s` switches the unit to seconds, `-ms` switches it to milliseconds) |
| `-s, --seconds` | Interpret bucket size as seconds instead of minutes |
| `-ms, --milliseconds` | Switch the `-bs <N>` bucket width to milliseconds (and render timestamps with `.fff` precision). Lets you draw buckets as narrow as 100ms — used to zoom the timeline into bursts that minute/second-width buckets average out. Does not change how the underlying log records are read, parsed, or measured. |
| `-st, --start <timestamp>` | Only process log lines at or after this time. A full date (`YYYY-MM-DD HH:MM:SS[.mmm]`) is an absolute cutoff; a bare time (`HH:MM[:SS[.mmm]]`) is a time-of-day window applied to every day, regardless of how the logs are split across files. A bare-time start later than the end wraps past midnight. |
| `-et, --end <timestamp>` | Only process log lines before this time. Same forms as `-st`: a full date is an absolute cutoff; a bare time applies to every day. |
| `-du, --duration-unit <unit>` | Specify the duration unit used in the log file when auto-detection is not possible (`ns`, `us`, `ms`, `s`) |
| `-ru, --rate-unit <unit>` | Set the time unit for rate normalization: `s` (second), `m` (minute, default), `h` (hour), `d` (day) |

```bash
# 5-minute buckets (default unit is minutes)
ltl -bs 5 access.log
# 30-second buckets
ltl -s -bs 30 access.log
# 100ms-wide buckets, zoomed into a 5-minute window (sub-second timestamp rendering enabled)
ltl -ms -bs 100 -st "2025-05-05 08:15:00.000" -et "2025-05-05 08:20:00.000" app.log
```

### Filtering

Filtering is the core of logtimeline's investigative power. Three operations — include, exclude, and highlight — drive an iterative analysis loop. **Include** isolates lines matching a pattern, discarding everything else. **Exclude** removes matching lines, keeping everything else. **Highlight** renders matching lines as a separate colored bar alongside the main bar in every time bucket, allowing visual comparison of a subset against the full population. All three accept regex, can be specified multiple times, and support `&` for AND logic within a single pattern.

The typical workflow is subtractive: start with all data, exclude known noise, narrow with includes until the signal is clear, then highlight to see your target in the context of the full population. Pattern files (`-if`, `-ef`, `-hf`) allow reusable sets of patterns for common scenarios. Numeric threshold filters (`-dmin`, `-dmax`, `-bmin`, `-bmax`, `-cmin`, `-cmax`) complement regex filtering by selecting entries based on metric values rather than text content.

| Option | Description |
|--------|-------------|
| `-i, --include <regex>` | Only process lines matching this pattern, discard everything else. Can be specified multiple times; patterns are combined with OR. Use `&` for AND: `A&B` matches lines containing both A and B. `&&` for literal `&`. `&` binds tighter than `\|`. |
| `-e, --exclude <regex>` | Discard lines matching this pattern before analysis. Can be specified multiple times; patterns are combined with OR. Supports `&` (AND) and `&&` (literal `&`). |
| `-h, --highlight <regex>` | Show matching lines as a separate colored bar alongside the main bar for visual comparison. Can be specified multiple times; patterns are combined with OR. Supports `&` (AND) and `&&` (literal `&`). |
| `-if, --include-file <file>` | Load include patterns from a file (one pattern per line) |
| `-ef, --exclude-file <file>` | Load exclude patterns from a file (one pattern per line) |
| `-hf, --highlight-file <file>` | Load highlight patterns from a file (one pattern per line) |
| `-dmin, --duration-min <N>` | Hide log entries with duration below this threshold |
| `-dmax, --duration-max <N>` | Hide log entries with duration above this threshold |
| `-bmin, --bytes-min <N>` | Hide log entries with response size below this threshold |
| `-bmax, --bytes-max <N>` | Hide log entries with response size above this threshold |
| `-cmin, --count-min <N>` | Hide log entries with count below this threshold |
| `-cmax, --count-max <N>` | Hide log entries with count above this threshold |
```bash
# Only show POST requests, exclude health checks
ltl -i "POST" -e healthcheck access.log
# Highlight a specific API against all traffic
ltl -h "/api/v2/orders" access.log
# Only show requests slower than 5 seconds
ltl -dmin 5000 access.log
```

> **Note:** Filters affect all computed statistics. For example, `-dmin 1000` will show a minimum duration of ~1s because faster entries were excluded. The statistics reflect the filtered subset, not the full population of data in the file.

### Recording & Processing

These options control which metrics logtimeline extracts and computes during processing. By default, it detects and processes everything it finds — durations, byte sizes, and counts. The omit options suppress extraction entirely, so the data is never computed and the corresponding columns do not appear. Use `-ic` to opt in to count tracking, which is off by default.

| Option | Description |
|--------|-------------|
| `-ov, --omit-values` | Hide the per-bucket numeric values on the bar graph |
| `-os, --omit-stats` | Hide the statistics columns (min/avg/max/stddev/etc.) |
| `-oe, --omit-empty` | Skip time buckets that contain zero log entries |
| `-or, --omit-rate` | Hide the error/message rate from the legend |
| `-od, --omit-durations` | Suppress duration extraction and related columns (significantly reduces memory and processing time on large files) |
| `-ob, --omit-bytes` | Suppress byte-size extraction and related columns |
| `-oc, --omit-count` | Suppress count extraction and related columns |
| `-ic, --include-count` | Add a count column to the output (off by default) |

```bash
# Focus on occurrences only — suppress duration and byte extraction
ltl -od -ob access.log
# Skip empty time buckets in the output
ltl -oe access.log
# Enable count tracking (off by default)
ltl -ic access.log
```

### Message Grouping

Log messages frequently contain variable parameters — user IDs, UUIDs, session tokens, IP addresses, endpoint paths, locale prefixes, and more. Two messages representing the same operation with different parameters create separate entries. Message grouping (`-g`) detects these variations using character-level similarity analysis and merges them into canonical patterns with `*` wildcards, aggregating their statistics.

**How it works:** During parsing, logtimeline discovers patterns by comparing unique messages using Dice coefficient scoring on character trigrams. When two messages are sufficiently similar, it aligns them character-by-character to identify which parts are constant and which vary, producing a canonical form like `GET /Thingworx/Things/*/Services/* HTTP/1.1`. Discovered patterns are compiled into regex and applied inline to all subsequent messages — matched messages never enter the main data structures, which is why consolidation reduces memory at scale.

Consolidated entries are marked with `~` in the summary table output. All statistics (occurrences, duration, bytes, percentiles, etc.) are aggregated across matched messages.

| Option | Description |
|--------|-------------|
| `-g, --group-similar <N>` | Enable fuzzy message consolidation with N% Dice similarity threshold (50-99, default: 85). Lower values are more aggressive. |
| `-uuid, --mask-uuid` | Replace UUIDs/GUIDs with a placeholder so that requests differing only by ID are grouped together (simpler alternative to `-g` for UUID-only variation) |
| `-iqs, --include-query-string` | Keep the query string when grouping URLs, so `/api?a=1` and `/api?b=2` are tracked separately |
| `-is, --include-session` | Keep session/user IDs when grouping messages, so each session is tracked separately |
| `-gc, --group-ceiling <N>` | Messages with more than N occurrences skip pairwise discovery but still match existing patterns (default: 1000000) |

```bash
# Consolidate similar messages at 85% similarity threshold
ltl -g access.log
# Don't consolidate messages with more than 5000 occurrences
ltl -g -gc 5000 access.log
# Consolidate but keep query strings and sessions as separate entries
ltl -g 80 -iqs -is access.log
```

**Performance characteristics:** Time overhead is ~20-30% at all scales. Memory overhead depends on data size — at small scale (< 200 MB) consolidation uses more memory due to trigram structures during checkpoint processing, but at production scale (1+ GB) it saves memory dramatically (up to 88% reduction on 7.9 GB) because matched keys are absorbed inline and never stored.

### Display & Output

These options control what is shown and how. After the timeline bar graph, logtimeline prints a summary table ranking the top contributing messages — `-n` controls how many entries appear, and `-osum` suppresses it entirely. The hide options hide individual columns from the bar graph while still processing the underlying data — useful for freeing horizontal space on narrow terminals or focusing on the metrics that matter. The CSV output option (`-o`) writes the full analysis data to a file for external processing, archival, or baseline comparison. The light background mode (`-lbg`) switches color gradients for white or light terminal backgrounds. The dark background mode (`-dbg`) forces the dark gradients and overrides `-lbg` if both are passed. The pause option (`-p`) is useful when output exceeds the terminal height.

| Option | Description |
|--------|-------------|
| `-n, --top-messages <N>` | Number of unique messages to show in the summary table (default: 10) |
| `-o, --output-csv` | Write all extracted data to a CSV file for external analysis |
| `-cp, --csv-precision <mode>` | Control CSV decimal precision: `default` (per-family decimals derived from `-du`), `full` (raw precise floats), or an integer N (cap all numeric columns at N decimals) |
| `-osum, --omit-summary` | Hide the summary table printed after the bar graph |
| `-hl, --hide-legend` | Hide the legend column (category breakdowns and rates) |
| `-ho, --hide-occurrences` | Hide the occurrences bar graph column, freeing space for other metric columns |
| `-hd, --hide-duration` | Hide the duration bar graph column |
| `-hb, --hide-bytes` | Hide the bytes bar graph column |
| `-hc, --hide-count` | Hide the count bar graph column |
| `-hs, --hide-session` | Hide the Sessions column that automatically appears when session IDs are found in the log data |
| `-hst, --hide-stats` | Hide the latency statistics or heatmap column |
| `-lbg, --light-background` | Use pale-to-bright color gradients suited for light/white terminal backgrounds |
| `-dbg, --dark-background` | Force dark-background color gradients; overrides `-lbg` and disables auto-detect |
| `-nah, --no-auto-hide` | Disable automatic column hiding at narrow terminal widths (squeeze all columns instead) |
| `-p, --pause` | Wait for a keypress between pages of output |
| `-V, --verbose [<section>...]` | Emit diagnostic sections. Bare `-V` emits all; `-V <name>[,<name>...]` or repeated `-V` selects sections; `-V list` prints known sections. See "Verbose output (`-V`)" section below |

```bash
# Show top 50 messages in the summary table
ltl -n 50 access.log
# Export full analysis data to CSV
ltl -o access.log
# Hide the summary table, show only the timeline
ltl -osum access.log
# Use color gradients suited for light terminal backgrounds
ltl -lbg access.log
# Force dark-background gradients (overrides auto-detect and -lbg)
ltl -dbg access.log
```

### Sorting

The summary table is sorted by occurrence count by default. Use `-so` to rank messages by a different metric — total duration, latency statistics (min/max/mean/stddev/cv), per-percentile latency (p1–p99999), distribution-shape moments (iqr/skewness/kurtosis/bimodality_coef), bytes, count, or impact (occurrences × mean duration). Use `-sa` to reverse the sort order.

| Option | Description |
|--------|-------------|
| `-so, --sort-on <field>` | Choose which metric to rank messages by in the summary. Valid values are grouped below. |
| `-sa, --sort-ascending` | Reverse the sort order to show lowest values first |

| Group | Values |
|-------|--------|
| Aggregates | `occurrences`, `duration` (alias `time`), `bytes` (alias `size`), `mean_bytes`, `count`, `count_occurrences`, `count_min`, `count_mean`, `count_max`, `impact` |
| Latency stats | `min`, `mean` (alias `avg`), `max`, `stddev` (alias `std_dev`), `cv` |
| Percentile latency | `p1`, `p5`, `p10`, `p25`, `p50`, `p75`, `p90`, `p95`, `p99`, `p999`, `p9999`, `p99999` |
| Distribution shape | `iqr`, `skewness`, `kurtosis`, `bimodality_coef` |

```bash
# Rank messages by total duration (heaviest hitters)
ltl -so duration access.log
# Find messages with the highest max latency
ltl -so max access.log
# Find the worst tail-latency offenders
ltl -so p999 access.log
# Surface likely multimodal distributions (cache-hit vs cache-miss patterns)
ltl -so bimodality_coef access.log
# Find the least frequent messages
ltl -so occurrences -sa access.log
```

Percentile and shape metrics require a sufficient sample size to be statistically meaningful: `p999` ≥ ~1k, `p9999` ≥ ~100k, `p99999` ≥ ~1M. `bimodality_coef` is a *screening* statistic — at n < 100 small-sample noise can produce false positives. Skewness/kurtosis/bimodality_coef are undefined (blank in CSV, treated as 0 for sort ordering) when n < 4.

### Percentile data model and algorithm

ltl computes percentiles from one of two data models, each with its own algorithm. The two models produce different values for the same input, particularly in the tail; this is the data model, not a precision deviation. See `ltl --explain percentiles` for the deeper explanation, when to use which, and the trade-offs.

**Raw values data model.** Every observation is held in memory and the percentile is selected by **nearest-rank** — an actually-observed sample at the computed rank in the sorted array. The returned value is a real request that happened. Scales with observation count.

**Bin counter data model.** Observations are accumulated into log-spaced bins and the percentile is computed by **exponential interpolation within the bucket** — a synthesised value placed inside the bin that contains the target rank, on the log scale spanning the bin's lower and upper edges. The returned value is generally not an observed sample. Bin resolution sets the interpolation tightness; it is governed by the precision lever (see *Tuning precision* below). Scales with partition count rather than observation count.

**Per-surface defaults.** Four consumer surfaces use percentile output; each has a default data model today:

| # | Surface | Default Data Model |
|---|---|---|
| 1 | Histogram statistics (consumed by `-hg`) | bin counter |
| 2 | Heatmap statistics (consumed by `-hm`) | bin counter |
| 3 | Per-message-key statistics | raw values |
| 4 | Per-time-bucket statistics | raw values |

**Pinning the data model.** The selectors below override the per-surface default when you need certainty (test harnesses, reproducibility, A/B comparison). The omnibus `-dm` flag pins every surface; per-surface flags override `-dm` for their surface.

| Option | Description |
|--------|-------------|
| `-dm, --data-model <raw\|bin>` | Pin the data model for every surface (overridden by any per-surface flag below). |
| `-hgdm, --histogram-data-model <raw\|bin>` | Pin the histogram surface's data model. |
| `-hmdm, --heatmap-data-model <raw\|bin>` | Pin the heatmap surface's data model. |
| `-mdm, --message-stats-data-model <raw\|bin>` | Pin the per-message-key statistics data model. Both reductions are implemented end-to-end: `raw` uses nearest-rank percentile selection over retained duration arrays; `bin` uses Prometheus-style exponential interpolation over HDR-style bin counters plus Welford-Pébay sidecar accumulators for exact-value statistics. Default is `raw`. |
| `-bdm, --bucket-stats-data-model <raw\|bin>` | Pin the per-time-bucket statistics data model. Both reductions are implemented end-to-end: `raw` uses nearest-rank percentile selection over retained duration arrays; `bin` uses Prometheus-style exponential interpolation over HDR-style bin counters plus Welford-Pébay sidecar accumulators for exact-value statistics. Default is `raw`. |

Per-surface flag overrides `-dm`; `-dm` overrides the per-surface default. Invalid values (anything other than `raw` or `bin`) cause ltl to exit at option-parse time with a clear error. Conflicting flags on the same axis follow standard last-one-wins ordering.

**Tuning precision.** A single lever sets how finely the bin counter surfaces resolve. Raise it for tighter values in the tail percentiles (`p999`, `p9999`); lower it to reduce per-partition memory cost. The default suits most analyses — you rarely need to touch it.

| Option | Description |
|--------|-------------|
| `-dmp, --data-model-precision <N>` | Precision tier 1..9 (default: 5). Higher tiers give finer resolution on the bin counter surfaces at higher memory cost. |

Precision increases in stages across the surfaces as you raise the tier, so the lever buys fidelity where it costs least first. Above the default, the histogram and heatmap are already at their finest, and the per-time-bucket statistics sharpen ahead of the per-message-key statistics — the per-message surface is the highest-cost consumer (one partition per unique message), so it reaches full resolution last. Below the default, every bin counter surface coarsens, including the histogram and heatmap shape.

Use `-V histogram-bin-counters` to inspect the resolved tier and its source, and `-V percentile-algorithm` to see each surface's resolved resolution.

```bash
# Default behavior (per-surface defaults above)
ltl access.log

# Higher precision tier for tight tail-percentile analysis
ltl -dmp 7 access.log

# Pin every surface to the raw values data model
ltl -dm raw access.log

# Override just the histogram surface; leave the heatmap on its default
ltl -hgdm raw -hm duration -hg access.log

# Inspect resolved settings
ltl -V histogram-bin-counters access.log
```

```bash
# Pin every surface to the raw reduction path
ltl -dm raw access.log

# Override just the histogram surface; leave the heatmap on its default
ltl -hgdm raw -hm duration -hg access.log

# Inspect which selectors are active for this run
ltl -V runtime-config -dm raw -hgdm bin access.log
```

### Distribution shape (CSV columns)

The `-o` CSV outputs (MESSAGES and STATS) carry three distribution-shape statistics alongside the percentile columns, enabling characterization of a latency distribution's *shape* — not just its quantile values:

| Column | Range | Interpretation |
|---|---|---|
| `skewness` | typically -3 to +3 | Distribution asymmetry. 0 = symmetric (e.g. Gaussian); positive = right tail heavier (typical for latencies); negative = left tail heavier. |
| `kurtosis` | typically -2 to ~30 | Excess kurtosis (normal = 0). Positive = heavier tails than a Gaussian; high values (> 10) indicate extreme outliers dominate. |
| `bimodality_coef` | 0 to 1 | Sarle's bimodality coefficient. **Values > 5/9 ≈ 0.555 flag suspect multimodal distributions** (e.g. cache-hit vs. cache-miss populations within a single API). |

Sample-size requirements:
- All three statistics require `n ≥ 4`; emitted blank otherwise (BC denominator requires `n > 3`).
- `bimodality_coef` is a *screening* statistic, not a test. At `n < 100` small-sample noise can produce false positives — treat low-sample bimodality flags as exploratory.
- `p9999` is meaningful at `n ≥ ~100,000`; below that, it collapses toward `max`.
- `p99999` is meaningful at `n ≥ ~1,000,000`; below that, it collapses toward `max` and carries no signal independent of `p9999`.

The body percentiles `p5`, `p10`, and `p25` and the precomputed interquartile range `iqr` (= `p75 − p25`) are emitted in both CSV files, completing the body/tail percentile pairing recommended in the Google SRE book.

For detailed explanations of every statistic ltl emits — including interpretation tables, operational use cases, and worked examples — run `ltl --explain <topic>` (e.g. `ltl --explain kurtosis`, `ltl --explain bimodality_coef`, `ltl --explain percentiles`). The full reference is also available on the [Statistics Reference](Statistics-Reference) wiki page. Use `ltl --help statistics` for a one-line index of all statistics, or `ltl --explain` (no argument) for the list of available `--explain` topics.

### Heatmap

Heatmap mode replaces the per-bucket latency statistics with a color-intensity visualization showing how values are distributed within each time bucket. Where percentile statistics reduce a distribution to a handful of numbers, the heatmap reveals its full shape — bimodal distributions (cache hits vs. misses), shifting modes over time, outlier clustering, and long tails all become visually apparent. Each cell represents a value range, with color intensity proportional to the number of entries falling within that range. Logarithmic bucket boundaries provide resolution across the full range of values, from sub-millisecond to multi-second durations.

| Option | Description |
|--------|-------------|
| `-hm, --heatmap [metric]` | Replace statistics with a color-intensity histogram showing value distribution per time bucket (`duration`, `bytes`, or `count`) |
| `-hmw, --heatmap-width <N>` | Number of columns for the heatmap display (default: 52) |

```bash
# Duration heatmap with 5-minute buckets
ltl -hm duration -bs 5 access.log
# Bytes heatmap with wider display
ltl -hm bytes -hmw 80 access.log
# Count heatmap on a light terminal background
ltl -hm count -lbg access.log
```

### Histogram

Histograms show the overall distribution shape of a metric across the entire time range. Unlike the heatmap which shows how the distribution evolves per time bucket, a histogram aggregates all values into a single chart — making it easy to identify the most common value ranges, spot outliers, and determine whether the distribution is normal, bimodal, or long-tailed. Multiple histograms (duration, bytes, count) can be displayed side by side for simultaneous comparison.

| Option | Description |
|--------|-------------|
| `-hg, --histogram [metric]` | Show an overall distribution histogram after the bar graph (`duration`, `bytes`, or `count`) |
| `-hgw, --histogram-width <N>` | Histogram width as percentage of terminal (default: 95) |
| `-hgh, --histogram-height <N>` | Histogram height in rows (default: 8) |
| `-hgb, --histogram-buckets <N>` | Override total histogram bucket count (default: 0 = auto-calculate) |

```bash
# Show duration and bytes histograms side by side
ltl -hg duration,bytes access.log
# Taller histogram for more detail
ltl -hg duration -hgh 15 access.log
# All available metric histograms
ltl -hg access.log
```

### User-Defined Metrics

User-defined metrics allow extraction of arbitrary numeric values from log lines using regex patterns or named field matching. Extracted values are tracked across time buckets and displayed as additional bar graph columns alongside the built-in duration, bytes, and count metrics. This enables ad-hoc exploratory analysis of application-specific data — queue depths, row counts, cache sizes, connection pools, or any numeric value that appears in the log — without requiring a dedicated log format parser. Units, aggregation functions, and delta transforms can be specified to control how values are converted, accumulated, and displayed.

| Option | Description |
|--------|-------------|
| `-udm, --user-defined-metrics <spec>` | Extract a custom numeric metric from each log line (see format below) |
| `-ucm, --udm-csv-message <cols>` | Treat the message field as CSV and name the columns for use with `-udm` |
| `-ucs, --udm-csv-separator <sep>` | Set the CSV field delimiter when using `-ucm` (default: comma) |

**UDM spec format:** `name[:unit[:function]][:/regex/]`

| Part | Description |
|------|-------------|
| `name` | Metric name — also used as default pattern to match `name=value` or `name: value` |
| `unit` | **Time:** `ns`, `us`, `ms`, `s`, `m`, `h` — **Bytes:** `B`, `kB`, `KB`, `MB`, `GB`, `TB`, `KiB`, `MiB`, `GiB`, `TiB` — **SI:** `k`/`K` (×1000), `M`, `G`, `T` — omit for raw numbers |
| `function` | **Aggregations:** `sum` (default), `min`, `max`, `avg` — **Transforms:** `delta` (clamped ≥0), `idelta` (unclamped) — **Combined:** `sum(delta)`, `avg(delta)`, `max(idelta)`, etc. |
| `/regex/` | Custom extraction pattern with one capture group around the numeric value to extract (overrides default name matching). e.g. for `[Duration 134ms]`: `/\[Duration (\d+)(?:ms\|Ms)\]/` |

```bash
# Track max value of a raw numeric field per bucket
ltl -udm "Send-Q::max" app.log
# Track a time-unit metric with delta transform
ltl -udm "busy:ms:sum(delta)" app.log
# Extract a custom metric by regex pattern
ltl -udm "rows:/(\d+) rows processed/" app.log
```

### Thread Pool Activity

Thread pool activity tracking adds columns to the timeline showing how many distinct threads were active per time bucket for each matched pool. This reveals infrastructure-level behavior — thread exhaustion, pool saturation, and correlation between thread utilization and latency spikes. When application logs include thread names (common in Java/Tomcat logs), this provides a view into the concurrency dimension that is otherwise invisible in the log messages themselves.

| Option | Description |
|--------|-------------|
| `-tpa, --threadpool-activity <regex>` | Track activity over time for threads whose name matches the given pattern. Can be specified multiple times; patterns are combined with OR. |
| `-tpas, --threadpool-activity-summary` | Show a summary of activity across all detected thread pools based on thread names in the log |

```bash
# Track HTTP thread pool activity
ltl -tpa "http-" access.log
# Show a summary of all detected thread pools
ltl -tpas app.log
# Track multiple thread pools
ltl -tpa "http-" -tpa "async-" app.log
```

### Verbose output (`-V`)

The `-V` flag emits diagnostic sections describing internal state — effective configuration (CLI + environment), index pre-seed lookups, bin-counter feature state, message-grouping statistics, log-format detection, heatmap palette resolution, benchmark data. Each section is named and bracketed by `=== <name> ===` / `=== END <name> ===` markers so it can be extracted by `grep`, `sed`, or `awk`.

| Form | Behavior |
|------|----------|
| `-V` (no argument) | Emit all known sections |
| `-V all` | Same as bare `-V` (explicit) |
| `-V list` | Print known section names + descriptions, exit 0 |
| `-V <name>` | Emit only the named section |
| `-V <a>,<b>,<c>` | Emit a comma-separated list of sections |
| `-V <a> -V <b>` | Repeat the flag — equivalent to `-V a,b` |
| `-V <unknown>` | Warn to stderr, continue with remaining valid sections |

Section names are stable across releases — renames are breaking changes governed by `tests/HARNESS-DESIGN.md`. Discover the current set with `ltl -V list`.

```bash
# Inspect the bin-counter feature state for a run
ltl -V histogram-bin-counters access.log

# Capture benchmark TSV for a regression run
ltl -V benchmark-data access.log

# Capture two sections at once
ltl -V runtime-config,benchmark-data access.log

# Discover the available sections
ltl -V list
```

Section content is governed by per-section stability contracts — additions are non-breaking, renames and removals are breaking. Test harnesses consume these sections; see `tests/HARNESS-DESIGN.md` for the contributor-facing contract.

### Stderr warnings

`ltl` emits warnings to stderr when an input is accepted but resolved in a way that may surprise the user. These do not affect exit codes — the run proceeds — but pipelines that capture stderr may need to filter them. The warnings exist to make previously-silent overrides observable; suppressing them by default would defeat the purpose.

| Trigger | Warning |
|---------|---------|
| `-g <non-numeric>` (e.g. `-g logfile.log`) | The non-numeric value is treated as a positional argument and the default similarity threshold (85) is applied. |
| `-hm <unknown-metric>` without any `-udm` configured (e.g. `-hm bogus`) | The value is treated as a positional argument and the default heatmap metric (`duration`) is applied. |
| `--data-model`, `--histogram-data-model`, `--heatmap-data-model`, `--message-stats-data-model`, or `--bucket-stats-data-model` supplied with a value other than `raw` or `bin` | ltl exits with `<flag>: '<value>' is not a valid data model; valid values are 'raw' and 'bin'`. |

To inspect the resolved configuration after warnings have fired, use `-V runtime-config` and read the `command-line` and `environment-variable` sub-sections.

## Environment

The `LTL_CONFIG` environment variable lets you define default options that apply to every run. This is useful for setting site-specific or personal preferences — a preferred bucket size, default exclusion patterns for health checks, light background mode — without typing them on every command. CLI arguments override scalar options from the environment and combine with additive options (filters, metrics, pattern files).

| Variable | Description |
|----------|-------------|
| `LTL_CONFIG` | Default command-line options. Parsed at startup and merged with command-line arguments. CLI values override environment values for scalar options. Additive options (`-i`, `-e`, `-h`, `-if`, `-ef`, `-hf`, `-tpa`, `-udm`, `-ucm`) combine from both sources. |

### Info

Version, help, and diagnostic options.

| Option | Description |
|--------|-------------|
| `-v, --version` | Print the version number and exit |
| `--help` | Show the help screen and exit |
| `-mem, --memory-usage` | Display memory consumption statistics after processing completes |

## Alternate Names

LogTimeLine uses precise metric names to avoid ambiguity. `duration` explicitly means a time lapse — how long something took. `count` means an amount of work completed in the metrics sense (e.g. rows processed, items returned), distinct from `occurrences` which is the total number of log entries matched. `bytes` means response or payload size. These distinctions matter because imprecise terms like "time" or "size" could refer to different things depending on context.

That said, logtimeline accepts conventional alternates for convenience. These aliases work anywhere a metric or function name is used — sorting (`-so`), heatmap (`-hm`), histogram (`-hg`), and user-defined metric aggregations.

| Canonical Name | Alternates |
|---------------|------------|
| `duration` | `time` |
| `bytes` | `size` |
| `occurrences` | `total` |
| `mean` | `avg` |
| `stddev` | `std_dev` |
