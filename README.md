# ltl : Log Time Line

Have you ever wished that you could quickly identify areas of interest or hotspots in very large log files so that you could navigate there directly?  That's what this timeline view is for!!

When dealing with logs which have a very large amount of lines/errors/whatever, it can be quite hard to get an overall view of the file while looking at a screen full of lines representing maybe less than a second.

`ltl`, or log timeline, reads log lines, establishes timestamps, extracts message details and statistics, and lets you filter and visualize everything through command-line options.  Use it to search for patterns, slowness, determine frequency and spacing of calls, and establish performance profiles of your APIs or services.

## Screenshots

Here is a very old screenshot showing the tools success in visualizing millions of log lines over a time range in a single screen.

![ltl - very old screenshot](images/slt-30minutewindows.png)

### GC Analysis using Heatmap and Histogram

A Full GC loop explored through zooming in on the specific time range, activating heatmap with 100 character width, enabling duration and bytes histograms, and setting the time-window bucketing to 1 minute.

![Full GC loop explored using heatmap and histogram views](images/gc-log-analysis_full-gc-loop_histogram-and-heatmap.png)

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

### Filtering

| Option | Description |
|--------|-------------|
| `-i, --include <regex>` | Only process lines matching this pattern, discard everything else |
| `-e, --exclude <regex>` | Discard lines matching this pattern before analysis |
| `-h, --highlight <regex>` | Show matching lines as a separate colored bar alongside the main bar for visual comparison |
| `-if, --include-file <file>` | Load include patterns from a file (one regex per line) |
| `-ef, --exclude-file <file>` | Load exclude patterns from a file (one regex per line) |
| `-hf, --highlight-file <file>` | Load highlight patterns from a file (one regex per line) |
| `-dmin, --duration-min <N>` | Hide log entries with duration below this threshold |
| `-dmax, --duration-max <N>` | Hide log entries with duration above this threshold |
| `-bmin, --bytes-min <N>` | Hide log entries with response size below this threshold |
| `-bmax, --bytes-max <N>` | Hide log entries with response size above this threshold |
| `-cmin, --count-min <N>` | Hide log entries with count below this threshold |
| `-cmax, --count-max <N>` | Hide log entries with count above this threshold |
| `-uuid, --mask-uuid` | Replace UUIDs/GUIDs with a placeholder so that requests differing only by ID are grouped together |

> **Note:** Filters affect all computed statistics. For example, `-dmin 1000` will show a minimum duration of ~1s because faster entries were excluded. The statistics reflect the filtered subset, not the full population of data in the file.

### Recording & Processing

| Option | Description |
|--------|-------------|
| `-ov, --omit-values` | Hide the per-bucket numeric values on the bar graph |
| `-os, --omit-stats` | Hide the statistics columns (min/avg/max/stddev/etc.) |
| `-oe, --omit-empty` | Skip time buckets that contain zero log entries |
| `-osum, --omit-summary` | Hide the summary table printed after the bar graph |
| `-or, --omit-rate` | Hide the lines/sec processing rate from output |
| `-od, --omit-durations` | Suppress duration extraction and related columns |
| `-ob, --omit-bytes` | Suppress byte-size extraction and related columns |
| `-oc, --omit-count` | Suppress count extraction and related columns |
| `-ic, --include-count` | Add a count column to the output (off by default) |
| `-iqs, --include-query-string` | Keep the query string when grouping URLs, so `/api?a=1` and `/api?b=2` are tracked separately |
| `-is, --include-session` | Keep session/user IDs when grouping messages, so each session is tracked separately |
| `-hs, --hide-session` | Hide the Sessions column that automatically appears when session IDs are found in the log data |

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
| `-udm, --user-defined-metrics <spec>` | Extract a custom numeric metric from each log line using a regex capture group (`name[:unit[:fn]]:/regex/`) |
| `-ucm, --udm-csv-message <cols>` | Treat the message field as CSV and name the columns for use with `-udm` |
| `-ucs, --udm-csv-separator <sep>` | Set the CSV field delimiter when using `-ucm` (default: comma) |

### Thread Pool Activity

| Option | Description |
|--------|-------------|
| `-tpa, --threadpool-activity <regex>` | Track activity over time for threads whose name matches the given pattern |
| `-tpas, --threadpool-activity-summary` | Show a summary of activity across all detected thread pools based on thread names in the log |

### Display

| Option | Description |
|--------|-------------|
| `-lbg, --light-background` | Use pale-to-bright color gradients suited for light/white terminal backgrounds |
| `-p, --pause` | Wait for a keypress between pages of output |
| `-V, --verbose` | Print detailed processing information including regex matches and parsing decisions |

### Info

| Option | Description |
|--------|-------------|
| `-v, --version` | Print the version number and exit |
| `--help` | Show the help screen and exit |
| `-mem, --memory-usage` | Display memory consumption statistics after processing completes |

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
```

## Download & Installation

Static binary packages are provided for Windows, Ubuntu, and macOS. Download from [Releases](https://github.com/gregeva/logtimeline/releases), rename to `ltl`, and place somewhere in your path.

To run directly from source:

```bash
./ltl [options] <logfile>
```
