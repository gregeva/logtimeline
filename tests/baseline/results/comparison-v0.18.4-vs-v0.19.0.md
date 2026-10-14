
## Benchmark Comparison

  Baseline:    v0.18.4 (v0.18.4, 77 test cases)
  Current:     v0.19.0 (v0.19.0, 77 test cases)

### Timing Delta

| # | file selection | standard | no-msgs | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons | sort-p99 | sort-skew | hm+hg+export |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | -27.1% | -27.8% | -28.5% | -17.4% | -22.1% | -26.4% | -24.1% | -17.5% | -23.6% | -23.4% | -24.4% |
| 2. | single-day-application-log | -30.1% | -26.8% | -28.6% | -20.7% | -29.5% | -29.8% | -27.6% | -20.8% | -31.0% | -30.2% | -25.9% |
| 3. | multi-day-application-logs | -26.0% | -24.7% | -24.6% | -11.8% | -27.3% | -25.4% | -24.7% | -11.4% | -24.8% | -24.5% | -24.2% |
| 4. | multi-day-custom-logs | -29.8% | -27.9% | -29.9% | -13.6% | -30.0% | -27.9% | -26.5% | -12.7% | -29.9% | -29.2% | -23.2% |
| 5. | single-day-access-log | -43.9% | -38.3% | -42.7% | -45.9% | -39.5% | -34.7% | -32.3% | -35.4% | -43.4% | -43.7% | -27.8% |
| 6. | month-single-server-access-logs | -41.8% | -38.0% | -42.0% | -47.0% | -38.2% | -33.0% | -32.0% | -35.3% | -39.5% | -41.1% | -27.1% |
| 7. | month-many-servers-access-logs | -41.4% | -38.0% | -41.4% | -52.3% | -37.9% | -32.7% | -31.1% | -40.4% | -38.6% | -40.6% | -26.2% |

### Memory Delta (RSS Peak)

| # | file selection | standard | no-msgs | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons | sort-p99 | sort-skew | hm+hg+export |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | +0.8% | +9.1% | +1.1% | +6.8% | +0.8% | +1.2% | +0.8% | +6.4% | +1.0% | +0.9% | +8.9% |
| 2. | single-day-application-log | +7.9% | +9.1% | +8.5% | +4.1% | +7.7% | +7.0% | +8.1% | +4.7% | +7.3% | +8.1% | +9.1% |
| 3. | multi-day-application-logs | +2.6% | +7.8% | +2.5% | +1.7% | +2.7% | +2.1% | +2.1% | +3.0% | +2.3% | +2.3% | +7.6% |
| 4. | multi-day-custom-logs | +1.8% | +4.3% | +2.3% | +2.8% | +2.4% | +1.2% | +2.3% | +2.2% | +1.9% | +2.4% | +0.7% |
| 5. | single-day-access-log | +0.4% | +5.4% | -0.4% | -0.8% | -2.4% | +0.4% | -3.6% | -6.1% | +0.7% | -5.4% | +0.2% |
| 6. | month-single-server-access-logs | -9.2% | -4.2% | -12.9% | +2.4% | -10.1% | -9.2% | -14.4% | -7.7% | -12.0% | -13.1% | -3.5% |
| 7. | month-many-servers-access-logs | -13.5% | -3.7% | -13.5% | -2.6% | -15.3% | -13.4% | -11.2% | +5.6% | -12.4% | -9.7% | -5.2% |

### Stage Rollup (timing)

| metric | baseline | current | delta | change% | cases +/- | result |
| --- | --- | --- | --- | --- | --- | --- |
| detect/registry_build | 925 ms | 1.7 s | +769 ms | 83.1% | 77/0 | REGRESS |
| detect/scan_sub_compile (within parent) | 697 ms | 1.2 s | +466 ms | 66.9% | 77/0 | REGRESS |
| parse/read_files | 126.3 min | 82.9 min | -43.4 min | -34.4% | 0/77 | IMPROVE |
| finalize/group_similar | 11.8 min | 57.2 s | -10.9 min | -91.9% | 0/14 | IMPROVE |
| finalize/calculate_statistics | 5 min | 4.9 min | -8.8 s | -2.9% | 12/48 | IMPROVE |
| finalize/calculate_statistics/bucket_stats (within parent) | 2 min | 1.7 min | -21.3 s | -17.5% | 0/32 | IMPROVE |
| finalize/calculate_statistics/population_walk (within parent) | 57.0 s | 1 min | +4.5 s | 7.8% | 3/5 | REGRESS (most cases IMPROVE) |
| finalize/calculate_statistics/sort_selection (within parent) | 1.3 min | 1.3 min | -1.5 s | -1.8% | 10/28 | IMPROVE |
| finalize/calculate_statistics/group_calc (within parent) | 40 s | 49.3 s | +9.3 s | 23.4% | 12/21 | REGRESS (most cases IMPROVE) |
| finalize/calculate_statistics/untimed (within parent) | 3.7 s | 3.9 s | +189 ms | 5.1% | 12/5 | REGRESS |
| render/normalize_data | 129 ms | 265 ms | +136 ms | 105.4% | 66/0 | REGRESS |
| total | 143.3 min | 88.8 min | -54.5 min | -38.0% | 0/77 | IMPROVE |
| (2 below noise floor) | 1.9 s | 1.8 s | -20 ms | -1.1% | - | IMPROVE |
| sum of stages | 143.3 min | 88.8 min | -54.5 min | -38.0% | - | IMPROVE |

### Category Rollup (memory)

| metric | baseline | current | delta | change% | cases +/- | result |
| --- | --- | --- | --- | --- | --- | --- |
| rss_peak | 101.2 GB | 90.8 GB | -10.4 GB | -10.3% | 51/26 | IMPROVE (most cases REGRESS) |
| log_messages | 68.9 GB | 59.8 GB | -9.1 GB | -13.2% | 31/32 | IMPROVE |
| unattributed | 16.5 GB | 15.2 GB | -1.3 GB | -7.8% | 49/26 | IMPROVE (most cases REGRESS) |
| format_scan_subs | 112.1 MB | 144.1 MB | +32.0 MB | 28.5% | 74/3 | REGRESS |
| consolidation_id_index | 839.9 MB | 841.6 MB | +1.7 MB | 0.2% | 8/4 | REGRESS |
| (27 below noise floor) | 15.0 GB | 15.0 GB | +498.8 KB | 0.0% | - | REGRESS |

### New In This Version

| metric | test cases | per-test range | aggregate |
| --- | --- | --- | --- |
| TIMING/read/path_generation | 77 | 6 ms - 277 ms | 3.9 s |

### Summary

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.8 s | 2.1 s | -771 ms | -27.1% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 265.5 MB | 267.6 MB | +2 MB | 0.8% | REGRESS |
| humungous-log-uniqueness-no-messages | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | TIMING/total | 2.0 s | 1.4 s | -550 ms | -27.8% | IMPROVE |
| humungous-log-uniqueness-no-messages | MEMORY/rss_peak | 38.6 MB | 42.1 MB | +3.5 MB | 9.1% | REGRESS |
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.9 s | 2 s | -815 ms | -28.5% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 264.7 MB | 267.7 MB | +3.0 MB | 1.1% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 4.1 s | 3.4 s | -715 ms | -17.4% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 50 MB | 53.5 MB | +3.4 MB | 6.8% | REGRESS |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.8 s | 2.2 s | -614 ms | -22.1% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 265.8 MB | 267.9 MB | +2.2 MB | 0.8% | REGRESS |
| humungous-log-uniqueness-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.8 s | 2.1 s | -749 ms | -26.4% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 264.4 MB | 267.7 MB | +3.3 MB | 1.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.8 s | 2.1 s | -668 ms | -24.1% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 265.5 MB | 267.7 MB | +2.2 MB | 0.8% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-export | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/total | 1.9 s | 1.5 s | -472 ms | -24.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/rss_peak | 38.5 MB | 41.9 MB | +3.4 MB | 8.9% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 4.1 s | 3.4 s | -712 ms | -17.5% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 49.9 MB | 53.1 MB | +3.2 MB | 6.4% | REGRESS |
| humungous-log-uniqueness-sort-p99 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/total | 2.7 s | 2.1 s | -646 ms | -23.6% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | MEMORY/rss_peak | 265.2 MB | 267.9 MB | +2.7 MB | 1.0% | REGRESS |
| humungous-log-uniqueness-sort-skewness | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/total | 2.7 s | 2.1 s | -639 ms | -23.4% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | MEMORY/rss_peak | 265.6 MB | 267.9 MB | +2.3 MB | 0.9% | REGRESS |
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.7 s | 2.6 s | -1.1 s | -30.1% | IMPROVE |
| single-day-application-log-standard | MEMORY/rss_peak | 42.3 MB | 45.7 MB | +3.3 MB | 7.9% | REGRESS |
| single-day-application-log-no-messages | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-no-messages | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-no-messages | TIMING/total | 3.1 s | 2.3 s | -839 ms | -26.8% | IMPROVE |
| single-day-application-log-no-messages | MEMORY/rss_peak | 38.5 MB | 41.9 MB | +3.5 MB | 9.1% | REGRESS |
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.6 s | 2.6 s | -1 s | -28.6% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 42.3 MB | 45.9 MB | +3.6 MB | 8.5% | REGRESS |
| single-day-application-log-top25-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 5.3 s | 4.2 s | -1.1 s | -20.7% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 111.5 MB | 116.2 MB | +4.6 MB | 4.1% | REGRESS |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.7 s | 2.6 s | -1.1 s | -29.5% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/rss_peak | 42.4 MB | 45.7 MB | +3.2 MB | 7.7% | REGRESS |
| single-day-application-log-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.7 s | 2.6 s | -1.1 s | -29.8% | IMPROVE |
| single-day-application-log-histogram | MEMORY/rss_peak | 42.5 MB | 45.5 MB | +3.0 MB | 7.0% | REGRESS |
| single-day-application-log-heatmap-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.6 s | 2.6 s | -1 s | -27.6% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 42.4 MB | 45.8 MB | +3.4 MB | 8.1% | REGRESS |
| single-day-application-log-heatmap-histogram-export | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | TIMING/total | 3.1 s | 2.3 s | -807 ms | -25.9% | IMPROVE |
| single-day-application-log-heatmap-histogram-export | MEMORY/rss_peak | 38.5 MB | 42.0 MB | +3.5 MB | 9.1% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 5.4 s | 4.2 s | -1.1 s | -20.8% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 111.4 MB | 116.7 MB | +5.3 MB | 4.7% | REGRESS |
| single-day-application-log-sort-p99 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/total | 3.7 s | 2.5 s | -1.1 s | -31.0% | IMPROVE |
| single-day-application-log-sort-p99 | MEMORY/rss_peak | 42.4 MB | 45.5 MB | +3.1 MB | 7.3% | REGRESS |
| single-day-application-log-sort-skewness | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/total | 3.7 s | 2.6 s | -1.1 s | -30.2% | IMPROVE |
| single-day-application-log-sort-skewness | MEMORY/rss_peak | 42.3 MB | 45.7 MB | +3.4 MB | 8.1% | REGRESS |
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 8 s | 5.9 s | -2.1 s | -26.0% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/rss_peak | 107.2 MB | 110.0 MB | +2.8 MB | 2.6% | REGRESS |
| multi-day-application-logs-no-messages | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | TIMING/total | 6.6 s | 4.9 s | -1.6 s | -24.7% | IMPROVE |
| multi-day-application-logs-no-messages | MEMORY/rss_peak | 39.8 MB | 42.9 MB | +3.1 MB | 7.8% | REGRESS |
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 7.9 s | 6.0 s | -2.0 s | -24.6% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 107.4 MB | 110.1 MB | +2.7 MB | 2.5% | REGRESS |
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 33.6 s | 29.6 s | -4.0 s | -11.8% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 229.9 MB | 233.9 MB | +4.0 MB | 1.7% | REGRESS |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 8 s | 5.8 s | -2.2 s | -27.3% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 107.2 MB | 110.2 MB | +2.9 MB | 2.7% | REGRESS |
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 8.0 s | 5.9 s | -2 s | -25.4% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 107.5 MB | 109.7 MB | +2.2 MB | 2.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 8.0 s | 6 s | -2.0 s | -24.7% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 107.5 MB | 109.7 MB | +2.2 MB | 2.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-export | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | TIMING/total | 6.6 s | 5.0 s | -1.6 s | -24.2% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/rss_peak | 39.9 MB | 42.9 MB | +3 MB | 7.6% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 33.4 s | 29.6 s | -3.8 s | -11.4% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 226.6 MB | 233.4 MB | +6.9 MB | 3.0% | REGRESS |
| multi-day-application-logs-sort-p99 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/total | 8.0 s | 6.0 s | -2.0 s | -24.8% | IMPROVE |
| multi-day-application-logs-sort-p99 | MEMORY/rss_peak | 107.7 MB | 110.1 MB | +2.5 MB | 2.3% | REGRESS |
| multi-day-application-logs-sort-skewness | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/total | 7.9 s | 6.0 s | -1.9 s | -24.5% | IMPROVE |
| multi-day-application-logs-sort-skewness | MEMORY/rss_peak | 107.8 MB | 110.2 MB | +2.5 MB | 2.3% | REGRESS |
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 16.5 s | 11.6 s | -4.9 s | -29.8% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 177.4 MB | 180.5 MB | +3.1 MB | 1.8% | REGRESS |
| multi-day-custom-logs-no-messages | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | TIMING/total | 13.2 s | 9.5 s | -3.7 s | -27.9% | IMPROVE |
| multi-day-custom-logs-no-messages | MEMORY/rss_peak | 54.5 MB | 56.9 MB | +2.3 MB | 4.3% | REGRESS |
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 16.5 s | 11.5 s | -4.9 s | -29.9% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 175.8 MB | 179.9 MB | +4.1 MB | 2.3% | REGRESS |
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 39.1 s | 33.8 s | -5.3 s | -13.6% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 227.2 MB | 233.4 MB | +6.2 MB | 2.8% | REGRESS |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 17.3 s | 12.1 s | -5.2 s | -30.0% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 172.6 MB | 176.7 MB | +4.1 MB | 2.4% | REGRESS |
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 17.2 s | 12.4 s | -4.8 s | -27.9% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 177.4 MB | 179.6 MB | +2.2 MB | 1.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 17.6 s | 12.9 s | -4.7 s | -26.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 173 MB | 177.0 MB | +3.9 MB | 2.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/total | 14.6 s | 11.2 s | -3.4 s | -23.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/rss_peak | 57.9 MB | 58.3 MB | +416 KB | 0.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 39.7 s | 34.6 s | -5.1 s | -12.7% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 225.8 MB | 230.8 MB | +5.0 MB | 2.2% | REGRESS |
| multi-day-custom-logs-sort-p99 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/total | 16.3 s | 11.4 s | -4.9 s | -29.9% | IMPROVE |
| multi-day-custom-logs-sort-p99 | MEMORY/rss_peak | 174.5 MB | 177.8 MB | +3.3 MB | 1.9% | REGRESS |
| multi-day-custom-logs-sort-skewness | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/total | 16.3 s | 11.6 s | -4.8 s | -29.2% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY/rss_peak | 172.6 MB | 176.8 MB | +4.2 MB | 2.4% | REGRESS |
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 8.7 s | 4.9 s | -3.8 s | -43.9% | IMPROVE |
| single-day-access-log-standard | MEMORY/rss_peak | 99.8 MB | 100.2 MB | +400 KB | 0.4% | REGRESS |
| single-day-access-log-no-messages | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-no-messages | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-no-messages | TIMING/total | 6.7 s | 4.1 s | -2.5 s | -38.3% | IMPROVE |
| single-day-access-log-no-messages | MEMORY/rss_peak | 65 MB | 68.5 MB | +3.5 MB | 5.4% | REGRESS |
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 8.7 s | 5.0 s | -3.7 s | -42.7% | IMPROVE |
| single-day-access-log-top25 | MEMORY/rss_peak | 99.8 MB | 99.5 MB | -368 KB | -0.4% | IMPROVE |
| single-day-access-log-top25-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 12 s | 6.5 s | -5.5 s | -45.9% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 131.0 MB | 130.0 MB | -1 MB | -0.8% | IMPROVE |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 9.5 s | 5.7 s | -3.7 s | -39.5% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/rss_peak | 83.6 MB | 81.6 MB | -2 MB | -2.4% | IMPROVE |
| single-day-access-log-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 10.7 s | 7.0 s | -3.7 s | -34.7% | IMPROVE |
| single-day-access-log-histogram | MEMORY/rss_peak | 99.6 MB | 100 MB | +448 KB | 0.4% | REGRESS |
| single-day-access-log-heatmap-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 11.2 s | 7.6 s | -3.6 s | -32.3% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 83.8 MB | 80.8 MB | -3 MB | -3.6% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | TIMING/total | 9.8 s | 7.1 s | -2.7 s | -27.8% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | MEMORY/rss_peak | 69 MB | 69.2 MB | +176 KB | 0.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 13.8 s | 8.9 s | -4.9 s | -35.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 113.2 MB | 106.2 MB | -7.0 MB | -6.1% | IMPROVE |
| single-day-access-log-sort-p99 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/total | 8.8 s | 5.0 s | -3.8 s | -43.4% | IMPROVE |
| single-day-access-log-sort-p99 | MEMORY/rss_peak | 98.7 MB | 99.4 MB | +736 KB | 0.7% | REGRESS |
| single-day-access-log-sort-skewness | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/total | 8.9 s | 5 s | -3.9 s | -43.7% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY/rss_peak | 104.5 MB | 98.9 MB | -5.7 MB | -5.4% | IMPROVE |
| month-single-server-access-logs-standard | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/total | 1.7 min | 58 s | -41.7 s | -41.8% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2 GB | 1.8 GB | -189.7 MB | -9.2% | IMPROVE |
| month-single-server-access-logs-no-messages | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | TIMING/total | 1.2 min | 45.3 s | -27.8 s | -38.0% | IMPROVE |
| month-single-server-access-logs-no-messages | MEMORY/rss_peak | 370.2 MB | 354.8 MB | -15.4 MB | -4.2% | IMPROVE |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 1.7 min | 57.8 s | -41.9 s | -42.0% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2 GB | 1.7 GB | -264.6 MB | -12.9% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 2.8 min | 1.5 min | -1.3 min | -47.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 801.2 MB | 820.7 MB | +19.5 MB | 2.4% | REGRESS |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/total | 1.8 min | 1.1 min | -41.4 s | -38.2% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 1.8 GB | 1.6 GB | -184.8 MB | -10.1% | IMPROVE |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/total | 2 min | 1.4 min | -40.4 s | -33.0% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 2 GB | 1.8 GB | -188.3 MB | -9.2% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.2 min | 1.5 min | -41.3 s | -32.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 1.8 GB | 1.5 GB | -262.6 MB | -14.4% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/total | 1.8 min | 1.3 min | -29.7 s | -27.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/rss_peak | 371.6 MB | 358.4 MB | -13.2 MB | -3.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 3.0 min | 1.9 min | -1 min | -35.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 692.7 MB | 639.3 MB | -53.3 MB | -7.7% | IMPROVE |
| month-single-server-access-logs-sort-p99 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | TIMING/total | 1.8 min | 1.1 min | -42 s | -39.5% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/rss_peak | 2.2 GB | 1.9 GB | -268 MB | -12.0% | IMPROVE |
| month-single-server-access-logs-sort-skewness | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/total | 1.7 min | 59.7 s | -41.7 s | -41.1% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/rss_peak | 2.1 GB | 1.8 GB | -277.7 MB | -13.1% | IMPROVE |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/total | 8.4 min | 4.9 min | -3.5 min | -41.4% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 10.1 GB | 8.7 GB | -1.4 GB | -13.5% | IMPROVE |
| month-many-servers-access-logs-no-messages | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | TIMING/total | 6.2 min | 3.8 min | -2.3 min | -38.0% | IMPROVE |
| month-many-servers-access-logs-no-messages | MEMORY/rss_peak | 1.7 GB | 1.6 GB | -64.0 MB | -3.7% | IMPROVE |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/total | 8.4 min | 4.9 min | -3.5 min | -41.4% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 10.1 GB | 8.7 GB | -1.4 GB | -13.5% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 16.2 min | 7.7 min | -8.5 min | -52.3% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 3.5 GB | 3.4 GB | -95.2 MB | -2.6% | IMPROVE |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/total | 9 min | 5.6 min | -3.4 min | -37.9% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 8.8 GB | 7.5 GB | -1.4 GB | -15.3% | IMPROVE |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/total | 10.3 min | 6.9 min | -3.4 min | -32.7% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 10 GB | 8.7 GB | -1.3 GB | -13.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 10.7 min | 7.4 min | -3.3 min | -31.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 8.8 GB | 7.9 GB | -1013.9 MB | -11.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/total | 9 min | 6.7 min | -2.4 min | -26.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/rss_peak | 1.7 GB | 1.6 GB | -88.3 MB | -5.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 16.7 min | 10.0 min | -6.8 min | -40.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 2.5 GB | 2.7 GB | +144.5 MB | 5.6% | REGRESS |
| month-many-servers-access-logs-sort-p99 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | TIMING/total | 9.1 min | 5.6 min | -3.5 min | -38.6% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/rss_peak | 10.9 GB | 9.6 GB | -1.4 GB | -12.4% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | TIMING/total | 8.6 min | 5.1 min | -3.5 min | -40.6% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY/rss_peak | 10.4 GB | 9.4 GB | -1 GB | -9.7% | IMPROVE |

