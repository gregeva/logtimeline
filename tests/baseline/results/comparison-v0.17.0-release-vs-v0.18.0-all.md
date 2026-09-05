
## Benchmark Comparison

  Baseline:    v0.17.0-release (v0.17.0, 63 test cases)
  Current:     v0.18.0-all (v0.18.0, 77 test cases)

### Timing Delta

| # | file selection | standard | no-msgs | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons | sort-p99 | sort-skew | hm+hg+export |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | +7.1% | - | +7.1% | -4.4% | +7.9% | +8.2% | +6.5% | -7.0% | -3.5% | -1.8% | - |
| 2. | single-day-application-log | +10.8% | - | +9.4% | +2.2% | +10.6% | +8.7% | +10.3% | +1.3% | +8.9% | +10.2% | - |
| 3. | multi-day-application-logs | +10.8% | - | +10.3% | -7.4% | +10.5% | +6.9% | +7.6% | -6.8% | +8.5% | +7.8% | - |
| 4. | multi-day-custom-logs | +2.0% | - | +1.3% | -5.9% | +3.3% | +3.0% | +2.6% | -5.3% | +3.0% | +3.1% | - |
| 5. | single-day-access-log | -1.1% | - | -2.5% | -4.8% | -0.7% | +0.5% | +0.2% | -0.3% | +0.6% | +0.5% | - |
| 6. | month-single-server-access-logs | -0.3% | - | +0.6% | -4.9% | -1.3% | -2.3% | -3.4% | -6.0% | -2.9% | -2.3% | - |
| 7. | month-many-servers-access-logs | -3.1% | - | -2.6% | +3.8% | +1.2% | +0.8% | +0.3% | +0.3% | +0.8% | +1.2% | - |

### Memory Delta (RSS Peak)

| # | file selection | standard | no-msgs | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons | sort-p99 | sort-skew | hm+hg+export |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | +26.8% | - | +26.3% | +4.0% | +27.0% | +26.1% | +25.8% | +3.6% | +27.0% | +28.3% | - |
| 2. | single-day-application-log | +16.4% | - | +14.3% | +5.7% | +14.8% | +15.1% | +14.2% | +6.0% | +15.7% | +13.6% | - |
| 3. | multi-day-application-logs | +12.3% | - | +11.4% | +1.4% | +12.2% | +11.2% | +12.2% | +0.9% | +11.7% | +11.2% | - |
| 4. | multi-day-custom-logs | +4.5% | - | +5.8% | +3.6% | +7.3% | +4.6% | +6.1% | +4.7% | +4.4% | +4.4% | - |
| 5. | single-day-access-log | +5.4% | - | +4.7% | +4.3% | +5.7% | +5.5% | +5.2% | +5.3% | +4.4% | +4.6% | - |
| 6. | month-single-server-access-logs | +8.0% | - | +8.6% | +0.5% | +10.5% | +8.5% | +10.5% | +0.5% | +8.6% | +11.5% | - |
| 7. | month-many-servers-access-logs | +7.9% | - | +8.2% | +0.8% | +10.4% | +11.1% | +10.4% | +4.1% | +7.6% | +8.4% | - |

### Stage Rollup (timing)

| metric | baseline | current | delta | change% | cases +/- | result |
| --- | --- | --- | --- | --- | --- | --- |
| detect/registry_build | 506 ms | 855 ms | +349 ms | 69.0% | 63/0 | REGRESS |
| detect/scan_sub_compile (within parent) | 264 ms | 691 ms | +427 ms | 161.7% | 63/0 | REGRESS |
| parse/read_files | 109.9 min | 128.6 min | +18.7 min | 17.0% | 41/22 | REGRESS |
| finalize/group_similar | 33.3 min | 34.2 min | +54.4 s | 2.7% | 2/12 | REGRESS (most cases IMPROVE) |
| finalize/calculate_statistics | 6.0 min | 6.2 min | +13.2 s | 3.7% | 0/52 | REGRESS (most cases IMPROVE) |
| finalize/calculate_statistics/bucket_stats (within parent) | 2.1 min | 2.6 min | +30.7 s | 24.4% | 1/23 | REGRESS (most cases IMPROVE) |
| finalize/calculate_statistics/population_walk (within parent) | 1.2 min | 1.2 min | -3.1 s | -4.3% | 0/14 | IMPROVE |
| finalize/calculate_statistics/sort_selection (within parent) | 1.5 min | 1.4 min | -9.2 s | -10.2% | 4/41 | IMPROVE |
| finalize/calculate_statistics/group_calc (within parent) | 1.1 min | 58.9 s | -5.2 s | -8.2% | 0/32 | IMPROVE |
| finalize/heatmap_statistics | 488 ms | 1.6 s | +1.1 s | 229.9% | 12/0 | REGRESS |
| finalize/histogram_statistics | 76 ms | 259 ms | +183 ms | 240.8% | 12/0 | REGRESS |
| total | 149.2 min | 169 min | +19.9 min | 13.3% | 40/23 | REGRESS |
| (1 below noise floor) | 99 ms | 126 ms | +27 ms | 27.3% | - | REGRESS |
| (1 below noise floor) (within parent) | 4.0 s | 4 s | +83 ms | 2.1% | - | REGRESS |
| sum of stages | 149.2 min | 169 min | +19.9 min | 13.3% | - | REGRESS |

### Category Rollup (memory)

| metric | baseline | current | delta | change% | cases +/- | result |
| --- | --- | --- | --- | --- | --- | --- |
| rss_peak | 115.3 GB | 133.5 GB | +18.2 GB | 15.8% | 63/0 | REGRESS |
| log_messages | 77.3 GB | 86.2 GB | +8.9 GB | 11.5% | 61/2 | REGRESS |
| log_analysis | 21.1 GB | 28.1 GB | +7 GB | 33.3% | 28/12 | REGRESS |
| unattributed | 12.6 GB | 14.5 GB | +1.9 GB | 15.3% | 54/5 | REGRESS |
| format_scan_subs | 45.7 MB | 110.8 MB | +65.2 MB | 142.8% | 63/0 | REGRESS |
| log_sessions | 154.3 MB | 188.5 MB | +34.1 MB | 22.1% | 1/17 | REGRESS (most cases IMPROVE) |
| heatmap_counters | 19.8 MB | 26.5 MB | +6.6 MB | 33.6% | 12/0 | REGRESS |
| consolidation_clusters | 6.4 GB | 6.4 GB | -2.2 MB | -0.0% | 10/4 | IMPROVE (most cases REGRESS) |
| log_stats | 1.2 MB | 2.3 MB | +1.2 MB | 98.5% | 63/0 | REGRESS |
| (24 below noise floor) | 1.6 GB | 1.6 GB | +1.9 MB | 0.1% | - | REGRESS |

### New In This Version

| metric | test cases | per-test range | aggregate |
| --- | --- | --- | --- |
| MEMORY/bucket_outcomes | 77 | 1.3 KB - 13.3 KB | 490.6 KB |
| MEMORY/log_users | 77 | 120 B - 85.5 KB | 1.6 MB |

### Summary

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.6 s | 2.8 s | +184 ms | 7.1% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 208.5 MB | 264.3 MB | +55.9 MB | 26.8% | REGRESS |
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.6 s | 2.7 s | +180 ms | 7.1% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 209.4 MB | 264.6 MB | +55.2 MB | 26.3% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 11.0 s | 10.5 s | -477 ms | -4.4% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 254.4 MB | 264.7 MB | +10.2 MB | 4.0% | REGRESS |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.5 s | 2.7 s | +200 ms | 7.9% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 208.3 MB | 264.5 MB | +56.2 MB | 27.0% | REGRESS |
| humungous-log-uniqueness-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.5 s | 2.8 s | +209 ms | 8.2% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 209.6 MB | 264.4 MB | +54.8 MB | 26.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.5 s | 2.7 s | +164 ms | 6.5% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 209.9 MB | 264.2 MB | +54.2 MB | 25.8% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 10.9 s | 10.2 s | -770 ms | -7.0% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 255.0 MB | 264.2 MB | +9.3 MB | 3.6% | REGRESS |
| humungous-log-uniqueness-sort-p99 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/total | 2.8 s | 2.7 s | -97 ms | -3.5% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | MEMORY/rss_peak | 208.2 MB | 264.4 MB | +56.2 MB | 27.0% | REGRESS |
| humungous-log-uniqueness-sort-skewness | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/total | 2.8 s | 2.7 s | -50 ms | -1.8% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | MEMORY/rss_peak | 205.9 MB | 264.2 MB | +58.3 MB | 28.3% | REGRESS |
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.3 s | 3.6 s | +355 ms | 10.8% | REGRESS |
| single-day-application-log-standard | MEMORY/rss_peak | 35.8 MB | 41.7 MB | +5.9 MB | 16.4% | REGRESS |
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.3 s | 3.6 s | +309 ms | 9.4% | REGRESS |
| single-day-application-log-top25 | MEMORY/rss_peak | 36.1 MB | 41.3 MB | +5.2 MB | 14.3% | REGRESS |
| single-day-application-log-top25-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 6.3 s | 6.4 s | +137 ms | 2.2% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 123.3 MB | 130.4 MB | +7.1 MB | 5.7% | REGRESS |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.3 s | 3.6 s | +347 ms | 10.6% | REGRESS |
| single-day-application-log-heatmap | MEMORY/rss_peak | 35.8 MB | 41.1 MB | +5.3 MB | 14.8% | REGRESS |
| single-day-application-log-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.3 s | 3.6 s | +286 ms | 8.7% | REGRESS |
| single-day-application-log-histogram | MEMORY/rss_peak | 35.8 MB | 41.2 MB | +5.4 MB | 15.1% | REGRESS |
| single-day-application-log-heatmap-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.3 s | 3.6 s | +337 ms | 10.3% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 35.9 MB | 41 MB | +5.1 MB | 14.2% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 6.3 s | 6.4 s | +80 ms | 1.3% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 123.1 MB | 130.5 MB | +7.3 MB | 6.0% | REGRESS |
| single-day-application-log-sort-p99 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/total | 3.3 s | 3.6 s | +296 ms | 8.9% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY/rss_peak | 36.0 MB | 41.6 MB | +5.6 MB | 15.7% | REGRESS |
| single-day-application-log-sort-skewness | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/total | 3.3 s | 3.6 s | +335 ms | 10.2% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY/rss_peak | 36.2 MB | 41.1 MB | +4.9 MB | 13.6% | REGRESS |
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 7.2 s | 8.0 s | +774 ms | 10.8% | REGRESS |
| multi-day-application-logs-standard | MEMORY/rss_peak | 94.5 MB | 106 MB | +11.6 MB | 12.3% | REGRESS |
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 7.2 s | 7.9 s | +740 ms | 10.3% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 95.1 MB | 106.0 MB | +10.8 MB | 11.4% | REGRESS |
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 43.0 s | 39.8 s | -3.2 s | -7.4% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 212.6 MB | 215.7 MB | +3.1 MB | 1.4% | REGRESS |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 7.1 s | 7.9 s | +748 ms | 10.5% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 94.5 MB | 106 MB | +11.5 MB | 12.2% | REGRESS |
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 7.4 s | 7.9 s | +510 ms | 6.9% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 95.5 MB | 106.2 MB | +10.7 MB | 11.2% | REGRESS |
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 7.3 s | 7.8 s | +552 ms | 7.6% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 95.1 MB | 106.7 MB | +11.6 MB | 12.2% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 42.6 s | 39.8 s | -2.9 s | -6.8% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 215.4 MB | 217.2 MB | +1.8 MB | 0.9% | REGRESS |
| multi-day-application-logs-sort-p99 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/total | 7.2 s | 7.8 s | +613 ms | 8.5% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY/rss_peak | 95.5 MB | 106.7 MB | +11.2 MB | 11.7% | REGRESS |
| multi-day-application-logs-sort-skewness | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/total | 7.3 s | 7.8 s | +569 ms | 7.8% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY/rss_peak | 95.5 MB | 106.2 MB | +10.7 MB | 11.2% | REGRESS |
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 16.1 s | 16.4 s | +330 ms | 2.0% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 194.4 MB | 203.1 MB | +8.7 MB | 4.5% | REGRESS |
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 16.1 s | 16.3 s | +215 ms | 1.3% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 195 MB | 206.4 MB | +11.4 MB | 5.8% | REGRESS |
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 55.1 s | 51.8 s | -3.3 s | -5.9% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 244.5 MB | 253.4 MB | +8.9 MB | 3.6% | REGRESS |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 16.4 s | 16.9 s | +538 ms | 3.3% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 178.8 MB | 191.9 MB | +13.1 MB | 7.3% | REGRESS |
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 16.8 s | 17.3 s | +509 ms | 3.0% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 194.4 MB | 203.3 MB | +8.9 MB | 4.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 17.1 s | 17.6 s | +437 ms | 2.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 179.5 MB | 190.4 MB | +10.9 MB | 6.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 55.7 s | 52.7 s | -3.0 s | -5.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 233.8 MB | 244.7 MB | +10.9 MB | 4.7% | REGRESS |
| multi-day-custom-logs-sort-p99 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/total | 16.0 s | 16.4 s | +485 ms | 3.0% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY/rss_peak | 191.9 MB | 200.3 MB | +8.4 MB | 4.4% | REGRESS |
| multi-day-custom-logs-sort-skewness | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/total | 16 s | 16.5 s | +499 ms | 3.1% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY/rss_peak | 192.2 MB | 200.7 MB | +8.5 MB | 4.4% | REGRESS |
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 9 s | 8.9 s | -102 ms | -1.1% | IMPROVE |
| single-day-access-log-standard | MEMORY/rss_peak | 142.8 MB | 150.5 MB | +7.7 MB | 5.4% | REGRESS |
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 9.2 s | 8.9 s | -227 ms | -2.5% | IMPROVE |
| single-day-access-log-top25 | MEMORY/rss_peak | 146.0 MB | 152.9 MB | +6.9 MB | 4.7% | REGRESS |
| single-day-access-log-top25-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 15.2 s | 14.5 s | -726 ms | -4.8% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 181.2 MB | 189.0 MB | +7.7 MB | 4.3% | REGRESS |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 9.6 s | 9.6 s | -68 ms | -0.7% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/rss_peak | 116.4 MB | 123 MB | +6.6 MB | 5.7% | REGRESS |
| single-day-access-log-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 10.8 s | 10.9 s | +56 ms | 0.5% | REGRESS |
| single-day-access-log-histogram | MEMORY/rss_peak | 144.2 MB | 152.2 MB | +8 MB | 5.5% | REGRESS |
| single-day-access-log-heatmap-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 11.3 s | 11.3 s | +17 ms | 0.2% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 116.5 MB | 122.5 MB | +6.1 MB | 5.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 15.6 s | 15.6 s | -44 ms | -0.3% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 154.9 MB | 163.1 MB | +8.2 MB | 5.3% | REGRESS |
| single-day-access-log-sort-p99 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/total | 8.8 s | 8.9 s | +55 ms | 0.6% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY/rss_peak | 144.6 MB | 150.9 MB | +6.3 MB | 4.4% | REGRESS |
| single-day-access-log-sort-skewness | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/total | 9.0 s | 9 s | +44 ms | 0.5% | REGRESS |
| single-day-access-log-sort-skewness | MEMORY/rss_peak | 150.4 MB | 157.3 MB | +6.9 MB | 4.6% | REGRESS |
| month-single-server-access-logs-standard | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_included | 7,749,167 | 7,749,159 | -8 | -0.0% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/total | 1.7 min | 1.7 min | -298 ms | -0.3% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2.4 GB | 2.6 GB | +194.1 MB | 8.0% | REGRESS |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_included | 7,749,167 | 7,749,159 | -8 | -0.0% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/total | 1.7 min | 1.7 min | +622 ms | 0.6% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2.4 GB | 2.6 GB | +208.5 MB | 8.6% | REGRESS |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,167 | 7,749,159 | -8 | -0.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 4.1 min | 3.9 min | -12.2 s | -4.9% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 1.4 GB | 1.4 GB | +6.5 MB | 0.5% | REGRESS |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,167 | 7,749,159 | -8 | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/total | 1.8 min | 1.8 min | -1.4 s | -1.3% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 1.9 GB | 2.1 GB | +208.3 MB | 10.5% | REGRESS |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_included | 7,749,167 | 7,749,159 | -8 | -0.0% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/total | 2.1 min | 2.1 min | -2.9 s | -2.3% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 2.4 GB | 2.6 GB | +207.2 MB | 8.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,167 | 7,749,159 | -8 | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.2 min | 2.1 min | -4.5 s | -3.4% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 1.9 GB | 2.1 GB | +200.5 MB | 10.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,167 | 7,749,159 | -8 | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 4.1 min | 3.9 min | -14.8 s | -6.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 1.1 GB | 1.1 GB | +5.1 MB | 0.5% | REGRESS |
| month-single-server-access-logs-sort-p99 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | lines_included | 7,749,167 | 7,749,159 | -8 | -0.0% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/total | 1.8 min | 1.8 min | -3.1 s | -2.9% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/rss_peak | 2.4 GB | 2.6 GB | +213.1 MB | 8.6% | REGRESS |
| month-single-server-access-logs-sort-skewness | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | lines_included | 7,749,167 | 7,749,159 | -8 | -0.0% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/total | 1.8 min | 1.7 min | -2.4 s | -2.3% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/rss_peak | 2.3 GB | 2.5 GB | +268.8 MB | 11.5% | REGRESS |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_included | 38,672,504 | 38,672,411 | -93 | -0.0% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/total | 8.8 min | 8.5 min | -16.4 s | -3.1% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 12.1 GB | 13.1 GB | +982.8 MB | 7.9% | REGRESS |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_included | 38,672,504 | 38,672,411 | -93 | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/total | 8.8 min | 8.6 min | -13.6 s | -2.6% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 12.2 GB | 13.2 GB | +1 GB | 8.2% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,504 | 38,672,411 | -93 | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 27.6 min | 28.7 min | +1 min | 3.8% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 6.4 GB | 6.4 GB | +50.5 MB | 0.8% | REGRESS |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,504 | 38,672,411 | -93 | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/total | 9.0 min | 9.1 min | +6.6 s | 1.2% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 9.7 GB | 10.8 GB | +1 GB | 10.4% | REGRESS |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_included | 38,672,504 | 38,672,411 | -93 | -0.0% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/total | 10.4 min | 10.4 min | +4.7 s | 0.8% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 11.8 GB | 13.1 GB | +1.3 GB | 11.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,504 | 38,672,411 | -93 | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 10.7 min | 10.7 min | +1.9 s | 0.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 9.8 GB | 10.8 GB | +1 GB | 10.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | 38,672,504 | 38,672,411 | -93 | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 25.8 min | 25.9 min | +4.3 s | 0.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 4.3 GB | 4.5 GB | +182.7 MB | 4.1% | REGRESS |
| month-many-servers-access-logs-sort-p99 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | lines_included | 38,672,504 | 38,672,411 | -93 | -0.0% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/total | 9.2 min | 9.3 min | +4.6 s | 0.8% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/rss_peak | 12.4 GB | 13.4 GB | +970.3 MB | 7.6% | REGRESS |
| month-many-servers-access-logs-sort-skewness | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | lines_included | 38,672,504 | 38,672,411 | -93 | -0.0% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/total | 8.7 min | 8.8 min | +6.4 s | 1.2% | REGRESS |
| month-many-servers-access-logs-sort-skewness | MEMORY/rss_peak | 12 GB | 13 GB | +1 GB | 8.4% | REGRESS |
| humungous-log-uniqueness-no-messages | lines_read | N/A | 288,025 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | lines_included | N/A | 288,025 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | TIMING/total | N/A | 1.9 s | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/rss_peak | N/A | 37.6 MB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | lines_read | N/A | 288,025 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | lines_included | N/A | 288,025 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/total | N/A | 1.9 s | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/rss_peak | N/A | 37.1 MB | N/A | N/A | ? |
| single-day-application-log-no-messages | lines_read | N/A | 479,904 | N/A | N/A | ? |
| single-day-application-log-no-messages | lines_included | N/A | 479,904 | N/A | N/A | ? |
| single-day-application-log-no-messages | TIMING/total | N/A | 3.1 s | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/rss_peak | N/A | 37.3 MB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | lines_read | N/A | 479,904 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | lines_included | N/A | 479,904 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | TIMING/total | N/A | 3.1 s | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/rss_peak | N/A | 37.8 MB | N/A | N/A | ? |
| multi-day-application-logs-no-messages | lines_read | N/A | 930,031 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | lines_included | N/A | 930,028 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | TIMING/total | N/A | 6.5 s | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/rss_peak | N/A | 38.7 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | lines_read | N/A | 930,031 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | lines_included | N/A | 930,028 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | TIMING/total | N/A | 6.5 s | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/rss_peak | N/A | 38.3 MB | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | lines_read | N/A | 1,530,399 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | lines_included | N/A | 1,530,399 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | TIMING/total | N/A | 13.1 s | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/rss_peak | N/A | 71.3 MB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | lines_read | N/A | 1,530,399 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | lines_included | N/A | 1,530,399 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/total | N/A | 14.7 s | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/rss_peak | N/A | 75.5 MB | N/A | N/A | ? |
| single-day-access-log-no-messages | lines_read | N/A | 761,698 | N/A | N/A | ? |
| single-day-access-log-no-messages | lines_included | N/A | 761,698 | N/A | N/A | ? |
| single-day-access-log-no-messages | TIMING/total | N/A | 6.9 s | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/rss_peak | N/A | 97.0 MB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | lines_read | N/A | 761,698 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | lines_included | N/A | 761,698 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/total | N/A | 10.0 s | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/rss_peak | N/A | 100.8 MB | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | lines_included | N/A | 7,749,159 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | TIMING/total | N/A | 1.2 min | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/rss_peak | N/A | 649.3 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | lines_included | N/A | 7,749,159 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/total | N/A | 1.8 min | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/rss_peak | N/A | 650.3 MB | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | lines_included | N/A | 38,672,411 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | TIMING/total | N/A | 6.2 min | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/rss_peak | N/A | 3.4 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | lines_included | N/A | 38,672,411 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/total | N/A | 9.2 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/rss_peak | N/A | 3.4 GB | N/A | N/A | ? |

