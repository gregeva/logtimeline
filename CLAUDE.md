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

### Build Static Binaries (Local)
```bash
# macOS (specify architecture)
./build/macos-package.sh arm64    # Output: ltl_static-binary_macos-arm64
./build/macos-package.sh x86_64   # Output: ltl_static-binary_macos-x86_64

# Ubuntu/Linux (requires Docker)
./build/ubuntu-package.sh amd64   # Output: ltl_static-binary_ubuntu-amd64
./build/ubuntu-package.sh arm64   # Output: ltl_static-binary_ubuntu-arm64

# Windows (requires Docker + Wine)
./build/windows-package.sh        # Output: ltl_static-binary_windows-amd64.exe
```

### CI/CD Automated Builds

The project uses GitHub Actions for automated cross-platform builds. See `.github/workflows/release-build.yml`.

**Triggers:**
- Version tags (`v*`) - creates GitHub Release with all binaries attached
- `workflow_dispatch` - manual trigger for testing (no release created)

**Output Binaries (4 total):**
| Platform | Binary Name |
|----------|-------------|
| macOS ARM64 | `ltl_static-binary_macos-arm64` |
| Ubuntu amd64 | `ltl_static-binary_ubuntu-amd64` |
| Ubuntu arm64 | `ltl_static-binary_ubuntu-arm64` |
| Windows amd64 | `ltl_static-binary_windows-amd64.exe` |

**Manual Testing:**
```bash
# Trigger workflow manually
gh workflow run release-build.yml

# Watch progress
gh run watch

# Download artifacts from latest run
gh run download
```

## Release Process

### Overview
Every release requires a release notes file in the `releases/` folder. The workflow will fail if release notes are not found.

### Steps

1. **Update version number** in `ltl` (line 75: `$version_number`)

2. **Create release notes** at `releases/v{version}.md` (e.g., `releases/v0.8.2.md`):
   ```markdown
   ## What's New
   - Feature 1 description
   - Feature 2 description

   ## Bug Fixes
   - Fix 1 description

   ## Breaking Changes
   - Any breaking changes (or "None")

   ## Upgrade Notes
   - Migration instructions if needed (or "No special steps required")
   ```

3. **Commit changes** to feature branch

4. **Create PR and merge** to `main`

5. **Create and push version tag** from `main`:
   ```bash
   git checkout main && git pull
   git tag v0.8.2
   git push origin v0.8.2
   ```

6. **Workflow automatically**:
   - Builds all 4 binaries
   - Creates GitHub Release with your release notes
   - Attaches binaries to release

### Pre-Release Versions
Tags containing `-` are marked as pre-releases (e.g., `v0.8.2-beta`, `v0.8.2-rc1`).
Release notes are still required: `releases/v0.8.2-rc1.md`

```bash
git tag v0.8.2-rc1
git push origin v0.8.2-rc1
```

### Release Checklist
- [ ] Version number updated in `ltl` (line 75)
- [ ] Release notes created at `releases/v{version}.md`
- [ ] All tests pass locally
- [ ] Feature documentation updated in `features/`
- [ ] CLAUDE.md updated if architecture changed
- [ ] PR created, reviewed, and merged to `main`
- [ ] Tag created and pushed from `main` branch

### Verifying a Release
After the workflow completes:
```bash
# View the release
gh release view v0.8.2

# Download and test binaries
gh release download v0.8.2
./ltl_static-binary_macos-arm64 -version
```

### Troubleshooting
If the release workflow fails with "Release notes file not found":
1. Ensure `releases/v{version}.md` exists (e.g., `releases/v0.8.2.md`)
2. Commit and push the release notes file
3. Delete the tag and re-create it:
   ```bash
   git tag -d v0.8.2
   git push origin :refs/tags/v0.8.2
   git tag v0.8.2
   git push origin v0.8.2
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

### Directory Structure
```
logs/
├── AccessLogs/              # HTTP access logs (duration, bytes, status)
├── Codebeamber/             # Codebeamer access logs
└── ThingworxLogs/           # ThingWorx application logs
    └── CustomThingworxLogs/ # Custom ScriptLogs with durationMS
