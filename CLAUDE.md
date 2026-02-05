# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Collaboration Model

**This is a co-authoring relationship.** The user is the architect and decision-maker. Claude is an active collaborator who contributes ideas, challenges assumptions, and helps discover the right path through dialog.

### Core Principles

1. **The way is found on the path.** We discover the right approach through iteration. Don't try to solve everything upfront. Take small steps, learn from each one.
2. **Challenge and contribute.** Bring ideas to the table. Question assumptions. Push back when something seems wrong.
3. **Ask, don't assume.** When uncertain about approach, scope, or priority - ask.
4. **Small steps with confirmation.** Present one idea or change at a time. Wait for confirmation before proceeding.
5. **No unsolicited implementation.** Do not write production code until explicitly asked.
6. **Dialog over monologue.** Keep responses concise. If writing more than a few paragraphs, stop and ask a clarifying question instead.

### Anti-patterns to Avoid

- Writing code "to show what it would look like" without being asked
- Making architectural decisions independently then defending them
- Lengthy explanations when a question would suffice
- Trying to solve everything in one pass instead of iterating

### Continuous Improvement

Track observations for process improvement. After releases, review what worked and what caused friction. Update CLAUDE.md with agreed changes.

**Observations log:**
- 2026-02-02: CRITICAL - Always use `--disable-progress` when running ltl from Claude Code. Progress output wastes massive tokens/cost. This was discovered after months of wasteful execution.
- 2026-02-03: Release workflow - Feature branches need PRs before merging to release branch. Create PR from release branch to main. Never use `--delete-branch` when merging release PRs - release branches must be preserved.
- 2026-02-03: After tagging a release, always create the GitHub release with `gh release create <tag> --notes-file releases/<version>.md` to attach release notes.
- 2026-02-03: When stuck on technical issues (e.g., floating-point precision), ask the user rather than iterating through failed attempts. The user often has quick answers.
- 2026-02-03: For sub-second time buckets in Perl, use integer milliseconds for hash keys to avoid floating-point precision issues (e.g., `.099` instead of `.100`).
- 2026-02-05: When updating issues with fix completion, always include the commit hash and branch name.

## Project Overview

LogTimeLine (ltl) is a Perl-based command-line log analysis tool that identifies hotspots in large log files through statistical analysis and time-bucket visualization. It displays horizontal bar graphs with color-coded performance bands and calculates percentile latency statistics (P1 through P99.9).

The repository contains three tools:
- **ltl** - Main analysis tool (single Perl script, ~2,500 lines)
- **cleanlogs** - Bash helper that removes stack traces, partial lines, and health probes
- **twxsummarize** - ThingWorx-specific log summarizer

## Build Commands

### Install Dependencies
```bash
# macOS
brew install cpanminus && cpanm PAR::Packer
cd build && ./generate-cpanfile.sh && cpanm --notest --installdeps .

# Ubuntu/Linux
sudo apt-get install build-essential perl perl-base perl-modules libperl-dev cpanminus
cpanm PAR::Packer
cd build && ./generate-cpanfile.sh && cpanm --notest --installdeps .
```

### Build Static Binaries
```bash
./build/macos-package.sh arm64|x86_64    # macOS
./build/ubuntu-package.sh amd64|arm64    # Linux (requires Docker)
./build/windows-package.sh               # Windows (requires Docker + Wine)
```

### CI/CD
GitHub Actions builds all platforms on version tags (`v*`). See `.github/workflows/release-build.yml`.

## Release Process

**CRITICAL: Follow these steps exactly. Do not skip steps or change the order.**

### Pre-release (for each feature/bugfix branch)
1. Commit all changes to feature branch
2. Push feature branch: `git push origin {feature-branch}`
3. Update GitHub issue with completion comment

### Create Release
4. Switch to main: `git checkout main && git pull origin main`
5. Create release branch: `git checkout -b release/X.Y.Z` (no `v` prefix)
6. Merge each feature/bugfix branch: `git merge {branch-name} --no-edit` (repeat for all branches going into this release)
7. Update version in `ltl` (line 74: `$version_number`)
8. Create release notes: `releases/v{version}.md` (include all features/fixes)
9. Commit: `git commit -am "Release vX.Y.Z"`
10. Push release branch: `git push -u origin release/X.Y.Z`
11. Tag and push: `git tag vX.Y.Z && git push origin vX.Y.Z`