### Detailed

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/detect/registry_build | 8 ms | 12 ms | +4 ms | 50.0% | REGRESS |
| humungous-log-uniqueness-standard | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| humungous-log-uniqueness-standard | TIMING/parse/read_files | 2.2 s | 2.4 s | +208 ms | 9.3% | REGRESS |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics | 340 ms | 312 ms | -28 ms | -8.2% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics/sort_selection | 327 ms | 299 ms | -28 ms | -8.6% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.6 s | 2.8 s | +184 ms | 7.1% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 208.5 MB | 264.3 MB | +55.9 MB | 26.8% | REGRESS |
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
| humungous-log-uniqueness-standard | MEMORY/format_scan_subs | 752 KB | 1.1 MB | +336 KB | 44.7% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/log_messages | 127 MB | 172.9 MB | +45.9 MB | 36.1% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_stats | 120 B | 1.7 KB | +1.6 KB | 1350.8% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/unattributed | 80.7 MB | 90.3 MB | +9.6 MB | 11.9% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY_FINAL/log_messages | 133188237 | 181317607 | 48129370 | 36.1% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
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
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/detect/registry_build | 8 ms | 12 ms | +4 ms | 50.0% | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/parse/read_files | 2.2 s | 2.4 s | +223 ms | 10.2% | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics | 348 ms | 302 ms | -46 ms | -13.2% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics/sort_selection | 335 ms | 289 ms | -46 ms | -13.7% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.6 s | 2.7 s | +180 ms | 7.1% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 209.4 MB | 264.6 MB | +55.2 MB | 26.3% | REGRESS |
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
| humungous-log-uniqueness-top25 | MEMORY/format_scan_subs | 736 KB | 1.2 MB | +464 KB | 63.0% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/log_messages | 127 MB | 172.9 MB | +45.9 MB | 36.1% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_stats | 120 B | 1.7 KB | +1.6 KB | 1350.8% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/message_key_order | 7.7 KB | 7.7 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/unattributed | 81.7 MB | 90.5 MB | +8.8 MB | 10.8% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/log_messages | 133188237 | 181317607 | 48129370 | 36.1% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
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
| humungous-log-uniqueness-top25-consolidate | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | TIMING/parse/read_files | 6.5 s | 6.5 s | -47 ms | -0.7% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | TIMING/finalize/group_similar | 4.4 s | 4.0 s | -435 ms | -9.8% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 11.0 s | 10.5 s | -477 ms | -4.4% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 254.4 MB | 264.7 MB | +10.2 MB | 4.0% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_clusters | 196.2 KB | 196.6 KB | +433 B | 0.2% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_message | 3.1 MB | 3.1 MB | +9.8 KB | 0.3% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_trigrams | 71.7 MB | 71.7 MB | +39.0 KB | 0.1% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 64.2 MB | 64.3 MB | +8.3 KB | 0.0% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_ngram_index | 66.7 MB | 66.7 MB | +50 KB | 0.1% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_patterns | 24.8 KB | 24.6 KB | -210 B | -0.8% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_posting_size | 614.1 KB | 614.1 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | 1.7 MB | -48 B | -0.0% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/format_scan_subs | 768 KB | 1.2 MB | +416 KB | 54.2% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_messages | 2.5 MB | 3.3 MB | +818.5 KB | 31.6% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_stats | 120 B | 1.7 KB | +1.6 KB | 1350.8% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/message_key_order | 9.4 KB | 9.4 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/unattributed | 42.9 MB | 51.8 MB | +8.9 MB | 20.8% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/log_messages | 100953 | 104707 | 3754 | 3.7% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 200881 | 201314 | 433 | 0.2% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 25391 | 25181 | -210 | -0.8% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 240 | 8 | 3.4% | REGRESS |
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
| humungous-log-uniqueness-heatmap | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/parse/read_files | 2.2 s | 2.4 s | +212 ms | 9.6% | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics | 326 ms | 310 ms | -16 ms | -4.9% | IMPROVE |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 313 ms | 298 ms | -15 ms | -4.8% | IMPROVE |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.5 s | 2.7 s | +200 ms | 7.9% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 208.3 MB | 264.5 MB | +56.2 MB | 27.0% | REGRESS |
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
| humungous-log-uniqueness-heatmap | MEMORY/format_scan_subs | 784 KB | 1.2 MB | +480 KB | 61.2% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/log_messages | 127 MB | 172.9 MB | +45.9 MB | 36.1% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_stats | 120 B | 1.7 KB | +1.6 KB | 1350.8% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/unattributed | 80.5 MB | 90.3 MB | +9.8 MB | 12.2% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/log_messages | 133188237 | 181317607 | 48129370 | 36.1% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
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
| humungous-log-uniqueness-histogram | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/parse/read_files | 2.2 s | 2.4 s | +246 ms | 11.3% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics | 357 ms | 315 ms | -42 ms | -11.8% | IMPROVE |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics/sort_selection | 343 ms | 302 ms | -41 ms | -12.0% | IMPROVE |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.5 s | 2.8 s | +209 ms | 8.2% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 209.6 MB | 264.4 MB | +54.8 MB | 26.1% | REGRESS |
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
| humungous-log-uniqueness-histogram | MEMORY/format_scan_subs | 768 KB | 1.2 MB | +432 KB | 56.2% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/log_messages | 127 MB | 172.9 MB | +45.9 MB | 36.1% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_stats | 120 B | 1.7 KB | +1.6 KB | 1350.8% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/unattributed | 81.9 MB | 90.3 MB | +8.4 MB | 10.3% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/log_messages | 133188237 | 181317607 | 48129370 | 36.1% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
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
| humungous-log-uniqueness-heatmap-histogram | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/parse/read_files | 2.2 s | 2.4 s | +207 ms | 9.5% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics | 343 ms | 295 ms | -48 ms | -14.0% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 329 ms | 282 ms | -47 ms | -14.3% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.5 s | 2.7 s | +164 ms | 6.5% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 209.9 MB | 264.2 MB | +54.2 MB | 25.8% | REGRESS |
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
| humungous-log-uniqueness-heatmap-histogram | MEMORY/format_scan_subs | 768 KB | 1 MB | +304 KB | 39.6% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_messages | 127 MB | 172.9 MB | +45.9 MB | 36.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_stats | 120 B | 1.7 KB | +1.6 KB | 1350.8% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/unattributed | 82.2 MB | 90.2 MB | +8 MB | 9.8% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/log_messages | 133188237 | 181317607 | 48129370 | 36.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
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
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/parse/read_files | 6.5 s | 6.4 s | -147 ms | -2.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 4.4 s | 3.8 s | -627 ms | -14.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 10.9 s | 10.2 s | -770 ms | -7.0% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 255.0 MB | 264.2 MB | +9.3 MB | 3.6% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 196.2 KB | 196.6 KB | +433 B | 0.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 3.1 MB | 3.1 MB | +9.8 KB | 0.3% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 71.7 MB | 71.7 MB | +39.0 KB | 0.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 64.2 MB | 64.3 MB | +8.3 KB | 0.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 66.7 MB | 66.7 MB | +37.2 KB | 0.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 24.8 KB | 24.6 KB | -210 B | -0.8% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 614.1 KB | 614.1 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | 1.7 MB | +16 B | 0.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 720 KB | 1.2 MB | +480 KB | 66.7% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_messages | 2.5 MB | 3.3 MB | +818.5 KB | 31.6% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 1.7 KB | +1.6 KB | 1350.8% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/message_key_order | 3.2 KB | 3.2 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/unattributed | 43.5 MB | 51.4 MB | +7.9 MB | 18.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 100953 | 104707 | 3754 | 3.7% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 200881 | 201314 | 433 | 0.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 25391 | 25181 | -210 | -0.8% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 240 | 8 | 3.4% | REGRESS |
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
| humungous-log-uniqueness-sort-p99 | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| humungous-log-uniqueness-sort-p99 | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| humungous-log-uniqueness-sort-p99 | TIMING/parse/read_files | 2.2 s | 2.4 s | +155 ms | 6.9% | REGRESS |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics | 570 ms | 315 ms | -255 ms | -44.7% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 274 ms | 0 us | -274 ms | -100.0% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 283 ms | 302 ms | +19 ms | 6.7% | REGRESS |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/total | 2.8 s | 2.7 s | -97 ms | -3.5% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | MEMORY/rss_peak | 208.2 MB | 264.4 MB | +56.2 MB | 27.0% | REGRESS |
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
| humungous-log-uniqueness-sort-p99 | MEMORY/format_scan_subs | 736 KB | 1 MB | +304 KB | 41.3% | REGRESS |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_messages | 127 MB | 172.9 MB | +45.9 MB | 36.1% | REGRESS |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_stats | 120 B | 1.7 KB | +1.6 KB | 1350.8% | REGRESS |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| humungous-log-uniqueness-sort-p99 | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| humungous-log-uniqueness-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/unattributed | 80.5 MB | 90.4 MB | +10.0 MB | 12.4% | REGRESS |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/log_messages | 133188237 | 181317607 | 48129370 | 36.1% | REGRESS |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
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
| humungous-log-uniqueness-sort-skewness | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| humungous-log-uniqueness-sort-skewness | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| humungous-log-uniqueness-sort-skewness | TIMING/parse/read_files | 2.2 s | 2.4 s | +205 ms | 9.4% | REGRESS |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics | 578 ms | 319 ms | -259 ms | -44.8% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 283 ms | 0 us | -283 ms | -100.0% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 282 ms | 306 ms | +24 ms | 8.5% | REGRESS |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/total | 2.8 s | 2.7 s | -50 ms | -1.8% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | MEMORY/rss_peak | 205.9 MB | 264.2 MB | +58.3 MB | 28.3% | REGRESS |
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
| humungous-log-uniqueness-sort-skewness | MEMORY/format_scan_subs | 768 KB | 1.1 MB | +336 KB | 43.8% | REGRESS |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_messages | 127 MB | 172.9 MB | +45.9 MB | 36.1% | REGRESS |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_stats | 120 B | 1.7 KB | +1.6 KB | 1350.8% | REGRESS |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| humungous-log-uniqueness-sort-skewness | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| humungous-log-uniqueness-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/unattributed | 78.1 MB | 90.2 MB | +12.1 MB | 15.5% | REGRESS |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/log_messages | 133188237 | 181317607 | 48129370 | 36.1% | REGRESS |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
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
| single-day-application-log-standard | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| single-day-application-log-standard | TIMING/detect/scan_sub_compile | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| single-day-application-log-standard | TIMING/parse/read_files | 3.3 s | 3.6 s | +352 ms | 10.8% | REGRESS |
| single-day-application-log-standard | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 5 ms | -1 ms | -16.7% | IMPROVE |
| single-day-application-log-standard | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.3 s | 3.6 s | +355 ms | 10.8% | REGRESS |
| single-day-application-log-standard | MEMORY/rss_peak | 35.8 MB | 41.7 MB | +5.9 MB | 16.4% | REGRESS |
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
| single-day-application-log-standard | MEMORY/format_scan_subs | 720 KB | 1.2 MB | +480 KB | 66.7% | REGRESS |
| single-day-application-log-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-application-log-standard | MEMORY/log_messages | 2.7 MB | 2.8 MB | +41.7 KB | 1.5% | REGRESS |
| single-day-application-log-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_occurrences | 21.8 KB | 21.5 KB | -256 B | -1.1% | IMPROVE |
| single-day-application-log-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_stats | 120 B | 7.9 KB | +7.7 KB | 6600.8% | REGRESS |
| single-day-application-log-standard | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-application-log-standard | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| single-day-application-log-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/unattributed | 32.3 MB | 37.6 MB | +5.3 MB | 16.3% | REGRESS |
| single-day-application-log-standard | MEMORY_FINAL/log_messages | 2872100 | 2914830 | 42730 | 1.5% | REGRESS |
| single-day-application-log-standard | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
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
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| single-day-application-log-top25 | TIMING/detect/scan_sub_compile | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| single-day-application-log-top25 | TIMING/parse/read_files | 3.3 s | 3.6 s | +307 ms | 9.4% | REGRESS |
| single-day-application-log-top25 | TIMING/finalize/calculate_statistics | 7 ms | 7 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/finalize/calculate_statistics/sort_selection | 7 ms | 6 ms | -1 ms | -14.3% | IMPROVE |
| single-day-application-log-top25 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.3 s | 3.6 s | +309 ms | 9.4% | REGRESS |
| single-day-application-log-top25 | MEMORY/rss_peak | 36.1 MB | 41.3 MB | +5.2 MB | 14.3% | REGRESS |
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
| single-day-application-log-top25 | MEMORY/format_scan_subs | 752 KB | 1 MB | +288 KB | 38.3% | REGRESS |
| single-day-application-log-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-application-log-top25 | MEMORY/log_messages | 2.7 MB | 2.8 MB | +41.7 KB | 1.5% | REGRESS |
| single-day-application-log-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_stats | 120 B | 7.9 KB | +7.7 KB | 6600.8% | REGRESS |
| single-day-application-log-top25 | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-application-log-top25 | MEMORY/message_key_order | 6.4 KB | 6.4 KB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| single-day-application-log-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/unattributed | 32.6 MB | 37.4 MB | +4.7 MB | 14.5% | REGRESS |
| single-day-application-log-top25 | MEMORY_FINAL/log_messages | 2872100 | 2914830 | 42730 | 1.5% | REGRESS |
| single-day-application-log-top25 | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
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
| single-day-application-log-top25-consolidate | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| single-day-application-log-top25-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| single-day-application-log-top25-consolidate | TIMING/parse/read_files | 6.0 s | 6.2 s | +168 ms | 2.8% | REGRESS |
| single-day-application-log-top25-consolidate | TIMING/finalize/group_similar | 282 ms | 247 ms | -35 ms | -12.4% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 6.3 s | 6.4 s | +137 ms | 2.2% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 123.3 MB | 130.4 MB | +7.1 MB | 5.7% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_clusters | 437.3 KB | 440.9 KB | +3.7 KB | 0.8% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_message | 2.6 MB | 2.6 MB | +3.5 KB | 0.1% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_trigrams | 29.3 MB | 29.3 MB | +17 KB | 0.1% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 16.4 MB | 16.4 MB | +2 KB | 0.0% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_ngram_index | 29.7 MB | 29.7 MB | +71.4 KB | 0.2% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_patterns | 54.2 KB | 54.3 KB | +180 B | 0.3% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_posting_size | 860.9 KB | 860.9 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_unmatched | 1.5 MB | 1.5 MB | +16 B | 0.0% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/format_scan_subs | 768 KB | 1.1 MB | +336 KB | 43.8% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/log_messages | 2.3 MB | 2.3 MB | +39.1 KB | 1.7% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_occurrences | 21.5 KB | 21.8 KB | +256 B | 1.2% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_stats | 120 B | 7.9 KB | +7.7 KB | 6600.8% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/message_key_order | 12.6 KB | 12.6 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/unattributed | 39.4 MB | 45.9 MB | +6.5 MB | 16.5% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/log_messages | 137524 | 151190 | 13666 | 9.9% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 447749 | 451529 | 3780 | 0.8% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 55464 | 55644 | 180 | 0.3% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 240 | 8 | 3.4% | REGRESS |
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
| single-day-application-log-heatmap | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| single-day-application-log-heatmap | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| single-day-application-log-heatmap | TIMING/parse/read_files | 3.2 s | 3.6 s | +344 ms | 10.6% | REGRESS |
| single-day-application-log-heatmap | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 5 ms | -1 ms | -16.7% | IMPROVE |
| single-day-application-log-heatmap | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.3 s | 3.6 s | +347 ms | 10.6% | REGRESS |
| single-day-application-log-heatmap | MEMORY/rss_peak | 35.8 MB | 41.1 MB | +5.3 MB | 14.8% | REGRESS |
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
| single-day-application-log-heatmap | MEMORY/format_scan_subs | 752 KB | 1.1 MB | +352 KB | 46.8% | REGRESS |
| single-day-application-log-heatmap | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-application-log-heatmap | MEMORY/log_messages | 2.7 MB | 2.8 MB | +41.7 KB | 1.5% | REGRESS |
| single-day-application-log-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_stats | 120 B | 7.9 KB | +7.7 KB | 6600.8% | REGRESS |
| single-day-application-log-heatmap | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-application-log-heatmap | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| single-day-application-log-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/unattributed | 32.3 MB | 37.1 MB | +4.8 MB | 14.9% | REGRESS |
| single-day-application-log-heatmap | MEMORY_FINAL/log_messages | 2872100 | 2914830 | 42730 | 1.5% | REGRESS |
| single-day-application-log-heatmap | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
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
| single-day-application-log-histogram | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| single-day-application-log-histogram | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| single-day-application-log-histogram | TIMING/parse/read_files | 3.3 s | 3.6 s | +283 ms | 8.6% | REGRESS |
| single-day-application-log-histogram | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.3 s | 3.6 s | +286 ms | 8.7% | REGRESS |
| single-day-application-log-histogram | MEMORY/rss_peak | 35.8 MB | 41.2 MB | +5.4 MB | 15.1% | REGRESS |
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
| single-day-application-log-histogram | MEMORY/format_scan_subs | 752 KB | 1.3 MB | +544 KB | 72.3% | REGRESS |
| single-day-application-log-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-application-log-histogram | MEMORY/log_messages | 2.7 MB | 2.8 MB | +41.7 KB | 1.5% | REGRESS |
| single-day-application-log-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_stats | 120 B | 7.9 KB | +7.7 KB | 6600.8% | REGRESS |
| single-day-application-log-histogram | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-application-log-histogram | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| single-day-application-log-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/unattributed | 32.3 MB | 37.1 MB | +4.8 MB | 14.7% | REGRESS |
| single-day-application-log-histogram | MEMORY_FINAL/log_messages | 2872100 | 2914830 | 42730 | 1.5% | REGRESS |
| single-day-application-log-histogram | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
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
| single-day-application-log-heatmap-histogram | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| single-day-application-log-heatmap-histogram | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| single-day-application-log-heatmap-histogram | TIMING/parse/read_files | 3.3 s | 3.6 s | +334 ms | 10.2% | REGRESS |
| single-day-application-log-heatmap-histogram | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 5 ms | -1 ms | -16.7% | IMPROVE |
| single-day-application-log-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.3 s | 3.6 s | +337 ms | 10.3% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 35.9 MB | 41 MB | +5.1 MB | 14.2% | REGRESS |
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
| single-day-application-log-heatmap-histogram | MEMORY/format_scan_subs | 784 KB | 1.1 MB | +304 KB | 38.8% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/log_messages | 2.7 MB | 2.8 MB | +41.7 KB | 1.5% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_occurrences | 21.5 KB | 21.8 KB | +256 B | 1.2% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_stats | 120 B | 7.6 KB | +7.5 KB | 6387.5% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/unattributed | 32.4 MB | 37.1 MB | +4.7 MB | 14.4% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/log_messages | 2872100 | 2914830 | 42730 | 1.5% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
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
| single-day-application-log-heatmap-histogram-consolidate | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/parse/read_files | 6 s | 6.1 s | +117 ms | 1.9% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 288 ms | 249 ms | -39 ms | -13.5% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 6.3 s | 6.4 s | +80 ms | 1.3% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 123.1 MB | 130.5 MB | +7.3 MB | 6.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 437.5 KB | 442.2 KB | +4.7 KB | 1.1% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.6 MB | 2.6 MB | +3.5 KB | 0.1% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 29.3 MB | 29.3 MB | +15 KB | 0.1% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 16.4 MB | 16.4 MB | +2 KB | 0.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 29.7 MB | 29.7 MB | +70 KB | 0.2% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 54.2 KB | 54.3 KB | +180 B | 0.3% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 860.9 KB | 860.9 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.5 MB | 1.5 MB | +16 B | 0.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 800 KB | 1 MB | +256 KB | 32.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_messages | 2.3 MB | 2.3 MB | +39.1 KB | 1.7% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 21.8 KB | 21.5 KB | -256 B | -1.1% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 7.6 KB | +7.5 KB | 6387.5% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/message_key_order | 2.6 KB | 2.6 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/unattributed | 39.2 MB | 46.1 MB | +6.9 MB | 17.5% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 137524 | 151190 | 13666 | 9.9% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 448005 | 452809 | 4804 | 1.1% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 55464 | 55644 | 180 | 0.3% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 240 | 8 | 3.4% | REGRESS |
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
| single-day-application-log-sort-p99 | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| single-day-application-log-sort-p99 | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| single-day-application-log-sort-p99 | TIMING/parse/read_files | 3.3 s | 3.6 s | +294 ms | 8.9% | REGRESS |
| single-day-application-log-sort-p99 | TIMING/finalize/calculate_statistics | 8 ms | 6 ms | -2 ms | -25.0% | IMPROVE |
| single-day-application-log-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 2 ms | 0 us | -2 ms | -100.0% | IMPROVE |
| single-day-application-log-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 5 ms | -1 ms | -16.7% | IMPROVE |
| single-day-application-log-sort-p99 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/total | 3.3 s | 3.6 s | +296 ms | 8.9% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY/rss_peak | 36.0 MB | 41.6 MB | +5.6 MB | 15.7% | REGRESS |
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
| single-day-application-log-sort-p99 | MEMORY/format_scan_subs | 736 KB | 1.2 MB | +480 KB | 65.2% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY/log_messages | 2.7 MB | 2.8 MB | +41.7 KB | 1.5% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_stats | 120 B | 7.9 KB | +7.7 KB | 6600.8% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/unattributed | 32.5 MB | 37.5 MB | +5 MB | 15.5% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY_FINAL/log_messages | 2872100 | 2914830 | 42730 | 1.5% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
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
| single-day-application-log-sort-skewness | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| single-day-application-log-sort-skewness | TIMING/detect/scan_sub_compile | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| single-day-application-log-sort-skewness | TIMING/parse/read_files | 3.3 s | 3.6 s | +333 ms | 10.2% | REGRESS |
| single-day-application-log-sort-skewness | TIMING/finalize/calculate_statistics | 8 ms | 6 ms | -2 ms | -25.0% | IMPROVE |
| single-day-application-log-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 3 ms | 0 us | -3 ms | -100.0% | IMPROVE |
| single-day-application-log-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| single-day-application-log-sort-skewness | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/total | 3.3 s | 3.6 s | +335 ms | 10.2% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY/rss_peak | 36.2 MB | 41.1 MB | +4.9 MB | 13.6% | REGRESS |
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
| single-day-application-log-sort-skewness | MEMORY/format_scan_subs | 752 KB | 1.1 MB | +352 KB | 46.8% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY/log_messages | 2.7 MB | 2.8 MB | +41.7 KB | 1.5% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_stats | 120 B | 7.9 KB | +7.7 KB | 6600.8% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/unattributed | 32.7 MB | 37.1 MB | +4.4 MB | 13.5% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY_FINAL/log_messages | 2872100 | 2914830 | 42730 | 1.5% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
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
| multi-day-application-logs-standard | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| multi-day-application-logs-standard | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| multi-day-application-logs-standard | TIMING/parse/read_files | 7.0 s | 7.8 s | +793 ms | 11.3% | REGRESS |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics | 195 ms | 172 ms | -23 ms | -11.8% | IMPROVE |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 191 ms | 169 ms | -22 ms | -11.5% | IMPROVE |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics/untimed | 4 ms | 3 ms | -1 ms | -25.0% | IMPROVE |
| multi-day-application-logs-standard | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| multi-day-application-logs-standard | TIMING/total | 7.2 s | 8.0 s | +774 ms | 10.8% | REGRESS |
| multi-day-application-logs-standard | MEMORY/rss_peak | 94.5 MB | 106 MB | +11.6 MB | 12.3% | REGRESS |
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
| multi-day-application-logs-standard | MEMORY/format_scan_subs | 720 KB | 1.1 MB | +384 KB | 53.3% | REGRESS |
| multi-day-application-logs-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-application-logs-standard | MEMORY/log_messages | 45.8 MB | 48.9 MB | +3.1 MB | 6.8% | REGRESS |
| multi-day-application-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_stats | 120 B | 17.1 KB | +17.0 KB | 14470.8% | REGRESS |
| multi-day-application-logs-standard | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-application-logs-standard | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| multi-day-application-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/unattributed | 47.9 MB | 55.9 MB | +8 MB | 16.7% | REGRESS |
| multi-day-application-logs-standard | MEMORY_FINAL/log_messages | 48030790 | 51302480 | 3271690 | 6.8% | REGRESS |
| multi-day-application-logs-standard | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
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
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| multi-day-application-logs-top25 | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| multi-day-application-logs-top25 | TIMING/parse/read_files | 6.9 s | 7.7 s | +767 ms | 11.1% | REGRESS |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics | 205 ms | 175 ms | -30 ms | -14.6% | IMPROVE |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 203 ms | 173 ms | -30 ms | -14.8% | IMPROVE |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| multi-day-application-logs-top25 | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| multi-day-application-logs-top25 | TIMING/total | 7.2 s | 7.9 s | +740 ms | 10.3% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 95.1 MB | 106.0 MB | +10.8 MB | 11.4% | REGRESS |
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
| multi-day-application-logs-top25 | MEMORY/format_scan_subs | 720 KB | 1.1 MB | +432 KB | 60.0% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/log_messages | 45.8 MB | 48.9 MB | +3.1 MB | 6.8% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_stats | 120 B | 17.1 KB | +17.0 KB | 14470.8% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/message_key_order | 6.5 KB | 6.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/unattributed | 48.6 MB | 55.8 MB | +7.2 MB | 14.9% | REGRESS |
| multi-day-application-logs-top25 | MEMORY_FINAL/log_messages | 48030790 | 51302480 | 3271690 | 6.8% | REGRESS |
| multi-day-application-logs-top25 | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
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
| multi-day-application-logs-top25-consolidate | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/parse/read_files | 38.3 s | 35.8 s | -2.5 s | -6.5% | IMPROVE |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/group_similar | 4.7 s | 4.0 s | -699 ms | -14.9% | IMPROVE |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 3 ms | 2 ms | -1 ms | -33.3% | IMPROVE |
| multi-day-application-logs-top25-consolidate | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 43.0 s | 39.8 s | -3.2 s | -7.4% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 212.6 MB | 215.7 MB | +3.1 MB | 1.4% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_clusters | 3.6 MB | 3.6 MB | -14.6 KB | -0.4% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_message | 3.5 MB | 3.5 MB | -3 KB | -0.1% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 62.2 MB | 62.1 MB | -135.8 KB | -0.2% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 10.4 MB | 10.4 MB | +5.2 KB | 0.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 60.8 MB | 60.6 MB | -127.0 KB | -0.2% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_patterns | 485.7 KB | 485.8 KB | +84 B | 0.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_posting_size | 1.6 MB | 1.6 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_unmatched | 2.1 MB | 2.1 MB | -3.3 KB | -0.2% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/format_scan_subs | 784 KB | 1.1 MB | +304 KB | 38.8% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/log_messages | 3.2 MB | 3.3 MB | +135.9 KB | 4.2% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_stats | 120 B | 17.1 KB | +17.0 KB | 14470.8% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/message_key_order | 5.7 KB | 5.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/unattributed | 63.8 MB | 66.7 MB | +2.9 MB | 4.5% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_messages | 726422 | 758060 | 31638 | 4.4% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 3738228 | 3723254 | -14974 | -0.4% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 497330 | 497416 | 86 | 0.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 240 | 8 | 3.4% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 8248 | 8248 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_messages_entries | 1304 | 1303 | -1 | -0.1% | IMPROVE |
| multi-day-application-logs-top25-consolidate | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_messages_population | 1304 | 1303 | -1 | -0.1% | IMPROVE |
| multi-day-application-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | 40 | 40 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/parse/read_files | 6.9 s | 7.7 s | +762 ms | 11.0% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics | 191 ms | 173 ms | -18 ms | -9.4% | IMPROVE |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 189 ms | 170 ms | -19 ms | -10.1% | IMPROVE |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/total | 7.1 s | 7.9 s | +748 ms | 10.5% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 94.5 MB | 106 MB | +11.5 MB | 12.2% | REGRESS |
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
| multi-day-application-logs-heatmap | MEMORY/format_scan_subs | 768 KB | 1.1 MB | +320 KB | 41.7% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/log_messages | 45.8 MB | 48.9 MB | +3.1 MB | 6.8% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_stats | 120 B | 17.1 KB | +17.0 KB | 14470.8% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/unattributed | 47.9 MB | 55.9 MB | +8.0 MB | 16.7% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY_FINAL/log_messages | 48030790 | 51302480 | 3271690 | 6.8% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
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
| multi-day-application-logs-histogram | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| multi-day-application-logs-histogram | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| multi-day-application-logs-histogram | TIMING/parse/read_files | 7.1 s | 7.7 s | +541 ms | 7.6% | REGRESS |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics | 209 ms | 173 ms | -36 ms | -17.2% | IMPROVE |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 205 ms | 170 ms | -35 ms | -17.1% | IMPROVE |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| multi-day-application-logs-histogram | TIMING/total | 7.4 s | 7.9 s | +510 ms | 6.9% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 95.5 MB | 106.2 MB | +10.7 MB | 11.2% | REGRESS |
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
| multi-day-application-logs-histogram | MEMORY/format_scan_subs | 736 KB | 1.1 MB | +368 KB | 50.0% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/log_messages | 45.8 MB | 48.9 MB | +3.1 MB | 6.8% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_stats | 120 B | 17.1 KB | +17.0 KB | 14470.8% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/unattributed | 48.9 MB | 56 MB | +7.1 MB | 14.6% | REGRESS |
| multi-day-application-logs-histogram | MEMORY_FINAL/log_messages | 48030790 | 51302480 | 3271690 | 6.8% | REGRESS |
| multi-day-application-logs-histogram | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
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
| multi-day-application-logs-heatmap-histogram | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/parse/read_files | 7 s | 7.6 s | +585 ms | 8.3% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 210 ms | 173 ms | -37 ms | -17.6% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 206 ms | 171 ms | -35 ms | -17.0% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 7.3 s | 7.8 s | +552 ms | 7.6% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 95.1 MB | 106.7 MB | +11.6 MB | 12.2% | REGRESS |
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
| multi-day-application-logs-heatmap-histogram | MEMORY/format_scan_subs | 736 KB | 1.2 MB | +480 KB | 65.2% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_messages | 45.8 MB | 48.9 MB | +3.1 MB | 6.8% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_occurrences | 56.7 KB | 56.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_stats | 120 B | 17.1 KB | +17.0 KB | 14470.8% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/unattributed | 48.5 MB | 56.5 MB | +7.9 MB | 16.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 48030790 | 51302480 | 3271690 | 6.8% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
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
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 9 ms | 11 ms | +2 ms | 22.2% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 38.0 s | 35.7 s | -2.2 s | -5.9% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 4.7 s | 4 s | -654 ms | -14.1% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 3 ms | 2 ms | -1 ms | -33.3% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 42.6 s | 39.8 s | -2.9 s | -6.8% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 215.4 MB | 217.2 MB | +1.8 MB | 0.9% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 3.6 MB | 3.6 MB | -14.6 KB | -0.4% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 3.5 MB | 3.5 MB | -3 KB | -0.1% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 62.2 MB | 62.1 MB | -134.8 KB | -0.2% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 10.4 MB | 10.4 MB | +5.2 KB | 0.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 60.8 MB | 60.6 MB | -185.5 KB | -0.3% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 485.7 KB | 485.8 KB | +84 B | 0.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 1.6 MB | 1.6 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 2.1 MB | 2.1 MB | -3.3 KB | -0.2% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 704 KB | 1.2 MB | +512 KB | 72.7% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 3.2 MB | 3.3 MB | +135.9 KB | 4.2% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 17.1 KB | +17.0 KB | 14470.8% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 3 KB | 3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/unattributed | 66.7 MB | 68.2 MB | +1.5 MB | 2.2% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 726422 | 758060 | 31638 | 4.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 3738228 | 3723254 | -14974 | -0.4% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 497330 | 497416 | 86 | 0.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 240 | 8 | 3.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 8248 | 8248 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 1304 | 1303 | -1 | -0.1% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | 1304 | 1303 | -1 | -0.1% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | 40 | 40 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| multi-day-application-logs-sort-p99 | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| multi-day-application-logs-sort-p99 | TIMING/parse/read_files | 6.9 s | 7.6 s | +694 ms | 10.0% | REGRESS |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics | 259 ms | 173 ms | -86 ms | -33.2% | IMPROVE |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 82 ms | 0 us | -82 ms | -100.0% | IMPROVE |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 175 ms | 170 ms | -5 ms | -2.9% | IMPROVE |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| multi-day-application-logs-sort-p99 | TIMING/total | 7.2 s | 7.8 s | +613 ms | 8.5% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY/rss_peak | 95.5 MB | 106.7 MB | +11.2 MB | 11.7% | REGRESS |
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
| multi-day-application-logs-sort-p99 | MEMORY/format_scan_subs | 720 KB | 1.1 MB | +448 KB | 62.2% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY/log_messages | 45.8 MB | 48.9 MB | +3.1 MB | 6.8% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_occurrences | 56.7 KB | 56.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_stats | 120 B | 17.1 KB | +17.0 KB | 14470.8% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/unattributed | 48.9 MB | 56.5 MB | +7.6 MB | 15.5% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/log_messages | 48030790 | 51302480 | 3271690 | 6.8% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
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
| multi-day-application-logs-sort-skewness | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| multi-day-application-logs-sort-skewness | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| multi-day-application-logs-sort-skewness | TIMING/parse/read_files | 7.0 s | 7.6 s | +649 ms | 9.3% | REGRESS |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics | 262 ms | 177 ms | -85 ms | -32.4% | IMPROVE |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 82 ms | 0 us | -82 ms | -100.0% | IMPROVE |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 177 ms | 174 ms | -3 ms | -1.7% | IMPROVE |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| multi-day-application-logs-sort-skewness | TIMING/total | 7.3 s | 7.8 s | +569 ms | 7.8% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY/rss_peak | 95.5 MB | 106.2 MB | +10.7 MB | 11.2% | REGRESS |
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
| multi-day-application-logs-sort-skewness | MEMORY/format_scan_subs | 752 KB | 1 MB | +288 KB | 38.3% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_analysis | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY/log_messages | 45.8 MB | 48.9 MB | +3.1 MB | 6.8% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_occurrences | 56.7 KB | 56.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_stats | 120 B | 17.1 KB | +17.0 KB | 14470.8% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/unattributed | 48.9 MB | 56.1 MB | +7.3 MB | 14.9% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/log_messages | 48030790 | 51302480 | 3271690 | 6.8% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/log_analysis | 232 | 240 | 8 | 3.4% | REGRESS |
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
| multi-day-custom-logs-standard | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| multi-day-custom-logs-standard | TIMING/detect/scan_sub_compile | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| multi-day-custom-logs-standard | TIMING/parse/read_files | 15.7 s | 16.1 s | +383 ms | 2.4% | REGRESS |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics | 418 ms | 363 ms | -55 ms | -13.2% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/bucket_stats | 59 ms | 50 ms | -9 ms | -15.3% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 348 ms | 302 ms | -46 ms | -13.2% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/group_calc | 4 ms | 3 ms | -1 ms | -25.0% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/untimed | 8 ms | 7 ms | -1 ms | -12.5% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 16.1 s | 16.4 s | +330 ms | 2.0% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 194.4 MB | 203.1 MB | +8.7 MB | 4.5% | REGRESS |
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
| multi-day-custom-logs-standard | MEMORY/format_scan_subs | 752 KB | 1.1 MB | +400 KB | 53.2% | REGRESS |
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
| multi-day-custom-logs-standard | MEMORY/log_messages | 103.0 MB | 104.9 MB | +2.0 MB | 1.9% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_stats | 39.8 KB | 55 KB | +15.2 KB | 38.3% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/unattributed | 62.2 MB | 68.5 MB | +6.3 MB | 10.2% | REGRESS |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_messages | 107966084 | 110035334 | 2069250 | 1.9% | REGRESS |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_analysis | 20342 | 20350 | 8 | 0.0% | REGRESS |
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
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/parse/read_files | 15.7 s | 15.9 s | +268 ms | 1.7% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics | 433 ms | 377 ms | -56 ms | -12.9% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 59 ms | 50 ms | -9 ms | -15.3% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 355 ms | 310 ms | -45 ms | -12.7% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/group_calc | 11 ms | 9 ms | -2 ms | -18.2% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 8 ms | 8 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 16.1 s | 16.3 s | +215 ms | 1.3% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 195 MB | 206.4 MB | +11.4 MB | 5.8% | REGRESS |
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
| multi-day-custom-logs-top25 | MEMORY/format_scan_subs | 736 KB | 1.2 MB | +496 KB | 67.4% | REGRESS |
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
| multi-day-custom-logs-top25 | MEMORY/log_messages | 103.0 MB | 105.4 MB | +2.4 MB | 2.4% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_stats | 39.8 KB | 55 KB | +15.2 KB | 38.3% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/unattributed | 62.8 MB | 71.2 MB | +8.4 MB | 13.4% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_messages | 107975804 | 110541678 | 2565874 | 2.4% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_analysis | 20342 | 20350 | 8 | 0.0% | REGRESS |
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
| multi-day-custom-logs-top25-consolidate | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/detect/scan_sub_compile | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/parse/read_files | 49.8 s | 47.1 s | -2.7 s | -5.4% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/group_similar | 5.1 s | 4.5 s | -554 ms | -10.9% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 293 ms | 253 ms | -40 ms | -13.7% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 138 ms | 115 ms | -23 ms | -16.7% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 154 ms | 137 ms | -17 ms | -11.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 55.1 s | 51.8 s | -3.3 s | -5.9% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 244.5 MB | 253.4 MB | +8.9 MB | 3.6% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_clusters | 29.5 MB | 29.6 MB | +21.6 KB | 0.1% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_message | 5.8 MB | 5.8 MB | +24.8 KB | 0.4% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 62.6 MB | 62.6 MB | +75.4 KB | 0.1% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 4.5 MB | 4.5 MB | +2.3 KB | 0.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 61.3 MB | 61.3 MB | +44.0 KB | 0.1% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_patterns | 202.1 KB | 202.8 KB | +794 B | 0.4% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_posting_size | 478.1 KB | 478.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_unmatched | 3.3 MB | 3.3 MB | +16 B | 0.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/format_scan_subs | 816 KB | 1.1 MB | +304 KB | 37.3% | REGRESS |
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
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages | 28.6 MB | 28.7 MB | +43.1 KB | 0.1% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_stats | 39.8 KB | 55 KB | +15.2 KB | 38.3% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/message_key_order | 6.1 KB | 6.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/unattributed | 18.9 MB | 27.3 MB | +8.4 MB | 44.1% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_messages | 30005802 | 30049900 | 44098 | 0.1% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 20342 | 20350 | 8 | 0.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 30969940 | 30992062 | 22122 | 0.1% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 206903 | 207697 | 794 | 0.4% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 240 | 8 | 3.4% | REGRESS |
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
| multi-day-custom-logs-heatmap | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/parse/read_files | 16 s | 16.6 s | +554 ms | 3.5% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics | 362 ms | 309 ms | -53 ms | -14.6% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 349 ms | 299 ms | -50 ms | -14.3% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/group_calc | 5 ms | 4 ms | -1 ms | -20.0% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 8 ms | 6 ms | -2 ms | -25.0% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/finalize/heatmap_statistics | 16 ms | 49 ms | +33 ms | 206.2% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 16.4 s | 16.9 s | +538 ms | 3.3% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 178.8 MB | 191.9 MB | +13.1 MB | 7.3% | REGRESS |
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
| multi-day-custom-logs-heatmap | MEMORY/format_scan_subs | 704 KB | 1.2 MB | +512 KB | 72.7% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters | 983.4 KB | 985.8 KB | +2.3 KB | 0.2% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters_hl | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data | 43.6 KB | 42.4 KB | -1.2 KB | -2.9% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_analysis | 20.9 KB | 20.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_messages | 102.5 MB | 104.9 MB | +2.4 MB | 2.4% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_stats | 28.2 KB | 35.5 KB | +7.3 KB | 26.0% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/unattributed | 74.6 MB | 84.7 MB | +10.1 MB | 13.6% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_messages | 107470852 | 110035334 | 2564482 | 2.4% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_analysis | 20342 | 20350 | 8 | 0.0% | REGRESS |
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
| multi-day-custom-logs-histogram | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/detect/scan_sub_compile | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/parse/read_files | 16.3 s | 16.9 s | +557 ms | 3.4% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics | 429 ms | 366 ms | -63 ms | -14.7% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 60 ms | 51 ms | -9 ms | -15.0% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 356 ms | 304 ms | -52 ms | -14.6% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/group_calc | 4 ms | 3 ms | -1 ms | -25.0% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 8 ms | 7 ms | -1 ms | -12.5% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/finalize/histogram_statistics | 4 ms | 14 ms | +10 ms | 250.0% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 16.8 s | 17.3 s | +509 ms | 3.0% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 194.4 MB | 203.3 MB | +8.9 MB | 4.6% | REGRESS |
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
| multi-day-custom-logs-histogram | MEMORY/format_scan_subs | 800 KB | 1.1 MB | +336 KB | 42.0% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/histogram_counters | 122.1 KB | 122.5 KB | +380 B | 0.3% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_analysis | 28.4 MB | 28.4 MB | +256 B | 0.0% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/log_messages | 102.5 MB | 104.9 MB | +2.4 MB | 2.4% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_stats | 39.6 KB | 55 KB | +15.5 KB | 39.1% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/unattributed | 62.5 MB | 68.6 MB | +6.1 MB | 9.8% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY_FINAL/log_messages | 107470852 | 110035334 | 2564482 | 2.4% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY_FINAL/log_analysis | 20086 | 20350 | 264 | 1.3% | REGRESS |
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
| multi-day-custom-logs-heatmap-histogram | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/parse/read_files | 16.7 s | 17.2 s | +415 ms | 2.5% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 345 ms | 318 ms | -27 ms | -7.8% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 333 ms | 308 ms | -25 ms | -7.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 5 ms | 4 ms | -1 ms | -20.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 7 ms | 6 ms | -1 ms | -14.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/heatmap_statistics | 15 ms | 50 ms | +35 ms | 233.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/histogram_statistics | 4 ms | 14 ms | +10 ms | 250.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 17.1 s | 17.6 s | +437 ms | 2.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 179.5 MB | 190.4 MB | +10.9 MB | 6.1% | REGRESS |
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
| multi-day-custom-logs-heatmap-histogram | MEMORY/format_scan_subs | 784 KB | 1.2 MB | +432 KB | 55.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_counters | 981.9 KB | 985.8 KB | +3.8 KB | 0.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data | 40 KB | 43.4 KB | +3.4 KB | 8.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters | 121.9 KB | 122.5 KB | +572 B | 0.5% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_analysis | 20.9 KB | 20.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages | 102.5 MB | 105.4 MB | +2.9 MB | 2.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_stats | 28.2 KB | 35.5 KB | +7.3 KB | 26.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/unattributed | 75 MB | 82.6 MB | +7.6 MB | 10.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 107470852 | 110530758 | 3059906 | 2.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 20342 | 20350 | 8 | 0.0% | REGRESS |
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
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 50.7 s | 48.3 s | -2.4 s | -4.7% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 4.8 s | 4.2 s | -589 ms | -12.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 142 ms | 123 ms | -19 ms | -13.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 141 ms | 121 ms | -20 ms | -14.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 20 ms | 53 ms | +33 ms | 165.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 4 ms | 15 ms | +11 ms | 275.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 55.7 s | 52.7 s | -3.0 s | -5.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 233.8 MB | 244.7 MB | +10.9 MB | 4.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 29.5 MB | 29.6 MB | +29.1 KB | 0.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 5.8 MB | 5.8 MB | +24.8 KB | 0.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 62.6 MB | 62.6 MB | +37.4 KB | 0.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 4.5 MB | 4.5 MB | +2.3 KB | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 61.3 MB | 61.3 MB | +40.2 KB | 0.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 202.1 KB | 202.8 KB | +794 B | 0.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 478.1 KB | 478.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 3.3 MB | 3.3 MB | +16 B | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 752 KB | 1.2 MB | +480 KB | 63.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 981.9 KB | 985.8 KB | +3.8 KB | 0.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 43.3 KB | 43.6 KB | +256 B | 0.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 121.9 KB | 122.5 KB | +572 B | 0.5% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 20.9 KB | 20.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 28.6 MB | 28.7 MB | +45.5 KB | 0.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 28.2 KB | 35.5 KB | +7.3 KB | 26.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 2.7 KB | 2.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/unattributed | 35.6 MB | 45.8 MB | +10.2 MB | 28.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 29998906 | 30045532 | 46626 | 0.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 20342 | 20350 | 8 | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 30969940 | 30999742 | 29802 | 0.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 206903 | 207697 | 794 | 0.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 240 | 8 | 3.4% | REGRESS |
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
| multi-day-custom-logs-sort-p99 | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| multi-day-custom-logs-sort-p99 | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| multi-day-custom-logs-sort-p99 | TIMING/parse/read_files | 15.6 s | 16.2 s | +527 ms | 3.4% | REGRESS |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics | 313 ms | 267 ms | -46 ms | -14.7% | IMPROVE |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 60 ms | 51 ms | -9 ms | -15.0% | IMPROVE |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 241 ms | 205 ms | -36 ms | -14.9% | IMPROVE |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 9 ms | 8 ms | -1000 us | -11.1% | IMPROVE |
| multi-day-custom-logs-sort-p99 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/total | 16.0 s | 16.4 s | +485 ms | 3.0% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY/rss_peak | 191.9 MB | 200.3 MB | +8.4 MB | 4.4% | REGRESS |
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
| multi-day-custom-logs-sort-p99 | MEMORY/format_scan_subs | 784 KB | 1.1 MB | +336 KB | 42.9% | REGRESS |
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
| multi-day-custom-logs-sort-p99 | MEMORY/log_messages | 102.5 MB | 105.4 MB | +2.9 MB | 2.8% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_stats | 39.8 KB | 55 KB | +15.2 KB | 38.3% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY/message_key_order | 2.7 KB | 2.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/unattributed | 60.1 MB | 65.2 MB | +5.1 MB | 8.5% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/log_messages | 107471628 | 110531486 | 3059858 | 2.8% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/log_analysis | 20342 | 20350 | 8 | 0.0% | REGRESS |
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
| multi-day-custom-logs-sort-skewness | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| multi-day-custom-logs-sort-skewness | TIMING/detect/scan_sub_compile | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| multi-day-custom-logs-sort-skewness | TIMING/parse/read_files | 15.6 s | 16.2 s | +543 ms | 3.5% | REGRESS |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics | 388 ms | 341 ms | -47 ms | -12.1% | IMPROVE |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 59 ms | 50 ms | -9 ms | -15.3% | IMPROVE |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 310 ms | 273 ms | -37 ms | -11.9% | IMPROVE |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 8 ms | 7 ms | -1 ms | -12.5% | IMPROVE |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 8 ms | 8 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/total | 16 s | 16.5 s | +499 ms | 3.1% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY/rss_peak | 192.2 MB | 200.7 MB | +8.5 MB | 4.4% | REGRESS |
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
| multi-day-custom-logs-sort-skewness | MEMORY/format_scan_subs | 784 KB | 1.1 MB | +352 KB | 44.9% | REGRESS |
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
| multi-day-custom-logs-sort-skewness | MEMORY/log_messages | 103.0 MB | 105.1 MB | +2.1 MB | 2.0% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_stats | 39.8 KB | 55 KB | +15.2 KB | 38.3% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY/message_key_order | 2.5 KB | 2.5 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/unattributed | 60.0 MB | 66.0 MB | +6.0 MB | 10.0% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/log_messages | 107968305 | 110165699 | 2197394 | 2.0% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/log_analysis | 20342 | 20350 | 8 | 0.0% | REGRESS |
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
| single-day-access-log-standard | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| single-day-access-log-standard | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| single-day-access-log-standard | TIMING/parse/read_files | 8.8 s | 8.8 s | -83 ms | -0.9% | IMPROVE |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics | 155 ms | 132 ms | -23 ms | -14.8% | IMPROVE |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/bucket_stats | 102 ms | 88 ms | -14 ms | -13.7% | IMPROVE |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 5 ms | -1 ms | -16.7% | IMPROVE |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/group_calc | 47 ms | 39 ms | -8 ms | -17.0% | IMPROVE |
| single-day-access-log-standard | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 9 s | 8.9 s | -102 ms | -1.1% | IMPROVE |
| single-day-access-log-standard | MEMORY/rss_peak | 142.8 MB | 150.5 MB | +7.7 MB | 5.4% | REGRESS |
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
| single-day-access-log-standard | MEMORY/format_scan_subs | 672 KB | 1.2 MB | +512 KB | 76.2% | REGRESS |
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
| single-day-access-log-standard | MEMORY/log_messages | 55.4 MB | 55.9 MB | +523.8 KB | 0.9% | REGRESS |
| single-day-access-log-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_stats | 22.5 KB | 30.5 KB | +8.0 KB | 35.3% | REGRESS |
| single-day-access-log-standard | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-access-log-standard | MEMORY/message_key_order | 1.8 KB | 1.8 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| single-day-access-log-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/unattributed | 34 MB | 40.7 MB | +6.7 MB | 19.6% | REGRESS |
| single-day-access-log-standard | MEMORY_FINAL/log_messages | 58114072 | 58650402 | 536330 | 0.9% | REGRESS |
| single-day-access-log-standard | MEMORY_FINAL/log_analysis | 6670 | 6678 | 8 | 0.1% | REGRESS |
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
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| single-day-access-log-top25 | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| single-day-access-log-top25 | TIMING/parse/read_files | 9.0 s | 8.8 s | -196 ms | -2.2% | IMPROVE |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics | 180 ms | 146 ms | -34 ms | -18.9% | IMPROVE |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 106 ms | 88 ms | -18 ms | -17.0% | IMPROVE |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/group_calc | 68 ms | 52 ms | -16 ms | -23.5% | IMPROVE |
| single-day-access-log-top25 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 9.2 s | 8.9 s | -227 ms | -2.5% | IMPROVE |
| single-day-access-log-top25 | MEMORY/rss_peak | 146.0 MB | 152.9 MB | +6.9 MB | 4.7% | REGRESS |
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
| single-day-access-log-top25 | MEMORY/format_scan_subs | 752 KB | 1.1 MB | +416 KB | 55.3% | REGRESS |
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
| single-day-access-log-top25 | MEMORY/log_messages | 55.2 MB | 55.9 MB | +721.9 KB | 1.3% | REGRESS |
| single-day-access-log-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_stats | 22.5 KB | 30.5 KB | +8.0 KB | 35.3% | REGRESS |
| single-day-access-log-top25 | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-access-log-top25 | MEMORY/message_key_order | 3.9 KB | 3.9 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| single-day-access-log-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/unattributed | 37.3 MB | 43.1 MB | +5.8 MB | 15.6% | REGRESS |
| single-day-access-log-top25 | MEMORY_FINAL/log_messages | 57922368 | 58661562 | 739194 | 1.3% | REGRESS |
| single-day-access-log-top25 | MEMORY_FINAL/log_analysis | 6670 | 6678 | 8 | 0.1% | REGRESS |
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
| single-day-access-log-top25-consolidate | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/detect/scan_sub_compile | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/parse/read_files | 10.7 s | 10.4 s | -307 ms | -2.9% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/finalize/group_similar | 4.1 s | 3.8 s | -344 ms | -8.3% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics | 334 ms | 255 ms | -79 ms | -23.7% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 164 ms | 126 ms | -38 ms | -23.2% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 170 ms | 127 ms | -43 ms | -25.3% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 15.2 s | 14.5 s | -726 ms | -4.8% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 181.2 MB | 189.0 MB | +7.7 MB | 4.3% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_clusters | 48.4 MB | 48.4 MB | +25.2 KB | 0.1% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_message | 883 KB | 888 KB | +5.0 KB | 0.6% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_trigrams | 4.1 MB | 4.1 MB | +1.2 KB | 0.0% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_ngram_index | 4.8 MB | 4.8 MB | +24.8 KB | 0.5% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_patterns | 118.1 KB | 118.1 KB | +6 B | 0.0% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_posting_size | 352.5 KB | 352.5 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_unmatched | 565.1 KB | 565.2 KB | +16 B | 0.0% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/format_scan_subs | 752 KB | 1.2 MB | +464 KB | 61.7% | REGRESS |
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
| single-day-access-log-top25-consolidate | MEMORY/log_messages | 55.4 MB | 55.9 MB | +522.4 KB | 0.9% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_stats | 22.5 KB | 30.5 KB | +8.0 KB | 35.3% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/message_key_order | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/unattributed | 13.1 MB | 19.8 MB | +6.7 MB | 51.1% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_messages | 56080289 | 56185715 | 105426 | 0.2% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_analysis | 6670 | 6678 | 8 | 0.1% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 50771065 | 50796862 | 25797 | 0.1% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 119797 | 119803 | 6 | 0.0% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 296 | 304 | 8 | 2.7% | REGRESS |
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
| single-day-access-log-heatmap | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| single-day-access-log-heatmap | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| single-day-access-log-heatmap | TIMING/parse/read_files | 9.6 s | 9.5 s | -86 ms | -0.9% | IMPROVE |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics | 49 ms | 42 ms | -7 ms | -14.3% | IMPROVE |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 5 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics/group_calc | 44 ms | 37 ms | -7 ms | -15.9% | IMPROVE |
| single-day-access-log-heatmap | TIMING/finalize/heatmap_statistics | 8 ms | 30 ms | +22 ms | 275.0% | REGRESS |
| single-day-access-log-heatmap | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 9.6 s | 9.6 s | -68 ms | -0.7% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/rss_peak | 116.4 MB | 123 MB | +6.6 MB | 5.7% | REGRESS |
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
| single-day-access-log-heatmap | MEMORY/format_scan_subs | 736 KB | 1.1 MB | +400 KB | 54.3% | REGRESS |
| single-day-access-log-heatmap | MEMORY/heatmap_counters | 569.7 KB | 571.2 KB | +1.5 KB | 0.3% | REGRESS |
| single-day-access-log-heatmap | MEMORY/heatmap_counters_hl | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-access-log-heatmap | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_analysis | 8.1 KB | 8.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_messages | 55.4 MB | 55.9 MB | +516.4 KB | 0.9% | REGRESS |
| single-day-access-log-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_stats | 15.2 KB | 18.2 KB | +3.0 KB | 19.7% | REGRESS |
| single-day-access-log-heatmap | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-access-log-heatmap | MEMORY/message_key_order | 1.8 KB | 1.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| single-day-access-log-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/unattributed | 59.6 MB | 65.3 MB | +5.7 MB | 9.6% | REGRESS |
| single-day-access-log-heatmap | MEMORY_FINAL/log_messages | 58114584 | 58643362 | 528778 | 0.9% | REGRESS |
| single-day-access-log-heatmap | MEMORY_FINAL/log_analysis | 6670 | 6678 | 8 | 0.1% | REGRESS |
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
| single-day-access-log-histogram | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| single-day-access-log-histogram | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| single-day-access-log-histogram | TIMING/parse/read_files | 10.7 s | 10.7 s | +63 ms | 0.6% | REGRESS |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics | 150 ms | 132 ms | -18 ms | -12.0% | IMPROVE |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 99 ms | 88 ms | -11 ms | -11.1% | IMPROVE |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 5 ms | -1 ms | -16.7% | IMPROVE |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/group_calc | 45 ms | 38 ms | -7 ms | -15.6% | IMPROVE |
| single-day-access-log-histogram | TIMING/finalize/histogram_statistics | 3 ms | 11 ms | +8 ms | 266.7% | REGRESS |
| single-day-access-log-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 10.8 s | 10.9 s | +56 ms | 0.5% | REGRESS |
| single-day-access-log-histogram | MEMORY/rss_peak | 144.2 MB | 152.2 MB | +8 MB | 5.5% | REGRESS |
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
| single-day-access-log-histogram | MEMORY/format_scan_subs | 656 KB | 1.1 MB | +480 KB | 73.2% | REGRESS |
| single-day-access-log-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/histogram_counters | 105.5 KB | 106 KB | +540 B | 0.5% | REGRESS |
| single-day-access-log-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_analysis | 52.7 MB | 52.7 MB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_messages | 55.4 MB | 55.9 MB | +523.3 KB | 0.9% | REGRESS |
| single-day-access-log-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_stats | 22.5 KB | 30.5 KB | +8.0 KB | 35.3% | REGRESS |
| single-day-access-log-histogram | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-access-log-histogram | MEMORY/message_key_order | 1.8 KB | 1.8 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| single-day-access-log-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/unattributed | 35.3 MB | 42.3 MB | +7 MB | 19.9% | REGRESS |
| single-day-access-log-histogram | MEMORY_FINAL/log_messages | 58114584 | 58650402 | 535818 | 0.9% | REGRESS |
| single-day-access-log-histogram | MEMORY_FINAL/log_analysis | 6670 | 6678 | 8 | 0.1% | REGRESS |
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
| single-day-access-log-heatmap-histogram | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/parse/read_files | 11.2 s | 11.2 s | -12 ms | -0.1% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics | 49 ms | 41 ms | -8 ms | -16.3% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 5 ms | -1 ms | -16.7% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 43 ms | 36 ms | -7 ms | -16.3% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/finalize/heatmap_statistics | 8 ms | 31 ms | +23 ms | 287.5% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/finalize/histogram_statistics | 3 ms | 11 ms | +8 ms | 266.7% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 11.3 s | 11.3 s | +17 ms | 0.2% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 116.5 MB | 122.5 MB | +6.1 MB | 5.2% | REGRESS |
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
| single-day-access-log-heatmap-histogram | MEMORY/format_scan_subs | 736 KB | 1.1 MB | +432 KB | 58.7% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_counters | 569.7 KB | 572.2 KB | +2.4 KB | 0.4% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_counters_hl | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_counters | 105.6 KB | 106 KB | +412 B | 0.4% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_analysis | 8.1 KB | 8.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_messages | 55.4 MB | 55.9 MB | +530.1 KB | 0.9% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_stats | 15.2 KB | 18.2 KB | +3.0 KB | 19.7% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/message_key_order | 1.8 KB | 1.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/unattributed | 59.6 MB | 64.7 MB | +5.1 MB | 8.6% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_messages | 58107544 | 58650402 | 542858 | 0.9% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_analysis | 6670 | 6678 | 8 | 0.1% | REGRESS |
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
| single-day-access-log-heatmap-histogram-consolidate | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/parse/read_files | 12.6 s | 12.7 s | +92 ms | 0.7% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 2.8 s | 2.7 s | -155 ms | -5.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 169 ms | 153 ms | -16 ms | -9.5% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 167 ms | 152 ms | -15 ms | -9.0% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 8 ms | 30 ms | +22 ms | 275.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 3 ms | 11 ms | +8 ms | 266.7% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 15.6 s | 15.6 s | -44 ms | -0.3% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 154.9 MB | 163.1 MB | +8.2 MB | 5.3% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 48.4 MB | 48.4 MB | +25.2 KB | 0.1% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 883 KB | 888 KB | +5.0 KB | 0.6% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 4.1 MB | 4.1 MB | -2.8 KB | -0.1% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 4.8 MB | 4.8 MB | +28.7 KB | 0.6% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 118.1 KB | 118.1 KB | +6 B | 0.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 352.5 KB | 352.5 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 565.1 KB | 565.2 KB | +16 B | 0.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 704 KB | 1.2 MB | +512 KB | 72.7% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 569.7 KB | 572.2 KB | +2.4 KB | 0.4% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_counters | 105.6 KB | 106 KB | +412 B | 0.4% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 8.1 KB | 8.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_messages | 55.4 MB | 55.9 MB | +529.3 KB | 0.9% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_stats | 15.2 KB | 18.2 KB | +3.0 KB | 19.7% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/message_key_order | 1.9 KB | 1.9 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/unattributed | 38.9 MB | 46.0 MB | +7.1 MB | 18.3% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 56068217 | 56174555 | 106338 | 0.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 6670 | 6678 | 8 | 0.1% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 50771065 | 50796862 | 25797 | 0.1% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 119797 | 119803 | 6 | 0.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 296 | 304 | 8 | 2.7% | REGRESS |
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
| single-day-access-log-sort-p99 | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| single-day-access-log-sort-p99 | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| single-day-access-log-sort-p99 | TIMING/parse/read_files | 8.6 s | 8.7 s | +78 ms | 0.9% | REGRESS |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics | 212 ms | 185 ms | -27 ms | -12.7% | IMPROVE |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 103 ms | 89 ms | -14 ms | -13.6% | IMPROVE |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 107 ms | 94 ms | -13 ms | -12.1% | IMPROVE |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/total | 8.8 s | 8.9 s | +55 ms | 0.6% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY/rss_peak | 144.6 MB | 150.9 MB | +6.3 MB | 4.4% | REGRESS |
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
| single-day-access-log-sort-p99 | MEMORY/format_scan_subs | 720 KB | 1.2 MB | +496 KB | 68.9% | REGRESS |
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
| single-day-access-log-sort-p99 | MEMORY/log_messages | 55.4 MB | 55.9 MB | +530.1 KB | 0.9% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_stats | 22.5 KB | 30.5 KB | +8.0 KB | 35.3% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY/message_key_order | 2.0 KB | 2.0 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/unattributed | 35.7 MB | 41 MB | +5.3 MB | 14.8% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY_FINAL/log_messages | 58107544 | 58650402 | 542858 | 0.9% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY_FINAL/log_analysis | 6670 | 6678 | 8 | 0.1% | REGRESS |
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
| single-day-access-log-sort-skewness | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| single-day-access-log-sort-skewness | TIMING/detect/scan_sub_compile | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| single-day-access-log-sort-skewness | TIMING/parse/read_files | 8.6 s | 8.7 s | +71 ms | 0.8% | REGRESS |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics | 334 ms | 304 ms | -30 ms | -9.0% | IMPROVE |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 100 ms | 88 ms | -12 ms | -12.0% | IMPROVE |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 228 ms | 210 ms | -18 ms | -7.9% | IMPROVE |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 5 ms | 5 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/total | 9.0 s | 9 s | +44 ms | 0.5% | REGRESS |
| single-day-access-log-sort-skewness | MEMORY/rss_peak | 150.4 MB | 157.3 MB | +6.9 MB | 4.6% | REGRESS |
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
| single-day-access-log-sort-skewness | MEMORY/format_scan_subs | 640 KB | 1.2 MB | +624 KB | 97.5% | REGRESS |
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
| single-day-access-log-sort-skewness | MEMORY/log_messages | 55.2 MB | 55.9 MB | +721.6 KB | 1.3% | REGRESS |
| single-day-access-log-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_stats | 22.5 KB | 30.5 KB | +8.0 KB | 35.3% | REGRESS |
| single-day-access-log-sort-skewness | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| single-day-access-log-sort-skewness | MEMORY/message_key_order | 1.9 KB | 1.9 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| single-day-access-log-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/unattributed | 41.8 MB | 47.4 MB | +5.6 MB | 13.3% | REGRESS |
| single-day-access-log-sort-skewness | MEMORY_FINAL/log_messages | 57913021 | 58651975 | 738954 | 1.3% | REGRESS |
| single-day-access-log-sort-skewness | MEMORY_FINAL/log_analysis | 6670 | 6678 | 8 | 0.1% | REGRESS |
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
| month-single-server-access-logs-standard | lines_included | 7,749,167 | 7,749,159 | -8 | -0.0% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| month-single-server-access-logs-standard | TIMING/detect/scan_sub_compile | 4 ms | 13 ms | +9 ms | 225.0% | REGRESS |
| month-single-server-access-logs-standard | TIMING/parse/read_files | 1.6 min | 1.6 min | -50 ms | -0.1% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics | 5.1 s | 4.8 s | -251 ms | -4.9% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/bucket_stats | 2.7 s | 2.7 s | -16 ms | -0.6% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 1.7 s | 1.6 s | -167 ms | -9.6% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/group_calc | 607 ms | 538 ms | -69 ms | -11.4% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/untimed | 63 ms | 64 ms | +1 ms | 1.6% | REGRESS |
| month-single-server-access-logs-standard | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/total | 1.7 min | 1.7 min | -298 ms | -0.3% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2.4 GB | 2.6 GB | +194.1 MB | 8.0% | REGRESS |
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
| month-single-server-access-logs-standard | MEMORY/format_scan_subs | 704 KB | 2.0 MB | +1.3 MB | 186.4% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_analysis | 568.5 MB | 568.5 MB | -576 B | -0.0% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/log_messages | 1.6 GB | 1.8 GB | +194.2 MB | 11.9% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_occurrences | 36.8 KB | 36.8 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_sessions | 2.2 MB | 2.2 MB | -877 B | -0.0% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/log_stats | 43.6 KB | 58.3 KB | +14.7 KB | 33.6% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/unattributed | 232.5 MB | 231.2 MB | -1.4 MB | -0.6% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_messages | 1704450153 | 1908108963 | 203658810 | 11.9% | REGRESS |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_analysis | 13010 | 13018 | 8 | 0.1% | REGRESS |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | COUNTS/log_messages_entries | 1212275 | 1212271 | -4 | -0.0% | IMPROVE |
| month-single-server-access-logs-standard | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | COUNTS/log_messages_population | 1212275 | 1212271 | -4 | -0.0% | IMPROVE |
| month-single-server-access-logs-standard | COUNTS/format_scan_subs_compiled | 1 | 2 | 1 | 100.0% | REGRESS |
| month-single-server-access-logs-standard | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_included | 7,749,167 | 7,749,159 | -8 | -0.0% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/detect/scan_sub_compile | 4 ms | 13 ms | +9 ms | 225.0% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/parse/read_files | 1.6 min | 1.6 min | +1.3 s | 1.4% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics | 5.6 s | 5.0 s | -691 ms | -12.2% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 3 s | 2.6 s | -376 ms | -12.5% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 1.6 s | 1.5 s | -123 ms | -7.5% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/group_calc | 934 ms | 745 ms | -189 ms | -20.2% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 67 ms | 64 ms | -3 ms | -4.5% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 1.7 min | 1.7 min | +622 ms | 0.6% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2.4 GB | 2.6 GB | +208.5 MB | 8.6% | REGRESS |
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
| month-single-server-access-logs-top25 | MEMORY/format_scan_subs | 736 KB | 1.9 MB | +1.2 MB | 167.4% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_analysis | 568.5 MB | 568.5 MB | -576 B | -0.0% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/log_messages | 1.6 GB | 1.8 GB | +194.2 MB | 11.9% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_occurrences | 36.8 KB | 36.8 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_sessions | 2.2 MB | 2.2 MB | -877 B | -0.0% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/log_stats | 43.6 KB | 58.3 KB | +14.7 KB | 33.6% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/message_key_order | 4.7 KB | 4.7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/unattributed | 234.3 MB | 247.4 MB | +13.1 MB | 5.6% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_messages | 1704461193 | 1908120691 | 203659498 | 11.9% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_analysis | 13010 | 13018 | 8 | 0.1% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | COUNTS/log_messages_entries | 1212275 | 1212271 | -4 | -0.0% | IMPROVE |
| month-single-server-access-logs-top25 | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | COUNTS/log_messages_population | 1212275 | 1212271 | -4 | -0.0% | IMPROVE |
| month-single-server-access-logs-top25 | COUNTS/format_scan_subs_compiled | 1 | 2 | 1 | 100.0% | REGRESS |
| month-single-server-access-logs-top25 | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,167 | 7,749,159 | -8 | -0.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 13 ms | +9 ms | 225.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/parse/read_files | 2.3 min | 2.2 min | -3.1 s | -2.3% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/group_similar | 1.7 min | 1.6 min | -8.4 s | -8.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 7.4 s | 6.7 s | -723 ms | -9.8% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 4.0 s | 3.6 s | -364 ms | -9.2% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 3.4 s | 3 s | -359 ms | -10.5% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 4.1 min | 3.9 min | -12.2 s | -4.9% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 1.4 GB | 1.4 GB | +6.5 MB | 0.5% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 505.6 MB | 505.7 MB | +90.0 KB | 0.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 2.5 MB | 2.5 MB | +4.8 KB | 0.2% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 36.7 MB | 36.7 MB | +36 KB | 0.1% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 29.4 MB | 29.4 MB | +67.0 KB | 0.2% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 36.0 MB | 36.0 MB | +43.8 KB | 0.1% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 283.0 KB | 283.2 KB | +168 B | 0.1% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_posting_size | 973.6 KB | 973.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 1.6 MB | 1.6 MB | -707 B | -0.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/format_scan_subs | 784 KB | 1.9 MB | +1.1 MB | 142.9% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_analysis | 567.4 MB | 567.4 MB | -576 B | -0.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages | 565.4 MB | 565.7 MB | +220.1 KB | 0.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | -877 B | -0.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_stats | 43.6 KB | 58.3 KB | +14.7 KB | 33.6% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/message_key_order | 4.2 KB | 4.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | 592910041 | 593135427 | 225386 | 0.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 13010 | 13018 | 8 | 0.1% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 530185487 | 530277617 | 92130 | 0.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 248469 | 248613 | 144 | 0.1% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | 304 | -120 | -28.3% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | 65592 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_messages_entries | 1317 | 1313 | -4 | -0.3% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_messages_population | 1317 | 1313 | -4 | -0.3% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 2 | 1 | 100.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,167 | 7,749,159 | -8 | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/detect/scan_sub_compile | 5 ms | 13 ms | +8 ms | 160.0% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/parse/read_files | 1.8 min | 1.8 min | -1.2 s | -1.1% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics | 2.3 s | 2.1 s | -243 ms | -10.4% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 1.7 s | 1.6 s | -160 ms | -9.3% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/group_calc | 548 ms | 466 ms | -82 ms | -15.0% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 73 ms | 72 ms | -1 ms | -1.4% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/finalize/heatmap_statistics | 66 ms | 106 ms | +40 ms | 60.6% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/total | 1.8 min | 1.8 min | -1.4 s | -1.3% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 1.9 GB | 2.1 GB | +208.3 MB | 10.5% | REGRESS |
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
| month-single-server-access-logs-heatmap | MEMORY/format_scan_subs | 752 KB | 1.9 MB | +1.2 MB | 163.8% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | +2.7 KB | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_counters_hl | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data | 79.1 KB | 75.9 KB | -3.2 KB | -4.1% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_analysis | 15.3 KB | 15.3 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_messages | 1.6 GB | 1.8 GB | +194.2 MB | 11.9% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_occurrences | 36.8 KB | 36.8 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_sessions | 2.2 MB | 2.2 MB | -877 B | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/log_stats | 29.6 KB | 35.0 KB | +5.4 KB | 18.4% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/unattributed | 356.8 MB | 369.7 MB | +12.8 MB | 3.6% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_messages | 1704450033 | 1908108843 | 203658810 | 11.9% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_analysis | 12594 | 12602 | 8 | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | COUNTS/log_messages_entries | 1212275 | 1212271 | -4 | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | COUNTS/log_messages_population | 1212275 | 1212271 | -4 | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap | COUNTS/format_scan_subs_compiled | 1 | 2 | 1 | 100.0% | REGRESS |
| month-single-server-access-logs-heatmap | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_included | 7,749,167 | 7,749,159 | -8 | -0.0% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/detect/scan_sub_compile | 4 ms | 13 ms | +9 ms | 225.0% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/parse/read_files | 2 min | 2.0 min | -2.3 s | -1.9% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics | 5.4 s | 4.8 s | -529 ms | -9.8% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 2.9 s | 2.6 s | -279 ms | -9.6% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 1.8 s | 1.6 s | -133 ms | -7.5% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/group_calc | 647 ms | 530 ms | -117 ms | -18.1% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 63 ms | 63 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/finalize/histogram_statistics | 7 ms | 19 ms | +12 ms | 171.4% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/total | 2.1 min | 2.1 min | -2.9 s | -2.3% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 2.4 GB | 2.6 GB | +207.2 MB | 8.5% | REGRESS |
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
| month-single-server-access-logs-histogram | MEMORY/format_scan_subs | 736 KB | 1.9 MB | +1.2 MB | 169.6% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/histogram_counters | 295.6 KB | 295.9 KB | +284 B | 0.1% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_analysis | 568.5 MB | 568.5 MB | -576 B | -0.0% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/log_messages | 1.6 GB | 1.8 GB | +194.2 MB | 11.9% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_occurrences | 36.8 KB | 36.8 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | -877 B | -0.0% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/log_stats | 43.6 KB | 58.3 KB | +14.7 KB | 33.6% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/unattributed | 234.0 MB | 245.7 MB | +11.7 MB | 5.0% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_messages | 1704450281 | 1908108963 | 203658682 | 11.9% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_analysis | 13010 | 13018 | 8 | 0.1% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | COUNTS/log_messages_entries | 1212275 | 1212271 | -4 | -0.0% | IMPROVE |
| month-single-server-access-logs-histogram | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | COUNTS/log_messages_population | 1212275 | 1212271 | -4 | -0.0% | IMPROVE |
| month-single-server-access-logs-histogram | COUNTS/format_scan_subs_compiled | 1 | 2 | 1 | 100.0% | REGRESS |
| month-single-server-access-logs-histogram | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,167 | 7,749,159 | -8 | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | 5 ms | 13 ms | +8 ms | 160.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/parse/read_files | 2.2 min | 2.1 min | -4.2 s | -3.2% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 2.4 s | 2 s | -360 ms | -15.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 1.7 s | 1.5 s | -230 ms | -13.4% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 578 ms | 459 ms | -119 ms | -20.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 83 ms | 72 ms | -11 ms | -13.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/heatmap_statistics | 65 ms | 106 ms | +41 ms | 63.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/histogram_statistics | 7 ms | 19 ms | +12 ms | 171.4% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.2 min | 2.1 min | -4.5 s | -3.4% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 1.9 GB | 2.1 GB | +200.5 MB | 10.5% | REGRESS |
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
| month-single-server-access-logs-heatmap-histogram | MEMORY/format_scan_subs | 704 KB | 2 MB | +1.3 MB | 190.9% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | +988 B | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data | 83.1 KB | 78.4 KB | -4.7 KB | -5.7% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_counters | 295.6 KB | 295.8 KB | +156 B | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.3 KB | 15.3 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_messages | 1.5 GB | 1.7 GB | +194.2 MB | 12.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | -877 B | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_stats | 29.6 KB | 35.0 KB | +5.4 KB | 18.4% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/unattributed | 353.3 MB | 358.3 MB | +5.0 MB | 1.4% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 1626865585 | 1830524139 | 203658554 | 12.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 12594 | 12602 | 8 | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_messages_entries | 1212275 | 1212271 | -4 | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_messages_population | 1212275 | 1212271 | -4 | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | COUNTS/format_scan_subs_compiled | 1 | 2 | 1 | 100.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,167 | 7,749,159 | -8 | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 5 ms | 13 ms | +8 ms | 160.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 2.8 min | 2.6 min | -10.3 s | -6.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 1.3 min | 1.2 min | -4.2 s | -5.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 3.1 s | 2.7 s | -324 ms | -10.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 4 ms | 3 ms | -1 ms | -25.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 3.1 s | 2.7 s | -323 ms | -10.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 60 ms | 99 ms | +39 ms | 65.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 11 ms | 22 ms | +11 ms | 100.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 4.1 min | 3.9 min | -14.8 s | -6.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 1.1 GB | 1.1 GB | +5.1 MB | 0.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 505.6 MB | 505.7 MB | +90.3 KB | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.5 MB | 2.5 MB | +4.8 KB | 0.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 36.7 MB | 36.7 MB | +37 KB | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 29.4 MB | 29.4 MB | +17.0 KB | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 36.0 MB | 36.0 MB | +44.5 KB | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 283.0 KB | 283.2 KB | +168 B | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 973.6 KB | 973.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.6 MB | 1.6 MB | -67 B | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 720 KB | 1.8 MB | +1.1 MB | 155.6% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | +2.7 KB | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 79.6 KB | 78.4 KB | -1.2 KB | -1.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 295.5 KB | 295.8 KB | +284 B | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 15.3 KB | 15.3 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 565.4 MB | 565.6 MB | +156.4 KB | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | -877 B | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 29.6 KB | 35.0 KB | +5.4 KB | 18.4% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 1.9 KB | 1.9 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 592899225 | 593059347 | 160122 | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 12594 | 12602 | 8 | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 530185103 | 530277617 | 92514 | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 248469 | 248613 | 144 | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | 432 | 8 | 1.9% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | 65592 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 1317 | 1313 | -4 | -0.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | 1317 | 1313 | -4 | -0.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 2 | 1 | 100.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | lines_included | 7,749,167 | 7,749,159 | -8 | -0.0% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/detect/scan_sub_compile | 4 ms | 13 ms | +9 ms | 225.0% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/parse/read_files | 1.6 min | 1.6 min | -1.9 s | -2.0% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics | 12.4 s | 11.2 s | -1.2 s | -9.8% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 2.8 s | 2.7 s | -151 ms | -5.4% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 6.0 s | 5.4 s | -617 ms | -10.3% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 3.5 s | 3 s | -432 ms | -12.5% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/group_calc | 22 ms | 16 ms | -6 ms | -27.3% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 140 ms | 132 ms | -8 ms | -5.7% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-p99 | TIMING/total | 1.8 min | 1.8 min | -3.1 s | -2.9% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/rss_peak | 2.4 GB | 2.6 GB | +213.1 MB | 8.6% | REGRESS |
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
| month-single-server-access-logs-sort-p99 | MEMORY/format_scan_subs | 736 KB | 2.0 MB | +1.2 MB | 173.9% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_analysis | 568.5 MB | 568.5 MB | -576 B | -0.0% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/log_messages | 1.6 GB | 1.8 GB | +194.2 MB | 11.9% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_occurrences | 36.8 KB | 36.8 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_sessions | 2.2 MB | 2.2 MB | -877 B | -0.0% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/log_stats | 43.6 KB | 58.3 KB | +14.7 KB | 33.6% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/unattributed | 279.7 MB | 297.3 MB | +17.6 MB | 6.3% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/log_messages | 1704461713 | 1908120011 | 203658298 | 11.9% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/log_analysis | 13010 | 13018 | 8 | 0.1% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | COUNTS/log_messages_entries | 1212275 | 1212271 | -4 | -0.0% | IMPROVE |
| month-single-server-access-logs-sort-p99 | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | COUNTS/log_messages_population | 1212275 | 1212271 | -4 | -0.0% | IMPROVE |
| month-single-server-access-logs-sort-p99 | COUNTS/format_scan_subs_compiled | 1 | 2 | 1 | 100.0% | REGRESS |
| month-single-server-access-logs-sort-p99 | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | lines_included | 7,749,167 | 7,749,159 | -8 | -0.0% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/detect/registry_build | 8 ms | 12 ms | +4 ms | 50.0% | REGRESS |
| month-single-server-access-logs-sort-skewness | TIMING/detect/scan_sub_compile | 4 ms | 13 ms | +9 ms | 225.0% | REGRESS |
| month-single-server-access-logs-sort-skewness | TIMING/parse/read_files | 1.6 min | 1.6 min | -1.8 s | -1.8% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics | 7.7 s | 7.1 s | -626 ms | -8.1% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 2.8 s | 2.7 s | -106 ms | -3.8% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 4.5 s | 4 s | -486 ms | -10.8% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 13 ms | 13 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 300 ms | 267 ms | -33 ms | -11.0% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 68 ms | 67 ms | -1 ms | -1.5% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/total | 1.8 min | 1.7 min | -2.4 s | -2.3% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/rss_peak | 2.3 GB | 2.5 GB | +268.8 MB | 11.5% | REGRESS |
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
| month-single-server-access-logs-sort-skewness | MEMORY/format_scan_subs | 752 KB | 2.0 MB | +1.2 MB | 166.0% | REGRESS |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_analysis | 568.5 MB | 568.5 MB | -576 B | -0.0% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/log_messages | 1.5 GB | 1.8 GB | +268.2 MB | 17.3% | REGRESS |
| month-single-server-access-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_occurrences | 36.8 KB | 36.8 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_sessions | 2.2 MB | 2.2 MB | -877 B | -0.0% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/log_stats | 43.6 KB | 58.3 KB | +14.7 KB | 33.6% | REGRESS |
| month-single-server-access-logs-sort-skewness | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-single-server-access-logs-sort-skewness | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| month-single-server-access-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/unattributed | 217.8 MB | 217.2 MB | -624 KB | -0.3% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/log_messages | 1626878326 | 1908121584 | 281243258 | 17.3% | REGRESS |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/log_analysis | 13010 | 13018 | 8 | 0.1% | REGRESS |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | COUNTS/log_messages_entries | 1212275 | 1212271 | -4 | -0.0% | IMPROVE |
| month-single-server-access-logs-sort-skewness | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | COUNTS/log_messages_population | 1212275 | 1212271 | -4 | -0.0% | IMPROVE |
| month-single-server-access-logs-sort-skewness | COUNTS/format_scan_subs_compiled | 1 | 2 | 1 | 100.0% | REGRESS |
| month-single-server-access-logs-sort-skewness | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_included | 38,672,504 | 38,672,411 | -93 | -0.0% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/detect/registry_build | 9 ms | 11 ms | +2 ms | 22.2% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/detect/scan_sub_compile | 4 ms | 20 ms | +16 ms | 400.0% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/parse/read_files | 8.2 min | 8 min | -12.9 s | -2.6% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics | 32.6 s | 29.1 s | -3.5 s | -10.8% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/bucket_stats | 17.8 s | 16.8 s | -998 ms | -5.6% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 10.8 s | 8.7 s | -2.1 s | -19.5% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/group_calc | 3.6 s | 3.2 s | -413 ms | -11.3% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/untimed | 390 ms | 389 ms | -1 ms | -0.3% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/render/normalize_data | 3 ms | 4 ms | +1 ms | 33.3% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/total | 8.8 min | 8.5 min | -16.4 s | -3.1% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 12.1 GB | 13.1 GB | +982.8 MB | 7.9% | REGRESS |
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
| month-many-servers-access-logs-standard | MEMORY/format_scan_subs | 720 KB | 2.3 MB | +1.6 MB | 228.9% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_analysis | 2.9 GB | 2.9 GB | -6.5 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/log_messages | 8.2 GB | 9.2 GB | +991.3 MB | 11.8% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -41.1 KB | -0.3% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/log_stats | 44.1 KB | 58.7 KB | +14.7 KB | 33.3% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/unattributed | 1 GB | 1 GB | -10.1 MB | -1.0% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_messages | 8806439108 | 9845871443 | 1039432335 | 11.8% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_analysis | 13010 | 13018 | 8 | 0.1% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | COUNTS/log_messages_entries | 6187253 | 6187234 | -19 | -0.0% | IMPROVE |
| month-many-servers-access-logs-standard | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | COUNTS/log_messages_population | 6187253 | 6187234 | -19 | -0.0% | IMPROVE |
| month-many-servers-access-logs-standard | COUNTS/format_scan_subs_compiled | 1 | 3 | 2 | 200.0% | REGRESS |
| month-many-servers-access-logs-standard | COUNTS/format_scan_sub_cache_hits | 139 | 142 | 3 | 2.2% | REGRESS |
| month-many-servers-access-logs-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_included | 38,672,504 | 38,672,411 | -93 | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/detect/scan_sub_compile | 4 ms | 20 ms | +16 ms | 400.0% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/parse/read_files | 8.2 min | 8.1 min | -10.4 s | -2.1% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics | 33.5 s | 30.4 s | -3.1 s | -9.4% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 17.5 s | 16.6 s | -886 ms | -5.1% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 10.3 s | 8.8 s | -1.5 s | -14.5% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/group_calc | 5.4 s | 4.6 s | -781 ms | -14.4% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 351 ms | 369 ms | +18 ms | 5.1% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/render/normalize_data | 3 ms | 4 ms | +1 ms | 33.3% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/total | 8.8 min | 8.6 min | -13.6 s | -2.6% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 12.2 GB | 13.2 GB | +1 GB | 8.2% | REGRESS |
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
| month-many-servers-access-logs-top25 | MEMORY/format_scan_subs | 736 KB | 2.4 MB | +1.7 MB | 230.4% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_analysis | 2.9 GB | 2.9 GB | -6.5 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/log_messages | 8.2 GB | 9.2 GB | +981.9 MB | 11.7% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +22.9 KB | 0.2% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/log_stats | 44.1 KB | 58.7 KB | +14.7 KB | 33.3% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/message_key_order | 4.7 KB | 4.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/unattributed | 1.1 GB | 1.1 GB | +40.5 MB | 3.8% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_messages | 8806449828 | 9836035363 | 1029585535 | 11.7% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_analysis | 13010 | 13018 | 8 | 0.1% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | COUNTS/log_messages_entries | 6187253 | 6187234 | -19 | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25 | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | COUNTS/log_messages_population | 6187253 | 6187234 | -19 | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25 | COUNTS/format_scan_subs_compiled | 1 | 3 | 2 | 200.0% | REGRESS |
| month-many-servers-access-logs-top25 | COUNTS/format_scan_sub_cache_hits | 139 | 142 | 3 | 2.2% | REGRESS |
| month-many-servers-access-logs-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,504 | 38,672,411 | -93 | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 20 ms | +16 ms | 400.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/parse/read_files | 10.3 min | 10.3 min | +2.0 s | 0.3% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/group_similar | 16.7 min | 17.8 min | +1 min | 6.1% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 38.2 s | 37.2 s | -971 ms | -2.5% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 20.2 s | 20 s | -174 ms | -0.9% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 8 ms | 6 ms | -2 ms | -25.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 18.0 s | 17.2 s | -793 ms | -4.4% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/untimed | 30 ms | 28 ms | -2 ms | -6.7% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/render/normalize_data | 3 ms | 4 ms | +1 ms | 33.3% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 27.6 min | 28.7 min | +1 min | 3.8% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 6.4 GB | 6.4 GB | +50.5 MB | 0.8% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 2.6 GB | 2.6 GB | -1.2 MB | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 2.5 MB | 2.5 MB | -9.8 KB | -0.4% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 36.8 MB | 36.9 MB | +38.2 KB | 0.1% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 29.5 MB | 29.4 MB | -16 KB | -0.1% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 36.1 MB | 36.2 MB | +58.6 KB | 0.2% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 531.3 KB | 523.2 KB | -8.1 KB | -1.5% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_posting_size | 1.2 MB | 1.2 MB | -6.4 KB | -0.5% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | 1.7 MB | -13.5 KB | -0.8% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/format_scan_subs | 752 KB | 2.6 MB | +1.9 MB | 257.4% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_analysis | 2.9 GB | 2.9 GB | -6.5 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages | 2.9 GB | 2.9 GB | -931.9 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -41.1 KB | -0.3% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_stats | 44.1 KB | 58.7 KB | +14.7 KB | 33.3% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/message_key_order | 4.2 KB | 4.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | 3100090410 | 3099136139 | -954271 | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 13010 | 13018 | 8 | 0.1% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 2843032320 | 2841799400 | -1232920 | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 544033 | 535708 | -8325 | -1.5% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | 432 | 8 | 1.9% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | 65592 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_messages_entries | 2549 | 2537 | -12 | -0.5% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_messages_population | 2549 | 2537 | -12 | -0.5% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 3 | 2 | 200.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | 139 | 142 | 3 | 2.2% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,504 | 38,672,411 | -93 | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/detect/scan_sub_compile | 4 ms | 20 ms | +16 ms | 400.0% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/parse/read_files | 8.7 min | 8.9 min | +8.8 s | 1.7% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics | 13.9 s | 11.7 s | -2.2 s | -15.8% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 10.3 s | 8.5 s | -1.8 s | -17.5% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/group_calc | 3.1 s | 2.7 s | -381 ms | -12.2% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 437 ms | 427 ms | -10 ms | -2.3% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/finalize/heatmap_statistics | 76 ms | 116 ms | +40 ms | 52.6% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/render/normalize_data | 3 ms | 2 ms | -1 ms | -33.3% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/total | 9.0 min | 9.1 min | +6.6 s | 1.2% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 9.7 GB | 10.8 GB | +1 GB | 10.4% | REGRESS |
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
| month-many-servers-access-logs-heatmap | MEMORY/format_scan_subs | 752 KB | 2.4 MB | +1.7 MB | 227.7% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | +988 B | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_counters_hl | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data | 81.1 KB | 72.8 KB | -8.3 KB | -10.2% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_analysis | 15.3 KB | 15.3 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_messages | 8.2 GB | 9.2 GB | +1000.7 MB | 11.9% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -9.1 KB | -0.1% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/log_stats | 29.6 KB | 35.0 KB | +5.4 KB | 18.4% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/unattributed | 1.5 GB | 1.6 GB | +36.8 MB | 2.3% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_messages | 8791532220 | 9840812043 | 1049279823 | 11.9% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_analysis | 12594 | 12602 | 8 | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | COUNTS/log_messages_entries | 6187253 | 6187234 | -19 | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | COUNTS/log_messages_population | 6187253 | 6187234 | -19 | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap | COUNTS/format_scan_subs_compiled | 1 | 3 | 2 | 200.0% | REGRESS |
| month-many-servers-access-logs-heatmap | COUNTS/format_scan_sub_cache_hits | 139 | 142 | 3 | 2.2% | REGRESS |
| month-many-servers-access-logs-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_included | 38,672,504 | 38,672,411 | -93 | -0.0% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/detect/scan_sub_compile | 4 ms | 20 ms | +16 ms | 400.0% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/parse/read_files | 9.8 min | 9.9 min | +6.5 s | 1.1% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics | 30.9 s | 29.1 s | -1.8 s | -5.8% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 16.7 s | 16.7 s | +44 ms | 0.3% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 10.3 s | 8.7 s | -1.6 s | -15.5% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/group_calc | 3.5 s | 3.2 s | -262 ms | -7.5% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 372 ms | 390 ms | +18 ms | 4.8% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/finalize/histogram_statistics | 10 ms | 20 ms | +10 ms | 100.0% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/render/normalize_data | 3 ms | 4 ms | +1 ms | 33.3% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/total | 10.4 min | 10.4 min | +4.7 s | 0.8% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 11.8 GB | 13.1 GB | +1.3 GB | 11.1% | REGRESS |
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
| month-many-servers-access-logs-histogram | MEMORY/format_scan_subs | 752 KB | 2.3 MB | +1.6 MB | 214.9% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_counters | 307.3 KB | 307.7 KB | +412 B | 0.1% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_analysis | 2.9 GB | 2.9 GB | -6.5 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/log_messages | 7.8 GB | 9.2 GB | +1.3 GB | 17.1% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_occurrences | 42.1 KB | 43.8 KB | +1.8 KB | 4.2% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -9.1 KB | -0.1% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/log_stats | 44.1 KB | 58.7 KB | +14.7 KB | 33.3% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/unattributed | 1.1 GB | 1 GB | -29.1 MB | -2.7% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_messages | 8410455044 | 9845871443 | 1435416399 | 17.1% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_analysis | 13010 | 13018 | 8 | 0.1% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | COUNTS/log_messages_entries | 6187253 | 6187234 | -19 | -0.0% | IMPROVE |
| month-many-servers-access-logs-histogram | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | COUNTS/log_messages_population | 6187253 | 6187234 | -19 | -0.0% | IMPROVE |
| month-many-servers-access-logs-histogram | COUNTS/format_scan_subs_compiled | 1 | 3 | 2 | 200.0% | REGRESS |
| month-many-servers-access-logs-histogram | COUNTS/format_scan_sub_cache_hits | 139 | 142 | 3 | 2.2% | REGRESS |
| month-many-servers-access-logs-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,504 | 38,672,411 | -93 | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/detect/registry_build | 8 ms | 12 ms | +4 ms | 50.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | 4 ms | 20 ms | +16 ms | 400.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/parse/read_files | 10.5 min | 10.5 min | +2.4 s | 0.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 13.2 s | 12.7 s | -561 ms | -4.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 9.7 s | 9.5 s | -270 ms | -2.8% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 3.1 s | 2.8 s | -308 ms | -10.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 407 ms | 424 ms | +17 ms | 4.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/heatmap_statistics | 78 ms | 120 ms | +42 ms | 53.8% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/histogram_statistics | 10 ms | 20 ms | +10 ms | 100.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/render/normalize_data | 3 ms | 2 ms | -1 ms | -33.3% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 10.7 min | 10.7 min | +1.9 s | 0.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 9.8 GB | 10.8 GB | +1 GB | 10.4% | REGRESS |
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
| month-many-servers-access-logs-heatmap-histogram | MEMORY/format_scan_subs | 720 KB | 2.7 MB | +2 MB | 284.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | +2.7 KB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data | 81.1 KB | 76.3 KB | -4.8 KB | -5.9% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_counters | 307.4 KB | 307.7 KB | +284 B | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.3 KB | 15.3 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages | 8.2 GB | 9.2 GB | +991.3 MB | 11.8% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -9.1 KB | -0.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_stats | 29.6 KB | 35.0 KB | +5.4 KB | 18.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/unattributed | 1.5 GB | 1.6 GB | +44.4 MB | 2.8% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 8801379580 | 9840812043 | 1039432463 | 11.8% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 12594 | 12602 | 8 | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_messages_entries | 6187253 | 6187234 | -19 | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_messages_population | 6187253 | 6187234 | -19 | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/format_scan_subs_compiled | 1 | 3 | 2 | 200.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/format_scan_sub_cache_hits | 139 | 142 | 3 | 2.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | 38,672,504 | 38,672,411 | -93 | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 4 ms | 20 ms | +16 ms | 400.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 12.6 min | 12.5 min | -4.5 s | -0.6% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 12.9 min | 13.1 min | +9.6 s | 1.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 15.3 s | 14.5 s | -816 ms | -5.3% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 6 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 15.3 s | 14.5 s | -810 ms | -5.3% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/untimed | 24 ms | 18 ms | -6 ms | -25.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 68 ms | 112 ms | +44 ms | 64.7% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 10 ms | 21 ms | +11 ms | 110.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 25.8 min | 25.9 min | +4.3 s | 0.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 4.3 GB | 4.5 GB | +182.7 MB | 4.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 2.6 GB | 2.6 GB | -1.3 MB | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.5 MB | 2.5 MB | -9.8 KB | -0.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 36.8 MB | 36.9 MB | +35.2 KB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 29.5 MB | 29.5 MB | -6 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 36.1 MB | 36.2 MB | +70.6 KB | 0.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 531.3 KB | 523.2 KB | -8.1 KB | -1.5% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 1.2 MB | 1.2 MB | -6.4 KB | -0.5% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | 1.7 MB | -13.5 KB | -0.8% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 736 KB | 2.6 MB | +1.8 MB | 256.5% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | +4.5 KB | 0.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 80.3 KB | 75.8 KB | -4.6 KB | -5.7% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 307.4 KB | 307.8 KB | +412 B | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 15.3 KB | 15.3 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 2.9 GB | 2.9 GB | -1 MB | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -9.1 KB | -0.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 29.6 KB | 35.0 KB | +5.4 KB | 18.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 1.9 KB | 1.9 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 3093178994 | 3092107051 | -1071943 | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 12594 | 12602 | 8 | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 2836131272 | 2834814968 | -1316304 | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 544033 | 535708 | -8325 | -1.5% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | 432 | 8 | 1.9% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | 65592 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 2549 | 2537 | -12 | -0.5% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | 2549 | 2537 | -12 | -0.5% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 3 | 2 | 200.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | 139 | 142 | 3 | 2.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | lines_included | 38,672,504 | 38,672,411 | -93 | -0.0% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/detect/registry_build | 8 ms | 12 ms | +4 ms | 50.0% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/detect/scan_sub_compile | 4 ms | 20 ms | +16 ms | 400.0% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/parse/read_files | 8.0 min | 8.1 min | +6.1 s | 1.3% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics | 1.3 min | 1.2 min | -1.5 s | -2.0% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 17.5 s | 16.8 s | -678 ms | -3.9% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 35.4 s | 34.7 s | -698 ms | -2.0% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 21.4 s | 21.2 s | -149 ms | -0.7% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 836 ms | 879 ms | +43 ms | 5.1% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | TIMING/total | 9.2 min | 9.3 min | +4.6 s | 0.8% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/rss_peak | 12.4 GB | 13.4 GB | +970.3 MB | 7.6% | REGRESS |
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
| month-many-servers-access-logs-sort-p99 | MEMORY/format_scan_subs | 704 KB | 2.3 MB | +1.6 MB | 238.6% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_analysis | 2.9 GB | 2.9 GB | -6.5 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_messages | 8.2 GB | 9.2 GB | +991.3 MB | 11.8% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_occurrences | 42.1 KB | 43.8 KB | +1.8 KB | 4.2% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -40.9 KB | -0.3% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_stats | 44.1 KB | 58.7 KB | +14.7 KB | 33.3% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/message_key_order | 2.5 KB | 2.5 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/unattributed | 1.3 GB | 1.3 GB | -22.6 MB | -1.7% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/log_messages | 8806471772 | 9845904363 | 1039432591 | 11.8% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/log_analysis | 13010 | 13018 | 8 | 0.1% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | COUNTS/log_messages_entries | 6187253 | 6187234 | -19 | -0.0% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | COUNTS/log_messages_population | 6187253 | 6187234 | -19 | -0.0% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | COUNTS/format_scan_subs_compiled | 1 | 3 | 2 | 200.0% | REGRESS |
| month-many-servers-access-logs-sort-p99 | COUNTS/format_scan_sub_cache_hits | 139 | 142 | 3 | 2.2% | REGRESS |
| month-many-servers-access-logs-sort-p99 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | lines_included | 38,672,504 | 38,672,411 | -93 | -0.0% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/detect/registry_build | 8 ms | 11 ms | +3 ms | 37.5% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/detect/scan_sub_compile | 4 ms | 20 ms | +16 ms | 400.0% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/parse/read_files | 7.9 min | 8.1 min | +7.4 s | 1.6% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics | 44.1 s | 43.1 s | -1 s | -2.3% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 17.0 s | 16.5 s | -483 ms | -2.8% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 25.6 s | 25.1 s | -478 ms | -1.9% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 73 ms | 78 ms | +5 ms | 6.8% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 1.1 s | 1 s | -56 ms | -5.2% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 384 ms | 391 ms | +7 ms | 1.8% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/render/normalize_data | 3 ms | 4 ms | +1 ms | 33.3% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/total | 8.7 min | 8.8 min | +6.4 s | 1.2% | REGRESS |
| month-many-servers-access-logs-sort-skewness | MEMORY/rss_peak | 12 GB | 13 GB | +1 GB | 8.4% | REGRESS |
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
| month-many-servers-access-logs-sort-skewness | MEMORY/format_scan_subs | 720 KB | 2.3 MB | +1.6 MB | 228.9% | REGRESS |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_analysis | 2.9 GB | 2.9 GB | -6.5 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_messages | 8.2 GB | 9.2 GB | +1000.7 MB | 11.9% | REGRESS |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_occurrences | 43.8 KB | 43.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -8.9 KB | -0.1% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_stats | 44.1 KB | 58.7 KB | +14.7 KB | 33.3% | REGRESS |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_threadpools | 232 B | 240 B | +8 B | 3.4% | REGRESS |
| month-many-servers-access-logs-sort-skewness | MEMORY/message_key_order | 2.1 KB | 2.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/threadpool_activity | 762 B | 778 B | +16 B | 2.1% | REGRESS |
| month-many-servers-access-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/unattributed | 957.8 MB | 984.7 MB | +26.9 MB | 2.8% | REGRESS |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/log_messages | 8796625985 | 9845905808 | 1049279823 | 11.9% | REGRESS |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/log_analysis | 13010 | 13018 | 8 | 0.1% | REGRESS |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | COUNTS/log_messages_entries | 6187253 | 6187234 | -19 | -0.0% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | COUNTS/log_messages_population | 6187253 | 6187234 | -19 | -0.0% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | COUNTS/format_scan_subs_compiled | 1 | 3 | 2 | 200.0% | REGRESS |
| month-many-servers-access-logs-sort-skewness | COUNTS/format_scan_sub_cache_hits | 139 | 142 | 3 | 2.2% | REGRESS |
| month-many-servers-access-logs-sort-skewness | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_excluded | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/bucket_outcomes | N/A | 1.3 KB | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/log_users | N/A | 8.5 KB | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | lines_read | N/A | 288,025 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | lines_excluded | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | lines_included | N/A | 288,025 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | TIMING/detect/registry_build | N/A | 12 ms | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | TIMING/detect/scan_sub_compile | N/A | 6 ms | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | TIMING/parse/read_files | N/A | 1.9 s | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | TIMING/finalize/group_similar | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | TIMING/finalize/calculate_statistics | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | TIMING/finalize/calculate_statistics/sort_selection | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | TIMING/finalize/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | TIMING/finalize/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | TIMING/render/normalize_data | N/A | 1 ms | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | TIMING/total | N/A | 1.9 s | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/rss_peak | N/A | 37.6 MB | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/bucket_outcomes | N/A | 1.3 KB | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/format_scan_subs | N/A | 1.1 MB | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/log_analysis | N/A | 240 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/log_messages | N/A | 240 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/log_occurrences | N/A | 4.5 KB | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/log_stats | N/A | 1.7 KB | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/log_threadpools | N/A | 240 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/log_users | N/A | 8.5 KB | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/message_key_order | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/threadpool_activity | N/A | 778 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/unattributed | N/A | 36.5 MB | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/log_messages | N/A | 240 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/log_analysis | N/A | 240 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | COUNTS/log_messages_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | COUNTS/log_occurrences_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | COUNTS/log_stats_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | COUNTS/log_messages_population | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/bucket_outcomes | N/A | 1.3 KB | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/log_users | N/A | 8.5 KB | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/bucket_outcomes | N/A | 1.3 KB | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_users | N/A | 8.5 KB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | lines_excluded | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/bucket_outcomes | N/A | 1.3 KB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/log_users | N/A | 8.5 KB | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/bucket_outcomes | N/A | 1.3 KB | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/log_users | N/A | 8.5 KB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/bucket_outcomes | N/A | 1.3 KB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_users | N/A | 8.5 KB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | lines_read | N/A | 288,025 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | lines_excluded | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | lines_included | N/A | 288,025 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/detect/registry_build | N/A | 11 ms | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/detect/scan_sub_compile | N/A | 6 ms | N/A | N/A | ? |
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
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/rss_peak | N/A | 37.1 MB | N/A | N/A | ? |
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
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/format_scan_subs | N/A | 1.1 MB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/log_analysis | N/A | 240 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/log_messages | N/A | 240 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/log_occurrences | N/A | 4.5 KB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/log_stats | N/A | 1.7 KB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/log_threadpools | N/A | 240 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/log_users | N/A | 8.5 KB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/message_key_order | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/threadpool_activity | N/A | 778 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/unattributed | N/A | 36 MB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/log_messages | N/A | 240 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/log_analysis | N/A | 240 | N/A | N/A | ? |
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
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | N/A | 1.3 KB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_users | N/A | 8.5 KB | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/bucket_outcomes | N/A | 1.3 KB | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_users | N/A | 8.5 KB | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | lines_excluded | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/bucket_outcomes | N/A | 1.3 KB | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_users | N/A | 8.5 KB | N/A | N/A | ? |
| single-day-application-log-standard | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/bucket_outcomes | N/A | 5.8 KB | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/log_users | N/A | 85.2 KB | N/A | N/A | ? |
| single-day-application-log-no-messages | lines_read | N/A | 479,904 | N/A | N/A | ? |
| single-day-application-log-no-messages | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-no-messages | lines_included | N/A | 479,904 | N/A | N/A | ? |
| single-day-application-log-no-messages | TIMING/detect/registry_build | N/A | 11 ms | N/A | N/A | ? |
| single-day-application-log-no-messages | TIMING/detect/scan_sub_compile | N/A | 6 ms | N/A | N/A | ? |
| single-day-application-log-no-messages | TIMING/parse/read_files | N/A | 3.1 s | N/A | N/A | ? |
| single-day-application-log-no-messages | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-no-messages | TIMING/finalize/group_similar | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-no-messages | TIMING/finalize/calculate_statistics | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-no-messages | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-no-messages | TIMING/finalize/calculate_statistics/sort_selection | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-no-messages | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-no-messages | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-no-messages | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-no-messages | TIMING/finalize/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-no-messages | TIMING/finalize/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-no-messages | TIMING/render/normalize_data | N/A | 1 ms | N/A | N/A | ? |
| single-day-application-log-no-messages | TIMING/total | N/A | 3.1 s | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/rss_peak | N/A | 37.3 MB | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/bucket_outcomes | N/A | 6 KB | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/format_scan_subs | N/A | 1.1 MB | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/log_analysis | N/A | 240 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/log_messages | N/A | 240 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/log_occurrences | N/A | 21.8 KB | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/log_stats | N/A | 7.6 KB | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/log_threadpools | N/A | 240 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/log_users | N/A | 85.2 KB | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/message_key_order | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/threadpool_activity | N/A | 778 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/unattributed | N/A | 36.1 MB | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY_FINAL/log_messages | N/A | 240 | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY_FINAL/log_analysis | N/A | 240 | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-no-messages | COUNTS/log_messages_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-no-messages | COUNTS/log_occurrences_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-no-messages | COUNTS/log_stats_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-no-messages | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-no-messages | COUNTS/log_messages_population | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-no-messages | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-no-messages | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| single-day-application-log-no-messages | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-no-messages | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-no-messages | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-no-messages | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-no-messages | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-application-log-no-messages | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-application-log-top25 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/bucket_outcomes | N/A | 6 KB | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/log_users | N/A | 85.5 KB | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/bucket_outcomes | N/A | 6 KB | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/log_users | N/A | 85.5 KB | N/A | N/A | ? |
| single-day-application-log-heatmap | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/bucket_outcomes | N/A | 6 KB | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/log_users | N/A | 85.2 KB | N/A | N/A | ? |
| single-day-application-log-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/bucket_outcomes | N/A | 6 KB | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/log_users | N/A | 85.2 KB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/bucket_outcomes | N/A | 6 KB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/log_users | N/A | 85.2 KB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | lines_read | N/A | 479,904 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | lines_included | N/A | 479,904 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | TIMING/detect/registry_build | N/A | 12 ms | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | TIMING/detect/scan_sub_compile | N/A | 6 ms | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | TIMING/parse/read_files | N/A | 3.1 s | N/A | N/A | ? |
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
| single-day-application-log-heatmap-histogram-export | MEMORY/rss_peak | N/A | 37.8 MB | N/A | N/A | ? |
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
| single-day-application-log-heatmap-histogram-export | MEMORY/format_scan_subs | N/A | 1.2 MB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_analysis | N/A | 240 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_messages | N/A | 240 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_occurrences | N/A | 21.8 KB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_stats | N/A | 7.9 KB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_threadpools | N/A | 240 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_users | N/A | 85.5 KB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/message_key_order | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/threadpool_activity | N/A | 778 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/unattributed | N/A | 36.5 MB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/log_messages | N/A | 240 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/log_analysis | N/A | 240 | N/A | N/A | ? |
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
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | N/A | 5.8 KB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_users | N/A | 85.2 KB | N/A | N/A | ? |
| single-day-application-log-sort-p99 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/bucket_outcomes | N/A | 6 KB | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/log_users | N/A | 84.7 KB | N/A | N/A | ? |
| single-day-application-log-sort-skewness | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/bucket_outcomes | N/A | 6 KB | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/log_users | N/A | 85.2 KB | N/A | N/A | ? |
| multi-day-application-logs-standard | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/bucket_outcomes | N/A | 13.3 KB | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/log_users | N/A | 40.4 KB | N/A | N/A | ? |
| multi-day-application-logs-no-messages | lines_read | N/A | 930,031 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | lines_included | N/A | 930,028 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | TIMING/detect/registry_build | N/A | 11 ms | N/A | N/A | ? |
| multi-day-application-logs-no-messages | TIMING/detect/scan_sub_compile | N/A | 6 ms | N/A | N/A | ? |
| multi-day-application-logs-no-messages | TIMING/parse/read_files | N/A | 6.5 s | N/A | N/A | ? |
| multi-day-application-logs-no-messages | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-no-messages | TIMING/finalize/group_similar | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-no-messages | TIMING/finalize/calculate_statistics | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-no-messages | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-no-messages | TIMING/finalize/calculate_statistics/sort_selection | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-no-messages | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-no-messages | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-no-messages | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-no-messages | TIMING/finalize/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-no-messages | TIMING/finalize/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-no-messages | TIMING/render/normalize_data | N/A | 2 ms | N/A | N/A | ? |
| multi-day-application-logs-no-messages | TIMING/total | N/A | 6.5 s | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/rss_peak | N/A | 38.7 MB | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/bucket_outcomes | N/A | 13.3 KB | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/format_scan_subs | N/A | 1.2 MB | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/log_analysis | N/A | 240 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/log_messages | N/A | 240 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/log_occurrences | N/A | 56.6 KB | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/log_stats | N/A | 17.1 KB | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/log_threadpools | N/A | 240 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/log_users | N/A | 40.6 KB | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/message_key_order | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/threadpool_activity | N/A | 778 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/unattributed | N/A | 37.4 MB | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY_FINAL/log_messages | N/A | 240 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY_FINAL/log_analysis | N/A | 240 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | COUNTS/log_messages_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | COUNTS/log_occurrences_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | COUNTS/log_stats_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | COUNTS/log_messages_population | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | COUNTS/format_scan_sub_cache_hits | N/A | 40 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | CONFIG/time_bucket_size | N/A | 480 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | CONFIG/bucket_size_seconds | N/A | 28800.00 | N/A | N/A | ? |
| multi-day-application-logs-top25 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/bucket_outcomes | N/A | 13.3 KB | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/log_users | N/A | 40.3 KB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_outcomes | N/A | 13.3 KB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/log_users | N/A | 40.6 KB | N/A | N/A | ? |
| multi-day-application-logs-heatmap | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/bucket_outcomes | N/A | 13.3 KB | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/log_users | N/A | 41.0 KB | N/A | N/A | ? |
| multi-day-application-logs-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/bucket_outcomes | N/A | 13.3 KB | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/log_users | N/A | 40.5 KB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/bucket_outcomes | N/A | 13.3 KB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_users | N/A | 40.7 KB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | lines_read | N/A | 930,031 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | lines_included | N/A | 930,028 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | TIMING/detect/registry_build | N/A | 11 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | TIMING/detect/scan_sub_compile | N/A | 6 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | TIMING/parse/read_files | N/A | 6.5 s | N/A | N/A | ? |
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
| multi-day-application-logs-heatmap-histogram-export | TIMING/total | N/A | 6.5 s | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/rss_peak | N/A | 38.3 MB | N/A | N/A | ? |
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
| multi-day-application-logs-heatmap-histogram-export | MEMORY/format_scan_subs | N/A | 1.1 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_analysis | N/A | 240 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_messages | N/A | 240 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_occurrences | N/A | 56.6 KB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_stats | N/A | 17.1 KB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_threadpools | N/A | 240 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_users | N/A | 40.7 KB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/message_key_order | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/threadpool_activity | N/A | 778 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/unattributed | N/A | 37.2 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/log_messages | N/A | 240 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/log_analysis | N/A | 240 | N/A | N/A | ? |
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
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | N/A | 13.3 KB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_users | N/A | 40.5 KB | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/bucket_outcomes | N/A | 13.3 KB | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/log_users | N/A | 41.0 KB | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/bucket_outcomes | N/A | 13.3 KB | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/log_users | N/A | 40.8 KB | N/A | N/A | ? |
| multi-day-custom-logs-standard | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/bucket_outcomes | N/A | 6.3 KB | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/log_users | N/A | 12.7 KB | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | lines_read | N/A | 1,530,399 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | lines_included | N/A | 1,530,399 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | TIMING/detect/registry_build | N/A | 11 ms | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | TIMING/detect/scan_sub_compile | N/A | 6 ms | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | TIMING/parse/read_files | N/A | 13 s | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | TIMING/finalize/group_similar | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | TIMING/finalize/calculate_statistics | N/A | 46 ms | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 46 ms | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | TIMING/finalize/calculate_statistics/sort_selection | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | TIMING/finalize/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | TIMING/finalize/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | TIMING/render/normalize_data | N/A | 1 ms | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | TIMING/total | N/A | 13.1 s | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/rss_peak | N/A | 71.3 MB | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/bucket_outcomes | N/A | 6.3 KB | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/format_scan_subs | N/A | 1.1 MB | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/log_analysis | N/A | 28.4 MB | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/log_messages | N/A | 240 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/log_occurrences | N/A | 20.3 KB | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/log_stats | N/A | 55 KB | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/log_threadpools | N/A | 240 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/log_users | N/A | 12.7 KB | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/message_key_order | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/threadpool_activity | N/A | 778 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/unattributed | N/A | 41.7 MB | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/log_messages | N/A | 240 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/log_analysis | N/A | 20350 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | COUNTS/log_messages_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | COUNTS/log_occurrences_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | COUNTS/log_stats_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | COUNTS/log_analysis_entries | N/A | 24 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | COUNTS/log_messages_population | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | COUNTS/format_scan_sub_cache_hits | N/A | 4 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/bucket_outcomes | N/A | 6.3 KB | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/log_users | N/A | 12.7 KB | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/bucket_outcomes | N/A | 6.3 KB | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_users | N/A | 12.7 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/bucket_outcomes | N/A | 6.3 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/log_users | N/A | 12.7 KB | N/A | N/A | ? |
| multi-day-custom-logs-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/bucket_outcomes | N/A | 6.3 KB | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/log_users | N/A | 12.7 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/bucket_outcomes | N/A | 6.3 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_users | N/A | 12.7 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | lines_read | N/A | 1,530,399 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | lines_included | N/A | 1,530,399 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/detect/registry_build | N/A | 11 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/detect/scan_sub_compile | N/A | 6 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/parse/read_files | N/A | 14.4 s | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/group_similar | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics | N/A | 111 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 110 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/sort_selection | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | N/A | 154 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/histogram_statistics | N/A | 14 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/render/normalize_data | N/A | 1 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/total | N/A | 14.7 s | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/rss_peak | N/A | 75.5 MB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/bucket_outcomes | N/A | 6.3 KB | N/A | N/A | ? |
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
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/format_scan_subs | N/A | 1.1 MB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_counters | N/A | 987.2 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_counters_hl | N/A | 240 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_data | N/A | 43.2 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/histogram_counters | N/A | 122.6 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_analysis | N/A | 28.4 MB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_messages | N/A | 240 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_occurrences | N/A | 20.3 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_stats | N/A | 83.1 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_threadpools | N/A | 240 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_users | N/A | 12.7 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/message_key_order | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/threadpool_activity | N/A | 778 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/unattributed | N/A | 44.7 MB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/log_messages | N/A | 240 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/log_analysis | N/A | 24647 | N/A | N/A | ? |
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
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | N/A | 6.3 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_users | N/A | 12.7 KB | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/bucket_outcomes | N/A | 6.3 KB | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/log_users | N/A | 12.7 KB | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/bucket_outcomes | N/A | 6.3 KB | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/log_users | N/A | 12.7 KB | N/A | N/A | ? |
| single-day-access-log-standard | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/bucket_outcomes | N/A | 3.8 KB | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | lines_read | N/A | 761,698 | N/A | N/A | ? |
| single-day-access-log-no-messages | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-no-messages | lines_included | N/A | 761,698 | N/A | N/A | ? |
| single-day-access-log-no-messages | TIMING/detect/registry_build | N/A | 11 ms | N/A | N/A | ? |
| single-day-access-log-no-messages | TIMING/detect/scan_sub_compile | N/A | 6 ms | N/A | N/A | ? |
| single-day-access-log-no-messages | TIMING/parse/read_files | N/A | 6.8 s | N/A | N/A | ? |
| single-day-access-log-no-messages | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-no-messages | TIMING/finalize/group_similar | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-no-messages | TIMING/finalize/calculate_statistics | N/A | 88 ms | N/A | N/A | ? |
| single-day-access-log-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 88 ms | N/A | N/A | ? |
| single-day-access-log-no-messages | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-no-messages | TIMING/finalize/calculate_statistics/sort_selection | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-no-messages | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-no-messages | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-no-messages | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-no-messages | TIMING/finalize/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-no-messages | TIMING/finalize/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-no-messages | TIMING/render/normalize_data | N/A | 1 ms | N/A | N/A | ? |
| single-day-access-log-no-messages | TIMING/total | N/A | 6.9 s | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/rss_peak | N/A | 97.0 MB | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/bucket_outcomes | N/A | 3.8 KB | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/format_scan_subs | N/A | 1.2 MB | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/log_analysis | N/A | 52.7 MB | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/log_messages | N/A | 240 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/log_occurrences | N/A | 18.4 KB | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/log_stats | N/A | 30.5 KB | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/log_threadpools | N/A | 240 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/message_key_order | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/threadpool_activity | N/A | 778 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/unattributed | N/A | 43 MB | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY_FINAL/log_messages | N/A | 240 | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY_FINAL/log_analysis | N/A | 6678 | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-no-messages | COUNTS/log_messages_entries | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-no-messages | COUNTS/log_occurrences_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-no-messages | COUNTS/log_stats_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-no-messages | COUNTS/log_analysis_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-no-messages | COUNTS/log_messages_population | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-no-messages | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-no-messages | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| single-day-access-log-no-messages | COUNTS/format_scan_sub_cache_hits | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-no-messages | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-no-messages | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| single-day-access-log-no-messages | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-no-messages | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-access-log-no-messages | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-access-log-top25 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/bucket_outcomes | N/A | 3.8 KB | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/bucket_outcomes | N/A | 3.8 KB | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/bucket_outcomes | N/A | 3.8 KB | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/bucket_outcomes | N/A | 3.8 KB | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/bucket_outcomes | N/A | 3.8 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | lines_read | N/A | 761,698 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | lines_included | N/A | 761,698 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/detect/registry_build | N/A | 11 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/detect/scan_sub_compile | N/A | 6 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/parse/read_files | N/A | 9.7 s | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/group_similar | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics | N/A | 205 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 205 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics/sort_selection | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | N/A | 97 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/histogram_statistics | N/A | 11 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/render/normalize_data | N/A | 1 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/total | N/A | 10.0 s | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/rss_peak | N/A | 100.8 MB | N/A | N/A | ? |
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
| single-day-access-log-heatmap-histogram-export | MEMORY/format_scan_subs | N/A | 1.1 MB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_counters | N/A | 571.2 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_counters_hl | N/A | 240 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_data | N/A | 34 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/histogram_counters | N/A | 105.9 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_analysis | N/A | 52.7 MB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_messages | N/A | 240 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_occurrences | N/A | 18.4 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_stats | N/A | 49.5 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_threadpools | N/A | 240 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/message_key_order | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/threadpool_activity | N/A | 778 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/unattributed | N/A | 46.2 MB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/log_messages | N/A | 240 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/log_analysis | N/A | 12095 | N/A | N/A | ? |
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
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | N/A | 3.8 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/bucket_outcomes | N/A | 3.8 KB | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | lines_excluded | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/bucket_outcomes | N/A | 3.8 KB | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | lines_included | N/A | 7,749,159 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | TIMING/detect/registry_build | N/A | 11 ms | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | TIMING/detect/scan_sub_compile | N/A | 13 ms | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | TIMING/parse/read_files | N/A | 1.2 min | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | TIMING/finalize/group_similar | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | TIMING/finalize/calculate_statistics | N/A | 1.9 s | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 1.9 s | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | TIMING/finalize/calculate_statistics/sort_selection | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | TIMING/finalize/calculate_statistics/untimed | N/A | 2 ms | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | TIMING/finalize/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | TIMING/finalize/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | TIMING/render/normalize_data | N/A | 1 ms | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | TIMING/total | N/A | 1.2 min | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/rss_peak | N/A | 649.3 MB | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/format_scan_subs | N/A | 2.0 MB | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/log_analysis | N/A | 566.1 MB | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/log_messages | N/A | 240 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/log_occurrences | N/A | 36.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/log_sessions | N/A | 2.2 MB | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/log_stats | N/A | 58.3 KB | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/log_threadpools | N/A | 240 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/message_key_order | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/threadpool_activity | N/A | 778 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/unattributed | N/A | 79.0 MB | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/log_messages | N/A | 240 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/log_analysis | N/A | 13018 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | COUNTS/log_messages_entries | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | COUNTS/log_messages_population | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | COUNTS/format_scan_subs_compiled | N/A | 2 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | COUNTS/format_scan_sub_cache_hits | N/A | 27 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | lines_included | N/A | 7,749,159 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/detect/registry_build | N/A | 11 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/detect/scan_sub_compile | N/A | 13 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/parse/read_files | N/A | 1.8 min | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/group_similar | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics | N/A | 3 s | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 3 s | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/sort_selection | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/untimed | N/A | 2 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | N/A | 222 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/histogram_statistics | N/A | 18 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/render/normalize_data | N/A | 1 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/total | N/A | 1.8 min | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/rss_peak | N/A | 650.3 MB | N/A | N/A | ? |
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
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/format_scan_subs | N/A | 2 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters | N/A | 2.4 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters_hl | N/A | 240 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_data | N/A | 75.9 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/histogram_counters | N/A | 296 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_analysis | N/A | 566.1 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_messages | N/A | 240 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_occurrences | N/A | 36.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_sessions | N/A | 2.2 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_stats | N/A | 94 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_threadpools | N/A | 240 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/message_key_order | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/threadpool_activity | N/A | 778 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/unattributed | N/A | 77.1 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_messages | N/A | 240 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_analysis | N/A | 23011 | N/A | N/A | ? |
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
| month-single-server-access-logs-heatmap-histogram-export | COUNTS/format_scan_subs_compiled | N/A | 2 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | COUNTS/format_scan_sub_cache_hits | N/A | 27 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | lines_included | N/A | 38,672,411 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | TIMING/detect/registry_build | N/A | 12 ms | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | TIMING/detect/scan_sub_compile | N/A | 19 ms | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | TIMING/parse/read_files | N/A | 6.0 min | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | TIMING/finalize/group_similar | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | TIMING/finalize/calculate_statistics | N/A | 12.2 s | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 12.2 s | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | TIMING/finalize/calculate_statistics/sort_selection | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | TIMING/finalize/calculate_statistics/untimed | N/A | 12 ms | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | TIMING/finalize/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | TIMING/finalize/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | TIMING/render/normalize_data | N/A | 2 ms | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | TIMING/total | N/A | 6.2 min | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/rss_peak | N/A | 3.4 GB | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/format_scan_subs | N/A | 2.9 MB | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/log_analysis | N/A | 2.9 GB | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/log_messages | N/A | 240 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/log_occurrences | N/A | 42.1 KB | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/log_sessions | N/A | 14.9 MB | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/log_stats | N/A | 58.7 KB | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/log_threadpools | N/A | 240 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/message_key_order | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/threadpool_activity | N/A | 778 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/unattributed | N/A | 479.2 MB | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/log_messages | N/A | 240 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/log_analysis | N/A | 13018 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | COUNTS/log_messages_entries | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | COUNTS/log_messages_population | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | COUNTS/format_scan_subs_compiled | N/A | 3 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | COUNTS/format_scan_sub_cache_hits | N/A | 142 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | lines_included | N/A | 38,672,411 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/detect/registry_build | N/A | 11 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/detect/scan_sub_compile | N/A | 19 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/parse/read_files | N/A | 8.9 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/group_similar | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics | N/A | 17.8 s | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 17.8 s | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/sort_selection | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/untimed | N/A | 12 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | N/A | 235 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/histogram_statistics | N/A | 19 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/render/normalize_data | N/A | 2 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/total | N/A | 9.2 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/rss_peak | N/A | 3.4 GB | N/A | N/A | ? |
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
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/format_scan_subs | N/A | 2.7 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters | N/A | 2.7 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters_hl | N/A | 240 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_data | N/A | 76.8 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/histogram_counters | N/A | 307.8 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_analysis | N/A | 2.9 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_messages | N/A | 240 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_occurrences | N/A | 43.8 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_sessions | N/A | 14.9 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_stats | N/A | 95.6 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_threadpools | N/A | 240 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/message_key_order | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/threadpool_activity | N/A | 778 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/unattributed | N/A | 482 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_messages | N/A | 240 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_analysis | N/A | 23011 | N/A | N/A | ? |
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
| month-many-servers-access-logs-heatmap-histogram-export | COUNTS/format_scan_subs_compiled | N/A | 3 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | COUNTS/format_scan_sub_cache_hits | N/A | 142 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |

