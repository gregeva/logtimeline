
## Benchmark Comparison

  Baseline:    v0.16.0 (v0.16.0, 63 test cases)
  Current:     v0.17.0-release (v0.17.0, 63 test cases)

### Timing Delta

| # | file selection | standard | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons | sort-p99 | sort-skew |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | -5.2% | -5.3% | +6.2% | -5.8% | -4.5% | -4.4% | +7.4% | -1.2% | -3.0% |
| 2. | single-day-application-log | -13.2% | -12.6% | -5.3% | -11.2% | -12.2% | -12.6% | -4.3% | -12.2% | -12.5% |
| 3. | multi-day-application-logs | -10.9% | -12.3% | +5.4% | -12.4% | -8.9% | -10.5% | +4.1% | -10.6% | -10.0% |
| 4. | multi-day-custom-logs | -2.5% | -1.6% | +4.8% | -3.7% | -2.8% | -2.9% | +5.3% | -2.5% | -2.7% |
| 5. | single-day-access-log | -20.3% | -18.4% | -9.1% | -18.9% | -18.6% | -17.4% | -12.9% | -22.1% | -22.3% |
| 6. | month-single-server-access-logs | -20.5% | -21.9% | -6.8% | -18.8% | -15.9% | -14.0% | -5.9% | -18.5% | -19.6% |
| 7. | month-many-servers-access-logs | -17.5% | -17.2% | -8.3% | -20.0% | -16.9% | -16.1% | -6.4% | -18.6% | -20.1% |

### Memory Delta (RSS Peak)

| # | file selection | standard | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons | sort-p99 | sort-skew |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | +1.5% | +1.9% | +2.2% | +1.6% | +2.2% | +2.1% | +2.1% | +2.5% | +1.1% |
| 2. | single-day-application-log | -4.1% | -3.1% | -1.9% | -4.0% | -4.1% | -3.8% | -2.6% | -2.7% | -3.2% |
| 3. | multi-day-application-logs | -17.7% | -17.3% | -6.0% | -17.9% | -16.9% | -17.4% | -4.0% | -16.5% | -16.5% |
| 4. | multi-day-custom-logs | +0.8% | +1.1% | -1.2% | +0.6% | +1.0% | -0.5% | +1.0% | +0.9% | +0.1% |
| 5. | single-day-access-log | -0.5% | +1.2% | +0.5% | -0.1% | -1.4% | -0.9% | -2.2% | +0.9% | +0.8% |
| 6. | month-single-server-access-logs | -6.5% | -6.0% | -11.4% | -7.9% | -6.9% | -8.5% | -13.1% | -6.3% | -9.3% |
| 7. | month-many-servers-access-logs | -0.1% | -1.6% | -4.2% | -1.7% | -4.9% | +1.3% | -6.0% | -1.9% | -2.7% |

### Stage Rollup (timing)

| metric | baseline | current | delta | change% | cases +/- | result |
| --- | --- | --- | --- | --- | --- | --- |
| parse/read_files | 132.8 min | 109.9 min | -22.9 min | -17.2% | 6/57 | IMPROVE |
| finalize/group_similar | 33.2 min | 33.3 min | +4.5 s | 0.2% | 13/1 | REGRESS |
| finalize/calculate_statistics | 5.7 min | 6.0 min | +16.9 s | 5.0% | 48/4 | REGRESS |
| total | 171.7 min | 149.2 min | -22.5 min | -13.1% | 6/57 | IMPROVE |
| (3 below noise floor) | 638 ms | 663 ms | +25 ms | 3.9% | - | REGRESS |
| sum of stages | 171.7 min | 149.1 min | -22.5 min | -13.1% | - | IMPROVE |

### Category Rollup (memory)

| metric | baseline | current | delta | change% | cases +/- | result |
| --- | --- | --- | --- | --- | --- | --- |
| rss_peak | 119 GB | 115.3 GB | -3.7 GB | -3.1% | 21/42 | IMPROVE |
| unattributed | 15.5 GB | 12.6 GB | -2.9 GB | -18.7% | 19/41 | IMPROVE |
| log_messages | 77.4 GB | 77.3 GB | -54.4 MB | -0.1% | 16/14 | IMPROVE (most cases REGRESS) |
| consolidation_clusters | 6.4 GB | 6.4 GB | +6.2 MB | 0.1% | 2/3 | REGRESS (most cases IMPROVE) |
| log_analysis | 21.1 GB | 21.1 GB | +4.2 MB | 0.0% | 5/2 | REGRESS |
| consolidation_key_trigrams_norm | 305 MB | 308.8 MB | +3.8 MB | 1.2% | 2/2 | REGRESS |
| (26 below noise floor) | 1.4 GB | 1.4 GB | -41.2 KB | -0.0% | - | IMPROVE |

### New In This Version

| metric | test cases | per-test range | aggregate |
| --- | --- | --- | --- |
| TIMING/detect/registry_build | 63 | 8 ms - 9 ms | 506 ms |
| TIMING/detect/scan_sub_compile (within parent) | 63 | 4 ms - 5 ms | 264 ms |
| TIMING/finalize/calculate_statistics/bucket_stats (within parent) | 63 | 0 us - 20.2 s | 2.1 min |
| TIMING/finalize/calculate_statistics/population_walk (within parent) | 63 | 0 us - 35.4 s | 1.2 min |
| TIMING/finalize/calculate_statistics/sort_selection (within parent) | 63 | 0 us - 21.4 s | 1.5 min |
| TIMING/finalize/calculate_statistics/group_calc (within parent) | 63 | 0 us - 18.0 s | 1.1 min |
| TIMING/finalize/calculate_statistics/threadpool_stats (within parent) | 63 | 0 us - 0 us | 0 us |
| TIMING/finalize/calculate_statistics/untimed (within parent) | 63 | 0 us - 836 ms | 4.0 s |
| MEMORY/format_scan_subs | 63 | 640 KB - 816 KB | 45.7 MB |

### Summary

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.7 s | 2.6 s | -142 ms | -5.2% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 205.3 MB | 208.5 MB | +3.2 MB | 1.5% | REGRESS |
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.7 s | 2.6 s | -143 ms | -5.3% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 205.6 MB | 209.4 MB | +3.9 MB | 1.9% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 10.3 s | 11.0 s | +640 ms | 6.2% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 249 MB | 254.4 MB | +5.4 MB | 2.2% | REGRESS |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.7 s | 2.5 s | -156 ms | -5.8% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 205 MB | 208.3 MB | +3.3 MB | 1.6% | REGRESS |
| humungous-log-uniqueness-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.7 s | 2.5 s | -119 ms | -4.5% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 205.2 MB | 209.6 MB | +4.4 MB | 2.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.7 s | 2.5 s | -116 ms | -4.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 205.7 MB | 209.9 MB | +4.3 MB | 2.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 10.2 s | 10.9 s | +758 ms | 7.4% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 249.7 MB | 255.0 MB | +5.3 MB | 2.1% | REGRESS |
| humungous-log-uniqueness-sort-p99 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/total | 2.8 s | 2.8 s | -34 ms | -1.2% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | MEMORY/rss_peak | 203.2 MB | 208.2 MB | +5 MB | 2.5% | REGRESS |
| humungous-log-uniqueness-sort-skewness | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/total | 2.9 s | 2.8 s | -85 ms | -3.0% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | MEMORY/rss_peak | 203.6 MB | 205.9 MB | +2.3 MB | 1.1% | REGRESS |
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.8 s | 3.3 s | -501 ms | -13.2% | IMPROVE |
| single-day-application-log-standard | MEMORY/rss_peak | 37.4 MB | 35.8 MB | -1.5 MB | -4.1% | IMPROVE |
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.8 s | 3.3 s | -471 ms | -12.6% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 37.3 MB | 36.1 MB | -1.2 MB | -3.1% | IMPROVE |
| single-day-application-log-top25-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 6.6 s | 6.3 s | -348 ms | -5.3% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 125.6 MB | 123.3 MB | -2.3 MB | -1.9% | IMPROVE |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.7 s | 3.3 s | -413 ms | -11.2% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/rss_peak | 37.3 MB | 35.8 MB | -1.5 MB | -4.0% | IMPROVE |
| single-day-application-log-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.8 s | 3.3 s | -460 ms | -12.2% | IMPROVE |
| single-day-application-log-histogram | MEMORY/rss_peak | 37.3 MB | 35.8 MB | -1.5 MB | -4.1% | IMPROVE |
| single-day-application-log-heatmap-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.7 s | 3.3 s | -471 ms | -12.6% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 37.3 MB | 35.9 MB | -1.4 MB | -3.8% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 6.6 s | 6.3 s | -285 ms | -4.3% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 126.4 MB | 123.1 MB | -3.2 MB | -2.6% | IMPROVE |
| single-day-application-log-sort-p99 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/total | 3.8 s | 3.3 s | -461 ms | -12.2% | IMPROVE |
| single-day-application-log-sort-p99 | MEMORY/rss_peak | 37.0 MB | 36.0 MB | -1 MB | -2.7% | IMPROVE |
| single-day-application-log-sort-skewness | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/total | 3.8 s | 3.3 s | -471 ms | -12.5% | IMPROVE |
| single-day-application-log-sort-skewness | MEMORY/rss_peak | 37.4 MB | 36.2 MB | -1.2 MB | -3.2% | IMPROVE |
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 8.1 s | 7.2 s | -880 ms | -10.9% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/rss_peak | 114.8 MB | 94.5 MB | -20.4 MB | -17.7% | IMPROVE |
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 8.2 s | 7.2 s | -999 ms | -12.3% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 115.1 MB | 95.1 MB | -19.9 MB | -17.3% | IMPROVE |
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 40.8 s | 43.0 s | +2.2 s | 5.4% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 226.1 MB | 212.6 MB | -13.5 MB | -6.0% | IMPROVE |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 8.1 s | 7.1 s | -1 s | -12.4% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 115.1 MB | 94.5 MB | -20.6 MB | -17.9% | IMPROVE |
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 8.1 s | 7.4 s | -723 ms | -8.9% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 114.9 MB | 95.5 MB | -19.4 MB | -16.9% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 8.1 s | 7.3 s | -853 ms | -10.5% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 115.1 MB | 95.1 MB | -20.0 MB | -17.4% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 41.0 s | 42.6 s | +1.7 s | 4.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 224.4 MB | 215.4 MB | -9 MB | -4.0% | IMPROVE |
| multi-day-application-logs-sort-p99 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/total | 8.1 s | 7.2 s | -852 ms | -10.6% | IMPROVE |
| multi-day-application-logs-sort-p99 | MEMORY/rss_peak | 114.4 MB | 95.5 MB | -18.9 MB | -16.5% | IMPROVE |
| multi-day-application-logs-sort-skewness | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/total | 8.1 s | 7.3 s | -809 ms | -10.0% | IMPROVE |
| multi-day-application-logs-sort-skewness | MEMORY/rss_peak | 114.3 MB | 95.5 MB | -18.9 MB | -16.5% | IMPROVE |
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 16.5 s | 16.1 s | -421 ms | -2.5% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 192.9 MB | 194.4 MB | +1.5 MB | 0.8% | REGRESS |
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 16.4 s | 16.1 s | -266 ms | -1.6% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 192.8 MB | 195 MB | +2.2 MB | 1.1% | REGRESS |
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 52.6 s | 55.1 s | +2.5 s | 4.8% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 247.3 MB | 244.5 MB | -2.9 MB | -1.2% | IMPROVE |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 17 s | 16.4 s | -626 ms | -3.7% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 177.8 MB | 178.8 MB | +1 MB | 0.6% | REGRESS |
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 17.3 s | 16.8 s | -486 ms | -2.8% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 192.6 MB | 194.4 MB | +1.8 MB | 1.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 17.6 s | 17.1 s | -503 ms | -2.9% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 180.4 MB | 179.5 MB | -976 KB | -0.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 52.9 s | 55.7 s | +2.8 s | 5.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 231.5 MB | 233.8 MB | +2.3 MB | 1.0% | REGRESS |
| multi-day-custom-logs-sort-p99 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/total | 16.4 s | 16.0 s | -416 ms | -2.5% | IMPROVE |
| multi-day-custom-logs-sort-p99 | MEMORY/rss_peak | 190.2 MB | 191.9 MB | +1.6 MB | 0.9% | REGRESS |
| multi-day-custom-logs-sort-skewness | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/total | 16.5 s | 16 s | -450 ms | -2.7% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY/rss_peak | 192 MB | 192.2 MB | +176 KB | 0.1% | REGRESS |
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 11.3 s | 9 s | -2.3 s | -20.3% | IMPROVE |
| single-day-access-log-standard | MEMORY/rss_peak | 143.5 MB | 142.8 MB | -704 KB | -0.5% | IMPROVE |
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 11.2 s | 9.2 s | -2.1 s | -18.4% | IMPROVE |
| single-day-access-log-top25 | MEMORY/rss_peak | 144.3 MB | 146.0 MB | +1.7 MB | 1.2% | REGRESS |
| single-day-access-log-top25-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 16.7 s | 15.2 s | -1.5 s | -9.1% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 180.4 MB | 181.2 MB | +880 KB | 0.5% | REGRESS |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 11.9 s | 9.6 s | -2.2 s | -18.9% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/rss_peak | 116.5 MB | 116.4 MB | -176 KB | -0.1% | IMPROVE |
| single-day-access-log-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 13.3 s | 10.8 s | -2.5 s | -18.6% | IMPROVE |
| single-day-access-log-histogram | MEMORY/rss_peak | 146.2 MB | 144.2 MB | -2.1 MB | -1.4% | IMPROVE |
| single-day-access-log-heatmap-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 13.6 s | 11.3 s | -2.4 s | -17.4% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 117.5 MB | 116.5 MB | -1 MB | -0.9% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 17.9 s | 15.6 s | -2.3 s | -12.9% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 158.4 MB | 154.9 MB | -3.4 MB | -2.2% | IMPROVE |
| single-day-access-log-sort-p99 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/total | 11.3 s | 8.8 s | -2.5 s | -22.1% | IMPROVE |
| single-day-access-log-sort-p99 | MEMORY/rss_peak | 143.3 MB | 144.6 MB | +1.3 MB | 0.9% | REGRESS |
| single-day-access-log-sort-skewness | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/total | 11.5 s | 9.0 s | -2.6 s | -22.3% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY/rss_peak | 149.2 MB | 150.4 MB | +1.2 MB | 0.8% | REGRESS |
| month-single-server-access-logs-standard | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/total | 2.1 min | 1.7 min | -26 s | -20.5% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2.5 GB | 2.4 GB | -169.3 MB | -6.5% | IMPROVE |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 2.1 min | 1.7 min | -28.1 s | -21.9% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2.5 GB | 2.4 GB | -155.8 MB | -6.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 4.4 min | 4.1 min | -17.9 s | -6.8% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 1.6 GB | 1.4 GB | -181.5 MB | -11.4% | IMPROVE |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/total | 2.3 min | 1.8 min | -25.4 s | -18.8% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 2.1 GB | 1.9 GB | -170.6 MB | -7.9% | IMPROVE |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/total | 2.5 min | 2.1 min | -23.9 s | -15.9% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 2.5 GB | 2.4 GB | -179.4 MB | -6.9% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.6 min | 2.2 min | -21.5 s | -14.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 2 GB | 1.9 GB | -178.6 MB | -8.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 4.4 min | 4.1 min | -15.6 s | -5.9% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 1.3 GB | 1.1 GB | -168.9 MB | -13.1% | IMPROVE |
| month-single-server-access-logs-sort-p99 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | TIMING/total | 2.3 min | 1.8 min | -25 s | -18.5% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/rss_peak | 2.6 GB | 2.4 GB | -165.4 MB | -6.3% | IMPROVE |
| month-single-server-access-logs-sort-skewness | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/total | 2.2 min | 1.8 min | -25.7 s | -19.6% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/rss_peak | 2.5 GB | 2.3 GB | -240.3 MB | -9.3% | IMPROVE |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/total | 10.7 min | 8.8 min | -1.9 min | -17.5% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 12.1 GB | 12.1 GB | -12.3 MB | -0.1% | IMPROVE |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/total | 10.6 min | 8.8 min | -1.8 min | -17.2% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 12.4 GB | 12.2 GB | -205.4 MB | -1.6% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 30.2 min | 27.6 min | -2.5 min | -8.3% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 6.7 GB | 6.4 GB | -285.9 MB | -4.2% | IMPROVE |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/total | 11.2 min | 9.0 min | -2.2 min | -20.0% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 9.9 GB | 9.7 GB | -171.1 MB | -1.7% | IMPROVE |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/total | 12.5 min | 10.4 min | -2.1 min | -16.9% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 12.4 GB | 11.8 GB | -626.3 MB | -4.9% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 12.8 min | 10.7 min | -2.1 min | -16.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 9.6 GB | 9.8 GB | +127.9 MB | 1.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 27.5 min | 25.8 min | -1.8 min | -6.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 4.6 GB | 4.3 GB | -281.1 MB | -6.0% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | TIMING/total | 11.3 min | 9.2 min | -2.1 min | -18.6% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/rss_peak | 12.7 GB | 12.4 GB | -245.2 MB | -1.9% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | TIMING/total | 10.9 min | 8.7 min | -2.2 min | -20.1% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY/rss_peak | 12.4 GB | 12 GB | -338.0 MB | -2.7% | IMPROVE |

