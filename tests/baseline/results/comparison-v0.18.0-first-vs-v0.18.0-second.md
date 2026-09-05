
## Benchmark Comparison

  Baseline:    v0.18.0-first (v0.18.0, 70 test cases)
  Current:     v0.18.0-second (v0.18.0, 77 test cases)

### Timing Delta

| # | file selection | standard | no-msgs | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons | sort-p99 | sort-skew | hm+hg+export |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | -0.9% | +4.4% | -1.7% | -1.7% | -2.3% | -3.7% | -0.0% | -0.2% | -1.2% | -1.3% | - |
| 2. | single-day-application-log | +2.8% | +2.0% | -0.5% | +0.9% | +1.2% | +1.2% | +0.2% | +0.9% | +0.4% | +0.8% | - |
| 3. | multi-day-application-logs | +1.1% | +3.2% | +1.7% | -0.3% | -0.6% | -0.3% | +1.5% | +0.3% | +0.5% | +2.0% | - |
| 4. | multi-day-custom-logs | +0.4% | +2.2% | -0.4% | -2.1% | -0.6% | -0.8% | -0.6% | -0.9% | -1.7% | -3.4% | - |
| 5. | single-day-access-log | -4.6% | -2.6% | -4.4% | -4.9% | -4.8% | -5.2% | -4.2% | -4.4% | -5.0% | -6.3% | - |
| 6. | month-single-server-access-logs | -6.0% | -4.4% | -5.4% | -5.6% | -4.8% | -5.8% | -5.1% | -6.1% | -6.5% | -5.7% | - |
| 7. | month-many-servers-access-logs | -5.4% | -3.4% | -5.3% | -2.0% | -3.4% | -2.7% | -2.1% | -0.5% | -3.9% | -3.1% | - |

### Memory Delta (RSS Peak)

| # | file selection | standard | no-msgs | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons | sort-p99 | sort-skew | hm+hg+export |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | -16.0% | +24.1% | -15.6% | +2.9% | -15.7% | -16.2% | -15.7% | +3.4% | -15.4% | -15.7% | - |
| 2. | single-day-application-log | +22.2% | +23.6% | +22.8% | +6.3% | +21.8% | +22.2% | +20.3% | +6.4% | +21.6% | +20.5% | - |
| 3. | multi-day-application-logs | +3.7% | +23.9% | +3.8% | +3.7% | +4.0% | +4.1% | +2.4% | +3.5% | +3.8% | +3.9% | - |
| 4. | multi-day-custom-logs | +2.7% | +11.7% | +2.1% | +1.3% | +2.9% | +2.2% | +2.0% | +2.7% | +2.1% | +2.5% | - |
| 5. | single-day-access-log | +4.1% | +7.1% | +2.8% | +2.6% | +4.4% | +3.6% | +5.0% | +3.8% | +3.0% | +3.3% | - |
| 6. | month-single-server-access-logs | -16.4% | +1.2% | -16.2% | +0.0% | -23.6% | -16.2% | -23.5% | +0.7% | -20.0% | -20.3% | - |
| 7. | month-many-servers-access-logs | -13.4% | +0.2% | -13.2% | -0.0% | -22.3% | -13.1% | -19.4% | -3.4% | -19.5% | -18.2% | - |

### Stage Rollup (timing)

| metric | baseline | current | delta | change% | cases +/- | result |
| --- | --- | --- | --- | --- | --- | --- |
| parse/read_files | 127.4 min | 134.5 min | +7.1 min | 5.6% | 19/51 | REGRESS (most cases IMPROVE) |
| finalize/group_similar | 32.7 min | 32.8 min | +4.1 s | 0.2% | 4/10 | REGRESS (most cases IMPROVE) |
| finalize/calculate_statistics | 6.4 min | 6.5 min | +7.4 s | 1.9% | 4/48 | REGRESS (most cases IMPROVE) |
| finalize/calculate_statistics/bucket_stats (within parent) | 2.5 min | 2.7 min | +11.9 s | 7.9% | 0/26 | REGRESS (most cases IMPROVE) |
| finalize/calculate_statistics/population_walk (within parent) | 1.2 min | 1.2 min | -1.2 s | -1.6% | 2/6 | IMPROVE |
| finalize/calculate_statistics/sort_selection (within parent) | 1.4 min | 1.4 min | -1.2 s | -1.4% | 11/32 | IMPROVE |
| finalize/calculate_statistics/group_calc (within parent) | 1.1 min | 1.1 min | -1.4 s | -2.1% | 2/25 | IMPROVE |
| finalize/calculate_statistics/untimed (within parent) | 4.5 s | 3.7 s | -748 ms | -16.7% | 2/21 | IMPROVE |
| finalize/heatmap_statistics | 947 ms | 1.6 s | +660 ms | 69.7% | 0/9 | REGRESS (most cases IMPROVE) |
| total | 166.5 min | 173.8 min | +7.3 min | 4.4% | 19/51 | REGRESS (most cases IMPROVE) |
| (3 below noise floor) | 980 ms | 1.1 s | +116 ms | 11.8% | - | REGRESS |
| (1 below noise floor) (within parent) | 289 ms | 310 ms | +21 ms | 7.3% | - | REGRESS |
| sum of stages | 166.5 min | 173.8 min | +7.3 min | 4.4% | - | REGRESS |

### Category Rollup (memory)

| metric | baseline | current | delta | change% | cases +/- | result |
| --- | --- | --- | --- | --- | --- | --- |
| rss_peak | 140.2 GB | 124.2 GB | -16.0 GB | -11.4% | 47/23 | IMPROVE (most cases REGRESS) |
| log_messages | 99.1 GB | 77.5 GB | -21.6 GB | -21.8% | 0/63 | IMPROVE |
| log_analysis | 24.6 GB | 28.1 GB | +3.5 GB | 14.3% | 0/40 | REGRESS (most cases IMPROVE) |
| unattributed | 12.0 GB | 14.2 GB | +2.2 GB | 18.8% | 56/10 | REGRESS |
| format_scan_subs | 55.1 MB | 72.7 MB | +17.6 MB | 32.0% | 68/2 | REGRESS |
| log_sessions | 171.5 MB | 188.6 MB | +17 MB | 9.9% | 4/5 | REGRESS (most cases IMPROVE) |
| heatmap_counters | 19.8 MB | 26.5 MB | +6.6 MB | 33.3% | 3/2 | REGRESS |
| consolidation_key_trigrams_norm | 302.1 MB | 308.6 MB | +6.5 MB | 2.2% | 4/0 | REGRESS |
| consolidation_clusters | 6.4 GB | 6.4 GB | -1.2 MB | -0.0% | 0/14 | IMPROVE |
| (25 below noise floor) | 1.3 GB | 1.3 GB | +1.5 MB | 0.1% | - | REGRESS |

### New In This Version

| metric | test cases | per-test range | aggregate |
| --- | --- | --- | --- |
| (none) | - | - | - |

### Summary

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.7 s | 2.7 s | -24 ms | -0.9% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 255.9 MB | 215.0 MB | -41.0 MB | -16.0% | IMPROVE |
| humungous-log-uniqueness-no-messages | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | TIMING/total | 1.8 s | 1.9 s | +81 ms | 4.4% | REGRESS |
| humungous-log-uniqueness-no-messages | MEMORY/rss_peak | 28.9 MB | 35.8 MB | +7.0 MB | 24.1% | REGRESS |
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.7 s | 2.7 s | -46 ms | -1.7% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 255.7 MB | 215.8 MB | -39.9 MB | -15.6% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 10.8 s | 10.6 s | -181 ms | -1.7% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 254.0 MB | 261.4 MB | +7.5 MB | 2.9% | REGRESS |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.7 s | 2.6 s | -61 ms | -2.3% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 256.0 MB | 215.8 MB | -40.2 MB | -15.7% | IMPROVE |
| humungous-log-uniqueness-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.7 s | 2.6 s | -99 ms | -3.7% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 255.9 MB | 214.4 MB | -41.5 MB | -16.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.6 s | 2.6 s | -1 ms | -0.0% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 255.7 MB | 215.4 MB | -40.2 MB | -15.7% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 10.2 s | 10.2 s | -25 ms | -0.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 253.9 MB | 262.5 MB | +8.5 MB | 3.4% | REGRESS |
| humungous-log-uniqueness-sort-p99 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/total | 2.6 s | 2.6 s | -31 ms | -1.2% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | MEMORY/rss_peak | 255.6 MB | 216.1 MB | -39.5 MB | -15.4% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/total | 2.6 s | 2.6 s | -34 ms | -1.3% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | MEMORY/rss_peak | 255.8 MB | 215.7 MB | -40.1 MB | -15.7% | IMPROVE |
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.4 s | 3.5 s | +96 ms | 2.8% | REGRESS |
| single-day-application-log-standard | MEMORY/rss_peak | 32.7 MB | 39.9 MB | +7.2 MB | 22.2% | REGRESS |
| single-day-application-log-no-messages | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-no-messages | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-no-messages | TIMING/total | 3.0 s | 3 s | +58 ms | 2.0% | REGRESS |
| single-day-application-log-no-messages | MEMORY/rss_peak | 29.2 MB | 36 MB | +6.9 MB | 23.6% | REGRESS |
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.5 s | 3.5 s | -17 ms | -0.5% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 32.5 MB | 39.9 MB | +7.4 MB | 22.8% | REGRESS |
| single-day-application-log-top25-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 6.3 s | 6.3 s | +59 ms | 0.9% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 121.7 MB | 129.4 MB | +7.7 MB | 6.3% | REGRESS |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.5 s | 3.5 s | +42 ms | 1.2% | REGRESS |
| single-day-application-log-heatmap | MEMORY/rss_peak | 32.6 MB | 39.8 MB | +7.1 MB | 21.8% | REGRESS |
| single-day-application-log-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.5 s | 3.5 s | +41 ms | 1.2% | REGRESS |
| single-day-application-log-histogram | MEMORY/rss_peak | 32.7 MB | 39.9 MB | +7.3 MB | 22.2% | REGRESS |
| single-day-application-log-heatmap-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.5 s | 3.5 s | +6 ms | 0.2% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 32.9 MB | 39.6 MB | +6.7 MB | 20.3% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 6.3 s | 6.3 s | +55 ms | 0.9% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 121.7 MB | 129.4 MB | +7.8 MB | 6.4% | REGRESS |
| single-day-application-log-sort-p99 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/total | 3.5 s | 3.5 s | +14 ms | 0.4% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY/rss_peak | 32.7 MB | 39.7 MB | +7 MB | 21.6% | REGRESS |
| single-day-application-log-sort-skewness | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/total | 3.5 s | 3.5 s | +27 ms | 0.8% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY/rss_peak | 32.9 MB | 39.6 MB | +6.8 MB | 20.5% | REGRESS |
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 7.6 s | 7.7 s | +81 ms | 1.1% | REGRESS |
| multi-day-application-logs-standard | MEMORY/rss_peak | 97.2 MB | 100.8 MB | +3.6 MB | 3.7% | REGRESS |
| multi-day-application-logs-no-messages | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | TIMING/total | 6.2 s | 6.4 s | +199 ms | 3.2% | REGRESS |
| multi-day-application-logs-no-messages | MEMORY/rss_peak | 30.1 MB | 37.3 MB | +7.2 MB | 23.9% | REGRESS |
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 7.5 s | 7.6 s | +126 ms | 1.7% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 97.1 MB | 100.8 MB | +3.7 MB | 3.8% | REGRESS |
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 40.3 s | 40.2 s | -130 ms | -0.3% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 207.1 MB | 214.7 MB | +7.6 MB | 3.7% | REGRESS |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 7.6 s | 7.6 s | -43 ms | -0.6% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 97.1 MB | 101 MB | +3.9 MB | 4.0% | REGRESS |
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 7.6 s | 7.6 s | -25 ms | -0.3% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 97.0 MB | 101.0 MB | +4 MB | 4.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 7.5 s | 7.6 s | +111 ms | 1.5% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 98.5 MB | 100.8 MB | +2.3 MB | 2.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 40.2 s | 40.3 s | +105 ms | 0.3% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 207.7 MB | 215 MB | +7.3 MB | 3.5% | REGRESS |
| multi-day-application-logs-sort-p99 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/total | 7.5 s | 7.6 s | +39 ms | 0.5% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY/rss_peak | 97.1 MB | 100.8 MB | +3.7 MB | 3.8% | REGRESS |
| multi-day-application-logs-sort-skewness | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/total | 7.5 s | 7.7 s | +152 ms | 2.0% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY/rss_peak | 97.1 MB | 100.9 MB | +3.8 MB | 3.9% | REGRESS |
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 16 s | 16.1 s | +58 ms | 0.4% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 195.2 MB | 200.5 MB | +5.2 MB | 2.7% | REGRESS |
| multi-day-custom-logs-no-messages | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | TIMING/total | 12.6 s | 12.9 s | +284 ms | 2.2% | REGRESS |
| multi-day-custom-logs-no-messages | MEMORY/rss_peak | 63.3 MB | 70.7 MB | +7.4 MB | 11.7% | REGRESS |
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 16.1 s | 16.1 s | -64 ms | -0.4% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 196.5 MB | 200.7 MB | +4.1 MB | 2.1% | REGRESS |
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 53.6 s | 52.4 s | -1.1 s | -2.1% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 246.3 MB | 249.5 MB | +3.2 MB | 1.3% | REGRESS |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 16.7 s | 16.6 s | -97 ms | -0.6% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 181.5 MB | 186.7 MB | +5.2 MB | 2.9% | REGRESS |
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 17.0 s | 16.8 s | -136 ms | -0.8% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 196.1 MB | 200.5 MB | +4.4 MB | 2.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 17.4 s | 17.3 s | -103 ms | -0.6% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 184.9 MB | 188.6 MB | +3.7 MB | 2.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 55.0 s | 54.5 s | -472 ms | -0.9% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 233.5 MB | 239.7 MB | +6.2 MB | 2.7% | REGRESS |
| multi-day-custom-logs-sort-p99 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/total | 16.3 s | 16 s | -285 ms | -1.7% | IMPROVE |
| multi-day-custom-logs-sort-p99 | MEMORY/rss_peak | 193.6 MB | 197.8 MB | +4.2 MB | 2.1% | REGRESS |
| multi-day-custom-logs-sort-skewness | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/total | 16.6 s | 16 s | -569 ms | -3.4% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY/rss_peak | 193.1 MB | 197.9 MB | +4.8 MB | 2.5% | REGRESS |
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 9.9 s | 9.4 s | -455 ms | -4.6% | IMPROVE |
| single-day-access-log-standard | MEMORY/rss_peak | 145.0 MB | 150.8 MB | +5.9 MB | 4.1% | REGRESS |
| single-day-access-log-no-messages | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-no-messages | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-no-messages | TIMING/total | 7.6 s | 7.4 s | -195 ms | -2.6% | IMPROVE |
| single-day-access-log-no-messages | MEMORY/rss_peak | 89.5 MB | 95.8 MB | +6.4 MB | 7.1% | REGRESS |
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 9.8 s | 9.4 s | -430 ms | -4.4% | IMPROVE |
| single-day-access-log-top25 | MEMORY/rss_peak | 146.9 MB | 151 MB | +4.1 MB | 2.8% | REGRESS |
| single-day-access-log-top25-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 15.7 s | 14.9 s | -768 ms | -4.9% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 180.2 MB | 184.9 MB | +4.7 MB | 2.6% | REGRESS |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 10.6 s | 10.1 s | -507 ms | -4.8% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/rss_peak | 116.2 MB | 121.3 MB | +5.1 MB | 4.4% | REGRESS |
| single-day-access-log-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 12 s | 11.4 s | -626 ms | -5.2% | IMPROVE |
| single-day-access-log-histogram | MEMORY/rss_peak | 145.8 MB | 150.9 MB | +5.2 MB | 3.6% | REGRESS |
| single-day-access-log-heatmap-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 12.5 s | 12.0 s | -520 ms | -4.2% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 115.8 MB | 121.5 MB | +5.8 MB | 5.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 17.1 s | 16.3 s | -749 ms | -4.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 155.3 MB | 161.2 MB | +5.9 MB | 3.8% | REGRESS |
| single-day-access-log-sort-p99 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/total | 10.0 s | 9.5 s | -498 ms | -5.0% | IMPROVE |
| single-day-access-log-sort-p99 | MEMORY/rss_peak | 145.5 MB | 149.8 MB | +4.3 MB | 3.0% | REGRESS |
| single-day-access-log-sort-skewness | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/total | 10.1 s | 9.5 s | -642 ms | -6.3% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY/rss_peak | 149.9 MB | 154.8 MB | +5.0 MB | 3.3% | REGRESS |
| month-single-server-access-logs-standard | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/total | 1.9 min | 1.8 min | -6.8 s | -6.0% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2.8 GB | 2.4 GB | -475.4 MB | -16.4% | IMPROVE |
| month-single-server-access-logs-no-messages | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | TIMING/total | 1.4 min | 1.3 min | -3.7 s | -4.4% | IMPROVE |
| month-single-server-access-logs-no-messages | MEMORY/rss_peak | 643.5 MB | 651.3 MB | +7.8 MB | 1.2% | REGRESS |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 1.9 min | 1.8 min | -6.1 s | -5.4% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2.8 GB | 2.4 GB | -472.5 MB | -16.2% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 4.3 min | 4 min | -14.2 s | -5.6% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 1.4 GB | 1.4 GB | +176 KB | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/total | 2 min | 1.9 min | -5.7 s | -4.8% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 2.6 GB | 1.9 GB | -616.8 MB | -23.6% | IMPROVE |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/total | 2.3 min | 2.1 min | -8.0 s | -5.8% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 2.8 GB | 2.4 GB | -470.8 MB | -16.2% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.4 min | 2.2 min | -7.2 s | -5.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 2.5 GB | 1.9 GB | -612.3 MB | -23.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 4.2 min | 4.0 min | -15.5 s | -6.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 1.1 GB | 1.1 GB | +7.7 MB | 0.7% | REGRESS |
| month-single-server-access-logs-sort-p99 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | TIMING/total | 2 min | 1.9 min | -7.9 s | -6.5% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/rss_peak | 3 GB | 2.4 GB | -619.4 MB | -20.0% | IMPROVE |
| month-single-server-access-logs-sort-skewness | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/total | 1.9 min | 1.8 min | -6.6 s | -5.7% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/rss_peak | 3.0 GB | 2.4 GB | -614.5 MB | -20.3% | IMPROVE |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/total | 9.5 min | 9.0 min | -30.7 s | -5.4% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 13.9 GB | 12 GB | -1.9 GB | -13.4% | IMPROVE |
| month-many-servers-access-logs-no-messages | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | TIMING/total | 6.9 min | 6.7 min | -14.2 s | -3.4% | IMPROVE |
| month-many-servers-access-logs-no-messages | MEMORY/rss_peak | 3.3 GB | 3.3 GB | +8.1 MB | 0.2% | REGRESS |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/total | 9.5 min | 9 min | -30.2 s | -5.3% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 14 GB | 12.2 GB | -1.8 GB | -13.2% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 28.7 min | 28.2 min | -34.1 s | -2.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 6.4 GB | 6.4 GB | -1.1 MB | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/total | 9.8 min | 9.5 min | -20.0 s | -3.4% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 12.1 GB | 9.4 GB | -2.7 GB | -22.3% | IMPROVE |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/total | 11.3 min | 11.0 min | -18.5 s | -2.7% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 14.0 GB | 12.2 GB | -1.8 GB | -13.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 11.5 min | 11.3 min | -14.2 s | -2.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 12.1 GB | 9.8 GB | -2.4 GB | -19.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 26.0 min | 25.8 min | -7.3 s | -0.5% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 4.4 GB | 4.3 GB | -154.7 MB | -3.4% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | TIMING/total | 10 min | 9.7 min | -23.8 s | -3.9% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/rss_peak | 15.5 GB | 12.4 GB | -3 GB | -19.5% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | TIMING/total | 9.5 min | 9.2 min | -17.8 s | -3.1% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY/rss_peak | 14.7 GB | 12 GB | -2.7 GB | -18.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-export | lines_read | N/A | 288,025 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | lines_included | N/A | 288,025 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/total | N/A | 1.9 s | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/rss_peak | N/A | 36.0 MB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | lines_read | N/A | 479,904 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | lines_included | N/A | 479,904 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | TIMING/total | N/A | 3.1 s | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/rss_peak | N/A | 36.1 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | lines_read | N/A | 930,031 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | lines_included | N/A | 930,028 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | TIMING/total | N/A | 6.3 s | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/rss_peak | N/A | 37.6 MB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | lines_read | N/A | 1,530,399 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | lines_included | N/A | 1,530,399 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/total | N/A | 14.6 s | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/rss_peak | N/A | 73.7 MB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | lines_read | N/A | 761,698 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | lines_included | N/A | 761,698 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/total | N/A | 10.6 s | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/rss_peak | N/A | 100.6 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | lines_included | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/total | N/A | 2.0 min | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/rss_peak | N/A | 653.8 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/total | N/A | 9.8 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/rss_peak | N/A | 3.3 GB | N/A | N/A | ? |

