
## Benchmark Comparison

  Baseline:    v0.19.0-second (v0.19.0, 77 test cases)
  Current:     v0.19.0-third (v0.19.0, 77 test cases)

### Timing Delta

| # | file selection | standard | no-msgs | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons | sort-p99 | sort-skew | hm+hg+export |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | -3.1% | -2.1% | -1.8% | -2.4% | -1.4% | -1.4% | -1.7% | -2.1% | -1.8% | -2.1% | -1.9% |
| 2. | single-day-application-log | -2.5% | -0.8% | -4.0% | -2.8% | -3.8% | -1.3% | -4.2% | -3.2% | -2.7% | -1.5% | -2.5% |
| 3. | multi-day-application-logs | -3.2% | -1.0% | -3.7% | -1.1% | -3.3% | -3.2% | -3.0% | -0.6% | -2.6% | -1.7% | -2.6% |
| 4. | multi-day-custom-logs | -6.0% | -3.3% | -5.1% | -1.8% | -5.5% | -6.7% | -5.3% | -2.9% | -4.5% | -5.2% | -2.7% |
| 5. | single-day-access-log | -9.7% | -7.0% | -12.2% | -9.1% | -10.4% | -9.4% | -8.1% | -5.4% | -9.6% | -9.4% | -4.6% |
| 6. | month-single-server-access-logs | -9.1% | -6.9% | -8.6% | -5.4% | -7.5% | -7.0% | -6.6% | -5.0% | -8.9% | -9.3% | -3.7% |
| 7. | month-many-servers-access-logs | -9.0% | -6.0% | -9.1% | -5.4% | -7.6% | -6.8% | -6.4% | -4.2% | -7.8% | -9.0% | -4.9% |

### Memory Delta (RSS Peak)

| # | file selection | standard | no-msgs | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons | sort-p99 | sort-skew | hm+hg+export |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | -0.8% | -3.3% | -0.4% | -1.4% | -0.3% | -0.4% | -0.3% | -1.1% | -0.3% | -0.2% | -1.8% |
| 2. | single-day-application-log | -1.5% | -2.0% | -1.6% | +1.3% | -2.2% | -0.9% | -1.6% | -2.6% | -1.2% | -2.5% | -0.9% |
| 3. | multi-day-application-logs | -0.8% | -1.7% | +0.0% | -0.7% | -0.6% | -0.5% | -0.7% | -1.9% | -0.6% | -0.3% | -1.6% |
| 4. | multi-day-custom-logs | +0.3% | -1.9% | -1.8% | -2.7% | -0.5% | -0.4% | -0.5% | +1.5% | -0.9% | -8.5% | -3.4% |
| 5. | single-day-access-log | -0.6% | -2.1% | -0.0% | +0.1% | -0.3% | +0.7% | -0.8% | -2.6% | +1.3% | -21.2% | -5.3% |
| 6. | month-single-server-access-logs | +4.0% | -0.7% | +0.2% | +18.0% | +4.8% | +0.1% | -4.6% | +0.2% | +0.0% | -2.0% | -0.2% |
| 7. | month-many-servers-access-logs | +0.2% | -1.0% | +0.0% | +0.2% | +0.0% | +4.3% | +0.1% | -0.2% | +3.9% | -5.7% | +0.1% |

### Stage Rollup (timing)

| metric | baseline | current | delta | change% | cases +/- | result |
| --- | --- | --- | --- | --- | --- | --- |
| parse/read_files | 121.9 min | 113.4 min | -8.5 min | -7.0% | 0/77 | IMPROVE |
| finalize/group_similar | 56.7 s | 57.2 s | +424 ms | 0.7% | 7/7 | REGRESS |
| finalize/calculate_statistics | 4.8 min | 4.9 min | +2.1 s | 0.7% | 30/20 | REGRESS |
| finalize/calculate_statistics/bucket_stats (within parent) | 1.7 min | 1.7 min | +469 ms | 0.5% | 21/4 | REGRESS |
| finalize/calculate_statistics/population_walk (within parent) | 1 min | 1 min | +376 ms | 0.6% | 3/5 | REGRESS (most cases IMPROVE) |
| finalize/calculate_statistics/sort_selection (within parent) | 1.3 min | 1.3 min | +1.2 s | 1.6% | 21/13 | REGRESS |
| total | 127.7 min | 119.3 min | -8.4 min | -6.6% | 0/77 | IMPROVE |
| (4 below noise floor) | 3.7 s | 3.7 s | +63 ms | 1.7% | - | REGRESS |
| (3 below noise floor) (within parent) | 54.3 s | 54.3 s | +51 ms | 0.1% | - | REGRESS |
| sum of stages | 127.7 min | 119.3 min | -8.4 min | -6.6% | - | IMPROVE |

### Category Rollup (memory)

| metric | baseline | current | delta | change% | cases +/- | result |
| --- | --- | --- | --- | --- | --- | --- |
| rss_peak | 91.7 GB | 92.0 GB | +296.3 MB | 0.3% | 22/55 | REGRESS (most cases IMPROVE) |
| log_messages | 60.7 GB | 60.9 GB | +264.3 MB | 0.4% | 11/9 | REGRESS |
| unattributed | 15.2 GB | 15.3 GB | +40.7 MB | 0.3% | 19/56 | REGRESS (most cases IMPROVE) |
| consolidation_id_index | 841.4 MB | 836.3 MB | -5.1 MB | -0.6% | 4/7 | IMPROVE |
| consolidation_key_trigrams | 433.0 MB | 428 MB | -5.0 MB | -1.1% | 4/8 | IMPROVE |
| format_scan_subs | 145.5 MB | 147.7 MB | +2.1 MB | 1.4% | 44/22 | REGRESS |
| log_analysis | 11.6 GB | 11.6 GB | +1.4 MB | 0.0% | 10/5 | REGRESS |
| (25 below noise floor) | 2.9 GB | 2.9 GB | -14.7 KB | -0.0% | - | IMPROVE |

### New In This Version

| metric | test cases | per-test range | aggregate |
| --- | --- | --- | --- |
| (none) | - | - | - |

### Summary

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.8 s | 2.7 s | -87 ms | -3.1% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 268.4 MB | 266.4 MB | -2 MB | -0.8% | IMPROVE |
| humungous-log-uniqueness-no-messages | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | TIMING/total | 1.9 s | 1.8 s | -40 ms | -2.1% | IMPROVE |
| humungous-log-uniqueness-no-messages | MEMORY/rss_peak | 42 MB | 40.7 MB | -1.4 MB | -3.3% | IMPROVE |
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.7 s | 2.6 s | -48 ms | -1.8% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 267.9 MB | 266.8 MB | -1.1 MB | -0.4% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 4.0 s | 3.9 s | -96 ms | -2.4% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 53.2 MB | 52.5 MB | -736 KB | -1.4% | IMPROVE |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.7 s | 2.6 s | -38 ms | -1.4% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 267.6 MB | 266.7 MB | -896 KB | -0.3% | IMPROVE |
| humungous-log-uniqueness-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.7 s | 2.6 s | -37 ms | -1.4% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 267.9 MB | 266.8 MB | -1.1 MB | -0.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.7 s | 2.6 s | -45 ms | -1.7% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 267.4 MB | 266.7 MB | -704 KB | -0.3% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-export | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/total | 1.9 s | 1.8 s | -36 ms | -1.9% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/rss_peak | 41.8 MB | 41 MB | -752 KB | -1.8% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 3.9 s | 3.9 s | -83 ms | -2.1% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 53.1 MB | 52.5 MB | -608 KB | -1.1% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/total | 2.6 s | 2.6 s | -48 ms | -1.8% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | MEMORY/rss_peak | 267.9 MB | 267.1 MB | -784 KB | -0.3% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/total | 2.7 s | 2.6 s | -57 ms | -2.1% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | MEMORY/rss_peak | 267.5 MB | 267.1 MB | -464 KB | -0.2% | IMPROVE |
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.5 s | 3.5 s | -87 ms | -2.5% | IMPROVE |
| single-day-application-log-standard | MEMORY/rss_peak | 45.7 MB | 45.0 MB | -720 KB | -1.5% | IMPROVE |
| single-day-application-log-no-messages | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-no-messages | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-no-messages | TIMING/total | 2.9 s | 2.9 s | -24 ms | -0.8% | IMPROVE |
| single-day-application-log-no-messages | MEMORY/rss_peak | 41.5 MB | 40.7 MB | -832 KB | -2.0% | IMPROVE |
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.5 s | 3.4 s | -142 ms | -4.0% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 45.7 MB | 44.9 MB | -768 KB | -1.6% | IMPROVE |
| single-day-application-log-top25-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 5.2 s | 5.1 s | -147 ms | -2.8% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 114.6 MB | 116 MB | +1.5 MB | 1.3% | REGRESS |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.6 s | 3.4 s | -135 ms | -3.8% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/rss_peak | 45.5 MB | 44.5 MB | -1 MB | -2.2% | IMPROVE |
| single-day-application-log-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.5 s | 3.4 s | -44 ms | -1.3% | IMPROVE |
| single-day-application-log-histogram | MEMORY/rss_peak | 45.3 MB | 44.9 MB | -416 KB | -0.9% | IMPROVE |
| single-day-application-log-heatmap-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.6 s | 3.4 s | -149 ms | -4.2% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 45.3 MB | 44.6 MB | -720 KB | -1.6% | IMPROVE |
| single-day-application-log-heatmap-histogram-export | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | TIMING/total | 3 s | 2.9 s | -75 ms | -2.5% | IMPROVE |
| single-day-application-log-heatmap-histogram-export | MEMORY/rss_peak | 41.5 MB | 41.1 MB | -400 KB | -0.9% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 5.2 s | 5 s | -169 ms | -3.2% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 116.6 MB | 113.5 MB | -3 MB | -2.6% | IMPROVE |
| single-day-application-log-sort-p99 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/total | 3.6 s | 3.5 s | -97 ms | -2.7% | IMPROVE |
| single-day-application-log-sort-p99 | MEMORY/rss_peak | 45.2 MB | 44.6 MB | -576 KB | -1.2% | IMPROVE |
| single-day-application-log-sort-skewness | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/total | 3.5 s | 3.5 s | -52 ms | -1.5% | IMPROVE |
| single-day-application-log-sort-skewness | MEMORY/rss_peak | 45.6 MB | 44.4 MB | -1.1 MB | -2.5% | IMPROVE |
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 7.9 s | 7.6 s | -253 ms | -3.2% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/rss_peak | 110.3 MB | 109.5 MB | -848 KB | -0.8% | IMPROVE |
| multi-day-application-logs-no-messages | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | TIMING/total | 6.3 s | 6.2 s | -61 ms | -1.0% | IMPROVE |
| multi-day-application-logs-no-messages | MEMORY/rss_peak | 43.3 MB | 42.5 MB | -752 KB | -1.7% | IMPROVE |
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 7.8 s | 7.5 s | -286 ms | -3.7% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 110.3 MB | 110.3 MB | +16 KB | 0.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 31.6 s | 31.2 s | -344 ms | -1.1% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 233.7 MB | 232.0 MB | -1.7 MB | -0.7% | IMPROVE |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 7.8 s | 7.5 s | -254 ms | -3.3% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 110.3 MB | 109.6 MB | -704 KB | -0.6% | IMPROVE |
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 7.7 s | 7.5 s | -249 ms | -3.2% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 110.8 MB | 110.2 MB | -608 KB | -0.5% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 7.8 s | 7.5 s | -231 ms | -3.0% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 110.5 MB | 109.8 MB | -784 KB | -0.7% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-export | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | TIMING/total | 6.4 s | 6.3 s | -169 ms | -2.6% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/rss_peak | 43.2 MB | 42.5 MB | -704 KB | -1.6% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 31.4 s | 31.3 s | -194 ms | -0.6% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 233.4 MB | 228.9 MB | -4.5 MB | -1.9% | IMPROVE |
| multi-day-application-logs-sort-p99 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/total | 7.7 s | 7.5 s | -201 ms | -2.6% | IMPROVE |
| multi-day-application-logs-sort-p99 | MEMORY/rss_peak | 110.4 MB | 109.7 MB | -720 KB | -0.6% | IMPROVE |
| multi-day-application-logs-sort-skewness | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/total | 7.7 s | 7.6 s | -133 ms | -1.7% | IMPROVE |
| multi-day-application-logs-sort-skewness | MEMORY/rss_peak | 109.9 MB | 109.6 MB | -288 KB | -0.3% | IMPROVE |
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 15.9 s | 14.9 s | -949 ms | -6.0% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 178.8 MB | 179.4 MB | +640 KB | 0.3% | REGRESS |
| multi-day-custom-logs-no-messages | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | TIMING/total | 12.7 s | 12.3 s | -419 ms | -3.3% | IMPROVE |
| multi-day-custom-logs-no-messages | MEMORY/rss_peak | 57 MB | 55.9 MB | -1.1 MB | -1.9% | IMPROVE |
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 15.9 s | 15.1 s | -807 ms | -5.1% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 180.2 MB | 177 MB | -3.2 MB | -1.8% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 37.1 s | 36.4 s | -673 ms | -1.8% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 233.9 MB | 227.5 MB | -6.4 MB | -2.7% | IMPROVE |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 16.4 s | 15.5 s | -910 ms | -5.5% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 174.2 MB | 173.4 MB | -816 KB | -0.5% | IMPROVE |
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 16.8 s | 15.6 s | -1.1 s | -6.7% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 178.8 MB | 178 MB | -816 KB | -0.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 17.1 s | 16.2 s | -910 ms | -5.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 174.3 MB | 173.5 MB | -832 KB | -0.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/total | 14.5 s | 14.1 s | -389 ms | -2.7% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/rss_peak | 59.8 MB | 57.7 MB | -2 MB | -3.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 38.6 s | 37.5 s | -1.1 s | -2.9% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 227 MB | 230.5 MB | +3.5 MB | 1.5% | REGRESS |
| multi-day-custom-logs-sort-p99 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/total | 15.6 s | 14.9 s | -709 ms | -4.5% | IMPROVE |
| multi-day-custom-logs-sort-p99 | MEMORY/rss_peak | 177.7 MB | 176.2 MB | -1.5 MB | -0.9% | IMPROVE |
| multi-day-custom-logs-sort-skewness | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/total | 15.8 s | 15 s | -816 ms | -5.2% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY/rss_peak | 191.8 MB | 175.5 MB | -16.4 MB | -8.5% | IMPROVE |
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 8.4 s | 7.6 s | -812 ms | -9.7% | IMPROVE |
| single-day-access-log-standard | MEMORY/rss_peak | 98.9 MB | 98.3 MB | -656 KB | -0.6% | IMPROVE |
| single-day-access-log-no-messages | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-no-messages | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-no-messages | TIMING/total | 6.8 s | 6.3 s | -481 ms | -7.0% | IMPROVE |
| single-day-access-log-no-messages | MEMORY/rss_peak | 68.4 MB | 66.9 MB | -1.4 MB | -2.1% | IMPROVE |
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 8.6 s | 7.5 s | -1 s | -12.2% | IMPROVE |
| single-day-access-log-top25 | MEMORY/rss_peak | 98.5 MB | 98.5 MB | -32 KB | -0.0% | IMPROVE |
| single-day-access-log-top25-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 9.9 s | 9.0 s | -903 ms | -9.1% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 129.5 MB | 129.6 MB | +80 KB | 0.1% | REGRESS |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 9.3 s | 8.3 s | -965 ms | -10.4% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/rss_peak | 80.8 MB | 80.5 MB | -256 KB | -0.3% | IMPROVE |
| single-day-access-log-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 10.6 s | 9.6 s | -994 ms | -9.4% | IMPROVE |
| single-day-access-log-histogram | MEMORY/rss_peak | 98.5 MB | 99.2 MB | +704 KB | 0.7% | REGRESS |
| single-day-access-log-heatmap-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 11 s | 10.1 s | -894 ms | -8.1% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 80.1 MB | 79.4 MB | -688 KB | -0.8% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | TIMING/total | 9.9 s | 9.4 s | -456 ms | -4.6% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | MEMORY/rss_peak | 71.4 MB | 67.5 MB | -3.8 MB | -5.3% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 12.3 s | 11.6 s | -663 ms | -5.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 107.5 MB | 104.7 MB | -2.8 MB | -2.6% | IMPROVE |
| single-day-access-log-sort-p99 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/total | 8.4 s | 7.6 s | -809 ms | -9.6% | IMPROVE |
| single-day-access-log-sort-p99 | MEMORY/rss_peak | 97.3 MB | 98.5 MB | +1.2 MB | 1.3% | REGRESS |
| single-day-access-log-sort-skewness | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/total | 8.6 s | 7.8 s | -812 ms | -9.4% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY/rss_peak | 124.3 MB | 98.0 MB | -26.3 MB | -21.2% | IMPROVE |
| month-single-server-access-logs-standard | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/total | 1.6 min | 1.4 min | -8.6 s | -9.1% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 1.7 GB | 1.8 GB | +71.5 MB | 4.0% | REGRESS |
| month-single-server-access-logs-no-messages | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | TIMING/total | 1.2 min | 1.1 min | -5.1 s | -6.9% | IMPROVE |
| month-single-server-access-logs-no-messages | MEMORY/rss_peak | 356.8 MB | 354.2 MB | -2.7 MB | -0.7% | IMPROVE |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 1.6 min | 1.4 min | -8.2 s | -8.6% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 1.7 GB | 1.7 GB | +2.9 MB | 0.2% | REGRESS |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 2 min | 1.9 min | -6.5 s | -5.4% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 821.3 MB | 969.3 MB | +148 MB | 18.0% | REGRESS |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/total | 1.7 min | 1.6 min | -7.7 s | -7.5% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 1.5 GB | 1.6 GB | +74.4 MB | 4.8% | REGRESS |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/total | 2.0 min | 1.8 min | -8.1 s | -7.0% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 1.7 GB | 1.7 GB | +1008 KB | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2 min | 1.9 min | -8.1 s | -6.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 1.6 GB | 1.5 GB | -75.3 MB | -4.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/total | 1.8 min | 1.7 min | -4 s | -3.7% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/rss_peak | 358.1 MB | 357.2 MB | -864 KB | -0.2% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 2.4 min | 2.3 min | -7.3 s | -5.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 637.1 MB | 638.6 MB | +1.5 MB | 0.2% | REGRESS |
| month-single-server-access-logs-sort-p99 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | TIMING/total | 1.7 min | 1.5 min | -9.0 s | -8.9% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/rss_peak | 1.9 GB | 1.9 GB | +960 KB | 0.0% | REGRESS |
| month-single-server-access-logs-sort-skewness | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/total | 1.6 min | 1.5 min | -8.9 s | -9.3% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/rss_peak | 1.9 GB | 1.9 GB | -38.8 MB | -2.0% | IMPROVE |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/total | 8.0 min | 7.3 min | -43.3 s | -9.0% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 9.1 GB | 9.1 GB | +18.5 MB | 0.2% | REGRESS |
| month-many-servers-access-logs-no-messages | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | TIMING/total | 6.2 min | 5.8 min | -22.4 s | -6.0% | IMPROVE |
| month-many-servers-access-logs-no-messages | MEMORY/rss_peak | 1.6 GB | 1.6 GB | -15.6 MB | -1.0% | IMPROVE |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/total | 7.9 min | 7.2 min | -43.5 s | -9.1% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 8.7 GB | 8.7 GB | +4.1 MB | 0.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 10.3 min | 9.8 min | -33.4 s | -5.4% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 3.4 GB | 3.4 GB | +5.7 MB | 0.2% | REGRESS |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/total | 8.6 min | 7.9 min | -39.3 s | -7.6% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 7.9 GB | 7.9 GB | +2.5 MB | 0.0% | REGRESS |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/total | 9.8 min | 9.1 min | -40 s | -6.8% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 8.7 GB | 9.1 GB | +386.4 MB | 4.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 10.2 min | 9.6 min | -39.5 s | -6.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 7.5 GB | 7.5 GB | +9.2 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/total | 9.2 min | 8.7 min | -27.2 s | -4.9% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/rss_peak | 1.6 GB | 1.6 GB | +2.0 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 12.4 min | 11.9 min | -31.2 s | -4.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 2.7 GB | 2.7 GB | -5.7 MB | -0.2% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | TIMING/total | 8.6 min | 7.9 min | -40.0 s | -7.8% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/rss_peak | 9.6 GB | 10.0 GB | +381.9 MB | 3.9% | REGRESS |
| month-many-servers-access-logs-sort-skewness | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | TIMING/total | 8.1 min | 7.4 min | -43.7 s | -9.0% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY/rss_peak | 9.9 GB | 9.3 GB | -582.5 MB | -5.7% | IMPROVE |

