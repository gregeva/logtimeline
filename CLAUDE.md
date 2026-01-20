# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LogTimeLine (ltl) is a Perl-based command-line log analysis tool that identifies hotspots in large log files through statistical analysis and time-bucket visualization. It displays horizontal bar graphs with color-coded performance bands and calculates percentile latency statistics (P1 through P99.9).

The repository contains three tools:
- **ltl** - Main analysis tool (single Perl script, ~2,500 lines)
- **cleanlogs** - Bash helper that removes stack traces, partial lines, and health probes
- **twxsummarize** - ThingWorx-specific log summarizer

## Build Commands

### Install Dependencies (macOS)
```bash
brew install cpanminus
cpanm PAR::Packer
cd build && ./generate-cpanfile.sh && cpanm --notest --installdeps .
```

### Install Dependencies (Ubuntu/Linux)
```bash
sudo apt-get install build-essential perl perl-base perl-modules libperl-dev cpanminus
cpanm PAR::Packer
cd build && ./generate-cpanfile.sh && cpanm --notest --installdeps .
```

### Build Static Binaries
```bash
# macOS ARM64
cd build && ./macos-package.sh    # Output: ltl_static-binary_macos-arm64

# Ubuntu amd64 (requires Docker)
cd build && ./ubuntu-package.sh   # Output: ltl_static-binary_ubuntu-amd64

# Windows (requires Rancher Desktop + Wine)
cd build && ./windows-package.sh  # Output: ltl_static-binary_windows-amd64.exe
```

### Run Directly
```bash
./ltl [options] <logfile(s)>
```

Key options: `-n N` (top N messages), `-b N` (bucket size minutes), `-o` (CSV output), `-dmin/-dmax` (duration filters), `-include/-exclude` (pattern filters), `-help` (full help)

## Architecture

### Code Structure (ltl)
The main script is organized into three sections:
- **GLOBALS** (lines 74-232): Version, configuration, data structures, command-line options
- **SUBS** (lines 235-2498): Processing and output subroutines
- **MAIN** (lines 2499+): Execution flow

### Key Data Structures
- `%log_occurrences` - Count tallies across time buckets
- `%log_analysis` - Time bucket statistics
- `%log_messages` - Message groupings
- `%log_stats` - Statistical calculations (min/max/avg/stddev/percentiles)
- `%log_threadpools` / `%threadpool_activity` - Thread pool tracking
- `%log_userdefinedmetrics` - Custom metrics framework
- `%heatmap_data` - Histogram bucket counts per time bucket for heatmap visualization
- `@heatmap_boundaries` - Pre-calculated logarithmic/linear bucket boundaries (array has bucket_count+1 elements; boundaries[0]=min, boundaries[bucket_count]=max)

### Output Column Layout System

The bar graph output uses a sophisticated column layout system with spacing and padding. Understanding this is critical for alignment.

**Key Width Variables:**
- `$terminal_width` - Total terminal width (e.g., 120)
- `$timestamp_length` - Width allocated for timestamp column
- `$legend_length` - Width allocated for legend column (log level counts)
- `$max_graph_width` - Space for all bar graph columns (calculated as `$terminal_width - $legend_length - $timestamp_length - $durations_graph_width`)
- `$durations_graph_width` - Width for heatmap/statistics column (= `$graph_column_padding_latency + $heatmap_width + $graph_column_padding_all`)
- `%graph_width` - Hash mapping column numbers to their allocated widths

**Padding Constants (line ~90):**
- `$graph_column_padding_all = 1` - Trailing padding after all columns
- `$graph_column_padding_timestamp = 1` - Padding for timestamp column
- `$graph_column_padding_legend = 0` - Padding for legend column
- `$graph_column_padding_count = 2` - Padding for count column (includes `│` separator)
- `$graph_column_padding_other = 1` - Padding for other metric columns
- `$graph_column_padding_latency = 3` - Padding before heatmap/latency column

**Column Separator Behavior:**
- The `│` character is used as a column separator
- For the heatmap column: `│` (1 char) + space (1 char padding) + content (`$heatmap_width` chars) + trailing space (1 char)
- The `$printed_chars` variable tracks how many characters have been printed on the current line
- Missing padding is calculated as: `$terminal_width - $printed_chars - $durations_graph_width`

**Heatmap Column Structure:**
When heatmap is enabled, the heatmap column replaces the latency statistics column:
- Separator: `│` (1 char)
- Padding: ` ` (1 space)
- Content: heatmap data or scale values (`$heatmap_width` chars, default 52)
- Trailing: ` ` (1 space)

**Footer Alignment:**
The footer scale must align with the heatmap data rows:
- Footer uses `┴` at the same position as the data row's `│`
- Scale content starts after one padding character (like the space after `│`)
- Scale labels at 0% position should left-align with first heatmap column
- Scale labels at 100% position should right-align with last heatmap column