### Detailed

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/detect/scan_sub_compile | 4 ms | 5 ms | +1 ms | 25.0% | REGRESS |
| humungous-log-uniqueness-standard | TIMING/parse/read_files | 2.4 s | 2.4 s | -1000 us | -0.0% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics | 338 ms | 315 ms | -23 ms | -6.8% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics/sort_selection | 326 ms | 302 ms | -24 ms | -7.4% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics/untimed | 12 ms | 13 ms | +1000 us | 8.3% | REGRESS |
| humungous-log-uniqueness-standard | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.7 s | 2.7 s | -24 ms | -0.9% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 255.9 MB | 215.0 MB | -41.0 MB | -16.0% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/format_scan_subs | 864 KB | 1 MB | +160 KB | 18.5% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_messages | 172.9 MB | 127 MB | -45.9 MB | -26.5% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/unattributed | 82.1 MB | 86.9 MB | +4.8 MB | 5.8% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY_FINAL/log_messages | 181317591 | 133188237 | -48129354 | -26.5% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | COUNTS/log_messages_entries | 286659 | 286659 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | COUNTS/log_messages_population | 286659 | 286659 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-no-messages | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-no-messages | TIMING/parse/read_files | 1.8 s | 1.9 s | +81 ms | 4.4% | REGRESS |
| humungous-log-uniqueness-no-messages | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-no-messages | TIMING/total | 1.8 s | 1.9 s | +81 ms | 4.4% | REGRESS |
| humungous-log-uniqueness-no-messages | MEMORY/rss_peak | 28.9 MB | 35.8 MB | +7.0 MB | 24.1% | REGRESS |
| humungous-log-uniqueness-no-messages | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/format_scan_subs | 864 KB | 912 KB | +48 KB | 5.6% | REGRESS |
| humungous-log-uniqueness-no-messages | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/log_messages | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/unattributed | 28 MB | 34.9 MB | +6.9 MB | 24.6% | REGRESS |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/log_messages | 232 | 232 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/detect/scan_sub_compile | 4 ms | 5 ms | +1 ms | 25.0% | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/parse/read_files | 2.4 s | 2.4 s | -26 ms | -1.1% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics | 334 ms | 313 ms | -21 ms | -6.3% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics/sort_selection | 321 ms | 301 ms | -20 ms | -6.2% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.7 s | 2.7 s | -46 ms | -1.7% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 255.7 MB | 215.8 MB | -39.9 MB | -15.6% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/format_scan_subs | 864 KB | 1 MB | +192 KB | 22.2% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_messages | 172.9 MB | 127 MB | -45.9 MB | -26.5% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/message_key_order | 7.7 KB | 7.7 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/unattributed | 81.9 MB | 87.7 MB | +5.8 MB | 7.1% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/log_messages | 181317591 | 133188237 | -48129354 | -26.5% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | COUNTS/log_messages_entries | 286659 | 286659 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | COUNTS/log_messages_population | 286659 | 286659 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/parse/read_files | 6.6 s | 6.5 s | -96 ms | -1.5% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | TIMING/finalize/group_similar | 4.2 s | 4.1 s | -84 ms | -2.0% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 10.8 s | 10.6 s | -181 ms | -1.7% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 254.0 MB | 261.4 MB | +7.5 MB | 2.9% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_clusters | 196.7 KB | 196.2 KB | -506 B | -0.3% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_message | 3.1 MB | 3.1 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_trigrams | 71.7 MB | 71.7 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 64.2 MB | 64.2 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_ngram_index | 66.7 MB | 66.7 MB | +1.5 KB | 0.0% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_patterns | 24.8 KB | 24.8 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_posting_size | 614.1 KB | 614.1 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | 1.7 MB | +64 B | 0.0% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/format_scan_subs | 848 KB | 960 KB | +112 KB | 13.2% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_messages | 3.3 MB | 2.5 MB | -818.5 KB | -24.0% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/message_key_order | 9.4 KB | 9.4 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/unattributed | 41.6 MB | 49.7 MB | +8.2 MB | 19.6% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/log_messages | 104691 | 100953 | -3738 | -3.6% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 201387 | 200881 | -506 | -0.3% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 25391 | 25391 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 232 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | 65592 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_messages_entries | 72 | 72 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_messages_population | 72 | 72 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/parse/read_files | 2.3 s | 2.3 s | -38 ms | -1.6% | IMPROVE |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics | 336 ms | 313 ms | -23 ms | -6.8% | IMPROVE |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 323 ms | 301 ms | -22 ms | -6.8% | IMPROVE |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.7 s | 2.6 s | -61 ms | -2.3% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 256.0 MB | 215.8 MB | -40.2 MB | -15.7% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/format_scan_subs | 880 KB | 1 MB | +144 KB | 16.4% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_messages | 172.9 MB | 127 MB | -45.9 MB | -26.5% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/unattributed | 82.2 MB | 87.7 MB | +5.6 MB | 6.8% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/log_messages | 181317591 | 133188237 | -48129354 | -26.5% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | COUNTS/log_messages_entries | 286659 | 286659 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | COUNTS/log_messages_population | 286659 | 286659 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/parse/read_files | 2.4 s | 2.3 s | -82 ms | -3.4% | IMPROVE |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics | 312 ms | 294 ms | -18 ms | -5.8% | IMPROVE |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics/sort_selection | 300 ms | 281 ms | -19 ms | -6.3% | IMPROVE |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.7 s | 2.6 s | -99 ms | -3.7% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 255.9 MB | 214.4 MB | -41.5 MB | -16.2% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/format_scan_subs | 944 KB | 1 MB | +80 KB | 8.5% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_messages | 172.9 MB | 127 MB | -45.9 MB | -26.5% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/unattributed | 82.1 MB | 86.4 MB | +4.3 MB | 5.2% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/log_messages | 181317591 | 133188237 | -48129354 | -26.5% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | COUNTS/log_messages_entries | 286659 | 286659 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | COUNTS/log_messages_population | 286659 | 286659 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/parse/read_files | 2.3 s | 2.3 s | -10 ms | -0.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics | 295 ms | 304 ms | +9 ms | 3.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 283 ms | 292 ms | +9 ms | 3.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.6 s | 2.6 s | -1 ms | -0.0% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 255.7 MB | 215.4 MB | -40.2 MB | -15.7% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/format_scan_subs | 864 KB | 976 KB | +112 KB | 13.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_messages | 172.9 MB | 127 MB | -45.9 MB | -26.5% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/unattributed | 81.9 MB | 87.4 MB | +5.5 MB | 6.8% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/log_messages | 181317591 | 133188237 | -48129354 | -26.5% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | COUNTS/log_messages_entries | 286659 | 286659 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | COUNTS/log_messages_population | 286659 | 286659 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/parse/read_files | 6.3 s | 6.3 s | -28 ms | -0.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 3.9 s | 3.9 s | +3 ms | 0.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 10.2 s | 10.2 s | -25 ms | -0.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 253.9 MB | 262.5 MB | +8.5 MB | 3.4% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 196.5 KB | 196.2 KB | -378 B | -0.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 3.1 MB | 3.1 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 71.7 MB | 71.7 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 64.2 MB | 64.2 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 66.7 MB | 66.7 MB | +8.6 KB | 0.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 24.8 KB | 24.8 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 614.1 KB | 614.1 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | 1.7 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 880 KB | 992 KB | +112 KB | 12.7% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_messages | 3.3 MB | 2.5 MB | -818.5 KB | -24.0% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/message_key_order | 3.2 KB | 3.2 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/unattributed | 41.5 MB | 50.7 MB | +9.2 MB | 22.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 104691 | 100953 | -3738 | -3.6% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 201259 | 200881 | -378 | -0.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 25391 | 25391 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 232 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | 65592 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 72 | 72 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_messages_population | 72 | 72 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/parse/read_files | 2.3 s | 2.3 s | -23 ms | -1.0% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics | 313 ms | 304 ms | -9 ms | -2.9% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 300 ms | 292 ms | -8 ms | -2.7% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 13 ms | 12 ms | -1000 us | -7.7% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/total | 2.6 s | 2.6 s | -31 ms | -1.2% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | MEMORY/rss_peak | 255.6 MB | 216.1 MB | -39.5 MB | -15.4% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/format_scan_subs | 848 KB | 944 KB | +96 KB | 11.3% | REGRESS |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_messages | 172.9 MB | 127 MB | -45.9 MB | -26.5% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/unattributed | 81.8 MB | 88.2 MB | +6.4 MB | 7.8% | REGRESS |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/log_messages | 181317591 | 133188237 | -48129354 | -26.5% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | COUNTS/log_messages_entries | 286659 | 286659 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | COUNTS/log_messages_population | 286659 | 286659 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/parse/read_files | 2.3 s | 2.3 s | -23 ms | -1.0% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics | 307 ms | 296 ms | -11 ms | -3.6% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 294 ms | 283 ms | -11 ms | -3.7% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/total | 2.6 s | 2.6 s | -34 ms | -1.3% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | MEMORY/rss_peak | 255.8 MB | 215.7 MB | -40.1 MB | -15.7% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/format_scan_subs | 848 KB | 912 KB | +64 KB | 7.5% | REGRESS |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_messages | 172.9 MB | 127 MB | -45.9 MB | -26.5% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/unattributed | 82 MB | 87.7 MB | +5.7 MB | 7.0% | REGRESS |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/log_messages | 181317591 | 133188237 | -48129354 | -26.5% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | COUNTS/log_messages_entries | 286659 | 286659 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | COUNTS/log_messages_population | 286659 | 286659 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/parse/read_files | 3.4 s | 3.5 s | +95 ms | 2.8% | REGRESS |
| single-day-application-log-standard | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.4 s | 3.5 s | +96 ms | 2.8% | REGRESS |
| single-day-application-log-standard | MEMORY/rss_peak | 32.7 MB | 39.9 MB | +7.2 MB | 22.2% | REGRESS |
| single-day-application-log-standard | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/format_scan_subs | 832 KB | 992 KB | +160 KB | 19.2% | REGRESS |
| single-day-application-log-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_messages | 2.8 MB | 2.7 MB | -41.7 KB | -1.5% | IMPROVE |
| single-day-application-log-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/unattributed | 29 MB | 36.1 MB | +7.1 MB | 24.5% | REGRESS |
| single-day-application-log-standard | MEMORY_FINAL/log_messages | 2914814 | 2872100 | -42714 | -1.5% | IMPROVE |
| single-day-application-log-standard | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-standard | COUNTS/log_messages_entries | 6512 | 6512 | 0 | 0.0% |  |
| single-day-application-log-standard | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-standard | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-standard | COUNTS/log_messages_population | 6512 | 6512 | 0 | 0.0% |  |
| single-day-application-log-standard | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-application-log-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-standard | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-standard | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-standard | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-no-messages | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-no-messages | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-no-messages | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| single-day-application-log-no-messages | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| single-day-application-log-no-messages | TIMING/parse/read_files | 3.0 s | 3 s | +58 ms | 2.0% | REGRESS |
| single-day-application-log-no-messages | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-no-messages | TIMING/total | 3.0 s | 3 s | +58 ms | 2.0% | REGRESS |
| single-day-application-log-no-messages | MEMORY/rss_peak | 29.2 MB | 36 MB | +6.9 MB | 23.6% | REGRESS |
| single-day-application-log-no-messages | MEMORY/bucket_outcomes | 5.8 KB | 6 KB | +256 B | 4.3% | REGRESS |
| single-day-application-log-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/format_scan_subs | 864 KB | 1008 KB | +144 KB | 16.7% | REGRESS |
| single-day-application-log-no-messages | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/log_messages | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/log_occurrences | 21.5 KB | 21.8 KB | +256 B | 1.2% | REGRESS |
| single-day-application-log-no-messages | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/unattributed | 28.3 MB | 35 MB | +6.7 MB | 23.8% | REGRESS |
| single-day-application-log-no-messages | MEMORY_FINAL/log_messages | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-no-messages | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-no-messages | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-no-messages | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-no-messages | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-application-log-no-messages | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-no-messages | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-no-messages | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-no-messages | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-no-messages | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/parse/read_files | 3.5 s | 3.5 s | -17 ms | -0.5% | IMPROVE |
| single-day-application-log-top25 | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.5 s | 3.5 s | -17 ms | -0.5% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 32.5 MB | 39.9 MB | +7.4 MB | 22.8% | REGRESS |
| single-day-application-log-top25 | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/format_scan_subs | 864 KB | 1008 KB | +144 KB | 16.7% | REGRESS |
| single-day-application-log-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_messages | 2.8 MB | 2.7 MB | -41.7 KB | -1.5% | IMPROVE |
| single-day-application-log-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/message_key_order | 6.4 KB | 6.4 KB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/unattributed | 28.9 MB | 36.2 MB | +7.3 MB | 25.3% | REGRESS |
| single-day-application-log-top25 | MEMORY_FINAL/log_messages | 2914814 | 2872100 | -42714 | -1.5% | IMPROVE |
| single-day-application-log-top25 | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-top25 | COUNTS/log_messages_entries | 6512 | 6512 | 0 | 0.0% |  |
| single-day-application-log-top25 | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-top25 | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-top25 | COUNTS/log_messages_population | 6512 | 6512 | 0 | 0.0% |  |
| single-day-application-log-top25 | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-application-log-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-top25 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-top25 | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-top25 | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/parse/read_files | 6 s | 6.1 s | +63 ms | 1.0% | REGRESS |
| single-day-application-log-top25-consolidate | TIMING/finalize/group_similar | 257 ms | 253 ms | -4 ms | -1.6% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 6.3 s | 6.3 s | +59 ms | 0.9% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 121.7 MB | 129.4 MB | +7.7 MB | 6.3% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_clusters | 441.8 KB | 437.5 KB | -4.3 KB | -1.0% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_message | 2.6 MB | 2.6 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_trigrams | 29.3 MB | 29.3 MB | +1 KB | 0.0% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 16.4 MB | 16.4 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_ngram_index | 29.7 MB | 29.7 MB | +1.8 KB | 0.0% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_patterns | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_posting_size | 860.9 KB | 860.9 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_unmatched | 1.5 MB | 1.5 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/format_scan_subs | 816 KB | 912 KB | +96 KB | 11.8% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_messages | 2.3 MB | 2.3 MB | -39.1 KB | -1.6% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/message_key_order | 12.6 KB | 12.6 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/unattributed | 37.7 MB | 45.4 MB | +7.6 MB | 20.3% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/log_messages | 151174 | 137524 | -13650 | -9.0% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 452431 | 448005 | -4426 | -1.0% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 55464 | 55464 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 32824 | 32824 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 32824 | 32824 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | COUNTS/log_messages_entries | 136 | 136 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | COUNTS/log_messages_population | 136 | 136 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/parse/read_files | 3.4 s | 3.5 s | +41 ms | 1.2% | REGRESS |
| single-day-application-log-heatmap | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| single-day-application-log-heatmap | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.5 s | 3.5 s | +42 ms | 1.2% | REGRESS |
| single-day-application-log-heatmap | MEMORY/rss_peak | 32.6 MB | 39.8 MB | +7.1 MB | 21.8% | REGRESS |
| single-day-application-log-heatmap | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/format_scan_subs | 848 KB | 896 KB | +48 KB | 5.7% | REGRESS |
| single-day-application-log-heatmap | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_messages | 2.8 MB | 2.7 MB | -41.7 KB | -1.5% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/unattributed | 29.0 MB | 36.1 MB | +7.1 MB | 24.5% | REGRESS |
| single-day-application-log-heatmap | MEMORY_FINAL/log_messages | 2914814 | 2872100 | -42714 | -1.5% | IMPROVE |
| single-day-application-log-heatmap | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap | COUNTS/log_messages_entries | 6512 | 6512 | 0 | 0.0% |  |
| single-day-application-log-heatmap | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap | COUNTS/log_messages_population | 6512 | 6512 | 0 | 0.0% |  |
| single-day-application-log-heatmap | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-application-log-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-heatmap | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/parse/read_files | 3.4 s | 3.5 s | +40 ms | 1.2% | REGRESS |
| single-day-application-log-histogram | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| single-day-application-log-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.5 s | 3.5 s | +41 ms | 1.2% | REGRESS |
| single-day-application-log-histogram | MEMORY/rss_peak | 32.7 MB | 39.9 MB | +7.3 MB | 22.2% | REGRESS |
| single-day-application-log-histogram | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/format_scan_subs | 848 KB | 1 MB | +208 KB | 24.5% | REGRESS |
| single-day-application-log-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_messages | 2.8 MB | 2.7 MB | -41.7 KB | -1.5% | IMPROVE |
| single-day-application-log-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/unattributed | 29 MB | 36.1 MB | +7.1 MB | 24.5% | REGRESS |
| single-day-application-log-histogram | MEMORY_FINAL/log_messages | 2914814 | 2872100 | -42714 | -1.5% | IMPROVE |
| single-day-application-log-histogram | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-histogram | COUNTS/log_messages_entries | 6512 | 6512 | 0 | 0.0% |  |
| single-day-application-log-histogram | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-histogram | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-histogram | COUNTS/log_messages_population | 6512 | 6512 | 0 | 0.0% |  |
| single-day-application-log-histogram | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-application-log-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/parse/read_files | 3.5 s | 3.5 s | +7 ms | 0.2% | REGRESS |
| single-day-application-log-heatmap-histogram | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.5 s | 3.5 s | +6 ms | 0.2% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 32.9 MB | 39.6 MB | +6.7 MB | 20.3% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/bucket_outcomes | 5.8 KB | 6 KB | +256 B | 4.3% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/format_scan_subs | 896 KB | 880 KB | -16 KB | -1.8% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_messages | 2.8 MB | 2.7 MB | -41.7 KB | -1.5% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_occurrences | 21.5 KB | 21.8 KB | +256 B | 1.2% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/unattributed | 29.2 MB | 35.9 MB | +6.7 MB | 23.1% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/log_messages | 2914814 | 2872100 | -42714 | -1.5% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | COUNTS/log_messages_entries | 6512 | 6512 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | COUNTS/log_messages_population | 6512 | 6512 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/parse/read_files | 6 s | 6.1 s | +51 ms | 0.8% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 253 ms | 258 ms | +5 ms | 2.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 6.3 s | 6.3 s | +55 ms | 0.9% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 121.7 MB | 129.4 MB | +7.8 MB | 6.4% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 440.8 KB | 437.3 KB | -3.6 KB | -0.8% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.6 MB | 2.6 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 29.3 MB | 29.3 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 16.4 MB | 16.4 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 29.7 MB | 29.7 MB | +3.8 KB | 0.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 860.9 KB | 860.9 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.5 MB | 1.5 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 816 KB | 912 KB | +96 KB | 11.8% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_messages | 2.3 MB | 2.3 MB | -39.1 KB | -1.6% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/message_key_order | 2.6 KB | 2.6 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/unattributed | 37.7 MB | 45.4 MB | +7.7 MB | 20.5% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 151174 | 137524 | -13650 | -9.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 451407 | 447749 | -3658 | -0.8% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 55464 | 55464 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 32824 | 32824 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 32824 | 32824 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 136 | 136 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_messages_population | 136 | 136 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/parse/read_files | 3.5 s | 3.5 s | +14 ms | 0.4% | REGRESS |
| single-day-application-log-sort-p99 | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| single-day-application-log-sort-p99 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/total | 3.5 s | 3.5 s | +14 ms | 0.4% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY/rss_peak | 32.7 MB | 39.7 MB | +7 MB | 21.6% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY/bucket_outcomes | 6 KB | 5.8 KB | -256 B | -4.2% | IMPROVE |
| single-day-application-log-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/format_scan_subs | 864 KB | 928 KB | +64 KB | 7.4% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_messages | 2.8 MB | 2.7 MB | -41.7 KB | -1.5% | IMPROVE |
| single-day-application-log-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_occurrences | 21.8 KB | 21.5 KB | -256 B | -1.1% | IMPROVE |
| single-day-application-log-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/unattributed | 29.0 MB | 36 MB | +7 MB | 24.2% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY_FINAL/log_messages | 2914814 | 2872100 | -42714 | -1.5% | IMPROVE |
| single-day-application-log-sort-p99 | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | COUNTS/log_messages_entries | 6512 | 6512 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | COUNTS/log_messages_population | 6512 | 6512 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/parse/read_files | 3.5 s | 3.5 s | +26 ms | 0.8% | REGRESS |
| single-day-application-log-sort-skewness | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| single-day-application-log-sort-skewness | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/total | 3.5 s | 3.5 s | +27 ms | 0.8% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY/rss_peak | 32.9 MB | 39.6 MB | +6.8 MB | 20.5% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/format_scan_subs | 848 KB | 928 KB | +80 KB | 9.4% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_messages | 2.8 MB | 2.7 MB | -41.7 KB | -1.5% | IMPROVE |
| single-day-application-log-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/unattributed | 29.2 MB | 36.0 MB | +6.7 MB | 23.0% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY_FINAL/log_messages | 2914814 | 2872100 | -42714 | -1.5% | IMPROVE |
| single-day-application-log-sort-skewness | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | COUNTS/log_messages_entries | 6512 | 6512 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | COUNTS/log_messages_population | 6512 | 6512 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/parse/read_files | 7.5 s | 7.5 s | +85 ms | 1.1% | REGRESS |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics | 177 ms | 174 ms | -3 ms | -1.7% | IMPROVE |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 175 ms | 171 ms | -4 ms | -2.3% | IMPROVE |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics/untimed | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 7.6 s | 7.7 s | +81 ms | 1.1% | REGRESS |
| multi-day-application-logs-standard | MEMORY/rss_peak | 97.2 MB | 100.8 MB | +3.6 MB | 3.7% | REGRESS |
| multi-day-application-logs-standard | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/format_scan_subs | 832 KB | 912 KB | +80 KB | 9.6% | REGRESS |
| multi-day-application-logs-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_messages | 48.9 MB | 45.8 MB | -3.1 MB | -6.4% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/unattributed | 47.4 MB | 54 MB | +6.7 MB | 14.0% | REGRESS |
| multi-day-application-logs-standard | MEMORY_FINAL/log_messages | 51302464 | 48030790 | -3271674 | -6.4% | IMPROVE |
| multi-day-application-logs-standard | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-standard | COUNTS/log_messages_entries | 105902 | 105902 | 0 | 0.0% |  |
| multi-day-application-logs-standard | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-standard | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-standard | COUNTS/log_messages_population | 105902 | 105902 | 0 | 0.0% |  |
| multi-day-application-logs-standard | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-application-logs-standard | COUNTS/format_scan_sub_cache_hits | 40 | 40 | 0 | 0.0% |  |
| multi-day-application-logs-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-standard | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-standard | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-standard | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-no-messages | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-no-messages | TIMING/parse/read_files | 6.2 s | 6.4 s | +199 ms | 3.2% | REGRESS |
| multi-day-application-logs-no-messages | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-no-messages | TIMING/total | 6.2 s | 6.4 s | +199 ms | 3.2% | REGRESS |
| multi-day-application-logs-no-messages | MEMORY/rss_peak | 30.1 MB | 37.3 MB | +7.2 MB | 23.9% | REGRESS |
| multi-day-application-logs-no-messages | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/format_scan_subs | 768 KB | 912 KB | +144 KB | 18.8% | REGRESS |
| multi-day-application-logs-no-messages | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/log_messages | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/unattributed | 29.3 MB | 36.3 MB | +7 MB | 24.1% | REGRESS |
| multi-day-application-logs-no-messages | MEMORY_FINAL/log_messages | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | COUNTS/format_scan_sub_cache_hits | 40 | 40 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/parse/read_files | 7.3 s | 7.5 s | +126 ms | 1.7% | REGRESS |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics | 176 ms | 176 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 174 ms | 174 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 7.5 s | 7.6 s | +126 ms | 1.7% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 97.1 MB | 100.8 MB | +3.7 MB | 3.8% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/format_scan_subs | 768 KB | 912 KB | +144 KB | 18.8% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_messages | 48.9 MB | 45.8 MB | -3.1 MB | -6.4% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/message_key_order | 6.5 KB | 6.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/unattributed | 47.3 MB | 54 MB | +6.7 MB | 14.2% | REGRESS |
| multi-day-application-logs-top25 | MEMORY_FINAL/log_messages | 51302464 | 48030790 | -3271674 | -6.4% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | COUNTS/log_messages_entries | 105902 | 105902 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | COUNTS/log_messages_population | 105902 | 105902 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | COUNTS/format_scan_sub_cache_hits | 40 | 40 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/parse/read_files | 36.2 s | 36.1 s | -87 ms | -0.2% | IMPROVE |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/group_similar | 4.2 s | 4.1 s | -41 ms | -1.0% | IMPROVE |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 3 ms | 2 ms | -1 ms | -33.3% | IMPROVE |
| multi-day-application-logs-top25-consolidate | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 40.3 s | 40.2 s | -130 ms | -0.3% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 207.1 MB | 214.7 MB | +7.6 MB | 3.7% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_clusters | 3.6 MB | 3.5 MB | -11.6 KB | -0.3% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_message | 3.5 MB | 3.5 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 62.1 MB | 62.1 MB | +1 KB | 0.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 10.4 MB | 10.4 MB | +8 KB | 0.1% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 60.6 MB | 60.6 MB | +7.8 KB | 0.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_patterns | 483.2 KB | 483.2 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_posting_size | 1.6 MB | 1.6 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_unmatched | 2.1 MB | 2.1 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/format_scan_subs | 800 KB | 1.1 MB | +288 KB | 36.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_messages | 3.3 MB | 3.2 MB | -140 KB | -4.1% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/message_key_order | 5.7 KB | 5.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/unattributed | 58.6 MB | 66 MB | +7.4 MB | 12.7% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_messages | 758044 | 725746 | -32298 | -4.3% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 3725134 | 3713260 | -11874 | -0.3% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 494746 | 494746 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 8248 | 8248 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_messages_entries | 1303 | 1303 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_messages_population | 1303 | 1303 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | 40 | 40 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/parse/read_files | 7.4 s | 7.4 s | -42 ms | -0.6% | IMPROVE |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics | 176 ms | 174 ms | -2 ms | -1.1% | IMPROVE |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 174 ms | 172 ms | -2 ms | -1.1% | IMPROVE |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 7.6 s | 7.6 s | -43 ms | -0.6% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 97.1 MB | 101 MB | +3.9 MB | 4.0% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/format_scan_subs | 768 KB | 1 MB | +256 KB | 33.3% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_messages | 48.9 MB | 45.8 MB | -3.1 MB | -6.4% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/unattributed | 47.4 MB | 54.1 MB | +6.8 MB | 14.3% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY_FINAL/log_messages | 51302464 | 48030790 | -3271674 | -6.4% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | COUNTS/log_messages_entries | 105902 | 105902 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | COUNTS/log_messages_population | 105902 | 105902 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | COUNTS/format_scan_sub_cache_hits | 40 | 40 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/parse/read_files | 7.4 s | 7.4 s | -11 ms | -0.1% | IMPROVE |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics | 187 ms | 173 ms | -14 ms | -7.5% | IMPROVE |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 184 ms | 170 ms | -14 ms | -7.6% | IMPROVE |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 3 ms | 2 ms | -1 ms | -33.3% | IMPROVE |
| multi-day-application-logs-histogram | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 7.6 s | 7.6 s | -25 ms | -0.3% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 97.0 MB | 101.0 MB | +4 MB | 4.1% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/format_scan_subs | 800 KB | 1 MB | +256 KB | 32.0% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_messages | 48.9 MB | 45.8 MB | -3.1 MB | -6.4% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/unattributed | 47.2 MB | 54.1 MB | +6.9 MB | 14.6% | REGRESS |
| multi-day-application-logs-histogram | MEMORY_FINAL/log_messages | 51302464 | 48030790 | -3271674 | -6.4% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | COUNTS/log_messages_entries | 105902 | 105902 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | COUNTS/log_messages_population | 105902 | 105902 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | COUNTS/format_scan_sub_cache_hits | 40 | 40 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | 5 ms | 4 ms | -1 ms | -20.0% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | TIMING/parse/read_files | 7.3 s | 7.4 s | +116 ms | 1.6% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 177 ms | 172 ms | -5 ms | -2.8% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 175 ms | 169 ms | -6 ms | -3.4% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 7.5 s | 7.6 s | +111 ms | 1.5% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 98.5 MB | 100.8 MB | +2.3 MB | 2.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/format_scan_subs | 800 KB | 960 KB | +160 KB | 20.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_messages | 48.9 MB | 45.8 MB | -3.1 MB | -6.4% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/unattributed | 48.7 MB | 54.0 MB | +5.3 MB | 10.9% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 51302464 | 48030790 | -3271674 | -6.4% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | COUNTS/log_messages_entries | 105902 | 105902 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | COUNTS/log_messages_population | 105902 | 105902 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | COUNTS/format_scan_sub_cache_hits | 40 | 40 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 36 s | 36.1 s | +112 ms | 0.3% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 4.2 s | 4.2 s | -7 ms | -0.2% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 4 ms | 3 ms | -1 ms | -25.0% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 40.2 s | 40.3 s | +105 ms | 0.3% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 207.7 MB | 215 MB | +7.3 MB | 3.5% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 3.5 MB | 3.5 MB | -8.4 KB | -0.2% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 3.5 MB | 3.5 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 62.1 MB | 62.1 MB | +2 KB | 0.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 10.4 MB | 10.4 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 60.6 MB | 60.6 MB | -28.8 KB | -0.0% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 483.2 KB | 483.2 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 1.6 MB | 1.6 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 2.1 MB | 2.1 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 784 KB | 1 MB | +256 KB | 32.7% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 3.3 MB | 3.2 MB | -140 KB | -4.1% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 3 KB | 3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/unattributed | 59.1 MB | 66.4 MB | +7.3 MB | 12.3% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 758044 | 725746 | -32298 | -4.3% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 3721870 | 3713260 | -8610 | -0.2% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 494746 | 494746 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 8248 | 8248 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 1303 | 1303 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | 1303 | 1303 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | 40 | 40 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/parse/read_files | 7.4 s | 7.4 s | +41 ms | 0.6% | REGRESS |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics | 178 ms | 175 ms | -3 ms | -1.7% | IMPROVE |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 176 ms | 173 ms | -3 ms | -1.7% | IMPROVE |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/total | 7.5 s | 7.6 s | +39 ms | 0.5% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY/rss_peak | 97.1 MB | 100.8 MB | +3.7 MB | 3.8% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/format_scan_subs | 768 KB | 944 KB | +176 KB | 22.9% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_messages | 48.9 MB | 45.8 MB | -3.1 MB | -6.4% | IMPROVE |
| multi-day-application-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/unattributed | 47.3 MB | 54.0 MB | +6.7 MB | 14.1% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/log_messages | 51302464 | 48030790 | -3271674 | -6.4% | IMPROVE |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | COUNTS/log_messages_entries | 105902 | 105902 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | COUNTS/log_messages_population | 105902 | 105902 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | COUNTS/format_scan_sub_cache_hits | 40 | 40 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/parse/read_files | 7.3 s | 7.5 s | +159 ms | 2.2% | REGRESS |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics | 179 ms | 171 ms | -8 ms | -4.5% | IMPROVE |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 177 ms | 169 ms | -8 ms | -4.5% | IMPROVE |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/total | 7.5 s | 7.7 s | +152 ms | 2.0% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY/rss_peak | 97.1 MB | 100.9 MB | +3.8 MB | 3.9% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/format_scan_subs | 768 KB | 912 KB | +144 KB | 18.8% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_messages | 48.9 MB | 45.8 MB | -3.1 MB | -6.4% | IMPROVE |
| multi-day-application-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/unattributed | 47.4 MB | 54.1 MB | +6.7 MB | 14.2% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/log_messages | 51302464 | 48030790 | -3271674 | -6.4% | IMPROVE |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | COUNTS/log_messages_entries | 105902 | 105902 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | COUNTS/log_messages_population | 105902 | 105902 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | COUNTS/format_scan_sub_cache_hits | 40 | 40 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/parse/read_files | 15.7 s | 15.7 s | +52 ms | 0.3% | REGRESS |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics | 380 ms | 385 ms | +5 ms | 1.3% | REGRESS |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/bucket_stats | 56 ms | 56 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 313 ms | 317 ms | +4 ms | 1.3% | REGRESS |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/group_calc | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/untimed | 7 ms | 7 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 16 s | 16.1 s | +58 ms | 0.4% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 195.2 MB | 200.5 MB | +5.2 MB | 2.7% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/format_scan_subs | 768 KB | 912 KB | +144 KB | 18.8% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_analysis | 28.4 MB | 28.4 MB | -2.6 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/log_messages | 105.1 MB | 103.0 MB | -2.1 MB | -2.0% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_stats | 51.9 KB | 52.2 KB | +272 B | 0.5% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/unattributed | 60.9 MB | 68.1 MB | +7.2 MB | 11.8% | REGRESS |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_messages | 110167263 | 107966852 | -2200411 | -2.0% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_analysis | 23359 | 20086 | -3273 | -14.0% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | COUNTS/log_messages_entries | 182419 | 182419 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | COUNTS/log_analysis_entries | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | COUNTS/log_messages_population | 182419 | 182419 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | COUNTS/format_scan_sub_cache_hits | 4 | 4 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-no-messages | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-no-messages | TIMING/parse/read_files | 12.6 s | 12.8 s | +286 ms | 2.3% | REGRESS |
| multi-day-custom-logs-no-messages | TIMING/finalize/calculate_statistics | 53 ms | 52 ms | -1 ms | -1.9% | IMPROVE |
| multi-day-custom-logs-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | 53 ms | 52 ms | -1 ms | -1.9% | IMPROVE |
| multi-day-custom-logs-no-messages | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-no-messages | TIMING/total | 12.6 s | 12.9 s | +284 ms | 2.2% | REGRESS |
| multi-day-custom-logs-no-messages | MEMORY/rss_peak | 63.3 MB | 70.7 MB | +7.4 MB | 11.7% | REGRESS |
| multi-day-custom-logs-no-messages | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/format_scan_subs | 800 KB | 1008 KB | +208 KB | 26.0% | REGRESS |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/log_analysis | 28.4 MB | 28.4 MB | -2.3 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-no-messages | MEMORY/log_messages | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/log_stats | 51.9 KB | 52.4 KB | +528 B | 1.0% | REGRESS |
| multi-day-custom-logs-no-messages | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/unattributed | 34.0 MB | 41.1 MB | +7.2 MB | 21.1% | REGRESS |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/log_messages | 232 | 232 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/log_analysis | 23359 | 20342 | -3017 | -12.9% | IMPROVE |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | COUNTS/log_analysis_entries | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | COUNTS/format_scan_sub_cache_hits | 4 | 4 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/parse/read_files | 15.7 s | 15.7 s | -11 ms | -0.1% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics | 436 ms | 383 ms | -53 ms | -12.2% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 62 ms | 56 ms | -6 ms | -9.7% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 355 ms | 310 ms | -45 ms | -12.7% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/group_calc | 11 ms | 10 ms | -1000 us | -9.1% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 8 ms | 7 ms | -1 ms | -12.5% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 16.1 s | 16.1 s | -64 ms | -0.4% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 196.5 MB | 200.7 MB | +4.1 MB | 2.1% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/format_scan_subs | 768 KB | 1 MB | +272 KB | 35.4% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_analysis | 28.4 MB | 28.4 MB | -3.6 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/log_messages | 105.1 MB | 103.0 MB | -2.1 MB | -2.0% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_stats | 51.9 KB | 52.4 KB | +528 B | 1.0% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/unattributed | 62.1 MB | 68.1 MB | +6.0 MB | 9.6% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_messages | 110178903 | 107977772 | -2201131 | -2.0% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_analysis | 24639 | 20342 | -4297 | -17.4% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | COUNTS/log_messages_entries | 182419 | 182419 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | COUNTS/log_analysis_entries | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | COUNTS/log_messages_population | 182419 | 182419 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | COUNTS/format_scan_sub_cache_hits | 4 | 4 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/parse/read_files | 48.5 s | 47.6 s | -941 ms | -1.9% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/group_similar | 4.8 s | 4.6 s | -192 ms | -4.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 271 ms | 262 ms | -9 ms | -3.3% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 125 ms | 120 ms | -5 ms | -4.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 145 ms | 140 ms | -5 ms | -3.4% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 53.6 s | 52.4 s | -1.1 s | -2.1% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 246.3 MB | 249.5 MB | +3.2 MB | 1.3% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_clusters | 29.6 MB | 29.5 MB | -29.5 KB | -0.1% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_message | 5.8 MB | 5.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 62.6 MB | 62.6 MB | -2 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 4.5 MB | 4.5 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 61.3 MB | 61.2 MB | -15.6 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_patterns | 202.1 KB | 202.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_posting_size | 478.1 KB | 478.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_unmatched | 3.3 MB | 3.3 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/format_scan_subs | 800 KB | 992 KB | +192 KB | 24.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_analysis | 28.4 MB | 28.4 MB | -3.6 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages | 28.7 MB | 28.6 MB | -42.1 KB | -0.1% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_stats | 51.9 KB | 52.4 KB | +528 B | 1.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/message_key_order | 6.1 KB | 6.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/unattributed | 20.6 MB | 23.8 MB | +3.2 MB | 15.3% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_messages | 30051269 | 30008170 | -43099 | -0.1% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 24639 | 20342 | -4297 | -17.4% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 31000143 | 30969940 | -30203 | -0.1% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 206903 | 206903 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 232 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 4152 | 4152 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_messages_entries | 606 | 606 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_analysis_entries | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_messages_population | 606 | 606 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | 4 | 4 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/parse/read_files | 16.3 s | 16.2 s | -76 ms | -0.5% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics | 332 ms | 313 ms | -19 ms | -5.7% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 319 ms | 302 ms | -17 ms | -5.3% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/group_calc | 5 ms | 5 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 7 ms | 6 ms | -1 ms | -14.3% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/finalize/heatmap_statistics | 52 ms | 50 ms | -2 ms | -3.8% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/render/normalize_data | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/total | 16.7 s | 16.6 s | -97 ms | -0.6% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 181.5 MB | 186.7 MB | +5.2 MB | 2.9% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/format_scan_subs | 784 KB | 1 MB | +240 KB | 30.6% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters | 985.8 KB | 985.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data | 43.7 KB | 43.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_analysis | 24.5 KB | 20.9 KB | -3.6 KB | -14.6% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/log_messages | 104.9 MB | 102.5 MB | -2.4 MB | -2.3% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_stats | 34.2 KB | 32.8 KB | -1.4 KB | -4.1% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/unattributed | 74.6 MB | 82.1 MB | +7.5 MB | 10.0% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_messages | 110040159 | 107471620 | -2568539 | -2.3% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_analysis | 24639 | 20342 | -4297 | -17.4% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | COUNTS/log_messages_entries | 182419 | 182419 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | COUNTS/log_analysis_entries | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | COUNTS/log_messages_population | 182419 | 182419 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | COUNTS/format_scan_sub_cache_hits | 4 | 4 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/parse/read_files | 16.6 s | 16.4 s | -114 ms | -0.7% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics | 404 ms | 382 ms | -22 ms | -5.4% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 58 ms | 55 ms | -3 ms | -5.2% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 334 ms | 316 ms | -18 ms | -5.4% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/group_calc | 5 ms | 4 ms | -1 ms | -20.0% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 8 ms | 7 ms | -1 ms | -12.5% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/finalize/histogram_statistics | 14 ms | 14 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/render/normalize_data | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/total | 17.0 s | 16.8 s | -136 ms | -0.8% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 196.1 MB | 200.5 MB | +4.4 MB | 2.2% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/format_scan_subs | 816 KB | 928 KB | +112 KB | 13.7% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/histogram_counters | 122.6 KB | 122.5 KB | -192 B | -0.2% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_analysis | 28.4 MB | 28.4 MB | -3.6 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/log_messages | 105.4 MB | 102.5 MB | -2.9 MB | -2.8% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_stats | 51.9 KB | 52.4 KB | +528 B | 1.0% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/unattributed | 61.2 MB | 68.4 MB | +7.2 MB | 11.8% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY_FINAL/log_messages | 110533471 | 107471620 | -3061851 | -2.8% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY_FINAL/log_analysis | 24639 | 20342 | -4297 | -17.4% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | COUNTS/log_messages_entries | 182419 | 182419 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | COUNTS/log_analysis_entries | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | COUNTS/log_messages_population | 182419 | 182419 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | COUNTS/format_scan_sub_cache_hits | 4 | 4 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/parse/read_files | 17.0 s | 16.9 s | -85 ms | -0.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 347 ms | 328 ms | -19 ms | -5.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 334 ms | 317 ms | -17 ms | -5.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 5 ms | 5 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 7 ms | 6 ms | -1 ms | -14.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/heatmap_statistics | 50 ms | 50 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/histogram_statistics | 15 ms | 14 ms | -1000 us | -6.7% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 17.4 s | 17.3 s | -103 ms | -0.6% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 184.9 MB | 188.6 MB | +3.7 MB | 2.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/format_scan_subs | 816 KB | 896 KB | +80 KB | 9.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_counters | 985.8 KB | 985.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data | 42.9 KB | 43.5 KB | +576 B | 1.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters | 122.5 KB | 122.5 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_analysis | 24.5 KB | 20.9 KB | -3.6 KB | -14.6% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages | 105.4 MB | 102.5 MB | -2.9 MB | -2.8% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_stats | 34.2 KB | 32.8 KB | -1.4 KB | -4.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/unattributed | 77.5 MB | 84 MB | +6.5 MB | 8.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 110533279 | 107471620 | -3061659 | -2.8% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 24639 | 20342 | -4297 | -17.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | COUNTS/log_messages_entries | 182419 | 182419 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | COUNTS/log_analysis_entries | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | COUNTS/log_messages_population | 182419 | 182419 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | COUNTS/format_scan_sub_cache_hits | 4 | 4 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 50.3 s | 50.0 s | -296 ms | -0.6% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 4.5 s | 4.3 s | -159 ms | -3.6% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 148 ms | 132 ms | -16 ms | -10.8% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 147 ms | 131 ms | -16 ms | -10.9% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 54 ms | 54 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 15 ms | 15 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 3 ms | 2 ms | -1 ms | -33.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 55.0 s | 54.5 s | -472 ms | -0.9% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 233.5 MB | 239.7 MB | +6.2 MB | 2.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 29.6 MB | 29.5 MB | -22.0 KB | -0.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 5.8 MB | 5.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 62.6 MB | 62.6 MB | -6 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 4.5 MB | 4.5 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 61.3 MB | 61.3 MB | -5.7 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 202.1 KB | 202.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 478.1 KB | 478.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 3.3 MB | 3.3 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 800 KB | 944 KB | +144 KB | 18.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 985.8 KB | 985.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 43.8 KB | 43.7 KB | -64 B | -0.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 122.5 KB | 122.5 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 23.2 KB | 20.9 KB | -2.3 KB | -10.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 28.7 MB | 28.6 MB | -40.6 KB | -0.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 34.2 KB | 32.8 KB | -1.4 KB | -4.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 2.7 KB | 2.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/unattributed | 35.1 MB | 41.3 MB | +6.2 MB | 17.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 30043797 | 30002202 | -41595 | -0.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 23359 | 20342 | -3017 | -12.9% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 30992463 | 30969940 | -22523 | -0.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 206903 | 206903 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 232 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 4152 | 4152 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 606 | 606 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | 606 | 606 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | 4 | 4 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/detect/scan_sub_compile | 5 ms | 4 ms | -1 ms | -20.0% | IMPROVE |
| multi-day-custom-logs-sort-p99 | TIMING/parse/read_files | 16 s | 15.8 s | -279 ms | -1.7% | IMPROVE |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics | 293 ms | 287 ms | -6 ms | -2.0% | IMPROVE |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 57 ms | 55 ms | -2 ms | -3.5% | IMPROVE |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 224 ms | 220 ms | -4 ms | -1.8% | IMPROVE |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 8 ms | 8 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/render/normalize_data | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| multi-day-custom-logs-sort-p99 | TIMING/total | 16.3 s | 16 s | -285 ms | -1.7% | IMPROVE |
| multi-day-custom-logs-sort-p99 | MEMORY/rss_peak | 193.6 MB | 197.8 MB | +4.2 MB | 2.1% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/format_scan_subs | 784 KB | 1 MB | +272 KB | 34.7% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_analysis | 28.4 MB | 28.4 MB | -3.6 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-sort-p99 | MEMORY/log_messages | 104.9 MB | 103.0 MB | -2.0 MB | -1.9% | IMPROVE |
| multi-day-custom-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_stats | 51.9 KB | 52.4 KB | +528 B | 1.0% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/message_key_order | 2.7 KB | 2.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/unattributed | 59.4 MB | 65.3 MB | +5.9 MB | 9.9% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/log_messages | 110041447 | 107967580 | -2073867 | -1.9% | IMPROVE |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/log_analysis | 24639 | 20342 | -4297 | -17.4% | IMPROVE |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | COUNTS/log_messages_entries | 182419 | 182419 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | COUNTS/log_analysis_entries | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | COUNTS/log_messages_population | 182419 | 182419 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | COUNTS/format_scan_sub_cache_hits | 4 | 4 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/parse/read_files | 16.2 s | 15.6 s | -565 ms | -3.5% | IMPROVE |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics | 365 ms | 360 ms | -5 ms | -1.4% | IMPROVE |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 57 ms | 57 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 288 ms | 286 ms | -2 ms | -0.7% | IMPROVE |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 8 ms | 8 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 9 ms | 8 ms | -1000 us | -11.1% | IMPROVE |
| multi-day-custom-logs-sort-skewness | TIMING/render/normalize_data | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| multi-day-custom-logs-sort-skewness | TIMING/total | 16.6 s | 16 s | -569 ms | -3.4% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY/rss_peak | 193.1 MB | 197.9 MB | +4.8 MB | 2.5% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/format_scan_subs | 864 KB | 1 MB | +160 KB | 18.5% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_analysis | 28.4 MB | 28.4 MB | -3.6 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY/log_messages | 105.4 MB | 103.0 MB | -2.4 MB | -2.3% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_stats | 51.9 KB | 52.4 KB | +528 B | 1.0% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/message_key_order | 2.5 KB | 2.5 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/unattributed | 58.3 MB | 65.4 MB | +7.1 MB | 12.2% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/log_messages | 110535692 | 107969153 | -2566539 | -2.3% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/log_analysis | 24639 | 20342 | -4297 | -17.4% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | COUNTS/log_messages_entries | 182419 | 182419 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | COUNTS/log_analysis_entries | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | COUNTS/log_messages_population | 182419 | 182419 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | COUNTS/format_scan_sub_cache_hits | 4 | 4 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/parse/read_files | 9.7 s | 9.3 s | -452 ms | -4.7% | IMPROVE |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics | 154 ms | 151 ms | -3 ms | -1.9% | IMPROVE |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/bucket_stats | 101 ms | 99 ms | -2 ms | -2.0% | IMPROVE |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/group_calc | 47 ms | 46 ms | -1 ms | -2.1% | IMPROVE |
| single-day-access-log-standard | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 9.9 s | 9.4 s | -455 ms | -4.6% | IMPROVE |
| single-day-access-log-standard | MEMORY/rss_peak | 145.0 MB | 150.8 MB | +5.9 MB | 4.1% | REGRESS |
| single-day-access-log-standard | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/format_scan_subs | 752 KB | 896 KB | +144 KB | 19.1% | REGRESS |
| single-day-access-log-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_analysis | 52.7 MB | 52.7 MB | -3.4 KB | -0.0% | IMPROVE |
| single-day-access-log-standard | MEMORY/log_messages | 56.9 MB | 55.4 MB | -1.5 MB | -2.7% | IMPROVE |
| single-day-access-log-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_stats | 31.4 KB | 30.5 KB | -912 B | -2.8% | IMPROVE |
| single-day-access-log-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/message_key_order | 1.8 KB | 1.8 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/unattributed | 34.5 MB | 41.8 MB | +7.3 MB | 21.1% | REGRESS |
| single-day-access-log-standard | MEMORY_FINAL/log_messages | 59705771 | 58115432 | -1590339 | -2.7% | IMPROVE |
| single-day-access-log-standard | MEMORY_FINAL/log_analysis | 11127 | 6670 | -4457 | -40.1% | IMPROVE |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-standard | COUNTS/log_messages_entries | 3184 | 3184 | 0 | 0.0% |  |
| single-day-access-log-standard | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-standard | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-standard | COUNTS/log_analysis_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-standard | COUNTS/log_messages_population | 3184 | 3184 | 0 | 0.0% |  |
| single-day-access-log-standard | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-access-log-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-standard | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-standard | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-standard | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-no-messages | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-no-messages | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-no-messages | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| single-day-access-log-no-messages | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| single-day-access-log-no-messages | TIMING/parse/read_files | 7.5 s | 7.3 s | -187 ms | -2.5% | IMPROVE |
| single-day-access-log-no-messages | TIMING/finalize/calculate_statistics | 108 ms | 100 ms | -8 ms | -7.4% | IMPROVE |
| single-day-access-log-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | 108 ms | 100 ms | -8 ms | -7.4% | IMPROVE |
| single-day-access-log-no-messages | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-no-messages | TIMING/total | 7.6 s | 7.4 s | -195 ms | -2.6% | IMPROVE |
| single-day-access-log-no-messages | MEMORY/rss_peak | 89.5 MB | 95.8 MB | +6.4 MB | 7.1% | REGRESS |
| single-day-access-log-no-messages | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/format_scan_subs | 768 KB | 1008 KB | +240 KB | 31.2% | REGRESS |
| single-day-access-log-no-messages | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/log_analysis | 52.7 MB | 52.7 MB | -4.4 KB | -0.0% | IMPROVE |
| single-day-access-log-no-messages | MEMORY/log_messages | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/log_stats | 31.4 KB | 30.5 KB | -912 B | -2.8% | IMPROVE |
| single-day-access-log-no-messages | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/unattributed | 36.0 MB | 42.1 MB | +6.1 MB | 17.1% | REGRESS |
| single-day-access-log-no-messages | MEMORY_FINAL/log_messages | 232 | 232 | 0 | 0.0% |  |
| single-day-access-log-no-messages | MEMORY_FINAL/log_analysis | 12087 | 6670 | -5417 | -44.8% | IMPROVE |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-no-messages | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-no-messages | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-no-messages | COUNTS/log_analysis_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-no-messages | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-access-log-no-messages | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-no-messages | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-no-messages | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-no-messages | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-no-messages | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/detect/scan_sub_compile | 5 ms | 4 ms | -1 ms | -20.0% | IMPROVE |
| single-day-access-log-top25 | TIMING/parse/read_files | 9.7 s | 9.2 s | -426 ms | -4.4% | IMPROVE |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics | 172 ms | 168 ms | -4 ms | -2.3% | IMPROVE |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 101 ms | 99 ms | -2 ms | -2.0% | IMPROVE |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 5 ms | -1 ms | -16.7% | IMPROVE |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/group_calc | 65 ms | 64 ms | -1 ms | -1.5% | IMPROVE |
| single-day-access-log-top25 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 9.8 s | 9.4 s | -430 ms | -4.4% | IMPROVE |
| single-day-access-log-top25 | MEMORY/rss_peak | 146.9 MB | 151 MB | +4.1 MB | 2.8% | REGRESS |
| single-day-access-log-top25 | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/format_scan_subs | 928 KB | 1008 KB | +80 KB | 8.6% | REGRESS |
| single-day-access-log-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_analysis | 52.7 MB | 52.7 MB | -4.4 KB | -0.0% | IMPROVE |
| single-day-access-log-top25 | MEMORY/log_messages | 56.6 MB | 55.4 MB | -1.2 MB | -2.1% | IMPROVE |
| single-day-access-log-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_stats | 31.4 KB | 30.5 KB | -912 B | -2.8% | IMPROVE |
| single-day-access-log-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/message_key_order | 3.9 KB | 3.9 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/unattributed | 36.7 MB | 41.8 MB | +5.2 MB | 14.0% | REGRESS |
| single-day-access-log-top25 | MEMORY_FINAL/log_messages | 59336915 | 58119552 | -1217363 | -2.1% | IMPROVE |
| single-day-access-log-top25 | MEMORY_FINAL/log_analysis | 12087 | 6670 | -5417 | -44.8% | IMPROVE |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25 | COUNTS/log_messages_entries | 3184 | 3184 | 0 | 0.0% |  |
| single-day-access-log-top25 | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25 | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25 | COUNTS/log_analysis_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25 | COUNTS/log_messages_population | 3184 | 3184 | 0 | 0.0% |  |
| single-day-access-log-top25 | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-access-log-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-top25 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-top25 | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-top25 | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/parse/read_files | 11.3 s | 10.8 s | -519 ms | -4.6% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/finalize/group_similar | 4.1 s | 3.9 s | -209 ms | -5.1% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics | 317 ms | 278 ms | -39 ms | -12.3% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 151 ms | 131 ms | -20 ms | -13.2% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 165 ms | 146 ms | -19 ms | -11.5% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/render/normalize_data | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/total | 15.7 s | 14.9 s | -768 ms | -4.9% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 180.2 MB | 184.9 MB | +4.7 MB | 2.6% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_clusters | 48.5 MB | 48.4 MB | -76.8 KB | -0.2% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_message | 883 KB | 883 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_trigrams | 4.1 MB | 4.1 MB | -1.5 KB | -0.0% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_ngram_index | 4.8 MB | 4.8 MB | -640 B | -0.0% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_patterns | 118.1 KB | 118.1 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_posting_size | 352.5 KB | 352.5 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_unmatched | 565.1 KB | 565.1 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/format_scan_subs | 800 KB | 1008 KB | +208 KB | 26.0% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_analysis | 52.7 MB | 52.7 MB | -4.4 KB | -0.0% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/log_messages | 56.6 MB | 55.4 MB | -1.2 MB | -2.1% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_stats | 31.4 KB | 30.5 KB | -912 B | -2.8% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/message_key_order | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/unattributed | 10.7 MB | 16.5 MB | +5.7 MB | 53.6% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_messages | 56326156 | 56080609 | -245547 | -0.4% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_analysis | 12087 | 6670 | -5417 | -44.8% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 50849684 | 50771065 | -78619 | -0.2% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 119797 | 119797 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 296 | 296 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 16440 | 16440 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_messages_entries | 615 | 615 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_analysis_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_messages_population | 615 | 615 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/parse/read_files | 10.5 s | 10.0 s | -504 ms | -4.8% | IMPROVE |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics | 51 ms | 48 ms | -3 ms | -5.9% | IMPROVE |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 5 ms | -1 ms | -16.7% | IMPROVE |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics/group_calc | 45 ms | 43 ms | -2 ms | -4.4% | IMPROVE |
| single-day-access-log-heatmap | TIMING/finalize/heatmap_statistics | 31 ms | 30 ms | -1 ms | -3.2% | IMPROVE |
| single-day-access-log-heatmap | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 10.6 s | 10.1 s | -507 ms | -4.8% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/rss_peak | 116.2 MB | 121.3 MB | +5.1 MB | 4.4% | REGRESS |
| single-day-access-log-heatmap | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/format_scan_subs | 768 KB | 960 KB | +192 KB | 25.0% | REGRESS |
| single-day-access-log-heatmap | MEMORY/heatmap_counters | 572.2 KB | 571.2 KB | -960 B | -0.2% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_analysis | 12.4 KB | 8.1 KB | -4.4 KB | -35.0% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/log_messages | 56.9 MB | 55.4 MB | -1.5 MB | -2.7% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_stats | 20.3 KB | 18.2 KB | -2.1 KB | -10.4% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/message_key_order | 1.8 KB | 1.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/unattributed | 57.8 MB | 64.3 MB | +6.5 MB | 11.2% | REGRESS |
| single-day-access-log-heatmap | MEMORY_FINAL/log_messages | 59705771 | 58108264 | -1597507 | -2.7% | IMPROVE |
| single-day-access-log-heatmap | MEMORY_FINAL/log_analysis | 12087 | 6670 | -5417 | -44.8% | IMPROVE |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap | COUNTS/log_messages_entries | 3184 | 3184 | 0 | 0.0% |  |
| single-day-access-log-heatmap | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap | COUNTS/log_analysis_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap | COUNTS/log_messages_population | 3184 | 3184 | 0 | 0.0% |  |
| single-day-access-log-heatmap | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-access-log-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-heatmap | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/parse/read_files | 11.8 s | 11.2 s | -623 ms | -5.3% | IMPROVE |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics | 154 ms | 150 ms | -4 ms | -2.6% | IMPROVE |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 101 ms | 99 ms | -2 ms | -2.0% | IMPROVE |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 5 ms | -1 ms | -16.7% | IMPROVE |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/group_calc | 46 ms | 45 ms | -1 ms | -2.2% | IMPROVE |
| single-day-access-log-histogram | TIMING/finalize/histogram_statistics | 11 ms | 12 ms | +1 ms | 9.1% | REGRESS |
| single-day-access-log-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 12 s | 11.4 s | -626 ms | -5.2% | IMPROVE |
| single-day-access-log-histogram | MEMORY/rss_peak | 145.8 MB | 150.9 MB | +5.2 MB | 3.6% | REGRESS |
| single-day-access-log-histogram | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/format_scan_subs | 720 KB | 848 KB | +128 KB | 17.8% | REGRESS |
| single-day-access-log-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/histogram_counters | 105.8 KB | 105.9 KB | +128 B | 0.1% | REGRESS |
| single-day-access-log-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_analysis | 52.7 MB | 52.7 MB | -4.4 KB | -0.0% | IMPROVE |
| single-day-access-log-histogram | MEMORY/log_messages | 56.6 MB | 55.4 MB | -1.2 MB | -2.0% | IMPROVE |
| single-day-access-log-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_stats | 31.4 KB | 30.5 KB | -912 B | -2.8% | IMPROVE |
| single-day-access-log-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/message_key_order | 1.8 KB | 1.8 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/unattributed | 35.6 MB | 41.8 MB | +6.2 MB | 17.5% | REGRESS |
| single-day-access-log-histogram | MEMORY_FINAL/log_messages | 59326955 | 58115432 | -1211523 | -2.0% | IMPROVE |
| single-day-access-log-histogram | MEMORY_FINAL/log_analysis | 12087 | 6670 | -5417 | -44.8% | IMPROVE |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-histogram | COUNTS/log_messages_entries | 3184 | 3184 | 0 | 0.0% |  |
| single-day-access-log-histogram | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-histogram | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-histogram | COUNTS/log_analysis_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-histogram | COUNTS/log_messages_population | 3184 | 3184 | 0 | 0.0% |  |
| single-day-access-log-histogram | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-access-log-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/detect/scan_sub_compile | 5 ms | 4 ms | -1 ms | -20.0% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/parse/read_files | 12.4 s | 11.9 s | -513 ms | -4.1% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics | 52 ms | 48 ms | -4 ms | -7.7% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 5 ms | -1 ms | -16.7% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 46 ms | 43 ms | -3 ms | -6.5% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/finalize/heatmap_statistics | 32 ms | 30 ms | -2 ms | -6.3% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/finalize/histogram_statistics | 12 ms | 11 ms | -1 ms | -8.3% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/render/normalize_data | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/total | 12.5 s | 12.0 s | -520 ms | -4.2% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 115.8 MB | 121.5 MB | +5.8 MB | 5.0% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/format_scan_subs | 800 KB | 880 KB | +80 KB | 10.0% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_counters | 570.3 KB | 571.2 KB | +960 B | 0.2% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_counters | 105.8 KB | 105.9 KB | +128 B | 0.1% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_analysis | 12.4 KB | 8.1 KB | -4.4 KB | -35.0% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/log_messages | 56.6 MB | 55.4 MB | -1.2 MB | -2.1% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_stats | 20.3 KB | 18.2 KB | -2.1 KB | -10.4% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/message_key_order | 1.8 KB | 1.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/unattributed | 57.6 MB | 64.5 MB | +6.9 MB | 12.0% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_messages | 59329067 | 58108392 | -1220675 | -2.1% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_analysis | 12087 | 6670 | -5417 | -44.8% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | COUNTS/log_messages_entries | 3184 | 3184 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | COUNTS/log_analysis_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | COUNTS/log_messages_population | 3184 | 3184 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/parse/read_files | 13.9 s | 13.3 s | -573 ms | -4.1% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 3.0 s | 2.8 s | -172 ms | -5.8% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 177 ms | 174 ms | -3 ms | -1.7% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 175 ms | 173 ms | -2 ms | -1.1% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 31 ms | 30 ms | -1 ms | -3.2% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 11 ms | 11 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 17.1 s | 16.3 s | -749 ms | -4.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 155.3 MB | 161.2 MB | +5.9 MB | 3.8% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 48.5 MB | 48.4 MB | -76.2 KB | -0.2% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 883 KB | 883 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 4.1 MB | 4.1 MB | +7.5 KB | 0.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 4.8 MB | 4.8 MB | +448 B | 0.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 118.1 KB | 118.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 352.5 KB | 352.5 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 565.1 KB | 565.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 752 KB | 848 KB | +96 KB | 12.8% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 571.2 KB | 571.2 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_counters | 105.9 KB | 105.9 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 12.4 KB | 8.1 KB | -4.4 KB | -35.0% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_messages | 56.6 MB | 55.4 MB | -1.2 MB | -2.1% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_stats | 20.3 KB | 18.2 KB | -2.1 KB | -10.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/message_key_order | 1.9 KB | 1.9 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/unattributed | 37.9 MB | 45 MB | +7.1 MB | 18.6% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 56299492 | 56069449 | -230043 | -0.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 12087 | 6670 | -5417 | -44.8% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 50849044 | 50771065 | -77979 | -0.2% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 119797 | 119797 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 296 | 296 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 16440 | 16440 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 615 | 615 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_messages_population | 615 | 615 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/detect/scan_sub_compile | 5 ms | 4 ms | -1 ms | -20.0% | IMPROVE |
| single-day-access-log-sort-p99 | TIMING/parse/read_files | 9.8 s | 9.3 s | -496 ms | -5.1% | IMPROVE |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics | 211 ms | 211 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 101 ms | 99 ms | -2 ms | -2.0% | IMPROVE |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 108 ms | 109 ms | +1 ms | 0.9% | REGRESS |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/total | 10.0 s | 9.5 s | -498 ms | -5.0% | IMPROVE |
| single-day-access-log-sort-p99 | MEMORY/rss_peak | 145.5 MB | 149.8 MB | +4.3 MB | 3.0% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/format_scan_subs | 816 KB | 960 KB | +144 KB | 17.6% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_analysis | 52.7 MB | 52.7 MB | -4.4 KB | -0.0% | IMPROVE |
| single-day-access-log-sort-p99 | MEMORY/log_messages | 56.6 MB | 55.4 MB | -1.2 MB | -2.1% | IMPROVE |
| single-day-access-log-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_stats | 31.4 KB | 30.5 KB | -912 B | -2.8% | IMPROVE |
| single-day-access-log-sort-p99 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/message_key_order | 2.0 KB | 2.0 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/unattributed | 35.3 MB | 40.6 MB | +5.3 MB | 15.1% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY_FINAL/log_messages | 59329067 | 58108392 | -1220675 | -2.1% | IMPROVE |
| single-day-access-log-sort-p99 | MEMORY_FINAL/log_analysis | 12087 | 6670 | -5417 | -44.8% | IMPROVE |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | COUNTS/log_messages_entries | 3184 | 3184 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | COUNTS/log_analysis_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | COUNTS/log_messages_population | 3184 | 3184 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/detect/scan_sub_compile | 5 ms | 4 ms | -1 ms | -20.0% | IMPROVE |
| single-day-access-log-sort-skewness | TIMING/parse/read_files | 9.8 s | 9.2 s | -635 ms | -6.5% | IMPROVE |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics | 340 ms | 333 ms | -7 ms | -2.1% | IMPROVE |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 104 ms | 100 ms | -4 ms | -3.8% | IMPROVE |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 230 ms | 227 ms | -3 ms | -1.3% | IMPROVE |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 5 ms | 5 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/total | 10.1 s | 9.5 s | -642 ms | -6.3% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY/rss_peak | 149.9 MB | 154.8 MB | +5.0 MB | 3.3% | REGRESS |
| single-day-access-log-sort-skewness | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/format_scan_subs | 976 KB | 960 KB | -16 KB | -1.6% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_analysis | 52.7 MB | 52.7 MB | -4.4 KB | -0.0% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY/log_messages | 56.6 MB | 55.4 MB | -1.2 MB | -2.1% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_stats | 31.4 KB | 30.5 KB | -912 B | -2.8% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/message_key_order | 1.9 KB | 1.9 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/unattributed | 39.6 MB | 45.7 MB | +6.1 MB | 15.5% | REGRESS |
| single-day-access-log-sort-skewness | MEMORY_FINAL/log_messages | 59331024 | 58109965 | -1221059 | -2.1% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY_FINAL/log_analysis | 12087 | 6670 | -5417 | -44.8% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | COUNTS/log_messages_entries | 3184 | 3184 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | COUNTS/log_analysis_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | COUNTS/log_messages_population | 3184 | 3184 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/parse/read_files | 1.8 min | 1.7 min | -6.1 s | -5.6% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics | 5.7 s | 5.0 s | -716 ms | -12.6% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/bucket_stats | 3.2 s | 2.7 s | -483 ms | -15.2% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 1.7 s | 1.6 s | -140 ms | -8.0% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/group_calc | 675 ms | 588 ms | -87 ms | -12.9% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/untimed | 69 ms | 63 ms | -6 ms | -8.7% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/total | 1.9 min | 1.8 min | -6.8 s | -6.0% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2.8 GB | 2.4 GB | -475.4 MB | -16.4% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/format_scan_subs | 752 KB | 896 KB | +144 KB | 19.1% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_analysis | 568.6 MB | 568.5 MB | -8 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/log_messages | 2 GB | 1.6 GB | -453.1 MB | -21.8% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_stats | 60.0 KB | 58.3 KB | -1.7 KB | -2.8% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/unattributed | 252.8 MB | 230.3 MB | -22.4 MB | -8.9% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_messages | 2179558580 | 1704451513 | -475107067 | -21.8% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_analysis | 23003 | 13010 | -9993 | -43.4% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | COUNTS/log_messages_entries | 1212275 | 1212275 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | COUNTS/log_messages_population | 1212275 | 1212275 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-no-messages | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-no-messages | TIMING/parse/read_files | 1.4 min | 1.3 min | -3.6 s | -4.4% | IMPROVE |
| month-single-server-access-logs-no-messages | TIMING/finalize/calculate_statistics | 2.1 s | 2.0 s | -106 ms | -5.1% | IMPROVE |
| month-single-server-access-logs-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | 2.1 s | 2.0 s | -106 ms | -5.1% | IMPROVE |
| month-single-server-access-logs-no-messages | TIMING/finalize/calculate_statistics/untimed | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-no-messages | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-no-messages | TIMING/total | 1.4 min | 1.3 min | -3.7 s | -4.4% | IMPROVE |
| month-single-server-access-logs-no-messages | MEMORY/rss_peak | 643.5 MB | 651.3 MB | +7.8 MB | 1.2% | REGRESS |
| month-single-server-access-logs-no-messages | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/format_scan_subs | 768 KB | 1 MB | +256 KB | 33.3% | REGRESS |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_analysis | 566.1 MB | 566.1 MB | -8 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-no-messages | MEMORY/log_messages | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_stats | 60.0 KB | 58.3 KB | -1.7 KB | -2.8% | IMPROVE |
| month-single-server-access-logs-no-messages | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/unattributed | 74.4 MB | 81.9 MB | +7.5 MB | 10.1% | REGRESS |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/log_messages | 232 | 232 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/log_analysis | 23003 | 13010 | -9993 | -43.4% | IMPROVE |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/detect/scan_sub_compile | 5 ms | 4 ms | -1 ms | -20.0% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/parse/read_files | 1.8 min | 1.7 min | -5.7 s | -5.4% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics | 5.9 s | 5.5 s | -344 ms | -5.9% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 3.2 s | 2.8 s | -412 ms | -13.0% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 1.7 s | 1.8 s | +131 ms | 7.8% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/group_calc | 935 ms | 878 ms | -57 ms | -6.1% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 68 ms | 62 ms | -6 ms | -8.8% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 1.9 min | 1.8 min | -6.1 s | -5.4% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2.8 GB | 2.4 GB | -472.5 MB | -16.2% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/format_scan_subs | 784 KB | 1008 KB | +224 KB | 28.6% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_analysis | 568.6 MB | 568.5 MB | -8 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/log_messages | 2 GB | 1.6 GB | -453.1 MB | -21.8% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_sessions | 2.2 MB | 2.2 MB | -128 B | -0.0% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/log_stats | 60.0 KB | 58.3 KB | -1.7 KB | -2.8% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/message_key_order | 4.7 KB | 4.7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/unattributed | 258.1 MB | 238.5 MB | -19.6 MB | -7.6% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_messages | 2179568852 | 1704463241 | -475105611 | -21.8% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_analysis | 23003 | 13010 | -9993 | -43.4% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | COUNTS/log_messages_entries | 1212275 | 1212275 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | COUNTS/log_messages_population | 1212275 | 1212275 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/parse/read_files | 2.4 min | 2.3 min | -8.4 s | -5.8% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/group_similar | 1.7 min | 1.6 min | -5.6 s | -5.4% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 7.3 s | 7.0 s | -303 ms | -4.2% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 3.9 s | 3.7 s | -164 ms | -4.2% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 3.4 s | 3.3 s | -138 ms | -4.1% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/render/normalize_data | 4 ms | 3 ms | -1 ms | -25.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 4.3 min | 4 min | -14.2 s | -5.6% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 1.4 GB | 1.4 GB | +176 KB | 0.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 505.8 MB | 505.6 MB | -152.1 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 2.5 MB | 2.5 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 36.7 MB | 36.7 MB | -512 B | -0.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 29.4 MB | 29.4 MB | +17 KB | 0.1% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 35.9 MB | 35.9 MB | -896 B | -0.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 283.0 KB | 283.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_posting_size | 973.6 KB | 973.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 1.6 MB | 1.6 MB | +512 B | 0.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/format_scan_subs | 784 KB | 912 KB | +128 KB | 16.3% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_analysis | 567.4 MB | 567.4 MB | -8 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages | 566 MB | 565.5 MB | -572.4 KB | -0.1% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_stats | 60.0 KB | 58.3 KB | -1.7 KB | -2.8% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/message_key_order | 4.2 KB | 4.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | 593504900 | 592918745 | -586155 | -0.1% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 23003 | 13010 | -9993 | -43.4% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 530341146 | 530185359 | -155787 | -0.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 248469 | 248469 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | 424 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | 65592 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_messages_entries | 1317 | 1317 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_messages_population | 1317 | 1317 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/parse/read_files | 2.0 min | 1.9 min | -5.6 s | -4.8% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics | 2.3 s | 2.2 s | -139 ms | -6.0% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 1.7 s | 1.6 s | -54 ms | -3.3% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/group_calc | 591 ms | 513 ms | -78 ms | -13.2% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 76 ms | 70 ms | -6 ms | -7.9% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/finalize/heatmap_statistics | 120 ms | 103 ms | -17 ms | -14.2% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/total | 2 min | 1.9 min | -5.7 s | -4.8% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 2.6 GB | 1.9 GB | -616.8 MB | -23.6% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/bucket_outcomes | 6.8 KB | 7 KB | +256 B | 3.7% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/format_scan_subs | 736 KB | 1008 KB | +272 KB | 37.0% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | +256 B | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data | 83.1 KB | 74.9 KB | -8.2 KB | -9.9% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_analysis | 23.1 KB | 15.3 KB | -7.8 KB | -33.7% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/log_messages | 2.2 GB | 1.6 GB | -597.4 MB | -26.9% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_occurrences | 36.3 KB | 36.6 KB | +256 B | 0.7% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_stats | 38.7 KB | 35.0 KB | -3.7 KB | -9.5% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/unattributed | 383.4 MB | 363.7 MB | -19.7 MB | -5.1% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_messages | 2330828476 | 1704451393 | -626377083 | -26.9% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_analysis | 22331 | 12594 | -9737 | -43.6% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | COUNTS/log_messages_entries | 1212275 | 1212275 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | COUNTS/log_messages_population | 1212275 | 1212275 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/parse/read_files | 2.2 min | 2.1 min | -7.5 s | -5.7% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics | 5.5 s | 5 s | -469 ms | -8.5% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 3.1 s | 2.7 s | -401 ms | -12.8% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 1.6 s | 1.6 s | -9 ms | -0.5% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/group_calc | 654 ms | 600 ms | -54 ms | -8.3% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 69 ms | 64 ms | -5 ms | -7.2% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/finalize/histogram_statistics | 19 ms | 19 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/render/normalize_data | 3 ms | 2 ms | -1 ms | -33.3% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/total | 2.3 min | 2.1 min | -8.0 s | -5.8% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 2.8 GB | 2.4 GB | -470.8 MB | -16.2% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/format_scan_subs | 736 KB | 992 KB | +256 KB | 34.8% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/histogram_counters | 295.9 KB | 295.9 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_analysis | 568.6 MB | 568.5 MB | -8 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/log_messages | 2 GB | 1.6 GB | -453.1 MB | -21.8% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | +128 B | 0.0% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/log_stats | 60.0 KB | 58.3 KB | -1.7 KB | -2.8% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/unattributed | 257.7 MB | 239.7 MB | -18.0 MB | -7.0% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_messages | 2179547956 | 1704451513 | -475096443 | -21.8% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_analysis | 23003 | 13010 | -9993 | -43.4% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | COUNTS/log_messages_entries | 1212275 | 1212275 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | COUNTS/log_messages_population | 1212275 | 1212275 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/parse/read_files | 2.3 min | 2.2 min | -7.2 s | -5.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 2.2 s | 2.2 s | -47 ms | -2.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 1.6 s | 1.6 s | -7 ms | -0.4% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 544 ms | 514 ms | -30 ms | -5.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 80 ms | 71 ms | -9 ms | -11.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/heatmap_statistics | 112 ms | 103 ms | -9 ms | -8.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/histogram_statistics | 19 ms | 19 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/render/normalize_data | 3 ms | 2 ms | -1 ms | -33.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.4 min | 2.2 min | -7.2 s | -5.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 2.5 GB | 1.9 GB | -612.3 MB | -23.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/format_scan_subs | 752 KB | 992 KB | +240 KB | 31.9% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data | 81.6 KB | 74.6 KB | -7.0 KB | -8.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_counters | 295.9 KB | 295.9 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_analysis | 23.3 KB | 15.3 KB | -8 KB | -34.4% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_messages | 2.2 GB | 1.6 GB | -597.4 MB | -26.9% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_stats | 38.9 KB | 35.0 KB | -3.9 KB | -10.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/unattributed | 378.1 MB | 362.9 MB | -15.2 MB | -4.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 2330828476 | 1704451393 | -626377083 | -26.9% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 22587 | 12594 | -9993 | -44.2% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_messages_entries | 1212275 | 1212275 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_messages_population | 1212275 | 1212275 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 2.9 min | 2.7 min | -9.5 s | -5.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 1.3 min | 1.2 min | -5.8 s | -7.7% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 2.9 s | 2.8 s | -175 ms | -6.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 2.9 s | 2.8 s | -175 ms | -6.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 104 ms | 100 ms | -4 ms | -3.8% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 26 ms | 21 ms | -5 ms | -19.2% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 4.2 min | 4.0 min | -15.5 s | -6.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 1.1 GB | 1.1 GB | +7.7 MB | 0.7% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 505.8 MB | 505.6 MB | -154.1 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.5 MB | 2.5 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 36.7 MB | 36.7 MB | +512 B | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 26.9 MB | 29.4 MB | +2.6 MB | 9.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 36.0 MB | 35.9 MB | -1.1 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 283.0 KB | 283.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 973.6 KB | 973.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.6 MB | 1.6 MB | -128 B | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 752 KB | 880 KB | +128 KB | 17.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | +1.8 KB | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 82.1 KB | 77.4 KB | -4.7 KB | -5.8% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 295.9 KB | 296 KB | +128 B | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 23.3 KB | 15.3 KB | -8 KB | -34.4% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 565.9 MB | 565.4 MB | -495.3 KB | -0.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 38.9 KB | 35.0 KB | -3.9 KB | -10.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 1.9 KB | 1.9 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 593407428 | 592900201 | -507227 | -0.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 22587 | 12594 | -9993 | -44.2% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 530343322 | 530185487 | -157835 | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 248469 | 248469 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | 296 | -128 | -30.2% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | 65592 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 1317 | 1317 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | 1317 | 1317 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-p99 | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-p99 | TIMING/parse/read_files | 1.8 min | 1.7 min | -7.0 s | -6.5% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics | 13.1 s | 12.2 s | -907 ms | -6.9% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 3.3 s | 2.8 s | -487 ms | -14.7% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 6.2 s | 6 s | -152 ms | -2.5% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 3.4 s | 3.2 s | -259 ms | -7.5% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/group_calc | 21 ms | 21 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 146 ms | 138 ms | -8 ms | -5.5% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-p99 | TIMING/total | 2 min | 1.9 min | -7.9 s | -6.5% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/rss_peak | 3 GB | 2.4 GB | -619.4 MB | -20.0% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/format_scan_subs | 816 KB | 928 KB | +112 KB | 13.7% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_analysis | 568.6 MB | 568.5 MB | -8 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/log_messages | 2.2 GB | 1.6 GB | -599.2 MB | -27.0% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_occurrences | 36.8 KB | 36.8 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_stats | 60.0 KB | 58.3 KB | -1.7 KB | -2.8% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/unattributed | 306.2 MB | 285.9 MB | -20.3 MB | -6.6% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/log_messages | 2330839644 | 1702549793 | -628289851 | -27.0% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/log_analysis | 23003 | 13010 | -9993 | -43.4% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | COUNTS/log_messages_entries | 1212275 | 1212275 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | COUNTS/log_messages_population | 1212275 | 1212275 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/parse/read_files | 1.8 min | 1.7 min | -6 s | -5.6% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics | 8 s | 7.5 s | -549 ms | -6.8% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 3.2 s | 2.8 s | -426 ms | -13.3% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 4.4 s | 4.3 s | -111 ms | -2.5% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 13 ms | 13 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 303 ms | 298 ms | -5 ms | -1.7% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 72 ms | 66 ms | -6 ms | -8.3% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/total | 1.9 min | 1.8 min | -6.6 s | -5.7% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/rss_peak | 3.0 GB | 2.4 GB | -614.5 MB | -20.3% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/format_scan_subs | 768 KB | 1 MB | +256 KB | 33.3% | REGRESS |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_analysis | 568.6 MB | 568.5 MB | -8 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/log_messages | 2.2 GB | 1.6 GB | -597.4 MB | -26.9% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_sessions | 2.2 MB | 2.2 MB | +128 B | 0.0% | REGRESS |
| month-single-server-access-logs-sort-skewness | MEMORY/log_stats | 60.0 KB | 58.3 KB | -1.7 KB | -2.8% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/unattributed | 239.7 MB | 222.3 MB | -17.4 MB | -7.3% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/log_messages | 2330840321 | 1704464134 | -626376187 | -26.9% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/log_analysis | 23003 | 13010 | -9993 | -43.4% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | COUNTS/log_messages_entries | 1212275 | 1212275 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | COUNTS/log_messages_population | 1212275 | 1212275 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/detect/scan_sub_compile | 5 ms | 4 ms | -1 ms | -20.0% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/parse/read_files | 8.9 min | 8.5 min | -28.4 s | -5.3% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics | 33.4 s | 31.1 s | -2.3 s | -6.9% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/bucket_stats | 19.5 s | 17.5 s | -2.0 s | -10.0% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 9.6 s | 9.5 s | -55 ms | -0.6% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/group_calc | 3.9 s | 3.7 s | -173 ms | -4.5% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/untimed | 472 ms | 351 ms | -121 ms | -25.6% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/total | 9.5 min | 9.0 min | -30.7 s | -5.4% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 13.9 GB | 12 GB | -1.9 GB | -13.4% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/format_scan_subs | 768 KB | 880 KB | +112 KB | 14.6% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_analysis | 2.9 GB | 2.9 GB | -8 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/log_messages | 10.5 GB | 8.2 GB | -2.3 GB | -21.6% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_occurrences | 43.8 KB | 43.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -32 KB | -0.2% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/log_stats | 60.4 KB | 58.7 KB | -1.7 KB | -2.8% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/unattributed | 566.6 MB | 966.4 MB | +399.9 MB | 70.6% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_messages | 11231584895 | 8806440212 | -2425144683 | -21.6% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_analysis | 23003 | 13010 | -9993 | -43.4% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | COUNTS/log_messages_entries | 6187253 | 6187253 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | COUNTS/log_messages_population | 6187253 | 6187253 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | COUNTS/format_scan_sub_cache_hits | 139 | 139 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-no-messages | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-no-messages | TIMING/parse/read_files | 6.7 min | 6.5 min | -13.7 s | -3.4% | IMPROVE |
| month-many-servers-access-logs-no-messages | TIMING/finalize/calculate_statistics | 13.4 s | 12.9 s | -484 ms | -3.6% | IMPROVE |
| month-many-servers-access-logs-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | 13.4 s | 12.9 s | -483 ms | -3.6% | IMPROVE |
| month-many-servers-access-logs-no-messages | TIMING/finalize/calculate_statistics/untimed | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-no-messages | TIMING/render/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-many-servers-access-logs-no-messages | TIMING/total | 6.9 min | 6.7 min | -14.2 s | -3.4% | IMPROVE |
| month-many-servers-access-logs-no-messages | MEMORY/rss_peak | 3.3 GB | 3.3 GB | +8.1 MB | 0.2% | REGRESS |
| month-many-servers-access-logs-no-messages | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/format_scan_subs | 752 KB | 880 KB | +128 KB | 17.0% | REGRESS |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/log_analysis | 2.9 GB | 2.9 GB | -8 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-no-messages | MEMORY/log_messages | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-no-messages | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -32.1 KB | -0.2% | IMPROVE |
| month-many-servers-access-logs-no-messages | MEMORY/log_stats | 60.4 KB | 58.7 KB | -1.7 KB | -2.8% | IMPROVE |
| month-many-servers-access-logs-no-messages | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/unattributed | 441.9 MB | 449.9 MB | +8 MB | 1.8% | REGRESS |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/log_messages | 232 | 232 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/log_analysis | 23003 | 13010 | -9993 | -43.4% | IMPROVE |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | COUNTS/format_scan_sub_cache_hits | 139 | 139 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/parse/read_files | 8.9 min | 8.5 min | -27.2 s | -5.1% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics | 35.4 s | 32.4 s | -3.0 s | -8.4% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 19.2 s | 17.3 s | -1.9 s | -10.0% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 9.9 s | 9.4 s | -591 ms | -5.9% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/group_calc | 5.7 s | 5.4 s | -346 ms | -6.0% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 465 ms | 354 ms | -111 ms | -23.9% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/total | 9.5 min | 9 min | -30.2 s | -5.3% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 14 GB | 12.2 GB | -1.8 GB | -13.2% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/format_scan_subs | 752 KB | 864 KB | +112 KB | 14.9% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_analysis | 2.9 GB | 2.9 GB | -8 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/log_messages | 10.5 GB | 8.2 GB | -2.3 GB | -21.7% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_stats | 60.4 KB | 58.7 KB | -1.7 KB | -2.8% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/message_key_order | 4.7 KB | 4.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/unattributed | 661.2 MB | 1.1 GB | +428.3 MB | 64.8% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_messages | 11231595359 | 8796604132 | -2434991227 | -21.7% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_analysis | 23003 | 13010 | -9993 | -43.4% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | COUNTS/log_messages_entries | 6187253 | 6187253 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | COUNTS/log_messages_population | 6187253 | 6187253 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | COUNTS/format_scan_sub_cache_hits | 139 | 139 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/parse/read_files | 11.2 min | 10.6 min | -35.0 s | -5.2% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/group_similar | 16.9 min | 16.9 min | +1.6 s | 0.2% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 39.3 s | 38.6 s | -707 ms | -1.8% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 20.7 s | 20.5 s | -261 ms | -1.3% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 7 ms | 6 ms | -1 ms | -14.3% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 18.5 s | 18.1 s | -446 ms | -2.4% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/untimed | 29 ms | 29 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 28.7 min | 28.2 min | -34.1 s | -2.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 6.4 GB | 6.4 GB | -1.1 MB | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 2.6 GB | 2.6 GB | -339.8 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 2.5 MB | 2.5 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 36.8 MB | 36.8 MB | +1.5 KB | 0.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 25.3 MB | 29.2 MB | +3.9 MB | 15.6% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 36.1 MB | 36.1 MB | -1.1 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 531.3 KB | 531.2 KB | -128 B | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_posting_size | 1.2 MB | 1.2 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | 1.7 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/format_scan_subs | 752 KB | 960 KB | +208 KB | 27.7% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_analysis | 2.9 GB | 2.9 GB | -8 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages | 2.9 GB | 2.9 GB | -1.1 MB | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_occurrences | 43.8 KB | 43.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_stats | 60.4 KB | 58.7 KB | -1.7 KB | -2.8% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/message_key_order | 4.2 KB | 4.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | 3101287141 | 3100092586 | -1194555 | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 23003 | 13010 | -9993 | -43.4% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 2843380195 | 2843032192 | -348003 | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 544033 | 543905 | -128 | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | 424 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | 65592 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_messages_entries | 2549 | 2549 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_messages_population | 2549 | 2549 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | 139 | 139 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/parse/read_files | 9.6 min | 9.3 min | -19.6 s | -3.4% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics | 13.6 s | 13.2 s | -326 ms | -2.4% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 9.6 s | 9.8 s | +137 ms | 1.4% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/group_calc | 3.4 s | 3.1 s | -373 ms | -10.8% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 477 ms | 386 ms | -91 ms | -19.1% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/finalize/heatmap_statistics | 125 ms | 118 ms | -7 ms | -5.6% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/total | 9.8 min | 9.5 min | -20.0 s | -3.4% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 12.1 GB | 9.4 GB | -2.7 GB | -22.3% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/format_scan_subs | 816 KB | 960 KB | +144 KB | 17.6% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data | 80.1 KB | 76.8 KB | -3.3 KB | -4.1% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_analysis | 23.3 KB | 15.3 KB | -8 KB | -34.4% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/log_messages | 10.5 GB | 7.8 GB | -2.6 GB | -25.1% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_occurrences | 42.1 KB | 43.8 KB | +1.8 KB | 4.2% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_stats | 38.9 KB | 35.0 KB | -3.9 KB | -10.1% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/unattributed | 1.6 GB | 1.5 GB | -67.6 MB | -4.1% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_messages | 11226553911 | 8405397260 | -2821156651 | -25.1% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_analysis | 22587 | 12594 | -9993 | -44.2% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | COUNTS/log_messages_entries | 6187253 | 6187253 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | COUNTS/log_messages_population | 6187253 | 6187253 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | COUNTS/format_scan_sub_cache_hits | 139 | 139 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/parse/read_files | 10.7 min | 10.4 min | -17.7 s | -2.8% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics | 32.1 s | 31.4 s | -762 ms | -2.4% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 18.6 s | 17.5 s | -1.1 s | -6.0% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 9.3 s | 9.8 s | +529 ms | 5.7% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/group_calc | 3.8 s | 3.7 s | -96 ms | -2.5% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 430 ms | 353 ms | -77 ms | -17.9% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/finalize/histogram_statistics | 21 ms | 20 ms | -1 ms | -4.8% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/total | 11.3 min | 11.0 min | -18.5 s | -2.7% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 14.0 GB | 12.2 GB | -1.8 GB | -13.1% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/format_scan_subs | 736 KB | 960 KB | +224 KB | 30.4% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_counters | 307.7 KB | 307.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_analysis | 2.9 GB | 2.9 GB | -6.3 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/log_messages | 10.5 GB | 8.2 GB | -2.2 GB | -21.5% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -32 KB | -0.2% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/log_stats | 60.4 KB | 58.7 KB | -1.7 KB | -2.8% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/unattributed | 649.7 MB | 1.1 GB | +433.5 MB | 66.7% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_messages | 11221737151 | 8806440212 | -2415296939 | -21.5% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_analysis | 21211 | 13010 | -8201 | -38.7% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | COUNTS/log_messages_entries | 6187253 | 6187253 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | COUNTS/log_messages_population | 6187253 | 6187253 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | COUNTS/format_scan_sub_cache_hits | 139 | 139 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/parse/read_files | 11.3 min | 11 min | -14.8 s | -2.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 12.4 s | 13 s | +627 ms | 5.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 8.8 s | 9.5 s | +778 ms | 8.9% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 3.2 s | 3.1 s | -80 ms | -2.5% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 461 ms | 390 ms | -71 ms | -15.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/heatmap_statistics | 125 ms | 117 ms | -8 ms | -6.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/histogram_statistics | 21 ms | 20 ms | -1 ms | -4.8% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/render/normalize_data | 4 ms | 3 ms | -1 ms | -25.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 11.5 min | 11.3 min | -14.2 s | -2.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 12.1 GB | 9.8 GB | -2.4 GB | -19.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/format_scan_subs | 720 KB | 992 KB | +272 KB | 37.8% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | -1.8 KB | -0.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data | 80.1 KB | 76.8 KB | -3.3 KB | -4.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_counters | 307.8 KB | 307.7 KB | -128 B | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_analysis | 23.3 KB | 15.3 KB | -8 KB | -34.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages | 10.5 GB | 8.2 GB | -2.3 GB | -21.6% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_occurrences | 42.1 KB | 43.8 KB | +1.8 KB | 4.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +128 B | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_stats | 38.9 KB | 35.0 KB | -3.9 KB | -10.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/unattributed | 1.6 GB | 1.5 GB | -95.1 MB | -5.7% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 11226552375 | 8801380812 | -2425171563 | -21.6% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 22587 | 12594 | -9993 | -44.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_messages_entries | 6187253 | 6187253 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_messages_population | 6187253 | 6187253 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/format_scan_sub_cache_hits | 139 | 139 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 13.4 min | 13.0 min | -22.9 s | -2.8% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 12.3 min | 12.6 min | +14.8 s | 2.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 14.6 s | 15.4 s | +820 ms | 5.6% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 5 ms | -1 ms | -16.7% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 14.6 s | 15.4 s | +815 ms | 5.6% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/untimed | 18 ms | 24 ms | +6 ms | 33.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 111 ms | 111 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 21 ms | 21 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 26.0 min | 25.8 min | -7.3 s | -0.5% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 4.4 GB | 4.3 GB | -154.7 MB | -3.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 2.6 GB | 2.6 GB | -339.7 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.5 MB | 2.5 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 36.8 MB | 36.8 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 29.5 MB | 29.5 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 36.1 MB | 36.1 MB | +4.9 KB | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 531.3 KB | 531.3 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 1.2 MB | 1.2 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | 1.7 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 736 KB | 960 KB | +224 KB | 30.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 81.1 KB | 73.8 KB | -7.3 KB | -9.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 307.7 KB | 307.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 23.3 KB | 15.3 KB | -8 KB | -34.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 2.9 GB | 2.9 GB | -995.8 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +128 B | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 38.9 KB | 35.0 KB | -3.9 KB | -10.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 1.9 KB | 1.9 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 3094199021 | 3093179330 | -1019691 | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 22587 | 12594 | -9993 | -44.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 2836479275 | 2836131400 | -347875 | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 544033 | 544033 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | 424 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | 65592 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 2549 | 2549 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | 2549 | 2549 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | 139 | 139 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | TIMING/detect/scan_sub_compile | 5 ms | 4 ms | -1 ms | -20.0% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/parse/read_files | 8.8 min | 8.4 min | -20.1 s | -3.8% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics | 1.3 min | 1.2 min | -3.7 s | -4.7% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 18.2 s | 17.5 s | -754 ms | -4.1% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 36.9 s | 35.6 s | -1.3 s | -3.5% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 21.8 s | 20.3 s | -1.5 s | -6.7% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 921 ms | 758 ms | -163 ms | -17.7% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | TIMING/total | 10 min | 9.7 min | -23.8 s | -3.9% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/rss_peak | 15.5 GB | 12.4 GB | -3 GB | -19.5% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/format_scan_subs | 784 KB | 960 KB | +176 KB | 22.4% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_analysis | 2.9 GB | 2.9 GB | -8 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_messages | 11.2 GB | 8.2 GB | -3.0 GB | -26.6% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_occurrences | 42.1 KB | 43.8 KB | +1.8 KB | 4.2% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -32 KB | -0.2% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_stats | 60.4 KB | 58.7 KB | -1.7 KB | -2.8% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/message_key_order | 2.5 KB | 2.5 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/unattributed | 1.4 GB | 1.3 GB | -35.1 MB | -2.5% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/log_messages | 12003745175 | 8806473132 | -3197272043 | -26.6% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/log_analysis | 23003 | 13010 | -9993 | -43.4% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | COUNTS/log_messages_entries | 6187253 | 6187253 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | COUNTS/log_messages_population | 6187253 | 6187253 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | COUNTS/format_scan_sub_cache_hits | 139 | 139 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | TIMING/detect/registry_build | 9 ms | 9 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | TIMING/detect/scan_sub_compile | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | TIMING/parse/read_files | 8.7 min | 8.4 min | -16.9 s | -3.2% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics | 46 s | 45.1 s | -931 ms | -2.0% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 18.7 s | 17.4 s | -1.2 s | -6.6% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 25.7 s | 26.1 s | +385 ms | 1.5% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 75 ms | 73 ms | -2 ms | -2.7% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 1.1 s | 1.1 s | +8 ms | 0.7% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 454 ms | 372 ms | -82 ms | -18.1% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | TIMING/total | 9.5 min | 9.2 min | -17.8 s | -3.1% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY/rss_peak | 14.7 GB | 12 GB | -2.7 GB | -18.2% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/format_scan_subs | 784 KB | 1 MB | +240 KB | 30.6% | REGRESS |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_analysis | 2.9 GB | 2.9 GB | -8 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_messages | 11.2 GB | 8.2 GB | -3.0 GB | -26.6% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_stats | 60.4 KB | 58.7 KB | -1.7 KB | -2.8% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/message_key_order | 2.1 KB | 2.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/unattributed | 647.9 MB | 948.6 MB | +300.7 MB | 46.4% | REGRESS |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/log_messages | 12003745084 | 8806474577 | -3197270507 | -26.6% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/log_analysis | 23003 | 13010 | -9993 | -43.4% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | COUNTS/log_messages_entries | 6187253 | 6187253 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | COUNTS/log_messages_population | 6187253 | 6187253 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | COUNTS/format_scan_sub_cache_hits | 139 | 139 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_excluded | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | lines_excluded | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | lines_excluded | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | lines_read | N/A | 288,025 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | lines_excluded | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | lines_included | N/A | 288,025 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/detect/registry_build | N/A | 9 ms | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/parse/read_files | N/A | 1.9 s | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/finalize/group_similar | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/finalize/calculate_statistics | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/finalize/calculate_statistics/sort_selection | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/finalize/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/render/normalize_data | N/A | 1 ms | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/total | N/A | 1.9 s | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/rss_peak | N/A | 36.0 MB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/bucket_outcomes | N/A | 1.3 KB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/format_scan_subs | N/A | 1 MB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/log_analysis | N/A | 232 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/log_messages | N/A | 232 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/log_occurrences | N/A | 4.5 KB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/log_stats | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/message_key_order | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/unattributed | N/A | 35.0 MB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/log_messages | N/A | 232 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | COUNTS/log_messages_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | COUNTS/log_occurrences_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | COUNTS/log_stats_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | COUNTS/log_messages_population | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-standard | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-no-messages | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-top25 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | lines_read | N/A | 479,904 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | lines_included | N/A | 479,904 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | TIMING/detect/registry_build | N/A | 9 ms | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | TIMING/parse/read_files | N/A | 3 s | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | TIMING/finalize/group_similar | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics/sort_selection | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | TIMING/finalize/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | TIMING/render/normalize_data | N/A | 1 ms | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | TIMING/total | N/A | 3.1 s | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/rss_peak | N/A | 36.1 MB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/bucket_outcomes | N/A | 6 KB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/format_scan_subs | N/A | 992 KB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_analysis | N/A | 232 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_messages | N/A | 232 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_occurrences | N/A | 21.8 KB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_stats | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/message_key_order | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/unattributed | N/A | 35.1 MB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/log_messages | N/A | 232 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | COUNTS/log_messages_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | COUNTS/log_occurrences_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | COUNTS/log_stats_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | COUNTS/log_messages_population | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-standard | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-top25 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | lines_read | N/A | 930,031 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | lines_included | N/A | 930,028 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | TIMING/detect/registry_build | N/A | 9 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | TIMING/parse/read_files | N/A | 6.3 s | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | TIMING/finalize/group_similar | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/sort_selection | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | TIMING/finalize/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | TIMING/render/normalize_data | N/A | 2 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | TIMING/total | N/A | 6.3 s | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/rss_peak | N/A | 37.6 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/bucket_outcomes | N/A | 13.3 KB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/format_scan_subs | N/A | 1 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_analysis | N/A | 232 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_messages | N/A | 232 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_occurrences | N/A | 56.6 KB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_stats | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/message_key_order | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/unattributed | N/A | 36.5 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/log_messages | N/A | 232 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | COUNTS/log_messages_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | COUNTS/log_occurrences_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | COUNTS/log_stats_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | COUNTS/log_messages_population | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | COUNTS/format_scan_sub_cache_hits | N/A | 40 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | CONFIG/time_bucket_size | N/A | 480 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | CONFIG/bucket_size_seconds | N/A | 28800.00 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-standard | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | lines_read | N/A | 1,530,399 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | lines_included | N/A | 1,530,399 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/detect/registry_build | N/A | 9 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/parse/read_files | N/A | 14.3 s | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/group_similar | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics | N/A | 115 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 115 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/sort_selection | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | N/A | 154 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/histogram_statistics | N/A | 14 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/render/normalize_data | N/A | 1 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/total | N/A | 14.6 s | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/rss_peak | N/A | 73.7 MB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/bucket_outcomes | N/A | 6.1 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/format_scan_subs | N/A | 992 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_counters | N/A | 985.5 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_data | N/A | 43.4 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/histogram_counters | N/A | 122.5 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_analysis | N/A | 28.4 MB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_messages | N/A | 232 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_occurrences | N/A | 20 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_stats | N/A | 80.2 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/message_key_order | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/unattributed | N/A | 43 MB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/log_messages | N/A | 232 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/log_analysis | N/A | 23103 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | COUNTS/log_messages_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | COUNTS/log_occurrences_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | COUNTS/log_stats_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | COUNTS/log_analysis_entries | N/A | 24 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | COUNTS/log_messages_population | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | COUNTS/format_scan_sub_cache_hits | N/A | 4 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-standard | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-no-messages | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-top25 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-heatmap | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | lines_read | N/A | 761,698 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | lines_included | N/A | 761,698 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/detect/registry_build | N/A | 9 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/parse/read_files | N/A | 10.3 s | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/group_similar | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics | N/A | 220 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 220 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics/sort_selection | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | N/A | 98 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/histogram_statistics | N/A | 11 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/render/normalize_data | N/A | 1 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/total | N/A | 10.6 s | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/rss_peak | N/A | 100.6 MB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/bucket_outcomes | N/A | 3.8 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/format_scan_subs | N/A | 976 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_counters | N/A | 572.2 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_data | N/A | 33.8 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/histogram_counters | N/A | 106 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_analysis | N/A | 52.7 MB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_messages | N/A | 232 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_occurrences | N/A | 18.4 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_stats | N/A | 49.5 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/message_key_order | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/unattributed | N/A | 46.2 MB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/log_messages | N/A | 232 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/log_analysis | N/A | 12087 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | COUNTS/log_messages_entries | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | COUNTS/log_occurrences_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | COUNTS/log_stats_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | COUNTS/log_analysis_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | COUNTS/log_messages_population | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-standard | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | lines_included | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/detect/registry_build | N/A | 9 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/parse/read_files | N/A | 1.9 min | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/group_similar | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics | N/A | 3.1 s | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 3.1 s | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/sort_selection | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/untimed | N/A | 2 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | N/A | 223 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/histogram_statistics | N/A | 18 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/render/normalize_data | N/A | 2 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/total | N/A | 2.0 min | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/rss_peak | N/A | 653.8 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/format_scan_subs | N/A | 992 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters | N/A | 2.4 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_data | N/A | 75.9 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/histogram_counters | N/A | 295.9 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_analysis | N/A | 566.1 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_messages | N/A | 232 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_occurrences | N/A | 36.8 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_sessions | N/A | 2.2 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_stats | N/A | 94 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/message_key_order | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/unattributed | N/A | 81.6 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_messages | N/A | 232 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_analysis | N/A | 23003 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | COUNTS/log_messages_entries | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | COUNTS/log_messages_population | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | COUNTS/format_scan_sub_cache_hits | N/A | 27 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/detect/registry_build | N/A | 9 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/parse/read_files | N/A | 9.4 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/group_similar | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics | N/A | 18.8 s | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 18.7 s | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/sort_selection | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/untimed | N/A | 12 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | N/A | 236 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/histogram_statistics | N/A | 19 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/render/normalize_data | N/A | 2 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/total | N/A | 9.8 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/rss_peak | N/A | 3.3 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/format_scan_subs | N/A | 1 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters | N/A | 2.7 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_data | N/A | 76.3 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/histogram_counters | N/A | 307.7 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_analysis | N/A | 2.9 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_messages | N/A | 232 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_occurrences | N/A | 42.1 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_sessions | N/A | 14.9 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_stats | N/A | 95.6 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/message_key_order | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/unattributed | N/A | 450.1 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_messages | N/A | 232 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_analysis | N/A | 23003 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | COUNTS/log_messages_entries | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | COUNTS/log_messages_population | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | COUNTS/format_scan_sub_cache_hits | N/A | 139 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | lines_excluded | N/A | 0 | N/A | N/A | ? |