### Detailed

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/parse/read_files | 2.5 s | 2.2 s | -216 ms | -8.8% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics | 274 ms | 340 ms | +66 ms | 24.1% | REGRESS |
| humungous-log-uniqueness-standard | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.7 s | 2.6 s | -142 ms | -5.2% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 205.3 MB | 208.5 MB | +3.2 MB | 1.5% | REGRESS |
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
| humungous-log-uniqueness-standard | MEMORY/log_messages | 127 MB | 127 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/unattributed | 78.3 MB | 80.7 MB | +2.4 MB | 3.1% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY_FINAL/log_messages | 133188237 | 133188237 | 0 | 0.0% |  |
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
| humungous-log-uniqueness-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/parse/read_files | 2.4 s | 2.2 s | -230 ms | -9.5% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics | 269 ms | 348 ms | +79 ms | 29.4% | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.7 s | 2.6 s | -143 ms | -5.3% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 205.6 MB | 209.4 MB | +3.9 MB | 1.9% | REGRESS |
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
| humungous-log-uniqueness-top25 | MEMORY/log_messages | 127 MB | 127 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/message_key_order | 7.7 KB | 7.7 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/unattributed | 78.5 MB | 81.7 MB | +3.1 MB | 4.0% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/log_messages | 133188237 | 133188237 | 0 | 0.0% |  |
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
| humungous-log-uniqueness-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/parse/read_files | 6.4 s | 6.5 s | +91 ms | 1.4% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | TIMING/finalize/group_similar | 3.9 s | 4.4 s | +542 ms | 14.0% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 10.3 s | 11.0 s | +640 ms | 6.2% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 249 MB | 254.4 MB | +5.4 MB | 2.2% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_clusters | 196.2 KB | 196.2 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_message | 3.1 MB | 3.1 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_trigrams | 71.7 MB | 71.7 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 64.2 MB | 64.2 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_ngram_index | 66.7 MB | 66.7 MB | +18.6 KB | 0.0% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_patterns | 24.8 KB | 24.8 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_posting_size | 614.1 KB | 614.1 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | 1.7 MB | 0 B | 0.0% |  |
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
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_messages | 2.5 MB | 2.5 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/message_key_order | 9.4 KB | 9.4 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/unattributed | 38.2 MB | 42.9 MB | +4.7 MB | 12.2% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/log_messages | 100953 | 100953 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 200881 | 200881 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 25391 | 25391 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 232 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | 65592 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_messages_entries | 72 | 72 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/parse/read_files | 2.4 s | 2.2 s | -219 ms | -9.0% | IMPROVE |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics | 270 ms | 326 ms | +56 ms | 20.7% | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.7 s | 2.5 s | -156 ms | -5.8% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 205 MB | 208.3 MB | +3.3 MB | 1.6% | REGRESS |
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
| humungous-log-uniqueness-heatmap | MEMORY/log_messages | 127 MB | 127 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/unattributed | 78.0 MB | 80.5 MB | +2.5 MB | 3.2% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/log_messages | 133188237 | 133188237 | 0 | 0.0% |  |
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
| humungous-log-uniqueness-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/parse/read_files | 2.4 s | 2.2 s | -222 ms | -9.2% | IMPROVE |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics | 261 ms | 357 ms | +96 ms | 36.8% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.7 s | 2.5 s | -119 ms | -4.5% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 205.2 MB | 209.6 MB | +4.4 MB | 2.2% | REGRESS |
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
| humungous-log-uniqueness-histogram | MEMORY/log_messages | 127 MB | 127 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/unattributed | 78.2 MB | 81.9 MB | +3.7 MB | 4.7% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/log_messages | 133188237 | 133188237 | 0 | 0.0% |  |
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
| humungous-log-uniqueness-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/parse/read_files | 2.4 s | 2.2 s | -207 ms | -8.6% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics | 259 ms | 343 ms | +84 ms | 32.4% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.7 s | 2.5 s | -116 ms | -4.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 205.7 MB | 209.9 MB | +4.3 MB | 2.1% | REGRESS |
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
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_messages | 127 MB | 127 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/unattributed | 78.6 MB | 82.2 MB | +3.5 MB | 4.5% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/log_messages | 133188237 | 133188237 | 0 | 0.0% |  |
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
| humungous-log-uniqueness-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/parse/read_files | 6.3 s | 6.5 s | +212 ms | 3.4% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 3.9 s | 4.4 s | +538 ms | 13.9% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 10.2 s | 10.9 s | +758 ms | 7.4% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 249.7 MB | 255.0 MB | +5.3 MB | 2.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 196.2 KB | 196.2 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 3.1 MB | 3.1 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 71.7 MB | 71.7 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 64.2 MB | 64.2 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 66.7 MB | 66.7 MB | +11.9 KB | 0.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 24.8 KB | 24.8 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 614.1 KB | 614.1 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | 1.7 MB | -64 B | -0.0% | IMPROVE |
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
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_messages | 2.5 MB | 2.5 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/message_key_order | 3.2 KB | 3.2 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/unattributed | 38.9 MB | 43.5 MB | +4.6 MB | 11.8% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 100953 | 100953 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 200881 | 200881 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 25391 | 25391 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 232 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | 65592 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 72 | 72 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/parse/read_files | 2.4 s | 2.2 s | -163 ms | -6.8% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics | 449 ms | 570 ms | +121 ms | 26.9% | REGRESS |
| humungous-log-uniqueness-sort-p99 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/total | 2.8 s | 2.8 s | -34 ms | -1.2% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | MEMORY/rss_peak | 203.2 MB | 208.2 MB | +5 MB | 2.5% | REGRESS |
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
| humungous-log-uniqueness-sort-p99 | MEMORY/log_messages | 127 MB | 127 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/unattributed | 76.1 MB | 80.5 MB | +4.3 MB | 5.7% | REGRESS |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/log_messages | 133188237 | 133188237 | 0 | 0.0% |  |
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
| humungous-log-uniqueness-sort-p99 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/parse/read_files | 2.4 s | 2.2 s | -217 ms | -9.1% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics | 453 ms | 578 ms | +125 ms | 27.6% | REGRESS |
| humungous-log-uniqueness-sort-skewness | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/total | 2.9 s | 2.8 s | -85 ms | -3.0% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | MEMORY/rss_peak | 203.6 MB | 205.9 MB | +2.3 MB | 1.1% | REGRESS |
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
| humungous-log-uniqueness-sort-skewness | MEMORY/log_messages | 127 MB | 127 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/unattributed | 76.6 MB | 78.1 MB | +1.5 MB | 2.0% | REGRESS |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/log_messages | 133188237 | 133188237 | 0 | 0.0% |  |
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
| humungous-log-uniqueness-sort-skewness | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/parse/read_files | 3.8 s | 3.3 s | -510 ms | -13.5% | IMPROVE |
| single-day-application-log-standard | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.8 s | 3.3 s | -501 ms | -13.2% | IMPROVE |
| single-day-application-log-standard | MEMORY/rss_peak | 37.4 MB | 35.8 MB | -1.5 MB | -4.1% | IMPROVE |
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
| single-day-application-log-standard | MEMORY/log_messages | 2.7 MB | 2.7 MB | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_occurrences | 21.5 KB | 21.8 KB | +256 B | 1.2% | REGRESS |
| single-day-application-log-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/unattributed | 34.6 MB | 32.3 MB | -2.3 MB | -6.5% | IMPROVE |
| single-day-application-log-standard | MEMORY_FINAL/log_messages | 2872100 | 2872100 | 0 | 0.0% |  |
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
| single-day-application-log-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-standard | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-standard | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-standard | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/parse/read_files | 3.7 s | 3.3 s | -481 ms | -12.8% | IMPROVE |
| single-day-application-log-top25 | TIMING/finalize/calculate_statistics | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| single-day-application-log-top25 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.8 s | 3.3 s | -471 ms | -12.6% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 37.3 MB | 36.1 MB | -1.2 MB | -3.1% | IMPROVE |
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
| single-day-application-log-top25 | MEMORY/log_messages | 2.7 MB | 2.7 MB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/message_key_order | 6.4 KB | 6.4 KB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/unattributed | 34.5 MB | 32.6 MB | -1.9 MB | -5.5% | IMPROVE |
| single-day-application-log-top25 | MEMORY_FINAL/log_messages | 2872100 | 2872100 | 0 | 0.0% |  |
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
| single-day-application-log-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-top25 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-top25 | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-top25 | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/parse/read_files | 6.4 s | 6.0 s | -383 ms | -6.0% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/finalize/group_similar | 254 ms | 282 ms | +28 ms | 11.0% | REGRESS |
| single-day-application-log-top25-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 6.6 s | 6.3 s | -348 ms | -5.3% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 125.6 MB | 123.3 MB | -2.3 MB | -1.9% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_clusters | 437.5 KB | 437.3 KB | -256 B | -0.1% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_message | 2.6 MB | 2.6 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_trigrams | 29.3 MB | 29.3 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 16.4 MB | 16.4 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_ngram_index | 29.7 MB | 29.7 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_patterns | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_posting_size | 860.9 KB | 860.9 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_unmatched | 1.5 MB | 1.5 MB | 0 B | 0.0% |  |
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
| single-day-application-log-top25-consolidate | MEMORY/log_messages | 2.3 MB | 2.3 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_occurrences | 21.8 KB | 21.5 KB | -256 B | -1.1% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/message_key_order | 12.6 KB | 12.6 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/unattributed | 42.5 MB | 39.4 MB | -3.1 MB | -7.3% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/log_messages | 137524 | 137524 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 448005 | 447749 | -256 | -0.1% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 55464 | 55464 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 32824 | 32824 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 32824 | 32824 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | COUNTS/log_messages_entries | 136 | 136 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/parse/read_files | 3.7 s | 3.2 s | -422 ms | -11.5% | IMPROVE |
| single-day-application-log-heatmap | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.7 s | 3.3 s | -413 ms | -11.2% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/rss_peak | 37.3 MB | 35.8 MB | -1.5 MB | -4.0% | IMPROVE |
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
| single-day-application-log-heatmap | MEMORY/log_messages | 2.7 MB | 2.7 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/unattributed | 34.5 MB | 32.3 MB | -2.2 MB | -6.4% | IMPROVE |
| single-day-application-log-heatmap | MEMORY_FINAL/log_messages | 2872100 | 2872100 | 0 | 0.0% |  |
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
| single-day-application-log-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-heatmap | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | TIMING/parse/read_files | 3.8 s | 3.3 s | -468 ms | -12.5% | IMPROVE |
| single-day-application-log-histogram | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.8 s | 3.3 s | -460 ms | -12.2% | IMPROVE |
| single-day-application-log-histogram | MEMORY/rss_peak | 37.3 MB | 35.8 MB | -1.5 MB | -4.1% | IMPROVE |
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
| single-day-application-log-histogram | MEMORY/log_messages | 2.7 MB | 2.7 MB | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/unattributed | 34.6 MB | 32.3 MB | -2.3 MB | -6.6% | IMPROVE |
| single-day-application-log-histogram | MEMORY_FINAL/log_messages | 2872100 | 2872100 | 0 | 0.0% |  |
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
| single-day-application-log-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/parse/read_files | 3.7 s | 3.3 s | -480 ms | -12.8% | IMPROVE |
| single-day-application-log-heatmap-histogram | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.7 s | 3.3 s | -471 ms | -12.6% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 37.3 MB | 35.9 MB | -1.4 MB | -3.8% | IMPROVE |
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
| single-day-application-log-heatmap-histogram | MEMORY/log_messages | 2.7 MB | 2.7 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_occurrences | 21.8 KB | 21.5 KB | -256 B | -1.1% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/unattributed | 34.6 MB | 32.4 MB | -2.2 MB | -6.3% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/log_messages | 2872100 | 2872100 | 0 | 0.0% |  |
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
| single-day-application-log-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/parse/read_files | 6.3 s | 6 s | -318 ms | -5.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 264 ms | 288 ms | +24 ms | 9.1% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 6.6 s | 6.3 s | -285 ms | -4.3% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 126.4 MB | 123.1 MB | -3.2 MB | -2.6% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 437.5 KB | 437.5 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.6 MB | 2.6 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 29.3 MB | 29.3 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 16.4 MB | 16.4 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 29.7 MB | 29.7 MB | +1.8 KB | 0.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 860.9 KB | 860.9 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.5 MB | 1.5 MB | 0 B | 0.0% |  |
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
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_messages | 2.3 MB | 2.3 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 21.5 KB | 21.8 KB | +256 B | 1.2% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/message_key_order | 2.6 KB | 2.6 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/unattributed | 43.3 MB | 39.2 MB | -4 MB | -9.3% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 137524 | 137524 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 448005 | 448005 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 55464 | 55464 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 32824 | 32824 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 32824 | 32824 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 136 | 136 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/parse/read_files | 3.8 s | 3.3 s | -469 ms | -12.5% | IMPROVE |
| single-day-application-log-sort-p99 | TIMING/finalize/calculate_statistics | 7 ms | 8 ms | +1 ms | 14.3% | REGRESS |
| single-day-application-log-sort-p99 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/total | 3.8 s | 3.3 s | -461 ms | -12.2% | IMPROVE |
| single-day-application-log-sort-p99 | MEMORY/rss_peak | 37.0 MB | 36.0 MB | -1 MB | -2.7% | IMPROVE |
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
| single-day-application-log-sort-p99 | MEMORY/log_messages | 2.7 MB | 2.7 MB | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/unattributed | 34.2 MB | 32.5 MB | -1.7 MB | -5.1% | IMPROVE |
| single-day-application-log-sort-p99 | MEMORY_FINAL/log_messages | 2872100 | 2872100 | 0 | 0.0% |  |
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
| single-day-application-log-sort-p99 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/parse/read_files | 3.7 s | 3.3 s | -479 ms | -12.8% | IMPROVE |
| single-day-application-log-sort-skewness | TIMING/finalize/calculate_statistics | 7 ms | 8 ms | +1 ms | 14.3% | REGRESS |
| single-day-application-log-sort-skewness | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/total | 3.8 s | 3.3 s | -471 ms | -12.5% | IMPROVE |
| single-day-application-log-sort-skewness | MEMORY/rss_peak | 37.4 MB | 36.2 MB | -1.2 MB | -3.2% | IMPROVE |
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
| single-day-application-log-sort-skewness | MEMORY/log_messages | 2.7 MB | 2.7 MB | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/unattributed | 34.6 MB | 32.7 MB | -1.9 MB | -5.6% | IMPROVE |
| single-day-application-log-sort-skewness | MEMORY_FINAL/log_messages | 2872100 | 2872100 | 0 | 0.0% |  |
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
| single-day-application-log-sort-skewness | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/parse/read_files | 7.9 s | 7.0 s | -919 ms | -11.6% | IMPROVE |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics | 164 ms | 195 ms | +31 ms | 18.9% | REGRESS |
| multi-day-application-logs-standard | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 8.1 s | 7.2 s | -880 ms | -10.9% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/rss_peak | 114.8 MB | 94.5 MB | -20.4 MB | -17.7% | IMPROVE |
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
| multi-day-application-logs-standard | MEMORY/log_messages | 45.8 MB | 45.8 MB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/unattributed | 69.0 MB | 47.9 MB | -21.1 MB | -30.6% | IMPROVE |
| multi-day-application-logs-standard | MEMORY_FINAL/log_messages | 48030790 | 48030790 | 0 | 0.0% |  |
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
| multi-day-application-logs-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-standard | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-standard | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-standard | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/parse/read_files | 8.0 s | 6.9 s | -1 s | -13.1% | IMPROVE |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics | 165 ms | 205 ms | +40 ms | 24.2% | REGRESS |
| multi-day-application-logs-top25 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 8.2 s | 7.2 s | -999 ms | -12.3% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 115.1 MB | 95.1 MB | -19.9 MB | -17.3% | IMPROVE |
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
| multi-day-application-logs-top25 | MEMORY/log_messages | 45.8 MB | 45.8 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/message_key_order | 6.5 KB | 6.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/unattributed | 69.2 MB | 48.6 MB | -20.6 MB | -29.8% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY_FINAL/log_messages | 48030790 | 48030790 | 0 | 0.0% |  |
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
| multi-day-application-logs-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/parse/read_files | 36.5 s | 38.3 s | +1.8 s | 4.8% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/group_similar | 4.3 s | 4.7 s | +433 ms | 10.2% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/render/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/total | 40.8 s | 43.0 s | +2.2 s | 5.4% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 226.1 MB | 212.6 MB | -13.5 MB | -6.0% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_clusters | 3.6 MB | 3.6 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_message | 3.5 MB | 3.5 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 62.2 MB | 62.2 MB | +1 KB | 0.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 10.4 MB | 10.4 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 60.8 MB | 60.8 MB | -27.9 KB | -0.0% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_patterns | 485.7 KB | 485.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_posting_size | 1.6 MB | 1.6 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_unmatched | 2.1 MB | 2.1 MB | 0 B | 0.0% |  |
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
| multi-day-application-logs-top25-consolidate | MEMORY/log_messages | 3.2 MB | 3.2 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/message_key_order | 5.7 KB | 5.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/unattributed | 78.1 MB | 63.8 MB | -14.3 MB | -18.3% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_messages | 726422 | 726422 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 3738228 | 3738228 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 497330 | 497330 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 8248 | 8248 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_messages_entries | 1304 | 1304 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/parse/read_files | 7.9 s | 6.9 s | -1 s | -13.1% | IMPROVE |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics | 167 ms | 191 ms | +24 ms | 14.4% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 8.1 s | 7.1 s | -1 s | -12.4% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 115.1 MB | 94.5 MB | -20.6 MB | -17.9% | IMPROVE |
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
| multi-day-application-logs-heatmap | MEMORY/log_messages | 45.8 MB | 45.8 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/unattributed | 69.3 MB | 47.9 MB | -21.4 MB | -30.8% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY_FINAL/log_messages | 48030790 | 48030790 | 0 | 0.0% |  |
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
| multi-day-application-logs-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/parse/read_files | 7.9 s | 7.1 s | -776 ms | -9.8% | IMPROVE |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics | 163 ms | 209 ms | +46 ms | 28.2% | REGRESS |
| multi-day-application-logs-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 8.1 s | 7.4 s | -723 ms | -8.9% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 114.9 MB | 95.5 MB | -19.4 MB | -16.9% | IMPROVE |
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
| multi-day-application-logs-histogram | MEMORY/log_messages | 45.8 MB | 45.8 MB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/unattributed | 69 MB | 48.9 MB | -20.1 MB | -29.2% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY_FINAL/log_messages | 48030790 | 48030790 | 0 | 0.0% |  |
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
| multi-day-application-logs-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/parse/read_files | 7.9 s | 7 s | -904 ms | -11.4% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 166 ms | 210 ms | +44 ms | 26.5% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 8.1 s | 7.3 s | -853 ms | -10.5% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 115.1 MB | 95.1 MB | -20.0 MB | -17.4% | IMPROVE |
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
| multi-day-application-logs-heatmap-histogram | MEMORY/log_messages | 45.8 MB | 45.8 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_occurrences | 56.7 KB | 56.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/unattributed | 69.2 MB | 48.5 MB | -20.7 MB | -29.9% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 48030790 | 48030790 | 0 | 0.0% |  |
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
| multi-day-application-logs-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 36.7 s | 38.0 s | +1.3 s | 3.5% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 4.3 s | 4.7 s | +361 ms | 8.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 41.0 s | 42.6 s | +1.7 s | 4.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 224.4 MB | 215.4 MB | -9 MB | -4.0% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 3.6 MB | 3.6 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 3.5 MB | 3.5 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 62.2 MB | 62.2 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 10.4 MB | 10.4 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 60.8 MB | 60.8 MB | +22.2 KB | 0.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 485.7 KB | 485.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 1.6 MB | 1.6 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 2.1 MB | 2.1 MB | 0 B | 0.0% |  |
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
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 3.2 MB | 3.2 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 3 KB | 3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/unattributed | 76.4 MB | 66.7 MB | -9.7 MB | -12.7% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 726422 | 726422 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 3738228 | 3738228 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 497330 | 497330 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 8248 | 8248 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 1304 | 1304 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/parse/read_files | 7.8 s | 6.9 s | -900 ms | -11.5% | IMPROVE |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics | 219 ms | 259 ms | +40 ms | 18.3% | REGRESS |
| multi-day-application-logs-sort-p99 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/total | 8.1 s | 7.2 s | -852 ms | -10.6% | IMPROVE |
| multi-day-application-logs-sort-p99 | MEMORY/rss_peak | 114.4 MB | 95.5 MB | -18.9 MB | -16.5% | IMPROVE |
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
| multi-day-application-logs-sort-p99 | MEMORY/log_messages | 45.8 MB | 45.8 MB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/unattributed | 68.6 MB | 48.9 MB | -19.6 MB | -28.6% | IMPROVE |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/log_messages | 48030790 | 48030790 | 0 | 0.0% |  |
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
| multi-day-application-logs-sort-p99 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/parse/read_files | 7.9 s | 7.0 s | -864 ms | -11.0% | IMPROVE |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics | 215 ms | 262 ms | +47 ms | 21.9% | REGRESS |
| multi-day-application-logs-sort-skewness | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/total | 8.1 s | 7.3 s | -809 ms | -10.0% | IMPROVE |
| multi-day-application-logs-sort-skewness | MEMORY/rss_peak | 114.3 MB | 95.5 MB | -18.9 MB | -16.5% | IMPROVE |
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
| multi-day-application-logs-sort-skewness | MEMORY/log_messages | 45.8 MB | 45.8 MB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_occurrences | 56.7 KB | 56.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/unattributed | 68.5 MB | 48.9 MB | -19.6 MB | -28.6% | IMPROVE |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/log_messages | 48030790 | 48030790 | 0 | 0.0% |  |
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
| multi-day-application-logs-sort-skewness | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/parse/read_files | 16.2 s | 15.7 s | -497 ms | -3.1% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics | 351 ms | 418 ms | +67 ms | 19.1% | REGRESS |
| multi-day-custom-logs-standard | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 16.5 s | 16.1 s | -421 ms | -2.5% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 192.9 MB | 194.4 MB | +1.5 MB | 0.8% | REGRESS |
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
| multi-day-custom-logs-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_analysis | 28.4 MB | 28.4 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_messages | 102.5 MB | 103.0 MB | +483.8 KB | 0.5% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_stats | 39.8 KB | 39.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/unattributed | 61.9 MB | 62.2 MB | +284.2 KB | 0.4% | REGRESS |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_messages | 107470660 | 107966084 | 495424 | 0.5% | REGRESS |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_analysis | 20342 | 20342 | 0 | 0.0% |  |
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
| multi-day-custom-logs-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/parse/read_files | 16 s | 15.7 s | -351 ms | -2.2% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics | 355 ms | 433 ms | +78 ms | 22.0% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 16.4 s | 16.1 s | -266 ms | -1.6% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 192.8 MB | 195 MB | +2.2 MB | 1.1% | REGRESS |
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
| multi-day-custom-logs-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_analysis | 28.4 MB | 28.4 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_messages | 102.5 MB | 103.0 MB | +481.9 KB | 0.5% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_stats | 39.8 KB | 39.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/unattributed | 61.8 MB | 62.8 MB | +1 MB | 1.6% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_messages | 107482300 | 107975804 | 493504 | 0.5% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_analysis | 20342 | 20342 | 0 | 0.0% |  |
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
| multi-day-custom-logs-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/parse/read_files | 47.7 s | 49.8 s | +2 s | 4.3% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/group_similar | 4.6 s | 5.1 s | +421 ms | 9.1% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 260 ms | 293 ms | +33 ms | 12.7% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 52.6 s | 55.1 s | +2.5 s | 4.8% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 247.3 MB | 244.5 MB | -2.9 MB | -1.2% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_clusters | 29.5 MB | 29.5 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_message | 5.8 MB | 5.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 62.6 MB | 62.6 MB | -40 KB | -0.1% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 4.5 MB | 4.5 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 61.3 MB | 61.3 MB | -11.7 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_patterns | 202.1 KB | 202.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_posting_size | 478.1 KB | 478.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_unmatched | 3.3 MB | 3.3 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_analysis | 28.4 MB | 28.4 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages | 28.6 MB | 28.6 MB | -1.6 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_stats | 39.8 KB | 39.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/message_key_order | 6.1 KB | 6.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/unattributed | 22.5 MB | 18.9 MB | -3.6 MB | -16.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_messages | 30007466 | 30005802 | -1664 | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 20342 | 20342 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 30969940 | 30969940 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 206903 | 206903 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 232 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 4152 | 4152 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_messages_entries | 606 | 606 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/parse/read_files | 16.7 s | 16 s | -706 ms | -4.2% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics | 291 ms | 362 ms | +71 ms | 24.4% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/finalize/heatmap_statistics | 15 ms | 16 ms | +1 ms | 6.7% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 17 s | 16.4 s | -626 ms | -3.7% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 177.8 MB | 178.8 MB | +1 MB | 0.6% | REGRESS |
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
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters | 981.9 KB | 983.4 KB | +1.5 KB | 0.2% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data | 43.8 KB | 43.6 KB | -128 B | -0.3% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_analysis | 20.9 KB | 20.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_messages | 102.5 MB | 102.5 MB | +192 B | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_stats | 28.2 KB | 28.2 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/unattributed | 74.2 MB | 74.6 MB | +334.4 KB | 0.4% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_messages | 107470660 | 107470852 | 192 | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_analysis | 20342 | 20342 | 0 | 0.0% |  |
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
| multi-day-custom-logs-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/parse/read_files | 16.9 s | 16.3 s | -571 ms | -3.4% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics | 352 ms | 429 ms | +77 ms | 21.9% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/finalize/histogram_statistics | 3 ms | 4 ms | +1 ms | 33.3% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 17.3 s | 16.8 s | -486 ms | -2.8% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 192.6 MB | 194.4 MB | +1.8 MB | 1.0% | REGRESS |
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
| multi-day-custom-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/histogram_counters | 122.1 KB | 122.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_analysis | 28.4 MB | 28.4 MB | -256 B | -0.0% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/log_messages | 102.5 MB | 102.5 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_stats | 39.8 KB | 39.6 KB | -256 B | -0.6% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/unattributed | 61.4 MB | 62.5 MB | +1.1 MB | 1.7% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY_FINAL/log_messages | 107470852 | 107470852 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY_FINAL/log_analysis | 20342 | 20086 | -256 | -1.3% | IMPROVE |
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
| multi-day-custom-logs-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/parse/read_files | 17.3 s | 16.7 s | -570 ms | -3.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 287 ms | 345 ms | +58 ms | 20.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/heatmap_statistics | 15 ms | 15 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/histogram_statistics | 3 ms | 4 ms | +1 ms | 33.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 17.6 s | 17.1 s | -503 ms | -2.9% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 180.4 MB | 179.5 MB | -976 KB | -0.5% | IMPROVE |
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
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_counters | 983.4 KB | 981.9 KB | -1.5 KB | -0.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data | 42.6 KB | 40 KB | -2.6 KB | -6.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters | 122.1 KB | 121.9 KB | -192 B | -0.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_analysis | 20.9 KB | 20.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages | 102.5 MB | 102.5 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_stats | 28.2 KB | 28.2 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/unattributed | 76.7 MB | 75 MB | -1.7 MB | -2.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 107470852 | 107470852 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 20342 | 20342 | 0 | 0.0% |  |
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
| multi-day-custom-logs-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 48.5 s | 50.7 s | +2.2 s | 4.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 4.2 s | 4.8 s | +555 ms | 13.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 127 ms | 142 ms | +15 ms | 11.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 19 ms | 20 ms | +1 ms | 5.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 52.9 s | 55.7 s | +2.8 s | 5.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 231.5 MB | 233.8 MB | +2.3 MB | 1.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 29.5 MB | 29.5 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 5.8 MB | 5.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 62.6 MB | 62.6 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 4.5 MB | 4.5 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 61.3 MB | 61.3 MB | -9.8 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 202.1 KB | 202.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 478.1 KB | 478.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 3.3 MB | 3.3 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 983.4 KB | 981.9 KB | -1.5 KB | -0.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 40.5 KB | 43.3 KB | +2.8 KB | 6.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 122.1 KB | 121.9 KB | -192 B | -0.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 20.9 KB | 20.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 28.6 MB | 28.6 MB | -64 B | -0.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 28.2 KB | 28.2 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 2.7 KB | 2.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/unattributed | 34.1 MB | 35.6 MB | +1.6 MB | 4.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 29998970 | 29998906 | -64 | -0.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 20342 | 20342 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 30969940 | 30969940 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 206903 | 206903 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 232 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 4152 | 4152 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 606 | 606 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/parse/read_files | 16.1 s | 15.6 s | -463 ms | -2.9% | IMPROVE |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics | 274 ms | 313 ms | +39 ms | 14.2% | REGRESS |
| multi-day-custom-logs-sort-p99 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/total | 16.4 s | 16.0 s | -416 ms | -2.5% | IMPROVE |
| multi-day-custom-logs-sort-p99 | MEMORY/rss_peak | 190.2 MB | 191.9 MB | +1.6 MB | 0.9% | REGRESS |
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
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_analysis | 28.4 MB | 28.4 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_messages | 102.5 MB | 102.5 MB | +192 B | 0.0% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_stats | 39.8 KB | 39.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/message_key_order | 2.7 KB | 2.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/unattributed | 59.2 MB | 60.1 MB | +895.8 KB | 1.5% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/log_messages | 107471436 | 107471628 | 192 | 0.0% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/log_analysis | 20342 | 20342 | 0 | 0.0% |  |
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
| multi-day-custom-logs-sort-p99 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/parse/read_files | 16.1 s | 15.6 s | -501 ms | -3.1% | IMPROVE |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics | 345 ms | 388 ms | +43 ms | 12.5% | REGRESS |
| multi-day-custom-logs-sort-skewness | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/total | 16.5 s | 16 s | -450 ms | -2.7% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY/rss_peak | 192 MB | 192.2 MB | +176 KB | 0.1% | REGRESS |
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
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_analysis | 28.4 MB | 28.4 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_messages | 102.5 MB | 103.0 MB | +483.5 KB | 0.5% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_stats | 39.8 KB | 39.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/message_key_order | 2.5 KB | 2.5 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/unattributed | 61 MB | 60.0 MB | -1.1 MB | -1.7% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/log_messages | 107473201 | 107968305 | 495104 | 0.5% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/log_analysis | 20342 | 20342 | 0 | 0.0% |  |
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
| multi-day-custom-logs-sort-skewness | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/parse/read_files | 11.1 s | 8.8 s | -2.3 s | -20.7% | IMPROVE |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics | 151 ms | 155 ms | +4 ms | 2.6% | REGRESS |
| single-day-access-log-standard | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 11.3 s | 9 s | -2.3 s | -20.3% | IMPROVE |
| single-day-access-log-standard | MEMORY/rss_peak | 143.5 MB | 142.8 MB | -704 KB | -0.5% | IMPROVE |
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
| single-day-access-log-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_analysis | 52.7 MB | 52.7 MB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_messages | 55.2 MB | 55.4 MB | +197.9 KB | 0.3% | REGRESS |
| single-day-access-log-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_stats | 22.5 KB | 22.5 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/message_key_order | 1.8 KB | 1.8 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/unattributed | 35.6 MB | 34 MB | -1.5 MB | -4.3% | IMPROVE |
| single-day-access-log-standard | MEMORY_FINAL/log_messages | 57911448 | 58114072 | 202624 | 0.3% | REGRESS |
| single-day-access-log-standard | MEMORY_FINAL/log_analysis | 6670 | 6670 | 0 | 0.0% |  |
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
| single-day-access-log-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-standard | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-standard | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-standard | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/parse/read_files | 11.1 s | 9.0 s | -2.1 s | -18.9% | IMPROVE |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics | 169 ms | 180 ms | +11 ms | 6.5% | REGRESS |
| single-day-access-log-top25 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 11.2 s | 9.2 s | -2.1 s | -18.4% | IMPROVE |
| single-day-access-log-top25 | MEMORY/rss_peak | 144.3 MB | 146.0 MB | +1.7 MB | 1.2% | REGRESS |
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
| single-day-access-log-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_analysis | 52.7 MB | 52.7 MB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_messages | 55.4 MB | 55.2 MB | -190.6 KB | -0.3% | IMPROVE |
| single-day-access-log-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_stats | 22.5 KB | 22.5 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/message_key_order | 3.9 KB | 3.9 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/unattributed | 36.1 MB | 37.3 MB | +1.1 MB | 3.1% | REGRESS |
| single-day-access-log-top25 | MEMORY_FINAL/log_messages | 58117504 | 57922368 | -195136 | -0.3% | IMPROVE |
| single-day-access-log-top25 | MEMORY_FINAL/log_analysis | 6670 | 6670 | 0 | 0.0% |  |
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
| single-day-access-log-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-top25 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-top25 | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-top25 | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/parse/read_files | 12.6 s | 10.7 s | -1.9 s | -15.0% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/finalize/group_similar | 3.8 s | 4.1 s | +300 ms | 7.8% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics | 279 ms | 334 ms | +55 ms | 19.7% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 16.7 s | 15.2 s | -1.5 s | -9.1% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 180.4 MB | 181.2 MB | +880 KB | 0.5% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_clusters | 48.4 MB | 48.4 MB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_message | 883 KB | 883 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_trigrams | 4.1 MB | 4.1 MB | +5.5 KB | 0.1% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_ngram_index | 4.8 MB | 4.8 MB | +1.4 KB | 0.0% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_patterns | 118.1 KB | 118.1 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_posting_size | 352.5 KB | 352.5 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_unmatched | 565.1 KB | 565.1 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_analysis | 52.7 MB | 52.7 MB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_messages | 55.4 MB | 55.4 MB | +6.9 KB | 0.0% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_stats | 22.5 KB | 22.5 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/message_key_order | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/unattributed | 13.0 MB | 13.1 MB | +114.2 KB | 0.9% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_messages | 56078049 | 56080289 | 2240 | 0.0% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_analysis | 6670 | 6670 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 50771065 | 50771065 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 119797 | 119797 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 296 | 296 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 16440 | 16440 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_messages_entries | 615 | 615 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/parse/read_files | 11.8 s | 9.6 s | -2.3 s | -19.0% | IMPROVE |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics | 49 ms | 49 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/finalize/heatmap_statistics | 8 ms | 8 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 11.9 s | 9.6 s | -2.2 s | -18.9% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/rss_peak | 116.5 MB | 116.4 MB | -176 KB | -0.1% | IMPROVE |
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
| single-day-access-log-heatmap | MEMORY/heatmap_counters | 569.7 KB | 569.7 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_analysis | 8.1 KB | 8.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_messages | 55.4 MB | 55.4 MB | +128 B | 0.0% | REGRESS |
| single-day-access-log-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_stats | 15.2 KB | 15.2 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/message_key_order | 1.8 KB | 1.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/unattributed | 60.5 MB | 59.6 MB | -912.1 KB | -1.5% | IMPROVE |
| single-day-access-log-heatmap | MEMORY_FINAL/log_messages | 58114456 | 58114584 | 128 | 0.0% | REGRESS |
| single-day-access-log-heatmap | MEMORY_FINAL/log_analysis | 6670 | 6670 | 0 | 0.0% |  |
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
| single-day-access-log-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-heatmap | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | TIMING/parse/read_files | 13.1 s | 10.7 s | -2.5 s | -18.9% | IMPROVE |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics | 152 ms | 150 ms | -2 ms | -1.3% | IMPROVE |
| single-day-access-log-histogram | TIMING/finalize/histogram_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 13.3 s | 10.8 s | -2.5 s | -18.6% | IMPROVE |
| single-day-access-log-histogram | MEMORY/rss_peak | 146.2 MB | 144.2 MB | -2.1 MB | -1.4% | IMPROVE |
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
| single-day-access-log-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/histogram_counters | 105.6 KB | 105.5 KB | -128 B | -0.1% | IMPROVE |
| single-day-access-log-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_analysis | 52.7 MB | 52.7 MB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_messages | 55.4 MB | 55.4 MB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_stats | 22.5 KB | 22.5 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/message_key_order | 1.8 KB | 1.8 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/unattributed | 38.0 MB | 35.3 MB | -2.7 MB | -7.2% | IMPROVE |
| single-day-access-log-histogram | MEMORY_FINAL/log_messages | 58114584 | 58114584 | 0 | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/log_analysis | 6670 | 6670 | 0 | 0.0% |  |
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
| single-day-access-log-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/parse/read_files | 13.6 s | 11.2 s | -2.4 s | -17.5% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics | 50 ms | 49 ms | -1 ms | -2.0% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/finalize/heatmap_statistics | 8 ms | 8 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/finalize/histogram_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 13.6 s | 11.3 s | -2.4 s | -17.4% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 117.5 MB | 116.5 MB | -1 MB | -0.9% | IMPROVE |
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
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_counters | 569.7 KB | 569.7 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_counters | 105.6 KB | 105.6 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_analysis | 8.1 KB | 8.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_messages | 55.2 MB | 55.4 MB | +191.5 KB | 0.3% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_stats | 15.2 KB | 15.2 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/message_key_order | 1.8 KB | 1.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/unattributed | 61.5 MB | 59.6 MB | -2.0 MB | -3.2% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_messages | 57911448 | 58107544 | 196096 | 0.3% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_analysis | 6670 | 6670 | 0 | 0.0% |  |
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
| single-day-access-log-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/parse/read_files | 15.0 s | 12.6 s | -2.4 s | -15.9% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 2.8 s | 2.8 s | +63 ms | 2.3% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 175 ms | 169 ms | -6 ms | -3.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 9 ms | 8 ms | -1000 us | -11.1% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 17.9 s | 15.6 s | -2.3 s | -12.9% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 158.4 MB | 154.9 MB | -3.4 MB | -2.2% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 48.4 MB | 48.4 MB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 883 KB | 883 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 4.1 MB | 4.1 MB | -512 B | -0.0% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 4.8 MB | 4.8 MB | +1.5 KB | 0.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 118.1 KB | 118.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 352.5 KB | 352.5 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 565.1 KB | 565.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 568.8 KB | 569.7 KB | +960 B | 0.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_counters | 105.5 KB | 105.6 KB | +128 B | 0.1% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 8.1 KB | 8.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_messages | 55.4 MB | 55.4 MB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_stats | 15.2 KB | 15.2 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/message_key_order | 1.9 KB | 1.9 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/unattributed | 43.0 MB | 38.9 MB | -4.1 MB | -9.6% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 56068601 | 56068217 | -384 | -0.0% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 6670 | 6670 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 50771065 | 50771065 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 119797 | 119797 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 296 | 296 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 16440 | 16440 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 615 | 615 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/parse/read_files | 11.1 s | 8.6 s | -2.5 s | -22.6% | IMPROVE |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics | 208 ms | 212 ms | +4 ms | 1.9% | REGRESS |
| single-day-access-log-sort-p99 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/total | 11.3 s | 8.8 s | -2.5 s | -22.1% | IMPROVE |
| single-day-access-log-sort-p99 | MEMORY/rss_peak | 143.3 MB | 144.6 MB | +1.3 MB | 0.9% | REGRESS |
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
| single-day-access-log-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_analysis | 52.7 MB | 52.7 MB | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_messages | 55.4 MB | 55.4 MB | -6.4 KB | -0.0% | IMPROVE |
| single-day-access-log-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_stats | 22.5 KB | 22.5 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/message_key_order | 2.0 KB | 2.0 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/unattributed | 35.2 MB | 35.7 MB | +582.4 KB | 1.6% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY_FINAL/log_messages | 58114072 | 58107544 | -6528 | -0.0% | IMPROVE |
| single-day-access-log-sort-p99 | MEMORY_FINAL/log_analysis | 6670 | 6670 | 0 | 0.0% |  |
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
| single-day-access-log-sort-p99 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/parse/read_files | 11.2 s | 8.6 s | -2.6 s | -23.0% | IMPROVE |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics | 333 ms | 334 ms | +1 ms | 0.3% | REGRESS |
| single-day-access-log-sort-skewness | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/total | 11.5 s | 9.0 s | -2.6 s | -22.3% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY/rss_peak | 149.2 MB | 150.4 MB | +1.2 MB | 0.8% | REGRESS |
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
| single-day-access-log-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_analysis | 52.7 MB | 52.7 MB | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_messages | 55.4 MB | 55.2 MB | -198.4 KB | -0.3% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_stats | 22.5 KB | 22.5 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/message_key_order | 1.9 KB | 1.9 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/unattributed | 41.1 MB | 41.8 MB | +774.4 KB | 1.8% | REGRESS |
| single-day-access-log-sort-skewness | MEMORY_FINAL/log_messages | 58116157 | 57913021 | -203136 | -0.3% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY_FINAL/log_analysis | 6670 | 6670 | 0 | 0.0% |  |
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
| single-day-access-log-sort-skewness | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/parse/read_files | 2 min | 1.6 min | -26.2 s | -21.4% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics | 4.9 s | 5.1 s | +186 ms | 3.8% | REGRESS |
| month-single-server-access-logs-standard | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/total | 2.1 min | 1.7 min | -26 s | -20.5% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2.5 GB | 2.4 GB | -169.3 MB | -6.5% | IMPROVE |
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
| month-single-server-access-logs-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_analysis | 567.3 MB | 568.5 MB | +1.2 MB | 0.2% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/log_messages | 1.6 GB | 1.6 GB | -512 B | -0.0% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_stats | 43.6 KB | 43.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/unattributed | 403.8 MB | 232.5 MB | -171.2 MB | -42.4% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_messages | 1704450665 | 1704450153 | -512 | -0.0% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
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
| month-single-server-access-logs-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/parse/read_files | 2.1 min | 1.6 min | -28.7 s | -23.2% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics | 5.1 s | 5.6 s | +539 ms | 10.6% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 2.1 min | 1.7 min | -28.1 s | -21.9% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2.5 GB | 2.4 GB | -155.8 MB | -6.0% | IMPROVE |
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
| month-single-server-access-logs-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_analysis | 567.3 MB | 568.5 MB | +1.2 MB | 0.2% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/log_messages | 1.6 GB | 1.6 GB | +1.8 MB | 0.1% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/log_sessions | 2.2 MB | 2.2 MB | +128 B | 0.0% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/log_stats | 43.6 KB | 43.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/message_key_order | 4.7 KB | 4.7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/unattributed | 393.9 MB | 234.3 MB | -159.6 MB | -40.5% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_messages | 1702548425 | 1704461193 | 1912768 | 0.1% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
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
| month-single-server-access-logs-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/parse/read_files | 2.6 min | 2.3 min | -23.1 s | -14.6% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/group_similar | 1.7 min | 1.7 min | +4.9 s | 4.9% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 7.1 s | 7.4 s | +305 ms | 4.3% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 4.4 min | 4.1 min | -17.9 s | -6.8% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 1.6 GB | 1.4 GB | -181.5 MB | -11.4% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 507.2 MB | 505.6 MB | -1.6 MB | -0.3% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 2.5 MB | 2.5 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 36.7 MB | 36.7 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 29.4 MB | 29.4 MB | -67 KB | -0.2% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 36.0 MB | 36.0 MB | +5.4 KB | 0.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 283.0 KB | 283.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_posting_size | 973.6 KB | 973.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 1.6 MB | 1.6 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_analysis | 567.4 MB | 567.4 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages | 567.0 MB | 565.4 MB | -1.5 MB | -0.3% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_stats | 43.6 KB | 43.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/message_key_order | 4.2 KB | 4.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | 594530097 | 592910041 | -1620056 | -0.3% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 531862951 | 530185487 | -1677464 | -0.3% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 248469 | 248469 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | 424 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | 65592 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_messages_entries | 1317 | 1317 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/parse/read_files | 2.2 min | 1.8 min | -25.6 s | -19.3% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics | 2.1 s | 2.3 s | +200 ms | 9.3% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/finalize/heatmap_statistics | 60 ms | 66 ms | +6 ms | 10.0% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/total | 2.3 min | 1.8 min | -25.4 s | -18.8% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 2.1 GB | 1.9 GB | -170.6 MB | -7.9% | IMPROVE |
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
| month-single-server-access-logs-heatmap | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data | 83.6 KB | 79.1 KB | -4.5 KB | -5.4% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_analysis | 15.3 KB | 15.3 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_messages | 1.6 GB | 1.6 GB | -512 B | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_stats | 29.6 KB | 29.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/unattributed | 528.2 MB | 356.8 MB | -171.3 MB | -32.4% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_messages | 1704450545 | 1704450033 | -512 | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_analysis | 12594 | 12594 | 0 | 0.0% |  |
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
| month-single-server-access-logs-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/parse/read_files | 2.4 min | 2 min | -24.3 s | -16.7% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics | 4.9 s | 5.4 s | +431 ms | 8.7% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/finalize/histogram_statistics | 7 ms | 7 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/total | 2.5 min | 2.1 min | -23.9 s | -15.9% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 2.5 GB | 2.4 GB | -179.4 MB | -6.9% | IMPROVE |
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
| month-single-server-access-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/histogram_counters | 295.6 KB | 295.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_analysis | 567.3 MB | 568.5 MB | +1.2 MB | 0.2% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/log_messages | 1.6 GB | 1.6 GB | -128 B | -0.0% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_occurrences | 36.8 KB | 36.8 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_stats | 43.6 KB | 43.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/unattributed | 415.4 MB | 234.0 MB | -181.4 MB | -43.7% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_messages | 1704450409 | 1704450281 | -128 | -0.0% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
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
| month-single-server-access-logs-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/parse/read_files | 2.5 min | 2.2 min | -21.9 s | -14.4% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 2 s | 2.4 s | +375 ms | 18.7% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/heatmap_statistics | 60 ms | 65 ms | +5 ms | 8.3% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/histogram_statistics | 7 ms | 7 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.6 min | 2.2 min | -21.5 s | -14.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 2 GB | 1.9 GB | -178.6 MB | -8.5% | IMPROVE |
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
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | +1.8 KB | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data | 80.1 KB | 83.1 KB | +3 KB | 3.7% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_counters | 295.5 KB | 295.6 KB | +128 B | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.3 KB | 15.3 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_messages | 1.5 GB | 1.5 GB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_stats | 29.6 KB | 29.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/unattributed | 532.6 MB | 353.3 MB | -179.3 MB | -33.7% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 1626865585 | 1626865585 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 12594 | 12594 | 0 | 0.0% |  |
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
| month-single-server-access-logs-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 3.1 min | 2.8 min | -17.5 s | -9.4% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 1.2 min | 1.3 min | +1.7 s | 2.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 2.8 s | 3.1 s | +237 ms | 8.4% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 58 ms | 60 ms | +2 ms | 3.4% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 10 ms | 11 ms | +1000 us | 10.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 4.4 min | 4.1 min | -15.6 s | -5.9% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 1.3 GB | 1.1 GB | -168.9 MB | -13.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 507.2 MB | 505.6 MB | -1.6 MB | -0.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.5 MB | 2.5 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 36.7 MB | 36.7 MB | +1.5 KB | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 25.6 MB | 29.4 MB | +3.8 MB | 15.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 36.0 MB | 36.0 MB | +1.4 KB | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 283.0 KB | 283.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 973.6 KB | 973.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.6 MB | 1.6 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | -1.8 KB | -0.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 80.1 KB | 79.6 KB | -512 B | -0.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 295.6 KB | 295.5 KB | -128 B | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 15.3 KB | 15.3 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 567 MB | 565.4 MB | -1.6 MB | -0.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 29.6 KB | 29.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 1.9 KB | 1.9 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/unattributed | 107.1 MB | 0 B | -107.1 MB | -100.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 594583729 | 592899225 | -1684504 | -0.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 12594 | 12594 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 531863079 | 530185103 | -1677976 | -0.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 248469 | 248469 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | 424 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | 65592 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 1317 | 1317 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | TIMING/parse/read_files | 2.1 min | 1.6 min | -25.8 s | -20.9% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics | 11.7 s | 12.4 s | +736 ms | 6.3% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-p99 | TIMING/total | 2.3 min | 1.8 min | -25 s | -18.5% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/rss_peak | 2.6 GB | 2.4 GB | -165.4 MB | -6.3% | IMPROVE |
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
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_analysis | 567.3 MB | 568.5 MB | +1.2 MB | 0.2% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY/log_messages | 1.6 GB | 1.6 GB | +1.8 MB | 0.1% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_stats | 43.6 KB | 43.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/unattributed | 448.8 MB | 279.7 MB | -169.1 MB | -37.7% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/log_messages | 1702548945 | 1704461713 | 1912768 | 0.1% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
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
| month-single-server-access-logs-sort-p99 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/parse/read_files | 2.1 min | 1.6 min | -26.3 s | -21.2% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics | 7.1 s | 7.7 s | +617 ms | 8.7% | REGRESS |
| month-single-server-access-logs-sort-skewness | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/total | 2.2 min | 1.8 min | -25.7 s | -19.6% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/rss_peak | 2.5 GB | 2.3 GB | -240.3 MB | -9.3% | IMPROVE |
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
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_analysis | 567.3 MB | 568.5 MB | +1.2 MB | 0.2% | REGRESS |
| month-single-server-access-logs-sort-skewness | MEMORY/log_messages | 1.6 GB | 1.5 GB | -74.0 MB | -4.6% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-sort-skewness | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_stats | 43.6 KB | 43.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/unattributed | 386.2 MB | 217.8 MB | -168.3 MB | -43.6% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/log_messages | 1704463286 | 1626878326 | -77584960 | -4.6% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
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
| month-single-server-access-logs-sort-skewness | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/parse/read_files | 10.1 min | 8.2 min | -1.9 min | -18.8% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics | 30.2 s | 32.6 s | +2.4 s | 8.1% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/total | 10.7 min | 8.8 min | -1.9 min | -17.5% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 12.1 GB | 12.1 GB | -12.3 MB | -0.1% | IMPROVE |
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
| month-many-servers-access-logs-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_analysis | 2.9 GB | 2.9 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_messages | 8.2 GB | 8.2 GB | +9.4 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_occurrences | 42.1 KB | 43.8 KB | +1.8 KB | 4.2% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_stats | 44.1 KB | 44.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/unattributed | 1.1 GB | 1 GB | -22.4 MB | -2.1% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_messages | 8796591492 | 8806439108 | 9847616 | 0.1% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
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
| month-many-servers-access-logs-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/parse/read_files | 10.1 min | 8.2 min | -1.9 min | -18.4% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics | 31.3 s | 33.5 s | +2.2 s | 7.2% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/total | 10.6 min | 8.8 min | -1.8 min | -17.2% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 12.4 GB | 12.2 GB | -205.4 MB | -1.6% | IMPROVE |
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
| month-many-servers-access-logs-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_analysis | 2.9 GB | 2.9 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_messages | 8.2 GB | 8.2 GB | +9.4 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_stats | 44.1 KB | 44.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/message_key_order | 4.7 KB | 4.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/unattributed | 1.3 GB | 1.1 GB | -215.5 MB | -16.7% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_messages | 8796602084 | 8806449828 | 9847744 | 0.1% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
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
| month-many-servers-access-logs-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/parse/read_files | 12.4 min | 10.3 min | -2.1 min | -17.1% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/group_similar | 17.1 min | 16.7 min | -22.9 s | -2.2% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 39.3 s | 38.2 s | -1.1 s | -2.9% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 30.2 min | 27.6 min | -2.5 min | -8.3% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 6.7 GB | 6.4 GB | -285.9 MB | -4.2% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 2.6 GB | 2.6 GB | +8.2 MB | 0.3% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 2.5 MB | 2.5 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 36.8 MB | 36.8 MB | -512 B | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 29.5 MB | 29.5 MB | -7 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 36.1 MB | 36.1 MB | -4.9 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 531.3 KB | 531.3 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_posting_size | 1.2 MB | 1.2 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | 1.7 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_analysis | 2.9 GB | 2.9 GB | -2 MB | -0.1% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages | 2.9 GB | 2.9 GB | +8.2 MB | 0.3% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_occurrences | 43.8 KB | 43.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_stats | 44.1 KB | 44.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/message_key_order | 4.2 KB | 4.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | 3091525898 | 3100090410 | 8564512 | 0.3% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 2834456928 | 2843032320 | 8575392 | 0.3% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 544033 | 544033 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | 424 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | 65592 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_messages_entries | 2549 | 2549 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/parse/read_files | 11.0 min | 8.7 min | -2.3 min | -20.6% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics | 12.2 s | 13.9 s | +1.7 s | 14.3% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/finalize/heatmap_statistics | 74 ms | 76 ms | +2 ms | 2.7% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/render/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/total | 11.2 min | 9.0 min | -2.2 min | -20.0% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 9.9 GB | 9.7 GB | -171.1 MB | -1.7% | IMPROVE |
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
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | +1.8 KB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data | 81.1 KB | 81.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_analysis | 15.3 KB | 15.3 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_messages | 8.2 GB | 8.2 GB | -9.4 MB | -0.1% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_occurrences | 42.1 KB | 43.8 KB | +1.8 KB | 4.2% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_stats | 29.6 KB | 29.6 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/unattributed | 1.7 GB | 1.5 GB | -162.4 MB | -9.3% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_messages | 8801379964 | 8791532220 | -9847744 | -0.1% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_analysis | 12594 | 12594 | 0 | 0.0% |  |
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
| month-many-servers-access-logs-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/parse/read_files | 12.0 min | 9.8 min | -2.1 min | -17.8% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics | 29.2 s | 30.9 s | +1.6 s | 5.6% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/finalize/histogram_statistics | 10 ms | 10 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/total | 12.5 min | 10.4 min | -2.1 min | -16.9% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 12.4 GB | 11.8 GB | -626.3 MB | -4.9% | IMPROVE |
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
| month-many-servers-access-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_counters | 307.4 KB | 307.3 KB | -128 B | -0.0% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_analysis | 2.9 GB | 2.9 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_messages | 8.2 GB | 7.8 GB | -377.6 MB | -4.5% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_stats | 44.1 KB | 44.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/unattributed | 1.3 GB | 1.1 GB | -249.4 MB | -18.8% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_messages | 8806439364 | 8410455044 | -395984320 | -4.5% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
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
| month-many-servers-access-logs-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/parse/read_files | 12.5 min | 10.5 min | -2.1 min | -16.5% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 12.8 s | 13.2 s | +422 ms | 3.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/heatmap_statistics | 75 ms | 78 ms | +3 ms | 4.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/histogram_statistics | 9 ms | 10 ms | +1 ms | 11.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 12.8 min | 10.7 min | -2.1 min | -16.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 9.6 GB | 9.8 GB | +127.9 MB | 1.3% | REGRESS |
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
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data | 80.6 KB | 81.1 KB | +512 B | 0.6% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_counters | 307.4 KB | 307.4 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.3 KB | 15.3 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages | 7.8 GB | 8.2 GB | +377.6 MB | 4.7% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_stats | 29.6 KB | 29.6 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/unattributed | 1.8 GB | 1.5 GB | -250.4 MB | -13.7% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 8405396412 | 8801379580 | 395983168 | 4.7% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 12594 | 12594 | 0 | 0.0% |  |
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
| month-many-servers-access-logs-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 14.7 min | 12.6 min | -2.1 min | -14.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 12.6 min | 12.9 min | +17.6 s | 2.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 14.8 s | 15.3 s | +529 ms | 3.6% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 69 ms | 68 ms | -1 ms | -1.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 11 ms | 10 ms | -1000 us | -9.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 27.5 min | 25.8 min | -1.8 min | -6.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 4.6 GB | 4.3 GB | -281.1 MB | -6.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 2.6 GB | 2.6 GB | +1.2 MB | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.5 MB | 2.5 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 36.8 MB | 36.8 MB | +1 KB | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 29.4 MB | 29.5 MB | +22 KB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 36.1 MB | 36.1 MB | -19.6 KB | -0.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 531.2 KB | 531.3 KB | +128 B | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 1.2 MB | 1.2 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | 1.7 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 80.1 KB | 80.3 KB | +256 B | 0.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 307.4 KB | 307.4 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 15.3 KB | 15.3 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 2.9 GB | 2.9 GB | +110.5 KB | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 43.8 KB | 43.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +32 KB | 0.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 29.6 KB | 29.6 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 1.9 KB | 1.9 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 3093065866 | 3093178994 | 113128 | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 12594 | 12594 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 2834892640 | 2836131272 | 1238632 | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 543905 | 544033 | 128 | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | 424 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | 65592 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 2549 | 2549 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | TIMING/parse/read_files | 10.1 min | 8.0 min | -2.2 min | -21.3% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics | 1.2 min | 1.3 min | +3.3 s | 4.6% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | TIMING/total | 11.3 min | 9.2 min | -2.1 min | -18.6% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/rss_peak | 12.7 GB | 12.4 GB | -245.2 MB | -1.9% | IMPROVE |
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
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_analysis | 2.9 GB | 2.9 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_messages | 8.2 GB | 8.2 GB | -512 B | -0.0% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -128 B | -0.0% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_stats | 44.1 KB | 44.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/message_key_order | 2.5 KB | 2.5 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/unattributed | 1.6 GB | 1.3 GB | -245.9 MB | -15.2% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/log_messages | 8806472284 | 8806471772 | -512 | -0.0% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
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
| month-many-servers-access-logs-sort-p99 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | TIMING/parse/read_files | 10.1 min | 7.9 min | -2.2 min | -21.7% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics | 43.4 s | 44.1 s | +675 ms | 1.6% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/render/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/total | 10.9 min | 8.7 min | -2.2 min | -20.1% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY/rss_peak | 12.4 GB | 12 GB | -338.0 MB | -2.7% | IMPROVE |
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
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_analysis | 2.9 GB | 2.9 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_messages | 8.2 GB | 8.2 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_occurrences | 43.8 KB | 43.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -32.1 KB | -0.2% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_stats | 44.1 KB | 44.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/message_key_order | 2.1 KB | 2.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/unattributed | 1.3 GB | 957.8 MB | -338.6 MB | -26.1% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/log_messages | 8796625985 | 8796625985 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
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
| month-many-servers-access-logs-sort-skewness | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| humungous-log-uniqueness-standard | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics/sort_selection | N/A | 327 ms | N/A | N/A | ? |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics/untimed | N/A | 13 ms | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/format_scan_subs | N/A | 752 KB | N/A | N/A | ? |
| humungous-log-uniqueness-standard | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | COUNTS/log_messages_population | N/A | 286659 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics/sort_selection | N/A | 335 ms | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics/untimed | N/A | 13 ms | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/format_scan_subs | N/A | 736 KB | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | COUNTS/log_messages_population | N/A | 286659 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/format_scan_subs | N/A | 768 KB | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_messages_population | N/A | 72 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics/sort_selection | N/A | 313 ms | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics/untimed | N/A | 13 ms | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/format_scan_subs | N/A | 784 KB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | COUNTS/log_messages_population | N/A | 286659 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics/sort_selection | N/A | 343 ms | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics/untimed | N/A | 13 ms | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/format_scan_subs | N/A | 768 KB | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | COUNTS/log_messages_population | N/A | 286659 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | N/A | 329 ms | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | N/A | 13 ms | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/format_scan_subs | N/A | 768 KB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | COUNTS/log_messages_population | N/A | 286659 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/format_scan_subs | N/A | 720 KB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_messages_population | N/A | 72 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | N/A | 274 ms | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | N/A | 283 ms | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics/untimed | N/A | 13 ms | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/format_scan_subs | N/A | 736 KB | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | COUNTS/log_messages_population | N/A | 286659 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | N/A | 283 ms | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | N/A | 282 ms | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics/untimed | N/A | 13 ms | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/format_scan_subs | N/A | 768 KB | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | COUNTS/log_messages_population | N/A | 286659 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-standard | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| single-day-application-log-standard | TIMING/detect/scan_sub_compile | N/A | 5 ms | N/A | N/A | ? |
| single-day-application-log-standard | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-standard | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-standard | TIMING/finalize/calculate_statistics/sort_selection | N/A | 6 ms | N/A | N/A | ? |
| single-day-application-log-standard | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-standard | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-standard | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/format_scan_subs | N/A | 720 KB | N/A | N/A | ? |
| single-day-application-log-standard | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-standard | COUNTS/log_messages_population | N/A | 6512 | N/A | N/A | ? |
| single-day-application-log-standard | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-standard | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| single-day-application-log-standard | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-top25 | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| single-day-application-log-top25 | TIMING/detect/scan_sub_compile | N/A | 5 ms | N/A | N/A | ? |
| single-day-application-log-top25 | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-top25 | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-top25 | TIMING/finalize/calculate_statistics/sort_selection | N/A | 7 ms | N/A | N/A | ? |
| single-day-application-log-top25 | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-top25 | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-top25 | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/format_scan_subs | N/A | 752 KB | N/A | N/A | ? |
| single-day-application-log-top25 | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-top25 | COUNTS/log_messages_population | N/A | 6512 | N/A | N/A | ? |
| single-day-application-log-top25 | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-top25 | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| single-day-application-log-top25 | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/format_scan_subs | N/A | 768 KB | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | COUNTS/log_messages_population | N/A | 136 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| single-day-application-log-heatmap | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| single-day-application-log-heatmap | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap | TIMING/finalize/calculate_statistics/sort_selection | N/A | 6 ms | N/A | N/A | ? |
| single-day-application-log-heatmap | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/format_scan_subs | N/A | 752 KB | N/A | N/A | ? |
| single-day-application-log-heatmap | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap | COUNTS/log_messages_population | N/A | 6512 | N/A | N/A | ? |
| single-day-application-log-heatmap | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| single-day-application-log-heatmap | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-histogram | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| single-day-application-log-histogram | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| single-day-application-log-histogram | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-histogram | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-histogram | TIMING/finalize/calculate_statistics/sort_selection | N/A | 6 ms | N/A | N/A | ? |
| single-day-application-log-histogram | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-histogram | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-histogram | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/format_scan_subs | N/A | 752 KB | N/A | N/A | ? |
| single-day-application-log-histogram | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-histogram | COUNTS/log_messages_population | N/A | 6512 | N/A | N/A | ? |
| single-day-application-log-histogram | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-histogram | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| single-day-application-log-histogram | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | N/A | 6 ms | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/format_scan_subs | N/A | 784 KB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | COUNTS/log_messages_population | N/A | 6512 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/format_scan_subs | N/A | 800 KB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_messages_population | N/A | 136 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| single-day-application-log-sort-p99 | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| single-day-application-log-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | N/A | 2 ms | N/A | N/A | ? |
| single-day-application-log-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | N/A | 6 ms | N/A | N/A | ? |
| single-day-application-log-sort-p99 | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-sort-p99 | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-sort-p99 | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/format_scan_subs | N/A | 736 KB | N/A | N/A | ? |
| single-day-application-log-sort-p99 | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | COUNTS/log_messages_population | N/A | 6512 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| single-day-application-log-sort-skewness | TIMING/detect/scan_sub_compile | N/A | 5 ms | N/A | N/A | ? |
| single-day-application-log-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | N/A | 3 ms | N/A | N/A | ? |
| single-day-application-log-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | N/A | 5 ms | N/A | N/A | ? |
| single-day-application-log-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-sort-skewness | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-sort-skewness | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/format_scan_subs | N/A | 752 KB | N/A | N/A | ? |
| single-day-application-log-sort-skewness | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | COUNTS/log_messages_population | N/A | 6512 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-standard | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| multi-day-application-logs-standard | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | N/A | 191 ms | N/A | N/A | ? |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics/untimed | N/A | 4 ms | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/format_scan_subs | N/A | 720 KB | N/A | N/A | ? |
| multi-day-application-logs-standard | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-standard | COUNTS/log_messages_population | N/A | 105902 | N/A | N/A | ? |
| multi-day-application-logs-standard | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-standard | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-application-logs-standard | COUNTS/format_scan_sub_cache_hits | N/A | 40 | N/A | N/A | ? |
| multi-day-application-logs-top25 | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| multi-day-application-logs-top25 | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | N/A | 203 ms | N/A | N/A | ? |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics/untimed | N/A | 2 ms | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/format_scan_subs | N/A | 720 KB | N/A | N/A | ? |
| multi-day-application-logs-top25 | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-top25 | COUNTS/log_messages_population | N/A | 105902 | N/A | N/A | ? |
| multi-day-application-logs-top25 | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-top25 | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-application-logs-top25 | COUNTS/format_scan_sub_cache_hits | N/A | 40 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | N/A | 3 ms | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/format_scan_subs | N/A | 784 KB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/log_messages_population | N/A | 1304 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | N/A | 40 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | N/A | 189 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | N/A | 3 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/format_scan_subs | N/A | 768 KB | N/A | N/A | ? |
| multi-day-application-logs-heatmap | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | COUNTS/log_messages_population | N/A | 105902 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | COUNTS/format_scan_sub_cache_hits | N/A | 40 | N/A | N/A | ? |
| multi-day-application-logs-histogram | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| multi-day-application-logs-histogram | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | N/A | 205 ms | N/A | N/A | ? |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics/untimed | N/A | 3 ms | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/format_scan_subs | N/A | 736 KB | N/A | N/A | ? |
| multi-day-application-logs-histogram | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-histogram | COUNTS/log_messages_population | N/A | 105902 | N/A | N/A | ? |
| multi-day-application-logs-histogram | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-histogram | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-application-logs-histogram | COUNTS/format_scan_sub_cache_hits | N/A | 40 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | N/A | 206 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | N/A | 3 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/format_scan_subs | N/A | 736 KB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | COUNTS/log_messages_population | N/A | 105902 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | COUNTS/format_scan_sub_cache_hits | N/A | 40 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | N/A | 9 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | N/A | 5 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | N/A | 3 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | N/A | 704 KB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | N/A | 1304 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | N/A | 40 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | N/A | 82 ms | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | N/A | 175 ms | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | N/A | 3 ms | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/format_scan_subs | N/A | 720 KB | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | COUNTS/log_messages_population | N/A | 105902 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | COUNTS/format_scan_sub_cache_hits | N/A | 40 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | N/A | 82 ms | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | N/A | 177 ms | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | N/A | 3 ms | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/format_scan_subs | N/A | 752 KB | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | COUNTS/log_messages_population | N/A | 105902 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | COUNTS/format_scan_sub_cache_hits | N/A | 40 | N/A | N/A | ? |
| multi-day-custom-logs-standard | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| multi-day-custom-logs-standard | TIMING/detect/scan_sub_compile | N/A | 5 ms | N/A | N/A | ? |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 59 ms | N/A | N/A | ? |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | N/A | 348 ms | N/A | N/A | ? |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/group_calc | N/A | 4 ms | N/A | N/A | ? |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/untimed | N/A | 8 ms | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/format_scan_subs | N/A | 752 KB | N/A | N/A | ? |
| multi-day-custom-logs-standard | COUNTS/log_analysis_entries | N/A | 24 | N/A | N/A | ? |
| multi-day-custom-logs-standard | COUNTS/log_messages_population | N/A | 182419 | N/A | N/A | ? |
| multi-day-custom-logs-standard | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-standard | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-custom-logs-standard | COUNTS/format_scan_sub_cache_hits | N/A | 4 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| multi-day-custom-logs-top25 | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 59 ms | N/A | N/A | ? |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | N/A | 355 ms | N/A | N/A | ? |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/group_calc | N/A | 11 ms | N/A | N/A | ? |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/untimed | N/A | 8 ms | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/format_scan_subs | N/A | 736 KB | N/A | N/A | ? |
| multi-day-custom-logs-top25 | COUNTS/log_analysis_entries | N/A | 24 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | COUNTS/log_messages_population | N/A | 182419 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | COUNTS/format_scan_sub_cache_hits | N/A | 4 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | TIMING/detect/scan_sub_compile | N/A | 5 ms | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 138 ms | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | N/A | 1 ms | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | N/A | 154 ms | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/format_scan_subs | N/A | 816 KB | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_analysis_entries | N/A | 24 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_messages_population | N/A | 606 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | N/A | 4 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | N/A | 349 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/group_calc | N/A | 5 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | N/A | 8 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/format_scan_subs | N/A | 704 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | COUNTS/log_analysis_entries | N/A | 24 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | COUNTS/log_messages_population | N/A | 182419 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | COUNTS/format_scan_sub_cache_hits | N/A | 4 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| multi-day-custom-logs-histogram | TIMING/detect/scan_sub_compile | N/A | 5 ms | N/A | N/A | ? |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 60 ms | N/A | N/A | ? |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | N/A | 356 ms | N/A | N/A | ? |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/group_calc | N/A | 4 ms | N/A | N/A | ? |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/untimed | N/A | 8 ms | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/format_scan_subs | N/A | 800 KB | N/A | N/A | ? |
| multi-day-custom-logs-histogram | COUNTS/log_analysis_entries | N/A | 24 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | COUNTS/log_messages_population | N/A | 182419 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | COUNTS/format_scan_sub_cache_hits | N/A | 4 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | N/A | 333 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | N/A | 5 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | N/A | 7 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/format_scan_subs | N/A | 784 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | COUNTS/log_analysis_entries | N/A | 24 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | COUNTS/log_messages_population | N/A | 182419 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | COUNTS/format_scan_sub_cache_hits | N/A | 4 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | N/A | 1 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | N/A | 141 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | N/A | 752 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | N/A | 24 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | N/A | 606 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | N/A | 4 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 60 ms | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | N/A | 241 ms | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | N/A | 3 ms | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | N/A | 9 ms | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/format_scan_subs | N/A | 784 KB | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | COUNTS/log_analysis_entries | N/A | 24 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | COUNTS/log_messages_population | N/A | 182419 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | COUNTS/format_scan_sub_cache_hits | N/A | 4 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | TIMING/detect/scan_sub_compile | N/A | 5 ms | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 59 ms | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | N/A | 310 ms | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | N/A | 3 ms | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | N/A | 8 ms | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | N/A | 8 ms | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/format_scan_subs | N/A | 784 KB | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | COUNTS/log_analysis_entries | N/A | 24 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | COUNTS/log_messages_population | N/A | 182419 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | COUNTS/format_scan_sub_cache_hits | N/A | 4 | N/A | N/A | ? |
| single-day-access-log-standard | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| single-day-access-log-standard | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 102 ms | N/A | N/A | ? |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/sort_selection | N/A | 6 ms | N/A | N/A | ? |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/group_calc | N/A | 47 ms | N/A | N/A | ? |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/format_scan_subs | N/A | 672 KB | N/A | N/A | ? |
| single-day-access-log-standard | COUNTS/log_analysis_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-standard | COUNTS/log_messages_population | N/A | 3184 | N/A | N/A | ? |
| single-day-access-log-standard | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-standard | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| single-day-access-log-standard | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-top25 | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| single-day-access-log-top25 | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 106 ms | N/A | N/A | ? |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/sort_selection | N/A | 6 ms | N/A | N/A | ? |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/group_calc | N/A | 68 ms | N/A | N/A | ? |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/format_scan_subs | N/A | 752 KB | N/A | N/A | ? |
| single-day-access-log-top25 | COUNTS/log_analysis_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-top25 | COUNTS/log_messages_population | N/A | 3184 | N/A | N/A | ? |
| single-day-access-log-top25 | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-top25 | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| single-day-access-log-top25 | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | TIMING/detect/scan_sub_compile | N/A | 5 ms | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 164 ms | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | N/A | 1 ms | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | N/A | 170 ms | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/format_scan_subs | N/A | 752 KB | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | COUNTS/log_analysis_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | COUNTS/log_messages_population | N/A | 615 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-heatmap | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| single-day-access-log-heatmap | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics/sort_selection | N/A | 5 ms | N/A | N/A | ? |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics/group_calc | N/A | 44 ms | N/A | N/A | ? |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/format_scan_subs | N/A | 736 KB | N/A | N/A | ? |
| single-day-access-log-heatmap | COUNTS/log_analysis_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-heatmap | COUNTS/log_messages_population | N/A | 3184 | N/A | N/A | ? |
| single-day-access-log-heatmap | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-heatmap | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| single-day-access-log-heatmap | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-histogram | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| single-day-access-log-histogram | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 99 ms | N/A | N/A | ? |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/sort_selection | N/A | 6 ms | N/A | N/A | ? |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/group_calc | N/A | 45 ms | N/A | N/A | ? |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/format_scan_subs | N/A | 656 KB | N/A | N/A | ? |
| single-day-access-log-histogram | COUNTS/log_analysis_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-histogram | COUNTS/log_messages_population | N/A | 3184 | N/A | N/A | ? |
| single-day-access-log-histogram | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-histogram | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| single-day-access-log-histogram | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | N/A | 6 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | N/A | 43 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/format_scan_subs | N/A | 736 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | COUNTS/log_analysis_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | COUNTS/log_messages_population | N/A | 3184 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | N/A | 1 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | N/A | 167 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/format_scan_subs | N/A | 704 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_messages_population | N/A | 615 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| single-day-access-log-sort-p99 | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 103 ms | N/A | N/A | ? |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | N/A | 107 ms | N/A | N/A | ? |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | N/A | 2 ms | N/A | N/A | ? |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/format_scan_subs | N/A | 720 KB | N/A | N/A | ? |
| single-day-access-log-sort-p99 | COUNTS/log_analysis_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | COUNTS/log_messages_population | N/A | 3184 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| single-day-access-log-sort-skewness | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 100 ms | N/A | N/A | ? |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | N/A | 228 ms | N/A | N/A | ? |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | N/A | 1 ms | N/A | N/A | ? |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | N/A | 5 ms | N/A | N/A | ? |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/format_scan_subs | N/A | 640 KB | N/A | N/A | ? |
| single-day-access-log-sort-skewness | COUNTS/log_analysis_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | COUNTS/log_messages_population | N/A | 3184 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 2.7 s | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | N/A | 1.7 s | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/group_calc | N/A | 607 ms | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/untimed | N/A | 63 ms | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/format_scan_subs | N/A | 704 KB | N/A | N/A | ? |
| month-single-server-access-logs-standard | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-standard | COUNTS/log_messages_population | N/A | 1212275 | N/A | N/A | ? |
| month-single-server-access-logs-standard | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-standard | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| month-single-server-access-logs-standard | COUNTS/format_scan_sub_cache_hits | N/A | 27 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 3 s | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | N/A | 1.6 s | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/group_calc | N/A | 934 ms | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/untimed | N/A | 67 ms | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/format_scan_subs | N/A | 736 KB | N/A | N/A | ? |
| month-single-server-access-logs-top25 | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | COUNTS/log_messages_population | N/A | 1212275 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | COUNTS/format_scan_sub_cache_hits | N/A | 27 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 4.0 s | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | N/A | 3 ms | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | N/A | 3.4 s | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/untimed | N/A | 3 ms | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/format_scan_subs | N/A | 784 KB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_messages_population | N/A | 1317 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | N/A | 27 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/detect/scan_sub_compile | N/A | 5 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | N/A | 1.7 s | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/group_calc | N/A | 548 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | N/A | 73 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/format_scan_subs | N/A | 752 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | COUNTS/log_messages_population | N/A | 1212275 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | COUNTS/format_scan_sub_cache_hits | N/A | 27 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 2.9 s | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | N/A | 1.8 s | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/group_calc | N/A | 647 ms | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/untimed | N/A | 63 ms | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/format_scan_subs | N/A | 736 KB | N/A | N/A | ? |
| month-single-server-access-logs-histogram | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | COUNTS/log_messages_population | N/A | 1212275 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | COUNTS/format_scan_sub_cache_hits | N/A | 27 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | N/A | 5 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | N/A | 1.7 s | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | N/A | 578 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | N/A | 83 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/format_scan_subs | N/A | 704 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_messages_population | N/A | 1212275 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | COUNTS/format_scan_sub_cache_hits | N/A | 27 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | N/A | 5 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | N/A | 4 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | N/A | 3.1 s | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/untimed | N/A | 3 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | N/A | 720 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | N/A | 1317 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | N/A | 27 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 2.8 s | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | N/A | 6.0 s | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | N/A | 3.5 s | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/group_calc | N/A | 22 ms | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | N/A | 140 ms | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/format_scan_subs | N/A | 736 KB | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | COUNTS/log_messages_population | N/A | 1212275 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | COUNTS/format_scan_sub_cache_hits | N/A | 27 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 2.8 s | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | N/A | 4.5 s | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | N/A | 13 ms | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | N/A | 300 ms | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | N/A | 68 ms | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/format_scan_subs | N/A | 752 KB | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | COUNTS/log_messages_population | N/A | 1212275 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | COUNTS/format_scan_sub_cache_hits | N/A | 27 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/detect/registry_build | N/A | 9 ms | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 17.8 s | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | N/A | 10.8 s | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/group_calc | N/A | 3.6 s | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/untimed | N/A | 390 ms | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/format_scan_subs | N/A | 720 KB | N/A | N/A | ? |
| month-many-servers-access-logs-standard | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | COUNTS/log_messages_population | N/A | 6187253 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | COUNTS/format_scan_sub_cache_hits | N/A | 139 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 17.5 s | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | N/A | 10.3 s | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/group_calc | N/A | 5.4 s | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/untimed | N/A | 351 ms | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/format_scan_subs | N/A | 736 KB | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | COUNTS/log_messages_population | N/A | 6187253 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | COUNTS/format_scan_sub_cache_hits | N/A | 139 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 20.2 s | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | N/A | 8 ms | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | N/A | 18.0 s | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/untimed | N/A | 30 ms | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/format_scan_subs | N/A | 752 KB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_messages_population | N/A | 2549 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | N/A | 139 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | N/A | 10.3 s | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/group_calc | N/A | 3.1 s | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | N/A | 437 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/format_scan_subs | N/A | 752 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | COUNTS/log_messages_population | N/A | 6187253 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | COUNTS/format_scan_sub_cache_hits | N/A | 139 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 16.7 s | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | N/A | 10.3 s | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/group_calc | N/A | 3.5 s | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/untimed | N/A | 372 ms | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/format_scan_subs | N/A | 752 KB | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | COUNTS/log_messages_population | N/A | 6187253 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | COUNTS/format_scan_sub_cache_hits | N/A | 139 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | N/A | 9.7 s | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | N/A | 3.1 s | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | N/A | 407 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/format_scan_subs | N/A | 720 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_messages_population | N/A | 6187253 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/format_scan_sub_cache_hits | N/A | 139 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | N/A | 6 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | N/A | 15.3 s | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/untimed | N/A | 24 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | N/A | 736 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | N/A | 2549 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | N/A | 139 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 17.5 s | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | N/A | 35.4 s | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | N/A | 21.4 s | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | N/A | 836 ms | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/format_scan_subs | N/A | 704 KB | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | COUNTS/log_messages_population | N/A | 6187253 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | COUNTS/format_scan_sub_cache_hits | N/A | 139 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | TIMING/detect/registry_build | N/A | 8 ms | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | TIMING/detect/scan_sub_compile | N/A | 4 ms | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 17.0 s | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | N/A | 25.6 s | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | N/A | 73 ms | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | N/A | 1.1 s | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | N/A | 384 ms | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/format_scan_subs | N/A | 720 KB | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | COUNTS/log_messages_population | N/A | 6187253 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | COUNTS/format_scan_sub_cache_hits | N/A | 139 | N/A | N/A | ? |