```

---

### AccessLogs/ - HTTP Request Logs (duration, bytes, status)

| File | Server | Latency Unit | Metrics | Size | Use Case |
|------|--------|--------------|---------|------|----------|
| `ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log` | Apache HTTP Server 2.x | microseconds (%D) | duration, bytes, count | 658KB | Apache HTTP2 with microsecond latency |
| `localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt` | Tomcat 9 | milliseconds (%D) | duration, bytes, count | 277MB | Primary Tomcat 9 access log test |
| `localhost_access_log-twx01-twx-thingworx-0.2025-05-06.txt` | Tomcat 9 | milliseconds (%D) | duration, bytes, count | 220MB | Secondary Tomcat 9 access log test |
| `localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt` | Tomcat 9 | milliseconds (%D) | duration, bytes, count | 148MB | Smaller Tomcat 9 access log test |
| `localhost_access_log.2025-03-21.txt` | Tomcat 9 | milliseconds (%D) | duration, bytes, count | 2.6MB | Small access log for quick tests |
| *(placeholder for Tomcat 11 logs)* | Tomcat 11 | milliseconds (%D) | duration, bytes, count | - | - |

**Format**: Apache combined log with duration at end (units vary by server)
```
# Apache HTTP Server 2.x - microseconds
127.0.0.1 - - [22/Jan/2026:08:49:51 +0000] "GET /path HTTP/1.1" 200 209 173542

