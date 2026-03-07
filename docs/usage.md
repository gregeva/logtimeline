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
| `-bs, --bucket-size <N>` | Set the width of each time bucket on the timeline (default unit: minutes; see `-s`, `-ms`) |
| `-s, --seconds` | Interpret bucket size as seconds instead of minutes |
| `-ms, --milliseconds` | Enable sub-second timestamp parsing and allow bucket sizes down to 100ms |
| `-st, --start <timestamp>` | Only process log lines at or after this time (`YYYY-MM-DD HH:MM:SS[.mmm]`) |
| `-et, --end <timestamp>` | Only process log lines before this time (`HH:MM:SS[.mmm]`) |
| `-du, --duration-unit <unit>` | Specify the duration unit used in the log file when auto-detection is not possible (`ns`, `us`, `ms`, `s`) |
| `-ru, --rate-unit <unit>` | Set the time unit for rate normalization: `s` (second), `m` (minute, default), `h` (hour), `d` (day) |

```bash
# 5-minute buckets (default unit is minutes)
ltl -bs 5 access.log
# 30-second buckets
ltl -s -bs 30 access.log
# Millisecond precision, 100ms buckets, zoomed into a 5-minute window
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
| `-od, --omit-durations` | Suppress duration extraction and related columns |
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
| `-g, --group-similar <N>` | Enable fuzzy message consolidation with N% Dice similarity threshold (50-99, default: 90). Lower values are more aggressive. |
| `-uuid, --mask-uuid` | Replace UUIDs/GUIDs with a placeholder so that requests differing only by ID are grouped together (simpler alternative to `-g` for UUID-only variation) |
| `-iqs, --include-query-string` | Keep the query string when grouping URLs, so `/api?a=1` and `/api?b=2` are tracked separately |
| `-is, --include-session` | Keep session/user IDs when grouping messages, so each session is tracked separately |
| `--no-final-pass` | Skip the final consolidation pass that re-processes high-frequency keys against discovered patterns |
| `--consolidate-full-key` | Score similarity on the full log key including metadata prefix (level, thread, object). Default: message body only with metadata as exact-match grouping keys. |
| `--consolidation-trigger <N>` | Unmatched keys before triggering a checkpoint (default: 5000) |
| `--consolidation-ceiling <N>` | Max occurrences for a key to be eligible for pattern discovery (default: 3) |
| `--consolidation-max-patterns <N>` | Hard cap on patterns per grouping key; 0 = unlimited (default: 0) |
| `--final-threshold <N>` | Similarity threshold for the final pass (default: 90) |
| `--final-ceiling <N>` | Occurrence ceiling for the final pass (default: 1000000) |

```bash
# Consolidate similar messages at 90% similarity threshold
ltl -g access.log
# Raise the occurrence ceiling to include higher-frequency keys in pattern discovery
ltl -g --consolidation-ceiling 10 access.log
# Consolidate but keep query strings and sessions as separate entries
ltl -g 80 -iqs -is access.log
```

**Performance characteristics:** Time overhead is ~20-30% at all scales. Memory overhead depends on data size — at small scale (< 200 MB) consolidation uses more memory due to trigram structures during checkpoint processing, but at production scale (1+ GB) it saves memory dramatically (up to 88% reduction on 7.9 GB) because matched keys are absorbed inline and never stored.

### Display & Output

These options control what is shown and how. After the timeline bar graph, logtimeline prints a summary table ranking the top contributing messages — `-n` controls how many entries appear, and `-osum` suppresses it entirely. The hide options hide individual columns from the bar graph while still processing the underlying data — useful for freeing horizontal space on narrow terminals or focusing on the metrics that matter. The CSV output option (`-o`) writes the full analysis data to a file for external processing, archival, or baseline comparison. The light background mode (`-lbg`) switches color gradients for white or light terminal backgrounds. The pause option (`-p`) is useful when output exceeds the terminal height.

| Option | Description |
|--------|-------------|
| `-n, --top-messages <N>` | Number of unique messages to show in the summary table (default: 10) |
| `-o, --output-csv` | Write all extracted data to a CSV file for external analysis |
| `-osum, --omit-summary` | Hide the summary table printed after the bar graph |
| `-hl, --hide-legend` | Hide the legend column (category breakdowns and rates) |
| `-ho, --hide-occurrences` | Hide the occurrences bar graph column, freeing space for other metric columns |
| `-hd, --hide-duration` | Hide the duration bar graph column |
| `-hb, --hide-bytes` | Hide the bytes bar graph column |
| `-hc, --hide-count` | Hide the count bar graph column |
| `-hs, --hide-session` | Hide the Sessions column that automatically appears when session IDs are found in the log data |
| `-hst, --hide-stats` | Hide the latency statistics or heatmap column |
| `-lbg, --light-background` | Use pale-to-bright color gradients suited for light/white terminal backgrounds |
| `-nah, --no-auto-hide` | Disable automatic column hiding at narrow terminal widths (squeeze all columns instead) |
| `-p, --pause` | Wait for a keypress between pages of output |
| `-V, --verbose` | Print detailed processing information including regex matches and parsing decisions |

```bash
# Show top 50 messages in the summary table
ltl -n 50 access.log
# Export full analysis data to CSV
ltl -o access.log
# Hide the summary table, show only the timeline
ltl -osum access.log
# Use color gradients suited for light terminal backgrounds
ltl -lbg access.log
```

### Sorting

The summary table is sorted by occurrence count by default. Use `-so` to rank messages by a different metric — total duration, min/max/mean latency, standard deviation, bytes, count, impact (occurrences × mean duration), or coefficient of variation. Use `-sa` to reverse the sort order.

| Option | Description |
|--------|-------------|
| `-so, --sort-on <field>` | Choose which metric to rank messages by in the summary (`occurrences`, `duration`, `min`, `mean`, `max`, `stddev`, `bytes`, `count`, `impact`, `cv`) |
| `-sa, --sort-ascending` | Reverse the sort order to show lowest values first |

```bash
# Rank messages by total duration (heaviest hitters)
ltl -so duration access.log
# Find messages with the highest max latency
ltl -so max access.log
# Find the least frequent messages
ltl -so occurrences -sa access.log
```

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
