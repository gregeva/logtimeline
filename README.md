# ltl : Log Time Line

Have you ever wished that you could quickly identify areas of interest or hotspots in very large log files so that you could navigate there directly?  That's what this timeline view is for!!

When dealing with logs which have a very large amount of lines/errors/whatever, it can be quite hard to get an overall view of the file while looking at a screen full of lines representing maybe less than a second.

Here is a very old screenshot showing the tools success in visualizing millions of log lines over a time range in a single screen.

![ltl - very old screenshot](images/slt-30minutewindows.png)

`ltl`, or log timeline has come a long way since its initial release bacin early 2025.  The usage principle is basically to a) read log lines and try to establish the included time, b) also pull out message details and stats, c) filter in or out the lines based on provided command line options.  Use it to search for patterns, slowness, determine frequency and spacing of calls, and establish performance profile/baseline of your APIs or services.  See help for a list of all of the options and try them out yourself.

Static binary packages are provided for Windows, Ubuntu, and Mac OS.  Download, rename to ltl, and place somewhere in your path.

## Heatmap Visualization (v0.8.0)

The heatmap mode (`-hm` or `--heatmap`) replaces the latency statistics column with a visual heat distribution showing request density across latency ranges. This feature is inspired by SRE best practices for analyzing load profiles and latency distributions.

**Why heatmaps?** While percentile statistics (P50, P95, P99) are valuable, they reduce complex distributions to a few numbers. Heatmaps reveal:
- **Distribution shape**: Is latency bi-modal (cache hit/miss)? Multi-modal (different code paths)?
- **Outlier clustering**: Are slow requests evenly distributed or clustered at specific times?
- **Population density**: Where do most requests fall within the latency range?
- **Temporal patterns**: How does the distribution shift over time?

**Usage:**
```bash
# Duration heatmap (default)
./ltl --heatmap logs/access.log
./ltl -hm duration logs/access.log

# Bytes heatmap (response size distribution)
./ltl -hm bytes logs/access.log

# Count heatmap (request count distribution)
./ltl -hm count logs/access.log

# With highlight filter
./ltl -hm -highlight "POST /api" logs/access.log

# Custom width (default: 52, use >75 to show 25%/75% markers)
./ltl -hm -hmw 80 logs/access.log

# Light background terminal (auto-detected, or force with -lbg)
./ltl -hm -lbg logs/access.log
```

**Reading the heatmap:**
- **Position (left to right)**: Metric value (left = fast/small, right = slow/large)
- **Color intensity**: Request density (bright = many requests, dark = few requests)
- **Percentile markers**: `|` characters in gray show P50, P95, P99, P99.9 positions
- **Scale**: Header shows min/max values, footer shows 0%/25%/50%/75%/100% positions
- **Axis labels**: Each label shows the start of the range for that column (logarithmic scale)

**Color schemes:**
- Duration: Yellow gradient (dark gray → bright yellow)
- Bytes: Green gradient (dark gray → bright green)
- Count: Cyan gradient (dark gray → bright cyan)

**Light background support (v0.8.1):**
Terminal background color is auto-detected using OSC 11 query. On light/white backgrounds, the heatmap uses pale-to-bright color gradients instead of dark-gray-to-bright, improving visibility. Use `-lbg` or `--light-background` to explicitly force light background mode.

# Screenshots

## GC Analysis using Heatmap and Histogram

Here is a Full GC loop explored through zooming in on the specific time range, activating heatmap with 100 character width, enabling duration and bytes histograms, and setting the time-window bucking to 1 minute.

![Full GC loop explorered using heatmap and histogram views](images/gc-log-analysis_full-gc-loop_histogram-and-heatmap.png)


## Millisecond Precision (v0.10.3)

The `-ms` or `--milliseconds` flag enables sub-second timestamp parsing and display. When enabled:
- Timestamps are parsed with millisecond precision from logs (supports 1-6 fractional digits)
- Time buckets can be as small as 100ms
- Time filters (`-st`/`-et`) accept millisecond precision: `-st "12:34:56.500" -et "12:35:00.999"`

**Usage:**
```bash
# View log timeline with 100ms time buckets
./ltl -ms -bs 100 logs/application.log

# Filter to a specific sub-second time range
./ltl -ms -bs 100 -st "08:15:30.500" -et "08:15:31.250" logs/application.log

# Full date with milliseconds
./ltl -ms -st "2025-04-10 12:34:56.789" logs/application.log
```

