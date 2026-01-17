# Feature Requirements: Latency Statistics Quantile Optimization

## Branch
`latency-statistics-quantile-optimization`

## Overview
<!-- Provide a high-level description of the feature -->
The time bucket latency statistics display currently shows P50, P90, P95, and Z-score. This feature optimizes the quantile selection to better serve users investigating anomalies, high latency issues, and areas requiring deeper investigation. The display will be updated to show P50, P95, P99, and P99.9 - removing Z-score to make room for P99.9 which provides more actionable tail latency visibility.

## Background / Problem Statement
<!-- Describe the problem this feature solves or the need it addresses -->
The current percentile display (P50, P90, P95 + Z-score) does not optimally serve users investigating performance issues:
- P90 and P95 are close together and provide overlapping information
- Missing P99 which is the industry standard for SLO/SLA monitoring and reveals architectural bottlenecks
- Z-score takes valuable display space but is less actionable than P99.9 for anomaly detection
- Users need visibility into extreme tail behavior (P99.9) which is more meaningful than max value

### Industry Research Summary

Based on research from SRE and observability best practices:

**Recommended Percentile Tiers:**
1. **P50 (Median)** - Represents typical user experience; detects broad regressions
2. **P95** - Early warning for tail latency; commonly used in SLOs (e.g., "95% of requests under 300ms")
3. **P99** - Critical for exposing architectural bottlenecks, GC pauses, cold starts, lock contention
4. **P99.9** - Extreme tail visibility without max value noise; reveals rare but impactful outliers

**Key Insights:**
- P99 reveals rare friction points that P95 masks
- In distributed systems with multiple service calls, tail latency compounds significantly
- Max value can be misleading noise; P99.9 is more representative of extreme conditions
- P99.9 is more useful than Z-score for practical anomaly detection in log analysis

**Sources:**
- [OneUptime: P50 vs P95 vs P99 Latency Percentiles](https://oneuptime.com/blog/post/2025-09-15-p50-vs-p95-vs-p99-latency-percentiles/view)
- [Aerospike: What Is P99 Latency?](https://aerospike.com/blog/what-is-p99-latency/)
- [Last9: Tail Latency in Distributed Systems](https://last9.io/blog/tail-latency/)

## Goals
<!-- List the main goals of this feature -->
- Display P50, P95, P99, P99.9 percentiles in time bucket latency statistics
- Remove Z-score display to make room for P99.9
- Align with industry standard SRE/observability practices
- Provide complete tail latency visibility for anomaly detection
- Ensure display fits within terminal width without line wrapping

## Requirements

### Functional Requirements
<!-- List what the feature must do -->
1. Change time bucket latency statistics from P50, P90, P95, Z-score to P50, P95, P99, P99.9
2. Remove Z-score from the time bucket display (retain in CSV output)
3. Ensure all four percentiles fit within existing column width constraints
4. Maintain consistent color coding to differentiate percentile tiers

### Non-Functional Requirements
<!-- List performance, usability, compatibility, etc. requirements -->
- No performance impact (all percentiles already calculated)
- Display must not wrap lines on standard terminal widths
- Color coding must use coherent progression where red indicates worst/extreme tail:
  - P50: `cyan` (coolest - typical/median)
  - P95: `yellow` (warming - SLO threshold)
  - P99: `bright-yellow` (hot - bottleneck indicator)
  - P99.9: `red` (worst - extreme tail)

## User Stories
<!-- Describe the feature from the user's perspective -->
- As a Software Developer investigating slow requests, I want to see P99 latency so I can identify architectural bottlenecks affecting 1% of users
- As an SRE defining SLOs, I want to see P95 latency aligned with industry standard thresholds
- As a Performance Engineer, I want to see P99.9 to understand extreme tail latency without the noise of single max outliers

## Acceptance Criteria
<!-- Define what "done" looks like -->
- [x] Time bucket latency statistics display shows P50, P95, P99, P99.9
- [x] Z-score is removed from time bucket display
- [x] Display fits within terminal width without line wrapping
- [x] CSV output continues to include all calculated percentiles and Z-score
- [x] Color coding clearly differentiates the four percentile tiers (cyan→yellow→bright-yellow→red)

## Technical Considerations
<!-- Any technical notes, dependencies, or implementation considerations -->
- All percentiles (p1, p50, p75, p90, p95, p99, p999) are already calculated in calculate_statistics()
- Changes affect display in print_bar_chart_column() around lines 2037-2041
- Width calculation via `$durations_graph_width` in normalize_data_for_output() (line ~1534)
- CSV output remains unchanged (includes all percentiles and Z-score)

### Width Calculation
The key variable controlling latency statistics column width is `$durations_graph_width`:

```perl
# Latency statistics column width: │ + 2 spaces + P50(11) + P95(11) + P99(11) + P999(11) + CV(7) = 54 chars
$durations_graph_width = $print_durations && !$omit_durations && !$omit_stats ? $graph_column_padding_latency + 52 + $graph_column_padding_all : 0;
```

Where:
- `$graph_column_padding_latency` = 3 (for `│ + 2 spaces`)
- Content = 52 chars: P50(11) + P95(11) + P99(11) + P999(11) + CV(7) + trailing(1)
- `$graph_column_padding_all` = 1 (standard column padding)
- Total: 3 + 52 + 1 = 56 chars

### Display Format (lines 2037-2041)
Each percentile uses consistent 11-character width format:
```perl
P50:%-6s   # "P50:" (4) + value (6) + space (1) = 11 chars
P95:%-6s   # "P95:" (4) + value (6) + space (1) = 11 chars
P99:%-6s   # "P99:" (4) + value (6) + space (1) = 11 chars
P999:%-5s  # "P999:" (5) + value (5) + space (1) = 11 chars
CV:%4s     # "CV:" (3) + value (4) = 7 chars (no trailing space)
```

## Out of Scope
<!-- What is explicitly not included in this feature -->
- Message table percentile columns (separate consideration)
- Configurable percentile selection via command line
- Changes to CSV output columns
- Removal of Z-score calculation (keep for CSV)

## Testing Requirements
<!-- What testing is needed -->
**Test Command:**
```bash
COLUMNS=200 LINES=50 ./ltl -n 50 -dmin 50 -o logs/accessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-0*
```

**Before/After Verification:**

1. Run test command BEFORE changes and capture:
   - Screenshot/output of time bucket latency statistics display
   - STATS CSV output file
   - Verify no line wrapping occurs

2. Run test command AFTER changes and verify:
   - P50, P95, P99, P99.9 displayed (not P90, Z-score)
   - **CRITICAL: No line wrapping on time bucket rows - any wrapping is cause for complete failure**
   - STATS CSV still contains all percentiles including Z-score
   - Values are correct and match calculated percentiles

**Line Wrapping Test:**
- Test at terminal width 200 (COLUMNS=200)
- Each time bucket row must fit on a single line
- Verify the latency statistics column does not cause overflow
- Check that graph area width is not negatively impacted

## Documentation Requirements
<!-- What documentation needs to be updated -->
- Update any user documentation describing latency statistics output
- Note the change from P90 to P99 and addition of P99.9

## Notes
<!-- Any additional notes or considerations -->
- Z-score remains calculated and available in CSV output for users who need it
- The four percentiles (P50, P95, P99, P99.9) provide complete distribution visibility:
  - P50: What typical users experience
  - P95: Early tail warning (SLO threshold)
  - P99: Architectural issues affecting 1 in 100
  - P99.9: Extreme outliers affecting 1 in 1000
