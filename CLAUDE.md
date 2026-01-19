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

When working on new features, follow this workflow to keep the project documentation current:

### 1. Planning & Research Phase
- Create a feature document in `features/<feature-name>.md` describing requirements, design decisions, and test plan
- Review existing TO-DO comments in `ltl` (lines 3-50) for related work
- Check `features/` directory for similar or dependent features

### 2. Implementation Phase
- Update the version number in `ltl` (line 75: `$version_number`) when making significant changes
- If adding new Perl modules, run `./build/generate-cpanfile.sh` to update dependency files
- For platform-specific code, ensure both Unix and Windows paths are handled

### 3. Testing Phase
- Test with sample log files in `logs/` directory
- Verify CSV output if `-o` flag behavior is affected
- Test on multiple platforms if changes involve platform-specific code

### 4. Documentation Updates
- Update `README.md` with new features and capabilities
- Update `features/<feature-name>.md` with implementation status and any deviations from the original plan
- Update TO-DO comments in `ltl` to mark completed items or add new ones
- Update this CLAUDE.md file if:
  - New data structures are added to the architecture
  - Build process changes
  - New command-line options are added
  - Known limitations change

### 5. Keeping CLAUDE.md Current
This file should reflect the current state of the project. When making changes:
- Add new key data structures to the Architecture section
- Update line number references if code reorganization shifts them significantly
- Document new build requirements or dependencies
- Add new known limitations discovered during development
