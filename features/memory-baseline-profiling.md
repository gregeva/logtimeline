# Memory Baseline Profiling (Issue #56)

## Purpose

Establish repeatable memory and performance baselines for ltl before the core architecture refactor (#23). Provides a machine-parseable benchmark data block via `-V` verbose output, a test runner to capture results as TSV, and a comparison tool to detect regressions.

## Design Decisions

### DD-01: Verbose output accumulator
All verbose output (regex info, histogram buckets, benchmark data) is collected in `@verbose_output` and printed via `print_verbose_output()` before the bar graph. This keeps verbose output grouped at the top of output.

### DD-02: Benchmark data block format
Machine-parseable TSV block delimited by `=== BENCHMARK DATA ===` / `=== END BENCHMARK DATA ===`. All values are raw (seconds for timing, bytes for memory). This block only appears when `-V` is used.

### DD-03: Per-structure memory requires `-mem`
Timing + RSS peak are always included in the benchmark block when `-V` is active. Per-structure HWMs require both `-V` and `-mem`.

### DD-04: Test runner output format
TSV with composite key (test_name + metric_name). Results stored in `tests/baseline/results/` and committed to git as reference baselines.

### DD-05: File metadata in benchmark block
`FILES` row includes semicolon-delimited paths and total file size in bytes, making results self-describing.

### DD-06: Cross-product test matrix
Test cases are the cross-product of file selections x option scenarios. This ensures every file selection is tested with every scenario combination for consistent and representative results.

### DD-07: Bucket size tied to file selection
Bucket size (`-bs`) is part of the file selection definition, not the scenario. Multi-day and month-long file sets need larger buckets (480 or 1440 minutes) for a deterministic and relevant number of time buckets.

### DD-08: Test suite tiers
- `full` (default) — 5 standard file selections x 7 scenarios = 35 tests
- `xl` — 2 extra-large file selections x 7 scenarios = 14 tests (run explicitly, too slow for routine use)
- `all` — all 7 file selections x 7 scenarios = 49 tests
- `quick` — single test case (`single-day-application-log-standard`) for dev/testing

### DD-09: Test naming convention
Test names describe file characteristics relevant to benchmarking (size, duration, format), not log content. Format: `{file-selection}-{scenario}`.

## File Selections

| # | Name | Files | Size | Base Options |
|---|------|-------|------|-------------|
| 1 | humungous-log-uniqueness | `ThingworxLogs/HundredsOfThousandsOfUniqueErrors.log` | 97 MB, 1 file | — |
| 2 | single-day-application-log | `ThingworxLogs/ApplicationLog.2025-05-05.0.log` | 85 MB, 1 file | — |
| 3 | multi-day-application-logs | `ThingworxLogs/archives/ApplicationLog*` | 315 MB, 41 files | `-bs 480` |
| 4 | multi-day-custom-logs | `ThingworxLogs/CustomThingworxLogs/ScriptLog.2025-*` | 463 MB, 5 files | — |
| 5 | single-day-access-log | `AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt` | 148 MB, 1 file | — |
| 6 | month-single-server-access-logs | `AccessLogs/really-big/*thingworx-1.2026-01-*` | 1.5 GB, 28 files | `-bs 1440` |
| 7 | month-many-servers-access-logs | `AccessLogs/really-big/*.2026-01-*` | 7.6 GB, 140 files | `-bs 1440` |

## Scenarios

| # | Name | Options | Description |
|---|------|---------|-------------|
| 1 | standard | — | Default, top 10 messages |
| 2 | top25 | `-n 25` | Top 25 messages |
| 3 | top25-consolidate | `-n 25 -g` | Top 25 with fuzzy message grouping |
| 4 | heatmap | `-hm` | Heatmap with default settings |
| 5 | histogram | `-hg` | Histogram(s) with default settings |
| 6 | heatmap-histogram | `-hm -hg` | Both heatmap and histogram(s) |
| 7 | heatmap-histogram-consolidate | `-hm -hg -g` | Heatmap, histogram(s), and message grouping |

## Acceptance Criteria

- [x] `@verbose_output` accumulator replaces direct `print` in existing verbose blocks
- [x] `print_verbose_output()` called before `print_bar_graph()` in MAIN
- [x] Benchmark data block includes version, files, lines, timing, and RSS
- [x] `-V -mem` additionally includes per-structure HWMs
- [x] Test runner captures benchmark data into TSV files
- [x] Comparison tool diffs two TSV files with deltas and % changes
- [x] Existing verbose output (regex info, histogram buckets) still appears correctly
- [x] Test matrix: 7 file selections x 7 scenarios = 49 test cases
- [ ] Initial v0.14.1 baseline captured and committed

## Progress

- [x] Phase 1: Feature doc
- [x] Phase 2: ltl verbose output refactor
- [x] Phase 3: Test runner script
- [x] Phase 4: Comparison tool
- [x] Phase 5: Test case definition (collaborative)
- [ ] Capture v0.14.1 baseline