### Post-release
12. Merge to main: `git checkout main && git merge release/X.Y.Z --no-edit && git push origin main`
13. Close all issues included in release: `gh issue close {number} --reason completed`
14. **Delete all merged feature branches**: `git branch -d {branch} && git push origin --delete {branch}` (repeat for each)

### Run Directly
```bash
./ltl [options] <logfile(s)>
```

Key options: `-n N` (top N messages), `-b N` (bucket size minutes), `-o` (CSV output), `-dmin/-dmax` (duration filters), `-include/-exclude` (pattern filters), `-if/-ef/-hf` (pattern files), `-du` (duration unit), `-hm` (heatmap), `-ms` (millisecond precision), `-st/-et` (time range filters, supports milliseconds), `-help` (full help)

**Hidden option for Claude Code:** `--disable-progress` - ALWAYS use this flag when running ltl to suppress progress output that wastes tokens.

## Architecture

### Code Structure (ltl)
- **GLOBALS** (lines 74-232): Version, configuration, data structures, command-line options
- **SUBS** (lines 235-2498): Processing and output subroutines
- **MAIN** (lines 2499+): Execution flow

### Key Data Structures
- `%log_occurrences` - Count tallies across time buckets
- `%log_analysis` - Time bucket statistics
- `%log_messages` - Message groupings
- `%log_stats` - Statistical calculations (min/max/avg/stddev/percentiles)
- `%heatmap_data` - Histogram bucket counts per time bucket
- `@heatmap_boundaries` - Logarithmic bucket boundaries (N+1 elements for N columns)

### Output Column Layout
The bar graph uses a column layout system with multiple width variables and padding constants. For detailed technical documentation, see `features/column-layout-refactor.md` (issue #33).

### Core Processing Flow
1. `adapt_to_command_line_options()` - Parse command line
2. `read_and_process_logs()` - Stream log files, extract timestamps/messages
3. `calculate_all_statistics()` - Compute statistics per bucket
4. `normalize_data_for_output()` - Prepare display data
5. `print_bar_graph()` - Render time-bucket visualization
6. `print_summary_table()` - Output statistics

### Platform-Specific Code
- Unix: Uses `Proc::ProcessTable` for memory tracking
- Windows: Uses `Win32::Process::Info` instead
- Platform detection via `$^O eq 'MSWin32'`

## Development Workflow

Each issue gets its own branch: `{issue-number}-{short-description}`. **CRITICAL: Verify branch before making code changes.** Do not write production code until implementation plan is approved.

### Branch Verification (MANDATORY FIRST STEP)
```bash
git branch --show-current  # Must match issue number
```

### GitHub Issue Updates (MANDATORY)
Update issues throughout development: when starting, during investigation, on design decisions, and when complete. Close with `gh issue close <number> --reason completed`.

### Development Phases
1. **Planning**: Create feature doc in `features/`, review existing TO-DOs, create implementation plan
2. **Prototyping** (non-trivial features): Validate approach in `prototype/` directory first
3. **Scheduling**: Get explicit user approval before implementation
4. **Implementation**: Update feature doc progress as you work
5. **Testing**: Use sample files in `logs/` directory (see `docs/test-logs.md`)
6. **Documentation**: Update help text, CLAUDE.md if architecture changed, close GitHub issue

## Pattern Files

The `patterns/` directory contains filter patterns for `-if`, `-ef`, and `-hf` options:
- `metrics` - ThingWorx metrics endpoints
- `navigate-app-calls` - Windchill Navigate API calls
- `probes` - Health check endpoints
- `thingworx` - ThingWorx-specific patterns

## Test Log Files

See `docs/test-logs.md` for detailed documentation of available test files.

**Quick reference:**
- **Quick tests**: `logs/AccessLogs/localhost_access_log.2025-03-21.txt` (2.6MB)
- **Heatmap tests**: `logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log`
- **Large file tests**: `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt` (277MB)

## Heatmap Feature

Heatmap mode (`-hm duration|bytes|count`) replaces latency statistics with color-intensity histogram visualization.

**Options**: `-hm [metric]`, `-hmw <width>` (default 52), `-lbg` (light background)

**Color gradients**: yellow (duration), green (bytes), cyan (count). Uses logarithmic bucket boundaries for better resolution at low values.

For implementation details, see `features/heatmap.md`.