**Boundary Array Indexing:**
For a heatmap with N display columns (default 52):
- `@heatmap_boundaries` has N+1 elements (indices 0 through N)
- `boundaries[0]` = minimum value
- `boundaries[N]` = maximum value
- Display column i covers range `[boundaries[i], boundaries[i+1])`
- To get the value at 100% position, use `boundaries[N]`, NOT `boundaries[N-1]`

### Core Processing Flow
1. `adapt_to_command_line_options()` - Parse command line
2. `read_and_process_logs()` - Stream log files, extract timestamps/messages
3. `calculate_all_statistics()` / `calculate_statistics()` - Compute statistics per bucket
4. `normalize_data_for_output()` - Prepare display data
5. `print_bar_graph()` - Render time-bucket visualization
6. `print_summary_table()` / `print_message_summary()` - Output statistics

### Platform-Specific Code
- Unix: Uses `Proc::ProcessTable` for memory tracking
- Windows: Uses `Win32::Process::Info` instead
- Platform detection via `$^O eq 'MSWin32'`
- Separate cpanfiles: `build/cpanfile` (Unix) and `build/cpanfile.windows`

## Development Notes

### Dependency Management
Run `./build/generate-cpanfile.sh` to regenerate cpanfile from script imports. It scans `use`/`require` statements and filters platform-specific modules.

### Feature Documentation
Feature requirements and test plans are in `features/` directory. Recent features include quantile optimization and custom metrics framework.

### Known Limitations
- Millisecond precision not yet supported (second-level only)
- Long filenames with many filters can exceed filesystem limits
- CSV output may skip metrics when using `-ov` flag

### TO-DO Items
Active development items are documented in comments at the top of the `ltl` script (lines 3-50), including data model refactoring, heatmap visualization, and additional log format support.

## Feature Development Workflow

When working on new features, follow this workflow to keep the project documentation current. **This workflow is mandatory** - always check and update feature documentation as you progress through each phase.

### 1. Planning & Research Phase
- Create a feature document in `features/<feature-name>.md` describing requirements, design decisions, and test plan
- Review existing TO-DO comments in `ltl` (lines 3-50) for related work
- Check `features/` directory for similar or dependent features
- For features requiring prototyping:
  - Create prototypes in `prototype/` directory
  - Document design decisions and questions in `prototype/<FEATURE>-DECISIONS.md`
  - Collect user feedback on decisions before proceeding
- Create implementation plan in `features/<feature-name>-implementation-plan.md` with:
  - Data structures and their locations
  - Integration points in the codebase
  - Step-by-step implementation order
  - Test cases and acceptance criteria

### 2. Scheduling Phase
- Review implementation plan with user
- Confirm implementation order and dependencies
- Update feature document progress tracking section

### 3. Implementation Phase
- Update the version number in `ltl` (line 75: `$version_number`) when making significant changes
- If adding new Perl modules, run `./build/generate-cpanfile.sh` to update dependency files
- For platform-specific code, ensure both Unix and Windows paths are handled
- **Update feature document progress tracking** as each task is completed

### 4. Testing Phase
- Test with sample log files in `logs/` directory
- Verify CSV output if `-o` flag behavior is affected
- Test on multiple platforms if changes involve platform-specific code
- **Update feature document** with test results and any issues found

### 5. Validation Phase
- Verify all acceptance criteria are met
- Verify visual output matches prototypes (if applicable)
- Verify compatibility with existing command-line flags
- **Update feature document** validation status

### 6. Documentation Updates
- Update `README.md` with new features and capabilities
- Update `features/<feature-name>.md` with implementation status and any deviations from the original plan
- Update TO-DO comments in `ltl` to mark completed items or add new ones
- Update this CLAUDE.md file if:
  - New data structures are added to the architecture
  - Build process changes
  - New command-line options are added
  - Known limitations change

### 7. Keeping Documentation Current
**IMPORTANT**: Always ensure decisions and current status are reflected in the feature documentation:
- `features/<feature-name>.md` - Main feature document with requirements, decisions, and progress tracking
- `features/<feature-name>-implementation-plan.md` - Detailed implementation plan (if created)
- `prototype/<FEATURE>-DECISIONS.md` - Design decisions from prototyping phase (if applicable)

When resuming work on a feature:
1. Read the feature document to understand current state
2. Check the progress tracking section for what's completed and what's next
3. Update progress tracking as you work
4. Ensure any new decisions or changes are documented before ending the session

## Test Log Files

The `logs/` directory contains sample log files for testing. **Always use these known files for testing - do not search for log files.**

### Access Logs (HTTP request logs with duration, bytes, status)
| File | Metrics Available | Size | Use Case |
|------|-------------------|------|----------|
| `logs/accessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt` | duration, bytes, count | 277MB | Primary access log test (duration: 1ms-8.6m range) |
| `logs/accessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-06.txt` | duration, bytes, count | 220MB | Secondary access log test |
| `logs/accessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt` | duration, bytes, count | 148MB | Smaller access log test |

**Format**: Apache combined log with duration in milliseconds at end
```
10.224.34.60 - - [05/May/2025:00:00:00 +0000] "POST /path HTTP/1.1" 200 261 1
```
Fields: IP, -, -, [timestamp], "method path protocol", status_code, bytes, duration_ms

### CustomThingworxLogs (ScriptLogs with duration, count, bytes)
| File | Metrics Available | Size | Use Case |
|------|-------------------|------|----------|
| `logs/CustomThingworxLogs/ScriptLog-clean.log` | duration, count | 29MB | Cleaned ScriptLog (durationMS: 167ms-1186ms) |
| `logs/CustomThingworxLogs/ScriptLog.2025-04-09.1.log` | duration, count | 98MB | Large ScriptLog with durationMS |
| `logs/CustomThingworxLogs/ScriptLog.2025-04-09.2.log` | duration, count | 98MB | Large ScriptLog with durationMS |
| `logs/CustomThingworxLogs/ScriptLog.2025-04-09.3.log` | duration, count | 98MB | Large ScriptLog with durationMS |
| `logs/CustomThingworxLogs/ScriptLog.2025-04-09.4.log` | duration, count | 72MB | Large ScriptLog with durationMS |
| `logs/CustomThingworxLogs/ScriptLog.2025-04-10.0.log` | duration, count | 98MB | Large ScriptLog with durationMS |
| `logs/CustomThingworxLogs/ScriptLog.log` | duration, count | 54MB | ScriptLog with durationMS |

**Format**: ThingWorx ScriptLog format with embedded durationMS
```
2025-04-10 04:46:35.844+0000 [L: WARN] ... durationMS=167 events to be processed count=0
```

### Other Script/Application Logs
| File | Metrics Available | Size | Use Case |
|------|-------------------|------|----------|
| `logs/ScriptLog.2025-12-17.0.log` | count only | 1.6MB | Basic ScriptLog without duration |

**Format**: ThingWorx log format
```
2025-04-10 04:46:35.844+0000 [L: WARN] [O: ...] [T: ...] message
```

### Application Logs (INFO/WARN/ERROR categories)
| File | Metrics Available | Size | Use Case |
|------|-------------------|------|----------|
| `logs/ApplicationLog.2025-12-12.282-Windows.log` | count only | 10MB | Windows ApplicationLog (no duration data) |

**Format**: ThingWorx ApplicationLog format
```
2025-12-12 15:38:13.648+0100 [L: INFO] [O: c.t.t.c.RemoteThing] ...
```

### Quick Test Commands
```bash
# Duration heatmap (access logs)
./ltl -hm duration logs/accessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt

# Bytes heatmap (access logs)
./ltl -hm bytes logs/accessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt

# Count heatmap (script logs - no duration data needed)
./ltl -hm count logs/CustomThingworxLogs/ScriptLog-clean.log

# Standard bar graph (any log)
./ltl -n 5 logs/ApplicationLog.2025-12-12.282-Windows.log
```

## Active Feature Branches

### feature/heatmap
**Status**: Implementation complete (v0.8.0)

Adds heatmap visualization mode (`-hm`/`--heatmap`) replacing duration statistics with color-intensity histogram.

**Command Line Options**:
- `-hm` or `--heatmap [duration|bytes|count]` - Enable heatmap mode (default: duration)
- `-hmw` or `--heatmap-width <N>` - Set heatmap width (default: 52)

**Key Features**:
- Logarithmic scale (default) for better latency distribution visualization
- Percentile markers (P50, P95, P99, P99.9) shown as `|` in gray
- Footer scale with value labels at 0%, 25%, 50%, 75%, 100% positions
- Color gradients: yellow (duration), green (bytes), cyan (count)
- Highlight support with background colors

**Key Files**:
- `features/heatmap.md` - Feature requirements and acceptance criteria
- `features/heatmap-implementation-plan.md` - Implementation plan
- `prototype/HEATMAP-DECISIONS.md` - Design decisions

**Known Issues Fixed (v0.8.0)**:
- **Footer 100% boundary value**: Must use `$heatmap_boundaries[$heatmap_content_width]` not `[$heatmap_content_width - 1]` - the boundaries array has bucket_count+1 elements
- **format_bytes() float handling**: Use `int($bytes)` for unit length comparison, not the raw float value (floats like `801.000765678898` have string length 16, exceeding TB threshold)
- **Heatmap width affecting layout**: When heatmap is enabled, `$durations_graph_width` must use `$heatmap_width`, not hardcoded 52
- **Highlight background colors**: Use same colors as bar graph column `plain_bg` values (184 yellow, 34 green, 30 cyan) for visual consistency