### Detailed

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/detect/registry_build | 21 ms | 22 ms | +1000 us | 4.8% | REGRESS |
| humungous-log-uniqueness-standard | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/parse/read_files | 2.5 s | 2.4 s | -92 ms | -3.7% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics | 306 ms | 310 ms | +4 ms | 1.3% | REGRESS |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics/sort_selection | 293 ms | 298 ms | +5 ms | 1.7% | REGRESS |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.8 s | 2.7 s | -87 ms | -3.1% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 268.4 MB | 266.4 MB | -2 MB | -0.8% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/format_scan_subs | 1.4 MB | 1.5 MB | +48 KB | 3.3% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_messages | 172.9 MB | 172.9 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_stats | 1.7 KB | 1.7 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_users | 8.5 KB | 8.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/unattributed | 94.1 MB | 92.0 MB | -2.1 MB | -2.2% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY_FINAL/log_messages | 181319175 | 181319175 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| humungous-log-uniqueness-no-messages | TIMING/detect/registry_build | 21 ms | 21 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-no-messages | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-no-messages | TIMING/parse/read_files | 1.9 s | 1.8 s | -41 ms | -2.2% | IMPROVE |
| humungous-log-uniqueness-no-messages | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-no-messages | TIMING/total | 1.9 s | 1.8 s | -40 ms | -2.1% | IMPROVE |
| humungous-log-uniqueness-no-messages | MEMORY/rss_peak | 42 MB | 40.7 MB | -1.4 MB | -3.3% | IMPROVE |
| humungous-log-uniqueness-no-messages | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/format_scan_subs | 1.5 MB | 1.4 MB | -96 KB | -6.2% | IMPROVE |
| humungous-log-uniqueness-no-messages | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/log_stats | 1.7 KB | 1.7 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/log_users | 8.5 KB | 8.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/unattributed | 40.5 MB | 39.2 MB | -1.3 MB | -3.2% | IMPROVE |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| humungous-log-uniqueness-top25 | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/parse/read_files | 2.3 s | 2.3 s | -27 ms | -1.2% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics | 321 ms | 300 ms | -21 ms | -6.5% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics/sort_selection | 309 ms | 287 ms | -22 ms | -7.1% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics/untimed | 12 ms | 13 ms | +1000 us | 8.3% | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.7 s | 2.6 s | -48 ms | -1.8% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 267.9 MB | 266.8 MB | -1.1 MB | -0.4% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/format_scan_subs | 1.5 MB | 1.5 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_messages | 172.9 MB | 172.9 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_stats | 1.7 KB | 1.7 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_users | 8.5 KB | 8.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/message_key_order | 7.7 KB | 7.7 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/unattributed | 93.5 MB | 92.4 MB | -1.1 MB | -1.2% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/log_messages | 181321335 | 181321335 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| humungous-log-uniqueness-top25-consolidate | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/parse/read_files | 3.2 s | 3.1 s | -90 ms | -2.8% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | TIMING/finalize/group_similar | 742 ms | 736 ms | -6 ms | -0.8% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 4.0 s | 3.9 s | -96 ms | -2.4% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 53.2 MB | 52.5 MB | -736 KB | -1.4% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_clusters | 197.9 KB | 197.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_id_index | 5.7 MB | 5.7 MB | +2 KB | 0.0% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_message | 231.4 KB | 231.4 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_trigrams | 2.8 MB | 2.8 MB | +2 KB | 0.1% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_patterns | 24.9 KB | 24.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_unmatched | 129.7 KB | 129.8 KB | +128 B | 0.1% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/format_scan_subs | 1.5 MB | 1.5 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_messages | 226.6 KB | 226.6 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_stats | 1.7 KB | 1.7 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_users | 8.5 KB | 8.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/message_key_order | 9.9 KB | 9.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/unattributed | 42.4 MB | 41.7 MB | -740.1 KB | -1.7% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/log_messages | 55688 | 56456 | 768 | 1.4% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 202622 | 202622 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 25496 | 25496 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 4152 | 4152 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 4152 | 4152 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_messages_entries | 74 | 74 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_messages_population | 74 | 74 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/max_log_message_length | 350 | 350 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/detect/registry_build | 21 ms | 21 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/parse/read_files | 2.3 s | 2.3 s | -20 ms | -0.9% | IMPROVE |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics | 320 ms | 302 ms | -18 ms | -5.6% | IMPROVE |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 307 ms | 290 ms | -17 ms | -5.5% | IMPROVE |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.7 s | 2.6 s | -38 ms | -1.4% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 267.6 MB | 266.7 MB | -896 KB | -0.3% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/format_scan_subs | 1.5 MB | 1.4 MB | -64 KB | -4.3% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_messages | 172.9 MB | 172.9 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_stats | 1.7 KB | 1.7 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_users | 8.5 KB | 8.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/unattributed | 93.2 MB | 92.4 MB | -832 KB | -0.9% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/log_messages | 181319175 | 181319175 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| humungous-log-uniqueness-histogram | TIMING/detect/registry_build | 20 ms | 22 ms | +2 ms | 10.0% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/parse/read_files | 2.3 s | 2.3 s | -62 ms | -2.6% | IMPROVE |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics | 294 ms | 319 ms | +25 ms | 8.5% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics/sort_selection | 281 ms | 306 ms | +25 ms | 8.9% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics/untimed | 12 ms | 13 ms | +1000 us | 8.3% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.7 s | 2.6 s | -37 ms | -1.4% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 267.9 MB | 266.8 MB | -1.1 MB | -0.4% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/format_scan_subs | 1.5 MB | 1.5 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_messages | 172.9 MB | 172.9 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_stats | 1.7 KB | 1.7 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_users | 8.5 KB | 8.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/unattributed | 93.5 MB | 92.4 MB | -1.1 MB | -1.2% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/log_messages | 181319175 | 181319175 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| humungous-log-uniqueness-heatmap-histogram | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/parse/read_files | 2.3 s | 2.3 s | -57 ms | -2.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics | 302 ms | 313 ms | +11 ms | 3.6% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 290 ms | 300 ms | +10 ms | 3.4% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 12 ms | 12 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.7 s | 2.6 s | -45 ms | -1.7% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 267.4 MB | 266.7 MB | -704 KB | -0.3% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/format_scan_subs | 1.4 MB | 1.4 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_messages | 172.9 MB | 172.9 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_stats | 1.7 KB | 1.7 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_users | 8.5 KB | 8.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/unattributed | 93 MB | 92.4 MB | -704 KB | -0.7% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/log_messages | 181319175 | 181319175 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| humungous-log-uniqueness-heatmap-histogram-export | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/detect/registry_build | 21 ms | 22 ms | +1000 us | 4.8% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 10 ms | 11 ms | +1000 us | 10.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/parse/read_files | 1.8 s | 1.8 s | -37 ms | -2.0% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/total | 1.9 s | 1.8 s | -36 ms | -1.9% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/rss_peak | 41.8 MB | 41 MB | -752 KB | -1.8% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/format_scan_subs | 1.4 MB | 1.5 MB | +32 KB | 2.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/log_stats | 1.7 KB | 1.7 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/log_users | 8.5 KB | 8.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/unattributed | 40.3 MB | 39.6 MB | -784 KB | -1.9% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | CONFIG/max_log_message_length | 350 | 350 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | CONFIG/timestamp_fraction_capture | 1 | 1 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/parse/read_files | 3.2 s | 3.1 s | -85 ms | -2.7% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 738 ms | 739 ms | +1 ms | 0.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 3.9 s | 3.9 s | -83 ms | -2.1% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 53.1 MB | 52.5 MB | -608 KB | -1.1% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 197.7 KB | 197.9 KB | +128 B | 0.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | 5.7 MB | 5.7 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 231.4 KB | 231.4 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 2.8 MB | 2.8 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 24.9 KB | 24.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 129.8 KB | 129.8 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 1.5 MB | 1.5 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_messages | 226.6 KB | 226.6 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_stats | 1.7 KB | 1.7 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_users | 8.5 KB | 8.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/message_key_order | 3.3 KB | 3.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/unattributed | 42.4 MB | 41.8 MB | -608.1 KB | -1.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 54168 | 54168 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 202494 | 202622 | 128 | 0.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 25496 | 25496 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 4152 | 4152 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 4152 | 4152 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 74 | 74 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_messages_population | 74 | 74 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 350 | 350 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| humungous-log-uniqueness-sort-p99 | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/parse/read_files | 2.3 s | 2.3 s | -48 ms | -2.1% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics | 298 ms | 297 ms | -1 ms | -0.3% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 286 ms | 284 ms | -2 ms | -0.7% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/total | 2.6 s | 2.6 s | -48 ms | -1.8% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | MEMORY/rss_peak | 267.9 MB | 267.1 MB | -784 KB | -0.3% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/format_scan_subs | 1.4 MB | 1.5 MB | +32 KB | 2.2% | REGRESS |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_messages | 172.9 MB | 172.9 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_stats | 1.7 KB | 1.7 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_users | 8.5 KB | 8.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/unattributed | 93.5 MB | 92.7 MB | -816 KB | -0.9% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/log_messages | 181319175 | 181319175 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| humungous-log-uniqueness-sort-skewness | TIMING/detect/registry_build | 21 ms | 21 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/parse/read_files | 2.3 s | 2.3 s | -57 ms | -2.4% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics | 300 ms | 299 ms | -1 ms | -0.3% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 287 ms | 287 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/total | 2.7 s | 2.6 s | -57 ms | -2.1% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | MEMORY/rss_peak | 267.5 MB | 267.1 MB | -464 KB | -0.2% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/format_scan_subs | 1.4 MB | 1.5 MB | +80 KB | 5.4% | REGRESS |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_messages | 172.9 MB | 172.9 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_stats | 1.7 KB | 1.7 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_users | 8.5 KB | 8.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/unattributed | 93.2 MB | 92.6 MB | -544 KB | -0.6% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/log_messages | 181319175 | 181319175 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| single-day-application-log-standard | TIMING/detect/registry_build | 21 ms | 21 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/parse/read_files | 3.5 s | 3.4 s | -87 ms | -2.5% | IMPROVE |
| single-day-application-log-standard | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.5 s | 3.5 s | -87 ms | -2.5% | IMPROVE |
| single-day-application-log-standard | MEMORY/rss_peak | 45.7 MB | 45.0 MB | -720 KB | -1.5% | IMPROVE |
| single-day-application-log-standard | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/format_scan_subs | 1.4 MB | 1.4 MB | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_messages | 2.8 MB | 2.8 MB | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_users | 85.0 KB | 85.2 KB | +256 B | 0.3% | REGRESS |
| single-day-application-log-standard | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/unattributed | 41.3 MB | 40.6 MB | -720.2 KB | -1.7% | IMPROVE |
| single-day-application-log-standard | MEMORY_FINAL/log_messages | 2916398 | 2916398 | 0 | 0.0% |  |
| single-day-application-log-standard | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| single-day-application-log-no-messages | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| single-day-application-log-no-messages | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| single-day-application-log-no-messages | TIMING/parse/read_files | 2.9 s | 2.9 s | -25 ms | -0.9% | IMPROVE |
| single-day-application-log-no-messages | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-application-log-no-messages | TIMING/total | 2.9 s | 2.9 s | -24 ms | -0.8% | IMPROVE |
| single-day-application-log-no-messages | MEMORY/rss_peak | 41.5 MB | 40.7 MB | -832 KB | -2.0% | IMPROVE |
| single-day-application-log-no-messages | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/format_scan_subs | 1.5 MB | 1.4 MB | -48 KB | -3.2% | IMPROVE |
| single-day-application-log-no-messages | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/log_stats | 7.6 KB | 7.9 KB | +256 B | 3.3% | REGRESS |
| single-day-application-log-no-messages | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/log_users | 85.2 KB | 85.2 KB | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/unattributed | 39.9 MB | 39.1 MB | -784.2 KB | -1.9% | IMPROVE |
| single-day-application-log-no-messages | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-no-messages | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| single-day-application-log-top25 | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| single-day-application-log-top25 | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/parse/read_files | 3.5 s | 3.4 s | -144 ms | -4.1% | IMPROVE |
| single-day-application-log-top25 | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.5 s | 3.4 s | -142 ms | -4.0% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 45.7 MB | 44.9 MB | -768 KB | -1.6% | IMPROVE |
| single-day-application-log-top25 | MEMORY/bucket_outcomes | 6 KB | 5.8 KB | -256 B | -4.2% | IMPROVE |
| single-day-application-log-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/format_scan_subs | 1.5 MB | 1.5 MB | +48 KB | 3.2% | REGRESS |
| single-day-application-log-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_messages | 2.8 MB | 2.8 MB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_occurrences | 21.8 KB | 21.5 KB | -256 B | -1.1% | IMPROVE |
| single-day-application-log-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_stats | 7.9 KB | 7.6 KB | -256 B | -3.2% | IMPROVE |
| single-day-application-log-top25 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_users | 85.5 KB | 84.5 KB | -1 KB | -1.2% | IMPROVE |
| single-day-application-log-top25 | MEMORY/message_key_order | 6.4 KB | 6.4 KB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/unattributed | 41.3 MB | 40.5 MB | -814.2 KB | -1.9% | IMPROVE |
| single-day-application-log-top25 | MEMORY_FINAL/log_messages | 2918558 | 2918558 | 0 | 0.0% |  |
| single-day-application-log-top25 | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| single-day-application-log-top25-consolidate | TIMING/detect/registry_build | 21 ms | 21 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/parse/read_files | 4.9 s | 4.8 s | -143 ms | -2.9% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/finalize/group_similar | 272 ms | 268 ms | -4 ms | -1.5% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 5.2 s | 5.1 s | -147 ms | -2.8% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 114.6 MB | 116 MB | +1.5 MB | 1.3% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_clusters | 346.7 KB | 346.8 KB | +128 B | 0.0% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_id_index | 55.7 MB | 55.7 MB | +2 KB | 0.0% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_message | 1.4 MB | 1.4 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_trigrams | 28.0 MB | 28.0 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_patterns | 42.8 KB | 42.8 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_unmatched | 800.7 KB | 800.7 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/format_scan_subs | 1.4 MB | 1.5 MB | +16 KB | 1.1% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_messages | 1.5 MB | 1.5 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_users | 85.2 KB | 85.5 KB | +256 B | 0.3% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/message_key_order | 6.8 KB | 6.8 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/unattributed | 25.3 MB | 26.8 MB | +1.5 MB | 5.7% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/log_messages | 106507 | 106507 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 354999 | 355127 | 128 | 0.0% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 43807 | 43807 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 32824 | 32824 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 32824 | 32824 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | COUNTS/log_messages_entries | 103 | 103 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | COUNTS/log_messages_population | 103 | 103 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/max_log_message_length | 350 | 350 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| single-day-application-log-heatmap | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/parse/read_files | 3.5 s | 3.4 s | -136 ms | -3.8% | IMPROVE |
| single-day-application-log-heatmap | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 5 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.6 s | 3.4 s | -135 ms | -3.8% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/rss_peak | 45.5 MB | 44.5 MB | -1 MB | -2.2% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/format_scan_subs | 1.5 MB | 1.5 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_messages | 2.8 MB | 2.8 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_users | 85.5 KB | 85.2 KB | -256 B | -0.3% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/unattributed | 41.2 MB | 40.2 MB | -1023.8 KB | -2.4% | IMPROVE |
| single-day-application-log-heatmap | MEMORY_FINAL/log_messages | 2916398 | 2916398 | 0 | 0.0% |  |
| single-day-application-log-heatmap | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| single-day-application-log-histogram | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| single-day-application-log-histogram | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/parse/read_files | 3.5 s | 3.4 s | -45 ms | -1.3% | IMPROVE |
| single-day-application-log-histogram | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.5 s | 3.4 s | -44 ms | -1.3% | IMPROVE |
| single-day-application-log-histogram | MEMORY/rss_peak | 45.3 MB | 44.9 MB | -416 KB | -0.9% | IMPROVE |
| single-day-application-log-histogram | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/format_scan_subs | 1.4 MB | 1.5 MB | +32 KB | 2.2% | REGRESS |
| single-day-application-log-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_messages | 2.8 MB | 2.8 MB | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_users | 85.5 KB | 85.2 KB | -256 B | -0.3% | IMPROVE |
| single-day-application-log-histogram | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/unattributed | 41 MB | 40.6 MB | -447.8 KB | -1.1% | IMPROVE |
| single-day-application-log-histogram | MEMORY_FINAL/log_messages | 2916398 | 2916398 | 0 | 0.0% |  |
| single-day-application-log-histogram | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| single-day-application-log-heatmap-histogram | TIMING/detect/registry_build | 21 ms | 21 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/parse/read_files | 3.6 s | 3.4 s | -151 ms | -4.2% | IMPROVE |
| single-day-application-log-heatmap-histogram | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| single-day-application-log-heatmap-histogram | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.6 s | 3.4 s | -149 ms | -4.2% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 45.3 MB | 44.6 MB | -720 KB | -1.6% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/format_scan_subs | 1.4 MB | 1.4 MB | +16 KB | 1.1% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_messages | 2.8 MB | 2.8 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_users | 85.2 KB | 85.5 KB | +256 B | 0.3% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/unattributed | 41.0 MB | 40.3 MB | -736.2 KB | -1.8% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/log_messages | 2916398 | 2916398 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| single-day-application-log-heatmap-histogram-export | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | TIMING/detect/registry_build | 21 ms | 21 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 10 ms | 11 ms | +1000 us | 10.0% | REGRESS |
| single-day-application-log-heatmap-histogram-export | TIMING/parse/read_files | 3.0 s | 2.9 s | -75 ms | -2.5% | IMPROVE |
| single-day-application-log-heatmap-histogram-export | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | TIMING/total | 3 s | 2.9 s | -75 ms | -2.5% | IMPROVE |
| single-day-application-log-heatmap-histogram-export | MEMORY/rss_peak | 41.5 MB | 41.1 MB | -400 KB | -0.9% | IMPROVE |
| single-day-application-log-heatmap-histogram-export | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/format_scan_subs | 1.4 MB | 1.5 MB | +32 KB | 2.2% | REGRESS |
| single-day-application-log-heatmap-histogram-export | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_stats | 7.9 KB | 7.6 KB | -256 B | -3.2% | IMPROVE |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_users | 85.5 KB | 85.5 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/unattributed | 40.0 MB | 39.5 MB | -431.8 KB | -1.1% | IMPROVE |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | CONFIG/max_log_message_length | 350 | 350 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | CONFIG/timestamp_fraction_capture | 1 | 1 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/parse/read_files | 4.9 s | 4.8 s | -167 ms | -3.4% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 275 ms | 272 ms | -3 ms | -1.1% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 5.2 s | 5 s | -169 ms | -3.2% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 116.6 MB | 113.5 MB | -3 MB | -2.6% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 346.2 KB | 346.8 KB | +640 B | 0.2% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | 55.7 MB | 55.7 MB | -2 KB | -0.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 1.4 MB | 1.4 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 28.0 MB | 28.0 MB | -4 KB | -0.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 42.8 KB | 42.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 800.7 KB | 800.7 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 1.4 MB | 1.4 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_messages | 1.5 MB | 1.5 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_users | 85.5 KB | 85.0 KB | -512 B | -0.6% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/unattributed | 27.4 MB | 24.3 MB | -3 MB | -11.1% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 103067 | 103451 | 384 | 0.4% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 354487 | 355127 | 640 | 0.2% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 43807 | 43807 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 32824 | 32824 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 32824 | 32824 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 103 | 103 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_messages_population | 103 | 103 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 350 | 350 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| single-day-application-log-sort-p99 | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/parse/read_files | 3.5 s | 3.4 s | -99 ms | -2.8% | IMPROVE |
| single-day-application-log-sort-p99 | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/total | 3.6 s | 3.5 s | -97 ms | -2.7% | IMPROVE |
| single-day-application-log-sort-p99 | MEMORY/rss_peak | 45.2 MB | 44.6 MB | -576 KB | -1.2% | IMPROVE |
| single-day-application-log-sort-p99 | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/format_scan_subs | 1.4 MB | 1.4 MB | -32 KB | -2.2% | IMPROVE |
| single-day-application-log-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_messages | 2.8 MB | 2.8 MB | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_users | 85.0 KB | 85.2 KB | +256 B | 0.3% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/unattributed | 40.8 MB | 40.3 MB | -544.2 KB | -1.3% | IMPROVE |
| single-day-application-log-sort-p99 | MEMORY_FINAL/log_messages | 2916398 | 2916398 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| single-day-application-log-sort-skewness | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| single-day-application-log-sort-skewness | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/parse/read_files | 3.5 s | 3.4 s | -52 ms | -1.5% | IMPROVE |
| single-day-application-log-sort-skewness | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 5 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/total | 3.5 s | 3.5 s | -52 ms | -1.5% | IMPROVE |
| single-day-application-log-sort-skewness | MEMORY/rss_peak | 45.6 MB | 44.4 MB | -1.1 MB | -2.5% | IMPROVE |
| single-day-application-log-sort-skewness | MEMORY/bucket_outcomes | 6 KB | 5.8 KB | -256 B | -4.2% | IMPROVE |
| single-day-application-log-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/format_scan_subs | 1.5 MB | 1.4 MB | -48 KB | -3.2% | IMPROVE |
| single-day-application-log-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_messages | 2.8 MB | 2.8 MB | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_occurrences | 21.8 KB | 21.5 KB | -256 B | -1.1% | IMPROVE |
| single-day-application-log-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_stats | 7.9 KB | 7.6 KB | -256 B | -3.2% | IMPROVE |
| single-day-application-log-sort-skewness | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_users | 84.7 KB | 85.0 KB | +256 B | 0.3% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/unattributed | 41.2 MB | 40.1 MB | -1.1 MB | -2.6% | IMPROVE |
| single-day-application-log-sort-skewness | MEMORY_FINAL/log_messages | 2916398 | 2916398 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| multi-day-application-logs-standard | TIMING/detect/registry_build | 21 ms | 21 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/parse/read_files | 7.7 s | 7.4 s | -253 ms | -3.3% | IMPROVE |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics | 178 ms | 178 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 175 ms | 175 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/render/normalize_data | 5 ms | 5 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 7.9 s | 7.6 s | -253 ms | -3.2% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/rss_peak | 110.3 MB | 109.5 MB | -848 KB | -0.8% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/format_scan_subs | 1.4 MB | 1.4 MB | +32 KB | 2.3% | REGRESS |
| multi-day-application-logs-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_messages | 48.9 MB | 48.9 MB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_occurrences | 56.7 KB | 56.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_users | 40.5 KB | 40.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/unattributed | 59.9 MB | 59 MB | -880 KB | -1.4% | IMPROVE |
| multi-day-application-logs-standard | MEMORY_FINAL/log_messages | 51304048 | 51304048 | 0 | 0.0% |  |
| multi-day-application-logs-standard | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| multi-day-application-logs-no-messages | TIMING/detect/registry_build | 21 ms | 21 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-no-messages | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-no-messages | TIMING/parse/read_files | 6.2 s | 6.2 s | -62 ms | -1.0% | IMPROVE |
| multi-day-application-logs-no-messages | TIMING/render/normalize_data | 5 ms | 5 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-no-messages | TIMING/total | 6.3 s | 6.2 s | -61 ms | -1.0% | IMPROVE |
| multi-day-application-logs-no-messages | MEMORY/rss_peak | 43.3 MB | 42.5 MB | -752 KB | -1.7% | IMPROVE |
| multi-day-application-logs-no-messages | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/format_scan_subs | 1.3 MB | 1.5 MB | +128 KB | 9.3% | REGRESS |
| multi-day-application-logs-no-messages | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/log_users | 40.8 KB | 40.6 KB | -256 B | -0.6% | IMPROVE |
| multi-day-application-logs-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/unattributed | 41.8 MB | 40.9 MB | -879.8 KB | -2.1% | IMPROVE |
| multi-day-application-logs-no-messages | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| multi-day-application-logs-top25 | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| multi-day-application-logs-top25 | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/parse/read_files | 7.6 s | 7.3 s | -286 ms | -3.8% | IMPROVE |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics | 176 ms | 176 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 173 ms | 173 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/render/normalize_data | 5 ms | 5 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 7.8 s | 7.5 s | -286 ms | -3.7% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 110.3 MB | 110.3 MB | +16 KB | 0.0% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/format_scan_subs | 1.4 MB | 1.5 MB | +16 KB | 1.1% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_messages | 48.9 MB | 48.9 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_users | 40.6 KB | 40.6 KB | +64 B | 0.2% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/message_key_order | 6.5 KB | 6.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/unattributed | 59.8 MB | 59.8 MB | -64 B | -0.0% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY_FINAL/log_messages | 51306208 | 51306208 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| multi-day-application-logs-top25-consolidate | TIMING/detect/registry_build | 20 ms | 22 ms | +2 ms | 10.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/parse/read_files | 29.4 s | 29 s | -328 ms | -1.1% | IMPROVE |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/group_similar | 2.2 s | 2.2 s | -17 ms | -0.8% | IMPROVE |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/render/normalize_data | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 31.6 s | 31.2 s | -344 ms | -1.1% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 233.7 MB | 232.0 MB | -1.7 MB | -0.7% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_clusters | 3.2 MB | 3.2 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_id_index | 127.2 MB | 127.2 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_message | 3.8 MB | 3.8 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 65.7 MB | 65.7 MB | +3 KB | 0.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_patterns | 450.8 KB | 450.8 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_unmatched | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/format_scan_subs | 1.4 MB | 1.4 MB | +80 KB | 5.7% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_messages | 4.1 MB | 4.1 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_users | 40.4 KB | 40.6 KB | +192 B | 0.5% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/message_key_order | 5.7 KB | 5.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/unattributed | 25.6 MB | 23.9 MB | -1.8 MB | -6.9% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_messages | 744582 | 745606 | 1024 | 0.1% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 3341979 | 3341979 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 461659 | 461659 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_messages_entries | 1079 | 1079 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_messages_population | 1079 | 1079 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | 40 | 40 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/max_log_message_length | 350 | 350 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/parse/read_files | 7.6 s | 7.3 s | -253 ms | -3.3% | IMPROVE |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics | 176 ms | 174 ms | -2 ms | -1.1% | IMPROVE |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 173 ms | 171 ms | -2 ms | -1.2% | IMPROVE |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/render/normalize_data | 5 ms | 5 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 7.8 s | 7.5 s | -254 ms | -3.3% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 110.3 MB | 109.6 MB | -704 KB | -0.6% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/format_scan_subs | 1.4 MB | 1.4 MB | +16 KB | 1.1% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_messages | 48.9 MB | 48.9 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_users | 40.6 KB | 41 KB | +448 B | 1.1% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/unattributed | 59.8 MB | 59.1 MB | -720.4 KB | -1.2% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY_FINAL/log_messages | 51304048 | 51304048 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| multi-day-application-logs-histogram | TIMING/detect/registry_build | 20 ms | 22 ms | +2 ms | 10.0% | REGRESS |
| multi-day-application-logs-histogram | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/parse/read_files | 7.5 s | 7.3 s | -252 ms | -3.3% | IMPROVE |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics | 172 ms | 173 ms | +1 ms | 0.6% | REGRESS |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 169 ms | 171 ms | +2 ms | 1.2% | REGRESS |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/render/normalize_data | 5 ms | 5 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 7.7 s | 7.5 s | -249 ms | -3.2% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 110.8 MB | 110.2 MB | -608 KB | -0.5% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/format_scan_subs | 1.4 MB | 1.4 MB | +80 KB | 5.7% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_messages | 48.9 MB | 48.9 MB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_occurrences | 56.7 KB | 56.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_users | 40.6 KB | 40.4 KB | -192 B | -0.5% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/unattributed | 60.4 MB | 59.7 MB | -687.8 KB | -1.1% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY_FINAL/log_messages | 51304048 | 51304048 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| multi-day-application-logs-heatmap-histogram | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/parse/read_files | 7.6 s | 7.3 s | -238 ms | -3.1% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 173 ms | 179 ms | +6 ms | 3.5% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 171 ms | 177 ms | +6 ms | 3.5% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/render/normalize_data | 5 ms | 5 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 7.8 s | 7.5 s | -231 ms | -3.0% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 110.5 MB | 109.8 MB | -784 KB | -0.7% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/format_scan_subs | 1.4 MB | 1.4 MB | -48 KB | -3.3% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_messages | 48.9 MB | 48.9 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_users | 40.3 KB | 40.8 KB | +576 B | 1.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/unattributed | 60.1 MB | 59.3 MB | -736.6 KB | -1.2% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 51304048 | 51304048 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| multi-day-application-logs-heatmap-histogram-export | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | TIMING/detect/registry_build | 21 ms | 22 ms | +1000 us | 4.8% | REGRESS |
| multi-day-application-logs-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 10 ms | 11 ms | +1000 us | 10.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-export | TIMING/parse/read_files | 6.4 s | 6.2 s | -170 ms | -2.7% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-export | TIMING/render/normalize_data | 5 ms | 5 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | TIMING/total | 6.4 s | 6.3 s | -169 ms | -2.6% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/rss_peak | 43.2 MB | 42.5 MB | -704 KB | -1.6% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/format_scan_subs | 1.4 MB | 1.5 MB | +48 KB | 3.3% | REGRESS |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_users | 40.6 KB | 40.7 KB | +64 B | 0.2% | REGRESS |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/unattributed | 41.7 MB | 41.0 MB | -752.1 KB | -1.8% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | COUNTS/format_scan_sub_cache_hits | 40 | 40 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | CONFIG/max_log_message_length | 350 | 350 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | CONFIG/timestamp_fraction_capture | 1 | 1 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 29.2 s | 29 s | -198 ms | -0.7% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 2.2 s | 2.2 s | +3 ms | 0.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 31.4 s | 31.3 s | -194 ms | -0.6% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 233.4 MB | 228.9 MB | -4.5 MB | -1.9% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 3.2 MB | 3.2 MB | +4 KB | 0.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | 127.2 MB | 127.2 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 3.8 MB | 3.8 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 65.7 MB | 65.7 MB | -1 KB | -0.0% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 450.8 KB | 450.8 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 1.4 MB | 1.4 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 4.1 MB | 4.1 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_users | 40.8 KB | 40.6 KB | -128 B | -0.3% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 3 KB | 3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/unattributed | 25.3 MB | 20.8 MB | -4.5 MB | -17.7% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 741974 | 742294 | 320 | 0.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 3337883 | 3341979 | 4096 | 0.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 461659 | 461659 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 1079 | 1079 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | 1079 | 1079 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | 40 | 40 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 350 | 350 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| multi-day-application-logs-sort-p99 | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/parse/read_files | 7.5 s | 7.3 s | -199 ms | -2.6% | IMPROVE |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics | 178 ms | 175 ms | -3 ms | -1.7% | IMPROVE |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 175 ms | 172 ms | -3 ms | -1.7% | IMPROVE |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/render/normalize_data | 5 ms | 5 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/total | 7.7 s | 7.5 s | -201 ms | -2.6% | IMPROVE |
| multi-day-application-logs-sort-p99 | MEMORY/rss_peak | 110.4 MB | 109.7 MB | -720 KB | -0.6% | IMPROVE |
| multi-day-application-logs-sort-p99 | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/format_scan_subs | 1.5 MB | 1.4 MB | -64 KB | -4.2% | IMPROVE |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_messages | 48.9 MB | 48.9 MB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_users | 40.5 KB | 40.7 KB | +192 B | 0.5% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/unattributed | 59.8 MB | 59.2 MB | -656.2 KB | -1.1% | IMPROVE |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/log_messages | 51304048 | 51304048 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| multi-day-application-logs-sort-skewness | TIMING/detect/registry_build | 21 ms | 21 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/parse/read_files | 7.5 s | 7.4 s | -118 ms | -1.6% | IMPROVE |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics | 187 ms | 172 ms | -15 ms | -8.0% | IMPROVE |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 184 ms | 169 ms | -15 ms | -8.2% | IMPROVE |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/render/normalize_data | 5 ms | 5 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/total | 7.7 s | 7.6 s | -133 ms | -1.7% | IMPROVE |
| multi-day-application-logs-sort-skewness | MEMORY/rss_peak | 109.9 MB | 109.6 MB | -288 KB | -0.3% | IMPROVE |
| multi-day-application-logs-sort-skewness | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/format_scan_subs | 1.4 MB | 1.4 MB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_analysis | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_messages | 48.9 MB | 48.9 MB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_users | 40.6 KB | 40.3 KB | -320 B | -0.8% | IMPROVE |
| multi-day-application-logs-sort-skewness | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/unattributed | 59.5 MB | 59.2 MB | -287.6 KB | -0.5% | IMPROVE |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/log_messages | 51304048 | 51304048 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| multi-day-custom-logs-standard | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| multi-day-custom-logs-standard | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/parse/read_files | 15.5 s | 14.5 s | -960 ms | -6.2% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics | 338 ms | 347 ms | +9 ms | 2.7% | REGRESS |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/bucket_stats | 30 ms | 31 ms | +1 ms | 3.3% | REGRESS |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 300 ms | 308 ms | +8 ms | 2.7% | REGRESS |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/group_calc | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/untimed | 7 ms | 7 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 15.9 s | 14.9 s | -949 ms | -6.0% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 178.8 MB | 179.4 MB | +640 KB | 0.3% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/format_scan_subs | 1.5 MB | 1.4 MB | -96 KB | -6.2% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_analysis | 12.9 MB | 12.9 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_messages | 88.8 MB | 88.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_stats | 46.8 KB | 46.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_users | 12.7 KB | 12.7 KB | +64 B | 0.5% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/unattributed | 75.5 MB | 76.2 MB | +735.9 KB | 1.0% | REGRESS |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_messages | 93084545 | 93084545 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_analysis | 21151 | 21151 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| multi-day-custom-logs-no-messages | TIMING/detect/registry_build | 21 ms | 21 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-no-messages | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-no-messages | TIMING/parse/read_files | 12.7 s | 12.2 s | -420 ms | -3.3% | IMPROVE |
| multi-day-custom-logs-no-messages | TIMING/finalize/calculate_statistics | 25 ms | 25 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | 25 ms | 25 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-no-messages | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-no-messages | TIMING/total | 12.7 s | 12.3 s | -419 ms | -3.3% | IMPROVE |
| multi-day-custom-logs-no-messages | MEMORY/rss_peak | 57 MB | 55.9 MB | -1.1 MB | -1.9% | IMPROVE |
| multi-day-custom-logs-no-messages | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/format_scan_subs | 1.5 MB | 1.4 MB | -16 KB | -1.1% | IMPROVE |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/log_analysis | 12.9 MB | 12.9 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/log_stats | 46.8 KB | 43.3 KB | -3.5 KB | -7.5% | IMPROVE |
| multi-day-custom-logs-no-messages | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/log_users | 12.7 KB | 12.7 KB | -64 B | -0.5% | IMPROVE |
| multi-day-custom-logs-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/unattributed | 42.6 MB | 41.5 MB | -1.1 MB | -2.6% | IMPROVE |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/log_analysis | 21151 | 21151 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| multi-day-custom-logs-top25 | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/parse/read_files | 15.6 s | 14.7 s | -816 ms | -5.2% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics | 345 ms | 352 ms | +7 ms | 2.0% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 29 ms | 30 ms | +1000 us | 3.4% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 305 ms | 311 ms | +6 ms | 2.0% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/group_calc | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 7 ms | 8 ms | +1 ms | 14.3% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 15.9 s | 15.1 s | -807 ms | -5.1% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 180.2 MB | 177 MB | -3.2 MB | -1.8% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/format_scan_subs | 1.5 MB | 1.4 MB | -48 KB | -3.2% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_analysis | 12.9 MB | 12.9 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_messages | 88.8 MB | 88.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_stats | 46.8 KB | 46.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_users | 12.7 KB | 12.7 KB | -64 B | -0.5% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/unattributed | 76.9 MB | 73.8 MB | -3.1 MB | -4.0% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_messages | 93093905 | 93093905 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_analysis | 21151 | 21151 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| multi-day-custom-logs-top25-consolidate | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/parse/read_files | 32.9 s | 32.3 s | -632 ms | -1.9% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/group_similar | 4.1 s | 4 s | -38 ms | -0.9% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 96 ms | 92 ms | -4 ms | -4.2% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 48 ms | 44 ms | -4 ms | -8.3% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 47 ms | 47 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/render/normalize_data | 4 ms | 3 ms | -1 ms | -25.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 37.1 s | 36.4 s | -673 ms | -1.8% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 233.9 MB | 227.5 MB | -6.4 MB | -2.7% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/bucket_outcomes | 6.1 KB | 6.3 KB | +256 B | 4.1% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_clusters | 14.1 MB | 14.1 MB | -7.4 KB | -0.1% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_id_index | 122.9 MB | 122.9 MB | -1 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_message | 5.8 MB | 5.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 62.7 MB | 62.7 MB | -1 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_patterns | 194.8 KB | 194.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_unmatched | 3.3 MB | 3.3 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/format_scan_subs | 1.4 MB | 1.4 MB | -16 KB | -1.1% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_analysis | 12.9 MB | 12.9 MB | +256 B | 0.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages | 13.2 MB | 13.2 MB | +1.1 KB | 0.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_occurrences | 20 KB | 20.3 KB | +256 B | 1.2% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_stats | 43.3 KB | 46.8 KB | +3.5 KB | 8.1% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_users | 12.5 KB | 12.7 KB | +256 B | 2.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/message_key_order | 6.1 KB | 6.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_messages | 13845160 | 13846312 | 1152 | 0.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 20895 | 21151 | 256 | 1.2% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 1534173 | 1526621 | -7552 | -0.5% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 199492 | 199492 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_messages_entries | 366 | 366 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_analysis_entries | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_messages_population | 366 | 366 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | 4 | 4 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/max_log_message_length | 350 | 350 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/parse/read_files | 16.1 s | 15.2 s | -904 ms | -5.6% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics | 309 ms | 301 ms | -8 ms | -2.6% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 301 ms | 294 ms | -7 ms | -2.3% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/group_calc | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/finalize/heatmap_statistics | 49 ms | 49 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 16.4 s | 15.5 s | -910 ms | -5.5% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 174.2 MB | 173.4 MB | -816 KB | -0.5% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/format_scan_subs | 1.4 MB | 1.5 MB | +16 KB | 1.1% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters | 987.2 KB | 985.8 KB | -1.5 KB | -0.2% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data | 43.6 KB | 43.4 KB | -192 B | -0.4% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_analysis | 23.2 KB | 22.0 KB | -1.2 KB | -5.4% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/log_messages | 88.8 MB | 88.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_stats | 31.9 KB | 31.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_users | 12.7 KB | 12.7 KB | +64 B | 0.5% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/unattributed | 82.8 MB | 82 MB | -829.1 KB | -1.0% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_messages | 93084545 | 93084545 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_analysis | 21151 | 19871 | -1280 | -6.1% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| multi-day-custom-logs-histogram | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/parse/read_files | 16.4 s | 15.3 s | -1.1 s | -6.8% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics | 340 ms | 340 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 30 ms | 30 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 301 ms | 302 ms | +1 ms | 0.3% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/group_calc | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 8 ms | 7 ms | -1 ms | -12.5% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/finalize/histogram_statistics | 14 ms | 14 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 16.8 s | 15.6 s | -1.1 s | -6.7% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 178.8 MB | 178 MB | -816 KB | -0.4% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/format_scan_subs | 1.5 MB | 1.4 MB | -16 KB | -1.1% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/histogram_counters | 122.5 KB | 122.6 KB | +192 B | 0.2% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_analysis | 12.9 MB | 12.9 MB | -1.2 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/log_messages | 88.8 MB | 88.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_stats | 43.3 KB | 43.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_users | 12.7 KB | 12.7 KB | +64 B | 0.5% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/unattributed | 75.5 MB | 74.7 MB | -799 KB | -1.0% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY_FINAL/log_messages | 93084545 | 93084545 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY_FINAL/log_analysis | 21151 | 19871 | -1280 | -6.1% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| multi-day-custom-logs-heatmap-histogram | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/parse/read_files | 16.7 s | 15.8 s | -908 ms | -5.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 307 ms | 304 ms | -3 ms | -1.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 299 ms | 297 ms | -2 ms | -0.7% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/heatmap_statistics | 49 ms | 49 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/histogram_statistics | 14 ms | 14 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 17.1 s | 16.2 s | -910 ms | -5.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 174.3 MB | 173.5 MB | -832 KB | -0.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/format_scan_subs | 1.4 MB | 1.4 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_counters | 987.2 KB | 987.2 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data | 40.1 KB | 42.6 KB | +2.5 KB | 6.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters | 122.6 KB | 122.6 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_analysis | 22.0 KB | 23.2 KB | +1.2 KB | 5.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages | 88.8 MB | 88.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_stats | 31.9 KB | 31.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_users | 12.7 KB | 12.7 KB | -64 B | -0.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/unattributed | 82.8 MB | 82 MB | -835.7 KB | -1.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 93084545 | 93084545 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 19871 | 21151 | 1280 | 6.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| multi-day-custom-logs-heatmap-histogram-export | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/detect/registry_build | 21 ms | 22 ms | +1000 us | 4.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 10 ms | 11 ms | +1000 us | 10.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/parse/read_files | 14.2 s | 13.9 s | -391 ms | -2.7% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics | 88 ms | 89 ms | +1 ms | 1.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | 88 ms | 89 ms | +1 ms | 1.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | 153 ms | 153 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/histogram_statistics | 13 ms | 13 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/total | 14.5 s | 14.1 s | -389 ms | -2.7% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/rss_peak | 59.8 MB | 57.7 MB | -2 MB | -3.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/format_scan_subs | 1.5 MB | 1.5 MB | +16 KB | 1.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_counters | 987.2 KB | 985.8 KB | -1.5 KB | -0.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_data | 43.7 KB | 43.5 KB | -192 B | -0.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/histogram_counters | 122.6 KB | 122.5 KB | -192 B | -0.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_analysis | 12.9 MB | 12.9 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_stats | 74.8 KB | 65.8 KB | -9 KB | -12.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_users | 12.7 KB | 12.7 KB | +64 B | 0.5% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/unattributed | 44.2 MB | 42.1 MB | -2 MB | -4.6% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/log_analysis | 22997 | 22997 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | COUNTS/log_analysis_entries | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | COUNTS/format_scan_sub_cache_hits | 4 | 4 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | CONFIG/max_log_message_length | 350 | 350 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | CONFIG/timestamp_fraction_capture | 1 | 1 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 20 ms | 22 ms | +2 ms | 10.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 34.5 s | 33.4 s | -1.1 s | -3.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 4.0 s | 3.9 s | -58 ms | -1.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 37 ms | 35 ms | -2 ms | -5.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 36 ms | 35 ms | -1000 us | -2.8% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 52 ms | 51 ms | -1 ms | -1.9% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 15 ms | 15 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 38.6 s | 37.5 s | -1.1 s | -2.9% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 227 MB | 230.5 MB | +3.5 MB | 1.5% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 14.1 MB | 14.1 MB | -5.2 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | 122.9 MB | 122.9 MB | +2 KB | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 5.8 MB | 5.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 62.7 MB | 62.7 MB | +2 KB | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 194.8 KB | 194.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 3.3 MB | 3.3 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 1.4 MB | 1.4 MB | +16 KB | 1.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 987.2 KB | 984.2 KB | -3 KB | -0.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 42.6 KB | 43.3 KB | +768 B | 1.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 122.6 KB | 122.3 KB | -384 B | -0.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 22.0 KB | 23.2 KB | +1.2 KB | 5.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 13.2 MB | 13.2 MB | +768 B | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 31.9 KB | 31.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_users | 12.7 KB | 12.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 2.6 KB | 2.6 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/unattributed | 2.2 MB | 5.7 MB | +3.5 MB | 157.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 13838392 | 13839160 | 768 | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 19871 | 21151 | 1280 | 6.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 1531997 | 1526621 | -5376 | -0.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 199492 | 199492 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 366 | 366 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | 366 | 366 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | 4 | 4 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 350 | 350 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| multi-day-custom-logs-sort-p99 | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/parse/read_files | 15.4 s | 14.7 s | -710 ms | -4.6% | IMPROVE |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics | 219 ms | 219 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 29 ms | 30 ms | +1000 us | 3.4% | REGRESS |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 179 ms | 178 ms | -1 ms | -0.6% | IMPROVE |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 8 ms | 8 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/total | 15.6 s | 14.9 s | -709 ms | -4.5% | IMPROVE |
| multi-day-custom-logs-sort-p99 | MEMORY/rss_peak | 177.7 MB | 176.2 MB | -1.5 MB | -0.9% | IMPROVE |
| multi-day-custom-logs-sort-p99 | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/format_scan_subs | 1.5 MB | 1.5 MB | +16 KB | 1.1% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_analysis | 12.9 MB | 12.9 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_messages | 88.8 MB | 88.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_stats | 46.8 KB | 46.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_users | 12.7 KB | 12.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/message_key_order | 2.7 KB | 2.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/unattributed | 74.5 MB | 73.0 MB | -1.5 MB | -2.1% | IMPROVE |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/log_messages | 93085025 | 93085025 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/log_analysis | 21151 | 21151 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| multi-day-custom-logs-sort-skewness | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| multi-day-custom-logs-sort-skewness | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/parse/read_files | 15.5 s | 14.7 s | -814 ms | -5.2% | IMPROVE |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics | 293 ms | 290 ms | -3 ms | -1.0% | IMPROVE |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 29 ms | 29 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 250 ms | 247 ms | -3 ms | -1.2% | IMPROVE |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 3 ms | 4 ms | +1 ms | 33.3% | REGRESS |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 8 ms | 8 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/total | 15.8 s | 15 s | -816 ms | -5.2% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY/rss_peak | 191.8 MB | 175.5 MB | -16.4 MB | -8.5% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/format_scan_subs | 1.5 MB | 1.4 MB | -80 KB | -5.3% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_analysis | 12.9 MB | 12.9 MB | +1.2 KB | 0.0% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY/log_messages | 101.1 MB | 88.8 MB | -12.3 MB | -12.2% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_stats | 46.8 KB | 46.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_users | 12.7 KB | 12.7 KB | +64 B | 0.5% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY/message_key_order | 2.5 KB | 2.5 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/unattributed | 76.3 MB | 72.3 MB | -4.0 MB | -5.2% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/log_messages | 106000166 | 93086598 | -12913568 | -12.2% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/log_analysis | 19871 | 21151 | 1280 | 6.4% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| single-day-access-log-standard | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| single-day-access-log-standard | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/parse/read_files | 8.3 s | 7.5 s | -814 ms | -9.8% | IMPROVE |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics | 73 ms | 74 ms | +1 ms | 1.4% | REGRESS |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/bucket_stats | 51 ms | 51 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 5 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/group_calc | 18 ms | 18 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 8.4 s | 7.6 s | -812 ms | -9.7% | IMPROVE |
| single-day-access-log-standard | MEMORY/rss_peak | 98.9 MB | 98.3 MB | -656 KB | -0.6% | IMPROVE |
| single-day-access-log-standard | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/format_scan_subs | 1.4 MB | 1.4 MB | +64 KB | 4.5% | REGRESS |
| single-day-access-log-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_analysis | 23.6 MB | 23.6 MB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_messages | 26.4 MB | 26.2 MB | -198.2 KB | -0.7% | IMPROVE |
| single-day-access-log-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_stats | 27.6 KB | 27.6 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/message_key_order | 1.8 KB | 1.8 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/unattributed | 47.4 MB | 46.9 MB | -521.8 KB | -1.1% | IMPROVE |
| single-day-access-log-standard | MEMORY_FINAL/log_messages | 27683801 | 27480793 | -203008 | -0.7% | IMPROVE |
| single-day-access-log-standard | MEMORY_FINAL/log_analysis | 9175 | 9175 | 0 | 0.0% |  |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| single-day-access-log-no-messages | TIMING/detect/registry_build | 21 ms | 21 ms | 0 ms | 0.0% |  |
| single-day-access-log-no-messages | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| single-day-access-log-no-messages | TIMING/parse/read_files | 6.8 s | 6.3 s | -479 ms | -7.1% | IMPROVE |
| single-day-access-log-no-messages | TIMING/finalize/calculate_statistics | 51 ms | 48 ms | -3 ms | -5.9% | IMPROVE |
| single-day-access-log-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | 51 ms | 48 ms | -3 ms | -5.9% | IMPROVE |
| single-day-access-log-no-messages | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-access-log-no-messages | TIMING/total | 6.8 s | 6.3 s | -481 ms | -7.0% | IMPROVE |
| single-day-access-log-no-messages | MEMORY/rss_peak | 68.4 MB | 66.9 MB | -1.4 MB | -2.1% | IMPROVE |
| single-day-access-log-no-messages | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/format_scan_subs | 1.4 MB | 1.4 MB | -16 KB | -1.1% | IMPROVE |
| single-day-access-log-no-messages | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/log_analysis | 23.6 MB | 23.6 MB | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/log_stats | 27.6 KB | 27.6 KB | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/unattributed | 43.3 MB | 41.8 MB | -1.4 MB | -3.3% | IMPROVE |
| single-day-access-log-no-messages | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| single-day-access-log-no-messages | MEMORY_FINAL/log_analysis | 9175 | 9175 | 0 | 0.0% |  |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| single-day-access-log-top25 | TIMING/detect/registry_build | 21 ms | 21 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/parse/read_files | 8.5 s | 7.4 s | -1 s | -12.3% | IMPROVE |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics | 79 ms | 80 ms | +1 ms | 1.3% | REGRESS |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 51 ms | 51 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 5 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/group_calc | 24 ms | 24 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 8.6 s | 7.5 s | -1 s | -12.2% | IMPROVE |
| single-day-access-log-top25 | MEMORY/rss_peak | 98.5 MB | 98.5 MB | -32 KB | -0.0% | IMPROVE |
| single-day-access-log-top25 | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/format_scan_subs | 1.4 MB | 1.5 MB | +16 KB | 1.1% | REGRESS |
| single-day-access-log-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_analysis | 23.6 MB | 23.6 MB | +960 B | 0.0% | REGRESS |
| single-day-access-log-top25 | MEMORY/log_messages | 26.2 MB | 26.4 MB | +197.4 KB | 0.7% | REGRESS |
| single-day-access-log-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_stats | 27.6 KB | 27.6 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/message_key_order | 3.9 KB | 3.9 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/unattributed | 47.2 MB | 46.9 MB | -246.4 KB | -0.5% | IMPROVE |
| single-day-access-log-top25 | MEMORY_FINAL/log_messages | 27490665 | 27692841 | 202176 | 0.7% | REGRESS |
| single-day-access-log-top25 | MEMORY_FINAL/log_analysis | 8215 | 9175 | 960 | 11.7% | REGRESS |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| single-day-access-log-top25-consolidate | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/parse/read_files | 9.2 s | 8.3 s | -914 ms | -9.9% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/finalize/group_similar | 559 ms | 570 ms | +11 ms | 2.0% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics | 90 ms | 90 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 51 ms | 51 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 38 ms | 37 ms | -1 ms | -2.6% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/render/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/total | 9.9 s | 9.0 s | -903 ms | -9.1% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 129.5 MB | 129.6 MB | +80 KB | 0.1% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_clusters | 16.4 MB | 16.4 MB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_id_index | 9.3 MB | 9.3 MB | -6.8 KB | -0.1% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_message | 888.1 KB | 888.1 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_trigrams | 4.6 MB | 4.6 MB | -6.8 KB | -0.1% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_patterns | 129.4 KB | 129.4 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_unmatched | 565.2 KB | 565.2 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/format_scan_subs | 1.4 MB | 1.4 MB | -32 KB | -2.2% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_analysis | 23.6 MB | 23.6 MB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_messages | 26.7 MB | 26.5 MB | -199 KB | -0.7% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_stats | 27.6 KB | 27.6 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/message_key_order | 3.9 KB | 3.9 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/unattributed | 45.9 MB | 46.2 MB | +324.5 KB | 0.7% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_messages | 25857887 | 25822175 | -35712 | -0.1% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_analysis | 9175 | 9175 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 608854 | 608854 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 132461 | 132461 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 304 | 304 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 16440 | 16440 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_messages_entries | 747 | 747 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_analysis_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_messages_population | 747 | 747 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/max_log_message_length | 350 | 350 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| single-day-access-log-heatmap | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/parse/read_files | 9.2 s | 8.3 s | -969 ms | -10.5% | IMPROVE |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics | 24 ms | 23 ms | -1 ms | -4.2% | IMPROVE |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 5 ms | -1 ms | -16.7% | IMPROVE |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics/group_calc | 18 ms | 18 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/finalize/heatmap_statistics | 30 ms | 34 ms | +4 ms | 13.3% | REGRESS |
| single-day-access-log-heatmap | TIMING/render/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| single-day-access-log-heatmap | TIMING/total | 9.3 s | 8.3 s | -965 ms | -10.4% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/rss_peak | 80.8 MB | 80.5 MB | -256 KB | -0.3% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/format_scan_subs | 1.4 MB | 1.4 MB | +16 KB | 1.1% | REGRESS |
| single-day-access-log-heatmap | MEMORY/heatmap_counters | 571.2 KB | 570.3 KB | -960 B | -0.2% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_data | 34 KB | 33.8 KB | -256 B | -0.7% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_analysis | 10.5 KB | 10.5 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_messages | 26.4 MB | 26.2 MB | -198.4 KB | -0.7% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_stats | 18.2 KB | 18.2 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/message_key_order | 1.8 KB | 1.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/unattributed | 52.3 MB | 52.2 MB | -72.4 KB | -0.1% | IMPROVE |
| single-day-access-log-heatmap | MEMORY_FINAL/log_messages | 27683929 | 27480793 | -203136 | -0.7% | IMPROVE |
| single-day-access-log-heatmap | MEMORY_FINAL/log_analysis | 9175 | 9175 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| single-day-access-log-histogram | TIMING/detect/registry_build | 21 ms | 21 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/parse/read_files | 10.5 s | 9.5 s | -993 ms | -9.5% | IMPROVE |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics | 76 ms | 74 ms | -2 ms | -2.6% | IMPROVE |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 52 ms | 51 ms | -1 ms | -1.9% | IMPROVE |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 5 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/group_calc | 18 ms | 18 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/finalize/histogram_statistics | 11 ms | 11 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 10.6 s | 9.6 s | -994 ms | -9.4% | IMPROVE |
| single-day-access-log-histogram | MEMORY/rss_peak | 98.5 MB | 99.2 MB | +704 KB | 0.7% | REGRESS |
| single-day-access-log-histogram | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/format_scan_subs | 1.4 MB | 1.5 MB | +80 KB | 5.6% | REGRESS |
| single-day-access-log-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/histogram_counters | 105.9 KB | 105.9 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_analysis | 23.6 MB | 23.6 MB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_messages | 26.2 MB | 26.4 MB | +198.4 KB | 0.7% | REGRESS |
| single-day-access-log-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_stats | 27.6 KB | 27.6 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/message_key_order | 1.8 KB | 1.8 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/unattributed | 47.1 MB | 47.5 MB | +425.6 KB | 0.9% | REGRESS |
| single-day-access-log-histogram | MEMORY_FINAL/log_messages | 27480793 | 27683929 | 203136 | 0.7% | REGRESS |
| single-day-access-log-histogram | MEMORY_FINAL/log_analysis | 9175 | 9175 | 0 | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| single-day-access-log-heatmap-histogram | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/parse/read_files | 10.9 s | 10 s | -894 ms | -8.2% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics | 22 ms | 22 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 5 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 18 ms | 17 ms | -1000 us | -5.6% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/finalize/heatmap_statistics | 30 ms | 30 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/finalize/histogram_statistics | 11 ms | 11 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 11 s | 10.1 s | -894 ms | -8.1% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 80.1 MB | 79.4 MB | -688 KB | -0.8% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/format_scan_subs | 1.4 MB | 1.5 MB | +48 KB | 3.3% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_counters | 571.2 KB | 571.2 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_counters | 105.9 KB | 105.9 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_analysis | 9.6 KB | 9.6 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_messages | 26.2 MB | 26.4 MB | +198.4 KB | 0.7% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_stats | 18.2 KB | 18.2 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/message_key_order | 1.8 KB | 1.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/unattributed | 51.7 MB | 50.8 MB | -934.4 KB | -1.8% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_messages | 27480793 | 27683929 | 203136 | 0.7% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_analysis | 8215 | 8215 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| single-day-access-log-heatmap-histogram-export | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | TIMING/detect/registry_build | 21 ms | 21 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 10 ms | 11 ms | +1000 us | 10.0% | REGRESS |
| single-day-access-log-heatmap-histogram-export | TIMING/parse/read_files | 9.6 s | 9.1 s | -459 ms | -4.8% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics | 168 ms | 169 ms | +1 ms | 0.6% | REGRESS |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | 168 ms | 169 ms | +1 ms | 0.6% | REGRESS |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | 97 ms | 97 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/histogram_statistics | 11 ms | 11 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | TIMING/total | 9.9 s | 9.4 s | -456 ms | -4.6% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | MEMORY/rss_peak | 71.4 MB | 67.5 MB | -3.8 MB | -5.3% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/format_scan_subs | 1.5 MB | 1.4 MB | -16 KB | -1.1% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_counters | 572.2 KB | 572.2 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_data | 33.8 KB | 34 KB | +256 B | 0.7% | REGRESS |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/histogram_counters | 106 KB | 106 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_analysis | 23.6 MB | 23.6 MB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_stats | 46.0 KB | 40.3 KB | -5.6 KB | -12.2% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/unattributed | 45.5 MB | 41.7 MB | -3.8 MB | -8.3% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/log_analysis | 11901 | 11901 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | COUNTS/log_analysis_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | CONFIG/max_log_message_length | 350 | 350 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | CONFIG/timestamp_fraction_capture | 1 | 1 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/parse/read_files | 11.7 s | 11 s | -666 ms | -5.7% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 510 ms | 512 ms | +2 ms | 0.4% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 48 ms | 47 ms | -1 ms | -2.1% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 47 ms | 46 ms | -1 ms | -2.1% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 30 ms | 30 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 11 ms | 11 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 12.3 s | 11.6 s | -663 ms | -5.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 107.5 MB | 104.7 MB | -2.8 MB | -2.6% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 16.4 MB | 16.4 MB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | 9.3 MB | 9.3 MB | -5.8 KB | -0.1% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 888.1 KB | 888.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 4.6 MB | 4.6 MB | -5.8 KB | -0.1% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 129.4 KB | 129.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 565.2 KB | 565.2 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 1.4 MB | 1.4 MB | +80 KB | 5.7% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 572.2 KB | 570.3 KB | -1.9 KB | -0.3% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_counters | 106 KB | 105.8 KB | -256 B | -0.2% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 10.5 KB | 10.5 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_messages | 26.5 MB | 26.7 MB | +199 KB | 0.7% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_stats | 18.2 KB | 18.2 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/message_key_order | 1.8 KB | 1.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/unattributed | 47 MB | 44 MB | -3 MB | -6.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 25812367 | 25848975 | 36608 | 0.1% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 9175 | 9175 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 608854 | 608854 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 132461 | 132461 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 304 | 304 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 16440 | 16440 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 747 | 747 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_messages_population | 747 | 747 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 350 | 350 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/detect/registry_build | 21 ms | 22 ms | +1000 us | 4.8% | REGRESS |
| single-day-access-log-sort-p99 | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/parse/read_files | 8.3 s | 7.5 s | -809 ms | -9.8% | IMPROVE |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics | 103 ms | 103 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 51 ms | 51 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 51 ms | 50 ms | -1000 us | -2.0% | IMPROVE |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/total | 8.4 s | 7.6 s | -809 ms | -9.6% | IMPROVE |
| single-day-access-log-sort-p99 | MEMORY/rss_peak | 97.3 MB | 98.5 MB | +1.2 MB | 1.3% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/format_scan_subs | 1.5 MB | 1.4 MB | -32 KB | -2.1% | IMPROVE |
| single-day-access-log-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_analysis | 23.6 MB | 23.6 MB | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_messages | 26.2 MB | 26.2 MB | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_stats | 27.6 KB | 27.6 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/message_key_order | 2.0 KB | 2.0 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/unattributed | 45.9 MB | 47.1 MB | +1.2 MB | 2.7% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY_FINAL/log_messages | 27481017 | 27481017 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY_FINAL/log_analysis | 9175 | 9175 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| single-day-access-log-sort-skewness | TIMING/detect/registry_build | 21 ms | 21 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/detect/scan_sub_compile | 10 ms | 10 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/parse/read_files | 8.4 s | 7.5 s | -818 ms | -9.8% | IMPROVE |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics | 229 ms | 235 ms | +6 ms | 2.6% | REGRESS |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 51 ms | 53 ms | +2 ms | 3.9% | REGRESS |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 175 ms | 179 ms | +4 ms | 2.3% | REGRESS |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| single-day-access-log-sort-skewness | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/total | 8.6 s | 7.8 s | -812 ms | -9.4% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY/rss_peak | 124.3 MB | 98.0 MB | -26.3 MB | -21.2% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/format_scan_subs | 1.5 MB | 1.4 MB | -80 KB | -5.4% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_analysis | 23.6 MB | 23.6 MB | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_messages | 49.4 MB | 26.2 MB | -23.1 MB | -46.9% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_stats | 27.6 KB | 27.6 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/message_key_order | 1.9 KB | 1.9 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/unattributed | 49.8 MB | 46.7 MB | -3.1 MB | -6.3% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY_FINAL/log_messages | 51748478 | 27482558 | -24265920 | -46.9% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY_FINAL/log_analysis | 9175 | 9175 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
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
| month-single-server-access-logs-standard | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/detect/registry_build | 20 ms | 22 ms | +2 ms | 10.0% | REGRESS |
| month-single-server-access-logs-standard | TIMING/detect/scan_sub_compile | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-single-server-access-logs-standard | TIMING/parse/read_files | 1.5 min | 1.4 min | -8.5 s | -9.4% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics | 3.6 s | 3.5 s | -91 ms | -2.5% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/bucket_stats | 1.7 s | 1.7 s | +1000 us | 0.1% | REGRESS |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 1.5 s | 1.4 s | -91 ms | -6.1% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/group_calc | 346 ms | 346 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/untimed | 63 ms | 63 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/render/normalize_data | 5 ms | 4 ms | -1 ms | -20.0% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/total | 1.6 min | 1.4 min | -8.6 s | -9.1% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 1.7 GB | 1.8 GB | +71.5 MB | 4.0% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/format_scan_subs | 2.6 MB | 2.6 MB | +16 KB | 0.6% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_analysis | 244 MB | 244 MB | +1.8 KB | 0.0% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/log_messages | 1.2 GB | 1.3 GB | +74.0 MB | 5.9% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/unattributed | 286.5 MB | 284 MB | -2.5 MB | -0.9% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_messages | 1316127738 | 1393712442 | 77584704 | 5.9% | REGRESS |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_analysis | 15803 | 17595 | 1792 | 11.3% | REGRESS |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | COUNTS/log_messages_entries | 1212271 | 1212271 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | COUNTS/log_messages_population | 1212271 | 1212271 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | COUNTS/format_scan_subs_compiled | 2 | 2 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-single-server-access-logs-no-messages | TIMING/detect/scan_sub_compile | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-single-server-access-logs-no-messages | TIMING/parse/read_files | 1.2 min | 1.1 min | -5.1 s | -7.1% | IMPROVE |
| month-single-server-access-logs-no-messages | TIMING/finalize/calculate_statistics | 1.4 s | 1.4 s | +3 ms | 0.2% | REGRESS |
| month-single-server-access-logs-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | 1.4 s | 1.4 s | +2 ms | 0.1% | REGRESS |
| month-single-server-access-logs-no-messages | TIMING/finalize/calculate_statistics/untimed | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-no-messages | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-no-messages | TIMING/total | 1.2 min | 1.1 min | -5.1 s | -6.9% | IMPROVE |
| month-single-server-access-logs-no-messages | MEMORY/rss_peak | 356.8 MB | 354.2 MB | -2.7 MB | -0.7% | IMPROVE |
| month-single-server-access-logs-no-messages | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/format_scan_subs | 2.5 MB | 2.6 MB | +48 KB | 1.8% | REGRESS |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_analysis | 241.6 MB | 241.6 MB | +1.8 KB | 0.0% | REGRESS |
| month-single-server-access-logs-no-messages | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-no-messages | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/unattributed | 110.4 MB | 107.7 MB | -2.7 MB | -2.4% | IMPROVE |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/log_analysis | 15803 | 17595 | 1792 | 11.3% | REGRESS |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | COUNTS/format_scan_subs_compiled | 2 | 2 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/detect/scan_sub_compile | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/parse/read_files | 1.5 min | 1.4 min | -8.2 s | -9.1% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics | 3.8 s | 3.8 s | +64 ms | 1.7% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 1.7 s | 1.7 s | +7 ms | 0.4% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 1.5 s | 1.5 s | +49 ms | 3.3% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/group_calc | 502 ms | 509 ms | +7 ms | 1.4% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 63 ms | 63 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 1.6 min | 1.4 min | -8.2 s | -8.6% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 1.7 GB | 1.7 GB | +2.9 MB | 0.2% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/format_scan_subs | 2.4 MB | 2.5 MB | +160 KB | 6.5% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_analysis | 244 MB | 244 MB | +1.8 KB | 0.0% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/log_messages | 1.2 GB | 1.2 GB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/message_key_order | 4.7 KB | 4.7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/unattributed | 282.4 MB | 285.1 MB | +2.7 MB | 1.0% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_messages | 1316140458 | 1316140458 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_analysis | 15803 | 17595 | 1792 | 11.3% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | COUNTS/log_messages_entries | 1212271 | 1212271 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | COUNTS/log_messages_population | 1212271 | 1212271 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | COUNTS/format_scan_subs_compiled | 2 | 2 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/detect/scan_sub_compile | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/parse/read_files | 1.9 min | 1.8 min | -6.7 s | -6.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/group_similar | 4.1 s | 4.3 s | +159 ms | 3.9% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 4.0 s | 4.0 s | +5 ms | 0.1% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 1.9 s | 1.9 s | +10 ms | 0.5% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 2.1 s | 2.1 s | -1 ms | -0.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/untimed | 7 ms | 3 ms | -4 ms | -57.1% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/render/normalize_data | 5 ms | 5 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 2 min | 1.9 min | -6.5 s | -5.4% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 821.3 MB | 969.3 MB | +148 MB | 18.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 210.7 MB | 210.7 MB | +64 B | 0.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_id_index | 49.4 MB | 46.8 MB | -2.6 MB | -5.3% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 2.1 MB | 2.1 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 26.1 MB | 23.6 MB | -2.5 MB | -9.6% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 226.9 KB | 226.8 KB | -64 B | -0.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 1.4 MB | 1.4 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/format_scan_subs | 2.4 MB | 2.5 MB | +64 KB | 2.6% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_analysis | 242.2 MB | 242.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages | 241.8 MB | 241.9 MB | +51.1 KB | 0.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | +128 B | 0.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/message_key_order | 4 KB | 4 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/unattributed | 42.6 MB | 195.7 MB | +153.1 MB | 359.4% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | 253588277 | 253640565 | 52288 | 0.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 17595 | 17595 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 888698 | 888762 | 64 | 0.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 185195 | 185195 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 432 | 432 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_messages_entries | 1057 | 1057 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_messages_population | 1057 | 1057 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | 2 | 2 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/max_log_message_length | 350 | 350 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/detect/registry_build | 21 ms | 21 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/detect/scan_sub_compile | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/parse/read_files | 1.7 min | 1.6 min | -7.7 s | -7.7% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics | 1.8 s | 1.8 s | +38 ms | 2.2% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 1.4 s | 1.4 s | +35 ms | 2.5% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/group_calc | 280 ms | 283 ms | +3 ms | 1.1% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 71 ms | 71 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/finalize/heatmap_statistics | 104 ms | 103 ms | -1 ms | -1.0% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/total | 1.7 min | 1.6 min | -7.7 s | -7.5% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 1.5 GB | 1.6 GB | +74.4 MB | 4.8% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/format_scan_subs | 2.5 MB | 2.6 MB | +80 KB | 3.1% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | -1.8 KB | -0.1% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data | 75.1 KB | 75.4 KB | +256 B | 0.3% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_analysis | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_messages | 1.2 GB | 1.3 GB | +74.0 MB | 5.9% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/log_sessions | 2.2 MB | 2.2 MB | +128 B | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/log_stats | 35 KB | 35 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/unattributed | 300.8 MB | 301.1 MB | +314.9 KB | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_messages | 1316127258 | 1393711962 | 77584704 | 5.9% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_analysis | 17179 | 17179 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | COUNTS/log_messages_entries | 1212271 | 1212271 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | COUNTS/log_messages_population | 1212271 | 1212271 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | COUNTS/format_scan_subs_compiled | 2 | 2 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/detect/scan_sub_compile | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/parse/read_files | 1.9 min | 1.8 min | -8.2 s | -7.2% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics | 3.5 s | 3.6 s | +33 ms | 0.9% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 1.7 s | 1.7 s | +12 ms | 0.7% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 1.4 s | 1.5 s | +27 ms | 1.9% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/group_calc | 350 ms | 345 ms | -5 ms | -1.4% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 63 ms | 63 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/finalize/histogram_statistics | 19 ms | 19 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/total | 2.0 min | 1.8 min | -8.1 s | -7.0% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 1.7 GB | 1.7 GB | +1008 KB | 0.1% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/format_scan_subs | 2.5 MB | 2.6 MB | +48 KB | 1.8% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/histogram_counters | 296 KB | 296 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_analysis | 244 MB | 244 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_messages | 1.2 GB | 1.2 GB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/unattributed | 282 MB | 283.0 MB | +959.8 KB | 0.3% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_messages | 1316127738 | 1316127738 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_analysis | 17595 | 17595 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | COUNTS/log_messages_entries | 1212271 | 1212271 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | COUNTS/log_messages_population | 1212271 | 1212271 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | COUNTS/format_scan_subs_compiled | 2 | 2 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/parse/read_files | 2 min | 1.9 min | -8.1 s | -6.7% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 1.8 s | 1.8 s | -14 ms | -0.8% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 1.4 s | 1.4 s | -8 ms | -0.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 285 ms | 283 ms | -2 ms | -0.7% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 73 ms | 70 ms | -3 ms | -4.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/heatmap_statistics | 103 ms | 105 ms | +2 ms | 1.9% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/histogram_statistics | 19 ms | 19 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2 min | 1.9 min | -8.1 s | -6.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 1.6 GB | 1.5 GB | -75.3 MB | -4.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/format_scan_subs | 2.6 MB | 2.6 MB | -32 KB | -1.2% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | -1.8 KB | -0.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data | 78.4 KB | 74.9 KB | -3.5 KB | -4.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_counters | 296 KB | 295.9 KB | -128 B | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_analysis | 18 KB | 18 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_messages | 1.3 GB | 1.2 GB | -74.0 MB | -5.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | -256 B | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_stats | 35 KB | 35 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/unattributed | 302 MB | 300.7 MB | -1.3 MB | -0.4% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 1393711962 | 1316127258 | -77584704 | -5.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 15387 | 15387 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_messages_entries | 1212271 | 1212271 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_messages_population | 1212271 | 1212271 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | COUNTS/format_scan_subs_compiled | 2 | 2 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/detect/registry_build | 21 ms | 22 ms | +1000 us | 4.8% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 21 ms | 21 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/parse/read_files | 1.8 min | 1.7 min | -4.1 s | -3.9% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics | 2.5 s | 2.6 s | +68 ms | 2.7% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | 2.5 s | 2.6 s | +68 ms | 2.7% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/untimed | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | 222 ms | 222 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/histogram_statistics | 18 ms | 18 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/total | 1.8 min | 1.7 min | -4 s | -3.7% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/rss_peak | 358.1 MB | 357.2 MB | -864 KB | -0.2% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/format_scan_subs | 2.5 MB | 2.6 MB | +32 KB | 1.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | +3.5 KB | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_data | 77.4 KB | 74.4 KB | -3 KB | -3.9% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/histogram_counters | 295.8 KB | 296 KB | +256 B | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_analysis | 241.6 MB | 241.6 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_stats | 86.9 KB | 80.8 KB | -6.1 KB | -7.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/unattributed | 108.9 MB | 108.0 MB | -890.9 KB | -0.8% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_analysis | 22609 | 22609 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | COUNTS/format_scan_subs_compiled | 2 | 2 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | CONFIG/max_log_message_length | 350 | 350 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | CONFIG/timestamp_fraction_capture | 1 | 1 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 2.3 min | 2.2 min | -7.3 s | -5.2% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 3.1 s | 3 s | -15 ms | -0.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 2.4 s | 2.4 s | +17 ms | 0.7% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 2.4 s | 2.4 s | +18 ms | 0.7% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/untimed | 6 ms | 5 ms | -1 ms | -16.7% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 94 ms | 94 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 20 ms | 20 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 5 ms | 5 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 2.4 min | 2.3 min | -7.3 s | -5.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 637.1 MB | 638.6 MB | +1.5 MB | 0.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 210.7 MB | 210.7 MB | +64 B | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | 49.6 MB | 49.6 MB | +6 KB | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.1 MB | 2.1 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 26.3 MB | 26.3 MB | +6 KB | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 226.8 KB | 226.9 KB | +64 B | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.4 MB | 1.4 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 2.5 MB | 2.4 MB | -80 KB | -3.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | +1.8 KB | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 77.4 KB | 77.9 KB | +512 B | 0.6% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 295.9 KB | 296 KB | +128 B | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 241.9 MB | 241.9 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | -128 B | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 35 KB | 35 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 1.9 KB | 1.9 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/unattributed | 97.3 MB | 98.9 MB | +1.6 MB | 1.6% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 253628837 | 253628837 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 17179 | 17179 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 888698 | 888762 | 64 | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 185195 | 185195 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 432 | 432 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 1057 | 1057 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | 1057 | 1057 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 2 | 2 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 350 | 350 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/detect/scan_sub_compile | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/parse/read_files | 1.5 min | 1.4 min | -9 s | -10.0% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics | 10.3 s | 10.4 s | +62 ms | 0.6% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 1.7 s | 1.7 s | +33 ms | 2.0% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 5.4 s | 5.4 s | -31 ms | -0.6% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 3.1 s | 3.1 s | +59 ms | 1.9% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 127 ms | 129 ms | +2 ms | 1.6% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-p99 | TIMING/total | 1.7 min | 1.5 min | -9.0 s | -8.9% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/rss_peak | 1.9 GB | 1.9 GB | +960 KB | 0.0% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/format_scan_subs | 2.7 MB | 2.5 MB | -160 KB | -5.8% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_analysis | 244 MB | 244 MB | -1.8 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/log_messages | 1.3 GB | 1.3 GB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_sessions | 2.2 MB | 2.2 MB | +128 B | 0.0% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/unattributed | 349.7 MB | 350.8 MB | +1.1 MB | 0.3% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/log_messages | 1420915962 | 1420915962 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/log_analysis | 17595 | 15803 | -1792 | -10.2% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | COUNTS/log_messages_entries | 1212271 | 1212271 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | COUNTS/log_messages_population | 1212271 | 1212271 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | COUNTS/format_scan_subs_compiled | 2 | 2 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-single-server-access-logs-sort-skewness | TIMING/detect/scan_sub_compile | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-single-server-access-logs-sort-skewness | TIMING/parse/read_files | 1.5 min | 1.4 min | -9 s | -9.9% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics | 5.2 s | 5.3 s | +71 ms | 1.4% | REGRESS |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 1.7 s | 1.7 s | +17 ms | 1.0% | REGRESS |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 3.4 s | 3.4 s | +47 ms | 1.4% | REGRESS |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 13 ms | 14 ms | +1 ms | 7.7% | REGRESS |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 88 ms | 95 ms | +7 ms | 8.0% | REGRESS |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 66 ms | 65 ms | -1 ms | -1.5% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/total | 1.6 min | 1.5 min | -8.9 s | -9.3% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/rss_peak | 1.9 GB | 1.9 GB | -38.8 MB | -2.0% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/format_scan_subs | 2.7 MB | 2.6 MB | -128 KB | -4.6% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_analysis | 244 MB | 244 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_messages | 1.4 GB | 1.4 GB | -25.4 MB | -1.7% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-sort-skewness | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/unattributed | 260.1 MB | 246.9 MB | -13.2 MB | -5.1% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/log_messages | 1525032959 | 1498393663 | -26639296 | -1.7% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/log_analysis | 17595 | 17595 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | COUNTS/log_messages_entries | 1212271 | 1212271 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | COUNTS/log_messages_population | 1212271 | 1212271 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | COUNTS/format_scan_subs_compiled | 2 | 2 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/detect/scan_sub_compile | 30 ms | 32 ms | +2 ms | 6.7% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/parse/read_files | 7.6 min | 6.9 min | -43.5 s | -9.5% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics | 22.1 s | 22.4 s | +275 ms | 1.2% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/bucket_stats | 10.4 s | 10.5 s | +104 ms | 1.0% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 8.4 s | 8.6 s | +163 ms | 1.9% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/group_calc | 3.0 s | 3.0 s | +16 ms | 0.5% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/untimed | 353 ms | 346 ms | -7 ms | -2.0% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/render/normalize_data | 7 ms | 5 ms | -2 ms | -28.6% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/total | 8.0 min | 7.3 min | -43.3 s | -9.0% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 9.1 GB | 9.1 GB | +18.5 MB | 0.2% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/format_scan_subs | 3.6 MB | 3.7 MB | +96 KB | 2.6% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_analysis | 1.2 GB | 1.2 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_messages | 6.6 GB | 6.6 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/unattributed | 1.2 GB | 1.2 GB | +18.4 MB | 1.5% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_messages | 7127178794 | 7127178794 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_analysis | 17595 | 17595 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | COUNTS/log_messages_entries | 6187234 | 6187234 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | COUNTS/log_messages_population | 6187234 | 6187234 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | COUNTS/format_scan_subs_compiled | 3 | 3 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | COUNTS/format_scan_sub_cache_hits | 142 | 142 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-many-servers-access-logs-no-messages | TIMING/detect/scan_sub_compile | 30 ms | 31 ms | +1 ms | 3.3% | REGRESS |
| month-many-servers-access-logs-no-messages | TIMING/parse/read_files | 6 min | 5.7 min | -22.4 s | -6.2% | IMPROVE |
| month-many-servers-access-logs-no-messages | TIMING/finalize/calculate_statistics | 8.6 s | 8.7 s | +32 ms | 0.4% | REGRESS |
| month-many-servers-access-logs-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | 8.6 s | 8.7 s | +32 ms | 0.4% | REGRESS |
| month-many-servers-access-logs-no-messages | TIMING/finalize/calculate_statistics/untimed | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-no-messages | TIMING/render/normalize_data | 5 ms | 5 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-no-messages | TIMING/total | 6.2 min | 5.8 min | -22.4 s | -6.0% | IMPROVE |
| month-many-servers-access-logs-no-messages | MEMORY/rss_peak | 1.6 GB | 1.6 GB | -15.6 MB | -1.0% | IMPROVE |
| month-many-servers-access-logs-no-messages | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/format_scan_subs | 3.7 MB | 3.7 MB | +48 KB | 1.3% | REGRESS |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/log_analysis | 1.2 GB | 1.2 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -32 KB | -0.2% | IMPROVE |
| month-many-servers-access-logs-no-messages | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/unattributed | 417.7 MB | 402 MB | -15.6 MB | -3.7% | IMPROVE |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/log_analysis | 17595 | 17595 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | COUNTS/format_scan_subs_compiled | 3 | 3 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | COUNTS/format_scan_sub_cache_hits | 142 | 142 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/detect/scan_sub_compile | 30 ms | 32 ms | +2 ms | 6.7% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/parse/read_files | 7.6 min | 6.8 min | -43.8 s | -9.6% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics | 23.3 s | 23.5 s | +241 ms | 1.0% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 10.5 s | 10.5 s | +48 ms | 0.5% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 8 s | 8.2 s | +140 ms | 1.7% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/group_calc | 4.4 s | 4.4 s | +52 ms | 1.2% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 385 ms | 388 ms | +3 ms | 0.8% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/render/normalize_data | 7 ms | 7 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/total | 7.9 min | 7.2 min | -43.5 s | -9.1% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 8.7 GB | 8.7 GB | +4.1 MB | 0.0% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/format_scan_subs | 3.5 MB | 3.8 MB | +320 KB | 9.0% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_analysis | 1.2 GB | 1.2 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_messages | 6.3 GB | 6.3 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/message_key_order | 4.7 KB | 4.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/unattributed | 1.2 GB | 1.2 GB | +3.8 MB | 0.3% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_messages | 6731209178 | 6731209178 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_analysis | 17595 | 17595 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | COUNTS/log_messages_entries | 6187234 | 6187234 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | COUNTS/log_messages_population | 6187234 | 6187234 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | COUNTS/format_scan_subs_compiled | 3 | 3 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | COUNTS/format_scan_sub_cache_hits | 142 | 142 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/detect/scan_sub_compile | 30 ms | 32 ms | +2 ms | 6.7% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/parse/read_files | 9.6 min | 9.1 min | -32.9 s | -5.7% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/group_similar | 19.8 s | 19.8 s | +2 ms | 0.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 23.9 s | 23.3 s | -531 ms | -2.2% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 10.5 s | 10.1 s | -328 ms | -3.1% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 4 ms | -1 ms | -20.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 13.4 s | 13.2 s | -203 ms | -1.5% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/untimed | 27 ms | 27 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/render/normalize_data | 6 ms | 6 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 10.3 min | 9.8 min | -33.4 s | -5.4% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 3.4 GB | 3.4 GB | +5.7 MB | 0.2% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 1.1 GB | 1.1 GB | -128 B | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_id_index | 50.6 MB | 50.6 MB | -1 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 2.0 MB | 2.0 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 26.7 MB | 26.7 MB | -1 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 387.1 KB | 387.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 1.3 MB | 1.3 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/format_scan_subs | 3.3 MB | 3.4 MB | +64 KB | 1.9% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_analysis | 1.2 GB | 1.2 GB | +1.4 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages | 1.2 GB | 1.2 GB | -30.1 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/message_key_order | 4.0 KB | 4.0 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | 1281350332 | 1281319548 | -30784 | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 17595 | 17595 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 1886972 | 1886844 | -128 | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 396351 | 396351 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 432 | 432 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_messages_entries | 2208 | 2208 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_messages_population | 2208 | 2208 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | 3 | 3 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | 142 | 142 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/max_log_message_length | 350 | 350 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/detect/scan_sub_compile | 30 ms | 32 ms | +2 ms | 6.7% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/parse/read_files | 8.4 min | 7.7 min | -39.4 s | -7.8% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics | 10.7 s | 10.8 s | +112 ms | 1.1% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 7.9 s | 8.0 s | +84 ms | 1.1% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/group_calc | 2.4 s | 2.4 s | +19 ms | 0.8% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 406 ms | 415 ms | +9 ms | 2.2% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/finalize/heatmap_statistics | 118 ms | 115 ms | -3 ms | -2.5% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/render/normalize_data | 5 ms | 5 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/total | 8.6 min | 7.9 min | -39.3 s | -7.6% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 7.9 GB | 7.9 GB | +2.5 MB | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/format_scan_subs | 3.5 MB | 3.8 MB | +288 KB | 8.0% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | +3.5 KB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data | 75.8 KB | 76.3 KB | +512 B | 0.7% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_analysis | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_messages | 6.6 GB | 6.6 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +32 KB | 0.2% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/log_stats | 35 KB | 35 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/unattributed | 1.2 GB | 1.2 GB | +2.2 MB | 0.2% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_messages | 7122118938 | 7122118938 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_analysis | 17179 | 17179 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | COUNTS/log_messages_entries | 6187234 | 6187234 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | COUNTS/log_messages_population | 6187234 | 6187234 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | COUNTS/format_scan_subs_compiled | 3 | 3 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | COUNTS/format_scan_sub_cache_hits | 142 | 142 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/detect/scan_sub_compile | 30 ms | 32 ms | +2 ms | 6.7% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/parse/read_files | 9.4 min | 8.8 min | -40.2 s | -7.1% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics | 21.8 s | 21.9 s | +150 ms | 0.7% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 10.5 s | 10.5 s | +77 ms | 0.7% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 8.0 s | 8.1 s | +75 ms | 0.9% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/group_calc | 3.0 s | 2.9 s | -5 ms | -0.2% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 385 ms | 389 ms | +4 ms | 1.0% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/finalize/histogram_statistics | 20 ms | 20 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/render/normalize_data | 7 ms | 7 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/total | 9.8 min | 9.1 min | -40 s | -6.8% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 8.7 GB | 9.1 GB | +386.4 MB | 4.3% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/format_scan_subs | 3.5 MB | 3.8 MB | +240 KB | 6.7% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_counters | 307.5 KB | 307.5 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_analysis | 1.2 GB | 1.2 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_messages | 6.3 GB | 6.6 GB | +377.6 MB | 5.9% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/unattributed | 1.2 GB | 1.2 GB | +8.6 MB | 0.7% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_messages | 6731196458 | 7127178794 | 395982336 | 5.9% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_analysis | 17595 | 17595 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | COUNTS/log_messages_entries | 6187234 | 6187234 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | COUNTS/log_messages_population | 6187234 | 6187234 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | COUNTS/format_scan_subs_compiled | 3 | 3 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | COUNTS/format_scan_sub_cache_hits | 142 | 142 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/detect/registry_build | 21 ms | 21 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | 30 ms | 32 ms | +2 ms | 6.7% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/parse/read_files | 10.1 min | 9.4 min | -40.1 s | -6.6% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 10.9 s | 11.5 s | +577 ms | 5.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 8.1 s | 8.7 s | +558 ms | 6.9% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 2.3 s | 2.4 s | +46 ms | 2.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 436 ms | 410 ms | -26 ms | -6.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/heatmap_statistics | 115 ms | 115 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/histogram_statistics | 20 ms | 20 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/render/normalize_data | 5 ms | 5 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 10.2 min | 9.6 min | -39.5 s | -6.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 7.5 GB | 7.5 GB | +9.2 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/format_scan_subs | 3.5 MB | 3.7 MB | +224 KB | 6.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | +1.8 KB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data | 76.8 KB | 75.8 KB | -1 KB | -1.3% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_counters | 307.7 KB | 307.8 KB | +128 B | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_analysis | 18 KB | 19.8 KB | +1.8 KB | 9.7% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages | 6.3 GB | 6.3 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_occurrences | 43.8 KB | 43.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +32 KB | 0.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_stats | 35 KB | 35 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/unattributed | 1.2 GB | 1.2 GB | +8.9 MB | 0.7% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 6726136602 | 6726136602 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 15387 | 17179 | 1792 | 11.6% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_messages_entries | 6187234 | 6187234 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_messages_population | 6187234 | 6187234 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/format_scan_subs_compiled | 3 | 3 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/format_scan_sub_cache_hits | 142 | 142 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/detect/registry_build | 21 ms | 22 ms | +1000 us | 4.8% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 31 ms | 32 ms | +1 ms | 3.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/parse/read_files | 9.0 min | 8.5 min | -27.6 s | -5.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics | 14.4 s | 14.7 s | +345 ms | 2.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | 14.3 s | 14.7 s | +345 ms | 2.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/untimed | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | 234 ms | 234 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/histogram_statistics | 18 ms | 18 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/render/normalize_data | 5 ms | 5 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/total | 9.2 min | 8.7 min | -27.2 s | -4.9% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/rss_peak | 1.6 GB | 1.6 GB | +2.0 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/format_scan_subs | 3.7 MB | 3.8 MB | +16 KB | 0.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_data | 76.8 KB | 76.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/histogram_counters | 307.7 KB | 307.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_analysis | 1.2 GB | 1.2 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_stats | 86.9 KB | 80.9 KB | -6.0 KB | -6.9% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/unattributed | 407.8 MB | 409.7 MB | +2.0 MB | 0.5% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_analysis | 22609 | 22609 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | COUNTS/format_scan_subs_compiled | 3 | 3 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | COUNTS/format_scan_sub_cache_hits | 142 | 142 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | CONFIG/max_log_message_length | 350 | 350 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | CONFIG/timestamp_fraction_capture | 1 | 1 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 31 ms | 33 ms | +2 ms | 6.5% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 12.0 min | 11.4 min | -31.7 s | -4.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 14.2 s | 14.6 s | +387 ms | 2.7% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 13.9 s | 14 s | +66 ms | 0.5% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 13.9 s | 14.0 s | +66 ms | 0.5% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/untimed | 23 ms | 23 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 105 ms | 108 ms | +3 ms | 2.9% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 20 ms | 19 ms | -1 ms | -5.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 6 ms | 6 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 12.4 min | 11.9 min | -31.2 s | -4.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 2.7 GB | 2.7 GB | -5.7 MB | -0.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 1.1 GB | 1.1 GB | +64 B | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | 50.3 MB | 47.9 MB | -2.4 MB | -4.9% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.0 MB | 2.0 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 26.4 MB | 24.0 MB | -2.4 MB | -9.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 387.1 KB | 387.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.3 MB | 1.3 MB | -128 B | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 3.2 MB | 3.4 MB | +192 KB | 5.8% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | +1.8 KB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 76.3 KB | 76.8 KB | +512 B | 0.7% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 307.7 KB | 307.8 KB | +128 B | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 19.8 KB | 18 KB | -1.8 KB | -8.9% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 1.2 GB | 1.2 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 35 KB | 35 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 1.9 KB | 1.9 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/unattributed | 297.5 MB | 296.5 MB | -1009.6 KB | -0.3% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 1278605764 | 1278605764 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 17179 | 15387 | -1792 | -10.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 1886844 | 1886908 | 64 | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 396351 | 396351 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 432 | 432 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 2208 | 2208 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | 2208 | 2208 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 3 | 3 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | 142 | 142 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 350 | 350 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/detect/scan_sub_compile | 30 ms | 31 ms | +1 ms | 3.3% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/parse/read_files | 7.6 min | 6.9 min | -40.9 s | -9.0% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics | 1 min | 1 min | +894 ms | 1.5% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 10.4 s | 10.4 s | +33 ms | 0.3% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 30.2 s | 30.9 s | +692 ms | 2.3% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 19.5 s | 19.6 s | +141 ms | 0.7% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 692 ms | 719 ms | +27 ms | 3.9% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/render/normalize_data | 7 ms | 6 ms | -1 ms | -14.3% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/total | 8.6 min | 7.9 min | -40.0 s | -7.8% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/rss_peak | 9.6 GB | 10.0 GB | +381.9 MB | 3.9% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/format_scan_subs | 3.5 MB | 3.7 MB | +192 KB | 5.3% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_analysis | 1.2 GB | 1.2 GB | -1.8 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_messages | 6.7 GB | 7.1 GB | +377.6 MB | 5.5% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/message_key_order | 2.5 KB | 2.5 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/unattributed | 1.7 GB | 1.7 GB | +4.1 MB | 0.2% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/log_messages | 7240687818 | 7636670154 | 395982336 | 5.5% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/log_analysis | 17595 | 15803 | -1792 | -10.2% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | COUNTS/log_messages_entries | 6187234 | 6187234 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | COUNTS/log_messages_population | 6187234 | 6187234 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | COUNTS/format_scan_subs_compiled | 3 | 3 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | COUNTS/format_scan_sub_cache_hits | 142 | 142 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | TIMING/detect/registry_build | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/detect/scan_sub_compile | 30 ms | 32 ms | +2 ms | 6.7% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/parse/read_files | 7.6 min | 6.9 min | -43.3 s | -9.5% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics | 32.7 s | 32.3 s | -330 ms | -1.0% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 10.4 s | 10.4 s | +9 ms | 0.1% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 21.3 s | 21.0 s | -331 ms | -1.6% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 77 ms | 72 ms | -5 ms | -6.5% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 418 ms | 455 ms | +37 ms | 8.9% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 400 ms | 359 ms | -41 ms | -10.3% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/render/normalize_data | 7 ms | 6 ms | -1 ms | -14.3% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/total | 8.1 min | 7.4 min | -43.7 s | -9.0% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY/rss_peak | 9.9 GB | 9.3 GB | -582.5 MB | -5.7% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/format_scan_subs | 3.6 MB | 3.7 MB | +176 KB | 4.8% | REGRESS |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_analysis | 1.2 GB | 1.2 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_messages | 7.6 GB | 7.1 GB | -504.3 MB | -6.5% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_occurrences | 43.8 KB | 43.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/message_key_order | 2.1 KB | 2.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/unattributed | 1.1 GB | 1 GB | -78.3 MB | -6.9% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/log_messages | 8164946031 | 7636104623 | -528841408 | -6.5% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/log_analysis | 17595 | 17595 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | COUNTS/log_messages_entries | 6187234 | 6187234 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | COUNTS/log_messages_population | 6187234 | 6187234 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | COUNTS/format_scan_subs_compiled | 3 | 3 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | COUNTS/format_scan_sub_cache_hits | 142 | 142 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |

