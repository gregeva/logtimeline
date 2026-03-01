# ltl Usage Reference

## Usage

```
ltl [options] <logfile> [logfile2 ...]
```

## Options

### Time & Buckets

| Option | Description |
|--------|-------------|
| `-bs, --bucket-size <N>` | Set the width of each time bucket on the timeline (default unit: minutes; see `-s`, `-ms`) |
| `-s, --seconds` | Interpret bucket size as seconds instead of minutes |
| `-ms, --milliseconds` | Enable sub-second timestamp parsing and allow bucket sizes down to 100ms |
| `-st, --start <timestamp>` | Only process log lines at or after this time (`YYYY-MM-DD HH:MM:SS[.mmm]`) |
| `-et, --end <timestamp>` | Only process log lines before this time (`HH:MM:SS[.mmm]`) |
| `-du, --duration-unit <unit>` | Specify the duration unit used in the log file when auto-detection is not possible (`ns`, `us`, `ms`, `s`) |
| `-ru, --rate-unit <unit>` | Set the time unit for rate normalization: `s` (second), `m` (minute, default), `h` (hour), `d` (day) |

### Filtering

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
> **Note:** Filters affect all computed statistics. For example, `-dmin 1000` will show a minimum duration of ~1s because faster entries were excluded. The statistics reflect the filtered subset, not the full population of data in the file.

### Message Grouping

Log messages frequently contain variable parameters — user IDs, UUIDs, session tokens, IP addresses, endpoint paths, locale prefixes, and more. Two messages representing the same operation with different parameters create separate entries. Message grouping (`-g`) detects these variations using character-level similarity analysis and merges them into canonical patterns with `*` wildcards, aggregating their statistics.

**How it works:** During parsing, ltl discovers patterns by comparing unique messages using Dice coefficient scoring on character trigrams. When two messages are sufficiently similar, it aligns them character-by-character to identify which parts are constant and which vary, producing a canonical form like `GET /Thingworx/Things/*/Services/* HTTP/1.1`. Discovered patterns are compiled into regex and applied inline to all subsequent messages — matched messages never enter the main data structures, which is why consolidation reduces memory at scale.

Consolidated entries are marked with `~` in the summary table output. All statistics (occurrences, duration, bytes, percentiles, etc.) are aggregated across matched messages.

| Option | Description |
|--------|-------------|
| `-g, --group-similar <N>` | Enable fuzzy message consolidation with N% Dice similarity threshold (50-99, default: 80). Lower values are more aggressive. |
| `-uuid, --mask-uuid` | Replace UUIDs/GUIDs with a placeholder so that requests differing only by ID are grouped together (simpler alternative to `-g` for UUID-only variation) |
| `-iqs, --include-query-string` | Keep the query string when grouping URLs, so `/api?a=1` and `/api?b=2` are tracked separately |
| `-is, --include-session` | Keep session/user IDs when grouping messages, so each session is tracked separately |
| `--no-final-pass` | Skip the final consolidation pass that re-processes high-frequency keys against discovered patterns |
| `--consolidate-full-key` | Score similarity on the full log key including metadata prefix (level, thread, object). Default: message body only with metadata as exact-match grouping keys. |
| `--consolidation-trigger <N>` | Unmatched keys before triggering a checkpoint (default: 5000) |
| `--consolidation-ceiling <N>` | Max occurrences for a key to be eligible for pattern discovery (default: 3) |
| `--consolidation-max-patterns <N>` | Hard cap on patterns per grouping key; 0 = unlimited (default: 0) |
| `--final-threshold <N>` | Similarity threshold for the final pass (default: 80) |
| `--final-ceiling <N>` | Occurrence ceiling for the final pass (default: 1000000) |

**Performance characteristics:** Time overhead is ~20-30% at all scales. Memory overhead depends on data size — at small scale (< 200 MB) consolidation uses more memory due to trigram structures during checkpoint processing, but at production scale (1+ GB) it saves memory dramatically (up to 88% reduction on 7.9 GB) because matched keys are absorbed inline and never stored.

### Recording & Processing

| Option | Description |
|--------|-------------|
| `-ov, --omit-values` | Hide the per-bucket numeric values on the bar graph |
| `-os, --omit-stats` | Hide the statistics columns (min/avg/max/stddev/etc.) |
| `-oe, --omit-empty` | Skip time buckets that contain zero log entries |
| `-osum, --omit-summary` | Hide the summary table printed after the bar graph |
| `-or, --omit-rate` | Hide the error/message rate from the legend |
| `-od, --omit-durations` | Suppress duration extraction and related columns |
| `-ob, --omit-bytes` | Suppress byte-size extraction and related columns |
| `-oc, --omit-count` | Suppress count extraction and related columns |
| `-ic, --include-count` | Add a count column to the output (off by default) |
| `-hl, --hide-legend` | Hide the legend column (category breakdowns and rates) |
| `-ho, --hide-occurrences` | Hide the occurrences bar graph column, freeing space for other metric columns |
| `-hd, --hide-duration` | Hide the duration bar graph column |
| `-hb, --hide-bytes` | Hide the bytes bar graph column |
| `-hc, --hide-count` | Hide the count bar graph column |
| `-hs, --hide-session` | Hide the Sessions column that automatically appears when session IDs are found in the log data |
| `-hst, --hide-stats` | Hide the latency statistics or heatmap column |

### Output

| Option | Description |
|--------|-------------|
| `-n, --top-messages <N>` | Number of unique messages to show in the summary table (default: 10) |
| `-o, --output-csv` | Write all extracted data to a CSV file for external analysis |
| `-so, --sort-on <field>` | Choose which metric to rank messages by in the summary (`occurrences`, `duration`, `min`, `mean`, `max`, `stddev`, `bytes`, `count`, `impact`, `cv`) |
| `-sa, --sort-ascending` | Reverse the sort order to show lowest values first |

### Heatmap

| Option | Description |
|--------|-------------|
| `-hm, --heatmap [metric]` | Replace statistics with a color-intensity histogram showing value distribution per time bucket (`duration`, `bytes`, or `count`) |
| `-hmw, --heatmap-width <N>` | Number of columns for the heatmap display (default: 52) |

### Histogram

| Option | Description |
|--------|-------------|
| `-hg, --histogram [metric]` | Show an overall distribution histogram after the bar graph (`duration`, `bytes`, or `count`) |
| `-hgw, --histogram-width <N>` | Histogram width as percentage of terminal (default: 65) |
| `-hgh, --histogram-height <N>` | Histogram height in rows (default: 20) |

### User-Defined Metrics

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

### Thread Pool Activity

| Option | Description |
|--------|-------------|
| `-tpa, --threadpool-activity <regex>` | Track activity over time for threads whose name matches the given pattern. Can be specified multiple times; patterns are combined with OR. |
| `-tpas, --threadpool-activity-summary` | Show a summary of activity across all detected thread pools based on thread names in the log |

### Display

| Option | Description |
|--------|-------------|
| `-lbg, --light-background` | Use pale-to-bright color gradients suited for light/white terminal backgrounds |
| `-nah, --no-auto-hide` | Disable automatic column hiding at narrow terminal widths (squeeze all columns instead) |
| `-p, --pause` | Wait for a keypress between pages of output |
| `-V, --verbose` | Print detailed processing information including regex matches and parsing decisions |

### Info

| Option | Description |
|--------|-------------|
| `-v, --version` | Print the version number and exit |
| `--help` | Show the help screen and exit |
| `-mem, --memory-usage` | Display memory consumption statistics after processing completes |

## Environment

| Variable | Description |
|----------|-------------|
| `LTL_CONFIG` | Default command-line options. Parsed at startup and merged with command-line arguments. CLI values override environment values for scalar options. Additive options (`-i`, `-e`, `-h`, `-if`, `-ef`, `-hf`, `-tpa`, `-udm`, `-ucm`) combine from both sources. |

```bash
# Set defaults in shell profile (~/.bashrc, ~/.zshrc, etc.)
export LTL_CONFIG="-n 20 -bs 5 -lbg -e healthcheck"

# Defaults apply automatically
ltl access.log

# CLI overrides scalar options, combines with additive options
ltl -n 50 -e metrics access.log
# Result: n=50 (CLI wins), bs=5, lbg from env; excludes both healthcheck and metrics
```

## Examples

```bash
# Basic analysis of an access log
ltl access.log

# Analyze with millisecond precision over a one-minute window
ltl -ms -bs 100 -st "08:15:00.000" -et "08:16:00.000" my-app.log

# Filter to POST requests and highlight a specific API
ltl -i "POST" -h "/api/v2/orders" access.log

# Duration heatmap with 5-minute buckets
ltl -hm duration -bs 5 access.log

# Track a custom metric from application logs
ltl -udm "rows:/(\d+) rows processed/" my-app.log

# Group similar messages to consolidate URL/UUID variations into patterns
ltl -g 80 access.log

# Group similar with no final pass (faster, skips re-processing high-frequency keys)
ltl -g 80 --no-final-pass access.log
```
