# Current Version & Release Notes

2026-01-21 : v0.8.1 - fixes heatmap axis alignment, adds light background terminal support with auto-detection

2026-01-20 : v0.8.0 - adds heatmap visualization mode for SRE-grade latency distribution analysis

2025-12-09 : v0.6.0 - introduces many column support architecture with dynamic layout and column padding

# Tools

These scripts and other resources are built to speed and facilitate debugging, diagnostics, and likely other things.

## llt : Log Time Line

Have you ever wished that you could quickly identify areas of interest or hotspots in very large log files so that you could navigate there directly?  That's what this timeline view is for!!

When dealing with logs which have a very large amount of lines/errors/whatever, it can be quite hard to get an overall view of the file while looking at a screen full of lines representing maybe less than a second.

![ltl](images/slt-30minutewindows.png)

ltl, or log time line has come a long way since its initial release a few months ago.  The usage principle is basically to a) read log lines and try to establish the included time, b) also pull out message details and stats, c) filter in or out the lines based on provided command line options.  Use it to search for patterns, slowness, determine frequency and spacing of calls, and establish performance profile/baseline of your APIs or services.  See help for a list of all of the options and try them out yourself.

Static binary packages are provided for Windows, Ubuntu, and Mac OS.  Download, rename to ltl, and place somewhere in your path.

### Heatmap Visualization (v0.8.0)

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

## cleanlogs : removes unwanted lines and partial lines to faciliate analysis

Partial lines where one node or thread have written over another log appender make programmatic analysis of logs quite challenging.  Similarly useless things like when there is a multi-line output like a thread dump or nuissance aspects like 100's of thousands of health probes.

Clean logs takes care of some of these scenarios, outputting a "clean" version of one or many log files.

## twxsummarize : ThingWorx Log Summary tool

Similar to the above, this tool is not time-based, but instead groups and summarizes ThingWorx log lines using the common log pattern from Logback.  This helps to answer questions like if certain subsystems are starting to have errors all of a sudden, or if errors present where your diagnostic efforts should focus.

![twxsummarize](images/twxsummarize-10lines-2files.png)

In a future release I'll add other capabilities like a message grouping view.

## Known Issues

- **Millisecond Precision Not Supported:**
  Although the application allows for selection of millisecond precision, reading and comparing timestamps with millisecond precision does not work at present. All timestamp parsing and comparison is currently performed at the second level, so any features or filters relying on millisecond accuracy will not function as expected.