### Detailed

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| humungous-log-uniqueness-standard | TIMING/detect/scan_sub_compile | 7 ms | 11 ms | +4 ms | 57.1% | REGRESS |
| humungous-log-uniqueness-standard | TIMING/parse/read_files | 2.5 s | 1.7 s | -762 ms | -30.3% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics | 323 ms | 305 ms | -18 ms | -5.6% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics/sort_selection | 310 ms | 292 ms | -18 ms | -5.8% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.8 s | 2.1 s | -771 ms | -27.1% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 265.5 MB | 267.6 MB | +2 MB | 0.8% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +416 KB | 35.6% | REGRESS |
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
| humungous-log-uniqueness-standard | MEMORY/log_messages | 172.9 MB | 172.9 MB | +1.5 KB | 0.0% | REGRESS |
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
| humungous-log-uniqueness-standard | MEMORY/unattributed | 91.5 MB | 93.1 MB | +1.6 MB | 1.8% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY_FINAL/log_messages | 181317607 | 181319175 | 1568 | 0.0% | REGRESS |
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
| humungous-log-uniqueness-no-messages | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| humungous-log-uniqueness-no-messages | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| humungous-log-uniqueness-no-messages | TIMING/parse/read_files | 2.0 s | 1.4 s | -560 ms | -28.4% | IMPROVE |
| humungous-log-uniqueness-no-messages | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-no-messages | TIMING/total | 2.0 s | 1.4 s | -550 ms | -27.8% | IMPROVE |
| humungous-log-uniqueness-no-messages | MEMORY/rss_peak | 38.6 MB | 42.1 MB | +3.5 MB | 9.1% | REGRESS |
| humungous-log-uniqueness-no-messages | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/format_scan_subs | 1.1 MB | 1.6 MB | +480 KB | 42.9% | REGRESS |
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
| humungous-log-uniqueness-no-messages | MEMORY/unattributed | 37.5 MB | 40.5 MB | +3 MB | 8.1% | REGRESS |
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
| humungous-log-uniqueness-top25 | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/parse/read_files | 2.5 s | 1.7 s | -788 ms | -31.2% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics | 327 ms | 289 ms | -38 ms | -11.6% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics/sort_selection | 314 ms | 276 ms | -38 ms | -12.1% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.9 s | 2 s | -815 ms | -28.5% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 264.7 MB | 267.7 MB | +3.0 MB | 1.1% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +368 KB | 32.9% | REGRESS |
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
| humungous-log-uniqueness-top25 | MEMORY/log_messages | 172.9 MB | 172.9 MB | +3.6 KB | 0.0% | REGRESS |
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
| humungous-log-uniqueness-top25 | MEMORY/unattributed | 90.6 MB | 93.3 MB | +2.6 MB | 2.9% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/log_messages | 181317607 | 181321335 | 3728 | 0.0% | REGRESS |
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
| humungous-log-uniqueness-top25-consolidate | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 11 ms | +5 ms | 83.3% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | TIMING/parse/read_files | 3.3 s | 2.6 s | -677 ms | -20.5% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | TIMING/finalize/group_similar | 784 ms | 737 ms | -47 ms | -6.0% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 4.1 s | 3.4 s | -715 ms | -17.4% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 50 MB | 53.5 MB | +3.4 MB | 6.8% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_clusters | 187.9 KB | 197.9 KB | +10 KB | 5.3% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_id_index | 5.7 MB | 5.7 MB | +2 KB | 0.0% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_message | 231.5 KB | 231.4 KB | -72 B | -0.0% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_trigrams | 2.8 MB | 2.8 MB | +2 KB | 0.1% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_patterns | 23.8 KB | 24.9 KB | +1.1 KB | 4.6% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_unmatched | 129.8 KB | 129.8 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +416 KB | 36.6% | REGRESS |
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
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_messages | 190.1 KB | 226.6 KB | +36.5 KB | 19.2% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_stats | 1.7 KB | 1.7 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_users | 8.5 KB | 8.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/message_key_order | 10.2 KB | 9.9 KB | -362 B | -3.4% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/unattributed | 39.7 MB | 42.7 MB | +3.0 MB | 7.4% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/log_messages | 45600 | 56968 | 11368 | 24.9% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 192377 | 202622 | 10245 | 5.3% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 24370 | 25496 | 1126 | 4.6% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 4152 | 4152 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 4152 | 4152 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_messages_entries | 76 | 74 | -2 | -2.6% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_messages_population | 76 | 74 | -2 | -2.6% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/max_log_message_length | 200 | 350 | 150 | 75.0% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/detect/scan_sub_compile | 6 ms | 11 ms | +5 ms | 83.3% | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/parse/read_files | 2.5 s | 1.8 s | -672 ms | -27.3% | IMPROVE |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics | 301 ms | 349 ms | +48 ms | 15.9% | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 288 ms | 336 ms | +48 ms | 16.7% | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.8 s | 2.2 s | -614 ms | -22.1% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 265.8 MB | 267.9 MB | +2.2 MB | 0.8% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/format_scan_subs | 1.2 MB | 1.5 MB | +336 KB | 27.6% | REGRESS |
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
| humungous-log-uniqueness-heatmap | MEMORY/log_messages | 172.9 MB | 172.9 MB | +1.5 KB | 0.0% | REGRESS |
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
| humungous-log-uniqueness-heatmap | MEMORY/unattributed | 91.6 MB | 93.5 MB | +1.8 MB | 2.0% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/log_messages | 181317607 | 181319175 | 1568 | 0.0% | REGRESS |
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
| humungous-log-uniqueness-histogram | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/parse/read_files | 2.5 s | 1.8 s | -741 ms | -29.7% | IMPROVE |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics | 325 ms | 306 ms | -19 ms | -5.8% | IMPROVE |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics/sort_selection | 312 ms | 293 ms | -19 ms | -6.1% | IMPROVE |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.8 s | 2.1 s | -749 ms | -26.4% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 264.4 MB | 267.7 MB | +3.3 MB | 1.2% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +416 KB | 38.2% | REGRESS |
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
| humungous-log-uniqueness-histogram | MEMORY/log_messages | 172.9 MB | 172.9 MB | +1.5 KB | 0.0% | REGRESS |
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
| humungous-log-uniqueness-histogram | MEMORY/unattributed | 90.4 MB | 93.3 MB | +2.9 MB | 3.2% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/log_messages | 181317607 | 181319175 | 1568 | 0.0% | REGRESS |
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
| humungous-log-uniqueness-heatmap-histogram | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/parse/read_files | 2.5 s | 1.8 s | -690 ms | -28.0% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics | 293 ms | 306 ms | +13 ms | 4.4% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 280 ms | 293 ms | +13 ms | 4.6% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.8 s | 2.1 s | -668 ms | -24.1% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 265.5 MB | 267.7 MB | +2.2 MB | 0.8% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +384 KB | 34.3% | REGRESS |
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
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_messages | 172.9 MB | 172.9 MB | +1.5 KB | 0.0% | REGRESS |
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
| humungous-log-uniqueness-heatmap-histogram | MEMORY/unattributed | 91.5 MB | 93.3 MB | +1.8 MB | 1.9% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/log_messages | 181317607 | 181319175 | 1568 | 0.0% | REGRESS |
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
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 6 ms | 11 ms | +5 ms | 83.3% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/parse/read_files | 1.9 s | 1.4 s | -483 ms | -25.1% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/total | 1.9 s | 1.5 s | -472 ms | -24.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/rss_peak | 38.5 MB | 41.9 MB | +3.4 MB | 8.9% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/format_scan_subs | 1.1 MB | 1.6 MB | +512 KB | 47.1% | REGRESS |
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
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/unattributed | 37.4 MB | 40.3 MB | +2.9 MB | 7.8% | REGRESS |
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
| humungous-log-uniqueness-heatmap-histogram-export | CONFIG/max_log_message_length | 200 | 350 | 150 | 75.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-export | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/parse/read_files | 3.3 s | 2.6 s | -697 ms | -21.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 768 ms | 742 ms | -26 ms | -3.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 4.1 s | 3.4 s | -712 ms | -17.5% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 49.9 MB | 53.1 MB | +3.2 MB | 6.4% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 187.9 KB | 197.9 KB | +10 KB | 5.3% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | 5.7 MB | 5.7 MB | +4 KB | 0.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 231.5 KB | 231.4 KB | -72 B | -0.0% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 2.8 MB | 2.8 MB | +4 KB | 0.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 23.8 KB | 24.9 KB | +1.1 KB | 4.6% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 129.8 KB | 129.8 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +400 KB | 35.7% | REGRESS |
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
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_messages | 190.1 KB | 226.6 KB | +36.5 KB | 19.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_stats | 1.7 KB | 1.7 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_users | 8.5 KB | 8.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/message_key_order | 3.3 KB | 3.3 KB | -16 B | -0.5% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/unattributed | 39.6 MB | 42.4 MB | +2.8 MB | 7.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 45600 | 54168 | 8568 | 18.8% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 192377 | 202622 | 10245 | 5.3% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 24370 | 25496 | 1126 | 4.6% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 4152 | 4152 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 4152 | 4152 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 76 | 74 | -2 | -2.6% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_messages_population | 76 | 74 | -2 | -2.6% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 350 | 150 | 75.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| humungous-log-uniqueness-sort-p99 | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| humungous-log-uniqueness-sort-p99 | TIMING/parse/read_files | 2.4 s | 1.8 s | -661 ms | -27.2% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics | 296 ms | 300 ms | +4 ms | 1.4% | REGRESS |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 284 ms | 287 ms | +3 ms | 1.1% | REGRESS |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/total | 2.7 s | 2.1 s | -646 ms | -23.6% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | MEMORY/rss_peak | 265.2 MB | 267.9 MB | +2.7 MB | 1.0% | REGRESS |
| humungous-log-uniqueness-sort-p99 | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +384 KB | 33.3% | REGRESS |
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
| humungous-log-uniqueness-sort-p99 | MEMORY/log_messages | 172.9 MB | 172.9 MB | +1.5 KB | 0.0% | REGRESS |
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
| humungous-log-uniqueness-sort-p99 | MEMORY/unattributed | 91.2 MB | 93.5 MB | +2.3 MB | 2.5% | REGRESS |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/log_messages | 181317607 | 181319175 | 1568 | 0.0% | REGRESS |
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
| humungous-log-uniqueness-sort-skewness | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| humungous-log-uniqueness-sort-skewness | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| humungous-log-uniqueness-sort-skewness | TIMING/parse/read_files | 2.4 s | 1.8 s | -661 ms | -27.4% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics | 302 ms | 314 ms | +12 ms | 4.0% | REGRESS |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 289 ms | 301 ms | +12 ms | 4.2% | REGRESS |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/total | 2.7 s | 2.1 s | -639 ms | -23.4% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | MEMORY/rss_peak | 265.6 MB | 267.9 MB | +2.3 MB | 0.9% | REGRESS |
| humungous-log-uniqueness-sort-skewness | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/format_scan_subs | 1 MB | 1.5 MB | +480 KB | 44.8% | REGRESS |
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
| humungous-log-uniqueness-sort-skewness | MEMORY/log_messages | 172.9 MB | 172.9 MB | +1.5 KB | 0.0% | REGRESS |
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
| humungous-log-uniqueness-sort-skewness | MEMORY/unattributed | 91.6 MB | 93.4 MB | +1.9 MB | 2.0% | REGRESS |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/log_messages | 181317607 | 181319175 | 1568 | 0.0% | REGRESS |
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
| single-day-application-log-standard | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| single-day-application-log-standard | TIMING/detect/scan_sub_compile | 6 ms | 11 ms | +5 ms | 83.3% | REGRESS |
| single-day-application-log-standard | TIMING/parse/read_files | 3.6 s | 2.5 s | -1.1 s | -30.5% | IMPROVE |
| single-day-application-log-standard | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 5 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-application-log-standard | TIMING/total | 3.7 s | 2.6 s | -1.1 s | -30.1% | IMPROVE |
| single-day-application-log-standard | MEMORY/rss_peak | 42.3 MB | 45.7 MB | +3.3 MB | 7.9% | REGRESS |
| single-day-application-log-standard | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +400 KB | 36.2% | REGRESS |
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
| single-day-application-log-standard | MEMORY/log_messages | 2.8 MB | 2.8 MB | +1.5 KB | 0.1% | REGRESS |
| single-day-application-log-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_users | 85.5 KB | 85.2 KB | -256 B | -0.3% | IMPROVE |
| single-day-application-log-standard | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/unattributed | 38.3 MB | 41.3 MB | +3.0 MB | 7.7% | REGRESS |
| single-day-application-log-standard | MEMORY_FINAL/log_messages | 2914830 | 2916398 | 1568 | 0.1% | REGRESS |
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
| single-day-application-log-no-messages | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| single-day-application-log-no-messages | TIMING/detect/scan_sub_compile | 6 ms | 11 ms | +5 ms | 83.3% | REGRESS |
| single-day-application-log-no-messages | TIMING/parse/read_files | 3.1 s | 2.3 s | -850 ms | -27.3% | IMPROVE |
| single-day-application-log-no-messages | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-application-log-no-messages | TIMING/total | 3.1 s | 2.3 s | -839 ms | -26.8% | IMPROVE |
| single-day-application-log-no-messages | MEMORY/rss_peak | 38.5 MB | 41.9 MB | +3.5 MB | 9.1% | REGRESS |
| single-day-application-log-no-messages | MEMORY/bucket_outcomes | 5.8 KB | 6 KB | +256 B | 4.3% | REGRESS |
| single-day-application-log-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +384 KB | 34.3% | REGRESS |
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
| single-day-application-log-no-messages | MEMORY/log_occurrences | 21.5 KB | 21.8 KB | +256 B | 1.2% | REGRESS |
| single-day-application-log-no-messages | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/log_stats | 7.6 KB | 7.9 KB | +256 B | 3.3% | REGRESS |
| single-day-application-log-no-messages | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/log_users | 85.2 KB | 85.5 KB | +256 B | 0.3% | REGRESS |
| single-day-application-log-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/unattributed | 37.2 MB | 40.3 MB | +3.1 MB | 8.3% | REGRESS |
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
| single-day-application-log-top25 | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| single-day-application-log-top25 | TIMING/detect/scan_sub_compile | 6 ms | 11 ms | +5 ms | 83.3% | REGRESS |
| single-day-application-log-top25 | TIMING/parse/read_files | 3.6 s | 2.6 s | -1.1 s | -29.1% | IMPROVE |
| single-day-application-log-top25 | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| single-day-application-log-top25 | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-application-log-top25 | TIMING/total | 3.6 s | 2.6 s | -1 s | -28.6% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 42.3 MB | 45.9 MB | +3.6 MB | 8.5% | REGRESS |
| single-day-application-log-top25 | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/format_scan_subs | 1.1 MB | 1.6 MB | +544 KB | 50.0% | REGRESS |
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
| single-day-application-log-top25 | MEMORY/log_messages | 2.8 MB | 2.8 MB | +3.6 KB | 0.1% | REGRESS |
| single-day-application-log-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_users | 85.5 KB | 85.5 KB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/message_key_order | 6.4 KB | 6.4 KB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/unattributed | 38.4 MB | 41.4 MB | +3 MB | 7.9% | REGRESS |
| single-day-application-log-top25 | MEMORY_FINAL/log_messages | 2914830 | 2918558 | 3728 | 0.1% | REGRESS |
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
| single-day-application-log-top25-consolidate | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| single-day-application-log-top25-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| single-day-application-log-top25-consolidate | TIMING/parse/read_files | 5 s | 4.0 s | -1.1 s | -21.3% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/finalize/group_similar | 291 ms | 252 ms | -39 ms | -13.4% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-application-log-top25-consolidate | TIMING/total | 5.3 s | 4.2 s | -1.1 s | -20.7% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 111.5 MB | 116.2 MB | +4.6 MB | 4.1% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_clusters | 346.8 KB | 346.2 KB | -640 B | -0.2% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_id_index | 55.7 MB | 55.7 MB | -2 KB | -0.0% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_message | 1.4 MB | 1.4 MB | +616 B | 0.0% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_trigrams | 28.0 MB | 28.0 MB | -4 KB | -0.0% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_patterns | 42.8 KB | 42.8 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_unmatched | 800.7 KB | 800.7 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +432 KB | 38.0% | REGRESS |
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
| single-day-application-log-top25-consolidate | MEMORY/log_messages | 1.2 MB | 1.5 MB | +290.2 KB | 23.1% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_users | 85.2 KB | 85.2 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/message_key_order | 6.8 KB | 6.8 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/unattributed | 22.9 MB | 26.8 MB | +3.9 MB | 17.1% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/log_messages | 91437 | 106507 | 15070 | 16.5% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 355127 | 354487 | -640 | -0.2% | IMPROVE |
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
| single-day-application-log-top25-consolidate | CONFIG/max_log_message_length | 200 | 350 | 150 | 75.0% | REGRESS |
| single-day-application-log-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| single-day-application-log-heatmap | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| single-day-application-log-heatmap | TIMING/parse/read_files | 3.7 s | 2.6 s | -1.1 s | -30.0% | IMPROVE |
| single-day-application-log-heatmap | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 5 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-application-log-heatmap | TIMING/total | 3.7 s | 2.6 s | -1.1 s | -29.5% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/rss_peak | 42.4 MB | 45.7 MB | +3.2 MB | 7.7% | REGRESS |
| single-day-application-log-heatmap | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +400 KB | 36.2% | REGRESS |
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
| single-day-application-log-heatmap | MEMORY/log_messages | 2.8 MB | 2.8 MB | +1.5 KB | 0.1% | REGRESS |
| single-day-application-log-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_users | 85.5 KB | 85.5 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/unattributed | 38.5 MB | 41.3 MB | +2.9 MB | 7.4% | REGRESS |
| single-day-application-log-heatmap | MEMORY_FINAL/log_messages | 2914830 | 2916398 | 1568 | 0.1% | REGRESS |
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
| single-day-application-log-histogram | TIMING/detect/registry_build | 13 ms | 22 ms | +9 ms | 69.2% | REGRESS |
| single-day-application-log-histogram | TIMING/detect/scan_sub_compile | 7 ms | 10 ms | +3 ms | 42.9% | REGRESS |
| single-day-application-log-histogram | TIMING/parse/read_files | 3.7 s | 2.6 s | -1.1 s | -30.2% | IMPROVE |
| single-day-application-log-histogram | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 5 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-application-log-histogram | TIMING/total | 3.7 s | 2.6 s | -1.1 s | -29.8% | IMPROVE |
| single-day-application-log-histogram | MEMORY/rss_peak | 42.5 MB | 45.5 MB | +3.0 MB | 7.0% | REGRESS |
| single-day-application-log-histogram | MEMORY/bucket_outcomes | 6 KB | 5.8 KB | -256 B | -4.2% | IMPROVE |
| single-day-application-log-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +400 KB | 35.7% | REGRESS |
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
| single-day-application-log-histogram | MEMORY/log_messages | 2.8 MB | 2.8 MB | +1.5 KB | 0.1% | REGRESS |
| single-day-application-log-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_occurrences | 21.8 KB | 21.5 KB | -256 B | -1.1% | IMPROVE |
| single-day-application-log-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_users | 85.2 KB | 85.2 KB | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/unattributed | 38.5 MB | 41.1 MB | +2.6 MB | 6.7% | REGRESS |
| single-day-application-log-histogram | MEMORY_FINAL/log_messages | 2914830 | 2916398 | 1568 | 0.1% | REGRESS |
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
| single-day-application-log-heatmap-histogram | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| single-day-application-log-heatmap-histogram | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| single-day-application-log-heatmap-histogram | TIMING/parse/read_files | 3.6 s | 2.6 s | -1 s | -28.1% | IMPROVE |
| single-day-application-log-heatmap-histogram | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 5 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.6 s | 2.6 s | -1 s | -27.6% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 42.4 MB | 45.8 MB | +3.4 MB | 8.1% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +384 KB | 33.3% | REGRESS |
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
| single-day-application-log-heatmap-histogram | MEMORY/log_messages | 2.8 MB | 2.8 MB | +1.5 KB | 0.1% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_users | 85.2 KB | 85.2 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/unattributed | 38.4 MB | 41.4 MB | +3 MB | 7.9% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/log_messages | 2914830 | 2916398 | 1568 | 0.1% | REGRESS |
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
| single-day-application-log-heatmap-histogram-export | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| single-day-application-log-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 6 ms | 11 ms | +5 ms | 83.3% | REGRESS |
| single-day-application-log-heatmap-histogram-export | TIMING/parse/read_files | 3.1 s | 2.3 s | -818 ms | -26.3% | IMPROVE |
| single-day-application-log-heatmap-histogram-export | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-application-log-heatmap-histogram-export | TIMING/total | 3.1 s | 2.3 s | -807 ms | -25.9% | IMPROVE |
| single-day-application-log-heatmap-histogram-export | MEMORY/rss_peak | 38.5 MB | 42.0 MB | +3.5 MB | 9.1% | REGRESS |
| single-day-application-log-heatmap-histogram-export | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/format_scan_subs | 1.1 MB | 1.6 MB | +544 KB | 50.0% | REGRESS |
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
| single-day-application-log-heatmap-histogram-export | MEMORY/log_users | 84.7 KB | 85.2 KB | +512 B | 0.6% | REGRESS |
| single-day-application-log-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/unattributed | 37.3 MB | 40.3 MB | +3.0 MB | 8.0% | REGRESS |
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
| single-day-application-log-heatmap-histogram-export | CONFIG/max_log_message_length | 200 | 350 | 150 | 75.0% | REGRESS |
| single-day-application-log-heatmap-histogram-export | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 11 ms | +5 ms | 83.3% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/parse/read_files | 5 s | 3.9 s | -1.1 s | -21.7% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 301 ms | 268 ms | -33 ms | -11.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/render/normalize_data | 1 ms | 3 ms | +2 ms | 200.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 5.4 s | 4.2 s | -1.1 s | -20.8% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 111.4 MB | 116.7 MB | +5.3 MB | 4.7% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 5.8 KB | 6 KB | +256 B | 4.3% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 346.1 KB | 346.8 KB | +768 B | 0.2% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | 55.7 MB | 55.7 MB | +4 KB | 0.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 1.4 MB | 1.4 MB | +616 B | 0.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 28.0 MB | 28.0 MB | +4 KB | 0.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 42.8 KB | 42.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 800.7 KB | 800.7 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +432 KB | 39.1% | REGRESS |
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
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_messages | 1.2 MB | 1.5 MB | +290.2 KB | 23.1% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 21.5 KB | 21.8 KB | +256 B | 1.2% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_stats | 7.6 KB | 7.9 KB | +256 B | 3.3% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_users | 85.2 KB | 85.2 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/unattributed | 22.8 MB | 27.4 MB | +4.6 MB | 19.9% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 91437 | 103451 | 12014 | 13.1% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 354359 | 355127 | 768 | 0.2% | REGRESS |
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
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 350 | 150 | 75.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| single-day-application-log-sort-p99 | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| single-day-application-log-sort-p99 | TIMING/parse/read_files | 3.7 s | 2.5 s | -1.2 s | -31.5% | IMPROVE |
| single-day-application-log-sort-p99 | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 5 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-application-log-sort-p99 | TIMING/total | 3.7 s | 2.5 s | -1.1 s | -31.0% | IMPROVE |
| single-day-application-log-sort-p99 | MEMORY/rss_peak | 42.4 MB | 45.5 MB | +3.1 MB | 7.3% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +400 KB | 35.2% | REGRESS |
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
| single-day-application-log-sort-p99 | MEMORY/log_messages | 2.8 MB | 2.8 MB | +1.5 KB | 0.1% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_users | 85.2 KB | 85.2 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/unattributed | 38.4 MB | 41.1 MB | +2.7 MB | 7.0% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY_FINAL/log_messages | 2914830 | 2916398 | 1568 | 0.1% | REGRESS |
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
| single-day-application-log-sort-skewness | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| single-day-application-log-sort-skewness | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| single-day-application-log-sort-skewness | TIMING/parse/read_files | 3.7 s | 2.6 s | -1.1 s | -30.7% | IMPROVE |
| single-day-application-log-sort-skewness | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| single-day-application-log-sort-skewness | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-application-log-sort-skewness | TIMING/total | 3.7 s | 2.6 s | -1.1 s | -30.2% | IMPROVE |
| single-day-application-log-sort-skewness | MEMORY/rss_peak | 42.3 MB | 45.7 MB | +3.4 MB | 8.1% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +400 KB | 35.7% | REGRESS |
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
| single-day-application-log-sort-skewness | MEMORY/log_messages | 2.8 MB | 2.8 MB | +1.5 KB | 0.1% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_users | 85.5 KB | 85.5 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/unattributed | 38.3 MB | 41.3 MB | +3 MB | 7.9% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY_FINAL/log_messages | 2914830 | 2916398 | 1568 | 0.1% | REGRESS |
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
| multi-day-application-logs-standard | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| multi-day-application-logs-standard | TIMING/detect/scan_sub_compile | 6 ms | 11 ms | +5 ms | 83.3% | REGRESS |
| multi-day-application-logs-standard | TIMING/parse/read_files | 7.8 s | 5.7 s | -2.1 s | -26.8% | IMPROVE |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics | 173 ms | 172 ms | -1 ms | -0.6% | IMPROVE |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 171 ms | 170 ms | -1 ms | -0.6% | IMPROVE |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/render/normalize_data | 2 ms | 5 ms | +3 ms | 150.0% | REGRESS |
| multi-day-application-logs-standard | TIMING/total | 8 s | 5.9 s | -2.1 s | -26.0% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/rss_peak | 107.2 MB | 110.0 MB | +2.8 MB | 2.6% | REGRESS |
| multi-day-application-logs-standard | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +448 KB | 40.6% | REGRESS |
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
| multi-day-application-logs-standard | MEMORY/log_messages | 48.9 MB | 48.9 MB | +1.5 KB | 0.0% | REGRESS |
| multi-day-application-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_users | 40.6 KB | 41.1 KB | +512 B | 1.2% | REGRESS |
| multi-day-application-logs-standard | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/unattributed | 57.1 MB | 59.4 MB | +2.3 MB | 4.1% | REGRESS |
| multi-day-application-logs-standard | MEMORY_FINAL/log_messages | 51302480 | 51304048 | 1568 | 0.0% | REGRESS |
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
| multi-day-application-logs-no-messages | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| multi-day-application-logs-no-messages | TIMING/detect/scan_sub_compile | 6 ms | 11 ms | +5 ms | 83.3% | REGRESS |
| multi-day-application-logs-no-messages | TIMING/parse/read_files | 6.5 s | 4.9 s | -1.6 s | -25.0% | IMPROVE |
| multi-day-application-logs-no-messages | TIMING/render/normalize_data | 2 ms | 5 ms | +3 ms | 150.0% | REGRESS |
| multi-day-application-logs-no-messages | TIMING/total | 6.6 s | 4.9 s | -1.6 s | -24.7% | IMPROVE |
| multi-day-application-logs-no-messages | MEMORY/rss_peak | 39.8 MB | 42.9 MB | +3.1 MB | 7.8% | REGRESS |
| multi-day-application-logs-no-messages | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +448 KB | 40.6% | REGRESS |
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
| multi-day-application-logs-no-messages | MEMORY/log_occurrences | 56.7 KB | 56.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/log_users | 40.5 KB | 40.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/unattributed | 38.6 MB | 41.3 MB | +2.7 MB | 6.9% | REGRESS |
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
| multi-day-application-logs-top25 | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| multi-day-application-logs-top25 | TIMING/detect/scan_sub_compile | 6 ms | 11 ms | +5 ms | 83.3% | REGRESS |
| multi-day-application-logs-top25 | TIMING/parse/read_files | 7.7 s | 5.8 s | -2.0 s | -25.4% | IMPROVE |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics | 172 ms | 175 ms | +3 ms | 1.7% | REGRESS |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 170 ms | 172 ms | +2 ms | 1.2% | REGRESS |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/render/normalize_data | 2 ms | 5 ms | +3 ms | 150.0% | REGRESS |
| multi-day-application-logs-top25 | TIMING/total | 7.9 s | 6.0 s | -2.0 s | -24.6% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 107.4 MB | 110.1 MB | +2.7 MB | 2.5% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +448 KB | 40.6% | REGRESS |
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
| multi-day-application-logs-top25 | MEMORY/log_messages | 48.9 MB | 48.9 MB | +3.6 KB | 0.0% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_users | 40.6 KB | 40.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/message_key_order | 6.5 KB | 6.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/unattributed | 57.2 MB | 59.5 MB | +2.3 MB | 4.0% | REGRESS |
| multi-day-application-logs-top25 | MEMORY_FINAL/log_messages | 51302480 | 51306208 | 3728 | 0.0% | REGRESS |
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
| multi-day-application-logs-top25-consolidate | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 11 ms | +5 ms | 83.3% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/parse/read_files | 29.5 s | 27.4 s | -2.1 s | -7.1% | IMPROVE |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/group_similar | 4 s | 2.2 s | -1.9 s | -46.4% | IMPROVE |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 3 ms | 2 ms | -1 ms | -33.3% | IMPROVE |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/render/normalize_data | 3 ms | 6 ms | +3 ms | 100.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/total | 33.6 s | 29.6 s | -4.0 s | -11.8% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 229.9 MB | 233.9 MB | +4.0 MB | 1.7% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_clusters | 3 MB | 3.2 MB | +155.3 KB | 5.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_id_index | 127.2 MB | 127.2 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_message | 3.8 MB | 3.8 MB | -200 B | -0.0% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 65.7 MB | 65.7 MB | -1 KB | -0.0% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_patterns | 427.2 KB | 450.8 KB | +23.6 KB | 5.5% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_unmatched | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/format_scan_subs | 1.2 MB | 1.5 MB | +336 KB | 26.9% | REGRESS |
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
| multi-day-application-logs-top25-consolidate | MEMORY/log_messages | 3.4 MB | 4.1 MB | +675 KB | 19.2% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_users | 40.5 KB | 40.4 KB | -64 B | -0.2% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/message_key_order | 5.7 KB | 5.7 KB | -14 B | -0.2% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/unattributed | 22.9 MB | 25.7 MB | +2.8 MB | 12.3% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_messages | 659452 | 745606 | 86154 | 13.1% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 3178834 | 3337883 | 159049 | 5.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 437484 | 461659 | 24175 | 5.5% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_messages_entries | 1127 | 1079 | -48 | -4.3% | IMPROVE |
| multi-day-application-logs-top25-consolidate | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_messages_population | 1127 | 1079 | -48 | -4.3% | IMPROVE |
| multi-day-application-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | 40 | 40 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 350 | 150 | 75.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/detect/scan_sub_compile | 6 ms | 11 ms | +5 ms | 83.3% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/parse/read_files | 7.9 s | 5.6 s | -2.2 s | -28.2% | IMPROVE |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics | 173 ms | 174 ms | +1 ms | 0.6% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 171 ms | 171 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/render/normalize_data | 2 ms | 5 ms | +3 ms | 150.0% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/total | 8 s | 5.8 s | -2.2 s | -27.3% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 107.2 MB | 110.2 MB | +2.9 MB | 2.7% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +448 KB | 41.2% | REGRESS |
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
| multi-day-application-logs-heatmap | MEMORY/log_messages | 48.9 MB | 48.9 MB | +1.5 KB | 0.0% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_users | 40.5 KB | 40.6 KB | +192 B | 0.5% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/unattributed | 57.1 MB | 59.6 MB | +2.5 MB | 4.3% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY_FINAL/log_messages | 51302480 | 51304048 | 1568 | 0.0% | REGRESS |
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
| multi-day-application-logs-histogram | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| multi-day-application-logs-histogram | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| multi-day-application-logs-histogram | TIMING/parse/read_files | 7.8 s | 5.7 s | -2 s | -26.2% | IMPROVE |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics | 176 ms | 177 ms | +1 ms | 0.6% | REGRESS |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 174 ms | 175 ms | +1 ms | 0.6% | REGRESS |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/render/normalize_data | 2 ms | 5 ms | +3 ms | 150.0% | REGRESS |
| multi-day-application-logs-histogram | TIMING/total | 8.0 s | 5.9 s | -2 s | -25.4% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 107.5 MB | 109.7 MB | +2.2 MB | 2.1% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +416 KB | 36.6% | REGRESS |
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
| multi-day-application-logs-histogram | MEMORY/log_messages | 48.9 MB | 48.9 MB | +1.5 KB | 0.0% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_users | 40.7 KB | 40.3 KB | -384 B | -0.9% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/unattributed | 57.3 MB | 59.1 MB | +1.8 MB | 3.2% | REGRESS |
| multi-day-application-logs-histogram | MEMORY_FINAL/log_messages | 51302480 | 51304048 | 1568 | 0.0% | REGRESS |
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
| multi-day-application-logs-heatmap-histogram | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/parse/read_files | 7.8 s | 5.8 s | -2.0 s | -25.5% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 176 ms | 174 ms | -2 ms | -1.1% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 173 ms | 171 ms | -2 ms | -1.2% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/render/normalize_data | 2 ms | 5 ms | +3 ms | 150.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 8.0 s | 6 s | -2.0 s | -24.7% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 107.5 MB | 109.7 MB | +2.2 MB | 2.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +480 KB | 43.5% | REGRESS |
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
| multi-day-application-logs-heatmap-histogram | MEMORY/log_messages | 48.9 MB | 48.9 MB | +1.5 KB | 0.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_occurrences | 56.7 KB | 56.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_users | 40.9 KB | 40.7 KB | -192 B | -0.5% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/unattributed | 57.3 MB | 59.1 MB | +1.8 MB | 3.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 51302480 | 51304048 | 1568 | 0.0% | REGRESS |
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
| multi-day-application-logs-heatmap-histogram-export | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| multi-day-application-logs-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 6 ms | 11 ms | +5 ms | 83.3% | REGRESS |
| multi-day-application-logs-heatmap-histogram-export | TIMING/parse/read_files | 6.6 s | 5.0 s | -1.6 s | -24.4% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-export | TIMING/render/normalize_data | 2 ms | 5 ms | +3 ms | 150.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-export | TIMING/total | 6.6 s | 5.0 s | -1.6 s | -24.2% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/rss_peak | 39.9 MB | 42.9 MB | +3 MB | 7.6% | REGRESS |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +480 KB | 43.5% | REGRESS |
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
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_users | 40.6 KB | 40.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/unattributed | 38.7 MB | 41.2 MB | +2.6 MB | 6.6% | REGRESS |
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
| multi-day-application-logs-heatmap-histogram-export | CONFIG/max_log_message_length | 200 | 350 | 150 | 75.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-export | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 29.4 s | 27.3 s | -2.1 s | -7.0% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 4.0 s | 2.2 s | -1.7 s | -43.7% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 3 ms | 2 ms | -1 ms | -33.3% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 3 ms | 7 ms | +4 ms | 133.3% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 33.4 s | 29.6 s | -3.8 s | -11.4% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 226.6 MB | 233.4 MB | +6.9 MB | 3.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 3 MB | 3.2 MB | +152 KB | 4.9% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | 127.2 MB | 127.2 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 3.8 MB | 3.8 MB | -200 B | -0.0% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 65.7 MB | 65.7 MB | +1 KB | 0.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 427.2 KB | 450.8 KB | +23.6 KB | 5.5% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +448 KB | 41.2% | REGRESS |
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
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 3.4 MB | 4.1 MB | +675 KB | 19.2% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_users | 40.1 KB | 40.5 KB | +384 B | 0.9% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 2.9 KB | 3 KB | +169 B | 5.8% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/unattributed | 19.7 MB | 25.3 MB | +5.6 MB | 28.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 659452 | 742294 | 82842 | 12.6% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 3182226 | 3337883 | 155657 | 4.9% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 437484 | 461659 | 24175 | 5.5% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 1127 | 1079 | -48 | -4.3% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | 1127 | 1079 | -48 | -4.3% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | 40 | 40 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 350 | 150 | 75.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| multi-day-application-logs-sort-p99 | TIMING/detect/scan_sub_compile | 6 ms | 11 ms | +5 ms | 83.3% | REGRESS |
| multi-day-application-logs-sort-p99 | TIMING/parse/read_files | 7.8 s | 5.8 s | -2.0 s | -25.6% | IMPROVE |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics | 175 ms | 174 ms | -1 ms | -0.6% | IMPROVE |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 172 ms | 171 ms | -1000 us | -0.6% | IMPROVE |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/render/normalize_data | 2 ms | 5 ms | +3 ms | 150.0% | REGRESS |
| multi-day-application-logs-sort-p99 | TIMING/total | 8.0 s | 6.0 s | -2.0 s | -24.8% | IMPROVE |
| multi-day-application-logs-sort-p99 | MEMORY/rss_peak | 107.7 MB | 110.1 MB | +2.5 MB | 2.3% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/format_scan_subs | 1.2 MB | 1.5 MB | +272 KB | 21.2% | REGRESS |
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
| multi-day-application-logs-sort-p99 | MEMORY/log_messages | 48.9 MB | 48.9 MB | +1.5 KB | 0.0% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_occurrences | 56.7 KB | 56.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_users | 40.1 KB | 40.8 KB | +640 B | 1.6% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/unattributed | 57.3 MB | 59.5 MB | +2.2 MB | 3.8% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/log_messages | 51302480 | 51304048 | 1568 | 0.0% | REGRESS |
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
| multi-day-application-logs-sort-skewness | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| multi-day-application-logs-sort-skewness | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| multi-day-application-logs-sort-skewness | TIMING/parse/read_files | 7.7 s | 5.8 s | -1.9 s | -25.2% | IMPROVE |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics | 174 ms | 172 ms | -2 ms | -1.1% | IMPROVE |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 171 ms | 169 ms | -2 ms | -1.2% | IMPROVE |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/render/normalize_data | 2 ms | 5 ms | +3 ms | 150.0% | REGRESS |
| multi-day-application-logs-sort-skewness | TIMING/total | 7.9 s | 6.0 s | -1.9 s | -24.5% | IMPROVE |
| multi-day-application-logs-sort-skewness | MEMORY/rss_peak | 107.8 MB | 110.2 MB | +2.5 MB | 2.3% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/format_scan_subs | 1.2 MB | 1.5 MB | +336 KB | 26.9% | REGRESS |
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
| multi-day-application-logs-sort-skewness | MEMORY/log_messages | 48.9 MB | 48.9 MB | +1.5 KB | 0.0% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_users | 40.5 KB | 40.7 KB | +192 B | 0.5% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/unattributed | 57.5 MB | 59.6 MB | +2.2 MB | 3.7% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/log_messages | 51302480 | 51304048 | 1568 | 0.0% | REGRESS |
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
| multi-day-custom-logs-standard | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| multi-day-custom-logs-standard | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| multi-day-custom-logs-standard | TIMING/parse/read_files | 16.2 s | 11.2 s | -4.9 s | -30.5% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics | 350 ms | 338 ms | -12 ms | -3.4% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/bucket_stats | 38 ms | 30 ms | -8 ms | -21.1% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 303 ms | 299 ms | -4 ms | -1.3% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/group_calc | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/untimed | 7 ms | 7 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/render/normalize_data | 1 ms | 3 ms | +2 ms | 200.0% | REGRESS |
| multi-day-custom-logs-standard | TIMING/total | 16.5 s | 11.6 s | -4.9 s | -29.8% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 177.4 MB | 180.5 MB | +3.1 MB | 1.8% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/format_scan_subs | 1.2 MB | 1.6 MB | +368 KB | 29.9% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_analysis | 12.9 MB | 12.9 MB | +1 KB | 0.0% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/log_messages | 89.9 MB | 88.8 MB | -1.1 MB | -1.2% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_stats | 50.3 KB | 46.8 KB | -3.6 KB | -7.1% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_users | 12.7 KB | 12.7 KB | +64 B | 0.5% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/unattributed | 73.3 MB | 77.1 MB | +3.8 MB | 5.2% | REGRESS |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_messages | 94222438 | 93084545 | -1137893 | -1.2% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_analysis | 20350 | 19871 | -479 | -2.4% | IMPROVE |
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
| multi-day-custom-logs-no-messages | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| multi-day-custom-logs-no-messages | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| multi-day-custom-logs-no-messages | TIMING/parse/read_files | 13.1 s | 9.4 s | -3.7 s | -28.0% | IMPROVE |
| multi-day-custom-logs-no-messages | TIMING/finalize/calculate_statistics | 33 ms | 25 ms | -8 ms | -24.2% | IMPROVE |
| multi-day-custom-logs-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | 33 ms | 25 ms | -8 ms | -24.2% | IMPROVE |
| multi-day-custom-logs-no-messages | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| multi-day-custom-logs-no-messages | TIMING/total | 13.2 s | 9.5 s | -3.7 s | -27.9% | IMPROVE |
| multi-day-custom-logs-no-messages | MEMORY/rss_peak | 54.5 MB | 56.9 MB | +2.3 MB | 4.3% | REGRESS |
| multi-day-custom-logs-no-messages | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +400 KB | 35.7% | REGRESS |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/log_analysis | 12.9 MB | 12.9 MB | +2 KB | 0.0% | REGRESS |
| multi-day-custom-logs-no-messages | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/log_stats | 50.3 KB | 46.5 KB | -3.8 KB | -7.6% | IMPROVE |
| multi-day-custom-logs-no-messages | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/log_users | 12.7 KB | 12.7 KB | +64 B | 0.5% | REGRESS |
| multi-day-custom-logs-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/unattributed | 40.5 MB | 42.4 MB | +2.0 MB | 4.8% | REGRESS |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/log_analysis | 20350 | 20895 | 545 | 2.7% | REGRESS |
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
| multi-day-custom-logs-top25 | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/parse/read_files | 16.1 s | 11.2 s | -4.9 s | -30.5% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics | 353 ms | 340 ms | -13 ms | -3.7% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 39 ms | 30 ms | -9 ms | -23.1% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 303 ms | 299 ms | -4 ms | -1.3% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/group_calc | 5 ms | 3 ms | -2 ms | -40.0% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 7 ms | 7 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/render/normalize_data | 1 ms | 3 ms | +2 ms | 200.0% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/total | 16.5 s | 11.5 s | -4.9 s | -29.9% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 175.8 MB | 179.9 MB | +4.1 MB | 2.3% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +416 KB | 36.1% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_analysis | 12.9 MB | 12.9 MB | +2.3 KB | 0.0% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/log_messages | 89.9 MB | 88.8 MB | -1.1 MB | -1.3% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_stats | 50.3 KB | 46.8 KB | -3.6 KB | -7.1% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_users | 12.7 KB | 12.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/unattributed | 71.7 MB | 76.6 MB | +4.8 MB | 6.7% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_messages | 94287062 | 93093905 | -1193157 | -1.3% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_analysis | 20350 | 21151 | 801 | 3.9% | REGRESS |
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
| multi-day-custom-logs-top25-consolidate | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 11 ms | +5 ms | 83.3% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/parse/read_files | 33.9 s | 29.6 s | -4.4 s | -12.9% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/group_similar | 5 s | 4.1 s | -896 ms | -17.9% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 160 ms | 93 ms | -67 ms | -41.9% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 68 ms | 50 ms | -18 ms | -26.5% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 91 ms | 43 ms | -48 ms | -52.7% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/render/normalize_data | 2 ms | 4 ms | +2 ms | 100.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 39.1 s | 33.8 s | -5.3 s | -13.6% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 227.2 MB | 233.4 MB | +6.2 MB | 2.8% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_clusters | 14.1 MB | 14.1 MB | +33.5 KB | 0.2% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_id_index | 122.9 MB | 122.9 MB | -2 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_message | 5.8 MB | 5.8 MB | -1.1 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 62.7 MB | 62.7 MB | -2 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_patterns | 193.0 KB | 194.8 KB | +1.8 KB | 1.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_unmatched | 3.3 MB | 3.3 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +416 KB | 37.1% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_analysis | 12.9 MB | 12.9 MB | +1 KB | 0.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages | 13.2 MB | 13.2 MB | +32.4 KB | 0.2% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_stats | 50.3 KB | 46.8 KB | -3.6 KB | -7.1% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_users | 12.7 KB | 12.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/message_key_order | 6.1 KB | 6.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_messages | 13812364 | 13845544 | 33180 | 0.2% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 20350 | 19871 | -479 | -2.4% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 14753524 | 1526621 | -13226903 | -89.7% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 197600 | 199492 | 1892 | 1.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_messages_entries | 363 | 366 | 3 | 0.8% | REGRESS |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_analysis_entries | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_messages_population | 363 | 366 | 3 | 0.8% | REGRESS |
| multi-day-custom-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | 4 | 4 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 350 | 150 | 75.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/detect/scan_sub_compile | 7 ms | 10 ms | +3 ms | 42.9% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/parse/read_files | 16.9 s | 11.7 s | -5.2 s | -30.7% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics | 313 ms | 304 ms | -9 ms | -2.9% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 305 ms | 297 ms | -8 ms | -2.6% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/group_calc | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/finalize/heatmap_statistics | 49 ms | 50 ms | +1 ms | 2.0% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/render/normalize_data | 1 ms | 3 ms | +2 ms | 200.0% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/total | 17.3 s | 12.1 s | -5.2 s | -30.0% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 172.6 MB | 176.7 MB | +4.1 MB | 2.4% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/bucket_outcomes | 6.3 KB | 6.1 KB | -256 B | -4.0% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +480 KB | 44.1% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters | 987.2 KB | 987 KB | -256 B | -0.0% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data | 43.7 KB | 43.4 KB | -256 B | -0.6% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_analysis | 20.9 KB | 21.7 KB | +801 B | 3.7% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_messages | 89.9 MB | 88.8 MB | -1.1 MB | -1.2% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_occurrences | 20.3 KB | 20 KB | -256 B | -1.2% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_stats | 35.5 KB | 31.9 KB | -3.6 KB | -10.0% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_users | 12.7 KB | 12.5 KB | -192 B | -1.5% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/unattributed | 80.6 MB | 85.3 MB | +4.7 MB | 5.9% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_messages | 94222438 | 93084545 | -1137893 | -1.2% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_analysis | 20350 | 19615 | -735 | -3.6% | IMPROVE |
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
| multi-day-custom-logs-histogram | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/parse/read_files | 16.8 s | 12 s | -4.8 s | -28.5% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics | 358 ms | 337 ms | -21 ms | -5.9% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 38 ms | 29 ms | -9 ms | -23.7% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 310 ms | 299 ms | -11 ms | -3.5% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/group_calc | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 7 ms | 7 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/finalize/histogram_statistics | 14 ms | 14 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/render/normalize_data | 1 ms | 3 ms | +2 ms | 200.0% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/total | 17.2 s | 12.4 s | -4.8 s | -27.9% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 177.4 MB | 179.6 MB | +2.2 MB | 1.2% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/format_scan_subs | 1.2 MB | 1.6 MB | +400 KB | 32.9% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/histogram_counters | 122.5 KB | 122.6 KB | +192 B | 0.2% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_analysis | 12.9 MB | 12.9 MB | +2.5 KB | 0.0% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/log_messages | 89.9 MB | 88.8 MB | -1.1 MB | -1.2% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_stats | 50.3 KB | 46.8 KB | -3.6 KB | -7.1% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_users | 12.7 KB | 12.7 KB | +64 B | 0.5% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/unattributed | 73.3 MB | 76.1 MB | +2.9 MB | 3.9% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY_FINAL/log_messages | 94222438 | 93084545 | -1137893 | -1.2% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY_FINAL/log_analysis | 20094 | 21151 | 1057 | 5.3% | REGRESS |
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
| multi-day-custom-logs-heatmap-histogram | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/parse/read_files | 17.2 s | 12.5 s | -4.7 s | -27.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 312 ms | 304 ms | -8 ms | -2.6% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 304 ms | 296 ms | -8 ms | -2.6% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/heatmap_statistics | 50 ms | 49 ms | -1 ms | -2.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/histogram_statistics | 14 ms | 14 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 3 ms | +2 ms | 200.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 17.6 s | 12.9 s | -4.7 s | -26.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 173 MB | 177.0 MB | +3.9 MB | 2.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +384 KB | 32.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_counters | 985.8 KB | 985.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data | 40.1 KB | 40.2 KB | +128 B | 0.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters | 122.5 KB | 122.5 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_analysis | 20.9 KB | 22.0 KB | +1 KB | 4.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages | 89.5 MB | 88.8 MB | -752.2 KB | -0.8% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_stats | 35.5 KB | 31.9 KB | -3.6 KB | -10.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_users | 12.7 KB | 12.7 KB | +64 B | 0.5% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/unattributed | 81.2 MB | 85.4 MB | +4.3 MB | 5.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 93854758 | 93084545 | -770213 | -0.8% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 20350 | 19871 | -479 | -2.4% | IMPROVE |
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
| multi-day-custom-logs-heatmap-histogram-export | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 6 ms | 11 ms | +5 ms | 83.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/parse/read_files | 14.4 s | 11.0 s | -3.4 s | -23.7% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics | 97 ms | 89 ms | -8 ms | -8.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | 96 ms | 89 ms | -7 ms | -7.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | 154 ms | 155 ms | +1 ms | 0.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/histogram_statistics | 14 ms | 14 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/render/normalize_data | 1 ms | 3 ms | +2 ms | 200.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/total | 14.6 s | 11.2 s | -3.4 s | -23.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/rss_peak | 57.9 MB | 58.3 MB | +416 KB | 0.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/format_scan_subs | 1.1 MB | 1.6 MB | +496 KB | 44.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_counters | 985.8 KB | 987.2 KB | +1.5 KB | 0.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_data | 43.4 KB | 43.1 KB | -384 B | -0.9% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/histogram_counters | 122.5 KB | 122.6 KB | +192 B | 0.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_analysis | 12.9 MB | 12.9 MB | +526 B | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_stats | 70.0 KB | 65.8 KB | -4.2 KB | -6.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_users | 12.7 KB | 12.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/unattributed | 42.7 MB | 42.6 MB | -77.6 KB | -0.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/log_analysis | 24647 | 22997 | -1650 | -6.7% | IMPROVE |
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
| multi-day-custom-logs-heatmap-histogram-export | CONFIG/max_log_message_length | 200 | 350 | 150 | 75.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 34.9 s | 30.5 s | -4.4 s | -12.7% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 4.6 s | 4 s | -583 ms | -12.7% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 66 ms | 36 ms | -30 ms | -45.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 0 us | -1 ms | -100.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 65 ms | 35 ms | -30 ms | -46.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 52 ms | 51 ms | -1 ms | -1.9% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 15 ms | 15 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 2 ms | 4 ms | +2 ms | 100.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 39.7 s | 34.6 s | -5.1 s | -12.7% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 225.8 MB | 230.8 MB | +5.0 MB | 2.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 14.1 MB | 14.1 MB | +40.9 KB | 0.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | 122.9 MB | 122.9 MB | +1 KB | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 5.8 MB | 5.8 MB | -1.1 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 62.7 MB | 62.7 MB | +1 KB | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 193.0 KB | 194.8 KB | +1.8 KB | 1.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 3.3 MB | 3.3 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +432 KB | 38.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 987.2 KB | 987.2 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 43.1 KB | 42.5 KB | -576 B | -1.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 122.6 KB | 122.6 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 20.9 KB | 22.0 KB | +1 KB | 4.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 13.2 MB | 13.2 MB | +31 KB | 0.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 35.5 KB | 31.9 KB | -3.6 KB | -10.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_users | 12.7 KB | 12.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 2.6 KB | 2.6 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/unattributed | 1.4 MB | 5.9 MB | +4.5 MB | 329.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 13809580 | 13841336 | 31756 | 0.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 20350 | 19871 | -479 | -2.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 14753524 | 1534173 | -13219351 | -89.6% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 197600 | 199492 | 1892 | 1.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 363 | 366 | 3 | 0.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | 363 | 366 | 3 | 0.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | 4 | 4 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 350 | 150 | 75.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| multi-day-custom-logs-sort-p99 | TIMING/detect/scan_sub_compile | 6 ms | 11 ms | +5 ms | 83.3% | REGRESS |
| multi-day-custom-logs-sort-p99 | TIMING/parse/read_files | 16.1 s | 11.2 s | -4.9 s | -30.3% | IMPROVE |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics | 234 ms | 220 ms | -14 ms | -6.0% | IMPROVE |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 39 ms | 30 ms | -9 ms | -23.1% | IMPROVE |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 185 ms | 179 ms | -6 ms | -3.2% | IMPROVE |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 8 ms | 8 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/render/normalize_data | 1 ms | 3 ms | +2 ms | 200.0% | REGRESS |
| multi-day-custom-logs-sort-p99 | TIMING/total | 16.3 s | 11.4 s | -4.9 s | -29.9% | IMPROVE |
| multi-day-custom-logs-sort-p99 | MEMORY/rss_peak | 174.5 MB | 177.8 MB | +3.3 MB | 1.9% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/format_scan_subs | 1.2 MB | 1.5 MB | +368 KB | 30.3% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_analysis | 12.9 MB | 12.9 MB | +2.3 KB | 0.0% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY/log_messages | 89.9 MB | 88.8 MB | -1.1 MB | -1.3% | IMPROVE |
| multi-day-custom-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_stats | 50.3 KB | 43.3 KB | -7.1 KB | -14.0% | IMPROVE |
| multi-day-custom-logs-sort-p99 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_users | 12.7 KB | 12.7 KB | +64 B | 0.5% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY/message_key_order | 2.7 KB | 2.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/unattributed | 70.4 MB | 74.5 MB | +4.1 MB | 5.8% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/log_messages | 94279670 | 93085025 | -1194645 | -1.3% | IMPROVE |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/log_analysis | 20350 | 21151 | 801 | 3.9% | REGRESS |
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
| multi-day-custom-logs-sort-skewness | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| multi-day-custom-logs-sort-skewness | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| multi-day-custom-logs-sort-skewness | TIMING/parse/read_files | 16 s | 11.2 s | -4.8 s | -29.8% | IMPROVE |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics | 306 ms | 292 ms | -14 ms | -4.6% | IMPROVE |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 40 ms | 30 ms | -10 ms | -25.0% | IMPROVE |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 251 ms | 248 ms | -3 ms | -1.2% | IMPROVE |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 5 ms | 4 ms | -1 ms | -20.0% | IMPROVE |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 8 ms | 8 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/render/normalize_data | 1 ms | 3 ms | +2 ms | 200.0% | REGRESS |
| multi-day-custom-logs-sort-skewness | TIMING/total | 16.3 s | 11.6 s | -4.8 s | -29.2% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY/rss_peak | 172.6 MB | 176.8 MB | +4.2 MB | 2.4% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/format_scan_subs | 1.1 MB | 1.6 MB | +432 KB | 37.0% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_analysis | 12.9 MB | 12.9 MB | +2.3 KB | 0.0% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY/log_messages | 89.4 MB | 88.8 MB | -627.6 KB | -0.7% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_stats | 50.3 KB | 46.8 KB | -3.6 KB | -7.1% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_users | 12.7 KB | 12.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/message_key_order | 2.5 KB | 2.5 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/unattributed | 69.1 MB | 73.5 MB | +4.3 MB | 6.3% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/log_messages | 93729243 | 93086598 | -642645 | -0.7% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/log_analysis | 20350 | 21151 | 801 | 3.9% | REGRESS |
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
| single-day-access-log-standard | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| single-day-access-log-standard | TIMING/detect/scan_sub_compile | 6 ms | 11 ms | +5 ms | 83.3% | REGRESS |
| single-day-access-log-standard | TIMING/parse/read_files | 8.6 s | 4.8 s | -3.8 s | -44.3% | IMPROVE |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics | 98 ms | 73 ms | -25 ms | -25.5% | IMPROVE |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/bucket_stats | 69 ms | 51 ms | -18 ms | -26.1% | IMPROVE |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 5 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/group_calc | 23 ms | 18 ms | -5 ms | -21.7% | IMPROVE |
| single-day-access-log-standard | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-access-log-standard | TIMING/total | 8.7 s | 4.9 s | -3.8 s | -43.9% | IMPROVE |
| single-day-access-log-standard | MEMORY/rss_peak | 99.8 MB | 100.2 MB | +400 KB | 0.4% | REGRESS |
| single-day-access-log-standard | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +368 KB | 32.9% | REGRESS |
| single-day-access-log-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_analysis | 23.6 MB | 23.6 MB | +1.5 KB | 0.0% | REGRESS |
| single-day-access-log-standard | MEMORY/log_messages | 26.9 MB | 26.4 MB | -478 KB | -1.7% | IMPROVE |
| single-day-access-log-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_stats | 27.6 KB | 27.6 KB | +8 B | 0.0% | REGRESS |
| single-day-access-log-standard | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/message_key_order | 1.8 KB | 1.8 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/unattributed | 48.2 MB | 48.7 MB | +508.5 KB | 1.0% | REGRESS |
| single-day-access-log-standard | MEMORY_FINAL/log_messages | 28173442 | 27683929 | -489513 | -1.7% | IMPROVE |
| single-day-access-log-standard | MEMORY_FINAL/log_analysis | 6678 | 8215 | 1537 | 23.0% | REGRESS |
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
| single-day-access-log-no-messages | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| single-day-access-log-no-messages | TIMING/detect/scan_sub_compile | 6 ms | 11 ms | +5 ms | 83.3% | REGRESS |
| single-day-access-log-no-messages | TIMING/parse/read_files | 6.6 s | 4 s | -2.5 s | -38.6% | IMPROVE |
| single-day-access-log-no-messages | TIMING/finalize/calculate_statistics | 65 ms | 48 ms | -17 ms | -26.2% | IMPROVE |
| single-day-access-log-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | 65 ms | 48 ms | -17 ms | -26.2% | IMPROVE |
| single-day-access-log-no-messages | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-access-log-no-messages | TIMING/total | 6.7 s | 4.1 s | -2.5 s | -38.3% | IMPROVE |
| single-day-access-log-no-messages | MEMORY/rss_peak | 65 MB | 68.5 MB | +3.5 MB | 5.4% | REGRESS |
| single-day-access-log-no-messages | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +384 KB | 33.3% | REGRESS |
| single-day-access-log-no-messages | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/log_analysis | 23.6 MB | 23.6 MB | +2.4 KB | 0.0% | REGRESS |
| single-day-access-log-no-messages | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/log_stats | 27.6 KB | 27.6 KB | +8 B | 0.0% | REGRESS |
| single-day-access-log-no-messages | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/unattributed | 40.2 MB | 43.3 MB | +3.1 MB | 7.8% | REGRESS |
| single-day-access-log-no-messages | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| single-day-access-log-no-messages | MEMORY_FINAL/log_analysis | 6678 | 9175 | 2497 | 37.4% | REGRESS |
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
| single-day-access-log-top25 | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| single-day-access-log-top25 | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| single-day-access-log-top25 | TIMING/parse/read_files | 8.6 s | 4.9 s | -3.7 s | -43.1% | IMPROVE |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics | 104 ms | 79 ms | -25 ms | -24.0% | IMPROVE |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 69 ms | 51 ms | -18 ms | -26.1% | IMPROVE |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 5 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/group_calc | 30 ms | 23 ms | -7 ms | -23.3% | IMPROVE |
| single-day-access-log-top25 | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-access-log-top25 | TIMING/total | 8.7 s | 5.0 s | -3.7 s | -42.7% | IMPROVE |
| single-day-access-log-top25 | MEMORY/rss_peak | 99.8 MB | 99.5 MB | -368 KB | -0.4% | IMPROVE |
| single-day-access-log-top25 | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +416 KB | 37.1% | REGRESS |
| single-day-access-log-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_analysis | 23.6 MB | 23.6 MB | +1.5 KB | 0.0% | REGRESS |
| single-day-access-log-top25 | MEMORY/log_messages | 26.9 MB | 26.2 MB | -681.6 KB | -2.5% | IMPROVE |
| single-day-access-log-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_stats | 27.6 KB | 27.6 KB | +8 B | 0.0% | REGRESS |
| single-day-access-log-top25 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/message_key_order | 3.9 KB | 3.9 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/unattributed | 48.2 MB | 48.1 MB | -103.9 KB | -0.2% | IMPROVE |
| single-day-access-log-top25 | MEMORY_FINAL/log_messages | 28188642 | 27490665 | -697977 | -2.5% | IMPROVE |
| single-day-access-log-top25 | MEMORY_FINAL/log_analysis | 6678 | 8215 | 1537 | 23.0% | REGRESS |
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
| single-day-access-log-top25-consolidate | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/parse/read_files | 9.6 s | 5.8 s | -3.7 s | -39.1% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/finalize/group_similar | 2.3 s | 558 ms | -1.7 s | -75.5% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics | 145 ms | 89 ms | -56 ms | -38.6% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 79 ms | 51 ms | -28 ms | -35.4% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 64 ms | 37 ms | -27 ms | -42.2% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/render/normalize_data | 1 ms | 3 ms | +2 ms | 200.0% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/total | 12 s | 6.5 s | -5.5 s | -45.9% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 131.0 MB | 130.0 MB | -1 MB | -0.8% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_clusters | 22 MB | 16.4 MB | -5.7 MB | -25.7% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_id_index | 8.5 MB | 9.3 MB | +885.2 KB | 10.2% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_message | 888 KB | 888.1 KB | +32 B | 0.0% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_trigrams | 4.1 MB | 4.6 MB | +446.1 KB | 10.5% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_patterns | 119.4 KB | 129.4 KB | +9.9 KB | 8.3% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_unmatched | 565.2 KB | 565.2 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +432 KB | 39.1% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_analysis | 23.6 MB | 23.6 MB | +1.5 KB | 0.0% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/log_messages | 26.9 MB | 26.7 MB | -137.3 KB | -0.5% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_stats | 27.6 KB | 27.6 KB | +8 B | 0.0% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/message_key_order | 3.8 KB | 3.9 KB | +70 B | 1.8% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/unattributed | 43.2 MB | 46.2 MB | +3.1 MB | 7.1% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_messages | 25749074 | 25857887 | 108813 | 0.4% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_analysis | 6678 | 8215 | 1537 | 23.0% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 23087425 | 608854 | -22478571 | -97.4% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 122293 | 132461 | 10168 | 8.3% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 304 | 304 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 16440 | 16440 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_messages_entries | 656 | 747 | 91 | 13.9% | REGRESS |
| single-day-access-log-top25-consolidate | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_analysis_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_messages_population | 656 | 747 | 91 | 13.9% | REGRESS |
| single-day-access-log-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/max_log_message_length | 200 | 350 | 150 | 75.0% | REGRESS |
| single-day-access-log-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| single-day-access-log-heatmap | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| single-day-access-log-heatmap | TIMING/parse/read_files | 9.4 s | 5.6 s | -3.7 s | -39.9% | IMPROVE |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics | 28 ms | 22 ms | -6 ms | -21.4% | IMPROVE |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 5 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics/group_calc | 23 ms | 17 ms | -6 ms | -26.1% | IMPROVE |
| single-day-access-log-heatmap | TIMING/finalize/heatmap_statistics | 30 ms | 30 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-access-log-heatmap | TIMING/total | 9.5 s | 5.7 s | -3.7 s | -39.5% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/rss_peak | 83.6 MB | 81.6 MB | -2 MB | -2.4% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +400 KB | 35.2% | REGRESS |
| single-day-access-log-heatmap | MEMORY/heatmap_counters | 572.2 KB | 570.3 KB | -1.9 KB | -0.3% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_analysis | 8.1 KB | 10.5 KB | +2.4 KB | 30.2% | REGRESS |
| single-day-access-log-heatmap | MEMORY/log_messages | 26.9 MB | 26.4 MB | -484.9 KB | -1.8% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_stats | 18.2 KB | 18.2 KB | +8 B | 0.0% | REGRESS |
| single-day-access-log-heatmap | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/message_key_order | 1.8 KB | 1.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/unattributed | 55.0 MB | 53 MB | -1.9 MB | -3.5% | IMPROVE |
| single-day-access-log-heatmap | MEMORY_FINAL/log_messages | 28180482 | 27683929 | -496553 | -1.8% | IMPROVE |
| single-day-access-log-heatmap | MEMORY_FINAL/log_analysis | 6678 | 9175 | 2497 | 37.4% | REGRESS |
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
| single-day-access-log-histogram | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| single-day-access-log-histogram | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| single-day-access-log-histogram | TIMING/parse/read_files | 10.6 s | 6.9 s | -3.7 s | -35.0% | IMPROVE |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics | 98 ms | 74 ms | -24 ms | -24.5% | IMPROVE |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 69 ms | 51 ms | -18 ms | -26.1% | IMPROVE |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 5 ms | -1 ms | -16.7% | IMPROVE |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/group_calc | 23 ms | 18 ms | -5 ms | -21.7% | IMPROVE |
| single-day-access-log-histogram | TIMING/finalize/histogram_statistics | 11 ms | 11 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-access-log-histogram | TIMING/total | 10.7 s | 7.0 s | -3.7 s | -34.7% | IMPROVE |
| single-day-access-log-histogram | MEMORY/rss_peak | 99.6 MB | 100 MB | +448 KB | 0.4% | REGRESS |
| single-day-access-log-histogram | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +400 KB | 34.2% | REGRESS |
| single-day-access-log-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/histogram_counters | 105.9 KB | 106 KB | +128 B | 0.1% | REGRESS |
| single-day-access-log-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_analysis | 23.6 MB | 23.6 MB | +2.4 KB | 0.0% | REGRESS |
| single-day-access-log-histogram | MEMORY/log_messages | 26.7 MB | 26.2 MB | -484.9 KB | -1.8% | IMPROVE |
| single-day-access-log-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_stats | 27.6 KB | 27.6 KB | +8 B | 0.0% | REGRESS |
| single-day-access-log-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/message_key_order | 1.8 KB | 1.8 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/unattributed | 47.9 MB | 48.5 MB | +530.3 KB | 1.1% | REGRESS |
| single-day-access-log-histogram | MEMORY_FINAL/log_messages | 27977346 | 27480793 | -496553 | -1.8% | IMPROVE |
| single-day-access-log-histogram | MEMORY_FINAL/log_analysis | 6678 | 9175 | 2497 | 37.4% | REGRESS |
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
| single-day-access-log-heatmap-histogram | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/parse/read_files | 11.1 s | 7.5 s | -3.6 s | -32.6% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics | 28 ms | 24 ms | -4 ms | -14.3% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 5 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 23 ms | 18 ms | -5 ms | -21.7% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/finalize/heatmap_statistics | 30 ms | 31 ms | +1 ms | 3.3% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/finalize/histogram_statistics | 11 ms | 11 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 3 ms | +2 ms | 200.0% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/total | 11.2 s | 7.6 s | -3.6 s | -32.3% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 83.8 MB | 80.8 MB | -3 MB | -3.6% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +432 KB | 37.5% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_counters | 571.2 KB | 571.2 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_counters | 105.9 KB | 105.9 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_analysis | 8.1 KB | 10.5 KB | +2.4 KB | 30.2% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/log_messages | 26.9 MB | 26.2 MB | -683.3 KB | -2.5% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_stats | 18.2 KB | 18.2 KB | +8 B | 0.0% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/message_key_order | 1.8 KB | 1.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/unattributed | 55 MB | 52.2 MB | -2.8 MB | -5.1% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_messages | 28180482 | 27480793 | -699689 | -2.5% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_analysis | 6678 | 9175 | 2497 | 37.4% | REGRESS |
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
| single-day-access-log-heatmap-histogram-export | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| single-day-access-log-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 6 ms | 11 ms | +5 ms | 83.3% | REGRESS |
| single-day-access-log-heatmap-histogram-export | TIMING/parse/read_files | 9.5 s | 6.8 s | -2.7 s | -28.7% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics | 183 ms | 169 ms | -14 ms | -7.7% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | 183 ms | 169 ms | -14 ms | -7.7% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | 98 ms | 98 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/histogram_statistics | 11 ms | 11 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | TIMING/render/normalize_data | 1 ms | 3 ms | +2 ms | 200.0% | REGRESS |
| single-day-access-log-heatmap-histogram-export | TIMING/total | 9.8 s | 7.1 s | -2.7 s | -27.8% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | MEMORY/rss_peak | 69 MB | 69.2 MB | +176 KB | 0.2% | REGRESS |
| single-day-access-log-heatmap-histogram-export | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/format_scan_subs | 1.2 MB | 1.6 MB | +416 KB | 33.8% | REGRESS |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_counters | 572.2 KB | 572.2 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/histogram_counters | 106 KB | 106 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_analysis | 23.6 MB | 23.6 MB | +766 B | 0.0% | REGRESS |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_stats | 41.3 KB | 40.3 KB | -952 B | -2.3% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/unattributed | 43.4 MB | 43.2 MB | -239.8 KB | -0.5% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/log_analysis | 12095 | 11901 | -194 | -1.6% | IMPROVE |
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
| single-day-access-log-heatmap-histogram-export | CONFIG/max_log_message_length | 200 | 350 | 150 | 75.0% | REGRESS |
| single-day-access-log-heatmap-histogram-export | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 11 ms | +5 ms | 83.3% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/parse/read_files | 12.0 s | 8.3 s | -3.7 s | -30.7% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 1.7 s | 517 ms | -1.2 s | -69.9% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 74 ms | 47 ms | -27 ms | -36.5% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 73 ms | 46 ms | -27 ms | -37.0% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 30 ms | 30 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 11 ms | 11 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/render/normalize_data | 1 ms | 3 ms | +2 ms | 200.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 13.8 s | 8.9 s | -4.9 s | -35.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 113.2 MB | 106.2 MB | -7.0 MB | -6.1% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 22 MB | 16.4 MB | -5.7 MB | -25.7% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | 8.5 MB | 9.3 MB | +893.2 KB | 10.3% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 888 KB | 888.1 KB | +32 B | 0.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 4.1 MB | 4.6 MB | +454.1 KB | 10.7% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 119.4 KB | 129.4 KB | +9.9 KB | 8.3% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 565.2 KB | 565.2 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +416 KB | 37.1% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 570.3 KB | 571.2 KB | +960 B | 0.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_counters | 105.8 KB | 105.9 KB | +128 B | 0.1% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 8.1 KB | 10.5 KB | +2.4 KB | 30.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_messages | 26.9 MB | 26.7 MB | -137.3 KB | -0.5% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_stats | 18.2 KB | 18.2 KB | +8 B | 0.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/message_key_order | 1.9 KB | 1.8 KB | -54 B | -2.8% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/unattributed | 48.3 MB | 45.4 MB | -2.9 MB | -6.0% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 25740914 | 25848975 | 108061 | 0.4% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 6678 | 9175 | 2497 | 37.4% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 23087425 | 608854 | -22478571 | -97.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 122293 | 132461 | 10168 | 8.3% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 304 | 304 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 16440 | 16440 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 656 | 747 | 91 | 13.9% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_messages_population | 656 | 747 | 91 | 13.9% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 350 | 150 | 75.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| single-day-access-log-sort-p99 | TIMING/detect/scan_sub_compile | 6 ms | 11 ms | +5 ms | 83.3% | REGRESS |
| single-day-access-log-sort-p99 | TIMING/parse/read_files | 8.6 s | 4.8 s | -3.8 s | -44.0% | IMPROVE |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics | 130 ms | 103 ms | -27 ms | -20.8% | IMPROVE |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 68 ms | 51 ms | -17 ms | -25.0% | IMPROVE |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 60 ms | 51 ms | -9 ms | -15.0% | IMPROVE |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-access-log-sort-p99 | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-access-log-sort-p99 | TIMING/total | 8.8 s | 5.0 s | -3.8 s | -43.4% | IMPROVE |
| single-day-access-log-sort-p99 | MEMORY/rss_peak | 98.7 MB | 99.4 MB | +736 KB | 0.7% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY/bucket_outcomes | 3.6 KB | 3.8 KB | +128 B | 3.4% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/format_scan_subs | 1.1 MB | 1.5 MB | +480 KB | 44.1% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_analysis | 23.6 MB | 23.6 MB | +2.6 KB | 0.0% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY/log_messages | 26.7 MB | 26.2 MB | -484.7 KB | -1.8% | IMPROVE |
| single-day-access-log-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_occurrences | 18.3 KB | 18.4 KB | +128 B | 0.7% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_stats | 27.4 KB | 27.6 KB | +136 B | 0.5% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/message_key_order | 2.0 KB | 2.0 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/unattributed | 47.2 MB | 48.0 MB | +737.8 KB | 1.5% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY_FINAL/log_messages | 27977346 | 27481017 | -496329 | -1.8% | IMPROVE |
| single-day-access-log-sort-p99 | MEMORY_FINAL/log_analysis | 6550 | 9175 | 2625 | 40.1% | REGRESS |
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
| single-day-access-log-sort-skewness | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| single-day-access-log-sort-skewness | TIMING/detect/scan_sub_compile | 6 ms | 10 ms | +4 ms | 66.7% | REGRESS |
| single-day-access-log-sort-skewness | TIMING/parse/read_files | 8.7 s | 4.8 s | -3.9 s | -44.9% | IMPROVE |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics | 251 ms | 226 ms | -25 ms | -10.0% | IMPROVE |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 69 ms | 50 ms | -19 ms | -27.5% | IMPROVE |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 178 ms | 172 ms | -6 ms | -3.4% | IMPROVE |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 4 ms | 3 ms | -1 ms | -25.0% | IMPROVE |
| single-day-access-log-sort-skewness | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-access-log-sort-skewness | TIMING/total | 8.9 s | 5 s | -3.9 s | -43.7% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY/rss_peak | 104.5 MB | 98.9 MB | -5.7 MB | -5.4% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/format_scan_subs | 1.2 MB | 1.5 MB | +240 KB | 19.0% | REGRESS |
| single-day-access-log-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_analysis | 23.6 MB | 23.6 MB | +2.4 KB | 0.0% | REGRESS |
| single-day-access-log-sort-skewness | MEMORY/log_messages | 26.9 MB | 26.2 MB | -683.1 KB | -2.5% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_stats | 27.6 KB | 27.6 KB | +8 B | 0.0% | REGRESS |
| single-day-access-log-sort-skewness | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/message_key_order | 1.9 KB | 1.9 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/unattributed | 52.7 MB | 47.5 MB | -5.2 MB | -9.9% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY_FINAL/log_messages | 28182055 | 27482558 | -699497 | -2.5% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY_FINAL/log_analysis | 6678 | 9175 | 2497 | 37.4% | REGRESS |
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
| month-single-server-access-logs-standard | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| month-single-server-access-logs-standard | TIMING/detect/scan_sub_compile | 13 ms | 21 ms | +8 ms | 61.5% | REGRESS |
| month-single-server-access-logs-standard | TIMING/parse/read_files | 1.6 min | 54.5 s | -40.9 s | -42.9% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics | 4.3 s | 3.5 s | -770 ms | -18.0% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/bucket_stats | 2.3 s | 1.7 s | -593 ms | -26.1% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 1.6 s | 1.4 s | -192 ms | -11.9% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/group_calc | 328 ms | 343 ms | +15 ms | 4.6% | REGRESS |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/untimed | 64 ms | 63 ms | -1 ms | -1.6% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/render/normalize_data | 2 ms | 4 ms | +2 ms | 100.0% | REGRESS |
| month-single-server-access-logs-standard | TIMING/total | 1.7 min | 58 s | -41.7 s | -41.8% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2 GB | 1.8 GB | -189.7 MB | -9.2% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/format_scan_subs | 2 MB | 2.5 MB | +512 KB | 25.0% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_analysis | 244 MB | 244 MB | +4.5 KB | 0.0% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/log_messages | 1.5 GB | 1.3 GB | -166.1 MB | -11.1% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_stats | 54.2 KB | 54.2 KB | +8 B | 0.0% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/unattributed | 311 MB | 286.9 MB | -24.1 MB | -7.8% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_messages | 1567835635 | 1393712442 | -174123193 | -11.1% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_analysis | 13018 | 17595 | 4577 | 35.2% | REGRESS |
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
| month-single-server-access-logs-no-messages | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| month-single-server-access-logs-no-messages | TIMING/detect/scan_sub_compile | 13 ms | 21 ms | +8 ms | 61.5% | REGRESS |
| month-single-server-access-logs-no-messages | TIMING/parse/read_files | 1.2 min | 43.9 s | -27.6 s | -38.6% | IMPROVE |
| month-single-server-access-logs-no-messages | TIMING/finalize/calculate_statistics | 1.5 s | 1.4 s | -184 ms | -11.9% | IMPROVE |
| month-single-server-access-logs-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | 1.5 s | 1.4 s | -184 ms | -11.9% | IMPROVE |
| month-single-server-access-logs-no-messages | TIMING/finalize/calculate_statistics/untimed | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-no-messages | TIMING/render/normalize_data | 2 ms | 4 ms | +2 ms | 100.0% | REGRESS |
| month-single-server-access-logs-no-messages | TIMING/total | 1.2 min | 45.3 s | -27.8 s | -38.0% | IMPROVE |
| month-single-server-access-logs-no-messages | MEMORY/rss_peak | 370.2 MB | 354.8 MB | -15.4 MB | -4.2% | IMPROVE |
| month-single-server-access-logs-no-messages | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/format_scan_subs | 1.9 MB | 2.5 MB | +608 KB | 30.6% | REGRESS |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_analysis | 241.5 MB | 241.6 MB | +4.5 KB | 0.0% | REGRESS |
| month-single-server-access-logs-no-messages | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-no-messages | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_stats | 54.2 KB | 54.2 KB | +8 B | 0.0% | REGRESS |
| month-single-server-access-logs-no-messages | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/unattributed | 124.4 MB | 108.4 MB | -16 MB | -12.9% | IMPROVE |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/log_analysis | 13018 | 17595 | 4577 | 35.2% | REGRESS |
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
| month-single-server-access-logs-top25 | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/detect/scan_sub_compile | 13 ms | 21 ms | +8 ms | 61.5% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/parse/read_files | 1.6 min | 54.1 s | -41.3 s | -43.3% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics | 4.3 s | 3.7 s | -637 ms | -14.7% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 2.2 s | 1.7 s | -531 ms | -23.9% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 1.6 s | 1.4 s | -123 ms | -7.9% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/group_calc | 483 ms | 501 ms | +18 ms | 3.7% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 63 ms | 62 ms | -1 ms | -1.6% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/render/normalize_data | 2 ms | 4 ms | +2 ms | 100.0% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/total | 1.7 min | 57.8 s | -41.9 s | -42.0% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2 GB | 1.7 GB | -264.6 MB | -12.9% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/format_scan_subs | 1.9 MB | 2.5 MB | +560 KB | 28.2% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_analysis | 244 MB | 244 MB | +2.7 KB | 0.0% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/log_messages | 1.5 GB | 1.2 GB | -238.2 MB | -16.0% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_stats | 54.2 KB | 54.2 KB | +8 B | 0.0% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/message_key_order | 4.7 KB | 4.7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/unattributed | 311 MB | 284.1 MB | -27.0 MB | -8.7% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_messages | 1565933395 | 1316140458 | -249792937 | -16.0% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_analysis | 13018 | 15803 | 2785 | 21.4% | REGRESS |
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
| month-single-server-access-logs-top25-consolidate | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/detect/scan_sub_compile | 13 ms | 22 ms | +9 ms | 69.2% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/parse/read_files | 1.9 min | 1.3 min | -36.7 s | -31.6% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/group_similar | 44.8 s | 4.1 s | -40.6 s | -90.7% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 4.7 s | 4.0 s | -696 ms | -14.8% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 2.7 s | 1.9 s | -845 ms | -31.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 2.0 s | 2.1 s | +149 ms | 7.6% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/untimed | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/render/normalize_data | 3 ms | 5 ms | +2 ms | 66.7% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 2.8 min | 1.5 min | -1.3 min | -47.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 801.2 MB | 820.7 MB | +19.5 MB | 2.4% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 211.7 MB | 210.7 MB | -1000.1 KB | -0.5% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_id_index | 49.6 MB | 49.6 MB | -1.5 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 2.1 MB | 2.1 MB | +152 B | 0.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 26.3 MB | 26.3 MB | -1.5 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 259 KB | 226.9 KB | -32.2 KB | -12.4% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 1.4 MB | 1.4 MB | -256 B | -0.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/format_scan_subs | 1.9 MB | 1.8 MB | -64 KB | -3.4% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_analysis | 242.2 MB | 242.2 MB | +2.7 KB | 0.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages | 242.2 MB | 241.9 MB | -302.0 KB | -0.1% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_stats | 54.2 KB | 54.2 KB | +8 B | 0.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/message_key_order | 4.2 KB | 4 KB | -220 B | -5.1% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/unattributed | 21.2 MB | 42.1 MB | +20.9 MB | 98.3% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | 253949787 | 253640565 | -309222 | -0.1% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 13018 | 15803 | 2785 | 21.4% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 222005253 | 888698 | -221116555 | -99.6% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 231512 | 185195 | -46317 | -20.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 432 | 432 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_messages_entries | 1184 | 1057 | -127 | -10.7% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_messages_population | 1184 | 1057 | -127 | -10.7% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | 2 | 2 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 350 | 150 | 75.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/detect/scan_sub_compile | 14 ms | 21 ms | +7 ms | 50.0% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/parse/read_files | 1.8 min | 1.1 min | -41.3 s | -38.8% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics | 1.8 s | 1.8 s | -56 ms | -3.1% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 1.5 s | 1.4 s | -49 ms | -3.4% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/group_calc | 289 ms | 283 ms | -6 ms | -2.1% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 72 ms | 71 ms | -1 ms | -1.4% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/finalize/heatmap_statistics | 104 ms | 102 ms | -2 ms | -1.9% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/render/normalize_data | 2 ms | 4 ms | +2 ms | 100.0% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/total | 1.8 min | 1.1 min | -41.4 s | -38.2% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 1.8 GB | 1.6 GB | -184.8 MB | -10.1% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/format_scan_subs | 1.9 MB | 2.5 MB | +608 KB | 30.9% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data | 77.9 KB | 75.9 KB | -2 KB | -2.6% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_analysis | 15.3 KB | 19.8 KB | +4.5 KB | 29.2% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/log_messages | 1.5 GB | 1.3 GB | -166.1 MB | -11.1% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/log_sessions | 2.2 MB | 2.2 MB | +128 B | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/log_stats | 35.0 KB | 35 KB | +8 B | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/unattributed | 321.6 MB | 302.3 MB | -19.3 MB | -6.0% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_messages | 1567835155 | 1393711962 | -174123193 | -11.1% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_analysis | 12602 | 17179 | 4577 | 36.3% | REGRESS |
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
| month-single-server-access-logs-histogram | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/detect/scan_sub_compile | 13 ms | 21 ms | +8 ms | 61.5% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/parse/read_files | 2.0 min | 1.3 min | -39.7 s | -33.6% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics | 4.1 s | 3.5 s | -645 ms | -15.6% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 2.2 s | 1.7 s | -505 ms | -23.1% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 1.6 s | 1.4 s | -161 ms | -10.2% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/group_calc | 326 ms | 347 ms | +21 ms | 6.4% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 62 ms | 63 ms | +1 ms | 1.6% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/finalize/histogram_statistics | 19 ms | 19 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/render/normalize_data | 2 ms | 4 ms | +2 ms | 100.0% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/total | 2 min | 1.4 min | -40.4 s | -33.0% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 2 GB | 1.8 GB | -188.3 MB | -9.2% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/format_scan_subs | 2 MB | 2.5 MB | +496 KB | 24.0% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/histogram_counters | 295.9 KB | 295.9 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_analysis | 244 MB | 244 MB | +2.7 KB | 0.0% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/log_messages | 1.5 GB | 1.3 GB | -166.1 MB | -11.1% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_occurrences | 36.8 KB | 36.8 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_stats | 54.2 KB | 54.2 KB | +8 B | 0.0% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/unattributed | 311.9 MB | 289.2 MB | -22.7 MB | -7.3% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_messages | 1567835635 | 1393712058 | -174123577 | -11.1% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_analysis | 13018 | 15803 | 2785 | 21.4% | REGRESS |
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
| month-single-server-access-logs-heatmap-histogram | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | 13 ms | 21 ms | +8 ms | 61.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/parse/read_files | 2.1 min | 1.4 min | -41.2 s | -32.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 2.0 s | 1.8 s | -127 ms | -6.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 1.6 s | 1.5 s | -106 ms | -6.7% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 298 ms | 283 ms | -15 ms | -5.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 78 ms | 70 ms | -8 ms | -10.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/heatmap_statistics | 111 ms | 103 ms | -8 ms | -7.2% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/histogram_statistics | 19 ms | 19 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/render/normalize_data | 2 ms | 4 ms | +2 ms | 100.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.2 min | 1.5 min | -41.3 s | -32.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 1.8 GB | 1.5 GB | -262.6 MB | -14.4% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/format_scan_subs | 2.0 MB | 2.6 MB | +592 KB | 29.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data | 74.9 KB | 78.4 KB | +3.5 KB | 4.7% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_counters | 295.9 KB | 295.9 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.3 KB | 19.8 KB | +4.5 KB | 29.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_messages | 1.5 GB | 1.2 GB | -240 MB | -16.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_stats | 35.0 KB | 35 KB | +8 B | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/unattributed | 323.1 MB | 299.9 MB | -23.1 MB | -7.2% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 1567835155 | 1316127258 | -251707897 | -16.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 12602 | 17179 | 4577 | 36.3% | REGRESS |
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
| month-single-server-access-logs-heatmap-histogram-export | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 13 ms | 22 ms | +9 ms | 69.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/parse/read_files | 1.8 min | 1.3 min | -29.6 s | -27.8% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics | 2.7 s | 2.6 s | -106 ms | -3.9% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | 2.7 s | 2.6 s | -105 ms | -3.9% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/untimed | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | 225 ms | 222 ms | -3 ms | -1.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/histogram_statistics | 18 ms | 18 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/render/normalize_data | 1 ms | 4 ms | +3 ms | 300.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/total | 1.8 min | 1.3 min | -29.7 s | -27.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/rss_peak | 371.6 MB | 358.4 MB | -13.2 MB | -3.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/format_scan_subs | 1.9 MB | 2.5 MB | +640 KB | 32.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | +1.8 KB | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_data | 74.6 KB | 77.4 KB | +2.8 KB | 3.7% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/histogram_counters | 295.9 KB | 296 KB | +128 B | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_analysis | 241.6 MB | 241.6 MB | +3.1 KB | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_stats | 82.5 KB | 80.8 KB | -1.7 KB | -2.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/unattributed | 123 MB | 109.2 MB | -13.8 MB | -11.2% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_analysis | 21219 | 22609 | 1390 | 6.6% | REGRESS |
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
| month-single-server-access-logs-heatmap-histogram-export | CONFIG/max_log_message_length | 200 | 350 | 150 | 75.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 13 ms | 22 ms | +9 ms | 69.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 2.4 min | 1.8 min | -35.9 s | -24.7% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 30.6 s | 3.1 s | -27.5 s | -90.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 1.8 s | 2.4 s | +609 ms | 33.4% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 1.8 s | 2.4 s | +607 ms | 33.4% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/untimed | 2 ms | 5 ms | +3 ms | 150.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 96 ms | 94 ms | -2 ms | -2.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 19 ms | 19 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 2 ms | 5 ms | +3 ms | 150.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 3.0 min | 1.9 min | -1 min | -35.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 692.7 MB | 639.3 MB | -53.3 MB | -7.7% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 211.8 MB | 210.7 MB | -1 MB | -0.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | 49.6 MB | 49.5 MB | -152 KB | -0.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.1 MB | 2.1 MB | +152 B | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 26.3 MB | 26.2 MB | -152 KB | -0.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 259 KB | 226.8 KB | -32.2 KB | -12.4% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.4 MB | 1.4 MB | +256 B | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 2 MB | 1.8 MB | -176 KB | -8.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | +1.8 KB | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 78.4 KB | 77.9 KB | -512 B | -0.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 295.8 KB | 295.9 KB | +128 B | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 15.3 KB | 19.8 KB | +4.5 KB | 29.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 242.2 MB | 241.9 MB | -296.4 KB | -0.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 35.0 KB | 35 KB | +8 B | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 1.9 KB | 1.9 KB | +3 B | 0.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/unattributed | 152 MB | 100.5 MB | -51.5 MB | -33.9% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 253932347 | 253628837 | -303510 | -0.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 12602 | 17179 | 4577 | 36.3% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 222042053 | 888634 | -221153419 | -99.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 231512 | 185195 | -46317 | -20.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 432 | 432 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 1184 | 1057 | -127 | -10.7% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | 1184 | 1057 | -127 | -10.7% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 2 | 2 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 350 | 150 | 75.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/detect/scan_sub_compile | 13 ms | 21 ms | +8 ms | 61.5% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/parse/read_files | 1.6 min | 54 s | -41.9 s | -43.7% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics | 10.4 s | 10.3 s | -116 ms | -1.1% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 2.2 s | 1.7 s | -502 ms | -22.6% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 4.9 s | 5.4 s | +522 ms | 10.6% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 3.1 s | 3.0 s | -121 ms | -3.9% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/group_calc | 9 ms | 0 us | -9 ms | -100.0% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 126 ms | 119 ms | -7 ms | -5.6% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/render/normalize_data | 2 ms | 4 ms | +2 ms | 100.0% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/total | 1.8 min | 1.1 min | -42 s | -39.5% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/rss_peak | 2.2 GB | 1.9 GB | -268 MB | -12.0% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/format_scan_subs | 1.9 MB | 2.5 MB | +624 KB | 31.5% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_analysis | 244 MB | 244 MB | +4.5 KB | 0.0% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY/log_messages | 1.6 GB | 1.3 GB | -240 MB | -15.0% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/log_sessions | 2.2 MB | 2.2 MB | +128 B | 0.0% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY/log_stats | 54.2 KB | 54.2 KB | +8 B | 0.0% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/unattributed | 381.6 MB | 353.0 MB | -28.6 MB | -7.5% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/log_messages | 1672623763 | 1420915962 | -251707801 | -15.0% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/log_analysis | 13018 | 17595 | 4577 | 35.2% | REGRESS |
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
| month-single-server-access-logs-sort-skewness | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| month-single-server-access-logs-sort-skewness | TIMING/detect/scan_sub_compile | 13 ms | 21 ms | +8 ms | 61.5% | REGRESS |
| month-single-server-access-logs-sort-skewness | TIMING/parse/read_files | 1.6 min | 54.4 s | -41.1 s | -43.1% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics | 5.9 s | 5.3 s | -609 ms | -10.3% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 2.2 s | 1.7 s | -491 ms | -22.1% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 3.4 s | 3.4 s | -2 ms | -0.1% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 13 ms | 13 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 213 ms | 95 ms | -118 ms | -55.4% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 66 ms | 68 ms | +2 ms | 3.0% | REGRESS |
| month-single-server-access-logs-sort-skewness | TIMING/render/normalize_data | 2 ms | 4 ms | +2 ms | 100.0% | REGRESS |
| month-single-server-access-logs-sort-skewness | TIMING/total | 1.7 min | 59.7 s | -41.7 s | -41.1% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/rss_peak | 2.1 GB | 1.8 GB | -277.7 MB | -13.1% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/format_scan_subs | 2.0 MB | 2.6 MB | +640 KB | 31.7% | REGRESS |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_analysis | 244 MB | 244 MB | +4.5 KB | 0.0% | REGRESS |
| month-single-server-access-logs-sort-skewness | MEMORY/log_messages | 1.6 GB | 1.3 GB | -240 MB | -15.0% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_stats | 54.2 KB | 54.2 KB | +8 B | 0.0% | REGRESS |
| month-single-server-access-logs-sort-skewness | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/unattributed | 284.1 MB | 245.8 MB | -38.2 MB | -13.5% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/log_messages | 1672516792 | 1420808959 | -251707833 | -15.0% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/log_analysis | 13018 | 17595 | 4577 | 35.2% | REGRESS |
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
| month-many-servers-access-logs-standard | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/detect/scan_sub_compile | 20 ms | 32 ms | +12 ms | 60.0% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/parse/read_files | 8 min | 4.6 min | -3.5 min | -43.1% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics | 23.7 s | 22.3 s | -1.4 s | -5.9% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/bucket_stats | 12.3 s | 10.3 s | -2.0 s | -16.1% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 9.0 s | 8.6 s | -354 ms | -3.9% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/group_calc | 2 s | 2.9 s | +935 ms | 46.7% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/untimed | 340 ms | 351 ms | +11 ms | 3.2% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/render/normalize_data | 4 ms | 7 ms | +3 ms | 75.0% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/total | 8.4 min | 4.9 min | -3.5 min | -41.4% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 10.1 GB | 8.7 GB | -1.4 GB | -13.5% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/format_scan_subs | 2.2 MB | 3.0 MB | +784 KB | 34.5% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_analysis | 1.2 GB | 1.2 GB | +4.5 KB | 0.0% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/log_messages | 7.5 GB | 6.3 GB | -1.2 GB | -16.1% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -32 KB | -0.2% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/log_stats | 54.2 KB | 54.2 KB | +8 B | 0.0% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/unattributed | 1.4 GB | 1.2 GB | -166.9 MB | -11.7% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_messages | 8019141603 | 6731196458 | -1287945145 | -16.1% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_analysis | 13018 | 17595 | 4577 | 35.2% | REGRESS |
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
| month-many-servers-access-logs-no-messages | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| month-many-servers-access-logs-no-messages | TIMING/detect/scan_sub_compile | 20 ms | 32 ms | +12 ms | 60.0% | REGRESS |
| month-many-servers-access-logs-no-messages | TIMING/parse/read_files | 6 min | 3.7 min | -2.3 min | -38.8% | IMPROVE |
| month-many-servers-access-logs-no-messages | TIMING/finalize/calculate_statistics | 9.6 s | 8.7 s | -950 ms | -9.9% | IMPROVE |
| month-many-servers-access-logs-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | 9.6 s | 8.7 s | -950 ms | -9.9% | IMPROVE |
| month-many-servers-access-logs-no-messages | TIMING/finalize/calculate_statistics/untimed | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-no-messages | TIMING/render/normalize_data | 3 ms | 5 ms | +2 ms | 66.7% | REGRESS |
| month-many-servers-access-logs-no-messages | TIMING/total | 6.2 min | 3.8 min | -2.3 min | -38.0% | IMPROVE |
| month-many-servers-access-logs-no-messages | MEMORY/rss_peak | 1.7 GB | 1.6 GB | -64.0 MB | -3.7% | IMPROVE |
| month-many-servers-access-logs-no-messages | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/format_scan_subs | 2.8 MB | 3.7 MB | +912 KB | 31.7% | REGRESS |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/log_analysis | 1.2 GB | 1.2 GB | -1.4 MB | -0.1% | IMPROVE |
| month-many-servers-access-logs-no-messages | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-no-messages | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -32 KB | -0.2% | IMPROVE |
| month-many-servers-access-logs-no-messages | MEMORY/log_stats | 54.2 KB | 54.2 KB | +8 B | 0.0% | REGRESS |
| month-many-servers-access-logs-no-messages | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/unattributed | 518.5 MB | 455 MB | -63.5 MB | -12.2% | IMPROVE |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/log_analysis | 13018 | 17595 | 4577 | 35.2% | REGRESS |
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
| month-many-servers-access-logs-top25 | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/detect/scan_sub_compile | 20 ms | 32 ms | +12 ms | 60.0% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/parse/read_files | 8 min | 4.5 min | -3.5 min | -43.3% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics | 25 s | 23.9 s | -1.1 s | -4.4% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 12.8 s | 10.6 s | -2.2 s | -17.3% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 8.7 s | 8.6 s | -143 ms | -1.6% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/group_calc | 3.2 s | 4.4 s | +1.2 s | 37.9% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 355 ms | 390 ms | +35 ms | 9.9% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/render/normalize_data | 4 ms | 7 ms | +3 ms | 75.0% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/total | 8.4 min | 4.9 min | -3.5 min | -41.4% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 10.1 GB | 8.7 GB | -1.4 GB | -13.5% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/format_scan_subs | 2.8 MB | 3.5 MB | +752 KB | 26.7% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_analysis | 1.2 GB | 1.2 GB | +4.5 KB | 0.0% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/log_messages | 7.5 GB | 6.3 GB | -1.2 GB | -16.1% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -32 KB | -0.2% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/log_stats | 54.2 KB | 54.2 KB | +8 B | 0.0% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/message_key_order | 4.7 KB | 4.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/unattributed | 1.4 GB | 1.2 GB | -167.2 MB | -11.7% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_messages | 8019152067 | 6731208794 | -1287943273 | -16.1% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_analysis | 13018 | 17595 | 4577 | 35.2% | REGRESS |
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
| month-many-servers-access-logs-top25-consolidate | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/detect/scan_sub_compile | 20 ms | 33 ms | +13 ms | 65.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/parse/read_files | 9.8 min | 7 min | -2.8 min | -28.9% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/group_similar | 5.9 min | 19.8 s | -5.6 min | -94.4% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 26.8 s | 23.4 s | -3.3 s | -12.5% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 14.4 s | 10.2 s | -4.2 s | -29.3% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 5 ms | -1 ms | -16.7% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 12.3 s | 13.2 s | +884 ms | 7.2% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/untimed | 15 ms | 27 ms | +12 ms | 80.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/render/normalize_data | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 16.2 min | 7.7 min | -8.5 min | -52.3% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 3.5 GB | 3.4 GB | -95.2 MB | -2.6% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 1.1 GB | 1.1 GB | +6 MB | 0.5% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_id_index | 50.5 MB | 50.5 MB | +16.5 KB | 0.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 2.0 MB | 2.0 MB | +232 B | 0.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 26.6 MB | 26.6 MB | +16.5 KB | 0.1% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 482.4 KB | 387.1 KB | -95.4 KB | -19.8% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 1.3 MB | 1.3 MB | +128 B | 0.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/format_scan_subs | 2.5 MB | 2.1 MB | -384 KB | -15.2% | IMPROVE |
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
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages | 1.2 GB | 1.2 GB | +7.4 MB | 0.6% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_occurrences | 43.8 KB | 43.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_stats | 54.2 KB | 54.2 KB | +8 B | 0.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/message_key_order | 4.2 KB | 4.0 KB | -214 B | -5.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | 1274050489 | 1281855028 | 7804539 | 0.6% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 13018 | 17595 | 4577 | 35.2% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 1155339023 | 1887036 | -1153451987 | -99.8% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 493990 | 396351 | -97639 | -19.8% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 432 | 432 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_messages_entries | 2443 | 2208 | -235 | -9.6% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_messages_population | 2443 | 2208 | -235 | -9.6% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | 3 | 3 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | 142 | 142 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 350 | 150 | 75.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/detect/scan_sub_compile | 20 ms | 32 ms | +12 ms | 60.0% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/parse/read_files | 8.8 min | 5.4 min | -3.4 min | -38.7% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics | 10.6 s | 10.8 s | +241 ms | 2.3% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 8.5 s | 8 s | -509 ms | -6.0% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/group_calc | 1.6 s | 2.4 s | +731 ms | 45.0% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 419 ms | 437 ms | +18 ms | 4.3% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/finalize/heatmap_statistics | 120 ms | 115 ms | -5 ms | -4.2% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/render/normalize_data | 2 ms | 5 ms | +3 ms | 150.0% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/total | 9 min | 5.6 min | -3.4 min | -37.9% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 8.8 GB | 7.5 GB | -1.4 GB | -15.3% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/format_scan_subs | 2.7 MB | 3.0 MB | +240 KB | 8.6% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | +1.8 KB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data | 75.8 KB | 75.3 KB | -512 B | -0.7% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_analysis | 15.3 KB | 19.8 KB | +4.5 KB | 29.2% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/log_messages | 7.5 GB | 6.3 GB | -1.2 GB | -16.1% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -32 KB | -0.2% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/log_stats | 35.0 KB | 35 KB | +8 B | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/unattributed | 1.4 GB | 1.2 GB | -157.7 MB | -11.3% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_messages | 8014081747 | 6726136602 | -1287945145 | -16.1% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_analysis | 12602 | 17179 | 4577 | 36.3% | REGRESS |
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
| month-many-servers-access-logs-histogram | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/detect/scan_sub_compile | 20 ms | 32 ms | +12 ms | 60.0% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/parse/read_files | 9.9 min | 6.6 min | -3.3 min | -33.8% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics | 23.7 s | 22.0 s | -1.8 s | -7.4% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 12.8 s | 10.3 s | -2.5 s | -19.4% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 8.6 s | 8.4 s | -192 ms | -2.2% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/group_calc | 2.1 s | 3.0 s | +903 ms | 44.0% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 352 ms | 352 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/finalize/histogram_statistics | 21 ms | 21 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/render/normalize_data | 4 ms | 5 ms | +1 ms | 25.0% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/total | 10.3 min | 6.9 min | -3.4 min | -32.7% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 10 GB | 8.7 GB | -1.3 GB | -13.4% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/format_scan_subs | 2.7 MB | 3.1 MB | +368 KB | 13.1% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_counters | 307.5 KB | 307.8 KB | +256 B | 0.1% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_analysis | 1.2 GB | 1.2 GB | +4.5 KB | 0.0% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/log_messages | 7.5 GB | 6.3 GB | -1.2 GB | -16.0% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -32.1 KB | -0.2% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/log_stats | 54.2 KB | 54.2 KB | +8 B | 0.0% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/unattributed | 1.4 GB | 1.2 GB | -160.0 MB | -11.2% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_messages | 8009293859 | 6731196458 | -1278097401 | -16.0% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_analysis | 13018 | 17595 | 4577 | 35.2% | REGRESS |
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
| month-many-servers-access-logs-heatmap-histogram | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | 20 ms | 32 ms | +12 ms | 60.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/parse/read_files | 10.5 min | 7.2 min | -3.3 min | -31.6% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 11.0 s | 11.1 s | +174 ms | 1.6% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 8.9 s | 8.3 s | -550 ms | -6.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 1.6 s | 2.3 s | +710 ms | 43.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 423 ms | 437 ms | +14 ms | 3.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/heatmap_statistics | 121 ms | 119 ms | -2 ms | -1.7% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/histogram_statistics | 20 ms | 20 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/render/normalize_data | 3 ms | 7 ms | +4 ms | 133.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 10.7 min | 7.4 min | -3.3 min | -31.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 8.8 GB | 7.9 GB | -1013.9 MB | -11.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/format_scan_subs | 2.9 MB | 3.1 MB | +160 KB | 5.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | +1.8 KB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data | 76.8 KB | 76.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_counters | 307.5 KB | 307.7 KB | +128 B | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.3 KB | 19.8 KB | +4.5 KB | 29.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages | 7.5 GB | 6.6 GB | -850.6 MB | -11.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_occurrences | 43.8 KB | 43.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_stats | 35.0 KB | 35 KB | +8 B | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/unattributed | 1.4 GB | 1.2 GB | -163.4 MB | -11.7% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 8014081747 | 7122118938 | -891962809 | -11.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 12602 | 17179 | 4577 | 36.3% | REGRESS |
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
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 20 ms | 33 ms | +13 ms | 65.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/parse/read_files | 8.8 min | 6.4 min | -2.4 min | -26.9% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics | 15.3 s | 14.7 s | -533 ms | -3.5% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | 15.2 s | 14.7 s | -533 ms | -3.5% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/untimed | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | 235 ms | 236 ms | +1 ms | 0.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/histogram_statistics | 19 ms | 19 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/render/normalize_data | 2 ms | 5 ms | +3 ms | 150.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/total | 9 min | 6.7 min | -2.4 min | -26.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/rss_peak | 1.7 GB | 1.6 GB | -88.3 MB | -5.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/format_scan_subs | 2.7 MB | 3.6 MB | +880 KB | 31.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | -1.8 KB | -0.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_data | 76.8 KB | 75.8 KB | -1 KB | -1.3% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/histogram_counters | 307.8 KB | 307.7 KB | -128 B | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_analysis | 1.2 GB | 1.2 GB | +1.4 KB | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_occurrences | 42.1 KB | 43.8 KB | +1.8 KB | 4.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +32 KB | 0.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_stats | 82.7 KB | 80.9 KB | -1.7 KB | -2.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/unattributed | 475.8 MB | 386.6 MB | -89.2 MB | -18.7% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_analysis | 23011 | 22609 | -402 | -1.7% | IMPROVE |
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
| month-many-servers-access-logs-heatmap-histogram-export | CONFIG/max_log_message_length | 200 | 350 | 150 | 75.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 20 ms | 33 ms | +13 ms | 65.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 12.3 min | 9.5 min | -2.8 min | -22.7% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 4.3 min | 14.6 s | -4 min | -94.3% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 10.3 s | 14.1 s | +3.8 s | 36.5% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 4 ms | -1 ms | -20.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 10.3 s | 14.1 s | +3.8 s | 36.5% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/untimed | 15 ms | 24 ms | +9 ms | 60.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 108 ms | 108 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 20 ms | 20 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 3 ms | 6 ms | +3 ms | 100.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 16.7 min | 10.0 min | -6.8 min | -40.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 2.5 GB | 2.7 GB | +144.5 MB | 5.6% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 1.1 GB | 1.1 GB | +6.7 MB | 0.6% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | 50.5 MB | 50.6 MB | +122.5 KB | 0.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.0 MB | 2.0 MB | +232 B | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 26.6 MB | 26.7 MB | +122.5 KB | 0.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 482.4 KB | 387.1 KB | -95.4 KB | -19.8% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.3 MB | 1.3 MB | +128 B | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 2.5 MB | 3 MB | +560 KB | 21.9% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | +1.8 KB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 75.3 KB | 76.3 KB | +1 KB | 1.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 307.7 KB | 307.8 KB | +128 B | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 15.3 KB | 19.8 KB | +4.5 KB | 29.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 1.2 GB | 1.2 GB | +6.8 MB | 0.6% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 35.0 KB | 35 KB | +8 B | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 1.9 KB | 1.9 KB | -70 B | -3.6% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/unattributed | 166.7 MB | 297 MB | +130.3 MB | 78.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 1271505553 | 1278605828 | 7100275 | 0.6% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 12602 | 17179 | 4577 | 36.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 1151389647 | 1887036 | -1149502611 | -99.8% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 493990 | 396351 | -97639 | -19.8% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 432 | 432 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 2443 | 2208 | -235 | -9.6% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | 2443 | 2208 | -235 | -9.6% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 3 | 3 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | 142 | 142 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 350 | 150 | 75.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/detect/scan_sub_compile | 20 ms | 32 ms | +12 ms | 60.0% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/parse/read_files | 8 min | 4.5 min | -3.5 min | -43.8% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics | 1 min | 1 min | +1.9 s | 3.1% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 12.9 s | 10.6 s | -2.3 s | -17.5% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 27.7 s | 30.7 s | +3.0 s | 10.8% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 19.8 s | 20.8 s | +1.1 s | 5.5% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 689 ms | 786 ms | +97 ms | 14.1% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/render/normalize_data | 4 ms | 7 ms | +3 ms | 75.0% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/total | 9.1 min | 5.6 min | -3.5 min | -38.6% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/rss_peak | 10.9 GB | 9.6 GB | -1.4 GB | -12.4% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/format_scan_subs | 2.8 MB | 3.1 MB | +256 KB | 8.8% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_analysis | 1.2 GB | 1.2 GB | +2.7 KB | 0.0% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_messages | 7.9 GB | 6.7 GB | -1.2 GB | -15.1% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_occurrences | 42.1 KB | 43.8 KB | +1.8 KB | 4.2% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +128 B | 0.0% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_stats | 54.2 KB | 54.2 KB | +8 B | 0.0% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/message_key_order | 2.5 KB | 2.5 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/unattributed | 1.8 GB | 1.6 GB | -161.9 MB | -8.8% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/log_messages | 8528632963 | 7240687818 | -1287945145 | -15.1% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/log_analysis | 13018 | 15803 | 2785 | 21.4% | REGRESS |
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
| month-many-servers-access-logs-sort-skewness | TIMING/detect/registry_build | 12 ms | 22 ms | +10 ms | 83.3% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/detect/scan_sub_compile | 20 ms | 32 ms | +12 ms | 60.0% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/parse/read_files | 8 min | 4.6 min | -3.5 min | -43.1% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics | 34.4 s | 32.4 s | -2.0 s | -5.8% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 13.0 s | 10.3 s | -2.7 s | -20.8% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 20.3 s | 21.3 s | +987 ms | 4.9% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 74 ms | 71 ms | -3 ms | -4.1% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 717 ms | 438 ms | -279 ms | -38.9% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 364 ms | 368 ms | +4 ms | 1.1% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/render/normalize_data | 4 ms | 7 ms | +3 ms | 75.0% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/total | 8.6 min | 5.1 min | -3.5 min | -40.6% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY/rss_peak | 10.4 GB | 9.4 GB | -1 GB | -9.7% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/format_scan_subs | 2.8 MB | 3 MB | +304 KB | 10.8% | REGRESS |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_analysis | 1.2 GB | 1.2 GB | +4.5 KB | 0.0% | REGRESS |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_messages | 7.9 GB | 7.1 GB | -850.6 MB | -10.5% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +32.1 KB | 0.2% | REGRESS |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_stats | 54.2 KB | 54.2 KB | +8 B | 0.0% | REGRESS |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/message_key_order | 2.1 KB | 2.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/unattributed | 1.2 GB | 1 GB | -184.5 MB | -14.7% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/log_messages | 8528067400 | 7636104655 | -891962745 | -10.5% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/log_analysis | 13018 | 17595 | 4577 | 35.2% | REGRESS |
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
| humungous-log-uniqueness-standard | TIMING/read/path_generation | N/A | 6 ms | N/A | N/A | ? |
| humungous-log-uniqueness-standard | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | TIMING/read/path_generation | N/A | 6 ms | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | TIMING/read/path_generation | N/A | 6 ms | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | TIMING/read/path_generation | N/A | 7 ms | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | TIMING/read/path_generation | N/A | 6 ms | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | TIMING/read/path_generation | N/A | 7 ms | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | TIMING/read/path_generation | N/A | 7 ms | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/read/path_generation | N/A | 6 ms | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | CONFIG/timestamp_fraction_capture | N/A | 1 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/read/path_generation | N/A | 7 ms | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | TIMING/read/path_generation | N/A | 6 ms | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | TIMING/read/path_generation | N/A | 6 ms | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-standard | TIMING/read/path_generation | N/A | 6 ms | N/A | N/A | ? |
| single-day-application-log-standard | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-no-messages | TIMING/read/path_generation | N/A | 6 ms | N/A | N/A | ? |
| single-day-application-log-no-messages | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-top25 | TIMING/read/path_generation | N/A | 6 ms | N/A | N/A | ? |
| single-day-application-log-top25 | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | TIMING/read/path_generation | N/A | 7 ms | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap | TIMING/read/path_generation | N/A | 6 ms | N/A | N/A | ? |
| single-day-application-log-heatmap | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-histogram | TIMING/read/path_generation | N/A | 7 ms | N/A | N/A | ? |
| single-day-application-log-histogram | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | TIMING/read/path_generation | N/A | 7 ms | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | TIMING/read/path_generation | N/A | 6 ms | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | CONFIG/timestamp_fraction_capture | N/A | 1 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/read/path_generation | N/A | 7 ms | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | TIMING/read/path_generation | N/A | 6 ms | N/A | N/A | ? |
| single-day-application-log-sort-p99 | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | TIMING/read/path_generation | N/A | 6 ms | N/A | N/A | ? |
| single-day-application-log-sort-skewness | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-standard | TIMING/read/path_generation | N/A | 58 ms | N/A | N/A | ? |
| multi-day-application-logs-standard | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | TIMING/read/path_generation | N/A | 46 ms | N/A | N/A | ? |
| multi-day-application-logs-no-messages | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-top25 | TIMING/read/path_generation | N/A | 58 ms | N/A | N/A | ? |
| multi-day-application-logs-top25 | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/read/path_generation | N/A | 68 ms | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | TIMING/read/path_generation | N/A | 63 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-histogram | TIMING/read/path_generation | N/A | 68 ms | N/A | N/A | ? |
| multi-day-application-logs-histogram | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | TIMING/read/path_generation | N/A | 72 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | TIMING/read/path_generation | N/A | 61 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | CONFIG/timestamp_fraction_capture | N/A | 1 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/read/path_generation | N/A | 81 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | TIMING/read/path_generation | N/A | 58 ms | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | TIMING/read/path_generation | N/A | 58 ms | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-standard | TIMING/read/path_generation | N/A | 12 ms | N/A | N/A | ? |
| multi-day-custom-logs-standard | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | TIMING/read/path_generation | N/A | 10 ms | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | TIMING/read/path_generation | N/A | 12 ms | N/A | N/A | ? |
| multi-day-custom-logs-top25 | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | TIMING/read/path_generation | N/A | 13 ms | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | TIMING/read/path_generation | N/A | 12 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | TIMING/read/path_generation | N/A | 13 ms | N/A | N/A | ? |
| multi-day-custom-logs-histogram | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | TIMING/read/path_generation | N/A | 14 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/read/path_generation | N/A | 12 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | CONFIG/timestamp_fraction_capture | N/A | 1 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/read/path_generation | N/A | 15 ms | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | TIMING/read/path_generation | N/A | 12 ms | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | TIMING/read/path_generation | N/A | 12 ms | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-standard | TIMING/read/path_generation | N/A | 6 ms | N/A | N/A | ? |
| single-day-access-log-standard | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-no-messages | TIMING/read/path_generation | N/A | 6 ms | N/A | N/A | ? |
| single-day-access-log-no-messages | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-top25 | TIMING/read/path_generation | N/A | 6 ms | N/A | N/A | ? |
| single-day-access-log-top25 | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | TIMING/read/path_generation | N/A | 7 ms | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-heatmap | TIMING/read/path_generation | N/A | 6 ms | N/A | N/A | ? |
| single-day-access-log-heatmap | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-histogram | TIMING/read/path_generation | N/A | 7 ms | N/A | N/A | ? |
| single-day-access-log-histogram | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | TIMING/read/path_generation | N/A | 7 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | TIMING/read/path_generation | N/A | 6 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | CONFIG/timestamp_fraction_capture | N/A | 1 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/read/path_generation | N/A | 7 ms | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | TIMING/read/path_generation | N/A | 6 ms | N/A | N/A | ? |
| single-day-access-log-sort-p99 | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | TIMING/read/path_generation | N/A | 6 ms | N/A | N/A | ? |
| single-day-access-log-sort-skewness | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/read/path_generation | N/A | 43 ms | N/A | N/A | ? |
| month-single-server-access-logs-standard | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | TIMING/read/path_generation | N/A | 35 ms | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/read/path_generation | N/A | 43 ms | N/A | N/A | ? |
| month-single-server-access-logs-top25 | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/read/path_generation | N/A | 49 ms | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/read/path_generation | N/A | 47 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/read/path_generation | N/A | 51 ms | N/A | N/A | ? |
| month-single-server-access-logs-histogram | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/read/path_generation | N/A | 53 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/read/path_generation | N/A | 45 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | CONFIG/timestamp_fraction_capture | N/A | 1 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/read/path_generation | N/A | 60 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | TIMING/read/path_generation | N/A | 44 ms | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | TIMING/read/path_generation | N/A | 44 ms | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/read/path_generation | N/A | 197 ms | N/A | N/A | ? |
| month-many-servers-access-logs-standard | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | TIMING/read/path_generation | N/A | 155 ms | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/read/path_generation | N/A | 198 ms | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/read/path_generation | N/A | 225 ms | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/read/path_generation | N/A | 212 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/read/path_generation | N/A | 234 ms | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/read/path_generation | N/A | 249 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/read/path_generation | N/A | 209 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | CONFIG/timestamp_fraction_capture | N/A | 1 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/read/path_generation | N/A | 277 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | TIMING/read/path_generation | N/A | 198 ms | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | TIMING/read/path_generation | N/A | 199 ms | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | CONFIG/timestamp_fraction_capture | N/A | 0 | N/A | N/A | ? |