# Tomcat 9 - milliseconds
10.224.34.60 - - [05/May/2025:00:00:00 +0000] "POST /path HTTP/1.1" 200 261 1
```
Fields: IP, -, -, [timestamp], "method path protocol", status_code, bytes, duration

**Note**: Apache HTTP Server uses `%D` for microseconds, while Tomcat uses `%D` for milliseconds. The ltl tool auto-detects the unit based on value ranges.

---

### Codebeamber/ - Codebeamer Access Logs

| File | Metrics | Size | Use Case |
|------|---------|------|----------|
| `codebeamer_access_log.2025-10-29.txt` | duration, bytes, count | 83KB | Codebeamer format testing |

**Format**: Apache-style with duration in brackets
```
127.0.0.1 - - [29/Oct/2025:08:03:31 +0000] "GET /hc/ping.spr HTTP/1.1" 200 112 [293ms] [0.293s]
```

---

### ThingworxLogs/ - ThingWorx Application Logs

All ThingWorx logs use this standard format:
```
2025-05-05 00:00:00.006+0000 [L: ERROR] [O: c.p.a.u.JobPurgeScheduler] [I: ] [U: SuperUser] [S: ] [P: ] [T: ThreadName] Message
```
Fields: timestamp [L: level] [O: origin] [I: instance] [U: user] [S: session] [P: process] [T: thread] message

#### ApplicationLog (General platform activity)
| File | Metrics | Size | Use Case |
|------|---------|------|----------|
| `ApplicationLog.2025-05-05.0.log` | count only | 85MB | Large Linux ApplicationLog |
| `ApplicationLog.2025-05-06.0.log` | count only | 6.5MB | Medium ApplicationLog |
| `ApplicationLog.2025-12-12.282-Windows.log` | count only | 10MB | Windows ApplicationLog |
| `ApplicationLog.log` | count only | 5.8MB | Current ApplicationLog |
| `ApplicationLog-improperlyRead.log` | count only | 468B | Edge case - malformed reads |

#### ScriptLog (Script execution logs)
| File | Metrics | Size | Use Case |
|------|---------|------|----------|
| `ScriptLog.2025-05-05.0.log` | count only | 13MB | Standard ScriptLog |
| `ScriptLog.2025-05-06.0.log` | count only | 15MB | Standard ScriptLog |
| `ScriptLog.2025-12-17.0.Rolex.log` | count only | 1.6MB | Basic ScriptLog test |
| `ScriptLog.log` | count only | 4.4MB | Current ScriptLog |

#### ErrorLog (Error-level messages)
| File | Metrics | Size | Use Case |
|------|---------|------|----------|
| `ErrorLog.2025-05-05.1.log` | count only | 61MB | Large error log (auth failures, etc.) |
| `ErrorLog.2025-05-06.0.log` | count only | 3.3MB | Medium error log |
| `ErrorLog.log` | count only | 3.7MB | Current error log |

#### SecurityLog (Security events)
| File | Metrics | Size | Use Case |
|------|---------|------|----------|
| `SecurityLog.2025-05-05.1.log` | count only | 70MB | Large security log (nonce rejections) |
| `SecurityLog.2025-05-06.0.log` | count only | 3.0MB | Medium security log |
| `SecurityLog.log` | count only | 3.6MB | Current security log |

#### ScriptErrorLog (Script-specific errors)
| File | Metrics | Size | Use Case |
|------|---------|------|----------|
| `ScriptErrorLog.2025-05-05.0.log` | count only | 14MB | Script error analysis |
| `ScriptErrorLog.2025-05-06.0.log` | count only | 14MB | Script error analysis |
| `ScriptErrorLog.log` | count only | 2.5MB | Current script errors |

#### DatabaseLog (Database operations)
| File | Metrics | Size | Use Case |
|------|---------|------|----------|
| `DatabaseLog.2025-05-05.0.log` | count only | 700KB | Database error tracking |
| `DatabaseLog.2025-05-06.0.log` | count only | 693KB | Database error tracking |
| `DatabaseLog.log` | count only | 29KB | Current database log |

#### AuthLog (Authentication events)
| File | Metrics | Size | Use Case |
|------|---------|------|----------|
| `AuthLog.2025-05-05.0.log` | count only | 324KB | SAML/SSO authentication events |
| `AuthLog.2025-05-06.0.log` | count only | 257KB | Authentication events |
| `AuthLog.log` | count only | 167KB | Current auth log |

#### ConfigurationLog (Configuration changes)
| File | Metrics | Size | Use Case |
|------|---------|------|----------|
| `ConfigurationLog.2025-05-05.0.log` | count only | 30KB | Configuration tracking |
| `ConfigurationLog.2025-05-06.0.log` | count only | 31KB | Configuration tracking |
| `ConfigurationLog.log` | count only | 31KB | Current configuration log |

#### Other ThingWorx Logs
| File | Metrics | Size | Use Case |
|------|---------|------|----------|
| `CommunicationLog.2025-05-06.0.log` | count only | 190B | Communication events (minimal) |
| `AkkaCommunicationLog.log` | count only | 2.2KB | Akka communication events |

---

### ThingworxLogs/CustomThingworxLogs/ - ScriptLogs with Full Metrics

These logs contain `durationMS=`, `result bytes=`, and `result count=` fields enabling all metric types for analysis and heatmaps.

| File | Metrics | Size | Use Case |
|------|---------|------|----------|
| `ScriptLog-DPMExtended-clean.log` | duration, bytes, count | 29MB | Cleaned DPM ScriptLog - ideal for all heatmap types |
| `ScriptLog.2025-04-09.1.log` | duration, bytes, count | 98MB | Large ScriptLog with full metrics |
| `ScriptLog.2025-04-09.2.log` | duration, bytes, count | 98MB | Large ScriptLog with full metrics |
| `ScriptLog.2025-04-09.3.log` | duration, bytes, count | 98MB | Large ScriptLog with full metrics |
| `ScriptLog.2025-04-09.4.log` | duration, bytes, count | 72MB | Large ScriptLog with full metrics |
| `ScriptLog.2025-04-10.0.log` | duration, bytes, count | 98MB | Large ScriptLog with full metrics |
| `ScriptLog.GetComplexPlotByIndex.log` | duration, bytes, count | 739KB | Specific service analysis |
| `ScriptLog.log` | duration, bytes, count | 54MB | ScriptLog with full metrics |

**Format**: ThingWorx ScriptLog with embedded metrics
```
2025-04-10 04:46:35.844+0000 [L: WARN] ... durationMS=167 events to be processed count=0
2025-04-10 05:00:03.529+0000 [L: INFO] ... durationMS=1041 result count=12 result bytes=6059
```

---

### Quick Test Commands

```bash
# Duration heatmap (access logs - best for latency analysis)
./ltl -hm duration logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt

# Bytes heatmap (access logs - response size distribution)
./ltl -hm bytes logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt

# Count heatmap (any log - message frequency distribution)
./ltl -hm count logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log

# Duration heatmap from ThingWorx ScriptLogs with durationMS
./ltl -hm duration logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log

# Standard bar graph (any log)
./ltl -n 5 logs/ThingworxLogs/ApplicationLog.2025-12-12.282-Windows.log

# Quick test with small access log
./ltl -n 10 logs/AccessLogs/localhost_access_log.2025-03-21.txt

# Error analysis
./ltl -n 20 logs/ThingworxLogs/ErrorLog.2025-05-05.1.log

# Security event analysis
./ltl -n 10 logs/ThingworxLogs/SecurityLog.2025-05-05.1.log

# Codebeamer access log
./ltl -hm duration logs/Codebeamber/codebeamer_access_log.2025-10-29.txt
```

### Logs by Use Case

| Use Case | Recommended Log Files |
|----------|----------------------|
| **Duration/latency heatmap** | `AccessLogs/*.txt`, `ThingworxLogs/CustomThingworxLogs/*` |
| **Bytes/response size analysis** | `AccessLogs/*.txt`, `ThingworxLogs/CustomThingworxLogs/*` |
| **Count/frequency analysis** | Any log file |
| **All three metrics (duration, bytes, count)** | `AccessLogs/*.txt`, `ThingworxLogs/CustomThingworxLogs/*` |
| **Error analysis** | `ThingworxLogs/ErrorLog.*`, `ThingworxLogs/ScriptErrorLog.*` |
| **Security events** | `ThingworxLogs/SecurityLog.*`, `ThingworxLogs/AuthLog.*` |
| **Database issues** | `ThingworxLogs/DatabaseLog.*` |
| **Quick tests (small files)** | `AccessLogs/localhost_access_log.2025-03-21.txt`, `Codebeamber/*`, `ThingworxLogs/CustomThingworxLogs/ScriptLog.GetComplexPlotByIndex.log` |
| **Large file stress tests** | `AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt`, `ThingworxLogs/CustomThingworxLogs/ScriptLog.2025-04-09.*.log` |

## Heatmap Visualization

### Background: SRE Best Practices

The heatmap feature is inspired by SRE best practices for analyzing load profiles and latency distributions. While percentile statistics (P50, P95, P99, P99.9) provide valuable insights, they reduce complex multi-modal distributions to a handful of numbers. Heatmaps address this by showing the entire distribution visually.

**Industry Research Sources:**
- **Brendan Gregg's Latency Heatmaps**: Heatmaps transform temporal latency data into visual representations where X-axis is time, Y-axis is latency ranges, and color intensity represents frequency/density. Bi-modal distributions become immediately visible, suggesting "fast path" and "slow path" behaviors.
- **Datadog Heatmap Engineering**: Distributing histogram boundaries approximately exponentially is effective for visualizing request distributions. Logarithmic scale is important for latency data spanning orders of magnitude.
- **Google SRE Monitoring**: The Four Golden Signals (latency, traffic, errors, saturation) are foundational. Latency distributions reveal more than averages.
- **ACM Queue**: Response time is crucial to understand in detail, but common presentations hide important patterns that heatmaps reveal.

**Key Implementation Insights:**
1. **Logarithmic bucket boundaries** work better for latency data than linear (values span orders of magnitude)
2. **Color intensity** represents request count/density (bright = many, dark = few)
3. **Fixed range** uses global min/max across all time buckets for consistent scale
4. **Position** tells you "at what latency", color tells you "how many requests"

### Heatmap Axes and Color Model

- **X-axis (horizontal position)**: Metric value range
  - Left edge = minimum value (fast requests / small responses / low count)
  - Right edge = maximum value (slow requests / large responses / high count)
- **Y-axis (rows)**: Time buckets (same as existing bar graph rows)
- **Color intensity**: Request COUNT/density at that value
  - Bright/intense color = MANY requests fell into this bucket
  - Dark/dim color = FEW requests fell into this bucket
  - Empty/space = NO requests at this level

### Color Gradients (256-color ANSI)

Each metric uses a 10-step gradient from dim (index 0) to bright (index 9).

**Dark Background (default)** - fades from dark gray to bright:
```perl
@yellow = (233, 234, 58, 94, 136, 142, 178, 184, 220, 226);   # Duration
@green  = (233, 234, 22, 28, 34, 40, 46, 82, 118, 154);       # Bytes
@cyan   = (233, 234, 23, 29, 30, 36, 37, 43, 44, 51);         # Count
```

**Light Background (`-lbg` flag)** - fades from pale to bright, avoids dark grays:
```perl
@yellow = (230, 229, 228, 227, 220, 214, 208, 202, 196, 226); # Duration
@green  = (194, 157, 156, 120, 84, 48, 47, 46, 82, 118);      # Bytes
@cyan   = (195, 159, 123, 87, 51, 50, 49, 43, 44, 51);        # Count
```

Terminal background is auto-detected using OSC 11 query when heatmap is enabled. Use `-lbg` or `--light-background` to explicitly force light background mode (overrides auto-detection).

### Logarithmic Bucket Boundaries

Formula: `boundary[i] = min * (max/min)^(i/num_buckets)`

For a 52-column heatmap with latency range 1ms to 100,000ms:
- Bucket 0: ~1ms
- Bucket 26: ~316ms (geometric midpoint)
- Bucket 52: ~100,000ms

Log scale provides better resolution at low values where most latency data clusters.

### Terminal Rendering

**256-Color ANSI Codes:**
- Foreground: `ESC[38;5;⟨n⟩m`
- Background: `ESC[48;5;⟨n⟩m`
- Color cube (216 colors): indices 16-231, formula: `16 + 36×r + 6×g + b` (0 ≤ r,g,b ≤ 5)
- Grayscale: indices 232-255 (24 shades)

**Unicode Block Characters:**
- U+2588 `█` - Full block (used for all density levels with color-only approach)
- U+2591 `░` - Light shade (~25%)
- U+2592 `▒` - Medium shade (~50%)
- U+2593 `▓` - Dark shade (~75%)

**Rendering Approach:** Color-only with full blocks (`█`) - provides clean appearance and universal terminal compatibility.

### Highlight Support

When `-highlight` is used with `-hm`, highlighted requests use background colors matching bar graph column `plain_bg` values:
- Duration: 184 (yellow background)
- Bytes: 34 (green background)
- Count: 30 (cyan background)

Foreground color (density) remains the same, allowing users to see both: which requests matched the filter AND their density.

## Active Feature Branches

### feature/heatmap
**Status**: Implementation complete (v0.8.0)

Adds heatmap visualization mode (`-hm`/`--heatmap`) replacing duration statistics with color-intensity histogram.

**Command Line Options**:
- `-hm` or `--heatmap [duration|bytes|count]` - Enable heatmap mode (default: duration)
- `-hmw` or `--heatmap-width <N>` - Set heatmap width (default: 52)
- `-lbg` or `--light-background` - Use light background color gradients (for white/light terminals)

**Key Features**:
- Logarithmic scale for better latency distribution visualization
- Percentile markers (P50, P95, P99, P99.9) shown as `|` in gray
- Header scale with min/max values (25%/75% markers when width > 75)
- Footer scale with value labels at 0%, 25%, 50%, 75%, 100% positions
- Color gradients: yellow (duration), green (bytes), cyan (count)
- Auto-detection of terminal background color (light/dark) using OSC 11
- Light background mode (`-lbg`) for terminals with white/light backgrounds
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
